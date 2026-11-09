// tb_cache.v
// Testbench for the direct-mapped cache.
//   1. Reads a memory-access trace file (one access per line):
//          R <hex address>
//          W <hex address> <hex data>
//   2. Sends every access to the cache and waits for cpu_ready.
//   3. Checks every read against a reference memory (self-checking).
//   4. Counts hits / misses / cycles and prints hit ratio, miss ratio, AMAT.
//
// Run options (plusargs):
//   +trace=traces/sequential.txt  +name=sequential
//   +csv=results/summary.csv (optional)  +vcd (optional: write waveform)
`timescale 1ns/1ps
`include "cache_params.vh"

module tb_cache;
    parameter MEM_LATENCY = 10;

    // ---------------- clock / reset ----------------
    reg clk = 0;
    always #5 clk = ~clk;           // 100 MHz, 10 ns period
    reg rst = 1;

    // ---------------- DUT signals ----------------
    reg                 cpu_req = 0, cpu_we = 0;
    reg  [31:0]         cpu_addr = 0, cpu_wdata = 0;
    wire [31:0]         cpu_rdata;
    wire                cpu_ready;
    wire                mem_req, mem_we, mem_ready;
    wire [31:0]         mem_addr, mem_wdata;
    wire [127:0]        mem_rdata;
    wire                stat_hit, stat_miss;
    wire [1:0]          state;

    cache_top dut (
        .clk(clk), .rst(rst),
        .cpu_req(cpu_req), .cpu_we(cpu_we), .cpu_addr(cpu_addr),
        .cpu_wdata(cpu_wdata), .cpu_rdata(cpu_rdata), .cpu_ready(cpu_ready),
        .mem_req(mem_req), .mem_we(mem_we), .mem_addr(mem_addr),
        .mem_wdata(mem_wdata), .mem_rdata(mem_rdata), .mem_ready(mem_ready),
        .stat_hit(stat_hit), .stat_miss(stat_miss), .state(state)
    );

    main_memory #(.LATENCY(MEM_LATENCY)) mem (
        .clk(clk), .rst(rst),
        .mem_req(mem_req), .mem_we(mem_we), .mem_addr(mem_addr),
        .mem_wdata(mem_wdata), .mem_rdata(mem_rdata), .mem_ready(mem_ready)
    );

    // ---------------- reference memory (golden model) ----------------
    reg [31:0] ref_mem [0:16383];
    integer k;
    initial for (k = 0; k < 16384; k = k + 1) ref_mem[k] = k * 4;

    // ---------------- statistics ----------------
    integer reads = 0, writes = 0;
    integer read_hits = 0, read_misses = 0, write_hits = 0, write_misses = 0;
    integer read_cycles = 0, read_hit_cycles = 0, read_miss_cycles = 0;
    integer total_cycles = 0, errors = 0;
    reg     this_hit;               // result of the current access

    always @(posedge clk) begin
        if (stat_hit)  this_hit <= 1'b1;
        if (stat_miss) this_hit <= 1'b0;
    end

    // ---------------- one access ----------------
    integer cycles;
    task do_access(input is_write, input [31:0] addr, input [31:0] wdata);
        begin
            // issue the request on a falling edge
            cpu_req   = 1;
            cpu_we    = is_write;
            cpu_addr  = addr;
            cpu_wdata = wdata;
            cycles    = 0;
            @(negedge clk); cycles = 1; cpu_req = 0;
            while (!cpu_ready) begin
                @(negedge clk); cycles = cycles + 1;
            end
            // cpu_ready is high now; data is valid
            if (!is_write && cpu_rdata !== ref_mem[addr[15:2]]) begin
                errors = errors + 1;
                $display("  ERROR: read %h got %h expected %h",
                         addr, cpu_rdata, ref_mem[addr[15:2]]);
            end
            @(negedge clk); cycles = cycles + 1;   // FSM returns to IDLE
        end
    endtask

    // ---------------- main ----------------
    reg [8*200:1] trace_file, name, csv_file;
    reg [8*8:1]   op;
    reg [31:0]    a, d;
    integer fd, logf, csv, rc, n;
    real hit_rate, miss_rate, amat_meas, amat_formula, hit_time, miss_pen;

    initial begin
        if (!$value$plusargs("trace=%s", trace_file)) trace_file = "traces/sequential.txt";
        if (!$value$plusargs("name=%s",  name))       name       = "sequential";
        if (!$value$plusargs("csv=%s",   csv_file))   csv_file   = "results/summary.csv";
        if ($test$plusargs("vcd")) begin
            $dumpfile("results/cache_wave.vcd");
            $dumpvars(0, tb_cache);
        end

        fd = $fopen(trace_file, "r");
        if (fd == 0) begin $display("Cannot open %0s", trace_file); $finish; end
        logf = $fopen($sformatf("results/%0s_log.txt", name), "w");
        $fdisplay(logf, "#    op  address   tag     index word  result  cycles  data");

        repeat (3) @(negedge clk);
        rst = 0;
        @(negedge clk);

        n = 0;
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%s %h", op, a);
            if (rc == 2) begin
                d = 0;
                if (op == "W") rc = $fscanf(fd, "%h", d);
                do_access(op == "W", a, d);
                n = n + 1;
                total_cycles = total_cycles + cycles;

                if (op == "W") begin
                    writes = writes + 1;
                    if (this_hit) write_hits = write_hits + 1;
                    else          write_misses = write_misses + 1;
                    ref_mem[a[15:2]] = d;
                end else begin
                    reads = reads + 1;
                    read_cycles = read_cycles + cycles;
                    if (this_hit) begin
                        read_hits = read_hits + 1;  read_hit_cycles = read_hit_cycles + cycles;
                    end else begin
                        read_misses = read_misses + 1; read_miss_cycles = read_miss_cycles + cycles;
                    end
                end
                $fdisplay(logf, "%-4d %0s   %h  %h  %2d    %0d     %s   %3d    %h",
                          n, op, a, a[31:10], a[9:4], a[3:2],
                          this_hit ? "HIT " : "MISS", cycles,
                          (op == "W") ? d : cpu_rdata);
            end
        end
        $fclose(fd);
        $fclose(logf);

        // ---------------- report ----------------
        hit_rate  = (reads > 0) ? 1.0 * read_hits   / reads : 0.0;
        miss_rate = (reads > 0) ? 1.0 * read_misses / reads : 0.0;
        hit_time  = (read_hits   > 0) ? 1.0 * read_hit_cycles  / read_hits   : 2.0;
        miss_pen  = (read_misses > 0) ? 1.0 * read_miss_cycles / read_misses - hit_time : 0.0;
        amat_meas    = (reads > 0) ? 1.0 * read_cycles / reads : 0.0;
        amat_formula = hit_time + miss_rate * miss_pen;

        $display("");
        $display("==================== %0s ====================", name);
        $display(" Memory latency      : %0d cycles", MEM_LATENCY);
        $display(" Accesses            : %0d  (reads %0d, writes %0d)", n, reads, writes);
        $display(" Read hits / misses  : %0d / %0d", read_hits, read_misses);
        $display(" Write hits / misses : %0d / %0d", write_hits, write_misses);
        $display(" Hit ratio           : %0.2f %%", hit_rate * 100.0);
        $display(" Miss ratio          : %0.2f %%", miss_rate * 100.0);
        $display(" Hit time            : %0.2f cycles", hit_time);
        $display(" Miss penalty        : %0.2f cycles", miss_pen);
        $display(" AMAT (formula)      : %0.2f + %0.4f x %0.2f = %0.3f cycles",
                 hit_time, miss_rate, miss_pen, amat_formula);
        $display(" AMAT (measured)     : %0.3f cycles", amat_meas);
        $display(" Total cycles        : %0d", total_cycles);
        $display(" Data check errors   : %0d  %s", errors, errors == 0 ? "(PASS)" : "(FAIL)");
        $display("==================================================");

        csv = $fopen($sformatf("%0s", csv_file), "a");
        $fdisplay(csv, "%0s,%0d,%0d,%0d,%0d,%0d,%0d,%0d,%0.4f,%0.4f,%0.2f,%0.2f,%0.3f,%0.3f,%0d,%0d",
                  name, MEM_LATENCY, n, reads, writes, read_hits, read_misses,
                  write_hits, hit_rate, miss_rate, hit_time, miss_pen,
                  amat_formula, amat_meas, total_cycles, errors);
        $fclose(csv);
        $finish;
    end
endmodule
