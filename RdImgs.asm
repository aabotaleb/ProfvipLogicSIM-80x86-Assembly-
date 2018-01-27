EXTRN ANDArr:BYTE,NANDArr:BYTE
EXTRN ORArr:BYTE ,NORArr:BYTE
EXTRN XORArr:BYTE,XNORArr:BYTE
EXTRN SendArr:BYTE,RunArr:BYTE
EXTRN DrawGArr:BYTE,DrawWArr:BYTE

RDIM MACRO  dArr,dfName  
	;Adjust Error and Success Messages to cope with the read file name
	;;
	LEA DX,dfName
	CALL ADJUST ; Input Param = DS:Source file Name
	;;
	PUSH DS;Push Procedure Ds
	MOV DS,MainDS
	MOV AL,dArr
	MOV AH,dArr+1
	LEA DI,dArr+2;Actual Data must be stored here
	POP DS
	MOV MaxR,AL
	MOV MaxC,AH
	MOV BufAdd,DI
	CALL ReadFile ; Input Params are MaxR,MaxC,BufAdd[Offset to the buffer in main DS]
    ENDM
	
Data_segment_name_RDImages segment para
ORG 10H
;File Reading Data
FileRDErrMsg1 DB 8 DUP(?),' read failure due to invalid function number',0ah,0dh,'$'
FileRDErrMsg2 DB 8 DUP(?),' read failure due to invalid file Name',0ah,0dh,'$'
FileRDErrMsg3 DB 8 DUP(?),' read failure due to invalid path',0ah,0dh,'$'
FileRDErrMsg4 DB 8 DUP(?),' read failure due to unavailable handle',0ah,0dh,'$'
FileRDErrMsg5 DB 8 DUP(?),' read failure due to access denied',0ah,0dh,'$'
FileRDErrMsgC DB 8 DUP(?),' read failure due to invalid Access code',0ah,0dh,'$'
FileRDErrMsgU DB 8 DUP(?),' read failure due to Undefined Reason',0ah,0dh,'$'
FileRDErrMsgP DB 8 DUP(?),' read failure during the process',0ah,0dh,'$'
FileRDSuccess DB 8 DUP(?),' is Successfully read ',0ah,0dh,'$'
FileHandler   DW ?
ANDfName      DB 'AND .txt',00
NANDfName     DB 'NAND.txt',00
ORfName       DB 'OR  .txt',00
NORfName      DB 'NOR .txt',00
XORfName      DB 'XOR .txt',00
XNORfName     DB 'XNOR.txt',00
SendfName     DB 'Send.txt',00
RunfName      DB 'Run .txt',00 
DrawGfName    DB 'DrwG.txt',00
DrawWfname    DB 'DrwW.txt',00

MainDS  DW ?

LF DB ?
COUNT_I    DB ?
BufAdd DW ?
MaxR DB ?
MaxC DB ?
Data_segment_name_RDImages ends

Stack_segment_name segment para stack
db 64 dup(0) ;define your stack segment
Stack_segment_name ends

PUBLIC RdImgs
Code_segment_name segment

RdImgs PROC FAR
assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name_RDImages

	;;;;;;;;;;;;;;;; Module Specific
	;;;;; Type : Return from Module to Main
	
	PUSH DS
	MOV CX,DS;Needed to pass variables through RAM it will be stored in CX then in MainDS after changing DS to current Procedure DS
	
	;Save BP,DS ;any changes to BP,DS here 
	;shouldn't reflect main program

	MOV AX,Data_segment_name_RDImages ; load the starting address of the data
	MOV DS,AX ; segment into DS reg.
	MOV MainDS,CX;
	;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	RDIM 	ANDArr ,ANDfName	
	RDIM 	NANDArr,NANDfName	
	RDIM 	ORArr  ,ORfName	
	RDIM 	NORArr ,NORfName	
	RDIM 	XORArr ,XORfName	
	RDIM 	XNORArr,XNORfName	
	
	RDIM 	RunArr,RunfName	
	RDIM 	DrawGArr,DrawGfName	
	RDIM 	DrawWArr,DrawWfName	
	RDIM 	SendArr,SendfName	
	
		
	;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv;
	POP DS
	;;;;;;;;;;;;;;;;; Module Specific End
	RETF ; RET Will Make a near return   
