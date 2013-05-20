;
; Digital Key Lock
;
; @author Akeda Bagus <admin@gedex.web.id>
; @copyright 2006
; @license MIT
;

;##########################
; Keypad's vars           #
;##########################
kunci equ 20h   ; secret code
keypad equ 40h

;##########################
; LCD's vars              #
;##########################
DB0 EQU 0B0h    ; P3.0
DB1 EQU 0B1h    ; P3.1
DB2 EQU 0B2h    ; P3.2
DB3 EQU 0B3h    ; P3.3
DB4 EQU 0B4h    ; P3.4
DB5 EQU 0B5h    ; P3.5
DB6 EQU 0B6h    ; P3.6
DB7 EQU 0B7h    ; P3.7
LCD_EN EQU 0A7h ; P2.7
LCD_RW EQU 0A6h ; P2.6
LCD_RS EQU 0A5h ; P2.5
DATA EQU 0B0h

;##########################
; OUTPUT INDICATOR        #
;##########################
LED_red EQU p2.0
LED_green EQU p2.1
LED_yellow EQU p2.2
BUZZER EQU p2.4
OUTPUT EQU P2

;##########################
; log invalid code        #
;##########################
timesInv EQU 50h
limitInv EQU 51h

org 0

;##########################
;# Main Program           #
;##########################
begin:
	MOV timesInv,#0   ; banyaknya salah kode awal = 0
	MOV limitInv,#3   ; batas salah kode = 3
	MOV kunci,#0B7h   ; digit ke-1 => 1
	MOV kunci+1,#0E7h ; digit ke-2 => 3
	MOV kunci+2,#0DEh ; digit ke-3 => 0
	MOV kunci+3,#0BDh ; digit ke-4 => 7
	MOV kunci+4,#0DDh ; digit ke-5 => 8
	MOV kunci+5,#0BBh ; digit ke-6 => 4
	LCALL INITIALIZE  ; Inisisalisasi LCD

mulai:
	LCALL CLEAR_SCREEN
	MOV OUTPUT, #0FFH
	MOV p0, #0FFH
	MOV A,#80H
	LCALL ADDRESS
	MOV dptr,#kal1     ; Kunci Digital v1' @1st row
	LCALL TRANSFER
	MOV A,#0C0H
	LCALL ADDRESS      ; By : Akeda Bagus' @2nd row
	MOV dptr,#kal2
	LCALL TRANSFER
	LCALL delay_1s     ; tahan 2 detik
	LCALL delay_1s
	LCALL CLEAR_SCREEN ; layar bersih
	MOV A,#80H
	LCALL ADDRESS
	MOV dptr,#kal3     ; --------------- @1st row
	LCALL TRANSFER
	MOV A,#0C0H
	LCALL ADDRESS      ; Please press # @2nd row
	MOV dptr,#kal4
	LCALL TRANSFER

requestIn: ; minta ditekan '#' dulu..
	LCALL ambilData
	CJNE A,#0EEh,requestIn

modeRequest:
	LCALL inKode ;input 6 Kode

;######################################################
; CHECK EACH DIGIT
;
; Setiap digit yang disimpan di RAM (symbol directive
: keypad), akan dicek. Apabila digit ke-1 sudah salah,
; maka langsung gagal, bila benar lanjut ke digit ke-2.
; Bila digit ke-2 salah, langsung gagal. Demikian
; seterusnya sampai 6 digit.
;######################################################
cekPasswd1:
	MOV A,keypad
	CJNE A,kunci,gagal
cekPasswd2:
	MOV A,keypad+1
	CJNE A,kunci+1,gagal
cekPasswd3:
	MOV A,keypad+2
	CJNE A,kunci+2,gagal
cekPasswd4:
	MOV A,keypad+3
	CJNE A,kunci+3,gagal
cekPasswd5:
	MOV A,keypad+4
	CJNE A,kunci+4,gagal
cekPasswd6:
	MOV A,keypad+5
	CJNE A,kunci+5,gagal

sjmp modeValid ; ke-6 digit valid, masuk mode valid
gagal:
	LJMP gagal_  ; digit invalid

