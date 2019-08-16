; Author: Vincent Bravinder

; This Program is a game where the player plays as an 'O'
; and must avoid red squares that move or else the player 
; will lose.
INCLUDE Irvine32.inc
INCLUDE Macros.inc

enemy STRUCT
	xPos BYTE ?
	yPos BYTE ?
enemy ENDS

mXLine MACRO x,y
	LOCAL LX
	.code
	mov DL, x
	mov DH, y
	call gotoxy
	mov AL, 219
	mov ECX, 110
	LX:
		call WriteChar
		Loop LX
ENDM

mYLine MACRO x,y
	LOCAL LY
	.code
	mov AL, 219
	mov ECX, 29
	mov DL, x	
	mov DH, y
	LY:	
		inc DH
		call gotoXY
		call WriteChar
		Loop LY
	ENDM

.data
	outhandle DWORD ?
	def CONSOLE_CURSOR_INFO <>
	randTime SYSTEMTIME <> 
	screen COORD <200, 56>
	wind SMALL_RECT <0,0,200,56>
	moveC BYTE "Move-Count - ", 0
	menu BYTE " Move with the arrow keys and avoid the enemy squares.", 0dh, 0ah,
			  " Every time you move they will move as well, if you run into them you will die.",0dh, 0ah,
			  " NOTE: Stay away from the walls, a red square can come out at any time and kill you", 0
	finalScore BYTE " GAME OVER ", 0dh,0ah,
					"Your Final Score Was - ",0
	enemyCount DWORD 0
	newEnemy DWORD 0
	enemyList enemy 1000 DUP(<>)
.code
main PROC
	INVOKE getstdhandle, STD_OUTPUT_HANDLE
	mov outhandle, EAX
	mov eax, 2
	INVOKE GetConsoleCursorInfo, outhandle, ADDR def
	mov def.bVisible, 0
	mov eax, 2
	INVOKE SetConsoleCursorInfo, outhandle, ADDR def
	mov eax, 2
	INVOKE SetConsoleScreenBufferSize, outhandle, screen
	mov eax, 1
	INVOKE SetConsoleWindowInfo, outhandle, eax, ADDR wind

	mov EAX,white+(black*16)
	call SetTextColor
	mov EDX, OFFSET menu
	call WriteString

	
	
	call createRectangle

	
	mov DL, 40
	mov DH, 45
	call gotoxy
	mov EDX, OFFSET moveC
	call WriteString

	mov ECX, 8
	Lcreate:
	call createCpu
	Loop Lcreate

	mov DL, 90
	mov DH, 25
	call gotoxy
	mov EAX,yellow+(black*16)
	call SetTextColor
	mov AL, 'O'
	call WriteChar
	call gotoxy

	call moveO
	call gameOver

	exit
main ENDP

;---------------------------------------------------
createRectangle PROC
; This Procedure creates the level that the player 
; is bound to.
; Receives	: None
; Returns	: EDX
;---------------------------------------------------

	mXLine 40,10
	mXLine 40,40
	mYLine 40,10
	mYLine 149,10

	ret
createRectangle ENDP

;---------------------------------------------------
initialSequence PROC USES EDX
; This Procedure initial enemy sequence.
; is bound to.
; Receives	: None
; Returns	: enemyList
;---------------------------------------------------

	mov AL, ' '
	mov ECX, 0
L2:
	mov DL, enemyList[ECX*2].xPos
	mov DH, enemyList[ECX*2].yPos
	call gotoxy
	call WriteChar
	inc ECX
	cmp ECX, enemyCount
	jl L2

	mov enemyList[0].xPos, 85
	mov enemyList[0].yPos, 20
	mov enemyList[2].xPos, 90
	mov enemyList[2].yPos, 20
	mov enemyList[4].xPos, 95
	mov enemyList[4].yPos, 20
	mov enemyList[6].xPos, 85
	mov enemyList[6].yPos, 25
	mov enemyList[8].xPos, 95
	mov enemyList[8].yPos, 25
	mov enemyList[10].xPos, 85
	mov enemyList[10].yPos, 30
	mov enemyList[12].xPos, 90
	mov enemyList[12].yPos, 30
	mov enemyList[14].xPos, 95
	mov enemyList[14].yPos, 30

	mov AL, 254
	mov ECX, 0
L3:
	mov DL, enemyList[ECX*2].xPos
	mov DH, enemyList[ECX*2].yPos
	call gotoxy
	call WriteChar
	inc ECX
	cmp ECX, enemyCount
	jl L3

	ret
initialSequence ENDP

;---------------------------------------------------
moveO PROC 
; This procedure allows to user to move and calls the
; other procedures related to both the player and the
; cpu.
; Receives	: EDX
; Returns	: EDI
;---------------------------------------------------

	mov EAX, red+(black*16)
	call settextcolor
	call initialSequence
	mov EDI, 0
	L1:
		mov ESI, EDX
		mov EAX, 10
		call delay	;Seems to run better with a delay.
		call readkey
		mov BX, dx
	
		.IF( BX >= 37 && BX <= 40)
			mov EAX, red+(black*16)
			call settextcolor
			inc newEnemy
			call cpuMove
			.IF(newEnemy == 2)
				call createCpu
				mov newEnemy, 0
			.ENDIF
			mov EDX, ESI
			mov EAX, yellow+(black*16)
			call settextcolor
			call gotoxy
			call collisionDetect
			jc LCarry
			mov AL, ' '
			call WriteChar
			LCarry: 
		.ENDIF

		.IF (bx == 37)	
			dec DL
		.ELSEIF (bx == 38)
			dec DH
		.ELSEIF (bx == 39)
			inc DL
		.ELSEIF (bx == 40)
			inc DH
		.ENDIF

		.IF( BX >= 37 && BX <= 40)
			call checkBound
			call gotoxy
			mov AL, 'O'
			call WriteChar
			call collisionDetect
			jc GO
			call countMoves
			call gotoxy
			mov ESI, EDX
		.ELSE
			mov EDX, ESI
		.ENDIF
		
		jmp L1
	GO:	ret