RdImgs  ENDP
ReadFile PROC
	;DS:DX =Address of ASCIIZ path [Terminated by zero byte]
	;DS,DX Should be set proprely before calling this procedure
	;1-Open file for read [Obtian the file handler]
	MOV AL,0 ;Mode flag is Read
	MOV AH,3DH 
	INT 21H
	JNC RD
	CMP AX,1
	JNE ChkErr2
	LEA DX,FileRDErrMsg1
	MOV AH,09H
	INT 21H
	RET
ChkErr2:
	CMP AX,2
	JNE ChkErr3
	LEA DX,FileRDErrMsg2
	MOV AH,09H
	INT 21H
	RET
ChkErr3:
	CMP AX,3
	JNE ChkErr4
	LEA DX,FileRDErrMsg3
	MOV AH,09H
	INT 21H
	RET
ChkErr4:
	CMP AX,4
	JNE ChkErr5
	LEA DX,FileRDErrMsg4
	MOV AH,09H
	INT 21H
	RET
ChkErr5:
	CMP AX,4
	JNE ChkErrC
	LEA DX,FileRDErrMsg5
	MOV AH,09H
	INT 21H
	RET
ChkErrC:
	CMP AX,4
	JNE ChkErrU
	LEA DX,FileRDErrMsgC
	MOV AH,09H
	INT 21H
	RET
ChkErrU:
	LEA DX,FileRDErrMsgU
	MOV AH,09H
	INT 21H
	RET
RD: 
	MOV FileHandler,AX
	;Read the actual number of rows
	;MOV CX,1
	;MOV BX,FileHandler
	;LEA DX,ANDArr
	;MOV AH,3FH
	;INT 21H
	;Read the actual number of columns
	;MOV CX,1
	;MOV BX,FileHandler
	;LEA DX,ANDArr+1
	;MOV AH,3FH
	;INT 21H
	;Read the actual data
	;Each time at most one line could be read
	;So Inside a loop of size ANDArr=#of rows
	;the ANDArr buffer is read starting from address 
	;DI=ANDArr+2 And each time DI is incremented by ANDArr+1 positions
	;;;;;;;;;;;;;;;;;;;
	
	
	MOV AL,MaxR
	MOV COUNT_I,AL
	MOV DI,BufAdd
L:	
	MOV CL,MaxC
	MOV CH,00H
	MOV BX,FileHandler
	;PERCAUTION : HERE IS THE ONLY NEED TO SWITCH TO MAIN DS
	PUSH DS;Save the current procedure DS
	MOV DS,MainDS ; Data is Readed into main data segment
	MOV DX,DI
	MOV AH,3FH
	INT 21H
	JC failP
	ADD DI,CX;Provided that CX isn't changed due to the interrupt
	POP DS; Return to the procedure data segment
	MOV CX,1 ;Read the LF character
	LEA DX,LF
	MOV AH,3FH
	INT 21H
	CMP LF,0AH
	JNE failP
	DEC COUNT_I
	JNZ L
	;;;;;;;;;;;;;;;;;;;;
	LEA DX,FileRDSuccess
	MOV AH,09H
	INT 21H
	RET
failP:	
	POP DS; Return to the procedure data segment
	LEA DX,FileRDErrMsgP
	MOV AH,09H
	INT 21H
	RET
ReadFile ENDP

ADJUST PROC
	MOV AX,DS
	MOV ES,AX
	CLD
	MOV SI,DX ; Source file name is passed through DX Register
	LEA DI,FileRDSuccess
	MOV CX,8
	REP MOVSB
	;Above 4 lines must be repeated for all other error messages [MACRO Should be a better idea]
	RET
ADJUST ENDP


Code_segment_name ends
end