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

# 🟦 5b. **Advanced: Per-Scanline Palette Manipulation & Timing Limits** ✅

*Verified by practical testing on real PC1 hardware (February 2026, palram5.asm experiment).*

While section 5 covers per-frame palette changes during VBlank, this section documents the theoretical possibility—and practical limitations—of changing palette entry 0 **multiple times within a single scanline** for horizontal color effects.

### Practical Experiment: palram5.asm

A comprehensive test (palram5.asm) attempted to write palette entry 0 repeatedly during the visible scanline period to create horizontal color bands. The experiment revealed important timing constraints.

### Timing Budget Analysis

**Scanline Duration (CRT drawing one horizontal line):**
- Total scanline time: ~63.5 microseconds
  - HBLANK (horizontal blanking): ~10 μs (80 CPU cycles @ 8MHz)
  - Visible area: ~53 μs (424 CPU cycles @ 8MHz)
  - **Total per scanline: ~509 CPU cycles**

**Palette Write Sequence Cost:**
- Address register select: ~7 cycles (OUT instruction)
- Data write 1 (R value): ~7 cycles
- Data write 2 (G|B value): ~7 cycles
- **Per write total: ~21 cycles**

**Theoretical Writes Per Scanline:**
- Full scanline budget: 509 cycles
- Per-write cost: 21 cycles
- **Theoretical maximum: ~24 writes per scanline**
- **Practical maximum (with delays): ~15-20 writes**

### The Critical Jitter Problem: Polling HSYNC

**Unavoidable Horizontal Position Jitter:**

The HSYNC polling loop introduces unpredictable delays:

```asm
.wait_visible:
    in al, dx           ; 7 cycles - Read status port
    test al, 0x01       ; 2 cycles - Test HSYNC bit
    jnz .wait_visible   ; 3 cycles (if jumping) = 12 cycles/iteration
```

When HSYNC transitions from HIGH to LOW, your code may catch it at **any point** in this polling loop:
- **Best case:** Detected immediately → ~2 cycle latency from transition
- **Worst case:** Just missed it → ~12 more cycles until next detection
- **Observed jitter:** ~4-8 pixels (typical ~10 cycle difference = 2.5 μs → 4 pixels @ ~160 pixels/53μs)

**This jitter is UNAVOIDABLE with polling.** It's not a bug—it's a fundamental limitation of interrupt-free, polled synchronization. Even professional demo code experiences similar jitter with this technique.

**Test Results:**
- ✅ Vertical stripe alignment is perfect (setup timing works)
- ✅ Observed horizontal jitter matches theoretical calculations
- ⚠️ Jitter is 4-8 pixels—noticeable but acceptable for most effects

### Critical Optimization: Setup During HBLANK

**Wrong approach (introduces extra jitter):**
```asm
.wait_high:
    in al, dx
    test al, 0x01
    jz .wait_high
    
    ; PROBLEM: Setup code here delays first write!
    push cx
    xor si, si
    mov cl, [writes_per_line]
    xor ch, ch
    
    ; Now wait for visible...
    .wait_visible: ...
    ; First write happens late—variable delay!
```

**Correct approach (minimizes jitter):**
```asm
.wait_high:
    in al, dx
    test al, 0x01
    jz .wait_high
    
    ; Setup DURING HBLANK (while HSYNC HIGH)
    push cx
    xor si, si
    mov cl, [writes_per_line]
    xor ch, ch
    
    ; Wait for visible—now first write happens IMMEDIATELY!
    .wait_visible:
    in al, dx
    test al, 0x01
    jnz .wait_visible
    
    ; First OUT instruction executes ~7 cycles after HSYNC LOW
    mov al, 0x40
    out PORT_PAL_ADDR, al
```

Moving setup to HBLANK reduces variance in first-write timing from ~50+ cycles to ~7 cycles, reducing jitter from 12+ pixels to 1-2 pixels. Still present due to polling variance, but minimized.

### Scanline Skipping: The Delay Penalty

**Problem:** Excessive delays between palette writes cause the main loop to exceed scanline duration.

