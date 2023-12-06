module SUBWAY(
    //Input Port
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    //Output Port
    out_valid,
    out
);


input clk, rst_n;
input in_valid;
input [1:0] init;
input [1:0] in0, in1, in2, in3; 
output reg       out_valid;
output reg [1:0] out;


reg [1:0] input_delay;

reg in_valid_r;
reg delay_flag;
reg mode;
reg [1:0] in_register [0:3][0:4];
reg [1:0] calculate_register [0:3][0:3];

reg [1:0] row_index;
reg [1:0] next_row_index;

reg output_set_flag;
reg output_flag;
reg [1:0] result;
reg [1:0] output_reg [0:63];

reg [0:7] count ;


wire [0:0] row_able [0:3];
wire [1:0] out_index;
assign out_index = input_delay -1;


assign row_able[0] = (calculate_register[0][3]== 2'b00 ) ? 1:0 ;
assign row_able[1] = (calculate_register[1][3]== 2'b00 ) ? 1:0 ;
assign row_able[2] = (calculate_register[2][3]== 2'b00 ) ? 1:0 ;
assign row_able[3] = (calculate_register[3][3]== 2'b00 ) ? 1:0 ;


always@(posedge clk or negedge rst_n)begin
    if(!rst_n )         in_valid_r <= 1'b0;
	else if(in_valid)   in_valid_r <= 1'b1;
    else                in_valid_r <= 1'b0;     
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n )           input_delay <= 2'd0;
	else if(in_valid_r)   input_delay <= input_delay +1;
    else                  input_delay <= 2'd0;     
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n )                     delay_flag <= 1'b0;
	else if(input_delay == 3'd3)    delay_flag <= 1'b1;
    else                            delay_flag <= 1'b0;       
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n )                                 count <= 9'b0;
    else if(count == 8'd59 && !out_valid)       count <= 0;
	else if(output_set_flag )                   count <= count + 1;
    else                                        count <= 9'b0;      
end


integer i;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        for(i=0 ; i < 5 ; i=i+1) begin
            in_register[0][i] <= 'b0;
            in_register[1][i] <= 'b0;
            in_register[2][i] <= 'b0;
            in_register[3][i] <= 'b0;
        end
    end
	else if(in_valid) begin
        // In the final input , only index 0~2 is useful , I can use in_register to  
        in_register[0][input_delay] <= in0;
        in_register[1][input_delay] <= in1;
        in_register[2][input_delay] <= in2;
        in_register[3][input_delay] <= in3;

        if(input_delay == 3'd3) begin
            in_register[0][4] <= in_register[0][0];
            in_register[1][4] <= in_register[1][0];
            in_register[2][4] <= in_register[2][0];
            in_register[3][4] <= in_register[3][0];
        end
        else begin
            in_register[0][4] <= in_register[0][4];
            in_register[1][4] <= in_register[1][4];
            in_register[2][4] <= in_register[2][4];
            in_register[3][4] <= in_register[3][4];
        end
    end
    else if(count == 8'd0) begin
        for(i=0 ; i < 5 ; i=i+1) begin
            in_register[0][i] <= 'b0;
            in_register[1][i] <= 'b0;
            in_register[2][i] <= 'b0;
            in_register[3][i] <= 'b0;
        end
    end
    else begin
        for(i=0 ; i < 5 ; i=i+1) begin
            in_register[0][i] <= in_register[0][i];
            in_register[1][i] <= in_register[1][i];
            in_register[2][i] <= in_register[2][i];
            in_register[3][i] <= in_register[3][i];
        end
    end
end

integer j;
integer k;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n )begin
        for(j=0 ; j < 4 ; j=j+1) begin
            calculate_register[0][j] <= 'b0;
            calculate_register[1][j] <= 'b0;
            calculate_register[2][j] <= 'b0;
            calculate_register[3][j] <= 'b0;
        end
    end
	else if(delay_flag) begin
        for(k=1 ; k < 4 ; k=k+1) begin
            calculate_register[0][k] <= in_register[0][k];
            calculate_register[1][k] <= in_register[1][k];
            calculate_register[2][k] <= in_register[2][k];
            calculate_register[3][k] <= in_register[3][k];
        end
        calculate_register[0][0] <= in_register[0][4];
        calculate_register[1][0] <= in_register[1][4];
        calculate_register[2][0] <= in_register[2][4];
        calculate_register[3][0] <= in_register[3][4];
    end
    else if(count == 8'd62) begin
        for(j=0 ; j < 4 ; j=j+1) begin
            calculate_register[0][j] <= 'b0;
            calculate_register[1][j] <= 'b0;
            calculate_register[2][j] <= 'b0;
            calculate_register[3][j] <= 'b0;
        end
    end
    else begin
        for(j=0 ; j < 4 ; j=j+1) begin
            calculate_register[0][j] <= calculate_register[0][j];
            calculate_register[1][j] <= calculate_register[1][j];
            calculate_register[2][j] <= calculate_register[2][j];
            calculate_register[3][j] <= calculate_register[3][j];
        end
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n )             row_index   <= 2'b0;
	else if( init)          row_index   <= init;
    else if(count == 8'd63) row_index   <= 1'b0;
    else if( mode== 1'b1 && output_set_flag)   
    begin
        if(result == 2'b01) begin
            row_index <= row_index +1;
        end
        else if(result == 2'b10) begin
            row_index <= row_index -1;
        end
        else begin
            row_index <= row_index;
        end
    end 
    else    
    begin
        row_index  <= row_index;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n )                                 mode <= 1'b1;
	else if(delay_flag)                         mode <= ~mode;
    else                                        mode <= mode;       
end

reg [1:0] next_row_index_r;
always@(posedge clk or negedge rst_n)begin
    if(!rst_n )                                 next_row_index_r <= 1'b0;
	else                                        next_row_index_r <= next_row_index;  
end


always@(*)begin

    if( out_index == 1'b0 && mode==1'b1) begin
        if(row_able[row_index]) begin
            next_row_index = row_index;
        end
        else begin
            if(row_index == 2'b00) begin
                if(row_able[1])      next_row_index = 2'b01;
                else if(row_able[2]) next_row_index = 2'b10;
                else                 next_row_index = 2'b11;
            end
            else if(row_index == 2'b01) begin
                if(row_able[0])      next_row_index = 2'b00;
                else if(row_able[2]) next_row_index = 2'b10;
                else                 next_row_index = 2'b11;
            end
            else if(row_index == 2'b10) begin
                if(row_able[0])      next_row_index = 2'b00;
                else if(row_able[1]) next_row_index = 2'b01;
                else                 next_row_index = 2'b11;
            end
            else begin
                if(row_able[0])      next_row_index = 2'b00;
                else if(row_able[1]) next_row_index = 2'b01;
                else                 next_row_index = 2'b10;
            end
        end
    end
    else begin
        next_row_index = next_row_index_r;
    end

end



always@(*)begin

    if(output_set_flag == 1'b1 && count <= 8'd59)begin
        if (mode == 1'b0) begin
            if(calculate_register[row_index][out_index] == 2'b01) begin
                result = 2'b11;
            end
            else begin
                result = 2'b00;
            end
        end
        else begin
            if(next_row_index != row_index) begin
                if(row_index <  next_row_index) begin
                    if(out_index != 2'b01 ) begin
                        result = 2'b01;
                    end
                    else begin
                        if(calculate_register[row_index][1]==2'b01) begin
                            result = 2'b11;
                        end
                        else begin
                            result = 2'b00;
                        end
                    end
                end
                else begin
                    if(out_index != 2'b01  ) begin
                        result = 2'b10;
                    end
                    else begin
                        if(calculate_register[row_index][1]==2'b01) begin
                            result = 2'b11;
                        end
                        else begin
                            result = 2'b00;
                        end
                    end
                end
            end
            else begin
                if(calculate_register[row_index][out_index] == 2'b01) begin
                    result = 2'b11;
                end
                else begin
                    result = 2'b00;
                end
            end
        end
    end
    else begin
        result = 2'b00;
    end
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n )             output_set_flag <= 1'b0;
	else if(delay_flag && output_set_flag == 1'b0)
    begin
        output_set_flag  <= 1'b1;
    end
    else if(count == 8'd62) output_set_flag <= 1'b0;
    else                    output_set_flag   <= output_set_flag ;
end



integer l;
always@(posedge clk or negedge rst_n)begin

    if(!rst_n) begin
        for( l=0 ; l < 64 ; l=l+1 ) begin
            output_reg[l] <= 2'b00;
        end
    end
    else begin
        if(!out_valid) begin
            if(!output_set_flag) begin
                for( l=0 ; l < 64 ; l=l+1 ) begin
                    output_reg[l] <= 2'b00;
                end
            end
            else begin

                output_reg[count] <= result;

                if(count == 8'd59) begin
                    if(in_register[row_index][1] == 2'b01) begin
                        output_reg[61] <= 2'b11;
                    end
                    else begin
                        output_reg[61] <= 2'b00;
                    end
                end
                else begin
                    output_reg[61] <= output_reg[61];
                end
            end
        end
    end

end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n )                                     out_valid <= 1'b0;
    else if(count == 8'd59 )                        out_valid <= 1'b1;
    else if(count < 8'd62 )                         out_valid <= out_valid;
	else                                            out_valid <= 1'b0;
end

always @(posedge clk or negedge rst_n )
begin
    if (!rst_n ) begin
        out <= 0;
    end
    else if(out_valid) begin 
        out <= output_reg[count+1];
    end
    else begin
        out <= 0;
    end
end

endmodule