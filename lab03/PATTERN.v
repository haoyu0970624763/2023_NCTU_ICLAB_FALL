`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif

`define TEST_NUM 1000

module PATTERN(
    // Output Signals
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    // Input Signals
    out_valid,
    out
);


/* Input for design */
output reg       clk, rst_n;
output reg       in_valid;
output reg [1:0] init;
output reg [1:0] in0, in1, in2, in3; 


/* Output for pattern */
input            out_valid;
input      [1:0] out; 

integer [1:0] map [0:3][0:63];


integer index;
integer position;

integer local_cycle;
integer total_cycles;
integer max_latency;
integer total_latency;
integer test = `TEST_NUM ; 

/* real is double precision floating point */
real CYCLE = `CYCLE_TIME;
always #(CYCLE/2.0) clk = ~clk;

integer k;
initial begin
    max_latency = 0;
    // spec3
    reset_task;

    for( k = 0 ; k < test ; k = k+1) begin
        set_map_task;
        in_valid = 1'b1;
        input_task;
        wait_ans_task;
        check_ans_task;
        check_out_task;
    end
    $finish;

end


task reset_task; begin 

    rst_n = 'b1;
    in_valid = 'b0;
    init = 'bx;
    in0 = 'bx;
    in1 = 'bx;
    in2 = 'bx;
    in3 = 'bx;

    total_latency = 0;
    // make the wire or reg assign to new value
    force clk = 0;
    #CYCLE; rst_n = 0;
    #CYCLE; rst_n = 1;
    if(out_valid !== 1'b0 || out !== 2'd0) begin
        $display("SPEC 3 IS FAIL!");
        $finish;
    end
    // make the wire or reg restore to original value
	#CYCLE; release clk;
end endtask

integer train_index0 , train_index1 , train_index2;
integer obstacle0 , obstacle1 , obstacle2 , obstacle3;
integer train_flag0 , train_flag1 , train_flag2 , train_flag3 ;
integer j ;
task set_map_task; begin 
    
    for( j = 0 ; j < 64 ; j=j+1) begin

        if(j % 8 == 0) begin
            train_index0 = $urandom_range(0,3);
            train_index1 = $urandom_range(0,3);
            train_index2 = $urandom_range(0,3);
            if(train_index0==0 || train_index1==0 || train_index2==0)  begin
                map[0][j] = 2'b11;
                train_flag0 = 1;
            end
            else begin
                map[0][j] = 2'b00;
                train_flag0 =0;
            end

            if(train_index0 == 1 || train_index1==1 || train_index2==1) begin
                map[1][j] = 2'b11;
                train_flag1 = 1;
            end
            else begin
                map[1][j] = 2'b00;
                train_flag1 = 0;
            end

            if(train_index0 == 2 || train_index1==2 || train_index2==2) begin
                map[2][j] = 2'b11;
                train_flag2  = 1;
            end
            else begin
                map[2][j] = 2'b00;
                train_flag2 = 0;
            end

            if(train_index0 == 3 || train_index1==3 || train_index2==3) begin
                map[3][j] = 2'b11;
                train_flag3 = 1;
            end
            else begin
                map[3][j] = 2'b00;
                train_flag3 = 0;
            end


            if(j==0) begin
                if(!train_flag0)begin
                    position = 0;
                end
                else if(!train_flag1) begin
                    position = 1;
                end
                else if(!train_flag2) begin
                    position = 2;
                end
                else begin
                    position = 3;
                end
            end
        end
        else if(j%8 == 1 || j%8 == 3) begin
            if(train_index0==0 || train_index1==0 || train_index2==0)  begin
                map[0][j] = 2'b11;
                map[0][j+2] = 2'b11;
            end
            else begin
                map[0][j] = 2'b00;
                map[0][j+2] = 2'b00;
            end

            if(train_index0 == 1 || train_index1==1 || train_index2==1) begin
                map[1][j] = 2'b11;
                map[1][j+2] = 2'b11;
            end
            else begin
                map[1][j] = 2'b00;
                map[1][j+2] = 2'b00;
            end

            if(train_index0 == 2 || train_index1==2 || train_index2==2) begin
                map[2][j] = 2'b11;
                map[2][j+2] = 2'b11;
            end
            else begin
                map[2][j] = 2'b00;
                map[2][j+2] = 2'b00;
            end

            if(train_index0 == 3 || train_index1==3 || train_index2==3) begin
                map[3][j] = 2'b11;
                map[3][j+2] = 2'b11;
            end
            else begin
                map[3][j] = 2'b00;
                map[3][j+2] = 2'b00;
            end
        end
        else if(j%2 == 0) begin
            obstacle0 = $urandom_range(0,2);
            obstacle1 = $urandom_range(0,2);
            obstacle2 = $urandom_range(0,2);
            obstacle3 = $urandom_range(0,2);
            if( j%8==2 &&(train_index0==0 || train_index1==0 || train_index2==0)) begin
                map[0][j] = 2'b11;
            end
            else if(obstacle0==0)begin
                map[0][j]=2'b00;
            end
            else if(obstacle0==1)begin
                map[0][j]=2'b01;
            end
            else begin 
                map[0][j]=2'b10;                   
            end

            if( j%8==2 &&(train_index0==1 || train_index1==1 || train_index2==1)) begin
                map[1][j] = 2'b11;
            end
            else if(obstacle1==0)begin
                map[1][j]=2'b00;
            end
            else if(obstacle1==1)begin
                map[1][j]=2'b01;
            end
            else begin
                map[1][j]=2'b10;                    
            end


            if( j%8==2 &&(train_index0==2 || train_index1==2 || train_index2==2)) begin
                map[2][j] = 2'b11;
            end
            else if(obstacle2==0)begin
                map[2][j]=2'b00;
            end
            else if(obstacle2==1)begin
                map[2][j]=2'b01;
            end
            else begin    
                map[2][j]=2'b10;                
            end

            if( j%8==2 &&(train_index0==3 || train_index1==3 || train_index2==3)) begin
                map[3][j] = 2'b11;
            end
            else if(obstacle3==0)begin
                map[3][j]=2'b00;
            end
            else if(obstacle3==1)begin
                map[3][j]=2'b01;
            end
            else begin     
                map[3][j]=2'b10;               
            end
        end
        else begin
            map[0][j]=2'b00;
            map[1][j]=2'b00;
            map[2][j]=2'b00;
            map[3][j]=2'b00;
        end
    end
    repeat(3) @(negedge clk);
