

`default_nettype none

module gci_std_display_vram_controller_sram #(
		parameter P_MEM_ADDR_N = 20,
		parameter P_AREA_H = 640,
		parameter P_AREA_V = 480
	)(
		//System
		input wire iGCI_CLOCK,
		input wire iDISP_CLOCK,
		input wire inRESET,
		//IF	
		input wire iIF_WRITE_REQ,
		input wire [P_MEM_ADDR_N-1:0] iIF_WRITE_ADDR,
		input wire [15:0] iIF_WRITE_DATA,
		output wire oIF_WRITE_FULL,
		input wire iDISP_REQ,
		input wire iDISP_SYNC,
		output wire [9:0] oDISP_DATA_R,
		output wire [9:0] oDISP_DATA_G,
		output wire [9:0] oDISP_DATA_B,
		//SRAM
		output wire onSRAM_CE,
		output wire onSRAM_WE,
		output wire onSRAM_OE,
		output wire onSRAM_UB,
		output wire onSRAM_LB,
		output wire [P_MEM_ADDR_N-1:0] oSRAM_ADDR,
		inout wire [15:0] ioSRAM_DATA
	);
	
	
	//Write FIFO Wire
	wire writefifo_empty;
	wire [P_MEM_ADDR_N-1:0] writefifo_addr;
	wire [15:0] writefifo_data;
	//Read FIFO Wire
	wire vramfifo0_full;
	wire [15:0] vramfifo0_data;
	wire vramfifo0_empty;
	wire vramfifo1_full;
		
	/********************************************
	//Memory Assignment
	********************************************/
	//Assignment Buffer
	reg b_buff_osram_rw;		//R=0 | W=1
	reg b_buff_onsram_we;
	reg b_buff_onsram_oe;
	reg b_buff_onsram_ub;
	reg b_buff_onsram_lb;
	reg [P_MEM_ADDR_N-1:0] b_buff_osram_addr;
	reg [15:0] b_buff_osram_data;
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_buff_osram_rw <= 1'b0;
			b_buff_onsram_we <= 1'b0;
			b_buff_onsram_oe <= 1'b0;
			b_buff_onsram_ub <= 1'b0;
			b_buff_onsram_lb <= 1'b0;
			b_buff_osram_addr <= {P_MEM_ADDR_N{1'b0}};
			b_buff_osram_data <= 16'h0;
		end
		else begin
			b_buff_onsram_oe <= 1'b0;
			case(b_main_state)
				L_PARAM_MAIN_STT_READ:
					begin
						case(b_rd_req_state)
							L_PARAM_READ_REQ_STT_ADDR_SET:
								begin
									b_buff_osram_rw <= 1'b0;
									b_buff_onsram_we <= 1'b1;
									b_buff_onsram_ub <= 1'b0;
									b_buff_onsram_lb <= 1'b0;
									b_buff_osram_addr <= b_rd_req_addr;
									b_buff_osram_data <= b_buff_osram_data;
								end
							default:
								begin
									b_buff_osram_rw <= 1'b0;
									b_buff_onsram_we <= 1'b1;
									b_buff_onsram_ub <= 1'b1;
									b_buff_onsram_lb <= 1'b1;
									b_buff_osram_addr <= {P_MEM_ADDR_N{1'h0}};
									b_buff_osram_data <= 16'h0;
								end
						endcase
					end
				L_PARAM_MAIN_STT_WRITE:
					begin
						case(b_wr_state)
							L_PARAM_WRITE_STT_ADDR_SET:
								begin	//CE=H, WE=H, Addr=Active
									b_buff_osram_rw <= 1'b0;
									b_buff_onsram_we <= 1'b1;
									b_buff_onsram_ub <= 1'b1;
									b_buff_onsram_lb <= 1'b1;
									b_buff_osram_addr <= writefifo_addr;
									b_buff_osram_data <= writefifo_data;
								end
							L_PARAM_WRITE_STT_LATCH_CONDITION:
								begin	//CE=L, WE=L
									b_buff_osram_rw <= 1'b1;
									b_buff_onsram_we <= 1'b0;
									b_buff_onsram_ub <= 1'b0;
									b_buff_onsram_lb <= 1'b0;
									b_buff_osram_addr <= b_buff_osram_addr;
									b_buff_osram_data <= b_buff_osram_data;
								end
							L_PARAM_WRITE_STT_DATA_SET:
								begin	//CE=L, WE=L, Data=Active
									b_buff_osram_rw <= 1'b1;
									b_buff_onsram_we <= 1'b0;
									b_buff_onsram_ub <= 1'b0;
									b_buff_onsram_lb <= 1'b0;
									b_buff_osram_addr <= b_buff_osram_addr;
									b_buff_osram_data <= b_buff_osram_data;
								end
							default:	//Idle or other
								begin
									b_buff_osram_rw <= 1'b0;
									b_buff_onsram_we <= 1'b1;
									b_buff_onsram_ub <= 1'b1;
									b_buff_onsram_lb <= 1'b1;
									b_buff_osram_addr <= {P_MEM_ADDR_N{1'h0}};
									b_buff_osram_data <= 16'h0;
								end
						endcase
					end
				default:
					begin
						b_buff_osram_rw <= 1'b0;
						b_buff_onsram_we <= 1'b1;
						b_buff_onsram_ub <= 1'b1;
						b_buff_onsram_lb <= 1'b1;
						b_buff_osram_addr <= {P_MEM_ADDR_N{1'h0}};
						b_buff_osram_data <= 16'h0;
					end
			endcase
		end
	end
	
	
	assign onSRAM_CE = 1'b0;//b_buff_onsram_ce;
	assign onSRAM_WE = b_buff_onsram_we;
	assign onSRAM_OE = b_buff_onsram_oe;
	assign onSRAM_UB = b_buff_onsram_ub;
	assign onSRAM_LB = b_buff_onsram_lb;
	assign oSRAM_ADDR = b_buff_osram_addr;
	assign ioSRAM_DATA = (b_buff_osram_rw)? b_buff_osram_data : 16'hzzzz;
	
	
	/********************************************
	//Main State
	********************************************/
	localparam L_PARAM_MAIN_STT_IDLE = 2'h0;
	localparam L_PARAM_MAIN_STT_READ = 2'h1;
	localparam L_PARAM_MAIN_STT_WRITE = 2'h2;
	
	reg [1:0] b_main_state;
	reg b_main_wait;	
	reg b_main_req;
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_main_state <= L_PARAM_MAIN_STT_IDLE;
			b_main_wait <= 1'b0;
			b_main_req <= 1'b0;
		end
		else if(b_main_wait)begin
			b_main_req <= 1'b0;
			if(b_wr_end || b_rd_req_end)begin
				b_main_state <= L_PARAM_MAIN_STT_IDLE;
				b_main_wait <= 1'b0;
			end
		end
		else begin
			case(b_main_state)
				L_PARAM_MAIN_STT_IDLE:
					begin
						if(vramfifo0_empty)begin
							b_main_state <= L_PARAM_MAIN_STT_READ;
							b_main_req <= 1'b1;
						end
						else if(!writefifo_empty)begin
							b_main_state <= L_PARAM_MAIN_STT_WRITE;
							b_main_req <= 1'b1;
						end
						else begin
							b_main_state <= L_PARAM_MAIN_STT_IDLE;
							b_main_wait <= 1'b0;
							b_main_req <= 1'b0;
						end
					end
				L_PARAM_MAIN_STT_READ:
					begin
						b_main_state <= L_PARAM_MAIN_STT_READ;
						b_main_wait <= 1;
						b_main_req <= 1'b0;
					end
				L_PARAM_MAIN_STT_WRITE:
					begin
						b_main_state <= L_PARAM_MAIN_STT_WRITE;
						b_main_wait <= 1;
						b_main_req <= 1'b0;
					end
				default:
					begin
						b_main_state <= L_PARAM_MAIN_STT_IDLE;
						b_main_wait <= 1'b0;
						b_main_req <= 1'b0;
					end
			endcase
		end
	end
		
	
	
	/********************************************
	//Write State
	********************************************/
	localparam L_PARAM_WRITE_STT_IDLE = 3'h0;	
	localparam L_PARAM_WRITE_STT_ADDR_SET = 3'h1;			//CE=H, WE=H, Addr=Active
	localparam L_PARAM_WRITE_STT_LATCH_CONDITION = 3'h2;	//CE=L, WE=L
	localparam L_PARAM_WRITE_STT_DATA_SET = 3'h3;			//CE=L, WE=L, Data=Active
	localparam L_PARAM_WRITE_STT_END = 3'h4;
	
	gci_std_sync_fifo #(16+P_MEM_ADDR_N, 64, 6)	VRAMWRITE_FIFO(
		.inRESET(inRESET),
		.iCLOCK(iGCI_CLOCK),
		.iREMOVE(1'b0),
		.oCOUNT(),
		.iWR_EN(iIF_WRITE_REQ),
		.iWR_DATA({iIF_WRITE_ADDR, iIF_WRITE_DATA}),
		.oWR_FULL(oIF_WRITE_FULL),
		.iRD_EN(b_wr_state == L_PARAM_WRITE_STT_DATA_SET && !writefifo_empty),
		.oRD_DATA({writefifo_addr, writefifo_data}),
		.oRD_EMPTY(writefifo_empty)
	);
	
	
	reg [2:0] b_wr_state;
	reg b_wr_end;
	
	
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_wr_state <= L_PARAM_WRITE_STT_IDLE;
			b_wr_end <= 1'b0;
		end
		else begin
			case(b_wr_state)
				L_PARAM_WRITE_STT_IDLE:
					begin
						if(b_main_req && (b_main_state == L_PARAM_MAIN_STT_WRITE))begin
							b_wr_state <= L_PARAM_WRITE_STT_ADDR_SET;
						end
						b_wr_end <= 1'b0;
					end
				L_PARAM_WRITE_STT_ADDR_SET:
					begin
						b_wr_state <= L_PARAM_WRITE_STT_LATCH_CONDITION;
					end
				L_PARAM_WRITE_STT_LATCH_CONDITION:
					begin
						b_wr_state <= L_PARAM_WRITE_STT_DATA_SET;
					end
				L_PARAM_WRITE_STT_DATA_SET:
					begin
						if(writefifo_empty || vramfifo0_empty)begin
							b_wr_state <= L_PARAM_WRITE_STT_END;
						end
						else begin
							b_wr_state <= L_PARAM_WRITE_STT_ADDR_SET;
						end
					end
				L_PARAM_WRITE_STT_END:
					begin
						b_wr_state <= L_PARAM_WRITE_STT_IDLE;
						b_wr_end <= 1'b1;
					end
				default:
					begin
						b_wr_state <= L_PARAM_WRITE_STT_IDLE;
					end
			endcase
		end
	end
	
	
	/********************************************
	//Read State (RD FIFO)
	********************************************/
	//Request State
	localparam L_PARAM_READ_REQ_STT_IDLE = 2'h0;
	localparam L_PARAM_READ_REQ_STT_ADDR_SET = 2'h1;
	localparam L_PARAM_READ_REQ_STT_RD_END = 2'h2;
	
	
	reg [1:0] b_rd_req_state;
	reg [P_MEM_ADDR_N-1:0] b_rd_req_addr;
	reg b_rd_req_end;
	
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_rd_req_state <= L_PARAM_READ_REQ_STT_IDLE;
			b_rd_req_addr <= 20'h0;
			b_rd_req_end <= 1'b0;
		end
		else begin
			case(b_rd_req_state)
				L_PARAM_READ_REQ_STT_IDLE:
					begin
						if(b_main_req && (b_main_state == L_PARAM_MAIN_STT_READ))begin
							b_rd_req_state <= L_PARAM_READ_REQ_STT_ADDR_SET;
						end
						b_rd_req_end <= 1'b0;
					end
				L_PARAM_READ_REQ_STT_ADDR_SET:
					begin
						if(vramfifo0_full)begin
							//b_rd_req_addr <= func_read_next_addr_640x480(b_rd_req_addr);
							b_rd_req_state <= L_PARAM_READ_REQ_STT_RD_END;
						end
						else begin
							b_rd_req_addr <= func_read_next_addr(b_rd_req_addr);
							b_rd_req_state <= L_PARAM_READ_REQ_STT_ADDR_SET;
						end
					end
				L_PARAM_READ_REQ_STT_RD_END:
					begin
						b_rd_req_state <= L_PARAM_READ_REQ_STT_IDLE;
						b_rd_req_end <= 1'b1;
					end
				default:
					begin
						b_rd_req_state <= L_PARAM_READ_REQ_STT_IDLE;
						b_rd_req_end <= 1'b0;
					end
			endcase
		end
	end
	

	
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
	
	//latch State
	localparam L_PARAM_READ_LATCH_STT_IDLE = 2'h0;
	localparam L_PARAM_READ_LATCH_STT_ADDR_SET = 2'h1;
	localparam L_PARAM_READ_LATCH_STT_RD = 2'h2;
	localparam L_PARAM_READ_LATCH_STT_RD_END = 2'h3;
	
	reg b_rd_latch_condition;
	
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_rd_latch_condition <= 1'b0;
		end
		else begin
			b_rd_latch_condition <= (b_rd_req_state == L_PARAM_READ_REQ_STT_ADDR_SET) && !vramfifo0_full;
		end
	end

	wire [15:0] vramfifo1_data;
	
	gci_std_sync_fifo #(16, 16, 4) VRAMREAD_FIFO0(
		.inRESET(inRESET),
		.iREMOVE(1'b0),
		.iCLOCK(iGCI_CLOCK),
		.iWR_EN(b_rd_latch_condition),
		.iWR_DATA(ioSRAM_DATA),
		.oWR_FULL(),
		.oWR_ALMOST_FULL(vramfifo0_full),
		.iRD_EN(!vramfifo0_empty && !vramfifo1_full),
		.oRD_DATA(vramfifo0_data),
		.oRD_EMPTY(vramfifo0_empty)
	);
	gci_std_async_fifo #(16, 16, 4)	VRAMREAD_FIFO1(
		.inRESET(inRESET),
		.iREMOVE(1'b0),
		.iWR_CLOCK(iGCI_CLOCK),
		.iWR_EN(!vramfifo0_empty && !vramfifo1_full),
		.iWR_DATA(vramfifo0_data),
		.oWR_FULL(vramfifo1_full),
		.iRD_CLOCK(iDISP_CLOCK),
		.iRD_EN(iDISP_REQ),
		.oRD_DATA(vramfifo1_data),
		.oRD_EMPTY()
	);
	
	assign oDISP_DATA_R = {vramfifo1_data[15:11], {5{vramfifo1_data[11]}}};
	assign oDISP_DATA_G = {vramfifo1_data[10:5], {4{vramfifo1_data[5]}}};
	assign oDISP_DATA_B = {vramfifo1_data[4:0], {5{vramfifo1_data[0]}}};
	
endmodule



`default_nettype wire
