// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input cg_en;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;


integer i , i2 , i3 , i4;
integer j , j2 , j3;
integer k;
integer l;

reg [2:0] counter;
reg [2:0] counter2;

reg [1:0] counter3;
reg [1:0] counter4;

reg [2:0] counter5;
reg [2:0] counter6;

reg img1_finish;
reg img2_finish;
reg weight_finish;
reg ker_finish;
reg convolution_start;
reg pooling_start;
reg fully_start;
reg first_finish;
reg second_finish;
reg reset_finish;

reg [7:0] img1_reg [0:5][0:5];
reg [7:0] img2_reg [0:5][0:5];
reg [7:0] ker_reg [0:2][0:2];
reg [7:0] weight_reg [0:3];
reg [1:0] convolution_row_index;
reg [1:0] convolution_col_index;
reg [7:0] quantization_reg [0:3][0:3];
reg [7:0] pooling_reg [0:3];
reg [7:0] final_reg [0:3];
reg [9:0] result_reg;

wire [7:0] operand1 [0:8];
wire [15:0] mul_result [0:8];
wire [19:0] sum_result;
wire [12:0] divisor1;
wire [8:0] divisor2;
wire [7:0] quantization_result;
wire [7:0] pooling_input [0:15];
wire [7:0] compare_tmp [0:11];

wire [7:0] operand2 [0:1];
wire [15:0] mul_result2 [0:1];
wire [16:0] sum_result2;
wire [7:0] final2_w;
wire [7:0] Distance;

assign operand1[0] = convolution_start ? (!reset_finish ? img1_reg[convolution_col_index][convolution_row_index]: img2_reg[convolution_col_index][convolution_row_index]): 0;
assign operand1[1] = convolution_start ? (!reset_finish ? img1_reg[convolution_col_index][convolution_row_index+1]: img2_reg[convolution_col_index][convolution_row_index+1]): 0;
assign operand1[2] = convolution_start ? (!reset_finish ? img1_reg[convolution_col_index][convolution_row_index+2]: img2_reg[convolution_col_index][convolution_row_index+2]): 0;
assign operand1[3] = convolution_start ? (!reset_finish ? img1_reg[convolution_col_index+1][convolution_row_index]: img2_reg[convolution_col_index+1][convolution_row_index]): 0;
assign operand1[4] = convolution_start ? (!reset_finish ? img1_reg[convolution_col_index+1][convolution_row_index+1]: img2_reg[convolution_col_index+1][convolution_row_index+1]): 0;
assign operand1[5] = convolution_start ? (!reset_finish ? img1_reg[convolution_col_index+1][convolution_row_index+2]: img2_reg[convolution_col_index+1][convolution_row_index+2]): 0;
assign operand1[6] = convolution_start ? (!reset_finish ? img1_reg[convolution_col_index+2][convolution_row_index]: img2_reg[convolution_col_index+2][convolution_row_index]): 0;
assign operand1[7] = convolution_start ? (!reset_finish ? img1_reg[convolution_col_index+2][convolution_row_index+1]: img2_reg[convolution_col_index+2][convolution_row_index+1]): 0;
assign operand1[8] = convolution_start ? (!reset_finish ? img1_reg[convolution_col_index+2][convolution_row_index+2]: img2_reg[convolution_col_index+2][convolution_row_index+2]): 0;

assign mul_result[0] = operand1[0] *  ker_reg[0][0];
assign mul_result[1] = operand1[1] *  ker_reg[0][1];
assign mul_result[2] = operand1[2] * ker_reg[0][2];
assign mul_result[3] = operand1[3] * ker_reg[1][0];
assign mul_result[4] = operand1[4] * ker_reg[1][1];
assign mul_result[5] = operand1[5] * ker_reg[1][2];
assign mul_result[6] = operand1[6] * ker_reg[2][0];
assign mul_result[7] = operand1[7] * ker_reg[2][1];
assign mul_result[8] = operand1[8] * ker_reg[2][2];

assign sum_result = mul_result[0]+mul_result[1]+mul_result[2]+mul_result[3]+mul_result[4]+mul_result[5]+mul_result[6]+mul_result[7]+mul_result[8];
assign divisor1 = 13'd2295;
assign divisor2 = 9'd510;
assign quantization_result = sum_result / divisor1;

