
;27/08/2025



MCLKOCR	EQU	0FE05H

P_SW2	DATA	0BAH

CLKSEL	EQU	0FE00H
CLKDIV	EQU	0FE01H
HIRCCR	EQU	0FE02H
XOSCCR	EQU	0FE03H
IRC32KCR	EQU	0FE04H

IRCBAND	DATA	09DH
IRTRIM	DATA	09FH
VRTRIM	DATA	0A6H
LIRTRIM	DATA	09EH





AUXR	DATA	08EH

P1M1	DATA	091H
P1M0	DATA	092H
P0M1	DATA	093H
P0M0	DATA	094H
P2M1	DATA	095H
P2M0	DATA	096H
P3M1	DATA	0B1H
P3M0	DATA	0B2H
P4M1	DATA	0B3H
P4M0	DATA	0B4H
P5M1	DATA	0C9H
P5M0	DATA	0CAH

P5	DATA	0C8H


TIM1_OVR	EQU	025H.0
OUT_PORT1	EQU	026H

HEX_CNT1	DATA	2EH
HEX_CNT2	DATA	2FH
TIM0_HI	DATA	30H
TIM0_MID	DATA	31H
TIM0_LO	DATA	32H

TIM1_CNT	DATA	33H

STR_BUF	DATA	34H		;34h+16 ..44h
HEX_BUF	DATA	STR_BUF+3	;HEX_BUF 34/35/36/37
DEC_BUF	DATA	HEX_BUF+5






DEL_CNT1	DATA	47H	;
DEL_CNT2	DATA	48H	;
DEL_CNT3	DATA	49H	;
NUM_CNT	DATA	4AH



;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

RS_1_	MACRO			;definition
	SETB	OUT_PORT1.5
ENDM

RS_0_	MACRO			;definition
	CLR	OUT_PORT1.5
ENDM

E_1_	MACRO			;definition
	SETB	OUT_PORT1.4
ENDM

E_0_	MACRO			;definition
	CLR	OUT_PORT1.4
ENDM


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


BIT_OUT_	MACRO		;definition 
	MOV	P3.5, C
	NOP
	NOP
ENDM

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CLK_595_1_	MACRO		;definition
	SETB	P3.7
ENDM


CLK_595_0_	MACRO		;definition
	CLR	P3.7
ENDM


CLK_595_	MACRO		;definition
	NOP
	SETB	P3.7
	NOP
	CLR	P3.7
	NOP
ENDM
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
STB_595_	MACRO		;definition
	NOP
	SETB	P3.6
	NOP
	CLR	P3.6
	NOP
ENDM
STB_595_0	MACRO		;definition
	CLR	P3.6		;  STB_E_
ENDM
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CLKDIV_0	MACRO		;definition             
	MOV	A, #0
	MOV	DPTR, #CLKDIV
	MOVX	@DPTR, A
ENDM

TGL_BRD	MACRO			;definition             
	CPL	P1.0
ENDM

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 

	ORG	0000H
	LJMP	INIT


;==========================================  tim0
	ORG	000BH
	INC	TIM0_HI
	;TGL_BRD
	RETI


;===========================================  ;tim1
	ORG	001BH

	PUSH	ACC
	PUSH	PSW
	DJNZ	TIM1_CNT, SKIP_TIM1
	CLR	TR0
	CLR	TR1
	SETB	TIM1_OVR
	;TGL_BRD

SKIP_TIM1:

	POP	PSW
	POP	ACC
;	TGL_BRD
	RETI







;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 
	ORG	0100H
INIT:
	MOV	SP, #5FH
	CLR	A

	MOV	P0M0, A
	MOV	P0M1, A
	MOV	P1M0, A
	MOV	P1M1, A
	MOV	P2M0, A
	MOV	P2M1, A
	MOV	P3M0, A
	MOV	P3M1, A
	MOV	P4M0, A
	MOV	P4M1, A
	MOV	P5M0, A
	MOV	P5M1, A



	ACALL	SET_XCLK
	ACALL	CLK_OUT
	ACALL	INIT_LCD_BUS4
	MOV	R7, #080H	; adres pervoy stroki
	ACALL	cmd
	MOV	DPTR, #MSG_FR
	ACALL	send_string_to_lcd


	ACALL	ALL_TIM_GO

	SETB	ET0
	SETB	ET1
	SETB	EA



main_loop:
	JNB	TIM1_OVR, $
	MOV	TIM0_MID, TH0
	MOV	TIM0_LO, TL0

	ACALL	HEX4_TO_DEC10
	;TGL_BRD
	ACALL	ALL_TIM_GO

	SJMP	main_loop


MSG_FR:
	db	'Fmetr.27/08/2025', 0

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  

ALL_TIM_GO:
	;25ms@24.000MHz
	ANL	AUXR, #0BFH	;Timer clock is 12T mode
	MOV	TMOD, #05H	;TIM1-timer/TIM0-counter
	MOV	TL1, #0B0H	;Initial timer value 25ms@24.000MHz
	MOV	TH1, #03CH	;Initial timer value 25ms@24.000MHz
	MOV	TIM0_HI, #0
	MOV	TL0, #0
	MOV	TH0, #0
	MOV	TIM1_CNT, #40	; 40 * 25ms = 1sek
	CLR	TIM1_OVR
	;CLR		TF1
	SETB	TR1
	SETB	TR0
	RET

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 


