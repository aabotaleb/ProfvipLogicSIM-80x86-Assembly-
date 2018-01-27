EXTRN WelScr:FAR
EXTRN RdImgs:FAR
EXTRN DispImgs:FAR
EXTRN DrawGate:FAR
EXTRN DrawWire:FAR
EXTRN SndFile:FAR
EXTRN Simulate:FAR
EXTRN RecFile:FAR

PUBLIC FileName1
PUBLIC SimDS
PUBLIC ANDArr,NANDArr
PUBLIC ORArr,NORArr
PUBLIC XORArr,XNORArr

PUBLIC SendArr,RunArr
PUBLIC DrawGArr,DrawWArr

PUBLIC Screen,ElemNum
PUBLIC Wires,WireNum

GetleftClck MACRO  
LOCAL E
	MOV AX,1;Display Mouse Pointer
	INT 33H
    MOV BX,00H
	MOV AX,5H
	INT 33H
	;Test if the right button is clicked
	;Select the Gate if Vertical position is between 0 and 50 
	CMP BX,00000001B;Accept the left click[any other center-right clicks are masked]
	JAE E
	JMP  MsLpE
	E:
ENDM

ChkClk MACRO i
	LOCAL E
	LOCAL T1
	LOCAL T2
	CMP DX,00
	JB E
	CMP DX,50
	JA E
	CMP CX,75*6+45*i ; CX is the horizontal position [x coordinate]
	JB E
	CMP CX,75*6+45*i+40
	JA E
	JNE T2
T2:	MOV IconNum,i
E:
 ENDM

 
;___________________________________________________
Data_segment_name segment para
ORG 00H
;Data Hold return from Welcome Screen module: [Passing is done through the Stack]
UserName1  DB 20,?,20 DUP (?);To Display MsgInUname : LEA DX, UserName1+2
FileName1  DB 20,?,20 DUP (00)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Data Hold return from Welcome Screen module:[Passing is done through the Data Segment]
ANDArr     DB 50,70,50 DUP (70 DUP(?));How to make dynamic allocation?
NANDArr    DB 50,70,50 DUP (70 DUP(?));How to make dynamic allocation?
ORArr      DB 50,70,50 DUP (70 DUP(?));How to make dynamic allocation?
NORArr     DB 50,70,50 DUP (70 DUP(?));How to make dynamic allocation?
XORArr     DB 50,70,50 DUP (70 DUP(?));How to make dynamic allocation?
XNORArr    DB 50,70,50 DUP (70 DUP(?));How to make dynamic allocation?

SendArr    DB 50,40,50 DUP (70 DUP(?));How to make dynamic allocation?
RunArr     DB 50,40,50 DUP (70 DUP(?));How to make dynamic allocation?
DrawGArr   DB 50,40,50 DUP (70 DUP(?));How to make dynamic allocation?
DrawWArr   DB 50,40,50 DUP (70 DUP(?));How to make dynamic allocation?

;; Mouse Specifics 
ErrMmouse DB 'The mouse is is not available',0DH,0AH,'$'
IconNum   DB 0FFH
;Here I'll Save the starting Row,Column of Each Mouse Draw Logic Gate 
;Plus its type
MaxElem    DB 20
ElemNum    DW 00
Screen     DW  20 dup (?,?,?,0FFFFH,0FFFFH,0FFFFh,?)
;for each row in matrix Screen : x coordinate(CX) , y coordinate (DX) , item type
;WireNum at firstInlet  [FFFF if user input];Default
;WireNum at SecondInlet [FFFF if user input];Defalut
;WireNum at Outlet      [FFFF if user output];Default
;Last Number is the Sequence Number
;;;;;;;;;
;Wires Data
WireNum DW 00 
Wires DW  40 DUP (?,?,?) 
;fo each row in Wires Matrix : ElemNum at Src ,ElemNum at dstn,Wire Type
;Wires Type =0 [If Wire Connecting Inputs]
;Wires Type =1 [If Wire Connecting Output of a Gate to another Gate Input](1st Click In,2nd Click Out or vice versa)
					
;Simulate Module DataSegment
SimDS DW ?					
;Counters i,j
COUNT_I    DB ?
COUNT_J    DB ? 
BufAdd DW ?
MaxR DB ?
MaxC DB ?
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Garbage [To debug the memory end]
MSG DB 0Ah,0Dh,'Bye $'
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Data_segment_name ends

;___________________________________________________
Stack_segment_name segment para stack
db 128 dup(0) ;define your stack segment
Stack_segment_name ends
;___________________________________________________


