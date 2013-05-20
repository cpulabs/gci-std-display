
`default_nettype none

module gci_std_display_clear #(
		//Area
		parameter P_AREA_H = 640,
		parameter P_AREA_V = 480,
		parameter P_AREAA_HV_N = 19,
		parameter P_MEM_ADDR_N = 23
	)(
		input wire iCLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,
		//Req
		input wire iIF_VALID,
		output wire oIF_BUSY,
		input wire [31:0] iIF_DATA,
		//Out
		output wire oIF_FINISH,
		output wire oIF_VALID,
		input wire iIF_BUSY,
		output wire [P_MEM_ADDR_N-1:0] oIF_ADDR,
		output wire [23:0] oIF_DATA
	);
	
	/********************************************
	Display Clear 
	********************************************/
	localparam P_L_CLEAR_STT_IDLE = 2'h0;
	localparam P_L_CLEAR_STT_CLEAR = 2'h1;
	localparam P_L_CLEAR_STT_END = 2'h2;
	
	reg [1:0] b_clear_state;
	reg [7:0] b_clear_color_r;
	reg [7:0] b_clear_color_g;
	reg [7:0] b_clear_color_b;
	reg [P_AREAA_HV_N-1:0] b_clear_counter;
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_clear_state <= P_L_CLEAR_STT_IDLE;
			b_clear_color_r <= 8'h0;
			b_clear_color_g <= 8'h0;
			b_clear_color_b <= 8'h0;
		end
		else if(iRESET_SYNC)begin
			b_clear_state <= P_L_CLEAR_STT_IDLE;
			b_clear_color_r <= 8'h0;
			b_clear_color_g <= 8'h0;
			b_clear_color_b <= 8'h0;
		end
		else begin
			case(b_clear_state)
				P_L_CLEAR_STT_IDLE:
					begin
						if(iIF_VALID)begin
							b_clear_state <= P_L_CLEAR_STT_CLEAR;
							{b_clear_color_r, 
							b_clear_color_g,
							b_clear_color_b} <= iIF_DATA[23:0];
						end
					end
				P_L_CLEAR_STT_CLEAR:
					begin
						if(b_clear_counter == (P_AREA_H*P_AREA_V))begin
							b_clear_state <= P_L_CLEAR_STT_END;
						end
					end
				P_L_CLEAR_STT_END:
					begin
						b_clear_state <= P_L_CLEAR_STT_IDLE;
					end
				default:
					begin
						b_clear_state <= P_L_CLEAR_STT_IDLE;
					end
			endcase
		end
	end
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_clear_counter <= {P_AREAA_HV_N{1'b0}};
		end
		else if(iRESET_SYNC)begin
			b_clear_counter <= {P_AREAA_HV_N{1'b0}};
		end
		else begin
			if(b_clear_state == P_L_CLEAR_STT_CLEAR)begin
				if(!iIF_BUSY)begin
					b_clear_counter <= b_clear_counter + {{P_AREAA_HV_N-1{1'b0}}, 1'b1};
				end
			end
			else begin
				b_clear_counter <= {P_AREAA_HV_N{1'b0}};
			end
		end
	end
	
	assign oIF_BUSY = b_clear_state != P_L_CLEAR_STT_IDLE;
	
	assign oIF_FINISH = b_clear_state == P_L_CLEAR_STT_END;
	assign oIF_VALID = !iIF_BUSY && (b_clear_state == P_L_CLEAR_STT_CLEAR);
	assign oIF_ADDR = b_clear_counter;
	assign oIF_DATA = {b_clear_color_r, b_clear_color_g, b_clear_color_b};

endmodule

`default_nettype wire
