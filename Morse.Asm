; Created  Jun 4, 2005 by Nikolay Khabarov

.386

.model flat, stdcall

include windows.inc
include kernel32.inc
include user32.inc
include gdi32.inc
include comctl32.inc
include d3d9_all.inc
include dsound9.inc
include winmm.inc
include comdlg32.inc

includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib comctl32.lib
includelib dsound.lib
includelib comdlg32.lib

; transmitter
WndProc PROTO:DWORD, :DWORD, :DWORD, :DWORD
RichEditProc PROTO:DWORD, :DWORD, :DWORD, :DWORD
AboutProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
OptionProc PROTO :DWORD,:DWORD,:DWORD,:DWORD
IntToChar PROTO :DWORD, :DWORD
CharToInt PROTO :DWORD
SetVolFreq PROTO :DWORD, :DWORD
Play PROTO :DWORD
Decod PROTO :BYTE
SyncRead PROTO
SaveOpt PROTO
LoadOpt PROTO
InitDSound PROTO
StartReceiver PROTO
StartTransmitter PROTO

; reciever
InitDSoundCap PROTO
SearchLen PROTO
IntToChar PROTO :DWORD, :DWORD
PWndProc PROTO :DWORD, :DWORD, :DWORD, :DWORD
memcpy PROTO :DWORD, :DWORD, :DWORD
Encod PROTO
Analyse PROTO

diskr equ 44100

.data
;  reciever vars
dot dd 170
dash dd 170*3
pause dd 170*3/5
ddpause dd 170*3/5*2
freq dd 2000
vol dd 32767
freqfpu dd ?
hInstance dd ?
pDirectSound  dd  ?
dsbdesc_    DSBUFFERDESC  <?>
wfx_        WAVEFORMATEX  <?>
S_data      dd  ?
S_lengte    dd 2*16000*2*3
pDSSample   dd  ?
fputmp dd ?
buff dd ?
bend dd ?
bpos dd ?
redlln db "riched20.dll",0
richedstt dd 0
hwnd dd ?
thr dd ?
rect RECT <?>
oldrect RECT <?>
ic WORD ?
oldic WORD ?
hdc HDC ?
oldprc dd ?
lastupd dd 0
clig dd 00FFh
cfont dd 0
olig dd 00FFh
ofont dd 0
sfont dd 12
draw BYTE 0
fn db MAX_PATH dup (0)
ofiltr db "*.txt",0,"*.txt",0,"*.rtf",0,"*.rtf",0,"All files",0,"*",0,0
sfiltr db "*.txt",0,"*.txt",0,"All files",0,"*",0,0
hFile dd ?
filete dd ?
fsize dd ?
lpstr db 12 dup (0)
crv dd 16 dup(0FFFFFFh)
spkr db 0
dsnd db 1
initds db FALSE
reslic db "#500", 0
iconka db "#100", 0
peekctr db FALSE
sinc db TRUE
defext db "txt", 0
ahwnd dd ?
tsavetext db "Save transmitted text", 0
topentext db "Open text for transmission", 0
otpravleno dd 0
sptime dd ?

;  transmitter vars
pDSoundCapture LPDIRECTSOUNDCAPTURE ?
waveFmt WAVEFORMATEX  <?>
dscBufDesc DSCBUFFERDESC <>
pDSCBuffer LPDIRECTSOUNDCAPTUREBUFFER ?
lpDsNotify LPDIRECTSOUNDNOTIFY ?
PositionNotify DSBPOSITIONNOTIFY <>
pCapBuf PUCHAR ?
dwCapBufSize DWORD ?
IDDSN  dd 0b0210783h,089cdh,011d0h
IDDSN2 dw 0afh,008h,000h,0a0h,0c9h,025h,0cdh,016h
dlen DWORD 0
ppause DWORD 0
phwnd dd ?
rbuff dd 20 dup (0)
rnum dd 0
rdot dd 3000
rpause dd 3000
rpbuff dd 20 dup (0)
rnpause dd 0
pogr dd 0.5
wbuff dw 22050 dup(0)
cme dd 0
stre SETTEXTEX <>
cyrlat db 1 ; 0 - cyrillic, 1 - latin
autorec db TRUE
kp dd 1.5
k dd 6.0
recconf db FALSE
probel dd 5.0
prinyto dd 0
sttime dd ?
msecinmin dd 60000
pst db TRUE
uroven dd 10000
prun db FALSE
trun db TRUE
arun db FALSE
ppos dq 0000001000000010h
tpos dq 0000001000000010h
psize dq 0000010900000181h
tsize dq 0000010900000181h
psavetext db "Save transmitted text", 0
popentext db "Open text in receiver window", 0
poldproc dd ?

; options saving names
inif db "\settings.ini",0
sect db "OPTIONS",0
wfreq db "freq",0
wvol db "vol", 0
wdash db "dash", 0
wdot db "dot", 0
wpause db "pause", 0
wddpause db "ddpause",0
wfont db "font", 0
wlig db "lig",0
wsize db "size", 0
wspkr db "spkr", 0
wdsnd db "dsnd", 0
wsinc db "sinc", 0
wuroven db "uroven", 0
wcyrlat db "cyrlat", 0
wppos db "ppos", 0
wpsize db "psize", 0
wtpos db "tpos", 0
wtsize db "tsize", 0
wrun db "run", 0
wautorec db "autorec", 0
CurDir db MAX_PATH dup (0)
waiting db "Idle",0
reciving db "Receving", 0
t1 db "RichEdit", 0
t2 db "#4508", 0
.code

WinMain PROC
LOCAL temp:DWORD
invoke  GetCurrentDirectory, sizeof CurDir-sizeof inif, addr CurDir
lea EBX, CurDir
add EBX, EAX
mov ECX, sizeof inif
lea EAX, inif
re:
mov dl, [EAX]
mov [EBX],dl
inc EAX
inc EBX
loop re
invoke GetPrivateProfileStruct,addr sect,addr wppos,addr ppos,sizeof ppos, addr CurDir
invoke GetPrivateProfileStruct,addr sect,addr wpsize,addr psize,sizeof psize, addr CurDir

invoke GetPrivateProfileStruct,addr sect,addr wtpos,addr tpos,sizeof tpos, addr CurDir
invoke GetPrivateProfileStruct,addr sect,addr wtsize,addr tsize,sizeof tsize, addr CurDir

mov temp, 0
invoke GetPrivateProfileStruct,addr sect,addr wrun,addr temp,sizeof WORD, addr CurDir
.if temp!=0
mov ax, WORD PTR temp
mov prun, al
mov trun, ah
.endif


invoke GlobalAlloc,GMEM_ZEROINIT,1024*1024
mov buff, EAX
mov bpos, EAX
mov bend, EAX

invoke CreateThread,NULL,NULL,addr SyncRead, NULL,NULL,NULL

invoke InitCommonControls
invoke LoadLibrary,addr redlln
invoke GetModuleHandle,NULL
mov hInstance, EAX
.if prun==TRUE
	invoke CreateThread, NULL,NULL,addr StartReceiver,NULL,NULL,NULL
.endif

.if trun==TRUE
	.if prun==TRUE
		invoke Sleep,50
	.endif
invoke CreateThread, NULL,NULL,addr StartTransmitter,NULL,NULL,NULL
.endif
prdown:
.if prun==TRUE || trun ==TRUE
	invoke Sleep, 100
	jmp prdown
.endif
.if initds==TRUE
	dsound8  Release, pDSSample
	dsound8  Release, pDirectSound
.endif

invoke WritePrivateProfileStruct,addr sect,addr wppos,addr ppos,sizeof ppos, addr CurDir
invoke WritePrivateProfileStruct,addr sect,addr wpsize,addr psize,sizeof psize, addr CurDir

invoke WritePrivateProfileStruct,addr sect,addr wtpos,addr tpos,sizeof tpos, addr CurDir
invoke WritePrivateProfileStruct,addr sect,addr wtsize,addr tsize,sizeof tsize, addr CurDir

invoke ExitProcess,0
	ret
WinMain endp


WndProc PROC hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
LOCAL sett:SETTEXTEX
LOCAL gettt:GETTEXTEX 
LOCAL ofn:OPENFILENAME
LOCAL temp:DWORD
LOCAL settextex:SETTEXTEX
LOCAL temp2:DWORD
LOCAL srect:RECT
.if uMsg==WM_CLOSE
	mov EAX, bend
	mov bpos, EAX
	invoke EndDialog,hWin, NULL
.elseif uMsg==WM_SIZE
invoke GetDlgItem,hWin, 1001
mov temp, EAX
mov EBX, 0
mov ECX, 0
mov BX, WORD PTR lParam
mov CX, WORD PTR lParam+2
sub ECX, 20
invoke MoveWindow,temp, 0,20,EBX, ECX,FALSE	
	.if wParam==SIZE_MAXIMIZED
		mov DWORD PTR tpos, 0
		mov DWORD PTR tsize,0
		mov DWORD PTR tpos+4, 0
		mov DWORD PTR tsize+4,0
	.elseif wParam==SIZE_RESTORED
		invoke GetWindowRect,hWin, addr srect
		invoke SendMessage,hWin, WM_SIZING,NULL, addr srect
	.endif
.elseif uMsg==WM_INITDIALOG
	mov EAX, hWin
	mov hwnd, EAX
	invoke LoadOpt
	invoke SetFocus,hWin
	.if dsnd==TRUE
	invoke InitDSound
	.endif
	mov sett.flags,ST_DEFAULT
	mov sett.codepage,1251
	invoke SendDlgItemMessage,hWin,1001,EM_SETTEXTEX, addr sett, addr richedstt
	invoke GetDlgItem,hWin, 1001
	invoke SetWindowLong,EAX,GWL_WNDPROC,addr RichEditProc
	mov oldprc, EAX
	invoke LoadImage,hInstance,addr iconka,IMAGE_ICON,0,0,LR_DEFAULTCOLOR
	invoke SendMessage,hWin,WM_SETICON,ICON_BIG, EAX
	
	invoke GetTickCount
	mov sptime, EAX
	
	.if DWORD PTR tpos==0 && DWORD PTR tpos+4==0 && DWORD PTR tsize==0 && DWORD PTR tsize+4==0
		invoke ShowWindow,hWin, SW_MAXIMIZE
	.else
		invoke MoveWindow,hWin,DWORD PTR tpos, DWORD PTR tpos+4,DWORD PTR tsize,DWORD PTR tsize+4,TRUE
	.endif
