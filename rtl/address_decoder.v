`timescale 1ns/1ps
// address_decoder.v
// Splits a 32-bit byte address into TAG, INDEX and OFFSET fields.
// Pure wiring (combinational) - no logic gates are needed.
`include "cache_params.vh"

module address_decoder (
    input  wire [`ADDR_W-1:0]   addr,
    output wire [`TAG_W-1:0]    tag,        // addr[31:10]
    output wire [`INDEX_W-1:0]  index,      // addr[9:4]  -> which cache line
    output wire [1:0]           word_sel    // addr[3:2]  -> which word in the block
);
    assign tag      = addr[`ADDR_W-1 : `INDEX_W+`OFFSET_W];
    assign index    = addr[`INDEX_W+`OFFSET_W-1 : `OFFSET_W];
    assign word_sel = addr[3:2];
endmodule
