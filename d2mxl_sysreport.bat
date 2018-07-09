@ECHO OFF
REM Author: Ryan Paul
REM Date: 07/09/18
REM Version: 0.3
REM Usage: d2mxl_sysreport.bat
REM Description: Saves various D2 and OS settings report to a text file

SETLOCAL EnableDelayedExpansion
SETLOCAL EnableExtensions



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Report file
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Define output temp file ~
SET "output_file=%~n0.txt"

REM ~ Test for report text file permissions ~
TYPE NUL > "%output_file%"
IF EXIST "%output_file%" (
    SET "tmpfile_exists=TRUE"
) ELSE (
    CALL :log "Could not create temp file '%output_file%'^! Outputting to console..."
    CALL :log_nl
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Diablo II Install Path
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET "reg_diabloII=HKEY_CURRENT_USER\Software\Blizzard Entertainment\Diablo II"

REM ~ Section header ~
CALL :log "[Installation Path]"

REM ~ Check for registry key ~
REG QUERY "%reg_diabloII%" >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    FOR /F "tokens=2*" %%a IN ('REG QUERY "%reg_diabloII%" /v "InstallPath"') DO SET "path_d2_install=%%b"
    IF "!path_d2_install: =!" == "" (
        CALL :log "No Diablo II path found in registry^!"
    ) ELSE (
        CALL :log "'!path_d2_install!'"
    )
) ELSE (
    CALL :log "No 'InstallPath' registry key detected!"
)

CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Patch Checksum
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET "patchfile_MD5_113c=eb514785fc4666bd53d97ad69ff53d16"
SET "patchfile_path=%path_d2_install%\patch_d2.mpq"

REM ~ Section header ~
CALL :log "[patch_d2.mpq Checksum]"

REM ~ Check for MD5 hash util on system (Win7+) ~
CertUtil >nul 2>&1 && (
    REM ~ Exclude the verbose output text ~
    FOR /F "skip=1 delims=" %%a IN ('CertUtil /hashfile "%patchfile_path%" MD5 ^| findstr /v "CertUtil"') DO SET "patch_checksum=%%a"
    SET "patch_checksum=!patch_checksum: =!"
    
    REM ~ Check patch_d2.mpq version ~
    IF "!patch_checksum!" == "!patchfile_MD5_113c!" (
        SET "patch_result=v1.13c detected"
    ) ELSE (
        SET "patch_result=not v1.13c"
    )
    CALL :log "!patch_checksum! - !patch_result!"
) || (
    CALL :log "CertUtil.exe Unavailable"
)

CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM DEP Settings
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET "reg_dep_path=HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

REM ~ Section header ~
CALL :log "[DEP Settings]"

REM ~ Check if registry entries exists ~
FOR /F "delims=" %%a IN ('REG QUERY "%reg_dep_path%" ^| FIND /I "%path_d2_install%"') DO (
    SET "match=%%a"

    REM Strip extra spaces, split on reg entry type, assign to aray
    SET "match=!match:    =!"
    SET "match='!match:REG_SZ=', '!'"

    CALL :log "!match!"
)
IF "%match%"=="" CALL :log "No D2 registry key detected!"

CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Diablo II File Listing
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Section header ~
CALL :log "[D2 Root File List]"

REM ~ /B reduces output to only names, /O:E sorts by extension ~
FOR /F "delims=" %%a IN ('DIR /B /O:E "%path_d2_install%" ^| findstr /v /i "screenshot"') DO (
    REM Output info
    CALL :log "%%~a"
)

CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Show output temp file, if exists
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

IF DEFINED tmpfile_exists (
    NOTEPAD %output_file%
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
        ECHO %~1>>"%output_file%"
    ) ELSE (
        ECHO %~1
    )
EXIT /B 0


REM ~ Outputs a newline ~
:log_nl
    IF DEFINED tmpfile_exists (
        ECHO\>>"%output_file%"
    ) ELSE (
        ECHO\
    )
EXIT /B 0
