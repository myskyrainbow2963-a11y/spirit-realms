@echo off
setlocal
set "GODOT_EXE=E:\Program Files\godot\Godot_v4.7.1-stable_win64.exe"
set "PROJECT_DIR=%~dp0"

if not exist "%GODOT_EXE%" (
  echo Godot standard executable was not found:
  echo %GODOT_EXE%
  pause
  exit /b 1
)

start "" "%GODOT_EXE%" --path "%PROJECT_DIR%" --editor
