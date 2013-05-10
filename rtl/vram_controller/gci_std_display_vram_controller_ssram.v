
`default_nettype none


module gci_std_display_vram_controller_ssram #(		
		parameter P_MEM_ADDR_N = 20,
		parameter P_AREA_H = 640,
		parameter P_AREA_V = 480,
		parameter P_WRITE_FIFO_DEPTH = 64,
		parameter P_WRITE_FIFO_DEPTH_N = 6,
		parameter P_READ_SYNC_FIFO_DEPTH = 64,
		parameter P_READ_SYNC_FIFO_DEPTH_N = 6,
		parameter P_READ_ASYNC_FIFO_DEPTH = 16,
		parameter P_READ_ASYNC_FIFO_DEPTH_N = 4
	)(
		//System
		input wire iGCI_CLOCK,
		input wire iDISP_CLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,
		//Write	
		input wire iIF_WRITE_REQ,
		input wire [19:0] iIF_WRITE_ADDR,
		input wire [15:0] iIF_WRITE_DATA,
		output wire oIF_WRITE_FULL,
		//Timing Sync
		input wire iDISP_REQ,
		input wire iDISP_SYNC,
		//Output VGA Data
		//output wire oDISP_DATA_VALID,
		//output wire [15:0] oDISP_DATA,
		output [9:0] oDISP_DATA_R,
		output [9:0] oDISP_DATA_G,
		output [9:0] oDISP_DATA_B,
		//SSRAM
		output wire oSSRAM_CLOCK,
		output wire onSSRAM_ADSC,
		output wire onSSRAM_ADSP,
		output wire onSSRAM_ADV,
		output wire onSSRAM_GW,
		output wire onSSRAM_OE,
		output wire onSSRAM_WE,
		output wire [3:0] onSSRAM_BE,
		output wire onSSRAM_CE1,
		output wire oSSRAM_CE2,
		output wire onSSRAM_CE3,
		output wire [18:0] oSSRAM_ADDR,
		inout wire [31:0] ioSSRAM_DATA,
		inout wire [3:0] ioSSRAM_PARITY
	);
	
	//Main State
	localparam P_L_MAIN_STT_IDLE = 2'h0;
	localparam P_L_MAIN_STT_READ = 2'h1; 
	localparam P_L_MAIN_STT_WRITE = 2'h2;
	//Read State
	localparam P_L_READ_STT_IDLE = 2'h0;
	localparam P_L_READ_STT_SET_ADDR = 2'h1;
	localparam P_L_READ_STT_WAIT = 2'h2;
	localparam P_L_READ_STT_GET_DATA = 2'h3;
	//Write State
	localparam P_L_WRITE_STT_IDLE = 2'h0;
	localparam P_L_WRITE_STT_WRITE = 2'h1;
	localparam P_L_WRITE_STT_STOP = 2'h2;
	
	/***************************************************
	Wire & Reg
	***************************************************/
	//Write FIFO
	wire [19:0] writefifo_addr;
	wire [15:0] writefifo_data;
	wire writefifo_empty;
	//Main State
	reg [1:0] b_main_state;
	reg b_main_job_start;
	//Read State
	reg [1:0] b_read_state;
	reg [18:0] b_read_addr;
	reg b_read_finish;
	//Write State
	reg [1:0] b_write_state;
	reg b_write_finish;
	//Vram Data-Receive
	reg b_get_data_valid;
	//READ FIFO
	wire vramfifo0_almost_full;
	wire vramfifo0_empty;
	wire [31:0] vramfifo0_data;
	wire vramfifo1_full;
	
	
	/***************************************************
	Condition
	***************************************************/
	wire vram_read_start_condition = b_main_job_start && (b_main_state == P_L_MAIN_STT_READ);
	wire vram_write_start_condition = b_main_job_start && (b_main_state == P_L_MAIN_STT_WRITE); 
	wire vram_read_sequence_condition = (b_read_state == P_L_READ_STT_GET_DATA);
	wire vram_write_sequence_condition = (b_write_state == P_L_WRITE_STT_WRITE);
	
	/***************************************************
	Input FIFO
	***************************************************/
	gci_std_sync_fifo #(36, P_WRITE_FIFO_DEPTH, P_WRITE_FIFO_DEPTH_N) VRAMWRITE_FIFO(
		.inRESET(inRESET),
		.iCLOCK(iGCI_CLOCK),
		.iREMOVE(iRESET_SYNC),
		.oCOUNT(),
		.iWR_EN(iIF_WRITE_REQ),
		.iWR_DATA({iIF_WRITE_ADDR, iIF_WRITE_DATA}),
		.oWR_FULL(oIF_WRITE_FULL),
		.iRD_EN(vram_write_sequence_condition),
		.oRD_DATA({writefifo_addr, writefifo_data}),
		.oRD_EMPTY(writefifo_empty),
		.oRD_ALMOST_EMPTY()
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
	
	
	//Memory Read State
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_read_state <= P_L_READ_STT_IDLE;
			b_read_addr <= 19'h0;
			b_read_finish <= 1'b0;
		end
		else if(iRESET_SYNC)begin
			b_read_state <= P_L_READ_STT_IDLE;
			b_read_addr <= 19'h0;
			b_read_finish <= 1'b0;
		end
		else begin
			case(b_read_state)
				P_L_READ_STT_IDLE:
					begin
						b_read_finish <= 1'b0;
						if(vram_read_start_condition)begin
							b_read_state <= P_L_READ_STT_SET_ADDR;
						end
					end		
				P_L_READ_STT_SET_ADDR:
					begin
						b_read_state <= P_L_READ_STT_WAIT;
						b_read_addr <= func_read_next_addr(b_read_addr);
					end
				P_L_READ_STT_WAIT:
					begin
						b_read_state <= P_L_READ_STT_GET_DATA;
						b_read_addr <= func_read_next_addr(b_read_addr);
					end
				P_L_READ_STT_GET_DATA:
					begin
						if(vramfifo0_almost_full)begin
							b_read_state <= P_L_READ_STT_IDLE;
							b_read_addr <= func_read_2prev_addr(b_read_addr);// - 19'h1;
							b_read_finish <= 1'b1;
						end
						else begin
							b_read_addr <= func_read_next_addr(b_read_addr);//b_read_addr + 19'h1;
						end
					end
			endcase
		end
	end //Read State
	
	function [P_MEM_ADDR_N-1:0] func_read_next_addr;
		input [P_MEM_ADDR_N-1:0] func_now_addr;
		begin
			if(func_now_addr < ((P_AREA_H*P_AREA_V)/2)-1)begin
				func_read_next_addr = func_now_addr + 1;
			end
			else begin
				func_read_next_addr = {P_MEM_ADDR_N{1'b0}};
			end
		end
	endfunction
	
	function [P_MEM_ADDR_N-1:0] func_read_2prev_addr;
		input [P_MEM_ADDR_N-1:0] func_now_addr;
		begin
			if(func_now_addr == {P_MEM_ADDR_N{1'b0}})begin
				func_read_2prev_addr = ((P_AREA_H*P_AREA_V)/2)-2;
			end
			else if(func_now_addr == {{P_MEM_ADDR_N-1{1'b0}}, 1'b1})begin	
				func_read_2prev_addr = ((P_AREA_H*P_AREA_V)/2)-1;
			end
			else begin
				func_read_2prev_addr = func_now_addr - 2;
			end
		end
	endfunction
	
	
	//Memory Write State
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_write_state <= P_L_WRITE_STT_IDLE;
			b_write_finish <= 1'b0;
		end
		else if(iRESET_SYNC)begin
			b_write_state <= P_L_WRITE_STT_IDLE;
			b_write_finish <= 1'b0;
		end
		else begin
			case(b_write_state)
				P_L_WRITE_STT_IDLE:
					begin
						b_write_finish <= 1'b0;
						if(vram_write_start_condition)begin
							b_write_state <= P_L_WRITE_STT_WRITE;
						end
					end		
				P_L_WRITE_STT_WRITE:
					begin
						if(writefifo_empty || vramfifo0_empty)begin
							b_write_state <= P_L_WRITE_STT_STOP;
						end
					end
				P_L_WRITE_STT_STOP:
					begin
						b_write_state <= P_L_WRITE_STT_IDLE;
						b_write_finish <= 1'b1;
					end
			endcase
		end
	end //Read State
	
	/***************************************************
	VRAM Data Receive
	***************************************************/
	reg b_get_data_tmp;
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_get_data_valid <= 1'b0;
			b_get_data_tmp <= 1'b0;
		end
		else if(iRESET_SYNC)begin
			b_get_data_valid <= 1'b0;
			b_get_data_tmp <= 1'b0;
		end
		else begin
			b_get_data_tmp <= vram_read_sequence_condition;
			b_get_data_valid <= vram_read_sequence_condition;//b_get_data_tmp;
		end
	end
	
	/***************************************************
	Output FIFO
	***************************************************/
	wire [31:0] vramfifo1_data;
	wire vramfifo0_full;
	wire vramfifo1_empty;
	gci_std_sync_fifo #(32, P_READ_SYNC_FIFO_DEPTH, P_READ_SYNC_FIFO_DEPTH_N) VRAMREAD_FIFO0(
		.inRESET(inRESET),
		.iREMOVE(iRESET_SYNC),
		.iCLOCK(iGCI_CLOCK),
		.iWR_EN(b_get_data_valid && !vramfifo0_full),
		.iWR_DATA(ioSSRAM_DATA),
		.oWR_FULL(vramfifo0_full),
		.oWR_ALMOST_FULL(vramfifo0_almost_full),
		.iRD_EN(!vramfifo0_empty && !vramfifo1_full),
		.oRD_DATA(vramfifo0_data),
		.oRD_EMPTY(vramfifo0_empty)
	);
	gci_std_async_fifo #(32, P_READ_ASYNC_FIFO_DEPTH, P_READ_ASYNC_FIFO_DEPTH_N) VRAMREAD_FIFO1(
		.inRESET(inRESET),
		.iREMOVE(iRESET_SYNC),
		.iWR_CLOCK(iGCI_CLOCK),
		.iWR_EN(!vramfifo0_empty && !vramfifo1_full),
		.iWR_DATA(vramfifo0_data),
		.oWR_FULL(vramfifo1_full),
		.iRD_CLOCK(iDISP_CLOCK),
		.iRD_EN(!vramfifo1_empty && b_dispout_state == P_L_DISPOUT_STT_1ST),
		.oRD_DATA(vramfifo1_data),
		.oRD_EMPTY(vramfifo1_empty)
	);
	
	
	parameter P_L_DISPOUT_STT_1ST = 1'b0;
	parameter P_L_DISPOUT_STT_2RD = 1'b1;
	
	reg b_dispout_state;
	reg [15:0] b_dispout_current_data;
	reg [15:0] b_dispout_next_data;
	
	always@(posedge iDISP_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_dispout_state <= P_L_DISPOUT_STT_1ST;
			b_dispout_current_data <= 16'h0;
			b_dispout_next_data <= 16'h0;
		end
		else if(iRESET_SYNC)begin
			b_dispout_state <= P_L_DISPOUT_STT_1ST;
			b_dispout_current_data <= 16'h0;
			b_dispout_next_data <= 16'h0;
		end
		else begin
			case(b_dispout_state)
				P_L_DISPOUT_STT_1ST:
					begin
						if(!vramfifo1_empty)begin
							{b_dispout_next_data, b_dispout_current_data} <= vramfifo1_data;
							b_dispout_state <= P_L_DISPOUT_STT_2RD;
						end
					end
				P_L_DISPOUT_STT_2RD:
					begin
						if(iDISP_REQ)begin
							b_dispout_current_data <= b_dispout_next_data;
							b_dispout_state <= P_L_DISPOUT_STT_1ST;
						end
					end
			endcase
		end
	end
	
	
	/***************************************************
	Memory Port Buffer
	***************************************************/		
	reg bn_ram_buff_adsc;
	reg bn_ram_buff_adsp;
	reg bn_ram_buff_adv;
	reg bn_ram_buff_gw;
	reg bn_ram_buff_oe;
	reg bn_ram_buff_we;
	reg [3:0] bn_ram_buff_be;
	//reg bn_ram_buff_ce1;
	//reg b_ram_buff_ce2;
	reg bn_ram_buff_ce3;
	reg [18:0] b_ram_buff_addr;
	reg [31:0] b_ram_buff_data;
	reg [3:0] b_ram_buff_parity;
	reg b_ram_buff_rw;
	
	always@(posedge iGCI_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			bn_ram_buff_adsc <= 1'b0;
			bn_ram_buff_adsp <= 1'b0; 
			bn_ram_buff_adv <= 1'b0;
			bn_ram_buff_gw <= 1'b0;
			bn_ram_buff_oe <= 1'b0;
			bn_ram_buff_we <= 1'b0;
			bn_ram_buff_be <= {4{1'b0}};
			//bn_ram_buff_ce1 <= 1'b0;
			//b_ram_buff_ce2 <= 1'b0;
			bn_ram_buff_ce3 <= 1'b0;
			b_ram_buff_addr <= {19{1'b0}};
			b_ram_buff_data <= {32{1'b0}};
			b_ram_buff_parity <= {4{1'b0}};
			b_ram_buff_rw <= 1'b0;
		end
		else if(iRESET_SYNC)begin
			bn_ram_buff_adsc <= 1'b0;
			bn_ram_buff_adsp <= 1'b0; 
			bn_ram_buff_adv <= 1'b0;
			bn_ram_buff_gw <= 1'b0;
			bn_ram_buff_oe <= 1'b0;
			bn_ram_buff_we <= 1'b0;
			bn_ram_buff_be <= {4{1'b0}};
			//bn_ram_buff_ce1 <= 1'b0;
			//b_ram_buff_ce2 <= 1'b0;
			bn_ram_buff_ce3 <= 1'b0;
			b_ram_buff_addr <= {19{1'b0}};
			b_ram_buff_data <= {32{1'b0}};
			b_ram_buff_parity <= {4{1'b0}};
			b_ram_buff_rw <= 1'b0;
		end
		else begin
			if(vram_write_sequence_condition)begin
				case(b_write_state)
					P_L_WRITE_STT_IDLE:
						begin
							bn_ram_buff_adsc <= 1'b0;
							bn_ram_buff_adsp <= 1'b0; 
							bn_ram_buff_adv <= 1'b0;
							bn_ram_buff_gw <= 1'b0;
							bn_ram_buff_oe <= 1'b0;
							bn_ram_buff_we <= 1'b0;
							bn_ram_buff_be <= {4{1'b0}};
							//bn_ram_buff_ce1 <= 1'b0;
							//b_ram_buff_ce2 <= 1'b0;
							bn_ram_buff_ce3 <= 1'b0;
							b_ram_buff_addr <= {19{1'b0}};
							b_ram_buff_data <= {32{1'b0}};
							b_ram_buff_parity <= {4{1'b0}};
							b_ram_buff_rw <= 1'b0;
						end
					P_L_WRITE_STT_WRITE:
						begin
							bn_ram_buff_adsc <= 1'b1;
							bn_ram_buff_adsp <= 1'b0; 
							bn_ram_buff_adv <= 1'b0;
							bn_ram_buff_gw <= 1'b0;
							bn_ram_buff_oe <= 1'b0;
							bn_ram_buff_we <= 1'b1;
							bn_ram_buff_be <= (!writefifo_addr[0])? 4'b0011 : 4'b1100;
							//bn_ram_buff_ce1 <= 1'b0;
							//b_ram_buff_ce2 <= 1'b0;
							bn_ram_buff_ce3 <= 1'b1;
							b_ram_buff_addr <= writefifo_addr[19:1];
							b_ram_buff_data <= {writefifo_data, writefifo_data};
							b_ram_buff_parity <= {4{1'b0}};
							b_ram_buff_rw <= 1'b1;
						end
					P_L_WRITE_STT_STOP:
						begin
							bn_ram_buff_adsc <= 1'b0;
							bn_ram_buff_adsp <= 1'b0; 
							bn_ram_buff_adv <= 1'b0;
							bn_ram_buff_gw <= 1'b0;
							bn_ram_buff_oe <= 1'b0;
							bn_ram_buff_we <= 1'b0;
							bn_ram_buff_be <= {4{1'b0}};
							//bn_ram_buff_ce1 <= 1'b0;
							//b_ram_buff_ce2 <= 1'b0;
							bn_ram_buff_ce3 <= 1'b1;
							b_ram_buff_addr <= {19{1'b0}};
							b_ram_buff_data <= {32{1'b0}};
							b_ram_buff_parity <= {4{1'b0}};
							b_ram_buff_rw <= 1'b0;
						end
				endcase
			end
			else if(b_main_state == P_L_MAIN_STT_READ)begin	
				case(b_read_state)
					P_L_READ_STT_IDLE:
						begin
							bn_ram_buff_adsc <= 1'b0;
							bn_ram_buff_adsp <= 1'b0; 
							bn_ram_buff_adv <= 1'b0;
							bn_ram_buff_gw <= 1'b0;
							bn_ram_buff_oe <= 1'b0;
							bn_ram_buff_we <= 1'b0;
							bn_ram_buff_be <= {4{1'b0}};
							//bn_ram_buff_ce1 <= 1'b0;
							//b_ram_buff_ce2 <= 1'b0;
							bn_ram_buff_ce3 <= 1'b0;
							b_ram_buff_addr <= {19{1'b0}};
							b_ram_buff_data <= {32{1'b0}};
							b_ram_buff_parity <= {4{1'b0}};
							b_ram_buff_rw <= 1'b0;
						end
					P_L_READ_STT_SET_ADDR:
						begin
							bn_ram_buff_adsc <= 1'b0;
							bn_ram_buff_adsp <= 1'b1; 
							bn_ram_buff_adv <= 1'b0;
							bn_ram_buff_gw <= 1'b0;
							bn_ram_buff_oe <= 1'b0;
							bn_ram_buff_we <= 1'b0;
							bn_ram_buff_be <= {4{1'b0}};
							//bn_ram_buff_ce1 <= 1'b0;
							//b_ram_buff_ce2 <= 1'b0;
							bn_ram_buff_ce3 <= 1'b1;
							b_ram_buff_addr <= b_read_addr;
							b_ram_buff_data <= {32{1'b0}};
							b_ram_buff_parity <= {4{1'b0}};
							b_ram_buff_rw <= 1'b0;
						end
					P_L_READ_STT_WAIT:
						begin
							bn_ram_buff_adsc <= 1'b0;
							bn_ram_buff_adsp <= 1'b1; 
							bn_ram_buff_adv <= 1'b1;
							bn_ram_buff_gw <= 1'b0;
							bn_ram_buff_oe <= 1'b0;
							bn_ram_buff_we <= 1'b0;
							bn_ram_buff_be <= {4{1'b0}};
							//bn_ram_buff_ce1 <= 1'b0;
							//b_ram_buff_ce2 <= 1'b0;
							bn_ram_buff_ce3 <= 1'b1;
							b_ram_buff_addr <= b_read_addr;
							b_ram_buff_data <= {32{1'b0}};
							b_ram_buff_parity <= {4{1'b0}};
							b_ram_buff_rw <= 1'b0;
						end
					P_L_READ_STT_GET_DATA:
						begin
							bn_ram_buff_adsc <= 1'b0;
							bn_ram_buff_adsp <= 1'b1; 
							bn_ram_buff_adv <= 1'b1;
							bn_ram_buff_gw <= 1'b0;
							bn_ram_buff_oe <= 1'b1;
							bn_ram_buff_we <= 1'b0;
							bn_ram_buff_be <= {4{1'b0}};
							//bn_ram_buff_ce1 <= 1'b0;
							//b_ram_buff_ce2 <= 1'b0;
							bn_ram_buff_ce3 <= 1'b1;
							b_ram_buff_addr <= b_read_addr;//{19{1'b0}};
							b_ram_buff_data <= {32{1'b0}};
							b_ram_buff_parity <= {4{1'b0}};
							b_ram_buff_rw <= 1'b0;
						end
				endcase
			end
			else begin
				bn_ram_buff_adsc <= 1'b0;
				bn_ram_buff_adsp <= 1'b0; 
				bn_ram_buff_adv <= 1'b0;
				bn_ram_buff_gw <= 1'b0;
				bn_ram_buff_oe <= 1'b0;
				bn_ram_buff_we <= 1'b0;
				bn_ram_buff_be <= {4{1'b0}};
				//bn_ram_buff_ce1 <= 1'b0;
				//b_ram_buff_ce2 <= 1'b0;
				bn_ram_buff_ce3 <= 1'b0;
				b_ram_buff_addr <= {19{1'b0}};
				b_ram_buff_data <= {32{1'b0}};
				b_ram_buff_parity <= {4{1'b0}};
				b_ram_buff_rw <= 1'b0;
			end
		end
	end
	
	/***************************************************
	Assign
	***************************************************/
	assign oSSRAM_CLOCK = iGCI_CLOCK;
	assign onSSRAM_ADSC = !bn_ram_buff_adsc;
	assign onSSRAM_ADSP = !bn_ram_buff_adsp;
	assign onSSRAM_ADV = !bn_ram_buff_adv;
	assign onSSRAM_GW = !bn_ram_buff_gw;
	assign onSSRAM_OE = !bn_ram_buff_oe;
	assign onSSRAM_WE = !bn_ram_buff_we;
	assign onSSRAM_BE = ~bn_ram_buff_be;
	assign onSSRAM_CE1 = 1'b0; //bn_ram_buff_ce1;
	assign oSSRAM_CE2 = 1'b1; //b_ram_buff_ce2;
	assign onSSRAM_CE3 = !bn_ram_buff_ce3;
	assign oSSRAM_ADDR = b_ram_buff_addr;
	assign ioSSRAM_DATA = (b_ram_buff_rw)? b_ram_buff_data : {32{1'bz}};
	assign ioSSRAM_PARITY = (b_ram_buff_rw)? b_ram_buff_parity : {4{1'bz}};
	
	//assign oDISP_DATA_VALID = iDISP_REQ;
	//assign oDISP_DATA = b_dispout_current_data;
	/*
	assign oDISP_DATA_R = {b_dispout_current_data[15:11], {5{b_dispout_current_data[11]}}};
	assign oDISP_DATA_G = {b_dispout_current_data[10:5], {4{b_dispout_current_data[5]}}};
	assign oDISP_DATA_B = {b_dispout_current_data[4:0], {5{b_dispout_current_data[0]}}};
	*/
	assign oDISP_DATA_B = {b_dispout_current_data[15:11], {5{b_dispout_current_data[11]}}};
	assign oDISP_DATA_G = {b_dispout_current_data[10:5], {4{b_dispout_current_data[5]}}};
	assign oDISP_DATA_R = {b_dispout_current_data[4:0], {5{b_dispout_current_data[0]}}};
	
	
endmodule

`default_nettype wire

