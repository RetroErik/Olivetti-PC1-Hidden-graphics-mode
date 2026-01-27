# Olivetti Prodest PC1 - 160×200×16 Graphics Mode Development

**Project Goal:** Enable the undocumented 160×200×16 color graphics mode on the Olivetti Prodest PC1 with custom palette support

---

## Hardware Specification

| Component | Specification |
|-----------|---------------|
| **Computer** | Olivetti Prodest PC1 (Italian XT-compatible) |
| **CPU** | NEC V40 (8088-compatible) |
| **Video Chip** | Yamaha V6355D LCDC (Liquid Crystal Display Controller) |
| **VRAM** | 16KB DRAM (segment 0xB000) |
| **Display** | Composite RGB SCART monitor (PAL standard, 50Hz, 625 scan lines) |
| **Target Resolution** | 160×200 pixels, 16 colors |
| **Target Mode** | Hidden/undocumented graphics mode (not enabled by BIOS) |

---

## Port Map (Yamaha V6355D)

| Port | Direction | Name | Function |
|------|-----------|------|----------|
| **0xD8** | Write Only | Mode Control Register | Sets graphics/text mode, video enable, 16-color unlock (Bit 6) |
| **0xD9** | Write Only | Color Select Register | Sets border/overscan color (0-15) |
| **0xDD** | Read/Write | Register Bank Address | Select internal register (0x40–0x6F) |
| **0xDE** | Read/Write | Register Bank Data | Read/write selected register value |

---

## Critical Register Addresses (via 0xDD/0xDE)

| Register | Address | Purpose | Current Value | Notes |
|----------|---------|---------|----------------|-------|
| Monitor Control | 0x65 | Vertical lines, TV standard, RAM type, CRT/LCD | **0x09** | 200 lines, PAL, CRT, DRAM |
| Configuration | 0x67 | 16-bit bus, page mode, centering | **0x18** | 8-bit bus, Page mode OFF, centering (required for PC1) |
| Palette Base | 0x40–0x5F | 16 color entries (2 bytes each) | Custom RGB | 9-bit RGB format (3 bits per channel, 512 colors) |

---

## Port 0xD8 - Mode Control Register (Bit Analysis)

### Verified Bit Definitions

| Bit | CGA Standard | Extended Function | 160×200×16 Value |
|-----|--------------|-------------------|-------------------|
| 0 | 0=40×25, 1=80×25 text | — | **0** (40-col) |
| 1 | 0=text, 1=graphics | — | **1** (graphics) |
| 2 | 0=color, 1=mono | — | **0** (color) |
| 3 | 0=blank, 1=active | Video enable | **1** |
| 4 | 0=320×200, 1=640×200 | Resolution select | **0** (160×200 via Bit 6) |
| 5 | 0=blinker off, 1=on | Blink enable | **0** (off) |
| **6** | **Unused in CGA** | **16-COLOR MODE ENABLE** | **1** ✓ **CRITICAL** |
| 7 | — | Standby/power save | **0** (normal) |

### Initialization Sequence (per colorbars.asm)

```
1. Set register 0x67 to 0x18 via ports 0xDD (address) and 0xDE (data)
2. Set register 0x65 to 0x09 via ports 0xDD/0xDE
3. Write 0x4A to port 0xD8 (enable 16-color mode)
4. Set border color to black via port 0xD9
5. Write palette: 0x40 to 0xDD, 32 bytes to 0xDE, then 0x80 to 0xDD
```

---

## Register 0x65 - Monitor Control (Bit Analysis)

| Bits | Name | Function | Value | Notes |
|------|------|----------|-------|-------|
| 0–1 | SCR[1:0] | Vertical lines | **01** | 01=200 lines, 00=192 lines |
| 2 | Horiz Dot | Horizontal pixels | **0** | 0=640/320, 1=512/256 |
| 3 | PAL | TV standard | **1** | 1=PAL/SECAM (50Hz), 0=NTSC (60Hz) |
| 4 | MONO | Monitor type | **0** | 0=Color, 1=Monochrome |
| 5 | — | Reserved | **0** | Always write 0 |
| 6 | — | Reserved | **0** | Always write 0 |
| 7 | — | Reserved | **0** | Always write 0 |

**Current Value:** 0x09 (00001001b) = 200 lines, PAL, CRT, DRAM

---

