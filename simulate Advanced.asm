
	PUSH DS
	MOV DS,MainDS
	MOV AX,ElemNum
	POP DS 
	
	MOV  COUNT_I,0 
IL:		
		MOV Indexx,00 ; Iterate over Single Non Existent Inlet 
		MOV COUNT_J,00
		JLP:
	
			MOV SI,COUNT_J
			PUSH DS
			MOV DS,MainDS
			LEA BX,Screen
			
			;;;; SI=14*SI Old
			PUSH CX 
			MOV CX,SI 
			MULBY14 CX 
			POP CX 
			;;;;;;;;
			MOV DI,[BX+SI+10];Check Outlet if calculated no need for re-calc
			MOV CX,[BX+SI+6]
			MOV BP,[BX+SI+8]
			MOV AX,[BX+SI+4]
			POP DS 
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		;
		;OutputIndex DW ?
		;Input1Index DW ?
		;Input2Index DW 	?
		;CrntWireNum DW ? 		

			
			CMP DI,0FFFFH 
			JNE OutletExist
			;Continue if outlet not exist
			;O/P is stored at wireNum+OtCnt and then INC OtCnt
			      ;HOW to check if it is calculated beofre !!!!
				  ;both Inlets not exist [starting gate]
					CMP BP,0FFFFH
					JNE ndc
					CMP CX,0FFFFH
					JNE ndc 
					JMP CONTIN
				  ; one inlet not exist but other exist and calculated
					ndc :
					CMP BP,0FFFFH
					JNE ndc2
						PUSH DI;2ND inlet not exist nut first exist and calculated 
						MOV  DI,CX
						CMP WireVal[DI],0FFH
						JE   T1T1
						POP DI 
						JMP CONTIN
				T1T1:	POP DI 
					ndc2:
					CMP CX,0FFFFH
					JNE rdc
						PUSH DI;2ND inlet not exist nut first exist and calculated 
						MOV  DI,BP
						CMP WireVal[DI],0FFH
						JE T2T2
						POP DI 
						JMP CONTIN
					T2T2:POP DI 
					rdc:
					;if both inlets exist and calculated
					CMP BP,0FFFFH
					JNE rth
					CMP CX,0FFFFH
					JNE rth
						PUSH DI
						PUSH SI
						MOV DI,BP 
						MOV SI,CX 
						CMP BYTE PTR [DI],0FFH
						JNE rth1 
						CMP BYTE PTR [SI],0FFH
						JNE rth1
						POP SI 
						POP DI 
						JMP CONTIN
				rth1:	POP SI 
						POP DI 
					rth:
			MOV BX,WireNum
			ADD BX,OtCnt
			ADD OutputIndex,BX
			INC OtCnt
			;;
			JMP CheckInlets