HEX4_TO_DEC10_test:

	MOV	HEX_BUF, #10H	;HEX--MSB   105affef/HEX = 274399215/DEC
	MOV	HEX_BUF+1, #05Ah
	MOV	HEX_BUF+2, #0ffh
	MOV	HEX_BUF+3, #0efh	;HEX--LSB
	SJMP	HEX4_TO_DEC_11


HEX4_TO_DEC10:
	MOV	HEX_BUF, #0	;HEX-MSB    
	MOV	HEX_BUF+1, TIM0_HI
	MOV	HEX_BUF+2, TIM0_MID
	MOV	HEX_BUF+3, TIM0_LO	;HEX-LSB


HEX4_TO_DEC_11:
	MOV	HEX_CNT1, #32

	CLR	A
	MOV	DEC_BUF, A	; DEC -MSB           
	MOV	DEC_BUF+1, A
	MOV	DEC_BUF+2, A
	MOV	DEC_BUF+3, A
	MOV	DEC_BUF+4, A	; DEC -LSB 

HEX4_TO_DEC_LOOP:

	MOV	R0, #HEX_BUF+3
	MOV	HEX_CNT2, #4
HEX_LOOP1:
	MOV	A, @R0
	RLC	A
	MOV	@R0, A
	DEC	R0
	DJNZ	HEX_CNT2, HEX_LOOP1


	MOV	R0, #DEC_BUF+4
	MOV	HEX_CNT2, #5
HEX_LOOP2:
	MOV	A, @R0
	ADDC	A, @R0
	DA	A
	MOV	@R0, A
	DEC	R0
	DJNZ	HEX_CNT2, HEX_LOOP2
	DJNZ	HEX_CNT1, HEX4_TO_DEC_LOOP
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

DEC10_TO_ACCII:

	MOV	R0, #DEC_BUF
	MOV	R1, #HEX_BUF
	MOV	HEX_CNT1, #5

ACCII_LOOP:
	MOV	A, @R0
	SWAP	A
	ANL	A, #0FH
	ORL	A, #30H
	MOV	@R1, A
	INC	R1
	MOV	A, @R0
	ANL	A, #0FH
	ORL	A, #30H
	MOV	@R1, A
	INC	R0
	INC	R1
	DJNZ	HEX_CNT1, ACCII_LOOP
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

DELL_LEFT_ZERO:

	MOV	R0, #HEX_BUF
	MOV	HEX_CNT1, #10
ZERO_CHANGE_DOT_LOOP:
	MOV	A, @R0
	CJNE	A, #30H, ZERO_CHANGE_OUT
	MOV	A, #'.'
	MOV	@R0, A
	INC	R0
	DJNZ	HEX_CNT1, ZERO_CHANGE_DOT_LOOP
	DEC	R0
	MOV	A, #30H
	MOV	@R0, A

ZERO_CHANGE_OUT:


ADD_CHAR_TO_STRING:
	MOV	STR_BUF, #'F'
	MOV	STR_BUF+1, #'x'
	MOV	STR_BUF+2, #'='
	MOV	STR_BUF+13, #'-'
	MOV	STR_BUF+14, #'H'
	MOV	STR_BUF+15, #'z'


OUT_STING_TO_LCD1602:
	MOV	R7, #0C0H	; adres vtoroy stroki
	ACALL	cmd
buf_to_lcd:

	MOV	R0, #STR_BUF
	MOV	HEX_CNT1, #16

buf_to_lcd_LOOP:
	MOV	A, @R0
	mov	r7, a
	acall	byte_to_lcd
	INC	R0
	DJNZ	HEX_CNT1, buf_to_lcd_LOOP
	RET


;@@@@@@@@  INIT_external high speed crystal oscillator  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

SET_XCLK:
	MOV	P_SW2, #80H
	MOV	A, #0C0H	;Start the external crystal
	MOV	DPTR, #XOSCCR
	MOVX	@DPTR, A
	MOVX	A, @DPTR
	JNB	ACC.0, $-1	;Wait for the clock to stabilize
	CLKDIV_0
	MOV	A, #01H		;Selecting an External Crystal
	MOV	DPTR, #CLKSEL
	MOVX	@DPTR, A
	MOV	P_SW2, #00H
	RET


;@@@@@@@@@@@@  Output the clock signal may divided by 1..127 to port P5.4  for test @@@@@@@@@@@@@@@@@@@@ 

CLK_OUT:
	MOV	P_SW2, #80H
	MOV	A, #10		 
	MOV	DPTR, #MCLKOCR
	MOVX	@DPTR, A
	MOV	P_SW2, #00H
	RET
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       

DEL_20MS:
	ACALL	DEL_5MS
DEL_15MS:
	ACALL	DEL_5MS

