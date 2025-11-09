module fifo_async (
  input wr_clk, rd_clk, rst,
  input wr, rd,
  input [7:0] data_in,
  output reg [7:0] data_out,
  output empty, almost_empty, almost_full, full
);
  
  parameter DEPTH = 32;
  parameter ADDR_WIDTH = 5;
  
  reg [7:0] mem [0:DEPTH-1];

  // Binary and Gray-coded pointers
  reg [ADDR_WIDTH:0] wr_ptr_bin = 0, rd_ptr_bin = 0;
  reg [ADDR_WIDTH:0] wr_ptr_gray = 0, rd_ptr_gray = 0;
  reg [ADDR_WIDTH:0] wr_ptr_gray_sync1 = 0, wr_ptr_gray_sync2 = 0;
  reg [ADDR_WIDTH:0] rd_ptr_gray_sync1 = 0, rd_ptr_gray_sync2 = 0;

  // Write logic
  always @(posedge wr_clk or posedge rst) begin
    if (rst) begin
      wr_ptr_bin <= 0;
      wr_ptr_gray <= 0;
    end else if (wr && !full) begin
      mem[wr_ptr_bin[ADDR_WIDTH-1:0]] <= data_in;
      wr_ptr_bin <= wr_ptr_bin + 1;
      wr_ptr_gray <= (wr_ptr_bin + 1) ^ ((wr_ptr_bin + 1) >> 1); // Binary to Gray
    end
  end

  // Read logic
  always @(posedge rd_clk or posedge rst) begin
    if (rst) begin
      rd_ptr_bin <= 0;
      rd_ptr_gray <= 0;
      data_out <= 0;
    end else if (rd && !empty) begin
      data_out <= mem[rd_ptr_bin[ADDR_WIDTH-1:0]];
      rd_ptr_bin <= rd_ptr_bin + 1;
      rd_ptr_gray <= (rd_ptr_bin + 1) ^ ((rd_ptr_bin + 1) >> 1);
    end
  end

  // Synchronize pointers across clock domains
  always @(posedge wr_clk or posedge rst) begin
    if (rst) begin
      rd_ptr_gray_sync1 <= 0;
      rd_ptr_gray_sync2 <= 0;
    end else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
  end

  always @(posedge rd_clk or posedge rst) begin
    if (rst) begin
      wr_ptr_gray_sync1 <= 0;
      wr_ptr_gray_sync2 <= 0;
    end else begin
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
  end

  // Convert synchronized Gray code pointers to binary
  function [ADDR_WIDTH:0] gray_to_bin(input [ADDR_WIDTH:0] gray);
    integer i;
    begin
      gray_to_bin[ADDR_WIDTH] = gray[ADDR_WIDTH];
      for (i = ADDR_WIDTH-1; i >= 0; i = i - 1)
        gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
    end
  endfunction

  wire [ADDR_WIDTH:0] rd_ptr_bin_sync = gray_to_bin(rd_ptr_gray_sync2);
  wire [ADDR_WIDTH:0] wr_ptr_bin_sync = gray_to_bin(wr_ptr_gray_sync2);

  // Status flag logic
  assign full  = ((wr_ptr_gray[ADDR_WIDTH] != rd_ptr_gray_sync2[ADDR_WIDTH]) &&
                  (wr_ptr_gray[ADDR_WIDTH-1:0] == rd_ptr_gray_sync2[ADDR_WIDTH-1:0]));

  assign empty = (wr_ptr_gray_sync2 == rd_ptr_gray);

  wire [ADDR_WIDTH:0] wr_count = wr_ptr_bin - rd_ptr_bin_sync;
  wire [ADDR_WIDTH:0] rd_count = wr_ptr_bin_sync - rd_ptr_bin;

  assign almost_full  = (wr_count == (DEPTH - 1));
  assign almost_empty = (rd_count == 1);

endmodule
