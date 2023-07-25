///////////////////////////////////////////////////////////////////////////////
//
//	   AUTHOR: zack
// ORGANIZATION: fsic
//	  CREATED: 2023/05/16
///////////////////////////////////////////////////////////////////////////////
//20230722
//1. rename variable for more readable in this project


typedef enum bit [3:0] {AXI_WR, AXI_RD} axi_operation;

class axilite_s_scenario;			//for transaction
	int trans_id;
	static int trans_id_st;
	rand axi_operation axi_op;

	rand logic [11:0] wr_addr;
	rand logic [31:0] wr_data;
	rand logic [3:0] wr_strb;

	rand logic [11:0] rd_addr;
	rand logic [31:0] rd_data;

	//extern constraint op_limit;
	function new();
		//this.randomize();
	endfunction

	virtual function void display(string prefix="");
		$display($sformatf("\ntrans_id %6d ========%s", trans_id, prefix));

		if(this.axi_op == AXI_WR)begin
			$display($sformatf("wr_addr = %h", wr_addr));
			$display($sformatf("wr_data = %h", wr_data));
			$display($sformatf("wr_strb = %b", wr_strb));
		end
		else if(this.axi_op == AXI_RD)begin
			$display($sformatf("rd_addr = %h", rd_addr));
			$display($sformatf("rd_data = %h", rd_data));
		end
		$display($sformatf("========================\n"));

	endfunction

	function void post_randomize();
		trans_id_st += 1;
		trans_id = trans_id_st;
	endfunction

	function bit compare(axilite_s_scenario tr_cmp);
		int err_cnt;

		err_cnt = 0;
		if(this.axi_op == AXI_WR)begin
			if(this.wr_addr !== tr_cmp.wr_addr) err_cnt += 1;
			if(this.wr_data !== tr_cmp.wr_data) err_cnt += 1;
			if(this.wr_strb !== tr_cmp.wr_strb) err_cnt += 1;
		end
		else begin
			if(this.rd_addr !== tr_cmp.rd_addr) err_cnt += 1;
			if(this.rd_data !== tr_cmp.rd_data) err_cnt += 1;
		end
		if(err_cnt != 0) return 0;
		else return 1;
	endfunction
endclass

typedef mailbox #(axilite_s_scenario) mb_axi;

class axilite_s_scenario_gen;		//generator
	axilite_s_scenario scnr;
	mb_axi mb_gen2drvr, mb_gen2scrbd;
	static int PKT_NUM;

	function new(mb_axi mb_gen2drvr, mb_gen2scrbd);
		this.mb_gen2drvr = mb_gen2drvr;		//scenario_gen to driver
		this.mb_gen2scrbd = mb_gen2scrbd;		//scenario_gen to scoreboard
	endfunction

	task gen();
		for(int i=0; i < PKT_NUM; i++)begin
			scnr = new();
			scnr.randomize();
			//scnr.display();
			mb_gen2drvr.put(scnr);
			mb_gen2scrbd.put(scnr);
		end
	endtask
endclass
