///////////////////////////////////////////////////////////////////////////////
//
//       AUTHOR: zack
// ORGANIZATION: fsic
//      CREATED: 2023/05/16
///////////////////////////////////////////////////////////////////////////////
//20230722
//1. rename variable for more readable in this project

class axilite_s_monitor;
    virtual axilite_s_interface.master intf;
    axilite_s_scenario scnr_mon_wr, scnr_mon_rd;
    mb_axi mb_mon2scrbd;
    logic [11:0] wr_addr, rd_addr;
    logic [31:0] wr_data, rd_data;
    logic [3:0] wr_strb;
    int packet_cnt = 0;

    function new(virtual axilite_s_interface.master intf, mb_axi mb_mon2scrbd);
        this.intf = intf;
        this.mb_mon2scrbd = mb_mon2scrbd;
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

                    scnr_mon_wr = new();
                    scnr_mon_wr.wr_addr = wr_addr;
                    scnr_mon_wr.wr_data = wr_data;
                    scnr_mon_wr.wr_strb = wr_strb;
                    scnr_mon_wr.axi_op = AXI_WR;
                    scnr_mon_wr.display("scnr_mon_wr");
                    mb_mon2scrbd.put(scnr_mon_wr);
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
                    scnr_mon_rd = new();
                    scnr_mon_rd.rd_addr = rd_addr;
                    scnr_mon_rd.rd_data = rd_data;
                    scnr_mon_rd.axi_op = AXI_RD;
                    scnr_mon_rd.display("scnr_mon_rd");
                    mb_mon2scrbd.put(scnr_mon_rd);
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