.elseif uMsg==WM_COMMAND
	.if wParam==040003E9h && sinc==TRUE
		mov gettt.codepage,1251
		mov gettt.cb,1024*1024*10
		mov gettt.flags,GT_DEFAULT
		mov gettt.lpDefaultChar, NULL
		mov gettt.lpUsedDefChar, NULL
		invoke SendDlgItemMessage,hWin, 1001,EM_GETTEXTEX,addr gettt,buff
		add EAX, buff
		
		mov bend, EAX
		cmp bpos, EAX
		jbe okk
		mov bpos, EAX
		okk:
	.elseif wParam==1002
		invoke GetTickCount
		mov sptime, EAX
		mov otpravleno, 0
		mov gettt.codepage,1251
		mov gettt.cb,1024*1024*10
		mov gettt.flags,GT_DEFAULT
		mov gettt.lpDefaultChar, NULL
		mov gettt.lpUsedDefChar, NULL
		invoke SendDlgItemMessage,hWin, 1001,EM_GETTEXTEX,addr gettt,buff
		add EAX, buff
		
		mov bend, EAX
		cmp bpos, EAX
		jbe okk1
		mov bpos, EAX
		okk1:
		mov EAX, buff
	 	mov bpos, EAX
	 .elseif wParam==1003
	 	invoke EndDialog,hWin,0
	 .elseif wParam==1005
	 invoke RtlZeroMemory,addr ofn, sizeof OPENFILENAME
	 mov ofn.lStructSize, sizeof OPENFILENAME
	 mov ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY
	 lea EAX, fn
	 mov ofn.lpstrFile,EAX
	 mov ofn.nMaxFile, MAX_PATH 
	 lea EAX, ofiltr
	 mov ofn.lpstrFilter, EAX
	 lea EAX, topentext
	mov ofn.lpstrTitle, EAX
		 
	 invoke GetOpenFileName,addr ofn
	 cmp EAX, FALSE
	 je cancel
	 invoke CreateFile,addr fn,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
	 mov hFile, EAX
	 invoke GetFileSize,hFile, 0
	 mov fsize, EAX
	 inc fsize
	 invoke GlobalAlloc, GMEM_ZEROINIT,fsize
	 mov filete, EAX
	 invoke ReadFile,hFile,filete,fsize,addr temp,NULL
	 mov settextex.flags,ST_DEFAULT
	 mov settextex.codepage, 1251
	 invoke SendDlgItemMessage,hWin, 1001,EM_SETTEXTEX,addr settextex,filete
	 invoke GlobalFree,filete
	 invoke CloseHandle,hFile
	 mov EAX, buff
	 add EAX, fsize
	 mov bpos, EAX
	 cancel:
	 .elseif wParam==1004
	 	;mov EAX, bend
	 	;mov bpos, EAX
	 	.if arun==FALSE
	 		mov arun, TRUE
	 		invoke DialogBoxParam,hInstance,2000,NULL,addr AboutProc,NULL
	 		mov arun, FALSE
	 		.else
	 		invoke SetForegroundWindow,ahwnd
	 	.endif
	 .elseif wParam==1006
	 	mov EAX, bend
	 	mov bpos, EAX
	 	invoke DialogBoxParam,hInstance,3000,hWin,addr OptionProc,NULL
	 .elseif wParam==1007
	 	mov EAX, bend
	 	mov bpos, EAX
	 	invoke GetTickCount
	 	mov sptime, EAX
	 	mov otpravleno, 0
	 .elseif wParam==1008
	 	mov gettt.codepage,1251
		mov gettt.cb,1024*1024*10
		mov gettt.flags,GT_DEFAULT
		mov gettt.lpDefaultChar, NULL
		mov gettt.lpUsedDefChar, NULL
		invoke SendDlgItemMessage,hWin, 1001,EM_GETTEXTEX,addr gettt,buff
		add EAX, buff
		
		mov bend, EAX
		cmp bpos, EAX
		jbe okk2
		mov bpos, EAX
		okk2:
	 	invoke SendDlgItemMessage,hWin, 1001,EM_GETSEL,addr temp,NULL
	 	mov EAX, buff
	 	add EAX, temp
	 	mov bpos, EAX
	 .elseif wParam==1009
	 	mov gettt.codepage,1251
		mov gettt.cb,1024*1024*10
		mov gettt.flags,GT_DEFAULT
		mov gettt.lpDefaultChar, NULL
		mov gettt.lpUsedDefChar, NULL
		invoke SendDlgItemMessage,hWin, 1001,EM_GETTEXTEX,addr gettt,buff
		add EAX, buff
		
		mov bend, EAX
		cmp bpos, EAX
		jbe okk3
		mov bpos, EAX
		okk3:
	 	invoke SendDlgItemMessage,hWin, 1001,EM_GETSEL,addr temp,addr temp2
	 	mov EAX, buff
	 	add EAX, temp
	 	mov bpos, EAX
	 	mov EAX, buff
	 	add EAX, temp2
	 	mov bend, EAX
	 .elseif wParam==1010
		 invoke RtlZeroMemory,addr ofn, sizeof OPENFILENAME
		 mov ofn.lStructSize, sizeof OPENFILENAME
		 mov ofn.Flags,OFN_HIDEREADONLY or OFN_OVERWRITEPROMPT
		 lea EAX, defext
		 mov ofn.lpstrDefExt, EAX
		 lea EAX, fn
		 mov ofn.lpstrFile,EAX
		 mov ofn.nMaxFile, MAX_PATH 
		 lea EAX, sfiltr
		 mov ofn.lpstrFilter, EAX
		 lea EAX, tsavetext
		 mov ofn.lpstrTitle, EAX
		 
		 invoke GetSaveFileName,addr ofn
		 cmp EAX, FALSE
		 je cancel2
		 invoke CreateFile,addr fn,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
		 mov hFile, EAX
		 mov gettt.codepage,1251
		 mov gettt.cb,1024*1024*10
		 mov gettt.flags,GT_DEFAULT
		 mov gettt.lpDefaultChar, NULL
		 mov gettt.lpUsedDefChar, NULL
		 invoke SendDlgItemMessage,hWin, 1001,EM_GETTEXTEX,addr gettt,buff
		 mov temp, EAX
		 invoke WriteFile,hFile,buff, temp, addr temp, NULL
		 invoke CloseHandle,hFile
	 cancel2:
	 .elseif wParam==1013
	 	.if prun==FALSE
			invoke CreateThread, NULL,NULL,addr StartReceiver,NULL,NULL,NULL
		.else
			invoke SetForegroundWindow,phwnd
		.endif
	 .elseif wParam==1014
		invoke SendDlgItemMessage,hWin,1001,WM_SETTEXT, NULL,addr richedstt
	.elseif wParam==1502
		invoke SendMessage,hWin, WM_COMMAND,1002,NULL
	.elseif wParam==1503
		invoke SendMessage,hWin, WM_COMMAND,1007,NULL
	.endif
	.elseif uMsg==WM_PAINT
	.elseif uMsg==WM_MOVING || uMsg==WM_SIZING
		mov EAX, lParam
		mov EBX, DWORD PTR [EAX+0d]
		mov DWORD PTR tpos, EBX
		
		mov EBX, DWORD PTR [EAX+4d]
		mov DWORD PTR tpos+4, EBX
		
		mov EBX, DWORD PTR [EAX+8d]
		sub EBX, DWORD PTR [EAX+0d]
		mov DWORD PTR tsize, EBX
		
		mov EBX, DWORD PTR [EAX+12d]
		sub EBX, DWORD PTR [EAX+4d]
		mov DWORD PTR tsize+4, EBX
	.endif

	xor EAX, EAX
	ret
WndProc endp


RichEditProc PROC hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL cf:CHARFORMAT
LOCAL hre:DWORD
LOCAL poi:POINTL
LOCAL height:DWORD
LOCAL windth:DWORD
.if uMsg!=WM_KEYUP
	.if wParam!=VK_ESCAPE
		invoke CallWindowProc,oldprc,hWnd,uMsg,wParam,lParam
	.endif
.endif
.if uMsg==WM_PAINT
		cmp draw, FALSE
		je ex
		PUSHAD
				invoke GetDlgItem,hwnd, 1001
		mov hre,EAX
	 	invoke GetDC,hre
	 	mov hdc, EAX
	 	
	 	mov cf.cbSize, sizeof CHARFORMAT
	 	invoke SendDlgItemMessage,hwnd,1001, EM_GETCHARFORMAT,SCF_DEFAULT, addr cf
	 	mov EAX, cf.crTextColor
	 	mov cfont, EAX	 	
	 	mov EDX, 0
	 	mov EAX, cf.yHeight
	 	mov ECX, 12
	 	div ECX
	 	mov height, EAX	
	 	mov EDX, 0
	 	mov ECX, 2
	 	div ECX
	 	mov windth, EAX
	 	invoke CreateFont,height,windth,0,0,400,0,0,0,0,0,0,0,0,addr cf.szFaceName
	 	invoke SelectObject,hdc, EAX
	 	
	 	invoke GetClientRect,hre, ADDR rect
	 	mov EAX, bpos
	 	sub EAX, buff
	 	invoke SendDlgItemMessage,hwnd,1001,EM_POSFROMCHAR,addr poi,EAX
	 	mov EAX, poi.x
	 	mov rect.left,EAX
	 	mov EAX, poi.y
	 	mov rect.top,EAX
	 	mov EAX, bpos
	 	mov dl, [EAX]
	 	cmp dl, 0Dh
	 	je ex
	 	mov ic,0
	 	mov BYTE PTR ic,dl
	 	
		invoke SetTextColor,hdc, cfont
		invoke DrawText, hdc,ADDR oldic,-1, ADDR oldrect, DT_SINGLELINE
		
	 	invoke SetTextColor,hdc, clig
		invoke DrawText, hdc,ADDR ic,-1, ADDR rect, DT_SINGLELINE
		mov EAX, poi.x
	 	mov oldrect.left,EAX
	 	mov EAX, poi.y
	 	mov oldrect.top,EAX
	 	mov EAX, rect.right
	 	mov oldrect.right,EAX
	 	mov EAX, rect.bottom
	 	mov oldrect.bottom,EAX
	 	mov ax, ic
	 	mov oldic,ax
		POPAD
		ex:
.elseif uMsg==WM_KEYDOWN
	.if dsnd==TRUE && wParam==VK_CONTROL && peekctr==FALSE
		dsbuffer8  SetCurrentPosition, pDSSample, 0
   		dsbuffer8  Play, pDSSample, 0, 0, DSBPLAY_LOOPING
   		mov peekctr, TRUE
   	.elseif wParam==VK_F1
   		invoke SendMessage,hwnd,WM_COMMAND,1004,NULL
   	.elseif wParam==VK_F2
   		invoke SendMessage,hwnd,WM_COMMAND,1006,NULL
   	.elseif wParam==VK_F3
   		invoke SendMessage,hwnd,WM_COMMAND,1005,NULL
    .elseif wParam==VK_F4
   		invoke SendMessage,hwnd,WM_COMMAND,1010,NULL
   	.elseif wParam==VK_F5
   		invoke SendMessage,hwnd,WM_COMMAND,1002,NULL
   	.elseif wParam==VK_F6
   		invoke SendMessage,hwnd,WM_COMMAND,1008, NULL
   	.elseif wParam==VK_F7
   		invoke SendMessage,hwnd,WM_COMMAND,1009, NULL
   	.elseif wParam==VK_F8
   		invoke SendMessage,hwnd,WM_COMMAND,1007,NULL
   	.elseif wParam==VK_F12
   		invoke SendMessage,hwnd,WM_COMMAND,1013,NULL
	.endif
