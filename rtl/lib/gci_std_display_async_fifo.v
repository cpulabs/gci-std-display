/**************************************************************************
Async Fifo
	
-parameter P_N
	Queue data vector width
	Example : DATA[3:0] is P_N=4

-parameter P_DEPTH
	Queue entry depth
	Example P_DEPTH 16 is P_DEPTH=16

-parameter P_DEPTH_N
	Queue entry depth n size
	Example PARAMETER_DEPTH16 is 4
	
-SDF Settings
	Asynchronus Clock : iWR_CLOCK - iRD_CLOCK
	
-Make	: 2013/2/13
-Update	: 

Takahiro Ito
**************************************************************************/

`default_nettype none

module gci_std_display_async_fifo #(
		parameter P_N = 16,
		parameter P_DEPTH = 4,
		parameter P_DEPTH_N = 2
	)(
		//System
		input inRESET,
		//Remove
		input iREMOVE,
		//WR
		input iWR_CLOCK,
		input iWR_EN,
		input [P_N-1:0] iWR_DATA,
		output oWR_FULL,
		//RD
		input iRD_CLOCK,
		input iRD_EN,
		output [P_N-1:0] oRD_DATA,
		output oRD_EMPTY
	);	

	//Full
	wire [P_DEPTH_N:0] full_count;
	wire full;
	wire [P_DEPTH_N:0] empty_count;
	wire empty;
	//Memory
	reg [P_N-1:0] b_memory[0:P_DEPTH-1];
	//Counter
	reg [P_DEPTH_N:0] b_wr_counter/* synthesis preserve = 1 */;		//Altera QuartusII Option
	reg [P_DEPTH_N:0] b_rd_counter/* synthesis preserve = 1 */;		//Altera QuartusII Option
	wire [P_DEPTH_N:0] gray_d_fifo_rd_counter;
	wire [P_DEPTH_N:0] binary_d_fifo_rd_counter;
	wire [P_DEPTH_N:0] gray_d_fifo_wr_counter;
	wire [P_DEPTH_N:0] binary_d_fifo_wr_counter;
	
	//Assign
	assign full_count = b_wr_counter - binary_d_fifo_rd_counter;
	assign full = full_count[P_DEPTH_N] || (full_count[P_DEPTH_N-1:0] == {P_DEPTH_N{1'b1}})? 1'b1 : 1'b0;
	//Empty
	assign empty_count = binary_d_fifo_wr_counter - (b_rd_counter);	
	assign empty = (empty_count == {P_DEPTH_N+1{1'b0}})? 1'b1 : 1'b0;
	
	/***************************************************
	Memory
	***************************************************/	
	//Write
	always@(posedge iWR_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_wr_counter <= {P_DEPTH_N{1'b0}};
		end
		else if(iREMOVE)begin
			b_wr_counter <= {P_DEPTH_N{1'b0}};
		end
		else begin
			if(iWR_EN && !full)begin
				b_memory[b_wr_counter[P_DEPTH_N-1:0]] <= iWR_DATA;
				b_wr_counter <= b_wr_counter + {{P_DEPTH_N-1{1'b0}}, 1'b1};
			end
		end
	end
	
	//Read Pointer
	always@(posedge iRD_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_rd_counter <= {P_DEPTH_N{1'b0}};
		end
		else if(iREMOVE)begin
			b_rd_counter <= {P_DEPTH_N{1'b0}};
		end
		else begin
			if(iRD_EN && !empty)begin
				b_rd_counter <= b_rd_counter + {{P_DEPTH_N-1{1'b0}}, 1'b1};
			end
		end
	end
	
	
	/***************************************************
	Counter Buffer
	***************************************************/	
	gci_std_display_async_fifo_double_flipflop #(P_DEPTH_N+1) D_FIFO_READ(
		.iCLOCK(iWR_CLOCK),
		.inRESET(inRESET),
		.iREQ_DATA(bin2gray(b_rd_counter)),
		.oOUT_DATA(gray_d_fifo_rd_counter)
	);
	assign binary_d_fifo_rd_counter = gray2bin(gray_d_fifo_rd_counter);
	
	
	gci_std_async_display_fifo_double_flipflop #(P_DEPTH_N+1) D_FIFO_WRITE(
		.iCLOCK(iRD_CLOCK),
		.inRESET(inRESET),
		.iREQ_DATA(bin2gray(b_wr_counter)),
		.oOUT_DATA(gray_d_fifo_wr_counter)
	);
	assign binary_d_fifo_wr_counter = gray2bin(gray_d_fifo_wr_counter);
	
	/***************************************************
	Function
	***************************************************/
	function [P_DEPTH_N:0] bin2gray;
		input [P_DEPTH_N:0] binary;
		begin
			bin2gray = binary ^ (binary >> 1'b1);
		end
	endfunction
	

	function[P_DEPTH_N:0] gray2bin(input[P_DEPTH_N:0] gray);
		integer i;
		for(i=P_DEPTH_N; i>=0; i=i-1)begin
			if(i==P_DEPTH_N)begin
				gray2bin[i] = gray[i];
			end
			else begin
				gray2bin[i] = gray[i] ^ gray2bin[i+1];
			end
		end
	endfunction
	
	
	/***************************************************
	Output Assign
	***************************************************/	
	assign oWR_FULL = full;
	assign oRD_EMPTY = empty;
	assign oRD_DATA = b_memory[b_rd_counter[P_DEPTH_N-1:0]];
	
				
endmodule

`default_nettype wire
