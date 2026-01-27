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
```
1. INT 10h, AX=0004h  (Set CGA Mode 4 as baseline)
2. Set register 0x67 to 0x18 via ports 0xDD/0xDE (8-bit bus mode)
3. Set register 0x65 to 0x09 via ports 0xDD/0xDE (200 lines, PAL)
4. Write 0x4A to port 0xD8 (enable 16-color mode)
5. Set border color via port 0xD9
6. Write palette: 0x40 to 0xDD, 32 bytes to 0xDE, then 0x80 to 0xDD
```

### Register 0x65 - Monitor Control (Value: 0x09)

- **Bits 0–1:** Vertical lines (01 = 200 lines)
- **Bit 3:** TV standard (1 = PAL/SECAM, 50Hz)
- **Bit 4:** Monitor type (0 = Color)

### Register 0x67 - Configuration Mode (Value: 0x18)

- **Bit 7:** 16-bit bus mode (0 = 8-bit bus, **MUST be 0 on PC1!**)
- **Bit 6:** 4-page video RAM (0 = disabled)
- **Bits 3–4:** Display timing/centering

### Color Palette (Registers 0x40–0x5F)

16 color entries, 2 bytes each:
- **Byte 1:** Red intensity (bits 0–2, values 0-7)
- **Byte 2:** Green (bits 4–6) | Blue (bits 0–2)
- **Format:** 9-bit RGB (3 bits per channel = 512 colors)

**Palette Write Process:**
1. Write 0x40 to port 0xDD (enable palette write)
2. Output 32 bytes (16 colors × 2 bytes) to port 0xDE
3. Write 0x80 to port 0xDD (disable palette write)

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

See [DEVELOPMENT_SUMMARY.md](DEVELOPMENT_SUMMARY.md) for detailed technical specifications.

## Credits

- **Author:** Dag Erik Hagesæter (Retro Erik)
- **Special Thanks:**
  - Simone Riminucci - Demonstrated that this hidden mode was possible
  - John Elliott - Extensive V6355D documentation
  - GitHub Copilot & Claude - AI-assisted development

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
