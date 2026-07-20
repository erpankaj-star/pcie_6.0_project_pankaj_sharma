`ifndef PCIE_GEN5_6_PIPE_MONITOR_SV
`define PCIE_GEN5_6_PIPE_MONITOR_SV

class pcie_gen5_6_pipe_monitor extends uvm_monitor;
  `uvm_component_utils(pcie_gen5_6_pipe_monitor)

  virtual pcie_pipe_if.monitor vif;
  uvm_analysis_port #(pcie_pipe_symbol_item) ap;

  function new(string name = "pcie_gen5_6_pipe_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pcie_pipe_if.monitor)::get(this, "", "pipe_vif", vif)) begin
      `uvm_fatal(get_type_name(), "pipe_vif not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.pclk);
      if (!vif.reset_n) begin
        continue;
      end
      sample_and_publish();
    end
  endtask

  function void sample_and_publish();
    pcie_pipe_symbol_item tr;
    tr = pcie_pipe_symbol_item::type_id::create("tr", this);

    // symbol_type: FLIT if tx_valid[0] asserted, else IDLE.
    // speed/width fields on tr use pcie_link_speed_e / pcie_link_width_e
    // (the updated types); the interface signals are the same width so the
    // assignment is direct.
    tr.symbol_type       = vif.cb_mon.tx_valid[0] ? PIPE_SYM_FLIT : PIPE_SYM_IDLE;
    tr.speed             = pcie_link_speed_e'(vif.cb_mon.negotiated_speed);
    tr.width             = pcie_link_width_e'(vif.cb_mon.negotiated_width);
    tr.lane_num          = 5'd0;
    tr.data              = vif.cb_mon.tx_data[0];
    tr.datak             = vif.cb_mon.tx_datak[0];
    tr.start_block       = vif.cb_mon.tx_start_block[0];
    tr.sync_header       = vif.cb_mon.tx_sync_header[0];
    tr.elec_idle         = vif.cb_mon.tx_elec_idle[0];
    tr.polarity_inverted = vif.cb_mon.rx_polarity_inverted[0];
    tr.lane_reversal     = vif.cb_mon.lane_reversal_detected;
    tr.deskew_marker     = vif.cb_mon.deskew_done;
    tr.retimer_marker    = vif.cb_mon.retimer_present;
    tr.pam4_symbol       = vif.cb_mon.pam4_symbol[0];
    tr.precoding_enable  = vif.cb_mon.precoding_enable;
    tr.scrambling_enable = vif.cb_mon.scrambling_enable;
    tr.error_kind        = pcie_error_kind_e'(vif.cb_mon.injected_error);

    ap.write(tr);
  endfunction
endclass : pcie_gen5_6_pipe_monitor

`endif


























































