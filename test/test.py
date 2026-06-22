# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


# Toggle active low reset.
async def reset(dut):
    dut._log.info("Reset")
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 1)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)


# Send one byte over UART to the DUT.
async def rx_byte(dut, val):
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, dut.nni.urx.CYCLES.value)
    for i in range(8):
        dut.ui_in.value = (val >> i) & 1
        await ClockCycles(dut.clk, dut.nni.urx.CYCLES.value)
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, dut.nni.urx.CYCLES.value)


@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 40, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    await reset(dut)

    # Send bytes
    await rx_byte(dut, 68)
    await rx_byte(dut, 65)
    await rx_byte(dut, 78)
    await rx_byte(dut, 79)

    # Assert received
    assert dut.nni.raw[0].value.to_unsigned() == 68
    assert dut.nni.raw[1].value.to_unsigned() == 65
    assert dut.nni.raw[2].value.to_unsigned() == 78
    assert dut.nni.raw[3].value.to_unsigned() == 79

    # Give time to transmit
    await ClockCycles(dut.clk, dut.nni.utx.CYCLES.value.to_unsigned() * 10 * 24)
