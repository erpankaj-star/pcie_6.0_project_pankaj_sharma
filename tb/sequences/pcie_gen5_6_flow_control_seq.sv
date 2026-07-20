`ifndef PCIE_GEN5_6_FLOW_CONTROL_SEQ_SV
  `define PCIE_GEN5_6_FLOW_CONTROL_SEQ_SV

  class pcie_gen5_6_flow_control_seq extends pcie_gen5_6_base_seq;
    `uvm_object_utils(pcie_gen5_6_flow_control_seq)

    function new(string name = "pcie_gen5_6_flow_control_seq");
      super.new(name);
    endfunction

virtual task body();
  super.pre_body();
  send_dlp(DLP_INITFC1, 10'h0);
  send_dlp(DLP_INITFC2, 10'h0);
  repeat (8) send_dlp(cfg.enable_flit_mode ? DLP_OPT_UPDATEFC : DLP_UPDATEFC, $urandom_range(1, 1023));
endtask

  endclass : pcie_gen5_6_flow_control_seq

  `endif

