//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2023-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

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
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]                 bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// axi read data channel
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;

parameter signed BASED_ADDRESS = 16'h1000 ;

parameter IDLE                = 3'd0 ;
parameter FETCH_INSTRUCTION   = 3'd1 ; 
parameter DECODE_INSTRUCTION  = 3'd2 ;
parameter EXECUTE             = 3'd3 ;
parameter DATA_LOAD           = 3'd4 ;
parameter DATA_STORE          = 3'd5 ;
parameter WRITE_BACK          = 3'd6 ;

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;

wire [15:0] instruction_w , data_w;
wire [2:0] opcode;
wire [3:0] rs, rt, rd;
wire func;
wire signed [4:0] immediate;
wire [15:0] address;
wire signed [15:0] data_address;

reg signed [15:0] current_pc, next_pc;
reg signed [15:0] rs_data_r, rt_data_r, rd_data_r;
reg signed [15:0] rd_data_w;

reg [2:0] current_state, next_state;

wire fetch_instruction_finish;
wire fetch_data_finish;
wire write_data_finish;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) current_state <= IDLE ;
  else        current_state <= next_state ;
end

always @(*) begin
  case(current_state)
    FETCH_INSTRUCTION: begin
      if (fetch_instruction_finish) next_state = DECODE_INSTRUCTION ;
      else next_state = current_state ;
    end
    DECODE_INSTRUCTION: begin
      if(opcode == 3'b100)          next_state = FETCH_INSTRUCTION ;
      else if(opcode == 3'b010)     next_state = DATA_STORE;
      else if(opcode == 3'b011)     next_state = DATA_LOAD ;
      else                          next_state = EXECUTE ;
    end
    EXECUTE: begin
      if(opcode != 3'b001)          next_state = FETCH_INSTRUCTION ;
      else                          next_state = WRITE_BACK ;
    end
    DATA_LOAD: begin
      if (fetch_data_finish)        next_state = FETCH_INSTRUCTION ;
      else next_state = current_state ;
    end
    DATA_STORE: begin
      if (write_data_finish)        next_state = FETCH_INSTRUCTION ;
      else next_state = current_state ;
    end
    default:                        next_state = FETCH_INSTRUCTION ;
    endcase
end

// set instruction wire when after fetch instruction
assign opcode     = instruction_w[15:13] ;
assign rs         = instruction_w[12:9] ;
assign rt         = instruction_w[8:5] ;
assign rd         = instruction_w[4:1] ;
assign func       = instruction_w[0] ;
assign immediate  = {rd , func} ;
assign address    = { 3'b000 , instruction_w[12:0] } ;

// set rs data reg & wire
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)     rs_data_r <= 0 ;
  else begin
    if (next_state == DECODE_INSTRUCTION) begin
      case(rs)
        0:        rs_data_r <= core_r0  ;
        1:        rs_data_r <= core_r1  ;
        2:        rs_data_r <= core_r2  ;
        3:        rs_data_r <= core_r3  ;
        4:        rs_data_r <= core_r4  ;
        5:        rs_data_r <= core_r5  ;
        6:        rs_data_r <= core_r6  ;
        7:        rs_data_r <= core_r7  ;
        8:        rs_data_r <= core_r8  ;
        9:        rs_data_r <= core_r9  ;
        10:       rs_data_r <= core_r10 ; 
        11:       rs_data_r <= core_r11 ; 
        12:       rs_data_r <= core_r12 ; 
        13:       rs_data_r <= core_r13 ; 
        14:       rs_data_r <= core_r14 ; 
        default:  rs_data_r <= core_r15 ; 
      endcase
    end         
  end
end

// set rt data reg
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)     rt_data_r <= 0 ;
  else begin
    if (next_state == DECODE_INSTRUCTION) begin
      case(rt)
        0:        rt_data_r <= core_r0  ;
        1:        rt_data_r <= core_r1  ;
        2:        rt_data_r <= core_r2  ;
        3:        rt_data_r <= core_r3  ;
        4:        rt_data_r <= core_r4  ;
        5:        rt_data_r <= core_r5  ;
        6:        rt_data_r <= core_r6  ;
        7:        rt_data_r <= core_r7  ;
        8:        rt_data_r <= core_r8  ;
        9:        rt_data_r <= core_r9  ;
        10:       rt_data_r <= core_r10 ; 
        11:       rt_data_r <= core_r11 ; 
        12:       rt_data_r <= core_r12 ; 
        13:       rt_data_r <= core_r13 ; 
        14:       rt_data_r <= core_r14 ; 
        default:  rt_data_r <= core_r15 ; 
      endcase
    end         
  end
end

// set rd data reg
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)       rd_data_r <= 0 ;
  else if (next_state == EXECUTE) begin
    if (opcode == 3'b000) begin
      if (!func)  rd_data_r <= rs_data_r - rt_data_r ;  
      else        rd_data_r <= rs_data_r + rt_data_r ;  
    end
    else if (opcode == 3'b001) begin
      if (!func)  rd_data_r <= rs_data_r * rt_data_r ; 
      else        rd_data_r <= rs_data_r < rt_data_r ;
    end
    else          rd_data_r <= 0 ;
  end
end

// set core reg
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r0 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 0) core_r0 <= rd_data_r ;
    else if ( fetch_data_finish && rt == 0)   core_r0 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r1 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 1)  core_r1 <= rd_data_r ;
    else if (fetch_data_finish && rt == 1)   core_r1 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r2 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 2)  core_r2 <= rd_data_r ;
    else if (fetch_data_finish && rt == 2) core_r2 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r3 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 3)  core_r3 <= rd_data_r ;
    else if (fetch_data_finish && rt == 3) core_r3 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r4 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 4)  core_r4 <= rd_data_r ;
    else if (fetch_data_finish && rt == 4)   core_r4 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r5 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 5)  core_r5 <= rd_data_r ;
    else if (fetch_data_finish && rt == 5) core_r5 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r6 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 6)  core_r6 <= rd_data_r ;
    else if (fetch_data_finish && rt == 6) core_r6 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r7 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 7)  core_r7 <= rd_data_r ;
    else if (fetch_data_finish && rt == 7) core_r7 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r8 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 8)  core_r8 <= rd_data_r ;
    else if (fetch_data_finish && rt == 8) core_r8 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r9 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 9)  core_r9 <= rd_data_r ;
    else if (fetch_data_finish && rt == 9) core_r9 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r10 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 10)  core_r10 <= rd_data_r ;
    else if (fetch_data_finish && rt == 10)  core_r10 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r11 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 11)  core_r11 <= rd_data_r ;
    else if (fetch_data_finish && rt == 11)  core_r11 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r12 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 12)  core_r12 <= rd_data_r ;
    else if (fetch_data_finish && rt == 12)  core_r12 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r13 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 13)  core_r13 <= rd_data_r ;
    else if (fetch_data_finish && rt == 13)  core_r13 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r14 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 14)  core_r14 <= rd_data_r ;
    else if (fetch_data_finish && rt == 14)  core_r14 <= data_w ;
  end
