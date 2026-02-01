# 🧠 **Olivetti Prodest PC1 - Video Memory & Hidden Graphics Mode**

By Retro Erik

This document describes how video memory works on the PC1 with the Yamaha V6355D chip, and documents the **working code** that enables the hidden 160×200×16 graphics mode.

**Status: SOLVED** — The hidden graphics mode is fully working in colorbar.asm, pc1-bmp.asm, and demo6.asm.

---

# ⚠️ **Source Verification Notice**

This document uses information from multiple sources. **Only trust information marked as VERIFIED.**

### ✅ VERIFIED ON REAL PC1 HARDWARE:
- Working code: colorbar.asm, pc1-bmp.asm, demo6.asm, BB.asm
- Simone Riminucci's discoveries and mouse driver (tested on real PC1)
- PERITEL.COM behavior (tested on real PC1)

### ⚠️ CORROBORATING SOURCES (Same V6355 chip, different systems):
- **ACV-1030 Video Card Manual** — Third-party card using V6355, explicitly documents bit 6 = 16-color mode
- **Yamaha V6355/V6355D Datasheets** — Official manufacturer specs (electrical, timing)

### ❌ UNVERIFIED SOURCES (Different hardware implementation):
- **Zenith Z-180 Manual** — Laptop with LCD focus, may differ from PC1
- **John Elliott Documentation** — Some claims not tested, some known errors

Information from unverified sources is marked with *(unverified)* throughout this document.

---

# 🟦 1. **VRAM Layout** ✅

*Verified by working code.*

The PC1 has **16 KB of video RAM**, mirrored four times in the memory map:

```
B0000–B3FFF  (16 KB)
B4000–B7FFF  (mirror)
B8000–BBFFF  (mirror)
BC000–BFFFF  (mirror)
```

The segment address **B000h** is used (not B800h like standard CGA).

### CGA-Style Interlacing
The VRAM uses CGA-compatible interlaced layout:
- **Even rows (0, 2, 4...)**: offset = (row/2) × 80, starting at 0x0000
- **Odd rows (1, 3, 5...)**: offset = (row/2) × 80, starting at 0x2000
- Each bank is 8KB (100 rows × 80 bytes per row)

---

# 🟦 2. **Hidden Graphics Mode: 160×200×16** ✅

*Verified by working code.*

This mode provides:
- **160×200 resolution** (actually 320×200 with pixel doubling)
- **16 colors** from a programmable **512-color palette**
- **4bpp packed pixels** (2 pixels per byte: high nibble = left, low nibble = right)
- **80 bytes per row** (160 pixels ÷ 2)

---

# 🟦 3. **Yamaha V6355D I/O Ports** ✅

*Verified by working code.*

| Port | Alias | Function |
|------|-------|----------|
| **0xDD** | 0x3DD | Register Bank Address (select register 0x00–0x7F) |
| **0xDE** | 0x3DE | Register Bank Data (read/write selected register) |
| **0xD8** | 0x3D8 | Mode Control Register (CGA compatible + extensions) |
| **0xD9** | 0x3D9 | Color Select / Border Color (0–15) |
| **0xDA** | 0x3DA | Status Register (bit 0=HSync, bit 3=VBlank) |

Note: 0xDD/0xDE and 0x3DD/0x3DE are aliases and work identically on PC1.

---

# 🟦 3b. **V6355D Chip Specifications (from Datasheet)** ✅

*Source: Official Yamaha V6355D datasheet — electrical specs are trusted.*

The Yamaha V6355D (LCDC - LCD/CRT Display Controller) is a silicon gate CMOS device.

### Package Variants
| Package | Pins | Description |
|---------|------|-------------|
| **V6355D-F** | 100 | Plastic Flat Package (QFP) |
| **V6355D-J** | 84 | Plastic Chip Carrier (PLCC) |

### Key Features (from Yamaha datasheet)
- Controls both LCD and CRT displays
- Includes 6845 restricted mode for IBM-PC compatibility
- Both SRAM and DRAM usable as VRAM
- Includes MOUSE and LIGHT PEN interface
- 16×16 hardware cursor (AND and XOR screens)
- Color palette: 16 colors from 512
- LCD intensity: 16 or 8 gradation steps
- Screen modes: 640/320/512/256 × 192/200/204/64
- CRT monitor support: IBM Color, Monochrome, NTSC, PAL
- 16-bit bus CPU compatible

### Master Clock
- **14.31818 MHz** external clock (DCK pin outputs divided clock for CPU)

### Electrical Characteristics