OutletExist:CMP  BYTE PTR WireVal[DI],0FFH
			JNE Y1Y1
			JMP CONTIN;O/P Calculated 
	Y1Y1:	MOV OutputIndex,DI
			
			;;;;;;;;; Checking Outlet is done 
			CheckInlets:
			;;Check if inlet1 or/and Inlet2 exist and not calculated 
			CMP BP,0FFFFH
			JNE FF 
			MOV Flag,02
			jmp FF1
		FF:		PUSH DI 
				MOV DI,BP
				CMP WireVal[DI],0FFH
				JnE t3t3
				POP DI 
				JMP CONTIN
		t3t3:	MOV Inlet2_index,DI
				POP DI 
		FF1:		
			CMP CX,0FFFFH
			JE Inlet1No
				PUSH DI 
				MOV DI,CX
				CMP WireVal[DI],0FFH
				JNE t4t4
				POP DI 
				JMP CONTIN
			t4t4:MOV Inlet1_index,DI
				POP DI
		Inlet1No:
			PUSH BX
			INC Indexx
			MOV BX,StGCnt
			ADD BX,BX ;BX=2*StGCnt
			ADD BX,Indexx
			MOV Inlet1_index,BX 
			POP BX 
			
			CMP flag,2
			JNE EEE
				PUSH BX
				INC Indexx
				MOV BX,StGCnt
				ADD BX,BX ;BX=2*StGCnt
				ADD BX,Indexx
				MOV Inlet2_index,BX 
				POP BX 
			EEE:
	
	;Here we calculate the new tuple
		;;;;;;;;;;;;;;;;;
		PUSH DX
		PUSH BX
		PUSH AX
		CMP AX,00 ;AND 
		JNE NANDx
	 
		MOV BX,00 
	PUSH SI 
	LOPx:
		;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
		MOV SI,Inlet1_index
		MOV AL,TTable[BX+SI]
		MOV SI,Inlet2_index
		AND AL,TTable[BX+SI]
		MOV SI,OutputIndex
		MOV WireVal[BX+SI],AL
		ADD BX,20
		MOV AX,20
		MOV DX,TotComb
		MUL DX
		CMP BX,AX
		JB LOPx
	POP SI 
		JMP ENJx
	NANDx:CMP AX,01
		  JNE OR1x
		  MOV BX,00
	PUSH SI 
	LOP1x:
		;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
		MOV SI,Inlet1_index
		MOV AL,TTable[BX+SI]
		MOV SI,Inlet2_index
		AND AL,TTable[BX+SI]
		XOR AX,1
		MOV SI,OutputIndex
		MOV WireVal[BX+SI],AL
		ADD BX,20
		MOV AX,20
		MOV DX,TotComb
		MUL DX
		CMP BX,AX
		JB LOP1x
	POP SI
	JMP ENJx
 
	OR1x :CMP AX,02
		  JNE NORx
	 	  MOV BX,00
	PUSH SI 
LOP2x:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
		MOV SI,Inlet1_index
		MOV AL,TTable[BX+SI]
		MOV SI,Inlet2_index
		OR AL,TTable[BX+SI]
		MOV SI,OutputIndex
	 MOV WireVal[BX+SI],AL
	 ADD BX,20
	 MOV AX,20
	 MOV DX,TotComb
	 MUL DX;AX=DX[TotComb]*20
	 CMP BX,AX
	 JB LOP2x
	 POP SI 
	JMP ENJx
	
NORx :	CMP AX,03
		JNE XOR1x
	
		 MOV BX,00 
	PUSH SI
LOP3x:
     ;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
		MOV SI,Inlet1_index
		MOV AL,TTable[BX+SI]
		MOV SI,Inlet2_index
		OR  AL,TTable[BX+SI]
		XOR AL,1
		MOV SI,OutputIndex
		MOV WireVal[BX+SI],AL
		ADD BX,20
		MOV AX,20
		MOV DX,TotComb
		MUL DX
		CMP BX,AX
		JB LOP3x
	POP SI
		JMP ENJx
	 
		XOR1x:CMP AX,04
			  JNE XNORx

			MOV BX,00 
		PUSH SI
		LOP4x:
			;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
			MOV SI,Inlet1_index
			MOV AL,TTable[BX+SI]
			MOV SI,Inlet2_index
			XOR AL,TTable[BX+SI]
			MOV SI,OutputIndex
			MOV WireVal[BX+SI],AL
			ADD BX,20
			MOV AX,20
			MOV DX,TotComb
			MUL DX
			CMP BX,AX
			JB LOP4x
		POP SI 
		JMP ENJx
	 
		XNORx:CMP AX,05
			POP AX
			POP BX
			POP DX
			JNE Err
			MOV BX,00

		PUSH SI 
		LOP5x:
			;WireVal[BX][DI]=TTable[BX][SI]&&TTable[BX][SI+1]
			MOV SI,Inlet1_index
			MOV AL,TTable[BX+SI]
			MOV SI,Inlet2_index
			XOR AL,TTable[BX+SI]
			XOR AL,1
			MOV SI,OutputIndex
			MOV WireVal[BX+SI],AL
			ADD BX,20
			MOV AX,20
			MOV DX,TotComb
			MUL DX
			CMP BX,AX
			JB LOP5x
			POP SI 
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