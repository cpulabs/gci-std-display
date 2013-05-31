
`default_nettype none
//`include "gci_std_display_parameter.h"

module gci_std_display_top #(
		parameter P_VRAM_SIZE = 307200,
		parameter P_VRAM_INDEX = 0,
		parameter P_AREA_H = 640,
		parameter P_AREA_V = 480,
		parameter P_AREAA_HV_N = 19,
		parameter P_MEM_ADDR_N = 23
	)(
		//System
		input wire iCLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,
		//Display Clock
		input wire iDISP_CLOCK,				
		//Write Reqest
		input wire iIF_WR_REQ,
		output wire oIF_WR_BUSY,
		input wire iIF_WR_RW,
		input wire [31:0] iIF_WR_ADDR,
		input wire [31:0] iIF_WR_DATA,
		//Read
		output wire oIF_RD_VALID,
		input wire iIF_RD_BUSY,
		output wire oIF_RD_DATA,
		//VRAM IF
		output wire oVRAM_ARBIT_REQ,
		input wire iVRAM_ARBIT_ACK,
		output wire oVRAM_ARBIT_FINISH,
		output wire oVRAM_ENA,
		input wire iVRAM_BUSY,
		output wire oVRAM_RW,
		output wire [P_MEM_ADDR_N-1:0] oVRAM_ADDR,
		output wire [31:0] oVRAM_DATA,
		input wire iVRAM_VALID,
		output wire oVRAM_BUSY,
		input wire [31:0] iVRAM_DATA,
		//Display
		output wire oDISP_CLOCK,
		output wire onDISP_RESET,
		output wire oDISP_ENA,
		output wire oDISP_BLANK,
		output wire onDISP_HSYNC,
		output wire onDISP_VSYNC,
		output wire [9:0] oDISP_DATA_R,
		output wire [9:0] oDISP_DATA_G,
		output wire [9:0] oDISP_DATA_B
	);
	
	
	/****************************************************************
	Hub Interface Controller
	****************************************************************/
	gci_std_display_hub_interface HUB_IF_CTRL(
		//System
		.iCLOCK(),
		.inRESET(),
		.iRESET_SYNC(),			
		//HUB(Reqest/Write)
		.iHUB_REQ(),
		.oHUB_BUSY(),
		.iHUB_RW(),
		.iHUB_ADDR(),
		.iHUB_DATA(),
		//HUB(Read)
		.oHUB_VALID(),
		.iHUB_BUSY(),
		.oHUB_DATA(),
		//Register(Request/Write)
		.oREG_ENA(),
		.oREG_RW(),
		.oREG_ADDR(),
		.oREG_DATA(),
		//Register(Read)
		.iREG_VALID(),
		.oREG_BUSY(),
		.iREG_DATA(),
		//Command(Request/Write)
		.oCOMM_VALID(),
		.oCOMM_SEQ(),
		.iCOMM_BUSY(),
		.oCOMM_RW(),
		.oCOMM_ADDR(),
		.oCOMM_DATA(),
		//Command(Read)
		.iCOMM_VALID(),
		.oCOMM_BUSY(),
		.iCOMM_ADDR(),
		.iCOMM_DATA()
	);
	
	/****************************************************************
	Display Struct Register
	****************************************************************/
	wire register_info_charactor;
	wire [1:0] register_info_color;
	gci_std_display_register #(P_VRAM_SIZE) REGISTER(
		.iCLOCK(iCLOCK),
		.inRESET(inRESET),
		.iRESET_SYNC(1'b0),
		//Write
		.iWR_VALID(register_ctrl_condition && !register_busy_condition && iIF_WR_RW),
		.iWR_ADDR(iIF_WR_ADDR[3:0]),
		.iWR_DATA(iIF_WR_DATA),
		//Read
		.iRD_VALID(register_ctrl_condition && !register_busy_condition && !iIF_WR_RW),
		.oRD_BUSY(),
		.iRD_ADDR(iIF_WR_ADDR[3:0]),
		.oRD_VALID(),
		.iRD_BUSY(),
		.oRD_DATA(),
		//Info
		.oINFO_CHARACTER(register_info_charactor),
		.oINFO_COLOR(register_info_color)
	);
	
	/****************************************************************
	Display Command Decoder
	****************************************************************/
	wire command2request_valid;
	wire request2command_busy;
	wire [P_MEM_ADDR_N:0] command2request_addr;
	wire [23:0] command2request_data;
	gci_std_display_command #(
		P_AREA_H,
		P_AREA_V,
		P_AREAA_HV_N,
		P_MEM_ADDR_N
	)COMMAND(
		.iCLOCK(),
		.inRESET(),
		//Register
		.iREG_MODE(register_info_charactor), //[0]Bitmap | [1]Charactor
		//BUS
		.iIF_VALID(display_ctrl_condition && !display_busy_condition || sequence_ctrl_condition && !sequence_busy_condition),
		.iIF_SEQ(sequence_ctrl_condition),
		.oIF_BUSY(),
		.iIF_RW(),
		.iIF_ADDR(),
		.iIF_DATA(),
		//Output
		.oIF_VALID(command2request_valid),
		.iIF_BUSY(request2command_busy),
		.oIF_ADDR(command2request_addr),
		.oIF_DATA(command2request_data)
	);
	
	/****************************************************************
	Display Write/Read Controller
	****************************************************************/
	wire request2vramif_req;
	wire vramif2request_ack;
	wire request2vramif_finish;
	wire vramif2request_break;
	wire vramif2request_busy;
	wire request2vramif_ena;
	wire request2vramif_rw;
	wire [P_MEM_ADDR_N-1:0] request2vramif_addr;
	wire [7:0] request2vramif_r;
	wire [7:0] request2vramif_g;
	wire [7:0] request2vramif_b;
	wire vramif2request_valid;
	wire request2vramif_busy;
	wire [31:0] vramif2request_data;
	
	gci_std_display_request_controller #(
		P_AREA_H,
		P_AREA_V,
		P_AREAA_HV_N,
		P_MEM_ADDR_N
	)(
		.iCLOCK(iCLOCK),
		.inRESET(inRESET),
		//BUS
		.iRQ_VALID(command2request_valid),
		.oRQ_BUSY(request2command_busy),
		.iRQ_ADDR(command2request_addr),
		.iRQ_DATA(command2request_data),
		//VRAM
		.oRQ_VALID(),
		.oRQ_BUSY(),
		.oRQ_DATA(), 
		//VRAM IF
		.oIF_REQ(request2vramif_req),
		.iIF_ACK(vramif2request_ack),
		.oIF_FINISH(request2vramif_finish),
		.iIF_BREAK(vramif2request_break),
		.iIF_BUSY(vramif2request_busy),
		.oIF_ENA(request2vramif_ena),
		.oIF_RW(request2vramif_rw),
		.oIF_ADDR(request2vramif_addr),
		.oIF_R(request2vramif_r),
		.oIF_G(request2vramif_g),
		.oIF_B(request2vramif_b),
		.iIF_VALID(vramif2request_valid),
		.oIF_BUSY(request2vramif_busy),
		.iIF_DATA(vramif2request_data)
	);
	
	/****************************************************************
	Vram Interface Controller
	****************************************************************/
	gci_std_display_vram_interface VRAM_IF_CTRL(
		.iGCI_CLOCK(iGCI_CLOCK),
		.inRESET(inRESET),
		.iRESET_SYNC(1'b0),
		//IF0 (Priority IF0>IF1)
		.iIF0_REQ(vramread2vramif_req),
		.oIF0_ACK(vramif2vramread_ack),
		.iIF0_FINISH(vramread2vramif_finish),
		.iIF0_ENA(vramread2vramif_ena),
		.oIF0_BUSY(vramif2vramread_busy),
		.iIF0_RW(1'b0),
		.iIF0_ADDR(vramread2vramif_addr + P_VRAM_INDEX),
		.iIF0_DATA(32'h0),
		.oIF0_VALID(vramif2vramread_valid),
		.iIF0_BUSY(1'b0),
		.oIF0_DATA(vramif2vramread_data),
		//IF1
		.iIF1_REQ(request2vramif_req),
		.oIF1_ACK(vramif2request_ack),
		.iIF1_FINISH(request2vramif_finish),
		.oIF1_BREAK(vramif2request_break),
		.iIF1_ENA(request2vramif_ena),
		.oIF1_BUSY(vramif2request_busy),
		.iIF1_RW(request2vramif_rw),
		.iIF1_ADDR(request2vramif_addr + P_VRAM_INDEX),
		.iIF1_DATA(request2vramif_data),
		.oIF1_VALID(vramif2request_valid),
		.iIF1_BUSY(request2vramif_busy),
		.oIF1_DATA(vramif2request_data),
		//Vram Interface
		.oVRAM_ARBIT_REQ(oVRAM_ARBIT_REQ),
		.iVRAM_ARBIT_ACK(iVRAM_ARBIT_ACK),
		.oVRAM_ARBIT_FINISH(oVRAM_ARBIT_FINISH),
		.oVRAM_ENA(oVRAM_ENA),
		.iVRAM_BUSY(iVRAM_BUSY),
		.oVRAM_RW(oVRAM_RW),
		.oVRAM_ADDR(oVRAM_ADDR),
		.oVRAM_DATA(oVRAM_DATA),
		.iVRAM_VALID(iVRAM_VALID),
		.oVRAM_BUSY(oVRAM_BUSY),
		.iVRAM_DATA(iVRAM_DATAs)
	);
	
	/****************************************************************
	Display Data Read Controller
	****************************************************************/
	wire vramread2vramif_req;
	wire vramif2vramread_ack;
	wire vramread2vramif_finish;
	wire vramread2vramif_ena;
	wire vramif2vramread_busy;
	wire [P_MEM_ADDR_N-:0] vramread2vramif_addr;
	wire vramif2vramread_valid;
	wire [31:0] vramif2vramread_data;
	
	gci_std_display_data_read VRAM_READ_CTRL(
		.iGCI_CLOCK(iGCI_CLOCK),
		.iDISP_CLOCK(iDISP_CLOCK),
		.inRESET(inRESET),
		.iRESET_SYNC(iRESET_SYNC),
		//Read Request
		.iRD_ENA(disptiming_data_req),
		.iRD_SYNC(disptiming_data_sync),
		.oRD_VALID(),
		.oRD_DATA_R(oDISP_DATA_R),
		.oRD_DATA_G(oDISP_DATA_G),
		.oRD_DATA_B(oDISP_DATA_B),
		//Memory IF
		.oIF_REQ(vramread2vramif_req),
		.iIF_ACK(vramif2vramread_ack),
		.oIF_FINISH(vramread2vramif_finish),
		.oIF_ENA(vramread2vramif_ena),
		.iIF_BUSY(vramif2vramread_busy),
		.oIF_ADDR(vramread2vramif_addr),
		.iIF_VALID(vramif2vramread_valid),
		.iIF_DATA(vramif2vramread_data)
	);
	
	
	/****************************************************************
	Display Timing Generator
	****************************************************************/
	//Display timing 
	gci_std_display_timing_generator DISPLAY_TIMING(
		.iDISP_CLOCK(iDISP_CLOCK),
		.inRESET(inRESET),
		.iRESET_SYNC(1'b0),
		.oDATA_REQ(disptiming_data_req),
		.oDATA_SYNC(disptiming_data_sync),
		.onDISP_RESET(onDISP_RESET),
		.oDISP_ENA(oDISP_ENA),
		.oDISP_BLANK(oDISP_BLANK),
		.onDISP_VSYNC(onDISP_VSYNC),
		.onDISP_HSYNC(onDISP_HSYNC)
	);
	

	//Assign
	assign oDISP_CLOCK = iDISP_CLOCK;		
	assign oIF_WR_BUSY = bus_req_wait;
	

endmodule

	
`default_nettype wire

