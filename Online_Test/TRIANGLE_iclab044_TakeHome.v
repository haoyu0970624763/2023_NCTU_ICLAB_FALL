//synopsys translate_off
`include "DW_div.v"
`include "DW_div_seq.v"
`include "DW_div_pipe.v"
//synopsys translate_on

module TRIANGLE(
    clk,
    rst_n,
    in_valid,
    in_length,
    out_cos,
    out_valid,
    out_tri
);
input wire clk, rst_n, in_valid;
input wire [7:0] in_length;

output reg out_valid;
output reg [15:0] out_cos;
output reg [1:0] out_tri;

parameter inst_a_width = 31;
parameter inst_b_width = 18;
parameter inst_tc_mode = 1;
parameter inst_num_cyc = 10;
parameter inst_rst_mode = 0;
parameter inst_input_mode = 1;
parameter inst_output_mode = 1;
parameter inst_early_start = 0;

reg [7:0] len [0:2];

reg signed [30:0] up_extend [0:2];
reg signed [17:0] down [0:2];

reg [2:0] in_flag;
reg [1:0] out_flag;
reg [3:0] count;

reg hold;
reg start;

wire [0:0] complete [0:2];
wire [0:0] devide_by_zero [0:2];

wire signed [30:0] quotient_w  [0:2];
wire signed [17:0] remainder_w [0:2];


DW_div_seq #(inst_a_width, inst_b_width, inst_tc_mode, inst_num_cyc,
inst_rst_mode, inst_input_mode, inst_output_mode,inst_early_start)
div (.clk(clk),
.rst_n(rst_n),
.hold(hold),
.start(start),
.a(up_extend[0]),
.b(down[0]),
.complete(complete[0]),
.divide_by_0(devide_by_zero[0]),
.quotient(quotient_w[0]),
.remainder(remainder_w[0]));

DW_div_seq #(inst_a_width, inst_b_width, inst_tc_mode, inst_num_cyc,
inst_rst_mode, inst_input_mode, inst_output_mode,inst_early_start)
div_2 (.clk(clk),
.rst_n(rst_n),
.hold(hold),
.start(start),
.a(up_extend[1]),
.b(down[1]),
.complete(complete[1]),
.divide_by_0(devide_by_zero[1]),
.quotient(quotient_w[1]),
.remainder(remainder_w[1]));

DW_div_seq #(inst_a_width, inst_b_width, inst_tc_mode, inst_num_cyc,
inst_rst_mode, inst_input_mode, inst_output_mode,inst_early_start)
div_3 (.clk(clk),
.rst_n(rst_n),
.hold(hold),
.start(start),
.a(up_extend[2]),
.b(down[2]),
.complete(complete[2]),
.divide_by_0(devide_by_zero[2]),
.quotient(quotient_w[2]),
.remainder(remainder_w[2]));

always @(posedge clk or negedge rst_n) begin

	if(!rst_n) begin
		in_flag <= 2'b00;
	end
	else if(count == 4'd13 && out_flag == 2'd3) in_flag <= 2'b00;
	else if(in_valid) begin
		if(in_flag == 2'b00) in_flag <= 2'b01;
		else if(in_flag == 2'b01 ) in_flag <= 2'b10;
		else if(in_flag == 2'b10 ) in_flag <= 2'b11;
	end
	else if(in_flag == 2'b11) in_flag <= 3'b100;
	else if(in_flag == 3'b100) in_flag <= 3'b101;
	else if(in_flag == 3'b101) in_flag <= 3'b110;
end


always @(posedge clk or negedge rst_n) begin

	if(!rst_n) begin
		len[0] <= 2'b00;
		len[1] <= 2'b00;
		len[2] <= 2'b00;
	end
	else if(in_valid) begin
		if(in_flag == 2'b00) len[0] <= in_length;
		else if(in_flag == 2'b01 ) len[1] <= in_length;
		else len[2] <= in_length;
	end

end

always @(posedge clk or negedge rst_n) begin

	if(!rst_n) begin
		up_extend[0] <= 'b0;
		up_extend[1] <= 'b0;
		up_extend[2] <= 'b0;
	end
	else if(in_flag == 2'b11) begin
		up_extend[0] <= ((len[1] * len[1] + len[2]*len[2] - len[0]*len[0]) << 13);
		up_extend[1] <= ((len[0] * len[0] + len[2]*len[2] - len[1]*len[1]) << 13);
		up_extend[2] <= ((len[0] * len[0] + len[1]*len[1] - len[2]*len[2]) << 13);
	end

end

always @(posedge clk or negedge rst_n) begin

	if(!rst_n) begin
		down[0] <= 16'b0;
		down[1] <= 16'b0;
		down[2] <= 16'b0;
	end
	else if(in_flag == 2'b11) begin
		down[0] <= 2 * len[1] * len[2];
		down[1] <= 2 * len[0] * len[2];
		down[2] <= 2 * len[0] * len[1];
	end

end

always @(posedge clk or negedge rst_n) begin

	if( !rst_n) hold <= 1'b0;
	else if(in_flag == 3'b100) hold <= 1'b1;
	else if(in_flag == 3'b101) hold <= 1'b0;

end

always @(posedge clk or negedge rst_n) begin
	if( !rst_n) start <= 1'b0;
	else if(in_flag == 3'b100) start <= 1'b1;
	else if(in_flag == 3'b101) start <= 1'b0;
end

always @(posedge clk or negedge rst_n) begin
	if( !rst_n) count <= 1'b0;
	else if(count == 4'd13 && out_flag == 2'd3) count <= 'b0;
	else if(in_flag >= 3'b100 && count!= 4'd13) count <= count+1;
end


always @(posedge clk or negedge rst_n) begin

	if(!rst_n) out_flag <= 'b0;
	else if(count == 4'd13 && out_flag == 2'd3) out_flag <= 'b0;
	else if(out_flag == 2'd3) out_flag  <= 'b0;
	else if(count >= 4'd12 && out_flag != 2'd3) out_flag <= out_flag+1;

end

always @(posedge clk or negedge rst_n) begin

	if(!rst_n) out_valid <= 'b0;
	else if(count == 4'd13 && out_flag == 2'd3) out_valid <= 'b0;
	else if(count == 4'd12) out_valid <= 1'b1;
	else out_valid <= out_valid;

end


always @(posedge clk or negedge rst_n) begin

	if(!rst_n) out_cos <= 'b0;
	else if(count == 4'd13 && out_flag == 2'd3) out_cos <= 'b0;
	else if(count >= 4'd12) begin
		if(quotient_w[out_flag] < 0) begin
			out_cos <= (quotient_w[out_flag][12:0]) | 17'h1e000;
		end
		else begin
			out_cos <= quotient_w[out_flag][12:0];
		end
	end
	else out_cos <= out_cos;

end

always @(posedge clk or negedge rst_n) begin

	if(!rst_n) out_tri <= 'b0;
	else if(count == 4'd13) out_tri <= 'b0;
	else if(count == 4'd12) begin
		if(quotient_w[0]=='b0 || quotient_w[1]=='b0 || quotient_w[2]=='b0 ) out_tri <= 2'd3;
		else if(quotient_w[0] < 0 || quotient_w[1] < 0 || quotient_w[2] < 0 ) out_tri <= 2'd1;
		else out_tri <= 2'd0;
	end
	else out_tri <= out_tri;

end

endmodule
