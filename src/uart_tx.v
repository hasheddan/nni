/*
 * Copyright (c) 2026 Dan Mangum
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module uart_tx #(
    // clock CYCLES per bit transmitted
    // 25000000 / 9600 ~= 2604
    parameter CYCLES = 2604
) (
    input clk,
    input rst,
    input send,
    input [7:0] data,
    output reg notif,
    output reg out
);

  // States
  localparam S_IDLE = 2'b00;
  localparam S_START_BIT = 2'b01;
  localparam S_DATA_BIT = 2'b10;
  localparam S_STOP_BIT = 2'b11;

  reg [1:0] state;

  reg [$clog2(CYCLES)-1:0] clock_count;
  reg [2:0] bit_index;

  always @(posedge clk) begin
    if (rst) begin
      state       <= S_IDLE;
      out         <= 1'b1;
      notif       <= 1'b0;
      clock_count <= 0;
      bit_index   <= 0;
    end else begin
      case (state)
        S_IDLE: begin
          notif <= 1'b0;
          out   <= 1'b1;
          if (send == 1'b1) begin
            clock_count <= 0;
            state <= S_START_BIT;
          end
        end
        S_START_BIT: begin
          out <= 1'b0;
          if (clock_count < CYCLES - 1) begin
            clock_count <= clock_count + 1;
          end else begin
            clock_count <= 0;
            state <= S_DATA_BIT;
          end
        end
        S_DATA_BIT: begin
          out <= data[bit_index];
          if (clock_count < CYCLES - 1) begin
            clock_count <= clock_count + 1;
          end else begin
            clock_count <= 0;
            if (bit_index < 7) begin
              bit_index <= bit_index + 1;
            end else begin
              bit_index <= 0;
              state <= S_STOP_BIT;
            end
          end
        end
        S_STOP_BIT: begin
          out <= 1'b1;
          if (clock_count < CYCLES - 1) begin
            clock_count <= clock_count + 1;
          end else begin
            clock_count <= 0;
            notif <= 1'b1;
            state <= S_IDLE;
          end
        end
        default: state <= S_IDLE;
      endcase
    end
  end
endmodule
