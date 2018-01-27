EXTRN FileName1:BYTE

EXTRN Screen:WORD
EXTRN ElemNum:WORD
EXTRN Wires: WORD
EXTRN WireNum:WORD
EXTRN SimDS:WORD 
PUBLIC Simulate

PUBLIC TTableA
PUBLIC WireValA ;Needed by SerComm
PUBLIC UsrInCnt
PUBLIC OtCnt
PUBLIC TotComb
PUBLIC OtTot
MULBY14 MACRO   j;Macro doesn't affect AX ; Only Mul Res in SI
	PUSH AX   ; j can't be AX or SI 
    MOV  AX,j             
	MOV  SI,AX
	ADD  AX,AX;AX=2*j  2
	ADD  AX,AX ;AX=4*j  4
	ADD  SI,SI;SI=2*j  2 
	ADD  SI,SI;SI=4*j  4 
	ADD  SI,SI;SI=8*j  8 
	ADD  SI,AX;SI=8*j+4*j=12*j    
	ADD SI,j  ; SI=12*j+j=13*j 
	ADD SI,j
	POP AX
ENDM
MULBY95 MACRO i,j;i=95*j  ; i can't be same as j and either can't be CX 
LOCAL loc
	PUSH CX
	MOV i,00
	MOV CX,96
Loc:ADD i,j
	LOOP Loc
	POP CX
ENDM
	
WLF MACRO
	;Write New Line [LF]
		LEA DX,LF
		MOV BX,FileHandler
		MOV CX,1
		MOV AH,40H
		INT 21H

ENDM

WriteGType MACRO Pos;Accept Type in AH Index of Statement in Pos;DS changed here to proc DS and after completing it'll be MainDS
LOCAL CScr           ;DX Inlet 1 - BP Inlet 2 - DI Outlet 
LOCAL TNAND
LOCAL TOR
LOCAL TNOR
LOCAL TXOR
LOCAL TXNOR
LOCAL TErr
LOCAL Hash
Local Hish
Local Hash1
Local Hish1
Local Hash2
Local Hish2
		POP DS
		PUSH BX;BX Subject to change
		MOV WriteStInfo[BX+47],AH 
		MULBY95 BX,Pos
			PUSH AX 
			MOV AX,DX
			CMP AX,0FFFFH
			JNE Hash 
			MOV AH,'N'
			MOV AL,'0'
			JMP Hish
	Hash:	AAM 
			OR AH,30H
			OR AL,30H; 47 48 71 72  94 95 
	Hish:	MOV WriteStInfo[BX+47],AH 
			MOV WriteStInfo[BX+48],AL
			MOV AX,BP 
			CMP AX,0FFFFH
			JNE Hash1 
			MOV AH,'N'
			MOV AL,'0'
			JMP Hish1
	Hash1:	AAM 
			OR AH,30H
			OR AL,30H
	Hish1:	MOV WriteStInfo[BX+71],AH 
			MOV WriteStInfo[BX+72],AL
			MOV AX,DI 
			CMP AX,0FFFFH
			JNE Hash2 
			MOV AH,'N'
			MOV AL,'0'
			JMP Hish2
	Hash2:	AAM 
			OR AH,30H
			OR AL,30H
	Hish2:	MOV WriteStInfo[BX+94],AH 
			MOV WriteStInfo[BX+95],AL
			POP AX
		CMP AH,00 
		JNE TNAND
		MOV WriteStInfo[BX+18],'A'
		MOV WriteStInfo[BX+19],'N'
		MOV WriteStInfo[BX+20],'D'
		JMP CScr
		TNAND:
		CMP AH,01
		JNE TOR
		MOV WriteStInfo[BX+18],'N'
		MOV WriteStInfo[BX+19],'A'
		MOV WriteStInfo[BX+20],'N'
		MOV WriteStInfo[BX+21],'D'
		JMP CScr
		TOR:
		CMP AH,02
		JNE TNOR
		MOV WriteStInfo[BX+18],'O'
		MOV WriteStInfo[BX+19],'R'
		JMP CScr
		TNOR:
		CMP AH,03
		JNE TXOR
		MOV WriteStInfo[BX+18],'N'
		MOV WriteStInfo[BX+19],'O'
		MOV WriteStInfo[BX+20],'R'
		JMP CScr
		TXOR:
		CMP AH,04
		JNE TXNOR
		MOV WriteStInfo[BX+18],'X'
		MOV WriteStInfo[BX+19],'O'
		MOV WriteStInfo[BX+20],'R'
		JMP CScr
		TXNOR:
		CMP AH,05
		JNE TErr		
		MOV WriteStInfo[BX+18],'X'
		MOV WriteStInfo[BX+19],'N'
		MOV WriteStInfo[BX+20],'O'
		MOV WriteStInfo[BX+21],'R'
		JMP CScr
		TErr:
		MOV WriteStInfo[BX+18],'E'
		MOV WriteStInfo[BX+19],'r'
		MOV WriteStInfo[BX+20],'r'
		CScr:
		POP BX
		PUSH DS
		MOV DS,MainDS
