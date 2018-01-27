EXTRN Screen:WORD
EXTRN ElemNum:WORD
EXTRN Wires: WORD
EXTRN WireNum:WORD
PUBLIC DrawWire

SetWire MACRO X,i,Y,j,t,SeqNum
	LOCAL Skp
	LOCAL C1
	LOCAL S1

	;Set Wire Params
	LEA BX,Wires
	MOV AL,1
	CMP AL,t
	JB Skp
	MOV AX,SeqNum
	MOV [BX],AX
	MOV WORD PTR [BX+4],t
	JMP C1
Skp:MOV AX,SeqNum
	MOV [BX+2],AX
C1:	POP AX ;Deallocate Stack
	POP DS;
	MOV AX,i
	MOV X,AX
	MOV AX,j
	MOV Y,AX

	MOV AL,1
	CMP AL,t	
	JB S1
	MOV MOVT,t
	JMP LOP ;Goto Accept the second click   	 
S1:	JMP Drw ;Draw the Current Wire   	 
	ENDM

	
Data_segment_name_DrawWire segment para
ORG 10H
;Counters i,j
COUNT_I    DB ?
COUNT_J    DB ? 
X1 DW ?
Y1 DW ? 
X2 DW ?
Y2 DW ?
MOVT DB ?
MainDS  DW ?
ErrM DB 'The mouse is is not available',0DH,0AH,'$'
ClickNum DB ?

MaxX DW 640
MaxY DW 480
Data_segment_name_DrawWire ends

Stack_segment_name segment para stack
db 64 dup(0) ;define your stack segment
Stack_segment_name ends


Code_segment_name segment
DrawWire PROC FAR
assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name_DrawWire

	;;;;;;;;;;;;;;;; Module Specific
	
	PUSH DS
	MOV CX,DS;Needed to pass variables through RAM it will be stored in CX then in MainDS after changing DS to current Procedure DS

	MOV AX,Data_segment_name_DrawWire ; load the starting address of the data
	MOV DS,AX ; segment into DS reg.
	MOV MainDS,CX;
	;;;;
		
M:  MOV AX,01H;Display the mouse pointer
	INT 33H
	;Get the mouse location
	;Scenario [To be enhanced ]
	;1-If the user is not press left click then loop till he does so
	;2-If the clicked area is not on the tool bar then return
	;3-If the clicked area is in the tool bar then request another click outside the tool bar to draw the first clicked item
	MOV ClickNum,0
LOP:
    MOV BX,00H
	MOV AX,5H
	INT 33H
	;Test if the left button is clicked
	;Select the Gate if Vertical position is between 0 and 50 
	CMP BX,00000001B;Accept the left click[any other center-right clicks are masked]
	JB   LOP
	INC ClickNum ; Mouse is already clicked 	
	;Check first the Vertical position
	CMP DX,00
	JA Tstloc ;Test StatusBar Location
	JMP RT ;JNA RT would be out of range by 313 bytes [not be short jump]
Tstloc:
	MOV AX,MaxY
	SUB AX,75;//Account for Status Bar height=25
	CMP DX,AX
	JB Tmbloc ;Test MenuBar location
	JMP RT
Tmbloc:	
	CMP DX,50;
	JA t1 ; MenuBar Check  [short jump to return is disallowed as Out of range by 56 bytes]
	JMP RT
t1:
	CMP ClickNum,1
	JE CONT
	JMP t2
CONT:
	;Save Wire Source ElemNum
	;Iterate over all Screen Logic Gates 
	;__________________________   First Click Logic    ____________________________	
	PUSH DS 
	MOV DS,MainDS
	MOV AX,ElemNum ; Max Number of present Gates
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	MOV SI,00 ;Point to start of Screen Array
LOPMain:	
	PUSH AX ; AX Subject to change
	LEA BX,Screen
	MOV AX,[BX+SI];Save x coordinate in AX
	SUB AX,CX
	NEG AX ; AX =CX-x coord
	CMP AX,35
	JBE CONT1
	JMP Outlet
CONT1:
	MOV AX,[BX+SI+2];Save Y coordinate in AX
	SUB AX,DX
	NEG AX ; AX =DX-y coord
	CMP AX,25 
	JBE fstInlt;Jump to first inlet check if DX-y <=25
	CMP AX,50
	jbe cont2
	JMP LOPElms;Skip to next element if DX-y  not <=50 
    ; Here assign the wire to begin from the second element inlet
	;if it's previuosly = FFFF h (not connected before)
cont2:
	CMP [BX+SI+8],0FFFFH
	JE add1 
	; If mouse click at second input terminal prevoisly connected then return
	POP AX
	POP DS 
	JMP RT
