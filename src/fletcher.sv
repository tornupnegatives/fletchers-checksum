// Description: Parameterized implementation of Fletcher's checksum
//
// Operation: After asserting reset, place bytes on data_i on each rising edge
// of the clock. On the last byte in the stream, also assert done_i. On the
// next positive edge of the clock, the checksum and check bytes will appear on
// their respective output ports
//
// Author: Joseph Bellahcen <joeclb@icloud.com>
// Reference: https://en.wikipedia.org/wiki/Fletcher%27s_checksum

`timescale 1ns / 1ps

module fletcher #(
    parameter integer CHECKSUM_WIDTH = 32,
    parameter integer DATA_WIDTH = CHECKSUM_WIDTH / 2,
    parameter integer MODULO = $pow(2, DATA_WIDTH) - 1
) (
    // FPGA Interface
    input logic clock_i,
    input logic reset_i,

    // Module Input/Control
    input logic done_i,
    input logic [DATA_WIDTH-1:0] data_i,

    // Module Output
    output logic [CHECKSUM_WIDTH-1:0] check_sum_o,
    output logic [CHECKSUM_WIDTH-1:0] check_bytes_o
);

    ////////////////////////////////////////////////////////////////////////////
    // FSM Variables
    ////////////////////////////////////////////////////////////////////////////

    enum {
        RESET_S,
        CHECKSUM_S,
        CHECKBYTES_S
    }
        state, state_ns;

    logic [DATA_WIDTH-1:0] lower_sum, lower_sum_ns;
    logic [DATA_WIDTH-1:0] upper_sum, upper_sum_ns;

    ////////////////////////////////////////////////////////////////////////////
    // Combinational Logic
    ////////////////////////////////////////////////////////////////////////////

    wire [DATA_WIDTH-1:0] c0, c1;

    // The check bytes, which when appended to the original data will produce a
    // checksum of zero, can be computed combinatorially from the checksum
    assign c0 = MODULO - ((lower_sum + upper_sum) % MODULO);
    assign c1 = MODULO - ((lower_sum + c0) % MODULO);

    ////////////////////////////////////////////////////////////////////////////
    // FSM
    ////////////////////////////////////////////////////////////////////////////

    always_ff @(posedge clock_i) begin
        if (reset_i) begin
            state <= RESET_S;
            lower_sum <= 0;
            upper_sum <= 0;
        end else begin
            state <= state_ns;
            lower_sum <= lower_sum_ns;
            upper_sum <= upper_sum_ns;
        end
    end

    always_comb begin
        // FSM Defaults
        state_ns = state;
        lower_sum_ns = lower_sum;
        upper_sum_ns = upper_sum;

        case (state)

            // Asserting reset is the only way to re-start the checksum
            RESET_S: begin
                lower_sum_ns = 0;
                upper_sum_ns = 0;

                check_sum_o = 0;
                check_bytes_o = 0;

                state_ns = CHECKSUM_S;
            end

            CHECKSUM_S: begin
                lower_sum_ns = (lower_sum + data_i) % MODULO;
                upper_sum_ns = (upper_sum + lower_sum_ns) % MODULO;

                if (done_i === 1) begin
                    state_ns = CHECKBYTES_S;
                end
            end

            // De-asserting done will NOT reset the checksum
            CHECKBYTES_S: begin
                check_sum_o   = {upper_sum, lower_sum};
                check_bytes_o = {c0, c1};

                if (done_i === 0) begin
                    state_ns = CHECKSUM_S;
                end
            end
        endcase
    end
endmodule : fletcher

