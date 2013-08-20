.data
    szDisplay		DB "DISPLAY",0

.code


CaptureScreen   proc    lpszTitle:dword, lpLocalTime:dword

    pushad
    mov     ebx, offset szPattern
    
    .repeat
    
        invoke  InString, 1, lpszTitle, ebx
        .break .if eax != -1 && eax >= 1
        add     ebx, 7
        
    .until  dword ptr [ebx] == -1
    
    .if eax != -1 && eax >= 1
    
        invoke  GetLocalTime, lpLocalTime
        
        push    20
        push    offset szFileNameBuf
        push    offset hDateFormat_FN
        push    lpLocalTime
        push    0
        push    0
        call    GetDateFormat
        ;invoke  GetDateFormat, 0, 0, addr lpLocalTime, addr hDateFormat_FN, addr szFileNameBuf, 20
        invoke  GetTimeFormat, 0, 0, lpLocalTime, addr hTimeFormat_FN, addr lpTimeBuf_FN, 20
        
        invoke  szCatStr, addr szFileNameBuf, addr lpTimeBuf_FN
        invoke  _CaptureScreen, addr szFileNameBuf

    .endif   
    popad
    ret 
CaptureScreen   endp


;Returns TRUE if successful, FALSE otherwise
_CaptureScreen   proc    lpszFileName:dword

    LOCAL hDC				:HDC
    LOCAL hDCmem			:HDC
    LOCAL hCapFile			:HANDLE
    LOCAL dwBytes			:DWORD
    LOCAL bmpfileheader		:BITMAPFILEHEADER
    LOCAL bmpinfoheader		:BITMAPINFOHEADER
    LOCAL colors[256]		:RGBQUAD
    LOCAL bmpinfo			:BITMAPINFO
    LOCAL hBitmap			:HBITMAP
    LOCAL pBits				:DWORD
    LOCAL dwWidth			:DWORD
    LOCAL dwHeight			:DWORD
    LOCAL dwNumColors		:DWORD
    LOCAL dwBPP				:DWORD
    LOCAL dwColorSize		:DWORD
 
    ;Let's create a device context for the display
	Invoke CreateDC,Offset szDisplay,NULL,NULL,NULL
	OR EAX,EAX
	JZ Exit

	MOV hDC,EAX

	;Let's get the width, in pixels, of the screen
	Invoke GetDeviceCaps,hDC,HORZRES
	MOV dwWidth,EAX
	
	;Let's get the height, in pixels, of the screen
	Invoke GetDeviceCaps,hDC,VERTRES
	MOV dwHeight,EAX
	
	;Let's get the number of adjacent color bits for each pixel.
	Invoke GetDeviceCaps,hDC,BITSPIXEL
	MOV dwBPP,EAX
	.If (EAX<=8)
		
		;Let's get the number of entries in the device's color table, if the device has a color depth
		;of no more than 8 bits per pixel. (for devices with greater color depths, -1 is returned)
		Invoke GetDeviceCaps,hDC,NUMCOLORS
		MOV dwNumColors,EAX
		
	.Else
		
		MOV dwNumColors,0
		
	.EndIf
	
	;Let's create a memory device context (DC) compatible with the display 
	Invoke CreateCompatibleDC,hDC
	OR EAX,EAX
	JZ DeleteDisplayDC
	
	MOV hDCmem,EAX
	
	

	;Let's fill the BITMAPINFO structure
	;(dimensions and color information for a Windows device-independent bitmap)
	MOV bmpinfo.bmiHeader.biSize,SizeOf BITMAPINFOHEADER
	MOV EAX,dwWidth
	MOV bmpinfo.bmiHeader.biWidth,EAX
	MOV EAX,dwHeight
	MOV bmpinfo.bmiHeader.biHeight,EAX
	MOV bmpinfo.bmiHeader.biPlanes,1
	MOV AX,WORD PTR [dwBPP]
	MOV bmpinfo.bmiHeader.biBitCount,AX
	MOV bmpinfo.bmiHeader.biCompression,BI_RGB
	MOV bmpinfo.bmiHeader.biSizeImage,0
	MOV bmpinfo.bmiHeader.biXPelsPerMeter,0
	MOV bmpinfo.bmiHeader.biYPelsPerMeter,0
	MOV EAX,dwNumColors
	MOV bmpinfo.bmiHeader.biClrUsed,EAX
	MOV bmpinfo.bmiHeader.biClrImportant,EAX
	
	;Let's create a device-independent bitmap (DIB) 
	Invoke CreateDIBSection,hDC,ADDR bmpinfo,DIB_PAL_COLORS,ADDR pBits,NULL,0
	OR EAX,EAX
	JZ DeleteMemoryDC

	MOV hBitmap,EAX
	
	;********************************************************************
	;Following code block fills the memory pointed to by pBits
	
	;Let's select the bitmap into the memory device context
	Invoke SelectObject,hDCmem,hBitmap
	OR EAX,EAX
	JZ DeleteDCsAndBMP
	
	;Let's perform a bit-block transfer of the color data from
	;the display device context into the memory device context
	Invoke BitBlt,hDCmem,0,0,dwWidth,dwHeight,hDC,0,0,SRCCOPY
	OR EAX,EAX
	JZ DeleteDCsAndBMP
	;********************************************************************
	
	
	
	.If dwNumColors
		Invoke GetDIBColorTable,hDCmem,0,dwNumColors,ADDR colors
		MOV dwNumColors,EAX
	.EndIf
	
	
	;**********************************************************************
	;Note that hDC and hDCmem are not needed any more, only hBitmap.
	;We 'll delete the DC's at the end because it is convenient in our code
	;**********************************************************************
	
	
	
	;Let's fill the BITMAPINFOHEADER structure
	;(information about the dimensions and color format of a device-independent bitmap)
	; & the BITMAPFILEHEADER structure
	;(information about the type, size, and layout of a file that contains a device-independent bitmap
	MOV bmpfileheader.bfType,"MB"
	MOV EAX,dwNumColors
	XOR EDX,EDX
	MOV ECX,SizeOf RGBQUAD
	MUL ECX
	MOV dwColorSize,EAX
	MOV EAX,dwWidth
	XOR EDX,EDX
	MOV ECX,dwHeight
	MUL ECX
	XOR EDX,EDX
	MOV ECX,dwBPP
	MUL ECX
	SHR EAX,3
	ADD EAX,dwColorSize
	ADD EAX,SizeOf BITMAPFILEHEADER
	ADD EAX,SizeOf BITMAPINFOHEADER
	MOV bmpfileheader.bfSize,EAX
	MOV bmpfileheader.bfReserved1,0
	MOV bmpfileheader.bfReserved2,0
	MOV EAX,dwColorSize
	ADD EAX,SizeOf BITMAPFILEHEADER
	ADD EAX,SizeOf BITMAPINFOHEADER
	MOV bmpfileheader.bfOffBits,EAX
	MOV bmpinfoheader.biSize,SizeOf BITMAPINFOHEADER
	MOV EAX,dwWidth
	MOV bmpinfoheader.biWidth,EAX
	MOV EAX,dwHeight
	MOV bmpinfoheader.biHeight,EAX
	MOV bmpinfoheader.biPlanes,1
	MOV AX,WORD PTR [dwBPP]
	MOV bmpinfoheader.biBitCount,AX
	MOV bmpinfoheader.biCompression,BI_RGB
	MOV bmpinfoheader.biSizeImage,0
	MOV bmpinfoheader.biXPelsPerMeter,0
	MOV bmpinfoheader.biYPelsPerMeter,0
	MOV EAX,dwNumColors
	MOV bmpinfoheader.biClrUsed,EAX
	MOV bmpinfoheader.biClrImportant,0
	
	;Let's create the file on Hard disk
	Invoke CreateFile, lpszFileName,GENERIC_WRITE,0,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,NULL
	CMP EAX,INVALID_HANDLE_VALUE
	JZ DeleteDCsAndBMP

	MOV hCapFile,EAX
	
	;Write the bitmap file header
	Invoke WriteFile,hCapFile,ADDR bmpfileheader,SizeOf BITMAPFILEHEADER,ADDR dwBytes,NULL
	
	;Write the bitmap info header
	Invoke WriteFile,hCapFile,ADDR bmpinfoheader,SizeOf BITMAPINFOHEADER,ADDR dwBytes,NULL
	.If dwNumColors
		;If dwNumColors, write the colors info we have
		Invoke WriteFile,hCapFile,ADDR colors,dwColorSize,ADDR dwBytes,NULL
	.EndIf
	
	MOV EAX,dwWidth
	XOR EDX,EDX
	MOV ECX,dwHeight
	MUL ECX
	XOR EDX,EDX
	MOV ECX,dwBPP
	MUL ECX
	SHR EAX,3
	MOV dwColorSize,EAX
	
	;Write the device-independent bitmap's bit values
	Invoke WriteFile,hCapFile,pBits,dwColorSize,ADDR dwBytes,NULL
	
	Invoke CloseHandle, hCapFile
	
	;The operating system closes the handle to the memory pointed to by pBits
	;when we delete the device-independent bitmap by calling the DeleteObject function.
	PUSH hBitmap
	CALL DeleteObject
	
	PUSH hDCmem
	CALL DeleteDC
	
	
	PUSH hDC
	CALL DeleteDC
	;Returns TRUE if successful
	
	;If we are here then all is OK, ie screen captured
	
	RET

	
	
	
	
	
	;--------------------------------------------------------------------------------
	;We come here in case of error only, so we should return FALSE
	;-------------------------------------------------------------
	
	DeleteDCsAndBMP:
	
	;The operating system closes the handle to the memory pointed to by pBits
	;when we delete the device-independent bitmap by calling the DeleteObject function.
	PUSH hBitmap
	CALL DeleteObject
	
	DeleteMemoryDC:
	PUSH hDCmem
	CALL DeleteDC
	
	DeleteDisplayDC:
	
	PUSH hDC
	CALL DeleteDC
	
	
	XOR EAX,EAX	;Return FALSE
	
	Exit:
	RET
	
_CaptureScreen EndP