add1:
	MOV AX,WireNum
	MOV [BX+SI+8],AX
	MOV CX,[BX+SI]
	MOV DX,[BX+SI+2]
	ADD DX,40
	MOV BP,[BX+SI+12]
	SetWire  X1,CX,Y1,DX,0,BP
	;;;;;;;;;;;;;;;;;;;;;;
	; Here assign the wire to begin from the first element inlet
	;if it's previuosly = FFFF h (not connected before)
fstInlt:	
	CMP [BX+SI+6],0FFFFH
	JE add2 
	; If mouse click at first input terminal prevoisly connected then return
	POP AX
	POP DS 
	JMP RT
add2:
	MOV AX,WireNum
	MOV [BX+SI+6],AX
	;Set Wire Params
	MOV CX,[BX+SI]
	MOV DX,[BX+SI+2]
	ADD DX,10
	MOV BP,[BX+SI+12]
	SetWire  X1,CX,Y1,DX,0,BP
Outlet:
    CMP AX,70
	JA LOPElms;Skip to next element if CX-x  not <=70
	MOV AX,[BX+SI+2];Save Y coordinate in AX
	SUB AX,DX
	NEG AX ; AX =DX-y coord
	CMP AX,50
	JA LOPElms;Skip to next element if DX-y  not <=50
	;;;;;;;;;;;;;;;;;;;;;;
	; Here assign the wire to begin from the element outlet
	;if it's previuosly = FFFF h (not connected before)
	CMP [BX+SI+10],0FFFFH
	JE add3 
	; If mouse click at output terminal prevoisly connected then return
	POP AX
	POP DS 
	JMP RT
add3:
	MOV AX,WireNum
	MOV [BX+SI+10],AX
	MOV CX,[BX+SI]
	ADD CX,70
	MOV DX,[BX+SI+2]
	ADD DX,25
	MOV BP,[BX+SI+12]
	SetWire  X1,CX,Y1,DX,1,Bp

LOPElms:	
	ADD SI,14
	POP AX 
	DEC AX
	JZ EXT
	JMP LOPMain
EXT:
	POP DS
	
	;______________________________________________________
    ;;; if first click not on any of the avilable elements then return 
	JMP RT
	;__________________________   Second Click Logic    ____________________________
t2:

	PUSH DS 
	MOV DS,MainDS
	MOV AX,ElemNum ; Max Number of present Gates
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	MOV SI,00 ;Point to start of Screen Array
LOPMain2:	
	PUSH AX ; AX Subject to change
	LEA BX,Screen
	MOV AX,[BX+SI];Save x coordinate in AX
	SUB AX,CX
	NEG AX ; AX =CX-x coord
	CMP AX,35 
	jbe cont3
	Jmp LOPElms2;Skip to next element
cont3:
	MOV AX,[BX+SI+2];Save Y coordinate in AX
	SUB AX,DX
	NEG AX ; AX =DX-y coord
	CMP AX,25 
	JBE fstInlt2;Jump to first inlet check if DX-y <=25
	CMP AX,50
	JBE CONT4
	JMP LOPElms2;Skip to next element if DX-y  not <=50 
    ; Here assign the wire to begin from the second element inlet
	;if it's previuosly = FFFF h (not connected before)
CONT4:
	CMP [BX+SI+8],0FFFFH
	JE add12 
	; If mouse click at second input terminal prevoisly connected then return
	POP AX
	POP DS 
	JMP RT
add12:
	MOV AX,WireNum
	MOV [BX+SI+8],AX
	MOV CX,[BX+SI]
	MOV DX,[BX+SI+2]
	ADD DX,40
	MOV BP,[BX+SI+12]
	SetWire  X2,CX,Y2,DX,2,BP
	;;;;;;;;;;;;;;;;;;;;;;
	; Here assign the wire to begin from the first element inlet
	;if it's previuosly = FFFF h (not connected before)
fstInlt2:	
	CMP [BX+SI+6],0FFFFH
	JE add22 
	; If mouse click at first input terminal prevoisly connected then return
	POP AX
	POP DS 
	JMP RT
add22:
	MOV AX,WireNum
	MOV [BX+SI+6],AX
	;Set Wire Params
	MOV CX,[BX+SI]
	MOV DX,[BX+SI+2]
	ADD DX,10
	MOV BP,[BX+SI+12]
	SetWire  X2,CX,Y2,DX,2,Bp
LOPElms2:	
	ADD SI,14
	POP AX 
	DEC AX
	JZ EXT1
	JMP LOPMain2
EXT1:
	POP DS
	
	;______________________________________________________
    ;;; if first click not on any of the avilable elements then return 
	JMP RT
	
		
Drw: 
	
	PUSH DS 
	MOV DS,MainDS
	INC WireNum
	POP DS 
	
	 CMP MOVT,1
     JNE D
     CALL DrawLine1
	 JMP RT
D:   CALL DrawLine0
RT:

	;;;;
	;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv;
	POP DS
	;;;;;;;;;;;;;;;;; Module Specific End
	RETF ; RET Will Make a near return   
DrawWire  ENDP

