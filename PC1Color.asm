; PC1Color.ASM - Olivetti Prodest PC1 (Yamaha V6355D)
; 160x200 16-color Graphics Mode with Custom Palette
; By Dag Erik Hagesæter (aka Retro Erik)
; ===========================================================================
; TARGET: NASM -> .COM
; CPU: NEC V40 (8088 compatible)
; Thanks to Simone Riminucci for showing us that this was possible.
; Thanks to John Elliott  for his work gathering documentation.
; And thanks to VS COde and Copilot for Github.
; SOURCES: 
; - 6355 LCDC Video Controller Manual (Port/Register specifications)


org 0x100

start:
    ; --- PC1 HARDWARE CHECK ---
    ; Verifies machine ID at FFFF:000D. PC1 uses 0xFE (XT) and 0x44 (PC1).
    mov ax, 0xFFFF
    mov es, ax
    mov ax, [es:0x000D]     ; PC1 signature check
    cmp ax, 0xFE44
    jne no_pc1

    ; --- INITIALIZE VIDEO FOUNDATION ---
    ; We explicitly start with BIOS Mode 4 (CGA 320x200 4-color Graphics).
    ; WHY: 
    ; 1. Sets Yamaha V6355D CRTC registers to standard 15.7kHz horizontal sync.
    ; 2. Maps the 16KB VRAM physical window to the B800h segment.
    ; 3. Updates BIOS Data Area (0040h:0049h) so DOS knows we are in graphics.
    mov ax, 0x0004          
    int 0x10

    ; --- UNLOCK 16-COLOR MODE (Port 0x3D8) ---
    ; This is the CGA Mode Control Register, but the PC1's Yamaha V6355D 
    ; repurposes several bits for extended functionality.
    ;
    ; Standard CGA bits (IBM PC/XT compatible):
    ; Bit 0: [0] Text mode column width (0 = 40×25 alphanumeric, 1 = 80×25 alphanumeric)
    ; Bit 1: [1] Graphics mode enable (0 = text, 1 = graphics)
    ; Bit 2: [0] Video signal type (0 = color burst/chrominance, 1 = composite intensity/mono)
    ; Bit 3: [1] Video enable (0 = blank screen, 1 = display enabled)
    ; Bit 4: [0] High-res graphics (320x200 if 0, 640x200 if 1)
    ;
    ; Extended PC1/Yamaha V6355D bits:
    ; Bit 5: [0] Blink/Background (text mode only - not used in graphics)
    ; Bit 6: [1] MODE UNLOCK (Yamaha/Zenith extension)
    ;            1 = Enable 16-color planar logic (160x200 or 640x200)
    ;            0 = Standard 4-color CGA mode
    ;            This is the key bit that unlocks the "hidden" modes
    ; Bit 7: [0] STANDBY MODE (From V6355D Datasheet)
    ;            0 = Normal operation
    ;            1 = Power save mode (blanks display, reduces power)
    ;
    ; Using ACV-1030 Manual AND/OR method: preserve Bit 7, set via AND/OR
    in al, 0x3D8
    and al, 0x80         ; Keep only Bit 7 (STANDBY mode bit)
    or al, 0x4A          ; OR with 0x4A (Bit 6=1 for 16-color, Bit 3=1 for video, Bit 1=1 for graphics)
    out 0x3D8, al
    jmp short $+2
    jmp short $+2

    ; --- SET MONITOR CONTROL REGISTER (Register 0x65) FIRST ---
    ; CRITICAL: This must be set BEFORE mode unlock writes to Port 0x3D8
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
    ;         │ │ │ │ │ │ │ └─ Bit 0: 200 vertical lines (01b)
    ;         │ │ │ │ │ │ └─── Bit 1: 200 vertical lines (01b)
    ;         │ │ │ │ │ └───── Bit 2: Standard pixel width
    ;         │ │ │ │ └─────── Bit 3: PAL/SECAM (European standard)
    ;         │ │ │ └───────── Bit 4: Color mode
    ;         │ │ └─────────── Bit 5: CRT (SCART) mode
    ;         │ └───────────── Bit 6: Dynamic RAM
    ;         └─────────────── Bit 7: Light-pen
    ;
    ; Value: 09h (00001001b) - CORRECTED for 200 lines (bits 0-1 = 01b, not 00b)
    ; This sets: 200 lines, standard pixels, PAL, color, CRT, dynamic RAM
    ;
    ; Access via Register Bank: Port 0x3DD (address) / Port 0x3DE (data)
    ; Per 6355 LCDC port map: 0x3DD = Register Bank Address, 0x3DE = Register Bank Data
    mov al, 0x65            ; Select register 0x65
    out 0x3DD, al           ; Register Bank Address Port
    jmp short $+2           ; I/O delay
    mov al, 0x09            ; CRT mode (Bit 5=0), PAL (Bit 3=1), 200 lines (Bit 0-1=01)
    out 0x3DE, al           ; Register Bank Data Port
    jmp short $+2           ; I/O delay

    ; --- SET CENTERING, BUS WIDTH & PLANAR (Register 0x67) FIRST ---
    ; CRITICAL: Planar merge (Bit 7) must be enabled BEFORE mode unlock
    ; This enables 16-bit addressing and pixel format interpretation
    ; This is a Yamaha V6355D proprietary register accessed via indexed I/O.
    ; Index Port: 0x3DD (write register number here)
    ; Data Port:  0x3DE (write/read register value here)
    ; Per 6355 LCDC port map: 0x3DD = Register Bank Address, 0x3DE = Register Bank Data
    ;
    ; Register 0x67 controls critical display and memory architecture settings:
    ;
    ; Bit 7: [1] 16-bit Bus Width / Planar Memory Merge
    ;            When enabled (1):
    ;            - Merges the two CGA memory banks (even/odd) into linear addressing
    ;            - Allows sequential pixel writing within each scanline
    ;            - Standard CGA splits horizontal pixels: even at B800:0000, 
    ;              odd at B800:2000 (NOT vertical interlacing like TV)
    ;            - This bit removes that horizontal pixel split for simpler access
    ;            - Enables true planar graphics similar to EGA/VGA
    ;            When disabled (0):
    ;            - Standard CGA split memory (even horizontal pixels at B800:0000, 
    ;              odd horizontal pixels at B800:2000)
    ;
    ; Bit 6: [0] Page Mode Enable
    ;            Datasheet note: "Page mode is not supported on static RAM".
    ;            Reality for PC1: it has **16KB DRAM mirrored**, not 64KB DRAM.
    ;            When enabled (1):
    ;            - Requires 64KB DRAM split into four pages (per datasheet)
    ;            - PC1 only has 16KB DRAM, so addressing wraps/mirrors
    ;            - Causes overlapping/corrupted bars on PC1
    ;            When disabled (0):
    ;            - Safe for the PC1's 16KB DRAM layout
    ;            - Standard linear VRAM addressing
    ;            KEEP THIS OFF on PC1 (hardware requirement for page mode not met)
    ;
    ; Bit 5: [0] LCD Control Signal Period
    ;            Adjusts the control signal timing for LCD/CRT compatibility.
    ;            0 = Standard CRT timing
    ;            1 = LCD timing
    ;
    ; Bit 4: [1] Display timing related (exact function unclear)
    ;            May affect horizontal sync or pixel clock
    ;
    ; Bit 3: [1] Display timing related (exact function unclear)
    ;            May affect horizontal sync or pixel clock
    ;
    ; Bits 0-2: [000] Horizontal Centering Offset
    ;            These 3 bits form a value that shifts the display horizontally.
    ;            Combined with bits 3-4, the full 5-bit value is 24 (11000b).
    ;            The "Sweet Spot" centering value discovered by Peritel.com authors.
    ;            Range: 0-31 (5 bits total)
    ;            Value 24-26 typically centers the image on most monitors
    ;
    ; Binary breakdown: 1 0 0 1 1 0 0 0
    ;                   │ │ │ │ │ └─┴─┴─ Bits 0-2: Centering low bits (000)
    ;                   │ │ │ │ └───────── Bit 3: Timing/centering bit
    ;                   │ │ │ └─────────── Bit 4: Timing/centering bit
    ;                   │ │ └───────────── Bit 5: LCD Control Signal Period
    ;                   │ └─────────────── Bit 6: Page Mode DISABLED (PC1: 16KB DRAM, needs 64KB for paging)
    ;                   └───────────────── Bit 7: Planar merge ENABLE
    ;
    ; Full 5-bit centering value: bits 4-3-2-1-0 = 11000b = 24 decimal
    ;
    ; Value: 98h (10011000b)
    ; This combines: Planar mode + Page Mode OFF + horizontal centering of 24
    ; (matches PERITEL.COM centering value)
    mov al, 0x67            ; Select register 0x67
    out 0x3DD, al           ; Register Bank Address Port
    jmp short $+2           ; I/O delay (give chip time to latch register index)
    mov al, 0x98            ; Planar merge enabled, page mode OFF (PC1 has 16KB DRAM, needs 64KB for paging)
    out 0x3DE, al           ; Register Bank Data Port
    jmp short $+2           ; I/O delay (give chip time to apply settings)

    ; --- SET BORDER COLOR (Port 0x3D9 - Color Select Register) ---
    ; This register sets the border/overscan color displayed around the 160x200 image.
    ; Bits 0-3: Border color index (0-15, selects from palette)
    ; Value: 00h = Color 0 (Black border)
    mov dx, 0x03D9
    mov al, 0x00            ; Border color = palette entry 0 (Black)
    out dx, al
    jmp short $+2           ; I/O delay

    ; --- SET PALETTE ONCE AT STARTUP ---
    call set_rainbow_palette   ; Configure palette at startup