end
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) core_r15 <= 0 ;
  else begin
    if (next_state == WRITE_BACK | (current_state == EXECUTE && !opcode[0]) && rd == 15)  core_r15 <= rd_data_r ;
    else if (fetch_data_finish && rt == 15)  core_r15 <= data_w ;
  end
end

// set program counter
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) current_pc <= BASED_ADDRESS ;
  else if (next_state == EXECUTE || (current_state == DECODE_INSTRUCTION && opcode[1]))  current_pc <= next_pc ;
  else if (current_state == DECODE_INSTRUCTION && opcode == 3'b100) current_pc <= address;
end

always @(*) begin
  if (opcode == 3'b100)         next_pc = address ;
  else if ( opcode == 3'b101) begin
    if (rs_data_r != rt_data_r) next_pc = current_pc + 2 ; 
    else                        next_pc = current_pc + (immediate +1) *2  ;
  end 
  else                          next_pc = current_pc + 2;
end

// set IO stall
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) IO_stall <= 1 ;
  else if (current_state != IDLE) IO_stall <= (next_state == FETCH_INSTRUCTION && current_state != FETCH_INSTRUCTION)? 0 : 1;
end

//  DRAM_instruction : Read Channel
reg read_instrunction_flag;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) read_instrunction_flag <= 0 ;
  else if (next_state == FETCH_INSTRUCTION && current_state != FETCH_INSTRUCTION)  read_instrunction_flag <= 1 ;
  else  read_instrunction_flag <= 0 ;
end

read_DRAM_instruction DRAM_1(
.clk(clk),
.rst_n(rst_n),

.in_valid(read_instrunction_flag),
.in_address(current_pc[11:1]),
.out_valid(fetch_instruction_finish),
.out_data(instruction_w),
                     
.arid_m_inf(arid_m_inf[7:4]),
.araddr_m_inf(araddr_m_inf[63:32]),
.arlen_m_inf(arlen_m_inf[13:7]),
.arsize_m_inf(arsize_m_inf[5:3]),
.arburst_m_inf(arburst_m_inf[3:2]),
.arvalid_m_inf(arvalid_m_inf[1]),
.arready_m_inf(arready_m_inf[1]), 
                 
.rdata_m_inf(rdata_m_inf[31:16]),
.rresp_m_inf(rresp_m_inf[3:2]),
.rlast_m_inf(rlast_m_inf[1]),
.rvalid_m_inf(rvalid_m_inf[1]),
.rready_m_inf(rready_m_inf[1]) 

);

//  DRAM_data : Read Channel
reg read_data_flag;
assign data_address = (rs_data_r+immediate)*2 + BASED_ADDRESS ;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) read_data_flag <= 0 ;
  else if ((next_state == DATA_LOAD && current_state != DATA_LOAD) || (next_state == DATA_STORE && current_state != DATA_STORE)) read_data_flag <= 1 ;
  else     read_data_flag <= 0 ;
