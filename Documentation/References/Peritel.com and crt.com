Peritel.com (SCART in french) hex dump
B8 FF FF 8E C0 26 A1 0D 00 3D 44 FE 74 0C 3D 49 FE 74 07 3D 4A FE 74 02 EB 0D B0 67 E6 DD B0 18 E6 DE B8 00 4C CD 21 0E 1F BA 35 01 B4 09 CD 21 B8 01 4C CD 21 45 78 65 63 75 74 69 6F 6E 20 70 6F 73 73 69 62 6C 65 20 6F 6E 6C 79 20 6F 6E 20 20 0D 0A 20 20 4F 4C 49 56 45 54 54 49 20 50 52 4F 44 45 53 54 20 50 43 31 0D 0A 24


Disassembled by Claude Haiku 4.5
B8 FF FF        mov ax, 0xFFFF
8E C0           mov es, ax
26 A1 0D 00     mov ax, [es:0x000D]      ; read ES:000D
3D 44 FE        cmp ax, 0xFE44           ; check for specific value
74 0C           je  +0x0C
3D 49 FE        cmp ax, 0xFE49
74 07           je  +0x07
3D 4A FE        cmp ax, 0xFE4A
74 02           je  +0x02
EB 0D           jmp +0x0D
B0 67           mov al, 0x67             ; <-- PERITEL sets reg 0x67
E6 DD           out 0xDD, al
B0 18           mov al, 0x18
E6 DE           out 0xDE, al
B8 00 4C        mov ax, 0x4C00           ; exit
CD 21           int 0x21



CRT.COM hex dump
B8 FF FF 8E C0 26 A1 0D 00 3D 44 FE 74 0C 3D 49 FE 74 07 3D 4A FE 74 02 EB 0D B0 65 E6 DD B0 81 E6 DE B8 00 4C CD 21 0E 1F BA 35 01 B4 09 CD 21 B8 01 4C CD 21 45 78 65 63 75 74 69 6F 6E 20 70 6F 73 73 69 62 6C 65 20 6F 6E 6C 79 20 6F 6E 20 20 0D 0A 20 20 4F 4C 49 56 45 54 54 49 20 50 52 4F 44 45 53 54 20 50 43 31 0D 0A 24

Disassembled by Claude Haiku 4.5

[same header/checks as PERITEL]
B0 65           mov al, 0x65             ; <-- CRT sets reg 0x65
E6 DD           out 0xDD, al
B0 81           mov al, 0x81
E6 DE           out 0xDE, al
[same exit]


========================================================================
VERIFIED ANALYSIS (based on disassembly above)
========================================================================

Both utilities check for PC1 hardware signature at FFFF:000D (values 0xFE44, 0xFE49, or 0xFE4A)
and exit with error message "Execution possible only on OLIVETTI PRODEST PC1" if not found.

1. PERITEL.COM - Horizontal Position for SCART Monitors

PERITEL.COM writes ONE register:
- Register 0x67 = 0x18

Register 0x67 (Configuration Mode) value 0x18 = 00011000 binary:
- Bits 0-2: [000] = Horizontal position offset
- Bits 3-4: [11]  = Display centering adjustment
- Bit 5:    [0]   = CRT timing (not LCD)
- Bit 6:    [0]   = 4-page VRAM disabled
- Bit 7:    [0]   = 8-bit bus mode

Purpose: Adjusts horizontal screen position for SCART monitors/TVs.
Does NOT change video timing, resolution, or refresh rate.

2. CRT.COM - NTSC Mode with Mouse

CRT.COM writes ONE register:
- Register 0x65 = 0x81

Register 0x65 (Monitor Control) value 0x81 = 10000001 binary:
- Bits 0-1: [01] = 200 vertical lines
- Bit 2:    [0]  = 320/640 horizontal width
- Bit 3:    [0]  = NTSC/60Hz (changed from BIOS default PAL/50Hz!)
- Bit 4:    [0]  = CGA color mode
- Bit 5:    [0]  = CRT output
- Bit 6:    [0]  = Dynamic RAM
- Bit 7:    [1]  = Mouse enabled

BIOS default for register 0x65 is 0x89 (PAL, mouse enabled).
CRT.COM changes it to 0x81 (NTSC, mouse enabled).

Purpose: Switches from 50Hz PAL to 60Hz NTSC timing.
Intended for CRT monitors that prefer NTSC timing.

3. Summary

| Utility      | Register | Value | Primary Effect                    |
|--------------|----------|-------|-----------------------------------|
| PERITEL.COM  | 0x67     | 0x18  | Horizontal position for SCART     |
| CRT.COM      | 0x65     | 0x81  | PAL to NTSC (50Hz to 60Hz)        |

Neither utility enables or affects the hidden 160x200x16 graphics mode.
That mode is enabled separately by writing 0x4A to port 0xD8.

Reference: John Elliott documentation confirms "The BIOS initialises [0x65] to 0x89. 
The provided CRT.COM utility changes it to 0x81."