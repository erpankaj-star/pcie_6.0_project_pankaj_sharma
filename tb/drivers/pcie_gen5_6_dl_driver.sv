`ifndef PCIE_GEN5_6_DL_DRIVER_SV
`define PCIE_GEN5_6_DL_DRIVER_SV

class pcie_gen5_6_dl_driver extends uvm_driver #(pcie_dlp_item);
  `uvm_component_utils(pcie_gen5_6_dl_driver)

  virtual pcie_dl_if.tb vif;
  pcie_gen5_6_cfg cfg;

  function new(string name = "pcie_gen5_6_dl_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pcie_dl_if.tb)::get(this, "", "dl_vif", vif)) begin
      `uvm_fatal(get_type_name(), "dl_vif not set")
    end
    if (!uvm_config_db#(pcie_gen5_6_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = pcie_gen5_6_cfg::type_id::create("cfg");
    end
  endfunction

  task run_phase(uvm_phase phase);
    vif.dl_ready <= 1'b1;
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass : pcie_gen5_6_dl_driver

`endif


































