module MMT(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [7:0] matrix;
input [1:0]  matrix_size,mode;
input [4:0]  matrix_idx;

output reg       	     out_valid;
output reg signed [49:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------

/* store 32 input matrixs to memory */
/* store matrix size in reg */
reg in1_flag;
reg state;
reg [4:0] width;
reg signed [8:0] mem_reg;
reg [11:0] sram_mem_index;
reg [15:0] mem_in_w;
reg   wen_mem_w;
wire  cen_mem_w;
wire  oen_mem_w;
wire [15:0] mem_out_w;

/* store the index of matrix needed to be used */
/* store calculate mode to reg*/
reg [1:0] in2_flag;
reg [1:0] mode_reg;
reg [4:0] matrix_index [0:2];



/* Read memory and store content to buffer*/
reg [2:0] shift_num;
reg [3:0] row;
reg [3:0] col;
reg [1:0] store_flag;
reg delay;
reg delay2;
reg   wen_buffer_1_w;
reg   wen_buffer_2_w;
wire  cen_buffer_w;
wire  oen_buffer_w;
wire signed [7:0] buffer_1_out;
wire signed[7:0] buffer_2_out;

reg [7:0] buffer_index;
reg [7:0] buffer_index2;
reg [7:0] buffer_in_w;
reg [7:0] buffer_in2_w;

/* calculate */
reg signed [7:0] mem_8bit_out_w;
reg signed [15:0] mul_result;
reg signed [26:0] mul_result2;
reg signed [19:0] mul_sum;
reg [3:0] count;
reg [3:0] count2;
reg [7:0] buffer_index2_reg;
reg [4:0] row_count;
reg signed [40:0] out_reg;
reg [3:0] caseNum;
assign cen_mem_w = 1'b0;
assign oen_mem_w = 1'b0;
assign cen_buffer_w = 1'b0;
assign oen_buffer_w = 1'b0;


//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

sram static_mem(.A(sram_mem_index) , .D(mem_in_w) , .CLK(clk) , .CEN(cen_mem_w) , .WEN(wen_mem_w) , .OEN(oen_mem_w) , .Q(mem_out_w));
buffer buffer_1(.A(buffer_index) , .D(buffer_in_w) , .CLK(clk) , .CEN(cen_buffer_w) , .WEN(wen_buffer_1_w) , .OEN(oen_buffer_w) , .Q(buffer_1_out));
buffer buffer_2(.A(buffer_index2) , .D(buffer_in2_w) , .CLK(clk) , .CEN(cen_buffer_w) , .WEN(wen_buffer_2_w) , .OEN(oen_buffer_w) , .Q(buffer_2_out));
/*

buffer buffer_c(.A(sram_mem_index) , .D(mem_in_w) , .CLK(clk) , .CEN(cen_w) , .WEN(wen_w) , .OEN(oen_w) , .Q(mem_out_w));
*/
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in1_flag <= 1'b0;
    else if(in_valid && !in1_flag) in1_flag <= 1'b1;
    else if(in_valid2) in1_flag <= 1'b0;
	else in1_flag <= in1_flag;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) state <= 1'b0;
    else if(in_valid) state <= ~state;
    else if(in_valid2 || caseNum == 4'd10) state <= 1'b0;
    else if(in2_flag==2'b11 && store_flag > 2'b00 && store_flag == 2'b01) state <= ~state;  
    else if(store_flag >= 2'b10 && delay2) state <= ~state;
    else if(store_flag == 2'b11 && !delay2) state <= 1'b1;
	else state <= state;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) width<= 5'd0;
    else if(caseNum == 4'd10 ) width<= 5'd0;
    else if(in_valid && !in1_flag) begin
        if(matrix_size == 2'b00) width <= 5'd2;
        else if(matrix_size == 2'b01) width <= 5'd4;
        else if(matrix_size == 2'b10) width <= 5'd8 ;
        else width <= 5'd16;
    end
	else width <= width;
end


always @(*) begin
	if(!rst_n) wen_mem_w = 1'b0;
    else if(caseNum == 4'd10 ) wen_mem_w = 1'b0;
    else if(in_valid) begin
        if(state) wen_mem_w = 1'b0;
        else wen_mem_w = 1'b1;
    end
	else wen_mem_w = 1'b1;
end

always @(*) begin
	if(!rst_n) mem_in_w = 16'b0;
    else if(in_valid && state) mem_in_w = {mem_reg , matrix};
	else mem_in_w = 16'b0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mem_reg <= 16'b0;
    else if(caseNum == 4'd10 ) mem_reg <= 16'b0;
    else if(in_valid) begin
        if(state == 1'b0) mem_reg <= matrix;
        else mem_reg <= mem_reg;
    end
	else mem_reg <= mem_reg;
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) sram_mem_index <= 11'b0;
    else if(caseNum == 4'd10 ) sram_mem_index <= 11'b0;
    else if(in1_flag && !state) sram_mem_index  <= sram_mem_index+1;
    else if(in2_flag == 2'b11) begin
        if(store_flag == 2'b00) sram_mem_index <= matrix_index[0] << shift_num;
        else if(store_flag == 2'b01) begin
            if(state) sram_mem_index <= sram_mem_index+1;
        end
        else if(store_flag == 2'b10) begin
            if(!delay) sram_mem_index <= matrix_index[2] << shift_num;
            else if(!delay2) sram_mem_index <= sram_mem_index;
            else if(state) sram_mem_index <= sram_mem_index+1;
                
        end
        else begin
            if(count2+1 == width &&  count+2 ==width ) sram_mem_index <= matrix_index[1] << shift_num;
            else if(!delay)  sram_mem_index <= matrix_index[1] << shift_num;
            else if(!delay2) sram_mem_index <= sram_mem_index;
            else if(state) sram_mem_index <= sram_mem_index+1;
        end
    end
	else sram_mem_index  <= sram_mem_index ;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in2_flag <= 2'b0;
    else if(caseNum == 4'd10 ) in2_flag <= 2'b0;
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2) in2_flag <= 2'b0;
    else if(row_count == width && count==4'd2) in2_flag <= 2'b0;
    else if(in_valid2) begin
        if(in2_flag == 2'b00) in2_flag <= 2'b01;
        else if(in2_flag == 2'b01) in2_flag <= 2'b10;
        else if(in2_flag == 2'b10) in2_flag <= 2'b11;
    end
	else in2_flag <= in2_flag;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mode_reg <= 2'b0;
    else if(caseNum == 4'd10 ) mode_reg <= 2'b0;
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2) mode_reg <= 2'b0;
    else if(row_count == width && count==4'd2) mode_reg <= 2'b0;
    else if(in_valid2 && !in2_flag) mode_reg <= mode;
	else mode_reg  <= mode_reg ;
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        matrix_index[0] <= 5'b0;
        matrix_index[1] <= 5'b0;
        matrix_index[2] <= 5'b0;
    end 
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2 ) begin
        matrix_index[0] <= 5'b0;
        matrix_index[1] <= 5'b0;
        matrix_index[2] <= 5'b0;
    end
    else if((row_count == width && count==4'd2) || caseNum==4'd10) begin
        matrix_index[0] <= 5'b0;
        matrix_index[1] <= 5'b0;
        matrix_index[2] <= 5'b0;
    end
    else if(in_valid2) begin
        if(in2_flag == 2'b0) begin
            if(mode == 2'b10) matrix_index[0] <= matrix_idx;
            else matrix_index[2] <= matrix_idx;
        end
        else if(in2_flag == 2'b1) matrix_index[1] <= matrix_idx;
        else begin
            if(mode_reg == 2'b10) matrix_index[2] <= matrix_idx;
            else matrix_index[0] <= matrix_idx;
        end
    end
	else begin
        matrix_index[0] <= matrix_index[0];
        matrix_index[1] <= matrix_index[1];
        matrix_index[2] <= matrix_index[2];
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        col <= 4'b0;
        row <= 4'b0;
        store_flag <= 2'b00;
        delay  <= 1'b0;
        delay2 <= 1'b0;
    end
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2 ) begin
        col <= 4'b0;
        row <= 4'b0;
        store_flag <= 2'b00;
        delay  <= 1'b0;
        delay2 <= 1'b0;
    end
    else if(row_count == width && count==4'd2 || caseNum==4'd10) begin
        col <= 4'b0;
        row <= 4'b0;
        store_flag <= 2'b00;
        delay  <= 1'b0;
        delay2 <= 1'b0;
    end
    else if( in2_flag == 2'b11 && store_flag ==2'b00 ) store_flag <= 2'b01;
    else if((store_flag==2'b01 || store_flag==2'b10) && !delay) delay <= 1'b1;
    else if(store_flag >=2'b10 && !delay2) delay2 <= 1'b1;
    else if( in2_flag == 2'b11 && store_flag !=2'b11 )begin
        if(row +1 != width) begin
            if(col+1 != width) col <= col +1;
            else begin
                col <= 4'b0;
                row <= row + 1;
            end
        end
        else begin
            if(col+1 != width) col <= col +1;
            else begin
                row <= 4'b0;
                col <= 4'b0;
                store_flag <= store_flag +1;
                delay <= 1'b0;
            end
        end
    end
    else if(store_flag == 2'b11 && !delay) begin
        delay <= 1'b1;
        delay2 <= 1'b0;
        row <= 4'b0;
        col <= 4'b0;
    end
    else if(store_flag == 2'b11 && delay) begin
        if(row +1 != width) begin
            if(col+1 != width) col <= col +1;
            else begin
                col <= 4'b0;
                row <= row + 1;
            end
        end
        else begin
            if(col+1 != width) col <= col +1;
            else begin
                row <= 4'b0;
                col <= 4'b0;
            end
        end
    end
end

always @(*) begin
    if(!rst_n) shift_num = 3'd0;
    else if(caseNum == 4'd10 ) shift_num = 3'd0;
    else begin
        if(width == 5'd2) shift_num = 3'd1;
        else if(width == 5'd4) shift_num = 3'd3;
        else if(width == 5'd8) shift_num = 3'd5;
        else shift_num = 3'd7;
    end
end

always @(*) begin
	if(delay && store_flag == 2'b01) wen_buffer_1_w = 1'b0;
    else wen_buffer_1_w = 1'b1;
end

always @(*) begin
	if(store_flag == 2'b10) wen_buffer_2_w = 1'b0;
    else wen_buffer_2_w = 1'b1;
end

always @(*) begin
    if(store_flag == 2'b01) begin
        if(mode_reg > 2'b01  )begin
            buffer_index = row * width + col;
            if(state) buffer_in_w = mem_out_w[15:8];
            else buffer_in_w = mem_out_w[7:0];
        end
        else begin
            buffer_index = col * width + row;
            if(state) buffer_in_w = mem_out_w[15:8];
            else buffer_in_w = mem_out_w[7:0];
        end
    end
    else if(store_flag == 2'b11 && delay && delay2) begin
        if(col +1 != width) begin
            buffer_index = row_count * width + col+1;
            buffer_in_w = 8'b0;
        end
        else begin
            if(count2+1 != width ) buffer_index = row_count * width ;
            else buffer_index = (row_count+1) * width  ;
            buffer_in_w = 8'b0;
        end
    end
    else begin
        buffer_in_w = 'b0;
        buffer_index = 'b0;
    end
end

always @(*) begin
    if(store_flag == 2'b10 && delay2) begin
        if(mode_reg == 2'b01 |  mode_reg == 2'b10 )begin
            buffer_index2 = row * width + col;
            if(state) buffer_in2_w = mem_out_w[15:8];
            else buffer_in2_w = mem_out_w[7:0];
        end
        else begin
            buffer_index2 = col * width + row;
            if(state) buffer_in2_w = mem_out_w[15:8];
            else buffer_in2_w = mem_out_w[7:0];
        end
    end
    else if(store_flag == 2'b11) begin
        buffer_index2 = buffer_index2_reg;
        buffer_in2_w = 'b0;
    end
    else begin
        buffer_in2_w = 'b0;
        buffer_index2 = 'b0;
    end
end

always @(*) begin
    if(store_flag == 2'b11 && delay &&delay2) begin
        if(state) mem_8bit_out_w = mem_out_w[15:8];
        else mem_8bit_out_w = mem_out_w[7:0];
    end
    else begin
        mem_8bit_out_w = 'b0;
    end
end

always @(*) begin
    if(store_flag == 2'b11 && delay && delay2) begin
        mul_result = mem_8bit_out_w * buffer_1_out;
    end
    else begin
        mul_result = 'b0;
    end
end

always @(*) begin
    if(store_flag == 2'b11 && (count2 || row_count) && count==0 ) begin
        mul_result2 = buffer_2_out * mul_sum ;
    end
    else begin
        mul_result2 = 'b0;
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) mul_sum <= 18'b0;
    else if(row_count == width && count==4'd2 || caseNum==4'd10) begin
        mul_sum <= 18'b0;
    end
	else if (store_flag == 2'b11 && delay && delay2) begin
        if(col != 0) mul_sum <= mul_sum + mul_result;
        else mul_sum <= mul_result;
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        count <= 4'b0;
        row_count <= 4'b0;
        count2 <= 4'b0;
    end
    else if(caseNum == 4'd10) begin
        count <= 4'b0;
        row_count <= 4'b0;
        count2 <= 4'b0;
    end
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2 ) begin
        count <= 4'b0;
        row_count <= 4'b0;
        count2 <= 4'b0;
    end
    else if(row_count == width && count==4'd2) begin
        count <= 4'b0;
        row_count <= 4'b0;
        count2 <= 4'b0;
    end
	else if (store_flag == 2'b11 && delay && delay2) begin
        if(count+1 != width) begin
            count <= count +1;
        end
        else begin
            count <= 0;
            if(count2 +1 != width) begin
                count2 <= count2 +1;
            end
            else begin
                count2 <= 0;
                row_count <= row_count+1;
            end
        end
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
        buffer_index2_reg <= 8'b0;
    end
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2 || caseNum==4'd10) buffer_index2_reg <= 8'b0;
    else if(row_count == width && count==4'd2 || caseNum==4'd10 ) buffer_index2_reg <= 8'b0;
	else if (store_flag == 2'b11 && count+2 == width ) begin
        if(count2 || row_count) buffer_index2_reg <= count2 * width + row_count;
    end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_reg <= 40'b0;
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2 || caseNum==4'd10) out_reg <= 40'b0;
    else if(row_count == width && count==4'd2 || caseNum==4'd10) out_reg <= 40'b0;
	else if(store_flag == 2'b11 && (count2 || row_count) && count==0 ) out_reg <= out_reg + mul_result2 ;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) caseNum <= 4'b0;
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2 ) caseNum <= caseNum +1 ;
    else if(row_count == width && count==4'd2 ) caseNum <= caseNum +1 ;
	else if(caseNum < 4'd10 ) caseNum <= caseNum ;
    else caseNum <= 4'b0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 1'b0;
    else if(row_count == width && count==4'd1) out_valid <= 1'b1;
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2 )  out_valid <= 1'b0;
    else if(row_count == width && count==4'd2) out_valid <= 1'b0;
	else out_valid <= out_valid;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_value <= 49'b0;
	else if(row_count == width && count==4'd1) out_value <= out_reg;
    else if(width == 4'd2 && row_count == width && count ==4'd0 && count2 )  out_value <= 49'b0;
    else if(row_count == width && count==4'd2) out_value <= 49'b0;
    else out_value <= out_value;
end
endmodule
