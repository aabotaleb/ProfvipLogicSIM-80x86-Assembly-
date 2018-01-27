EXTRN ANDArr:BYTE,NANDArr:BYTE
EXTRN ORArr:BYTE ,NORArr:BYTE
EXTRN XORArr:BYTE,XNORArr:BYTE
EXTRN SendArr:BYTE,RunArr:BYTE
EXTRN DrawGArr:BYTE,DrawWArr:BYTE

PUBLIC DispImgs

DISPIM MACRO SR,SC,dArr
	;Display the AND Gate
	MOV SI,SC;Start Column Pixel
	MOV DX,SR;Start Rwo Pixel
	LEA DI,dArr+2 ;image data strats from here 
	PUSH DS
	MOV DS,MainDS
	MOV AL,dArr
	MOV AH,dArr+1
	POP DS
	MOV MaxR,AL
	MOV MaxC,AH
	CALL DispFile
	  ENDM

Data_segment_name_DispImgs segment para
ORG 10H
;Counters i,j
COUNT_I    DB ?
COUNT_J    DB ?
Back DB ?
Fore DB ? 
BufAdd DW ?
MaxR DB ?
MaxC DB ?
MainDS  DW ?

Data_segment_name_DispImgs ends

Stack_segment_name segment para stack
db 64 dup(0) ;define your stack segment
Stack_segment_name ends


Code_segment_name segment
DispImgs PROC FAR
assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name_DispImgs

	;;;;;;;;;;;;;;;; Module Specific
	
	PUSH DS
	MOV CX,DS;Needed to pass variables through RAM it will be stored in CX then in MainDS after changing DS to current Procedure DS

	MOV AX,Data_segment_name_DispImgs ; load the starting address of the data
	MOV DS,AX ; segment into DS reg.
	MOV MainDS,CX;
	;;;;;;;;;;;;;;
	MOV Back,0F0H
	MOV Fore,0FH
	;;;;;;;;;;;;;;
	;Display the AND Gate	
	DISPIM 00,00,ANDArr
	;Display rest of gates
	DISPIM 00,75,NANDArr
	DISPIM 00,75*2,ORArr
	DISPIM 00,75*3,NORArr
	DISPIM 00,75*4,XORArr
	DISPIM 00,75*5,XNORArr
	;;;;;;;;;;;;;;
	MOV Back,044H
	MOV Fore,66H
	;;;;;;;;;;;;;;
	DISPIM 00,75*6,DrawGArr
	DISPIM 00,75*6+45,DrawWArr
	DISPIM 00,75*6+45*2,RunArr
	DISPIM 00,75*6+45*3,SendArr

	;;;;
	;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv;
	POP DS
	;;;;;;;;;;;;;;;;; Module Specific End
	RETF ; RET Will Make a near return   
DispImgs  ENDP
DispFile PROC

	;DI Contains offest to the binasry image
	;MaxR and MaxC contains the number of rows and columns
	MOV CX,SI
	
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
	
	POP DS 
	MOV AL,Fore
	PUSH DS 
	MOV DS,MainDS
	
	
	JMP DP

P0:	POP DS
	MOV AL,Back
	PUSH DS 
	MOV DS,MainDS
	
DP:	MOV BH,00
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
DispFile ENDP
;____________________________

Code_segment_name ends
end

;____________________________
