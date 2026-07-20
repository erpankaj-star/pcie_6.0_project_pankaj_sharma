`ifndef PCIE_GEN5_6_IDE_SEQ_SV
  `define PCIE_GEN5_6_IDE_SEQ_SV

  class pcie_gen5_6_ide_seq extends pcie_gen5_6_base_seq;
    `uvm_object_utils(pcie_gen5_6_ide_seq)

    function new(string name = "pcie_gen5_6_ide_seq");
      super.new(name);
    endfunction

virtual task body();
  super.pre_body();
  cfg.enable_ide = 1'b1;
  send_tlp(TLP_MSG, 64'h0, 10'h011);
  send_tlp(TLP_MEM_WR, 64'hB000_0000, 10'h012);
endtask

  endclass : pcie_gen5_6_ide_seq

  `endif

