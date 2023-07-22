///////////////////////////////////////////////////////////////////////////////
//
//       AUTHOR: zack
// ORGANIZATION: fsic
//      CREATED: 2023/05/16
///////////////////////////////////////////////////////////////////////////////
//20230722
//1. rename variable for more readable in this project

class axilite_s_scoreboard;
    virtual axilite_s_interface.master intf;
    axilite_s_scenario scnr_gen, scnr_mon;
    mb_axi mb_gen2scrbd, mb_mon2scrbd;
    static int succ_cnt, fail_cnt;
    axilite_s_scenario gen_wr_tr_q[$], gen_rd_tr_q[$], mon_wr_tr_q[$], mon_rd_tr_q[$], gen_wr_tr, gen_rd_tr, mon_wr_tr, mon_rd_tr;

    function new(virtual axilite_s_interface.master intf, mb_axi mb_gen2scrbd, mb_axi mb_mon2scrbd);
        this.intf = intf;                         
        this.mb_gen2scrbd = mb_gen2scrbd;
        this.mb_mon2scrbd = mb_mon2scrbd;
    endfunction

    virtual task compare_trans();
        fork
            // get trans, put in queue
            while(1)begin
                mb_gen2scrbd.get(scnr_gen);
                if(scnr_gen.axi_op == AXI_WR)begin
                    gen_wr_tr_q.push_back(scnr_gen);
                end
                else
                    gen_rd_tr_q.push_back(scnr_gen);
            end

            while(1)begin
                mb_mon2scrbd.get(scnr_mon);
                if(scnr_mon.axi_op == AXI_WR)begin
                    mon_wr_tr_q.push_back(scnr_mon);
                end
                else
                    mon_rd_tr_q.push_back(scnr_mon);
            end

            while(1)begin
                if((gen_wr_tr_q.size() != 0) && (mon_wr_tr_q.size() != 0))begin
                    gen_wr_tr = gen_wr_tr_q.pop_front();
                    mon_wr_tr = mon_wr_tr_q.pop_front();
                    if(gen_wr_tr.compare(mon_wr_tr))begin
                        $display($sformatf("trans %6d compare ok", gen_wr_tr.trans_id));
                        succ_cnt +=1;
                    end
                    else begin
                        $display($sformatf("[ERROR] %6t trans %6d compare fail", $time(), gen_wr_tr.trans_id));
                        gen_wr_tr.display();
                        mon_wr_tr.display();
                        fail_cnt +=1;
                    end
                end
                else begin
                    @(posedge intf.axi_aclk);
                end
            end

            while(1)begin
                if((gen_rd_tr_q.size() != 0) && (mon_rd_tr_q.size() != 0))begin
                    gen_rd_tr = gen_rd_tr_q.pop_front();
                    mon_rd_tr = mon_rd_tr_q.pop_front();
                    if(gen_rd_tr.compare(mon_rd_tr))begin
                        $display($sformatf("trans %6d compare ok", gen_rd_tr.trans_id));
                        succ_cnt +=1;
                    end
                    else begin
                        $display($sformatf("[ERROR] %6t trans %6d compare fail", $time(), gen_rd_tr.trans_id));
                        gen_rd_tr.display();
                        mon_rd_tr.display();
                        fail_cnt +=1;
                    end
                end
                else begin
                    @(posedge intf.axi_aclk);
                end
            end
         
            while(1)begin
                if((succ_cnt + fail_cnt) >= axilite_s_scenario_gen::PKT_NUM) break;
                else begin
                    @(posedge intf.axi_aclk);
                end
            end
        join_any
        disable fork;

    endtask

    virtual function void report();
        $display($sformatf("total trans %6d, success %6d, fail %6d", succ_cnt + fail_cnt, succ_cnt, fail_cnt));
    endfunction

endclass
