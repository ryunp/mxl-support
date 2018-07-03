@ECHO OFF
REM Author: Ryan Paul
REM Date: 07/02/18
REM Usage: mxl_report.bat [process name]
REM Description: Scans various OS settings and file system paths related to D2

SETLOCAL EnableDelayedExpansion
SETLOCAL EnableExtensions



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Temp file
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Define output temp file ~
SET "output_file=%tmp%\d2mxl_report.txt"

REM ~ Test for temp file permissions ~
TYPE NUL > "%output_file%"
IF EXIST "%output_file%" (
    SET "tmpfile_exists=TRUE"
) ELSE (
    ECHO "Could not create temp file '%output_file%'^! Outputting to console..."
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Diablo II Install Path
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET "reg_diabloII=HKEY_CURRENT_USER\Software\Blizzard Entertainment\Diablo II"

FOR /F "tokens=2*" %%a in ('REG QUERY "%reg_diabloII%" /v "InstallPath"') DO SET "path_d2_install=%%b"
IF "%path_d2_install: =%" == "" (
    CALL :log "No Diablo II path found in registry^!"
) ELSE (
    CALL :log "D2 Installion Path: %path_d2_install%"
)
CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM DEP Settings
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Section header ~
CALL :log "[DEP Settings]"

REM ~ Reg path ~
SET "reg_dep_path=HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

REM ~ Loop over each D2 reg entry ~
FOR /F "delims=" %%a in ('REG QUERY "%reg_dep_path%" ^| FIND /I "%path_d2_install%"') DO (
    SET "match=%%a"
    
    REM Strip extra spaces, split on reg entry type, assign to aray
    SET "match=!match:    =!"
    SET "match='!match:REG_SZ=', '!'"

    REM Output info
    CALL :log "!match!"
)
CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Diablo II File Listing
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Seciton header ~
CALL :log "[File List]"

REM ~ /B reduces output to only names, /O:E sorts by extension ~
FOR /F "delims=" %%a in ('DIR /B /O:E "%path_d2_install%" ^| findstr /v /i "screenshot"') DO (
    REM Output info
    CALL :log "%%~a"
)
CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Show output temp file, if exists
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

IF DEFINED tmpfile_exists (
    NOTEPAD %output_file%
    DEL %output_file%
) ELSE (
    PAUSE
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM End of program
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

EXIT /B 0



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Functions
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Function signature: log(str) ~
:log
    IF DEFINED tmpfile_exists (
        ECHO %~1>> %output_file%
    ) ELSE (
        ECHO %~1
    )
EXIT /B 0

REM ~ Outputs a newline ~
:log_nl
    IF DEFINED tmpfile_exists (
        ECHO\>> %output_file%
    ) ELSE (
        ECHO\
    )
EXIT /B 0
