@echo off
cd /d "%~dp0.."
call venv\Scripts\activate
python code_generator\generate_codes.py
pause
