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
  a sixth distinct tag, different from all five game-sharing modules — and it
  uses **decrypt mode 9**, whereas all five game-sharing modules use **mode
  10**. The mode selects which variant of the tag transform applies, so this
  one disc exercises two of them. Useful: whichever variant gets implemented
  first, this disc can validate it.
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
| `b00_bootbin.dat` | Baseball Superstar | 4,212,342 | 10 | `0x09000000` |
| `b02_bootbin.dat` | Lumberjack | 4,104,742 | 10 | `0x09000000` |
| `b04_bootbin.dat` | Pendemonium | 4,393,310 | 10 | `0x09000000` |
| `b80_bootbin.dat` | Lumberjack Challenge | 4,092,606 | 10 | `0x09000000` |
| `b81_bootbin.dat` | Séance | 4,725,526 | 10 | `0x09000000` |

> **Correction.** An earlier revision of this file listed five *different* tags
> here, read from header offset `0x130`. That offset lands inside the encrypted
> key material, so each module produces a different plausible-looking 32-bit
> value there — and a satisfying but false conclusion ("five distinct tags").
> The tag is at **`0xD0`**, cross-checked against an independent decryptor. All
> five microgames share one tag; only the main executable differs.

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

**First target: `b02` (Lumberjack)** — smallest `.text`, fewest functions,
0.19% VFPU. Previously a guess from the title's premise; now measured.

## Analysis of the decrypted modules

All six decrypted (see the Decryption section in the README for the bootstrap),
each byte-exact against the size its `~PSP` header declares.

| Module | `.text` | functions | reached | instructions | VFPU | imports | indirect |
|---|---:|---:|---:|---:|---:|---:|---:|
| Lumberjack | 584 KB | 3376 | 89.0% | 132,979 | 0.16% | 137 | 60 |
| Lumberjack Challenge | 586 KB | 3381 | 89.1% | 133,688 | 0.16% | 137 | 60 |
| Séance | 601 KB | 3484 | 89.2% | 137,181 | 0.15% | 137 | 62 |
| Pendemonium | 603 KB | 3485 | 89.3% | 137,880 | 0.15% | 137 | 62 |
| Baseball Superstar | 656 KB | 3886 | 88.2% | 148,217 | 0.16% | 137 | 60 |
| `hell2k` (main) | 961 KB | 5419 | 88.1% | 216,743 | 0.11% | 204 | 102 |

Zero invalid instructions in any module.

Coverage reached ~89% once seeding included the relocation tables. The five
microgames are relocatable PRXs, so their stored function pointers — thread
entries, callbacks, vtables — are enumerated exactly from `R_MIPS_32`
relocations (2,633 of them on Lumberjack). `hell2k` is statically linked, so
its relocation sections are empty and its pointers had to be recognised by
shape instead — a heuristic, and labelled as one.

Note the two module shapes on this one disc: the game-sharing modules are
relocatable PRXs (`ET_PSP_PRX`, linked at 0), while `EBOOT.BIN` is a static
executable (`ET_EXEC`) at `0x08900000`. Anything that assumes one shape breaks
on the other, which makes this disc a useful test of both paths.

Three things worth recording:

- **The VFPU is a non-issue for this game.** 0.14–0.20% of instructions, ~2% of
  functions. The standard objection to PSP static recompilation does not apply
  here. (Whether it applies to a 3D engine is a separate question; the same
  measurement answers it per-title.)
- **The five microgames share an engine.** Identical import counts (134) and
  near-identical VFPU density is not a coincidence — engine work done for the
  first transfers to all five. This is the anthology payoff the project was
  picked for.
- **`hell2k` imports 184 firmware functions** to the microgames' 134. The extra
  50 are the shell: video playback (`.pmf` streams), the `RPK` archive, save
  data, and the ad-hoc networking behind game sharing.

### Module layout (Lumberjack, representative)

```
.text                 0x00000000  597,588 bytes    the code
.sceStub.text         0x00091E54    1,304 bytes    import thunks (163 stubs)
.lib.ent              0x00092370       16 bytes    export table
.lib.stub             0x00092388      460 bytes    import table
.rodata.sceModuleInfo 0x00092558       52 bytes    module descriptor
.data                 0x00093020  3,283,040 bytes  assets
.rel.text             (non-alloc)  190,816 bytes   relocations
```

The single `PT_LOAD` is `rwx` and spans code *and* data, so any analysis that
trusts the segment rather than `.text` measures 3.3 MB of assets as
instructions. That is the difference between 70.8% and 99.81% decode coverage.

`module_start` (`0x000183AC`) is **not** the program — it makes four firmware
calls, builds some pointers, and returns. The real entry is handed to a thread
as a *pointer*, which is why discovery has to harvest `jal` targets by scanning
rather than relying on reachability alone.

## Decryption status

The toolkit's KIRK CMD1 layer — the part that actually decrypts — is done and
tested (toolkit phase 2a). What remains is the per-tag transform that builds
the CMD1 header from a `~PSP` header.

Probing this disc produced a useful negative result. `allegrexrecomp decrypt`
scans a module for an embedded CMD1 metadata block using a tightly constrained
structural signature, and finds none in any module here:

```
$ allegrexrecomp decrypt b02_bootbin.dat
module:   boot_bin
tag:      0x4597CB4E   decrypt mode 10
sizes:    4105088 encrypted -> 4104742 decrypted

probing for a KIRK CMD1 metadata block...
  none found in the first 0x400 bytes
```

So the CMD1 header is **constructed** by the tag layer rather than sitting in
the `~PSP` header at a fixed offset — meaning that layer does real
cryptographic work, not a memcpy. Worth knowing before anyone spends time
looking for it.

Note this is **not** a blocker for recompilation. Phase 3 needs plaintext, not
necessarily the toolkit's own decryptor;
[`pspdecrypt`](https://github.com/John-K/pspdecrypt) (GPL-3.0) run as a
separate process produces it today, the same way PPSSPP is used as an oracle.

## Open items

- **The tag transform** (toolkit phase 2b) — see
  [DECRYPT.md](https://github.com/sp00nznet/psprecomp/blob/main/docs/DECRYPT.md).
  This disc is a good validation target because it exercises both mode 9 and
  mode 10.
- **`RPK` archive format** — `data_en.pkh` is a 160 KB index (`RPK\x1a`) over
  the 60 MB `data_en.pkb`. Not on the critical path for the standalone
  microgames, which do not use it, but needed for the main game.
- **Which microgame is cheapest** — answer with `cover` across all five once
  decrypted, rather than guessing from size.
- **`bNN` → microgame name mapping** — partially recovered from the five
  game-sharing modules and the stream filenames; the rest is inside the main
  executable.
