module bridge(input clk, INF.bridge_inf inf);

logic read_flag;
logic write_flag;
logic [1:0] flag ;
logic out_high_flag;
logic wvalid_flag;
logic [63:0] write_reg;


always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AR_VALID = 1'b0;
        inf.AR_ADDR = 16'd0;
    end
    else if(flag == 2'd3) begin
        inf.AR_VALID = 1'b0;
        inf.AR_ADDR = 16'd0;
    end
    else if(read_flag && flag != 2'd2) begin
        inf.AR_VALID = 1'b1;
        inf.AR_ADDR = 17'h10000 | (inf.C_addr << 3);
    end
end


always_comb begin
    if( (read_flag && flag == 2'd3) || inf.C_out_valid) begin
        inf.R_READY = 1'b1;
    end
    else begin
        inf.R_READY = 1'b0;
    end
end


always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.AW_VALID = 1'b0;
        inf.AW_ADDR = 16'd0;
    end
    else if(flag == 2'd3) begin
        inf.AW_VALID = 1'b0;
        inf.AW_ADDR = 16'd0;
    end
    else if(write_flag && flag != 2'd2) begin
        inf.AW_VALID = 1'b1;
        inf.AW_ADDR = 17'h10000 | (inf.C_addr << 3);
    end
end


always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) inf.W_DATA  <= 'b0;
    else if(inf.AW_READY) inf.W_DATA <= write_reg;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) inf.B_READY <= 1'b0;
    else if(inf.B_VALID) inf.B_READY <= 1'b0;
    else if(inf.AW_READY) inf.B_READY <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) inf.W_VALID <= 1'b0;
    else if(inf.W_READY) inf.W_VALID <= 1'b0;
    else if(inf.AW_READY) inf.W_VALID <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) flag <= 1'b0;
    else if(inf.C_out_valid) flag <= 1'b0;
    else if(read_flag || write_flag) begin
        if(flag != 2'd3) flag <= flag +1;
        else flag <= 2'd0;
    end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) read_flag <= 1'b0;
    else if(inf.C_out_valid) read_flag <= 1'b0;
    else if(inf.C_in_valid && inf.C_r_wb ) read_flag <= 1'b1;
    else if(flag == 2'd3) read_flag <= 1'b0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) write_flag <= 1'b0;
    else if(inf.C_out_valid) write_flag <= 1'b0;
    else if(inf.C_in_valid && !inf.C_r_wb ) write_flag <= 1'b1;
    else if(flag == 2'd3) write_flag <= 1'b0;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) write_reg <= 64'b0;
    else if(inf.C_out_valid) write_reg <= 64'b0;
    else if(inf.C_in_valid && !inf.C_r_wb ) write_reg <= inf.C_data_w;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) out_high_flag <= 1'b0;
    else if(inf.C_in_valid) out_high_flag <= 1'b0;
    else if(inf.R_VALID ) out_high_flag <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) wvalid_flag <= 1'b0;
    else if(inf.W_READY) wvalid_flag <= 1'b0;
    else if(inf.W_VALID) wvalid_flag <= 1'b1;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if (!inf.rst_n) begin
        inf.C_out_valid  <= 1'b0;
        inf.C_data_r <= 64'd0;
    end
    else if(inf.B_VALID) begin
        inf.C_out_valid <= 1'b1;
        inf.C_data_r <= 64'd0;
    end
    else if(inf.R_VALID) begin
        if(!out_high_flag) begin
            inf.C_out_valid <= 1'b1;
            inf.C_data_r <= inf.R_DATA;
        end
        else begin
            inf.C_out_valid  <= 1'b0;
            inf.C_data_r <= 64'd0;
        end
    end
    else begin
        inf.C_out_valid  <= 1'b0;
    end
end


endmodule