DrawLine1  PROC  ;for MOVT=1
	
	;If X1 less than X2 Then draw Horiz then Vert lines
	MOV BP,X1
	CMP BP,X2
	JA VthenH
	;Draw the horiz Line
Drwh1 :
	MOV AL,0FH
	MOV BH,00H
	MOV CX,BP
	MOV DX,Y1
	MOV AH,0CH
	INT 10H
	INC BP
	CMP BP,X2
	JB Drwh1
	
	MOV BP,Y1
	CMP BP,Y2 ; If Y1<Y2 
	JA DrwV12
DrwV11 :
	MOV AL,0FH
	MOV BH,00H
	MOV CX,X2
	MOV DX,BP
	MOV AH,0CH
	INT 10H
	INC BP
	CMP BP,Y2
	JB DrwV11
	RET
DrwV12 :
	MOV AL,0FH
	MOV BH,00H
	MOV CX,X2
	MOV DX,BP
	MOV AH,0CH
	INT 10H
	DEC BP
	CMP BP,Y2
	JB DrwV11
	RET

VthenH:
	MOV BP,X1
	;First Draw Short Horiz line
L:	MOV AL,0FH
	MOV BH,00H
	MOV CX,BP
	MOV DX,Y1
	MOV AH,0CH
	INT 10H
	INC BP
	MOV AX,X1
	ADD AX,10
	CMP BP,AX
	JB L


	MOV BP,Y1
	CMP BP,Y2  
	JA DrwV22
DrwV21 :; If Y1<Y2
	MOV AX,X1
	ADD AX,10
	MOV CX,AX	
	MOV AL,0FH
	MOV BH,00H
	MOV DX,BP
	MOV AH,0CH
	INT 10H
	INC BP
	CMP BP,Y2
	JB DrwV21
	jmp DrwH2
DrwV22 :
	MOV AX,X1
	ADD AX,10
	MOV CX,AX
	MOV AL,0FH
	MOV BH,00H
	MOV DX,BP
	MOV AH,0CH
	INT 10H
	DEC BP
	CMP BP,Y2
	JB DrwV21

MOV BP,X1
ADD BP,10
	
DrwH2 :
	MOV AL,0FH
	MOV BH,00H
	MOV CX,BP
	MOV DX,Y2
	MOV AH,0CH
	INT 10H
	DEC BP
	CMP BP,X2
	JB DrwV21
RET
DrawLine1  ENDP


DrawLine0  PROC  ;for MOVT=0
	
	;If X1 less than X2 Then draw Horiz then Vert lines
	MOV BP,X1
	CMP BP,X2
	JA V0thenH
	;Draw the horiz Line
D0rwh1 :
	MOV AL,0FH
	MOV BH,00H
	MOV CX,BP
	MOV DX,Y1
	MOV AH,0CH
	INT 10H
	INC BP
	CMP BP,X2
	JB D0rwh1
	
	MOV BP,Y1
	CMP BP,Y2 ; If Y1<Y2 
	JA D0rwV12
D0rwV11 :
	MOV AL,0FH
	MOV BH,00H
	MOV CX,X2
	MOV DX,BP
	MOV AH,0CH
	INT 10H
	INC BP
	CMP BP,Y2
	JB D0rwV11
	RET
D0rwV12 :
	MOV AL,0FH
	MOV BH,00H
	MOV CX,X2
	MOV DX,BP
	MOV AH,0CH
	INT 10H
	DEC BP
	CMP BP,Y2
	JB D0rwV11
	RET

V0thenH:
	MOV BP,X1
	;First Draw Short Horiz line
L0:	MOV AL,0FH
	MOV BH,00H
	MOV CX,BP
	MOV DX,Y1
	MOV AH,0CH
	INT 10H
	INC BP
	MOV AX,X1
	ADD AX,10
	CMP BP,AX
	JB L0


	MOV BP,Y1
	CMP BP,Y2  
	JA D0rwV22
D0rwV21 :; If Y1<Y2
	MOV AX,X1
	ADD AX,10
	MOV CX,AX	
	MOV AL,0FH
	MOV BH,00H
	MOV DX,BP
	MOV AH,0CH
	INT 10H
	INC BP
	CMP BP,Y2
	JB D0rwV21
	jmp D0rwH2
D0rwV22 :
	MOV AX,X1
	ADD AX,10
	MOV CX,AX
	MOV AL,0FH
	MOV BH,00H
	MOV DX,BP
	MOV AH,0CH
	INT 10H
	DEC BP
	CMP BP,Y2
	JB D0rwV21

MOV BP,X1
ADD BP,10
	
D0rwH2 :
	MOV AL,0FH
	MOV BH,00H
	MOV CX,BP
	MOV DX,Y2
	MOV AH,0CH
	INT 10H
	DEC BP
	CMP BP,X2
	JB D0rwV21
RET
DrawLine0  ENDP




Code_segment_name ends
end

;____________________________