end

wire write_sram_flag_w;
assign write_sram_flag_w = current_state == DATA_STORE;

read_DRAM_data DRAM_2( 
.clk(clk),
.rst_n(rst_n),

.in_valid(read_data_flag),
.in_address(data_address[11:1]),
.write_sram_flag(write_sram_flag_w),
.write_sram_data(rt_data_r),
.out_valid(fetch_data_finish),
.out_data(data_w),
                    
.arid_m_inf(arid_m_inf[3:0]),
.araddr_m_inf(araddr_m_inf[31:0]),
.arlen_m_inf(arlen_m_inf[6:0]),
.arsize_m_inf(arsize_m_inf[2:0]),
.arburst_m_inf(arburst_m_inf[1:0]),
.arvalid_m_inf(arvalid_m_inf[0]),
.arready_m_inf(arready_m_inf[0]), 
                   
.rid_m_inf(rid_m_inf[3:0]),
.rdata_m_inf(rdata_m_inf[15:0]),
.rresp_m_inf(rresp_m_inf[1:0]),
.rlast_m_inf(rlast_m_inf[0]),
.rvalid_m_inf(rvalid_m_inf[0]),
.rready_m_inf(rready_m_inf[0]) 

);

//  DRAM_data : Write Channel
reg write_data_flag;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n) write_data_flag <= 0 ;
  else if (next_state == DATA_STORE && current_state != DATA_STORE)  write_data_flag <= 1 ;
  else      write_data_flag <= 0 ;
end

write_DRAM_data DRAM_3(
.clk(clk),
.rst_n(rst_n),
 
.in_valid(write_data_flag),
.in_address(data_address[11:1]),
.write_sram_data(rt_data_r),
.out_valid(write_data_finish),

.awid_m_inf(awid_m_inf),
.awaddr_m_inf(awaddr_m_inf),
.awsize_m_inf(awsize_m_inf),
.awburst_m_inf(awburst_m_inf),
.awlen_m_inf(awlen_m_inf),
.awvalid_m_inf(awvalid_m_inf),
.awready_m_inf(awready_m_inf),
                    
.wdata_m_inf(wdata_m_inf),
.wlast_m_inf(wlast_m_inf),
.wvalid_m_inf(wvalid_m_inf),
.wready_m_inf(wready_m_inf),

.bid_m_inf(bid_m_inf),
.bresp_m_inf(bresp_m_inf),
.bvalid_m_inf(bvalid_m_inf),
.bready_m_inf(bready_m_inf)
);

