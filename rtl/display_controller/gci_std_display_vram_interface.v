
`default_nettype none

module gci_std_display_vram_interface #(
		parameter P_MEM_ADDR_N = 19
	)(
		input wire iCLOCK,
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
		output wire [31:0] oIF0_DATA,
		//IF1
		input wire iIF1_REQ,
		output wire oIF1_ACK,
		input wire iIF1_FINISH,
		input wire iIF1_ENA,
		output wire oIF1_BUSY,
		input wire iIF1_RW,
		input wire [P_MEM_ADDR_N-1:0] iIF1_ADDR,
		input wire [31:0] iIF1_DATA,
		output wire oIF1_VALID,
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
	
	
	
endmodule

`default_nettype wire
