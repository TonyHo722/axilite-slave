///////////////////////////////////////////////////////////////////////////////
//
//	   AUTHOR: zack
// ORGANIZATION: fsic
//	  CREATED: 2023/05/16
///////////////////////////////////////////////////////////////////////////////
//20230722
//1. rename variable for more readable in this project


`timescale 1ns/1ns
`include "axilite_s_interface.sv"

// https://stackoverflow.com/questions/55198865/problem-with-creating-structural-modules-using-interfaces-systemverilog

module tc(axilite_s_interface axi_intf);
	`include "axilite_s_scenario.sv"
	`include "axilite_s_driver.sv"
	`include "axilite_s_monitor.sv"
	`include "axilite_s_scoreboard.sv"
	axilite_s_scenario_gen gen;
	axilite_s_driver drvr;
	axilite_s_monitor mon;
	axilite_s_scoreboard scrbd;
	mb_axi mb_gen2drvr, mb_gen2scrbd, mb_mon2scrbd;

	//constraint axi_scenario::op_limit{
	//	//axi_op == AXI_WR;
	//}

	function void connect();
		mb_gen2drvr = new();
		mb_gen2scrbd = new();
		mb_mon2scrbd = new();

		gen = new(mb_gen2drvr, mb_gen2scrbd);
		drvr = new(axi_intf.master, mb_gen2drvr);
		mon = new(axi_intf.master, mb_mon2scrbd);
		scrbd = new(axi_intf.master, mb_gen2scrbd, mb_mon2scrbd);
	endfunction

	initial begin
		connect();
		axilite_s_scenario_gen::PKT_NUM = 300;			//set PKT_NUM

		fork
			gen.gen();
			drvr.bus_op();
			mon.bus_mon();
			scrbd.compare_trans();
		join

		scrbd.report();
		$finish();
	end
endmodule
