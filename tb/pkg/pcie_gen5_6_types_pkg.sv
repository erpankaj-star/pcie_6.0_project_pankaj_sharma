`ifndef PCIE_GEN5_6_TYPES_PKG_SV
`define PCIE_GEN5_6_TYPES_PKG_SV

package pcie_gen5_6_types_pkg;

  //--------------------------------------------------------------------------
  // Parameters
  //--------------------------------------------------------------------------
  parameter int PCIE_MAX_LANES      = 16;
  parameter int PCIE_PIPE_DATA_W    = 32;
  parameter int PCIE_FLIT_TLP_BYTES = 236;
  parameter int PCIE_FLIT_DLP_BYTES = 6;
  parameter int PCIE_FLIT_CRC_BYTES = 8;
  parameter int PCIE_FLIT_ECC_BYTES = 6;
  parameter int PCIE_FLIT_BYTES     = 256;
  parameter int PCIE_MAX_PAYLOAD_DW = 1024;

  //--------------------------------------------------------------------------
  // Link speed
  // pcie_link_speed_e is the new name used by updated files.
  // pcie_speed_e is kept as a typedef alias so any file still using the old
  // name compiles without change.
  //--------------------------------------------------------------------------
  typedef enum int unsigned {
    PCIE_GEN1_2P5  = 1,
    PCIE_GEN2_5P0  = 2,
    PCIE_GEN3_8P0  = 3,
    PCIE_GEN4_16P0 = 4,
    PCIE_GEN5_32P0 = 5,
    PCIE_GEN6_64P0 = 6
  } pcie_link_speed_e;

  // Backward-compat alias - any file using pcie_speed_e still compiles
  typedef pcie_link_speed_e pcie_speed_e;

  //--------------------------------------------------------------------------
  // Link width
  // pcie_link_width_e already had the correct name in the original file.
  // New enum values PCIE_WIDTH_X* added alongside original PCIE_X* values
  // so both styles compile.
  //--------------------------------------------------------------------------
  typedef enum int unsigned {
    PCIE_WIDTH_X1  = 1,
    PCIE_WIDTH_X2  = 2,
    PCIE_WIDTH_X4  = 4,
    PCIE_WIDTH_X8  = 8,
    PCIE_WIDTH_X16 = 16
  } pcie_link_width_e;

  // Backward-compat aliases for old PCIE_X* enum values
  localparam pcie_link_width_e PCIE_X1  = PCIE_WIDTH_X1;
  localparam pcie_link_width_e PCIE_X2  = PCIE_WIDTH_X2;
  localparam pcie_link_width_e PCIE_X4  = PCIE_WIDTH_X4;
  localparam pcie_link_width_e PCIE_X8  = PCIE_WIDTH_X8;
  localparam pcie_link_width_e PCIE_X16 = PCIE_WIDTH_X16;

  //--------------------------------------------------------------------------
  // Device / agent mode
  // pcie_agent_mode_e is the new name used by updated files.
  // pcie_device_mode_e kept as typedef alias.
  // New enum value names PCIE_AGENT_RC/EP alongside old PCIE_MODE_RC/EP.
  //--------------------------------------------------------------------------
  typedef enum bit {
    PCIE_AGENT_RC = 1'b0,
    PCIE_AGENT_EP = 1'b1
  } pcie_agent_mode_e;

  // Backward-compat alias
  typedef pcie_agent_mode_e pcie_device_mode_e;

  // Backward-compat value aliases
  localparam pcie_agent_mode_e PCIE_MODE_RC = PCIE_AGENT_RC;
  localparam pcie_agent_mode_e PCIE_MODE_EP = PCIE_AGENT_EP;

  //--------------------------------------------------------------------------
  // LTSSM states
  //--------------------------------------------------------------------------
  typedef enum int unsigned {
    LTSSM_DETECT_QUIET,
    LTSSM_DETECT_ACTIVE,
    LTSSM_POLLING_ACTIVE,
    LTSSM_POLLING_COMPLIANCE,
    LTSSM_POLLING_CONFIGURATION,
    LTSSM_POLLING_SPEED,
    LTSSM_CONFIGURATION_LINKWIDTH_START,
    LTSSM_CONFIGURATION_LINKWIDTH_ACCEPT,
    LTSSM_CONFIGURATION_LANENUM_ACCEPT,
    LTSSM_CONFIGURATION_LANENUM_WAIT,
    LTSSM_CONFIGURATION_COMPLETE,
    LTSSM_CONFIGURATION_IDLE,
    LTSSM_RECOVERY_RCVRLOCK,
    LTSSM_RECOVERY_EQUALIZATION,
    LTSSM_RECOVERY_SPEED,
    LTSSM_RECOVERY_RCVRCFG,
    LTSSM_RECOVERY_IDLE,
    LTSSM_L0,
    LTSSM_L0S,
    LTSSM_L0P,
    LTSSM_L1,
    LTSSM_L2,
    LTSSM_DISABLED,
    LTSSM_LOOPBACK_ENTRY,
    LTSSM_LOOPBACK_ACTIVE,
    LTSSM_LOOPBACK_EXIT,
    LTSSM_HOT_RESET
  } pcie_ltssm_state_e;

  //--------------------------------------------------------------------------
  // DL state
  //--------------------------------------------------------------------------
  typedef enum int unsigned {
    DL_INACTIVE,
    DL_FEATURE,
    DL_INIT,
    DL_ACTIVE,
    DL_DOWN
  } pcie_dl_state_e;

  //--------------------------------------------------------------------------
  // TLP types
  //--------------------------------------------------------------------------
  typedef enum int unsigned {
    TLP_MEM_RD,
    TLP_MEM_WR,
    TLP_CFG_RD0,
    TLP_CFG_WR0,
    TLP_CFG_RD1,
    TLP_CFG_WR1,
    TLP_CPL,
    TLP_CPLD,
    TLP_MSG,
    TLP_MSGD,
    TLP_ATOMIC_FETCHADD,
    TLP_ATOMIC_SWAP,
    TLP_ATOMIC_CAS,
    TLP_DEFERRABLE_MEM_WR,
    TLP_NOP
  } pcie_tlp_type_e;

  // Alias for files using TLP_MSG_D instead of TLP_MSGD
  localparam pcie_tlp_type_e TLP_MSG_D = TLP_MSGD;

  //--------------------------------------------------------------------------
  // DLLP types
  // Original names kept. New convenience aliases added for FC init/update
  // sub-sequences in updated virtual sequence files.
  //--------------------------------------------------------------------------
  typedef enum int unsigned {
    DLP_ACK,
    DLP_NAK,
    DLP_INITFC1,
    DLP_INITFC2,
    DLP_UPDATEFC,
    DLP_OPT_UPDATEFC,
    DLP_FEATURE,
    DLP_PM,
    DLP_VENDOR,
    DLP_NOP
  } pcie_dlp_type_e;

  // Aliases used by FC init/update sub-sequences (virtual sequence layer)
  localparam pcie_dlp_type_e DLP_FC_INIT1_P   = DLP_INITFC1;
  localparam pcie_dlp_type_e DLP_FC_INIT1_NP  = DLP_INITFC1;
  localparam pcie_dlp_type_e DLP_FC_INIT1_CPL = DLP_INITFC1;
  localparam pcie_dlp_type_e DLP_FC_INIT2_P   = DLP_INITFC2;
  localparam pcie_dlp_type_e DLP_FC_INIT2_NP  = DLP_INITFC2;
  localparam pcie_dlp_type_e DLP_FC_INIT2_CPL = DLP_INITFC2;
  localparam pcie_dlp_type_e DLP_FC_UPDATE_P   = DLP_UPDATEFC;
  localparam pcie_dlp_type_e DLP_FC_UPDATE_NP  = DLP_UPDATEFC;
  localparam pcie_dlp_type_e DLP_FC_UPDATE_CPL = DLP_UPDATEFC;

  //--------------------------------------------------------------------------
  // PIPE symbol types
  // PIPE_SYM_EIEOS_GEN6 kept (was in original file, some files still use it).
  // PIPE_SYM_DATA added as alias for PIPE_SYM_FLIT.
  //--------------------------------------------------------------------------
  typedef enum int unsigned {
    PIPE_SYM_TS1,
    PIPE_SYM_TS2,
    PIPE_SYM_SKP,
    PIPE_SYM_SDS,
    PIPE_SYM_EIOS,
    PIPE_SYM_EIEOS,
    PIPE_SYM_FTS,
    PIPE_SYM_FLIT,
    PIPE_SYM_IDLE,
    PIPE_SYM_EIEOS_GEN6,
    PIPE_SYM_UNKNOWN
  } pcie_pipe_symbol_e;

  // Alias used by updated pipe driver/monitor
  localparam pcie_pipe_symbol_e PIPE_SYM_DATA = PIPE_SYM_FLIT;

  //--------------------------------------------------------------------------
  // FLIT types
  //--------------------------------------------------------------------------
  typedef enum int unsigned {
    FLIT_IDLE,
    FLIT_NOP,
    FLIT_PAYLOAD,
    FLIT_REPLAY,
    FLIT_NULLIFIED,
    FLIT_POISONED
  } pcie_flit_type_e;

  //--------------------------------------------------------------------------
  // Error kinds
  // pcie_error_kind_e is the new name used by all updated files.
  // pcie_error_inject_e kept as typedef alias for backward compat.
  // ERR_INVALID_TLP added (used by tl_monitor to replace ERR_MALFORMED_TLP).
  // ERR_CREDIT_EXHAUSTION added (used by error inject vseq).
  // ERR_BAD_FLIT_CRC added (used by pipe-layer error injection).
  //--------------------------------------------------------------------------
  typedef enum int unsigned {
    ERR_NONE,
    ERR_BAD_LCRC,
    ERR_BAD_CRC,
    ERR_BAD_ECC,
    ERR_BAD_FLIT_SEQ,
    ERR_DROP_FLIT,
    ERR_DUP_FLIT,
    ERR_FORCE_NAK,
    ERR_REPLAY_TIMEOUT,
    ERR_UNSUPPORTED_REQUEST,
    ERR_COMPLETER_ABORT,
    ERR_UNEXPECTED_COMPLETION,
    ERR_MALFORMED_TLP,
    ERR_INVALID_TLP,
    ERR_POISONED_TLP,
    ERR_FC_CREDIT_UNDERFLOW,
    ERR_CREDIT_EXHAUSTION,
    ERR_LINK_DOWN_ACTIVE,
    ERR_LTSSM_TIMEOUT,
    ERR_EQ_FAILURE,
    ERR_DESKEW_FAILURE,
    ERR_IDE_PCRC,
    ERR_BAD_FLIT_CRC,
    ERR_IDE_AUTH_FAIL,
    ERR_IDE_BAD_MAC,
    ERR_PASID_INVALID,
    ERR_PASID_PRIV_VIOL,
    ERR_OHC_MALFORMED,
    ERR_OHC_BAD_VENDOR
  } pcie_error_kind_e;

  // Backward-compat alias - any file using pcie_error_inject_e still compiles
  typedef pcie_error_kind_e pcie_error_inject_e;

  //--------------------------------------------------------------------------
  // Completion status (new - used by pcie_tlp_item step 2 additions)
  //--------------------------------------------------------------------------
  typedef enum bit [2:0] {
    CPL_SC  = 3'b000,   // Successful Completion
    CPL_UR  = 3'b001,   // Unsupported Request
    CPL_CRS = 3'b010,   // Configuration Request Retry Status
    CPL_CA  = 3'b100    // Completer Abort
  } pcie_cpl_status_e;

  //--------------------------------------------------------------------------
  // OHC type (new - used by pcie_tlp_item step 2 additions)
  //--------------------------------------------------------------------------
  typedef enum bit [3:0] {
    OHC_NONE          = 4'h0,
    OHC_LN_NOTICE     = 4'h1,
    OHC_TPH           = 4'h2,
    OHC_ATS_MARKER    = 4'h3,
    OHC_IDE_PCRC      = 4'h4,
    OHC_VENDOR        = 4'hF
  } pcie_ohc_type_e;

  //--------------------------------------------------------------------------
  // BAR type (new - used by pcie_gen5_6_cfg step 2 additions)
  //--------------------------------------------------------------------------
  typedef enum bit [1:0] {
    BAR_MEM32 = 2'b00,
    BAR_MEM64 = 2'b01,
    BAR_IO    = 2'b10
  } pcie_bar_type_e;

  //--------------------------------------------------------------------------
  // Flow control credit availability (struct - unchanged from original)
  //--------------------------------------------------------------------------
  typedef struct packed {
    bit ph;
    bit pd;
    bit nph;
    bit npd;
    bit cplh;
    bit cpld;
  } pcie_credit_avail_s;

endpackage : pcie_gen5_6_types_pkg

`endif




































































































































































