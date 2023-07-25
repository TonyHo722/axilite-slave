///////////////////////////////////////////////////////////////////////////////
//
//	   AUTHOR: zack
// ORGANIZATION: fsic
//	  CREATED: 2023/05/16
///////////////////////////////////////////////////////////////////////////////


interface axilite_s_interface();
	logic axi_aclk;
	logic axi_aresetn;
	logic axi_awvalid;
	logic [11:0] axi_awaddr;
	logic axi_wvalid;
	logic [31:0] axi_wdata;
	logic [3:0] axi_wstrb;
	logic axi_arvalid;
	logic [11:0] axi_araddr;
	logic axi_rready;
	logic [31:0] axi_rdata;
	logic axi_awready;
	logic axi_wready;
	logic axi_arready;
	logic axi_rvalid;
	
	logic bk_wstart;
	logic [11:0] bk_waddr;
	logic [31:0] bk_wdata;
	logic [3:0]  bk_wstrb;
	logic bk_wdone;
	logic bk_rstart;
	logic [11:0] bk_raddr;
	logic [31:0] bk_rdata;
	logic bk_rdone;

	modport master(		//axilite master interface 
		input axi_aclk,
		input axi_aresetn,
		input axi_awready,
		input axi_wready,
		input axi_arready,
		input axi_rvalid,
		input axi_rdata,
		output axi_awvalid,
		output axi_awaddr,
		output axi_wvalid,
		output axi_wdata,
		output axi_wstrb,
		output axi_arvalid,
		output axi_araddr,
		output axi_rready,

		input bk_wstart,
		input bk_waddr,
		input bk_wdata,
		input bk_wstrb,
		output bk_wdone,
		input bk_rstart,
		input bk_raddr,
		output bk_rdata,		//axilite master interface provide bk_rdata
		output bk_rdone			//axilite master interface provide bk_rdone
	);

	modport slave(				//axilite slave interface
		input axi_aclk,
		input axi_aresetn,
		input axi_awvalid,
		input axi_awaddr,
		input axi_wvalid,
		input axi_wdata,
		input axi_wstrb,
		input axi_arvalid,
		input axi_araddr,
		input axi_rready,
		output axi_rdata,
		output axi_awready,
		output axi_wready,
		output axi_arready,
		output axi_rvalid

	);

endinterface
