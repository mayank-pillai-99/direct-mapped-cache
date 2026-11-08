`timescale 1ns/1ps
// valid_ram.v
// One valid bit per cache line (64 x 1 bit).
// All bits are cleared on reset, so the cache starts empty and the
// first access to every line is a compulsory (cold) miss.
`include "cache_params.vh"

module valid_ram (
    input  wire               clk,
    input  wire               rst,
    input  wire [`INDEX_W-1:0] index,
    input  wire               we,       // set the valid bit of line 'index'
    output wire               valid_out
);
    reg [`LINES-1:0] valid;

    always @(posedge clk) begin
        if (rst)
            valid <= {`LINES{1'b0}};
        else if (we)
            valid[index] <= 1'b1;
    end

    assign valid_out = valid[index];    // asynchronous read
endmodule