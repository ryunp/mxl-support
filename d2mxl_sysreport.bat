@ECHO OFF
REM Authors: Ryan Paul & Gavin Kehler
REM Date: 07/13/18
REM Version: 0.4.1
REM Usage: d2mxl_sysreport.bat
REM Description: Reports various D2 and OS settings to a text file

REM ~ Action List ~
REM 1. Install Path
REM 2. Patch Checksum
REM 3. DEP Settings
REM 4. Video Mode
REM 5. Overlay Detection
REM 6. File List


SETLOCAL EnableDelayedExpansion
SETLOCAL EnableExtensions



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Output file
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Define output temp file ~
SET "output_file=%~n0.txt"

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
    CALL :log "[Installation Path]"
    FOR /F "tokens=2*" %%a IN ('REG QUERY "%reg_diabloII%" /v "InstallPath"') DO SET "path_d2_install=%%b"
    IF "!path_d2_install!" == "" (
        CALL :log "Diablo II registry sub-key 'InstallPath' not found^^^!"
        GOTO :end
    ) ELSE (
        CALL :log "'!path_d2_install!'"
    )
) ELSE (
    CALL :log "Parent 'Diablo II' registry key not found^^^!"
    GOTO :end
)

CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM 2. Patch Checksum
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET "patchfile_path=%path_d2_install%\patch_d2.mpq"

REM ~ patch_d2.mpq version hash definitions ~
SET "patchfile_MD5_113c=eb514785fc4666bd53d97ad69ff53d16"

REM ~ Section header ~
CALL :log "[patch_d2.mpq Checksum]"

REM ~ Check for MD5 hash util on system (Win7+) ~
CertUtil >nul 2>&1 && (
    REM ~ Exclude the verbose output text ~
    FOR /F "skip=1 delims=" %%a IN ('CertUtil /hashfile "%patchfile_path%" MD5 ^| findstr /v "CertUtil"') DO SET "patch_checksum=%%a"
    SET "patch_checksum=!patch_checksum: =!"
    
    REM ~ Check against known hashes ~
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
REM 3. DEP Settings
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET "reg_dep_path=HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"

REM ~ Section header ~
CALL :log "[DEP Settings]"

REM ~ Check if registry entries exists ~
FOR /F "delims=" %%a IN ('REG QUERY "%reg_dep_path%" ^| FIND /I "%path_d2_install%"') DO (
    SET "match=%%a"

    REM ~ Strip extra spaces, split on reg entry type, assign to aray ~
    SET "match=!match:    =!"
    rem SET "match='!match:REG_SZ=', '!'"
    SET "match='!match:REG_SZ=', '!'"

    CALL :log "!match!"
)
IF "%match%" == "" CALL :log "No D2 registry key detected!"

CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM 4. Video Mode
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET "reg_d2_video=HKEY_CURRENT_USER\Software\Blizzard Entertainment\Diablo II\VideoConfig"

REM ~ Video setting definitions ~
SET "vid_directdraw=0x0"
SET "vid_direct3d=0x1"
SET "vid_glide=0x3"

REM ~ Default to unset ~
SET "display_mode=Not Set"

REM ~ Query registry ~
FOR /F "tokens=2*" %%a IN ('REG QUERY "%reg_d2_video%" ^/v "Render"') DO SET "video_setting=%%b"

REM ~ Map video mode code to human readable label ~
IF "%video_setting%" == "%vid_directdraw%" SET "display_mode=DirectDraw"
IF "%video_setting%" == "%vid_direct3d%" SET "display_mode=Direct3D"
IF "%video_setting%" == "%vid_glide%" SET "display_mode=Glide"

REM ~ Section header ~
CALL :log "[Display Mode]"

CALL :log "%display_mode%"
CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM 5. Overlay Detection
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SET "ol_array_len=0"

REM ~ Overlay definitions ~
SET "ps_steam=GameOverlayUI.exe"
SET "ps_nvidia=nvsphelper.exe"
SET "ps_ati=amddvr.exe"
SET "ps_gamebar=GamePanel.exe"
SET "ps_discord=Discord.exe"

REM ~ Search process list for known overlays ~
FOR /F "tokens=1*" %%a IN ('tasklist /nh') DO (
    SET "ps_name=%%a"
    
    IF "!ps_name!" == "%ps_steam%" CALL :ol_array_add "Steam"
    IF "!ps_name!" == "%ps_nvidia%" CALL :ol_array_add "Nvidia"
    IF "!ps_name!" == "%ps_ati%" CALL :ol_array_add "ATI"
    IF "!ps_name!" == "%ps_gamebar%" CALL :ol_array_add "GameBar"
)

REM ~ Special check for Discord ~
FOR /F "tokens=1,2" %%a IN ('wmic process where caption^="!ps_discord!" get commandline') DO (
    IF "%%b" == "--overlay-host" CALL :ol_array_add "Discord"
)

REM ~ Section header ~
CALL :log "[Gaming Overlay Detection]"

REM ~ Iterate over matched overlays ~
IF %ol_array_len% GTR 0 (
    FOR /L %%i IN (1,1,%ol_array_len%) DO CALL :log "!overlay_array[%%i]!"
) ELSE (
    CALL :log "No overlays detected!"
)

CALL :log_nl



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM 6. File List
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Section header ~
CALL :log "[D2 Root File List]"

REM ~ /B reduces output to only names, /O:E sorts by extension ~
FOR /F "delims=" %%a IN ('DIR /B /O:E "%path_d2_install%" ^| findstr /v /i "screenshot"') DO (
    REM Output info
    CALL :log "%%a"
)

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

EXIT /B 0



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Functions
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Function signature: log(str) ~
:log
    REM ~ Parens are needed to keep all characters escaped as strings ~
    IF DEFINED output_file_exists (
        (ECHO %~1)>>"%output_file%"
    ) ELSE (
        (ECHO %~1)
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


REM ~ for Overlay Detection's array.push shim ~
:ol_array_add
    SET /A ol_array_len += 1
    SET "overlay_array[%ol_array_len%]=%~1"
EXIT /B 0