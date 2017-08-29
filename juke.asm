	include "p16f877.inc"
	
;PORTA, 0: COIN;
;PORTA, 1: GRID1;
;PORTA, 2: GRID2;
;PORTA, 3: GRID4;
;PORTA, 4: GRID3;
;PORTA, 5: GRID5;
;PORTB, 0: SEGD;
;PORTB, 1: SEGC;
;PORTB, 2: SEGG;
;PORTB, 4: SEGF;
;PORTB, 5: SEGE;
;PORTB, 6: SEGA;
;PORTB, 7: SEGB;
;PORTC, 0: SIDE;
;PORTC, 1: ENCODER;
;PORTC, 2: HOME;
;PORTC, 3: SCAN;
;PORTC, 4: B1;
;PORTC, 5: DEBUG;
;PORTD, 0: RUN;
;PORTD, 1: STOP;
;PORTD, 2: B2;
;PORTD, 3: B3;
;PORTD, 4: NOWLED;
;PORTD, 5: YOURLED;
;PORTD, 6: RESETLED;
;PORTD, 7: ADDLED;
;PORTE, 0: KBD1;
;PORTE, 1: KBD2;
;PORTE, 2: KBD3;


m	equ	0x21
n	equ	0x22
grid	equ	0x23
disp	equ	0x24
credits	equ	0x29
umode	equ	0x2a
key	equ	0x2b
keycnt	equ	0x2c
dig1	equ	0x2d
dig2	equ	0x2e
dig3	equ	0x2f
mmode	equ	0x30
queue	equ	0x31
cpos	equ	0x32
side	equ	0x33
count	equ	0x34
playdly	equ	0x35
coincnt equ	0x36
npdig1	equ	0x37
npdig2	equ	0x38
npdig3	equ	0x39
playing	equ	0x3a
l	equ	0x3b
qfront	equ	0x3c
qback	equ	0x3d
qnum	equ	0x3e
cpos_p	equ	0x3f
side_p	equ	0x40
cpos_t	equ	0x41
side_t	equ	0x42
wait	equ	0x42
wait_l	equ	0x43
cpos_tm	equ	0x44
gotchar	equ	0x45

;	goto	start
	
start	bcf	STATUS, RP1	; bank 1
	bsf	STATUS, RP0
	
	movlw	B'00000111'	; initialise the ports
	movwf	ADCON1
	movlw	B'00000001'
	movwf	TRISA
	movlw	B'00000000'
	movwf	TRISB
	movlw	B'11011111'
	movwf	TRISC	
	movlw	B'00001100'
	movwf	TRISD
	movlw	B'00000111'
	movwf	TRISE

	call	init_uart
	
	bcf	STATUS, RP0	; bank 0
	movlw	B'11111101'	; select the first grid
	movwf	grid

	movlw	B'11110000'	; leds???
	movwf	PORTD
	
	clrf	credits		; no credits at startup
	call	dispcreds

	clrf	keycnt		; initialise status vars
	bsf	key, 7
	clrf	umode
	clrf	mmode
	clrf	queue
	clrf	playdly
	clrf	coincnt
	clrf	playing
	clrf	qnum
	clrf	wait
	movlw	0xa0
	movwf	qfront
	movwf	qback

	movlw	0xff		; clear the displays
	movwf	disp+2
	movwf	disp+3
	movwf	disp+4	

	bsf	PORTC, 5	; signal proc alive.
main	
	movlw	0xff		; clear the segs before changing grid.
	movwf	PORTB

	rlf	grid, F		; switch grids.
	bsf	grid, 1
	btfss	grid, 6
	bcf	grid, 1
	bcf	grid, 0
	movf	grid, W
	movwf	PORTA

	btfss	grid, 1		; emit the corret number for this grid
	movf	disp, W
	btfss	grid, 2
	movf	disp+1, W
	btfss	grid, 3
	movf	disp+3, W
	btfss	grid, 4
	movf	disp+2, W
	btfss	grid, 5
	movf	disp+4, W

	movwf	PORTB

	bsf	key, 7		; ????
	call	getkey

;	movf	umode, W
;	movwf	credits
;	call	dispcreds

	incf	umode, F	; if umode == 0 : idle
	decfsz	umode, F
	goto	umoden0

	incf	credits, F	; if credits
	decfsz	credits, F
	incf	umode, F
