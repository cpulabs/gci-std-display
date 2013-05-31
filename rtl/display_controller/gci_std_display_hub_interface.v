
`default_nettype none

module gci_std_display_hub_interface(
		//System
		input wire iCLOCK,
		input wire inRESET,
		input wire iRESET_SYNC,			
		//HUB(Reqest/Write)
		input wire iHUB_REQ,
		output wire oHUB_BUSY,
		input wire iHUB_RW,
		input wire [31:0] iHUB_ADDR,
		input wire [31:0] iHUB_DATA,
		//HUB(Read)
		output wire oHUB_VALID,
		input wire iHUB_BUSY,
		output wire oHUB_DATA,
		//Register(Request/Write)
		output wire oREG_ENA,
		output wire oREG_RW,
		output wire [3:0] oREG_ADDR,
		output wire [31:0] oREG_DATA,
		//Register(Read)
		input wire iREG_VALID,
		output wire oREG_BUSY,
		input wire [31:0] iREG_DATA,
		//Command(Request/Write)
		output wire oCOMM_VALID,
		output wire oCOMM_SEQ,
		input wire iCOMM_BUSY,
		output wire oCOMM_RW,
		output wire [31:0] oCOMM_ADDR,
		output wire [31:0] oCOMM_DATA,
		//Command(Read)
		input wire iCOMM_VALID,
		output wire oCOMM_BUSY,
		input wire [31:0] iCOMM_ADDR,
		input wire [23:0] iCOMM_DATA
	);

	//Register / Command -> Hub
	assign oHUB_BUSY = 
	assign oHUB_VALID = 
	assign oHUB_DATA = 
	//Hub -> Register
	assign oREG_ENA = register_ctrl_condition;
	assign oREG_RW = iHUB_RW;
	assign oREG_ADDR = iHUB_ADDR;
	assign oREG_DATA = iHUB_DATA;
	assign oREG_BUSY = 
	//Hub -> Command
	assign oCOMM_VALID = display_ctrl_condition || sequence_ctrl_condition;
	assign oCOMM_SEQ = sequence_ctrl_condition;
	assign oCOMM_RW = iHUB_RW;
	assign oCOMM_ADDR = iHUB_ADDR;
	assign oCOMM_DATA = iHUB_DATA;
	assign oCOMM_BUSY = 
	
	
	
	
	wire register_busy_condition = 
	wire display_busy_condition = 
	wire sequence_busy_condition = 
	
	wire register_ctrl_condition = iHUB_ADDR <= 32'hF && (iHUB_ADDR == 32'h4)? !iHUB_RW : 1'b1;
	wire display_ctrl_condition = iHUB_ADDR > 32'hF;
	wire sequence_ctrl_condition = (iHUB_ADDR == 32'h4) && iHUB_RW;
	
	localparam P_L_MAIN_STT_WRITE = 1'b0;
	localparam P_L_MAIN_STT_READ_WAIT = 1'b1;
	
	
	reg b_main_state;
	always@(posedge iCLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_main_state <= P_L_MAIN_STT_WRITE;
		end
		else if(iRESET_SYNC)begin
			b_main_state <= P_L_MAIN_STT_WRITE;
		end
		else begin
			case(b_main_state)
				P_L_MAIN_STT_WRITE:
					begin
						if(!iHUB_RW)begin
							b_main_state <= P_L_MAIN_STT_READ_WAIT;
						end
					end
				P_L_MAIN_STT_READ_WAIT:
					begin
						if(!iHUB_BUSY && ())begin
							b_main_state <= P_L_MAIN_STT_WRITE;
						end
					end
			endcase
		end
	end
	
	
	assign oIF_WR_BUSY = (iIF_WR_RW)? ??? : 
	
	
	
endmodule

`default_nettype wire
