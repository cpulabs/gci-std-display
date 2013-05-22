
`default_nettype none
//`include "gci_std_display_parameter.h"

module gci_std_display_display_controller #(
		parameter P_VRAM_SIZE = 307200,
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
		/*
		`ifdef GCI_STD_DISPLAY_SRAM
			//SRAM
			output wire onSRAM_CE,
			output wire onSRAM_WE,
			output wire onSRAM_OE,
			output wire onSRAM_UB,
			output wire onSRAM_LB,
			output wire [19:0] oSRAM_ADDR,
			inout wire [15:0] ioSRAM_DATA,
		`elsif GCI_STD_DISPLAY_SSRAM
			//SSRAM
			output wire oSSRAM_CLOCK,
			output wire onSSRAM_ADSC,
			output wire onSSRAM_ADSP,
			output wire onSSRAM_ADV,
			output wire onSSRAM_GW,
			output wire onSSRAM_OE,
			output wire onSSRAM_WE,
			output wire [3:0] onSSRAM_BE,
			output wire onSSRAM_CE1,
			output wire oSSRAM_CE2,
			output wire onSSRAM_CE3,
			output wire [18:0] oSSRAM_ADDR,
			inout wire [31:0] ioSSRAM_DATA,
			inout wire [3:0] ioSSRAM_PARITY,
		`endif
		*/
		
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
	
	wire register_busy_condition = 
	wire display_busy_condition = 
	wire sequence_busy_condition = 
	
	wire register_ctrl_condition = iIF_WR_ADDR <= 32'hF && (iIF_WR_ADDR == 32'h4)? !iIF_WR_RW : 1'b1;
	wire display_ctrl_condition = iIF_WR_ADDR > 32'hF;
	wire sequence_ctrl_condition = (iIF_WR_ADDR == 32'h4) && iIF_WR_RW;
	
	localparam P_L_MAIN_STT_WRITE = 1'b0;
	localparam P_L_MAIN_STT_READ_WAIT = 1'b1;
	
	
	reg b_main_state;
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_main_state <= P_L_MAIN_STT_WRITE;
		end
		else if(iRESET_SYNC)begin
			b_main_state <= P_L_MAIN_STT_WRITE;
		end
		else begin
			case(b_main_state)
				P_L_MAIN_STT_WRITE:
					begin
						if(!iIF_WR_RW)begin
							b_main_state <= P_L_MAIN_STT_READ_WAIT;
						end
					end
				P_L_MAIN_STT_READ_WAIT:
					begin
						if(!iIF_RD_BUSY && ())begin
							b_main_state <= P_L_MAIN_STT_WRITE;
						end
					end
			endcase
		end
	end
	
	
	assign oIF_WR_BUSY = (iIF_WR_RW)? ??? : 
	
	
	
	
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
		.oINFO_CHARACTER(),
		.oINFO_COLOR()
	);
	
	
	gci_std_display_command #(
		P_AREA_H,
		P_AREA_V,
		P_AREAA_HV_N,
		P_MEM_ADDR_N
	)COMMAND(
		.iCLOCK(),
		.inRESET(),
		//Register
		.iREG_MODE(), //[0]Bitmap | [1]Charactor
		//BUS
		.iIF_VALID(display_ctrl_condition && !display_busy_condition || sequence_ctrl_condition && !sequence_busy_condition),
		.iIF_SEQ(sequence_ctrl_condition),
		.oIF_BUSY(),
		.iIF_RW(),
		.iIF_ADDR(),
		.iIF_DATA(),
		//Output
		.oIF_VALID(),
		.iIF_BUSY(),
		.oIF_ADDR(),
		.oIF_DATA()
	);
	
	
	
	
	
	
	
