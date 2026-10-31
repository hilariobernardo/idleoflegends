@echo off
where godot >nul 2>nul
if errorlevel 1 (
  echo Instale Godot 4.7.2 e abra game\project.godot no editor.
  pause
  exit /b 1
)
godot --path "%~dp0game"