umoden0

	movlw	0x00		; accept money, debug and add credits.
	subwf	credits, W
	btfsc	STATUS, Z
	bcf	PORTD, 7	

	movlw	0x00
	subwf	coincnt, W
	btfss	STATUS, Z
	decf	coincnt, F
	btfss	PORTA, 0   
	goto	nocoin
	movlw	0x00
	subwf	coincnt, W
	btfsc	STATUS, Z
	incf	credits, F
	movlw	0xfe
	movwf	coincnt
	bsf	PORTD, 7
	call	dispcreds
nocoin

chkscan	btfsc	PORTC, 3	; deal with the scan lever
	goto	noscan
	btfss	PORTC, 2
	bsf	PORTD, 0
	btfsc	PORTC, 2
	bcf	PORTD, 0
	goto	chkscan
noscan

	movlw	0x01
	subwf	umode, W	; if umode == 1 : just got money.
	btfss	STATUS, Z
	goto	umoden1
	bcf	PORTD, 5	; change some lights
	bsf	PORTD, 6
	movlw	0xff		; set disp to dash-blank-blank
	movwf	disp+3
	movwf	disp+4
	movlw	0xfe
	movwf	disp+2
	btfsc	key, 7		; check for key.
	goto	umoden1
	movlw	0x0a		; check if reset.
	subwf	key, W
	btfss	STATUS, Z
	goto	d1nr
	movlw	0x01
	movwf	umode
	goto	umoden1
d1nr	movf	key, W		; save and copy to display
	movwf	dig1
	PAGESEL	segs
	call	segs
	movwf	disp+2	
	movlw	0x03		; check for key validity
	subwf	key, W
	btfss	STATUS, C
	goto	dig1lt3
	movlw	0x04
	movwf	umode
	goto	dig1bad
dig1lt3	movlw	0x00		; can't have zero either.
	subwf	key, W
	btfss	STATUS, Z
	goto	dig1ok
	movlw	0x04
	movwf	umode
	goto	dig1bad
dig1ok	incf	umode, F	; a ok
dig1bad	bsf	key, 7
umoden1

	movlw	0x02
	subwf	umode, W	; if umode == 2 : second digit.
	btfss	STATUS, Z
	goto	umoden2
	movlw	0xfe		; dash second digit
	movwf	disp+3
	btfsc	key, 7
	goto	umoden2
	movlw	0x0a		; reset ?
	subwf	key, W
	btfss	STATUS, Z
	goto	d2nr
	movlw	0x01
	movwf	umode
	goto	umoden2
d2nr	movf	key, W		; save digit and update display
	movwf	dig2
	PAGESEL	segs
	call	segs
	movwf	disp+3
	bsf	key, 7	
	incf	umode, F
umoden2

	movlw	0x03
	subwf	umode, W	; if umode == 3 : third digit.
	btfss	STATUS, Z
	goto	umoden3
	movlw	0xfe		; dash third digit
	movwf	disp+4
	btfsc	key, 7
	goto	umoden3
	movlw	0x0a		; reset?
	subwf	key, W
	btfss	STATUS, Z
	goto	d3nr
	movlw	0x01
	movwf	umode
	goto	umoden3
d3nr	movf	key, W		; save digit and update disp
	movwf	dig3
	PAGESEL	segs
	call	segs
	movwf	disp+4
	movlw	0x08		; check for validity
	subwf	key, W
	btfss	STATUS, C
	goto	dig3lt8
	movlw	0x04
	movwf	umode
	bsf	key, 7
	goto	umoden3
dig3lt8	bsf	key, 7		; valid: process data
	movlw	0x05
	movwf	umode
umoden3

	movlw	0x05
	subwf	umode, W	; if umode == 5 : "show selected"
	btfss	STATUS, Z
	goto	umoden5
	btfsc	key, 7		; see if reset pressed
	goto	tnor
	movlw	0x0a		; reset ?
	subwf	key, W 
	btfss	STATUS, Z
	goto	tnor
	clrf	wait
	movlw	0x01		; back to first digit.
	movwf	umode
	bsf	key, 7
tnor	movlw	0x00		; if wait is zero set the timer.
	subwf	wait, W
	btfss	STATUS, Z
	goto	chkwait
	movlw	0x0a
	movwf	wait
	movlw	0xff
	movwf	wait_l
chkwait	movlw	0x01		; if wait is 1 then stop waiting
	subwf	wait, W		
	btfss	STATUS, Z
	goto	decwait
	movlw	0x06
	movwf	umode
	clrf	wait
