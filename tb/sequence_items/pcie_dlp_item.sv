`ifndef PCIE_DLP_ITEM_SV
`define PCIE_DLP_ITEM_SV

class pcie_dlp_item extends uvm_sequence_item;
//  `uvm_object_utils(pcie_dlp_item)

  //--------------------------------------------------------------------------
  // Existing DLLP fields
  //--------------------------------------------------------------------------
  rand pcie_dlp_type_e   dlp_type;
  rand bit [11:0]        tlp_seq_num;
  rand bit [9:0]         flit_seq_num;
  rand bit [9:0]         ack_nak_seq_num;
  rand bit [31:0]        dllp_payload;
  rand bit               optimized_update_fc;
  rand bit               scaled_fc;
  rand bit [11:0]        ph_credit;
  rand bit [11:0]        pd_credit;
  rand bit [11:0]        nph_credit;
  rand bit [11:0]        npd_credit;
  rand bit [11:0]        cplh_credit;
  rand bit [11:0]        cpld_credit;

  //--------------------------------------------------------------------------
  // Step 3 additions: FC header/data credit fields used by send_dlp()
  // randomize() with {} block in pcie_gen5_6_base_seq
  //--------------------------------------------------------------------------
  rand bit [7:0]         fc_hdr_credits;
  rand bit [11:0]        fc_data_credits;

  //--------------------------------------------------------------------------
  // Step 3 additions: error kind and force bits consumed by send_dlp()
  //--------------------------------------------------------------------------
  rand pcie_error_kind_e error_kind;
  bit                    force_bad_lcrc;
  bit                    force_replay_timeout;
  bit                    force_credit_exhaust;

  //--------------------------------------------------------------------------
  // Constraints
  //--------------------------------------------------------------------------
  constraint c_credit { ph_credit   <= 4095;
                        pd_credit   <= 4095;
                        nph_credit  <= 4095;
                        npd_credit  <= 4095;
                        cplh_credit <= 4095;
                        cpld_credit <= 4095; }
  constraint c_fc_hdr  { fc_hdr_credits  inside {[0:255]};  }
  constraint c_fc_data { fc_data_credits inside {[0:4095]}; }
  constraint c_error_default { soft error_kind == ERR_NONE; }

  `uvm_object_utils_begin(pcie_dlp_item)
    `uvm_field_enum(pcie_dlp_type_e,   dlp_type,            UVM_ALL_ON)
    `uvm_field_int(tlp_seq_num,                              UVM_ALL_ON)
    `uvm_field_int(flit_seq_num,                             UVM_ALL_ON)
    `uvm_field_int(ack_nak_seq_num,                          UVM_ALL_ON)
    `uvm_field_int(dllp_payload,                             UVM_ALL_ON)
    `uvm_field_int(optimized_update_fc,                      UVM_ALL_ON)
    `uvm_field_int(scaled_fc,                                UVM_ALL_ON)
    `uvm_field_int(ph_credit,                                UVM_ALL_ON)
    `uvm_field_int(pd_credit,                                UVM_ALL_ON)
    `uvm_field_int(nph_credit,                               UVM_ALL_ON)
    `uvm_field_int(npd_credit,                               UVM_ALL_ON)
    `uvm_field_int(cplh_credit,                              UVM_ALL_ON)
    `uvm_field_int(cpld_credit,                              UVM_ALL_ON)
    `uvm_field_int(fc_hdr_credits,                           UVM_ALL_ON)
    `uvm_field_int(fc_data_credits,                          UVM_ALL_ON)
    `uvm_field_enum(pcie_error_kind_e, error_kind,           UVM_ALL_ON)
    `uvm_field_int(force_bad_lcrc,                           UVM_ALL_ON)
    `uvm_field_int(force_replay_timeout,                     UVM_ALL_ON)
    `uvm_field_int(force_credit_exhaust,                     UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pcie_dlp_item");
    super.new(name);
    error_kind = ERR_NONE;
  endfunction
endclass : pcie_dlp_item

`endif










































