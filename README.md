# Olivetti Prodest PC1 - Hidden 160×200×16 Graphics Mode

Enable the undocumented 160×200×16 color graphics mode on the Olivetti Prodest PC1 with custom palette support.

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
| **Target Resolution** | 160×200 pixels, 16 colors |
| **Video Memory Segment** | 0xB000 |

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
nasm -f bin Colorbars.asm -o Colorbars.com
```

### Running on PC1

1. Transfer `Colorbars.com` to your PC1 floppy disk
2. Boot the PC1 with DOS
3. Run the program: `COLORBARS.COM`
4. Press **ESC** to exit and return to text mode

## Register Reference

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

**Initialization Sequence:**
```
1. Set register 0x67 to 0x18 via ports 0xDD (address) and 0xDE (data)
2. Set register 0x65 to 0x09 via ports 0xDD/0xDE
3. Write 0x4A to port 0xD8 (enable 16-color mode)
4. Set border color to black via port 0xD9
5. Write palette: 0x40 to 0xDD, 32 bytes to 0xDE, then 0x80 to 0xDD
```

### Register 0x65 - Monitor Control

- **Bits 0–1:** Vertical lines (01 = 200 lines)
- **Bit 3:** TV standard (1 = PAL/SECAM)
- **Bit 4:** Monitor type (0 = Color)
- **Bit 5:** CRT/LCD mode (0 = CRT)
- **Bit 6:** RAM type (0 = DRAM)
- **Bit 7:** Input device (0 = none)

**Value:** 0x09 (200 lines, PAL, color, CRT, DRAM)

### Register 0x67 - Configuration Mode

- **Bit 7:** Planar memory merge (0 = disabled, required for PC1)
- **Bit 6:** Page mode (0 = disabled)
- **Bits 4–5:** Display timing/centering (recommended for PC1)
- **Bits 0–2:** Horizontal centering offset (default)

**Value:** 0x18 (Planar OFF, centering, page mode OFF)

### Registers 0x40–0x5F - Color Palette

16 color palette entries, 2 bytes each:
- **Byte 1:** Red intensity (bits 0–2)
- **Byte 2:** Green (bits 4–6), Blue (bits 0–2)
- **Format:** 9-bit RGB (3 bits per channel, 512 colors)

**Palette Write Process:**
1. Write 0x40 to port 0xDD (enable palette write)
2. Output 32 bytes (16 colors × 2 bytes) to port 0xDE
3. Write 0x80 to port 0xDD (disable palette write)

## Memory Layout

Video RAM is organized in two 8KB banks at segment 0xB000 (not 0xB800):

```
Even rows:  0xB000:0000–0xB000:1FFF
Odd rows:   0xB000:2000–0xB000:3FFF
```
Each byte holds two pixels (packed nibbles).

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
