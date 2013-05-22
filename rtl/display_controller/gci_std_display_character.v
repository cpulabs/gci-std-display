
`default_nettype none

module gci_std_display_character #(
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
		input wire [13:0] iIF_ADDR,	//Charactor Addr
		input wire [31:0] iIF_DATA,
		//Out
		output wire oIF_FINISH,
		output wire oIF_VALID,
		input wire iIF_BUSY,
		output wire [P_MEM_ADDR_N-1:0] oIF_ADDR,
		output wire [23:0] oIF_DATA
	);
	
	/********************************************
	Charactor Output
	********************************************/
	localparam P_L_CHARACT_STT_IDLE = 2'h0;
	localparam P_L_CHARACT_STT_OUT = 2'h1;
	localparam P_L_CHARACT_STT_END = 2'h2;
	
	reg [1:0] b_charact_state;
	reg [7:0] b_charact_font_color_r;
	reg [7:0] b_charact_font_color_g;
	reg [7:0] b_charact_font_color_b;
	reg [7:0] b_charact_back_color_r;
	reg [7:0] b_charact_back_color_g;
	reg [7:0] b_charact_back_color_b;
	reg [13:0] b_charact_base_addr;
	reg [6:0] b_charact_font;
	
	reg [P_AREAA_HV_N-1:0] b_charact_counter;
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_charact_state <= P_L_CHARACT_STT_IDLE;
			b_charact_font_color_r <= 8'h0;
			b_charact_font_color_g <= 8'h0;
			b_charact_font_color_b <= 8'h0;
			b_charact_back_color_r <= 8'h0;
			b_charact_back_color_g <= 8'h0;
			b_charact_back_color_b <= 8'h0;
			b_charact_base_addr <= 14'h0;
			b_charact_font <= 7'h0;
		end
		else if(iRESET_SYNC)begin
			b_charact_state <= P_L_CHARACT_STT_IDLE;
			b_charact_font_color_r <= 8'h0;
			b_charact_font_color_g <= 8'h0;
			b_charact_font_color_b <= 8'h0;
			b_charact_back_color_r <= 8'h0;
			b_charact_back_color_g <= 8'h0;
			b_charact_back_color_b <= 8'h0;
			b_charact_base_addr <= 14'h0;
			b_charact_font <= 7'h0;
		end
		else begin
			case(b_charact_state)
				P_L_CHARACT_STT_IDLE:
					begin
						if(iIF_VALID)begin
							b_charact_state <= P_L_CHARACT_STT_OUT;
							{b_charact_font_color_r,
							b_charact_font_color_g,
							b_charact_font_color_b} <= {iIF_DATA[19:16], iIF_DATA[16], iIF_DATA[15:12], {2{iIF_DATA[12]}}, iIF_DATA[11:8], iIF_DATA[8]};//iBUSMOD_DATA[19:8];
							{b_charact_back_color_r,
							b_charact_back_color_g,
							b_charact_back_color_b} <= {iIF_DATA[31:28], iIF_DATA[28], iIF_DATA[27:24], {2{iIF_DATA[24]}}, iIF_DATA[23:20], iIF_DATA[20]};//iBUSMOD_DATA[31:20];
							b_charact_base_addr <= iIF_ADDR;
							b_charact_font <= iIF_DATA[6:0];	
						end
					end
				P_L_CHARACT_STT_OUT:
					begin
						if(b_charact_counter == 7'd112)begin
							b_charact_state <= P_L_CHARACT_STT_END;
						end
					end
				P_L_CHARACT_STT_END:
					begin
						b_charact_state <= P_L_CLEAR_STT_IDLE;
					end
				default:
					begin
						b_charact_state <= P_L_CLEAR_STT_IDLE;
					end
			endcase
		end
	end
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_charact_counter <= 7'h0;
		end
		else if(iRESET_SYNC)begin
			b_charact_counter <= 7'h0;
		end
		else begin
			if(b_charact_state == P_L_CHARACT_STT_OUT)begin
				if(!iIF_BUSY)begin
					b_charact_counter <= b_charact_counter + 7'h1;
				end
			end
			else begin
				b_charact_counter <= 7'h0;
			end
		end
	end
	
	//Font ROM
	wire [111:0] font_rom_data;
	gci_std_display_font FONT14X8(
		.iADDR(b_charact_font),
		.oDATA(font_rom_data)
	);
	
	
	assign oIF_BUSY = b_charact_state != P_L_CHARACT_STT_IDLE;
	
	assign oIF_FINISH = b_charact_state == P_L_CHARACT_STT_END;
	assign oIF_VALID = !iIF_BUSY && (b_clear_state == P_L_CLEAR_STT_CLEAR || b_charact_state == P_L_CHARACT_STT_OUT);
	assign oIF_ADDR = charact_addr = b_charact_base_addr[13:8]*(640*14) + (b_charact_counter/8)*640 + b_charact_base_addr[7:0]*8 + b_charact_counter[2:0];;
	assign oIF_DATA = ((font_rom_data[7'd111 - b_charact_counter + 7'h01])? (
			{b_charact_font_color_r, b_charact_font_color_g, b_charact_font_color_b} : 
			{b_charact_back_color_r, b_charact_back_color_g, b_charact_back_color_b}
		);
	
endmodule

`default_nettype wire
