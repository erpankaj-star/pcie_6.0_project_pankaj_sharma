`timescale 1ns/1ps

module tb_top;
  import uvm_pkg::*;
  import pcie_gen5_6_types_pkg::*;
  import pcie_gen5_6_pkg::*;

  logic core_clk;
  logic pipe_clk;
  logic reset_n;

  initial begin
    core_clk = 1'b0;
    forever #2 core_clk = ~core_clk;
  end

  initial begin
    pipe_clk = 1'b0;
    forever #1 pipe_clk = ~pipe_clk;
  end

  initial begin
    reset_n = 1'b0;
    repeat (10) @(posedge core_clk);
    reset_n = 1'b1;
  end


// initial begin
// $shm_open("waves.shm");
// $shm_probe("AC"); // "AC" probes all signals and hierarchy recursively
// end

  pcie_pipe_if #(.LANES(PCIE_MAX_LANES), .DATA_W(PCIE_PIPE_DATA_W)) pipe_if (
    .pclk(pipe_clk),
    .reset_n(reset_n)
  );

  pcie_tl_if tl_if (
    .clk(core_clk),
    .reset_n(reset_n)
  );

  pcie_dl_if dl_if (
    .clk(core_clk),
    .reset_n(reset_n)
  );

  pcie_gen5_6_dut_stub #(
    .DUT_MODE(PCIE_AGENT_RC),
    .MAX_SPEED(PCIE_GEN6_64P0),
    .MAX_WIDTH(PCIE_WIDTH_X16),
    .ENABLE_FLIT_MODE(1'b1)
  ) dut (
    .core_clk(core_clk),
    .reset_n(reset_n),
    .pipe(pipe_if),
    .tl(tl_if),
    .dl(dl_if)
  );

  pcie_gen5_6_pipe_assertions  u_pipe_assertions  (.pipe(pipe_if));
  pcie_gen5_6_tl_assertions    u_tl_assertions    (.tl(tl_if));
  pcie_gen5_6_dl_assertions    u_dl_assertions    (.dl(dl_if));
  pcie_gen5_6_ltssm_assertions u_ltssm_assertions (.pipe(pipe_if));

  initial begin
    uvm_config_db#(virtual pcie_pipe_if.phy_model)::set(null, "uvm_test_top.env.pipe_agent.driver", "pipe_vif", pipe_if);
    uvm_config_db#(virtual pcie_pipe_if.monitor)::set(null, "uvm_test_top.env.pipe_agent.monitor", "pipe_vif", pipe_if);
    uvm_config_db#(virtual pcie_tl_if.tb)::set(null, "uvm_test_top.env.tl_agent.driver", "tl_vif", tl_if);
    uvm_config_db#(virtual pcie_tl_if.monitor)::set(null, "uvm_test_top.env.tl_agent.monitor", "tl_vif", tl_if);
    uvm_config_db#(virtual pcie_dl_if.tb)::set(null, "uvm_test_top.env.dl_agent.driver", "dl_vif", dl_if);
    uvm_config_db#(virtual pcie_dl_if.monitor)::set(null, "uvm_test_top.env.dl_agent.monitor", "dl_vif", dl_if);
    run_test();
  end
endmodule : tb_top









































































