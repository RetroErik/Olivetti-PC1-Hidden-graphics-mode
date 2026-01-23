# Olivetti Prodest PC1 - Hidden 160×200×16 Graphics Mode

Enable the undocumented 160×200×16 color graphics mode on the Olivetti Prodest PC1 with custom palette support.

## Overview

The Olivetti Prodest PC1 features a Yamaha V6355D LCDC (Liquid Crystal Display Controller) that supports a hidden 160×200×16 color graphics mode not enabled by the BIOS. This project provides assembly code to unlock and utilize this extended graphics capability.

### Hardware Specifications

| Component | Details |
|-----------|---------|
| **Computer** | Olivetti Prodest PC1 (Italian XT-compatible) |
| **CPU** | NEC V40 (8088-compatible) |
| **Video Chip** | Yamaha V6355D LCDC |
| **VRAM** | 16KB DRAM |
| **Display** | Composite RGB SCART monitor (PAL standard) |
| **Target Resolution** | 160×200 pixels, 16 colors |

## Features

- ✅ Unlocks hidden 16-color mode via Port 0x3D8
- ✅ Configures Yamaha V6355D registers (0x65, 0x67, 0x40–0x5F)
- ✅ Custom palette support (12-bit RGB format)
- ✅ Hardware detection (PC1 signature verification)
- ✅ NASM-compatible assembly code
- ✅ Compiles to .COM executable

## Getting Started

### Compilation

```bash
nasm -f bin PC1Color.asm -o PC1Color.com
```

### Running on PC1

1. Transfer `PC1Color.com` to your PC1 floppy disk
2. Boot the PC1 with DOS
3. Run the program: `PC1COLOR.COM`
4. Press **ESC** to exit and return to text mode

## Register Reference

### Port 0x3D8 - Mode Control Register

| Bit | Function | Value |
|-----|----------|-------|
| 0 | Text/Graphics column width | 0 (40-col) |
| 1 | Graphics mode enable | 1 |
| 2 | Video signal type | 0 (color) |
| 3 | Video enable | 1 |
| 4 | Resolution select | 0 |
| 5 | Blink enable | 0 |
| **6** | **16-color mode unlock** | **1** |
| 7 | Standby mode | 0 |

**Initialization Sequence:**
```
Step 1: Write 0x4A (unlock + video ON)
Step 2: Write 0x42 (set mode + video OFF)
Step 3: Write 0x4A (finalize + video ON)
```

### Register 0x65 - Monitor Control

- **Bits 0–1:** Vertical lines (01 = 200 lines)
- **Bit 3:** TV standard (1 = PAL/SECAM)
- **Bit 4:** Monitor type (0 = Color)
- **Bit 5:** CRT/LCD mode (0 = CRT)

**Value:** 0x09 (200 lines, PAL, CRT, DRAM)

### Register 0x67 - Configuration Mode

- **Bit 7:** Planar memory merge (1 = enabled)
- **Bit 6:** Page mode (0 = disabled, required for PC1's 16KB DRAM)
- **Bits 0–2:** Horizontal centering offset

**Value:** 0x98 (Planar ON, Page mode OFF, centering = 24)

### Registers 0x40–0x5F - Color Palette

16 color palette entries, 2 bytes each:
- **Even register:** Red intensity (bits 0–3)
- **Odd register:** Green (bits 4–7), Blue (bits 0–3)
- **Format:** 12-bit RGB (4 bits per channel)

## Memory Layout

Video RAM is organized in four 4KB planes (planar addressing):

```
Plane 0 (bit 0): 0xB800:0000–0xB800:3FFF
Plane 1 (bit 1): 0xB800:4000–0xB800:7FFF
Plane 2 (bit 2): 0xB800:8000–0xB800:BFFF
Plane 3 (bit 3): 0xB800:C000–0xB800:FFFF
```

Each plane holds one bit of the 4-bit color value.

## Documentation

See `DEVELOPMENT_SUMMARY.md` for detailed technical specifications and testing procedures.

## Credits

- **Author:** Dag Erik Hagesæter (Retro Erik)
- **Special Thanks:**
  - Simone Riminucci - Showed that this hidden mode was possible
  - John Elliott - Extensive documentation gathering
  - VS Code & GitHub Copilot - Development tools

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
- Use this code for commercial purposes (selling, bundling with commercial software, etc.)
- Remove attribution or claim the work as your own

For full license details, see the `LICENSE` file.

## Contributing

Found a bug or improvement? Feel free to create an issue or pull request!

---

**Last Updated:** January 2026
