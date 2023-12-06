//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

covergroup spec1_check @ (posedge clk iff inf.amnt_valid);
    coverpoint inf.D.d_money {
        option.at_least = 10;
        bins m1 = {[0:12000]};
        bins m2 = {[12001:24000]};
        bins m3 = {[24001:36000]};
        bins m4 = {[36001:48000]};
        bins m5 = {[48001:60000]};
    }
endgroup

covergroup spec2_check @ (posedge clk iff inf.id_valid);
    coverpoint inf.D.d_id[0] {
        option.at_least = 2 ; 
	    option.auto_bin_max = 256;
    }
endgroup

covergroup spec3_check @ (posedge clk iff inf.act_valid);
    coverpoint inf.D.d_act[0] {
        option.at_least = 10 ; 

	    bins transition_0  = (Buy => Buy);
        bins transition_1  = (Buy => Check);
        bins transition_2  = (Buy => Deposit);
        bins transition_3  = (Buy => Return);

        bins transition_4  = (Check => Buy);
        bins transition_5  = (Check => Check);
        bins transition_6  = (Check => Deposit);
        bins transition_7  = (Check => Return);

        bins transition_8  = (Deposit => Buy);
        bins transition_9  = (Deposit => Check);
        bins transition_10 = (Deposit => Deposit);
        bins transition_11 = (Deposit => Return);

        bins transition_12 = (Return => Buy);
        bins transition_13 = (Return => Check);
        bins transition_14 = (Return => Deposit);
        bins transition_15 = (Return => Return);       
    }
endgroup

covergroup spec4_check @ (posedge clk iff inf.item_valid);
    coverpoint inf.D.d_item[0] {
        option.at_least = 20 ; 
        bins item_1 = {Large};
        bins item_2 = {Medium};
        bins item_3 = {Small};
    }
endgroup

covergroup spec5_check @ (negedge clk iff inf.out_valid);
    coverpoint inf.err_msg {
        option.at_least = 20;
        bins err_1 = {INV_Not_Enough};
        bins err_2 = {Out_of_money};
        bins err_3 = {INV_Full};
        bins err_4 = {Wallet_is_Full};
        bins err_5 = {Wrong_ID};
        bins err_6 = {Wrong_Num};
        bins err_7 = {Wrong_Item};
        bins err_8 = {Wrong_act};
    }
endgroup

covergroup spec6_check @ (negedge clk iff inf.out_valid);
    coverpoint inf.complete {
        option.at_least     = 200;
        bins complete_0  = {0};
        bins complete_1  = {1};
    }
endgroup

spec1_check cover_spec1 = new();
spec2_check cover_spec2 = new();
spec3_check cover_spec3 = new();
spec4_check cover_spec4 = new();
spec5_check cover_spec5 = new();
spec6_check cover_spec6 = new();

Action act_reg;
logic [1:0] id_flag;
logic [1:0] act_flag;
logic [1:0] item_flag;
logic [1:0] number_flag;
logic [1:0] amnt_flag;
logic [1:0] id_before_act;
logic [3:0] check_count;
wire valid_1;
wire valid_2;
wire valid_3;
wire valid_4;
wire valid_5;
wire  [3:0] valid_num;

assign valid_1 = (inf.id_valid === 1) ? 1 :0;
assign valid_2 = (inf.act_valid === 1) ? 1 :0;
assign valid_3 = (inf.item_valid === 1) ? 1 :0;
assign valid_4 = (inf.num_valid === 1) ? 1 :0;
assign valid_5 = (inf.amnt_valid === 1) ? 1 :0;
assign valid_num = valid_1 + valid_2 + valid_3 + valid_4 + valid_5;

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) begin
        id_flag  <= 0;
        act_reg <= 0;
        act_flag <= 0;
        item_flag <= 0;
        number_flag <= 0;
        amnt_flag <= 0;
        id_before_act <= 0;
    end
    else if(inf.out_valid) begin
        id_flag  <= 0;
        act_reg <= 0;
        act_flag <= 0;
        item_flag <= 0;
        number_flag <= 0;
        amnt_flag <= 0;
        id_before_act <= 0;
    end
    else if(inf.id_valid) begin
        id_flag <= id_flag +1;
        if(!act_flag) id_before_act <= id_before_act +1;
    end
    else if(inf.act_valid) begin
        act_reg <= inf.D.d_act;
        act_flag <= act_flag +1;
    end
    else if(inf.item_valid) begin
        item_flag <= item_flag + 1;
    end
    else if(inf.num_valid) begin
        number_flag <= number_flag + 1;
    end 
    else if(inf.amnt_valid) begin
        amnt_flag <= amnt_flag +1;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n) check_count <= 0;
    else if(inf.out_valid) check_count <= 0;
    else if(act_reg === Check) check_count <= check_count +1;
