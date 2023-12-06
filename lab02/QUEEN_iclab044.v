module QUEEN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    col,
    row,

    in_valid_num,
    in_num,

    out_valid,
    out

);

input               clk, rst_n, in_valid,in_valid_num;
input       [3:0]   col,row;
input       [2:0]   in_num;

output reg          out_valid;
output reg  [3:0]   out;


reg [3:0] current_state;
reg [3:0] next_state;

reg [3:0] in_num_r;
reg signed[4:0] row_r [11:0];
reg signed[4:0] col_r [11:0];
reg [11:0] bitmap [11:0];

reg [3:0] write_queen_num;
reg [3:0] wrong_queen_num;
reg [3:0] output_counter;


parameter before_input = 4'h0;
parameter read_input = 4'h1;
parameter search = 4'h2;
parameter wrong_occur = 4'h3;
parameter reload = 4'h4;
parameter update_wrong_dot = 4'h5;
parameter check = 4'h6;
parameter wrong_occur_2 = 4'h7;
parameter answer = 4'h8;
parameter wait_next_input = 4'h9;


wire [0:0] count [11:0];
wire [3:0] count_result;
wire [0:0] row_index [11:0];
wire [11:0] row_index_vector;
wire [3:0] col_pos;
wire [3:0] row_pos;
wire [3:0] insertable_line;

