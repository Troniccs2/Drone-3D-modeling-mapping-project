@echo off
REM --- run_odm.bat ---
REM This script executes the OpenDroneMap Docker command.
REM Make sure Docker Desktop is running on your Windows machine.
REM
REM Argument 1 (%~1): The absolute path to the folder containing input images
REM                   (and where ODM will store its output, e.g., odm_orthophoto, odm_texturing).

set "INPUT_OUTPUT_PATH=%~1"

if "%INPUT_OUTPUT_PATH%"=="" (
    echo ERROR: No input folder path provided.
    echo Usage: run_odm.bat "C:\Path\To\Your\Images"
    exit /b 1
)

echo Starting OpenDroneMap processing for: %INPUT_OUTPUT_PATH%
echo.

REM The core Docker command
REM -v "%INPUT_OUTPUT_PATH%":/data maps the user's chosen folder to /data inside the container
docker run --rm -v "%INPUT_OUTPUT_PATH%":/data opendronemap/odm /data

REM Check the exit code of the last command
if %errorlevel% neq 0 (
    echo.
    echo ERROR: OpenDroneMap processing failed!
    echo Please check Docker Desktop status and the command output above.
    exit /b %errorlevel%
) else (
    echo.
    echo OpenDroneMap processing finished successfully.
    exit /b 0
)