endmodule

//   SUBMODULE

module read_DRAM_instruction(
clk,
rst_n,

in_valid,
in_address,
out_valid,
out_data,
                   
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
input  wire clk, rst_n;
input  in_valid;
input  [10:0] in_address;
output reg out_valid;
output reg [15:0] out_data;

// axi read address channel 
output  wire [3:0]                arid_m_inf;
output  wire [31:0]             araddr_m_inf;
output  wire [6:0]               arlen_m_inf;
output  wire [2:0]              arsize_m_inf;
output  wire [1:0]             arburst_m_inf;
output  reg                    arvalid_m_inf;
input   wire                   arready_m_inf;

// axi read data channel
input   wire [3:0]                  rid_m_inf;
input   wire [15:0]               rdata_m_inf;
input   wire [1:0]                rresp_m_inf;
input   wire                      rlast_m_inf;
input   wire                     rvalid_m_inf;
output  wire                     rready_m_inf;

//  FSM
parameter IDLE              = 3'd0 ;
parameter HIT_SRAM          = 3'd1 ;
parameter READ_SRAM         = 3'd2 ;
parameter READ_DRAM         = 3'd3 ;
parameter WAIT_DRAM_FINISH  = 3'd4 ;
parameter OUT               = 3'd5 ;

reg sram_not_empty;
reg  [2:0] current_state, next_state;
reg [3:0] tag;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    sram_not_empty <= 0 ;
    tag <= 0 ;
  end
  else if (current_state == READ_DRAM)  begin
    sram_not_empty <= 1 ;
    tag <= in_address[10:7] ;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) current_state <= IDLE ;
  else        current_state <= next_state ;
end

always @(*) begin
  case(current_state)
    IDLE : begin
      if (in_valid) begin
        if (sram_not_empty && tag == in_address[10:7])  next_state = HIT_SRAM ;
        else next_state = READ_DRAM ;
      end
      else next_state = current_state ;
    end
    HIT_SRAM:  next_state = READ_SRAM ;
    READ_SRAM:  next_state = OUT ;
    READ_DRAM: begin
      if(arready_m_inf)   next_state = WAIT_DRAM_FINISH ;
      else next_state = current_state ;
    end
    WAIT_DRAM_FINISH: begin
      if(rlast_m_inf)     next_state = OUT ;
      else next_state = current_state ;
    end
    default:  next_state = IDLE  ;
    endcase
end

assign arid_m_inf = 0 ;
assign araddr_m_inf =  !rst_n ? 0 : { 16'd0 , 4'b001 , in_address[10:7] , 8'd0 } ;
assign arlen_m_inf = 7'b111_1111 ;
assign arsize_m_inf = 3'b001 ;
assign arburst_m_inf = 2'b01 ;
assign rready_m_inf = current_state == WAIT_DRAM_FINISH;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)                     arvalid_m_inf <= 0 ;
  else if (next_state == READ_DRAM)  arvalid_m_inf <= 1 ;
  else                          arvalid_m_inf <= 0 ;
end

reg [6:0] sram_mem_index;
wire [15:0] mem_out_w;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)     sram_mem_index <= 0 ;
  else if (next_state == HIT_SRAM)     sram_mem_index <= in_address[6:0] ;
  else if (rvalid_m_inf)          sram_mem_index <= sram_mem_index + 1 ;
  else if (next_state == IDLE)    sram_mem_index <= 0 ;
end


sram SRAM_inst( .A(sram_mem_index), .D(rdata_m_inf), .CLK(clk), .CEN(1'b0), .WEN(current_state != WAIT_DRAM_FINISH) , .OEN(1'b0) , .Q(mem_out_w));

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)     out_data <= 0 ;
  else if (current_state == READ_SRAM) begin
    out_data <= mem_out_w ;
  end
  else if (current_state == WAIT_DRAM_FINISH) begin
    if (rvalid_m_inf  && sram_mem_index == in_address[6:0]) begin
      out_data <= rdata_m_inf ;
    end
  end 
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)               out_valid <= 0 ;
  else if (next_state != OUT)  out_valid <= 0 ;
  else                    out_valid <= 1 ;
