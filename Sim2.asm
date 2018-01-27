EXTRN FileName1:BYTE

EXTRN Screen:WORD
EXTRN ElemNum:WORD
EXTRN Wires: WORD
EXTRN WireNum:WORD
EXTRN SimDS:WORD 
PUBLIC Sim2

PUBLIC TTableA
PUBLIC WireValA ;Needed by SerComm
PUBLIC UsrInCnt
PUBLIC OtCnt
PUBLIC TotComb
PUBLIC OtTot
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

Data_segment_name_Sim2 segment para
ORG 10H
;Counters i,j
COUNT_I    DW ?
COUNT_J    DW ? 
MainDS  DW ?
fileTT  DB 'TruthTable.txt',00
LF  DB 0AH,00  
Slash DB ' - ',00
ErrM DB 'The mouse is is not available',0DH,0AH,'$'
ClickNum DB ?
;;;;;;;;;;;;;
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MaxX DW 640
MaxY DW 480

StGates    DB 20 DUP(0ffh)
VarGate    DB 20 DUP(0FFH)
UsrInCnt   DW ? ;Total User Inputs Number  [All gates inlet connectors count without being wired]
UsrOtCnt   DW ? ;Total User Outputs Number [All gates outlet connectors count without being wired]
OtCnt 	   Dw 00
OtTot 	   DW 00
TotComb    DW ?;Actual number of total combinations
TTable     DB 256 DUP (20 DUP(?));Assuming maximum 9 Input User Variables and 11 Output bollean Functions
TTableA    DB 256 DUP (20 DUP(?)) 
WireVal    DB 256 DUP (20 DUP (0FFH))
WireValA   DB 256 DUP (20 DUP (0FFH))
WriteGCount DB 'Gate Count = ',?,?;15 Charcters
WriteWCount DB 'Wire Count = ',?,?;15 Charcters
WriteTotCom DB 'Total Combinations = ',?,?,?;24 characters

; Actual Signal in Wire #i corresponds to combination # j 
;in truth table is  WireVal[j][i] ;there are max 1024 combinations and max 20 wires  
Data_segment_name_Sim2 ends

Stack_segment_name segment para stack
db 64 dup(0) ;define your stack segment
Stack_segment_name ends


Code_segment_name segment
Sim2 PROC FAR
assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name_Sim2

	;;;;;;;;;;;;;;;; Module Specific
	
	PUSH DS
	MOV CX,DS;Needed to pass variables through RAM it will be stored in CX then in MainDS after changing DS to current Procedure DS

	MOV AX,Data_segment_name_Sim2 ; load the starting address of the data
	MOV DS,AX ; segment into DS reg.
	MOV MainDS,CX;
	;Store Module DataSegment at Main 
	PUSH DS 
	MOV CX,DS ;Current Proc DS in CX
	MOV DS,MainDS
	MOV SimDS,CX
	POP DS 
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;__ Loop Over all Elements on the Screen
	;Search for all elements with both FFFF WireNums in both inlets"No Input"
	;____________________________   Search for the starting gates 
	;____________________________   loop also calculates the UserIn,Out count
	PUSH DS
	MOV DS,MainDS
	MOV AX,ElemNum
	MOV SI,00
	MOV DI,00
	MOV DX,00; UsrInCnt
	MOV BP,00; UsrOutCnt
	MOV CX,00
L: 	LEA BX,Screen
	CMP WORD PTR [BX+SI+6],0FFFFH;Inlet 1
	JNE Cont1
	CMP WORD PTR [BX+SI+8],0FFFFH;Inlet 2
	JNE Cont1
	MOV DL,[BX+SI+12] ; Save the sequence number of the starting gates in StGates[DI]
	POP DS
	MOV StGates[DI],DL
	INC DI
	PUSH DS
	MOV DS,MainDS
Cont1:
	CMP WORD PTR [BX+SI+6],0FFFFH;
	JNZ T1
	INC DH
T1:	CMP WORD PTR [BX+SI+8],0FFFFH;
	JNZ T2
	INC DH
