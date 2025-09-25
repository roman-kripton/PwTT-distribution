@echo off
chcp 65001 > nul
SETLOCAL EnableDelayedExpansion

:: Переход в папку, где находится скрипт
cd /d "%~dp0"

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

echo %BLUE%=== PwTT Repository Update Script ===%RESET%
echo.

:: Проверка Git
echo %YELLOW%[1/4]%RESET% %CYAN%Checking Git...%RESET%
git --version 2>nul
if %errorlevel% neq 0 (
    echo %RED%Git not found. Please install Git first.%RESET%
    echo.
    pause
    exit /b 1
) else (
    echo %GREEN%Git is available.%RESET%
)

:: Проверка что это git репозиторий
echo %YELLOW%[2/4]%RESET% %CYAN%Checking if this is a git repository...%RESET%
git status >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED%This is not a git repository or repository is corrupted.%RESET%
    echo %YELLOW%Please run the main installation script instead.%RESET%
    echo.
    pause
    exit /b 1
) else (
    echo %GREEN%Valid git repository found.%RESET%
)

:: Проверка и исправление безопасной директории
echo %YELLOW%[3/4]%RESET% %CYAN%Checking repository safety settings...%RESET%
git status >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%Detected repository ownership issue. Fixing...%RESET%
    
    :: Получаем текущий путь и преобразуем его для Git
    set "REPO_PATH=%~dp0"
    :: Убираем завершающий обратный слэш
    if "!REPO_PATH:~-1!"=="\" set "REPO_PATH=!REPO_PATH:~0,-1!"
    :: Заменяем обратные слэши на прямые для Git
    set "REPO_PATH=!REPO_PATH:\=/!"
    
    echo %CYAN%Adding to safe directories: !REPO_PATH!%RESET%
    git config --global --add safe.directory "!REPO_PATH!"
    
    if %errorlevel% neq 0 (
        echo %RED%Failed to add repository to safe directories.%RESET%
        echo %YELLOW%Please run manually: git config --global --add safe.directory "!REPO_PATH!"%RESET%
        echo.
        pause
        exit /b 1
    ) else (
        echo %GREEN%Repository added to safe directories successfully.%RESET%
    )
) else (
    echo %GREEN%Repository safety check passed.%RESET%
)

:: Обновление репозитория
echo %YELLOW%[4/4]%RESET% %CYAN%Updating repository...%RESET%
git pull
if %errorlevel% neq 0 (
    echo %RED%Failed to update repository.%RESET%
    echo %YELLOW%Please check your internet connection and try again.%RESET%
    echo.
    pause
    exit /b 1
)

echo.
echo %GREEN%Repository updated successfully!%RESET%
echo %CYAN%Current directory: %CD%%RESET%
echo.

:: Рестарт Docker контейнеров для обновления кода
echo %MAGENTA%=== Restarting Docker containers to apply updates ===%RESET%
echo %YELLOW%[5/5]%RESET% %CYAN%Restarting Docker containers...%RESET%

:: Проверка наличия Docker Compose
docker-compose --version >nul 2>&1
if %errorlevel% neq 0 (
    echo %YELLOW%Docker Compose not found, trying docker compose...%RESET%
    docker compose version >nul 2>&1
    if %errorlevel% neq 0 (
        echo %RED%Docker Compose not available. Please install Docker Compose.%RESET%
        echo %YELLOW%Containers need to be restarted manually to apply updates.%RESET%
        echo.
        pause
        exit /b 1
    ) else (
        set DOCKER_COMPOSE_CMD=docker compose
    )
) else (
    set DOCKER_COMPOSE_CMD=docker-compose
)

:: Рестарт контейнеров
echo %CYAN%Stopping containers...%RESET%
%DOCKER_COMPOSE_CMD% down

echo %CYAN%Starting containers with updated code...%RESET%
%DOCKER_COMPOSE_CMD% up -d

if %errorlevel% neq 0 (
    echo %RED%Failed to restart Docker containers.%RESET%
    echo %YELLOW%Please check Docker configuration and try again.%RESET%
    echo.
    pause
    exit /b 1
) else (
    echo %GREEN%Docker containers restarted successfully!%RESET%
    echo %CYAN%New code is now running in containers.%RESET%
)

echo.
echo %GREEN%=== Update completed successfully! ===%RESET%
echo %CYAN%Repository updated and Docker containers restarted.%RESET%
echo.
pause