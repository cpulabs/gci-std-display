
`timescale 1ns/10ps
`default_nettype none


module display_model #(
		/**********************************************
		640x480 60Hz VGA Monitor for default parameter 
		**********************************************/
		parameter P_DOT_CYCLE = 40,	//25MHz
		//Counter Width
		parameter P_H_AREA = 640,
		parameter P_V_AREA = 480,
		//Hsync
		parameter P_THP = 95,	//Hsync pulse width.(Unit:NCLK)
		parameter P_THB = 48,	//To Hsync - data width.(Unit:NCLK) 
		parameter P_THF = 15,	//To data - next Hsync width.(Unit:NCLK) 
		//Vsync
		parameter P_TVP = 2,	//Vsync pulse width.(Unit:HSYNC)
		parameter P_TVB = 33,	//To Vsync - active data area width.(Unit:HSYNC) 
		parameter P_TVF = 10	//To active data area - next Vsync width.(Unit:HSYNC) 
	)(
		input wire iFILE_DUMP,
		input wire inSYNC_H,
		input wire inSYNC_V,
		input wire [7:0] iDISP_R,
		input wire [7:0] iDISP_G,
		input wire [7:0] iDISP_B
	);

	
	integer i, j;
	reg [7:0] b_disp_r[0:(P_H_AREA*P_V_AREA)-1];
	reg [7:0] b_disp_g[0:(P_H_AREA*P_V_AREA)-1];
	reg [7:0] b_disp_b[0:(P_H_AREA*P_V_AREA)-1];
	
	//Hsync-THP Check
	integer hsync_thp_time;
	reg hsync_thp_check_end;
	initial begin
		hsync_thp_time = 0;
		hsync_thp_check_end = 0;
		//Wait
		#(P_DOT_CYCLE/2);
		while(inSYNC_H == 0 || inSYNC_H == 1'bx)begin
			#(P_DOT_CYCLE);
		end
		while(inSYNC_H == 1)begin
			#(P_DOT_CYCLE);
		end
		//THP
		while(!inSYNC_H)begin
			hsync_thp_time = hsync_thp_time + 1;
			#(P_DOT_CYCLE);
		end
		if(hsync_thp_time != P_THP)begin
			$display("[ERROR][display_model] : THP Error. Correct%d, Fact%d", P_THP, hsync_thp_time);
			$stop;
		end
		$display("[OK][display_model] : HSYNC THP Timing OK");
		hsync_thp_check_end = 1;
	end
	
	//Hsync-other timing Check
	integer hsync_other_time;
	reg hsync_other_check_end;
	initial begin
		hsync_other_time = 0;
		hsync_other_check_end = 0;
		//Wait
		#(P_DOT_CYCLE/2);
		while(inSYNC_H == 0 || inSYNC_H == 1'bx)begin
			#(P_DOT_CYCLE);
		end
		//THB or P_H_AREA or THF
		while(inSYNC_H)begin
			hsync_other_time = hsync_other_time + 1;
			#(P_DOT_CYCLE);
		end
		if(hsync_other_time != (P_THB+P_H_AREA+P_THF))begin
			$display("[ERROR][display_model] : THB or P_H_AREA or THF Error. Correct%d, Fact%d", (P_THB+P_H_AREA+P_THF), hsync_other_time);
			$stop;
		end
		$display("[OK][display_model] : HSYNC THP, P_H_AREA, THF OK");
		hsync_other_check_end = 1;
	end
		
		

	//Vsync Check
	integer vsync_time;
	reg vsync_check_end;
	initial begin
		vsync_time = 0;
		vsync_check_end = 0;
		//Wait
		#(P_DOT_CYCLE);
		while(!inSYNC_V || inSYNC_V == 1'bx)begin
			#(P_DOT_CYCLE);
		end
		while(inSYNC_V)begin
			#(P_DOT_CYCLE);
		end
		//TVP
		while(!inSYNC_V)begin
			#(P_DOT_CYCLE);
			vsync_time = vsync_time + 1;
		end
		if(vsync_time != P_TVP*(P_THP+P_THB+P_H_AREA+P_THF))begin
			$display("[ERROR][display_model] : TVP Error. Correct%d, Fact%d", P_TVP*(P_THP+P_THB+P_H_AREA+P_THF), vsync_time);
			$stop;
		end
		else begin
			$display("[OK][display_model] : TVP OK");
		end
		vsync_time = 0;
		//TVB, P_V_AREA, TVF
		while(inSYNC_V)begin
			#(P_DOT_CYCLE);
			vsync_time = vsync_time + 1;
		end
		if(vsync_time != (P_TVB+P_V_AREA+P_TVF)*(P_THP+P_THB+P_H_AREA+P_THF))begin
			$display("[ERROR][display_model] : TVB or P_V_AREA or TVF Error. Correct%d, Fact%d", (P_TVB+P_V_AREA+P_TVF)*(P_THP+P_THB+P_H_AREA+P_THF), vsync_time);
			$stop;
		end
		else begin
			$display("[OK][display_model] : TVP, P_V_AREA, TVF OK");
		end
		$display("[OK][display_model] : Hsync Timing OK");
		vsync_check_end = 1;
	end

	integer fp;
	initial begin
		#(P_DOT_CYCLE);
			//File Dump Start
		while(!iFILE_DUMP)begin	
			#(P_DOT_CYCLE);
		end
		//H, V sync check wait
		while(!hsync_thp_check_end ||!hsync_other_check_end || !vsync_check_end)begin	
			#(P_DOT_CYCLE);
		end
		//File Open
		fp = $fopen("dump_disp.bmp", "wb");
		if(!fp)begin
			$display("File open error");
			$stop;
		end
		//Memory Reset
		for(i = 0; i < P_H_AREA*P_V_AREA; i = i + 1)begin : MEM_RESET
			b_disp_r[i] = 8'h0;
			b_disp_g[i] = 8'h0;
			b_disp_b[i] = 8'h0;
		end
		i = 0;
		//Waif Vsync
		while(inSYNC_V || inSYNC_V == 1'bx)begin
			#(P_DOT_CYCLE);
		end
		#(P_DOT_CYCLE*(P_THP+P_THB+P_H_AREA+P_THF)*P_TVB);
		//Get Data
		while(i < P_H_AREA*P_V_AREA)begin
			j = 0;
			while(j < P_H_AREA)begin
				b_disp_r[i] = iDISP_R;
				b_disp_g[i] = iDISP_G;
				b_disp_b[i] = iDISP_B;
				i = i + 1;
				j = j + 1;
				#(P_DOT_CYCLE);
			end
			//Hsync Wait
			while(inSYNC_H)begin
				#(P_DOT_CYCLE);
			end
			while(!inSYNC_H)begin
				#(P_DOT_CYCLE);
			end
			#(P_DOT_CYCLE*P_THB);
		end
		//File dump
		tsk_write_bmp();
		$fclose(fp);
		$stop;
	end
	
	
	//File Header
	reg [15:0] bfType = "BM";
	reg [31:0] bfSize = 14+40+(P_V_AREA*P_H_AREA*4);	//File Header + Info Header + PixcelData32bit
	reg [15:0] bfReserved1 = 0;
	reg [15:0] bfReserved2 = 0;
	reg [31:0] bfOffBits = 14+40;						//File Header + Info Header
	//Info Header
	reg [31:0] biSize = 40;
	reg [31:0] biWidth = P_H_AREA;
	reg [31:0] biHeight = P_V_AREA;
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
			for(i = (P_V_AREA*P_H_AREA)-1; i >= 0 ; i = i - 1)begin : F_DATA_OUT
				$fwrite(fp, "%c%c%c%c", b_disp_b[i], b_disp_g[i], b_disp_r[i], bBitReserved); 
			end
		end
	endtask
	
endmodule

`default_nettype wire

