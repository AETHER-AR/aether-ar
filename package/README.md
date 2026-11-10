# AETHER AR

**An unofficial mixed-reality mod for *Dragon Ball Z: Budokai Tenkaichi 3* (PS2), for Meta Quest.** The fighters fight
in your real room at 20 cm tall, on your floor and your tables, and your walls and furniture (from the Quest's own
Space Setup) block them. A fighter knocked into a wall takes the damage the game gives for crashing into a rock.

Built on [BT3-Recomp](https://github.com/z3xox/BT3-Recomp) (a static recompilation of the PS2 game, GPL-3.0). This mod
adds the headset output (OpenXR over Link / Air Link with passthrough) and the room: collision, placement, the
HUD as its own panel.

## Version 1.0.16

- **Smooth Link over the cable.** If you started Link over a USB cable from the headset's Quick Settings, the picture
  and the buttons could lag up to two seconds behind. In that mode Link sends a fixed 200 Mbit/s, and the Quest
  cannot unpack frames that big in time, so they pile up. AETHER AR now turns on Link's own setting for a steady
  100 Mbit/s (only for your Windows user, no admin rights). Link reads it only when it starts, so the first **Start**
  after the update restarts the Meta Horizon Link app on the PC once. A message tells you first. If Link was on in
  the headset, turn it on again there. The AETHER AR window shows it as *Smooth Link over the cable*. If you play on
  Air Link over weak Wi-Fi, you can turn it off in *Options*. Uninstalling puts back what was there before.
- **Quick start** now stops at *New Game* / *Continue* and leaves the choice to you. Before, it went on into the
  game by itself.
- Pressing the trigger to place the arena no longer reaches the game. Before, the same press also counted as L1/R1
  in the menu or the fight.

## Version 1.0.15

- Fixes the crash right after **Start** ("The game stopped unexpectedly (code -1073741819)") that hit many graphics
  cards. Four of the game's shaders described one of their inputs wrongly to the graphics driver. Only the newest
  NVIDIA cards and drivers took a path where that did not matter; on every other card it depended on the driver, and
  NVIDIA's crashed. It is described right now, so it no longer depends on your card.
- If the game's graphics cannot start on the graphics card Link uses, the game now stops at once and says what to do.
  Before, it ran on without a picture and closed by itself some minutes later.
- **Report a problem** now also saves your graphics card, driver, processor and memory, the game's own crash record and
  the crash records Windows keeps for the game, and says where to send it: **contact@aether-xr.com**.

## Version 1.0.14

- No more black shadow behind the fighters and the aiming ray in the headset. The slightly offset dark edge came from
  Meta Horizon Link itself: by default it sends the picture's transparency at a lower size and stretches it back
  slightly wrong. AETHER AR now turns on Link's own setting that sends it at full size (for your Windows user only, no
  admin rights). Link reads it only when it starts, so the first **Start** after the update restarts the Meta Horizon
  Link app on the PC once -- a message says so first; if Link was on in the headset, turn it on again there. The
  AETHER AR window shows it as *Link passthrough edge fix*, and *Options* can turn it off. Uninstalling puts back what
  was there before.

## Version 1.0.13

- The first start of the AETHER AR window no longer brings up a Windows Firewall question about "adb" (tested on a
  freshly installed Windows 11: install, shortcuts, launcher and removal).

## Version 1.0.12

- Help now opens with a numbered Quest setup checklist, including where to find each Meta setting and what it means.
- Fixes repeated menu navigation and reduces character color flicker on Quest.
- Adds an illustrated Quest-controller-to-PS2-button guide to Help in the AETHER AR desktop window.
- Adds Quest recording guidance to Help and the setup instructions: use Air Link for headset recordings.
- Known issue: Quest recording over USB Link can cause severe lag, freezing and dark trails. This is not fixed.

## Bring your own disc

**Nothing of the game is included.** No code, no graphics, no sound, no save. You need your own copy of
*Dragon Ball Z: Budokai Tenkaichi 3* (PlayStation 2, **USA**, SLUS-21678) as an ISO. The installer checks it and
builds the game from it on your PC. Please do not ask for, or share, the ISO or the built program.

AETHER AR is an unofficial fan project by AETHER. It is not affiliated with or endorsed by Bandai Namco, Spike
Chunsoft, Toei Animation, Bird Studio / Shueisha or Meta. All trademarks belong to their owners; the game's name is
used only to say which game this mod is for.

## You need

- A Windows 10/11 PC with a recent NVIDIA / AMD graphics card (PC VR class)
- The **Meta Horizon Link** app on the PC (formerly Meta Quest Link; meta.com/quest/setup), with these settings in
  the Link app:
  - Settings > General > OpenXR Runtime: **Set Meta Horizon Link as active** (not SteamVR)
  - Settings > General > **Unknown sources**: on (needed for apps not from the Meta store; harmless otherwise)
  - Settings > Beta: **Developer runtime features**, **Passthrough over Meta Horizon Link** and **Spatial data over
    Meta Horizon Link** turned on (without them the headset cannot show your room or hand it to the game)