.elseif uMsg==WM_KEYUP
	.if dsnd==TRUE && wParam==VK_CONTROL && peekctr==TRUE
		 dsbuffer8  Stop, pDSSample
		 mov peekctr, FALSE
	.endif
.elseif uMsg==WM_KILLFOCUS
	.if peekctr==TRUE
		dsbuffer8  Stop, pDSSample
		mov peekctr, FALSE
	.endif
.endif
	ret
RichEditProc endp


PRichEditProc PROC hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL cf:CHARFORMAT
LOCAL hre:DWORD
LOCAL poi:POINTL
LOCAL height:DWORD
LOCAL windth:DWORD
.if uMsg!=WM_KEYUP
	.if wParam!=VK_ESCAPE
		invoke CallWindowProc,poldproc,hWnd,uMsg,wParam,lParam
	.endif
.endif
	.if uMsg==WM_KEYDOWN
		.if WORD PTR wParam==VK_F1
			invoke SendMessage,phwnd,WM_COMMAND,4509,NULL
		.elseif WORD PTR wParam==VK_F2
			invoke SendMessage,phwnd,WM_COMMAND,4511,NULL
		.elseif WORD PTR wParam==VK_F3
			invoke SendMessage,phwnd,WM_COMMAND,4502,NULL
		.elseif WORD PTR wParam==VK_F4
			invoke SendMessage,phwnd,WM_COMMAND,4503,NULL
		.elseif WORD PTR wParam==VK_F5
			invoke SendMessage,phwnd,WM_COMMAND,4506,NULL
		.elseif WORD PTR wParam==VK_F7
			invoke SendMessage,phwnd,WM_COMMAND,4508, NULL
		.elseif WORD PTR wParam==VK_F8
			invoke SendMessage,phwnd,WM_COMMAND,4507,NULL
		.elseif WORD PTR wParam==VK_F12
			invoke SendMessage,phwnd,WM_COMMAND,4510,NULL
		.endif
	.endif
	ret
PRichEditProc endp


SetVolFreq PROC sVol:DWORD, sFreq:DWORD
	dsbuffer8  Lock1, pDSSample, 0, S_lengte, ADDR S_data, ADDR S_lengte, NULL, 0, 0                   
	fldpi
	mov fputmp, 2
	fild fputmp
	fmul
	fild sFreq
	fmul
	fild S_lengte
	fdiv
	fst freqfpu
	mov ECX, S_lengte
	mov EBX, S_data
wrbeep:
	fld freqfpu
	mov fputmp, ECX
	fild fputmp
	mov fputmp, 3
	fild fputmp
	fmul
	fmul
	fcos
	mov EAX, sVol
	mov fputmp, EAX
	fild fputmp
	fmul
	fistp fputmp
	mov EDX, fputmp
	mov WORD PTR [ECX+EBX-2], dx
	dec ECX
	loop wrbeep
	dsbuffer8  Unlock, pDSSample, S_data, S_lengte, NULL, 0
	ret
SetVolFreq endp


Play PROC time:DWORD
	.if dsnd==TRUE
		dsbuffer8  SetCurrentPosition, pDSSample, 0
		dsbuffer8  Play, pDSSample, 0, 0, DSBPLAY_LOOPING
	.endif
    	.if spkr==FALSE
    		.if dsnd==TRUE
    			invoke Sleep, time
		.endif
 	 .else
    		invoke Beep,freq,time
	 .endif
	.if dsnd==TRUE
		dsbuffer8  Stop, pDSSample
	.endif   
	ret
Play endp


Decod PROC symb:BYTE
	LOCAL temp:DWORD
	LOCAL string:TBYTE
	inc otpravleno
	invoke GetTickCount
	sub EAX, sptime
	mov temp, EAX
	fild temp
	fild msecinmin
	fdiv
	fstp temp
	fild otpravleno
	fld temp
	fdiv
	fistp temp
	invoke IntToChar,temp,addr string
	invoke SendDlgItemMessage,hwnd,1505,WM_SETTEXT,NULL,addr string
	.if symb=='1' ; . - - - -
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='2'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='3'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='4'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='5'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='6'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='7'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='8'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='9'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='0'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='A' || symb=='a' || symb=='À' || symb=='à'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='B' || symb=='b' || symb=='Á' || symb=='á'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='C' || symb=='c' || symb=='Ö' || symb=='ö'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='D' || symb=='d' || symb=='Ä' || symb=='ä'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='E' || symb=='e' || symb=='Å' || symb=='å' || symb=='¨' || symb=='¸'
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='F' || symb=='f' || symb=='Ô' || symb=='ô'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='G' || symb=='g' || symb=='Ã' || symb=='ã'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='H' || symb=='h' || symb=='Õ' || symb=='õ'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='I' || symb=='i' || symb=='È' || symb=='è'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='J' || symb=='j' || symb=='É' || symb=='é'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='K' || symb=='k' || symb=='Ê' || symb=='ê'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='L' || symb=='l' || symb=='Ë' || symb=='ë'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='M' || symb=='m' || symb=='Ì' || symb=='ì'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='N' || symb=='n' || symb=='Í' || symb=='í'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='O' || symb=='o' || symb=='Î' || symb=='î'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='P' || symb=='p' || symb=='Ï' || symb=='ï'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='Q' || symb=='q' || symb=='Ù' || symb=='ù'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='R' || symb=='r' || symb=='Ð' || symb=='ð'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='S' || symb=='s' || symb=='Ñ' || symb=='ñ'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='T' || symb=='t' || symb=='Ò' || symb=='ò'
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='U' || symb=='u' || symb=='Ó' || symb=='ó'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='V' || symb=='v' || symb=='Æ' || symb=='æ'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='W' || symb=='w' || symb=='Â' || symb=='â'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='X' || symb=='x' || symb=='Ü' || symb=='ü' || symb=='Ú' || symb=='ú'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='Y' || symb=='y' || symb=='Û' || symb=='û'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='Z' || symb=='z' || symb=='Ç' || symb=='ç'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='×' || symb=='÷'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='Ø' || symb=='ø'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='Þ' || symb=='þ'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='ß' || symb=='ÿ'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='Ý' || symb=='ý'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb==','
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='.'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb==';'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb==':'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='?'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='#' || symb=='¹'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='"'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='`'
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb=='(' || symb==')'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='!'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='-'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
	.elseif symb=='/'
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
		invoke Play,dash ;-
		invoke Sleep,pause
		invoke Play,dot ;.
		invoke Sleep,pause
	.elseif symb==' '
		invoke Sleep,pause
		invoke Sleep,pause
	.endif	
	
	ret
Decod endp


SyncRead PROC
LOCAL cf:CHARFORMAT
LOCAL hre:DWORD
LOCAL poi:POINTL
LOCAL height:DWORD
LOCAL windth:DWORD
okk:
	mov EAX, bpos
	cmp EAX, bend 
	jae no
	push EAX
	invoke GetDlgItem,hwnd, 1001
	mov hre,EAX
 	invoke GetDC,hre
 	mov hdc, EAX
	 	
 	mov cf.cbSize, sizeof CHARFORMAT
 	invoke SendDlgItemMessage,hwnd,1001, EM_GETCHARFORMAT,SCF_DEFAULT, addr cf
 	mov EAX, cf.crTextColor
 	mov cfont, EAX	 	
 	mov EDX, 0
 	mov EAX, cf.yHeight
 	mov ECX, 12
 	div ECX
 	mov height, EAX	
 	mov EDX, 0
 	mov ECX, 2
 	div ECX
 	mov windth, EAX
 	invoke CreateFont,height,windth,0,0,400,0,0,0,0,0,0,0,0,addr cf.szFaceName
 	invoke SelectObject,hdc, EAX
	 	
 	invoke GetClientRect,hre, ADDR rect
 	mov EAX, bpos
 	sub EAX, buff
 	invoke SendDlgItemMessage,hwnd,1001,EM_POSFROMCHAR,addr poi,EAX
 	mov EAX, poi.x
 	mov rect.left,EAX
 	mov EAX, poi.y
 	mov rect.top,EAX
 	mov EAX, bpos
 	mov dl, [EAX]
 	cmp dl, 0Dh
 	je ex
 	mov ic,0
 	mov BYTE PTR ic,dl
 	invoke SetTextColor,hdc, cfont
	invoke DrawText, hdc,ADDR oldic,-1, ADDR oldrect, DT_SINGLELINE
		
 	invoke SetTextColor,hdc, clig
	invoke DrawText, hdc,ADDR ic,-1, ADDR rect, DT_SINGLELINE
	mov EAX, poi.x
 	mov oldrect.left,EAX
 	mov EAX, poi.y
 	mov oldrect.top,EAX
 	mov EAX, rect.right
 	mov oldrect.right,EAX
 	mov EAX, rect.bottom
 	mov oldrect.bottom,EAX
 	mov ax, ic
 	mov oldic,ax
	mov draw, TRUE
	pop EAX
ex:
	mov dl, [EAX]
	cmp dl, 0Dh
	je nou
	cmp dl, 0Ah
	je nou
	invoke Decod, dl
	invoke Sleep,ddpause
nou:
	inc bpos
	jmp okk
no:
	mov draw, FALSE
	invoke Sleep,10
	jmp okk

	ret
SyncRead endp


AboutProc PROC hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
LOCAL settext:SETTEXTEX
	.if uMsg==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.elseif uMsg==WM_INITDIALOG
		push hWin
		pop ahwnd
		mov settext.flags, ST_DEFAULT
		mov settext.codepage,1251
		invoke FindResource,NULL,addr reslic,RT_RCDATA
		invoke LoadResource,NULL, EAX
		invoke SendDlgItemMessage,hWin, 2003,EM_SETTEXTEX, addr settext,EAX
		invoke SendDlgItemMessage,hWin, 2003,EM_SETREADONLY, TRUE, NULL
		invoke SendDlgItemMessage,hWin, 2003,EM_AUTOURLDETECT, TRUE, NULL
		invoke LoadImage,hInstance,addr iconka,IMAGE_ICON,0,0,LR_DEFAULTCOLOR
		invoke SendMessage,hWin,WM_SETICON,ICON_BIG, EAX
		invoke SetFocus,hWin
	.elseif uMsg==WM_COMMAND
		.if wParam==2001
			invoke EndDialog,hWin,0		
		.endif
	.endif
	xor EAX, EAX
	ret
