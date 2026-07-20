`ifndef PCIE_FLIT_ITEM_SV
`define PCIE_FLIT_ITEM_SV

class pcie_flit_item extends uvm_sequence_item;
  rand pcie_flit_type_e flit_type;
  rand bit [9:0]        flit_seq_num;
  rand bit [1:0]        replay_cmd;
  rand bit              prior_flit_payload;
  rand bit [7:0]        tlp_bytes[PCIE_FLIT_TLP_BYTES];
  rand bit [7:0]        dlp_bytes[PCIE_FLIT_DLP_BYTES];
  rand bit [7:0]        crc_bytes[PCIE_FLIT_CRC_BYTES];
  rand bit [7:0]        ecc_bytes[PCIE_FLIT_ECC_BYTES];
  rand bit              crc_ok;
  rand bit              ecc_correctable;
  rand bit              ecc_uncorrectable;
  rand bit              poisoned_marker;
  rand bit              nullified_marker;
  rand bit              shared_fc_marker;
  rand pcie_error_inject_e error_kind;

  constraint c_seq { if (flit_type == FLIT_IDLE) flit_seq_num == 0; }
  constraint c_err { !(ecc_correctable && ecc_uncorrectable); }

  `uvm_object_utils_begin(pcie_flit_item)
    `uvm_field_enum(pcie_flit_type_e, flit_type, UVM_ALL_ON)
    `uvm_field_int(flit_seq_num, UVM_ALL_ON)
    `uvm_field_int(replay_cmd, UVM_ALL_ON)
    `uvm_field_int(prior_flit_payload, UVM_ALL_ON)
    `uvm_field_sarray_int(tlp_bytes, UVM_ALL_ON)
    `uvm_field_sarray_int(dlp_bytes, UVM_ALL_ON)
    `uvm_field_sarray_int(crc_bytes, UVM_ALL_ON)
    `uvm_field_sarray_int(ecc_bytes, UVM_ALL_ON)
    `uvm_field_int(crc_ok, UVM_ALL_ON)
    `uvm_field_int(ecc_correctable, UVM_ALL_ON)
    `uvm_field_int(ecc_uncorrectable, UVM_ALL_ON)
    `uvm_field_int(poisoned_marker, UVM_ALL_ON)
    `uvm_field_int(nullified_marker, UVM_ALL_ON)
    `uvm_field_int(shared_fc_marker, UVM_ALL_ON)
    `uvm_field_enum(pcie_error_inject_e, error_kind, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pcie_flit_item");
    super.new(name);
    crc_ok = 1'b1;
    error_kind = ERR_NONE;
  endfunction

  function void pack_tlp(input pcie_tlp_item tlp);
    foreach (tlp_bytes[i]) begin
      tlp_bytes[i] = 8'h00;
    end
    tlp_bytes[0] = {4'h0, tlp.tlp_type[3:0]};
    tlp_bytes[1] = tlp.tag[7:0];
    tlp_bytes[2] = tlp.length_dw[7:0];
    tlp_bytes[3] = {tlp.first_be, tlp.last_be};
    flit_type = (tlp.tlp_type == TLP_NOP) ? FLIT_NOP : FLIT_PAYLOAD;
    poisoned_marker  = tlp.poisoned;
    nullified_marker = (tlp.error_kind == ERR_MALFORMED_TLP);
  endfunction

  function bit valid_after_fec_crc();
    return crc_ok && !ecc_uncorrectable;
  endfunction
endclass : pcie_flit_item

`endif

