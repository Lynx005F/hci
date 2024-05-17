// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Register Package auto-generated by `reggen` containing data structure

package hci_ecc_manager_reg_pkg;

  // Address widths within the block
  parameter int BlockAw = 4;

  ////////////////////////////
  // Typedefs for registers //
  ////////////////////////////

  typedef struct packed {
    logic [31:0] q;
  } hci_ecc_manager_reg2hw_data_correctable_errors_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } hci_ecc_manager_reg2hw_data_uncorrectable_errors_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } hci_ecc_manager_reg2hw_metadata_correctable_errors_reg_t;

  typedef struct packed {
    logic [31:0] q;
  } hci_ecc_manager_reg2hw_metadata_uncorrectable_errors_reg_t;

  typedef struct packed {
    logic [31:0] d;
    logic        de;
  } hci_ecc_manager_hw2reg_data_correctable_errors_reg_t;

  typedef struct packed {
    logic [31:0] d;
    logic        de;
  } hci_ecc_manager_hw2reg_data_uncorrectable_errors_reg_t;

  typedef struct packed {
    logic [31:0] d;
    logic        de;
  } hci_ecc_manager_hw2reg_metadata_correctable_errors_reg_t;

  typedef struct packed {
    logic [31:0] d;
    logic        de;
  } hci_ecc_manager_hw2reg_metadata_uncorrectable_errors_reg_t;

  // Register -> HW type
  typedef struct packed {
    hci_ecc_manager_reg2hw_data_correctable_errors_reg_t data_correctable_errors; // [127:96]
    hci_ecc_manager_reg2hw_data_uncorrectable_errors_reg_t data_uncorrectable_errors; // [95:64]
    hci_ecc_manager_reg2hw_metadata_correctable_errors_reg_t metadata_correctable_errors; // [63:32]
    hci_ecc_manager_reg2hw_metadata_uncorrectable_errors_reg_t metadata_uncorrectable_errors; // [31:0]
  } hci_ecc_manager_reg2hw_t;

  // HW -> register type
  typedef struct packed {
    hci_ecc_manager_hw2reg_data_correctable_errors_reg_t data_correctable_errors; // [131:99]
    hci_ecc_manager_hw2reg_data_uncorrectable_errors_reg_t data_uncorrectable_errors; // [98:66]
    hci_ecc_manager_hw2reg_metadata_correctable_errors_reg_t metadata_correctable_errors; // [65:33]
    hci_ecc_manager_hw2reg_metadata_uncorrectable_errors_reg_t metadata_uncorrectable_errors; // [32:0]
  } hci_ecc_manager_hw2reg_t;

  // Register offsets
  parameter logic [BlockAw-1:0] HCI_ECC_MANAGER_DATA_CORRECTABLE_ERRORS_OFFSET = 4'h 0;
  parameter logic [BlockAw-1:0] HCI_ECC_MANAGER_DATA_UNCORRECTABLE_ERRORS_OFFSET = 4'h 4;
  parameter logic [BlockAw-1:0] HCI_ECC_MANAGER_METADATA_CORRECTABLE_ERRORS_OFFSET = 4'h 8;
  parameter logic [BlockAw-1:0] HCI_ECC_MANAGER_METADATA_UNCORRECTABLE_ERRORS_OFFSET = 4'h c;

  // Register index
  typedef enum int {
    HCI_ECC_MANAGER_DATA_CORRECTABLE_ERRORS,
    HCI_ECC_MANAGER_DATA_UNCORRECTABLE_ERRORS,
    HCI_ECC_MANAGER_METADATA_CORRECTABLE_ERRORS,
    HCI_ECC_MANAGER_METADATA_UNCORRECTABLE_ERRORS
  } hci_ecc_manager_id_e;

  // Register width information to check illegal writes
  parameter logic [3:0] HCI_ECC_MANAGER_PERMIT [4] = '{
    4'b 1111, // index[0] HCI_ECC_MANAGER_DATA_CORRECTABLE_ERRORS
    4'b 1111, // index[1] HCI_ECC_MANAGER_DATA_UNCORRECTABLE_ERRORS
    4'b 1111, // index[2] HCI_ECC_MANAGER_METADATA_CORRECTABLE_ERRORS
    4'b 1111  // index[3] HCI_ECC_MANAGER_METADATA_UNCORRECTABLE_ERRORS
  };

endpackage
