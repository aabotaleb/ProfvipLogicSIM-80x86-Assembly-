PUBLIC RecFile2
EXTRN WireValA:BYTE ;Needed by RecFile2
EXTRN UsrInCnt:WORD
EXTRN OtCnt:WORD
EXTRN OtTot:WORD
EXTRN TotComb:WORD
EXTRN TTableA:BYTE 
EXTRN SimDS:WORD 
Data_segment_name_RecFile2 segment para
FileNameR  DB 'Rec2.txt',00
FileCrErr  DB 'File Creation Fauilre - Unknown Error ','$'
FilePnfErr DB 'File Creation Fauilre - Path Not Found','$'
FileADErr  DB 'File Creation Fauilre - Access Denied ','$'


temp1  db    ? 
LF      DB 0AH 
SLASH   DB ' - '
MainDS  DW ?
SimuDS DW ?
COUNT_I DW 0

FileHandler DW ?

TotCombR DW 17
WireNumR DW 17
ElemNumR DW 17

LFR      DB 0AH
SlashR   DB ' - '


UsrInCntR DW ?
OtTotR DW ?
OtCntR dw ?

TTableAR DB  512 DUP (20 DUP('h'))
WireValAR DB 512 DUP (20 DUP ('T'))

WriteGCount DB 'Gate Count = ',?,?;15 Charcters
WriteWCount DB 'Wire Count = ',?,?;15 Charcters
WriteTotCom DB 'Total Combinations = ',?,?,?;24 characters
WriteUsrInCount DB 'Total User In Variables = ',?,?,?;29 characters
WriteOtCnt      DB 'Total User Output Variables = ',?,?;32 characters
WriteOtTot      DB 'Total Output Variables =',?,?;26 Characters

Data_segment_name_RecFile2 ends

Stack_segment_name segment para stack
dw 16 dup(0) ;define your stack segment
Stack_segment_name ends

Code_segment_name segment
RecFile2 proc far

assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name_RecFile2
	PUSH DS
	MOV CX,DS;Needed to pass variables through RAM it will be stored in CX then in MainDS after changing DS to current Procedure DS
	
	MOV AX,Data_segment_name_RecFile2 ; load the starting address of the data
	MOV DS,AX ; segment into DS reg.
	MOV MainDS,CX;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;Read Simulation Module Data Segment  
	PUSH DS 
	MOV CX,DS ;Current Proc DS in CX
	MOV DS,MainDS
	MOV AX,SimDS
	POP DS 	
	MOV SimuDS,AX
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
;Recive and then write to file
;;;;;;;;;;;;;
	;Receive  the TotComb
	LEA BX,TotCombR
	
	mov DX,2F8h       ;Read data from Receive buffer [2F8] into AL    
	In  AL,DX
	MOV [BX],AL ;Recevie Low Byte of TotComb
	
	INC BX
	CALL Receive
	MOV [BX],AL;Receive High Byte of TotComb

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Receive the User Input Count 
	
	LEA BX,UsrInCntR
	CALL Receive
	MOV [BX],AL ;Recevie Low Byte of TotComb
	INC BX
	CALL Receive
	MOV [BX],AL;Receive High Byte of TotComb
	;;;;;;;;;;;;;;;;;;;;;;;

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Receive the User Input Count 
	
	LEA BX,OtCntR
	CALL Receive
	MOV [BX],AL ;Recevie Low Byte of OtCntR
	INC BX
	CALL Receive
	MOV [BX],AL;Receive High Byte of OtCntR
	;;;;;;;;;;;;;;;;;;;;;;;

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Receive the User Input Count 
	
	LEA BX,OtTotR
	CALL Receive
	MOV [BX],AL ;Recevie Low Byte of OtTotR
	INC BX
	CALL Receive
	MOV [BX],AL;Receive High Byte of OtTotR
	;;;;;;;;;;;;;;;;;;;;;;;
	 
	MOV SI,00
	MOV COUNT_I,0
LpZsR:	
	
	LEA BX,TTableAR
	ADD BX,SI
	MOV CX,UsrInCntR
LR:	CALL Receive ; Send Char in DS:DX
	MOV [BX],AL
	INC BX
	LOOP LR
	
	
	;Write the wire Values 

	MOV CX,OtTotR
	;;;;;;;;;
	LEA BX,WireValAR 
	ADD BX,SI
L2R:CALL Receive ; Send Char in DS:DX
	MOV [BX],AL
	INC BX
	LOOP L2R
	
	ADD SI,20 ;Skip to the next 20 lines
	INC COUNT_I
	MOV AX,COUNT_I
	CMP AX,TotCombR
	JB LpZsR

	
;;;;;;;;;;;;;;;;;;;;;;
	CALL WriteFile1		
	POP DS 
	RETF

RecFile2 endp

