; ============================================================================
; COLORBARS.ASM (v59) - 16 Color Bar Demo for Olivetti Prodest PC1
; Hidden 160x200x16 Graphics Mode
; Written for NASM - NEC V40 (80186 compatible)
; By Retro Erik - 2026
;
; Controls:
;   SPACE - Cycle palette colors (random from 512-color palette)
;   A     - Cycle border color (0-15)   
;   Q     - Draw random colored circle
;   0     - Set bar width to 10 pixels (default, fills screen)
;   T     - Draw test pattern (circle + crosshair for measuring)
;   1-9   - Set bar width to 2,4,6,8,10,12,14,16,18 pixels (Not working)
;   ESC   - Exit to DOS in text mode
; ============================================================================

[BITS 16]
[ORG 0x100]

; ============================================================================
; Constants
; ============================================================================
VIDEO_SEG       equ 0xB000      ; Video memory segment (B000, not B800!)

; Note: 0xDD and 0x3DD are aliases on PC1 hardware
PORT_REG_ADDR   equ 0xDD        ; 6355 Register Bank Address Port
PORT_REG_DATA   equ 0xDE        ; 6355 Register Bank Data Port  
PORT_MODE       equ 0xD8        ; CGA Mode Control Port
PORT_COLOR      equ 0xD9        ; CGA Color Select Port

PALETTE_BASE    equ 0x40        ; Palette starts at register 0x40

SCREEN_WIDTH    equ 160         ; Pixels
SCREEN_HEIGHT   equ 200         ; Pixels
BYTES_PER_ROW   equ 80          ; 160 pixels / 2 (packed nibbles)

KEY_SPACE       equ 0x20
KEY_ESC         equ 0x1B
KEY_Q           equ 'q'
KEY_Q_UPPER     equ 'Q'

; ============================================================================
; Main Program Entry Point
; ============================================================================
main:
    ; Initialize random seed from timer
    call init_random
    
    ; Enable the hidden 160x200x16 graphics mode
    call enable_graphics_mode
    
    ; Clear video memory to avoid garbage
    call clear_screen
    
    ; Generate initial random palette
    call generate_random_palette
    
    ; Set the palette
    call set_palette
    
    ; Draw the 16 color bars
    call draw_color_bars
    
.main_loop:
    ; Wait for keypress (AH = scan code, AL = ASCII)
    call wait_key
    
    ; Check for ESC
    cmp al, KEY_ESC
    je .exit_program
    
    ; Check for SPACE - cycle colors
    cmp al, KEY_SPACE
    jne .not_space
    call generate_random_palette
    call set_palette
    jmp .main_loop
    
.not_space:
    ; Check for A - cycle border color
    cmp al, 'a'
    je .do_border
    cmp al, 'A'
    je .do_border
    jmp .not_border
.do_border:
    call cycle_border
    jmp .main_loop
    
.not_border:
    ; Check for Q - draw circle
    cmp al, KEY_Q
    je .do_circle
    cmp al, KEY_Q_UPPER
    je .do_circle
    jmp .not_q
.do_circle:
    call draw_circle
    jmp .main_loop
.not_q:

    ; Check for T - draw test pattern (circle + crosshair for measuring)
    cmp al, 't'
    je .do_test
    cmp al, 'T'
    je .do_test
    jmp .not_t
.do_test:
    call draw_test_pattern
    jmp .main_loop
.not_t:

    ; Check for 0 FIRST (since '0' < '1')
    cmp al, '0'
    jne .not_zero
    mov byte [bar_width], 10
    call draw_color_bars
    jmp .main_loop
    
.not_zero:
    ; Check for 1-9 (bar width 2,4,6,8,10,12,14,16,18 pixels)
    ; We multiply by 2 to always get even pixel counts
    cmp al, '1'
    jb .not_digit
    cmp al, '9'
    ja .not_digit
    ; Convert '1'-'9' to 2,4,6,8,10,12,14,16,18
    sub al, '0'         ; AL = 1-9
    shl al, 1           ; AL = 2,4,6,8,10,12,14,16,18
    mov [bar_width], al
    call draw_color_bars
    jmp .main_loop
    
