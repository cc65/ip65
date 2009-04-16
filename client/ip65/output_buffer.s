.bss

;global scratch buffer that DHCP/DNS/TFTP and others can use while building outbound packets.
;you need to be careful if using this that you don't call a function that also uses it.
;if this is reversed for higher level protocols, the likelyhood of collision is low.
.export output_buffer
output_buffer: .res 520