;##########################
; MODE VALID              #
;##########################
modeValid:
	CLR LED_yellow
	LCALL CLEAR_SCREEN
	LCALL CURSOR_OFF
	MOV A,#80h
	LCALL ADDRESS
	MOV dptr,#kal6
	LCALL TRANSFER
	LCALL delay_1s
	MOV A,#0C0h
	LCALL ADDRESS
	MOV dptr,#kal7
	LCALL TRANSFER
	LCALL delay_1s
	LCALL CLEAR_SCREEN
	MOV A,#80h
	LCALL ADDRESS
	MOV dptr,#kal8 ; 1. Buka kunci
	LCALL TRANSFER
	MOV A,#0C0h
	LCALL ADDRESS
	MOV dptr,#kal9 ; 2. Ganti kode
	LCALL TRANSFER

pilih1or2:
	LCALL ambilData
	CJNE A,#0B7h,apa2      ; klo bukan '1', cek tombol '2'
	SJMP pilih1            ; berarti pilih '1'
apa2:
	CJNE A,#0D7h,pilih1or2 ; bukan '1'or '2'
	; cek truz
	SJMP pilih2            ; klo '2' loncat ke pilih2

;##########################
; Kunci terbuka           #
;##########################
pilih1:
	LCALL CLEAR_SCREEN
	MOV A,#80h
	LCALL ADDRESS
	MOV dptr, #kal10 ; Kunci terbuka!!
	LCALL TRANSFER
	MOV A,#0C0h
	LCALL ADDRESS
	MOV dptr, #kal11 ; Closed after xs
	LCALL TRANSFER
	MOV r7, #09h     ; 9 detik redirect
	LCALL COUNT_DOWN
	LJMP mulai

;##########################
; Request new code        #
;##########################
pilih2:
	LCALL inKode
	MOV kunci,keypad
	MOV kunci+1,keypad+1
	MOV kunci+2,keypad+2
	MOV kunci+3,keypad+3
	MOV kunci+4,keypad+4
	MOV kunci+5,keypad+5
	LCALL CLEAR_SCREEN
	MOV A,#80h
	LCALL ADDRESS
	MOV dptr, #kal14
	LCALL TRANSFER
	LCALL delay_1s
	LJMP mulai

;##########################
; MODE INVALID            #
;##########################
gagal_:
	INC timesInv
	MOV A, timesInv
	CJNE A, limitInv, mshBisa
	SJMP gagal_total

mshBisa:
	CLR BUZZER
	LCALL CLEAR_SCREEN
	LCALL CURSOR_OFF
	MOV A,#80h
	LCALL ADDRESS
	MOV dptr,#kal12  ; Kode salah..!!
	LCALL TRANSFER
	MOV A,#0C0h
	LCALL ADDRESS
	MOV dptr, #kal13 ; kembali setelah x s
	LCALL TRANSFER
	MOV r7, #05h     ; 9 detik redirect
	LCALL COUNT_DOWN2
	LJMP mulai

;##########################
; INVALID 3x !!           #
;                         #
; scrolling display       #
; dan tunggu ~1 menit     #
;##########################
gagal_total:
	CLR timesInv    ; hapus log invalid
	CLR BUZZER
	LCALL CLEAR_SCREEN
	LCALL CURSOR_OFF
	MOV A,#0C0h
	LCALL ADDRESS
	MOV dptr, #kal15 ; Salah xX 2nd row
	LCALL TRANSFER
	MOV A, #0CEh
	LCALL ADDRESS
	MOV A, limitInv
	ADD A,#30h
	LCALL WRITE_ON
	LCALL delay_1s
	LCALL delay_1s
	LCALL CLEAR_SCREEN
	MOV A,#80h
	LCALL ADDRESS
	MOV dptr, #kal15 ; Salah xX 1st row
	LCALL TRANSFER
	MOV A, #8Eh
	LCALL ADDRESS
	MOV A, limitInv
	ADD A,#30h
	LCALL WRITE_ON
	MOV A,#0C0h
	LCALL ADDRESS
	MOV dptr, #kal16 ; Lupa or Maling? 2nd row
	LCALL TRANSFER
	LCALL delay_1s
	LCALL delay_1s
	LCALL CLEAR_SCREEN
	MOV A,#80h
	LCALL ADDRESS
	MOV dptr, #kal16 ; Lupa or Maling? 1st row
	LCALL TRANSFER
	MOV A,#0C0h
	LCALL ADDRESS
	MOV dptr, #kal17 ; Tunggu 1 menit 2nd row
	LCALL TRANSFER
