


`default_nettype none

module gci_std_display_vram_interface #(
		parameter P_AREA_H = 640,
		parameter P_AREA_Y = 480
	)(
		input wire iCLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,
		//Read Request
		input wire iRD_ENA,
		input wire iRD_SYNC,
		output wire oRD_VALID,
		output wire [15:0] oRD_DATA,
		//Memory IF
		input wire iIF_ENA,
		output wire oIF_BUSY,
		input wire iIF_RW,
		input wire [18:0] iIF_ADDR,
		input wire [15:0] iIF_DATA,
		output wire oIF_VALID,
		output wire [31:0] oIF_DATA
	);


	/***************************************************
	Output FIFO
	***************************************************/
	wire [31:0] vramfifo1_data;
	wire vramfifo0_full;
	wire vramfifo1_empty;
	gci_std_sync_fifo #(32, 32, 5) VRAMREAD_FIFO0(
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
	gci_std_async_fifo #(32, 32, 5) VRAMREAD_FIFO1(
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
