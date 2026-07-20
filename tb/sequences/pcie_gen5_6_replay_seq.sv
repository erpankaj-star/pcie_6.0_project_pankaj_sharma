`ifndef PCIE_GEN5_6_REPLAY_SEQ_SV
  `define PCIE_GEN5_6_REPLAY_SEQ_SV

  class pcie_gen5_6_replay_seq extends pcie_gen5_6_base_seq;
    `uvm_object_utils(pcie_gen5_6_replay_seq)

    function new(string name = "pcie_gen5_6_replay_seq");
      super.new(name);
    endfunction

virtual task body();
  super.pre_body();
  repeat (3) send_tlp(TLP_MEM_WR, 64'hA000_0000 + ($urandom_range(0, 63) << 2), $urandom_range(0, 1023));
  send_dlp(DLP_NAK, 10'h1);
  repeat (3) send_pipe_symbol(PIPE_SYM_FLIT, 0, 32'hF17A_FEED);
  send_dlp(DLP_ACK, 10'h3);
endtask

  endclass : pcie_gen5_6_replay_seq

  `endif

