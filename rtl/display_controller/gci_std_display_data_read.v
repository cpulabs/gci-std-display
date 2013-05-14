


`default_nettype none

module gci_std_display_data_read #(
		parameter P_AREA_H = 640,
		parameter P_AREA_Y = 480,
		parameter P_READ_FIFO_DEPTH = 64,
		parameter P_READ_FIFO_DEPTH_N = 6,
		parameter P_MEM_ADDR_N = 19
	)(
		//System
		input wire iGCI_CLOCK,
		input wire iDISP_CLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,
		//Read Request
		input wire iRD_ENA,
		input wire iRD_SYNC,
		output wire oRD_VALID,
		output wire [7:0] oRD_DATA_R,
		output wire [7:0] oRD_DATA_G,
		output wire [7:0] oRD_DATA_B,
		//Memory IF
		output wire oIF_REQ,
		input wire iIF_ACK,
		output wire oIF_FINISH,
		output wire oIF_ENA,
		input wire iIF_BUSY,
		output wire [P_MEM_ADDR_N-1:0] oIF_ADDR,
		input wire iIF_VALID,
		input wire [31:0] iIF_DATA
	);
	
	//Main State
	localparam P_L_MAIN_STT_IDLE = 2'h0;
	localparam P_L_MAIN_STT_IF_REQ = 2'h1;
	localparam P_L_MAIN_STT_WORK = 2'h2;
	localparam P_L_MAIN_STT_IF_FINISH = 2'h3;
	//Read State
	localparam P_L_READ_STT_IDLE = 1'h0;
	localparam P_L_READ_STT_READ = 1'h1;
	localparam P_L_READ_STT_END = 1'h2;
	
	//Main State
	reg [1:0] b_main_state;
	//Read State
	reg b_read_state;
	reg [P_MEM_ADDR_N-1:0] b_read_addr;
	reg [P_READ_FIFO_DEPTH_N-1:0] b_read_count;
	//FIFO
	wire vramfifo0_full;
	wire vramfifo0_empty;
	wire [31:0] vramfifo0_data;
	wire vramfifo1_full;
	wire vramfifo1_empty;
	
	//Condition
	wire if_request_condition = vramfifo0_empty;
	wire read_state_start_condition = (b_main_state == P_L_MAIN_STT_WORK);
	
	/***************************************************
	Main State
	***************************************************/
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_main_state <= P_L_MAIN_STT_IDLE;
		end
		else if(iRESET_SYNC)begin
			b_main_state <= P_L_MAIN_STT_IDLE;
		end
		else begin
			case(b_main_state)
				P_L_MAIN_STT_IDLE:
					begin
						if(if_request_condition)begin
							b_main_state <= P_L_MAIN_STT_IF_REQ;
						end
					end
				P_L_MAIN_STT_IF_REQ:
					begin
						if(iIF_ACK)begin
							b_main_state <= P_L_MAIN_STT_WORK;
						end
					end
				P_L_MAIN_STT_WORK:
					begin
						if(b_read_state == P_L_READ_STT_END)begin
							b_main_state <= P_L_MAIN_STT_IF_FINISH;
						end
					end
				P_L_MAIN_STT_IF_FINISH:
					begin
						b_main_state <= P_L_MAIN_STT_IDLE;
					end
			endcase
		end
	end
	
	/***************************************************
	Read State
	***************************************************/	
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_read_state <= P_L_READ_STT_IDLE;
			b_read_addr <= {P_MEM_ADDR_N{1'b0}};
			b_read_count <= {P_READ_FIFO_DEPTH_N{1'b0}};
		end
		else if(iRESET_SYNC)begin
			b_read_state <= P_L_READ_STT_IDLE;
			b_read_addr <= {P_MEM_ADDR_N{1'b0}};
			b_read_count <= {P_READ_FIFO_DEPTH_N{1'b0}};
		end
		else begin
			case(b_read_state)
				P_L_READ_STT_IDLE:
					begin
						b_read_count <= {P_READ_FIFO_DEPTH_N{1'b0}};
						if(read_state_start_condition)begin
							b_read_state <= P_L_READ_STT_READ;
						end
					end		
				P_L_READ_STT_READ:
					begin
						if(b_read_count < {P_READ_FIFO_DEPTH_N{1'b0}})begin
							if(!iIF_BUSY)begin	//Busy Check
								b_read_addr <= func_read_next_addr(b_read_addr);
								b_read_count <= b_read_count + {{P_READ_FIFO_DEPTH_N-1{1'b0}}, 1'b1};
							end
						end
						else begin
							b_read_state <= P_L_READ_STT_END;
						end
					end
				P_L_READ_STT_END:
					begin
						b_read_state <= P_L_READ_STT_IDLE;
					end
				default:
					begin
						b_read_state <= P_L_READ_STT_IDLE;
					end
			endcase
		end
	end //Read State
	
	function [P_MEM_ADDR_N-1:0] func_read_next_addr;
		input [P_MEM_ADDR_N-1:0] func_now_addr;
		begin
			if(func_now_addr < (P_AREA_H*P_AREA_V)-1)begin
				func_read_next_addr = func_now_addr + 1;
			end
			else begin
				func_read_next_addr = {P_MEM_ADDR_N{1'b0}};
			end
		end
	endfunction


	/***************************************************
	Output FIFO
	***************************************************/
	gci_std_sync_fifo #(32, P_READ_FIFO_DEPTH, P_READ_FIFO_DEPTH_N) VRAMREAD_FIFO0(
		.inRESET(inRESET),
		.iREMOVE(iRESET_SYNC),
		.iCLOCK(iGCI_CLOCK),
		.iWR_EN(iIF_VALID && !vramfifo0_full),
		.iWR_DATA(iIF_DATA),
		.oWR_FULL(vramfifo0_full),
		.oWR_ALMOST_FULL(),
		.iRD_EN(!vramfifo0_empty && !vramfifo1_full),
		.oRD_DATA(vramfifo0_data),
		.oRD_EMPTY(vramfifo0_empty)
	);
	gci_std_async_fifo #(32, P_READ_FIFO_DEPTH, P_READ_FIFO_DEPTH_N) VRAMREAD_FIFO1(
		.inRESET(inRESET),
		.iREMOVE(iRESET_SYNC),
		.iWR_CLOCK(iGCI_CLOCK),
		.iWR_EN(!vramfifo0_empty && !vramfifo1_full),
		.iWR_DATA(vramfifo0_data),
		.oWR_FULL(vramfifo1_full),
		.iRD_CLOCK(iDISP_CLOCK),
		.iRD_EN(!vramfifo1_empty && iRD_ENA),
		.oRD_DATA({oRD_DATA_R, oRD_DATA_G, oRD_DATA_B}),
		.oRD_EMPTY(vramfifo1_empty)
	);
	
	assign oRD_VALID = iRD_ENA;
	
	assign oIF_REQ = (b_main_state == P_L_MAIN_STT_IF_REQ);
	assign oIF_FINISH = (b_main_state == P_L_MAIN_STT_IF_FINISH);
	assign oIF_ENA = !iIF_BUSY && (b_read_state == P_L_READ_STT_READ);
	assign oIF_ADDR = b_read_addr;
	
	
endmodule

`default_nettype wire
