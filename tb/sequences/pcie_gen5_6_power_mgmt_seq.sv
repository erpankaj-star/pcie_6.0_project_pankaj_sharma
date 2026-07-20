`ifndef PCIE_GEN5_6_POWER_MGMT_SEQ_SV
  `define PCIE_GEN5_6_POWER_MGMT_SEQ_SV

  class pcie_gen5_6_power_mgmt_seq extends pcie_gen5_6_base_seq;
    `uvm_object_utils(pcie_gen5_6_power_mgmt_seq)

    function new(string name = "pcie_gen5_6_power_mgmt_seq");
      super.new(name);
    endfunction

virtual task body();
  super.pre_body();
  send_pipe_symbol(PIPE_SYM_EIOS, 0, 32'hE105_E105);
  send_pipe_symbol(PIPE_SYM_FTS, 0, 32'hF75F_F75F);
endtask

  endclass : pcie_gen5_6_power_mgmt_seq

  `endif