#### Absolute Maximum Ratings
| Parameter | Min | Max | Unit |
|-----------|-----|-----|------|
| Supply voltage (VDD) | -0.5 | +7.0 | V |
| Input/Output voltage | VSS | VDD+0.5 | V |
| Operating temp | 0 | +70 | °C |
| Storage temp | -50 | +125 | °C |

#### Recommended Operating Conditions
| Parameter | Min | Typ | Max | Unit |
|-----------|-----|-----|-----|------|
| Supply voltage (VDD) | 4.75 | 5.0 | 5.25 | V |
| Operating temp | 0 | 25 | 70 | °C |

#### DC Characteristics
| Parameter | Condition | Min | Max | Unit |
|-----------|-----------|-----|-----|------|
| High output (TTL) | IOH=-0.4mA | 2.7 | — | V |
| Low output (TTL) | IOL=0.8mA | — | 0.4 | V |
| High output (CMOS) | IOH<1μA | VDD-0.4 | — | V |
| Low output (CMOS) | IOL<1μA | — | 0.4 | V |
| High input voltage | — | 2.2 | — | V |
| Low input voltage | — | — | 0.8 | V |
| Supply current (normal) | RL=5.6KΩ | — | 70 | mA |
| Supply current (standby) | RL=5.6KΩ | — | 50 | mA |
| Clock input high | — | 3.6 | — | V |
| Clock input low | — | — | 0.6 | V |

### Key Pin Functions (for hardware hackers)
| Pin | I/O | Function |
|-----|-----|----------|
| IOR | I | Read enable for I/O register (active low) |
| IOW | I | Write enable for I/O register (active low) |
| IOSEL | I | I/O register address decode (selected at low) |
| A0-A3 | I | I/O register address |
| MEMSEL | I | Memory address decode (selected at low) |
| MEMR | I | Memory read enable (active low) |
| MEMW | I | Memory write enable (active low) |
| MEMRDY | O | VRAM access ready (busy/wait at low, hi-Z when MEMSEL high) |
| WE | O | Write enable for memory |
| BDIR | O | Bi-directional buffer direction control |
| RESET | I | Reset signal |
| CD0-CD7 | I/O | Data bus with CPU |
| RD0-RD7 | I/O | Data bus with VRAM |
| AD0-AD7 | O | VRAM address (SRAM mode) |
| AD8/CLK | O | VRAM address (DRAM mode) |
| LSEL | O | First 8KB bank selected |
| HSEL | O | Second 8KB bank selected |
| RAS | O | CPU row address enable |
| CAS | O | CPU column address enable |
| DCK | O | Divided clock output (14.31818 MHz ÷ N) |

### I/O Timing Requirements (Critical!)
From the datasheet, the V6355D has strict timing requirements:

| Parameter | Minimum | Unit |
|-----------|---------|------|
| I/O Cycle Time (tCYC) | **300** | ns |
| Read/Write Low Pulse | 120 | ns |
| Read/Write High Pulse | 120 | ns |
| Address Setup Time | 40 | ns |
| Data Setup Time | 60 | ns |
| Data Hold Time | 10 | ns |

**Why delays are required:** The 300ns minimum cycle time is longer than what fast CPUs (like the 80186 at 8MHz) naturally provide. The `jmp short $+2` instruction adds approximately 15+ clock cycles of delay, ensuring the I/O cycle completes before the next access. Without these delays, palette writes and register changes may be corrupted or ignored.

---

# 🟦 4. **How to Enable the Hidden Graphics Mode** ✅

*Verified by working code (colorbar.asm, pc1-bmp.asm).*

## ⭐ THE ONLY REQUIRED STEP:
```asm
mov al, 0x4A        ; Magic value to unlock 16-color mode
out 0xD8, al        ; Write to Mode Control Register
```

**That's it!** Writing **0x4A to port 0xD8** is all you need to enable the hidden mode.

Bit breakdown of **0x4A** (01001010b):
- Bit 0: [0] = 40-column text mode
- Bit 1: [1] = Graphics mode enable
- Bit 3: [1] = Video output enable
- **Bit 6: [1] = MODE UNLOCK** — This enables 16-color planar logic!
- Bit 7: [0] = Normal operation (not standby)

---

## Optional Steps (for specific configurations):

### Optional: Set BIOS Mode 4 first
```asm
mov ax, 0x0004      ; CGA 320x200 graphics mode
int 0x10            ; Sets CRTC for proper 15.7kHz sync
```
Useful if you want BIOS to initialize CRTC timing before switching to hidden mode.

