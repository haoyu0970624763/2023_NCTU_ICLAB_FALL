//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : INV_IP.v
//   	Module Name : INV_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module INV_IP #(parameter IP_WIDTH = 6 ) (
    // Input signals
    IN_1, IN_2,
    // Output signals
    OUT_INV
);

// ===============================================================
// Declaration
// ===============================================================
input  [IP_WIDTH-1:0] IN_1, IN_2;
output [IP_WIDTH-1:0] OUT_INV;

parameter maximum =(IP_WIDTH == 7) ? 4'd8 : 4'd6;
wire [IP_WIDTH-1:0]         a_w [0:maximum+1][0:1];
wire [IP_WIDTH-1:0]         b_w [0:maximum+1][0:1];
wire [IP_WIDTH-1:0]         up_w [0:maximum];
wire [IP_WIDTH-1:0]         down_w [0:maximum];
wire [IP_WIDTH-1:0]         quotient_w [0:maximum] ;
wire [0:0]                  flag [0:maximum];
wire [0:0]                  zero_flag [0:maximum-1];
wire signed [IP_WIDTH-1:0]  out_w;

assign a_w[0][0] = 1'b1;
assign a_w[1][0] = 1'b1;
assign a_w[0][1] = (IN_1 < IN_2 ? IN_1 : IN_2);
assign a_w[1][1] = a_w[0][1];
assign b_w[0][0] = 1'b0;
assign b_w[0][1] = (IN_1 > IN_2 ? IN_1 : IN_2);
assign flag[0] = 1'b0;
assign quotient_w[0] = b_w[0][1] / a_w[0][1];

genvar i , j ;
genvar k , l ;
genvar m;

generate
    for(i = 2 ; i <= maximum ; i=i+2) begin: loop_i
        for(j = 0 ; j < 2 ; j=j+1) begin: loop_j
            assign a_w[i][j] = a_w[i-1][j] - quotient_w[i-1]* b_w[i-1][j];
            assign a_w[i+1][j] = a_w[i][j];
        end
    end

endgenerate

generate
    for(k = 1 ; k <= maximum ; k=k+2) begin: loop_k
        for(l = 0 ; l < 2 ; l=l+1) begin: loop_l
            assign b_w[k][l] = ((!flag[k-1]) ? b_w[k-1][l] - a_w[k-1][l] * quotient_w[k-1]: b_w[k-1][l]);
            assign b_w[k+1][l] = b_w[k][l];
        end
    end
endgenerate

generate
    for(m = 1 ; m <= maximum ; m=m+1) begin: loop_m
        assign flag[m] = ~flag[m-1];
        assign zero_flag[m-1] =  a_w[m][1] ? (b_w[m][1] ? 0:1) : 1 ;
        assign up_w[m] = (!flag[m] )? b_w[m][1] : a_w[m][1];
        assign down_w[m] = (!flag[m])? a_w[m][1] : b_w[m][1];
        if( m <= 1'd1) begin : block1
            assign quotient_w[m] =   (zero_flag[m-1]) ?  0 : (up_w[m] / down_w[m]);
        end
        else if(m <= 2'd3) begin : block1
            assign quotient_w[m] =   (zero_flag[m-1]) ?  0 : (up_w[m][IP_WIDTH-2:0] / down_w[m][IP_WIDTH-2:0]);
        end
        else if(m == 3'd4)begin : block1
            assign quotient_w[m] =   (zero_flag[m-1]) ?  0 : (up_w[m][IP_WIDTH-3:0] / down_w[m][IP_WIDTH-3:0]);
        end
        else if(m == 3'd5)begin : block1
            assign quotient_w[m] =   (zero_flag[m-1]) ?  0 : (up_w[m][IP_WIDTH-4:0] / down_w[m][IP_WIDTH-4:0]);
        end
        else if(m == 3'd6)begin : block1
            assign quotient_w[m] =   (zero_flag[m-1]) ?  0 : (up_w[m][IP_WIDTH-5:0] / down_w[m][IP_WIDTH-5:0]);
        end
        else begin : block1
            assign quotient_w[m] =   (zero_flag[m-1]) ?  0 : (up_w[m] / down_w[m]);
        end
    end
endgenerate

assign out_w    =  (!a_w[maximum][1]) ?  b_w[maximum][0] : a_w[maximum][0];
assign OUT_INV  =   out_w < 0 ? out_w +b_w[0][1] : out_w;

endmodule