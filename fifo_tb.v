module tb_fifo_async;

  reg wr_clk, rd_clk, rst, wr, rd;
  reg [7:0] data_in;
  wire empty, almost_empty, almost_full, full;
  wire [7:0] data_out;

  fifo_async dut (
    .wr_clk(wr_clk), .rd_clk(rd_clk), .rst(rst),
    .wr(wr), .rd(rd),
    .data_in(data_in), .data_out(data_out),
    .empty(empty), .almost_empty(almost_empty),
    .almost_full(almost_full), .full(full)
  );

  // Clock generation (different frequencies)
  initial begin
    wr_clk = 0; forever #5 wr_clk = ~wr_clk;  // 10ns period
  end

  initial begin
    rd_clk = 0; forever #7 rd_clk = ~rd_clk;  // 14ns period (asynchronous)
  end

  initial begin
    rst = 1;
    wr = 0;
    rd = 0;
    data_in = 0;
    #20; rst = 0;

    $display("Starting Asynchronous FIFO Test...");

    // Write phase
    repeat (16) begin
      @(posedge wr_clk);
      if (!full) begin
        wr = 1;
        data_in = $random;
        $display("Write: %0d", data_in);
      end
      @(posedge wr_clk);
      wr = 0;
    end

    // Read phase
    repeat (16) begin
      @(posedge rd_clk);
      if (!empty) begin
        rd = 1;
      end
      @(posedge rd_clk);
      rd = 0;
      $display("Read: %0d", data_out);
    end

    #50;
    $display("Test Completed.");
    $finish;
  end
endmodule
