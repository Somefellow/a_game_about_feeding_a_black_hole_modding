# A Game About Feeding A Black Hole — Mod Workspace

A reproducible modding workflow for *A Game About Feeding A Black Hole* using [GDRETools](https://github.com/GDRETools/gdsdecomp).

---

## Prerequisites

- Linux (x86_64)
- `curl`, `unzip`, `diff` (standard on most distros)

---

## Setup

### 1. Install GDRETools

```bash
bash scripts/init.sh
```

This downloads `gdre_tools.x86_64` into `tools/` and makes it executable.

### 2. Drop your game PCK

Copy the original game `.pck` file into `original_pck/`:

```
original_pck/
└── A Game About Feeding A Black Hole.pck
```

> The PCK is not included in this repo (copyrighted). Export it from the game directory.

---

## Workflow

### Decompile the original PCK

```bash
bash scripts/decompile.sh
```

Recovers all GDScript source files into `recovered/`. You only need to do this once (or when you want a fresh baseline).

### Edit mods

All your changes go in `recovered/`. Edit any `.gd` file — the recompile script will detect what changed.

### Build a modded PCK

```bash
bash scripts/recompile.sh
```

This will:
1. Decompile the original PCK into a temp directory to establish a diff baseline
2. Auto-detect the bytecode revision
3. Compile only the `.gd` files you changed
4. Patch the original PCK with your compiled bytecode
5. Output `modded_<name>.pck` at the project root

### Deploy

Copy `modded_<name>.pck` into the game directory, replacing the original `.pck`.

---

## Directory Layout

```
/
├── scripts/
│   ├── init.sh          ← downloads GDRETools
│   ├── decompile.sh     ← recovers source from PCK
│   └── recompile.sh     ← compiles changes → modded PCK
├── original_pck/        ← put your .pck here (gitignored)
├── recovered/           ← decompiled source; edit here (gitignored)
├── tools/               ← GDRETools binary (gitignored, populated by init.sh)
├── compiled/            ← temp bytecode output (gitignored)
```

---

## Notes

- `recovered/` and `tools/` are gitignored — clone the repo fresh and re-run `init.sh` + `decompile.sh` to reconstruct them.
- The bytecode revision is auto-detected from the PCK; no hardcoded version strings.
- Absolute paths are used internally because gdre_tools requires them in headless mode.