.not_digit:
    jmp .main_loop
    
.exit_program:
    ; Disable graphics mode (return to text mode)
    call disable_graphics_mode
    
    ; Restore video mode 3 (80x25 text)
    mov ax, 0x0003
    int 0x10
    
    ; Exit to DOS
    mov ax, 0x4C00
    int 0x21

; ============================================================================
; enable_graphics_mode - Olivetti Prodest PC1 hidden 160x200x16 graphics mode
; Configures Yamaha V6355D for hidden 160x200x16 graphics mode:
; - Sets 8-bit bus mode (PC1 has 8-bit bus, NOT 16-bit!)
; - Sets PAL timing (50Hz, 200 lines)
; - Enables 16-color mode (planar logic, custom palette)
; - Sets border color to black
; - Ensures safe defaults for PC1 hardware (no page mode, CRT timing)
; ---------------------------------------------------------------------------
enable_graphics_mode:
    push ax
    push dx
    
    ; BIOS Mode 4: CGA 320x200 graphics, sets CRTC for 15.7kHz sync
    mov ax, 0x0004
    int 0x10
    
    ; --- CONFIGURATION MODE REGISTER (Register 0x67) ---
    ; Sets V6355D register 0x67 to 0x18:
    ; Bit 7: [0] 16-bit bus mode OFF - MUST be 0 on PC1's 8-bit bus!
    ;            If set on 8-bit bus, controller can only access odd bytes of VRAM.
    ; Bit 6: [0] 4-page video RAM OFF (PC1's only have 16KB DRAM)
    ; Bit 5: [0] LCD control period (CRT timing)
    ; Bit 4: [1] Display timing/centering (see datasheet)
    ; Bit 3: [1] Display timing/centering (see datasheet)
    ; Bits 0-2: [000] Horizontal centering offset (default) Range: 0-31 (5 bits total)
    ; Binary: 00011000b (0x18)
    mov al, 0x67
    out PORT_REG_ADDR, al
    jmp short $+2
    mov al, 0x18            ; 8-bit bus, no paging, h-position=24
    out PORT_REG_DATA, al
    jmp short $+2
    
    ; --- SET MONITOR CONTROL REGISTER (Register 0x65) FIRST ---
    ; This register sets operational requirements for the video interface.
    ; Per 6355 LCDC manual Table 14-28 and Table 14-21:
    ; Bit 0-1: [01] Vertical line count = 200 lines (01b not 00b which equals 192 lines)
    ; Bit 2: [0] Horizontal pixel width = 320 or 640 pixels (standard)
    ; Bit 3: [1] TV Standard = PAL/SECAM (Norway/EU)
    ; Bit 4: [0] Color/Monochrome = IBM PC-compatible color mode
    ; Bit 5: [0] CRT vs LCD = Raster-scan CRT (SCART monitor)
    ; Bit 6: [0] RAM type = Dynamic RAM
    ; Bit 7: [0] Input device = Light-pen
    ;
    ; Binary: 0 0 0 0 1 0 0 1
    ;         │ │ │ │ │ │ │ └─ Bit 0: Vertical height of screen: 0 => 192, 1 => 200; 2 => 204
    ;         │ │ │ │ │ │ └─── Bit 1: Vertical height of screen: 0 => 192, 1 => 200; 2 => 204
    ;         │ │ │ │ │ └───── Bit 2: Width of screen: 0 => 640 / 320, 1 => 512 / 256
    ;         │ │ │ │ └─────── Bit 3: Vertical refresh: Set for 50Hz, clear for 60Hz
    ;         │ │ │ └───────── Bit 4: Monitor type: Set for MDA, clear for CGA
    ;         │ │ └─────────── Bit 5: CRT (SCART) mode
    ;         │ └───────────── Bit 6: Dynamic RAM
    ;         └─────────────── Bit 7: Light-pen
    ;
    ; Value: 0x09 (00001001b) = 200 lines, PAL, color, CRT
    ; Access via Register Bank: PORT_REG_ADDR (0xDD) / PORT_REG_DATA (0xDE)
    mov al, 0x65
    out PORT_REG_ADDR, al
    jmp short $+2
    mov al, 0x09
    out PORT_REG_DATA, al
    jmp short $+2
    
    ; --- UNLOCK 16-COLOR MODE (Port 0xD8, value 0x4A) ---
    ; This is the CGA Mode Control Register, but the PC1's Yamaha V6355D 
    ; repurposes several bits for extended functionality.
    ;
    ; Standard CGA bits (IBM PC/XT compatible):
    ; Bit 0: [0] Text mode column width (0 = 40×25, 1 = 80×25)
    ; Bit 1: [1] Graphics mode enable (0 = text, 1 = graphics)
    ; Bit 2: [0] Video signal type (0 = color burst, 1 = mono)
    ; Bit 3: [1] Video enable (0 = blank, 1 = display)
    ; Bit 4: [0] High-res graphics (0 = 320x200, 1 = 640x200)
    ;
    ; Extended PC1/Yamaha V6355D bits:
    ; Bit 5: [0] Blink/Background (text mode only)
    ; Bit 6: [1] MODE UNLOCK (Yamaha extension)
    ;         1 = Enable 16-color planar logic (160x200)
    ;         0 = Standard 4-color CGA mode
    ; Bit 7: [0] STANDBY MODE (V6355D Datasheet)
    ;         0 = Normal operation
    ;         1 = Power save mode (display blank)
    ;
    ; Value 0x4A = 01001010b
    ;   Bit 6 = 1 (MODE UNLOCK: enable 16-color planar)
    ;   Bit 3 = 1 (Video enable)
    ;   Bit 1 = 1 (Graphics mode)
    ;   All other bits = 0
    mov al, 0x4A
    out PORT_MODE, al
    jmp short $+2
    jmp short $+2
    
    ; Port 0xD9: 0x00 = black border
    mov byte [border_color], 0
    xor al, al
    out PORT_COLOR, al
    jmp short $+2
    jmp short $+2
    
    pop dx
    pop ax
    ret

; ============================================================================
; disable_graphics_mode - Disable the hidden graphics mode
; Must reset V6355 registers before BIOS mode switch
; ============================================================================
disable_graphics_mode:
    push ax
    push dx
    
    ; --- RESET CONFIGURATION MODE REGISTER (Register 0x67) ---
    ; Sets V6355D register 0x67 to 0x00:
    ; Bit 7: [0] 16-bit bus mode OFF (8-bit bus for PC1)
    ; Bit 6: [0] 4-page video RAM OFF
    ; Bit 5: [0] LCD control period (CRT timing)
    ; Bit 4: [0] Display timing (default)
    ; Bit 3: [0] Display timing (default)
    ; Bits 0-2: [000] Horizontal centering offset (default)
    ; Binary: 00000000b
    mov al, 0x67            ; Select register 0x67
    out PORT_REG_ADDR, al   ; Register Bank Address Port
    jmp short $+2           ; I/O delay
    mov al, 0x00            ; Reset to defaults
    out PORT_REG_DATA, al   ; Register Bank Data Port
    jmp short $+2           ; I/O delay
    
    ; --- RESET MONITOR CONTROL REGISTER (Register 0x65) ---
    ; Value: 09h (00001001b) - CORRECTED for 200 lines (bits 0-1 = 01b, not 00b)
    ; This sets: 200 lines, standard pixels, PAL, color, CRT, dynamic RAM
    ;
    ; Access via Register Bank: Port 0x3DD (address) / Port 0x3DE (data)
    ; Per 6355 LCDC port map: 0x3DD = Register Bank Address, 0x3DE = Register Bank Data
    ; Note: On PC1, 0xDD/0xDE and 0x3DD/0x3DE are aliases and function identically.
    mov al, 0x65            ; Select register 0x65
    out PORT_REG_ADDR, al   ; Register Bank Address Port
    jmp short $+2           ; I/O delay
    mov al, 0x09            ; Keep 200 lines, PAL (safe default)
    out PORT_REG_DATA, al   ; Register Bank Data Port
    jmp short $+2           ; I/O delay
    
    ; --- RESET 16-COLOR MODE (Port 0xD8, value 0x28) ---
    ; Reset mode control port to standard CGA mode
    ; 0x28 = text mode (bit 5=1 blink, bit 3=1 video on)
    mov al, 0x28
    out PORT_MODE, al
    jmp short $+2
    
    pop dx
    pop ax
    ret

; ============================================================================
; clear_screen - Clear video memory to black (color 0)
; ============================================================================
clear_screen:
    push ax
    push cx
    push di
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    xor di, di
    mov cx, 8000            ; 16KB = 8000 words
    xor ax, ax              ; Fill with 0x0000
    cld
    rep stosw
    
    pop es
    pop di
    pop cx
    pop ax
    ret

; ============================================================================
; set_palette - Write the 16-color palette to the 6355 chip
;   MOV AL, 0x40 / OUT 0xDD, AL   ; Enable palette write
;   REP OUTSB                      ; Output 32 bytes to port 0xDE
;   MOV AL, 0x80 / OUT 0xDD, AL   ; Disable palette write
;
; Palette format: 32 bytes (16 colors × 2 bytes each)
;   Byte 1: Red intensity (bits 0-3)
;   Byte 2: Green (bits 4-7) + Blue (bits 0-3)
; ============================================================================
set_palette:
    push ax
    push cx
    push dx
    push si
    
    cli                     ; Disable interrupts during palette write
    
    ; Enable palette write mode (write 0x40 to port 0xDD)
    mov al, 0x40
    out PORT_REG_ADDR, al
    
    ; Write 32 bytes of palette data using REP OUTSB
    mov dx, 0x3DE           ; Full 16-bit port address for OUTSB
    mov si, palette
    mov cx, 32              ; 16 colors × 2 bytes
    cld                     ; Clear direction flag
    rep outsb               ; Output CX bytes from DS:SI to port DX
    
    ; Disable palette write mode (write 0x80 to port 0xDD)
    mov al, 0x80
    out PORT_REG_ADDR, al
    
    sti                     ; Re-enable interrupts
    
    pop si
    pop dx
    pop cx
    pop ax
    ret

; ============================================================================
; draw_color_bars - Draw 16 vertical color bars on screen
; EXACT COPY of working algorithm structure
; 80 bytes per row, 2 pixels per byte (packed nibbles)
; Manual even/odd bank handling
; ============================================================================
draw_color_bars:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    ; Draw all 200 rows
    xor bx, bx              ; BX = row counter (0-199)
    
.row_loop:
    ; Calculate offset for this row
    mov ax, bx
    test ax, 1
    jz .even_row
    
    ; Odd row: 0x2000 + (row/2)*80
    shr ax, 1
    mov cx, 80
    mul cx
    add ax, 0x2000
    mov di, ax
    jmp .draw_row
    
.even_row:
    ; Even row: (row/2)*80
    shr ax, 1
    mov cx, 80
    mul cx
    mov di, ax
    
.draw_row:
    ; Draw 16 bars of 5 bytes each
    mov cl, 0               ; CL = color (0-15)
    
.bar_loop:
    ; Pack color into both nibbles
    mov al, cl
    mov ah, al
    shl al, 4
    or al, ah
    
    ; Write 5 bytes
    stosb
    stosb
    stosb
    stosb
    stosb
    
    inc cl
    cmp cl, 16
    jb .bar_loop
    
    ; Next row
    inc bx
    cmp bx, 200
    jb .row_loop
    
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; cycle_border - Cycle the border color 0-15
; ============================================================================
cycle_border:
    push ax
    push dx
    
    mov al, [border_color]
    inc al
    and al, 0x0F            ; Keep in range 0-15
    mov [border_color], al
    
    ; Output to border color port
    out PORT_COLOR, al
    
    pop dx
    pop ax
    ret

; ============================================================================
; draw_test_pattern - Draw measurement test pattern
; Draws a 40-pixel radius circle with horizontal/vertical lines through center
; Makes it easy to count pixels and verify resolution
; ============================================================================
draw_test_pattern:
    push ax
    push bx
    push cx
    push dx
    push di
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    ; Clear screen first
    xor di, di
    mov cx, 16000           ; 32KB / 2
    xor ax, ax
    rep stosw
    
    ; Draw white circle (color 15)
    mov byte [circle_color], 15
    call draw_circle
    
    ; Draw horizontal line through center (Y=100)
    ; From X=0 to X=159, color 14
    mov word [circle_x1], 0
    mov word [circle_x2], 159
    mov byte [circle_color], 14
    mov ax, 100
    call draw_hline_packed
    
    ; Draw vertical line through center (X=80)
    ; From Y=0 to Y=199, color 14
    ; SIMPLIFIED to avoid crash
    mov dx, 0
.vline_loop:
    cmp dx, 200
    jae .vline_done
    
    ; Set up for hline drawing (draw 1-pixel wide "line")
    mov word [circle_x1], 80
    mov word [circle_x2], 80
    mov byte [circle_color], 14
    mov ax, dx
    
    push dx
    call draw_hline_packed
    pop dx
    
    inc dx
    jmp .vline_loop
    
.vline_done:
    pop es
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; draw_circle - Draw a filled circle that appears round on display
; Center: (80, 100), Radius: 40 pixels vertically, scaled horizontally
; Compensates for non-square pixel aspect ratio
; ============================================================================
draw_circle:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    push es
    
    mov ax, VIDEO_SEG
    mov es, ax
    
    call random_byte
    and al, 0x0F
    mov [circle_color], al
    
    mov word [circle_y], 60     ; Y = 100 - 40
    
.y_loop:
    mov ax, [circle_y]
    cmp ax, 140                 ; Y = 100 + 40
    ja .done
    
    ; Calculate dy = Y - 100
    sub ax, 100
    mov bx, ax                  ; BX = dy
    
    ; Calculate dy²
    mov ax, bx
    cmp ax, 0
    jge .pos
    neg ax
.pos:
    mov cx, ax
    mul cx                      ; AX = dy²
    
    ; Calculate 1600 - dy² (radius² = 1600)
    mov cx, 1600
    sub cx, ax
    jbe .next_y
    
    ; Get sqrt
    mov ax, cx
    call simple_sqrt            ; AX = dx
    
    ; NO SCALING - let hardware chunky pixels handle aspect ratio
    mov [circle_dx], ax
    
    ; Calculate X coordinates
    mov ax, 80
    sub ax, [circle_dx]
    mov [circle_x1], ax
    
    mov ax, 80
    add ax, [circle_dx]
    mov [circle_x2], ax
    
    mov ax, [circle_y]
    call draw_hline_packed
    
.next_y:
    inc word [circle_y]
    jmp .y_loop
    
.done:
    pop es
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; simple_sqrt - Very simple integer square root
; Input: AX = value
; Output: AX = approximate sqrt
; Uses simple bit-by-bit calculation
; ============================================================================
simple_sqrt:
    push bx
    push cx
    push dx
    push si
    
    cmp ax, 0
    je .zero
    cmp ax, 1
    je .one
    
    ; Use binary search approach
    mov bx, ax              ; BX = value
    mov cx, ax
    shr cx, 1               ; Initial guess = value/2
    add cx, 1
    
    ; Do a few iterations (use SI as counter, not DX!)
    mov si, 4
.iter:
    mov ax, bx              ; AX = value
    xor dx, dx
    div cx                  ; AX = value / guess
    add ax, cx              ; AX = guess + value/guess  
    shr ax, 1               ; AX = average
    mov cx, ax              ; New guess
    dec si                  ; Use SI not DX!
    jnz .iter
    
    mov ax, cx
    jmp .end
    
.zero:
    xor ax, ax
    jmp .end
    
.one:
    mov ax, 1
    
.end:
    pop si
    pop dx
    pop cx
    pop bx
    ret

; ============================================================================
; draw_hline_packed - Draw horizontal line using packed nibbles
; Input: AX = Y, [circle_x1] = start X, [circle_x2] = end X
; Format: 2 pixels per byte, even/odd banks
; ============================================================================
draw_hline_packed:
    push ax
    push bx
    push cx
    push dx
    push di
    push si
    
    mov si, ax              ; SI = Y
    
    ; Clamp X (0-159)
    mov bx, [circle_x1]
    cmp bx, 0
    jge .x1ok
    xor bx, bx
.x1ok:
    cmp bx, 159
    jle .x1ok2
    mov bx, 159
.x1ok2:
    mov [circle_x1], bx
    
    mov bx, [circle_x2]
    cmp bx, 0
    jge .x2ok
    xor bx, bx
.x2ok:
    cmp bx, 159
    jle .x2ok2
    mov bx, 159
.x2ok2:
    mov [circle_x2], bx
    
    ; Calculate bank and offset
    mov ax, si
    test ax, 1
    jz .even
    
    ; Odd: offset = 0x2000 + (Y/2)*80
    shr ax, 1
    mov bx, 80
    mul bx
    add ax, 0x2000
    jmp .gotbase
    
.even:
    ; Even: offset = (Y/2)*80
    shr ax, 1
    mov bx, 80
    mul bx
    
.gotbase:
    mov di, ax              ; DI = row base
    
    ; Draw pixels X1 to X2
    mov cx, [circle_x1]
    
.ploop:
    cmp cx, [circle_x2]
    ja .done
    
    ; Byte offset = X/2
    mov ax, cx
    shr ax, 1
    push di
    add di, ax
    
    ; Read byte
    mov bl, [es:di]
    
    ; Check even/odd pixel
    test cl, 1
    jnz .oddpix
    
    ; Even pixel (high nibble)
    and bl, 0x0F
    mov al, [circle_color]
    shl al, 4
    or bl, al
    jmp .write
    
.oddpix:
    ; Odd pixel (low nibble)
    and bl, 0xF0
    or bl, [circle_color]
    
.write:
    mov [es:di], bl
    pop di
    inc cx
    jmp .ploop
    
.done:
    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ============================================================================
; generate_random_palette - Generate 16 TRUE RANDOM colors
; Each color is encoded as 2 bytes for the 6355 chip palette format
; Hardware supports 512 colors (3 bits per channel = 8 levels each)
; Format: Byte 1 = Red (bits 0-2), Byte 2 = Green (bits 4-6) | Blue (bits 0-2)
; FIXED: Color 0 is always BLACK (for border), colors 1-15 are random
; ============================================================================
generate_random_palette:
    push ax
    push bx
    push cx
    push di
    
    mov di, palette
    
    ; Color 0 = BLACK (for border)
    mov byte [di], 0x00     ; Red = 0
    inc di
    mov byte [di], 0x00     ; Green = 0, Blue = 0
    inc di
    
    ; Randomize colors 1-15
    mov cx, 15
    
.gen_loop:
    ; Generate random Red (0-7, stored in bits 0-2)
    call random_byte
    and al, 0x07            ; 3 bits = 0-7
    mov [di], al            ; Store Red byte
    inc di
    
    ; Generate random Green (0-7) and Blue (0-7)
    call random_byte
    mov bl, al
    and bl, 0x07            ; Blue in bits 0-2
    
    call random_byte
    and al, 0x07            ; Green 0-7
    shl al, 4               ; Shift to bits 4-6
    or al, bl               ; Combine: Green (high nibble) | Blue (low nibble)
    mov [di], al            ; Store GB byte
    inc di
    
    loop .gen_loop
    
    pop di
    pop cx
    pop bx
    pop ax
    ret

; Fixed rainbow palette - kept for reference
; Format: Red (bits 0-2), Green (bits 4-6) | Blue (bits 0-2)
; True 512-color palette (3 bits per channel)
rainbow_palette:
    db 0x04, 0x44    ; 0:  Gray 
    db 0x07, 0x00    ; 1:  Red         (R:7, G:0, B:0)
    db 0x00, 0x70    ; 2:  Green       (R:0, G:7, B:0)
    db 0x07, 0x70    ; 3:  Yellow      (R:7, G:7, B:0)
    db 0x00, 0x07    ; 4:  Blue        (R:0, G:0, B:7)
    db 0x07, 0x07    ; 5:  Magenta     (R:7, G:0, B:7)
    db 0x00, 0x77    ; 6:  Cyan        (R:0, G:7, B:7)
    db 0x07, 0x77    ; 7:  White       (R:7, G:7, B:7)
    db 0x07, 0x40    ; 8:  Orange      (R:7, G:4, B:0)
    db 0x04, 0x70    ; 9:  Lime        (R:4, G:7, B:0)
    db 0x00, 0x47    ; 10: Sky Blue    (R:0, G:4, B:7)
    db 0x04, 0x07    ; 11: Purple      (R:4, G:0, B:7)
    db 0x07, 0x47    ; 12: Pink        (R:7, G:4, B:7)
    db 0x04, 0x74    ; 13: Aqua        (R:4, G:7, B:4)
    db 0x07, 0x04    ; 14: Brown       (R:7, G:0, B:4)
    db 0x06, 0x66    ; 15: Light Gray  (R:6, G:6, B:6)

; ============================================================================
; init_random - Initialize random number generator from timer
; ============================================================================
init_random:
    push ax
    push dx
    
    ; Read timer tick count
    xor ax, ax
    int 0x1A                    ; Get timer ticks in CX:DX
    
    ; Use DX as initial seed
    mov [rand_seed], dx
    
    pop dx
    pop ax
    ret

; ============================================================================
; random_byte - Generate a pseudo-random byte
; Output: AL = random byte
; Uses linear congruential generator: seed = seed * 25173 + 13849
; ============================================================================
random_byte:
    push bx
    push dx
    
    mov ax, [rand_seed]
    mov bx, 25173
    mul bx
    add ax, 13849
    mov [rand_seed], ax
    
    ; Use high byte for better randomness
    mov al, ah
    
    pop dx
    pop bx
    ret

; ============================================================================
; wait_key - Wait for a key press
; Output: AL = ASCII code of key pressed
; ============================================================================
wait_key:
    mov ah, 0x00
    int 0x16                    ; BIOS keyboard read
    ret

; ============================================================================
; Data Section
; ============================================================================
rand_seed:      dw 0            ; Random number seed
bar_width:      db 10           ; Bar width in DISPLAY pixels (gets divided by 2 for 80-pixel mode)
border_color:   db 0            ; Current border color (0-15)

; Circle drawing variables
circle_color:   db 0
circle_y:       dw 0
circle_dx:      dw 0
circle_x1:      dw 0
circle_x2:      dw 0

; Palette buffer - 32 bytes (16 colors × 2 bytes each)
; Will be filled with random values
palette:
    times 32 db 0

; ============================================================================
; End of program
; ============================================================================