wait1men:
	MOV r7, #60      ; 60 x 1s
wait1men_:
	MOV r6, #10      ; 100ms x 10 = 1s
wait1men2:
	MOV A, #100      ; 100ms
	LCALL delay_Xms
	djnz r6, wait1men2
	djnz r7, wait1men_
	LJMP mulai

;##########################
; END OF MAIN PROGRAM     #
;##########################

;##########################
; KUMPULAN RUTIN          #
;##########################
; Rutin LCD
INITIALIZE:
	SETB LCD_EN
	CLR LCD_RW
	CLR LCD_RS
	MOV DATA,#00110000B
	CLR LCD_EN
	LCALL DELAY1
	SETB LCD_EN
	CLR LCD_RW
	CLR LCD_RS
	MOV DATA,#00110000B
	CLR LCD_EN
	LCALL DELAY1
	SETB LCD_EN
	CLR LCD_RW
	CLR LCD_RS
	MOV DATA,#00110000B
	CLR LCD_EN
	LCALL DELAY1
	SETB LCD_EN
	CLR LCD_RW
	CLR LCD_RS
	MOV DATA,#00111000B
	CLR LCD_EN
	LCALL DELAY1
	SETB LCD_EN
	CLR LCD_RW
	CLR LCD_RS
	MOV DATA,#00001100B
	CLR LCD_EN
	LCALL DELAY1
	SETB LCD_EN
	CLR LCD_RW
	CLR LCD_RS
	MOV DATA,#00000110B
	CLR LCD_EN
	LCALL DELAY1
	RET
CURSOR_BLINK:
	MOV A,#0FH
	LCALL COMMAND
	RET
CURSOR_OFF:
	MOV A,#0CH
	LCALL COMMAND
	RET
CURSOR_CUSTOM:
	MOV A,#0C0H
	LCALL COMMAND
	RET
SHIFT_LEFT_SCREEN:
	MOV A,#18H
	LCALL COMMAND
	RET
SHIFT_RIGHT_SCREEN:
	MOV A,#1CH
	LCALL COMMAND
	RET
COMMAND:
	MOV DATA,A
	SETB LCD_EN
	CLR LCD_RW
	CLR LCD_RS
	LCALL DELAY0
	CLR LCD_EN
	LCALL DELAY0
	RET
CLEAR_SCREEN:
	SETB LCD_EN
	CLR LCD_RS
	CLR LCD_RW
	MOV DATA,#00000001B
	LCALL DELAY0
	CLR LCD_EN
	LCALL DELAY0
	RET
ADDRESS:
	SETB LCD_EN
	CLR LCD_RW
	CLR LCD_RS
	MOV DATA,A
	LCALL DELAY0
	CLR LCD_EN
	LCALL DELAY0
	RET
WRITE_ON:
	MOV DATA,A
	SETB LCD_EN
	CLR LCD_RW
	SETB LCD_RS
	LCALL DELAY0
	CLR LCD_EN
	LCALL DELAY0
	LCALL DELAY0
	RET
TRANSFER:
	CLR A
	MOVC A,@A+DPTR
	INC DPTR
	CJNE A,#0FFH,TRANS
	LJMP EXIT3
TRANS:
	MOV DATA,A
	LCALL WRITE_ON
	LJMP TRANSFER
EXIT3:
	RET
DELAY0:
	PUSH 7
	MOV R7,#1
SUB_DELAY:
	MOV TMOD,#00000001B
	MOV TH0,#0FCH
	MOV TL0,#00H
	SETB TR0