AboutProc endp


OptionProc PROC hWin:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
LOCAL cc:CHOOSECOLOR
LOCAL temp:DWORD
LOCAL settext:SETTEXTEX
LOCAL hDC:HDC
LOCAL ps:PAINTSTRUCT
LOCAL charfrm:CHARFORMAT2
LOCAL temp2:DWORD
	.if uMsg==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.elseif uMsg==WM_PAINT
		invoke BeginPaint,hWin,addr ps
		mov hDC, EAX
		invoke CreatePen,PS_SOLID,0,ofont
		invoke SelectObject,hDC, EAX
		mov ECX, 158
re:
		inc ECX
		push ECX
		invoke MoveToEx,hDC, 355,ECX,NULL
		pop ECX
		push ECX
		invoke LineTo,hDC, 355+80,ECX
		pop ECX
		cmp ECX, 169
		jb re

		invoke CreatePen,PS_SOLID,0,olig
		invoke SelectObject,hDC, EAX
		mov ECX, 181
re2:
		inc ECX
		push ECX
		invoke MoveToEx,hDC, 100,ECX,NULL
		pop ECX
		push ECX
		invoke LineTo,hDC, 180,ECX
		pop ECX
		cmp ECX, 192
		jb re2
		invoke EndPaint,hWin, addr ps
	
	.elseif uMsg==WM_INITDIALOG
		mov EAX, cfont
		mov ofont, EAX
		mov EAX, clig
		mov olig, EAX
		invoke SetFocus,hWin
		invoke SendDlgItemMessage,hWin,3013,SBM_SETRANGE,0,7000
		invoke SendDlgItemMessage,hWin,3015,SBM_SETRANGE,0,32767
		invoke SendDlgItemMessage,hWin,3017,SBM_SETRANGE,0,2000
		invoke SendDlgItemMessage,hWin,3019,SBM_SETRANGE,0,2000
		invoke SendDlgItemMessage,hWin,3021,SBM_SETRANGE,0,2000
		invoke SendDlgItemMessage,hWin,3025,SBM_SETRANGE,0,24
		invoke SendDlgItemMessage,hWin,3028,SBM_SETRANGE,0,100
		invoke SendDlgItemMessage,hWin,3030,SBM_SETRANGE,0,2000
		invoke SendDlgItemMessage,hWin,3036,SBM_SETRANGE,0,32767
		
		invoke SendDlgItemMessage,hWin, 3013,SBM_SETPOS,freq,TRUE
		invoke SendDlgItemMessage,hWin, 3015,SBM_SETPOS,vol,TRUE
		invoke SendDlgItemMessage,hWin, 3017,SBM_SETPOS,dash,TRUE
		invoke SendDlgItemMessage,hWin, 3019,SBM_SETPOS,dot,TRUE
		invoke SendDlgItemMessage,hWin, 3021,SBM_SETPOS,pause,TRUE
		invoke SendDlgItemMessage,hWin, 3025,SBM_SETPOS,sfont,TRUE
		invoke SendDlgItemMessage,hWin, 3036,SBM_SETPOS,uroven,TRUE 
		mov EDX, 0
		mov EAX, dash
		mov ECX, 15
		div ECX
		dec EAX
		invoke SendDlgItemMessage,hWin, 3028,SBM_SETPOS,EAX,TRUE
		invoke SendDlgItemMessage,hWin, 3030,SBM_SETPOS,ddpause,TRUE
		
		mov settext.flags, ST_DEFAULT
		mov settext.codepage,1251
		invoke SendDlgItemMessage,hWin,3013,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX,addr lpstr
		invoke SendDlgItemMessage,hWin,3012,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3015,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX,addr lpstr
		invoke SendDlgItemMessage,hWin,3014,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3017,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX,addr lpstr
		invoke SendDlgItemMessage,hWin,3016,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3019,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX,addr lpstr
		invoke SendDlgItemMessage,hWin,3018,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3021,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX,addr lpstr
		invoke SendDlgItemMessage,hWin,3020,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3025,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX,addr lpstr
		invoke SendDlgItemMessage,hWin,3024,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3030,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX,addr lpstr
		invoke SendDlgItemMessage,hWin,3029,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3036,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX,addr lpstr
		invoke SendDlgItemMessage,hWin,3035,WM_SETTEXT,addr settext,addr lpstr
		  
		mov EAX, 0
		mov al, spkr
		invoke SendDlgItemMessage,hWin,3008,BM_SETCHECK, EAX,NULL
		mov EAX, 0
		mov al, dsnd
		invoke SendDlgItemMessage,hWin,3009,BM_SETCHECK, EAX, NULL
		mov EAX, 0
		mov al, sinc
		invoke SendDlgItemMessage,hWin,3031,BM_SETCHECK, EAX, NULL
		mov EAX, 0
		mov al, cyrlat
		push EAX
		.if EAX>0
			mov EAX, 0
		.else
			mov EAX, 1
		.endif
		invoke SendDlgItemMessage,hWin,3038,BM_SETCHECK, EAX, NULL
		pop EAX
		invoke SendDlgItemMessage,hWin,3039,BM_SETCHECK, EAX, NULL
		
		invoke GetPrivateProfileStruct,addr sect,addr wrun,addr temp,sizeof WORD, addr CurDir
		mov EAX, 0
		mov al, BYTE PTR temp
		invoke SendDlgItemMessage,hWin,3042,BM_SETCHECK, EAX, NULL
		mov EAX, 0
		mov al, BYTE PTR temp+1
		invoke SendDlgItemMessage,hWin,3043,BM_SETCHECK, EAX, NULL
		mov EAX, 0
		mov al, autorec
		invoke SendDlgItemMessage,hWin,3044,BM_SETCHECK, EAX, NULL
		
		invoke LoadImage,hInstance,addr iconka,IMAGE_ICON,0,0,LR_DEFAULTCOLOR
		invoke SendMessage,hWin,WM_SETICON,ICON_BIG, EAX
	.elseif uMsg==WM_COMMAND
		mov EAX, wParam
		and EAX, 04000000h
		.if EAX==04000000h
			mov EAX, 0
			mov AX, WORD PTR wParam
			mov wParam, EAX
			lea EBX, lpstr
			mov DWORD PTR [EBX], sizeof lpstr
			invoke SendDlgItemMessage,hWin, wParam,EM_GETLINE,NULL,addr lpstr
			.if DWORD PTR lpstr!=0
			invoke CharToInt,addr lpstr
			inc wParam
			invoke SendDlgItemMessage,hWin, wParam,SBM_SETPOS,EAX,TRUE	
			.endif
		.elseif wParam==3011
			invoke EndDialog,hWin,0	
		.elseif wParam==3026
			mov dl, dsnd
			mov dh, spkr
			push edx
			invoke SendDlgItemMessage,hWin,3008,BM_GETCHECK, NULL, NULL
			mov spkr, al
			invoke SendDlgItemMessage,hWin,3009,BM_GETCHECK, NULL, NULL
			mov dsnd, al
			
			invoke SendDlgItemMessage,hWin,3013,SBM_GETPOS,NULL, NULL
			mov EBX, EAX
			push EBX
			invoke SendDlgItemMessage,hWin,3015,SBM_GETPOS,NULL, NULL
			pop EBX
			.if dsnd==TRUE
				.if initds==FALSE
					push EAX
					push EBX
					invoke InitDSound
					pop EBX
					pop EAX
				.endif
				invoke SetVolFreq,EAX, EBX
			.endif
			invoke SendDlgItemMessage,hWin,3017,SBM_GETPOS,NULL, NULL
			invoke Play,EAX
			invoke SendDlgItemMessage,hWin,3021,SBM_GETPOS,NULL, NULL
			invoke Sleep,EAX
			invoke SendDlgItemMessage,hWin,3019,SBM_GETPOS,NULL, NULL
			invoke Play,EAX
			invoke SendDlgItemMessage,hWin,3030,SBM_GETPOS,NULL, NULL
			invoke Sleep,EAX
			invoke SendDlgItemMessage,hWin,3017,SBM_GETPOS,NULL, NULL
			invoke Play,EAX
			invoke SendDlgItemMessage,hWin,3021,SBM_GETPOS,NULL, NULL
			invoke Sleep,EAX
			invoke SendDlgItemMessage,hWin,3019,SBM_GETPOS,NULL, NULL
			invoke Play,EAX
			
			.if dsnd==TRUE
				invoke SetVolFreq,vol,freq
			.endif
			pop edx
			mov dsnd, dl
			mov spkr, dh
		.elseif wParam==3010 ; OK button
			invoke SendDlgItemMessage,hWin,3013,SBM_GETPOS,NULL, NULL
			mov freq, EAX
			invoke SendDlgItemMessage,hWin,3015,SBM_GETPOS,NULL, NULL
			mov vol, EAX
			.if dsnd==TRUE && trun==TRUE
				invoke SetVolFreq,vol, freq
			.endif
			invoke SendDlgItemMessage,hWin,3017,SBM_GETPOS,NULL, NULL
			mov dash,EAX
			invoke SendDlgItemMessage,hWin,3021,SBM_GETPOS,NULL, NULL
			mov pause,EAX
			invoke SendDlgItemMessage,hWin,3019,SBM_GETPOS,NULL, NULL
			mov dot,EAX
			invoke SendDlgItemMessage,hWin,3030,SBM_GETPOS,NULL, NULL
			mov ddpause,EAX
			invoke SendDlgItemMessage,hWin,3036,SBM_GETPOS,NULL, NULL
			mov uroven,EAX
			
			invoke SendDlgItemMessage,hWin,3025,SBM_GETPOS,NULL, NULL
			mov charfrm.cbSize, sizeof CHARFORMAT2
			mov charfrm.dwMask, CFM_COLOR or CFM_SIZE
			mov ECX, 20
			mov sfont, EAX
			mul ECX
			mov charfrm.yHeight,EAX
			mov EAX, ofont
			mov charfrm.crTextColor,EAX
			mov cfont, EAX
			invoke SendDlgItemMessage,hwnd,1001,EM_SETCHARFORMAT,SCF_ALL, addr charfrm
			invoke SendDlgItemMessage,phwnd,4008,EM_SETCHARFORMAT,SCF_ALL, addr charfrm
			
			mov EAX, olig
			mov clig, EAX
			invoke SendDlgItemMessage,hWin,3008,BM_GETCHECK, NULL, NULL
			mov spkr, al
			invoke SendDlgItemMessage,hWin,3009,BM_GETCHECK, NULL, NULL
			mov dsnd, al
			invoke SendDlgItemMessage,hWin,3044,BM_GETCHECK, NULL, NULL
			mov autorec, al
			invoke SendDlgItemMessage,hWin,3039,BM_GETCHECK, NULL, NULL
			.if al==FALSE
			mov cyrlat, 0
			.else
			mov cyrlat, 1
			.endif
			.if al==TRUE && initds==FALSE
				invoke InitDSound
			.endif
			invoke SendDlgItemMessage,hWin,3031,BM_GETCHECK, NULL, NULL
			mov sinc, al
			invoke SaveOpt
			invoke SendDlgItemMessage,hWin,3042,BM_GETCHECK, NULL, NULL
			mov BYTE PTR temp, al
			invoke SendDlgItemMessage,hWin,3043,BM_GETCHECK, NULL, NULL
			mov BYTE PTR temp+1, al
			invoke WritePrivateProfileStruct,addr sect,addr wrun,addr temp,sizeof WORD, addr CurDir
			
			invoke EndDialog,hWin,0
		.elseif wParam==3022
			mov cc.lStructSize, sizeof CHOOSECOLOR
			mov cc.Flags, CC_ANYCOLOR or CC_RGBINIT
			mov EAX, hWin
			mov cc.hwndOwner,EAX
			mov EAX, ofont
			mov cc.rgbResult, EAX
			lea EAX, crv
			mov cc.lpCustColors,EAX
			invoke ChooseColor,addr cc
			.if EAX==TRUE
				mov EAX, cc.rgbResult
				mov ofont, EAX
				invoke InvalidateRect,hWin,NULL,TRUE
			.endif
		.elseif wParam==3023
			mov cc.lStructSize, sizeof CHOOSECOLOR
			mov cc.Flags, CC_ANYCOLOR or CC_RGBINIT
			mov EAX, hWin
			mov cc.hwndOwner, EAX
			mov EAX, olig
			mov cc.rgbResult, EAX
			lea EAX, crv
			mov cc.lpCustColors,EAX
			invoke ChooseColor,addr cc
			.if EAX==TRUE
				mov EAX, cc.rgbResult
				mov olig, EAX
				invoke InvalidateRect,hWin,NULL,TRUE
			.endif
		.elseif wParam==3027 ; default
			invoke SendDlgItemMessage,hWin, 3013,SBM_SETPOS,2000,TRUE
			invoke SendDlgItemMessage,hWin, 3015,SBM_SETPOS,32767,TRUE
			invoke SendDlgItemMessage,hWin, 3017,SBM_SETPOS,510,TRUE
			invoke SendDlgItemMessage,hWin, 3019,SBM_SETPOS,170,TRUE
			invoke SendDlgItemMessage,hWin, 3021,SBM_SETPOS,102,TRUE
			invoke SendDlgItemMessage,hWin, 3025,SBM_SETPOS,12,TRUE
			invoke SendDlgItemMessage,hWin, 3030,SBM_SETPOS,204,TRUE
			invoke SendDlgItemMessage,hWin, 3028,SBM_SETPOS,33,TRUE
			invoke SendDlgItemMessage,hWin, 3036,SBM_SETPOS,10000,TRUE
			
			mov settext.flags, ST_DEFAULT
			mov settext.codepage,1251
			invoke SendDlgItemMessage,hWin,3013,SBM_GETPOS,NULL, NULL
			invoke IntToChar,EAX,addr lpstr
			invoke SendDlgItemMessage,hWin,3012,WM_SETTEXT,addr settext,addr lpstr
			invoke SendDlgItemMessage,hWin,3015,SBM_GETPOS,NULL, NULL
			invoke IntToChar,EAX,addr lpstr
			invoke SendDlgItemMessage,hWin,3014,WM_SETTEXT,addr settext,addr lpstr
			invoke SendDlgItemMessage,hWin,3017,SBM_GETPOS,NULL, NULL
			invoke IntToChar,EAX,addr lpstr
			invoke SendDlgItemMessage,hWin,3016,WM_SETTEXT,addr settext,addr lpstr
			invoke SendDlgItemMessage,hWin,3019,SBM_GETPOS,NULL, NULL
			invoke IntToChar,EAX,addr lpstr
			invoke SendDlgItemMessage,hWin,3018,WM_SETTEXT,addr settext,addr lpstr
			invoke SendDlgItemMessage,hWin,3021,SBM_GETPOS,NULL, NULL
			invoke IntToChar,EAX,addr lpstr
			invoke SendDlgItemMessage,hWin,3020,WM_SETTEXT,addr settext,addr lpstr
			invoke SendDlgItemMessage,hWin,3025,SBM_GETPOS,NULL, NULL
			invoke IntToChar,EAX,addr lpstr
			invoke SendDlgItemMessage,hWin,3024,WM_SETTEXT,addr settext,addr lpstr
			invoke SendDlgItemMessage,hWin,3030,SBM_GETPOS,NULL, NULL
			invoke IntToChar,EAX,addr lpstr
			invoke SendDlgItemMessage,hWin,3029,WM_SETTEXT,addr settext,addr lpstr
			invoke SendDlgItemMessage,hWin,3036,SBM_GETPOS,NULL, NULL
			invoke IntToChar,EAX,addr lpstr
			invoke SendDlgItemMessage,hWin,3035,WM_SETTEXT,addr settext,addr lpstr
			
			mov EAX, 0
			invoke SendDlgItemMessage,hWin,3008,BM_SETCHECK, EAX,NULL
			mov EAX, 1
			invoke SendDlgItemMessage,hWin,3009,BM_SETCHECK, EAX, NULL
			mov EAX, 1
			invoke SendDlgItemMessage,hWin,3031,BM_SETCHECK, EAX, NULL
			mov EAX, 1
			invoke SendDlgItemMessage,hWin,3038,BM_SETCHECK, EAX, NULL
			mov EAX, 0
			invoke SendDlgItemMessage,hWin,3039,BM_SETCHECK, EAX, NULL
			mov EAX, 0
			invoke SendDlgItemMessage,hWin,3042,BM_SETCHECK, EAX, NULL
			mov EAX, 1
			invoke SendDlgItemMessage,hWin,3043,BM_SETCHECK, EAX, NULL
			mov EAX, 1
			invoke SendDlgItemMessage,hWin,3044,BM_SETCHECK, EAX, NULL
			
			mov ofont, 0h
			mov olig, 0FFh
			invoke InvalidateRect,hWin,NULL, TRUE
		.elseif wParam==3038
			invoke SendDlgItemMessage,hWin,3038,BM_GETCHECK,NULL, NULL
			.if EAX>0
				mov EAX, 0
			.else
				mov EAX, 1
			.endif
			invoke SendDlgItemMessage,hWin,3039,BM_SETCHECK,EAX, NULL
		.elseif wParam==3039
			invoke SendDlgItemMessage,hWin,3039,BM_GETCHECK,NULL, NULL
			.if EAX>0
				mov EAX, 0
			.else
				mov EAX, 1
			.endif
			invoke SendDlgItemMessage,hWin,3038,BM_SETCHECK,EAX, NULL
		.elseif wParam==3042
			invoke SendDlgItemMessage,hWin,3042,BM_GETCHECK,NULL, NULL
			.if EAX==0
				invoke SendDlgItemMessage,hWin,3043,BM_GETCHECK,NULL, NULL
				.if EAX==0
				invoke SendDlgItemMessage,hWin,3043,BM_SETCHECK,1, NULL
				.endif
			.endif
		.elseif wParam==3043
			invoke SendDlgItemMessage,hWin,3043,BM_GETCHECK,NULL, NULL
			.if EAX==0
				invoke SendDlgItemMessage,hWin,3042,BM_GETCHECK,NULL, NULL
				.if EAX==0
				invoke SendDlgItemMessage,hWin,3042,BM_SETCHECK,1, NULL
				.endif
			.endif
		.endif
	.elseif uMsg==WM_HSCROLL
		.if WORD PTR wParam==SB_LINERIGHT
			invoke SendMessage,lParam,SBM_GETRANGE,addr temp2, addr temp
			mov EDX, 0
			mov EAX, temp
			mov ECX, 20
			div ECX
			.if EAX<0
			 mov EAX, 1
			.endif
			mov temp, EAX
			invoke SendMessage,lParam,SBM_GETPOS,NULL, NULL
			add EAX, temp
			invoke SendMessage,lParam,SBM_SETPOS,EAX,TRUE
		.elseif WORD PTR wParam==SB_LINELEFT
			invoke SendMessage,lParam,SBM_GETRANGE,addr temp2, addr temp
			mov EDX, 0
			mov EAX, temp
			mov ECX, 20
			div ECX
			.if EAX<=0
			 mov EAX, 1
			.endif
			mov temp, EAX
			invoke SendMessage,lParam,SBM_GETPOS,NULL, NULL
			sub EAX, temp
			invoke SendMessage,lParam,SBM_SETPOS,EAX,TRUE
		.elseif WORD PTR wParam==SB_THUMBPOSITION || WORD PTR wParam==SB_THUMBTRACK
			mov EAX, wParam
			shr eax,16
			invoke SendMessage,lParam,SBM_SETPOS,EAX,TRUE
		.elseif WORD PTR wParam==SB_PAGELEFT
			invoke SendMessage,lParam,SBM_GETRANGE,addr temp2, addr temp
			mov EDX, 0
			mov EAX, temp
			mov ECX, 5
			div ECX
			.if EAX<=0
			 mov EAX, 1
			.endif
			mov temp, EAX
			invoke SendMessage,lParam,SBM_GETPOS,NULL, NULL
			sub EAX, temp
			invoke SendMessage,lParam,SBM_SETPOS,EAX,TRUE
		.elseif WORD PTR wParam==SB_PAGERIGHT
			invoke SendMessage,lParam,SBM_GETRANGE,addr temp2, addr temp
			mov EDX, 0
			mov EAX, temp
			mov ECX, 5
			div ECX
			.if EAX<=0
			 mov EAX, 1
			.endif
			mov temp, EAX
			invoke SendMessage,lParam,SBM_GETPOS,NULL, NULL
			add EAX, temp
			invoke SendMessage,lParam,SBM_SETPOS,EAX,TRUE
		.endif
		invoke GetDlgItem,hWin, 3028
		.if lParam==EAX
			invoke SendDlgItemMessage,hWin,3028,SBM_GETPOS,NULL, NULL
			add EAX, 1
			mov temp, EAX
			mov EDX, 15
			mul EDX
			invoke SendDlgItemMessage,hWin,3017,SBM_SETPOS,EAX, TRUE
			mov EAX, temp
			mov EDX, 5
			mul EDX
			invoke SendDlgItemMessage,hWin,3019,SBM_SETPOS,EAX, TRUE
			mov EAX, temp
			mov EDX, 3
			mul EDX
			invoke SendDlgItemMessage,hWin,3021,SBM_SETPOS,EAX, TRUE
			mov EAX, temp
			mov EDX, 6
			mul EDX
			invoke SendDlgItemMessage,hWin,3030,SBM_SETPOS,EAX, TRUE
			
		.endif
		mov settext.flags,ST_DEFAULT
		mov settext.codepage,1251
		invoke SendDlgItemMessage,hWin,3013,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX, addr lpstr
		invoke SendDlgItemMessage,hWin,3012,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3015,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX, addr lpstr
		invoke SendDlgItemMessage,hWin,3014,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3017,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX, addr lpstr
		invoke SendDlgItemMessage,hWin,3016,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3019,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX, addr lpstr
		invoke SendDlgItemMessage,hWin,3018,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3021,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX, addr lpstr
		invoke SendDlgItemMessage,hWin,3020,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3025,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX, addr lpstr
		invoke SendDlgItemMessage,hWin,3024,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3030,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX, addr lpstr
		invoke SendDlgItemMessage,hWin,3029,WM_SETTEXT,addr settext,addr lpstr
		invoke SendDlgItemMessage,hWin,3036,SBM_GETPOS,NULL, NULL
		invoke IntToChar,EAX, addr lpstr
		invoke SendDlgItemMessage,hWin,3035,WM_SETTEXT,addr settext,addr lpstr
	.endif
	xor EAX, EAX
	ret
