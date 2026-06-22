/*
 * Copyright (c) 2026 Dan Mangum
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module uart_rx #(
    // clock CYCLES per bit transmitted
    // 25000000 / 9600 ~= 2604
    parameter CYCLES = 2604
) (
    input clk,
    input rst,
    input in,
    output reg notif,
    output reg [7:0] data
);

  // States
  localparam S_IDLE = 2'b00;
  localparam S_START_BIT = 2'b01;
  localparam S_DATA_BIT = 2'b10;
  localparam S_STOP_BIT = 2'b11;

  reg [1:0] state;

  reg meta_sync_in, sync_in;

  reg [$clog2(CYCLES)-1:0] clock_count;
  reg [2:0] bit_index;

  always @(posedge clk) begin
    // Guard against metastability issues on external signal.
    meta_sync_in <= in;
    sync_in <= meta_sync_in;

    if (rst) begin
      state        <= S_IDLE;
      notif        <= 1'b0;
      data         <= 8'b0;
      clock_count  <= 0;
      bit_index    <= 0;
      sync_in      <= 1'b1;
      meta_sync_in <= 1'b1;
    end else begin
      case (state)
        S_IDLE: begin
          notif <= 1'b0;
          if (sync_in == 1'b0) begin
            // Input pulled low, immediately transition to start bit.
            state <= S_START_BIT;
          end
        end
        S_START_BIT: begin
          // Align to midpoint of bit before transition.
          if (clock_count < (CYCLES - 1) / 2) begin
            clock_count <= clock_count + 1;
          end else begin
            clock_count <= 0;
            if (sync_in != 1'b0) begin
              // If input is not still low, transition back to idle.
              state <= S_IDLE;
            end else begin
              // Reached midpoint of start bit, transition to data bit.
              bit_index <= 0;
              state <= S_DATA_BIT;
            end
          end
        end
        S_DATA_BIT: begin
          data[bit_index] <= sync_in;
          if (clock_count < CYCLES - 1) begin
            clock_count <= clock_count + 1;
          end else begin
            clock_count <= 0;
            if (bit_index < 7) begin
              bit_index <= bit_index + 1;
            end else begin
              // Reached end of transmitted byte, transition to stop bit.
              bit_index <= 0;
              state <= S_STOP_BIT;
            end
          end
        end
        S_STOP_BIT: begin
          if (clock_count < CYCLES - 1) begin
            clock_count <= clock_count + 1;
          end else begin
            notif <= 1'b1;
            clock_count <= 0;
            state <= S_IDLE;
          end
        end
        default: state <= S_IDLE;
      endcase
    end
  end
endmodule
