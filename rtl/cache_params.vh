// cache_params.vh
// Shared cache parameters. Change them here and every module follows.
//
//   Cache size  = 1 KB  (1024 bytes)
//   Block size  = 16 B  (4 words of 32 bits)
//   Lines       = 1024 / 16 = 64
//   Address     = 32 bits
//
//   | 31 ........ 10 | 9 ..... 4 | 3 ... 0 |
//   |   TAG (22)     | INDEX (6) | OFFSET(4)|
//
//   OFFSET[3:2] selects one of the 4 words in a block.
//   OFFSET[1:0] is the byte inside a word (always 00 for word accesses).

`ifndef CACHE_PARAMS_VH
`define CACHE_PARAMS_VH

`define ADDR_W      32                      // address width
`define DATA_W      32                      // word width
`define OFFSET_W    4                       // log2(16 byte block)
`define INDEX_W     6                       // log2(64 lines)
`define TAG_W       (`ADDR_W - `INDEX_W - `OFFSET_W)   // 22
`define LINES       (1 << `INDEX_W)         // 64
`define WORDS_PER_BLOCK 4
`define BLOCK_W     (`DATA_W * `WORDS_PER_BLOCK)       // 128 bits

`endif