;____________________________________________________
Receive proc near
ee:	mov dx,2FDh        ;Line status register
	In al,dx

	test al,00000001b ; Test if DR=1
	jz ee             ;Jump if zero [DR=0] No data is ready to be picked up ;check again

	mov dx,2F8h       ;Read data from Receive buffer [3F8] into AL    
	In al,dx
	ret
Receive endp
;____________________________________________________

WriteFile1 PROC

	LEA DX,FileNameR
	;DS:DX =Address of ASCIIZ path [Terminated by zero byte]
	;DS,DX Should be set proprely before calling this procedure
	;1-Open file for Write [Obtian the file handler]
	MOV CX,00
	MOV AL,1 ;Mode flag is write
	MOV AH,3CH;Create new file 
	INT 21H
	JNC WTs
	CMP AX,3
	JE  PnF
	CMP AX,5 
	JE AD 
	LEA DX,FileCrErr
	MOV AH,09H
	INT 21H
	RET
Pnf:LEA DX,FilePnfErr
	MOV AH,09H
	INT 21H
	RET
AD: LEA DX,FileADErr
	MOV AH,09H
	INT 21H
	RET	
WTs:
	MOV FileHandler,AX
	;;;;;;;;;;
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;; test 
	;1-Write Total Number of Combinations  
		;Convert Two Digits Hex Number to ASCII 
		MOV AX,TotCombR
		CMP TotCombR,256
		JNE Ctot2
		MOV WriteTotCom[21],'2'
		MOV WriteTotCom[22],'5'
		MOV WriteTotCom[23],'6'
		JMP w
Ctot2:	CMP TotCombR,512
		JNE Ctot3
		MOV WriteTotCom[21],'5'
		MOV WriteTotCom[22],'1'
		MOV WriteTotCom[23],'2'
		JMP w
Ctot3:	AAM 
		MOV CL,AL
		MOV AL,AH
		AAM 
		OR AH,30H 
		OR AL,30H
		OR CL,30H
		MOV WriteTotCom[21],AH
		MOV WriteTotCom[22],AL
		MOV WriteTotCom[23],CL	
w:	LEA DX,WriteTotCom
	MOV BX,FileHandler
	MOV CX,24
	MOV AH,40H
	INT 21H
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Write New Line [LF]
	LEA DX,LFR
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H
	;;;;;;;;;;;;;;;;;;;;;;
	;2-Write Total User Input Variables   
		;Convert Two Digits Hex Number to ASCII 
		MOV AX,UsrInCntR
		AAM 
		MOV CL,AL
		MOV AL,AH
		AAM 
		OR AH,30H 
		OR AL,30H
		OR CL,30H
		MOV WriteUsrInCount [26],AH
		MOV WriteUsrInCount [27],AL
		MOV WriteUsrInCount [28],CL	
	LEA DX,WriteUsrInCount
	MOV BX,FileHandler
	MOV CX,29
	MOV AH,40H
	INT 21H
	;Write New Line [LF]
	LEA DX,LFR
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H
	;3-Write the Number of User O/P Variables 
		;Convert Two Digits Hex Number to ASCII 
		MOV AX,OtCntR
		AAM 
		OR AH,30H 
		OR AL,30H 
		MOV WriteOtCnt[30],AH
		MOV WriteOtCnt[31],AL	
	LEA DX,WriteOtCnt
	MOV BX,FileHandler
	MOV CX,32
	MOV AH,40H
	INT 21H
	;Write New Line [LF]
	LEA DX,LFR
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H

	;4-Write Total Number of Combinations  
		;Convert Two Digits Hex Number to ASCII 
		MOV AX,OtTotR
		AAM 
		OR AH,30H 
		OR AL,30H
		MOV WriteOtTot[24],AH
		MOV WriteOtTot[25],AL		
	LEA DX,WriteOtTot
	MOV BX,FileHandler
	MOV CX,26
	MOV AH,40H
	INT 21H
	;Write New Line [LF]
	LEA DX,LFR
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H

		
	MOV SI,00
	MOV COUNT_I,0
LpZsRf:	
	LEA DX,TTableAR
	ADD DX,SI
	MOV BX,FileHandler
	MOV CX,UsrInCntR
	MOV AH,40H
	INT 21H
	;Write Slash to divide I/O
	LEA DX,SlashR
	MOV BX,FileHandler
	MOV CX,3
	MOV AH,40H
	INT 21H
	;Write the wire Values 
	LEA DX,WireValAR
	ADD DX,SI
	MOV BX,FileHandler
	MOV CX,OtTotR
	MOV AH,40H
	INT 21H	
	;Write New Line [LF]
	LEA DX,LFR
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H
	
	
	ADD SI,20 ;Skip to the next 20 lines
	INC COUNT_I
	MOV AX,COUNT_I
	CMP AX,TotCombR
	JB LpZsRf
	
	;Close the file 
	MOV AH,3EH
	MOV BX,FileHandler
	INT 21H
	RET
WriteFile1 ENDP
;____________________________________________________ 
Code_segment_name ends
end 