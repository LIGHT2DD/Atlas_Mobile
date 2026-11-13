@echo off
echo ===================================================
echo   ATLAS Backend Server - Academic Management System
echo ===================================================
echo Starting Uvicorn on 0.0.0.0:8000...
echo Phone / Mobile devices on Wi-Fi can connect to:
echo   http://192.168.0.101:8000
echo.
.venv\Scripts\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
pause