decwait	decfsz	wait_l, F
	goto	umoden5
	decf	wait, F
	movlw	0xff
	movwf	wait_l
umoden5

	movlw	0x06
	subwf	umode, W	; if umode == 6 : "process data"
	btfss	STATUS, Z
	goto	umoden6
	call	calcpos
	call	q_add
	movlw	0x00		; get q imediately if nothing in q
	subwf	queue, W
	btfsc	STATUS, Z
	call	q_get
	;bsf	queue, 0
	incf	queue, F
	decf	credits, F
	call	dispcreds
	bsf	PORTD, 5	; play with leds
	clrf	umode		; wash rinse REPEAT.
	movlw	0xff		; clear the display
	movwf	disp+2
	movwf	disp+3
	movwf	disp+4
	btfsc	playing, 0	; if we are playing better switch back to displaying the current record.
	bcf	PORTD, 6
	btfsc	playing, 0
	call	dispnp
umoden6

	movlw	0x04
	subwf	umode, W	; if umode == 4 : "press reset"
	btfss	STATUS, Z
	goto	umoden4
	bcf	PORTD, 4	; reset light on
	btfsc	key, 7
	goto	umoden4
	movlw	0x0a		; reset ?
	subwf	key, W 
	btfss	STATUS, Z
	goto	noreset
	bsf	PORTD, 4	; lamp off
	movlw	0x01		; back to first digit.
	movwf	umode
noreset	bsf	key, 7	
umoden4

	movlw	0x00
	subwf	mmode, W	; if mmode == 0 : rolling
	btfss	STATUS, Z
	goto	mmoden0
	btfss	PORTC, 2	; we're at home
	incf	mmode, F
mmoden0

	movlw	0x01
	subwf	mmode, W	; if mmode == 1 : at home
	btfss	STATUS, Z
	goto	mmoden1
	;;bcf	PORTC, 5	; debug led
	;;;call	dispcreds
	movlw	0x00		; is stuff in queue?
	subwf	queue, W
	btfsc	STATUS, Z
	goto	mmoden1
	incf	mmode, F
	clrf	count
mmoden1

	movlw	0x02
	subwf	mmode, W	; if mmode == 2 : get go
	btfss	STATUS, Z
	goto	mmoden2
	bsf	PORTD, 0	; go go go
	btfsc	PORTC, 2
	bcf	PORTD, 0
	btfsc	PORTC, 2
	incf	mmode, F
mmoden2

	movlw	0x03
	subwf	mmode, W	; if mmode == 3 : waiting for next record
	btfss	STATUS, Z
	goto	mmoden3
	btfsc	PORTC, 2
	goto	nothome
	movlw	0x01		; at home -> mode 1
	movwf	mmode
	goto	mmoden3
nothome	btfsc	PORTC, 1	; are we by a record
	goto	mmoden3
	btfss	playing, 0	; clear displays if we were playing a previous record
	goto	notplay
	clrf	playing
	bsf	PORTD, 6
	movlw	0xff		; clear display
	movwf	disp+2
	movwf	disp+3
	movwf	disp+4
notplay	incf	count, F
	movf	count, W	; if count == cpos ie. if this is the right position/
	subwf	cpos_p, W
	btfss	STATUS, Z
	goto	notequ
	;;bsf	PORTC, 5	; debug
;	goto	pequ
	btfss	side_p, 0		; if side == A/B
	goto	side0
	btfsc	PORTC, 0
	goto	pequ
	goto	notequ
side0	btfsc	PORTC, 0
	goto	notequ
pequ	incf	mmode, F	; thats us, lets play
	goto	mmoden3
notequ	movlw	0x06
	movwf	mmode
mmoden3

	movlw	0x04
	subwf	mmode, W	; if mmode == 4 : play the record.
	btfss	STATUS, Z
	goto	mmoden4
	;movf	dig1, W		; update now playing digits.
	;movwf	npdig1
	;movf	dig2, W
	;movwf	npdig2
	;movf	dig3, W
	;movwf	npdig3
	call	calcnp
	movlw	0x00		; if we still have credits then don't display now playing.
	subwf	credits, W
	btfss	STATUS, Z
	goto	norp
	bcf	PORTD, 6
	call	dispnp
norp	
	;clrf	queue		; no queue
	movlw	0x01		; set playing flag
	movwf	playing
	decf	playdly, F	; send a short 'play' pulse. (no way of checking if the micro-switch has dropped out so just send it for a while)
	bsf	PORTD, 1
	movlw	0x00
	subwf	playdly, W
	btfss	STATUS, Z
	goto	skipdly
	movlw	0xff
	movwf	playdly