main_loop:
    call draw_16_columns

    ; --- INPUT HANDLING ---
    xor ah, ah
    int 0x16                ; Wait for key
    cmp al, 27              ; ESC to exit
    je exit_program
    jmp main_loop           ; Loop to keep image alive

exit_program:
    ; Reset to standard Text Mode 3 to restore the BIOS state.
    mov ax, 0x0003          
    int 0x10
    mov ax, 0x4C00          ; DOS exit function
    int 0x21

no_pc1:
    mov dx, msg_err
    mov ah, 0x09
    int 0x21
    mov ax, 0x4C01          ; Exit with error code
    int 0x21

; --- SUBROUTINES ---

set_rainbow_palette:
    ; Access palette registers 0x40-0x5F via indexed I/O (6355 internal registers)
    ; Per 6355 LCDC manual Table 14-26: Color palettes 0-15 at addresses 0x40-0x5F
    ; Each color uses 2 bytes:
    ; Even register (0x40, 0x42...): Red intensity in bits 0-3
    ; Odd register (0x41, 0x43...): Green in bits 4-7, Blue in bits 0-3
    ; Format: 12-bit RGB (4 bits per channel = 4096 colors available)
    ; 
    ; Access via Register Bank: Port 0x3DD (address) / Port 0x3DE (data)
    ; Per 6355 LCDC port map: 0x3DD = Register Bank Address, 0x3DE = Register Bank Data
    
    mov al, 0x40            ; Select palette register 0x40 (first color)
    out 0x3DD, al           ; Register Bank Address Port
    jmp short $+2           ; I/O delay
    
    mov si, rainbow_data
    mov cx, 16              ; 16 colors (writes 32 bytes total)
