/*
 * Copyright (c) 2026 Dan Mangum
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_hasheddan_nni (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Handle unused.
  assign uio_out = 8'b0;
  assign uio_oe = 8'b0;
  assign uo_out[7:1] = 7'b0;
  wire       _unused = &{ena, clk, rst_n, 1'b0};

  wire       rx_notif;
  wire [7:0] rx_data;

  uart_rx urx (
      .clk  (clk),
      .rst  (~rst_n),
      .in   (ui_in[0]),
      .notif(rx_notif),
      .data (rx_data)
  );

  wire       tx_notif;
  reg        tx_send;
  reg  [7:0] tx_data;

  uart_tx utx (
      .clk  (clk),
      .rst  (~rst_n),
      .send (tx_send),
      .data (tx_data),
      .notif(tx_notif),
      .out  (uo_out[0])
  );


  reg rx_notif_d;
  wire rx_sig = rx_notif & ~rx_notif_d;

  // Raw 8-bit pixel values (RGGB).
  reg [7:0] raw[4];
  reg [1:0] raw_idx;
  integer raw_rst_idx;

  reg [3:0] tx_idx;
  reg tx_busy;

  // States
  localparam S_IDLE = 2'd0;
  localparam S_RX = 2'd1;
  localparam S_TX = 2'd2;

  reg [1:0] state;

  always @(posedge clk) begin
    rx_notif_d <= rx_notif;

    if (!rst_n) begin
      state    <= S_IDLE;
      raw_idx   <= 0;
      tx_idx   <= 0;
      tx_send  <= 0;
      tx_busy  <= 0;
      tx_data  <= 0;
      rx_notif_d <= 0;

      for (raw_rst_idx = 0; raw_rst_idx < 4; raw_rst_idx = raw_rst_idx + 1) raw[raw_rst_idx] <= 0;

    end else begin
      tx_send <= 0;
      case (state)
        S_IDLE: begin
          // On first received byte signal, store and move to receiving state.
          if (rx_sig) begin
            raw[0]  <= rx_data;
            raw_idx <= 1;
            state   <= S_RX;
          end
        end
        S_RX: begin
          if (rx_sig) begin
            raw[raw_idx] <= rx_data;
            if (raw_idx == 2'd3) begin
              raw_idx <= 0;
              tx_idx  <= 0;
              state   <= S_TX;
            end else begin
              raw_idx <= raw_idx + 1;
            end
          end
        end
        S_TX: begin
          if (!tx_busy) begin
            case (tx_idx)
              // Send R (red) value.
              0, 3, 6, 9:  tx_data <= raw[0];
              // Send first G (green) value.
              1, 4:        tx_data <= raw[1];
              // Send B (blue) value.
              2, 5, 8, 11: tx_data <= raw[3];
              // Send second G (green) value.
              7, 10:       tx_data <= raw[2];
              default: begin
                // All data sent, go back to idle.
                state  <= S_IDLE;
                tx_idx <= 0;
              end
            endcase
            // If we aren't done, signal to send.
            if (state == S_TX) begin
              tx_send <= 1;
              tx_busy <= 1;
            end
          end
          // Mark as not busy on sent notification.
          if (tx_notif) begin
            tx_busy <= 0;
            tx_idx  <= tx_idx + 1;
          end
        end
        default: state <= S_IDLE;
      endcase
    end
  end

endmodule