**Example that FAILS:**
```asm
mov al, [test_colors + bx]
out PORT_PAL_DATA, al
    
; Large delay loop (WRONG!)
push cx
mov cx, 10          ; 10 iterations of loop
.delay:
    loop .delay     ; ~3 cycles per iteration = 30+ cycles total
pop cx

; Result: Each write takes ~20 + 30 = 50 cycles
; 8 writes = 400 cycles in just the write loop
; Plus setup/jump overhead = ~450+ cycles per scanline
; Exceeds 509 cycle budget!
```

**Observed Effect in palram5.asm Test:**
- With 8 writes × 10-cycle delays: Total = ~568 cycles (exceeds 509-cycle scanline budget)
- Only ~2-3 scanlines fit in each frame's ~17ms window
- Result: Only **~68 of 200 scanlines get processed** (200 ÷ 3 ≈ 67)
- **Visible on screen:** Only the first third of screen shows stripes; rest blank

**Solution:** Use minimal delays (just 3 NOPs) to space writes without excessive overhead:
```asm
mov al, [test_colors + bx]
out PORT_PAL_DATA, al

; Minimal delay (CORRECT)
nop
nop
nop

; Result: Each write = ~20 + 9 = 29 cycles
; 8 writes = 232 cycles (well within budget)
; All 200 scanlines process per frame ✅
```

### Polling vs Interrupt Methods Comparison

Two fundamentally different synchronization approaches exist:

#### Method A: Polling HSYNC (This Hardware, palram5.asm)
**Advantages:**
- ✅ Simple to implement
- ✅ No interrupt handlers needed
- ✅ Works on V6355D (no interrupt output documented)

