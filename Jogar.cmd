@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\jogar.ps1" %*
if errorlevel 1 (
  echo.
  echo Nao foi possivel iniciar o Nexo Idle. Veja a mensagem acima.
  pause
  exit /b 1
)
exit /b 0
