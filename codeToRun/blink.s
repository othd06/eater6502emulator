PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

value = $0200    ;  2 bytes
mod10 = $0202    ;  2 bytes
message = $0204  ;  6 bytes

E  = %10000000
RW = %01000000
RS = %00100000

  .org $8000

reset:
  ldx #$ff
  txs

  lda #%11111111 ; Set all pins on port B to output
  sta DDRB
  lda #%11100000 ; Set top 3 pins on port A to output
  sta DDRA

  lda #%00111000 ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #$00000001 ; Clear display
  jsr lcd_instruction


  lda #0
  sta message

  ;Initialise value to be the number we want to convert
  lda number
  sta value
  lda number + 1
  sta value + 1

divide:
  ;Initialise the remainder to be 0
  lda #0
  sta mod10
  sta mod10 + 1
  clc

  ldx #16
divloop:
  ;Rotate quotient and remainder
  rol value
  rol value + 1
  rol mod10
  rol mod10 + 1

  ;a,y = dividend - divisor
  sec
  lda mod10
  sbc #10
  tay  ;  save low byte in Y
  lda mod10 + 1
  sbc #0
  bcc ignore_result  ; branch if dividend is less than divisor
  sty mod10
  sta mod10 + 1

ignore_result:
  dex
  bne divloop
  rol value
  rol value + 1

  lda mod10
  clc
  adc #"0"
  jsr push_char

  ;  if value != 0, then continue dividing
  lda value
  ora value + 1
  bne divide  ;  branch if the value is not zero

  
  ldx #0
print:
  lda message,x
  beq loop
  jsr print_char
  inx
  jmp print

loop:
  jmp loop

number: .word 1729

;Add the character in the A register to the beginning of the null terminated string 'message'
push_char:
  pha  ; Push new first character onto the stack
  ldy #0

char_loop:
  lda message, y
  tax  ; Load character from the string and put it in the x register
  pla
  sta message, y  ; Pull char off stack and add it to the string
  iny
  txa
  pha  ; push char from string onto stack
  bne char_loop

  pla
  sta message, y  ; Put the null termination back on the string

  rts


lcd_wait:
  pha
  lda #%00000000  ; Port B is input
  sta DDRB
lcdbusy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000
  bne lcdbusy

  lda #RW
  sta PORTA
  lda #%11111111  ; Port B is output
  sta DDRB
  pla
  rts

lcd_instruction:
  jsr lcd_wait
  sta PORTB
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  lda #E         ; Set E bit to send instruction
  sta PORTA
  lda #0         ; Clear RS/RW/E bits
  sta PORTA
  rts

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS         ; Set RS; Clear RW/E bits
  sta PORTA
  lda #(RS | E)   ; Set E bit to send instruction
  sta PORTA
  lda #RS         ; Clear E bits
  sta PORTA
  rts

  .org $fffc
  .word reset
  .word $0000