//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : EC_TOP.v
//   	Module Name : EC_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "INV_IP.v"
//synopsys translate_on

module EC_TOP(
    // Input signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Output signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [6-1:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
output reg out_valid;
output reg [6-1:0] out_Rx, out_Ry;

parameter IP_WIDTH =6;

reg [5:0] p_reg [0:1];
reg [5:0] q_reg [0:1];
reg [5:0] prime_reg;
reg [5:0] prime_w;

reg same_flag_w;
reg same_flag;

reg [0:0] count [0:4];
integer i;

reg signed [14:0] s_up_w;
reg signed [7:0] s_down_w;

reg [5:0] s_up_mod_w;
reg [5:0] s_down_mod_w;

reg [5:0] s_up_mod_reg;
reg [5:0] s_down_mod_reg;

reg [5:0] reg_1;

reg [5:0] mul_left_input_w;
reg [5:0] mul_right_input_w;

reg [12:0] mul_result_w;

reg [13:0] mod_input_w;

reg [13:0] minus_1_w;
reg [13:0] minus_2_w;

reg [5:0]  mod_result_w;
wire [5:0] INV_out_w;


reg [5:0] x_r;


INV_IP #(.IP_WIDTH(IP_WIDTH)) I_INV_IP ( .IN_1(s_down_mod_reg), .IN_2(prime_reg), .OUT_INV(INV_out_w));

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        for(i=0 ; i <= 4 ; i=i+1 ) begin
            count[i] <= 1'b0;
        end
    end
    else if(count[4]) begin
        for(i=0 ; i <= 4 ; i=i+1 ) begin
            count[i] <= 1'b0;
        end
    end
    else if(in_valid || count[0])begin
        count[0] <= 1'b1;
        for(i=1 ; i <= 4 ; i=i+1 ) begin
            count[i] <= count[i-1];
        end
    end

end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        p_reg[0] <= 'b0;
        p_reg[1] <= 'b0;
    end
    else if(in_valid)begin
        p_reg[0] <= in_Px;
        p_reg[1] <= in_Py;
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        q_reg[0] <= 'b0;
        q_reg[1] <= 'b0;
    end
    else if(in_valid)begin
        q_reg[0] <= in_Qx;
        q_reg[1] <= in_Qy;
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)  prime_reg <= 'b0;
    else if(in_valid) prime_reg <= in_prime;
end

always @(*) begin
    if((in_Px == in_Qx) && (in_Py==in_Qy)) same_flag_w = 1'b1;
    else same_flag_w = 1'b0;
end

always @(*) begin
    if(in_valid) prime_w = in_prime;
    else prime_w  = prime_reg;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)  same_flag <= 'b0;
    else if(in_valid) same_flag <= same_flag_w;
    else same_flag <= same_flag ;
end

always @(*) begin
    if(same_flag_w) begin
        s_up_w = 2'd3 * in_Px * in_Px + in_a;
    end
    else begin
        if( in_Qy >= in_Py ) begin
            s_up_w = in_Qy - in_Py;
        end
        else begin
            s_up_w = in_Qy - in_Py + in_prime;
        end
    end
end

always @(*) begin
    if(same_flag_w) begin
        s_down_w = 2'd2 * in_Py ; 
    end
    else begin
        if( in_Qx >= in_Px) begin
            s_down_w = in_Qx - in_Px;
        end
        else begin
            s_down_w = in_Qx - in_Px + in_prime;
        end
    end
end

always @(*) begin
    if(same_flag_w) begin
        s_up_mod_w = mod_result_w; 
    end
    else begin
        s_up_mod_w = s_up_w[5:0];
    end
end

always @(*) begin
    if(same_flag_w) begin
        s_down_mod_w = s_down_w[6:0] % in_prime; 
    end
    else begin
        s_down_mod_w = s_down_w[5:0];
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        s_up_mod_reg <= 'b0;
        s_down_mod_reg <= 'b0;
    end
    else if(in_valid) begin
        s_up_mod_reg <= s_up_mod_w;
        s_down_mod_reg <= s_down_mod_w;
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        reg_1 <= 'b0;
    end
    else if(count[4]) begin
        reg_1 <= 'b0;
    end
    else if(count[0] && !count[1]) begin
        reg_1 <= INV_out_w;
    end
    else if(count[1] && !count[2]) begin
        reg_1 <= mod_result_w;
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        x_r<= 'b0;
    end
    else if(count[4]) begin
        x_r<= 'b0;
    end
    else if(count[2] && !count[3]) begin
        x_r <= mod_result_w;
    end
    else begin
        x_r <= x_r;
    end
end


always @(*) begin
    if(count[1] && !count[2]) begin
        mul_left_input_w = s_up_mod_reg;
        mul_right_input_w =  reg_1;
    end
    else if(count[2] && !count[3]) begin
        mul_left_input_w = reg_1;
        mul_right_input_w =  reg_1;
    end
    else if(count[3] && !count[4]) begin
        mul_left_input_w = reg_1;
        if(p_reg[0] >= x_r) begin
            mul_right_input_w = p_reg[0] - x_r;
        end
        else begin
            mul_right_input_w = p_reg[0] - x_r + prime_reg;
        end
    end
    else begin
        mul_left_input_w = 'b0;
        mul_right_input_w =  'b0;
    end
end

always @(*) begin
    if(count[1] && !count[4]) begin
        mul_result_w = mul_left_input_w * mul_right_input_w;
    end
    else begin
        mul_result_w = 'b0;
    end
end

always @(*) begin

    if(in_valid) begin
        mod_input_w = s_up_w[13:0];
    end
    else if(count[1] && !count[2]) begin
        mod_input_w = mul_result_w;
    end
    else if(count[2] && !count[3]) begin
        mod_input_w = minus_2_w;
    end
    else if(count[3] && !count[4]) begin
        mod_input_w = minus_1_w;
    end
    else begin
        mod_input_w = 'b0;
    end
end

always @(*) begin
    if(count[2] && !count[3]) begin
        if (mul_result_w >= p_reg[0]) begin
            minus_1_w = mul_result_w  - p_reg[0];
        end
        else begin
            minus_1_w = mul_result_w  - p_reg[0] + prime_reg;
        end
    end
    else if(count[3] && !count[4]) begin
        if (mul_result_w >= p_reg[1]) begin
            minus_1_w = mul_result_w - p_reg[1];
        end
        else begin
            minus_1_w = mul_result_w - p_reg[1] + prime_reg;
        end
    end
    else begin
        minus_1_w = 'b0;
    end
end

always @(*) begin
    if(count[2] && !count[3]) begin
        if (minus_1_w >= q_reg[0]) begin
            minus_2_w = minus_1_w  - q_reg[0];
        end
        else begin
            minus_2_w = minus_1_w  - q_reg[0] + prime_reg;
        end
    end
    else begin
        minus_2_w = 'b0;
    end
end


always @(*) begin
    if( in_valid || (count[1] && !count[4]) ) begin
        mod_result_w = mod_input_w % prime_w;
    end
    else begin
        mod_result_w = 'b0;
    end
end



always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 'b0;
    else if(count[4]) out_valid <= 1'b0;
    else if(count[3]) out_valid <= 1'b1;
    else out_valid <= out_valid;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        out_Rx <= 'b0;
        out_Ry <= 'b0;
    end
    else if(count[4]) begin
        out_Rx <= 'b0;
        out_Ry <= 'b0;
    end
    else if(count[3]) begin
        out_Rx <= x_r;
        out_Ry <= mod_result_w;
    end
    else begin
        out_Rx <= out_Rx;
        out_Ry <= out_Ry;
    end
end
endmodule
