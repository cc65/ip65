; IP configuration defaults
; most of these will be overwritten if dhcp is used for configuration

.include "../inc/common.i"

.export cfg_mac
.export cfg_ip
.export cfg_netmask
.export cfg_gateway
.export cfg_dns
.export cfg_tftp_server
.export cfg_get_configuration_ptr

.export dhcp_server
.import copymem
.importzp copy_src
.importzp copy_dest


.data

cfg_mac:                        .byte $00, $80, $10, $00, $51, $00      ; mac address to be assigned to local machine
cfg_ip:                         .byte 192, 168, 1, 64                   ; ip address of local machine (will be overwritten if dhcp_init is called)
; cfg_ip:                       .byte 0, 0, 0, 0                        ; ip address of local machine (will be overwritten if dhcp_init is called)
cfg_netmask:                    .byte 255, 255, 255, 0                  ; netmask of local network (will be overwritten if dhcp_init is called)
; cfg_gateway:                  .byte 0, 0, 0, 0                        ; ip address of router on local network (will be overwritten if dhcp_init is called)
cfg_gateway:                    .byte 192, 168, 1, 1                    ; ip address of router on local network (will be overwritten if dhcp_init is called)
cfg_dns:                        .byte 0, 0, 0, 0                        ; ip address of dns server to use (will be overwritten if dhcp_init is called)
dhcp_server:                    .byte 0, 0, 0, 0                        ; will be set address of dhcp server that configuration was obtained from
cfg_tftp_server:                .byte $ff, $ff, $ff, $ff                ; ip address of server to send tftp requests to (can be a broadcast address)


.code

; return a pointer to where the IP configuration is kept
; this is really only useful for the NB65 API - for anything
; linking directly against ip65, you would just import the
; address of the individual configuration elements, rather
; than use a base pointer+offsets to find each item.
; inputs: none
; outputs: AX = pointer to IP configuration.
cfg_get_configuration_ptr:
  ldax #cfg_mac
  clc
  rts



; -- LICENSE FOR config.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
;
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
;
; The Original Code is ip65.
;
; The Initial Developer of the Original Code is Per Olofsson,
; MagerValp@gmail.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Per Olofsson. All Rights Reserved.
; -- LICENSE END --
