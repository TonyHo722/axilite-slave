///////////////////////////////////////////////////////////////////////////////
//
//       AUTHOR: zack
// ORGANIZATION: fsic
//      CREATED: 2023/05/16
///////////////////////////////////////////////////////////////////////////////

class axilite_s_monitor;
    virtual axilite_s_interface.master intf;
    axilite_s_scenario scnr_mon[2];
    mb_axi mb_mon;
    logic [11:0] wr_addr, rd_addr;
    logic [31:0] wr_data, rd_data;
    logic [3:0] wr_strb;
    int packet_cnt = 0;

    function new(virtual axilite_s_interface.master intf, mb_axi mb_mon);
        this.intf = intf;
        this.mb_mon = mb_mon;
    endfunction

    virtual task bus_mon();
        //while(1)begin
        //for(int i=0; i< axilite_s_scenario_gen::PKT_NUM; i++)begin
            
            fork
                while(1)begin // wr
                    while(1)begin
                        @(posedge intf.axi_aclk);
                        -> top.evt_001;

                        // write addr
                        if(intf.bk_wstart === 1)begin
                            wr_addr = intf.bk_waddr;
                            wr_data = intf.bk_wdata;
                            wr_strb = intf.bk_wstrb;
                            break;
                        end
                    end

                    scnr_mon[0] = new();
                    scnr_mon[0].wr_addr = wr_addr;
                    scnr_mon[0].wr_data = wr_data;
                    scnr_mon[0].wr_strb = wr_strb;
                    scnr_mon[0].axi_op = AXI_WR;
                    scnr_mon[0].display("scnr_mon[0]");
                    mb_mon.put(scnr_mon[0]);
                    packet_cnt +=1;
                end
                
                while(1)begin // rd
                    fork
                        while(1)begin
                            @(posedge intf.axi_aclk);
                            -> top.evt_002;

                            // rd addr
                            if(intf.bk_rstart === 1)begin
                                rd_addr = intf.bk_raddr;
                                break;
                            end
                        end
                        while(1)begin
                            @(posedge intf.axi_aclk);

                            // read data
                            if(intf.axi_rvalid === 1'b1 && intf.axi_rready === 1'b1)begin
                                //#(BUS_DELAY);
                                rd_data = intf.axi_rdata;
                                break;
                            end
                        end
                    join
                    scnr_mon[1] = new();
                    scnr_mon[1].rd_addr = rd_addr;
                    scnr_mon[1].rd_data = rd_data;
                    scnr_mon[1].axi_op = AXI_RD;
                    scnr_mon[1].display("scnr_mon[1]");
                    mb_mon.put(scnr_mon[1]);
                    packet_cnt +=1;
                end
                
                while(1)begin
                    @(posedge intf.axi_aclk);
                    if(packet_cnt >= axilite_s_scenario_gen::PKT_NUM) break;
                end
            join_any
            disable fork;
        //end
    endtask

endclass
