//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NCTU ED415
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 spring
//   Midterm Proejct            : GLCM 
//   Author                     : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : GLCM.v
//   Module Name : GLCM
//   Release version : V1.0 (Release Date: 2023-04)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module GLCM(
				clk,	
			  rst_n,	
	
			in_addr_M,
			in_addr_G,
			in_dir,
			in_dis,
			in_valid,
			out_valid,
	

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32;
input			  clk,rst_n;



// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
      your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
	    therefore I declared output of AXI as wire in Poly_Ring
*/
   
// -----------------------------
// IO port
input [ADDR_WIDTH-1:0]      in_addr_M;
input [ADDR_WIDTH-1:0]      in_addr_G;
input [1:0]  	  		in_dir;
input [3:0]	    		in_dis;
input 			    	in_valid;
output reg 	              out_valid;
// -----------------------------


// axi write address channel 
output  wire [ID_WIDTH-1:0]        awid_m_inf;
output  wire [ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [2:0]            awsize_m_inf;
output  wire [1:0]           awburst_m_inf;
output  wire [3:0]             awlen_m_inf;
output  wire                 awvalid_m_inf;
input   wire                 awready_m_inf;
// axi write data channel 
output  wire [ DATA_WIDTH-1:0]     wdata_m_inf;
output  wire                   wlast_m_inf;
output  wire                  wvalid_m_inf;
input   wire                  wready_m_inf;
// axi write response channel
input   wire [ID_WIDTH-1:0]         bid_m_inf;
input   wire [1:0]             bresp_m_inf;
input   wire              	   bvalid_m_inf;
output  wire                  bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]       arid_m_inf;
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [3:0]            arlen_m_inf;
output  wire [2:0]           arsize_m_inf;
output  wire [1:0]          arburst_m_inf;
output  wire                arvalid_m_inf;
input   wire               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [1:0]             rresp_m_inf;
input   wire                   rlast_m_inf;
input   wire                  rvalid_m_inf;
output  wire                  rready_m_inf;
// -----------------------------


reg [4:0] input_matrix [0:15][0:15];
reg [1:0] dir_reg;
reg [3:0] dis_reg;
reg [3:0] offset_reg [0:1];
reg [11:0] addr_M_base;
reg [11:0] addr_G_base;
reg [1:0] in_flag;
reg [1:0] flag;
reg [2:0] counter;
reg [3:0] counter2;
reg [3:0] counter3;

reg [4:0] row_idx;
reg [4:0] col_idx;
reg [7:0] glcm_matrix [0:31][0:31];
reg glcm_finish_flag;


wire [4:0] row_plus_offset;
wire [4:0] col_plus_offset;
wire [4:0] tmp_w;
wire [4:0] tmp2_w;

reg [4:0] tmp_reg;
reg [4:0] tmp2_reg;
reg flag2;


reg [3:0] sram_mem_index;
reg [1:0] mem_in_w;
wire [1:0] mem_out_w;
reg out_flag;
reg [1:0] mem_out_r;

wire cen_mem_w;
reg wen_mem_w;
wire oen_mem_w;

assign cen_mem_w = 1'b0;
assign oen_mem_w = 1'b0;

sram static_mem(.A(sram_mem_index) , .D(mem_in_w) , .CLK(clk) , .CEN(cen_mem_w) , .WEN(wen_mem_w) , .OEN(oen_mem_w) , .Q(mem_out_w));