DEL_10MS:
	ACALL	DEL_5MS

DEL_5MS:
	MOV	DEL_CNT2, #0
	MOV	DEL_CNT1, #160
	AJMP	DEL_LOOP1









DEL_1MS:

	ACALL	DEL_05MS
DEL_05MS:
	MOV	DEL_CNT2, #0
	MOV	DEL_CNT1, #16
	AJMP	DEL_LOOP1

;
DEL_10US:
	MOV	DEL_CNT2, #26H
	MOV	DEL_CNT1, #1
	AJMP	DEL_LOOP1
;

DEL_5US:
	MOV	DEL_CNT2, #10H
	MOV	DEL_CNT1, #1
	AJMP	DEL_LOOP1
;
DEL_60US:
	MOV	DEL_CNT2, #0FFH
	MOV	DEL_CNT1, #1
	AJMP	DEL_LOOP1
;
DEL_125US:
	MOV	DEL_CNT2, #46H
	MOV	DEL_CNT1, #3
	AJMP	DEL_LOOP1
;
DEL_250US:
	MOV	DEL_CNT2, #32H
	MOV	DEL_CNT1, #5
	AJMP	DEL_LOOP1

DEL_500US:
	MOV	DEL_CNT2, #5
	MOV	DEL_CNT1, #0AH


DEL_LOOP1:
	DJNZ	DEL_CNT2, DEL_LOOP1
	DJNZ	DEL_CNT1, DEL_LOOP1
	RET
;


DEL_1S:
	MOV	DEL_CNT3, #0C8H
DEL_LOOP2:
	ACALL	DEL_5MS
	DJNZ	DEL_CNT3, DEL_LOOP2
	RET


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

INIT_LCD_BUS4:

	CLK_595_0_		;CLK_REG_
	STB_595_0		;  STB_E_
	E_1_
	RS_1_



	LCALL	DEL_20MS
	MOV	r7, #03H
	LCALL	cmd1		 

	LCALL	DEL_10MS
	MOV	r7, #03H
	LCALL	cmd1		 
	LCALL	DEL_1MS

	MOV	r7, #03H	 
	LCALL	cmd1
	LCALL	DEL_1MS
	LCALL	DEL_1MS
	LCALL	DEL_1MS
	LCALL	DEL_1MS
	LCALL	DEL_1MS


	MOV	r7, #02H
	LCALL	cmd1		 
	LCALL	DEL_1MS

	MOV	R7, #028H
	LCALL	cmd		 

	MOV	R7, #08H
	LCALL	cmd		 

	MOV	R7, #01H
	ACALL	cmd		 

	MOV	R7, #06H
	LCALL	cmd		 

	MOV	R7, #0cH
	ACALL	cmd		 

	LCALL	DEL_20MS
	LCALL	DEL_20MS
	LCALL	DEL_20MS
	LCALL	DEL_20MS
	LCALL	DEL_20MS
	LCALL	DEL_20MS
	RET
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



SHIFT_595:

	MOV	A, OUT_PORT1
	ACALL	SEND_595
	STB_595_
	RET

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
SEND_595:
	MOV	r4, #8
SEND_595_LOOP:
	RRC	A
	BIT_OUT_
	CLK_595_
	DJNZ	r4, SEND_595_LOOP
	RET
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

cmd:
	ACALL	cmd3
	LCALL	DEL_1MS
	RET
cmd3:
	MOV	A, R7
	ACALL	cmd2


cmd1:
	MOV	A, R7
	SWAP	A
cmd2:

	RLC	A
	MOV	OUT_PORT1.0, C
	RLC	A
	MOV	OUT_PORT1.1, C
	RLC	A
	MOV	OUT_PORT1.2, C
	RLC	A
	MOV	OUT_PORT1.3, C

	E_1_			; lcd_e        data lcd 7..4 acc.7....4 
	RS_0_			; lcd_rs

	SJMP	byte_to_lcd_out

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

byte_to_lcd:
	ACALL	byte_to_lcd_1
	LCALL	DEL_1MS
	RET


byte_to_lcd_1:
	MOV	A, R7
	ACALL	byte_to_lcd2
byte_to_lcd_11:
	MOV	A, R7
	SWAP	A

byte_to_lcd2:
	RLC	A
	MOV	OUT_PORT1.0, C
	RLC	A
	MOV	OUT_PORT1.1, C
	RLC	A
	MOV	OUT_PORT1.2, C
	RLC	A
	MOV	OUT_PORT1.3, C

	E_1_			; lcd_e        
	RS_1_			; lcd_rs 



byte_to_lcd_out:

	ACALL	SHIFT_595
	E_0_			; e
	ACALL	SHIFT_595
	E_1_			; e
	ACALL	SHIFT_595
	RET

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
send_string_to_lcd:
NEXTBYT:
	clr	a
	movc	A, @A+DPTR
	CJNE	A, #0, NEXTBYT1
	ret
NEXTBYT1:
	mov	r7, a
	acall	byte_to_lcd
	inc	dptr
	sjmp	NEXTBYT


	END

