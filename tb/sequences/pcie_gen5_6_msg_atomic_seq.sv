`ifndef PCIE_GEN5_6_MSG_ATOMIC_SEQ_SV
  `define PCIE_GEN5_6_MSG_ATOMIC_SEQ_SV

  class pcie_gen5_6_msg_atomic_seq extends pcie_gen5_6_base_seq;
    `uvm_object_utils(pcie_gen5_6_msg_atomic_seq)

    function new(string name = "pcie_gen5_6_msg_atomic_seq");
      super.new(name);
    endfunction

virtual task body();
  super.pre_body();
  send_tlp(TLP_MSG, 64'h0, 10'h101);
  send_tlp(TLP_ATOMIC_FETCHADD, 64'hC000_0000, 10'h102);
  send_tlp(TLP_DEFERRABLE_MEM_WR, 64'hC000_1000, 10'h103);
endtask

  endclass : pcie_gen5_6_msg_atomic_seq

  `endif