- A Meta Quest 3 (Quest 3S / Quest Pro should work) with **Link** (cable) or **Air Link**, and **Space Setup** done
  for your room (headset: Settings > Physical space > Space setup -- walls, and your desk / table and other furniture)
- About **10 GB** free for the game folder on an **NTFS** drive (your normal C: drive; not an exFAT/FAT USB stick or
  external disk); about **20 GB** free on C: in all when the Visual Studio Build Tools still have to be installed
  (they always go to C:, the game folder too by default) -- and an internet connection for the install
- Your BT3 USA ISO

## Install

**First-time Quest setup:** in the AETHER AR desktop window, press **Help > Quest setup - Start here**.
The first Help page walks through the headset and PC settings separately. The Controller guide is the next tab.
You do not copy a room-scan file: the game reads the room captured on your own Quest.

1. Unpack the package (`AETHER-AR-<version>.zip`) anywhere. Put your ISO in a folder you keep (e.g. `Documents\BT3`).
2. Double-click **`Install AETHER AR.cmd`** (Windows may ask whether to run it: *Run*). The **AETHER AR Setup** window
   opens. Drag your ISO onto it (or press *Choose the ISO...*): it is checked at once. Leave the install folder
   (`C:\AETHER-AR`) and press **Install**. Setup then:
   - fetches BT3-Recomp from GitHub at the exact version this mod is made for, and puts the mod's changes on it,
   - sets up what is missing on your PC (Git, Python 3.10 or newer, CMake, Ninja, and the Visual Studio 2022 C++ /
     Clang build tools). Python 3.11 is supported; Setup installs Python 3.12 only when no supported version is found.
     It also tries to get optional Android platform-tools for headset status and boundary controls. Windows asks for
     permission for some installs: click *Yes*,
   - builds the game from your disc. **The first build takes 30-60 minutes**; the window shows each step.
   You do not need to install the build tools yourself. If Windows App Installer (winget) is missing, Setup explains
   how to add it before you try again.
3. When it is done, press **Start AETHER AR**.
   **Keep your disc image where it is: AETHER AR reads it every time you play.** You can delete the ZIP and the
   unpacked Setup folder.

**Start it** with the desktop shortcut **AETHER AR**, or type *AETHER* in the Start menu. To keep it in the taskbar:
right-click it in Start > *Pin to taskbar*. No shortcut? Double-click `AETHER AR.cmd` in the install folder.
`AETHER AR - START HERE.txt` in the install folder sums this page up.

**Updates:** a new version comes as a new ZIP from whoever gave you AETHER AR: unpack it and run its
`Install AETHER AR.cmd` -- Setup finds your install, keeps your memory card and settings, and updates it. (Close
AETHER AR first; Setup says so if it is still running.)

If something fails, the Setup window says what to do, with *Try again*. Its log is `install-log.txt` next to the
`.cmd`; the build's own log is `build\setup.log` in the install folder. (`setup\install-aether-ar.ps1` is the same
install without the window, for a terminal.)

## Remove AETHER AR

Windows **Settings > Apps > Installed apps > AETHER AR > Uninstall**. It asks first whether to keep your memory card
(a copy goes to `Documents\AETHER AR saves\<date>`), closes AETHER AR, and deletes the install folder, the shortcuts
and its entry. It also puts back the Link setting of the passthrough edge fix as it was before. Your disc image is
not touched. The tools Setup installed (Git, Python, the Visual Studio Build Tools
...) stay, because other programs may use them; the uninstaller lists them, and you can remove them in Settings > Apps.

## Play

### Recording on Quest

**Use Air Link when recording with the Quest's built-in camera.** Start the recording in Quest Home first,
then connect through Air Link and start AETHER AR. This path was confirmed working on the test Quest 3;
performance on other PCs and Wi-Fi networks is not guaranteed.

**USB Link with Quest recording has a known issue:** severe lag or freezing can begin even in the Link menu,
without AETHER AR running. Dark trails behind moving fighters have also been reported during affected sessions.
USB recording is not considered fixed or validated in this release. Do not use the headset power button as a
recording fix. The Quest camera menu and recording shortcut may be unavailable while inside Link; leave Link
to stop the recording in Quest Home. In the desktop window, Help > Quest setup includes this guidance;
Help > Controller guide > Quest recordings opens the recording details.

Press **Start** in the AETHER AR window first, then put the headset on and turn on **Link** (Quick Settings > Link;
or Air Link). The game appears in the headset by itself; it waits up to 5 minutes. In the AETHER AR window:

- **Mode**: *Room* (the fighters in your room) or *Screen* (the whole game on a big floating screen, e.g. for the
  story mode).
- **Room**: the Quest's own room from Space Setup (automatic).
- **Turn the Quest boundary off while playing**: needs USB debugging on the Quest (developer mode). Without it the
  game still runs.
- **Quick start**: no logos and no opening movie, straight to *New Game* / *Continue*. Off: the intro plays.
- **Link passthrough edge fix** (on): no black shadow behind the fighters. A Meta Horizon Link setting for your
  Windows user; Link restarts once at the next Start when it changes.

