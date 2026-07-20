`ifndef PCIE_GEN5_6_TL_DRIVER_SV
`define PCIE_GEN5_6_TL_DRIVER_SV

class pcie_gen5_6_tl_driver extends uvm_driver #(pcie_tlp_item);
  `uvm_component_utils(pcie_gen5_6_tl_driver)

  virtual pcie_tl_if.tb vif;
  pcie_gen5_6_cfg cfg;

  function new(string name = "pcie_gen5_6_tl_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pcie_tl_if.tb)::get(this, "", "tl_vif", vif)) begin
      `uvm_fatal(get_type_name(), "tl_vif not set")
    end
    if (!uvm_config_db#(pcie_gen5_6_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = pcie_gen5_6_cfg::type_id::create("cfg");
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.tl_ready     <= 1'b1;
    vif.credit_avail <= '{ph:1'b1, pd:1'b1, nph:1'b1, npd:1'b1, cplh:1'b1, cpld:1'b1};
    forever begin
      seq_item_port.get_next_item(req);
      wait_for_credit(req);
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask

  // Wait until the required FC credit type is available.
  // Posted TLPs (MEM_WR / MSG) consume PH credit.
  // Non-posted TLPs (reads / atomics) consume NPH credit.
  task wait_for_credit(pcie_tlp_item tr);
    do begin
      @(posedge vif.clk);
    end while (
      (tr.is_posted()        && !vif.credit_avail.ph) ||
      (tr.needs_completion() && !vif.credit_avail.nph)
    );
  endtask
endclass : pcie_gen5_6_tl_driver

`endif











