OptionProc endp


IntToChar PROC sour:DWORD, dest:DWORD
PUSHAD ;looking for the digit count
	mov EAX, sour
	mov EBX, 10d
	mov ECX, 0
re:
	mov EDX, 0
	div EBX
	inc ECX
	cmp EAX, 0
	jne re
	;  put zero terminated char
	push ECX
	add ECX, dest
	mov dl, 0
	mov [ECX], dl
	pop ECX
	; put digits
	mov EAX, sour
re2:
	mov EDX, 0
	div EBX
	add EDX, 30h
	push ECX
	add ECX, dest
	mov [ECX-1], dl
	pop ECX
	loop re2
POPAD
	ret
IntToChar endp


CharToInt PROC sour:DWORD
LOCAL retu:DWORD
PUSHAD
	mov retu, 0
	;  lookup for the string length
	mov ECX, sour
	dec ECX
	mov EAX, 0
re:
	inc EAX
	inc ECX
	mov dl, 0
	cmp [ECX], dl
	jne re
	dec EAX
	
	mov ECX, EAX
	mov EAX, 1
	mov EBX, 10
re2:
	mov EDX, 0
	push ECX
	add ECX, sour
	mov dl, [ECX-1]
	pop ECX
	cmp dl, 30h
	jb donot
	cmp dl, 39h
	ja donot
	sub dl, 30h
	
	push EAX
	mul EDX
	add retu, EAX
	pop EAX
	
	mul EBX
