EXTRN ANDArr:BYTE,NANDArr:BYTE
EXTRN ORArr:BYTE ,NORArr:BYTE
EXTRN XORArr:BYTE,XNORArr:BYTE

EXTRN Screen:WORD
EXTRN ElemNum:WORD

PUBLIC DrawGate

DISPIM1 MACRO SR,SC,dArr
	;Display the AND Gate
	MOV SI,SC;Start Column Pixel
	MOV DX,SR;Start Row Pixel
	LEA DI,dArr+2 ;image data strats from here 
	PUSH DS
	MOV DS,MainDS
	MOV AL,dArr
	MOV AH,dArr+1
	POP DS
	MOV MaxR,AL
	MOV MaxC,AH
	CALL DispFile1
	  ENDM
	  
ChkClk MACRO i
	LOCAL E
	LOCAL T1
	LOCAL T2

	CMP CX,75*i ; CX is the horizontal position [x coordinate]
	JA T1
	JMP RT1
T1:	CMP CX,75*i+70
	JA E
	CMP ClickNum,2 
	JNE T2
	JMP  RT1
T2:	MOV ItemNum,i
	JMP LOP
E:
 ENDM
	
MULBY14 MACRO   j;Macro doesn't affect AX ; Only Mul Res in SI
	PUSH AX
    MOV  AX,j
	MOV  SI,AX
	ADD  AX,AX;AX=2*j
	ADD  AX,AX ;AX=4*j
	ADD  SI,SI;SI=2*j
	ADD  SI,SI;SI=4*j
	ADD  SI,SI;SI=8*j
	ADD  SI,AX;SI=8*j+4*j=12*j
	ADD SI,j  ; SI=12*j+j=13*j
	ADD SI,j
	POP AX
ENDM

	
Data_segment_name_DrawGate segment para
ORG 10H
;Counters i,j
COUNT_I    DB ?
COUNT_J    DB ? 
BufAdd DW ?
MaxR DB ?
MaxC DB ?
MainDS  DW ?
ErrM DB 'The mouse is is not available',0DH,0AH,'$'
ClickNum DB ?
ItemNum DW ?
MaxX DW 640
MaxY DW 480
Data_segment_name_DrawGate ends

Stack_segment_name segment para stack
db 64 dup(0) ;define your stack segment
Stack_segment_name ends


Code_segment_name segment
DrawGate PROC FAR
assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name_DrawGate

	;;;;;;;;;;;;;;;; Module Specific
	
	PUSH DS
	MOV CX,DS;Needed to pass variables through RAM it will be stored in CX then in MainDS after changing DS to current Procedure DS

	MOV AX,Data_segment_name_DrawGate ; load the starting address of the data
	MOV DS,AX ; segment into DS reg.
	MOV MainDS,CX;
	;;;;
	;Get the mouse location
	;Scenario [To be enhanced ]
	;1-If the user is not press right click then loop till he does so
	;2-If the clicked area is not on the tool bar then return
	;3-If the clicked area is in the tool bar then request another click outside the tool bar to draw the first clicked item
	MOV ClickNum,0
	
	MOV AX,01H;Display the mouse pointer
	INT 33H
LOP:
    MOV BX,00H
	MOV AX,5H
	INT 33H
	;Test if the right button is clicked
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
	CMP DX,50
	JB mbchk ; MenuBar Check  [short jump to return is disallowed as Out of range by 56 bytes]
	JMP  drw;If second click then draw ItemNum
mbchk:
	ChkClk 0
	ChkClk 1	
	ChkClk 2
	ChkClk 3
	ChkClk 4
	ChkClk 5
	;If 0<=vertical pos(y)<=50 and Not item selected[in first or in second click] Exit
RT1:  
	JMP RT
drw:

	CMP ClickNum,2
	JNE RT1
	CMP ItemNum,0
	JNE C1
	DISPIM1 DX,CX,ANDArr
	JMP iRT
C1:	CMP ItemNum,1
	JNE C2
	DISPIM1 DX,CX,NANDArr
	JMP iRT
C2:	CMP ItemNum,2
	JNE C3
	DISPIM1 DX,CX,ORArr
	JMP iRT
