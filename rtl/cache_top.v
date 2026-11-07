`timescale 1ns/1ps
// cache_top.v
// Direct-mapped cache: 1 KB, 16-byte blocks, 64 lines, 32-bit addresses.
// Connects: address decoder, tag/valid/data RAMs, tag comparator and the
// controller FSM. Main memory is outside this module (see main_memory.v).
//
//          CPU side                               Memory side
//   cpu_req/we/addr/wdata --> [request regs] --> mem_req/we/addr/wdata
//   cpu_rdata/ready       <-- [cache]        <-- mem_rdata/ready
`include "cache_params.vh"

module cache_top (
    input  wire                clk,
    input  wire                rst,
    // CPU interface
    input  wire                cpu_req,
    input  wire                cpu_we,
    input  wire [`ADDR_W-1:0]  cpu_addr,
    input  wire [`DATA_W-1:0]  cpu_wdata,
    output wire [`DATA_W-1:0]  cpu_rdata,
    output wire                cpu_ready,
    // Main-memory interface
    output wire                mem_req,
    output wire                mem_we,
    output wire [`ADDR_W-1:0]  mem_addr,
    output wire [`DATA_W-1:0]  mem_wdata,
    input  wire [`BLOCK_W-1:0] mem_rdata,
    input  wire                mem_ready,
    // statistics / debug
    output wire                stat_hit,
    output wire                stat_miss,
    output wire [1:0]          state
);
    // ---------- request registers (hold the request while FSM works) ----------
    reg [`ADDR_W-1:0] addr_r;
    reg [`DATA_W-1:0] wdata_r;
    reg               we_r;
    wire              latch_req;

    always @(posedge clk) begin
        if (rst) begin
            addr_r  <= 0;
            wdata_r <= 0;
            we_r    <= 1'b0;
        end else if (latch_req) begin
            addr_r  <= cpu_addr;
            wdata_r <= cpu_wdata;
            we_r    <= cpu_we;
        end
    end

    // ---------- address decoder ----------
    wire [`TAG_W-1:0]   tag;
    wire [`INDEX_W-1:0] index;
    wire [1:0]          word_sel;

    address_decoder u_dec (
        .addr(addr_r), .tag(tag), .index(index), .word_sel(word_sel)
    );

    // ---------- storage ----------
    wire               refill_we, word_we;
    wire               valid;
    wire [`TAG_W-1:0]  stored_tag;

    valid_ram u_valid (
        .clk(clk), .rst(rst), .index(index),
        .we(refill_we), .valid_out(valid)
    );

    tag_ram u_tag (
        .clk(clk), .index(index),
        .we(refill_we), .tag_in(tag), .tag_out(stored_tag)
    );

    data_ram u_data (
        .clk(clk), .index(index), .word_sel(word_sel),
        .block_we(refill_we), .block_in(mem_rdata),
        .word_we(word_we),    .word_in(wdata_r),
        .word_out(cpu_rdata)
    );

    // ---------- tag comparator ----------
    wire hit;
    tag_comparator u_cmp (
        .stored_tag(stored_tag), .addr_tag(tag), .valid(valid), .hit(hit)
    );

    // ---------- controller FSM ----------
    cache_controller u_ctrl (
        .clk(clk), .rst(rst),
        .cpu_req(cpu_req), .req_we(we_r), .hit(hit), .mem_ready(mem_ready),
        .latch_req(latch_req), .cpu_ready(cpu_ready),
        .mem_req(mem_req), .mem_we(mem_we),
        .refill_we(refill_we), .word_we(word_we),
        .stat_hit(stat_hit), .stat_miss(stat_miss), .state_out(state)
    );

    // ---------- memory interface ----------
    assign mem_addr  = addr_r;
    assign mem_wdata = wdata_r;
endmodule
