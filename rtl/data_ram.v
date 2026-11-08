`timescale 1ns/1ps
// data_ram.v
// Stores the data blocks: 64 lines x 128 bits (4 words per line).
//   - block_we : write a whole block (refill from main memory on a miss)
//   - word_we  : write a single word (write hit, write-through policy)
`include "cache_params.vh"

module data_ram (
    input  wire                clk,
    input  wire [`INDEX_W-1:0]  index,
    input  wire [1:0]          word_sel,
    // whole-block write (refill)
    input  wire                block_we,
    input  wire [`BLOCK_W-1:0] block_in,
    // single-word write (CPU store hit)
    input  wire                word_we,
    input  wire [`DATA_W-1:0]  word_in,
    // read port
    output wire [`DATA_W-1:0]  word_out
);
    reg [`BLOCK_W-1:0] lines [0:`LINES-1];

    always @(posedge clk) begin
        if (block_we)
            lines[index] <= block_in;
        else if (word_we)
            lines[index][word_sel*`DATA_W +: `DATA_W] <= word_in;
    end

    // asynchronous read, then pick one of the 4 words
    wire [`BLOCK_W-1:0] line = lines[index];
    assign word_out = line[word_sel*`DATA_W +: `DATA_W];
endmodule
