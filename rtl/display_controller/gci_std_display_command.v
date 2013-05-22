
`default_nettype none


module gci_std_display_command #(
		parameter P_AREA_H = 640,
		parameter P_AREA_V = 480,
		parameter P_AREAA_HV_N = 19,
		parameter P_MEM_ADDR_N = 23
	)(
		input wire iCLOCK,
		input wire inRESET,
		//Register
		input wire iREG_MODE, //[0]Bitmap | [1]Charactor
		//BUS
		input wire iIF_VALID,
		input wire iIF_SEQ,
		output wire oIF_BUSY,
		input wire iIF_RW,
		input wire [P_MEM_ADDR_N-1:0] iIF_ADDR,
		input wire [31:0] iIF_DATA,
		//Output
		output wire oIF_VALID,
		input wire iIF_BUSY,
		output wire [P_MEM_ADDR_N-1:0] oIF_ADDR,
		output wire [23:0] oIF_DATA
	);
	
	localparam P_L_REQ_STT_BITMAP = 3'h0;
	localparam P_L_REQ_STT_CLARACTER = 3'h1;
	localparam P_L_REQ_STT_CLARACTER_WAIT = 3'h2;
	localparam P_L_REQ_STT_SEAQUENCER = 3'h3;
	localparam P_L_REQ_STT_SEAQUENCER_WAIT = 3'h4;
	
	//State
	reg [2:0] b_req_state;
	//FIFO
	wire reqfifo_wr_full;
	wire reqfifo_rd_empty;
	wire reqfifo_rd_mode;
	wire reqfifo_rd_seq;
	wire reqfifo_rd_rw;
	wire [31:0] reqfifo_rd_data;
	wire [P_MEM_ADDR_N-1:0] reqfifo_rd_addr;
	//Bitmap Latch
	reg b_req_valid;
	reg [P_MEM_ADDR_N-1:0] b_req_addr;
	reg [23:0] b_req_data;
	//Charactor
	wire character_busy;
	wire character_finish;
	wire character_out_valid;
	wire [P_MEM_ADDR_N-1:0] character_out_addr;
	wire [23:0] character_out_data;
	//Sequencer
	wire sequencer_busy;
	wire sequencer_finish;
	wire sequencer_out_valid;
	wire [P_MEM_ADDR_N-1:0] sequencer_out_addr;
	wire [23:0] sequencer_out_data;
	
	//Condition
	reg fifo_read_condition;						
	always @* begin
		case(b_req_state)
			P_L_REQ_STT_BITMAP : fifo_read_condition = !reqfifo_rd_empty && !iIF_BUSY;
			P_L_REQ_STT_CLARACTER : fifo_read_condition = !reqfifo_rd_empty && !character_busy;
			P_L_REQ_STT_CLARACTER_WAIT : fifo_read_condition = 1'b0;
			P_L_REQ_STT_SEAQUENCER : fifo_read_condition = !reqfifo_rd_empty && !sequencer_busy;
			P_L_REQ_STT_SEAQUENCER_WAIT : fifo_read_condition = 1'b0;
			default : fifo_read_condition = 1'b0;
		endcase
	end //conb				
	
	wire seaquencer_start_condition = fifo_read_condition && reqfifo_rd_seq;
	wire charactor_start_condition = fifo_read_condition && reqfifo_rd_mode && !reqfifo_rd_seq;
	
	
	gci_std_display_sync_fifo #(35+P_MEM_ADDR_N, 16, 4) REQ_FIFO 
		.iCLOCK(iCLOCK),
		.inRESET(inRESET),
		.iREMOVE(1'b0),
		//Counter
		.oCOUNT(),
		//WR
		.iWR_EN(iIF_VALID && !reqfifo_wr_full),
		.iWR_DATA({iREG_MODE, iIF_SEQ, iIF_RW, iIF_DATA, iIF_DATA}),
		.oWR_FULL(reqfifo_wr_full),
		.oWR_ALMOST_FULL(),
		//RD
		.iRD_EN(fifo_read_condition),
		.oRD_DATA({reqfifo_rd_mode, reqfifo_rd_seq, reqfifo_rd_rw, reqfifo_rd_addr, reqfifo_rd_data}),
		.oRD_EMPTY(reqfifo_rd_empty),
		.oRD_ALMOST_EMPTY()
	);
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_req_state <= P_L_REQ_STT_BITMAP;
		end
		else begin
			case(b_req_state)
				P_L_REQ_STT_BITMAP:
					begin
						if(seaquencer_start_condition)begin
							b_req_state <= P_L_REQ_STT_SEAQUENCER;
						end
						else if(charactor_start_condition)begin
							b_req_state <= P_L_REQ_STT_CLARACTER;
						end
						else begin
							b_req_state <= P_L_REQ_STT_BITMAP;
						end
					end
				P_L_REQ_STT_CLARACTER:
					begin
						if(!character_busy)begin
							b_req_state <= P_L_REQ_STT_CLARACTER_WAIT;
						end
					end
				P_L_REQ_STT_CLARACTER_WAIT:
					begin
						if(character_finish)begin
							b_req_state <= P_L_REQ_STT_BITMAP;
						end
					end
				P_L_REQ_STT_SEAQUENCER:
					begin
						if(!sequencer_busy)begin
							b_req_state <= P_L_REQ_STT_SEAQUENCER_WAIT;
						end
					end
				P_L_REQ_STT_SEAQUENCER_WAIT:
					begin
						if(sequencer_finish)begin
							b_req_state <= P_L_REQ_STT_BITMAP;
						end
					end
				default:
					begin
						b_req_state <= P_L_REQ_STT_BITMAP;
					end
			endcase
		end
	end
	
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_req_valid <= 1'b0;
			b_req_addr <= {P_MEM_ADDR_N{1'b0}};
			b_req_data <= 24'h0;
		end
		else begin
			if(!iIF_BUSY)begin
				b_req_valid <= !reqfifo_rd_empty;
				b_req_addr <= reqfifo_rd_addr;
				b_req_data <= reqfifo_rd_data[23:0];
			end
		end
	end
	
	gci_std_display_character #(P_AREA_H, P_AREA_V, P_AREAA_HV_N, P_MEM_ADDR_N) CHARACTER_CONTROLLER(
		.iCLOCK(iCLOCK),
		.inRESET(inRESET),
		.iRESET_SYNC(1'b0),
		//Req
		.iIF_VALID(b_req_state == P_L_REQ_STT_CLARACTER),
		.oIF_BUSY(character_busy),
		.iIF_ADDR(reqfifo_rd_addr),	//Charactor Addr
		.iIF_DATA(reqfifo_rd_data),
		//Out
		.oIF_FINISH(character_finish)
		.oIF_VALID(character_out_valid),
		.iIF_BUSY(iIF_BUSY),
		.oIF_ADDR(character_out_addr),
		.oIF_DATA(character_out_data)
	);
	
	gci_std_display_sequencer #(P_AREA_H, P_AREA_V, P_AREAA_HV_N, P_MEM_ADDR_N) SEQUENCER_CONTROLLER(
		.iCLOCK(iCLOCK),
		.inRESET(inRESET),
		.iRESET_SYNC(1'b0),
		//Req
		.iIF_VALID(b_req_state == P_L_REQ_STT_SEAQUENCER),
		.oIF_BUSY(sequencer_busy),
		.iIF_DATA(reqfifo_rd_data),
		//Out
		.oIF_FINISH(sequencer_finish)
		.oIF_VALID(sequencer_out_valid),
		.iIF_BUSY(iIF_BUSY),
		.oIF_ADDR(sequencer_out_addr),
		.oIF_DATA(sequencer_out_data)
	);
	
	reg if_out_valid;
	reg [P_MEM_ADDR_N-1:0] if_out_addr;
	reg [23:0] if_out_data;
	always @* begin
		case(b_req_state)
			P_L_REQ_STT_BITMAP:
				begin
					if_out_valid = b_req_valid;
					if_out_addr = b_req_addr;
					if_out_data = b_req_data;
				end
			P_L_REQ_STT_CLARACTER_WAIT:
				begin
					if_out_valid = character_out_valid;
					if_out_addr = character_out_addr;
					if_out_data = character_out_data;
				end
			P_L_REQ_STT_SEAQUENCER_WAIT:
				begin
					if_out_valid = sequencer_out_valid;
					if_out_addr = sequencer_out_addr;
					if_out_data = sequencer_out_data;
				end
			default:
				begin
					if_out_valid = b_req_valid;
					if_out_addr = b_req_addr;
					if_out_data = b_req_data;
				end
		endcase
	end
	
	assign oIF_BUSY = reqfifo_wr_full;
	assign oIF_VALID = !iIF_BUSY && if_out_valid;
	assign oIF_ADDR = if_out_addr;
	assign oIF_DATA = if_out_data;
	
endmodule

`default_nettype wire
