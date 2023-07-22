///////////////////////////////////////////////////////////////////////////////
//
//       AUTHOR: zack
// ORGANIZATION: fsic
//      CREATED: 2023/05/16
///////////////////////////////////////////////////////////////////////////////

`define dut top.axilite_s
//event evt_wr_addr, evt_wr_data;

//20230722 
//1. use NBA in driver to update value
//20230707 
//1. use #0 for testbench update value
//2. issue axi_awvalid & axi_wvalid at the same time
//3. set axi_awvalid=1 in next T after write data complete 

parameter BUS_DELAY = 1ns;

class axilite_s_driver;
    virtual axilite_s_interface.master intf;
    axilite_s_scenario scnr_drvr;
    mb_axi mb_drvr;
    axilite_s_scenario wr_q[$], rd_q[$], wr_tr, rd_tr;

    function new(virtual axilite_s_interface.master intf, mb_axi mb_drvr);
        this.intf = intf;
        this.scnr_drvr = scnr_drvr;
        this.mb_drvr = mb_drvr;
    endfunction

    virtual task bus_op();
        bit down;
        bit [11:0] wr_addr, rd_addr;
        bit [31:0] wr_data;
        bit [3:0] wstrb;
        //event evt_wr_addr, evt_wr_data;

        init_bus();

        //while(1)begin
        for(int i=0; i < axilite_s_scenario_gen::PKT_NUM; i++)begin
            scnr_drvr = new();
            mb_drvr.get(scnr_drvr);
            scnr_drvr.display();
            //-> top.evt_001;
            if(scnr_drvr.axi_op == AXI_WR)begin
                wr_q.push_back(scnr_drvr);		//push to wr_q
            end
            else begin
                rd_q.push_back(scnr_drvr);		//push to rd_q
            end
        end

		@(posedge intf.axi_aclk);
        fork
            while(1)begin
                if(wr_q.size() != 0)begin
                    wr_tr = wr_q.pop_front();		//get wr_q
					begin // write addr and data
						intf.axi_awaddr <= wr_tr.wr_addr;
						intf.axi_awvalid <= 1;
						intf.axi_wdata <= wr_tr.wr_data;
						intf.axi_wstrb <= wr_tr.wr_strb;
						intf.axi_wvalid <= 1;
						$display($sformatf("[INFO] %6t write addr and data trans %6d", $time(), wr_tr.trans_id));
						fork 
							begin
								// wait for axi_awready
								while(1)begin
									@(posedge intf.axi_aclk);
									if(intf.axi_awready === 1'b1)begin
										intf.axi_awaddr <= 0;
										intf.axi_awvalid <= 0;
										$display($sformatf("[INFO] %6t axi_awready==1 trans %6d", $time(), wr_tr.trans_id));
										break;
									end
								end
							end
							begin
								// wait for axi_wready
								while(1)begin
									@(posedge intf.axi_aclk);
									if(intf.axi_wready === 1'b1)begin
										//#(BUS_DELAY);
										intf.axi_wdata <= 0;
										intf.axi_wstrb <= 0;
										intf.axi_wvalid <= 0;
										$display($sformatf("[INFO] %6t axi_wready==1 trans %6d", $time(), wr_tr.trans_id));
										break;
									end
								end
							end
						join

					end

                    //repeat($urandom_range(5)) @(posedge intf.axi_aclk);
                    //break;
                end
                else begin
                    @(posedge intf.axi_aclk);
                end
            end
            
            while(1)begin
                if(rd_q.size() != 0)begin
                    rd_tr = rd_q.pop_front();
                    fork // read
                        begin // rd addr
                            @(posedge intf.axi_aclk);
                            intf.axi_araddr = rd_tr.rd_addr;
                            intf.axi_arvalid = 1;
                            
                            while(1)begin
                                @(posedge intf.axi_aclk);
                                if(intf.axi_arready === 1'b1)begin
                                    #(BUS_DELAY);
                                    intf.axi_araddr = 0;
                                    intf.axi_arvalid = 0;
                                    break;
                                end
                            end
                        end

                        begin // rd ready
                            while(1)begin
                                @(posedge intf.axi_aclk);
                                if(intf.axi_rready == 0)begin
                                    #(BUS_DELAY);
                                    if($urandom_range(1))
                                        intf.axi_rready = 1;
                                end
                                 @(posedge intf.axi_aclk);
                                if(intf.axi_rready == 1)begin
                                    if(intf.axi_rvalid === 1)begin
                                        #(BUS_DELAY);
                                        if($urandom_range(1))
                                            intf.axi_rready = 0;
                                        break;
                                    end
                                end
                            end
                        end

                        begin // rd data
                            //@(posedge intf.axi_aclk);
                            //Willy debug - s
                            while(1)begin
                                @(posedge intf.axi_aclk);
                                if(intf.bk_rstart === 1'b1)begin
                                    #(BUS_DELAY);
                                    intf.bk_rdata = rd_tr.rd_data;
                                    intf.bk_rdone = 1;
        
                                    @(posedge intf.axi_aclk);
                                    #(BUS_DELAY);
                                    intf.bk_rdata = 0;
                                    intf.bk_rdone = 0;
                                    
                                    break;
                                end
                            end
                            //Willy debug - e
                        end
                    join

                    repeat($urandom_range(5)) @(posedge intf.axi_aclk);
                end
                else begin
                    @(posedge intf.axi_aclk);
                end
            end
            
            while(1)begin
                if((wr_q.size() + rd_q.size()) == 0)begin
                    repeat(20)@(posedge intf.axi_aclk);
                    break;
                end
                else begin
                    @(posedge intf.axi_aclk);
                end
            end
        join_any
        disable fork;
    endtask

    virtual task init_bus();
        intf.bk_wdone = 0;
        intf.bk_rdata = 0;
        intf.bk_rdone = 0;

        intf.axi_awvalid = 0;
        intf.axi_awaddr = 0;
        intf.axi_wvalid = 0;
        intf.axi_wdata = 0;
        intf.axi_wstrb = 0;
        intf.axi_arvalid = 0;
        intf.axi_araddr = 0;
        intf.axi_rready = 0;
        
        wait(intf.axi_aresetn === 1);
    endtask
endclass
