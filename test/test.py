import cocotb
from cocotb.triggers import RisingEdge, Timer


@cocotb.test()
async def test_project(dut):

    dut._log.info("Start")

    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0

    await Timer(20, units="ns")
    dut.rst_n.value = 1

    # wait some clocks
    for _ in range(5):
        await RisingEdge(dut.clk)

    dut._log.info("ALU test complete")