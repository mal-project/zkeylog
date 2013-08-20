@ECHO OFF
REM -----------------------------------
SET BIN=%CD%\bin
SET FILENAME=keylog

REM -----------------------------------
SET DBGPATH=\Programs\Development\RCE\Debuggers\OllyDBG
FOR %%i IN (C X Y Z) DO (
	IF EXIST %%i:%DBGPATH%. SET DBGPATH=%%i:%DBGPATH%
)
SET DBGEXE=%DBGPATH%\asphx.exe

IF NOT EXIST %DBGEXE%. (
    ECHO NO DEBUGGER FOUND! CHECK PATH IN DEBUG.CMD
    ECHO DBG=%DBGEXE%
    GOTO ERROR
)


REM -----------------------------------
IF EXIST %BIN%\%FILENAME%.exe. (
	START /D"%DBGPATH%" %DBGEXE% "%BIN%\%FILENAME%.exe"
	GOTO FINISH
)

SET /P CHOISE=Compile it first. Launch make.cmd? (y/n)
IF %CHOISE%==y (
	START /D"%CD%" make.cmd
	GOTO FINISH
)
:ERROR
    PAUSE>nul

:FINISH
    EXIT