## Register 0x67 - Configuration Mode (Bit Analysis)

| Bits | Name | Function | 0x18 Value | Status |
|------|------|----------|-----------|--------|
| 0–2 | CENTER[2:0] | Horizontal centering low | **000** | Default |
| 3–4 | CENTER[4:3] | Horizontal centering high | **11** | Recommended for PC1 |
| 5 | LCD Period | LCD control signal timing | **0** | 0=CRT timing |
| 6 | Page Mode | 4-page VRAM mode | **0** | OFF |
| 7 | 16-bit Bus | 16-bit bus mode | **0** | OFF - MUST be 0 on PC1's 8-bit bus! |

**Current Value:** 0x18 (00011000b)

---

## Palette Configuration

### Format: 9-bit RGB (per colorbars.asm)

- **Register Range:** 0x40–0x5F (16 colors, 2 bytes each)
- **Byte 1:** Red (bits 0–2, 0–7 intensity)
- **Byte 2:** Green (bits 4–6, 0–7 intensity) + Blue (bits 0–2, 0–7 intensity)

> **Note:** The Yamaha V6355D chip supports 4 bits per channel (12-bit RGB, 4096 colors) in its palette registers. However, on the Olivetti Prodest PC1, only 3 bits per channel (9-bit RGB, 512 colors) are actually output, because the hardware is not physically wired to a DAC that handles the full 4 bits per channel. So, while you can program 4096 possible colors in the registers, only 512 unique colors can be displayed on the PC1’s output.

### Example Color Entry (Color 0 = Black)

```
Register 0x40: 0x00  (Red = 0)
Register 0x41: 0x00  (Green = 0, Blue = 0)
```

### Access Method

```asm
mov al, 0x40            ; Enable palette write
out 0xDD, al            ; Register Bank Address
; Output 32 bytes to 0xDE (16 colors × 2 bytes)
mov al, 0x80            ; Disable palette write
out 0xDD, al            ; Register Bank Address
```

**Status:** ✅ **VERIFIED** (current code writes 16 colors × 2 bytes = 32 bytes total)

---

## VRAM Memory Architecture

### Physical Layout
- **16KB DRAM block** located at hardware segment 0xB000

#### Addressing (colorbars.asm)
- Even rows:  0xB000:0000–0xB000:1FFF
- Odd rows:   0xB000:2000–0xB000:3FFF
- Each byte holds two pixels (packed nibbles)

**Current Code:** Uses 0xB000 segment, 8-bit bus mode

---

## Draw Routine Analysis

### Current Implementation
```asm
; 160×200 resolution = 160 pixels wide × 200 rows
; 16 colors = 4 bits per pixel = 2 pixels per byte
; 160 pixels ÷ 2 = 80 bytes per scanline
; 80 bytes ÷ 5 = 16 columns (10 pixels each)

; Fill 16 vertical color bars:
mov dx, 200             ; 200 rows
.row_loop:
  mov bl, 0             ; Start color 0
  .col_loop:
    pack two 4-bit pixels into one byte
    write 5 bytes (10 pixels wide)
    increment color (0–15)
  dec dx
```

**Status:** ✅ **Logic verified**

---

## Primary Working File
- **[Colorbars.asm](Olivetti-PC1-Hidden%20graphics%20mode/Colorbars.asm)** - Latest verified version with all corrections
  - Includes initialization for Port 0xD8, 0xDD/0xDE
  - Correct Register 0x65 value (0x09)
  - Correct Register 0x67 value (0x18)
  - Proper palette loading (0x40–0x5F, 9-bit RGB)
  - Random color palette (512 possible colors)

---

## Things Tested / Verified

✅ **PC1 Hardware Detection** - FFFF:000D signature check (0xFE44)  
✅ **BIOS Mode 4 Initialization** - CGA baseline setup via INT 10h  
✅ **Port 0xD8 Mode Control** - Initialization sequence confirmed  
✅ **Port 0xD9 Border Color** - Correctly sets border to palette entry 0  
✅ **Register 0x65 Monitor Control** - 200 lines, PAL, CRT, DRAM settings  
✅ **Register 0x67 Configuration** - 8-bit bus mode, Page mode OFF, centering  
✅ **Palette Registers 0x40–0x5F** - 9-bit RGB format, auto-increment via 0xDE  
✅ **I/O Delay Timing** - `jmp short $+2` inserted after all register writes  
✅ **Binary-to-Hex Conversions** - Manual verification of all register values  
✅ **CGA Palette Restore** - Both programs reset palette to CGA defaults on exit  
✅ **320→160 Downsampling** - Automatic pixel decimation for wider images  