ENDM 		
Data_segment_name_Simulate segment para
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
Ind DW ?
StGates    DB 20 DUP(0ffh)
VarGate    DB 20 DUP(0FFH)
UsrInCnt   DW ? ;Total User Inputs Number  [All gates inlet connectors count without being wired]
UsrOtCnt   DW ? ;Total User Outputs Number [All gates outlet connectors count without being wired]
OtCnt 	   Dw 00
OtTot 	   DW 00
StGCnt     DW 00
TotComb    DW ?;Actual number of total combinations
TTable     DB 512 DUP (20 DUP(9));Assuming maximum 9 Input User Variables and 11 Output bollean Functions
TTableA    DB 512 DUP (20 DUP(?)) 
WireVal    DB 512 DUP (20 DUP (0FFH))
WireValA   DB 512 DUP (20 DUP (0FFH))
Indexx     DW 00
WriteGCount DB 'Gate Count = ',?,?;15 Charcters
WriteWCount DB 'Wire Count = ',?,?;15 Charcters
WriteTotCom DB 'Total Combinations = ',?,?,?;24 characters
WriteStGCnt DB 'Total Starting Gates = ',?,?;25 characters
WriteStGind DB 'Starting Gates Indices =','   ',?,?,19 DUP(' , ',?,?);Then Display StGates 
WriteVrGind DB 'Variable Gates Indices ='     ,'   ',?,?,19 DUP(' , ',?,?);Then Display VarGates 
WriteStInfo DB 20 DUP('Gate # ',?,?,' Of type ',?,?,' ',' ',' has an inlet 1 wire # = ',?,?,' and inlet 2 wire # = ',?,?,' and outlet wire # = ',?,?)
OutputIndex DW ?
Inlet1_index DW ?
Inlet2_index DW 	?
CrntWireNum DW ?
FLAG DW ? 		
; Actual Signal in Wire #i corresponds to combination # j 
;in truth table is  WireVal[j][i] ;there are max 1024 combinations and max 20 wires  
Data_segment_name_Simulate ends

Stack_segment_name segment para stack
db 64 dup(0) ;define your stack segment
Stack_segment_name ends


Code_segment_name segment
Simulate PROC FAR
assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name_Simulate

	;;;;;;;;;;;;;;;; Module Specific
	
	PUSH DS
	MOV CX,DS;Needed to pass variables through RAM it will be stored in CX then in MainDS after changing DS to current Procedure DS

	MOV AX,Data_segment_name_Simulate ; load the starting address of the data
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

	CALL StGateInit
	;;;;;;;;;;;;;;;;;;;
	;StGateInit initilaize StGates[] and Return # of UsrIn Count in UsrInCnt and UsrOut Count in UsrOtCnt.
	PUSH DS 
	MOV DS,MainDS 
	MOV AX,WireNum
	POP DS 
	ADD AX,UsrOtCnt
	MOV OtTot,AX
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Simulate for all possible values of the user input 
	 ;_____________________________ Build the Truth Table ____________________________ 
	CALL BuildTT
	 ;Truth Table is setup now 
	 ;_____________________________ Build the Truth Table End ____________________________ 
	;Write TT to truthtable.txt;
	CALL WriteFile
	;___
	 
	;;;;;;;;;;;;;;;;;;;;
	 CALL BuildSimTSG

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
		

		CALL BuildFullSimT
Err:

		call WriteFile1

		POP DS
		RETF
Simulate  ENDP

BuildFullSimT  PROC



RET
BuildFullSimT ENDP




WriteFile PROC

;Convert the Truth Table to ASCII comma seperated 
	 
	LEA SI,TTable
	LEA DI,TTableA
	MOV CX,512*20
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
;;;;;;;;;;;;;;;;;;;;
BuildSimTSG  PROC
	MOV SI,0
	MOV DI,00