donot:
	loop re2
POPAD
	mov EAX, retu
	ret
CharToInt endp


SaveOpt PROC
	invoke WritePrivateProfileStruct,addr sect,addr wfreq,addr freq,sizeof freq, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wvol,addr vol,sizeof vol, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wdash,addr dash,sizeof dash, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wdot,addr dot,sizeof dot, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wpause,addr pause,sizeof pause, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wddpause,addr ddpause,sizeof ddpause, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wfont,addr cfont,sizeof cfont, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wlig,addr clig,sizeof clig, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wsize,addr sfont,sizeof sfont, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wspkr,addr spkr,sizeof spkr, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wdsnd,addr dsnd,sizeof dsnd, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wsinc,addr sinc,sizeof sinc, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wuroven,addr uroven,sizeof uroven, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wcyrlat,addr cyrlat,sizeof cyrlat, addr CurDir
	invoke WritePrivateProfileStruct,addr sect,addr wautorec,addr autorec,sizeof autorec, addr CurDir

	ret
SaveOpt endp


LoadOpt PROC
LOCAL charfrm:CHARFORMAT2
	invoke GetFileAttributes,addr CurDir
	.if EAX==-1
		invoke SaveOpt
		jmp def
	.endif
	invoke GetPrivateProfileStruct,addr sect,addr wfreq,addr freq,sizeof freq, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wvol,addr vol,sizeof vol, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wdash,addr dash,sizeof dash, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wdot,addr dot,sizeof dot, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wpause,addr pause,sizeof pause, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wddpause,addr ddpause,sizeof ddpause, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wfont,addr cfont,sizeof cfont, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wlig,addr clig,sizeof clig, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wsize,addr sfont,sizeof sfont, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wspkr,addr spkr,sizeof spkr, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wdsnd,addr dsnd,sizeof dsnd, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wsinc,addr sinc,sizeof sinc, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wuroven,addr uroven,sizeof uroven, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wcyrlat,addr cyrlat,sizeof cyrlat, addr CurDir
	invoke GetPrivateProfileStruct,addr sect,addr wautorec,addr autorec,sizeof autorec, addr CurDir

def:

	mov charfrm.cbSize, sizeof CHARFORMAT2
	mov charfrm.dwMask, CFM_COLOR or CFM_SIZE
	mov ECX, 20
	mov EAX, sfont
	mul ECX
	mov charfrm.yHeight,EAX
	mov EAX, cfont
	mov charfrm.crTextColor,EAX
	invoke SendDlgItemMessage,hwnd,1001,EM_SETCHARFORMAT,SCF_ALL, addr charfrm

	ret
LoadOpt endp


InitDSound PROC
invoke DirectSoundCreate,NULL, addr pDirectSound, NULL
	dsound8 SetCooperativeLevel,pDirectSound, hwnd, DSSCL_PRIORITY
	mov wfx_.nChannels,2
	mov wfx_.wFormatTag, WAVE_FORMAT_PCM
	mov wfx_.nSamplesPerSec,16000
	mov wfx_.wBitsPerSample,16
	mov wfx_.nBlockAlign, 16 / 8 * 2 ;wfx_.wBitsPerSample / 8 * wfx_.nChannels
	mov wfx_.nAvgBytesPerSec , 16000 * 16 / 8 * 2; wfx_.nSamplesPerSec * wfx_.nBlockAlign
	mov wfx_.cbSize, 0
	mov     dsbdesc_.dwSize, sizeof DSBUFFERDESC
	mov     dsbdesc_.dwFlags, DSBCAPS_GLOBALFOCUS
	mov EAX, S_lengte
	mov     dsbdesc_.dwBufferBytes, EAX
	lea     EAX,wfx_
	mov     dsbdesc_.lpwfxFormat, EAX
	dsound8 CreateSoundBuffer, pDirectSound, ADDR dsbdesc_, ADDR pDSSample, NULL
	invoke SetVolFreq,vol,freq	
	mov initds, TRUE
	ret
InitDSound endp


PWndProc PROC hWin:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
LOCAL ofn:OPENFILENAME
LOCAL temp:DWORD
LOCAL settextex:SETTEXTEX
LOCAL gettt:GETTEXTEX 
LOCAL charfrm:CHARFORMAT2
LOCAL srect:RECT
	.if uMsg==WM_CLOSE
		invoke EndDialog,hWin,NULL
	.elseif uMsg==WM_INITDIALOG
		mov EAX, hWin
		mov phwnd, EAX
		invoke SetFocus,hWin
		invoke SendDlgItemMessage,hWin, 4008,WM_SETTEXT, NULL,addr richedstt
		mov stre.flags,ST_DEFAULT
		mov stre.flags,1251
		
		invoke CreateThread,NULL,NULL,addr InitDSoundCap,NULL,NULL,NULL
		invoke GetPrivateProfileStruct,addr sect,addr wfont,addr cfont,sizeof cfont, addr CurDir
	
		invoke GetPrivateProfileStruct,addr sect,addr wlig,addr clig,sizeof clig, addr CurDir
		invoke GetPrivateProfileStruct,addr sect,addr wsize,addr sfont,sizeof sfont, addr CurDir
		mov charfrm.cbSize, sizeof CHARFORMAT2
		mov charfrm.dwMask, CFM_COLOR or CFM_SIZE
		mov ECX, 20
		mov EAX, sfont
		mul ECX
		mov charfrm.yHeight,EAX
		mov EAX, cfont
		mov charfrm.crTextColor,EAX
		invoke SendDlgItemMessage,phwnd,4008,EM_SETCHARFORMAT,SCF_ALL, addr charfrm
		
		invoke LoadImage,hInstance,addr iconka,IMAGE_ICON,0,0,LR_DEFAULTCOLOR
		invoke SendMessage,hWin,WM_SETICON,ICON_BIG, EAX
		.if DWORD PTR ppos==0 && DWORD PTR ppos+4==0 && DWORD PTR psize==0 && DWORD PTR psize+4==0
			invoke ShowWindow,hWin, SW_MAXIMIZE
		.else
		invoke MoveWindow,hWin,DWORD PTR ppos, DWORD PTR ppos+4,DWORD PTR psize,DWORD PTR psize+4,TRUE
		.endif
		invoke GetDlgItem,hWin, 4008
		invoke SetWindowLong,EAX,GWL_WNDPROC,addr PRichEditProc
		mov poldproc, EAX
		invoke SendDlgItemMessage,hWin, 4012,PBM_SETRANGE32,0, 32767
		
	.elseif uMsg==WM_SIZE
		invoke SendDlgItemMessage,phwnd, 4008, EM_SETOPTIONS,ECOOP_OR, ECO_AUTOHSCROLL
		
		invoke GetDlgItem,hWin, 4008
		mov temp, EAX
		mov EBX, 0
		mov ECX, 0
		mov BX, WORD PTR lParam
		mov CX, WORD PTR lParam+2
		sub ECX, 30
		invoke MoveWindow,temp, 0,30,EBX, ECX,FALSE
		.if wParam==SIZE_MAXIMIZED
			mov DWORD PTR ppos, 0
			mov DWORD PTR psize,0
			mov DWORD PTR ppos+4, 0
			mov DWORD PTR psize+4,0
		.elseif wParam==SIZE_RESTORED
			invoke GetWindowRect,hWin, addr srect
			invoke SendMessage,hWin, WM_SIZING,NULL, addr srect
		.endif
	.elseif uMsg==WM_COMMAND
		.if wParam==4510
			.if trun==FALSE
				invoke CreateThread, NULL,NULL,addr StartTransmitter,NULL,NULL,NULL
			.else
				invoke SetForegroundWindow,hwnd
			.endif
		.elseif wParam==4511
			mov EAX, bend
		 	mov bpos, EAX
		 	invoke SetLastError,NULL
		 	invoke DialogBoxParam,hInstance,3000,hwnd,addr OptionProc,NULL
		 	invoke GetLastError
		 	.if EAX==ERROR_INVALID_WINDOW_HANDLE
		 		invoke DialogBoxParam,hInstance,3000,NULL,addr OptionProc,NULL
		 	.endif
		.elseif wParam==4506
		call GetTickCount
		mov sttime, EAX
		mov prinyto, 0
			mov recconf, TRUE
		.elseif wParam==4507
			mov recconf, FALSE
		.elseif wParam==4508
		 	mov rdot,3000
		 	mov rpause, 3000
		.elseif wParam==4509
		 	.if arun==FALSE
			 	mov arun, TRUE
			 	invoke DialogBoxParam,hInstance,2000,NULL,addr AboutProc,NULL
			 	mov arun, FALSE
		 	.else
		 		invoke SetForegroundWindow,ahwnd
		 	.endif
		.elseif wParam==4503
			 invoke RtlZeroMemory,addr ofn, sizeof OPENFILENAME
			 mov ofn.lStructSize, sizeof OPENFILENAME
			 mov ofn.Flags,OFN_HIDEREADONLY or OFN_OVERWRITEPROMPT
			 lea EAX, defext
			 mov ofn.lpstrDefExt, EAX
			 lea EAX, fn
			 mov ofn.lpstrFile,EAX
			 mov ofn.nMaxFile, MAX_PATH 
			 lea EAX, sfiltr
			 mov ofn.lpstrFilter, EAX
			 lea EAX, psavetext
			 mov ofn.lpstrTitle, EAX
			 
			 invoke GetSaveFileName,addr ofn
			 cmp EAX, FALSE
			 je cancel2
			 invoke CreateFile,addr fn,GENERIC_WRITE,FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,FILE_ATTRIBUTE_NORMAL,0
			 mov hFile, EAX
			 mov gettt.codepage,1251
			 mov gettt.cb,1024*1024*10
			 mov gettt.flags,GT_DEFAULT
			 mov gettt.lpDefaultChar, NULL
			 mov gettt.lpUsedDefChar, NULL
			 invoke SendDlgItemMessage,hWin, 4008,EM_GETTEXTEX,addr gettt,buff
			 mov temp, EAX
			 invoke WriteFile,hFile,buff, temp, addr temp, NULL
			 invoke CloseHandle,hFile