end

/* asset 1 check */
wire #(1) rst_delay = inf.rst_n;
always_ff @(negedge rst_delay) begin
    assert_1 : assert ((inf.out_valid === 0 ) && (inf.out_info === 0) && (inf.err_msg === No_Err    ) && 
                       (inf.complete === 0  ) && (inf.C_addr === 0  ) && (inf.C_data_w === 0   ) && 
                       (inf.C_in_valid === 0) && (inf.C_r_wb === 0  ) && (inf.C_out_valid === 0) && 
                       (inf.C_data_r === 0  ) && (inf.AR_VALID === 0) && (inf.AR_ADDR === 0    ) && 
                       (inf.R_READY === 0   ) && (inf.AW_VALID === 0) && (inf.AW_ADDR === 0    ) && 
                       (inf.W_VALID === 0   ) && (inf.W_DATA === 0  ) && (inf.B_READY === 0    ))
    else begin
       $display("Assertion 1 is violated");
       $fatal; 
    end
end

assert_2 : assert property (@(posedge clk) (inf.out_valid === 1 && inf.complete === 1) |-> (inf.err_msg === No_Err))
else begin
    $display("Assertion 2 is violated");
    $fatal; 
end

assert_3 : assert property (@(posedge clk) (inf.out_valid === 1 && inf.complete === 0) |-> (inf.out_info === 0))
else begin
	$display("Assertion 3 is violated");
	$fatal; 
end

assert_4_id_valid : assert property ( @(posedge clk) (inf.id_valid === 1) |=> (inf.id_valid === 0))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4_act_valid : assert property ( @(posedge clk) (inf.act_valid === 1) |=> (inf.act_valid === 0))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4_item_valid : assert property ( @(posedge clk) (inf.item_valid === 1) |=> (inf.item_valid === 0))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4_num_valid : assert property ( @(posedge clk) (inf.num_valid === 1) |=> (inf.num_valid === 0))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_4_amnt_valid : assert property ( @(posedge clk) (inf.amnt_valid === 1) |=>  (inf.amnt_valid === 0))
else begin
    $display("Assertion 4 is violated");
    $fatal; 
end

assert_5 : assert property( @(posedge clk)  valid_num < 2)
else begin
    $display("Assertion 5 is violated");
	$fatal;
end

assert_6_repeat_id : assert property( @(posedge clk)  ((id_flag+valid_1) <= 1 || ((id_flag + valid_1 == 2) && id_before_act && act_flag)) )
else begin
    $display("Assertion 5 is violated");
	$fatal;
end

assert_6_repeat_other : assert property( @(posedge clk) (act_flag + valid_2) <= 1 && (item_flag + valid_3) <= 1 && (number_flag + valid_4) <= 1 && (amnt_flag + valid_5) <= 1 )
else begin
    $display("Assertion 5 is violated");
	$fatal;
end

assert_6_one_cycle_gap : assert property( @(posedge clk)  (valid_num == 1) |=> (valid_num != 1))
else begin
    $display("Assertion 5 is violated");
	$fatal;
end