end

endmodule

module read_DRAM_data(
clk,
rst_n,

in_valid,
write_sram_flag,
write_sram_data,
in_address,
out_valid,
out_data,

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
input  wire clk, rst_n;
input  in_valid;
input  write_sram_flag;
input  [10:0] in_address;
input  [15:0] write_sram_data;
output reg out_valid;
output reg [15:0] out_data;

// axi read address channel 
output  wire [3:0]                arid_m_inf;
output  wire [31:0]             araddr_m_inf;
output  wire [6:0]               arlen_m_inf;
output  wire [2:0]              arsize_m_inf;
output  wire [1:0]             arburst_m_inf;
output  reg                    arvalid_m_inf;
input   wire                   arready_m_inf;

// axi read data channel
input   wire [3:0]                  rid_m_inf;
input   wire [15:0]               rdata_m_inf;
input   wire [1:0]                rresp_m_inf;
input   wire                      rlast_m_inf;
input   wire                     rvalid_m_inf;
output  wire                     rready_m_inf;


//  FSM
parameter IDLE              = 3'd0 ;
parameter HIT_SRAM          = 3'd1 ;
parameter READ_SRAM         = 3'd2 ;
parameter WRITE_SARM        = 3'd3 ;
parameter READ_DRAM         = 3'd4 ;
parameter WAIT_DRAM_FINISH  = 3'd5 ;
parameter OUT               = 3'd6 ;

reg sram_not_empty;
reg  [2:0] current_state, next_state;
reg [3:0] tag;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    sram_not_empty <= 0 ;
    tag <= 0 ;
  end
  else if (current_state == READ_DRAM)  begin
    sram_not_empty <= 1 ;
    tag <= in_address[10:7] ;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) current_state <= IDLE ;
  else        current_state <= next_state ;
end

always @(*) begin
  case(current_state)
    IDLE : begin
      if (in_valid) begin
        if (write_sram_flag && tag == in_address[10:7])
          next_state = WRITE_SARM ;
        else if (sram_not_empty && tag == in_address[10:7])  
          next_state = HIT_SRAM ;
        else if (write_sram_flag != 1)
            next_state = READ_DRAM ;
        else next_state = current_state ;
      end
      else next_state = current_state ;
    end
    HIT_SRAM:   next_state = READ_SRAM ;
    READ_SRAM:  next_state = OUT ;
    READ_DRAM: begin
      if (arready_m_inf) next_state = WAIT_DRAM_FINISH ;
      else next_state = current_state ;
    end
    WAIT_DRAM_FINISH: begin
      if (rlast_m_inf)  next_state = OUT ;
      else next_state = current_state ;
    end
    default:  next_state = IDLE  ;
    endcase
end

assign arid_m_inf = 0 ;
assign araddr_m_inf =  !rst_n ? 0 : { 16'd0 , 4'b001 , in_address[10:7] , 8'd0 } ;
assign arlen_m_inf = 7'b111_1111 ;
assign arsize_m_inf = 3'b001 ;
assign arburst_m_inf = 2'b01 ;
assign rready_m_inf = (current_state == WAIT_DRAM_FINISH);

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) arvalid_m_inf <= 0 ;
  else if (next_state == READ_DRAM)  arvalid_m_inf <= 1 ;
  else  arvalid_m_inf <= 0 ;
end


reg [6:0] sram_mem_index;
wire [15:0] mem_in_w , mem_out_w;
wire wen_w;
assign mem_in_w = (current_state == WRITE_SARM) ? write_sram_data : rdata_m_inf ;
assign wen_w = (current_state != WAIT_DRAM_FINISH && current_state != WRITE_SARM);
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)     sram_mem_index <= 0 ;
  else if (next_state == HIT_SRAM || next_state == WRITE_SARM) sram_mem_index <= in_address[6:0] ;
  else if (rvalid_m_inf)                                  sram_mem_index <= sram_mem_index + 1 ;
  else if (next_state == IDLE)                            sram_mem_index <= 0 ;
end