.p_loop:
    lodsb                   ; Load Red byte from table
    out 0x3DE, al           ; Register Bank Data Port (Write to Even register, auto-increments)
    jmp short $+2           ; I/O delay
    lodsb                   ; Load Green/Blue byte from table
    out 0x3DE, al           ; Register Bank Data Port (Write to Odd register, auto-increments)
    jmp short $+2           ; I/O delay
    loop .p_loop
    ret

draw_16_columns:
    ; PLANAR WRITE TEST: VRAM is organized in 4 planes, not packed pixels.
    ; Hypothesis: Each plane holds one bit of the 4-bit color code.
    ; 
    ; Memory layout (planar):
    ; Plane 0 (bit 0): 0xB800:0000–0xB800:3FFF (4KB)
    ; Plane 1 (bit 1): 0xB800:4000–0xB800:7FFF (4KB)
    ; Plane 2 (bit 2): 0xB800:8000–0xB800:BFFF (4KB)
    ; Plane 3 (bit 3): 0xB800:C000–0xB800:FFFF (4KB)
    ;
    ; Simple test: Fill plane 0 with pattern 0xAA (alternating bits)
    ; This should show vertical dither if planar, or solid pattern if not.
    
    mov ax, 0xB800
    mov es, ax
    
    ; === FILL PLANE 0 (bit 0) ===
    xor di, di              ; Start at 0xB800:0000
    mov cx, 0x1000         ; 4KB per plane
    mov al, 0xAA            ; Test pattern: 10101010b
    rep stosb
    
    ; === FILL PLANE 1 (bit 1) ===
    mov di, 0x4000          ; Start at 0xB800:4000
    mov cx, 0x1000
    mov al, 0x55            ; Test pattern: 01010101b (opposite of plane 0)
    rep stosb
    
    ; === FILL PLANE 2 (bit 2) ===
    mov di, 0x8000          ; Start at 0xB800:8000
    mov cx, 0x1000
    mov al, 0xFF            ; Test pattern: 11111111b
    rep stosb
    
    ; === FILL PLANE 3 (bit 3) ===
    mov di, 0xC000          ; Start at 0xB800:C000
    mov cx, 0x1000
    mov al, 0x00            ; Test pattern: 00000000b
    rep stosb
    
    ret