S:	CMP BYTE PTR StGates[DI],0FFH ; If it contains FFFF then stop (we may use starting gates max counter instead)	
	JNE  T
	JMP StopSt
T:	
	PUSH DI;Will subject to changes 	
	PUSH SI
	
	PUSH AX
	MOV AL,StGates[DI];StGates[DI] Is the starting gate seq number 
	MOV AH,00
	MOV SI,AX ; Get the Serial Number of Starting Gates [Which will used in indexing the Screen to get the type]
	MOV Ind,SI
	POP AX
	
	PUSH CX 
	MOV CX,SI 
	MULBY14 CX 
	POP CX 
	;Now SI=14*Ind
	
	
	;fetch global variables needed
	PUSH DS
	MOV DS,MainDS
	LEA BX,Screen
	MOV AH,[BX][SI+4];Get the gate type
	MOV DI,[BX][SI+10];Get the outlet wire index	
	MOV DX,[BX][SI+6]
	MOV BP,[BX][SI+8]
		WriteGType Ind

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

	 PUSH SI
	 
	 MOV BP,DI
	 ADD BP,BP
	 ADD SI,BP; SI=2*DI +    ;BX Corresponds to comb number

	 CMP  AX,00 ;AND 
	 JNE  NAND 
	 MOV  BX,00 
