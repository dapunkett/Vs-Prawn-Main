<div align="center">

# 🦐 Friday Night Funkin': VS Prawn 🌴
### *A high-tide, seaside rhythm battle powered by NightmareVision Engine*

![Version](https://img.shields.io/badge/Version-1.0.0--dev-orange?style=for-the-badge)
![Haxe](https://img.shields.io/badge/Haxe-4.3.6-ea8220?style=for-the-badge&logo=haxe)
![Platform](https://img.shields.io/badge/Platform-Windows-0078d4?style=for-the-badge&logo=windows)
![Engine](https://img.shields.io/badge/Engine-NightmareVision-blueviolet?style=for-the-badge)

</div>

---

## 🌊 Overview

**VS Prawn** is an adrenaline-fueled, tropical beach-themed Friday Night Funkin' mod featuring custom graphics, fluid micro-animations, and a completely reimagined Freeplay interface tailored to the sandy shores.

### ✨ Key Features
- **🦐 Custom Shrimpy Freeplay Cards:** Distinctive cartoon cards with pixel-perfect song name pill capsules rendered in the custom `round.ttf` font.
- **🏖️ Staggered Coastline Card Carousel:** Cards slide along a natural beach curve, with the active song always smoothly centered on-screen.
- **🌊 Animated Wave Selector:** Custom blue wave arrow indicating the active song, reacting with an energetic pop on selection.
- **🪵 Wooden Difficulty Plank Banner:** Hand-drawn difficulty selector with interactive animated arrow buttons (`easy`, `normal`, `hard` story sprites supported).
- **⏱️ Looping Animated HUD Timebar:** High-definition timebar with Sparrow atlas loop, integrated seamlessly above the note strums.
- **🎨 Pure Tropical Aesthetic:** Dynamic lighting and untinted natural beach backdrop.

---

## 🛠️ How to Compile (Windows)

Follow these steps to compile **VS Prawn** from source on Windows:

### 1. Prerequisites

Make sure you have the following software installed:
1. **[Haxe 4.3.6+](https://haxe.org/download/)**: The core programming language.
2. **[Git for Windows](https://git-scm.com/downloads)**: Source control and dependency fetching.
3. **[Visual Studio Community 2022](https://visualstudio.microsoft.com/vs/community/)**:
   - In the Visual Studio Installer, select the **Desktop development with C++** workload.
   - Ensure **MSVC v143** and **Windows 10/11 SDK** are checked.

---

### 2. Install Project Dependencies

Open Command Prompt or PowerShell in the root project directory:

#### Standard Method
```sh
# Install and set up hxpkg
haxelib git hxpkg https://github.com/ADA-Funni/hxpkg add-hmm-compatibility
haxelib run hxpkg install
```

#### Fast Method (Requires [Rust](https://rust-lang.org/tools/install/))
```sh
haxelib git hxpkg https://github.com/ADA-Funni/hxpkg add-hmm-compatibility
haxelib run hxpkg to-hmm

cargo install --git https://github.com/ninjamuffin99/hmm-rs hmm-rs
hmm-rs clean
hmm-rs install

haxelib fixrepo
haxelib install hmm
haxelib remove grig.audio
haxelib run hmm reinstall grig.audio
haxelib fixrepo
```

---

### 3. Rebuild Lime & C++ NDLLs

Run this once to build the required C++ binaries:
```sh
haxelib run lime rebuild cpp -release
```

If you encounter issues related to Lime, run the included batch script:
```sh
.\projFiles\limeFixer.bat
```

---

### 4. Build and Run

To compile and immediately launch the game:
```sh
# Release build (recommended for gameplay)
haxelib run lime test windows

# Debug build (useful for troubleshooting)
haxelib run lime test windows -debug
```

To build without automatically launching:
```sh
haxelib run lime build windows
```
The compiled executable will be located in:
`export/release/windows/bin/ApplicationMain.exe`

---

## 🎮 Controls

| Action | Keybinding |
| :--- | :--- |
| **Note Keys** | `D F J K` or `Arrow Keys` |
| **Navigate Menus** | `W / S` or `Up / Down Arrow` |
| **Change Difficulty** | `A / D` or `Left / Right Arrow` |
| **Switch Freeplay Tabs** | `TAB` (Hold `SHIFT` for reverse) |
| **Listen to Instrumental** | `SPACE` in Freeplay |
| **Gameplay Changers** | `CTRL` in Freeplay |
| **Song Meta Editor** | `7` in Freeplay / PlayState |
| **Reset Highscore** | `R` in Freeplay |
| **Select / Confirm** | `ENTER` |
| **Back / Cancel** | `ESCAPE` / `BACKSPACE` |

---

## 📜 Credits & Acknowledgments

- **VS Prawn Team**: Artwork, concept, music, and custom menus.
- **[NightmareVision Team](https://github.com/NMVTeam/NightmareVision)**: Base engine architecture & features.
- **[Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine)**: ShadowMario and the Psych Engine team.
- **[Funkin' Crew](https://github.com/FunkinCrew)**: The creators of Friday Night Funkin' (ninjamuffin99, PhantomArcade, evilsk8r, Kawai Sprite).
- **Nebula_Zorua**: Modchart backend & Psych fork foundation.
- **MaybeMaru**: MoonChart & Flixel-Animate contributions.

---

<div align="center">
  <i>Stay shrimp-ple and keep funkin'! 🦐🌊</i>
</div>
