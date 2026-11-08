`timescale 1ns/1ps
// tag_ram.v
// Stores the 22-bit tag of the block held in each of the 64 lines.
`include "cache_params.vh"

module tag_ram (
    input  wire               clk,
    input  wire [`INDEX_W-1:0] index,
    input  wire               we,
    input  wire [`TAG_W-1:0]  tag_in,
    output wire [`TAG_W-1:0]  tag_out
);
    reg [`TAG_W-1:0] tags [0:`LINES-1];

    always @(posedge clk) begin
        if (we)
            tags[index] <= tag_in;
    end

    assign tag_out = tags[index];       // asynchronous read
endmodule