### Optional: Configure Register 0x67 (Horizontal Position)
```asm
mov al, 0x67
out 0xDD, al        ; Select register 0x67
mov al, 0x18        ; 8-bit bus mode + horizontal position
out 0xDE, al
```
Bit breakdown:
- Bit 7: [0] = 8-bit bus mode (PC1 has 8-bit bus, NOT 16-bit!)
- Bit 6: [0] = 4-page video RAM OFF (PC1 only has 16KB)
- Bit 5: [0] = LCD control period (CRT timing)
- Bits 3-4: [11] = Display timing/centering
- Bits 0-2: [000] = Horizontal centering offset

⚠️ **Note:** If you run **PERITEL.COM** before your program, it sets register 0x67 to adjust horizontal position for SCART monitors. Your program will overwrite this if you set 0x67. To preserve PERITEL's setting, skip the 0x67 write.

### Optional: Configure Register 0x65 (Monitor Control)
```asm
mov al, 0x65
out 0xDD, al        ; Select register 0x65
mov al, 0x09        ; 200 lines, PAL, color, CRT
out 0xDE, al
```
Bit breakdown:
- Bits 0-1: [01] = 200 vertical lines (00=192, 01=200, 10=204)
- Bit 2: [0] = 320/640 horizontal width (used for 160 with double pixels)
- Bit 3: [1] = PAL/50Hz (clear for NTSC/60Hz)
- Bit 4: [0] = CGA color mode
- Bit 5: [0] = CRT (not LCD)
- Bit 6: [0] = Dynamic RAM
- Bit 7: [0] = Light-pen

💡 **Note:** Register 0x65 is usually **not needed** because the PC1 BIOS defaults are already correct: PAL timing, 200 lines, CRT mode, 320 width (which becomes 160 with double pixels in the hidden mode).

### Optional: Set Border Color
```asm
xor al, al
out 0xD9, al        ; Black border (color 0-15)
```

---

# 🟦 5. **Palette Programming (V6355D DAC)** ✅

*Verified by working code (colorbar.asm, pc1-bmp.asm).*

The V6355D has an integrated **3-bit DAC per channel**, providing a **512-color palette** (8 × 8 × 8 = 512 possible colors).

### DAC Specifications:
- **3 bits per channel** (Red, Green, Blue)
- **8 intensity levels** per channel (0-7)
- **512 total colors** available (8³)
- **16 simultaneous colors** on screen (selected from the 512)
- **32 bytes** of palette data (16 colors × 2 bytes each)

### Palette Data Format (2 bytes per color):
```
Byte 1: [-----RRR]  Red intensity (bits 0-2, values 0-7)
Byte 2: [0GGG0BBB]  Green (bits 4-6) + Blue (bits 0-2)
```

### Palette Write Sequence:
```asm
cli                         ; Disable interrupts during palette write
mov al, 0x40
out 0xDD, al                ; Enable palette write mode (starts at color 0)
jmp short $+2               ; I/O delay required!

; Write 32 bytes (16 colors × 2 bytes each)
mov cx, 32
mov si, palette_data
.loop:
    lodsb
    out 0xDE, al
    jmp short $+2           ; I/O delay required between writes!
    loop .loop

mov al, 0x80
out 0xDD, al                ; Disable palette write mode
sti
```

### Converting 8-bit RGB to V6355D format:
```asm
; Input: 8-bit values in BL=Blue, BH=Green, AL=Red
; Convert 8-bit (0-255) to 3-bit (0-7) by taking upper 3 bits

; Red byte (bits 0-2)
shr al, 5                   ; Red >> 5 → 3-bit value
out 0xDE, al                ; Write red byte

; Green|Blue byte
mov al, bh                  ; Green
and al, 0xE0                ; Keep upper 3 bits
shr al, 1                   ; Shift to bits 4-6
mov ah, al                  ; Save green
mov al, bl                  ; Blue  
shr al, 5                   ; Convert to 3-bit
or al, ah                   ; Combine: 0GGG0BBB
out 0xDE, al                ; Write green|blue byte
```

### Color Intensity Levels:
| Value | Intensity |
|-------|-----------|
| 0 | 0% (off) |
| 1 | 14% |
| 2 | 29% |
| 3 | 43% |
| 4 | 57% |
| 5 | 71% |
| 6 | 86% |
| 7 | 100% (full) |

### Example: CGA-compatible colors
```asm
palette:
    ; Color 0: Black (R=0, G=0, B=0)
    db 0x00, 0x00           ; 0, 0|0
    ; Color 1: Blue (R=0, G=0, B=5)
    db 0x00, 0x05           ; 0, 0|5
    ; Color 2: Green (R=0, G=5, B=0)  
    db 0x00, 0x50           ; 0, 5<<4|0
    ; Color 4: Red (R=5, G=0, B=0)
    db 0x05, 0x00           ; 5, 0|0
    ; Color 7: White (R=5, G=5, B=5)
    db 0x05, 0x55           ; 5, 5<<4|5
    ; Color 15: Bright White (R=7, G=7, B=7)
    db 0x07, 0x77           ; 7, 7<<4|7
```