cancel2:
		.elseif wParam==4504
			invoke EndDialog,hWin, 0
		.elseif wParam==4502
			 invoke RtlZeroMemory,addr ofn, sizeof OPENFILENAME
			 mov ofn.lStructSize, sizeof OPENFILENAME
			 mov ofn.Flags,OFN_FILEMUSTEXIST or OFN_HIDEREADONLY
			 lea EAX, fn
			 mov ofn.lpstrFile,EAX
			 mov ofn.nMaxFile, MAX_PATH 
			 lea EAX, ofiltr
			 mov ofn.lpstrFilter, EAX
			 lea EAX, popentext
			 mov ofn.lpstrTitle, EAX
			 
			 invoke GetOpenFileName,addr ofn
			 cmp EAX, FALSE
			 je cancel
			 invoke CreateFile,addr fn,GENERIC_READ,FILE_SHARE_READ,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,0
			 mov hFile, EAX
			 invoke GetFileSize,hFile, 0
			 mov fsize, EAX
			 inc fsize
			 invoke GlobalAlloc, GMEM_ZEROINIT,fsize
			 mov filete, EAX
			 invoke ReadFile,hFile,filete,fsize,addr temp,NULL
			 mov settextex.flags,ST_DEFAULT
			 mov settextex.codepage, 1251
			 invoke SendDlgItemMessage,hWin, 4008,EM_SETTEXTEX,addr settextex,filete
			 invoke GlobalFree,filete
			 invoke CloseHandle,hFile
			 mov EAX, buff
			 add EAX, fsize
			 mov bpos, EAX
cancel:
		.elseif wParam==4512
			invoke SendDlgItemMessage,hWin, 4008,WM_SETTEXT, NULL,addr richedstt
		.elseif wParam==4013
			invoke SendMessage,hWin, WM_COMMAND, 4506, NULL
		.elseif wParam==4014
			invoke SendMessage,hWin, WM_COMMAND, 4507, NULL
		.endif
	.elseif uMsg==WM_MOVING || uMsg==WM_SIZING
		mov EAX, lParam
		mov EBX, DWORD PTR [EAX+0d]
		mov DWORD PTR ppos, EBX
		
		mov EBX, DWORD PTR [EAX+4d]
		mov DWORD PTR ppos+4, EBX
		
		mov EBX, DWORD PTR [EAX+8d]
		sub EBX, DWORD PTR [EAX+0d]
		mov DWORD PTR psize, EBX
		
		mov EBX, DWORD PTR [EAX+12d]
		sub EBX, DWORD PTR [EAX+4d]
		mov DWORD PTR psize+4, EBX
	.endif	
		
	xor EAX, EAX
	ret
PWndProc endp


InitDSoundCap PROC
LOCAL recst:BYTE
LOCAL temp:DWORD
	invoke DirectSoundCaptureCreate,NULL, addr pDSoundCapture, NULL
	mov waveFmt.wFormatTag, WAVE_FORMAT_PCM
	mov waveFmt.nChannels, 1
	mov waveFmt.nSamplesPerSec, diskr
	mov waveFmt.wBitsPerSample, 16
	mov waveFmt.nBlockAlign, 16*1/8
	mov waveFmt.nAvgBytesPerSec,  diskr * 16*1/8
	mov waveFmt.cbSize, 0

	invoke RtlZeroMemory, addr dscBufDesc, sizeof dscBufDesc
	mov dscBufDesc.dwSize, sizeof dscBufDesc
	mov dscBufDesc.dwFlags, 0
	mov dscBufDesc.dwBufferBytes, diskr * 16*1/8 * 10
	mov dscBufDesc.dwReserved, 0
	lea EAX, waveFmt
	mov dscBufDesc.lpwfxFormat, EAX

	dscapture CreateCaptureBuffer,pDSoundCapture, addr dscBufDesc, addr pDSCBuffer, NULL
	dscaptbuff Start, pDSCBuffer, DSCBSTART_LOOPING
	.if autorec==TRUE
		invoke SendDlgItemMessage,phwnd,4011,WM_SETTEXT, NULL, addr reciving
	.endif
	mov recst, TRUE
	invoke GetTickCount
	mov sttime, EAX
	mov dlen, 0
	mov ppause, 0
	mov rnum, 0
	mov rdot,3000
	mov rpause, 3000
	mov rnpause, 0
	mov cme, 0
	mov prinyto, 0
	mov pst, TRUE
	mov al, autorec
	mov recconf, al
rec:
	invoke Sleep, 500
	cmp prun, FALSE
	je ex
	.if recconf==FALSE
		.if recst==TRUE
			dscaptbuff Stop, pDSCBuffer
			mov recst, FALSE
		.endif
		invoke SendDlgItemMessage,phwnd,4011,WM_SETTEXT, NULL, addr waiting
		invoke SendDlgItemMessage,phwnd,4012, PBM_SETPOS,NULL,TRUE
		jmp rec
	.endif
	.if recst==FALSE
		dscaptbuff Start, pDSCBuffer, DSCBSTART_LOOPING
		invoke SendDlgItemMessage,phwnd,4011,WM_SETTEXT, NULL, addr reciving
		invoke Sleep,500
		mov recst, TRUE
	.endif
	dscaptbuff Lock1,pDSCBuffer,0, 0, addr pCapBuf, addr dwCapBufSize, NULL, 0, DSCBLOCK_ENTIREBUFFER
	;  ready buffer
	mov EAX, pCapBuf
	add EAX, cme
	add cme, diskr
	invoke memcpy,addr wbuff,EAX,diskr
	
	; show
	mov ECX, 0
	mov EBX, 0
	mov EDX, 0
calc:
	mov BX, WORD PTR [EAX]
	cmp BX, 07FFFh
	jbe poloj
	mov temp, 0FFFFh
	sub temp, EBX
	mov EBX, temp
poloj:
	add ECX, EBX
	add EDX, 2000;50
	add EAX, 2000;50
	cmp EDX, diskr;-50
	jb calc
	mov EDX, 0
	mov EAX, ECX
	mov EBX, diskr/2000;/50
	div EBX
	invoke SendDlgItemMessage,phwnd, 4012,PBM_SETPOS, EAX, NULL
	
	.if cme>=diskr * 16*1/8 * 10
		mov cme, 0
	.endif
	invoke CreateThread,NULL,NULL,SearchLen, NULL, NULL,NULL
	;invoke SearchLen
	
	dscaptbuff Unlock,pDSCBuffer,pCapBuf, dwCapBufSize, NULL, 0
	cmp prun, FALSE
	jne rec
ex:
	ret
InitDSoundCap endp


SearchLen PROC
LOCAL temp:DWORD
LOCAL string:TBYTE
LOCAL i:DWORD
	mov ECX, diskr/2
	mov i, ECX
	mov ECX, 0
cycl:
	mov EBX, 0
	mov BX, WORD PTR wbuff[ECX*2]
	push ECX
	cmp BX, 07FFFh
	jbe poloj
	mov temp, 0FFFFh
	sub temp, EBX
	mov EBX, temp
	poloj:
	.if EBX>uroven
		inc dlen
		.if dlen<1 && ppause>0
			inc ppause
		.else
			.if rnpause>19
				mov rnpause, 0
			.endif
			.if ppause>1000 && rnum>0
				mov EAX, rnpause
				mov EDX, ppause
				mov rpbuff[EAX*4], EDX
				INC rnpause
			.endif
			mov ppause, 0
			.if dlen>1000
				mov pst, FALSE
			.endif
		.endif
	.else
		inc ppause
		.if ppause<1300 && dlen>0
			.if ppause<1
				inc dlen
			.endif
		.else
			.if rnum>19
				mov rnum, 0
			.endif
			.if dlen>1000
				fild dlen
				fld k
				fdiv
				fistp temp
				mov EAX, temp
				.if EAX>rpause
					mov EAX, dlen
					mov rpause, EAX
				.endif
				mov EAX, rnum
				mov EDX, dlen
				mov rbuff[EAX*4], EDX
				INC rnum
			.endif
			mov dlen, 0
		.endif
		.if rnpause>1
			dec rnpause
			mov ECX, rnpause
			mov EBX, 0
summir:
			add EBX, rpbuff[ECX*4-4]
			loop summir
			mov temp, EBX
			fild temp
			fild rnpause
			fdiv
			fistp rpause
		.endif
		fild rpause
		fld kp
		fmul
		fistp temp
		mov EAX, temp
	
		.if ppause>EAX && rnum>0
			invoke Encod
			inc prinyto
			mov rnum, 0
			mov rnpause, 0
		.else
			fild rpause
			fld probel
			fmul
			fistp temp
			mov EBX, temp
			.if ppause>EBX && pst==FALSE
				mov pst, TRUE
				mov temp, 32d
				invoke SendDlgItemMessage,phwnd, 4008,EM_SETTEXTEX, addr stre,addr temp		
			.endif
		.endif

	.endif
	pop ECX
	inc ECX
	cmp ECX, i
	jb cycl
	
	ret