assert_6_id_to_act : assert property ( @(posedge clk)  (inf.id_valid===1 && !act_flag) |=> ##[1:5]  (inf.act_valid ===1 ))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_id_to_other : assert property ( @(posedge clk)  (inf.id_valid===1 |=> (valid_num >= 2 || act_flag || !(valid_1 || valid_3 || valid_4 || valid_5))[*6]))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_valid_before_act : assert property ( @(posedge clk )  !act_flag |->  !( valid_3 || valid_4  || valid_5))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_act_to_item_buy_return : assert property ( @(posedge clk)  (inf.act_valid === 1 && (inf.D.d_act == Buy | inf.D.d_act == Return)) |=> ##[1:5] inf.item_valid ===1 )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_act_to_other_buy_return : assert property ( @(posedge clk)  ( inf.act_valid === 1 && (inf.D.d_act == Buy | inf.D.d_act == Return) |=> (valid_num >= 2 || item_flag || !(valid_1 || valid_2 || valid_4 || valid_5))[*6]))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_item_to_number_buy_return : assert property ( @(posedge clk)  (inf.item_valid===1 && (act_reg == Buy || act_reg == Return ) ) |=> ##[1:5] inf.num_valid===1 )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_item_to_other : assert property ( @(posedge clk)  (inf.item_valid===1 && (act_reg == Buy || act_reg == Return ) ) |=> (valid_num >= 2 || number_flag || !(valid_1 || valid_2 || valid_3 || valid_5))[*6] )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end


assert_6_item_num_err : assert property ( @(posedge clk)  ( (inf.item_valid === 1 || inf.num_valid === 1) |-> (act_reg == Buy || act_reg == Return)))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_amnt_err : assert property ( @(posedge clk)  ( inf.amnt_valid === 1  |-> act_reg == Deposit))
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_number_to_id_buy_return : assert property ( @(posedge clk)  (inf.num_valid===1 && (act_reg == Buy || act_reg == Return ) ) |=> ##[1:5] inf.id_valid===1 )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_number_to_other : assert property ( @(posedge clk)  (inf.num_valid===1 && (act_reg == Buy || act_reg == Return ) && !id_flag) |=> (valid_num >= 2 || id_flag || !(valid_2 || valid_3 || valid_4 || valid_5))[*6] )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_number_to_other2 : assert property ( @(posedge clk)  (inf.num_valid===1 && (act_reg == Buy || act_reg == Return ) && id_flag) |=> (valid_num >= 2 || id_flag==2 || !(valid_2 || valid_3 || valid_4 || valid_5))[*6] )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_act_check : assert property ( @(posedge clk)  (inf.act_valid && (inf.D.d_act == Check)) |=> ##[1:5] (inf.id_valid | check_count == 3'd5 ) )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_act_check_err : assert property ( @(posedge clk)  (inf.act_valid===1 && inf.D.d_act == Check && !id_flag) |=> (valid_num >= 2 || id_flag || !(valid_2 || valid_3 || valid_4 || valid_5))[*6] )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_act_check_err2 : assert property ( @(posedge clk)  (inf.act_valid===1 && inf.D.d_act == Check && id_flag) |=> (valid_num >= 2 || id_flag == 2 || !(valid_2 || valid_3 || valid_4 || valid_5))[*6] )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_act_deposit : assert property ( @(posedge clk)  (inf.act_valid===1 && (inf.D.d_act == Deposit)) |=> ##[1:5] inf.amnt_valid )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end

assert_6_act_deposit_err : assert property ( @(posedge clk)   (inf.act_valid===1 && inf.D.d_act == Deposit) |=> (valid_num >= 2  || !(valid_1 || valid_2 || valid_3 || valid_4))[*6] )
else begin
    $display("Assertion 6 is violated");
    $fatal; 
end


assert_7 : assert property ( @(posedge clk)  (inf.out_valid===1 ) |=> (inf.out_valid === 0))
else begin
    $display("Assertion 7 is violated");
    $fatal;
end

assert_8 : assert property ( @(posedge clk)  (inf.out_valid === 1 ) |=>  ##[2:10] (inf.id_valid || inf.act_valid))
else begin
    $display("Assertion 8 is violated");
    $fatal;
end

assert_8_2 : assert property ( @(posedge clk)  (inf.out_valid === 1 ) |-> ##0 (!(inf.id_valid || inf.act_valid))[*2])
else begin
    $display("Assertion 8 is violated");
    $fatal;
end

assert_9 : assert property ( @(posedge clk) ((inf.id_valid && (act_reg == Buy) || (inf.id_valid && act_reg == Return) || (inf.amnt_valid && act_reg == Deposit) || (inf.id_valid && act_reg == Check)) |=> ##[0:10000] (inf.out_valid)))
else begin
	$display("Assertion 9 is violated");
	$fatal;
end


assert_9_2 : assert property ( @(posedge clk) ((act_reg == Check && check_count==3'd4 ) |=> ##[0:9996] (inf.out_valid)))
else begin
	$display("Assertion 9 is violated");
	$fatal;
end

endmodule