end endtask


integer i;
task input_task; begin

    while(!in_valid) begin
        if(out_valid === 1'b0 && out !== 2'd0) begin
            $display("SPEC 4 IS FAIL!");
            $finish;
        end
        else begin
    	    if(out_valid === 1'b1) begin 
                check_ans_task;
    	    end    	
        end
    end

    for(i = 0; i < 64; i = i + 1)begin
        if(out_valid === 1'b0 && out !== 2'd0) begin
            $display("SPEC 4 IS FAIL!");
            $finish;
        end
        else begin
    	    if(out_valid === 1'b1) begin 
                $display("SPEC 5 IS FAIL!");
                $finish;
    	    end
            else begin
                if(i==0) begin
                    init = position;
                end
                else begin
                    init = 'bx;
                end
                in0 = map[0][i];
                in1 = map[1][i];
                in2 = map[2][i];
                in3 = map[3][i];
            end
        end
        @(negedge clk);
	end

    in_valid = 1'b0;
    in0 = 'bx;
    in1 = 'bx;
    in2 = 'bx;
    in3 = 'bx;
end endtask 



task wait_ans_task; begin

    local_cycle = 0;
    while(out_valid !== 1'b1 ) begin
        local_cycle = local_cycle +1;
        if( out !== 2'd0 ) begin
            $display("SPEC 4 IS FAIL!");
            $finish;
        end

        if(local_cycle >= 3000) begin
            $display("SPEC 6 IS FAIL!");
            $finish;
        end
        @(negedge clk);
    end

end
endtask


task check_ans_task; begin

    index = 0;
    for(i = index; i < 63; i = i + 1)begin
        if(out_valid === 1'b0 ) begin
            if(out !== 2'd0 ) begin
                $display("SPEC 4 IS FAIL!");
            end
            else begin
                $display("SPEC 7 IS FAIL!");
            end
            $finish;
        end
        else begin
            if(out=== 2'b01) begin
                position = position +1;
                if(position >= 4) begin
                    $display("SPEC 8-1 IS FAIL!");
                    $finish;
                end
                if(map[position][i+1]==2'b01) begin
                    $display("SPEC 8-2 IS FAIL!");
                    $finish;
                end                
                if(map[position][i+1]==2'b10) begin
                    $display("SPEC 8-3 IS FAIL!");
                    $finish;
                end
                if(map[position][i+1]==2'b11) begin
                    $display("SPEC 8-4 IS FAIL!");
                    $finish;
                end
            end
            else if(out=== 2'b10) begin
                position = position -1;
                if(position < 0) begin
                    $display("SPEC 8-1 IS FAIL!");
                    $finish;
                end
                if(map[position][i+1]==2'b01) begin
                    $display("SPEC 8-2 IS FAIL!");
                    $finish;
                end
                if(map[position][i+1]==2'b10) begin
                    $display("SPEC 8-3 IS FAIL!");
                    $finish;
                end
                if(map[position][i+1]==2'b11) begin
                    $display("SPEC 8-4 IS FAIL!");
                    $finish;
                end
            end
            else if(out === 2'b00) begin
                if(map[position][i+1]==2'b01) begin
                    $display("SPEC 8-2 IS FAIL!");
                    $finish;
                end
                if(map[position][i+1]==2'b11) begin
                    $display("SPEC 8-4 IS FAIL!");
                    $finish;
                end
            end
            else if(out === 2'b11)begin

                if(map[position][i+1]==2'b10) begin
                    $display("SPEC 8-3 IS FAIL!");
                    $finish;
                end
                if(map[position][i+1]==2'b11) begin
                    $display("SPEC 8-4 IS FAIL!");
                    $finish;
                end
                if(map[position][i]==2'b01) begin
                    $display("SPEC 8-5 IS FAIL!");
                    $finish;
                end
            end
        end
        @(negedge clk);
	end
end endtask 


task check_out_task; begin

    if( out_valid === 1'b1) begin
        $display("SPEC 7 IS FAIL!");
        $finish;
    end
    else begin
        if(out !== 2'd0) begin
            $display("SPEC 4 IS FAIL!");
            $finish;
        end
    end

end endtask 

endmodule
