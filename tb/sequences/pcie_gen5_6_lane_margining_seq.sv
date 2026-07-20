`ifndef PCIE_GEN5_6_LANE_MARGINING_SEQ_SV
  `define PCIE_GEN5_6_LANE_MARGINING_SEQ_SV

  class pcie_gen5_6_lane_margining_seq extends pcie_gen5_6_base_seq;
    `uvm_object_utils(pcie_gen5_6_lane_margining_seq)

    function new(string name = "pcie_gen5_6_lane_margining_seq");
      super.new(name);
    endfunction

virtual task body();
  super.pre_body();
  cfg.enable_lane_margining = 1'b1;
  for (int lane = 0; lane < cfg.active_lanes; lane++) begin
    send_pipe_symbol(PIPE_SYM_SKP, lane, 32'hCAFE_0000 | lane);
  end
endtask

  endclass : pcie_gen5_6_lane_margining_seq

  `endif

