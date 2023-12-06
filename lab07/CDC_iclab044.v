`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
    doraemon_id,
    size,
    iq_score,
    eq_score,
    size_weight,
    iq_weight,
    eq_weight,
    //Output Port
	ready,
    out_valid,
	out,
    
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
output reg  [7:0] out;
output reg	out_valid,ready;

input rst_n, clk1, clk2, in_valid;
input  [4:0]doraemon_id;
input  [7:0]size;
input  [7:0]iq_score;
input  [7:0]eq_score;
input [2:0]size_weight,iq_weight,eq_weight;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

reg [4:0] id_reg [0:4];
reg [7:0] size_reg [0:4];
reg [7:0] iq_score_reg [0:4];
reg [7:0] eq_score_reg [0:4];
reg [2:0] weight [0:2];
reg [12:0] score [0:4];
reg flag;
reg flag2;
reg [2:0] count;
reg [2:0] count2;

reg [12:0] in_count;
reg [2:0] door_index;
reg [11:0] max_score;

reg [8:0] final_out;

reg w_inc;
reg [7:0] w_data;


reg r_inc;
wire r_empty;
wire [7:0] r_data ;
wire w_full;




always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
        in_count <= 0;
    end
    else if(count2 == 3'd6 ) begin
        in_count <= in_count +1;
    end
end

integer i;
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
		for( i=0 ; i < 5 ; i=i+1) begin
			id_reg[i]<= 0;
        end
    end
    else if(in_valid && flag2) begin
        id_reg[door_index] <= doraemon_id;
    end
	else if(in_valid )begin
		id_reg[count] <= doraemon_id;
	end
end




integer i2;
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
		for( i2=0 ; i2 < 5 ; i2=i2+1) begin
			size_reg[i2]<= 0;
        end
    end
    else if(in_valid && flag2) begin
        size_reg[door_index] <= size;
    end
	else if(in_valid)begin
		size_reg[count] <= size;
	end
end


integer i3;
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
		for( i3=0 ; i3 < 5 ; i3=i3+1) begin
			iq_score_reg[i3]<= 0;
        end
    end
    else if(in_valid && flag2) begin
        iq_score_reg[door_index] <= iq_score;
    end
	else if(in_valid)begin
		iq_score_reg[count] <= iq_score;
	end
end

integer i4;
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
		for( i4=0 ; i4 < 5 ; i4=i4+1) begin
			eq_score_reg[i4]<= 0;
        end
    end
    else if(in_valid && flag2) begin
        eq_score_reg[door_index] <= eq_score;
    end
	else if(in_valid )begin
		eq_score_reg[count] <= eq_score;
	end
end

always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
        weight[0] <= 0;
        weight[1] <= 0;
        weight[2] <= 0;
    end
	else if((count == 3'd4 && in_valid) || (flag2 && in_valid))begin
        weight[0] <= size_weight;
        weight[1] <= iq_weight;
        weight[2] <= eq_weight;
	end
end

integer i5;
always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
		for( i5=0 ; i5 < 5 ; i5=i5+1) begin
			score[i5]<= 0;
        end
    end
	else if( (count >= 3'd4 || !flag2 ) && count2 <= 3'd5)begin
        score[count2] <= size_reg[count2] * weight[0] + iq_score_reg[count2] * weight[1] + eq_score_reg[count2] * weight[2];
	end
end

always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
        door_index <= 'b0;
        max_score <= 'b0;
    end
    else if( count2 == 3'd1) begin
        door_index <= 'b0;
        max_score <= score[0];
    end
	else if( count2 > 3'd1 && count2 <= 3'd6)begin
        if(max_score < score[count2-1]) begin
            max_score <= score[count2-1];
            door_index <= count2 -1;
        end
	end
end

always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
        count <= 3'b0;
    end
    else if(count2 == 3'd6) begin
        count <= 3'b0;
    end
	else if(in_valid)begin
        if(count == 3'd0) count <= 3'd1;
        else if(count == 3'd1) count <= 3'd2;
        else if(count == 3'd2) count <= 3'd3;
        else if(count == 3'd3) count <= 3'd4;
        else if(count == 3'd4) count <= 3'd5;
	end
end

always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
        count2 <= 3'b0;
    end
    else if(count2 == 3'd6) count2 <= 3'd0;
	else if((count == 3'd5) || (flag && !flag2))begin
        if(count2 == 3'd0) count2 <= 3'd1;
        else if(count2 == 3'd1) count2 <= 3'd2;
        else if(count2 == 3'd2) count2 <= 3'd3;
        else if(count2 == 3'd3) count2 <= 3'd4;
        else if(count2 == 3'd4) count2 <= 3'd5;
        else if(count2 == 3'd5) count2 <= 3'd6;
	end
end



always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
        flag <= 1'b0;
    end
	else if(count2 == 3'd6 && !flag)begin
        flag <= 1'b1;
	end
end

always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
        flag2 <= 1'b0;
    end
    else if(flag2 && in_valid) begin
        flag2 <= 1'b0;
    end
	else if(count2 == 3'd5 && !flag2)begin
        flag2 <= 1'b1;
	end
end

always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) begin
        w_inc <= 0;
        w_data <= 0;
    end
    else if((count == 3'd5 || flag ) && count2 == 3'd6) begin
        w_inc <= 1;
        w_data <= ((door_index << 5) | id_reg[door_index]);
    end
    else begin
        w_inc <= 0;
        w_data <= 0;
    end
end

always@(*)begin
	if(!r_empty) begin
        r_inc = 1;
    end
    else begin
        r_inc = 0;
    end
end

always@(posedge clk1 or negedge rst_n)begin
	if(!rst_n) ready = 0;
    else if(in_count >= 13'd5996 ) ready = 0;
    else if(count <= 3'd3 && !flag)	ready =1;
    else if(count == 3'd4 && !flag && in_valid) ready =0;
    else if(count2 == 3'd6) ready = 1;
    else if(flag && in_valid) ready = 0;
end

reg r_inc_reg;


always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n) r_inc_reg <= 0;
    else if(r_inc_reg) r_inc_reg <= 0;
    else if(r_inc) r_inc_reg <=  1;
end

always@(posedge clk2 or negedge rst_n)begin
	if(!rst_n) final_out <= 0;
    else if(r_inc) final_out <=  r_data;
    else final_out <= 0;
end

always@(*)begin
	if(!rst_n) out = 0;
    else out = final_out;
end

always@(*)begin
	if(!rst_n) out_valid = 0;
    else if(r_inc_reg) out_valid = 1;
    else  out_valid = 0;
end



AFIFO u_AFIFO(
    .rst_n(rst_n),
    .rclk(clk2),
    .rinc(r_inc),
	.wclk(clk1),
    .winc(w_inc),
    .wdata(w_data),
    .rempty(r_empty),
    .rdata(r_data),
    .wfull(w_full)
);

endmodule