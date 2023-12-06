module CC(
  in_s0,
  in_s1,
  in_s2,
  in_s3,
  in_s4,
  in_s5,
  in_s6,
  opt,
  a,
  b,
  s_id0,
  s_id1,
  s_id2,
  s_id3,
  s_id4,
  s_id5,
  s_id6,
  out

);
input [3:0]in_s0;
input [3:0]in_s1;
input [3:0]in_s2;
input [3:0]in_s3;
input [3:0]in_s4;
input [3:0]in_s5;
input [3:0]in_s6;
input [2:0]opt;

input [1:0]a;
input [2:0]b;
output [2:0] s_id0;
output [2:0] s_id1;
output [2:0] s_id2;
output [2:0] s_id3;
output [2:0] s_id4;
output [2:0] s_id5;
output [2:0] s_id6;
output [2:0] out; 


wire signed [4:0] signed_in_s0 ;
wire signed [4:0] signed_in_s1 ;
wire signed [4:0] signed_in_s2 ;
wire signed [4:0] signed_in_s3 ;
wire signed [4:0] signed_in_s4 ;
wire signed [4:0] signed_in_s5 ;
wire signed [4:0] signed_in_s6 ;
wire signed [2:0] signed_a;
wire signed [4:0] signed_b;

// Expand all 4 bits input convert to 5 bits signed number
assign signed_in_s0 = (opt[0]) ? {in_s0[3],in_s0[3:0]}:{1'b0,in_s0[3:0]};
assign signed_in_s1 = (opt[0]) ? {in_s1[3],in_s1[3:0]}:{1'b0,in_s1[3:0]};
assign signed_in_s2 = (opt[0]) ? {in_s2[3],in_s2[3:0]}:{1'b0,in_s2[3:0]};
assign signed_in_s3 = (opt[0]) ? {in_s3[3],in_s3[3:0]}:{1'b0,in_s3[3:0]};
assign signed_in_s4 = (opt[0]) ? {in_s4[3],in_s4[3:0]}:{1'b0,in_s4[3:0]};
assign signed_in_s5 = (opt[0]) ? {in_s5[3],in_s5[3:0]}:{1'b0,in_s5[3:0]};
assign signed_in_s6 = (opt[0]) ? {in_s6[3],in_s6[3:0]}:{1'b0,in_s6[3:0]};
assign signed_a = {1'b0 , a};
assign signed_b = {1'b0 , b};


// Always make sorting  ascending 
// If it want to sort descending (opt[1] equal to 1), transform the input to make it can sort ascending 
wire signed [4:0] transform_in_s0 ;
wire signed [4:0] transform_in_s1 ;
wire signed [4:0] transform_in_s2 ;
wire signed [4:0] transform_in_s3 ;
wire signed [4:0] transform_in_s4 ;
wire signed [4:0] transform_in_s5 ;
wire signed [4:0] transform_in_s6 ;

wire [4:0] bit0;
wire [4:0] optExtend;
assign bit0 = 5'b00000;
assign optExtend = {5{opt[1]}};

assign transform_in_s0 = signed_in_s0 ^ bit0 ^  optExtend;
assign transform_in_s1 = signed_in_s1 ^ bit0 ^  optExtend;
assign transform_in_s2 = signed_in_s2 ^ bit0 ^  optExtend;
assign transform_in_s3 = signed_in_s3 ^ bit0 ^  optExtend;
assign transform_in_s4 = signed_in_s4 ^ bit0 ^  optExtend;
assign transform_in_s5 = signed_in_s5 ^ bit0 ^  optExtend;
assign transform_in_s6 = signed_in_s6 ^ bit0 ^  optExtend;


// Record every input's order
wire [2:0] id_in_s0;
wire [2:0] id_in_s1;
wire [2:0] id_in_s2;
wire [2:0] id_in_s3;
wire [2:0] id_in_s4;
wire [2:0] id_in_s5;
wire [2:0] id_in_s6;

assign id_in_s0 = 0;
assign id_in_s1 = 1;
assign id_in_s2 = 2;
assign id_in_s3 = 3;
assign id_in_s4 = 4;
assign id_in_s5 = 5;
assign id_in_s6 = 6;

// Make the input to 8 bits format (transform_in + id) in order to let every input unique
wire signed [7:0] unique_in0;
wire signed [7:0] unique_in1;
wire signed [7:0] unique_in2;
wire signed [7:0] unique_in3;
wire signed [7:0] unique_in4;
wire signed [7:0] unique_in5;
wire signed [7:0] unique_in6;

assign unique_in0 = {transform_in_s0[4:0] , id_in_s0[2:0]};
assign unique_in1 = {transform_in_s1[4:0] , id_in_s1[2:0]};
assign unique_in2 = {transform_in_s2[4:0] , id_in_s2[2:0]};
assign unique_in3 = {transform_in_s3[4:0] , id_in_s3[2:0]};
assign unique_in4 = {transform_in_s4[4:0] , id_in_s4[2:0]};
assign unique_in5 = {transform_in_s5[4:0] , id_in_s5[2:0]};
assign unique_in6 = {transform_in_s6[4:0] , id_in_s6[2:0]};


// Use this picture to simulate the circuit https://i.imgur.com/ZpFr6xS.jpg 
wire signed [7:0] w1;
wire signed [7:0] w2;
wire signed [7:0] w3;
wire signed [7:0] w4;
wire signed [7:0] w5;
wire signed [7:0] w6;
wire signed [7:0] w7;
wire signed [7:0] w8;
wire signed [7:0] w9;
wire signed [7:0] w10;
wire signed [7:0] w11;
wire signed [7:0] w12;
wire signed [7:0] w13;
wire signed [7:0] w14;
wire signed [7:0] w15;
wire signed [7:0] w16;
wire signed [7:0] w17;
wire signed [7:0] w18;
wire signed [7:0] w19;
wire signed [7:0] w20;
wire signed [7:0] w21;
wire signed [7:0] w22;
wire signed [7:0] w23;
wire signed [7:0] w24;
wire signed [7:0] w25;
wire signed [7:0] w26;
wire signed [7:0] w27;
wire signed [7:0] w28;
wire signed [7:0] w29;
wire signed [7:0] w30;
wire signed [7:0] w31;
wire signed [7:0] w32;
wire signed [7:0] w33;
wire signed [7:0] w34;


Comparator_8bit C1(unique_in0 , unique_in1 ,w1 , w2);
Comparator_8bit C2(unique_in2 , unique_in3 ,w3 , w4);
Comparator_8bit C3(unique_in4 , unique_in5 ,w5 , w6);
Comparator_8bit C4(w1 , w3 ,w7 , w8);
Comparator_8bit C5(w2 , w4 ,w9 , w10);
Comparator_8bit C6(w6 , unique_in6 ,w11 , w12);
Comparator_8bit C7(w8 , w9 ,w13 , w14);
Comparator_8bit C8(w5 , w11 ,w15 , w16);
Comparator_8bit C9(w7 , w15 ,w17 , w18);
Comparator_8bit C10(w14 , w16,w19, w20);
Comparator_8bit C11(w10 , w12 ,w21 , w22);
Comparator_8bit C12(w20 , w21 ,w23 , w24);
Comparator_8bit C13(w18 , w13 ,w25 , w26);
Comparator_8bit C14(w19 , w23 ,w27 , w28);
Comparator_8bit C15(w25 , w27 ,w29 , w30);
Comparator_8bit C16(w26 , w28 ,w31 , w32);
Comparator_8bit C17(w30 , w31 ,w33 , w34);

assign s_id0 = w17[2:0];
assign s_id1 = w29[2:0];
assign s_id2 = w33[2:0];
assign s_id3 = w34[2:0];
assign s_id4 = w32[2:0];
assign s_id5 = w24[2:0];
assign s_id6 = w22[2:0];


wire signed [7:0] average;
wire signed [5:0] modify_pass_score;

wire signed [4:0] signed_a_plus1;

wire signed [5:0] adjustment0 ;
wire signed [5:0] adjustment1 ;
wire signed [5:0] adjustment2 ;
wire signed [5:0] adjustment3 ;
wire signed [5:0] adjustment4 ;
wire signed [5:0] adjustment5 ;
wire signed [5:0] adjustment6 ;

assign average = (signed_in_s0 + signed_in_s1 + signed_in_s2 + signed_in_s3 + signed_in_s4 + signed_in_s5 + signed_in_s6) / 7;

// all linera transformation need to plus b  , so I move b to here to calculate in order to reduce adder 
assign modify_pass_score = average - signed_a - signed_b;

assign signed_a_plus1 = signed_a+1;


wire signed [5:0] negative0 ;
wire signed [5:0] negative1 ;
wire signed [5:0] negative2 ;
wire signed [5:0] negative3 ;
wire signed [5:0] negative4 ;
wire signed [5:0] negative5 ;
wire signed [5:0] negative6 ;

assign negative0 = signed_in_s0 / signed_a_plus1 ;
assign negative1 = signed_in_s1 / signed_a_plus1 ;
assign negative2 = signed_in_s2 / signed_a_plus1 ;
assign negative3 = signed_in_s3 / signed_a_plus1 ;
assign negative4 = signed_in_s4 / signed_a_plus1 ;
assign negative5 = signed_in_s5 / signed_a_plus1 ;
assign negative6 = signed_in_s6 / signed_a_plus1 ;

wire signed [7:0] positive0 ;
wire signed [7:0] positive1 ;
wire signed [7:0] positive2 ;
wire signed [7:0] positive3 ;
wire signed [7:0] positive4 ;
wire signed [7:0] positive5 ;
wire signed [7:0] positive6 ;


assign positive0 = signed_a_plus1 * signed_in_s0 ;
assign positive1 = signed_a_plus1 * signed_in_s1 ;
assign positive2 = signed_a_plus1 * signed_in_s2 ;
assign positive3 = signed_a_plus1 * signed_in_s3 ;
assign positive4 = signed_a_plus1 * signed_in_s4 ;
assign positive5 = signed_a_plus1 * signed_in_s5 ;
assign positive6 = signed_a_plus1 * signed_in_s6 ;

wire signed [7:0] Linear_transform_s0 ;
wire signed [7:0] Linear_transform_s1 ;
wire signed [7:0] Linear_transform_s2 ;
wire signed [7:0] Linear_transform_s3 ;
wire signed [7:0] Linear_transform_s4 ;
wire signed [7:0] Linear_transform_s5 ;
wire signed [7:0] Linear_transform_s6 ;

assign Linear_transform_s0 = signed_in_s0[4] ? negative0: positive0 ;
assign Linear_transform_s1 = signed_in_s1[4] ? negative1: positive1 ;
assign Linear_transform_s2 = signed_in_s2[4] ? negative2: positive2 ;
assign Linear_transform_s3 = signed_in_s3[4] ? negative3: positive3 ;
assign Linear_transform_s4 = signed_in_s4[4] ? negative4: positive4 ;
assign Linear_transform_s5 = signed_in_s5[4] ? negative5: positive5 ;
assign Linear_transform_s6 = signed_in_s6[4] ? negative6: positive6 ;

reg count0;
reg count1;
reg count2;
reg count3;
reg count4;
reg count5;
reg count6;

always @(*) begin
  if(opt[2]==1) begin
    count0 = (Linear_transform_s0 < modify_pass_score) ? 1'b1 : 1'b0;
    count1 = (Linear_transform_s1 < modify_pass_score) ? 1'b1 : 1'b0;
    count2 = (Linear_transform_s2 < modify_pass_score) ? 1'b1 : 1'b0;
    count3 = (Linear_transform_s3 < modify_pass_score) ? 1'b1 : 1'b0;
    count4 = (Linear_transform_s4 < modify_pass_score) ? 1'b1 : 1'b0;
    count5 = (Linear_transform_s5 < modify_pass_score) ? 1'b1 : 1'b0;
    count6 = (Linear_transform_s6 < modify_pass_score) ? 1'b1 : 1'b0;
  end
  else begin
    count0 = (Linear_transform_s0 >= modify_pass_score) ? 1'b1 : 1'b0;
    count1 = (Linear_transform_s1 >= modify_pass_score) ? 1'b1 : 1'b0;
    count2 = (Linear_transform_s2 >= modify_pass_score) ? 1'b1 : 1'b0;
    count3 = (Linear_transform_s3 >= modify_pass_score) ? 1'b1 : 1'b0;
    count4 = (Linear_transform_s4 >= modify_pass_score) ? 1'b1 : 1'b0;
    count5 = (Linear_transform_s5 >= modify_pass_score) ? 1'b1 : 1'b0;
    count6 = (Linear_transform_s6 >= modify_pass_score) ? 1'b1 : 1'b0;
  end
end

assign out = count0 + count1 + count2 + count3 + count4 + count5 + count6;



endmodule

module Comparator_8bit(
  in0,
  in1,
  out0,
  out1
);
input signed [7:0]in0;
input signed [7:0]in1;
output wire signed [7:0]out0;
output wire signed [7:0]out1;
assign out0 = (in0 < in1) ? in0 : in1;
assign out1 = (in0 < in1) ? in1 : in0;

endmodule

