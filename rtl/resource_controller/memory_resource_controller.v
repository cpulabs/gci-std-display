
`default_netype none


module memory_resource_controller #(
		parameter P_MEM_ADDR_N = 22
	)(
		input wire iCLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,
		//IF0
		input wire iIF0_ARBIT_REQ,
		output wire oIF0_ARBIT_ACK,
		input wire iIF0_ARBIT_FINISH,
		input wire iIF0_ENA,
		output wire oIF0_BUSY,
		input wire iIF0_RW,
		input wire [P_MEM_ADDR_N-1:0] iIF0_ADDR,
		input wire [31:0] iIF0_DATA,
		output wire oIF0_VALID,
		input wire iIF0_BUSY,
		output wire [31:0] oIF0_DATA,
		//IF1
		input wire iIF1_ARBIT_REQ,
		output wire oIF1_ARBIT_ACK,
		input wire iIF1_ARBIT_FINISH,
		input wire iIF1_ENA,
		output wire oIF1_BUSY,
		input wire iIF1_RW,
		input wire [P_MEM_ADDR_N-1:0] iIF1_ADDR,
		input wire [31:0] iIF1_DATA,
		output wire oIF1_VALID,
		input wire iIF1_BUSY,
		output wire [31:0] oIF1_DATA,
		//Memory Controller
		output wire oMEM_ENA,
		input wire iMEM_BUSY,
		output wire oMEM_RW,
		output wire [P_MEM_ADDR_N-1:0] oMEM_ADDR,
		output wire [31:0] oMEM_DATA,
		input wire iMEM_VALID,
		output wire oMEM_BUSY,
		input wire [31:0] iMEM_DATA
	);
	
	localparam L_PARAM_STT_IDLE = 2'h0;
	localparam L_PARAM_STT_ACK = 2'h1;
	localparam L_PARAM_STT_WORK = 2'h2;
	
	reg [1:0] b_state;
	reg b_authority;
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_state <= L_PARAM_STT_IDLE;
		end
		else if(iRESET_SYNC)begin
			b_state <= L_PARAM_STT_IDLE;
		end
		else begin
			case(b_state)
				L_PARAM_STT_IDLE:
					begin
						if(iIF0_ARBIT_REQ || iIF1_ARBIT_REQ)begin
							b_state <= L_PARAM_STT_ACK;
						end
					end
				L_PARAM_STT_ACK:
					begin
						b_state <= L_PARAM_STT_WORK;
					end
				L_PARAM_STT_WORK:
					begin
						if(func_if_finish_check(b_authority, iIF0_ARBIT_FINISH, iIF1_ARBIT_FINISH))begin
							b_state <= L_PARAM_STT_IDLE;
						end
					end
				default:
					begin
						b_state <= L_PARAM_STT_IDLE;
					end
			endcase
		end
	end
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_authority <= 1'b0;
		end
		else if(iRESET_SYNC)begin
			b_authority <= 1'b0;
		end
		else begin
			if(b_state == L_PARAM_STT_IDLE)begin
				b_authority <= func_priority_encoder(b_authority, iIF0_ARBIT_REQ, iIF1_ARBIT_REQ);
			end
		end
	end
	
	function func_if_finish_check;
		input func_now;
		input func_if0_finish;
		input func_if1_finish;
		begin
			if(!func_now && func_if0_finish)begin
				func_if_finish_check = 1'b1;
			end
			else if(func_now && func_if1_finish)begin
				func_if_finish_check = 1'b1;
			end
			else begin
				func_if_finish_check = 1'b0;
			end
		end
	endfunction
	
	
	//Interface
	function func_priority_encoder;
		input func_now;
		input func_if0_req;
		input func_if1_req;
		begin
			case(func_now)
				1'b0:
					begin
						if(func_if1_req)begin
							func_priority_encoder = 1'b1;
						end
						else if(func_if0_req)begin
							func_priority_encoder = 1'b0;
						end
						else begin
							func_priority_encoder = 1'b0;
						end
					end
				1'b1:
					begin
						if(func_if0_req)begin
							func_priority_encoder = 1'b0;
						end
						else if(func_if1_req)begin
							func_priority_encoder = 1'b1;
						end
						
						else begin
							func_priority_encoder = 1'b0;
						end
					end
			endcase
		end
	endfunction
	
	
	reg b_if2mem_ena;
	reg b_if2mem_rw;
	reg [P_MEM_ADDR_N-1:0] b_if2mem_addr;
	reg [31:0] b_if2mem_data;
	reg b_mem2if0_valid;
	reg [31:0] b_mem2if0_data;
	reg b_mem2if1_valid;
	reg [31:0] b_mem2if1_data;
	
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_if2mem_ena <= 1'b0;
			b_if2mem_rw <= 1'b0;
			b_if2mem_addr <= {P_MEM_ADDR_N{1'b0}}; 
			b_if2mem_data <= 32'h0;
			b_mem2if0_valid <= 1'b0;
			b_mem2if0_data <= 32'h0;
			b_mem2if1_valid <= 1'b0;
			b_mem2if1_data <= 32'h0;
		end
		else if(b_state != L_PARAM_STT_WORK || iRESET_SYNC)begin
			b_if2mem_ena <= 1'b0;
			b_if2mem_rw <= 1'b0;
			b_if2mem_addr <= {P_MEM_ADDR_N{1'b0}}; 
			b_if2mem_data <= 32'h0;
			b_mem2if0_valid <= 1'b0;
			b_mem2if0_data <= 32'h0;
			b_mem2if1_valid <= 1'b0;
			b_mem2if1_data <= 32'h0;
		end
		else begin
			case(b_authority)
				1'b0:
					begin
						b_if2mem_ena <= iIF0_ENA;
						b_if2mem_rw <= iIF0_RW;
						b_if2mem_addr <= iIF0_ADDR; 
						b_if2mem_data <= iIF0_DATA;
						b_mem2if0_valid <= iMEM_VALID;
						b_mem2if0_data <= iMEM_DATA;
						b_mem2if1_valid <= 1'b0;
						b_mem2if1_data <= 32'h0;
					end
				1'b1:
					begin
						b_if2mem_ena <= iIF1_ENA;
						b_if2mem_rw <= iIF1_RW;
						b_if2mem_addr <= iIF1_ADDR; 
						b_if2mem_data <= iIF1_DATA;
						b_mem2if0_valid <= 1'b0;
						b_mem2if0_data <= 32'h0;
						b_mem2if1_valid <= iMEM_VALID;
						b_mem2if1_data <= iMEM_DATA;
					end
			endcase
		end
	end
	
	assign oIF0_ARBIT_ACK = (b_state == L_PARAM_STT_ACK) && !b_authority;
	assign oIF1_ARBIT_ACK = (b_state == L_PARAM_STT_ACK) && b_authority;

	assign oIF0_VALID = b_mem2if0_valid;
	assign oIF0_DATA = b_mem2if0_data;
	assign oIF1_VALID = b_mem2if1_valid;
	assign oIF1_DATA = b_mem2if1_data;
	
	assign oMEM_ENA = b_if2mem_ena;
	assign oMEM_RW = b_if2mem_rw;
	assign oMEM_ADDR = b_if2mem_addr;
	assign oMEM_DATA = b_if2mem_data;
	
	
endmodule

`default_nettype wire