T2:	CMP WORD PTR [BX+SI+10],0FFFFH;
	JNZ T3
	INC BP
	;Add the gate count to VarGate 
	MOV DL,[BX+SI+12]
	POP DS 
	PUSH DI 
	MOV DI,CX
	MOV VarGate[DI],DL
	INC CX 
	POP DI 
	PUSH DS 
	MOV DS,MainDS
T3:	ADD SI,14
	DEC AX
	JNZ L
	POP DS
	
	MOV DL,DH
	MOV DH,00
	MOV UsrInCnt,DX
	MOV UsrOtCnt,BP
	;;;;;;;;;;;;;;;;;;;
	PUSH DS 
	MOV DS,MainDS 
	MOV AX,WireNum
	POP DS 
	ADD AX,UsrOtCnt
	MOV OtTot,AX
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Sim2 for all possible values of the user input 
	 ;_____________________________ Build the Truth Table ____________________________ 
	MOV TotComb,1
	MOV CX,UsrInCnt
	SHL TotComb,CL ; TotComb=2^UsrInCnt
	
	MOV SI,UsrInCnt
	MOV DX,0
TT1:DEC SI
	
	MOV BX,00
TT:	
	MOV AX,1
	MOV CX,SI
	SHL AX,CL;AX=2^SI
	
TT2:MOV TTable[BX][SI],Dl
	ADD BX,20;Each row in TTable contains 20 elements 
	DEC AX
	JNZ TT2
	XOR Dl,1
	 MOV AX,20
	 
	 PUSH DX
	 MOV DX,TotComb
	 MUL DX
	 POP DX
	 
	 CMP BX,AX;AX=20*TotComb
	 Jb TT
	
	CMP SI,00
	JNZ TT1
	
	 ;Truth Table is setup now 
	 ;_____________________________ Build the Truth Table End ____________________________ 
	
	;Write TT to truthtable.txt;
	CALL WriteFile
	
	;___

	
	 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	 
	
	;;;;;;;;;;;;;;;;;;;;
	mov si,0
	MOV DI,00
S:	CMP BYTE PTR StGates[DI],0FFH ; If it contains FFFF then stop (we may use starting gates max counter instead)	
	JNE  T
	JMP StopSt
T:	
	PUSH DI;Will subject to changes 
	
	PUSH SI
	PUSH ax
	MOV AL,StGates[DI];StGates[DI] Is the starting gate seq number 
	MOV AH,00
	MOV SI,AX ; Get the Serial Number of Starting Gates [Which will used in indexing the Screen to get the type]
	POP AX
	MULBY14 SI
	
	;fetch global variables needed
	PUSH DS
	
	MOV DS,MainDS
	LEA BX,Screen
	MOV AH,[BX][SI+4];Get the gate type 
	MOV DI,[BX][SI+10];Get the outlet wire index
	MOV AL,[BX][SI+12];Gate Count
	CMP DI,0FFFFH ;If no outlet wire
	JNE COMPAU;Complete as usual
	;otherwise modify to access WireVal(WireNum+Gate Count)
	MOV DI,WireNum
	POP DS 
	ADD DI,OtCnt
	INC OtCnt
	PUSH DS 
	MOV DS,MainDS
	;pick index WireNum+VarGate(i)  
COMPAU:
	MOV AL,AH
	MOV AH,00H 
	;Now AX Contains the Gate Type
	POP DS 
	;Screen[SI+6]=Screen[SI+8]=0FFFFH For Starting Gate
	;Screen[SI+10]=The index of the outlet wire
	;WireVal[BX][Screen[SI+10]]=TTable[BX][SI]&&TTable[BX][SI+1]
	POP SI ; SI Contains the indices for the user input variable [Increment by 2 in Starting Gate loop]
    ;Apply the operation based on its type [Type is based through AX]
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	 PUSH DX
	 PUSH BX
	 PUSH AX
	 CMP AX,00 ;AND 
	 JNE NAND 
	 MOV BX,00 
