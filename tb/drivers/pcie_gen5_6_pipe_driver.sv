


`ifndef PCIE_GEN5_6_PIPE_DRIVER_SV
`define PCIE_GEN5_6_PIPE_DRIVER_SV

class pcie_gen5_6_pipe_driver extends uvm_driver #(pcie_pipe_symbol_item);
  `uvm_component_utils(pcie_gen5_6_pipe_driver)

  virtual pcie_pipe_if.phy_model vif;
  pcie_gen5_6_cfg cfg;

  function new(string name = "pcie_gen5_6_pipe_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pcie_pipe_if.phy_model)::get(this, "", "pipe_vif", vif)) begin
      `uvm_fatal(get_type_name(), "pipe_vif not set")
    end
    if (!uvm_config_db#(pcie_gen5_6_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = pcie_gen5_6_cfg::type_id::create("cfg");
    end
  endfunction

  task run_phase(uvm_phase phase);
    reset_pipe();
    forever begin
      seq_item_port.get_next_item(req);
      drive_symbol(req);
      seq_item_port.item_done();
    end
  endtask

  task reset_pipe();
    vif.cb_drv.rx_valid               <= '0;
    vif.cb_drv.rx_data                <= '0;
    vif.cb_drv.rx_datak               <= '0;
    vif.cb_drv.rx_start_block         <= '0;
    vif.cb_drv.rx_sync_header         <= '0;
    vif.cb_drv.rx_elec_idle           <= '1;
    vif.cb_drv.rx_status              <= '0;
    vif.cb_drv.rx_polarity_inverted   <= '0;
    vif.cb_drv.rx_block_align         <= '0;
    vif.cb_drv.rx_symbol_lock         <= '0;
    vif.cb_drv.rx_lane_aligned        <= '0;
    vif.cb_drv.rx_margin_status       <= '0;
    vif.cb_drv.pam4_symbol            <= '0;
    vif.cb_drv.phy_status             <= 1'b0;
    vif.cb_drv.rate_change_ack        <= 1'b0;
    vif.cb_drv.eq_phase_done          <= 1'b0;
    vif.cb_drv.lane_reversal_detected <= 1'b0;
    vif.cb_drv.deskew_done            <= 1'b0;
    vif.cb_drv.retimer_present        <= cfg.enable_retimer_hooks;
    vif.cb_drv.pipe_stall             <= 1'b0;
    repeat (5) @(vif.cb_drv);
  endtask

  task drive_symbol(pcie_pipe_symbol_item tr);
    @(vif.cb_drv);
    vif.cb_drv.rx_elec_idle[tr.lane_num]         <= tr.elec_idle;
    vif.cb_drv.rx_data[tr.lane_num]              <= tr.data;
    vif.cb_drv.rx_datak[tr.lane_num]             <= tr.datak;
    vif.cb_drv.rx_valid[tr.lane_num]             <= !tr.elec_idle;
    vif.cb_drv.rx_start_block[tr.lane_num]       <= tr.start_block;
    vif.cb_drv.rx_sync_header[tr.lane_num]       <= tr.sync_header;
    vif.cb_drv.rx_polarity_inverted[tr.lane_num] <= tr.polarity_inverted;
    vif.cb_drv.rx_symbol_lock[tr.lane_num]       <= 1'b1;
    vif.cb_drv.rx_block_align[tr.lane_num]       <= (tr.symbol_type inside {PIPE_SYM_SDS, PIPE_SYM_FLIT});
    vif.cb_drv.rx_lane_aligned[tr.lane_num]      <= tr.deskew_marker;
    vif.cb_drv.pam4_symbol[tr.lane_num]          <= tr.pam4_symbol;
    vif.cb_drv.phy_status                        <= 1'b1;
    // PIPE_SYM_EIEOS_GEN6 was removed from pcie_pipe_symbol_e in the updated
    // pcie_gen5_6_pkg_types.sv; rate_change_ack is now inferred from PIPE_SYM_EIEOS
    // which covers both Gen5 and Gen6 electrical idle exit ordered sets.
    vif.cb_drv.rate_change_ack                   <= (tr.symbol_type == PIPE_SYM_EIEOS);
    vif.cb_drv.eq_phase_done                     <= (tr.symbol_type == PIPE_SYM_TS2);
    vif.cb_drv.deskew_done                       <= tr.deskew_marker;
    vif.cb_drv.lane_reversal_detected            <= tr.lane_reversal;
  endtask
endclass : pcie_gen5_6_pipe_driver

`endif





















































