# wtf-psp-recomp

### *Clock in. Cap pens. Compile to native code.*

> **WTF: Work Time Fun** (PSP, 2006) — statically recompiled to native C.
> Built on [psprecomp](https://github.com/sp00nznet/psprecomp).

---

## What Is This?

*WTF* is about thirty microgames strung together by a job-agency framing device:
you clock in, you do something absurd for fifteen seconds — capping pens,
chopping wood, launching a rocket-powered hamster — you get paid in fake
currency, you buy junk with it. One of the strangest things Sony ever published
in the West, and a genuine cult object.

This repo turns it into a native executable. No emulator.

## Why This Title

An anthology is thirty small independent programs sharing a shell, which makes
progress **incremental and demonstrable**. The first microgame that runs
end-to-end is a real milestone, and the remaining twenty-nine are a built-in
corpus proving the toolkit generalises. Most games give you one binary and one
all-or-nothing result; this one gives you thirty checkpoints.

Better still, five microgames ship as **separately-bootable modules** — the
"game sharing" feature that beams a playable demo to a second PSP. Each is a
self-contained ~4 MB module in a plain PBP container, a far smaller first target
than the main executable plus its 60 MB asset archive.

Three more practical reasons:

- **Two independent dumps exist** — a UMD (Redump) and a PSN release — plus the
  Japanese original *Bakudan Handan*. Three views of the same code is a cheap
  cross-check whenever something looks wrong.
- **The microgames are small and 2D-ish.** A pen-capping minigame does not build
  a projection matrix, and VFPU density is the main cost driver in PSP
  recompilation.
- **It is interesting to other people.** A recomp project's value scales with how
  many people want to poke at it, and "the weird PSP job simulator" draws more
  attention than a puzzle game would.

> **No game data here.** Disc images, `EBOOT.BIN`, extracted modules and PSP
> decryption keys are all `.gitignore`d. Bring your own UMD or PSN dump of a copy
> you legally own.

## Status

**Two microgames play in a window, with keyboard or controller.** Lumberjack
and Pendemonium run from the WTF title screen through the Job Share menu and
their own title cards into the game, and Lumberjack on to its paycheck.

| Microgame | State |
|---|---|
| Lumberjack (`b02`) | ✅ Plays: title, menu, game, paycheck |
| Pendemonium (`b04`) | ✅ Plays: a lit 3D factory, capping pens |
| Lumberjack Challenge (`b80`) | 🔨 Reaches its title screen; not played further |
| Baseball Superstar (`b00`) | ❌ Bad memory reads at start-up |
| Séance (`b81`) | ❌ Stops on an indirect call to code discovery missed |

Not yet: sound is mixed but not played to a device, the window is Windows-only,
and the main game (`EBOOT.BIN`, codename *hell2k*) has not been attempted.

### The five game-sharing microgames

Each a PBP wrapping a `~PSP` module:

| Module | Microgame | Decrypted size | Key tag |
|---|---|---:|---|
| `b00_bootbin.dat` | Baseball Superstar | 4,212,342 | `0x09000000` |
| `b02_bootbin.dat` | Lumberjack | 4,104,742 | `0x09000000` |
| `b04_bootbin.dat` | Pendemonium | 4,393,310 | `0x09000000` |
| `b80_bootbin.dat` | Lumberjack Challenge | 4,092,606 | `0x09000000` |
| `b81_bootbin.dat` | Séance | 4,725,526 | `0x09000000` |

The main executable is `SYSDIR/EBOOT.BIN`, a `~PSP` module whose internal name is
**`hell2k`** -- the game's development codename.

How it got here -- including every retraction, and there were several -- is in
[psprecomp/docs/BRINGUP.md](psprecomp/docs/BRINGUP.md).

## Getting Started

```powershell
git clone --recursive https://github.com/sp00nznet/wtf-psp-recomp
cd wtf-psp-recomp
cmake -S . -B build
cmake --build build --config Release

# map a dump you own and pull out the boot chain + microgames
.\scripts\extract.ps1 -Iso "WTF - Work Time Fun (USA).iso"
```

`extract.ps1` writes to `work/` (gitignored) and prints a report. Nothing it
produces is committed.

### Decryption

Every executable on the disc is an encrypted `~PSP` module. Until psprecomp's own
tag transform lands, plaintext comes from
[`pspdecrypt`](https://github.com/John-K/pspdecrypt) — GPL-3.0, so it runs as a
**separate process** and is never linked or vendored, exactly as PPSSPP is used
as an oracle. This repo and the toolkit stay MIT.

```bash
# in WSL, or any Linux box

# game-sharing microgames are PBPs; -P reaches the executable inside
pspdecrypt -P b02_bootbin.dat -o b02_lumberjack.elf

# the main executable is a bare ~PSP
pspdecrypt EBOOT.BIN -o eboot_hell2k.elf
```

### Building and playing

Decrypt the microgames into `work\dec\` as `<id>.elf` (`b02_lumberjack.elf`,
`b04_pendemonium.elf`, ...; see above), then:

```powershell
.\scripts\build.ps1
.\build\games\wtf\Release\wtf_b04_pendemonium.exe
```

`build.ps1` recompiles every module it finds into `build\gen\` and builds one
executable per microgame. The generated C stays in `build\`: it is derived from
your copy of the game and is never committed.

| Keyboard | Controller | PSP |
|---|---|---|
| Arrow keys | D-pad | D-pad |
| -- | Left stick | Analog stick |
| Z | A | Cross |
| X | B | Circle |
| A | X | Square |
| S | Y | Triangle |
| Q / W | LB, LT / RB, RT | L / R |
| Enter | Start | Start |
| Backspace | Back | Select |

Press Start at the WTF title, Cross on the job, Cross on START. In
Pendemonium, Cross drops a cap.

## Layout

```
wtf-psp-recomp/
├── psprecomp/        # the toolkit, as a git submodule
├── games/wtf/        # the host: window, controls, one exe per microgame
├── scripts/          # extract.ps1 (map a dump), build.ps1 (recompile + build)
├── docs/             # NOTES.md — findings specific to this title
└── work/             # gitignored: dumps, decrypted modules, generated C
```

The toolkit lives in its own repo on purpose: it is the thing you fork to
recompile *your* PSP game, and keeping it free of anything WTF-specific is what
makes that possible.

## Legal

No game data, no firmware, no keys are distributed here. Recompiling requires a
dump you made from media you own. The toolkit is a clean-room implementation
built from published documentation and MIT/BSD reverse-engineering work.

## License

MIT — see [LICENSE](LICENSE). *WTF: Work Time Fun* is © Sony Computer
Entertainment / D3 Publisher. This project is not affiliated with either.