assign pooling_input[0] = quantization_reg[0][0];
assign pooling_input[1] = quantization_reg[0][1];
assign pooling_input[2] = quantization_reg[1][0];
assign pooling_input[3] = quantization_reg[1][1];
assign pooling_input[4] = quantization_reg[0][2];
assign pooling_input[5] = quantization_reg[0][3];
assign pooling_input[6] = quantization_reg[1][2];
assign pooling_input[7] = quantization_reg[1][3];
assign pooling_input[8] = quantization_reg[2][0];
assign pooling_input[9] = quantization_reg[2][1];
assign pooling_input[10] = quantization_reg[3][0];
assign pooling_input[11] = quantization_reg[3][1];
assign pooling_input[12] = quantization_reg[2][2];
assign pooling_input[13] = quantization_reg[2][3];
assign pooling_input[14] = quantization_reg[3][2];
assign pooling_input[15] = quantization_reg[3][3];

assign compare_tmp[0] = (pooling_input[0] > pooling_input[1]) ? pooling_input[0] : pooling_input[1];
assign compare_tmp[1] = (pooling_input[2] > pooling_input[3]) ? pooling_input[2] : pooling_input[3];
assign compare_tmp[2] = (compare_tmp[0] > compare_tmp[1]) ? compare_tmp[0] : compare_tmp[1];

assign compare_tmp[3] = (pooling_input[4] > pooling_input[5]) ? pooling_input[4] : pooling_input[5];
assign compare_tmp[4] = (pooling_input[6] > pooling_input[7]) ? pooling_input[6] : pooling_input[7];
assign compare_tmp[5] = (compare_tmp[3] > compare_tmp[4]) ? compare_tmp[3] : compare_tmp[4];

assign compare_tmp[6] = (pooling_input[8] > pooling_input[9]) ? pooling_input[8] : pooling_input[9];
assign compare_tmp[7] = (pooling_input[10] > pooling_input[11]) ? pooling_input[10] : pooling_input[11];
assign compare_tmp[8] = (compare_tmp[6] > compare_tmp[7]) ? compare_tmp[6] : compare_tmp[7];

assign compare_tmp[9] = (pooling_input[12] > pooling_input[13]) ? pooling_input[12] : pooling_input[13];
assign compare_tmp[10] = (pooling_input[14] > pooling_input[15]) ? pooling_input[14] : pooling_input[15];
assign compare_tmp[11] = (compare_tmp[9] > compare_tmp[10]) ? compare_tmp[9] : compare_tmp[10];


assign operand2[0] = (counter3 == 2'd0 || counter3 == 2'd2) ? weight_reg[0] : weight_reg[1];
assign operand2[1] = (counter3 == 2'd0 || counter3 == 2'd2) ? weight_reg[2] : weight_reg[3];
assign mul_result2[0] = operand2[0] * pooling_reg[counter4];
assign mul_result2[1] = operand2[1] * pooling_reg[counter4+1];
assign sum_result2 = mul_result2[0] + mul_result2[1];
assign final2_w = sum_result2 / divisor2;
assign Distance = (final_reg[counter3] >= final2_w) ? final_reg[counter3] - final2_w : final2_w - final_reg[counter3];



wire count_clk;
GATED_OR GATED_count(.CLOCK(clk), .SLEEP_CTRL( ~(in_valid | out_valid) & cg_en && img2_finish), .RST_N(rst_n), .CLOCK_GATED(count_clk));

