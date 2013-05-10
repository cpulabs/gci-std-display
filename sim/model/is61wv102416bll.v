
//IS61WV102416BLL-10 Simulation Model

// `define OEb
`timescale 1ns/10ps

module is61wv102416bll (A, IO, CE_, OE_, WE_, LB_, UB_);

parameter SPEED_RANK = 10;

/*
generate 
	if(SPEED_RANK == 8)begin
		localparam dqbits = 16;
		localparam memdepth = 1048576;	//1M bit
		localparam addbits = 20;
		localparam Taa   = 8;
		localparam Toha  = 3;
		localparam Thzce = 3;
		localparam Tsa   = 0;
		localparam Thzwe = 4;
	end
	else if(SPEED_RANK == 10)begin
		localparam dqbits = 16;
		localparam memdepth = 1048576;	//1M bit
		localparam addbits = 20;
		localparam Taa   = 10;
		localparam Toha  = 3;
		localparam Thzce = 4;
		localparam Tsa   = 0;
		localparam Thzwe = 5;
	end
	else begin	//20ns
		localparam dqbits = 16;
		localparam memdepth = 1048576;	//1M bit
		localparam addbits = 20;
		localparam Taa   = 20;
		localparam Toha  = 3;
		localparam Thzce = 8;
		localparam Tsa   = 0;
		localparam Thzwe = 9;
	end
endgenerate
*/

		localparam dqbits = 16;
		localparam memdepth = 1048576;	//1M bit
		localparam addbits = 20;
		localparam Taa   = 10;
		localparam Toha  = 3;
		localparam Thzce = 4;
		localparam Tsa   = 0;
		localparam Thzwe = 5;

/*
parameter dqbits = 16;
parameter memdepth = 1048576;	//1M bit
parameter addbits = 20;
parameter Taa   = 10;
parameter Toha  = 3;
parameter Thzce = 4;
parameter Tsa   = 0;
parameter Thzwe = 5;
*/

input CE_, OE_, WE_, LB_, UB_;
input [(addbits - 1) : 0] A;
inout [(dqbits - 1) : 0] IO;
 
wire [(dqbits - 1) : 0] dout;
reg  [(dqbits/2 - 1) : 0] bank0 [0 : memdepth];
reg  [(dqbits/2 - 1) : 0] bank1 [0 : memdepth];
// wire [(dqbits - 1) : 0] memprobe = {bank1[A], bank0[A]};

wire r_en = WE_ & (~CE_) & (~OE_);
wire w_en = (~WE_) & (~CE_) & ((~LB_) | (~UB_));
assign #(r_en ? Taa : Thzce) IO = r_en ? dout : 16'bz;   

assign dout [(dqbits/2 - 1) : 0]        = LB_ ? 8'bz : bank0[A];
assign dout [(dqbits - 1) : (dqbits/2)] = UB_ ? 8'bz : bank1[A];


/*
int i;
initial 
 #0 begin
 	for(i = 0; i < 640*480; i = i + 1)begin
 		if(i < (640*480)/2)begin
			{bank1[i], bank0[i]} = {5'hFF, 6'h00, 5'h00}; 
		end
		else begin
			{bank1[i], bank0[i]} = {5'h0, 6'h00, 5'hFF};
		end
	end
end

*/

always @(A or w_en)
  begin
    #Tsa
    if (w_en)
      #Thzwe
      begin
        bank0[A] = LB_ ? bank0[A] : IO [(dqbits/2 - 1) : 0];
        bank1[A] = UB_ ? bank1[A] : IO [(dqbits - 1)   : (dqbits/2)];
		
      end
  end
  
 
specify

  specparam

    tSA   = 0,
    tAW   = 8,
    tSCE  = 8,
    tSD   = 6,
    tPWE2 = 8,
    tPWE1 = 8,
    tPBW  = 8;

  $setup (A, negedge CE_, tSA);
  $setup (A, posedge CE_, tAW);
  $setup (IO, posedge CE_, tSD);
  $setup (A, negedge WE_, tSA);
  $setup (IO, posedge WE_, tSD);
  $setup (A, negedge LB_, tSA);
  $setup (A, negedge UB_, tSA);

  $width (negedge CE_, tSCE);
  $width (negedge LB_, tPBW);
  $width (negedge UB_, tPBW);
  `ifdef OEb
  $width (negedge WE_, tPWE1);
  `else
  $width (negedge WE_, tPWE2);
  `endif 

endspecify

endmodule

