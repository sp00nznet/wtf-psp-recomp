# wtf-psp-recomp

**WTF: Work Time Fun (PSP, 2006) — statically recompiled to native C.**

*WTF* is a collection of about thirty microgames strung together by a job-agency
framing device: you clock in, you do something absurd for fifteen seconds —
capping pens, chopping wood, launching a rocket-powered hamster — you get paid
in fake currency, you buy junk with it. It is one of the strangest things Sony
ever published in the West, and it has aged into a genuine cult object.

It is also, structurally, an unusually good recompilation target. An anthology
is thirty small independent programs sharing a shell, which means progress is
*incremental and demonstrable*: the first microgame that runs end-to-end is a
real milestone, and the remaining twenty-nine are a built-in corpus proving the
toolkit generalizes. Most games give you one binary and one all-or-nothing
result. This one gives you thirty checkpoints.

Better still, five of its microgames ship as **separately-bootable modules** —
the "game sharing" feature that beams a playable demo to a second PSP. Each is
a self-contained ~4 MB module in a plain PBP container, which makes them a much
smaller first target than the 1.2 MB main executable plus its 60 MB asset
archive.

Built on [**psprecomp**](https://github.com/sp00nznet/psprecomp), the reusable
PSP recompilation toolkit, vendored here as a git submodule.

> **No game data here.** Disc images, `EBOOT.BIN`, the extracted modules and the
> PSP decryption keys are all `.gitignore`d. Bring your own UMD or PSN dump of a
> copy you legally own.

## Status — the disc is fully mapped; decryption is the gate

The toolkit walks a retail dump end to end and reports exactly what stands
between here and decodable Allegrex code. Everything below is tool output, not
assertion — reproduce it with `scripts/extract.ps1`.

- ✅ **Disc mapped.** ULUS10172, 90 entries, `PARAM.SFO` read, full boot chain
  identified. The container stack (ISO9660 → PBP → `~PSP` → ELF) handles every
  layer this disc uses.
- ✅ **The five game-sharing microgames identified** — each a PBP wrapping a
  `~PSP` module:

  | Module | Microgame | Decrypted size | Mode | Key tag |
  |---|---|---:|---:|---|
  | `b00_bootbin.dat` | Baseball Superstar | 4,212,342 | 10 | `0x09000000` |
  | `b02_bootbin.dat` | Lumberjack | 4,104,742 | 10 | `0x09000000` |
  | `b04_bootbin.dat` | Pendemonium | 4,393,310 | 10 | `0x09000000` |
  | `b80_bootbin.dat` | Lumberjack Challenge | 4,092,606 | 10 | `0x09000000` |
  | `b81_bootbin.dat` | Séance | 4,725,526 | 10 | `0x09000000` |

  *(An earlier revision listed five different tags here, read from header
  offset `0x130`. That offset falls inside the encrypted key material, so it
  yields a different plausible-looking value per module — it was noise. The tag
  is at `0xD0`, verified against an independent decryptor.)*

- ✅ **All six modules decrypted and analyzed.** Every output is byte-exact
  against the size its `~PSP` header declares.

- ✅ **Main executable identified** — `SYSDIR/EBOOT.BIN`, a `~PSP` module whose
  internal name is **`hell2k`** (the game's development codename; the Japanese
  original is *Bakudan Handan*), mode 9, key tag `0xC0CB167C`. Its declared
  decrypted size is 1,224,764 bytes — *exactly* the size of the zeroed
  `BOOT.BIN` stub, and decryption reproduces it precisely.
- ✅ **Function discovery running on all six modules:**

  | Module | `.text` | functions | reached | instructions | VFPU | imports |
  |---|---:|---:|---:|---:|---:|---:|
  | Lumberjack | 584 KB | 3376 | 89.0% | 132,979 | **0.16%** | 137 |
  | Lumberjack Challenge | 586 KB | 3381 | 89.1% | 133,688 | **0.16%** | 137 |
  | Séance | 601 KB | 3484 | 89.2% | 137,181 | **0.15%** | 137 |
  | Pendemonium | 603 KB | 3485 | 89.3% | 137,880 | **0.15%** | 137 |
  | Baseball Superstar | 656 KB | 3886 | 88.2% | 148,217 | **0.16%** | 137 |
  | `hell2k` (main) | 961 KB | 5419 | 88.1% | 216,743 | **0.11%** | 204 |

  Zero invalid instructions anywhere. **The VFPU — the usual reason the PSP is
  called a hard recompilation target — is 0.2% of this game**, touched by ~2%
  of functions. And the five microgames report *identical* import counts and
  near-identical VFPU density, confirming they share one engine: work done for
  the first transfers to all five.
- 🚧 **Decryption is bootstrapped, not native.** psprecomp's own KIRK CMD1
  layer is done, but the `~PSP` tag transform above it is not, so plaintext
  currently comes from [`pspdecrypt`](https://github.com/John-K/pspdecrypt)
  (GPL-3.0) run as a separate process — the same posture as PPSSPP-as-oracle.
  Nothing is linked and this repo stays MIT. See [Decryption](#decryption) below.
- 🚧 **The remaining 25%** of `.text` is reachable only through function
  pointers (callbacks, vtables, thread entries). `.rel.text` lists every
  address the loader patches, which is how to recover them.
- ✅ **Recompiled — including the main game executable.** Both Lumberjack and
  `hell2k` emit C that compiles with MSVC, links against the psprecomp runtime,
  and runs:

  ```
  registered 3376 recompiled functions   (Lumberjack)
  registered 5419 recompiled functions   (hell2k, the main game)
  module_start resolved in both
  ```

  Whole pipeline end to end: **disc → decrypt → discover → emit → compile →
  link → run.**

  Three bugs this disc forced that synthetic tests would never have found —
  each showing up exactly once in a quarter of a million generated lines: a
  delay slot that is also a branch target; a tail-call thunk whose target lies
  *below* its own entry point; and an import reached by a branch rather than a
  `jal` (which linked fine on the microgames and failed only on `hell2k`).
- 🚧 **The HLE layer** — the module registers and resolves, but the first
  firmware call traps: there is no `sceKernel` yet. Lumberjack imports 134
  functions, and bringing it up is largely the process of watching that list
  stop being hit.
- ⬜ **Playable** — one microgame reaching a rendered frame.

**First target: `b02` Lumberjack.** Smallest `.text`, fewest functions, and
0.19% VFPU. That was a guess from the title's premise in the previous revision;
it is now measured.

This README tracks *WTF*'s progress as it comes up.

## Why this title

Beyond the anthology structure, three practical reasons:

- **Two independent dumps exist** — a UMD (Redump) and a PSN release — plus the
  Japanese original *Bakudan Handan*. Three views of the same code is a cheap
  cross-check whenever something looks wrong.
- **The microgames are small and 2D-ish.** A pen-capping minigame does not
  build a projection matrix. That matters, because VFPU density is the main
  cost driver in PSP recompilation, and the toolkit's `cover` subcommand will
  give a real number per module rather than a guess.
- **It is interesting to other people.** A recomp project's value scales with
  how many people want to poke at it, and "the weird PSP job-simulator" draws
  more attention than a puzzle game would.

## Building & running

```powershell
git clone --recursive https://github.com/sp00nznet/wtf-psp-recomp
cd wtf-psp-recomp
cmake -S . -B build
cmake --build build --config Release

# map a dump you own and pull out the boot chain + microgames:
.\scripts\extract.ps1 -Iso "WTF - Work Time Fun (USA).iso"
```

`extract.ps1` writes to `work/` (gitignored) and prints a report. Nothing it
produces is committed.

## Decryption

Every executable on the disc is an encrypted `~PSP` module. Until psprecomp's
own tag transform lands, plaintext comes from
[`pspdecrypt`](https://github.com/John-K/pspdecrypt) — GPL-3.0, so it is run as
a **separate process** and never linked or vendored, exactly like PPSSPP is used
as an oracle. This repo and the toolkit stay MIT.

```bash
# in WSL, or any Linux box
sudo apt-get install -y g++ make zlib1g-dev libssl-dev
git clone https://github.com/John-K/pspdecrypt && cd pspdecrypt
make CC=gcc CXX=g++ -j4

# game-sharing microgames are PBPs; -P reaches the executable inside
./pspdecrypt -P -o b02_lumberjack.elf .../b02_bootbin.dat
# the main executable is a bare ~PSP
./pspdecrypt -o eboot_hell2k.elf .../EBOOT.BIN
```

Each output should be **byte-exact** against the size its `~PSP` header
declares — `allegrexrecomp info` on the encrypted module prints that number, so
the check is free. Then:

```powershell
.\build\psprecomp\tools\allegrexrecomp\Release\allegrexrecomp.exe funcs work\dec\b02_lumberjack.elf
```

## Layout

```
psprecomp/            the toolkit (git submodule)
scripts/extract.ps1   map a dump and pull out the boot chain + microgames
docs/NOTES.md         game-specific findings: hashes, disc structure, modules
```

`games/wtf/` — the per-game host and the generated C — arrives with the
emitter, in toolkit phase 3. Building a host before there is code to run in it
would be scaffolding for its own sake.

## Legal

The recompiler, the runtime and the scripts are original work, MIT-licensed.
**No game data, no PSP firmware, and no decryption keys are included in this
repository.** *WTF: Work Time Fun* is © Sony Computer Entertainment / h.a.n.d.;
this is an independent, non-commercial preservation project, not affiliated
with or endorsed by either. Built on
[**psprecomp**](https://github.com/sp00nznet/psprecomp).
