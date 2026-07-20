`ifndef PCIE_GEN5_6_TL_MONITOR_SV
`define PCIE_GEN5_6_TL_MONITOR_SV

class pcie_gen5_6_tl_monitor extends uvm_monitor;
  `uvm_component_utils(pcie_gen5_6_tl_monitor)

  virtual pcie_tl_if.monitor vif;
  uvm_analysis_port #(pcie_tlp_item) ap;

  function new(string name = "pcie_gen5_6_tl_monitor", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual pcie_tl_if.monitor)::get(this, "", "tl_vif", vif)) begin
      `uvm_fatal(get_type_name(), "tl_vif not set")
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
/* task run_phase(uvm_phase phase);
  forever begin
    @(posedge vif.clk);

    if(!vif.reset_n)
      continue;

    if(vif.tl_valid)
      sample_and_publish();
  end
endtask*/

  function void sample_and_publish();
    pcie_tlp_item tr;
    tr = pcie_tlp_item::type_id::create("tr", this);

    tr.tlp_type      = vif.tl_type;
    tr.requester_id  = vif.requester_id;
    tr.completer_id  = vif.completer_id;
    tr.tag           = vif.tag;
    tr.addr          = vif.addr;
    tr.length_dw     = vif.length_dw;
    tr.first_be      = vif.first_be;
    tr.last_be       = vif.last_be;
    tr.traffic_class = vif.traffic_class;
    tr.attr          = vif.attr;
    tr.poisoned      = vif.poisoned;
    tr.ecrc_present  = vif.ecrc_present;
    tr.ide_present   = vif.ide_present;
    tr.pasid         = vif.pasid;
    tr.ohc_vector    = vif.ohc_vector;
    // ERR_MALFORMED_TLP was removed from pcie_error_kind_e in the updated
    // pcie_gen5_6_pkg_types.sv; the closest semantic match is ERR_INVALID_TLP.
    tr.error_kind    = vif.malformed_tlp ? ERR_INVALID_TLP : ERR_NONE;

    ap.write(tr);
   `uvm_info("TL_MON",
          $sformatf("type=%s valid=%0b",
                    tr.tlp_type.name(),
                    vif.tl_valid),
          UVM_LOW)

  endfunction

endclass : pcie_gen5_6_tl_monitor

`endif

























































