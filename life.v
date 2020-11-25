module cel (
  input tl, tc, tr, cl, cr, bl, bc, br, // 隣接セルの生死
  input reset,  // 初期化時にON
  input init, // 初期化時にセットされる値
  input clock,
  output reg state  // 生死
);
  wire [3:0] count = tl + tc + tr + cl + cr + bl + bc + br;

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

`define STDIN 32'h8000_0000
`define WIDTH 20
`define HEIGHT 20
`define CELL_NUM (`WIDTH*`HEIGHT)
`define ESC 27
// `define TORUS

module main;
  reg clock;
  reg reset;
  reg [`CELL_NUM - 1 : 0] init;
  wire [`CELL_NUM - 1 : 0] states;

  genvar i, j;
  generate
    for (i = 0; i < `HEIGHT; i = i + 1) begin: cell_rows
      for (j = 0; j < `WIDTH; j = j + 1) begin: cell_cols
        localparam t = (i - 1 + `HEIGHT) % `HEIGHT;
        localparam b = (i + 1) % `HEIGHT;
        localparam l = (j - 1 + `WIDTH) % `WIDTH;
        localparam r = (j + 1) % `WIDTH;
        localparam is_t = t == `HEIGHT;
        localparam is_b = b == 0;
        localparam is_l = l == `WIDTH;
        localparam is_r = r == 0;
        cel c(
`ifdef TORUS
          .tl(states[t*`WIDTH + l]),
          .tc(states[t*`WIDTH + j]),
          .tr(states[t*`WIDTH + r]),
          .cl(states[i*`WIDTH + l]),
          .cr(states[i*`WIDTH + r]),
          .bl(states[b*`WIDTH + l]),
          .bc(states[b*`WIDTH + j]),
          .br(states[b*`WIDTH + r]),
`else
          .tl((is_t || is_l) ? 1'b0 : states[t*`WIDTH + l]),
          .tc((is_t        ) ? 1'b0 : states[t*`WIDTH + j]),
          .tr((is_t || is_r) ? 1'b0 : states[t*`WIDTH + r]),
          .cl((        is_l) ? 1'b0 : states[i*`WIDTH + l]),
          .cr((        is_r) ? 1'b0 : states[i*`WIDTH + r]),
          .bl((is_b || is_l) ? 1'b0 : states[b*`WIDTH + l]),
          .bc((is_b        ) ? 1'b0 : states[b*`WIDTH + j]),
          .br((is_b || is_r) ? 1'b0 : states[b*`WIDTH + r]),
`endif
          .reset(reset),
          .init(init[i*`WIDTH + j]),
          .clock(clock),
          .state(states[i*`WIDTH + j])
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
    for (idx = 0; idx < `CELL_NUM; idx = idx + 1) begin
      init[idx] <= $random & 1;
    end
    #5 clock <= 1;
    #5 clock <= 0; reset = 0;

    // 画面クリア
    $write("%c[49m", `ESC);
    $write("%c[2J", `ESC);

    forever begin
      #5
      $write("%c[H", `ESC); // カーソルを戻す
      for (row = 0; row < `HEIGHT; row = row + 1) begin
        for (col = 0; col < `WIDTH; col = col + 1) begin
          if (states[row*`WIDTH + col]) begin
            $write("%c[46m", `ESC);
          end else begin
            $write("%c[40m", `ESC);
          end
          $write("  %c[49m", `ESC);
        end
        $write("\n");
      end
      $fflush;
      clock <= 1;
      #5 clock <= 0;
    end
  end

endmodule