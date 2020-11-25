module cel (
  input [7:0] neighbours, // 隣接セルの生死
  input reset,  // 初期化時にON
  input init, // 初期化時にセットされる値
  input clock,
  output reg state  // 生死
);
  wire [3:0] count =
    neighbours[0] +
    neighbours[1] +
    neighbours[2] +
    neighbours[3] +
    neighbours[4] +
    neighbours[5] +
    neighbours[6] +
    neighbours[7];

  reg q;

  always @(posedge clock) begin
    if (reset) begin
      q <= init;
    end else begin
      q <= count == 3 || (count == 2 && state);
    end
  end
  always @(negedge clock) begin
    state <= q;
  end
endmodule

module main;
  parameter STDIN = 32'h8000_0000;
  parameter WIDTH = 16;
  parameter HEIGHT = 16;
  parameter CELL_NUM = WIDTH*HEIGHT;
  parameter ESC = 27;

  reg clock;
  reg reset;
  reg [CELL_NUM - 1 : 0] init;
  wire [CELL_NUM - 1 : 0] states;

  genvar i, j;
  generate
    for (i = 0; i < HEIGHT; i = i + 1) begin: cell_rows
      for (j = 0; j < WIDTH; j = j + 1) begin: cell_cols
        localparam t = (i - 1 + HEIGHT) % HEIGHT;
        localparam b = (i + 1) % HEIGHT;
        localparam l = (j - 1 + WIDTH) % WIDTH;
        localparam r = (j + 1) % WIDTH;
        cel c(
          .neighbours({
            states[t*WIDTH + l],
            states[t*WIDTH + j],
            states[t*WIDTH + r],
            states[i*WIDTH + l],
            states[i*WIDTH + r],
            states[b*WIDTH + l],
            states[b*WIDTH + j],
            states[b*WIDTH + r]
          }),
          .reset(reset),
          .init(init[i*WIDTH + j]),
          .clock(clock),
          .state(states[i*WIDTH + j])
        );
      end
    end
  endgenerate

  integer idx, dummy, row, col;
  initial begin;
    // $dumpfile("life.vcd");
    // $dumpvars(1, main);

    // 初期化
    clock <= 0;
    reset <= 1;
    for (idx = 0; idx < CELL_NUM; idx = idx + 1) begin
      init[idx] <= $random & 1;
    end
    #5 clock <= 1;
    #5 clock <= 0; reset = 0;
    forever begin
      // 入力待ち
      dummy = $fgetc(STDIN);
      if (dummy == -1) begin
        $display("aborted");
        $finish;
      end
      // 出力
      #1
      $write("%c[H%c[2J", ESC, ESC);
      for (row = 0; row < HEIGHT; row = row + 1) begin
        for (col = 0; col < WIDTH; col = col + 1) begin
          if (states[row*WIDTH + col]) begin
            $write("#");
          end else begin
            $write(".");
          end
        end
        $write("\n");
      end
      $fflush;
      // 更新
      #4 clock <= 1;
      #5 clock <= 0;
    end
  end

endmodule