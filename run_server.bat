@echo off
cd /d "%~dp0"
echo Starting Casino Server...
"love" server --console
pause