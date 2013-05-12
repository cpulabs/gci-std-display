`default_nettype none
//Display Clock = NCLK is 25MHz



module gci_std_display_timing_generator #(
		/**********************************************
		640x480 60Hz VGA Monitor for default parameter 
		**********************************************/
		//Counter Width
		parameter P_H_WIDTH = 10,
		parameter P_V_WIDTH = 10,
		//Area
		parameter P_AREA_H = 640,
		parameter P_AREA_V = 480,
		//Hsync
		parameter P_THP = 95,	//Hsync pulse width.(Unit:NCLK)
		parameter P_THB = 48,	//To Hsync - data width.(Unit:NCLK) 
		parameter P_THF = 15,	//To data - next Hsync width.(Unit:NCLK) 
		//Vsync
		parameter P_TVP = 2,	//Vsync pulse width.(Unit:HSYNC)
		parameter P_TVB = 33,	//To Vsync - active data area width.(Unit:HSYNC) 
		parameter P_TVF = 10	//To active data area - next Vsync width.(Unit:HSYNC) 
	)(
		input wire iDISP_CLOCK,	//25MHz @640x480 60Hz
		input wire inRESET,
		input wire iRESET_SYNC,
		//PIXCEL
		output wire oDATA_REQ,
		output wire oDATA_SYNC,	
		//DISP Out
		output wire onDISP_RESET,
		output wire oDISP_ENA,	
		output wire oDISP_BLANK,
		output wire onDISP_VSYNC,
		output wire onDISP_HSYNC
	);
	
	reg [P_H_WIDTH-1:0] b_hsync_counter;
	reg [P_V_WIDTH-1:0] b_vsync_counter;
	reg bn_disp_reset;
	
	wire hsync_restart_condition = !(b_hsync_counter < (P_THP + P_THB + P_AREA_H + P_THF-1));
	wire vsync_restart_condition = !(b_vsync_counter < (P_TVP + P_TVB + P_AREA_V + P_TVF-1));
	wire data_active_condition = func_data_enable_area(b_hsync_counter, b_vsync_counter);
	wire hsync_active_condition = func_hsync_enable_area(b_hsync_counter);
	wire vsync_active_condition = func_vsync_enable_area(b_vsync_counter);
	
	function func_data_enable_area;
		input [P_H_WIDTH-1:0] func_hsync;
		input [P_V_WIDTH-1:0] func_vsync;
		begin
			//HSYNC Check
			if(func_hsync >= (P_THP + P_THB) && func_hsync < (P_THP + P_THB + P_AREA_H))begin
				//VSYNC Check
				if(func_vsync >= (P_TVP + P_TVB) && func_vsync < (P_TVP + P_TVB + P_AREA_V))begin
					func_data_enable_area = 1'b1;
				end
				else begin
					func_data_enable_area = 1'b0;
				end
			end
			else begin
				func_data_enable_area = 1'b0;
			end
		end
	endfunction
	
	function func_hsync_enable_area;
		input [P_H_WIDTH-1:0] func_hsync;
		begin
			//HSYNC Check
			if(func_hsync < P_THP)begin
				func_hsync_enable_area = 1'b1;
			end
			else begin
				func_hsync_enable_area = 1'b0;
			end
		end
	endfunction
	
	function func_vsync_enable_area;
		input [P_H_WIDTH-1:0] func_vsync;
		begin
			//HSYNC Check
			if(func_vsync < P_TVP)begin
				func_vsync_enable_area = 1'b1;
			end
			else begin
				func_vsync_enable_area = 1'b0;
			end
		end
	endfunction
	
		
	/*********************************
	Sync Counter
	*********************************/
	//H-SYNC Cunter	
	always@(posedge iDISP_CLOCK or negedge inRESET)begin	
		if(!inRESET)begin	
			b_hsync_counter <= {P_H_WIDTH{1'b0}}; 
		end
		else if(iRESET_SYNC)begin	
			b_hsync_counter <= {P_H_WIDTH{1'b0}}; 
		end
		else begin
			if(hsync_restart_condition)begin
				b_hsync_counter <= {P_H_WIDTH{1'b0}};
			end
			else begin
				b_hsync_counter <= b_hsync_counter + {{P_H_WIDTH-1{1'b0}}, 1'b1};
			end
		end
	end
	
	//VSYNC Counter
	always@(posedge iDISP_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			b_vsync_counter <= {P_V_WIDTH{1'b0}}; 
		end
		else if(iRESET_SYNC)begin
			b_vsync_counter <= {P_V_WIDTH{1'b0}};
		end
		else begin
			if(hsync_restart_condition)begin
				if(vsync_restart_condition)begin
					b_vsync_counter <= {P_V_WIDTH{1'b0}}; 
				end
				else begin
					b_vsync_counter <= b_vsync_counter + {{P_V_WIDTH-1{1'b0}}, 1'b1};
				end
			end
		end
	end
	
	
	/*********************************
	Display Reset
	*********************************/
	always@(posedge iDISP_CLOCK or negedge inRESET)begin
		if(!inRESET)begin
			bn_disp_reset <= 1'b0;
		end
		else if(iRESET_SYNC)begin
			bn_disp_reset <= 1'b0;
		end
		else begin
			bn_disp_reset <= 1'b1;
		end
	end
	
	assign oDATA_REQ = data_active_condition;
	assign oDATA_SYNC = vsync_restart_condition;
	assign onDISP_RESET = bn_disp_reset;
	assign oDISP_ENA = data_active_condition;
	assign oDISP_BLANK = !data_active_condition;
	assign onDISP_HSYNC = !hsync_active_condition;
	assign onDISP_VSYNC = !vsync_active_condition;
	
	
	/*********************************
	Property Check
	*********************************/
	//`define GCI_STD_DISPLAY_SVA_ASSERTION
	`ifdef GCI_STD_DISPLAY_SVA_ASSERTION
		//THP Check
		property THP_CHECK;
			@(posedge iDISP_CLOCK) 
				disable iff (!inRESET) 
				($past(onDISP_HSYNC, 1) and !onDISP_HSYNC) |-> (!onDISP_HSYNC[*P_THP] and ##(P_THP)onDISP_HSYNC);
		endproperty
		
		assert property(THP_CHECK)else begin
			$display("[Error][Assertion] : THP - Start%d, End%d", $past(onDISP_HSYNC, P_THP), onDISP_HSYNC);
			$stop;
		end	
		//THB + P_AREA_H + P_THF Check
		property THB_HAREA_THF_CHECK;
			@(posedge iDISP_CLOCK) 
				disable iff (!inRESET) 
				(!$past(oDISP_ENA, 1) and oDISP_ENA) |-> (onDISP_HSYNC[*(P_THB+P_AREA_H+P_THF)]);// and ##(P_THB+P_AREA_H+P_THF)!onDISP_HSYNC);
		endproperty
		assert property(THB_HAREA_THF_CHECK)else begin
			$display("[Error][Assertion] : Display Area-H - Start%d, End%d", $past(onDISP_HSYNC, (P_THB+P_AREA_H+P_THF)), onDISP_HSYNC);
			$stop;
		end	
		//P_AREA_H Check
		property HAREA_CHECK;
			@(posedge iDISP_CLOCK) 
				disable iff (!inRESET) 
				(!$past(oDISP_ENA, 1) and oDISP_ENA) |-> (oDISP_ENA[*P_AREA_H] and ##(P_AREA_H)!oDISP_ENA);
		endproperty
		
		assert property(HAREA_CHECK)else begin
			$display("[Error][Assertion] : Display Area-H - Start%d, End%d", $past(oDISP_ENA, P_THP), oDISP_ENA);
			$stop;
		end	
		
		//TVP Check
		property TVP_CHECK;
			@(posedge iDISP_CLOCK) 
				disable iff (!inRESET) 
				($past(onDISP_VSYNC, 1) and !onDISP_VSYNC) |-> (!onDISP_VSYNC[*(P_TVP*(P_THP+P_THB+P_AREA_H+P_THF))] and ##((P_TVP*(P_THP+P_THB+P_AREA_H+P_THF)))onDISP_VSYNC);
		endproperty
		
		assert property(TVP_CHECK)else begin
			$display("[Error][Assertion] : TVP - Start%d, End%d", $past(onDISP_VSYNC, (P_TVP*(P_THP+P_THB+P_AREA_H+P_THF))), onDISP_VSYNC);
			$stop;
		end	
			
		
	`endif
	
endmodule

`default_nettype wire
