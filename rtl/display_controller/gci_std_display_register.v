
`default_nettype none

module gci_std_display_register #(
		parameter P_VRAM_SIZE = 307200	//VGA
	(
		input wire iCLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,
		//Write
		input wire iWR_VALID,
		input wire [3:0] iWR_ADDR,
		input wire [31:0] iWR_DATA,
		//Read
		input wire iRD_VALID,
		output wire oRD_BUSY,
		input wire [3:0] iRD_ADDR,
		output wire oRD_VALID,
		input wire iRD_BUSY,
		output wire [31:0] oRD_DATA,
		//Info
		output oINFO_CHARACTER,
		output [1:0] oINFO_COLOR
	);
	
	localparam P_L_REG_ADDR_RESOLUT = 4'h0;
	localparam P_L_REG_ADDR_MODE = 4'h2;
	localparam P_L_REG_ADDR_SIZE = 4'h3;
	
	wire ds_resolut_write_condition = iWR_VALID && iWR_ADDR == P_L_REG_ADDR_RESOLUT;
	wire ds_mode_write_condition = iWR_VALID && iWR_ADDR == P_L_REG_ADDR_MODE;
	
	
	//RESOLUTION
	reg [11:0] b_ds_resolut_h;
	reg [11:0] b_ds_resolut_v;
	reg [6:0] b_ds_resolut_refresh;
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_ds_resolut_h <= 12'h0;
			b_ds_resolut_v <= 12'h0;
			b_ds_resolut_refresh <= 7'h0;
		end
		else if(!iRESET_SYNC)begin
			b_ds_resolut_h <= 12'h0;
			b_ds_resolut_v <= 12'h0;
			b_ds_resolut_refresh <= 7'h0;
		end
		else begin
			if(ds_resolut_write_condition)begin
				b_ds_resolut_h <= iWR_DATA[11:1];
				b_ds_resolut_v <= iWR_DATA[23:12];
				b_ds_resolut_refresh <= iWR_DATA[30:24];
			end
		end
	end
	wire [31:0] ds_resolut_data = {1'b0, b_ds_resolut_refresh, b_ds_resolut_v, b_ds_resolut_h};
	
	//MODE
	reg [1:0] b_ds_mode_color;
	reg b_ds_mode_character;
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_ds_mode_color <= 2'h0;
			b_ds_mode_character <= 1'b0;
		end
		else if(!iRESET_SYNC)begin
			b_ds_mode_color <= 2'h0;
			b_ds_mode_character <= 1'b0;
		end
		else begin
			if(ds_mode_write_condition)begin
				b_ds_mode_color <= iWR_DATA[2:1];
				b_ds_mode_character <= iWR_DATA[0];
			end
		end
	end
	wire [31:0] ds_mode_data = {29'h0, b_ds_mode_color, b_ds_mode_character};
	
	//SIZE
	wire [31:0] ds_size_data = P_VRAM_SIZE;
	
	/************************************************
	Read 
	************************************************/
	reg b_read_valid;
	reg [31:0] b_read_buffer;
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_read_valid <= 1'b0;
			b_read_buffer <= 32'h0;
		end
		else if(iRESET_SYNC)begin
			b_read_valid <= 1'b0;
			b_read_buffer <= 32'h0;
		end
		else begin
			if(!iRD_BUSY)begin
				b_read_valid <= iRD_VALID;
				case(iRD_ADDR)
					P_L_REG_ADDR_RESOLUT : b_read_buffer <= ds_resolut_data;
					P_L_REG_ADDR_MODE : b_read_buffer <= ds_mode_data;
					P_L_REG_ADDR_SIZE : b_read_buffer <= ds_size_data;
					default : b_read_buffer <= 32'h0;
				endcase
			end
		end
	end
	
	assign oRD_BUSY = iRD_BUSY;
	assign oRD_VALID = !iRD_BUSY && b_read_valid;
	assign oRD_DATA = b_read_buffer;

	assign oINFO_CHARACTER = b_ds_mode_character;
	assign oINFO_COLOR = b_ds_mode_color;
	
endmodule

`default_nettype wire

	