assign row_plus_offset = row_idx + offset_reg[1];
assign col_plus_offset = col_idx + offset_reg[0];
assign tmp_w = input_matrix[col_idx][row_idx];
assign tmp2_w = col_plus_offset < 5'd16 ? input_matrix[col_plus_offset ][row_plus_offset]:0;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
    tmp_reg <= 'b0;
    tmp2_reg <= 'b0;
  end
  else if(out_valid) begin
    tmp_reg <= 'b0;
    tmp2_reg <= 'b0;
  end
  else if(col_plus_offset <= 5'd16) begin
    tmp_reg <= tmp_w;
    tmp2_reg <= tmp2_w;
  end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
    flag2 <= 1'b0;
  end
  else if(out_valid) begin
    flag2 <= 1'b0;
  end
  else if(counter == 3'd4) begin
    flag2 <= 1'b1;
  end
end

assign bready_m_inf = 1'b1;

wire [11:0] add_12_result;
reg [11:0] operand1;
reg [4:0] operand2;

assign add_12_result = operand1 + (operand2 << 6);

always @(*) begin
  if((glcm_finish_flag && flag != 2'd2 && !out_valid )) begin
    operand1 = addr_G_base;
    operand2 = counter3;
  end
  else begin
    operand1 = addr_M_base;
    operand2 = counter;
  end
end

/* read data from dram */
reg [ADDR_WIDTH-1:0]   araddr_m_inf_w;
reg arvalid_m_inf_w;
reg rready_m_inf_w;
assign arid_m_inf = 4'b0;
assign araddr_m_inf = araddr_m_inf_w;
assign arlen_m_inf = 4'b1111;
assign arsize_m_inf = 3'b010;
assign arburst_m_inf = 2'b01;
assign arvalid_m_inf = arvalid_m_inf_w;
assign rready_m_inf = rready_m_inf_w;

always @(*) begin
  if((in_flag==1'b1 && counter < 3'd4 && flag != 2'd2)) begin
    araddr_m_inf_w = {16'h0000, 4'h1, add_12_result};
    arvalid_m_inf_w = 1'b1;
  end
  else begin
    araddr_m_inf_w = 'b0;
    arvalid_m_inf_w = 1'b0;
  end
end
always @(*) begin
  if(counter < 3'd4 && flag == 2'd2) rready_m_inf_w = 1'b1;
  else rready_m_inf_w = 1'b0;
end

/* write data to dram */
reg [ADDR_WIDTH-1:0]  awaddr_m_inf_w;
reg awvalid_m_inf_w;
reg [DATA_WIDTH-1:0] wdata_m_inf_w;
reg wlast_m_inf_w;
reg wvalid_m_inf_w;

assign awid_m_inf = 4'b0;
assign awaddr_m_inf = awaddr_m_inf_w;
assign awsize_m_inf = 3'b010;
assign awburst_m_inf = 2'b01;
assign awlen_m_inf = 4'b1111;
assign awvalid_m_inf = awvalid_m_inf_w;
assign wvalid_m_inf = wvalid_m_inf_w;
assign wlast_m_inf = wlast_m_inf_w;
assign wdata_m_inf = wdata_m_inf_w;



always @(*) begin
  if((glcm_finish_flag && flag != 2'd2 && !out_valid )) begin
    awaddr_m_inf_w = {16'h0000, 4'h2, add_12_result};
    awvalid_m_inf_w = 1'b1;
  end
  else begin
    awaddr_m_inf_w = 'b0;
    awvalid_m_inf_w = 1'b0;
  end
end

wire [7:0] data [0:3];
wire [31:0] data_32;
assign data[0] = glcm_matrix[0][3];
assign data[1] = glcm_matrix[0][2];
assign data[2] = glcm_matrix[0][1];
assign data[3] = glcm_matrix[0][0];
assign data_32 = {data[0] , data[1] , data[2], data[3]};

always @(*) begin
  if((wvalid_m_inf)) begin
    wdata_m_inf_w = data_32;
  end
  else begin
    wdata_m_inf_w = 'b0;
  end
end

always @(*) begin
  if(glcm_finish_flag && flag == 2'd2 && counter2 <= 4'hf) begin
    wvalid_m_inf_w = 1'b1;
  end
  else begin
    wvalid_m_inf_w = 1'b0;
  end
end

always @(*) begin
  if(glcm_finish_flag && counter2 == 4'hf) wlast_m_inf_w = 1'b1;
  else wlast_m_inf_w = 1'b0;
end


always @(posedge clk or negedge rst_n) begin
	if(!rst_n) sram_mem_index <= 1'b0;
  else sram_mem_index <= sram_mem_index;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_flag <= 1'b0;
  else if(out_valid) out_flag <= 1'b0;
  else if(counter3 == 4'd15 && wlast_m_inf_w) out_flag <= 1'b1;
end

always @(*) begin
	if(counter3 == 4'd15 && wlast_m_inf_w ) wen_mem_w = 1'b0;
  else wen_mem_w = 1'b1;
end

always @(*) begin
	if(counter3 == 4'd15 && wlast_m_inf_w ) mem_in_w = 1'b1;
  else mem_in_w = 1'b0;
end

always @(*) begin
	if(out_flag) mem_out_r = mem_out_w;
  else mem_out_r = 1'b0;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) counter2 <= 1'b0;
  else if(wlast_m_inf_w) counter2 <= 1'b0;
  else if(wready_m_inf) counter2 <= counter2+1;
  
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) counter3 <= 1'b0;
  else if(out_valid) counter3 <= 1'b0;
  else if(wlast_m_inf_w) counter3 <= counter3+1;
end

/* set input reg */
integer i ,j;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
    for( i = 0 ; i < 16 ; i= i+1)begin
      for ( j = 0 ; j < 16 ; j= j+1) begin
          input_matrix[i][j] <= 'b0;
      end
    end
  end
  else if(out_valid) begin
    for( i = 0 ; i < 16 ; i= i+1)begin
      for ( j = 0 ; j < 16 ; j= j+1) begin
          input_matrix[i][j] <= 'b0;
      end
    end
  end
  else if(rvalid_m_inf) begin
    input_matrix[15][0] <= input_matrix[15][4];
    input_matrix[15][1] <= input_matrix[15][5];
    input_matrix[15][2] <= input_matrix[15][6];
    input_matrix[15][3] <= input_matrix[15][7];
    input_matrix[15][4] <= input_matrix[15][8];
    input_matrix[15][5] <= input_matrix[15][9];
    input_matrix[15][6] <= input_matrix[15][10];
    input_matrix[15][7] <= input_matrix[15][11];
    input_matrix[15][8] <= input_matrix[15][12];
    input_matrix[15][9] <= input_matrix[15][13];
    input_matrix[15][10] <= input_matrix[15][14];
    input_matrix[15][11] <= input_matrix[15][15];
    input_matrix[15][12] <= rdata_m_inf[4:0];
    input_matrix[15][13] <= rdata_m_inf[12:8];
    input_matrix[15][14] <= rdata_m_inf[20:16];
    input_matrix[15][15] <= rdata_m_inf[28:24];
    for( i = 0 ; i < 15 ; i= i+1)begin      
      input_matrix[i][12] <= input_matrix[i+1][0];
      input_matrix[i][13] <= input_matrix[i+1][1];
      input_matrix[i][14] <= input_matrix[i+1][2];
      input_matrix[i][15] <= input_matrix[i+1][3];
      for (j = 0 ; j < 12 ; j= j+1) begin
          input_matrix[i][j] <= input_matrix[i][j+4];
      end
    end
  end
end

integer i2 ,j2 , k2;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
    for( i2 = 0 ; i2 < 32 ; i2= i2+1)begin
      for ( j2 = 0 ; j2 < 32 ; j2= j2+1) begin
          glcm_matrix[i2][j2] <= 'b0;
      end
    end
  end
  else if(out_valid) begin
    for( i2 = 0 ; i2 < 32 ; i2= i2+1)begin
      for ( j2 = 0 ; j2 < 32 ; j2= j2+1) begin
          glcm_matrix[i2][j2] <= 'b0;
      end
    end
  end
  else if(flag2 &&  !glcm_finish_flag) begin
    glcm_matrix[tmp_reg][tmp2_reg] <= glcm_matrix[tmp_reg][tmp2_reg]+1;
  end
  else if(wready_m_inf) begin
    for( i2 = 0 ; i2 < 31 ; i2= i2+1)begin
      glcm_matrix[i2][28] <= glcm_matrix[i2+1][0];
      glcm_matrix[i2][29] <= glcm_matrix[i2+1][1];
      glcm_matrix[i2][30] <= glcm_matrix[i2+1][2];
      glcm_matrix[i2][31] <= glcm_matrix[i2+1][3];
      for ( j2 = 0 ; j2 < 28 ; j2= j2+1) begin
          glcm_matrix[i2][j2] <= glcm_matrix[i2][j2+4];
      end
    end
    for ( k2 = 0 ; k2 < 28 ; k2= k2+1) begin
        glcm_matrix[31][k2] <= glcm_matrix[31][k2+4];
    end
  end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) in_flag <= 1'b0;
  else if(out_valid) in_flag <= 1'b0;
  else if(in_valid) in_flag <= 1'b1;
  else if(counter == 3'd4) in_flag <= 2'b10;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) flag <= 1'b0;
  else if(out_valid) flag <= 'b0 ;
  else if(wlast_m_inf_w) flag <= 'b0 ;
  else if(glcm_finish_flag) begin
    if(flag != 2'd2) flag <= flag +1;
  end
  else if(col_plus_offset == 5'd16) flag <= 'b0 ;
  else if(flag == 2'd2 && rlast_m_inf) flag <= 'b0 ;
  else if(in_flag && flag != 2'd2) flag <= flag +1;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) counter <= 1'b0;
  else if(out_valid) counter <= 1'b0;
  else if(rlast_m_inf) counter <= counter + 1;
end

reg [4:0] row;
always @(*) begin
  if(!offset_reg[1]) row = row_idx;
  else row = row_plus_offset;
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
    row_idx <= 'b0;
    col_idx <= 'b0;
    glcm_finish_flag <= 1'b0;
  end
  else if(out_valid) begin
    row_idx <= 'b0;
    col_idx <= 'b0;
    glcm_finish_flag <= 1'b0;
  end
  else if(col_plus_offset == 5'd16) glcm_finish_flag <= 1'b1;
  else if(counter == 3'd4) begin
    if(!offset_reg[0]) begin
      if(row_plus_offset == 4'hf) begin
        row_idx <= 'b0;
        col_idx <= col_idx +1;
      end
      else begin
        row_idx <= row_idx +1;
      end
    end
    else begin
      if(col_plus_offset <= 4'hf && row_plus_offset <= 4'hf) begin
        if(col_plus_offset <= 4'hf) begin
          if(row < 4'hf ) begin
            row_idx <= row_idx +1;
          end
          else begin
            row_idx <= 'b0;
            col_idx <= col_idx +1;
          end
        end
      end
    end
  end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
    dir_reg <= 'b0;
    dis_reg <= 'b0;
    addr_M_base <= 'b0;
    addr_G_base <= 'b0;
    offset_reg[0] <= 'b0;
    offset_reg[1] <= 'b0; 
  end
  else if(out_valid) begin
    dir_reg <= 'b0;
    dis_reg <= 'b0;
    addr_M_base <= 'b0;
    addr_G_base <= 'b0;
    offset_reg[0] <= 'b0;
    offset_reg[1] <= 'b0; 
  end
  else if(in_valid) begin
    dir_reg <= in_dir;
    dis_reg <= in_dis;
    addr_M_base <= in_addr_M[11:0];
    addr_G_base <= in_addr_G[11:0];
    if( in_dir == 2'b01) begin
      offset_reg[0] <= in_dis ;
      offset_reg[1] <= 1'b0;
    end
    else if(in_dir == 2'b10)begin
      offset_reg[0] <= 1'b0;
      offset_reg[1] <= in_dis ;
    end
    else if(in_dir == 2'b11) begin
      offset_reg[0] <= in_dis;
      offset_reg[1] <= in_dis;
    end
  end
end

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) out_valid <= 1'b0;
  else if(out_valid) out_valid <= 1'b0;
  else if(mem_out_r) out_valid <= 1'b1;
end

endmodule