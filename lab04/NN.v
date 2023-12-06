module NN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	data_h,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
parameter round = 3'b000;
parameter inst_faithful_round = 0;
parameter float_one= 32'b00111111100000000000000000000000;
parameter float_one_tenth = 32'b00111101110011001100110011001101;


//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x,data_h;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

/* FSM declaration */
reg [0:0] counter[0:35];


/* h can be reuse to store h2 */
integer i  , j , k , l;
reg [31:0] x [0:8];
reg [31:0] h [0:2];
reg [31:0] h1 [0:2];
reg [31:0] u [0:8];
reg [31:0] w [0:8];
reg [31:0] v [0:8];
reg [31:0] a2_reg ;
reg [31:0] a3_reg ;

reg [31:0] relu_reg ;
reg [1:0] add_count;
reg [31:0] out_reg [0:2];


reg [inst_sig_width+inst_exp_width:0] mul_1_a , mul_1_b;
reg [inst_sig_width+inst_exp_width:0] mul_2_a , mul_2_b;
reg [inst_sig_width+inst_exp_width:0] mul_3_a , mul_3_b;

wire [inst_sig_width+inst_exp_width:0] m1_out, m2_out , m3_out;
wire [inst_sig_width+inst_exp_width:0] a1_out, a2_out , a3_out , a4_out;
wire [inst_sig_width+inst_exp_width:0] relu_out;

wire [7:0] status_m1, status_m2, status_m3;
wire [7:0] status_a1, status_a2, status_a3, status_a4;
wire [7:0] status_relu;
wire [7:0] status_exp;
wire [7:0] status_recip;

wire [31:0] relu_w;
wire [31:0] exp_w;
wire [31:0] exp_out;
wire [31:0] recip_out;

