@ECHO OFF
SET BIN=%CD%\bin
SET FILENAME=keylog

IF EXIST %BIN%\%FILENAME%.exe. (
	START /D"%BIN%" %FILENAME%.exe
	GOTO FINISH
)

SET /P CHOISE=Compile it first. Launch make.cmd? (y/n)
IF %CHOISE%==y (
	START /D"%CD%" make.cmd
	GOTO FINISH
)

:FINISH
EXIT