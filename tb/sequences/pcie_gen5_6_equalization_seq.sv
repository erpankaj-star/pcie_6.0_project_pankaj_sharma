`ifndef PCIE_GEN5_6_EQUALIZATION_SEQ_SV
  `define PCIE_GEN5_6_EQUALIZATION_SEQ_SV

  class pcie_gen5_6_equalization_seq extends pcie_gen5_6_base_seq;
    `uvm_object_utils(pcie_gen5_6_equalization_seq)

    function new(string name = "pcie_gen5_6_equalization_seq");
      super.new(name);
    endfunction

virtual task body();
  super.pre_body();
  repeat (4) send_pipe_symbol(PIPE_SYM_TS1, 0, 32'hE0A1_0000);
  repeat (4) send_pipe_symbol(PIPE_SYM_TS2, 0, 32'hE0A2_0000);
endtask

  endclass : pcie_gen5_6_equalization_seq

  `endif

