;-----------------------------------------------------------------------
; PET Term
; Version 0.1
;
; A bit-banged full duplex serial terminal for the PET 2001 computers,
; including those running BASIC 1.
;
; Targets 8N1 serial. 300 baud
; 
; 
;
; Hayden Kroepfl 2017
;
; Written for the DASM assembler
;----------------------------------------------------------------------- 
	PROCESSOR 6502

;-----------------------------------------------------------------------
; Zero page definitions
;-----------------------------------------------------------------------
	SEG.U	ZPAGE
	RORG	$0

SERCNT	DS.B	1		; Current sample number
TXTGT	DS.B	1		; Sample number of next send event
RXTGT	DS.B	1		; Sample number of next recv event
TXCUR	DS.B	1		; Current byte being transmitted
RXCUR	DS.B	1		; Current byte being received
TXSTATE	DS.B	1		; Next Transmit state
RXSTATE	DS.B	1		; Next Receive state
TXBIT	DS.B	1		; Tx data bit #
RXBIT	DS.B	1		; Rx data bit #
RXSAMP	DS.B	1		; Last sampled value

TXBYTE	DS.B	1		; Next byte to transmit
RXBYTE	DS.B	1		; Last receved byte

RXNEW	DS.B	1		; Indicates byte has been recieved

	REND
;-----------------------------------------------------------------------

;-----------------------------------------------------------------------
; GLOBAL Defines
;-----------------------------------------------------------------------
STSTART	EQU	0		; Waiting for start bit
STDONE	EQU	0		; Finished sending
STRDY	EQU	1		; Ready to start sending
STBIT	EQU	2		; Sending/receiving data
STSTOP	EQU	4		; Sending/receiving stop bit


BITCNT	EQU	8		; 8-bit
BITMSK	EQU	$FF		; No mask


;-----------------------------------------------------------------------
; Start of loaded data
	SEG	CODE
	ORG	$0401           ; For PET 2001



;-----------------------------------------------------------------------
; Simple Basic 'Loader' - BASIC Statement to jump into our program
BLDR
	DC.W BLDR_ENDL	; LINK (To end of program)
	DC.W 10		; Line Number = 10
	DC.B $9E	; SYS
	; Decimal Address in ASCII $30 is 0 $31 is 1, etc
	DC.B (INIT/10000)%10 + '0
	DC.B (INIT/ 1000)%10 + '0
	DC.B (INIT/  100)%10 + '0
	DC.B (INIT/   10)%10 + '0
	DC.B (INIT/    1)%10 + '0

	DC.B $0		; Line End
BLDR_ENDL
	DC.W $0		; LINK (End of program)
;-----------------------------------------------------------------------


;-----------------------------------------------------------------------
; Initialization
INIT	SUBROUTINE
	
	; Fall into START
;-----------------------------------------------------------------------
; Start of program (after INIT called)
START	SUBROUTINE








;-----------------------------------------------------------------------
; Bit-banged serial sample (Called at 3x baud rate)
SERSAMP	SUBROUTINE
	LDA	SERCNT
	CMP	RXTGT		; Check if we're due for the next Rx event
	JSR	SERRX
	JSR	SERTX
	RTS
	
; Do a Rx sample
SERRX	SUBROUTINE
	JSR	SAMPRX		; Sample the Rx line
	LDA	RXSTATE
	CMP	#STSTART	; Waiting for start bit
	BEQ	.start
	CMP	#STDATA		; Sample data bit
	BEQ	.datab
	CMP	#STSTOP		; Sample stop bit
	BEQ	.stop
	; Invalid Rx state, reset to STSTART
	LDA	#STSTART
	STA	RXSTATE
	JMP	.next1
.stop
	LDA	RXSAMP
	CMP	#1		; Make sure stop bit is 0
	BEQ	.nextstart	; Failed recv, unexpected value Ignore byte 
				; resume waiting for start bit
	; Otherwise save bit
	LDA	RXCUR
	STA	RXBYTE		; Save cur byte, as received byte
	LDA	#$FF
	STA	RXNEW		; Indicate byte recieved
.nextstart
	LDA	#STSTART
	STA	RXSTATE
	JMP	.next3		
		
.datab
	CLC
	ROL	RXCUR		; Shift left to make room for bit
	LDA	RXCUR
	ORA	RXSAMP		; Or in current bit
	INC	RXBIT
	LDA	RXBIT
	CMP	#BITCNT		; Check if we've read our last bit
	BNE	.next3
	LDA	#STSTOP		; Next is the stop bit
	STA	RXSTATE
	JMP	.next3
	
.start
	LDA	RXSAMP
	CMP	#1		; Check if high
	BEQ	.next1		; If we didn't find it, try again next sample
	LDA	#STDATA
	STA	RXSTATE
	EOR	A		; Reset bit count
	STA	RXBIT
.next4
	INC	RXSAMP		; Next sample at cur+4
.next3
	INC	RXSAMP		; cur + 3
.next2
	INC	RXSAMP		; Cur + 2
.next1
	INC	RXSAMP		; Cur + 1
	RTS
	
	
; Sample the Rx pin into RXSAMP
; 1 for high, 0 for low
; NOTE: If we want to support inverse serial do it in here, and SERTX
SAMPRX	SUBROUTINE
	
	RTS


; Do a Tx sample event
SERTX	SUBROUTINE
	RTS


; Set Tx pin to value in A
SETTX	SUBROUTINE
	
