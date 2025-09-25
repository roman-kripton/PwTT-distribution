@echo off
chcp 65001 > nul
SETLOCAL EnableDelayedExpansion


:: Определение цветов
set ESC=[
set GREEN=%ESC%32m
set YELLOW=%ESC%33m
set RED=%ESC%31m
set BLUE=%ESC%34m
set MAGENTA=%ESC%35m
set CYAN=%ESC%36m
set WHITE=%ESC%37m
set RESET=%ESC%0m

::Переход в папку, где находится скрипт
cd /d "%~dp0"
echo %CYAN%Script location: %CD%%RESET%
:: Функция для проверки прав администратора
:CHECK_ADMIN
echo %BLUE%Checking administrator privileges...%RESET%
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%Error: Script must be run as Administrator!%RESET%
    echo %YELLOW%Please right-click on the script and select "Run as administrator"%RESET%
    echo.
    pause
    exit /b 1
)
echo %GREEN%Administrator privileges confirmed.%RESET%
echo.

:: Проверка наличия Winget
echo %YELLOW%[1/8]%RESET% %CYAN%Checking Winget...%RESET%
winget --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%Winget not found.%RESET%
    echo %YELLOW%Please install Winget from:%RESET%
    echo https://apps.microsoft.com/detail/9nblggh4nns1?hl=ru-RU&gl=RU
    echo.
    pause
    exit /b 1
) else (
    echo %GREEN%Winget is available.%RESET%
)

:: Проверка виртуализации
echo %YELLOW%[2/8]%RESET% %CYAN%Checking virtualization...%RESET%
systeminfo | findstr /C:"Virtualization Enabled In Firmware" | find "Yes" >nul
if %errorlevel% neq 0 (
    echo %RED%Virtualization is disabled.%RESET% %GREEN%Enabling Hyper-V...%RESET%
    dism.exe /Online /Enable-Feature:Microsoft-Hyper-V /All /NoRestart
    echo %YELLOW%Hyper-V has been enabled. Please restart your computer and run the script again.%RESET%
    echo.
    pause
) else (
    echo %GREEN%Virtualization is enabled.%RESET%
)

:: Проверка и установка/обновление WSL
echo %YELLOW%[3/8]%RESET% %CYAN%Checking WSL...%RESET%
wsl --status >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%WSL not found or not enabled.%RESET% %GREEN%Installing WSL...%RESET%
    wsl --install -d Ubuntu --no-distribution
    if %errorlevel% neq 0 (
        echo %RED%Failed to install WSL. Please check your system configuration.%RESET%
        echo.
        pause
        exit /b 1
    )
    echo %YELLOW%WSL installation initiated. Please restart your computer after completion.%RESET%
    echo.
    pause
) else (
    echo %GREEN%WSL is installed.%RESET% %CYAN%Updating WSL...%RESET%
    wsl --update
    if %errorlevel% neq 0 (
        echo %RED%Failed to update WSL.%RESET%
        echo.
        pause
        exit /b 1
    )
    echo %GREEN%WSL updated successfully.%RESET%
)

:: 1. Проверка Python 3.11
echo %YELLOW%[4/8]%RESET% %CYAN%Checking Python 3.11...%RESET%
python --version 2>nul | find "3.11" >nul
if %errorlevel% neq 0 (
    echo %RED%Python 3.11 not found.%RESET% %GREEN%Installing...%RESET%
    winget install -e --id Python.Python.3.11
    if %errorlevel% neq 0 (
        echo %RED%Failed to install Python 3.11.%RESET%
        echo.
        pause
        exit /b 1
    )
    echo %GREEN%Installation completed. Please restart the script.%RESET%
    echo.
    pause
) else (
    echo %GREEN%Python 3.11 is already installed.%RESET%
)

:: 2. Проверка Docker
echo %YELLOW%[5/8]%RESET% %CYAN%Checking Docker...%RESET%
docker --version 2>nul
if %errorlevel% neq 0 (
    echo %RED%Docker not found.%RESET% %GREEN%Installing...%RESET%
    winget install -e --id Docker.DockerDesktop
    if %errorlevel% neq 0 (
        echo %RED%Failed to install Docker Desktop.%RESET%
        echo.
        pause
        exit /b 1
    )
    echo %GREEN%Installation completed. Start Docker Desktop and restart the script.%RESET%
    echo.
    pause
) else (
    echo %GREEN%Docker is already installed.%RESET%
)

:: 3. Проверка Git
echo %YELLOW%[6/8]%RESET% %CYAN%Checking Git...%RESET%
git --version 2>nul
if %errorlevel% neq 0 (
    echo %RED%Git not found.%RESET% %GREEN%Installing...%RESET%
    winget install -e --id Git.Git
    if %errorlevel% neq 0 (
        echo %RED%Failed to install Git.%RESET%
        echo.
        pause
        exit /b 1
    )
    echo %GREEN%Installation completed. Please restart the script.%RESET%
    echo.
    pause
) else (
    echo %GREEN%Git is already installed.%RESET%
)

:: 4. Проверка Antares SQL
@REM echo %YELLOW%[7/8]%RESET% %CYAN%Checking Antares SQL...%RESET%
@REM where antares-sql >nul 2>&1
@REM if %errorlevel% neq 0 (
@REM     echo %RED%Antares SQL not found.%RESET% %GREEN%Installing...%RESET%
@REM     winget install -e --id AntaresSQL.AntaresSQL
@REM     if %errorlevel% neq 0 (
@REM         echo %RED%Failed to install Antares SQL.%RESET%
@REM         echo.
@REM         pause
@REM         exit /b 1
@REM     )
@REM     echo %GREEN%Antares SQL installation completed.%RESET%
@REM ) else (
@REM     echo %GREEN%Antares SQL is already installed.%RESET%
@REM )

:: 5. Клонирование/обновление репозитория в папку pw-twin-tools
echo %YELLOW%[8/8]%RESET% %CYAN%Working with repository...%RESET%
set REPO_URL=https://github.com/roman-kripton/PwTT-distribution.git
set REPO_DIR=pw-twin-tools

if exist "%REPO_DIR%" (
    echo %MAGENTA%Repository found in %REPO_DIR%.%RESET% %GREEN%Updating...%RESET%
    cd "%REPO_DIR%"
    git pull
    if %errorlevel% neq 0 (
        echo %RED%Failed to update repository.%RESET%
        echo.
        pause
        exit /b 1
    )
) else (
    echo %MAGENTA%Repository not found.%RESET% %GREEN%Cloning to %REPO_DIR%...%RESET%
    git clone %REPO_URL% "%REPO_DIR%"
    if %errorlevel% neq 0 (
        echo %RED%Failed to clone repository.%RESET%
        echo.
        pause
        exit /b 1
    )
    cd "%REPO_DIR%"
)

:: Установка зависимостей Python
echo %CYAN%Installing Python dependencies...%RESET%
pip install -r requirements-for-acc.txt
if %errorlevel% neq 0 (
    echo %RED%Failed to install Python dependencies.%RESET%
    echo.
    pause
    exit /b 1
)

:: Запуск Docker Compose
echo %CYAN%Starting Docker Compose...%RESET%
docker compose up -d --build
if %errorlevel% neq 0 (
    echo %RED%Failed to start Docker Compose.%RESET%
    echo.
    pause
    exit /b 1
)

echo.
echo %GREEN%All operations completed successfully!%RESET%
echo %YELLOW%Please make sure Docker Desktop is running before using the application.%RESET%
echo %CYAN%Repository is located in the %REPO_DIR% folder.%RESET%
pause