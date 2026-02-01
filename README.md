# Olivetti Prodest PC1 - Hidden 160×200×16 Graphics Mode

Enable the undocumented 160×200×16 color graphics mode on the Olivetti Prodest PC1 with custom 512 color palette.

## Overview

The Olivetti Prodest PC1 features a Yamaha V6355D LCDC (Liquid Crystal Display Controller) that supports a hidden 160×200×16 color graphics mode not enabled by the BIOS. This project provides assembly code to unlock and utilize this extended graphics capability.

### Hardware Specifications

| Component | Details |
|-----------|---------|
| **Computer** | Olivetti Prodest PC1 (Italian XT-compatible) |
| **CPU** | NEC V40 (8088/80186-compatible) |
| **Video Chip** | Yamaha V6355D LCDC |
| **VRAM** | 16KB DRAM |
| **Display** | Composite RGB SCART monitor (PAL standard) |
| **Target Resolution** | 160×200 pixels, 16 colors from 512-color palette |
| **Video Memory Segment** | 0xB000 |

## Programs Included

### COLORBAR.COM - Graphics Mode Demo
Interactive demonstration of the hidden 160×200×16 graphics mode.

**Controls:**
| Key | Function |
|-----|----------|
| **SPACE** | Randomize palette (512 colors) |
| **W** | Reset to CGA palette with 16 color bars |
| **A** | Cycle border color (0-15) |
| **Q** | Draw random colored circle |
| **D** | Gradient dither demo (Red→Green→Blue→Gray) |
| **T** | Draw test pattern (grid, color boxes, gradient) |
| **0** | Set bar width to 10 pixels (fills screen) |
| **1-9** | Set bar width to 1-9 pixels |
| **ESC** | Exit to DOS |
| **/?** | Show help |

## Getting Started

### Compilation

```bash
nasm -f bin colorbar.asm -o colorbar.com
```
## Technical Reference

### Port 0xD8 - Mode Control Register

| Bit | Function | Value |
|-----|----------|-------|
| 0 | Text mode column width | 0 (40-col) |
| 1 | Graphics mode enable | 1 |
| 2 | Video signal type | 0 (color) |
| 3 | Video enable | 1 |
| 4 | High-res graphics | 0 |
| 5 | Blink/Background | 0 |
| **6** | **16-color mode unlock** | **1** |
| 7 | Standby mode | 0 |

**Value 0x4A** enables the hidden 16-color mode.

### Initialization Sequence

**Minimal (required):**
```asm
mov al, 0x4A
out 0xD8, al        ; Enable 16-color mode - THAT'S IT!
```

**Full sequence (optional steps for specific configurations):**
```
1. INT 10h, AX=0004h  (Optional: Set CGA Mode 4 as baseline)
2. Set register 0x67 to 0x18 via ports 0xDD/0xDE (Optional: 8-bit bus mode)
3. Set register 0x65 to 0x09 via ports 0xDD/0xDE (Optional: 200 lines, PAL)
4. Write 0x4A to port 0xD8 (REQUIRED: enable 16-color mode)
5. Set border color via port 0xD9 (Optional)
6. Write palette (Optional - defaults to CGA colors)
```

> **Note:** Steps 1-3 and 5-6 are optional because the PC1 BIOS defaults are already correct for PAL/CRT operation.

### Register 0x65 - Monitor Control (Value: 0x09)

- **Bits 0–1:** Vertical lines (01 = 200 lines, 00=192, 10=204)
- **Bit 2:** Horizontal width (0 = 320/640, 1 = 256/512)
- **Bit 3:** TV standard (1 = PAL/SECAM 50Hz, 0 = NTSC 60Hz)
- **Bit 4:** Monitor type (0 = CGA color, 1 = MDA monochrome)
- **Bit 5:** Display type (0 = CRT, 1 = LCD)
- **Bit 6:** VRAM type (0 = Dynamic RAM, 1 = Static RAM)
- **Bit 7:** Pointing device (0 = Light-pen, 1 = Mouse)

### Register 0x67 - Configuration Mode (Value: 0x18)

- **Bits 0–2:** Horizontal position adjustment
- **Bits 3–4:** Display timing/centering
- **Bit 5:** LCD control signal period
- **Bit 6:** 4-page video RAM (0 = disabled, PC1 only has 16KB)
- **Bit 7:** Bus width (0 = 8-bit bus, 1 = 16-bit bus, **MUST be 0 on PC1!**)

### Color Palette (Registers 0x40–0x5F)

16 color entries, 2 bytes each:
- **Byte 1:** Red intensity (bits 0–2, values 0-7)
- **Byte 2:** Green (bits 4–6) | Blue (bits 0–2)
- **Format:** 9-bit RGB (3 bits per channel = 512 colors)

**Palette Write Process:**
1. Write 0x40 to port 0xDD (enable palette write)
2. Output 32 bytes (16 colors × 2 bytes) to port 0xDE
3. Write 0x80 to port 0xDD (disable palette write)

> **⚠️ Important:** You must include I/O delays between each palette byte write (e.g., `jmp short $+2`). The V6355D requires 300ns minimum I/O cycle time. Without delays, palette writes may be corrupted.

## Memory Layout

Video RAM at segment 0xB000 (not 0xB800 like standard CGA):

```
Even rows:  0xB000:0000–0xB000:1FFF (8KB)
Odd rows:   0xB000:2000–0xB000:3FFF (8KB)
```

Each byte holds two pixels (packed nibbles: high nibble = left pixel, low nibble = right pixel).

