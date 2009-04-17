; ip65 main routines

.include "../inc/common.i"

.ifndef NB65_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/nb65_constants.i"
.endif

	.export ip65_init
	.export ip65_process

	.export ip65_ctr
	.export ip65_ctr_arp
	.export ip65_ctr_ip
  
  .export ip65_error
   
  .import cfg_init
  
	.import eth_init
	.import timer_init
	.import arp_init
	.import ip_init

	.import eth_inp
	.import eth_rx

	.import ip_process
	.import arp_process

	.importzp eth_proto_arp


	.bss

ip65_ctr:	.res 1		; incremented for every incoming packet
ip65_ctr_arp:	.res 1		; incremented for every incoming arp packet
ip65_ctr_ip:	.res 1		; incremented for every incoming ip packet

ip65_error: .res 1  ;last error code

	.code

; initialise the IP stack
; this calls the individual protocol & driver initialisations, so this is
; the only *_init routine that must be called by a user application,
; except for dhcp_init which must also be called if the application
; is using dhcp rather than hardcoded ip configuration
; inputs: none
; outputs: none
ip65_init:
  jsr cfg_init    ;copy default values (including MAC address) to RAM
	jsr eth_init		; initialize ethernet driver
  
	bcc @ok
  lda #NB65_ERROR_DEVICE_FAILURE
  sta ip65_error
  rts
@ok:  
	jsr timer_init		; initialize timer
	jsr arp_init		; initialize arp
	jsr ip_init		; initialize ip, icmp, udp, and tcp
	clc
	rts


;main ip polling loop
;this routine should be periodically called by an application at any time
;that an inbound packet needs to be handled.
;it is 'non-blocking', i.e. it will return if there is no packet waiting to be
;handled. any inbound packet will be handed off to the appropriate handler.
;inputs: none
;outputs: carry flag set if no packet was waiting, or packet handling caused error.
;  since the inbound packet may trigger generation of an outbound, eth_outp 
;  and eth_outp_len may be overwriiten. 
ip65_process:
	jsr eth_rx		; check for incoming packets
	bcs @done

	lda eth_inp + 12	; type should be 08xx
	cmp #8
	bne @done

	lda eth_inp + 13
;	cmp #eth_proto_ip	; ip = 00
	beq @ip
	cmp #eth_proto_arp	; arp = 06
	beq @arp
@done:
	rts

@arp:
	inc ip65_ctr_arp
	jmp arp_process

@ip:
	inc ip65_ctr_ip
	jmp ip_process
