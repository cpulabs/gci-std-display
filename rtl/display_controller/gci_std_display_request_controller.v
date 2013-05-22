
`default_nettype none


/****************************************************************************
Command (Address)
	0x0 ~ 0xFF					: Not Use
	0x100 ~ 0x2100				: Charactor Set (Use Data : ANSI Charactor = 7bit)
	0x3000						: Display Clear (Use Data : Collor 16bit = 5R6G5B)
****************************************************************************/


module gci_std_display_request_controller #(
		parameter P_AREA_H = 640,
		parameter P_AREA_V = 480,
		parameter P_AREAA_HV_N = 19,
		parameter P_MEM_ADDR_N = 23
	)(
		input wire iCLOCK,
		input wire inRESET,
		//BUS
		input wire iBUSMOD_REQ,
		input wire [31:0] iBUSMOD_ADDR,
		input wire [31:0] iBUSMOD_DATA,
		output wire oBUSMOD_WAIT,
		//VRAM
		output wire oBUS_VALID,
		output wire [31:0] oBUS_DATA, 
		//New
		output wire oIF_REQ,
		input wire iIF_ACK,
		output wire oIF_FINISH,
		input wire iIF_BREAK,
		input wire iIF_BUSY,
		output wire oIF_ENA,
		output wire oIF_RW,
		output wire [P_MEM_ADDR_N-1:0] oIF_ADDR,
		output wire [7:0] oIF_R,
		output wire [7:0] oIF_G,
		output wire [7:0] oIF_B,
		input wire iIF_VALID,
		input wire [31:0] iIF_DATA
	);
	
	
	
	
	
	
	assign oBUSMOD_WAIT = reqfifo_wr_full;
	
	wire request_break_condition = iIF_BREAK || reqfifo_rd_empty;
	wire reqfifo_read_condition = 
	
	
	localparam P_L_MAIN_STT_IDLE = 3'h0;
	localparam P_L_MAIN_STT_IF_REQ = 3'h1;
	localparam P_L_MAIN_STT_IF_WORK = 3'h2;
	localparam P_L_MAIN_STT_IF_READ_WAIT = 3'h3;
	localparam P_L_MAIN_STT_IF_END = 3'h4;
	
	reg [2:0] b_main_state;
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_main_state <= P_L_MAIN_STT_IDLE;
		end
		else begin
			case(b_main_state)
				P_L_MAIN_STT_IDLE:
					begin
						if(!reqfifo_rd_empty)begin
							b_main_state <= P_L_MAIN_STT_IF_REQ;
						end
					end
				P_L_MAIN_STT_IF_REQ:
					begin
						if(iIF_ACK)begin
							b_main_state <= P_L_MAIN_STT_IF_WORK;
						end
					end
				P_L_MAIN_STT_IF_WORK:
					begin
						if(request_break_condition)begin
							b_main_state <= P_L_MAIN_STT_IF_END;
						end
						else if(reqfifo_rd_rw)begin
							b_main_state <= P_L_MAIN_STT_IF_WRITE;
						end
						else begin
							b_main_state <= P_L_MAIN_STT_IF_READ;
						end
					end
				P_L_MAIN_STT_IF_READ_WAIT:
					begin
						if(iIF_VALID)begin
							if(request_break_condition)begin
								b_main_state <= P_L_MAIN_STT_IF_END;
							end
							else if(reqfifo_rd_rw)begin
								b_main_state <= P_L_MAIN_STT_IF_WRITE;
							end
							else begin
								b_main_state <= P_L_MAIN_STT_IF_READ;
							end
						end
					end
				P_L_MAIN_STT_IF_END:
					begin
						b_main_state <= P_L_MAIN_STT_IDLE;
					end
				default:
					begin
						b_main_state <= P_L_MAIN_STT_IDLE;
					end
			endcase
		end
	end //main(vram-interface) state always
	
	
　
endmodule


`default_nettype wire
				