Row offset calculation:
- Even row Y: `offset = (Y / 2) * 80`
- Odd row Y: `offset = 0x2000 + (Y / 2) * 80`

## Documentation

For comprehensive technical documentation, see [V6355D-Technical-Reference.md](../V6355D-Technical-Reference.md).

## Compatibility with Other V6355-Based Systems

The Yamaha V6355/V6355D video chip was used in several computers and add-on cards beyond the Olivetti Prodest PC1. The most notable are:

### Zenith Z-180 Series Laptops (Z-181, Z-183)

**What it is:** Portable laptop computers manufactured by Zenith Data Systems in the late 1980s, featuring both an internal LCD panel and external video output capability.

**Hardware Specifications:**
- CPU: Intel x86-compatible (8086/8088-based)
- Video: Yamaha V6355 LCDC
- Display: Internal LCD + external RGB CRT output
- Video outputs: Standard RGB (R, G, B, I) CGA-compatible connector
- Dual-mode: Can drive LCD or CRT simultaneously

**Code Compatibility:**
The V6355 chip and register layout are identical, but modifications are needed:

| Component | PC1 Value | Z-180 Value | Required Change |
|-----------|-----------|-------------|-----------------|
| **I/O Ports** | 0xD8, 0xD9, 0xDD, 0xDE | 0x3D8, 0x3D9, 0x3DD, 0x3DE | Update all port addresses (add 0x300) |
| **Video Segment** | 0xB000 | Unknown (needs testing) | Verify video RAM location |
| **Register 0x65** | 0x09 (CRT, PAL) | Needs LCD-specific value | LCD requires different timing |
| **Display Type** | CRT (SCART) | LCD or external CRT | Bit 5 of Reg 0x65 (0=CRT, 1=LCD) |

**Recommended Approach:**
1. Change all port addresses from 0xDx to 0x3Dx
2. Test video segment (try 0xB000, 0xB800)
3. For LCD mode: Set bit 5 of register 0x65 to 1
4. Adjust timing parameters if needed (registers 0x65, 0x67)

### ACV-1030 Color Graphics Adapter

**What it is:** An ISA expansion card for IBM PC/XT/AT compatible computers, using the V6355 chip to provide CGA-compatible graphics with extended capabilities.

**Hardware Specifications:**
- Form factor: ISA short-slot expansion card
- Video: Yamaha V6355 LCDC
- Video outputs: 
  - Standard 9-pin CGA RGB connector (R, G, B, Intensity, H-sync, V-sync)
  - Composite video output (4-pin header)
  - RF modulator support
- Compatible with: IBM PC/XT/AT and clones

**Code Compatibility:**
The ACV-1030 follows IBM CGA standard more closely than the PC1:

| Component | PC1 Value | ACV-1030 Value | Required Change |
|-----------|-----------|----------------|-----------------|
| **Video Segment** | 0xB000 | **0xB800** | **Must change to 0xB800** |
| **I/O Ports** | 0xD8, 0xD9, 0xDD, 0xDE | 0x3D8, 0x3D9, 0x3DD, 0x3DE | Update all port addresses (add 0x300) |
| **Register 0x65** | 0x09 (200 lines, PAL) | Same | Should work as-is |
| **Register 0x67** | 0x18 (8-bit bus) | Same | Should work as-is |

**Required Code Changes for ACV-1030:**
```nasm
; Change these constants:
VIDEO_SEG       equ 0xB800      ; Was 0xB000 on PC1
PORT_REG_ADDR   equ 0x3DD       ; Was 0xDD
PORT_REG_DATA   equ 0x3DE       ; Was 0xDE
PORT_MODE       equ 0x3D8       ; Was 0xD8
PORT_COLOR      equ 0x3D9       ; Was 0xD9
```

**Why it should work:**
- Same V6355 chip with identical register bank
- Standard CGA video memory layout (even/odd row interlacing)
- RGB output compatible with SCART (via proper cable)
- Palette registers (0x40–0x5F) function identically

### Summary

Both the Zenith Z-180 and ACV-1030 use the same Yamaha V6355 video controller and support RGB output, making them theoretically compatible with this hidden 160×200×16 color mode. The main differences are:

- **ACV-1030:** Straightforward port—just change video segment to 0xB800 and port addresses to 0x3Dxx
- **Zenith Z-180:** More complex—needs port changes, video segment verification, and LCD vs CRT mode consideration

The 16-color palette mode should work on both systems since it's a feature of the V6355 chip itself, not the PC1 hardware.

## Credits

- **Author:** Dag Erik Hagesæter (Retro Erik)
- **Special Thanks:**
  - Simone Riminucci - Discovered and demonstrated the hidden mode on real PC1 hardware
  - John Elliott - V6355D documentation (note: some claims unverified on PC1)
  - GitHub Copilot & Claude - AI-assisted development

**For comprehensive technical documentation, see:** [V6355D-Technical-Reference.md](../V6355D-Technical-Reference.md)

## License

This project is licensed under the **Creative Commons Attribution-NonCommercial 4.0 International License**.

You are free to:
- Use this code for personal, educational, and non-commercial projects
- Modify and improve the code
- Share and redistribute the code

You must:
- Give appropriate credit to the original author
- Include a copy of the license

You cannot:
- Use this code for commercial purposes
- Remove attribution or claim the work as your own

For full license details, see the [LICENSE](LICENSE) file.

## Contributing

Found a bug or improvement? Feel free to create an issue or pull request!

---

**Last Updated:** January 2026