skipdly	movlw	0x01
	subwf	playdly, W
	btfsc	STATUS, Z
	incf	mmode, F
mmoden4

	movlw	0x05
	subwf	mmode, W	; if mmode == 5 : pickup triggered - stop it
	btfss	STATUS, Z	
	goto	mmoden5
	decf	queue, F	; less in queue
	movlw	0x00		; get next record from queue
	subwf	queue, W
	btfss	STATUS, Z
	call	q_get
	bcf	PORTD, 1	; stop it
	incf	mmode, F
mmoden5

	movlw	0x06
	subwf	mmode, W	; if mmode == 6 : record playing.
	btfss	STATUS, Z
	goto	mmoden6
	btfss	PORTC, 1	; wait for record to finish.
	goto	mmoden6
	movlw	0x03		; go back to watching the records pass.
	movwf	mmode
mmoden6

	;call	getchar_poll	; check the serial port.
; Don't do this for now as it seems to cause random record selections occasionally (noise on the line??).

	;call	send_np		; let the PC know what record is playing now.

	movlw	0x01		; have a short wait.
	call	delay
	goto	main		; do it all again.

endloop	goto	endloop		; Oh what are you doing here??

getkey	movlw	0x00		; see which grid is on
	btfss	grid, 2
	movlw	0x00
	btfss	grid, 3
	movlw	0x01
	btfss	grid, 4
	movlw	0x02
	btfss	grid, 5
	movlw	0x03
	btfss	PORTE, 0	; and see what circuit is complete
	iorlw	0x04
	btfss	PORTE, 1
	iorlw	0x08
	btfss	PORTE, 2
	iorlw	0x0c
	PAGESEL	keys		; map this value to a key
	call	keys
	movwf	n
	btfsc	n, 7		; check if this is a valid keypress
	goto	nopress		; isn't
	incf	keycnt, F	; save the key??????
	decfsz	keycnt, F
	goto 	kcnz
	movf	n, W
	movwf	key
kcnz	movlw	0xf0
	movwf	keycnt

nopress
	decf	keycnt, F
	movlw	0xff
	subwf	keycnt, W
	btfsc	STATUS, Z
	incf	keycnt, F
	return

calcpos	movf	dig3, W		; figure out what pos in the carousel a 3 digit record lies.
	movwf	cpos
	bcf	STATUS, C
	rlf	cpos, F
	rlf	cpos, F
	rlf	cpos, F
	addwf	cpos, F
	addwf	dig2, W
	addwf	cpos, F
	incf	cpos, F
	clrf	side
	btfsc	dig1, 0
	bsf	side, 0
	return
	
calcnp	movf	cpos_p, W	; Calculate the digits for the record which record is now playing
	movwf	cpos_tm
	movlw	0x01
	movwf	npdig1
	clrf	npdig3
	btfss	side_p, 0
	incf	npdig1, F
	movlw	0x0a
nextten	subwf	cpos_tm, F
	btfss	STATUS, C
	goto	below
	btfsc	STATUS, Z
	goto	below
	incf	npdig3, F
	goto	nextten
below	decf	cpos_tm, F
	movf	cpos_tm, W
	addlw	0x0a
	movwf	npdig2
	return
	
dispnp	movf	npdig1, W	; display the record that is now playing.
	PAGESEL	segs
	call	segs
	movwf	disp+2
	movf	npdig2, W
	PAGESEL	segs
	call	segs
	movwf	disp+3
	movf	npdig3, W
	PAGESEL	segs
	call	segs
	movwf	disp+4
	return

dispcreds			; display the number of credits remaining
	clrf	m
	movf	credits, W
	;movf	queue, W
	movwf	n
	movlw	0x0a
dcloop	incf	m, F
	subwf	n, F
	btfsc	STATUS, C
	goto	dcloop
	addwf	n, W
	PAGESEL	segs
	call	segs
	movwf	disp+1
	decf	m, W
	PAGESEL	segs
	call	segs
	movwf	disp
	retlw	0

delay	movlw	0x01		; wait a while (depending on w)
	movwf	n
delay_m	movlw	0xff
	movwf	m
	decfsz	m, f
	goto	$-1
	decfsz	n, f
	goto	delay_m
	retlw	0
	