SearchLen endp


Encod PROC
LOCAL temp:DWORD
LOCAL string:TBYTE
LOCAL wo:WORD
	invoke Analyse
	fild rdot
	fld pogr
	fmul
	fistp temp
	mov ECX, 20
cycl:
	mov EBX, rbuff[ECX*4-4]
	cmp rdot, EBX
	ja bol
	mov EAX, rdot
	sub rbuff[ECX*4-4], EAX
	jmp men
bol:
	mov EAX, rdot
	sub EAX, rbuff[ECX*4-4]
	mov rbuff[ECX*4-4], EAX
men:
	mov EAX, temp
	cmp rbuff[ECX*4-4], EAX
	ja okk
	mov rbuff[ECX*4-4], 0
	jmp ok
okk:
	mov rbuff[ECX*4-4], 1
ok:
	loop cycl


	mov ECX, 10
tmp:
	mov al, 02Eh
	sub al, BYTE PTR rbuff[ECX*4-4]
	lea EBX, string
	mov [EBX+ECX-1], al
	loop tmp
	lea EBX, string
	add EBX, rnum
	.if rnum!=0
		dec EBX
	.endif
	mov al, 0
	mov [EBX+1], al

	invoke SendDlgItemMessage,phwnd, 4003,WM_SETTEXT,NULL, addr string
	;0 - dot, 1 - dash
	;cyrlat 0 - cyr, 1 - lat
	mov wo, 0
	.if rnum==1
		.if rbuff[0d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'å' 
			.else
				 mov WORD PTR wo, 'e'	
			.endif
		.elseif rbuff[0d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'ò' 
			.else
				 mov WORD PTR wo, 't'	
			.endif	
		.endif
	.elseif rnum==2
		.if rbuff[0d]==1 && rbuff[4d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'í' 
			.else
				 mov WORD PTR wo, 'n'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'ì' 
			.else
				 mov WORD PTR wo, 'm'	
			.endif	
		.elseif rbuff[0d]==0 && rbuff[4d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'è' 
			.else
				 mov WORD PTR wo, 'i'	
			.endif	
		.elseif rbuff[0d]==0 && rbuff[4d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'à' 
			.else
				 mov WORD PTR wo, 'a'	
			.endif	
		.endif
	.elseif rnum==3
		.if rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'â' 

			.else
				 mov WORD PTR wo, 'w'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==0
			.if cyrlat==0
	
	
				mov WORD PTR wo, 'ã' 
			.else
				 mov WORD PTR wo, 'g'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'ä' 
			.else
				 mov WORD PTR wo, 'd'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'ê' 
			.else
				 mov WORD PTR wo, 'k'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'î' 
			.else
				 mov WORD PTR wo, 'o'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'í' 
			.else
				 mov WORD PTR wo, 'n'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'ð' 
			.else
				 mov WORD PTR wo, 'r'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'ñ' 
			.else
				 mov WORD PTR wo, 's'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'ó' 
			.else
				 mov WORD PTR wo, 'u'	
			.endif
		.endif
	.elseif rnum==4
		.if rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'á' 
			.else
				mov WORD PTR wo, 'b'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'æ' 
			.else
				mov WORD PTR wo, 'v'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==0 && rbuff[12d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'ç' 
			.else
				mov WORD PTR wo, 'z'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==0 && rbuff[12d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'ë' 
			.else
				mov WORD PTR wo, 'l'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'ï' 
			.else
				mov WORD PTR wo, 'p'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==1 && rbuff[12d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'ô' 
			.else
				mov WORD PTR wo, 'f'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'õ' 
			.else
				mov WORD PTR wo, 'h'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==1 && rbuff[12d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'ö' 
			.else
				mov WORD PTR wo, 'c'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==0
			.if cyrlat==0
				mov WORD PTR wo, '÷' 
			;.else
				;mov WORD PTR wo, 'u'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'ø' 
			;.else
			;	mov WORD PTR wo, 'u'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==0 && rbuff[12d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'ù' 
			.else
				mov WORD PTR wo, 'q'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==1 && rbuff[12d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'û' 
			.else
				mov WORD PTR wo, 'y'	
			.endif
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'ü' 
			.else
				mov WORD PTR wo, 'x'	
			.endif	
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==1 && rbuff[12d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'þ' 
			;.else
			;	mov WORD PTR wo, 'u'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==0 && rbuff[12d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'ÿ' 
			;.else
			;	mov WORD PTR wo, 'u'	
			.endif
		.elseif rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==1
			.if cyrlat==0
				mov WORD PTR wo, 'é' 
			.else
				mov WORD PTR wo, 'j'	
			.endif
		.endif
	.elseif rnum==5
		.if rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==1 && rbuff[16d]==1
		mov WORD PTR wo, '1'
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==1 && rbuff[12d]==1 && rbuff[16d]==1
		mov WORD PTR wo, '2'
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==1 && rbuff[16d]==1
		mov WORD PTR wo, '3'
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==0 && rbuff[16d]==1
		mov WORD PTR wo, '4'
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==0 && rbuff[16d]==0
		mov WORD PTR wo, '5'
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==0 && rbuff[16d]==0
		mov WORD PTR wo, '6'
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==0 && rbuff[12d]==0 && rbuff[16d]==0
		mov WORD PTR wo, '7'
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==0 && rbuff[16d]==0
		mov WORD PTR wo, '8'
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==1 && rbuff[16d]==0
		mov WORD PTR wo, '9'
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==1 && rbuff[16d]==1
		mov WORD PTR wo, '0'
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==1 && rbuff[12d]==0 && rbuff[16d]==1
		mov WORD PTR wo, ';'
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==1 && rbuff[16d]==0
		mov WORD PTR wo, '#'
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==1 && rbuff[16d]==0
		mov WORD PTR wo, '/'
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==1 && rbuff[12d]==0 && rbuff[16d]==0
			.if cyrlat==0
				mov WORD PTR wo, 'ý' 
			.else
				 ;mov WORD PTR wo, ''	
			.endif
		.endif
	.elseif rnum==6
		.if rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==0 && rbuff[12d]==1 && rbuff[16d]==0 && rbuff[20d]==1
		mov WORD PTR wo, ','
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==0 && rbuff[16d]==0 && rbuff[20d]==0
		mov WORD PTR wo, '.'
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==0 && rbuff[16d]==0 && rbuff[20d]==0
		mov WORD PTR wo, ':'
		.elseif rbuff[0d]==0 && rbuff[4d]==0 && rbuff[8d]==1 && rbuff[12d]==1 && rbuff[16d]==0 && rbuff[20d]==0
		mov WORD PTR wo, '?'
		.elseif rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==0 && rbuff[12d]==0 && rbuff[16d]==1 && rbuff[20d]==0
		mov WORD PTR wo, '"'
		.elseif rbuff[0d]==0 && rbuff[4d]==1 && rbuff[8d]==1 && rbuff[12d]==1 && rbuff[16d]==1 && rbuff[20d]==0
		mov WORD PTR wo, '`'
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==1 && rbuff[12d]==1 && rbuff[16d]==0 && rbuff[20d]==1
		mov WORD PTR wo, '('
		.elseif rbuff[0d]==1 && rbuff[4d]==1 && rbuff[8d]==0 && rbuff[12d]==0 && rbuff[16d]==1 && rbuff[20d]==1
		mov WORD PTR wo, '!'
		.elseif rbuff[0d]==1 && rbuff[4d]==0 && rbuff[8d]==0 && rbuff[12d]==0 && rbuff[16d]==0 && rbuff[20d]==1
		mov WORD PTR wo, '-'
		.endif
	.endif

	.if wo==0
	
	mov wo, 003Ch
		invoke SendDlgItemMessage,phwnd, 4008,EM_SETTEXTEX, addr stre,addr wo
		invoke SendDlgItemMessage,phwnd, 4008,EM_SETTEXTEX, addr stre,addr string
	mov wo, 003Eh
		invoke SendDlgItemMessage,phwnd, 4008,EM_SETTEXTEX, addr stre,addr wo
	.else 
		invoke SendDlgItemMessage,phwnd, 4008,EM_SETTEXTEX, addr stre,addr wo
	.endif
	
	fild rpause
	mov temp, diskr/1000
	fild temp
	fdiv
	fistp temp
	invoke IntToChar,temp,addr string
	invoke SendDlgItemMessage,phwnd,4002,WM_SETTEXT,NULL,addr string
	
	invoke GetTickCount
	sub EAX, sttime
	mov temp, EAX
	fild temp
	fild msecinmin
	fdiv
	fstp temp
	fild prinyto
	fld temp
	fdiv
	fistp temp
	invoke IntToChar,temp,addr string
	invoke SendDlgItemMessage,phwnd,4009,WM_SETTEXT,NULL,addr string

	ret
Encod endp


Analyse PROC
LOCAL temp:DWORD
LOCAL string:TBYTE
LOCAL sumt:DWORD
LOCAL t:DWORD
	mov sumt, 0
	mov t, 0
	mov ECX, rnum
	inc ECX
cycl:
	mov EBX, rbuff[ECX*4-4]
	push ECX
	mov ECX, rnum
	inc ECX
	cycl2:
	fild rbuff[ECX*4-4]
	mov temp, EBX
	fild temp
	fdiv
	mov temp, 10
	fild temp
	fmul
	fistp temp
	.if temp>=18 && temp<300 ; everything multiply by 10
		push EBX
		push ECX
		add sumt, EBX
		inc t
		pop ECX
		pop EBX
	.endif
	loop cycl2
	pop ECX
	loop cycl
	.if t>0
		fild sumt
		fild t
		fdiv
		fistp rdot
	.endif

	fild rdot
	mov temp, diskr/1000
	fild temp
	fdiv
	fistp temp
	invoke IntToChar,temp, addr string
	invoke SendDlgItemMessage,phwnd, 4004,WM_SETTEXT,NULL, addr string
	ret
Analyse endp


memcpy PROC dest:DWORD, sour:DWORD, slen:DWORD
PUSHAD
	mov EAX, dest
	mov EBX, sour
	mov ECX, slen
re:
	mov dl, [EBX+ECX-1]
	mov [EAX+ECX-1], dl
	loop re
POPAD
	ret
memcpy endp


StartReceiver PROC
	mov prun, TRUE
	invoke DialogBoxParam,hInstance,4000,NULL, addr PWndProc, NULL
	mov prun, FALSE
	dscaptbuff8 Release, pDSCBuffer
	dscapture Release, pDSoundCapture
	ret

StartReceiver endp


StartTransmitter PROC
	mov trun, TRUE
	invoke DialogBoxParam,hInstance,1000,NULL, addr WndProc,NULL
	mov trun, FALSE
	ret
StartTransmitter endp

end WinMain