sram SRAM_data( .A(sram_mem_index), .D(mem_in_w),  .CLK(clk), .CEN(1'b0), .WEN(wen_w),  .OEN(1'b0) ,.Q(mem_out_w) );

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)     out_data <= 0 ;
  else if (current_state == WAIT_DRAM_FINISH) begin
    if (rvalid_m_inf  && sram_mem_index == in_address[6:0]) begin
      out_data <= rdata_m_inf ;
    end
    end
  else if (current_state == READ_SRAM) begin
    out_data <= mem_out_w ;
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)               out_valid <= 0 ;
  else if (next_state != OUT)  out_valid <= 0 ;
  else                    out_valid <= 1 ;
end

endmodule

module write_DRAM_data(
clk,
rst_n,

in_valid,
in_address,
write_sram_data,
out_valid,

awid_m_inf,
awaddr_m_inf,
awlen_m_inf,
awsize_m_inf,
awburst_m_inf,
awvalid_m_inf,
awready_m_inf,
                    
wdata_m_inf,
wlast_m_inf,
wvalid_m_inf,
wready_m_inf,

bid_m_inf,
bresp_m_inf,
bvalid_m_inf,
bready_m_inf
);

input  wire clk, rst_n;
input  in_valid;
input  [10:0] in_address;
input  [15:0] write_sram_data;
output reg out_valid;

// axi write address channel 
output  wire [3:0]                 awid_m_inf;
output  wire [31:0]              awaddr_m_inf;
output  wire [2:0]               awsize_m_inf;
output  wire [1:0]              awburst_m_inf;
output  wire [6:0]                awlen_m_inf;
output  reg                     awvalid_m_inf;
input   wire                    awready_m_inf;

// axi write data channel 
output  reg  [15:0]               wdata_m_inf;
output  reg                       wlast_m_inf;
output  reg                      wvalid_m_inf;
input   wire                     wready_m_inf;

// axi write response channel
input   wire [3:0]         bid_m_inf;
input   wire [1:0]                bresp_m_inf;
input   wire                     bvalid_m_inf;
output  wire                     bready_m_inf;

//  FSM
parameter IDLE  = 2'd0 ;
parameter SEND = 2'd1 ;
parameter WAIT_DRAM_FINISH = 2'd2 ;
parameter OUT  = 2'd3 ;

reg  [1:0] current_state, next_state;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) current_state <= IDLE ;
  else        current_state <= next_state ;
end

always @(*) begin
  case(current_state)
    IDLE :begin
      if(in_valid)        next_state = SEND ;
      else next_state = current_state ;
    end 
    SEND:begin
      if(awready_m_inf)   next_state = WAIT_DRAM_FINISH ;
      else next_state = current_state ;
    end
    WAIT_DRAM_FINISH: begin
      if(wready_m_inf && wlast_m_inf) next_state = OUT ;
      else next_state = current_state ;
    end
    default:  begin
      if  (bvalid_m_inf)  next_state = IDLE ;
      else next_state = current_state ;
    end
  endcase
end

assign awid_m_inf = 0 ;
assign awaddr_m_inf =  !rst_n ? 0 :{ 16'd0 , 4'b0001 , in_address , 1'b0 } ;
assign awlen_m_inf = 7'd0 ;
assign awsize_m_inf = 3'b001 ;
assign awburst_m_inf = 2'b01 ;
assign bready_m_inf = current_state == OUT;
always @(posedge clk or negedge rst_n) begin
  if (!rst_n)     awvalid_m_inf <= 0 ;
  else if (next_state != SEND) awvalid_m_inf <= 0 ;
  else                    awvalid_m_inf <= 1 ;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)         wdata_m_inf <= 0 ;
  else if (in_valid)  wdata_m_inf <= write_sram_data;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    wlast_m_inf <= 0 ;
    wvalid_m_inf <= 0 ;
  end
  else begin
    if (next_state == WAIT_DRAM_FINISH) begin
      wlast_m_inf <= 1 ;
      wvalid_m_inf <= 1 ;
    end
    else begin
      wlast_m_inf <= 0 ;
      wvalid_m_inf <= 0 ;
    end
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)     out_valid <= 0 ;
  else if (current_state == OUT && next_state == IDLE)     out_valid <= 1 ;
  else                                                out_valid <= 0 ;
end

endmodule