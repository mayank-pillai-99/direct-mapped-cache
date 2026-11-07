`timescale 1ns/1ps
// tag_comparator.v
// HIT = (line is valid) AND (stored tag == tag of the requested address)
`include "cache_params.vh"

module tag_comparator (
    input  wire [`TAG_W-1:0] stored_tag,   // tag read from Tag RAM
    input  wire [`TAG_W-1:0] addr_tag,     // tag of the CPU address
    input  wire              valid,        // valid bit read from Valid RAM
    output wire              hit
);
    assign hit = valid && (stored_tag == addr_tag);
endmodule
