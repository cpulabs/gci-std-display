
`default_nettype none

module gci_std_display_vram_interface #(
		parameter P_AREA_H = 640,
		parameter P_AREA_Y = 480
	)(
		input wire iCLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,
		//User IF 
		input wire iIF_ENA,
		output wire oIF_BUSY,
		input wire iIF_RW,
		input wire [18:0] iIF_ADDR,
		input wire [15:0] iIF_DATA,
		output wire oIF_VALID,
		output wire [31:0] oIF_DATA,
		//Read IF
		input wire iRD_ENA,
		input wire iRD_SYNC,
		output wire oRD_VALID,
		output wire [15:0] oRD_DATA,
		//Vram Interface
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
	);
	
	/***************************************************
	Input FIFO
	***************************************************/
	gci_std_sync_fifo #(36, 64, 6) VRAMWRITE_FIFO(
		.inRESET(inRESET),
		.iCLOCK(iGCI_CLOCK),
		.iREMOVE(iRESET_SYNC),
		.oCOUNT(),
		.iWR_EN(iIF_WRITE_REQ),
		.iWR_DATA({iIF_RW, iIF_ADDR, iIF_DATA}),
		.oWR_FULL(oIF_WRITE_FULL),
		.iRD_EN(vram_write_sequence_condition),
		.oRD_DATA({writefifo_addr, writefifo_data}),
		.oRD_EMPTY(writefifo_empty),
		.oRD_ALMOST_EMPTY()
	);
	
	
	/***************************************************
	State
	***************************************************/
	//Main State
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin	
			b_main_state <= P_L_MAIN_STT_IDLE;
			b_main_job_start <= 1'b0;
		end
		else if(iRESET_SYNC)begin
			b_main_state <= P_L_MAIN_STT_IDLE;
			b_main_job_start <= 1'b0;
		end
		else begin
			case(b_main_state)
				P_L_MAIN_STT_IDLE:
					begin
						if(vramfifo0_empty)begin
							b_main_state <= P_L_MAIN_STT_READ;
							b_main_job_start <= 1'b1;
						end
						else if(!writefifo_empty)begin
							b_main_state <= P_L_MAIN_STT_WRITE;
							b_main_job_start <= 1'b1;
						end
						else begin
							b_main_job_start <= 1'b0;
						end
					end
				P_L_MAIN_STT_READ:
					begin
						b_main_job_start <= 1'b0;
						if(b_read_finish)begin
							b_main_state <= P_L_MAIN_STT_IDLE;
						end
					end
				P_L_MAIN_STT_WRITE:
					begin
						b_main_job_start <= 1'b0;
						if(b_write_finish)begin
							b_main_state <= P_L_MAIN_STT_IDLE;
						end
					end
				default:
					begin
						b_main_job_start <= 1'b0;
						b_main_state <= P_L_MAIN_STT_IDLE;
					end
			endcase			
		end
	end //main state
	
	
	localparam P_L_VRAM_IF_IDLE = 2'h0;
	localparam P_L_VRAM_IF_REQ = 2'h1;
	localparam P_L_VRAM_IF_WORK = 2'h2;
	
	reg [1:0] b_vram_if_state;
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_vram_if_state <= P_L_VRAM_IF_IDLE;
		end
		else if(!iRESET_SYNC)begin
			b_vram_if_state <= P_L_VRAM_IF_IDLE;
		end
		else begin
			case(b_vram_if_state)
				P_L_VRAM_IF_IDLE:
					begin
						if()begin
							b_vram_if_state <= P_L_VRAM_IF_REQ;
						end
					end
				P_L_VRAM_IF_REQ:
					begin
						if(iVRAM_ARBIT_ACK)begin
							b_vram_if_state <= P_L_VRAM_IF_WORK;
						end
					end
				P_L_VRAM_IF_WORK:
					begin
						//
					end
				default:
					begin
						b_vram_if_state <= P_L_VRAM_IF_IDLE;
					end
			endcase
		end
	end
	
	
	/***************************************************
	Output FIFO
	***************************************************/
	wire [31:0] vramfifo1_data;
	wire vramfifo0_full;
	wire vramfifo1_empty;
	gci_std_sync_fifo #(32, P_READ_SYNC_FIFO_DEPTH, P_READ_SYNC_FIFO_DEPTH_N) VRAMREAD_FIFO0(
		.inRESET(inRESET),
		.iREMOVE(iRESET_SYNC),
		.iCLOCK(iGCI_CLOCK),
		.iWR_EN(b_get_data_valid && !vramfifo0_full),
		.iWR_DATA(ioSSRAM_DATA),
		.oWR_FULL(vramfifo0_full),
		.oWR_ALMOST_FULL(vramfifo0_almost_full),
		.iRD_EN(!vramfifo0_empty && !vramfifo1_full),
		.oRD_DATA(vramfifo0_data),
		.oRD_EMPTY(vramfifo0_empty)
	);
	gci_std_async_fifo #(32, P_READ_ASYNC_FIFO_DEPTH, P_READ_ASYNC_FIFO_DEPTH_N) VRAMREAD_FIFO1(
		.inRESET(inRESET),
		.iREMOVE(iRESET_SYNC),
		.iWR_CLOCK(iGCI_CLOCK),
		.iWR_EN(!vramfifo0_empty && !vramfifo1_full),
		.iWR_DATA(vramfifo0_data),
		.oWR_FULL(vramfifo1_full),
		.iRD_CLOCK(iDISP_CLOCK),
		.iRD_EN(!vramfifo1_empty && b_dispout_state == P_L_DISPOUT_STT_1ST),
		.oRD_DATA(vramfifo1_data),
		.oRD_EMPTY(vramfifo1_empty)
	);
	
	
	parameter P_L_DISPOUT_STT_1ST = 1'b0;
	parameter P_L_DISPOUT_STT_2RD = 1'b1;
	
	reg b_dispout_state;
	reg [15:0] b_dispout_current_data;
	reg [15:0] b_dispout_next_data;
	
	always@(posedge iDISP_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_dispout_state <= P_L_DISPOUT_STT_1ST;
			b_dispout_current_data <= 16'h0;
			b_dispout_next_data <= 16'h0;
		end
		else if(iRESET_SYNC)begin
			b_dispout_state <= P_L_DISPOUT_STT_1ST;
			b_dispout_current_data <= 16'h0;
			b_dispout_next_data <= 16'h0;
		end
		else begin
			case(b_dispout_state)
				P_L_DISPOUT_STT_1ST:
					begin
						if(!vramfifo1_empty)begin
							{b_dispout_next_data, b_dispout_current_data} <= vramfifo1_data;
							b_dispout_state <= P_L_DISPOUT_STT_2RD;
						end
					end
				P_L_DISPOUT_STT_2RD:
					begin
						if(iDISP_REQ)begin
							b_dispout_current_data <= b_dispout_next_data;
							b_dispout_state <= P_L_DISPOUT_STT_1ST;
						end
					end
			endcase
		end
	end
	
	
	
endmodule

`default_nettype wire
