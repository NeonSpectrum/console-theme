# Console Theme

A minimal [Starship](https://starship.rs/) prompt setup with optional [Oh My Zsh](https://ohmyz.sh/) on Linux. One command installs everything and copies the included `starship.toml` to the right place.

## Prerequisites

- A [Nerd Font](https://www.nerdfonts.com/) installed and enabled in your terminal
- `curl` (Linux / macOS / Windows)

## Quick install

### Linux / macOS

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/NeonSpectrum/console-theme/main/install.sh)"
```

Or:

```bash
curl -fsSL https://raw.githubusercontent.com/NeonSpectrum/console-theme/main/install.sh | bash
```

### Windows (Command Prompt)

```cmd
curl -fsSL -o "%TEMP%\install.bat" https://raw.githubusercontent.com/NeonSpectrum/console-theme/main/install.bat && "%TEMP%\install.bat"
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/NeonSpectrum/console-theme/main/install.bat -OutFile $env:TEMP\install.bat; & $env:TEMP\install.bat
```

You will be prompted to pick your shell. Only options compatible with your OS are shown.

## Supported Shells

| Platform | Installer | Shells |
|----------|-----------|--------|
| **Linux / macOS** | `install.sh` | Bash, Fish, Zsh, Ion, Elvish, Tcsh, Nushell, Xonsh |
| **Windows** | `install.bat` | PowerShell, Elvish, Cmd (with [Clink](https://github.com/chrisant996/clink)) |

## What the Installer Does

1. **Oh My Zsh** — installed on **Linux only** (skipped on macOS and Windows)
2. **[Starship](https://starship.rs/)** — installed via the official install script (`curl -sS https://starship.rs/install.sh | sh`)
3. **`starship.toml`** — copied to `~/.config/starship.toml` (or `%USERPROFILE%\.config\starship.toml` on Windows)
4. **Shell init** — adds the Starship init line to your chosen shell config (skips if already present)

The installer is idempotent — safe to run more than once.

## Manual Install

Clone the repo and run the script locally:

```bash
git clone https://github.com/NeonSpectrum/console-theme.git
cd console-theme
chmod +x install.sh
./install.sh
```

On Windows:

```cmd
git clone https://github.com/NeonSpectrum/console-theme.git
cd console-theme
install.bat
```

## Customization

Edit `~/.config/starship.toml` after install, or change the repo's `starship.toml` before running the installer.

See the [Starship configuration docs](https://starship.rs/config/) for all available options.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Icons show as boxes | Install and enable a [Nerd Font](https://www.nerdfonts.com/) in your terminal |
| `starship: command not found` | Add `~/.local/bin` to your PATH and restart the terminal |
| Oh My Zsh failed on Linux | Install `zsh` and `git`, then re-run the installer |
| Cmd option unavailable | Install [Clink](https://github.com/chrisant996/clink) v1.2.30+ first |

## License

See the repository license file for details.
