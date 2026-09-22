@echo off
title IT Administration Repair Toolkit
color 0A
setlocal EnableDelayedExpansion

:: ============================================
:: Check for Admin rights, relaunch if needed
:: ============================================
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set LOGDIR=%~dp0Logs
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
set LOGFILE=%LOGDIR%\ToolkitLog_%date:~-4%%date:~4,2%%date:~7,2%.txt

:MENU
cls
echo ==============================================================
echo               IT ADMINISTRATION REPAIR TOOLKIT
echo ==============================================================
echo  [1]  System Info              [10] Reset TCP/IP
echo  [2]  SFC Scan                 [11] Battery Report
echo  [3]  SFC Verify Only          [12] Performance Report
echo  [4]  DISM Scan Health         [13] WinRE Info
echo  [5]  DISM Repair (RestoreH.)  [14] System Restore
echo  [6]  Component Store Cleanup  [15] Memory Diagnostic
echo  [7]  Drive Health (SMART)     [16] Advanced Startup
echo  [8]  Flush DNS                [17] Check Windows Update
echo  [9]  Reset Winsock            [18] Full Report (All Info)
echo                                [19] Disk Cleanup
echo                                [20] Event Log Errors (last 20)
echo  [Q]  Exit
echo ==============================================================
set /p choice="Select [1-20/Q]: "

if /I "%choice%"=="Q" goto END
if "%choice%"=="1"  goto SYSINFO
if "%choice%"=="2"  goto SFCSCAN
if "%choice%"=="3"  goto SFCVERIFY
if "%choice%"=="4"  goto DISMSCAN
if "%choice%"=="5"  goto DISMREPAIR
if "%choice%"=="6"  goto CLEANUP
if "%choice%"=="7"  goto DRIVEHEALTH
if "%choice%"=="8"  goto FLUSHDNS
if "%choice%"=="9"  goto WINSOCK
if "%choice%"=="10" goto TCPIP
if "%choice%"=="11" goto BATTERY
if "%choice%"=="12" goto PERFREPORT
if "%choice%"=="13" goto WINREINFO
if "%choice%"=="14" goto RESTORE
if "%choice%"=="15" goto MEMDIAG
if "%choice%"=="16" goto ADVSTARTUP
if "%choice%"=="17" goto WINUPDATE
if "%choice%"=="18" goto FULLREPORT
if "%choice%"=="19" goto DISKCLEAN
if "%choice%"=="20" goto EVENTLOG
goto MENU

:SYSINFO
cls
echo Gathering system info... (also logged to %LOGFILE%)
systeminfo
systeminfo >> "%LOGFILE%" 2>&1
goto PAUSE_MENU

:SFCSCAN
cls
echo Running SFC /scannow ...
sfc /scannow >> "%LOGFILE%" 2>&1
sfc /scannow
goto PAUSE_MENU

:SFCVERIFY
cls
echo Running SFC /verifyonly ...
sfc /verifyonly
sfc /verifyonly >> "%LOGFILE%" 2>&1
goto PAUSE_MENU

:DISMSCAN
cls
echo Running DISM /ScanHealth ...
DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /ScanHealth >> "%LOGFILE%" 2>&1
goto PAUSE_MENU

:DISMREPAIR
cls
echo Running DISM /RestoreHealth ...
DISM /Online /Cleanup-Image /RestoreHealth
DISM /Online /Cleanup-Image /RestoreHealth >> "%LOGFILE%" 2>&1
goto PAUSE_MENU

:CLEANUP
cls
echo Cleaning up WinSxS component store ...
DISM /Online /Cleanup-Image /StartComponentCleanup
DISM /Online /Cleanup-Image /StartComponentCleanup >> "%LOGFILE%" 2>&1
goto PAUSE_MENU

:DRIVEHEALTH
cls
echo Checking drive SMART status ...
wmic diskdrive get model,status,size
wmic diskdrive get model,status,size >> "%LOGFILE%" 2>&1
echo.
echo Checking file system health (chkdsk read-only):
chkdsk C:
goto PAUSE_MENU

:FLUSHDNS
cls
echo Flushing DNS cache ...
ipconfig /flushdns
ipconfig /flushdns >> "%LOGFILE%" 2>&1
goto PAUSE_MENU

:WINSOCK
cls
echo Resetting Winsock catalog ...
netsh winsock reset
netsh winsock reset >> "%LOGFILE%" 2>&1
echo NOTE: A restart is required for this to take effect.
goto PAUSE_MENU

:TCPIP
cls
echo Resetting TCP/IP stack ...
netsh int ip reset
netsh int ip reset >> "%LOGFILE%" 2>&1
echo NOTE: A restart is required for this to take effect.
goto PAUSE_MENU

:BATTERY
cls
echo Generating battery report to Desktop ...
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery-report.html"
echo Saved to Desktop\battery-report.html
goto PAUSE_MENU

:PERFREPORT
cls
echo Generating performance/health report (60 sec, please wait) ...
powercfg /energy /output "%USERPROFILE%\Desktop\energy-report.html"
echo Saved to Desktop\energy-report.html
goto PAUSE_MENU

:WINREINFO
cls
echo Checking WinRE status ...
reagentc /info
reagentc /info >> "%LOGFILE%" 2>&1
goto PAUSE_MENU

:RESTORE
cls
echo Opening System Restore ...
rstrui.exe
goto PAUSE_MENU

:MEMDIAG
cls
echo Launching Windows Memory Diagnostic ...
mdsched.exe
goto PAUSE_MENU

:ADVSTARTUP
cls
echo Restarting into Advanced Startup Options in 5 seconds...
echo Press Ctrl+C to cancel.
timeout /t 5
shutdown /r /o /f /t 0
goto PAUSE_MENU

:WINUPDATE
cls
echo Checking Windows Update status via PowerShell/COM object ...
powershell -Command "(New-Object -ComObject Microsoft.Update.AutoUpdate).DetectNow()"
echo Update check triggered. Check Settings > Windows Update for results.
goto PAUSE_MENU

:DISKCLEAN
cls
echo Launching Disk Cleanup ...
cleanmgr.exe
goto PAUSE_MENU

:EVENTLOG
cls
echo Last 20 System Error events ...
powershell -Command "Get-WinEvent -FilterHashtable @{LogName='System'; Level=2} -MaxEvents 20 | Format-Table TimeCreated, Id, ProviderName, Message -AutoSize -Wrap"
goto PAUSE_MENU

:FULLREPORT
cls
echo Generating full system report to %LOGFILE% ...
echo ===== SYSTEM INFO ===== >> "%LOGFILE%"
systeminfo >> "%LOGFILE%" 2>&1
echo ===== DISK HEALTH ===== >> "%LOGFILE%"
wmic diskdrive get model,status,size >> "%LOGFILE%" 2>&1
echo ===== SFC VERIFY ===== >> "%LOGFILE%"
sfc /verifyonly >> "%LOGFILE%" 2>&1
echo ===== DISM CHECK ===== >> "%LOGFILE%"
DISM /Online /Cleanup-Image /CheckHealth >> "%LOGFILE%" 2>&1
echo ===== NETWORK CONFIG ===== >> "%LOGFILE%"
ipconfig /all >> "%LOGFILE%" 2>&1
echo ===== WINRE STATUS ===== >> "%LOGFILE%"
reagentc /info >> "%LOGFILE%" 2>&1
echo Full report saved to: %LOGFILE%
goto PAUSE_MENU

:PAUSE_MENU
echo.
echo ----------------------------------------------------------
pause
goto MENU

:END
echo Exiting IT Toolkit. Logs saved in: %LOGDIR%
timeout /t 2 >nul
exit