always @(posedge count_clk or negedge rst_n ) begin
	if(!rst_n) begin
		counter <= 'b0;
		counter2 <= 'b0;
	end
	else if(out_valid) begin
		counter <= 'b0;
		counter2 <= 'b0;
	end
    else if(in_valid) begin
		if(counter2 == 3'd5) begin
			if(counter == 3'd5) begin
				counter <= 'b0;
			end
			else begin
				counter <= counter +1;
			end
			counter2 <= 'b0;
		end
		else begin
			counter2 <= counter2 + 1;
		end
	end
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		counter3 <= 'b0;
		counter4 <= 'b0;
	end
	else if(out_valid) begin
		counter3 <= 'b0;
		counter4 <= 'b0;
	end
	else if(img2_finish && !reset_finish) begin
		counter3 <= 'b0;
		counter4 <= 'b0;
	end
    else if(in_valid && !ker_finish) begin
		if(counter4 == 2'd2) begin
			if(counter3 != 2'd2) begin
				counter3 <= counter3 +1;
			end
			counter4 <= 'b0;
		end
		else begin
			counter4 <= counter4 + 1;
		end
	end
	else if(ker_finish && !img1_finish) begin
		counter3 <= 'b0;
	end
	else if(fully_start ) begin	
		counter3 <= counter3 +1;
		if(counter3 == 2'd1) counter4 <= 2'd2;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		counter5 <= 'b0;
		counter6 <= 'b0;
	end
	else if(out_valid) begin
		counter5 <= 'b0;
		counter6 <= 'b0;
	end
	else if(img2_finish && !reset_finish) begin
		counter5 <= 'b0;
		counter6 <= 'b0;
	end
	else if(convolution_start) begin
		if(counter5 == 3'd3) begin
			counter5 <= 'b0;
		end
		else begin
			counter5 <= counter5 +1;
		end

		if(pooling_start) begin
			if(counter6 == 2'd1) begin
				counter6 <= 'b0;
			end
			else begin
				counter6 <= counter6 +1;
			end
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		img1_finish <= 'b0;
	end
	else if(out_valid) begin
		img1_finish <= 'b0;
	end
    else if(counter == 3'd5  && counter2== 3'd5) begin
		if(!img1_finish) begin
			img1_finish <= 'b1;
		end
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		img2_finish <= 'b0;
	end
	else if(out_valid) begin
		img2_finish <= 'b0;
	end
    else if(counter == 3'd5  && counter2== 3'd5) begin
		if(img1_finish) begin
			img2_finish <= 'b1;
		end
	end
end

wire ker_clk;
GATED_OR GATED_ker(.CLOCK(clk), .SLEEP_CTRL( ~out_valid & cg_en  & ker_finish), .RST_N(rst_n), .CLOCK_GATED(ker_clk));

always @(posedge ker_clk or negedge rst_n) begin
	if(!rst_n) begin
		ker_finish <= 'b0;
	end
	else if(out_valid) begin
		ker_finish <= 'b0;
	end
    else if(counter3 == 2'd2  && counter4== 2'd2) begin
		ker_finish <= 1'b1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		convolution_start <= 1'b0;
	end
	else if((img2_finish && !reset_finish) || out_valid) begin
		convolution_start <= 1'b0;
	end
    else if(img1_finish) begin
		convolution_start <= 1'b1;
	end
end

wire in1_reg_clk;
GATED_OR GATED_in1_reg(.CLOCK(clk), .SLEEP_CTRL(cg_en & img1_finish), .RST_N(rst_n), .CLOCK_GATED(in1_reg_clk));
always @(posedge in1_reg_clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0 ; i < 6 ; i = i+1 )begin
			for( j = 0 ; j < 6 ; j = j+1) begin
				img1_reg[i][j] <= 'b0;
			end
		end
	end
    else if(in_valid && !img1_finish) begin
		img1_reg[counter][counter2] <= img;
	end
end

wire in2_reg_clk;
GATED_OR GATED_in2_reg(.CLOCK(clk), .SLEEP_CTRL((cg_en & ~img1_finish) | !in_valid ), .RST_N(rst_n), .CLOCK_GATED(in2_reg_clk));
always @(posedge in2_reg_clk or negedge rst_n) begin
	if(!rst_n) begin
		for(k = 0 ; k < 6 ; k = k+1 )begin
			for( l = 0 ; l < 6 ; l = l+1) begin
				img2_reg[k][l] <= 'b0;
			end
		end
	end
    else if(in_valid && img1_finish) begin
		img2_reg[counter][counter2] <= img;
	end
end

wire ker_reg_clk;
GATED_OR GATED_ker_reg(.CLOCK(clk), .SLEEP_CTRL( cg_en & ker_finish), .RST_N(rst_n), .CLOCK_GATED(ker_reg_clk));

always @(posedge ker_reg_clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i2 = 0 ; i2 < 3 ; i2 = i2+1 )begin
			for( j2 = 0 ; j2 < 3 ; j2 = j2+1) begin
				ker_reg[i2][j2] <= 'b0;
			end
		end
	end
    else if(in_valid &&  !ker_finish ) begin
		ker_reg[counter3][counter4] <= ker;
	end
end

wire weight_clk;
GATED_OR GATED_weight(.CLOCK(clk), .SLEEP_CTRL( ~out_valid & cg_en  & weight_finish), .RST_N(rst_n), .CLOCK_GATED(weight_clk));

always @(posedge weight_clk or negedge rst_n) begin
	if(!rst_n) begin
		weight_finish <= 1'b0;
	end
	else if(out_valid) begin 
		weight_finish <= 1'b0;
	end
    else if( counter2 == 3'd3  ) begin
		weight_finish <= 1'b1;
	end
end

wire weight_reg_clk;
GATED_OR GATED_weight_reg(.CLOCK(clk), .SLEEP_CTRL( cg_en & weight_finish), .RST_N(rst_n), .CLOCK_GATED(weight_reg_clk));

always @(posedge weight_reg_clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i3 = 0 ; i3 < 4 ; i3 = i3+1 )begin
			weight_reg[i3] <= 'b0;
		end
	end
    else if(in_valid && !weight_finish ) begin
		weight_reg[counter2] <= weight;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		convolution_row_index <= 'b0;
		convolution_col_index <= 'b0;
	end
	else if((img2_finish && !reset_finish) || out_valid) begin
		convolution_row_index <= 'b0;
		convolution_col_index <= 'b0;
	end
	else if((convolution_start && !pooling_start)) begin
		convolution_row_index <= convolution_row_index +1 ;
		if(counter5 == 3'd3) begin
			convolution_col_index <= convolution_col_index + 1 ;
		end
	end
	else if(pooling_start) begin
		convolution_row_index <= 'b0;
		convolution_col_index <= 'b0;
	end
end

wire quantization_reg_clk;
GATED_OR GATED_quantization_reg(.CLOCK(clk), .SLEEP_CTRL( (cg_en & !convolution_start) | pooling_start), .RST_N(rst_n), .CLOCK_GATED(quantization_reg_clk));

always @(posedge quantization_reg_clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i4 = 0 ; i4 < 4 ; i4 = i4+1 )begin
			for( j3 = 0 ; j3 < 4 ; j3 = j3+1) begin
				quantization_reg[i4][j3] <= 'b0;
			end
		end
	end
	else if(convolution_start) begin
		quantization_reg[convolution_col_index][convolution_row_index] <= quantization_result;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		pooling_start <= 1'b0;
	end
	else if((img2_finish && !reset_finish) || out_valid) begin
		pooling_start <= 1'b0;
	end
	else if(convolution_col_index == 2'd3 && convolution_row_index == 2'd3) begin
		pooling_start <= 1'b1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		fully_start <= 1'b0;
	end
	else if((img2_finish && !reset_finish) || out_valid) begin
		fully_start <= 1'b0;
	end
	else if(pooling_start) begin
		fully_start <= 1'b1;
	end
end

wire pooling_reg_clk;
GATED_OR GATED_pooling_reg(.CLOCK(clk), .SLEEP_CTRL( (cg_en & !pooling_start) || fully_start), .RST_N(rst_n), .CLOCK_GATED(pooling_reg_clk));
always @(posedge pooling_reg_clk or negedge rst_n) begin
	if(!rst_n) begin
		pooling_reg[0] <= 'b0; 
		pooling_reg[1] <= 'b0; 
		pooling_reg[2] <= 'b0; 
		pooling_reg[3] <= 'b0; 
	end
	else if(pooling_start && !fully_start) begin
		pooling_reg[0] <= compare_tmp[2]; 
		pooling_reg[1] <= compare_tmp[5];  
		pooling_reg[2] <= compare_tmp[8];  
		pooling_reg[3] <= compare_tmp[11]; 
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		first_finish <= 1'b0;
	end	
	else if(out_valid) begin
		first_finish <= 1'b0;
	end
	else if(counter3 == 2'd3 && fully_start) begin
		first_finish <= 1'b1;
	end
end

wire final_reg_clk;
GATED_OR GATED_final(.CLOCK(clk), .SLEEP_CTRL( (cg_en & first_finish) || !img1_finish), .RST_N(rst_n), .CLOCK_GATED(final_reg_clk));
always @(posedge final_reg_clk or negedge rst_n) begin
	if(!rst_n) begin
		final_reg[0] <= 'b0; 
		final_reg[1] <= 'b0; 
		final_reg[2] <= 'b0; 
		final_reg[3] <= 'b0; 
	end
	else if(fully_start && !first_finish) begin
		final_reg[counter3] <= sum_result2 / divisor2;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		result_reg <= 'b0;
	end
	else if(out_valid) result_reg <= 'b0;
	else if(fully_start && !second_finish && reset_finish ) begin
		result_reg <= result_reg + Distance;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		second_finish <= 1'b0;
	end
	else if(out_valid) begin
		second_finish <= 1'b0;
	end
	else if(counter3 == 2'd3 && fully_start && reset_finish) begin
		second_finish <= 1'b1;
	end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		reset_finish <= 1'b0;
	end
	else if(out_valid) reset_finish <= 1'b0;
	else if(img2_finish) begin
		reset_finish <= 1'b1;
	end
end

wire [9:0] result_w;
assign result_w = (result_reg <= 4'd15) ? 'b0 : result_reg;

always @(*) begin
	if(!rst_n) out_valid = 'b0;
	else if(second_finish) out_valid = 1'b1;
    else out_valid = 'b0;
end

always @(*) begin
	if(!rst_n) out_data = 'b0;
	else if(second_finish) begin
		out_data = result_w;
	end
    else out_data = 'b0;
end

endmodule