LOP:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX][SI]
	 AND AL,TTable[BX][SI+1]
	 MOV   WireVal[BX][DI],AL
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
	 OR  AL,TTable[BX][SI+1]
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
	 MOV AL,TTable[BX+SI]
	 OR  AL,TTable[BX+SI+1]
	 XOR AL,1
	 MOV WireVal[BX+DI],AL
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
	 MOV AL,TTable[BX+SI]
	 XOR AL,TTable[BX+SI+1]
	 MOV WireVal[BX+DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP4
	 JMP ENJ
	 
XNOR:CMP AX,05
	 JE comp
	 POP SI
	 POP AX
	 POP BX
	 POP DX
     POP DI	 
	 jmp Err
comp:
	 MOV BX,00 
LOP5:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
	 MOV AL,TTable[BX+SI]
	 XOR AL,TTable[BX+SI+1]
	 XOR AL,1
	 MOV WireVal[BX+DI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX
	 CMP BX,AX
	 JB LOP5
ENJ:

	 POP SI 
	 POP AX
	 POP BX
	 POP DX

	 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	 
	POP DI
	INC DI
	JMP S
StopSt:


	MOV DI,00H
StGC:
	CMP BYTE PTR StGates[DI],0FFH
	JE EStGc
	INC StGCnt
	INC DI 
	JMP StGC
EStGc:
	RET
	
BuildSimTSG  ENDP


;Write the simulation Output
WriteFile1 PROC

	;Preperations
	;Convert the Truth Table to ASCII comma seperated 
		LEA SI,TTable
		LEA DI,TTableA
		MOV CX,512*20
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
		MOV CX,512*20
	LL1ss:	 
		MOV AL,[SI]
		CMP AL,0FFH 
		JE DispB
		OR AL,30H
		JMP CLL1ss
DispB:	MOV AL,39H
CLL1ss:	MOV [DI],AL
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
	WLF
	
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
	WLF
	
	;3-Write Total Number of Combinations  
		;Convert Two Digits Hex Number to ASCII 
		MOV AX,TotComb
		CMP TotComb,256
		JNE Ctot2
		MOV WriteTotCom[21],'2'
		MOV WriteTotCom[22],'5'
		MOV WriteTotCom[23],'6'
		JMP w
Ctot2:	CMP TotComb,512
		JNE Ctot3
		MOV WriteTotCom[21],'5'
		MOV WriteTotCom[22],'1'
		MOV WriteTotCom[23],'2'
		JMP w
Ctot3:	AAM    ; 16=0106
		MOV CL,AL ;CL=06
		MOV AL,AH ;AL=01 
		AAM       ;AH=00 AL=01 
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
	;Write New Line [LF]
	WLF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;4-Write Starting Gates Indices and Info   
	LEA DX,WriteStGind
	MOV BX,FileHandler
	MOV CX,24
	MOV AH,40H
	INT 21H
	
		MOV DI,00
		MOV BX,0		
StGindL:
		CMP StGates[DI],0FFH
		JE  StGindLE
		MOV AL,StGates[DI]
		AAM
		OR AH,30H 
		OR AL,30H
		MOV WriteStGind[BX+3+24],AH
		MOV WriteStGind[BX+4+24],AL
		ADD BX,5
		INC DI
		JMP StGindL
StGindLE:
	MOV CX,BX
	LEA DX,WriteStGind[24]
	MOV BX,FileHandler
	MOV AH,40H
	INT 21H
		;Write New Line [LF]
		WLF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;5-Write Variable Gates Indices and Info   
		;Convert Two Digits Hex Number to ASCII 
	LEA DX,WriteVrGind
	MOV BX,FileHandler
	MOV CX,24
	MOV AH,40H
	INT 21H
	
	MOV DI,00
	MOV BX,0		
VrGindL:
		CMP VarGate[DI],0FFH
		JE  VrGindLE
		MOV AL,VarGate[DI]
		AAM
		OR AH,30H 
		OR AL,30H
		MOV WriteVrGind[BX+3+24],AH
		MOV WriteVrGind[BX+4+24],AL
		ADD BX,5
		INC DI
		JMP VrGindL
VrGindLE:
	MOV CX,BX
	LEA DX,WriteVrGind[24]
	MOV BX,FileHandler
	MOV AH,40H
	INT 21H
	;Write the Line Feed
	WLF
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;6-Write Starting Gates Info
	MOV DI,00
StGinfoL:
	CMP StGates[DI],0FFH
	JNE ContStGinfoL
	JMP  StGinfoLE
ContStGinfoL:	
	;Setting Gate Parameters 
	MOV AL,StGates[DI];StGates[DI] Is the starting gate seq number 
	MOV AH,00
	MOV SI,AX ; Get the Serial Number of Starting Gates
	;fetch global variables needed
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
	MULBY95 SI,AX
	;Now SI=95* SI Old=AX 
	;;;;;;
	;;;'Gate # '
	LEA DX,WriteStInfo
	MOV BX,FileHandler
	MOV CX,7
	MOV AH,40H
	INT 21H
	;;  # Here # 
	MOV AL,StGates[DI]
	AAM
	OR AH,30H 
	OR AL,30H
	MOV WriteStInfo[SI+7],AH
	MOV WriteStInfo[SI+8],AL
	LEA DX,WriteStInfo[SI+7]
	MOV BX,FileHandler
	MOV CX,2
	MOV AH,40H
	INT 21H
	;; ' of type '
	LEA DX,WriteStInfo[SI+9]
	MOV BX,FileHandler
	MOV CX,9
	MOV AH,40H
	INT 21H	
	;; 'AND ' or 'NAND' or 'OR  ' ..
	;;18,19,20,21      
	LEA DX,WriteStInfo[SI+18]
	MOV BX,FileHandler
	MOV CX,4         
	MOV AH,40H
	INT 21H	
	;; ' has an inlet 1 wire # = '
	LEA DX,WriteStInfo[SI+22]
	MOV BX,FileHandler
	MOV CX,25
	MOV AH,40H
	INT 21H	
	;;47,48
	LEA DX,WriteStInfo[SI+47]
	MOV BX,FileHandler
	MOV CX,2
	MOV AH,40H
	INT 21H	

	;;' and inlet 2 wire # = '
	LEA DX,WriteStInfo[SI+49]
	MOV BX,FileHandler
	MOV CX,22
	MOV AH,40H
	INT 21H	
	;;71,72   	
	LEA DX,WriteStInfo[SI+71]
	MOV BX,FileHandler
	MOV CX,2
	MOV AH,40H
	INT 21H	
	;;' and outlet wire # = '
	LEA DX,WriteStInfo[SI+73]
	MOV BX,FileHandler
	MOV CX,21
	MOV AH,40H
	INT 21H	
	;;94,95  
	LEA DX,WriteStInfo[SI+94]
	MOV BX,FileHandler
	MOV CX,2
	MOV AH,40H
	INT 21H	
	
	WLF
	INC DI
	JMP StGinfoL
	
StGinfoLE:	
;WriteStInfo DB 'Gate # ',?,?,' Of type ',?,?,?,?,' has an inlet 1 wire # = ',?,?
;			DB ' and inlet 2 wire # = ',?,?,' and outlet wire # = ',?,?

			

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


StGateInit PROC  
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
RET 

StGateInit ENDP

BuildTT PROC 
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
	RET 
BuildTT ENDP 

Code_segment_name ends
end

;____________________________
