# AETHER AR

**An unofficial mixed-reality mod for *Dragon Ball Z: Budokai Tenkaichi 3* (PS2), for Meta Quest.** The fighters
fight in your real room at 20 cm tall, on your floor and your tables, and your walls and furniture (from the Quest's
own Space Setup) block them.

**Bring your own disc.** Nothing of the game is included: no code, no graphics, no sound. You need your own copy of
the game (PlayStation 2, **USA**, SLUS-21678) as an ISO; Setup checks it and builds the game from it on your PC.

## Download

Get **`AETHER-AR-<version>.zip`** from **[Releases](../../releases)**, unpack it and double-click
**`Install AETHER AR.cmd`**. What you need (a PC VR-class Windows PC, the Meta Horizon Link app, a Quest with Link or
Air Link), the Quest and Link settings, the controls and the troubleshooting are in
**[package/README.md](package/README.md)** and in *Help* in the AETHER AR window.

## Help

- **Something does not work:** open an issue (**[New issue](../../issues/new/choose)**). The form says which log to
  attach. In the AETHER AR window, **Report a problem** saves everything a helper needs as one ZIP on your desktop.
- **Questions, ideas, your recordings:** **[Discussions](../../discussions)**.
- **Never post, link or ask for disc images, BIOS files or game files.** Posts that do are deleted.

## What is in this repository

- `package/` holds the current release exactly as it is in the ZIP: the Setup (`setup/`), the mod's complete source
  as a patch against BT3-Recomp (`mod/aether-ar.patch`, its base version in `mod/BASE`) and the player README.
- `tools/new-release.ps1` publishes a release here.

## License and credits

AETHER AR is built on [BT3-Recomp](https://github.com/z3xox/BT3-Recomp) by z3xox (GPL-3.0) and is GPL-3.0 as well
(see [`LICENSE`](LICENSE)). [`NOTICE`](NOTICE) says what was changed and lists the third-party parts.

AETHER AR is an unofficial fan project by AETHER. It is not affiliated with or endorsed by Bandai Namco, Spike
Chunsoft, Toei Animation, Bird Studio / Shueisha or Meta. All trademarks belong to their owners; the game's name is
used only to say which game this mod is for.