TF0?:
	JNB TF0,TF0?
	CLR TR0
	CLR TF0
	DJNZ R7,SUB_DELAY
	POP 7
	RET
DELAY1:
	PUSH 7
	MOV R7,#1
SUB_DELAY1Z:
	MOV TMOD,#00000001B
	MOV TH0,#0A0H
	MOV TL0,#00H
	SETB TR0
TF0??:
	JNB TF0,TF0??
	CLR TR0
	CLR TF0
	DJNZ R7,SUB_DELAY1Z
	POP 7
	RET
COUNT_DOWN:
	CLR LED_green
	MOV A,#0CDh
	LCALL ADDRESS
	MOV A,R7
	ADD A,#30h
	LCALL WRITE_ON
	SETB LED_green
	LCALL delay_1s
	djnz r7,COUNT_DOWN
	RET
COUNT_DOWN2:
	CLR LED_red
	MOV A,#0CDh
	LCALL ADDRESS
	MOV A,R7
	ADD A,#30h
	LCALL WRITE_ON
	SETB LED_red
	LCALL delay_1s
	djnz r7,COUNT_DOWN2
	RET

; Rutin keypad
inKode:
	LCALL CLEAR_SCREEN ; bersihkan layar
	MOV A,#80h
	LCALL ADDRESS
	MOV dptr,#kal5     ; Masukkan Password :
	LCALL TRANSFER
	MOV A,#0C0H
	LCALL ADDRESS
	LCALL delay_1s
	LCALL CURSOR_BLINK ; Aktifkan kursor blink

passwd1:             ; digit ke-1
	LCALL ambilData
	CJNE A, #0BEh, pass1
	CLR BUZZER
	LCALL DELAY0
	SETB BUZZER
	SJMP passwd1
pass1:               ; digit ke-1 bukan '*'
	MOV keypad, A
	MOV A,#0C0h
	LCALL ADDRESS
	MOV A,#'*'
	LCALL WRITE_ON
	MOV A, #50
	ACALL delay_Xms    ; 50ms

passwd2:             ; digit ke-2
	LCALL ambilData
	CJNE A, #0BEh, pass2
	MOV A,#0C0H
	LCALL ADDRESS
	MOV A,#' '
	LCALL WRITE_ON
	MOV A,#0C0H
	LCALL ADDRESS
	SJMP passwd1
pass2:               ; digit ke-2 bukan '*'
	MOV keypad+1,A
	MOV A,#'*'
	LCALL WRITE_ON
	MOV A, #50
	ACALL delay_Xms    ; 50ms

passwd3:             ; digit ke-3
	LCALL ambilData
	CJNE A, #0BEH, pass3
	MOV A, #0C1H
	LCALL ADDRESS
	MOV A,#' '
	LCALL WRITE_ON
	MOV A, #0C1H
	LCALL ADDRESS
	SJMP passwd2
pass3:               ; digit ke-3 bukan '*'
	MOV keypad+2,A
	MOV A,#'*'
	LCALL WRITE_ON
	MOV A, #50
	ACALL delay_Xms    ; 50ms

passwd4:             ; digit ke-4
	LCALL ambilData
	CJNE A, #0BEH, pass4
	MOV A,#0C2H
	LCALL ADDRESS
	MOV A,#' '
	LCALL WRITE_ON
	MOV A,#0C2H
	LCALL ADDRESS
	SJMP passwd3
pass4:               ; digit ke-4 bukan '*'
	MOV keypad+3,A
	MOV A, #'*'
	LCALL WRITE_ON
	MOV A, #50
	ACALL delay_Xms    ; 50ms

passwd5:             ; digit ke-5
	LCALL ambilData
	CJNE A, #0BEh, pass5
	MOV A,#0C3H
	LCALL ADDRESS
	MOV A,#' '
	LCALL WRITE_ON
	MOV A,#0C3H
	LCALL ADDRESS
	SJMP passwd4
