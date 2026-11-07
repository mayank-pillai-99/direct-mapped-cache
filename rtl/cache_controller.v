`timescale 1ns/1ps
// cache_controller.v
// Cache Controller FSM (4 states).
//
//  IDLE      : wait for a CPU request, latch address / data / read-write.
//  COMPARE   : look up the line (valid bit + tag compare).
//                read  hit  -> return data, go to IDLE
//                read  miss -> go to ALLOCATE (fetch block from memory)
//                write      -> update cache word if it is a hit, then
//                              go to WRITE_MEM (write-through)
//  ALLOCATE  : request the 16-byte block from main memory; when it arrives
//              write data + tag + valid bit, then go back to COMPARE
//              (the second compare is now guaranteed to hit).
//  WRITE_MEM : write the word to main memory, then finish (go to IDLE).
//
// Write policy: write-through, no-write-allocate (simple and no dirty bits).

module cache_controller (
    input  wire clk,
    input  wire rst,
    // from CPU / datapath
    input  wire cpu_req,        // new request (sampled in IDLE)
    input  wire req_we,         // latched: 1 = write, 0 = read
    input  wire hit,            // from tag comparator
    // from main memory
    input  wire mem_ready,
    // control outputs
    output reg  latch_req,      // load address/data registers
    output reg  cpu_ready,      // request finished
    output reg  mem_req,
    output reg  mem_we,
    output reg  refill_we,      // write block + tag + valid
    output reg  word_we,        // write one word (store hit)
    // statistics (one-cycle pulses, only on the FIRST compare of a request)
    output reg  stat_hit,
    output reg  stat_miss,
    output wire [1:0] state_out
);
    localparam IDLE      = 2'd0,
               COMPARE   = 2'd1,
               ALLOCATE  = 2'd2,
               WRITE_MEM = 2'd3;

    reg [1:0] state, next_state;
    reg       refilled;         // 1 = we are in COMPARE again after a refill

    assign state_out = state;

    // ---------------- state register ----------------
    always @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            refilled <= 1'b0;
        end else begin
            state <= next_state;
            if (state == ALLOCATE && mem_ready) refilled <= 1'b1;
            else if (state == IDLE)             refilled <= 1'b0;
        end
    end

    // ---------------- next state + outputs ----------------
    always @(*) begin
        // defaults
        next_state = state;
        latch_req  = 1'b0;
        cpu_ready  = 1'b0;
        mem_req    = 1'b0;
        mem_we     = 1'b0;
        refill_we  = 1'b0;
        word_we    = 1'b0;
        stat_hit   = 1'b0;
        stat_miss  = 1'b0;

        case (state)
            IDLE: begin
                if (cpu_req) begin
                    latch_req  = 1'b1;
                    next_state = COMPARE;
                end
            end

            COMPARE: begin
                stat_hit  = !refilled &&  hit;
                stat_miss = !refilled && !hit;
                if (req_we) begin
                    word_we    = hit;           // update cache only on hit
                    next_state = WRITE_MEM;     // always write memory
                end else if (hit) begin
                    cpu_ready  = 1'b1;          // read hit: data is ready
                    next_state = IDLE;
                end else begin
                    next_state = ALLOCATE;      // read miss
                end
            end

            ALLOCATE: begin
                mem_req = 1'b1;
                if (mem_ready) begin
                    refill_we  = 1'b1;
                    next_state = COMPARE;
                end
            end

            WRITE_MEM: begin
                mem_req = 1'b1;
                mem_we  = 1'b1;
                if (mem_ready) begin
                    cpu_ready  = 1'b1;
                    next_state = IDLE;
                end
            end
        endcase
    end
endmodule