💡 **Note:** I/O delays (`jmp short $+2`) are **required** between palette writes. The PC1 hardware needs time to latch each value. Without delays, colors may be corrupted.

---

# 🟦 6. **Video Control (Blanking)** ✅

*Verified by working code.*

For flicker-free updates:
```asm
mov al, 0x42        ; Graphics mode, video OFF (blanked)
out 0xD8, al
; ... update VRAM ...
mov al, 0x4A        ; Graphics mode, video ON
out 0xD8, al
```

---

# 🟦 7. **VBlank Synchronization** ✅

*Verified by working code.*

Wait for vertical blanking:
```asm
wait_vblank:
    mov dx, 0x3DA
.wait_end:
    in al, dx
    test al, 0x08       ; Bit 3 = VBlank
    jnz .wait_end       ; Wait for VBlank to end
.wait_start:
    in al, dx
    test al, 0x08
    jz .wait_start      ; Wait for VBlank to start
    ret
```

---

# 🟦 8. **Returning to Text Mode** ✅

*Verified by working code.*

```asm
disable_graphics_mode:
    ; Reset register 0x65
    mov al, 0x65
    out 0xDD, al
    mov al, 0x09
    out 0xDE, al
    
    ; Reset mode control to text mode
    mov al, 0x28        ; Text mode (bit 5=blink, bit 3=video on)
    out 0xD8, al
    
    ; Restore BIOS text mode
    mov ax, 0x0003
    int 0x10
    ret
```

---

# 🟦 9. **Pixel Format** ✅

*Verified by working code.*

Each byte contains 2 pixels:
```
Byte value: [LLLLRRRR]
  - High nibble (bits 4-7) = Left pixel color (0-15)
  - Low nibble (bits 0-3) = Right pixel color (0-15)
```

Example: To draw a red pixel (color 4) and blue pixel (color 1):
```asm
mov al, 0x41        ; Red=4, Blue=1
mov [es:di], al
```

---

# 🟦 10. **Memory Calculation** ✅

*Verified by working code.*

- Screen: 160 × 200 = 32,000 pixels
- At 4bpp (2 pixels/byte): 16,000 bytes needed
- Actual VRAM: 16,384 bytes (16KB) — perfect fit!

Row address calculation:
```asm
; For row number in SI:
mov ax, si
shr ax, 1           ; AX = row / 2
mov bx, 80
mul bx              ; AX = (row/2) * 80
mov di, ax
test si, 1          ; Odd row?
jz .done
add di, 0x2000      ; Odd rows at bank 2
.done:
```

---

# 🟦 11. **Video Outputs on PC1** ✅

*Verified by Simone Riminucci (tested on real PC1).*

The PC1 has two video outputs, but only RGB analog supports the hidden mode:

### RGB Analog (SCART)
- Supports the hidden 160×200×16 mode
- Supports full 512-color palette
- Connected via SCART or Amiga-style RGB cable (e.g., to Commodore 1084s monitor)
- Use **PERITEL.COM** to adjust horizontal position for SCART monitors

#### Linear RGB Output Levels (from V6355 datasheet)
Useful for building custom SCART cables:

| Parameter | Min | Typical | Max | Unit |
|-----------|-----|---------|-----|------|
| Offset Voltage | 1.1 | 1.3 | 1.7 | V |
| Maximum Amplitude | 1.3 | 1.45 | 1.6 | V |
| Step Voltage (per level) | 0.14 | 0.21 | 0.27 | V |

- **Terminating resistor:** 5.6 kΩ between R, G, B terminals and GND
- **White level:** RGB = 777 (all at maximum 7)
- **Step voltage:** Each DAC level (0-7) increases output by ~0.21V

### RGBI Digital
- Outputs the same 160×200 resolution in hidden mode
- **Cannot use custom palette** — only standard CGA/EGA 16 colors
- Behaves like standard CGA digital output
- Not recommended for hidden graphics mode

### Composite Video
- The V6355D chip has composite output capability, but it is **disconnected** on the PC1 motherboard
- Attempts to use the composite pin produce unclear picture

#### Composite Specifications (from V6355 datasheet, for reference)
If you modify the hardware to enable composite output:

