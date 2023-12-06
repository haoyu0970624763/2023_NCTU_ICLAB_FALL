module OS(input clk, INF.OS_inf inf);
import usertype::*;

logic read_user_flag;
logic read_dram_flag;
logic write_dram_flag;
logic write_dram_flag2;
logic read_dram_flag2;
logic read_finish_flag1;
logic read_start2;
logic calculate_start;
logic calculate_finish;
logic write_back;
logic finish_action_flag;
User_id user1 , user2;
Action action;
Item_id item_id;
Item_num item_num;
Money money_store;
Shop_Info shop_info1 , shop_info2 ;
User_Info user_info1 , user_info2 ;

logic first_user;
logic first_user_table;
logic user1_unstable;

logic [5:0] buyer_object_num;
logic [5:0] seller_object_num;
logic [8:0] price;
logic [5:0] exp;

logic [6:0] buyer_object_num2;
logic [5:0] seller_object_num2;

logic [6:0] Delivery_fee;
logic [11:0] updrade_exp;
logic [1:0]  new_level;
wire [12:0] total_exp;

logic [15:0] buyer_money;
wire [16:0] seller_money;

logic buyer_full;
logic seller_not_enough;
logic no_money;

logic buyer_full_reg;
logic seller_not_enough_reg;
logic no_money_reg;

/* used for check */
logic [2:0] count_check;
logic check_other_user;
logic count_start;
logic count_stop;
logic once;
logic twice;
logic first_complete;
logic [1:0] count_valid;


/* used for deposit */
wire [16:0] wallet_money;
logic wallet_full;
logic wallet_full_reg;

/* used for return */
integer i;
integer j;
logic [0:0] return_flag_reg [0:255];
logic [0:0] return_flag_reg2 [0:255];
logic [7:0] seller_record [0:255];
logic return_store_flag;
logic return_wrong;
logic wrong_id;
logic wrong_num;
logic wrong_item;

wire [7:0] D_trans [0:7];
wire [31:0] left32 , right32 ;


assign D_trans[3] = inf.C_data_r[7:0];
assign D_trans[2] = inf.C_data_r[15:8];
assign D_trans[1] = inf.C_data_r[23:16];
assign D_trans[0] = inf.C_data_r[31:24];
assign D_trans[7] = inf.C_data_r[39:32];
assign D_trans[6] = inf.C_data_r[47:40];
assign D_trans[5] = inf.C_data_r[55:48];
assign D_trans[4] = inf.C_data_r[63:56];

assign right32 = {D_trans[3],D_trans[2],D_trans[1],D_trans[0]};
assign left32 = {D_trans[7],D_trans[6],D_trans[5],D_trans[4]};