;___________________________________________________
Code_segment_name segment
;____________________________
Main_prog PROC FAR
assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name,ES:Data_segment_name

	MOV AX,Data_segment_name ; load the starting address of the data
	MOV DS,AX ; segment into DS reg.	

	
	;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^;
	;Allocate Space first for the return UserName
	;By Push Dummy String;	MOV CX,22;	LEA SI,UserName1;Alloc1:;	PUSH [SI];	ADD SI,2;	LOOP Alloc1
	;or Simply position SP to make the allocation
	SUB SP,22;Allocate 22 byte for the return 1st string
	SUB SP,22;Allocate 22 byte for the return 2nd string
	CALL WelScr
	CALL RETURN
	;Allocated 44 bytes are freed up by the RETURN Proc
	;As of RET 44 instruction
	; %%%%%%%%%% debug point %%%%%%%%%
    ; %%%%%%%%%%             %%%%%%%%%
	;LEA DX, FileName1 +2
	;MOV AH,09H
	;INT 21H
	; %%%%%%%%%%             %%%%%%%%%
	;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv;

	;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^;
	CALL ClrScr
	;Read AND Gate binary Image file
	CALL RdImgs
	;getch() for debug purpose [after receiving readImages reporting messages]
	MOV AH,00
	INT 16H
	;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv;

	;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^;
	;Switch to graphics mode
	;640*480 Resolution 16 Colors
	;Buffer is located at A0000h
	MOV AL,12H
	MOV AH,00H
	INT 10H
	CALL DispImgs
	
	
	
	;Main Loop Doing The Mouse Action
	;Accepts two Mouse Left Clicks to draw the gate
	;Maximum 20 Gate is allowed [# of Rows in Screen Matrix]
	;To Escape Drawing Action ESC Must be pressed

	;;; Main Mouse Action Loop ;;; 
	;Initialize The Mouse and The Serial Communications
	CALL InitMouse 
	CALL InitSer
	

	;If Keyboard buffer is empty then continue in loop 
	;Otherwise Remove the character in buffer and compare it 
	;with the ESC ASCII Code 

	MOV ElemNum,00h
	MOV WireNum,00h
		
MsLp:

	MOV AH,01      ;check the status of the keyboard buffer 
	INT 16h       
    JZ ContMsLp    ;if ZF=1 No waiting characters in the buffer Continue Mouse Loop
	
	MOV AH,0       ;read the character from the keyboard buffer 
	INT 16H
	CMP AL,'a'
	JNE ContMsLp
	JMP  Ret2DOS
ContMsLp:
	
	;Read Mouse Position and Decide Whether
	;to set it to DrawGate or DrawWire or Simulate 
		
	GetleftClck 
	MOV IconNum,0FFH
		ChkClk 0 
		ChkClk 1
		ChkClk 2 
		ChkClk 3 
	;Draw Gate 
	;Icon Image Coordinates Start at (x=75*6,y=0) to (x=75*6+40,y=50)
		CMP IconNum,00
		JNE TstIfDrwW
		CALL DrawGate
		
	;Draw Wire  
	;Icon Image Coordinates Start at (x=75*6,y=0) to (x=75*6+40,y=50)
	TstIfDrwW:
		CMP IconNum,1
		JNE TstIfRun
		CALL DrawWire
	TstIfRun:
		CMP IconNum,2
		JNE TstIfSend
		CALL Simulate
	TstIfSend :
		;_______ Serial Communications Part [Send the Simulation Results File]
		CMP IconNum,3
		JNE MsLpE
		CALL SndFile	
	MsLpE:

		MOV  DX,3FDh        ;Line status register
		In   AL,DX

		TEST AL,00000001b ; Test if DR=1
		JZ EE             ;Jump if zero [DR=0] No data is ready to be picked up ;Continue Loop
		CALL RecFile
	EE:
	JMP MsLp


	;Wait 1 Second before the end
	;MOV     CX, 0FH
	;MOV     DX, 4240H
	;MOV     AH, 86H
	;INT     15H
Ret2DOS:
	;Set the Video Mode [Text Mode]
	;VGA Card 80*25   9*16 ResPerChar
	MOV AL,03H
	MOV AH,00H
	INT 10H
	;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv;

	;;;;;;;;;;;;;;;;;;;;;;;
	;Return to DOS
	MOV AH,4CH
	INT 21H
Main_prog endp
;____________________________
RETURN PROC
	;Read Returned Strings from the stack
	MOV BP,SP
	MOV CX,22
	;Transfer UserM
	MOV SI,00
	MOV DI,44+2
TRA1:
	MOV AL,[BP+DI]
	MOV UserName1[SI],AL
	DEC DI
	INC SI
	LOOP TRA1
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	MOV CX,22
	;Transfer UserM
	MOV SI, 00
	MOV DI,22+2
TRA2:
	MOV AL,[BP+DI]
	MOV FileName1 [SI], AL
	INC SI
	DEC DI
	LOOP TRA2
	RET 44
;44 is mandatory to ensure that stack is empty
;otherwise this will make stak leaks and leads to stack overflow
RETURN ENDP
;____________________________
ClrScr PROC
	
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX	
	MOV AH,06h
	MOV AL,00
	MOV BH,72H
	MOV CL,00
	MOV CH,00
	MOV DL,79
	MOV DH,24
	INT 10H
	POP DX
	POP CX
	POP BX
	POP AX
RET
ClrScr ENDP

InitMouse PROC
;Initialize the mouse 
	MOV AX,00;Note here in mouse interrupt specify the subfunction by AX not AH Only
	INT 33H  ;Initilaization didn't work correctly when AH only is set to 0
	CMP AX,0FFFFH
	JE M
	MOV AH,9
	LEA DX,ErrMmouse
	INT 21H
	RET	
M:  RET 
InitMouse ENDP

InitSer proc near

mov dx,3FBh            ;Address of line control register
mov al,10000000b       ;Data to be outputted on LCR =1000 0000 [To make DLAB=1]
Out dx,al              ;OUT DX,AL   Put Data on AL on the port of address DX

mov dx,3F8h            ;Divisor Latch Low [DLAB=1]
mov al,0Ch              
Out dx,al

mov dx,3F9h            ;Divisor Latch High [DLAB=0]
mov al,0
Out dx,al
;Divisor = 00 0C ; The Baud Rate =9600

mov dx,3FBh              ;Return to LCR
mov al,00011011b         ;Data =8 bit - 1 stop bit - even parity
Out dx,al

ret
InitSer endp


;____________________________

Code_segment_name ends
        end Main_prog