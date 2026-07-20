`ifndef PCIE_GEN5_6_LINK_TRAINING_SEQ_SV
  `define PCIE_GEN5_6_LINK_TRAINING_SEQ_SV

  class pcie_gen5_6_link_training_seq extends pcie_gen5_6_base_seq;
    `uvm_object_utils(pcie_gen5_6_link_training_seq)

    function new(string name = "pcie_gen5_6_link_training_seq");
      super.new(name);
    endfunction

virtual task body();
  super.pre_body();
  repeat (8) send_pipe_symbol(PIPE_SYM_TS1, 0, 32'h5453_315F);
  repeat (8) send_pipe_symbol(PIPE_SYM_TS2, 0, 32'h5453_325F);
  if (cfg.max_speed >= PCIE_GEN3_8P0) begin
    send_pipe_symbol(PIPE_SYM_EIEOS, 0, 32'hE1E0_5E1E);
  end
  send_pipe_symbol(PIPE_SYM_SDS, 0, 32'h5D5D_5D5D);
endtask

  endclass : pcie_gen5_6_link_training_seq

  `endif

