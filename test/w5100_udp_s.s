.export _init
.export _recv_init, _recv_byte, _recv_done
.export _send_init, _send_byte, _send_done

.import init
.import recv_init, recv_byte, recv_done
.import send_init, send_byte, send_done

_init:
        jmp init

_recv_init:
        jsr recv_init
        bcc :+
        lda #<$0000
        ldx #>$0000
:       rts

_recv_byte:
        jsr recv_byte
        ldx #>$0000
        rts

_recv_done:
        jmp recv_done

_send_init:
        jsr send_init
        bcc :+
        lda #<$0000
        ldx #>$0000
        rts
:       lda #<$0001
        ldx #>$0001
        rts

_send_byte:
        jmp send_byte

_send_done:
        jmp send_done