C3:	CMP ItemNum,3
	JNE C4
	DISPIM1 DX,CX,NORArr
	JMP iRT
C4:	CMP ItemNum,4
	JNE C5
	DISPIM1 DX,CX,XORArr
	JMP iRT
C5:	CMP ItemNum,5
	JNE RT
	DISPIM1 DX,CX,XNORArr
iRT : ;Increment then return
	PUSH DS 
	MOV DS,MainDS
	INC ElemNum
	POP DS 
	
RT:
	;;;;
	;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv;
	POP DS
	;;;;;;;;;;;;;;;;; Module Specific End
	RETF ; RET Will Make a near return   
DrawGate  ENDP

DispFile1 PROC

	MOV AX,02H;Hide the mouse pointer
	INT 33H

	MOV CX,SI
	
	;____________________________ Adjusting Screen+(ElemNum*6) in main
	;____________________________i.e. storing the draw logic gate
	
	PUSH SI;Save the Starting Row Number Passed to the procedure
	PUSH DI;Save DI :Address of binary image passed to the procedure
	PUSH DS
	;________
	;Here  CX,DX aren't subject ti any changes
	MOV  DI,ItemNum;Type
	MOV  DS,MainDS
	LEA  BX,Screen
	;____________________________
	;________   Validate the drawing Area
	;________   Actually we are here because the second click
	;________   is not in the menu bar
	;  Iterate Over All Previous Screen 
	MOV AX,00
PrevScr:
	MULBY14 AX ;SI=14*AX
	;Accept if Distance in X >=70 Or Distance in y>=50
	;|CX-x| >=70 ?
	;Get |CX -x | first 
	PUSH AX 
	MOV AX,[BX+SI];current x in loop 
	CMP AX,CX ; 
	JB NG
	SUB AX,CX ; AX=|CX-x|=(x-CX) 
	JMP CMP70
NG: SUB AX,CX
    NEG AX   ;	AX=|CX-x|=-(x-CX)
CMP70:
	CMP AX,70 
	JA OK
	;;;
	MOV AX,[BX+SI+2];current y in loop 
	CMP AX,DX ; 
	JB NG1
	SUB AX,DX ; AX=|DX-y|=(y-DX) 
	JMP CMP50
NG1: SUB AX,DX
    NEG AX   ;	AX=|CX-x|=-(x-CX)
CMP50:
	CMP AX,50 
	JA OK
	;Otherwise Decrement ElemNum as actually nothing is drawing
	;the Return [Does n't Draw Anything]
	;DEC ElemNum
	;Stack must be deallocated before return 
	POP AX
	POP DS
	POP DI
	POP SI	
	RET  
OK:	
	POP AX
	INC AX
	CMP AX,ElemNum
	JB PrevScr
	;___________ Validate Loop End
	
	MULBY14 ElemNum ;Result in SI=6*ElemNum
	MOV [BX+SI],CX
	MOV [BX+SI+2],DX
	MOV [BX+SI+4],DI
	MOV DI,ElemNum
	MOV [BX+SI+12],DI
	

	POP DS
	POP DI
	POP SI
	;DI Contains offest to the binary image
	;MaxR and MaxC contains the number of rows and columns
	;____________________________
	;____________________________
	MOV AL,MaxR
	MOV COUNT_I,AL  ; i= number of rows in image
	;CX and DX are set to the starting pixels
	;Outer Loop Start
L1:	
	MOV AL,MaxC
	MOV COUNT_J,AL  ; j = number of columns in image 
	;Inner loop Start
	L2:	
	PUSH DS;Push Procedure Ds
	MOV DS,MainDS
	CMP BYTE PTR [DI],'1'
	JNE P0
	MOV AL,0Fh
	JMP DP
P0:	MOV AL,0F0H
DP:	MOV BH,00H
	MOV AH,0CH
	INT 10H
	POP DS
	INC DI
	INC CX
	DEC COUNT_J
	JNZ L2
	;Inner loop end
	INC DX
	MOV CX,SI
	DEC COUNT_I
	JNZ L1
	
	RET
DispFile1 ENDP
;____________________________

Code_segment_name ends
end

;____________________________