q_add	btfsc	side, 0		; set 7th bit as side
	bsf	cpos, 7
	movf	cpos, W
	
	bcf	STATUS, IRP	; put cpos in place pointed by qback
	movf	qback, W
	movwf	FSR
	movf	cpos, W
	movwf	INDF
	
	incf	qback, F
	movlw	0x00		; if qback 0 then wrap
	subwf	qback, W	
	btfss	STATUS, Z
	return
	movlw	0xa0
	movwf	qback
	return
	
q_get	bcf	STATUS, IRP	; get cpos_p from place pointed by qfront
	movf	qfront, W
	movwf	FSR
	movf	INDF, W
	movwf	cpos_p
	
	clrf	side_p		; set side if needed
	btfsc	cpos_p, 7
	bsf	side_p, 0
	bcf	cpos_p, 7

	incf	qfront, F
	movlw	0x00		; if qfront 0 then wrap
	subwf	qfront, W	
	btfss	STATUS, Z
	goto	calc
	movlw	0xa0
	movwf	qfront
calc	
	return
	
getchar_poll
	bcf	STATUS, RP0	;bank 0
	bcf	STATUS, RP1

	btfsc	RCSTA, OERR	;overrun error - clear buffers and reset if detected
	goto	getchar_poll_oerr

	btfss	PIR1, RCIF	; comms interrupt - is there a byte waiting for me to read
	return			
	
	btfsc	RCSTA, FERR	; framing error - this byte should be discarded
	goto	getchar_poll_ferr

	movf	RCREG, W
	movwf	gotchar		
	movwf	cpos		;get carousel posn.
	bcf	cpos, 7
	movlw	D'81'		;bail if out of range
	subwf	cpos, W
	btfsc	STATUS, C
	return
	clrf	side		;set up side variable
	btfsc	gotchar, 7
	bsf	side, 0
	call	q_add
	movlw	0x00		;get q imediately if nothing in q
	subwf	queue, W
	btfsc	STATUS, Z
	call	q_get
	incf	queue, F
	return

getchar_poll_oerr	
	bcf	RCSTA, CREN
	movf	RCREG, W
	movf	RCREG, W
	bsf	RCSTA, CREN
	return

getchar_poll_ferr
	movf	RCREG, W	; read and discard the invalid byte
	return

send_np
	movlw	'F'
	BANKSEL PIR1
	btfss	PIR1, TXIF		; check if we have sent the previous char
	return
	BANKSEL TXREG
	movwf	TXREG
	return	

init_uart
	bsf	STATUS, RP0	;bank 1
	bcf	STATUS, RP1
	bsf	TXSTA, BRGH	;baud rate = 9600
	movlw	D'25'
	movwf	SPBRG
	bcf	TXSTA, SYNC	;async serial mode
	bcf	STATUS, RP0	;bank 0
	bsf	RCSTA, SPEN	;enable serial port
	bsf	RCSTA, CREN	;enable reception
	bsf	STATUS, RP0	;bank 1
	bsf	TXSTA, TXEN	;enable transmission
	bcf	STATUS, RP0	;bank 0
	movf	RCREG, W
	movf	RCREG, W
	;bsf	INTCON, PEIE	;enable interupts
	;bsf	INTCON, GIE
	;bsf	PIE1, TXIE	;enable TX interrupt
	;bsf	PIE1, RCIE	;enable RC interrupt
	return
	

	org	0x300

keys	movwf	l		; map scancodes to key legend.
	movlw	HIGH keys
	movwf	PCLATH
	movf	l, W
	addwf	PCL, F
	retlw	0xfa
	retlw	0xfb
	retlw	0xfc
	retlw	0xfd
	retlw	0x00 
	retlw	0x03
	retlw	0x05
	retlw	0x08
	retlw	0x01
	retlw	0x04
	retlw	0x06
	retlw	0x09
	retlw	0x02
	retlw	0xfe
	retlw	0x07
	retlw	0x0a


segs	movwf	l		; map numbers to seven seg 
	movlw	HIGH segs
	movwf	PCLATH
	movf	l, W
	addwf	PCL, F
	retlw	0x01
	retlw	0xe5
	retlw	0x22
	retlw	0xa0
	retlw	0xc4
	retlw	0x90
	retlw	0x10
	retlw	0xc1
	retlw	0x00
	retlw	0x80
	retlw	0x40
	retlw	0x14
	retlw	0x13	
	retlw	0x24
	retlw	0x12
	retlw	0x52

	end