endmodule

	
	
	
	
	
	
	
	
	
	
	
	
	

	//VRAM Write Command Controller 
	wire bus_req_wait;
	wire vram_write_req;
	wire [18:0] vram_write_addr;
	wire [15:0] vram_write_data;
	// VRAM Controll 
	wire vram_write_full;
	wire [9:0] vram2display_r, vram2display_g, vram2display_b;
	wire SramRw;
	//Display Timing
	wire disptiming_data_req;
	wire disptiming_data_sync;
	wire disptiming_vsync_n;
	wire disptiming_hsync_n;
	wire disptiming_reset_n;
	wire disptiming_enable;
	wire disptiming_blank;
	
	//VRAM Write Command Controller 
	gci_std_display_font_command FONT_CONTROLLER(
		.iCLOCK(iCLOCK),
		.inRESET(inRESET),
		.iBUSMOD_REQ(iIF_WR_REQ && !bus_req_wait),
		.iBUSMOD_ADDR(iIF_WR_ADDR),
		.iBUSMOD_DATA(iIF_WR_DATA),
		.oBUSMOD_WAIT(bus_req_wait),
		.iVRAM_WAIT(vram_write_full),
		.oVRAM_WRITE_REQ(vram_write_req),
		.oVRAM_WRITE_ADDR(vram_write_addr),
		.oVRAM_WRITE_DATA(vram_write_data)
	);

	//Vram Controll
	/*
	`ifdef GCI_STD_DISPLAY_SRAM
		gci_std_display_vram_controller_sram VRAM_CTRL_SRAM(
			.iGCI_CLOCK(iCLOCK),
			.iDISP_CLOCK(iDISP_CLOCK),
			.inRESET(inRESET),
			.iIF_WRITE_REQ(vram_write_req),
			.iIF_WRITE_ADDR({1'b0, vram_write_addr}),
			.iIF_WRITE_DATA(vram_write_data),
			.oIF_WRITE_FULL(vram_write_full),
			.iDISP_REQ(disptiming_data_req),
			.iDISP_SYNC(disptiming_data_sync),
			.oDISP_DATA_R(vram2display_r),
			.oDISP_DATA_G(vram2display_g),
			.oDISP_DATA_B(vram2display_b),
			.onSRAM_CE(onSRAM_CE),
			.onSRAM_WE(onSRAM_WE),
			.onSRAM_OE(onSRAM_OE),
			.onSRAM_UB(onSRAM_UB),
			.onSRAM_LB(onSRAM_LB),
			.oSRAM_ADDR(oSRAM_ADDR),
			.ioSRAM_DATA(ioSRAM_DATA)
		);
	`elsif GCI_STD_DISPLAY_SSRAM
		gci_std_display_vram_controller_ssram VRAM_CTRL_SSRAM(
			.iGCI_CLOCK(iCLOCK),
			.iDISP_CLOCK(iDISP_CLOCK),
			.inRESET(inRESET),
			.iRESET_SYNC(1'b0),
			.iIF_WRITE_REQ(vram_write_req),
			.iIF_WRITE_ADDR({1'b0, vram_write_addr}),
			.iIF_WRITE_DATA(vram_write_data),
			.oIF_WRITE_FULL(vram_write_full),
			.iDISP_REQ(disptiming_data_req),
			.iDISP_SYNC(disptiming_data_sync),
			.oDISP_DATA_R(vram2display_r),
			.oDISP_DATA_G(vram2display_g),
			.oDISP_DATA_B(vram2display_b),
			//Memory
			.oSSRAM_CLOCK(oSSRAM_CLOCK),
			.onSSRAM_ADSC(onSSRAM_ADSC),
			.onSSRAM_ADSP(onSSRAM_ADSP),
			.onSSRAM_ADV(onSSRAM_ADV),
			.onSSRAM_GW(onSSRAM_GW),
			.onSSRAM_OE(onSSRAM_OE),
			.onSSRAM_WE(onSSRAM_WE),
			.onSSRAM_BE(onSSRAM_BE),
			.onSSRAM_CE1(onSSRAM_CE1),
			.oSSRAM_CE2(oSSRAM_CE2),
			.onSSRAM_CE3(onSSRAM_CE3),
			.oSSRAM_ADDR(oSSRAM_ADDR),
			.ioSSRAM_DATA(ioSSRAM_DATA),
			.ioSSRAM_PARITY(ioSSRAM_PARITY)
		);
	`endif
	*/
	
	gci_std_display_vram_interface VRAM_IF_CTRL(
		.iGCI_CLOCK(iGCI_CLOCK),
		.inRESET(inRESET),
		.iRESET_SYNC(iRESET_SYNC),
		//IF0 (Priority IF0>IF1)
		.iIF0_REQ(vramread2vramif_req),
		.oIF0_ACK(vramif2vramread_ack),
		.iIF0_FINISH(vramread2vramif_finish),
		.iIF0_ENA(vramread2vramif_ena),
		.oIF0_BUSY(vramif2vramread_busy),
		.iIF0_RW(1'b0),
		.iIF0_ADDR(vramread2vramif_addr),
		.iIF0_DATA(32'h0),
		.oIF0_VALID(vramif2vramread_valid),
		.iIF0_BUSY(1'b0),
		.oIF0_DATA(vramif2vramread_data),
		//IF1
		.iIF1_REQ(),
		.oIF1_ACK(),
		.iIF1_FINISH(),
		.oIF1_BREAK(),
		.iIF1_ENA(),
		.oIF1_BUSY(),
		.iIF1_RW(),
		.iIF1_ADDR(),
		.iIF1_DATA(),
		.oIF1_VALID(),
		.iIF1_BUSY(),
		.oIF1_DATA(),
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
		.oRD_DATA_R(vram2display_r),
		.oRD_DATA_G(vram2display_g),
		.oRD_DATA_B(vram2display_b),
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
	
	
	
	//Display timing 
	gci_std_display_timing_generator DISPLAY_TIMING(
		.iDISP_CLOCK(iDISP_CLOCK),
		.inRESET(inRESET),
		.iRESET_SYNC(1'b0),
		.oDATA_REQ(disptiming_data_req),
		.oDATA_SYNC(disptiming_data_sync),
		.onDISP_RESET(disptiming_reset_n),
		.oDISP_ENA(disptiming_enable),
		.oDISP_BLANK(disptiming_blank),
		.onDISP_VSYNC(disptiming_vsync_n),
		.onDISP_HSYNC(disptiming_hsync_n)
	);
	
	
	//Display Output latch
	reg [9:0] b_disp_buff_r, b_disp_buff_g, b_disp_buff_b;
	reg bn_disp_buff_reset, b_disp_buff_ena, b_disp_buff_blank, bn_disp_buff_vsync, bn_disp_buff_hsync;
	
	always@(posedge iDISP_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_disp_buff_r <= 10'h0;
			b_disp_buff_g <= 10'h0;
			b_disp_buff_b <= 10'h0;
			bn_disp_buff_reset <= 1'b0;
			b_disp_buff_ena <= 1'b0;
			b_disp_buff_blank <= 1'b0;
			bn_disp_buff_vsync <= 1'b0;
			bn_disp_buff_hsync <= 1'b0;
		end
		else begin
			b_disp_buff_r <= vram2display_r;
			b_disp_buff_g <= vram2display_g;
			b_disp_buff_b <= vram2display_b;
			bn_disp_buff_reset <= disptiming_reset_n;
			b_disp_buff_ena <= disptiming_enable;
			b_disp_buff_blank <= disptiming_blank;
			bn_disp_buff_vsync <= disptiming_vsync_n;
			bn_disp_buff_hsync <= disptiming_hsync_n;
		end
	end
	
	//Assign
	assign oDISP_CLOCK = iDISP_CLOCK;		
	assign oIF_WR_BUSY = bus_req_wait;
	
	assign onDISP_RESET = bn_disp_buff_reset;
	assign oDISP_ENA = b_disp_buff_ena;
	assign oDISP_BLANK = b_disp_buff_blank;
	assign onDISP_HSYNC = bn_disp_buff_hsync;
	assign onDISP_VSYNC = bn_disp_buff_vsync;
	assign oDISP_DATA_R = b_disp_buff_r;
	assign oDISP_DATA_G = b_disp_buff_g;
	assign oDISP_DATA_B = b_disp_buff_b;
	
endmodule

`default_nettype wire

