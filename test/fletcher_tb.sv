`timescale 1ns/1ps

module fletcher_tb;
    //////////////////////////////////////////////////////////////////////////// 
    // DUT Instantiation
    //////////////////////////////////////////////////////////////////////////// 

    logic clock_i;
    logic reset_i;
    logic done_i;

    logic[15:0] data_i;
    logic [15:0] check_sum_o;
    logic [15:0] check_bytes_o;

    fletcher DUT(.*);
    defparam DUT.CHECKSUM_WIDTH = 16;

    //////////////////////////////////////////////////////////////////////////// 
    // Clock Generation (100-MHz)
    //////////////////////////////////////////////////////////////////////////// 

    always #5 clock_i = ~clock_i;

    //////////////////////////////////////////////////////////////////////////// 
    // Task Definitions
    //////////////////////////////////////////////////////////////////////////// 

    task reset_dut();
        begin
            // Reset all IO (except for clock)
            reset_i = 1;
            done_i = 0;
            data_i = 0;

            // Hold reset and then release
            repeat (15) @(posedge clock_i);
            @(posedge clock_i) reset_i = 0;
        end
    endtask

    task test(input integer data[], input integer check_sum, input integer check_bytes);
        begin
            $display("@@@@@@@@@@@@@@@@@@@@@@@@");
            reset_dut();

            for (int i = 0; i < $size(data); i++) begin
                @(posedge clock_i) begin
                    $display("Sending 0x%2h", data[i]);
                    data_i = data[i];

                    if (i == $size(data) - 1) begin
                        done_i = 1;
                    end
                end
            end
            
            @(posedge clock_i);

            @(posedge clock_i) begin
                $display("Check sum: 0x%4h", check_sum_o);
                $display("Check bytes: 0x%4h", check_bytes_o);
                
                assert(check_sum_o === check_sum) else
                    $fatal(1, "Incorrect check sum");

                assert(check_bytes_o === check_bytes) else
                    $fatal(1, "Incorrect check bytes");
            end
        end
    endtask

    initial begin
        clock_i = 0;
        
        // 0x0102
        test({8'h01, 8'h02}, 16'h0403, 16'hf804);

        // "abcde"
        test({8'h61, 8'h62, 8'h63, 8'h64, 8'h65}, 16'hc8f0, 16'h46c8);

        // "abcdef"
        test({8'h61, 8'h62, 8'h63, 8'h64, 8'h65, 8'h66}, 16'h2057, 16'h8820);
        
        // "abcdefgh"
        test({8'h61, 8'h62, 8'h63, 8'h64, 8'h65, 8'h66, 8'h67, 8'h68}, 16'h0627, 16'hd206);

        $display("@@@@@@@@@@@@@@@@@@@@@@@@\nPASSED");
        $finish;
    end
endmodule