assign count[0] = (bitmap[0] == 12'hfff) ? 1'b0: 1'b1; 
assign count[1] = (bitmap[1] == 12'hfff) ? 1'b0: 1'b1;
assign count[2] = (bitmap[2] == 12'hfff) ? 1'b0: 1'b1;
assign count[3] = (bitmap[3] == 12'hfff) ? 1'b0: 1'b1;
assign count[4] = (bitmap[4] == 12'hfff) ? 1'b0: 1'b1;
assign count[5] = (bitmap[5] == 12'hfff) ? 1'b0: 1'b1;
assign count[6] = (bitmap[6] == 12'hfff) ? 1'b0: 1'b1;
assign count[7] = (bitmap[7] == 12'hfff) ? 1'b0: 1'b1;
assign count[8] = (bitmap[8] == 12'hfff) ? 1'b0: 1'b1;
assign count[9] = (bitmap[9] == 12'hfff) ? 1'b0: 1'b1;
assign count[10] = (bitmap[10] == 12'hfff) ? 1'b0: 1'b1;
assign count[11] = (bitmap[11] == 12'hfff) ? 1'b0: 1'b1;

assign count_result = count[0]+count[1]+count[2]+count[3]+count[4]+count[5]+count[6]+count[7]+count[8]+count[9]+count[10]+count[11];
assign col_pos = count[0] ? 4'h0 : (count[1] ? 4'h1 : (count[2] ? 4'h2 : (count[3] ? 4'h3 : (count[4] ? 4'h4 : (count[5] ? 4'h5 : (count[6] ? 4'h6 : (count[7] ? 4'h7 : (count[8] ? 4'h8 : (count[9] ? 4'h9 : (count[10] ? 4'ha : (count[11] ? 4'hb : 4'hc)))))))))));
assign insertable_line = 12'hc - count_result ;

assign row_index_vector = (~(bitmap[col_pos]))^((~(bitmap[col_pos])) & ((~(bitmap[col_pos]))-1));
assign row_index[0] = (row_index_vector == 12'h001) ? 1'b1: 1'b0; 
assign row_index[1] = (row_index_vector == 12'h002) ? 1'b1: 1'b0; 
assign row_index[2] = (row_index_vector == 12'h004) ? 1'b1: 1'b0; 
assign row_index[3] = (row_index_vector == 12'h008) ? 1'b1: 1'b0; 
assign row_index[4] = (row_index_vector == 12'h010) ? 1'b1: 1'b0; 
assign row_index[5] = (row_index_vector == 12'h020) ? 1'b1: 1'b0; 
assign row_index[6] = (row_index_vector == 12'h040) ? 1'b1: 1'b0; 
assign row_index[7] = (row_index_vector == 12'h080) ? 1'b1: 1'b0; 
assign row_index[8] = (row_index_vector == 12'h100) ? 1'b1: 1'b0; 
assign row_index[9] = (row_index_vector == 12'h200) ? 1'b1: 1'b0; 
assign row_index[10] = (row_index_vector == 12'h400) ? 1'b1: 1'b0; 
assign row_index[11] = (row_index_vector == 12'h800) ? 1'b1: 1'b0; 

assign row_pos = row_index[0] ? 4'h0 : (row_index[1] ? 4'h1 : (row_index[2] ? 4'h2 : (row_index[3] ? 4'h3 : (row_index[4] ? 4'h4 : (row_index[5] ? 4'h5 : (row_index[6] ? 4'h6 : (row_index[7] ? 4'h7 : (row_index[8] ? 4'h8 : (row_index[9] ? 4'h9 : (row_index[10] ? 4'ha : (row_index[11] ? 4'hb : 4'hc)))))))))));


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)  current_state <= before_input;
    else        current_state <= next_state;
end

always@(*)begin
	case( current_state )
		before_input: begin
			if( in_valid_num )  next_state = read_input;
			else                next_state = current_state;
		end                                   
		read_input: begin                 
            if(write_queen_num == in_num_r)     next_state = search;
            else                                next_state = current_state;            
		end       
        search: begin                 
            if(write_queen_num == insertable_line && write_queen_num != 4'hb) begin
                next_state = current_state;
            end
            else if(write_queen_num == insertable_line && write_queen_num == 4'hb)begin
                next_state = answer ;
            end
            else begin
                next_state = wrong_occur;
            end
		end 
        wrong_occur: begin
            next_state = reload;
        end    
        reload: begin
            if(write_queen_num+1 != wrong_queen_num) next_state = current_state;
            else                                     next_state = update_wrong_dot;
        end 
        update_wrong_dot: begin
            next_state = check;
        end      
        check : begin
            if(write_queen_num == insertable_line) next_state = search;
            else                                   next_state = wrong_occur_2;
        end
        wrong_occur_2:begin
            next_state = reload;
        end
        answer : begin
            if(output_counter < 11)                 next_state = current_state;
            else                                    next_state = wait_next_input;
        end
        wait_next_input : begin
            if(in_valid_num)    next_state = read_input;
            else                next_state = current_state;
        end
        default : begin
            next_state = before_input;       
        end                  
	endcase 
end


always@(posedge clk or negedge rst_n)begin
    if(!rst_n)                  in_num_r <= 4'h0;
    else begin
        if(in_valid_num)        in_num_r <= in_num;
        else                    in_num_r <= in_num_r;
    end
end

integer i , j , k;
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n ) begin
        for(i=0 ; i < 12 ; i=i+1) begin
            row_r[i] <= -5'd1;
        end
    end
    else begin
        if(in_valid_num || (write_queen_num < in_num_r  && current_state != reload))begin
            row_r[write_queen_num] <= row;
        end     
        else if(current_state == search) begin
            row_r[write_queen_num] <= row_pos;
        end
        else if(current_state == wrong_occur) begin
            row_r[write_queen_num-1] <= -5'd1;
        end
        else if(current_state == wrong_occur_2) begin
            row_r[write_queen_num] <= -5'd1;
        end
        else if(current_state == wait_next_input) begin
            for(i=0 ; i < 12 ; i=i+1) begin
                row_r[i] <= -5'd1;
            end
        end
        else begin
            for(i=0 ; i < 12 ; i=i+1) begin
                row_r[i] <= row_r[i];
            end
        end
    end                  
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n ) begin
        for(j=0 ; j < 12 ; j=j+1) begin
            col_r[j] <= -5'd1;
        end
    end
    else begin
        if(in_valid_num || ((write_queen_num < in_num_r) && (current_state != reload) ) ) begin
            col_r[write_queen_num] <= col;
        end  
        else if(current_state == search) begin
            col_r[write_queen_num] <= col_pos;
        end
        else if(current_state == wrong_occur) begin
            col_r[write_queen_num-1] <= -5'd1;
        end
        else if(current_state == wrong_occur_2) begin
            col_r[write_queen_num] <= -5'd1;
        end
        else if(current_state ==wait_next_input) begin
            for(j=0 ; j < 12 ; j=j+1) begin
                col_r[j] <= -5'd1;
            end
        end
        else begin 
            for(j=0 ; j < 12 ; j=j+1) begin
                col_r[j] <= col_r[j];
            end
        end
    end                       
end

wire [4:0]  column ;
wire [11:0] row_vector_input;
wire [11:0] update_vector; 
assign      row_vector_input = (current_state ==reload) ? (12'b000000000001 << row_r[write_queen_num]):(12'b000000000001 << row) ;
assign      column  =(current_state ==reload) ? col_r[write_queen_num]:col;
assign      update_vector =  (12'b000000000001 << row_r[write_queen_num]) | ((12'b000000000001 << row_r[write_queen_num])-1);

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) begin
        for(k=0 ; k < 12 ; k=k+1) begin
            bitmap[k] <= 12'h000;
        end
    end
    else begin
        if(in_valid_num || (write_queen_num < in_num_r && current_state!=wait_next_input) || current_state == reload) begin
            for(k=0 ; k < 12 ; k=k+1) begin
                if(k == column) begin
                    bitmap[k] <= 12'hfff;
                end
                else if( k > column) begin
                    bitmap[k] <= ((row_vector_input << (k-column)) | (row_vector_input >> ( k- column)) | row_vector_input) | bitmap[k];
                end
                else begin
                    bitmap[k] <= ((row_vector_input << (column-k)) | (row_vector_input >> ( column-k )) | row_vector_input) | bitmap[k];
                end
            end
        end
        else if (current_state == search) begin
            for(k=0 ; k < 12 ; k=k+1) begin
                if(k == col_pos) begin
                    bitmap[k] <= 12'hfff;
                end
                else if( k > col_pos) begin
                    bitmap[k] <= ((row_index_vector  << (k-col_pos)) | (row_index_vector  >> ( k- col_pos)) | row_index_vector ) | bitmap[k];
                end
                else begin
                    bitmap[k] <= ((row_index_vector  << (col_pos-k)) | (row_index_vector  >> ( col_pos-k )) | row_index_vector ) | bitmap[k];
                end
            end
        end
        else if (current_state == wrong_occur || current_state == wrong_occur_2) begin
            for(k=0 ; k < 12 ; k=k+1) begin
                bitmap[k] <= 12'h000;
            end
        end
        else if(current_state == update_wrong_dot) begin
            bitmap[col_pos] <= bitmap[col_pos] | update_vector;
        end
        else if(current_state == wait_next_input)begin
            for(k=0 ; k < 12 ; k=k+1) begin
                bitmap[k] <= 12'h000;
            end
        end
        else begin
            for(k=0 ; k < 12 ; k=k+1) begin
                bitmap[k] <= bitmap[k];
            end
        end   
    end                       
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n) begin
        write_queen_num <= 4'h0 ;  
    end
    else begin
        if(in_valid_num || ((write_queen_num < in_num_r) && (current_state!=wait_next_input) )|| current_state == search  || current_state == reload   )begin
            write_queen_num <= write_queen_num +1;
        end
        else if(current_state == wrong_occur || current_state == wrong_occur_2)begin
            write_queen_num <= 0; 
        end
        else if(current_state == answer) begin
            write_queen_num <= 4'hd;
        end
        else if(current_state == wait_next_input) begin
            write_queen_num <= 4'h0 ;  
        end
        else begin
            write_queen_num <= write_queen_num; 
        end
        
    end 
end

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n ) begin
        wrong_queen_num <= 4'hf ;  
    end
    else begin
        if(current_state == wrong_occur)        wrong_queen_num <= write_queen_num -2;
        else if(current_state == wrong_occur_2) wrong_queen_num <= write_queen_num-1;
        else if(current_state == wait_next_input) begin
            wrong_queen_num <= 4'hf ;  
        end
        else begin
            wrong_queen_num <= wrong_queen_num; 
        end
    end 
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n )                         output_counter <= 4'h0;
    else if(current_state == answer)    output_counter <= output_counter+1;
	else                                output_counter <= 4'h0;
end

always@(posedge clk or negedge rst_n)begin
    if(!rst_n )                                                     out_valid <= 4'h0;
    else if(current_state == answer)                                out_valid <= 4'h1;
	else if((current_state == answer) && (output_counter == 11))    out_valid <= 4'h0;
	else                                                            out_valid <= 4'h0;
end

integer l;
always @(posedge clk or negedge rst_n )
begin
    if (!rst_n ) begin
        out <= 0;
    end
    else if(current_state == answer) begin
        for(l=0 ; l < 12 ; l=l+1) begin
            if(col_r[l]==output_counter) begin
                out <= row_r[l];
            end
        end
    end
    else begin 
        out <= 0;
    end
end


endmodule 
