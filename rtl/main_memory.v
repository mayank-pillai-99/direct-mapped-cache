`timescale 1ns/1ps
// main_memory.v
// Simple main-memory model with a fixed latency (simulation model).
//   - Size: 64 KB (16384 words). Higher address bits are ignored.
//   - Read : returns a whole 16-byte block (4 words) after LATENCY cycles.
//   - Write: writes one 32-bit word after LATENCY cycles.
//   - Initial contents: word at byte address A holds the value A,
//     so a read of 0x0000_0123 should return 0x0000_0120 (word aligned).
//     This makes every result easy to check by eye.

module main_memory #(
    parameter LATENCY = 10,         // cycles per memory access (miss penalty)
    parameter WORDS   = 16384       // 64 KB
)(
    input  wire         clk,
    input  wire         rst,
    input  wire         mem_req,
    input  wire         mem_we,
    input  wire [31:0]  mem_addr,
    input  wire [31:0]  mem_wdata,
    output reg  [127:0] mem_rdata,
    output reg          mem_ready
);
    reg [31:0] mem [0:WORDS-1];
    reg [15:0] count;

    integer i;
    initial begin
        for (i = 0; i < WORDS; i = i + 1)
            mem[i] = i * 4;
    end

    // word index of the first word of the block, and of the single word
    wire [13:0] block_base = {mem_addr[15:4], 2'b00};
    wire [13:0] word_idx   = mem_addr[15:2];

    always @(posedge clk) begin
        if (rst) begin
            count     <= 0;
            mem_ready <= 1'b0;
        end else begin
            mem_ready <= 1'b0;
            if (mem_req && !mem_ready) begin
                if (count == LATENCY - 1) begin
                    count     <= 0;
                    mem_ready <= 1'b1;
                    if (mem_we)
                        mem[word_idx] <= mem_wdata;
                    else
                        mem_rdata <= { mem[block_base + 3], mem[block_base + 2],
                                       mem[block_base + 1], mem[block_base    ] };
                end else begin
                    count <= count + 1;
                end
            end
        end
    end
endmodule
