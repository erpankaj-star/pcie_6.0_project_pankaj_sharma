`ifndef PCIE_GEN5_6_DL_MONITOR_SV
`define PCIE_GEN5_6_DL_MONITOR_SV

class pcie_gen5_6_dl_monitor extends uvm_monitor;
  `uvm_component_utils(pcie_gen5_6_dl_monitor)

  virtual pcie_dl_if.monitor vif;
  uvm_analysis_port #(pcie_dlp_item) ap;

  function new(string name = "pcie_gen5_6_dl_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pcie_dl_if.monitor)::get(this, "", "dl_vif", vif)) begin
      `uvm_fatal(get_type_name(), "dl_vif not set")
    end
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.clk);
      if (!vif.reset_n) begin
        continue;
      end
      sample_and_publish();
    end
  endtask

  function void sample_and_publish();
    pcie_dlp_item tr;
    tr = pcie_dlp_item::type_id::create("tr", this);

    tr.dlp_type            = vif.dlp_type;
    tr.tlp_seq_num         = vif.tlp_seq_num;
    tr.flit_seq_num        = vif.flit_seq_num;
    tr.ack_nak_seq_num     = vif.ack_nak_seq_num;
    tr.optimized_update_fc = vif.optimized_update_fc;
    tr.scaled_fc           = vif.scaled_fc_enable;
    tr.ph_credit           = vif.ph_credit;
    tr.pd_credit           = vif.pd_credit;
    tr.nph_credit          = vif.nph_credit;
    tr.npd_credit          = vif.npd_credit;
    tr.cplh_credit         = vif.cplh_credit;
    tr.cpld_credit         = vif.cpld_credit;
    tr.error_kind          = ERR_NONE;

    ap.write(tr);
  endfunction
endclass : pcie_gen5_6_dl_monitor

`endif





















