assign wallet_money = user_info1.money + money_store;
assign total_exp = shop_info1.exp + item_num * exp;
assign seller_money = action[0] ? (user_info2.money + item_num * price) : (user_info2.money - item_num * price);

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) first_user <= 1'b0;
    else if(inf.id_valid) first_user <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)  user1_unstable <= 1'b0;
    else if(inf.out_valid) user1_unstable <= 1'b0;
    else if(!first_user && inf.id_valid) user1_unstable <= 1'b1;
    else if(first_user && !read_user_flag && inf.id_valid )  user1_unstable <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n)  first_user_table <= 1'b0;
    else if(inf.C_out_valid )  first_user_table <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) read_user_flag <= 1'b0;
    else if(inf.out_valid) read_user_flag <= 1'b0;
    else if((!read_dram_flag && inf.id_valid) || (action[0] || action[1] || action[3])) read_user_flag <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n ) begin
    if (!inf.rst_n) begin
        user1 <= 'b0;
        user2 <= 'b0;
        action <= 'b0;
        item_id <= 'b0;
        item_num <= 'b0;
        money_store <= 'b0;
    end
    else if(inf.out_valid) begin
        user2 <= 'b0;
        action <= 'b0;
        item_id <= 'b0;
        item_num <= 'b0;
        money_store <= 'b0;
    end
    else if(inf.id_valid) begin
        if(!read_user_flag) user1 <= inf.D[7:0];
        else user2 <= inf.D[7:0];
    end
    else if(inf.act_valid) action <= inf.D[3:0];
    else if(inf.item_valid) item_id <= inf.D[1:0];
    else if(inf.num_valid) item_num <= inf.D[5:0];
    else if(inf.amnt_valid) money_store <= inf.D;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) read_dram_flag <= 1'b0;
    else if(inf.out_valid) read_dram_flag <= 1'b0;
    else if(inf.C_in_valid) read_dram_flag <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) write_dram_flag <= 1'b0;
    else if(inf.out_valid) write_dram_flag <= 1'b0;
    else if(calculate_finish) write_dram_flag <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) read_dram_flag2 <= 1'b0;
    else if(inf.out_valid) read_dram_flag2 <= 1'b0;
    else if(inf.C_in_valid && read_dram_flag ) read_dram_flag2 <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) write_dram_flag2 <= 1'b0;
    else if(inf.out_valid) write_dram_flag2 <= 1'b0;
    else if(write_dram_flag && inf.C_out_valid) write_dram_flag2 <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) read_finish_flag1 <= 1'b0;
    else if(inf.out_valid) read_finish_flag1 <= 1'b0;
    else if(inf.C_out_valid) read_finish_flag1 <= 1'b1;
    else if(first_user_table && !user1_unstable && (action[0]|action[1]|action[3]) && inf.id_valid) read_finish_flag1 <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) read_start2 <= 1'b0;
    else if(inf.out_valid) read_start2 <= 1'b0;
    else if(first_user_table && !user1_unstable && action[0]) read_start2 <= 1'b1;
    else if(inf.id_valid && read_dram_flag) read_start2 <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) count_start <= 1'b0;
    else if(inf.out_valid) count_start <= 1'b0;
    else if(action[1]) count_start <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) count_stop <= 1'b0;
    else if(inf.out_valid) count_stop <= 1'b0;
    else if(inf.id_valid && action[1] && count_start) count_stop <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) count_check <= 3'b0;
    else if(inf.out_valid) count_check <= 3'b0;
    else if((!count_stop && count_start)) begin
        if(count_check != 3'd6) count_check <= count_check +1;
    end    
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) count_valid <= 'b0;
    else if(inf.out_valid) count_valid <= 'b0;
    else if(inf.C_out_valid) begin
        count_valid <= count_valid +1;
    end    
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) calculate_start <= 1'b0;
    else if(inf.out_valid) calculate_start <= 1'b0;
    else if(action[0]) begin
        if(read_finish_flag1 && inf.C_out_valid) calculate_start <= 1'b1;
    end
    else if(action[2]) begin
        if(user1_unstable) begin
            if(inf.C_out_valid) calculate_start <= 1'b1;
        end
        else begin
            if(inf.amnt_valid) calculate_start <= 1'b1;
        end
    end
    else if(action[3]) begin
        if(!user1_unstable) begin
            if(inf.C_out_valid) calculate_start <= 1'b1;
        end
        else begin
            if(read_finish_flag1 && inf.C_out_valid) calculate_start <= 1'b1;
        end
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) calculate_finish <= 1'b0;
    else if(inf.out_valid) calculate_finish <= 1'b0;
    else if(action[0] || action[2] || action[3]) begin
        if(calculate_start) calculate_finish <= 1'b1;
    end
    else if(action[1]) begin
        if(!first_complete) begin
            if(first_user_table) begin
                if(inf.C_out_valid ) calculate_finish <= 1'b1;
            end
        end
        else begin
            if( !user1_unstable) begin
                if(inf.C_out_valid) calculate_finish <= 1'b1;
                if(count_check==3'd6 && !count_stop) calculate_finish <= 1'b1;
            end
            else begin
                if(count_valid == 2'd2) calculate_finish <= 1'b1;
                if(count_check==3'd6 && !count_stop && inf.C_out_valid) calculate_finish <= 1'b1;
            end
        end
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
        inf.C_addr <= 8'b0;
        inf.C_data_w <= 64'b0;
        inf.C_in_valid <= 1'b0;
        inf.C_r_wb <= 1'b0;
        once <= 1'b0;
        twice <= 1'b0;
    end
    else if(inf.out_valid) begin
        inf.C_addr <= 8'b0;
        inf.C_data_w <= 64'b0;
        inf.C_in_valid <= 1'b0;
        inf.C_r_wb <= 1'b0;
        once <= 1'b0;
        twice <= 1'b0;
    end
    else if(action[0]) begin
        /* buy action */
        if(!calculate_finish) begin
            if(inf.C_in_valid) begin
                inf.C_in_valid <= 1'b0;
                inf.C_r_wb <= 1'b0;
            end
            else begin
                if(user1_unstable) begin
                    if(!read_dram_flag ) begin
                        inf.C_addr <= user1;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                    end
                    else if(read_finish_flag1 && read_start2 && !read_dram_flag2) begin
                        inf.C_addr <= user2;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                    end
                end
                else begin
                    if(inf.id_valid) begin
                        inf.C_addr <= inf.D[7:0];
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                    end
                end
            end
        end
        else begin
            if(!buyer_full_reg && !seller_not_enough_reg && !no_money_reg) begin
                if(inf.C_in_valid) begin
                    inf.C_in_valid <= 1'b0;
                    inf.C_r_wb <= 1'b0;
                    inf.C_data_w <= 64'b0;
                end
                else begin
                    /* buy action */
                    if(!write_dram_flag) begin
                        inf.C_addr <= user1;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b0;
                        inf.C_data_w <= {user_info1[7:0],user_info1[15:8],user_info1[23:16],user_info1[31:24],shop_info1[7:0],shop_info1[15:8],shop_info1[23:16],shop_info1[31:24]};
                    end
                    else if(inf.C_out_valid && !write_dram_flag2) begin
                        inf.C_addr <= user2;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b0;
                        inf.C_data_w <= {user_info2[7:0],user_info2[15:8],user_info2[23:16],user_info2[31:24],shop_info2[7:0],shop_info2[15:8],shop_info2[23:16],shop_info2[31:24]};
                    end
                end
            end
        end
    end
    else if(action[1]) begin
        if(!user1_unstable) begin
            if(inf.C_in_valid) begin
                inf.C_in_valid <= 1'b0;
                inf.C_r_wb <= 1'b0;
            end
            else begin
                if(inf.id_valid) begin
                    inf.C_addr <= inf.D[7:0];
                    inf.C_in_valid <= 1'b1;
                    inf.C_r_wb <= 1'b1;
                end
            end
        end
        else begin
            if(!first_user_table) begin
                if(inf.C_in_valid) begin
                    inf.C_in_valid <= 1'b0;
                    inf.C_r_wb <= 1'b0;
                end
                else begin
                    if(!read_dram_flag) begin
                        inf.C_addr <= user1;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                    end
                    else if(read_finish_flag1 && read_start2 && !read_dram_flag2) begin
                        inf.C_addr <= user2;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                    end
                end
            end
            else begin
                if(!first_complete) begin
                    if(inf.C_in_valid) begin
                        inf.C_in_valid <= 1'b0;
                        inf.C_r_wb <= 1'b0;
                    end
                    else if(!once)begin
                        inf.C_addr <= user2;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                        once <= 1'b1;
                    end
                end
                else begin
                    if(inf.C_in_valid) begin
                        inf.C_in_valid <= 1'b0;
                        inf.C_r_wb <= 1'b0;
                    end
                    else if(!once)begin
                        inf.C_addr <= user1;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                        once <= 1'b1;
                    end
                    else if(once && count_stop && inf.C_out_valid && !twice) begin
                        inf.C_addr <= user2;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                        once <= 1'b1;
                        twice <= 1'b1;
                    end
                end
            end
        end
    end
    else if(action[2]) begin
        if(!calculate_finish) begin
            if(user1_unstable) begin
                if(inf.C_in_valid) begin
                    inf.C_in_valid <= 1'b0;
                    inf.C_r_wb <= 1'b0;
                end
                else begin
                    if(!read_dram_flag) begin
                        inf.C_addr <= user1;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                    end
                end
            end
        end
        else begin
            if(!wallet_full_reg) begin
                if(inf.C_in_valid) begin
                    inf.C_in_valid <= 1'b0;
                    inf.C_r_wb <= 1'b0;
                    inf.C_data_w <= 64'b0;
                end
                else begin
                    if(!write_dram_flag) begin
                        inf.C_addr <= user1;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b0;
                        inf.C_data_w <= {user_info1[7:0],user_info1[15:8],user_info1[23:16],user_info1[31:24],shop_info1[7:0],shop_info1[15:8],shop_info1[23:16],shop_info1[31:24]};
                    end
                end
            end
        end
    end
    else if(action[3]) begin
        if(!calculate_finish) begin
            if(!user1_unstable) begin
                if(inf.C_in_valid) begin
                    inf.C_in_valid <= 1'b0;
                    inf.C_r_wb <= 1'b0;
                end
                else begin
                    if(inf.id_valid) begin
                        inf.C_addr <= inf.D[7:0];
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                    end
                end
            end
            else begin
                if(inf.C_in_valid) begin
                    inf.C_in_valid <= 1'b0;
                    inf.C_r_wb <= 1'b0;
                end
                else begin
                    if(!read_dram_flag ) begin
                        inf.C_addr <= user1;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                    end
                    else if(read_finish_flag1 && read_start2 && !read_dram_flag2) begin
                        inf.C_addr <= user2;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b1;
                    end
                end
            end
        end
        else begin
            if(!return_wrong) begin
                if(inf.C_in_valid) begin
                    inf.C_in_valid <= 1'b0;
                    inf.C_r_wb <= 1'b0;
                    inf.C_data_w <= 64'b0;
                end
                else begin
                    /* buy action */
                    if(!write_dram_flag) begin
                        inf.C_addr <= user1;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b0;
                        inf.C_data_w <= {user_info1[7:0],user_info1[15:8],user_info1[23:16],user_info1[31:24],shop_info1[7:0],shop_info1[15:8],shop_info1[23:16],shop_info1[31:24]};
                    end
                    else if(inf.C_out_valid && !write_dram_flag2) begin
                        inf.C_addr <= user2;
                        inf.C_in_valid <= 1'b1;
                        inf.C_r_wb <= 1'b0;
                        inf.C_data_w <= {user_info2[7:0],user_info2[15:8],user_info2[23:16],user_info2[31:24],shop_info2[7:0],shop_info2[15:8],shop_info2[23:16],shop_info2[31:24]};
                    end
                end
            end
        end
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        shop_info1 <= 32'b0;
        shop_info2 <= 32'b0;
        user_info1 <= 32'b0;
        user_info2 <= 32'b0;
    end
    else if(inf.out_valid) begin
        shop_info2 <= 32'b0;
        user_info2 <= 32'b0;
    end
    else if(inf.C_out_valid && !calculate_finish) begin
        if(!read_finish_flag1) begin
            shop_info1 <= right32;
            user_info1 <= left32;
        end
        else begin
            shop_info2 <= right32;
            user_info2 <= left32;
        end
    end
    else if(calculate_start && !calculate_finish) begin
        if(action[0]) begin
            if(!buyer_full && !seller_not_enough && !no_money) begin
                case (item_id)
                    2'd1: begin
                        shop_info1.large_num <= buyer_object_num2;
                        shop_info2.large_num <= seller_object_num2;
                    end
                    2'd2:begin
                        shop_info1.medium_num <= buyer_object_num2;
                        shop_info2.medium_num <= seller_object_num2;
                    end
                    2'd3:begin
                        shop_info1.small_num <= buyer_object_num2;
                        shop_info2.small_num <= seller_object_num2;
                    end
                    default: begin end
                endcase

                if(total_exp >= updrade_exp) begin
                    shop_info1.exp <= 12'b0;
                    if(shop_info1.level) shop_info1.level <= shop_info1.level -1;
                end
                else begin
                    shop_info1.exp <= shop_info1.exp + exp * item_num;
                end

                user_info1.money <= buyer_money;
                user_info1.shop_history.item_ID <= item_id;
                user_info1.shop_history.item_num <= item_num;
                user_info1.shop_history.seller_ID <= user2;

                if( seller_money <= 16'd65535) begin
                    user_info2.money <= seller_money;
                end
                else begin
                    user_info2.money <= 16'd65535;
                end
                
            end
        end
        else if(action[2]) begin
            if(!wallet_full) begin
                user_info1.money <= wallet_money;
            end
        end
        else if(action[3]) begin
            if(!return_wrong && !wrong_id &&  !wrong_num && !wrong_item ) begin
                case (item_id)
                    2'd1: begin
                        shop_info1.large_num <= buyer_object_num2;
                        shop_info2.large_num <= seller_object_num2;
                    end
                    2'd2:begin
                        shop_info1.medium_num <= buyer_object_num2;
                        shop_info2.medium_num <= seller_object_num2;
                    end
                    2'd3:begin
                        shop_info1.small_num <= buyer_object_num2;
                        shop_info2.small_num <= seller_object_num2;
                    end
                    default: begin end
                endcase
                user_info1.money <= buyer_money;
                user_info2.money <= seller_money;
            end
        end
    end
end

always_comb begin
    if(calculate_start) begin
        case (item_id)
            2'd1: begin
                buyer_object_num = shop_info1.large_num;
                seller_object_num = shop_info2.large_num;
                price = 9'd300;
                exp = 6'd60;
            end
            2'd2:begin
                buyer_object_num = shop_info1.medium_num;
                seller_object_num = shop_info2.medium_num;
                price = 9'd200;
                exp = 6'd40;
            end
            2'd3:begin
                buyer_object_num = shop_info1.small_num;
                seller_object_num = shop_info2.small_num;
                price = 9'd100;
                exp = 6'd20;
            end
            default: begin
                buyer_object_num = 0;
                seller_object_num = 0;
                price = 0;
                exp = 0;
            end
        endcase
    end
    else begin
        buyer_object_num = 0;
        seller_object_num = 0;
        price = 0;
        exp = 0;
    end
end

always_comb begin
    if(calculate_start) begin
        case (shop_info1.level)
            2'd0: begin
                Delivery_fee = 7'd10;
                updrade_exp = 0; 
            end
            2'd1:begin
                Delivery_fee = 7'd30;
                updrade_exp = 12'd4000; 
            end
            2'd2:begin
                Delivery_fee = 7'd50;
                updrade_exp = 12'd2500; 
            end
            default: begin
                Delivery_fee = 7'd70;
                updrade_exp = 12'd1000; 
            end
        endcase
    end
    else begin
        Delivery_fee = 0;
        updrade_exp = 0; 
    end
end

always_comb begin
    if(calculate_start) begin
        if(action[0]) begin
            if(user_info1.money >= (Delivery_fee + item_num * price)) begin
                buyer_money = user_info1.money - (Delivery_fee + item_num * price);
                no_money = 0;
            end
            else begin
                buyer_money = user_info1.money;
                no_money = 1;
            end
        end
        else begin
            buyer_money = user_info1.money + ( item_num * price);
            no_money = 0;
        end
    end
    else begin
        buyer_money  = 0;
        no_money = 0; 
    end
end

always_comb begin
    if(calculate_start) begin
        if(action[0]) buyer_object_num2 = buyer_object_num + item_num;
        else buyer_object_num2 = buyer_object_num - item_num;
    end
    else buyer_object_num2 = 0;
end

always_comb begin
    if(calculate_start && buyer_object_num2 > 6'd63 ) buyer_full = 1'b1;
    else buyer_full = 1'b0;
end

always_comb begin
    if(calculate_start) begin
        if(action[0]) begin
            if(seller_object_num < item_num) begin
                seller_not_enough = 1'b1;
                seller_object_num2 = seller_object_num;
            end
            else begin
                seller_not_enough = 1'b0;
                seller_object_num2 = seller_object_num - item_num;
            end
        end
        else begin
            seller_not_enough = 1'b0;
            seller_object_num2 = seller_object_num + item_num;
        end
    end
    else begin
        seller_not_enough = 0;
        seller_object_num2 = 0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        buyer_full_reg <= 1'b0;
        seller_not_enough_reg <= 1'b0;
        no_money_reg <= 1'b0;
        wallet_full_reg <= 1'b0;
    end
    else if(inf.out_valid) begin
        buyer_full_reg <= 1'b0;
        seller_not_enough_reg <= 1'b0;
        no_money_reg <= 1'b0;
        wallet_full_reg <= 1'b0;
    end
    else if(calculate_start && !calculate_finish) begin
        if(action[0]) begin
            buyer_full_reg <= buyer_full;
            seller_not_enough_reg <= seller_not_enough;
            no_money_reg <= no_money;
        end
        else if(action[2]) begin
            wallet_full_reg  <= wallet_full;
        end
    end
end

/* check wallet full*/
always_comb begin
    if(calculate_start) begin
        if(wallet_money > 16'hffff ) begin
            wallet_full = 1;
        end
        else begin
            wallet_full = 0;
        end
    end
    else begin
        wallet_full = 0;
    end
end

/* check return wrong */
always_comb begin
    if(calculate_start) begin
        if( return_flag_reg[user1] == 0 || return_flag_reg2[user_info1.shop_history.seller_ID] == 0 ) return_wrong = 1;
        else if(return_flag_reg[user1] && return_flag_reg2[user_info1.shop_history.seller_ID]) begin
            if(seller_record[user_info1.shop_history.seller_ID] != user1) return_wrong = 1;
            else return_wrong = 0;
        end
        else return_wrong = 0;
    end
    else return_wrong = 0;
end

always_comb begin
    if(calculate_start) begin
        if(user_info1.shop_history.seller_ID != user2 ) wrong_id = 1;
        else wrong_id = 0;
    end
    else wrong_id = 0;
end

always_comb begin
    if(calculate_start) begin
        if(!wrong_id && user_info1.shop_history.item_num != item_num ) wrong_num = 1;
        else wrong_num = 0;
    end
    else wrong_num = 0;
end

always_comb begin
    if(calculate_start) begin
        if(!wrong_id && user_info1.shop_history.item_ID != item_id ) wrong_item = 1;
        else wrong_item = 0;
    end
    else wrong_item = 0;
end

always_comb begin
    if(action[0])begin
        if(write_dram_flag2 && inf.C_out_valid) finish_action_flag = 1;
        else if(buyer_full_reg || seller_not_enough_reg || no_money_reg) finish_action_flag = 1;
        else finish_action_flag = 0;
    end
    else if(action[1]) begin
        if(calculate_finish) finish_action_flag = 1;
        else finish_action_flag = 0;
    end
    else if(action[2]) begin
        if((write_dram_flag && inf.C_out_valid) || wallet_full_reg) finish_action_flag = 1;
        else finish_action_flag = 0;
    end
    else if(action[3]) begin
        if(write_dram_flag2 && inf.C_out_valid) finish_action_flag = 1;
        else finish_action_flag = 0;
    end
    else finish_action_flag = 0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        first_complete <= 1'b0;
    end
    else if(finish_action_flag) begin
        first_complete <= 1'b1;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        for(i = 0 ; i < 256 ; i=i+1) begin
            return_flag_reg[i] <= 1'b0;
            return_flag_reg2[i] <= 1'b0;
        end
    end
    else if(finish_action_flag) begin
        case (action)
            4'd1: begin
                if( !buyer_full_reg && !seller_not_enough_reg && !no_money_reg) begin
                    return_flag_reg[user1] <= 1'b1; 
                    return_flag_reg2[user2] <= 1'b1; 

                    if(return_flag_reg[user2]) return_flag_reg[user2] <= 1'b0;
                    if(return_flag_reg2[user1]) return_flag_reg2[user1] <= 1'b0;
                end
            end
            4'd2:begin
                return_flag_reg[user1] <= 1'b0; 
                return_flag_reg2[user1] <= 1'b0; 
                if(count_stop) begin
                    return_flag_reg[user2] <= 1'b0;
                    return_flag_reg2[user2] <= 1'b0; 
                end 
            end
            4'd4:begin
                if(!wallet_full_reg) begin
                    return_flag_reg[user1] <= 1'b0; 
                    return_flag_reg2[user1] <= 1'b0; 
                end
            end
            4'd8:begin
                return_flag_reg[user1] <= 1'b0; 
                return_flag_reg[user2] <= 1'b0; 
                return_flag_reg2[user1] <= 1'b0; 
                return_flag_reg2[user2] <= 1'b0; 
            end
            default: begin end
            endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        for(j = 0 ; j < 256 ; j=j+1) begin
            seller_record[j] <= 236;
        end
    end
    else if(finish_action_flag) begin
        case (action)
            4'd1: begin
                if( !buyer_full_reg && !seller_not_enough_reg && !no_money_reg) begin
                    seller_record[user2] <= user1; 
                end
            end
            default: begin end
            endcase
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if (!inf.rst_n) begin
        inf.out_valid <= 1'b0;
        inf.err_msg <= 4'b0;
        inf.complete <= 1'b0;
        inf.out_info <= 32'b0;
    end
    else if(inf.out_valid) begin
        inf.out_valid <= 1'b0;
        inf.err_msg <= 4'b0;
        inf.complete <= 1'b0;
        inf.out_info <= 32'b0;
    end
    else if((return_wrong || wrong_id || wrong_num || wrong_item) && action[3]) begin
        inf.out_valid <= 1'b1;
        if(return_wrong)  inf.err_msg <= 4'b1111;
        else if(wrong_id) inf.err_msg <= 4'b1001;
        else if(wrong_num) inf.err_msg <= 4'b1100;
        else inf.err_msg <= 4'b1010;
    end
    else if(finish_action_flag) begin
        inf.out_valid <= 1'b1;
        case (action)
            4'd1: begin
                if(buyer_full_reg) begin
                    inf.err_msg <= 4'b0100;
                    inf.complete <= 1'b0;
                    inf.out_info <= 0;
                end
                else if(seller_not_enough_reg) begin
                    inf.err_msg <= 4'b0010;
                    inf.complete <= 1'b0;
                    inf.out_info <= 0;
                end
                else if(no_money_reg) begin
                    inf.err_msg <= 4'b0011;
                    inf.complete <= 1'b0;
                    inf.out_info <= 0;
                end
                else begin
                    inf.err_msg <= 4'b0000;
                    inf.complete <= 1'b1;
                    inf.out_info <= user_info1;
                end
            end
            4'd2:begin
                inf.complete <= 1'b1;
                if(count_stop) inf.out_info <= {14'd0 , shop_info2.large_num , shop_info2.medium_num , shop_info2.small_num};
                else inf.out_info <= {16'd0,user_info1.money};
            end
            4'd4:begin
                if(wallet_full_reg) begin
                    inf.err_msg <= 4'b1000;
                end
                else begin
                    inf.complete <= 1'b1;
                    inf.out_info <= user_info1.money;
                end
            end
            4'd8:begin
                inf.complete <= 1'b1;
                inf.out_info <= {14'd0 , shop_info1.large_num , shop_info1.medium_num , shop_info1.small_num};
            end
            default: begin end
            endcase
    end
	else begin
        inf.out_valid <= 1'b0;
        inf.err_msg <= 4'b0;
        inf.complete <= 1'b0;
        inf.out_info <= 32'b0;
    end
end

endmodule