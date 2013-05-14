
`default_nettype none

module gci_std_display_vram_interface #(
		parameter P_MEM_ADDR_N = 19
	)(
		input wire iGCI_CLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,
		//IF0 (Priority IF0>IF1)
		input wire iIF0_REQ,
		output wire oIF0_ACK,
		input wire iIF0_FINISH,
		input wire iIF0_ENA,
		output wire oIF0_BUSY,
		input wire iIF0_RW,
		input wire [P_MEM_ADDR_N-1:0] iIF0_ADDR,
		input wire [31:0] iIF0_DATA,
		output wire oIF0_VALID,
		input wire iIF0_BUSY,
		output wire [31:0] oIF0_DATA,
		//IF1
		input wire iIF1_REQ,
		output wire oIF1_ACK,
		input wire iIF1_FINISH,
		output wire oIF1_BREAK,
		input wire iIF1_ENA,
		output wire oIF1_BUSY,
		input wire iIF1_RW,
		input wire [P_MEM_ADDR_N-1:0] iIF1_ADDR,
		input wire [31:0] iIF1_DATA,
		output wire oIF1_VALID,
		input wire iIF1_BUSY,
		output wire [31:0] oIF1_DATA,
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
		input wire [31:0] iVRAM_DATA
	);
	
	//Main State
	parameter P_L_MAIN_STT_IDLE = 2'h0;
	parameter P_L_MAIN_STT_REQ = 2'h1;
	parameter P_L_MAIN_STT_IF0 = 2'h2;
	parameter P_L_MAIN_STT_IF1 = 2'h3;
	
	
	//Main State
	reg [1:0] b_main_state;
	reg [1:0] b_main_if_select;
	//IF 2 Memory
	reg b_if2vram_req;
	reg b_if2vram_finish;
	reg b_if2vram_ena;
	reg b_if2vram_rw;
	reg [P_MEM_ADDR_N-1:0] b_if2vram_addr;
	reg [31:0] b_if2vram_data;
	reg b_if2vram_busy;
	//Memory 2 IF0
	reg b_vram2if0_ack;
	reg b_vram2if0_busy;
	reg b_vram2if0_valid;
	reg [31:0] b_vram2if0_data;	
	//Memory 2 IF1
	reg b_vram2if1_ack;
	reg b_vram2if1_busy;
	reg b_vram2if1_valid;
	reg [31:0] b_vram2if1_data;
	//IF0 Pryority
	reg b_if0_break;
	
	/***************************************************
	State
	***************************************************/
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_main_state <= P_L_MAIN_STT_IDLE;
			b_main_if_select <= P_L_PARAM_STT_IDLE;
		end
		else if(iRESET_SYNC)begin
			b_main_state <= P_L_PARAM_STT_IDLE;
			b_main_if_select <= P_L_PARAM_STT_IDLE;
		end
		else begin
			case(b_main_state)
				P_L_MAIN_STT_IDLE:
					begin			
						if(iIF0_REQ)begin
							b_main_state <= P_L_MAIN_STT_REQ;
							b_main_if_select <= P_L_MAIN_STT_IF0;
						end
						else if(iIF1_REQ)begin
							b_main_state <= P_L_MAIN_STT_REQ;
							b_main_if_select <= P_L_MAIN_STT_IF1;
						end
					end
				P_L_MAIN_STT_REQ:
					begin
						if(iVRAM_ARBIT_ACK)begin
							b_main_state <= b_main_if_select;
						end
					end
				P_L_MAIN_STT_IF0:
					begin
						if(iIF0_FINISH)begin
							b_main_state <= P_L_MAIN_STT_IDLE;
						end
					end
				P_L_MAIN_STT_IF1:
					begin
						if(iIF1_FINISH)begin
							b_main_state <= P_L_MAIN_STT_IDLE;
						end
					end
				default:
					begin
						b_main_state <= P_L_MAIN_STT_IDLE;
					end
			endcase
		end
	end //main state
	
	
	//IF 2 Memory
	always@(posedge iGCI_CLOCK or negedge inRESET)begin	
		if(!inRESET)begin			
			b_if2vram_req <= 1'b0;
			b_if2vram_finish <= 1'b0;
			b_if2vram_ena <= 1'b0;
			b_if2vram_rw <= 1'b0;
			b_if2vram_addr <= {P_MEM_ADDR_N{1'b0}};
			b_if2vram_data <= 32'h0;
			b_if2vram_busy <= 1'b0;
		end
		else if(iRESET_SYNC)begin
			b_if2vram_req <= 1'b0;
			b_if2vram_finish <= 1'b0;
			b_if2vram_ena <= 1'b0;
			b_if2vram_rw <= 1'b0;
			b_if2vram_addr <= {P_MEM_ADDR_N{1'b0}};
			b_if2vram_data <= 32'h0;
			b_if2vram_busy <= 1'b0;
		end
		else begin
			if(b_main_state == P_L_MAIN_STT_IF0)begin
				b_if2vram_req <= iIF0_REQ;
				b_if2vram_finish <= iIF0_FINISH;
				b_if2vram_ena <= iIF0_ENA;
				b_if2vram_rw <= iIF0_RW;
				b_if2vram_addr <= iIF0_ADDR;
				b_if2vram_data <= iIF0_DATA;
				b_if2vram_busy <= iIF0_BUSY;
			end
			else if(b_main_state == P_L_MAIN_STT_IF1)begin
				b_if2vram_req <= iIF1_REQ;
				b_if2vram_finish <= iIF1_FINISH;
				b_if2vram_ena <= iIF1_ENA;
				b_if2vram_rw <= iIF1_RW;
				b_if2vram_addr <= iIF1_ADDR;
				b_if2vram_data <= iIF1_DATA;
				b_if2vram_busy <= iIF1_BUSY;
			end
			else begin
				b_if2vram_req <= 1'b0;
				b_if2vram_finish <= 1'b0;
				b_if2vram_ena <= 1'b0;
				b_if2vram_rw <= 1'b0;
				b_if2vram_addr <= {P_MEM_ADDR_N{1'b0}};
				b_if2vram_busy <= 1'b0;
				b_if2vram_data <= 32'h0;
				b_if2vram_busy <= 1'b0;
			end
		end
	end //Output buffer alwyas
	
	
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_vram2if0_ack <= 1'b0;
			b_vram2if0_busy <= 1'b0;
			b_vram2if0_valid <= 1'b0;
			b_vram2if0_data <= 32'h0;
		end
		else if(iRESET_SYNC)begin
			b_vram2if0_ack <= 1'b0;
			b_vram2if0_busy <= 1'b0;
			b_vram2if0_valid <= 1'b0;
			b_vram2if0_data <= 32'h0;
		end
		else begin
			if(b_main_state == P_L_MAIN_STT_IF0)begin
				b_vram2if0_ack <= iVRAM_ARBIT_ACK;
				b_vram2if0_busy <= iVRAM_BUSY;
				b_vram2if0_valid <= iVRAM_VALID;
				b_vram2if0_data <= iVRAM_DATA;
			end
			else begin
				b_vram2if0_ack <= 1'b0;
				b_vram2if0_busy <= 1'b0;
				b_vram2if0_valid <= 1'b0;
				b_vram2if0_data <= 32'h0;
			end
		end
	end
	

	
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_vram2if1_ack <= 1'b0;
			b_vram2if1_busy <= 1'b0;
			b_vram2if1_valid <= 1'b0;
			b_vram2if1_data <= 32'h0;
		end
		else if(iRESET_SYNC)begin
			b_vram2if1_ack <= 1'b0;
			b_vram2if1_busy <= 1'b0;
			b_vram2if1_valid <= 1'b0;
			b_vram2if1_data <= 32'h0;
		end
		else begin
			if(b_main_state == P_L_MAIN_STT_IF1)begin
				b_vram2if1_ack <= iVRAM_ARBIT_ACK;
				b_vram2if1_busy <= iVRAM_BUSY;
				b_vram2if1_valid <= iVRAM_VALID;
				b_vram2if1_data <= iVRAM_DATA;
			end
			else begin
				b_vram2if1_ack <= 1'b0;
				b_vram2if1_busy <= 1'b0;
				b_vram2if1_valid <= 1'b0;
				b_vram2if1_data <= 32'h0;
			end
		end
	end
	
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_if0_break <= 1'b0;
		end
		else if(iRESET_SYNC)begin
			b_if0_break <= 1'b0;
		end
		else begin
			b_if0_break <= (b_main_state == P_L_MAIN_STT_IF1) && iIF0_REQ;
		end
	end //Pryority
	
	
	
	assign oVRAM_ARBIT_REQ = b_if2vram_req;
	assign oVRAM_ARBIT_FINISH = b_if2vram_finish;
	assign oVRAM_ENA = b_if2vram_ena;
	assign oVRAM_RW = b_if2vram_rw;
	assign oVRAM_ADDR = b_if2vram_addr;
	assign oVRAM_DATA = b_if2vram_data;
	assign oVRAM_BUSY = b_if2vram_busy;
		
	assign oIF0_ACK = b_vram2if0_ack;
	assign oIF0_BUSY = b_vram2if0_busy;
	assign oIF0_VALID = b_vram2if0_valid;
	assign oIF0_DATA = b_vram2if0_data;

	assign oIF1_ACK = b_vram2if1_ack;
	assign oIF1_BREAK = b_if0_break;
	assign oIF1_BUSY = b_vram2if1_busy;
	assign oIF1_VALID = b_vram2if1_valid;
	assign oIF1_DATA = b_vram2if1_data;
	
	
endmodule

`default_nettype wire