**Disadvantages:**
- ❌ 4-8 pixel horizontal jitter (inherent)
- ❌ CPU dedicated to polling (can't do other work)
- ❌ Tight cycle budget (must minimize code)

**Code pattern:**
```asm
.wait_high:
    in al, dx           ; Poll until HSYNC high (HBLANK)
    test al, 0x01
    jz .wait_high
    
    ; Setup here during HBLANK
    
.wait_visible:
    in al, dx           ; Poll until HSYNC low (visible starts)
    test al, 0x01
    jnz .wait_visible
    
    ; Writes here at precise pixel 0
```

#### Method B: PIT Timer Interrupts (8088mph, Area 5150, Kefrens Bars)
**Used by:** Professional demo scene code on CGA-compatible systems

**Advantages:**
- ✅ Zero horizontal jitter (hardware-timed)
- ✅ CPU can do other work between interrupts
- ✅ Very precise synchronization

**Disadvantages:**
- ❌ Requires PIT (8253/8254 timer chip) to be accessible
- ❌ Requires careful timer calibration to match CRT frequency
- ❌ Not verified to work on V6355D (different timing than CGA)

**Code pattern (from Kefrens source):**
```asm
; Program PIT to generate IRQ0 at scanline frequency
writePIT16 0, 2, 76*262    ; ~59.923Hz @ 262 scanlines = one interrupt per scanline
setInterrupt 8, interrupt8 ; Install ISR

; ISR fires with zero jitter
interrupt8:
    mov al,0x20
    out 0x20,al             ; Acknowledge PIC
    ; Write palette here—perfectly timed!
    iret
```

**Why Not Use PIT on PC1?**
- The V6355D datasheet does not document per-scanline interrupt generation
- CGA's PIT synchronization relies on specific CRTC timing (which V6355D may not match exactly)
- The interrupt frequency would need to match the V6355D's 50Hz PAL vertical timing (not the CGA standard 60Hz NTSC)
- No verified working example on PC1 hardware (unlike polling, which is proven)

**Conclusion:** For V6355D, polling is the proven method. PIT interrupts may be theoretically possible but require undocumented research and careful calibration.

### Color Resolution Within a Scanline

**With 8 palette writes per scanline:**
- 160 pixels ÷ 8 writes = ~20 pixels per color band
- Creates clearly visible vertical stripes on RGB monitors
- Each stripe is a distinct horizontal color

**With 16 palette writes per scanline (maximum practical):**
- 160 pixels ÷ 16 writes = ~10 pixels per color band
- Creates narrow horizontal lines
- Approaches smooth gradients at screen resolution

**With 3 NOPs between writes:**
- Each write takes ~29 cycles
- 16 writes = 464 cycles (just fits in 509-cycle budget)
- Minimal delays mean writes are evenly spaced in time = evenly spaced in pixels
- Creates uniform horizontal banding pattern

### Research Findings Summary

| Finding | Impact | Workaround |
|---------|--------|-----------|
| **Polling jitter 4-8 pixels** | Unavoidable | Use for visual effects, not precise positioning |
| **Scanline skipping with large delays** | Visible (200→68 lines) | Use minimal delays (NOPs only) |
| **Setup timing variance** | Reduces jitter by ~10x | Move setup to HBLANK before waiting |
| **No V6355D interrupt output** | Can't use PIT method | Stick with polling synchronization |
| **CPU cycle budget tight** | Limits write count | 15-20 writes practical max, not 24 theoretical |

### Reference: palram5.asm Implementation

The palram5.asm file in PC1-Labs/demos/05-scanline-palette/ demonstrates this technique:
- Polls HSYNC for synchronization
- Setup during HBLANK to minimize jitter
- Uses 3-NOP delays (no large loops)
- Processes all 200 scanlines per frame
- Adjustable write count (. and , keys) for testing different band counts
- Creates smooth horizontal color transitions within each scanline

### Use Cases for Per-Scanline Palette Writes

**Suitable for:**
- ✅ Horizontal gradient fills (smooth left-to-right color transitions)
- ✅ Scanline-based visual effects (each line renders different palette state)
- ✅ Pseudo-3D effects using palette as animation layer
- ✅ Educational timing demonstrations

**Not suitable for:**
- ❌ Precise horizontal raster positioning (jitter is visible)
- ❌ Text rendering (colors must be stable per character)
- ❌ Photo-realistic graphics (banding artifacts too obvious)

---

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

# 🟦 12b. **SCI0 Driver Lessons** ✅

*Verified by real PC1 hardware while building the SCI0 driver series (PC1-1..PC1-7).* 

- SCI entry point must use the 3-byte `E9` jump convention; a plain `jmp` can break keyboard/interrupt behavior.
- CGA interlace requires per-row interleaved writes; two-pass even/odd updates cause visible combing.
- Direct framebuffer to VRAM conversion (3 transfers) is faster than line/full buffering (4 transfers) on the 8-bit bus.
- Rectangle-aware updates are essential; full-frame copies are slower for typical SCI dirty regions.

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

### 17c. Register 0x64 Vertical Adjustment *(TESTED - WORKING)*

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

✅ **Status:** Confirmed by Z-180 manual and **VERIFIED on real PC1 hardware** — Register 0x64 works with ±8 line range (3-bit adjustment).

#### PC1 Hardware Test Results (February 2, 2026)

A comprehensive hardware test (scroll_test.asm) was performed on actual PC1 hardware to verify Register 0x64 functionality:

**Test Setup:**
- Graphics mode enabled (0x4A to port 0x3D8)
- Color bands displayed on screen (easy to detect vertical movement)
- Register 0x64 bits 3-5 written with values 0-7 (all possible 3-bit values)
- Tested in **160×200×16 graphics mode only**

**Test Results:**
| Observation | Result |
|-------------|--------|
| Write operations crash? | ❌ NO - Register 0x64 accepts writes without fault |
| Screen shifts vertically? | ✅ **YES!** - Screen shifts by 0-7 rows |
| Max scroll range? | ✅ **8 rows** (exactly 3 bits worth: 2³ = 8 values) |
| Matches Z-180 documentation? | ✅ **YES** - "Bits 3-5: Vertical adjustment (rows to shift)" confirmed |
| Colors affected during scroll? | ⚠️ YES - Color shifts observed during register write (side effect) |

**Conclusion:**
- Register 0x64 **DOES work** for vertical scrolling on Olivetti Prodest PC1
- Limited to ±8 line adjustments (intended for monitor calibration)
- For hardware scrolling within VRAM bounds, use CGA CRTC R12/R13 (see section 17f below)
- Register 0x64 useful for fine-tuning display position or micro-scrolling effects

**Recommendation:**
For smooth scrolling **within VRAM** (16KB = 200 rows), use **CGA CRTC R12/R13** via ports 0x3D4/0x3D5. For scrolling images **taller than VRAM**, software viewport copying is required. For small adjustments (±4 rows each direction), Register 0x64 is simpler and more direct.

**Note:** Test was performed in **graphics mode only** (0x4A). Register 0x64 behavior in text mode remains unknown.

---

### 17f. CGA CRTC R12/R13 Hardware Scrolling ✅ VERIFIED

*Verified on real PC1 hardware (February 2, 2026)*

The V6355D supports standard MC6845-compatible CRTC registers for hardware scrolling via the **Start Address** registers (R12 and R13).

#### Ports and Registers

| Port | Function |
|------|----------|
| 0x3D4 | CRTC Address Register (select register 0-17) |
| 0x3D5 | CRTC Data Register (read/write selected register) |

| Register | Name | Description |
|----------|------|-------------|
| R12 (0x0C) | Start Address High | High 6 bits of VRAM start address (word offset) |
| R13 (0x0D) | Start Address Low | Low 8 bits of VRAM start address (word offset) |

#### How It Works

The Start Address registers tell the CRTC where to begin reading VRAM for display. Changing this value makes the display "pan" through video memory instantly, with no CPU overhead during display.

```asm
; Set CRTC start address to word offset in AX
set_crtc_start:
    push ax
    push bx
    push dx
    
    mov bx, ax              ; Save word offset
    
    ; Write R12 (high byte)
    mov dx, 0x3D4
    mov al, 0x0C            ; Register 12
    out dx, al
    mov dx, 0x3D5
    mov al, bh              ; High byte of offset
    out dx, al
    
    ; Write R13 (low byte)
    mov dx, 0x3D4
    mov al, 0x0D            ; Register 13
    out dx, al
    mov dx, 0x3D5
    mov al, bl              ; Low byte of offset
    out dx, al
    
    pop dx
    pop bx
    pop ax
    ret
```

#### ⚠️ CRITICAL LIMITATION: VRAM-Only Addressing

**R12/R13 can ONLY address video memory (16KB at segment B000h).**

The CRTC reads from VRAM, not system RAM. This means:

| Image Size | VRAM Fit? | Scrolling Method |
|------------|-----------|------------------|
| 160×200 (16KB) | ✅ Yes | R12/R13 works but image already fills screen |
| 160×400 (32KB) | ❌ No | Software viewport copying required |
| 160×800 (64KB) | ❌ No | Software viewport copying required |

**Important clarification:** R12/R13 hardware scrolling works correctly on the V6355D. The limitation is that it can only pan through what's already in the 16KB VRAM. For images taller than 200 rows, the extra data must be stored in system RAM and copied to VRAM—R12/R13 cannot help with this.

For images **larger than VRAM**, you must:
1. Keep the full image in system RAM
2. Copy a 200-row viewport to VRAM each frame
3. R12/R13 cannot reduce this copying—use software blitting (demo7 approach)

We attempted to combine R12/R13 with a circular buffer technique (copy only 2 new rows per scroll, use R12/R13 to shift display) but this **failed due to the 384-byte gap problem** described below.

#### Scrolling Techniques Comparison

| Technique | Speed | Image Size Limit | Flicker | Notes |
|-----------|-------|------------------|---------|-------|
| **R12/R13 Hardware Scroll** | Instant | 200 rows (VRAM size) | None | Works, but limited to VRAM content |
| **Register 0x64 Fine Scroll** | Instant | ±8 rows adjustment | None | Monitor calibration only |
| **Software Viewport Copy** | Slow (~16KB/frame) | Unlimited | Yes (without vsync) | demo7.asm - only working method for tall images |
| **Circular Buffer + R12/R13** | ⚠️ FAILED | N/A | N/A | **384-byte gap bug** - see below |

#### Circular Buffer Technique (Advanced)

For scrolling images taller than VRAM with minimal flicker:

1. Fill VRAM with 200 rows initially
2. Use R12/R13 to scroll smoothly within VRAM
3. When approaching VRAM edge, copy 2 new rows into the "old" area
4. Wrap R12/R13 address back to beginning
5. Result: Only 160 bytes copied per 2-row scroll step, not 16KB

This combines fast hardware scrolling with minimal software updates.

#### ⚠️ THE 384-BYTE GAP PROBLEM (Circular Buffer Limitation) ✅ VERIFIED

*Verified on real PC1 hardware (February 2, 2026) - demo8a.asm*

**The circular buffer technique described above has a critical flaw that prevents it from working with 200-row displays.**

##### The Problem

CGA interlaced memory uses two 8KB banks, but each bank only needs 8000 bytes for 100 rows:

```
Even bank (0x0000-0x1FFF):
  - Used:   0x0000-0x1F3F = 8000 bytes (100 rows × 80 bytes)
  - Gap:    0x1F40-0x1FFF = 192 bytes (unused)
  
Odd bank (0x2000-0x3FFF):
  - Used:   0x2000-0x3F3F = 8000 bytes (100 rows × 80 bytes)
  - Gap:    0x3F40-0x3FFF = 192 bytes (unused)

Total gap: 192 × 2 = 384 bytes
```

##### Why Circular Buffer Fails

The V6355D/MC6845 CRTC wraps at **8192 bytes** (physical bank size), not 8000 bytes (logical display area):

| crtc_start_addr | What Gets Displayed |
|-----------------|---------------------|
| 0 | Rows 0-199 → ✅ Correct |
| 80 | Rows 2-199, then **GAP DATA** at bottom → ❌ Garbage! |
| 160 | Rows 4-199, then **MORE GAP DATA** → ❌ Garbage! |

**Example:** With `crtc_start_addr = 80` (scrolled down 2 rows):
- Display reads even bank offsets: 80, 160, 240, ... 7920, **8000**, 8080...
- Offset 8000-8079 is in the **gap area** (0x1F40-0x1F8F)
- Gap contains uninitialized/garbage data
- Result: Bottom row(s) of screen show random pixels

##### Visual Representation

```
Before scroll (crtc_start = 0):
┌──────────────────────────┐
│ Row 0   ← display start  │
│ Row 2                    │
│ Row 4                    │
│ ...                      │
│ Row 196                  │
│ Row 198 ← last visible   │
└──────────────────────────┘
Gap (hidden): bytes 8000-8191

After scroll (crtc_start = 80):
┌──────────────────────────┐
│ Row 2   ← display start  │
│ Row 4                    │
│ ...                      │
│ Row 198                  │
│ ████ GAP GARBAGE ████    │ ← reads from offset 8000+
└──────────────────────────┘
```

##### Demo Code Reference

- **demo8a.asm** — Demonstrates the circular buffer concept with the gap bug visible
- **demo8.asm** — Comprehensive documentation of all failed workaround attempts
- **demo7.asm** — Uses full viewport copy (16KB/frame) to avoid the gap problem

##### Workarounds Tested ✅ ALL FAILED

*All workarounds tested on real PC1 hardware (February 2, 2026)*

**Solution A: Gap Patching** ❌ FAILED
- **Idea:** Copy wraparound data into gap regions (offsets 8000-8191) so CRTC reads valid pixels when it reads from the gap.
- **Result:** When `crtc_start_addr` exceeds ~192 bytes, the display shows images offset 64-80 pixels to the right, then jumps to correct position partway down the screen.
- **Conclusion:** The V6355D does not handle CRTC address wrapping the same way as standard MC6845 CGA. Gap patching is fundamentally broken on this chip.

**Solution B: Reduced Viewport (196, 192, 180 rows)** ❌ NOT VIABLE
- **Idea:** Reduce visible rows via CRTC R6 so CRTC never reads into gap region.
- **Math:** 196 rows = 98 rows/bank = 352 byte headroom = only 4 fast scroll steps before refresh needed. 180 rows = 12 steps. 160 rows = 22 steps.
- **Result:** Would still require periodic refresh after headroom exhausted. Loses screen real estate for minimal gain.
- **Conclusion:** Not worth the tradeoff—loses visible area without solving the fundamental problem.

**Solution C: Hybrid Periodic Refresh** ❌ STUTTERS BADLY
- **Idea:** Fast circular updates for N frames, then full 16KB refresh when approaching gap.
- **Result:** With 192-byte gap limit, can only do 2 fast frames (160 bytes each) before mandatory 16KB refresh. Pattern of "fast-fast-slow" is visibly stuttery and worse than demo7's consistent slow speed.
- **Conclusion:** 2:1 ratio of fast:slow frames is not smooth enough for usable scrolling.

##### Why All Solutions Fail

The fundamental constraint is:
- **Gap size:** 192 bytes per bank (fixed by CGA interlaced memory layout)
- **Bytes per scroll step:** 80 bytes (1 row per bank = 2 visual rows)
- **Maximum fast scroll steps:** 192 ÷ 80 = **2.4 steps**

This means **any** approach using R12/R13 with 200 visible rows will require a full VRAM refresh every 2-3 scroll steps. There is no configuration of gap patching, viewport reduction, or hybrid refresh that avoids this limit while maintaining smooth scrolling.

##### Conclusion

**The circular buffer technique is fundamentally incompatible with 200-row CGA interlaced mode** due to the 384-byte gap and V6355D's non-standard CRTC address handling. For smooth scrolling of tall images, use software viewport copying (demo7 approach).

##### Future Investigation

The V6355D may have undocumented registers or modes that could enable:
- Different memory layouts without the gap
- Linear (non-interlaced) addressing
- Different CRTC address generation schemes

Until discovered, software viewport copying remains the only reliable method for scrolling tall images.

#### PC1 Hardware Test Results

**What works:**
- ✅ R12/R13 successfully pans display through VRAM
- ✅ Scrolling by 80 bytes = 1 line (for each bank)
- ✅ Works in 160×200×16 hidden graphics mode
- ✅ No visible tearing when updated during VBlank

**What doesn't work:**
- ❌ Cannot address system RAM (only 16KB VRAM visible)
- ❌ Images taller than 200 rows require software assistance
- ❌ Gap patching for circular buffer (V6355D has non-standard address wrapping)
- ❌ Reduced viewport doesn't provide enough headroom for smooth scrolling

#### Reference: 8088 MPH Credits Scroller

The famous 8088 MPH demo's credits scroller uses R12/R13 in **text mode** to scroll pre-loaded text through 16KB of text VRAM. They do NOT scroll images larger than VRAM—the entire scroll buffer fits in video memory.

```asm
; From 8088 MPH credits (text mode)
mov di,initialScrollPosition    ; Start at position 2064 in VRAM
mov cx,0x2000                   ; Fill 8KB words (16KB) of text VRAM
rep movsw                       ; Pre-load all text
; ...later use hCrtcUpdate to change Start Address for scrolling
```

---

### 17i. V6355D Memory Architecture Clarification ✅ FROM SIMONE

*Simone provided authoritative correction to memory architecture assumptions (February 6, 2026)*

The V6355D's relationship between internal and external addressing had been theorized as a potential workaround to CGA interlacing, but the actual architecture is:

#### Internal vs. External Addressing

**Memory Layout:**
- **Internally:** VRAM is **linear** — reads sequentially from offset 0x0000 onward
- **Externally:** CGA interlaced addressing is enforced by **hardware-locked address line swapping** at the pin level
- **Address swapping:** A0 line is swapped (inverted or rerouted) to split the memory visually into two 8KB banks
- **Speed:** The memory is fast enough for true linear operation, but the V6355D intentionally applies interlaced formatting at the hardware level

#### Why This Matters

1. **No undocumented linear mode:** There is no register or configuration that disables the address swapping. It is hardcoded in the silicon.
2. **Implications for developers:** You cannot bypass interlacing to achieve a single 16384-byte linear VRAM bank. The 384-byte gap in each 8KB bank is inherent to the CGA interlace format and cannot be avoided.
3. **Positive side effect:** The fast internal memory makes the V6355D reliable for rapid register updates (palette, scrolling) since physical memory cycles are not the bottleneck.

#### Dummy Registers

**CGA-derived registers that are non-functional on V6355D:**
All CGA/MC6845 emulation registers related to interlace control are **dummy registers** on the V6355D:
- Interlace mode register (R8)
- Interlace offset register (R16)
- Skew/line attribute registers

**Why:** These registers are irrelevant because interlacing is forced by hardware at the address line level, not through register control. The V6355D provides CGA-compatible register accesses for software compatibility, but the actual interlace behavior cannot be changed.

#### Implications for 320×200 Mode

For 320×200×4 color mode (which uses linear addressing naturally), the interlace overhead is not present, allowing full utilization of VRAM without the 384-byte gap.

---

### 17j. Dynamic Palette Switching Per Scanline ✅ VERIFIED BY SIMONE

*Simone demonstrated per-scanline palette switching on PC1 hardware (February 6, 2026)*

**Verified working on Olivetti Prodest PC1** — Simone provided photographic evidence of Sierra games (Monkey Island) running with 512 virtual colors on actual PC1 hardware using this technique.

#### Achieving 512 Virtual Colors in 320×200

The key insight: The V6355D supports **per-scanline CGA palette switching** by writing to port 0x3D8 during horizontal blanking, allowing different color combinations on each horizontal line.

#### The Two CGA Palettes (320×200×4 Mode)

In standard CGA 320×200×4 color mode, you have **4 simultaneous colors**: one background + three foreground colors from a fixed palette.

```
Palette 0 (Cyan/Magenta/White):
  Background: Any of 16 colors (selectable)
  Foreground 1: Cyan (dark or bright)
  Foreground 2: Magenta (dark or bright)
  Foreground 3: White (dark or bright)

Palette 1 (Green/Red/Yellow):
  Background: Any of 16 colors (selectable)
  Foreground 1: Green (dark or bright)
  Foreground 2: Red (dark or bright)
  Foreground 3: Yellow/Brown (dark or bright)
```

**Controlled by:** Port 0x3D8 (CGA Mode Control Register)
- Bit 5: Palette select (0 = Palette 0, 1 = Palette 1)
- Bit 4: Intensity (0 = dark colors, 1 = bright colors)
- Bits 0-3: Background color (0-15)

#### Switching Strategy

**Basic concept:**
1. **On Scanline N (during HSync):** Set Palette 0 + Background Color A + Intensity = Light
2. **Display scanline** with Cyan/Magenta/White palette
3. **On Scanline N+1 (during HSync):** Set Palette 1 + Background Color B + Intensity = Dark
4. **Display scanline** with Green/Red/Yellow palette
5. Repeat, alternating palettes and varying background colors per line

**Timing:**
- **HSync (horizontal blanking):** ~10 microseconds — safe time to update palette register
- **Active line rendering:** ~51 microseconds — prepare next line's palette configuration
- Each line gets **4 colors from one of two palettes**

#### Result: 512 Virtual Colors

**Calculation:**
- **2 palettes** (cyan/magenta/white vs green/red/yellow)
- **16 background colors** per palette
- **2 intensity levels** (dark vs bright foreground)
- **8 combinations per palette** (16 backgrounds × 2 intensity ÷ mixing = effective combinations)
- **Total: 2 × 16 × 16 = 512 unique color combinations** across 200 scanlines

Different scanlines can show completely different color sets, creating the appearance of far more than 4 simultaneous colors when viewed as a whole screen.

#### Implementation Requirements

1. **Mode:** CGA 320×200×4 (standard CGA graphics mode)
2. **Precise timing:** HSync interrupt or CRTC-based synchronization required
3. **Fast port writes:** Port 0x3D8 (Mode Control Register) updated every scanline
4. **Pre-calculated palette table:** 200-entry table with palette/background/intensity per line
5. **V6355D compatibility:** ✅ **VERIFIED working on PC1** (Simone, February 2026)

#### Code Strategy

```asm
; Pseudocode for per-scanline palette switching (320×200×4 mode)

    ; Enable 320×200×4 graphics mode
    mov ax, 0x0004
    int 0x10
    
scanline_loop:
    ; Wait for HSync (horizontal retrace)
    call wait_hsync
    
    ; Get palette byte for current scanline
    mov al, [palette_table + si]
    inc si
    
    ; Update CGA mode control register
    ; (changes palette, intensity, background instantly)
    mov dx, 0x3D8
    out dx, al
    
    ; Loop until all 200 scanlines rendered
    cmp si, 200
    jl scanline_loop

; Palette table (200 bytes, one per scanline):
palette_table:
    db 0x1D    ; Line 0: Palette 0, Bright, Background=Blue
    db 0x2E    ; Line 1: Palette 1, Bright, Background=Yellow
    db 0x1A    ; Line 2: Palette 0, Bright, Background=Green
    ; ...196 more entries
```

#### Advantages Over Dithering

| Technique | Colors per line | Total screen colors | Speed | Artifacts |
|-----------|----------------|---------------------|-------|----------|
| Standard 320×200×4 | 4 | 4 | Real-time | None |
| Palette switching per line | 4 | 512 virtual | Real-time (with precalc) | Horizontal color bands visible |
| Standard 160×200×16 | 16 | 16 | Real-time | None |
| Software dithering | 4 | 256 quasi | Slow (~3+ frames) | Dither patterns visible |

#### Comparison to 160×200×16 Mode

| Feature | 320×200×4 + Palette Switching | 160×200×16 (PC1 Hidden Mode) |
|---------|------------------------------|----------------------------|
| Horizontal resolution | 320 pixels | 160 pixels |
| Colors per scanline | 4 | 16 |
| Total unique colors per frame | 512 (via switching) | 16 (fixed palette) |
| Horizontal banding | Visible (different palettes) | None |
| Complexity | High (timing-critical) | Low (static palette) |

#### Potential for 160×200×16 Mode Extension

An unexplored possibility: If the V6355D's palette registers (0xDD/0xDE) can be updated during HSync in the hidden 160×200×16 mode, this could theoretically provide **256+ virtual colors** with 16 colors per scanline. This remains untested.

#### Applications

This technique is ideal for:
- **Sierra SCI games** with detailed backgrounds (Monkey Island, as demonstrated)
- Smooth vertical gradients (sky, water, sunsets)
- Title screens and static artwork with pre-calculated scanline palettes
- Games that can tolerate horizontal color banding

**Note:** Requires precise HSync timing and pre-calculated palette tables. Not suitable for fast-moving horizontal graphics where per-line color changes would create visible artifacts.

---

### 17k. Extended Row Support (204 rows) ✅ FROM SIMONE

*Simone confirmed undocumented capability for exceeding standard 200-row display (February 6, 2026)*

#### Hidden 204-Row Mode

The V6355D can display **204 rows** (16,320 bytes) instead of the standard 200 rows (16,000 bytes).

#### Memory Allocation

```
Standard 200-row mode:
  Even bank: 100 rows × 80 bytes = 8000 bytes
  Odd bank: 100 rows × 80 bytes = 8000 bytes
  Total used: 16,000 bytes
  
  Gap per bank: 192 bytes
  Total VRAM: 16,384 bytes

Extended 204-row mode:
  Even bank: 102 rows × 80 bytes = 8160 bytes
  Odd bank: 102 rows × 80 bytes = 8160 bytes
  Total used: 16,320 bytes (USE 4 ADDITIONAL BYTES!)
  
  Gap per bank: 32 bytes (reduced)
  Total VRAM: 16,384 bytes (still fits!)
```

#### Implementation

To enable 204-row mode:
1. Set CRTC register R6 ("Vertical Displayed Rows") to 204 (0xCC) instead of 200 (0xC8)
2. Adjust R7 ("Vertical Sync Position") proportionally
3. Adjust R9 ("Max Scan Line Address") to maintain proper interlace timing

**Exact register values:** To be determined through hardware testing.

#### Advantage Over Standard Mode

- **+320 additional bytes of VRAM** for image data
- **4 more scanlines** at the bottom of the display
- **Better circular buffer headroom:** 32-byte gap instead of 192-byte gap doubles viable scroll steps

#### Circular Buffer Re-evaluation

With 204-row mode's reduced gap:
- Maximum fast scroll steps: 32 ÷ 80 ≈ **0.4 steps** (worse than 200-row!)
- **Conclusion:** Even with extended rows, the gap remains a fundamental limitation. 204 rows provides storage capacity, not better scrolling.

#### Practical Use Cases

1. **Taller image storage:** 204-row display fills 16KB exactly with minimal waste
2. **Scrolling storage:** Can hold 8 independent 204-row frames with only 32-byte gaps (for offline scrolling effects)
3. **Sierra SCI adaptation:** Could store CGA images at near-native height with fewer cropping requirements

#### Status

- ✅ Information provided by Simone (February 2026)
- ✅ Theoretically sound based on V6355D CRTC capabilities
- ⚠️ Exact CRTC register values need hardware testing and verification
- ⚠️ May require display synchronization tuning to avoid artifacts

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
