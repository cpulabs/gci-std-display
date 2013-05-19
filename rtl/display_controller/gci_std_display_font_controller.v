
`default_nettype none


/****************************************************************************
Command (Address)
	0x0 ~ 0xFF					: Not Use
	0x100 ~ 0x2100				: Charactor Set (Use Data : ANSI Charactor = 7bit)
	0x3000						: Display Clear (Use Data : Collor 16bit = 5R6G5B)
****************************************************************************/


module gci_std_display_request_controller #(
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
		/*
		input wire iVRAM_WAIT,
		output wire oVRAM_WRITE_REQ,
		output wire [18:0] oVRAM_WRITE_ADDR,
		output wire [15:0] oVRAM_WRITE_DATA
		*/
		
		//New
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
	
	wire reqfifo_wr_full;
	wire reqfifo_rd_empty;
	
	gci_std_display_sync_fifo #(64, 16, 4) REQ_FIFO 
		.iCLOCK(iCLOCK),
		.inRESET(inRESET),
		.iREMOVE(1'b0),
		//Counter
		.oCOUNT(),
		//WR
		.iWR_EN(iBUSMOD_REQ && !reqfifo_wr_full),
		.iWR_DATA({iBUSMOD_ADDR, iBUSMOD_DATA}),
		.oWR_FULL(reqfifo_wr_full),
		.oWR_ALMOST_FULL(),
		//RD
		.iRD_EN(),
		.oRD_DATA(),
		.oRD_EMPTY(reqfifo_rd_empty),
		.oRD_ALMOST_EMPTY()
	);
	
	assign oBUSMOD_WAIT = reqfifo_wr_full;
	
	
	localparam P_L_MAIN_STT_IDLE = 2'h0;
	localparam P_L_MAIN_STT_IF_REQ = 2'h1;
	localparam P_L_MAIN_STT_IF_WORK = 2'h2;
	
	reg [1:0] b_main_state;
	
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
						if(iIF_BREAK || reqfifo_rd_empty)begin
							b_main_state <= P_L_MAIN_STT_IDLE;
						end
					end
				default:
					begin
						b_main_state <= P_L_MAIN_STT_IDLE;
					end
			endcase
		end
	end
	
	
	
	
	
	
	
	
	
	//Old
	
	localparam P_L_STT_IDLE = 2'h0;
	localparam P_L_STT_CHARACTOR = 2'h1;
	localparam P_L_STT_CLEAR = 2'h2;
	localparam P_L_STT_BITMAP = 2'h3;

	//Lock Controll
	wire state_lock = iVRAM_WAIT;
					
	//State Controller				
	reg [1:0] main_state;
	reg [6:0] sub_state;
	reg [13:0] req_addr;
	reg [15:0] req_data;
	reg [15:0] req_color;
	reg [15:0] req_back_color;
	reg [18:0] vram_addr;
	//Font ROM
	wire [111:0] font_rom_data;
	
	//State
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			main_state <= P_L_STT_IDLE;
			sub_state <= {7{1'b0}};
			req_addr <= {14{1'b0}};
			req_data <= {16{1'b0}};
			req_color <= {16{1'b0}};
			req_back_color <= {16{1'b0}};
			vram_addr <= {19{1'b0}};
		end
		else begin
			if(!state_lock)begin
				case(main_state)
					P_L_STT_IDLE : //Idle
						begin
							if(iBUSMOD_REQ)begin
								if(iBUSMOD_ADDR == 32'h00003000)begin
									main_state <= P_L_STT_CLEAR;
									req_data <= iBUSMOD_DATA[15:0];//iBUSMOD_DATA[11:0];
									vram_addr <= {19{1'b0}};
								end
								else if(iBUSMOD_ADDR >= 32'h00000100 && iBUSMOD_ADDR <= 32'h00002200)begin
									main_state <= P_L_STT_CHARACTOR;
									req_addr <= iBUSMOD_ADDR[13:0] - 13'h0100;
									req_data <= {9'h00, iBUSMOD_DATA[6:0]};	
									req_color <= {/*G*/iBUSMOD_DATA[19:16], iBUSMOD_DATA[16], /*G*/iBUSMOD_DATA[15:12], iBUSMOD_DATA[12], iBUSMOD_DATA[12], /*B*/iBUSMOD_DATA[11:8], iBUSMOD_DATA[8]};//iBUSMOD_DATA[19:8];
									req_back_color <= {/*G*/iBUSMOD_DATA[31:28], iBUSMOD_DATA[28], /*G*/iBUSMOD_DATA[27:24], iBUSMOD_DATA[24], iBUSMOD_DATA[24], /*B*/iBUSMOD_DATA[23:20], iBUSMOD_DATA[20]};//iBUSMOD_DATA[31:20];
									vram_addr <= req_addr[13:8] * (640 * 14) + (sub_state/8)*640 + req_addr[7:0]*8 + sub_state[2:0];
								end
								else if(iBUSMOD_ADDR >= 32'h00003100 && iBUSMOD_ADDR <= 32'h0004E199)begin
									main_state <= P_L_STT_BITMAP;
									req_data <= iBUSMOD_DATA[15:0];
									vram_addr <= iBUSMOD_ADDR - 32'h00003100;
								end
							end
							sub_state <= {7{1'b0}};
						end
					P_L_STT_CHARACTOR : //CharactorOut
						begin
							if(sub_state < 7'd112)begin
								sub_state <= sub_state + 7'h01;
								vram_addr <= req_addr[13:8] * (640 * 14) + (sub_state/8)*640 + req_addr[7:0]*8 + sub_state[2:0];
							end
							else begin
								main_state <= P_L_STT_IDLE;
							end
						end
					P_L_STT_CLEAR : //DisplayClear
						begin
							if(vram_addr < 19'h4B000)begin
								vram_addr <= vram_addr + 19'h00001;
							end 
							else begin
								main_state <= P_L_STT_IDLE;
							end
						end
					P_L_STT_BITMAP : //Bitmap
						begin
							main_state <= P_L_STT_IDLE;
						end
				endcase	
			end
		end
	end //always
	
	//Font ROM
	gci_std_display_font FONT(
		.iADDR(req_data[6:0]),
		.oDATA(font_rom_data)
	);
	
	//Assignment Module Output
	assign oBUSMOD_WAIT = state_lock || (main_state != 2'h0);
	assign oVRAM_WRITE_REQ = !state_lock && (main_state != 2'h0);
	assign oVRAM_WRITE_ADDR = vram_addr;
	assign oVRAM_WRITE_DATA = (main_state == P_L_STT_CLEAR || main_state == P_L_STT_BITMAP)? req_data : ((font_rom_data[7'd111 - sub_state + 7'h01])? req_color : req_back_color);


endmodule


`default_nettype wire
				