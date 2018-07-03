@ECHO OFF
REM Author: Ryan Paul
REM Date: 05/11/18
REM Usage: ps_ping.bat [process name]
REM Description: Searches for matching process and shows list of network
REM  connections to ping. Will ask for process name if not given as argument.

SETLOCAL EnableDelayedExpansion
SETLOCAL EnableExtensions



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Get process name to search
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Parse command line argument ~
SET "psPattern=%~1"

REM ~ Prompt for input ~
:_psInput
IF NOT DEFINED psPattern (SET /P "psPattern=Search Process Name: ")

REM ~ Check user input ~
IF NOT DEFINED psPattern (GOTO :_psInput)
IF "%psPattern: =%" == "" (
    SET "psPattern=%psPattern: =%"
    GOTO :_psInput
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Scan for any matching processes
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Set Array variables ~
SET "matchCount=0"
SET "matches[1]=Exit"

REM ~ Scan matching processes ~
FOR /F "tokens=1,2" %%a in ('TASKLIST ^| FIND /I "%psPattern%"') DO (
    SET /A matchCount+=1
    SET "matches[!matchCount!]=%%~a %%~b"
)

REM ~ Exit if no process found ~
IF %matchCount% LEQ 0 (
    ECHO/
    ECHO No processes found^^!
    PAUSE
    GOTO :EOF
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Process selection
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Print menu for matching processes ~
ECHO/
ECHO Processes Found:
ECHO 0^) EXIT
FOR /L %%i in (1,1,%matchCount%) DO (
    FOR /F "tokens=1,2" %%a in ("!matches[%%i]!") DO ECHO %%i^) %%a
)
ECHO/

:_psMenu
REM ~ Default to only option otherwise Exit ~
IF %matchCount% EQU 1 (SET menuSelection=1) ELSE (SET menuSelection=0)

REM ~ Get process target from user ~
SET /P "menuSelection=Select Process (%menuSelection%): "

REM ~ Check user input ~
IF "%menuSelection: =%" == "" (GOTO :_psMenu)
if %menuSelection% EQU 0 (GOTO :EOF)
IF %menuSelection% GTR %matchCount% (GOTO :_psMenu)


REM ~ Set target process data ~
FOR /F "tokens=1,2" %%a in ("!matches[%menuSelection%]!") DO (
    SET "psName=%%a"
    SET "psID=%%b"
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Scan for process' active network connections
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Set Array variables ~
SET "matchCount=0"

REM ~ Scan available network connections for PID ~
FOR /F "tokens=3,*" %%i in ('NETSTAT /O /N ^| FIND /I "%psID%"') DO (
    SET /A matchCount+=1

    REM Strip extra spaces, replace colon with space, assign to array:
    SET "match=%%~i"
    SET "match=!match::= !"
    SET "matches[!matchCount!]=!match!"
)

REM ~ Exit if no network activity found for process ~
IF %matchCount% EQU 0 (
    ECHO/
    ECHO No network activity found for %psName%^^!
    PAUSE
    GOTO :EOF
)



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM IP selection
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

REM ~ Print menu for active network connections ~
ECHO/
ECHO %psName%'s Network Connections:
ECHO 0^) EXIT
FOR /L %%i in (1,1,%matchCount%) DO (
    FOR /F "tokens=1,2" %%a in ("!matches[%%i]!") DO ECHO %%i^) %%a:%%b
)
ECHO/

:_ipMenu
REM ~ Default to only option otherwise Exit ~
IF %matchCount% EQU 1 (SET menuSelection=1) ELSE (SET menuSelection=0)

REM ~ Get target IP from user ~
SET /P "menuSelection=Select IP (%menuSelection%): "

REM ~ Check user input ~
IF "%menuSelection: =%" == "" (GOTO :_ipMenu)
if %menuSelection% EQU 0 (GOTO :EOF)
IF %menuSelection% GTR %matchCount% (GOTO :_ipMenu)

REM ~ Set target IP of selected network connection ~
FOR /F "tokens=1,2" %%a in ("!matches[%menuSelection%]!") DO (SET "psIP=%%a")



REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
REM Ping target IP
REM ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

ECHO/
ECHO Long ping starting, press Ctrl+C to exit...
ping /t %psIP%
