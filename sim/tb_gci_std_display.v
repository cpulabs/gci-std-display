
`timescale 1ns/ 10ps

`default_nettype none

module tb_gci_std_display;
	parameter SYS_CYCLE = 20;	//50MHz
	parameter DISP_CYCLE = 40;	//525MHz


	reg iCLOCK;
	reg inRESET;
	//BUS(DATA)-Input
	reg iDEV_REQ;		
	wire oDEV_BUSY;
	reg iDEV_RW;
	reg [31:0] iDEV_ADDR;
	reg [31:0] iDEV_DATA;
	//BUS(DATA)-Output
	wire oDEV_REQ;		
	reg iDEV_BUSY;
	wire [31:0] oDEV_DATA;
	//IRQ
	wire oDEV_IRQ_REQ;		
	reg iDEV_IRQ_BUSY; 
	wire [23:0] oDEV_IRQ_DATA; 	
	reg iDEV_IRQ_ACK;
	//Display Clock
	reg iVGA_CLOCK;
	`ifdef GCI_STD_DISPLAY_SRAM
		//SRAM
		wire onSRAM_CE;
		wire onSRAM_WE;
		wire onSRAM_OE;
		wire onSRAM_UB;
		wire onSRAM_LB;
		wire [19:0] oSRAM_ADDR;
		wire [15:0] ioSRAM_DATA;
	`elsif GCI_STD_DISPLAY_SSRAM
		//SSRAM
		wire oSSRAM_CLOCK;
		wire onSSRAM_ADSC;
		wire onSSRAM_ADSP;
		wire onSSRAM_ADC;
		wire onSSRAM_GW;
		wire onSSRAM_OE;
		wire onSSRAM_WE;
		wire [3:0] onSSRAM_BE;
		wire onSSRAM_CE1;
		wire oSSRAM_CE2;
		wire onSSRAM_CE3;
		wire [18:0] oSSRAM_ADDR;
		wire [31:0] ioSSRAM_DATA;
		wire [3:0] ioSSRAM_PARITY;
	`endif
	//Display
	wire oDISP_CLOCK;
	wire onDISP_RESET;
	wire oDISP_ENA;
	wire oDISP_BLANK;
	wire onDISP_HSYNC;
	wire onDISP_VSYNC;
	wire [9:0] oDISP_DATA_R;
	wire [9:0] oDISP_DATA_G;
	wire [9:0] oDISP_DATA_B;
	

	/********************************
	Model
	********************************/
	//VGA
	reg display_model_file_dump;
	initial display_model_file_dump = 0;
	display_model VGA_MODEL(
		.iFILE_DUMP(display_model_file_dump),
		.inSYNC_H(onDISP_HSYNC),
		.inSYNC_V(onDISP_VSYNC),
		.iDISP_R(oDISP_DATA_R),
		.iDISP_G(oDISP_DATA_G),
		.iDISP_B(oDISP_DATA_B)
	);
	
	//Memory
	`ifdef GCI_STD_DISPLAY_SRAM
		//SRAM
		is61wv102416bll #(10) SRAM_MODEL(
			.A(oSRAM_ADDR), 
			.IO(ioSRAM_DATA), 
			.CE_(onSRAM_CE), 
			.OE_(onSRAM_OE), 
			.WE_(onSRAM_WE), 
			.LB_(onSRAM_LB),
			.UB_(onSRAM_UB)
		);
	`elsif GCI_STD_DISPLAY_SSRAM
		//SSRAM
		CY7C1380_PLSCD SSRAM_MODEL(
			.ZZ(1'b0), 
			.Mode(1'b0),	//Lenear Burst 
			.ADDR(oSSRAM_ADDR), 
			.GW_N(onSSRAM_GW), 
			.BWE_N(onSSRAM_WE), 
			.BWd_N(onSSRAM_BE[3]), 
			.BWc_N(onSSRAM_BE[2]), 
			.BWb_N(onSSRAM_BE[1]), 
			.BWa_N(onSSRAM_BE[0]), 
			.CE1_N(onSSRAM_CE1), 
			.CE2(oSSRAM_CE2), 
			.CE3_N(onSSRAM_CE3), 
			.ADSP_N(onSSRAM_ADSP), 
			.ADSC_N(onSSRAM_ADSC), 
			.ADV_N(onSSRAM_ADC), 
			.OE_N(onSSRAM_OE), 
			.DQ({ioSSRAM_PARITY[3], ioSSRAM_DATA[31:24], ioSSRAM_PARITY[2], ioSSRAM_DATA[23:16], ioSSRAM_PARITY[1], ioSSRAM_DATA[15:8], ioSSRAM_PARITY[0], ioSSRAM_DATA[7:0]}), 
			.CLK(oSSRAM_CLOCK)
		);
	`endif
	
	
	integer i = 0;
	
	//Port Initial
	initial begin	
		#(SYS_CYCLE/2)begin	
			iCLOCK = 1'b1;
			inRESET = 1'b0;
			iDEV_REQ = 1'b0;
			iDEV_RW = 1'b0;
			iDEV_ADDR = 32'h0;
			iDEV_DATA = 32'h0;
			iDEV_BUSY = 1'b0;
			iDEV_IRQ_BUSY = 1'b0;
			iDEV_IRQ_ACK = 1'b0;
			iVGA_CLOCK = 1'b0;		
		end
		#(SYS_CYCLE) begin	
			inRESET = 1'b1;	
			#SYS_CYCLE;
			inRESET = 1'b0;
			#SYS_CYCLE;
			inRESET = 1'b1;
		end
	end
	
	/**************************************
	Test Vector
	**************************************/
	
	reg [7:0] b_disp_b[0:(640*480)-1]; 
	reg [7:0] b_disp_g[0:(640*480)-1];
	reg [7:0] b_disp_r[0:(640*480)-1];
	
	function [7:0] f_test_r;
		input [15:0] data;
		begin
			f_test_r = {data[4:0], {3{data[0]}}};
		end
	endfunction
	
	function [7:0] f_test_g;
		input [15:0] data;
		begin
			f_test_g = {data[10:5], {2{data[5]}}};
		end
	endfunction
	
	
	function [7:0] f_test_b;
		input [15:0] data;
		begin
			f_test_b = {data[15:11], {3{data[11]}}};
		end
	endfunction
	
	function [7:0] func_mask;
		input [8:0] data;
		begin 
			func_mask = data[7:0];
		end
	endfunction
	
	
	integer fp;
	integer l;
	initial begin
		#(500);
			//File Dump Start
		while(!vram_writend_flag)begin	
			#(200);
		end
		
		for(l = 0; l < 640*480; l = l + 1)begin
			if(!l[0])begin
				b_disp_r[l] = f_test_r({func_mask(SSRAM_MODEL.bank1[l>>1]), func_mask(SSRAM_MODEL.bank0[l>>1])});
				b_disp_g[l] = f_test_g({func_mask(SSRAM_MODEL.bank1[l>>1]), func_mask(SSRAM_MODEL.bank0[l>>1])});
				b_disp_b[l] = f_test_b({func_mask(SSRAM_MODEL.bank1[l>>1]), func_mask(SSRAM_MODEL.bank0[l>>1])});
			end
			else begin	
				b_disp_r[l] = f_test_r({func_mask(SSRAM_MODEL.bank3[l>>1]), func_mask(SSRAM_MODEL.bank2[l>>1])});
				b_disp_g[l] = f_test_g({func_mask(SSRAM_MODEL.bank3[l>>1]), func_mask(SSRAM_MODEL.bank2[l>>1])});
				b_disp_b[l] = f_test_b({func_mask(SSRAM_MODEL.bank3[l>>1]), func_mask(SSRAM_MODEL.bank2[l>>1])});
			end
		end

		
		
		
		//File Open
		fp = $fopen("dump_disp_memory.bmp", "wb");
		if(!fp)begin
			$display("File open error");
			$stop;
		end

		//File dump
		tsk_write_bmp();
		$fclose(fp);
		$stop;
		
	end
	
	
	//File Header
	reg [15:0] bfType = "BM";
	reg [31:0] bfSize = 14+40+(640*480*4);	//File Header + Info Header + PixcelData32bit
	reg [15:0] bfReserved1 = 0;
	reg [15:0] bfReserved2 = 0;
	reg [31:0] bfOffBits = 14+40;						//File Header + Info Header
	//Info Header
	reg [31:0] biSize = 40;
	reg [31:0] biWidth = 640;
	reg [31:0] biHeight = 480;
	reg [15:0] biPlanes = 1;
	reg [15:0] biBitCount = 32;
	reg [31:0] biCopmression = 0;
	reg [31:0] biSizeImage = 3780;
	reg [31:0] biXPixPerMeter = 3780;
	reg [31:0] biYPixPerMeter = 3780;
	reg [31:0] biClrUsed = 0;
	reg [31:0] biCirImportant = 0;
	//ReserveData
	reg [7:0] bBitReserved = 0;
	
	task tsk_write_bmp;
		begin
			//Write File Header	
			$fwrite(fp, "%s", bfType);
			$fwrite(fp, "%c", bfSize[7:0]);
			$fwrite(fp, "%c", bfSize[15:8]);
			$fwrite(fp, "%c", bfSize[23:16]); 
			$fwrite(fp, "%c", bfSize[31:24]); 
			$fwrite(fp, "%c", bfReserved1[7:0]);
			$fwrite(fp, "%c", bfReserved1[15:8]);
			$fwrite(fp, "%c", bfReserved2[7:0]);
			$fwrite(fp, "%c", bfReserved2[15:8]);
			$fwrite(fp, "%c", bfOffBits[7:0]);
			$fwrite(fp, "%c", bfOffBits[15:8]);
			$fwrite(fp, "%c", bfOffBits[23:16]); 
			$fwrite(fp, "%c", bfOffBits[31:24]); 
			//Write Info Header
			$fwrite(fp, "%c", biSize[7:0]);
			$fwrite(fp, "%c", biSize[15:8]);
			$fwrite(fp, "%c", biSize[23:16]); 
			$fwrite(fp, "%c", biSize[31:24]); 
			$fwrite(fp, "%c", biWidth[7:0]);
			$fwrite(fp, "%c", biWidth[15:8]);
			$fwrite(fp, "%c", biWidth[23:16]); 
			$fwrite(fp, "%c", biWidth[31:24]); 
			$fwrite(fp, "%c", biHeight[7:0]);
			$fwrite(fp, "%c", biHeight[15:8]);
			$fwrite(fp, "%c", biHeight[23:16]); 
			$fwrite(fp, "%c", biHeight[31:24]); 
			$fwrite(fp, "%c", biPlanes[7:0]);
			$fwrite(fp, "%c", biPlanes[15:8]);
			$fwrite(fp, "%c", biBitCount[7:0]); 
			$fwrite(fp, "%c", biBitCount[15:8]); 
			$fwrite(fp, "%c", biCopmression[7:0]);
			$fwrite(fp, "%c", biCopmression[15:8]);
			$fwrite(fp, "%c", biCopmression[23:16]); 
			$fwrite(fp, "%c", biCopmression[31:24]);
			$fwrite(fp, "%c", biSizeImage[7:0]);
			$fwrite(fp, "%c", biSizeImage[15:8]);
			$fwrite(fp, "%c", biSizeImage[23:16]); 
			$fwrite(fp, "%c", biSizeImage[31:24]);
			$fwrite(fp, "%c", biXPixPerMeter[7:0]);
			$fwrite(fp, "%c", biXPixPerMeter[15:8]);
			$fwrite(fp, "%c", biXPixPerMeter[23:16]); 
			$fwrite(fp, "%c", biXPixPerMeter[31:24]);
			$fwrite(fp, "%c", biYPixPerMeter[7:0]);
			$fwrite(fp, "%c", biYPixPerMeter[15:8]);
			$fwrite(fp, "%c", biYPixPerMeter[23:16]); 
			$fwrite(fp, "%c", biYPixPerMeter[31:24]);
			$fwrite(fp, "%c", biClrUsed[7:0]);
			$fwrite(fp, "%c", biClrUsed[15:8]);
			$fwrite(fp, "%c", biClrUsed[23:16]); 
			$fwrite(fp, "%c", biClrUsed[31:24]);
			$fwrite(fp, "%c", biCirImportant[7:0]);
			$fwrite(fp, "%c", biCirImportant[15:8]);
			$fwrite(fp, "%c", biCirImportant[23:16]); 
			$fwrite(fp, "%c", biCirImportant[31:24]);
			//Write Pixcel Data
			for(i = (640*480)-1; i >= 0 ; i = i - 1)begin : F_DATA_OUT
				$fwrite(fp, "%c%c%c%c", b_disp_b[i], b_disp_g[i], b_disp_r[i], bBitReserved); 
			end
		end
	endtask
	
	
	
	
	
	
	
	
	
	
	
	//VRAM Write
	reg vram_writend_flag;
	initial begin
		#0 begin
			vram_writend_flag = 0;
		end
		#(SYS_CYCLE/2)
		//Write VRAM
		#(SYS_CYCLE*20)begin
			for(i = 0; i < 640*480; i = i+1)begin
				tsk_write_data(32'hc400 + i*4, func_patgen(i%640, i/640));
			end
			vram_writend_flag = 1;
			$display("VRAM Write END");
			display_model_file_dump = 1;
		end
		
	end

	
	task tsk_write_data;
		input [31:0] addr;
		input [31:0] data;
		begin	
			iDEV_REQ = 1'b1;
			iDEV_RW = 1'b1;
			iDEV_ADDR = addr;
			iDEV_DATA = data;
			#(SYS_CYCLE);
			while(oDEV_BUSY)begin	
				#(SYS_CYCLE);
			end
			iDEV_REQ = 1'b0;
			#(SYS_CYCLE);
		end
	endtask
	
	
	
	
	function [15:0] func_patgen;
		input [9:0] func_h_addr;
		input [8:0] func_v_addr;
		reg [2:0] pri_h_case;
		reg [1:0] pri_v_case;
		reg [2:0] pri_puttern_case;
		begin
			//h
			if(func_h_addr[9:4] < 6'h5)begin
				pri_h_case = 3'H0;
			end
			else if(func_h_addr[9:4] < 6'ha)begin
				pri_h_case = 3'h1;
			end
			else if(func_h_addr[9:4] < 6'hf)begin
				pri_h_case = 3'h2;
			end
			else if(func_h_addr[9:4] < 6'h14)begin
				pri_h_case = 3'h3;
			end
			else if(func_h_addr[9:4] < 6'h19)begin
				pri_h_case = 3'h4;
			end
			else if(func_h_addr[9:4] < 6'h1e)begin
				pri_h_case = 3'h5;
			end
			else if(func_h_addr[9:4] < 6'h23)begin
				pri_h_case = 3'h6;
			end
			else begin
				pri_h_case = 3'h7;
			end
			//v
			if(func_v_addr < 9'h78)begin
				pri_v_case = 2'h0;
			end
			else if(func_v_addr < 9'hf0)begin
				pri_v_case = 2'h1;
			end
			else if(func_v_addr < 9'h168)begin
				pri_v_case = 2'h2;
			end
			else begin
				pri_v_case = 2'h3;
			end
			pri_puttern_case = pri_h_case + pri_v_case;
			case(pri_puttern_case)
				3'h0 : func_patgen = {5'hFF, 6'h00, 5'h00};
				3'h1 : func_patgen = {5'h00, 6'hFF, 5'h00};
				3'h2 : func_patgen = {5'h00, 6'h00, 5'hFF};
				3'h3 : func_patgen = {5'hFF, 6'h00, 5'hFF};
				3'h4 : func_patgen = {5'hFF, 6'hFF, 5'h00};
				3'h5 : func_patgen = {5'h00, 6'hFF, 5'hFF};
				3'h6 : func_patgen = {5'h00, 6'h00, 5'h00};
				default : func_patgen = {5'hFF, 6'hFF, 5'hFF};
			endcase
		end
	endfunction
	

	//System CLock
	always#(SYS_CYCLE/2)begin
		iCLOCK =  !iCLOCK;
	end
	
	//Display Clock
	always#(DISP_CYCLE/2)begin	
		iVGA_CLOCK = !iVGA_CLOCK;
	end

	gci_std_display TARGET(
		//System
		.iCLOCK(iCLOCK),
		.inRESET(inRESET),
		//BUS(DATA)-Input
		.iDEV_REQ(iDEV_REQ),		
		.oDEV_BUSY(oDEV_BUSY),
		.iDEV_RW(iDEV_RW),
		.iDEV_ADDR(iDEV_ADDR),
		.iDEV_DATA(iDEV_DATA),
		//BUS(DATA)-Output
		.oDEV_REQ(oDEV_REQ),		
		.iDEV_BUSY(iDEV_BUSY),
		.oDEV_DATA(oDEV_DATA),
		//IRQ
		.oDEV_IRQ_REQ(oDEV_IRQ_REQ),		
		.iDEV_IRQ_BUSY(iDEV_IRQ_BUSY), 
		.oDEV_IRQ_DATA(oDEV_IRQ_DATA), 	
		.iDEV_IRQ_ACK(iDEV_IRQ_ACK),
		//Display Clock
		.iVGA_CLOCK(iVGA_CLOCK),
		//SRAM
		`ifdef GCI_STD_DISPLAY_SRAM
			.onSRAM_CE(onSRAM_CE),
			.onSRAM_WE(onSRAM_WE),
			.onSRAM_OE(onSRAM_OE),
			.onSRAM_UB(onSRAM_UB),
			.onSRAM_LB(onSRAM_LB),
			.oSRAM_ADDR(oSRAM_ADDR),
			.ioSRAM_DATA(ioSRAM_DATA),
		`elsif GCI_STD_DISPLAY_SSRAM			
			.oSSRAM_CLOCK(oSSRAM_CLOCK),
			.onSSRAM_ADSC(onSSRAM_ADSC),
			.onSSRAM_ADSP(onSSRAM_ADSP),
			.onSSRAM_ADV(onSSRAM_ADC),
			.onSSRAM_GW(onSSRAM_GW),
			.onSSRAM_OE(onSSRAM_OE),
			.onSSRAM_WE(onSSRAM_WE),
			.onSSRAM_BE(onSSRAM_BE),
			.onSSRAM_CE1(onSSRAM_CE1),
			.oSSRAM_CE2(oSSRAM_CE2),
			.onSSRAM_CE3(onSSRAM_CE3),
			.oSSRAM_ADDR(oSSRAM_ADDR),
			.ioSSRAM_DATA(ioSSRAM_DATA),
			.ioSSRAM_PARITY(ioSSRAM_PARITY),
		`endif
		//Display
		.oDISP_CLOCK(oDISP_CLOCK),
		.onDISP_RESET(onDISP_RESET),
		.oDISP_ENA(oDISP_ENA),
		.oDISP_BLANK(oDISP_BLANK),
		.onDISP_HSYNC(onDISP_HSYNC),
		.onDISP_VSYNC(onDISP_VSYNC),
		.oDISP_DATA_R(oDISP_DATA_R),
		.oDISP_DATA_G(oDISP_DATA_G),
		.oDISP_DATA_B(oDISP_DATA_B)	
		
	);


endmodule

`default_nettype wire