| Parameter | Min | Typical | Max | Unit |
|-----------|-----|---------|-----|------|
| Blanking Level | 1.2 | 1.5 | 1.9 | V |
| Black - Blanking | 70 | 85 | 100 | mV |
| Sync - Blanking | -0.35 | -0.38 | -0.42 | V |
| White - Black | 1.65 | 1.95 | 2.35 | V |
| HSY Pulse Width | 4.5 | — | — | μs |
| Color Burst Width | — | 2.7 | — | μs |

*(Terminating resistor: 5.6 kΩ for Y and CH terminals)*

*(Source: Simone Riminucci, vcfed.org forums)*

---

# 🟦 12. **Performance Limitations** ✅

*Verified by Simone Riminucci + our demo testing.*

### Racing the Beam: Not Possible

Simone Riminucci tested "racing the beam" techniques (changing palette mid-frame) and found:

> *"All tests to race the beam failed also on line basis. Changing 16 colors per line is too slow also for 80186, and I need to use many OUTs... maybe change only 4 colors could be achieved... but per line."*

**Our own testing confirms this:** In demo4, demo5, and demo6, we found that:
- Palette changes require I/O delays between each byte
- 32 bytes × I/O delay = too slow for per-scanline updates
- Mid-frame palette tricks are not practical on PC1

### VBlank is Your Only Window
- All palette updates should be done during VBlank
- Per-frame palette animation is possible (one full palette change per frame)
- Per-scanline palette changes are too slow

*(Source: Simone Riminucci, vcfed.org forums + our demo testing)*

---

# 🟦 13. **Video Player Optimization Techniques** ✅

*Verified by Simone Riminucci (achieved 25 FPS on real PC1).*

Simone Riminucci achieved **25 FPS video playback** using these techniques:

### Use the VRAM Mirrors for Multi-Frame Loading
The 16KB VRAM is mirrored 4 times (B000-BFFF). Simone exploited this:
> *"Because we have the video RAM repeated 4 times I loaded 4 frames each INT 13h call (loading 128 consecutive sectors from hard disk)."*

This means:
- Load 4 × 16KB = 64KB per disk read
- Each 16KB frame lands in its mirror
- Reduces disk I/O overhead significantly

### Pre-Interlace Your Data
> *"I had to load directly to video memory the byte flux already interlaced and exactly of 16384 bytes (instead of 16000)."*

- Pre-process video frames to match CGA interlaced layout
- Include the 384-byte gap (16,384 - 16,000 = padding between banks)
- No CPU time wasted on runtime interlacing

### Use Bulk Sector Reads
- 128 consecutive sectors = 64KB per INT 13h call
- Minimizes disk head movement
- Maximizes data throughput

*(Source: Simone Riminucci, vcfed.org forums)*

---
# 🟦 14. **Text and Font Rendering** ✅

*Verified by working code (demo6.asm).*

### The Problem: Hardware Font is Unusable

The PC1's hardware character generator does not work properly in the hidden 160×200×16 mode:

> *"When rendered in this mode, the hardware tries to create shadows around it, and it deforms, looking worse than composite mode."*

*(Source: Davide Ottonelli & Massimiliano Pascuzzi, YouTube interview)*

### The Solution: Software Font Rendering

You must draw text as bitmap graphics. Our demo6.asm implements this:

1. **Embed an 8×8 pixel font** as raw bitmap data (8 bytes per character)
2. **Render each character pixel-by-pixel** to VRAM
3. **Use the brightest palette color** for visibility

### Example: 8×8 Bitmap Font (from demo6.asm)
```asm
; Font bitmaps - 8 bytes per character (8x8 pixels)
font_0:
    db 0x3C  ; ..####..
    db 0x66  ; .##..##.
    db 0x6E  ; .##.###.
    db 0x76  ; .###.##.
    db 0x66  ; .##..##.
    db 0x66  ; .##..##.
    db 0x3C  ; ..####..
    db 0x00  ; ........
```

### Character Rendering Code Pattern
```asm
; For each font byte (8 pixels per row):
; Test each bit and write 2 pixels at a time to VRAM
mov al, [font_byte]
mov cl, [text_color]

; Bits 7,6 → first byte (2 pixels)
xor ah, ah
test al, 0x80           ; Left pixel?
jz .skip_left
mov ah, cl
shl ah, 4               ; Color in high nibble
.skip_left:
test al, 0x40           ; Right pixel?
jz .skip_right
or ah, cl               ; Color in low nibble
.skip_right:
mov [es:di], ah         ; Write 2 pixels
```

### Performance Note
Software font rendering is slow. For real-time applications like the FPS counter in demo6.asm, limit text updates to once per second.