; --- DATA SECTION ---

; Format: Byte 1 (Red), Byte 2 (Green/Blue)
; 12-bit RGB format: 4 bits per channel (0-15 intensity)
; Per 6355 LCDC manual Table 14-26: Palette registers 0x40-0x5F
; Even register (0x40, 0x42...): Red in bits 0-3
; Odd register (0x41, 0x43...): Green in bits 4-7, Blue in bits 0-3
rainbow_data:
    db 0x00, 0x00    ; 0: Black       (R:0,  G:0,  B:0)
    db 0x0F, 0x00    ; 1: Red         (R:15, G:0,  B:0)
    db 0x00, 0xF0    ; 2: Green       (R:0,  G:15, B:0)
    db 0x0F, 0xF0    ; 3: Yellow      (R:15, G:15, B:0)
    db 0x00, 0x0F    ; 4: Blue        (R:0,  G:0,  B:15)
    db 0x0F, 0x0F    ; 5: Magenta     (R:15, G:0,  B:15)
    db 0x00, 0xFF    ; 6: Cyan        (R:0,  G:15, B:15)
    db 0x0F, 0xFF    ; 7: White       (R:15, G:15, B:15)
    db 0x08, 0x00    ; 8: Dark Red    (R:8,  G:0,  B:0)
    db 0x0F, 0x80    ; 9: Orange      (R:15, G:8,  B:0)
    db 0x08, 0xF0    ; 10: Lime       (R:8,  G:15, B:0)
    db 0x00, 0x8F    ; 11: Navy       (R:0,  G:0,  B:8)
    db 0x08, 0x0F    ; 12: Purple     (R:8,  G:0,  B:15)
    db 0x00, 0x88    ; 13: Teal       (R:0,  G:8,  B:8)
    db 0x08, 0x88    ; 14: Gray       (R:8,  G:8,  B:8)
    db 0x0F, 0x8F    ; 15: Light Gray (R:15, G:8,  B:15)

msg_err db 'Error: Requires Olivetti PC1.', 0x0D, 0x0A, '$'