LOP:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX][SI]
	 AND AL,TTable[BX][SI+1]
	 MOV WireVal[BX][DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP
	 JMP ENJ
	 
NAND:CMP AX,01
	 JNE OR1
	 MOV BX,00 
LOP1:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX][SI]
	 AND AL,TTable[BX][SI+1]
	 XOR AL,1
	 MOV WireVal[BX][DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP1
	 JMP ENJ
	 
	 
OR1 :CMP AX,02
	 JNE NOR
	 MOV BX,00 
LOP2:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX][SI]
	 OR AL,TTable[BX][SI+1]
	 MOV WireVal[BX][DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP2
	 JMP ENJ
NOR :CMP AX,03
	 JNE XOR1
	 MOV BX,00 
LOP3:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX][SI]
	 OR  AL,TTable[BX][SI+1]
	 XOR AL,1
	 MOV WireVal[BX][DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP3
	 JMP ENJ
	 
XOR1:CMP AX,04
	 JNE XNOR

	 MOV BX,00 
LOP4:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX][SI]
	 XOR AL,TTable[BX][SI+1]
	 MOV WireVal[BX][DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP4
	 JMP ENJ
	 
XNOR:CMP AX,05
	 JE comp
	 POP AX
	 POP BX
	 POP DX
     POP DI	 
	 jmp Err
comp:
	 MOV BX,00 
LOP5:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX][SI]
	 XOR AL,TTable[BX][SI+1]
	 XOR AL,1
	 MOV WireVal[BX][DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP5
ENJ:
	 POP AX
	 POP BX
	 POP DX

	 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	 
	POP DI
	INC DI
	JMP S
StopSt:

	;;;;;;End of  Calculating all Wires Connected to the starting gates 
		
	;_____________________________ O(N^2) Code 
	;Iterating all gates 
	;Calculating the output wire  value for all combinations 
	;if the input inlets are calculated before 
	;Netsing this again inside a loop of size N 
	;Resulting in all wire signals are calculated
	; for i=1:ElemNum
	;    for j=1:ElemNum
	;		if(WireVal[for any k][Screen(j).Outlet_index] != FF ) 
	;        continue;//if it calculated before no need to re-calcaulte it 
	;       else 
	;
	;       if(WireVal[for any k][Screen(j).Inlet1_index]!=FF &&  WireVal[for any k][Screen(j).Inlet2_index]!=FF )
	;          WireVal[for all k][Screen(j).Outlet_index]=Apply Operation 
	;       end
	;   end
	; end
	PUSH DS
	MOV DS,MainDS
	MOV AX,ElemNum
	POP DS 
	
	MOV  COUNT_I,0 
IL:		
		MOV COUNT_J,00
		JLP:
			PUSH AX
			MOV SI,COUNT_J
			PUSH DS
			MOV DS,MainDS
			LEA BX,Screen
			MULBY14 SI
			MOV DI,[BX+SI+10];Check Outlet if calculated no need for re-calc
			MOV CX,[BX+SI+6]
			MOV BP,[BX+SI+8]
			MOV AX,[BX+SI+4]
			POP DS 
			CMP DI,0FFFFH  
			JNZ OK; wired output
			CMP BP,0FFFFH 
			JNZ OK1;Not wired output But Wired  first Input 
			CMP CX,0FFFFH
			JNZ OK1;Not wired output But Wire Second Input 
			;;Not wired output and Inputs [Calculated with start] 
			JMP CONTIN	
	Ok1:		;LESSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSA 	
	OK:		CMP WireVal[0][DI],0FFH;Check against any combination ; let's try the first 
			JE A
			JMP CONTIN;Calculated before
	A:		
			CMP CX,0ffffh;Not wired first input
			;LESSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSA 
			MOV DI,CX
			CMP WireVal[0][DI],0FFH;Check against any combination ; let's try the first 
			JNE B
			JMP CONTIN;Can't be calculated this pass 
	B:		
			
			CMP BP,0ffffh;Not wired second input
			;LESSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSA 
			MOV DI,BP
			CMP WireVal[0][DI],0FFFFH;Check against any combination ; let's try the first 
			JNE CLP
			JMP CONTIN;Can't be calculated this pass 
	CLP:		
			;Here we calculate the new tuple
		;;;;;;;;;;;;;;;;;
		PUSH DX
		PUSH BX
		PUSH AX
		CMP AX,00 ;AND 
		JNE NANDx
	 
		MOV BX,00 
	LOPx:
		;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
		MOV AL,TTable[BX][SI]
		AND AL,TTable[BX][SI+1]
		MOV WireVal[BX][DI],AL
		ADD BX,20
		MOV AX,20
		MOV DX,TotComb
		MUL DX
		CMP BX,AX
		JB LOPx
		JMP ENJx
	NANDx:CMP AX,01
		  JNE OR1x
		  MOV BX,00 
	LOP1x:
		;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
		MOV AL,TTable[BX][SI]
		AND AL,TTable[BX][SI+1]
		XOR AX,1
		MOV WireVal[BX][DI],AL
		ADD BX,20
		MOV AX,20
		MOV DX,TotComb
		MUL DX
		CMP BX,AX
		JB LOP1x
		JMP ENJx

	 
	 
	OR1x :CMP AX,02
		  JNE NORx

	 	 MOV BX,00 
LOP2x:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX][SI]
	 OR AL,TTable[BX][SI+1]
	 MOV WireVal[BX][DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP2x
	JMP ENJx
NORx :CMP AX,03
	 JNE XOR1x
	
		 MOV BX,00 
LOP3x:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX][SI]
	 OR  AL,TTable[BX][SI+1]
	 XOR AL,1
	 MOV WireVal[BX][DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP3x
	JMP ENJx
	 
		XOR1x:CMP AX,04
			  JNE XNORx

			MOV BX,00 
		LOP4x:
			;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
			MOV AL,TTable[BX][SI]
			XOR AL,TTable[BX][SI+1]
			MOV WireVal[BX][DI],AL
			ADD BX,20
			MOV AX,20
			MOV DX,TotComb
			MUL DX
			CMP BX,AX
			JB LOP4x
		JMP ENJx
	 
		XNORx:CMP AX,05
			POP AX
			POP BX
			POP DX
			  JNE Err
			  MOV BX,00 
		LOP5x:
			;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
			MOV AL,TTable[BX][SI]
			XOR AL,TTable[BX][SI+1]
			XOR AL,1
			MOV WireVal[BX][DI],AL
			ADD BX,20
			MOV AX,20
			MOV DX,TotComb
			MUL DX
			CMP BX,AX
			JB LOP5x
 ENJx:
			POP AX
			POP BX
			POP DX

	 ;;;;;;;;;;;;;;;;;;;;
		
	CONTIN:				
			POP AX
			INC COUNT_J 
			CMP COUNT_J,AX
		    JAE COM
			JMP JLP
		COM:
	INC COUNT_I 
	CMP COUNT_I,AX	
	JAE COM2
	JMP IL 
	COM2:
		
Err:

		call WriteFile1

		POP DS
		RETF
Sim2  ENDP


WriteFile PROC

;Convert the Truth Table to ASCII comma seperated 
	 
	LEA SI,TTable
	LEA DI,TTableA
	MOV CX,128*20
LL1:	 
     MOV AL,[SI]
	 OR AL,30H
	 MOV [DI],AL
	 INC SI
	 INC DI
	 LOOP LL1
	
	
		


	;PUSH DS
	;MOV DS,MainDS
	LEA DX,fileTT
	;DS:DX =Address of ASCIIZ path [Terminated by zero byte]
	;DS,DX Should be set proprely before calling this procedure
	;1-Open file for Write [Obtian the file handler]
	MOV AL,1 ;Mode flag is write
	MOV AH,3CH;Create new file 
	INT 21H
	;POP DS 
	JNC WT
	RET
WT:
	MOV FileHandler,AX
	;Write Data to the file 
	 MOV SI,00
	MOV COUNT_I,0
LpZ:	
	LEA DX,TTableA
	ADD DX,SI
	MOV BX,FileHandler
	MOV CX,UsrInCnt
	MOV AH,40H
	INT 21H
	;Write New Line [LF]
	LEA DX,LF
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H
	
	
	ADD SI,20 ;Skip to the next 20 lines
	INC COUNT_I
	MOV AX,COUNT_I
	CMP AX,TotComb
	JB LpZ
	
	;Close the file 
	MOV AH,3EH
	MOV BX,FileHandler
	INT 21H
	
	
	
RET
WriteFile ENDP 

;Write the simulation Output
WriteFile1 PROC


	;Preperations
	;Convert the Truth Table to ASCII comma seperated 
		LEA SI,TTable
		LEA DI,TTableA
		MOV CX,128*20
	LL1s:	 
		MOV Al,[SI]
		OR AL,30H
		MOV [DI],Al
		INC SI
		INC DI
		LOOP LL1s
	;Convert the WireVal to ASCII comman seperated
		LEA SI, WireVal
		LEA DI,WireValA
		MOV CX,128*20
	LL1ss:	 
		MOV AL,[SI]
		OR AL,30H
		MOV [DI],AL
		INC SI
		INC DI
		LOOP LL1ss	
	
	;Set the fileName 
	PUSH DS
	MOV DS,MainDS
	LEA DX,FileName1
	ADD DX,2
	
	;DS:DX =Address of ASCIIZ path [Terminated by zero byte]
	;DS,DX Should be set proprely before calling this procedure
	;1-Open file for Write [Obtian the file handler]
	MOV AL,1 ;Mode flag is write
	MOV AH,3CH;Create new file 
	INT 21H
	POP DS 
	JNC WTs
	RET
WTs:
	MOV FileHandler,AX
	;Write Data to the file 
	;1-Write the Number of Gates 
		;Convert Two Digits Hex Number to ASCII 
		PUSH DS 
		MOV DS,MainDS
		MOV AX,ElemNum
		POP DS 
		AAM 
		OR AH,30H 
		OR AL,30H 
		MOV WriteGCount[13],AH
		MOV WriteGCount[14],AL
	LEA DX,WriteGCount
	MOV BX,FileHandler
	MOV CX,15
	MOV AH,40H
	INT 21H
	;Write New Line [LF]
	LEA DX,LF
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H
	
	;2-Write the Number of Wires 
		;Convert Two Digits Hex Number to ASCII 
		PUSH DS 
		MOV DS,MainDS
		MOV AX,WireNum
		POP DS 
		AAM 
		OR AH,30H 
		OR AL,30H 
		MOV WriteWCount[13],AH
		MOV WriteWCount[14],AL	
	LEA DX,WriteWCount
	MOV BX,FileHandler
	MOV CX,15
	MOV AH,40H
	INT 21H
	;Write New Line [LF]
	LEA DX,LF
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H

	;3-Write Total Number of Combinations  
		;Convert Two Digits Hex Number to ASCII 
		MOV AX,TotComb
		AAM 
		MOV CL,AL
		MOV AL,AH
		AAM 
		OR AH,30H 
		OR AL,30H
		OR CL,30H
		MOV WriteTotCom[21],AH
		MOV WriteTotCom[22],AL
		MOV WriteTotCom[23],CL	
	LEA DX,WriteTotCom
	MOV BX,FileHandler
	MOV CX,24
	MOV AH,40H
	INT 21H
	;Write New Line [LF]
	LEA DX,LF
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H



	MOV SI,00
	MOV COUNT_I,0
LpZs:	
	LEA DX,TTableA
	ADD DX,SI
	MOV BX,FileHandler
	MOV CX,UsrInCnt
	MOV AH,40H
	INT 21H
	;Write Slash to divide I/O
	LEA DX,Slash
	MOV BX,FileHandler
	MOV CX,3
	MOV AH,40H
	INT 21H
	;Write the wire Values 
	LEA DX,WireValA
	ADD DX,SI
	MOV BX,FileHandler
	MOV CX,OtTot
	MOV AH,40H
	INT 21H	
	;Write New Line [LF]
	LEA DX,LF
	MOV BX,FileHandler
	MOV CX,1
	MOV AH,40H
	INT 21H
	
	
	ADD SI,20 ;Skip to the next 20 lines
	INC COUNT_I
	MOV AX,COUNT_I
	CMP AX,TotComb
	JB LpZs
	
	;Close the file 
	MOV AH,3EH
	MOV BX,FileHandler
	INT 21H
	
	
	
RET
WriteFile1 ENDP 


Code_segment_name ends
end

;____________________________
