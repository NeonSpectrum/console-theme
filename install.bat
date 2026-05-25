@echo off
setlocal EnableDelayedExpansion

REM Install your preferred shell config, then install Starship and copy starship.toml.
REM
REM Usage:
REM   install.bat
REM   curl -fsSL -o "%TEMP%\install.bat" https://raw.githubusercontent.com/NeonSpectrum/console-theme/main/install.bat ^&^& "%TEMP%\install.bat"

set "REPO_RAW=https://raw.githubusercontent.com/NeonSpectrum/console-theme/main"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "STARSHIP_TOML_SRC=%SCRIPT_DIR%\starship.toml"
set "STARSHIP_MARKER=# starship prompt (added by install.bat)"

echo.
echo [INFO] Console Theme installer for Windows
echo.

call :show_shell_menu
call :configure_shell
if errorlevel 1 exit /b 1

call :install_starship
if errorlevel 1 exit /b 1

call :copy_starship_config
if errorlevel 1 exit /b 1

call :setup_starship_init
if errorlevel 1 exit /b 1

call :print_success
exit /b 0

:install_starship
where starship >nul 2>&1
if not errorlevel 1 (
    echo [OK] Starship is already installed.
    for /f "delims=" %%v in ('starship --version 2^>nul') do echo       %%v
    goto :eof
)

echo [INFO] Installing Starship...

where sh >nul 2>&1
if not errorlevel 1 (
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    if not errorlevel 1 (
        echo [OK] Starship installed via install.sh.
        goto :ensure_path
    )
    echo [WARN] curl ^| sh install failed, trying winget...
)

where winget >nul 2>&1
if not errorlevel 1 (
    winget install --id Starship.Starship -e --accept-source-agreements --accept-package-agreements
    if not errorlevel 1 (
        echo [OK] Starship installed via winget.
        goto :ensure_path
    )
)

echo [ERROR] Could not install Starship.
echo         Install Git Bash or WSL for: curl -sS https://starship.rs/install.sh ^| sh
echo         Or install manually: winget install Starship.Starship
exit /b 1

:ensure_path
set "LOCAL_BIN=%USERPROFILE%\.local\bin"
if exist "%LOCAL_BIN%\starship.exe" (
    set "PATH=%LOCAL_BIN%;%PATH%"
)
where starship >nul 2>&1
if errorlevel 1 (
    echo [WARN] Starship was installed but is not on PATH yet.
    echo        Add %LOCAL_BIN% to your PATH and restart the terminal.
)
goto :eof

:copy_starship_config
set "CONFIG_DIR=%USERPROFILE%\.config"
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"

if exist "%STARSHIP_TOML_SRC%" (
    copy /Y "%STARSHIP_TOML_SRC%" "%CONFIG_DIR%\starship.toml" >nul
    echo [OK] Copied starship.toml to %USERPROFILE%\.config\starship.toml
    goto :eof
)

echo [INFO] Downloading starship.toml from %REPO_RAW%...
curl -fsSL -o "%CONFIG_DIR%\starship.toml" "%REPO_RAW%/starship.toml"
if errorlevel 1 (
    echo [ERROR] Could not download starship.toml from %REPO_RAW%
    exit /b 1
)
echo [OK] Downloaded starship.toml to %USERPROFILE%\.config\starship.toml
goto :eof

:show_shell_menu
echo.
echo Select your shell:
echo   1^) PowerShell
echo   2^) Elvish
echo   3^) Cmd ^(requires Clink v1.2.30+^)
echo   0^) Skip shell configuration
echo.
set /p "SHELL_CHOICE=Enter choice [1-3, 0 to skip]: "
goto :eof

:configure_shell
if "%SHELL_CHOICE%"=="1" goto :eof
if "%SHELL_CHOICE%"=="2" goto :eof
if "%SHELL_CHOICE%"=="3" goto :eof
if "%SHELL_CHOICE%"=="0" (
    echo [INFO] Skipped shell configuration.
    goto :eof
)
echo [ERROR] Invalid choice: %SHELL_CHOICE%
exit /b 1

:setup_starship_init
if "%SHELL_CHOICE%"=="1" goto :setup_powershell
if "%SHELL_CHOICE%"=="2" goto :setup_elvish
if "%SHELL_CHOICE%"=="3" goto :setup_cmd
if "%SHELL_CHOICE%"=="0" goto :eof
goto :eof

:setup_powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$marker = '# starship prompt (added by install.bat)';" ^
  "$initLine = 'Invoke-Expression (&starship init powershell)';" ^
  "$profilePath = $PROFILE.CurrentUserAllHosts;" ^
  "$profileDir = Split-Path -Parent $profilePath;" ^
  "if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null };" ^
  "if (-not (Test-Path $profilePath)) { New-Item -ItemType File -Path $profilePath -Force | Out-Null };" ^
  "$content = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue;" ^
  "if ($content -and $content.Contains($marker)) { Write-Host '[OK] Starship init already configured in' $profilePath; exit 0 };" ^
  "Add-Content -Path $profilePath -Value ([Environment]::NewLine + $marker + [Environment]::NewLine + $initLine);" ^
  "Write-Host '[OK] Added Starship init to' $profilePath"
goto :eof

:setup_elvish
set "ELVISH_CONFIG=%APPDATA%\elvish\rc.elv"
if not exist "%APPDATA%\elvish" mkdir "%APPDATA%\elvish"
if not exist "%ELVISH_CONFIG%" type nul > "%ELVISH_CONFIG%"
findstr /C:"%STARSHIP_MARKER%" "%ELVISH_CONFIG%" >nul 2>&1
if not errorlevel 1 (
    echo [OK] Starship init already configured in %ELVISH_CONFIG%
    goto :eof
)
>>"%ELVISH_CONFIG%" echo.
>>"%ELVISH_CONFIG%" echo %STARSHIP_MARKER%
>>"%ELVISH_CONFIG%" echo eval (starship init elvish)
echo [OK] Added Starship init to %ELVISH_CONFIG%
goto :eof

:setup_cmd
set "CLINK_SCRIPT="
if defined CLINK_DIR set "CLINK_SCRIPT=%CLINK_DIR%\starship.lua"
if not defined CLINK_SCRIPT if exist "%LOCALAPPDATA%\clink\scripts" set "CLINK_SCRIPT=%LOCALAPPDATA%\clink\scripts\starship.lua"
if not defined CLINK_SCRIPT if exist "%ProgramFiles%\clink\scripts" set "CLINK_SCRIPT=%ProgramFiles%\clink\scripts\starship.lua"

if not defined CLINK_SCRIPT (
    echo [WARN] Clink scripts directory not found.
    echo        Install Clink v1.2.30+ from https://github.com/chrisant996/clink
    echo        Then create starship.lua in your Clink scripts folder with:
    echo          load^(io.popen^('starship init cmd'^):read^("*a"^)^)^^(^)
    exit /b 1
)

(
echo -- starship prompt (added by install.bat^)
echo load^(io.popen^('starship init cmd'^):read^("*a"^)^)^^(^)
) > "%CLINK_SCRIPT%"
echo [OK] Wrote Starship init to %CLINK_SCRIPT%
goto :eof

:print_success
echo.
echo [OK] ============================================
echo [OK]   Installation completed successfully!
echo [OK] ============================================
echo.
echo Next steps:
echo   * Restart your terminal
echo   * Ensure a Nerd Font is enabled in your terminal
echo   * Starship config: %USERPROFILE%\.config\starship.toml
echo   * Docs: https://starship.rs/
echo.
goto :eof
