/*
 * hci_parity.svh
 * Maurus Item <itemm@student.ethz.ch>
 *
 * Copyright (C) 2024 ETH Zurich, University of Bologna
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */

// Based on an existing interface define a parity interface for it
`define HCI_PARITY_PARAM(base_interface_param, parity_interface_param) \
  localparam hci_package::hci_size_parameter_t `HCI_SIZE_PARAM(parity_interface_param) = '{ \
    DW: `HCI_SIZE_GET_DW(base_interface_param) / `HCI_SIZE_GET_BW(base_interface_param), \
    AW: 1, \
    BW: 1, \
    UW: `HCI_SIZE_GET_UW(base_interface_param), \
    IW: `HCI_SIZE_GET_IW(base_interface_param), \
    EW: 1, \
    EHW: 1 \
  };
