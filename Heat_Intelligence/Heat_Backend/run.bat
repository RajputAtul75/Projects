@echo off
call .venv\Scripts\activate.bat
echo Starting FastAPI Server on port 8000...
uvicorn main:app --reload --host 127.0.0.1 --port 8000