pass5:               ; digit ke-5 bukan '*'
	MOV keypad+4,A
	MOV A, #'*'
	LCALL WRITE_ON
	MOV A, #50
	ACALL delay_Xms    ; 50ms

passwd6: ;digit ke-6
	LCALL ambilData
	CJNE A, #0BEH, pass6
	MOV A,#0C4H
	LCALL ADDRESS
	MOV A,#' '
	LCALL WRITE_ON
	MOV A,#0C4H
	LCALL ADDRESS
	sjmp passwd5
pass6:               ; digit ke-6 bukan '*'
	MOV keypad+5,A
	MOV A, #'*'
	LCALL WRITE_ON
	RET

ambilData:
	MOV p0, #0FFH
datapad:
	MOV A, #50 ;50ms
	ACALL delay_Xms
	CLR A
	MOV A, p0
	PUSH ACC
	MOV A, #50
	ACALL delay_Xms ;50ms
	POP ACC
	CJNE A,#0FFH,ambil1
	AJMP datapad
ambil1:
	CJNE A,#0B7h,ambil2
	SJMP ambil              ; '1' ditekan
ambil2:
	CJNE A,#0D7h,ambil3
	SJMP ambil              ; '2' ditekan
ambil3:
	CJNE A,#0E7h,ambil4     ; '3' ditekan
	SJMP ambil
ambil4:
	CJNE A,#0BBh,ambil5     ; '4' ditekan
	SJMP ambil
ambil5:
	CJNE A,#0DBh,ambil6     ; '5' ditekan
	SJMP ambil
ambil6:
	CJNE A,#0EBh,ambil7     ; '6' ditekan
	SJMP ambil
ambil7:
	CJNE A,#0BDh,ambil8     ; '7' ditekan
	SJMP ambil
ambil8:
	CJNE A,#0DDh,ambil9     ; '8' ditekan
	SJMP ambil
ambil9:
	CJNE A,#0EDh,ambilStar  ; '9' ditekan
	SJMP ambil
ambilStar:
	CJNE A,#0BEh,ambil0     ; '*' ditekan
	SJMP ambil
ambil0:
	CJNE A,#0DEh,ambilSharp ; '0' ditekan
	SJMP ambil
ambilSharp:
	CJNE A,#0EEh,ngacow     ; '#' ditekan
	SJMP ambil
ngacow:
	AJMP datapad
ambil:
	RET
delay_1s:
	PUSH 7
	MOV r1,#5
loop1:
	MOV r2,#250
loop2:
	MOV r3,#250
loop3:
	DJNZ r3, loop3
	DJNZ r2, loop2
	DJNZ r1, loop1
	POP 7
	RET
delay_Xms:
	MOV r1, A     ; A x 1000 = x us
	MOV TMOD, #01 ; timer 0 - 16 bit
lagi:
	MOV TH0, #HIGH(-1000)
	MOV TL0, #LOW(-1000)
	SETB TR0
tunggu:
	JNB TF0, tunggu
	clr TF0
	clr TR0
	djnz r1,lagi
	RET

kal1:
	DB 'Kunci DigitaL v1', 0FFH
kal2:
	DB 'By : Akeda Bagus', 0FFH
kal3:
	DB '----------------', 0FFH
kal4:
	DB ' Please press # ', 0FFH
kal5:
	DB 'Masukkan Kode : ', 0FFH
kal6:
	DB 'OK, you're in...', 0FFH
kal7:
	DB ' Pilih 1 atau 2 ', 0FFH
kal8:
	DB '1. Buka kunci ',   0FFH
kal9:
	DB '2. Ganti kode ',   0FFH
kal10:
	DB 'Kunci terbuka!! ', 0FFH
kal11:
	DB 'Closed after s',   0FFH
kal12:
	DB 'Kode Salah...!!!', 0FFH
kal13:
	DB 'beBack after s',   0FFH
kal14:
	DB 'Kode telah ganti', 0FFH
kal15:
	DB 'eLo dah Salah x',  0FFH
kal16:
	DB 'Lupa apa Maling?', 0FFH
kal17:
	DB 'Tunggu 1 Menit..', 0FFH
END
