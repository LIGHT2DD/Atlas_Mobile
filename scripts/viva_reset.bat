@echo off
REM ==============================================================================
REM ATLAS - Academic Thesis Lifecycle & Assessment Suite
REM VIVA DEMO RESET & VERIFICATION SCRIPT
REM ==============================================================================

echo [ATLAS] Initializing Clean Academic Environment for Presentation & Viva...
echo ------------------------------------------------------------------------------

REM 1. Activate virtual environment if present
if exist ".venv\Scripts\activate.bat" (
    echo [*] Activating local virtual environment (.venv)...
    call .venv\Scripts\activate.bat
)

REM 2. Reset and seed SQLite database
echo [*] Seeding database with realistic institutional records...
python -m scripts.seeders.seed_atlas
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Database seeding failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [*] Executing core architectural test suite...
python -m pytest tests/ -q
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Test verification failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ==============================================================================
echo [SUCCESS] ATLAS Environment Ready for Viva Demonstration!
echo ==============================================================================
echo Credentials Reference:
echo   Coordinator: coordinator@atlas.edu       Password: Password123
echo   Supervisor:  supervisor1@atlas.edu      Password: Password123
echo   Supervisor:  supervisor2@atlas.edu      Password: Password123
echo   Student:     student1@atlas.edu         Password: Password123
echo   Student:     student2@atlas.edu         Password: Password123
echo.
echo Mobile Release Binary:
echo   app-arm64.apk (Standalone ARM64 APK)
echo ==============================================================================
pause