---

# 🟦 15. **Related Systems**

The Yamaha V6355D chip was used in other computers:

### Zenith Z-180 / Z-181 / Z-183 Series *(unverified on PC1)*
- Uses V6355 (or similar) video controller
- Technical manuals available with detailed register descriptions
- **⚠️ WARNING:** Z-180 is a laptop with LCD focus — hardware implementation may differ from PC1
- **⚠️ WARNING:** Register behaviors described in Z-180 manual have NOT been verified on PC1
- Some researchers used these manuals as reference, but **working PC1 code should be trusted over Z-180 docs**

### IBM PCjr Heritage
The 160×200×16 mode originates from PCjr specifications:
> *"That video mode was in pre-production specification but was dropped in the final (maybe because after the PCjr market failure?)"*

*(Source: Simone Riminucci, vcfed.org forums)*

### Machines That Do NOT Support This Mode

| Machine | Reason |
|---------|--------|
| **Olivetti M24 / AT&T 6300** | Different video chip, not V6355D |
| **Olivetti M200** | Uses VLSI chip, different architecture |
| **Standard IBM CGA** | Original 6845 CRTC, no extended modes |

⚠️ **The hidden mode only works on machines with the Yamaha V6355D chip.**

---
# 🟦 16. **Hardware Sprite (16×16 Cursor)** ✅