moveO ENDP

;---------------------------------------------------
checkBound PROC
; Checks if unit is within bounds, if not it fixes it.
; Receives	: EDX
; Returns	: EDX
;---------------------------------------------------

	.IF (DL == 40)
		inc DL
	.ELSEIF (DL == 149)
		dec DL
	.ENDIF

	.IF (DH == 10)
		inc DH
	.ELSEIF (DH == 40)
		dec DH
	.ENDIF
	
	ret
checkBound ENDP
;---------------------------------------------------
countMoves PROC USES EDX
; This Procedure tracks and writes the move counter
; Receives	: EDI
; Returns	: EDI
;---------------------------------------------------

	inc EDI
	mov DH, 45
	mov DL, 53
	call gotoxy
	mov EAX, EDI
	call WriteDec
	ret
countMoves ENDP

;---------------------------------------------------
createCpu PROC USES EBX EDX ECX
; This procedure creates and enemy CPU, adds it to 
; the list of enemies, and tracks the number of enemies.
; It also randomly assigns the cpu a position.
; Receives	: enemylist, enemyCount
; Returns	: enemylist, enemyCount
;---------------------------------------------------

	INVOKE GetLocalTime, ADDR randTime
	movzx EAX, randTime.wMilliseconds
	mov EDX, 0
	mov BX, 4
	div BX 

	.IF (dx == 0)
		INVOKE GetLocalTime, ADDR randTime
		movzx EAX, randTime.wMilliseconds
		mov EDX, 0
		mov BX, 28
		div BX
		add dx, 11
		mov DH, DL
		mov DL, 41
	.ELSEIF (dx == 1)
		INVOKE GetLocalTime, ADDR randTime
		movzx EAX, randTime.wMilliseconds
		mov EDX, 0
		mov BX, 106
		div BX
		add dx, 41
		mov DH, 11
	.ELSEIF (dx == 2)
		INVOKE GetLocalTime, ADDR randTime
		movzx EAX, randTime.wMilliseconds
		mov EDX, 0
		mov BX, 28
		div BX
		add dx, 11
		mov DH, DL
		mov DL, 148
	.ELSEIF (dx == 3)
		INVOKE GetLocalTime, ADDR randTime
		movzx EAX, randTime.wMilliseconds
		mov EDX, 0
		mov BX, 106
		div BX
		add dx, 41
		mov DH, 39
	.ENDIF

	call gotoxy
	mov AL, 254
	call WriteChar
	mov ECX, enemyCount
	add enemyCount,1
	mov enemylist[ECX*2].xPos, DL
	mov enemylist[ECX*2].yPos, DH
	
	ret
createCpu ENDP

;---------------------------------------------------
cpuMove PROC USES EBX EDX ESI
; This procedure moves the enemy cpu randomly and 
; changes its coordinates in enemyList.
; Receives	: enemyList, enemyCount
; Returns	: enemylist
;---------------------------------------------------

	mov ECX, 0
LC:	mov DL, enemyList[ECX*2].xPos 
	mov DH, enemyList[ECX*2].yPos 
	call gotoxy
	mov AL, ' '
	call WriteChar

	mov ESI, ECX
	INVOKE GetLocalTime, ADDR randTime
	movzx EAX, randTime.wMilliseconds
	mov EDX, 0
	mov BX, 4
	div BX 

	mov ECX, ESI
	.IF(dx == 0)
		sub enemyList[ECX*2].xPos, 1
	.ELSEIF(dx == 1)
		sub enemyList[ECX*2].yPos, 1
	.ELSEIF(dx == 2)
		add enemyList[ECX*2].xPos, 1
	.ELSEIF(dx == 3)
		add enemyList[ECX*2].yPos, 1
	.ENDIF

	mov DL, enemyList[ECX*2].xPos
	mov DH, enemyList[ECX*2].yPos
	call checkBound
	call gotoxy
	mov AL, 254
	call WriteChar
	mov enemyList[ECX*2].xPos, DL 
	mov enemyList[ECX*2].yPos, DH 
	inc ECX
	cmp ECX, enemyCount
	JL LC
	ret
cpuMove ENDP



;---------------------------------------------------
collisionDetect PROC
; Detects if the player has collided with an enemy,
; if so it sets the carry flag
; Receives	: EDX, enemylist
; Returns	: cf
;---------------------------------------------------

	mov ECX, 0
	LGG:

	.IF(DL == enemylist[ECX*2].xPos && DH == enemylist[ECX*2].yPos)
		JMP LD
	.ENDIF

	inc ECX
	cmp ECX, enemyCount
	jge LG

	JMP LGG
	LD: stc
	LG: ret
collisionDetect  ENDP

;---------------------------------------------------
gameOver PROC
; This is the game over screen which shows the player
; their final score
; Receives	: EDI
; Returns	: None
;---------------------------------------------------

	call Clrscr
	mov DL, 0
	mov DH, 0
	call gotoxy
	mov EDX, OFFSET finalScore
	call WriteString
	mov EAX, EDI
	call WriteDec
	call crlf
	mov EAX, 5000
	call delay
	call WaitMsg

	ret
gameOver ENDP

END main