assign relu_w = (relu_reg[31]== 1'b1) ? float_one_tenth : float_one;
assign exp_w = (x[8][31]== 1'b1) ? {1'b0,x[8][30:0]}:{1'b1,x[8][30:0]};

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)	begin
		for(j =0 ; j < 36 ; j = j+1) begin
			counter[j] <= 1'b0;
		end
	end
	else if(counter[35]) begin
		for(j =0 ; j < 36 ; j = j+1) begin
			counter[j] <= 1'b0;
		end
	end
	else if(in_valid || counter[1] != 1'b0 ) begin
		counter[0] <= 1'b1;
		for(j = 1 ; j < 36 ; j = j+1) begin
			counter[j] <= counter[j-1];
		end
	end
	else begin
		for(j =0 ; j < 36 ; j = j+1) begin
			counter[j] <= counter[j];
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)	begin
		add_count <= 2'b0;
	end
	else if(counter[35]) begin
		add_count <= 2'b0;
	end
	else if(counter[1]) begin
		if(add_count == 2'b00)  add_count <=  2'b01;
		else if(add_count==2'b01) add_count <= 2'b10;
		else add_count <= 2'b00;
	end
	else add_count <= add_count;
end

// store input to reg
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for(i =0 ; i < 9 ; i = i+1) begin
			u[i] <= 'b0;
			w[i] <= 'b0;
			v[i] <= 'b0;
		end
	end	
	else if(counter[35]) begin
		for(i =0 ; i < 9 ; i = i+1) begin
			u[i] <= 'b0;
			w[i] <= 'b0;
			v[i] <= 'b0;
		end
	end
	else if(in_valid) begin
		u[0] <= weight_u;
		w[0] <= weight_w ;
		v[0] <= weight_v ;
		for(i = 1 ; i < 9 ; i = i+1) begin
			u[i] <= u[i-1];
			w[i] <= w[i-1];
			v[i] <= v[i-1];
		end
	end	
	else if(counter[9] && !counter[27] ) begin
		w[0] <= w[8];
		u[0] <= u[8];
		v[0] <= v[8];
		for(i = 1 ; i < 9 ; i = i+1) begin
			u[i] <= u[i-1];
			w[i] <= w[i-1];
			v[i] <= v[i-1];
		end
	end
	else if(counter[27] && !counter[28] ) begin
		for(i = 0 ; i < 9 ; i = i+1) begin
			u[i] <= 32'b0;
			w[i] <= 32'b0;
		end
	end
	else begin
		for(i =0 ; i < 9 ; i = i+1) begin
			u[i] <= u[i];
			w[i] <= w[i];
			v[i] <= v[i];
		end
	end
end

// store input to reg
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for(i =0 ; i < 9 ; i = i+1) begin
			x[i] <= 'b0;
		end
	end	
	else if(counter[35]) begin
		for(i =0 ; i < 9 ; i = i+1) begin
			x[i] <= 'b0;
		end
	end
	else if(in_valid) begin
		x[0] <= data_x ;
		for(i = 1 ; i < 9 ; i = i+1) begin
			x[i] <= x[i-1];
		end
	end
	else if((counter[29]&& !counter[30])) begin
		x[6] <= a4_out;
		x[8] <= a3_out;
	end
	else if((counter[30]&& !counter[31])) begin
		x[8] <= a3_out;
		x[7] <= exp_out;
		x[3] <= recip_out;
	end
	else if( counter[31] && !counter[32]) begin
		x[8] <= a3_out;
		x[7] <= exp_out;
		x[6] <= a4_out;
	end
	else if( counter[32] && !counter[33]) begin
		x[7] <= exp_out;
		x[6] <= a4_out;
	end
	else if((counter[33]&& !counter[34])) begin
		x[6] <= a4_out;
	end
	else if((counter[12]&& !counter[13]) || (counter[15]&& !counter[16]) || (counter[18]&& !counter[19]) || (counter[21]&& !counter[22]) || (counter[24]&& !counter[25]) || (counter[27]&& !counter[28])) begin
		if((counter[24] && !counter[25])) begin
			x[5] <= recip_out ;
		end
		if((counter[27] && !counter[28])) begin
			x[4] <= recip_out ;
		end
		x[8] <= a3_out;
	end
	else if((counter[13]&& !counter[14]) || (counter[16]&& !counter[17]) || (counter[19]&& !counter[20]) || (counter[22]&& !counter[23]) || (counter[25]&& !counter[26]) || (counter[28]&& !counter[29])) begin
		x[7] <= exp_out;
	end
	else if((counter[14]&& !counter[15]) || (counter[17]&& !counter[18]) || (counter[20]&& !counter[21]) || (counter[23]&& !counter[24]) || (counter[26]&& !counter[27]) ) begin
		x[6] <= a4_out;
	end
	else begin
		for(i =0 ; i < 9 ; i = i+1) begin
			x[i] <= x[i];
		end
	end
end
// store input to reg
always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		h[0] <= 'b0;
		h[1] <= 'b0;
		h[2] <= 'b0;
	end
	else if(counter[35]) begin
		h[0] <= 'b0;
		h[1] <= 'b0;
		h[2] <= 'b0;
	end
	else if(in_valid && !counter[2]) begin
		h[0] <= data_h;
		h[1] <= h[0];
		h[2] <= h[1];
	end
	else if(!counter[9]) begin
		h[0] <= h[2];
		h[1] <= h[0];
		h[2] <= h[1];
	end
	else if(counter[13] && !counter[14]) begin
		h[0] <= relu_out;
	end
	else if(counter[16] && !counter[17]) begin
		h[1] <= relu_out;
	end
	else if(counter[19] && !counter[20]) begin
		h[2] <= relu_out;
	end
	else begin
		h[0] <= h[0];
		h[1] <= h[1];
		h[2] <= h[2];
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		h1[0] <= 'b0;
		h1[1] <= 'b0;
		h1[2] <= 'b0;
	end	
	else if(counter[35]) begin
		h1[0] <= 'b0;
		h1[1] <= 'b0;
		h1[2] <= 'b0;
	end
	else if(counter[4] && !counter[5]) begin
		h1[0] <= relu_out;
	end
	else if(counter[7] && !counter[8]) begin
		h1[1] <= relu_out;
	end	
	else if(counter[10] && !counter[11]) begin
		h1[2] <= relu_out;
	end
	else if(counter[22] && !counter[23]) begin
		h1[0] <= relu_out;
	end
	else if(counter[25] && !counter[26]) begin
		h1[1] <= relu_out;
	end	
	else if(counter[28] && !counter[29]) begin
		h1[2] <= relu_out;
	end
	else begin
		h1[0] <= h1[0];
		h1[1] <= h1[1];
		h1[2] <= h1[2];
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mul_1_a <= 32'b0;
	else if(counter[35]) begin
 		mul_1_a <= 32'b0;
	end
	else if(counter[9] == 1'b0) begin
		mul_1_a <= u[0];
	end
	else if(counter[27] == 1'b0) begin
		mul_1_a <= u[8];
	end
	else if(!counter[28]) begin
		mul_1_a <= v[8];
	end
	else if(!counter[29]) begin
		mul_1_a <= v[5];
	end
	else if(!counter[30]) begin
		mul_1_a <= v[2];
	end
	else mul_1_a <= mul_1_a;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mul_1_b <= 32'b0;
	else if(counter[35]) begin
 		mul_1_b <= 32'b0;
	end
	else if(counter[9] == 1'b0) begin
		if(counter[3] == 1'b0) begin
			mul_1_b <= x[0];
		end
		else if(counter[6]== 1'b0)begin
			mul_1_b <= x[3];
		end
		else begin
			mul_1_b <= x[6];
		end
	end
	else if(counter[18] == 1'b0) begin
		if((!counter[10])||(counter[12]&&!counter[13])||(counter[15]&&!counter[16])) begin
			mul_1_b <= x[5];
		end
		else if((counter[10]&&!counter[11])||(counter[13]&&!counter[14])||(counter[16]&&!counter[17])) begin
			mul_1_b <= x[4];
		end
		else begin
			mul_1_b <= x[3];
		end
	end
	else if(counter[27] == 1'b0) begin
		if((!counter[19])||(counter[21]&&!counter[22])||(counter[24]&&!counter[25])) begin
			mul_1_b <= x[2];
		end
		else if((counter[19]&&!counter[20])||(counter[22]&&!counter[23])||(counter[25]&&!counter[26])) begin
			mul_1_b <= x[1];
		end
		else begin
			mul_1_b <= x[0];
		end
	end
	else if(!counter[30]) begin
		mul_1_b <= h1[0];
	end
	else mul_1_b <= mul_1_b;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mul_2_a <= 32'b0;
	else if(counter[35]) begin
 		mul_2_a <= 32'b0;
	end
	else if(counter[9] == 1'b0) begin
		mul_2_a <= w[0];
	end
	else if(counter[27] == 1'b0) begin
		mul_2_a <= w[8];
	end
	else if(!counter[28]) begin
		mul_2_a <= v[7];
	end
	else if(!counter[29]) begin
		mul_2_a <= v[4];
	end
	else if(!counter[30]) begin
		mul_2_a <= v[1];
	end
	else mul_2_a <= mul_2_a;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mul_2_b <= 32'b0;
	else if(counter[35]) begin
 		mul_2_b <= 32'b0;
	end
	else if(counter[9] == 1'b0) begin
		mul_2_b <= h[0];
	end
	else if(counter[18] == 1'b0) begin
		if(!counter[10] | (counter[12]&& !counter[13]) | (counter[15] && !counter[16]))begin
			mul_2_b <= h1[0];
		end
		else  if((counter[10]&& !counter[11]) | (counter[13]&& !counter[14]) | (counter[16] && !counter[17]))begin
			mul_2_b <= h1[1];
		end
		else begin
			mul_2_b <= h1[2];
		end
	end
	else if(counter[27] == 1'b0) begin
		if(!counter[19] | (counter[21]&& !counter[22]) | (counter[24] && !counter[25]))begin
			mul_2_b <= h[0];
		end
		else if((counter[19]&& !counter[20]) | (counter[22]&& !counter[23]) | (counter[25] && !counter[26]))begin
			mul_2_b <= h[1];
		end
		else begin
			mul_2_b <= h[2];
		end
	end
	else if(!counter[30]) begin
		mul_2_b <= h1[1];
	end
	else mul_2_b <= mul_2_b;
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mul_3_a <= 32'b0;
	else if(counter[35]) begin
 		mul_3_a <= 32'b0;
	end
	else if(counter[9] && !counter[27]) begin
		mul_3_a <= v[8];
	end
	else if(!counter[28]) begin
		mul_3_a <= 32'b0;
	end
	else if(!counter[29]) begin
		mul_3_a <= v[6];
	end
	else if(!counter[30]) begin
		mul_3_a <= v[3];
	end
	else if(!counter[31]) begin
		mul_3_a <= v[0];
	end
	else mul_3_a <= mul_3_a;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mul_3_b <= 32'b0;
	else if(counter[35]) begin
 		mul_3_b <= 32'b0;
	end
	else if(counter[9] && counter[18] == 1'b0) begin
		if((!counter[10]) | (counter[12]&& !counter[13]) | (counter[15] && !counter[16]))begin
			mul_3_b <= h1[0];
		end
		else if((counter[10]&& !counter[11]) | (counter[13]&& !counter[14]) | (counter[16] && !counter[17]))begin
			mul_3_b <= h1[1];
		end
		else begin
			mul_3_b <= h1[2];
		end
	end
	else if(counter[27] == 1'b0) begin
		if((!counter[19]) | (counter[21]&& !counter[22]) | (counter[24] && !counter[25]))begin
			mul_3_b <= h[0];
		end
		else if((counter[19]&& !counter[20]) | (counter[22]&& !counter[23]) | (counter[25] && !counter[26]))begin
			mul_3_b <= h[1];
		end
		else begin
			mul_3_b <= h[2];
		end
	end
	else if(!counter[28]) begin
		mul_3_b <= 32'b0;
	end
	else if(!counter[29])begin
		mul_3_b <= relu_out;
	end
	else if(!counter[31]) begin
		mul_3_b <= h1[2];
	end
	else mul_3_b <= mul_3_b;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) a2_reg <= 32'b0;
	else if(counter[35]) begin
 		a2_reg <= 32'b0;
	end
	else if(add_count != 2'b10) begin
		a2_reg <= a2_out;
	end
	else a2_reg <= 32'b0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) a3_reg <= 32'b0;
	else if(counter[35]) begin
 		a3_reg <= 32'b0;
	end
	else if((counter[28]&& !counter[29])) begin
		a3_reg <= a1_out;
	end
	else if((counter[29]&& !counter[30])) begin
		a3_reg <= a1_out;
	end
	else if((counter[30]&& !counter[31])) begin
		a3_reg <= a1_out;
	end
	else if(add_count != 2'b10) begin
		a3_reg <= a3_out;
	end
	else a3_reg <= 32'b0;
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		relu_reg <= 32'b0;
	end
	else if(counter[35]) begin
 		relu_reg <= 32'b0;
	end
	else if(add_count == 2'b10) begin
		relu_reg <= a2_out;
	end
	else relu_reg <= relu_reg;
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		for(k=0 ; k < 3 ; k=k+1) begin
			out_reg[k] <= 32'b0;
		end
	end
	else if(counter[35]) begin
 		for(k=0 ; k < 3 ; k=k+1) begin
			out_reg[k] <= 32'b0;
		end
	end
	else if((counter[15]&& !counter[16])) begin
		out_reg[0] <= recip_out ;
	end
	else if((counter[18] && !counter[19])) begin
		out_reg[1] <= recip_out ;
	end
	else if((counter[21] && !counter[22])) begin
		out_reg[2] <= recip_out ;
	end


end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 1'b0;
	else if(counter[35])begin
		out_valid <= 1'b0;
	end
	else if(counter[26]&& !counter[27]) begin
		out_valid <= 1'b1;
	end
	else out_valid <= out_valid;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out <= 32'b0;
	else if(counter[26]&& !counter[27]) out <= out_reg[0];
	else if(counter[27]&& !counter[28]) out <= out_reg[1];
	else if(counter[28]&& !counter[29]) out <= out_reg[2];
	else if(counter[29]&& !counter[30]) out <= x[5];
	else if(counter[30]&& !counter[31]) out <= x[4];
	else if(counter[31]&& !counter[32]) out <= x[3];
	else if(counter[32]&& !counter[33]) out <= recip_out;
	else if(counter[33]&& !counter[34]) out <= recip_out;
	else if(counter[34]&& !counter[35]) out <= recip_out;
	else if(counter[35])				out <= 1'b0;
	else out <= out;
end

DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) mul_1(.a(mul_1_a), .b(mul_1_b), .rnd(round), .z(m1_out), .status(status_m1));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) mul_2(.a(mul_2_a), .b(mul_2_b), .rnd(round), .z(m2_out), .status(status_m2));
DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) mul_3(.a(mul_3_a), .b(mul_3_b), .rnd(round), .z(m3_out), .status(status_m3));

DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance) add_1(.a(m1_out), .b(m2_out), .rnd(round), .z(a1_out), .status(status_a1));
DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance) add_2(.a(a2_reg), .b(a1_out), .rnd(round), .z(a2_out), .status(status_a2));
DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance) add_3(.a(a3_reg), .b(m3_out), .rnd(round), .z(a3_out), .status(status_a3));

DW_fp_mult #(inst_sig_width,inst_exp_width,inst_ieee_compliance) relu(.a(relu_w), .b(relu_reg), .rnd(round), .z(relu_out), .status(status_relu));


DW_fp_exp #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch) exp(.a(exp_w), .z(exp_out), .status(status_exp));
DW_fp_add #(inst_sig_width,inst_exp_width,inst_ieee_compliance) add_4(.a(x[7]), .b(float_one), .rnd(round), .z(a4_out), .status(status_a3));
DW_fp_recip #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_faithful_round) recip(.a(x[6]), .rnd(round), .z(recip_out), .status(status_recip));

endmodule

