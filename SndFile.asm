PUBLIC SndFile

EXTRN WireValA:BYTE ;Needed by SndFile
EXTRN UsrInCnt:WORD
EXTRN OtCnt:WORD
EXTRN OtTot:WORD
EXTRN TotComb:WORD
EXTRN TTableA:BYTE 
EXTRN SimDS:WORD 
Data_segment_name_SndFile segment para
temp1   db    ? 
LF      DB 0AH 
SLASH   DB ' - '
MainDS  DW ?
SimuDS  DW ? 
COUNT_I DW 0
FileHandler DW ?
LFR    DB ?
SlashR DB ?
WireValAR DB  512 DUP (20 DUP (0FFH))
TotCombR  dw ?
OtCntR    dw ?
TTableAR  DB  512 DUP (20 DUP(?))
UsrInCntR DW ?
OtTotR    DW ?
WriteOtTot      DB 'Total Output Variables =',?,?,'$';26 Characters
Data_segment_name_SndFile ends

Stack_segment_name segment para stack
dw 16 dup(0) ;define your stack segment
Stack_segment_name ends

Code_segment_name segment
SndFile proc far

assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name_SndFile
	PUSH DS
	MOV CX,DS;Needed to pass variables through RAM it will be stored in CX then in MainDS after changing DS to current Procedure DS
	
	MOV AX,Data_segment_name_SndFile ; load the starting address of the data
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
	
	PUSH DS
	MOV  DS,SimuDS
	MOV  AX,TotComb
	POP  DS

	;Send the TotComb first 
	;Send AL First
	MOV 	temp1,AL	
	CALL    send
	
	MOV temp1,AH;Then Send AH
	CALL    send

	;;;;;;;;;;;;;;;;;;;;;
	PUSH DS
	MOV  DS,SimuDS
	MOV  AX,UsrInCnt
	POP  DS

	;Send the UsrInCnt next 
	;Send AL First 
	MOV    temp1,AL
	CALL   send
	MOV    temp1,AH;Then Send AH
	CALL   send

	;;;;;;;;;;;;
	PUSH DS
	MOV DS,SimuDS
	MOV  AX,OtCnt
	POP DS

	;Send the OtCnt next 
	;Send AL First 
	MOV temp1,AL
	CALL    send
	MOV temp1,AH;Then Send AH
	CALL    send

	;;;;;;;;;;;;;;;;;;;
	PUSH DS
	MOV DS,SimuDS
	MOV  AX,OtTot
	POP DS

	;Send the oTtot next 
	;Send AL First 
	MOV temp1,AL
	CALL    send
	MOV temp1,AH;Then Send AH
	CALL    send
 
 
	;;;;;;;;;;;;;;;;;;;;;
	;PUSH DS
	;MOV DS,SimuDS
	;MOV  AX,OtTot
	;POP DS
	;AAM 
	;OR AH,30H 
	;OR AL,30H
	;	MOV WriteOtTot[24],AH
	;	MOV WriteOtTot[25],AL		
	;LEA DX,WriteOtTot
	;MOV AH,09H
	;INT 21H
	;;;;;;;;;;;;;;;;;
		
		
;;;;;;;;;;;;;;;;;;; First Send All the file 
	 MOV SI,00
	 MOV COUNT_I,0
LpZs:	
	

	PUSH DS
	MOV DS,SimuDS
	MOV CX,UsrInCnt
	LEA BX,TTableA
	ADD BX,SI
L1:	MOV AL,[BX]
	POP DS
	MOV temp1,AL
    CALL send ; Send Char in DS:DX
	PUSH DS
	MOV DS,SimuDS
	INC BX
	LOOP L1
	POP DS 
	;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;Write the wire Values 
	PUSH DS
	MOV DS,SimuDS
	MOV CX,OtTot
	LEA BX,WireValA
	ADD BX,SI
L:	MOV AL,[BX]
	MOV temp1,AL
	CALL send ; Send Char in DS:DX
	INC BX
	LOOP L
	POP DS 
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	ADD SI,20 ;Skip to the next 20 lines
	INC COUNT_I
	MOV AX,COUNT_I
	
	PUSH DS 
	MOV DS,SimuDS
	MOV BX,TotComb
	POP DS
	
	CMP AX,BX;BX Contains TotComb
	
	JB LpZs

	POP DS
	RETF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
finish:
	MOV AX,4c00h ; exit program
	INT 21h
SndFile endp



Send proc near
	;Send Byte By Byte 
	;Character to be send is in temp1

CheckSend:
	MOV  DX,3FDh   ;Read the line status register`
	IN   AL,DX
	TEST AL,20h   ;test the THRE [Transmit hold register empty] 
	JZ   CheckSend  ; if THRE=0 then loop until it = 1 [until the old data is sent
	MOV DX,3F8h     
	MOV AL,DS:[temp1] ;mov temp1 [the data read from the user to THR]
	OUT DX,AL
eee:
	RET
Send endp

Code_segment_name ends
end 