@echo off
echo Creating Python Virtual Environment...
if not exist .venv (
    python -m venv .venv
)
call .venv\Scripts\activate.bat

echo Installing dependencies...
echo "Using pip from .venv\Scripts\pip.exe"
.\.venv\Scripts\pip.exe install -r requirements.txt

echo.
echo =======================================
echo Backend setup complete.
echo To run the server, use: run.bat
echo =======================================
pause