Then press **Start**. *Restart* applies changed settings. The window also shows the headset (USB / Wi-Fi, Link,
battery) and sets up adb over Wi-Fi for Air Link.

The package brings no save: the game starts like on a new memory card, with the characters and stages a new game
has. On the very first start choose **New Game** and answer **Yes** when it asks to create a save file on the memory
card (it is kept in `games\bt3\savedata` in the install folder). After that, **Continue** loads your progress.

In the headset: the menus show on a floating game screen (left stick + **A**, **B** = back; the trigger does not
select). The fight starts on your desk or table by itself -- look around your room for it. The trigger only **moves**
the fight: point a controller at the floor or a table (cyan ring = OK, red = not here) and pull it. The fight's HUD
(health, ki, timer, portraits) floats as its own panel above it. To end, take the headset off and press **Stop** in
the AETHER AR window.

| Quest controller | PS2 input | What it does |
| --- | --- | --- |
| Left stick | Left analog; D-pad in menus | Move relative to your view; navigate menus |
| Right stick | Right analog | Passed through to BT3 |
| A (right controller) | Cross | Confirm in menus; Cross action in a fight |
| B (right controller) | Circle | Back/cancel in menus; Circle action in a fight |
| X (left controller) | Square | Square action in a fight |
| Y (left controller) | Triangle | Triangle action in a fight |
| Left / right trigger | L1 / R1 | Normal BT3 inputs; when the placement ray is shown, pull either trigger to place the fight |
| Left / right grip | L2 / R2 | Normal BT3 inputs |
| Left / right stick click | L3 / R3 | Normal BT3 inputs; click both together to choose the fight's spot again |
| Menu button (left) | START | Pause; hold 3 seconds without grips to update Space Setup |
| Both grips + Menu | L2 + R2 + START | Switch between Room and Screen mode |
| Select | Not mapped | Quest controllers have no separate Select button |

In combat, the game assigns the Cross / Circle / Square / Triangle actions according to the selected
character and situation. The triggers do not confirm menu choices; use A (Cross). To end the game, take
the headset off and press **Stop** in the AETHER AR window.

For the illustrated controller guide, open the AETHER AR window on the PC and press **Help**.

## If something does not work

The line under the Start button always says what is happening -- waiting for the headset, playing, or what to do.
When the game cannot go on, a message box says exactly what to change:

- **The OpenXR runtime is not Meta Horizon Link** -- in the Link app: Settings > General > OpenXR Runtime > *Set Meta
  Horizon Link as active*.
- **No passthrough / no room from Link** -- turn on the Beta settings listed under *You need*.
- **No room came from the headset** -- run Space Setup in the headset (or choose *Mode: Screen* to play without the room).
- **The headset did not connect** -- the game waits 5 minutes for it: put it on and start Link, then press Start again.

Also:

- **A black, slightly offset shadow behind the fighters or the aiming ray:** check the line *Link passthrough edge
  fix* in the AETHER AR window. It should say *on*; if it says Link restarts at the next Start, press Start.
- **The headset shows a black or frozen picture while the game runs on in the PC window:** that is Link, not the
  mod. Press Stop, turn Link off and on in the headset (or restart the headset and the Link app on the PC), then
  press Start again.
- The very first start shows the memory card check and the logos for about 25 seconds before the versus menu.
- A room without a desk or table works too: the fight then starts on another table-high surface (a bed, a sideboard)
  or, if there is none, on the most open spot of the floor. Aim the controller at a spot and pull the trigger to move it.
- More than one room in Space Setup: the game uses the one you stand in when it starts.
- To change the room, hold the menu button for 3 seconds: the game stops and says how (update Space Setup in the
  headset, then press Start).

## Your room

The mod uses **your own room**: while the game runs it asks your headset for its Space Setup (walls, floor, ceiling,
furniture) over Link. It keeps that in memory only: nothing of your room is saved to disk or sent anywhere, and no
room is included in the package.

## Something does not work?

Press **Report a problem** in the AETHER AR window. It saves `AETHER-AR-report-<date>.zip` on your desktop: AETHER AR's
logs and settings, your graphics card, driver, processor and memory, and the crash records Windows keeps for the game.
Nothing of your room and nothing of the game is in it. Email that file to **contact@aether-xr.com**, with a sentence
about what happened.

## Known limits

- The fighters are 20 cm tall; other sizes may come in a later version.
- Parts of the arena the game only draws for its own camera (some sky, distant scenery) are not in your room.
- Air Link depends on your Wi-Fi. For Quest camera recordings, use Air Link; USB recording remains a known issue.
- Only the USA release is supported.
- The install needs GitHub: BT3-Recomp is fetched from there at the version in `mod\BASE`.

## License

GPL-3.0, like BT3-Recomp (see `LICENSE`). The mod's complete source is in the package: `mod\aether-ar.patch` holds
every change it makes to BT3-Recomp at the version in `mod\BASE`.
