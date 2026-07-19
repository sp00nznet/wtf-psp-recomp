# WTF: Work Time Fun — game-specific notes

Toolkit documentation lives in
[psprecomp/docs](https://github.com/sp00nznet/psprecomp/tree/main/docs). This
file records what is true about *this disc*.

Phase numbering mirrors the toolkit's [ROADMAP](https://github.com/sp00nznet/psprecomp/blob/main/ROADMAP.md).

## The dump

Two Western releases exist and both were checked. The PSN release is a raw ISO
and is the more convenient of the two to work from; the Redump UMD is
distributed zipped.

| | PSN | Redump (UMD) |
|---|---|---|
| File | `WTF - Work Time Fun (USA) (PSP) (PSN).iso` | `WTF - Work Time Fun (USA).zip` |
| Size | 410 MB | 383 MB (compressed) |
| SHA-1 | `9D9DD2FD23A625F83591FF1FF79BE1DBC11F18DA` | — |

The Japanese original, *Bakudan Handan* (600 MB), is a third view of the same
code and is worth keeping to hand as a cross-check.

`PARAM.SFO`:

```
BOOTABLE           1
CATEGORY           UG
DISC_ID            ULUS10172
DISC_VERSION       1.01
PARENTAL_LEVEL     5
PSP_SYSTEM_VER     2.71
REGION             32768
TITLE              WTF: work time fun™
```

## Disc structure

90 entries. The parts that matter:

```
/PSP_GAME/
  PARAM.SFO                             472        disc identity
  SYSDIR/
    BOOT.BIN                        1224764        ZEROED (see below)
    EBOOT.BIN                       1225104        ~PSP, module "hell2k"
    UPDATE/EBOOT.BIN                5089088        firmware 2.71 updater, not game code
  USRDIR/
    data_en.pkb                    60456960        asset archive
    data_en.pkh                      159744        its index — magic "RPK\x1a"
    gamesharing_en/b*_bootbin.dat  ~4.2 MB ea      five standalone microgames (PBP)
    module/*.prx                   20 modules      engine libraries (~SCE -> ~PSP)
    kmodule/*.prx                   8 modules      kernel modules (~PSP)
    stream/*.pmf, *.sgb            ~330 MB         video and audio
```

Two useful details:

- **`BOOT.BIN` is zeroed** — 1,224,764 bytes of `0x00`. This is normal for
  retail UMDs (the plain ELF is stripped at mastering), and it means the only
  route to the code is decrypting `EBOOT.BIN`. Note that `EBOOT.BIN`'s header
  declares a decrypted size of **1,224,764 bytes — exactly the size of the
  zeroed `BOOT.BIN`**. That is a free correctness check: a successful
  decryption must reproduce that length precisely, and the stub tells us what
  it should be.
- **The main module** (`EBOOT.BIN`) is module `hell2k`, key tag `0x88CF097F` —
  a sixth distinct tag, different from all five game-sharing modules.
- **`data_en.pkb` opens with a build path**: `/cygdrive/d/sce_...`. The asset
  archive carries absolute paths from the original build machine, which will be
  worth mining for internal file and module names once the archive format is
  worked out.

## The executable modules

Every executable on this disc is encrypted — all 28 of them, with no exceptions.
Checked individually, not assumed:

- `SYSDIR/EBOOT.BIN` — `~PSP`, module name **`hell2k`**
- 20 × `USRDIR/module/*.prx` — `~SCE` wrapping `~PSP`
- 8 × `USRDIR/kmodule/*.prx` — `~PSP`
- 5 × `gamesharing_en/*.dat` — PBP wrapping `~PSP`

The engine module list is itself informative about what the game does:
`libatrac3plus`, `libpsmfplayer`, `psmf`, `mpeg` (video playback — those 330 MB
of `.pmf` streams), `libfont`, `libccc` (text and character encoding),
`libmt19937` (Mersenne Twister — the microgames' RNG), `libmd5`/`libsha*`/
`libadler`/`libdeflt`/`libbase64` (hashing and compression), `scan` and
`show_macaddr` (the game-sharing / ad-hoc networking path).

## The game-sharing microgames — the wedge

The most useful thing on the disc. WTF's "game sharing" feature beams a
playable microgame to a nearby PSP, and to do that it ships five microgames as
**separately-bootable standalone modules**. Each is a plain PBP — an
unencrypted container — wrapping one `~PSP` module:

```
format:   PBP container (version 0x10000)
  PARAM.SFO   offset 0x00000028  size        440
  DATA.PSP    offset 0x000001E0  size    4212688  [~PSP encrypted PRX]

  CATEGORY           WG                  (game sharing)
  DISC_ID            ULUS10172
  SHARING_ID         0
  TITLE              Baseball Superstar

DATA.PSP:
format:   ~PSP encrypted PRX
  module        boot_bin
  version       1.1
  attributes    mod=0x0400 comp=0x0000
  segments      1
  elf size      4212342 bytes (decrypted)
  entry         0x00000C0C
  modinfo       0x000A4874
  bss           1030448 bytes
  decrypt mode  10
  tag           0xF8710C50
  segment 0     addr 0x00000000 size 4984576
```

All five:

| Module | Title | Decrypted ELF | Decrypt mode | Key tag |
|---|---|---:|---:|---|
| `b00_bootbin.dat` | Baseball Superstar | 4,212,342 | 10 | `0xF8710C50` |
| `b02_bootbin.dat` | Lumberjack | 4,104,742 | 10 | `0x4597CB4E` |
| `b04_bootbin.dat` | Pendemonium | 4,393,310 | 10 | `0x1F628E58` |
| `b80_bootbin.dat` | Lumberjack Challenge | 4,092,606 | 10 | `0xB4050E6E` |
| `b81_bootbin.dat` | Séance | 4,725,526 | 10 | `0x9B09CE7E` |

**Why this is the right first target.** A standalone module is self-contained:
one relocatable PRX at load address `0x00000000`, one segment, a known entry
point, and no dependency on the 60 MB asset archive or the main shell. That is
a far smaller thing to bring up than `EBOOT.BIN` plus `data_en.pkb`.

Two things to note. The five carry **five different key tags**, so a decryptor
that hard-codes one key will fail visibly on the second module instead of
appearing to work — a useful property. And the `bNN` prefixes match the stream
assets (`b01_erkonig.sgb`, `b73_m01_fe3.pmf`, `b80_makiwari_amb.sgb`,
`b81_m*.pmf`), which means **`bNN` is the game's internal microgame ID** and the
asset files can be attributed to specific microgames by prefix. `b81`/Séance
alone has 24 `.pmf` streams — it is the most asset-heavy of the five and
probably the wrong one to start with.

**Suggested first target: `b02` (Lumberjack)** — the smallest decrypted module
of the five, and a title whose gameplay ("chop wood rhythmically") implies very
little 3D. Confirm with `allegrexrecomp cover` once it is decrypted; the VFPU
percentage is the real cost signal, not the file size.

## Open items

- **Decryption** (toolkit phase 2) — blocks everything. See
  [DECRYPT.md](https://github.com/sp00nznet/psprecomp/blob/main/docs/DECRYPT.md).
- **`RPK` archive format** — `data_en.pkh` is a 160 KB index (`RPK\x1a`) over
  the 60 MB `data_en.pkb`. Not on the critical path for the standalone
  microgames, which do not use it, but needed for the main game.
- **Which microgame is cheapest** — answer with `cover` across all five once
  decrypted, rather than guessing from size.
- **`bNN` → microgame name mapping** — partially recovered from the five
  game-sharing modules and the stream filenames; the rest is inside the main
  executable.