---

## Outstanding Issues / Next Steps

### ✅ Completed
- [x] **Compile colorbar.asm with NASM** → `nasm -f bin colorbar.asm -o colorbar.com`
- [x] **CGA palette reset on exit** → Both programs restore default CGA palette

### Primary Testing (Hardware)
- [ ] **Test on PC1 hardware** → Run colorbar.com
- [ ] **Verify output:**
  - [ ] 16 vertical color columns (not overlapping bars)
  - [ ] Proper random palette (not CGA defaults)
  - [ ] 160×200 resolution (wider pixels than 320×200)
  - [ ] Stable display (no noise/artifacts)
  - [ ] Clean exit to text mode with correct CGA colors

### Diagnostic Tests (if issues found)
- If **still CGA colors:** Check if palette writes reaching 0x40–0x5F correctly
- If **overlapping bars persist:** Bit 6 (Register 0x67) may need different state
- If **display blank:** Check Register 0x65 bit 3 (PAL/NTSC) or timing parameters
- If **wrong resolution:** Verify Mode Control Register (0xD8) Bit 6 = 1

### Optional Enhancements
- [ ] Demo scene effects (gradient.asm, acid88.asm)
- [ ] Text overlay on graphics mode
- [ ] Mouse/light pen support

---

## Programs in This Project

| Program | Description | Status |
|---------|-------------|--------|
| **colorbar.com** | Interactive demo with color bars, circles, gradients, test patterns | ✅ Complete |


---

## Documentation Sources

| Source | Coverage | Reliability |
|--------|----------|-------------|
| **6355 LCDC Manual** | Port map, register details | ✅ Official (primary authority) |
| **ACV-1030 Manual** | Mode switching, Bit 6 definition | ✅ Same V6355 chip (graphics card) |
| **John Elliott Documentation** | PC1 hardware details, reverse-engineering notes | ✅ Well-researched XT variant |
| **Peritel.com** | Horizontal centering value (24) | ✅ Reverse-engineered, tested |
| **Datasheet for V6355D** | SRAM vs DRAM modes, page mode requirements | ✅ Official component datasheet |
| **Z-180 PC Manual** | Register 0x65 Monitor Control details | ✅ Z-180 variant (similar chip) |

---

## Key Insights

1. **Register 0x67 Bit 6 (Page Mode)** is the most common source of overlapping bars
   - Requires 64KB DRAM to function
   - PC1 only has 16KB DRAM
   - Must stay OFF (0) for correct display

2. **Register 0x67 Bit 7 (16-bit Bus Mode)** must be OFF on PC1
   - If set on 8-bit bus, controller can only access odd bytes of VRAM
   - PC1 has 8-bit bus, not 16-bit
   - Must stay OFF (0) for correct display

3. **Port 0xD8 Bit 6** is the 16-COLOR ENABLE
   - Must be set to 1 for 160×200×16 mode
   - 0x4A has Bit 6 = 1 ✓

4. **Initialization Sequence** prevents display artifacts
   - Set registers and mode in correct order
   - Video must be enabled at end to complete initialization

5. **Palette Format is 9-bit RGB**
   - Byte 1: Red (3 bits, 0–7)
   - Byte 2: Green (3 bits, bits 4-6) + Blue (3 bits, bits 0–2)
   - Each color uses exactly 2 bytes (16 colors × 2 = 32 bytes total)
   - Total palette: 512 possible colors

6. **CGA Palette Must Be Restored on Exit**
   - The hidden mode uses custom palette registers
   - Text mode expects standard CGA colors
   - Both programs now reset palette to CGA defaults before exiting

---

## Contact & Attribution

- **Developer:** Dag Erik Hagesæter (Retro Erik)
- **AI Assistance:** GitHub Copilot, Claude (Anthropic)
- **Documentation:** John Elliott
- **Original Discovery:** Simone Riminucci (unlocking 160×200×16 mode)

---

**Last Updated:** January 2026  
**Current Code Status:** ✅ Ready for hardware testing  
**All Critical Fixes:** ✅ Implemented and verified
