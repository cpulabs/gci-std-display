
`default_nettype none

module gci_std_display_request_controller #(
		parameter P_AREA_H = 640,
		parameter P_AREA_V = 480,
		parameter P_AREAA_HV_N = 19,
		parameter P_MEM_ADDR_N = 23
	)(
		input wire iCLOCK,
		input wire inRESET,
		//BUS
		input wire iRQ_VALID,
		output wire oRQ_BUSY,
		input wire [P_MEM_ADDR_N-1:0] iRQ_ADDR,
		input wire [23:0] iRQ_DATA,
		//VRAM
		output wire oRQ_VALID,
		input wire iRQ_BUSY,
		output wire [23:0] oRQ_DATA, 
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
		output wire oIF_BUSY,
		input wire [31:0] iIF_DATA
	);
	
	
	assign oBUSMOD_WAIT = reqfifo_wr_full;
	
	wire request_break_condition = iIF_BREAK || ;
	wire reqfifo_read_condition = 
	
	
	
	gci_std_sync_fifo #(24, 16, 4) VRAM_REQ_FIFO(
		.inRESET(inRESET),
		.iREMOVE(1'b0),
		.iCLOCK(iCLOCK),
		.iWR_EN(iRQ_VALID && !read_fifo_wr_full),
		.iWR_DATA(iIF_DATA[23:0]),
		.oWR_FULL(read_fifo_wr_full),
		.oWR_ALMOST_FULL(),
		.iRD_EN(!read_fifo_rd_empty && !iRQ_BUSY),
		.oRD_DATA(read_fifo_rd_data),
		.oRD_EMPTY(read_fifo_rd_empty)
	);
	
	
	
	
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
						if(iRQ_VALID)begin
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
						else if()begin
							b_main_state <= P_L_MAIN_STT_IF_READ_WAIT;
						end
					end
				P_L_MAIN_STT_IF_READ_WAIT:
					begin
						if(iIF_VALID && !read_fifo_wr_full)begin
							b_main_state <= P_L_MAIN_STT_IF_END;
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
	
	
	wire read_fifo_wr_full;
	wire read_fifo_rd_empty;
	wire [23:0] read_fifo_rd_data;
	
	gci_std_sync_fifo #(24, 4, 2) VRAM_RESULT_FIFO(
		.inRESET(inRESET),
		.iREMOVE(1'b0),
		.iCLOCK(iCLOCK),
		.iWR_EN(iIF_VALID && !read_fifo_wr_full),
		.iWR_DATA(iIF_DATA[23:0]),
		.oWR_FULL(read_fifo_wr_full),
		.oWR_ALMOST_FULL(),
		.iRD_EN(!read_fifo_rd_empty && !iRQ_BUSY),
		.oRD_DATA(read_fifo_rd_data),
		.oRD_EMPTY(read_fifo_rd_empty)
	);
	
	
	assign oRQ_VALID = !read_fifo_rd_empty && !iRQ_BUSY;
	assign oRQ_DATA = read_fifo_rd_data;
	
	assign oIF_BUSY = read_fifo_wr_full;
	
	/***************************************************
	Assertion
	***************************************************/
	/*
	`ifdef GCI_STD_DISP_SVA_ASSERTION
		proterty PRO_FIFO_NEVER_NOT_FULL;
			@(posedge iCLOCK) disable iff (!inRESET) (!read_fifo_wr_full);
		endproperty
		assert property(PRO_FIFO_NEVER_NOT_FULL);
	`endif
	*/
	
　
endmodule


`default_nettype wire
				