*Verified by working code (BB.asm + Simone's mouse driver).*

The V6355D includes a hardware sprite engine, documented in the datasheet as:
> *"Cursor position can be specified by any 16 x 16 dot patterns in the bit unit (AND and EXOR screens)."*

This provides a **single hardware sprite** that moves independently of the framebuffer — perfect for mouse cursors or simple game objects.

### Sprite Specifications
- **Size:** 16×16 pixels (fixed)
- **Colors:** Monochrome (AND/XOR combination with background)
- **Position:** Pixel-accurate across entire screen
- **Performance:** Zero CPU overhead for rendering (hardware accelerated)

### Accessing the Hardware Sprite

The sprite is controlled via **INT 33h** (mouse driver). Simone Riminucci's mouse driver exposes the V6355D hardware sprite:

#### Load Mouse Driver First
```bash
mouse.com /I
```

#### INT 33h Functions for Sprite Control

| Function | AX | Description |
|----------|-----|-------------|
| **00h** | 0000h | Check driver / Reset (returns AX=FFFFh if loaded) |
| **01h** | 0001h | Show sprite |
| **02h** | 0002h | Hide sprite |
| **04h** | 0004h | Move sprite (CX=X, DX=Y) |
| **09h** | 0009h | Set sprite shape (ES:DX = 32-word mask) |

### Sprite Mask Format

The sprite uses two 16-word (32-byte) bitmaps:

```
[16 words] Screen Mask (AND)  - 0 = transparent, 1 = preserve background
[16 words] Cursor Mask (XOR)  - 1 = draw pixel, 0 = no change
```

### Example: Circular Ball Sprite (from BB.asm)

```asm
; Upload 16x16 circular sprite
mov ax, 09h             ; Function 09h: Set graphic pointer shape
mov bx, 8               ; Horizontal hot spot (center)
mov cx, 8               ; Vertical hot spot (center)
push cs
pop es
mov dx, sprite_mask     ; Pointer to mask data
int 33h

; Show sprite
mov ax, 01h
int 33h

; Move sprite to position
mov ax, 04h
mov cx, 320             ; X position
mov dx, 100             ; Y position
int 33h

; Sprite mask data (32 words total)
sprite_mask:
    ; Screen mask (AND) - circle hole in solid background
    dw 1111111111111111b    ; Row 0
    dw 1111111001111111b    ; Row 1
    dw 1111110000011111b    ; Row 2
    ; ... (16 rows total)
    
    ; Cursor mask (XOR) - solid circle
    dw 0000000000000000b    ; Row 0
    dw 0000000110000000b    ; Row 1
    dw 0000001111100000b    ; Row 2
    ; ... (16 rows total)
```

### Limitations

- **Only 1 hardware sprite** — for multiple sprites, use sprite multiplexing (see demo02)
- **Monochrome only** — sprite is single color (XOR with background)
- **Requires mouse driver** — must load Simone's INT 33h driver first
- **Position range:** X = 0-639, Y = 0-199 (virtual coordinates, doubled for 160×200 mode)

### Use Cases

- Mouse cursor
- Simple bouncing ball demos
- Single-object games
- Hardware-accelerated crosshair

*(See: PC1-Sprite-Demo-Repo/demos/01-bouncing-ball/BB.asm for full working example)*

---
# 🟧 17. **Unverified Information from John Elliott** ⚠️

*Source: John Elliott (seasip.info), May 2025. **NOT VERIFIED ON PC1** — may not work or may differ on real PC1 hardware.*

The following information comes from John Elliott's documentation. It has been cross-referenced against the Zenith Z-180 manual where possible, but **has not been tested on actual PC1 hardware**. Use with caution.

---

### 17a. Mouse Pointer Grid and Visible Screen Range *(John Elliott testing only)*

According to John Elliott's testing (not from any datasheet):

> *"The mouse pointer is positioned on a 512 × 256 grid, of which 16 ≤ X ≤ 335 and 16 ≤ Y ≤ 215 correspond to the visible screen."*

| Parameter | Value |
|-----------|-------|
| Pointer grid | 512 × 256 |
| Visible X range | 16 to 335 |
| Visible Y range | 16 to 215 |
| Default position | (0,0) — off-screen, pointer not visible |

⚠️ **Status:** John's own testing, not confirmed by any datasheet or PC1 testing.

---

### 17b. Register 0x62 Discrepancy *(Z-180 vs John Elliott)*

There is a **discrepancy** between sources:

| Source | Register 0x62 Function |
|--------|------------------------|
| Z-180 Manual | Cursor Y position (low byte) |
| John Elliott | "Not used" |

⚠️ **Status:** Conflicting information. Neither verified on PC1.

---

### 17c. Register 0x64 Vertical Adjustment *(Confirmed by Z-180)*

Both John Elliott and Z-180 manual agree on this:

> *"Bits 3-5: Vertical adjustment (number of rows to move the screen up)"*

```
Register 0x64:
    Bits 0-2: Mouse pointer visibility
        Bit 0: Pointer blinks
        Bit 1: Apply AND mask
        Bit 2: Apply XOR mask
    Bits 3-5: Vertical adjustment (rows to shift screen up)
    Bits 6-7: Reserved (leave as 0)
```

⚠️ **Status:** Confirmed by Z-180 manual, not verified on PC1.

---

### 17d. Register 0x66 LCD Driver Settings *(From John Elliott)*

John Elliott documents additional LCD-related bits:

```
Register 0x66 (Display Control):
    Bits 0-1: LCD vertical position (multiply by 2 for offset)
    Bits 2-3: LCD driver type:
        0 = Dual, 1-bit serial
        1 = Dual, 4-bit parallel
        2,3 = Dual, 4-bit intensity
    Bits 4-5: LCD driver shift clock frequency
    Bit 6: MDA greyscale mode (text attributes as MDA, not CGA)
    Bit 7: Underline blue foreground characters
```

⚠️ **Status:** From John Elliott. LCD settings not applicable to PC1 (CRT only). Bits 6-7 may work on PC1 but untested.

---

### 17e. Register 0x67 Additional Bits *(From John Elliott)*

Extended documentation of register 0x67:

```
Register 0x67 (Configuration Mode):
    Bits 0-4: Horizontal position adjustment
    Bit 5: LCD control signal period
    Bit 6: Enable 4-page video RAM (64KB systems only, NOT PC1)
    Bit 7: Enable 16-bit bus (if set on 8-bit bus → only odd bytes accessible)
```

⚠️ **Status:** From John Elliott. Verified that bit 7=0 required on PC1 (8-bit bus). Bit 6 not applicable (PC1 has 16KB only).

---

### 17f. Auto-Increment Behavior Difference *(From John Elliott)*

John Elliott notes different behavior between systems:

> *"When I tried to use the autoincrement to program a mouse pointer shape, I found that the same code worked reliably on the Prodest PC1 but led to random corruption on the ACV-1030. On the latter it proved necessary to select each register manually before programming it."*

⚠️ **Status:** Suggests PC1 has reliable auto-increment. ACV-1030 has different timing requirements.

---

### 17g. BIOS Data Area Locations *(From John Elliott)*

John Elliott documents PC1 BIOS usage of memory at segment 0x40:

| Offset | Size | Description |
|--------|------|-------------|
| 0x88 | BYTE | Not used on PC1 (Z8000 coprocessor on M24) |
| 0x89 | BYTE | Last value written to port 0x68 |
| 0x8A | BYTE | BIOS flags (bit 0=Turbo, bit 1=video init, bit 2=expansion) |
| 0x8C | BYTE | 0x40 if mode 0x40 selected, else 0 |
| 0x8F | WORD | "Real" equipment word (returned by INT 0x11) |
| 0x91 | BYTE | Last value read from port 0x62 |

⚠️ **Status:** From John Elliott's BIOS disassembly. May be useful for debugging but not verified.

---

### 17h. Port 0x3DF Display Page Selection *(From John Elliott)*

For systems with 64KB video RAM (NOT PC1):

> *"On systems with 64k video RAM, port 0x3DF is used to select one of four 16k pages."*

⚠️ **Status:** Does NOT apply to PC1 (only 16KB VRAM). Included for completeness.

---
# �🟩 **Summary Table**

| What | Value |
|------|-------|
| Video segment | B000h |
| Screen size | 160×200×16 colors |
| Bytes per row | 80 |
| VRAM total | 16KB interlaced |
| Mode unlock port | 0xD8 |
| Mode unlock value | **0x4A** |
| Palette port | 0xDD/0xDE |
| Status port | 0x3DA (bit 3 = VBlank) |

---

# 🟩 **Corrections from Original Document**

The original document had several inaccuracies. Here are the corrections:

1. **"C-ports (C0h–CFh)"** — WRONG. The mode control is at ports **0xD8/0xD9** and registers are accessed via **0xDD/0xDE**. There are no C0h-CFh ports.

2. **"FFFx ports required for ASIC reset"** — NOT REQUIRED for graphics mode. The working code does not use FFFx ports at all.

3. **"1 byte = 1 pixel"** — WRONG. The mode uses **packed nibbles: 2 pixels per byte** (4bpp).

4. **"We still need to find the exact values"** — SOLVED. The key is writing **0x4A to port 0xD8** (Mode Control Register with bit 6 set).

5. **"CRT controller (3DD/3DE) controls timing"** — PARTIALLY WRONG. Ports 0xDD/0xDE are the Register Bank ports for accessing internal V6355D registers (like 0x65 and 0x67), not just CRT timing.

---

# 🟩 **Final One-Sentence Summary**

**The PC1's hidden 160×200×16 graphics mode is enabled by a single I/O write: `OUT 0xD8, 0x4A` — that's all that's required, since the BIOS defaults for registers 0x65 and 0x67 are already correct for PAL/CRT operation.**

---

# 🟩 **Minimal Working Code**

```asm
; Enable hidden 160x200x16 graphics mode (minimum required)
mov al, 0x4A
out 0xD8, al

; Now write pixels to B000:0000
; High nibble = left pixel, Low nibble = right pixel
mov ax, 0xB000
mov es, ax
xor di, di
mov al, 0x12        ; Color 1 left, Color 2 right
stosb

; Return to text mode when done
mov al, 0x28
out 0xD8, al
mov ax, 0x0003
int 0x10
```

---

# 🟩 **Chip Manufacturer Information**

The V6355D was manufactured by Yamaha (then known as Nippon Gakki Co., Ltd.):

**NIPPON GAKKI CO., LTD.**  
Electronic System Division

**Toyooka Factory**  
203, Matsunokijima, Toyooka-mura, Iwata-gun, Shizuoka-ken, 438-01  
Electronic Equipment business section  
Tel. 053962-3125 | Fax. 053962-5054

**Tokyo Office**  
3-4, Surugadai Kanda, Chiyoda-ku, Tokyo, 104  
Ryumeikan Bldg. 4F  
Tel. 03-255-4481

**Osaka Office**  
1-6 Shin-ashiya shita, Suita-city, Osaka-fu, 565  
Tel. 06-877-7731

**U.S.A.**  
YAMAHA International Corp.  
6600 Orangethorpe Ave.  
Buena Park, California 90620

---

# 🟩 **References & Sources**

### ✅ TRUSTED (Verified on PC1):
1. **Working ASM Code** — colorbar.asm, pc1-bmp.asm, demo6.asm, BB.asm (proven on real hardware)
2. **Simone Riminucci** — vcfed.org forums, discovered the hidden mode (tested on real PC1)
3. **ACV-1030 Video Card Manual** — Third-party card with same V6355 chip, confirms bit 6 = 16-color mode

### ⚠️ REFERENCE ONLY (Electrical specs trusted, register behavior unverified):
4. **Yamaha V6355D (LCDC) Data Sheet** — Official Yamaha documentation (electrical/timing specs)
5. **Yamaha V6355 (LCDC) Data Sheet** — More detailed technical specifications

### ❌ UNVERIFIED (Use with caution):
6. **Zenith Z-180/Z-181 Technical Manuals** — Different hardware, register behavior may differ from PC1
7. **John Elliott (seasip.info)** — Some claims unverified; see **Section 17** for documented information with disclaimers
8. **Davide Ottonelli & Massimiliano Pascuzzi Interview** — Contains known technical errors (wrong palette format)
