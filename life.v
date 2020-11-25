module life_cell (
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
        life_cell c(
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

  integer a, row, col;
  reg [80*8 - 1 : 0] filename;
  reg [80*8 - 1 : 0] fileerror;
  reg [7:0] c;
  integer fd;

  initial begin;
    // 初期化
    clock <= 0;
    reset <= 1;
    if ($value$plusargs("i=%s", filename)) begin
      // 引数に指定があればファイルから読む
      fd = $fopen(filename, "r");
      if ($ferror(fd, fileerror)) begin
        $display("%0s: %0s", fileerror, filename);
        $finish;
      end
      init = {`CELL_NUM{1'b0}};
      row = 0;
      col = 0;
      c = $fgetc(fd);
      while (c != 255) begin
        if (c == "#") begin
          init[row*`WIDTH + col] = 1'b1;
          col = col + 1;
        end else if (c == ".") begin
          col = col + 1;
        end else if (c == "\n") begin
          row = row + 1;
          col = 0;
        end else begin
          $display("invalid character: %d, %0d, %0d", c, row, col);
          $finish;
        end
        c = $fgetc(fd);
      end
    end else begin
      // 指定がなければランダム
      for (a = 0; a < `CELL_NUM; a = a + 1) begin
        init[a] = $random & 1;
      end
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