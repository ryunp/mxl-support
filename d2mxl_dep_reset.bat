@ECHO OFF
REM Authors: Ryan Paul
REM Date: 01/18/19
REM Version: 0.1.0
REM Usage: d2mxl_dep_reset.bat
REM Description: Removes any DEP settings for the current Diablo II install path

REM ~ Action List ~
REM 1. Install Path
REM 2. DEP Settings


SETLOCAL EnableDelayedExpansion
SETLOCAL EnableExtensions


REM ~ Privelege Mode Check ~
net session >nul 2>&1
if NOT %errorLevel% == 0 (
    CALL :log "Administrative permissions required. Run this batch file as Administrator..."
    pause >nul
    goto :exitapp
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Output file
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Define output temp file ~
SET "output_file=%tmp%\%~n0.txt"

REM ~ Test for report text file permissions ~
TYPE NUL > "%output_file%"
IF EXIST "%output_file%" (
    SET "output_file_exists=TRUE"
) ELSE (
    CALL :log "Could not create '%output_file%'^^^! Sending output to console..."
    CALL :log_nl
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM 1. Install Path
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET "reg_diabloII=HKEY_CURRENT_USER\Software\Blizzard Entertainment\Diablo II"

REM ~ Check for registry key ~
REG QUERY "%reg_diabloII%" >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    CALL :log "Checking For Installation Path..."

    REM ~ Search registry entries ~
    FOR /F "tokens=2*" %%a IN ('REG QUERY "%reg_diabloII%" /v "InstallPath"') DO SET "path_d2_install=%%b"

    REM ~ Remove trailing backslash ~
    IF "!path_d2_install:~-1!" == "\" SET "path_d2_install=!path_d2_install:~0,-1!"

    REM ~ Report findings ~
    IF "!path_d2_install!" == "" (
        CALL :log "Diablo II registry sub-key 'InstallPath' not found^^^!"
        GOTO :end
    ) ELSE (
        CALL :log "Entry Exists: '!path_d2_install!'"
    )
) ELSE (
    CALL :log "Parent 'Diablo II' registry key not found^^^!"
    GOTO :end
)

CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM 2. DEP Settings
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Config ~
SET "reg_hive[0]=HKCU"
SET "reg_hive[1]=HKLM"
SET "process_name[0]=Diablo II.exe"
SET "process_name[1]=Game.exe"
SET "reg_compat_path=Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
SET "dep_deleted=0"

REM ~ For each hive ~
FOR /L %%h IN (0,1,1) DO (
    REM ~ For each process ~
    FOR /L %%p IN (0,1,1) DO (
        REG DELETE "!reg_hive[%%h]!\%reg_compat_path%" /v "%path_d2_install%\!process_name[%%p]!" /f >nul 2>&1
        
        IF !ERRORLEVEL! EQU 0 (
            CALL :log "Deleted !reg_hive[%%h]!'s '!process_name[%%p]!' DEP entry"
            SET "dep_deleted=1"
        )
    )
)

IF %dep_deleted% EQU 0 (
    CALL :log "No DEP entries found for current installation"
)

CALL :log_nl

CALL :log "Use the Windows DEP dialog to re-add 'Game.exe' and 'Diablo II.exe' to the exception list..."

CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Show output file, if existing
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:end
IF DEFINED output_file_exists (
    NOTEPAD %output_file%
) ELSE (
    PAUSE
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM End of program
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:exitapp
EXIT /B 0



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Functions
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Function signature: log(str) ~
:log
    REM ~ Parens are needed to keep all characters escaped as strings ~
    IF DEFINED output_file_exists (
        (ECHO "%~1")>>"%output_file%"
    ) ELSE (
        (ECHO "%~1")
    )
EXIT /B 0


REM ~ Outputs a newline ~
:log_nl
    IF DEFINED output_file_exists (
        ECHO\>>"%output_file%"
    ) ELSE (
        ECHO\
    )
EXIT /B 0
