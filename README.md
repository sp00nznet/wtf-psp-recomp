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
  `~PSP` module, with its own title and its own decryption key tag:

  | Module | Microgame | Decrypted size | Key tag |
  |---|---|---:|---|
  | `b00_bootbin.dat` | Baseball Superstar | 4,212,342 | `0xF8710C50` |
  | `b02_bootbin.dat` | Lumberjack | 4,104,742 | `0x4597CB4E` |
  | `b04_bootbin.dat` | Pendemonium | 4,393,310 | `0x1F628E58` |
  | `b80_bootbin.dat` | Lumberjack Challenge | 4,092,606 | `0xB4050E6E` |
  | `b81_bootbin.dat` | Séance | 4,725,526 | `0x9B09CE7E` |

- ✅ **Main executable identified** — `SYSDIR/EBOOT.BIN`, a `~PSP` module whose
  internal name is **`hell2k`** (the game's development codename; the Japanese
  original is *Bakudan Handan*), key tag `0x88CF097F`. Its declared decrypted
  size is 1,224,764 bytes — *exactly* the size of the zeroed `BOOT.BIN` stub,
  which gives decryption a free correctness check.
- 🚧 **Decryption** — `BOOT.BIN` is zeroed, as on essentially every retail UMD,
  so the real code is the encrypted `EBOOT.BIN`. All 28 executable modules on
  this disc are encrypted, without exception. This is the current frontier and
  it is toolkit work, not game work — see
  [psprecomp `docs/DECRYPT.md`](https://github.com/sp00nznet/psprecomp/blob/main/docs/DECRYPT.md).
- ⬜ **Recompiled** — function discovery and the C emitter, once there is
  plaintext to run them on.
- ⬜ **Playable** — one microgame reaching a rendered frame.

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
