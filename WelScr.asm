Data_segment_name_WelScr segment para
ORG 10H
MsgWelcome    DB 'Hello to CUFE Electric Circuits Simulation Program','$'
MsgInUname    DB 'Enter your User name : ','$'
MsgInFileName DB 'Enter your File name : ','$'
Str1Offset DW 44+8
;44 Accounts for returning to Str1 first address 22+22
;as in main PUSH {STR1} Then PUSH {STR2}
;8 account for CALL FAR ,PUSH BP,PUSH DS
Str2Offset DW 22+8
;22 Accounts for returning to Str2 first address
;8 account for CALL FAR ,PUSH BP,PUSH DS

UserName1  DB 20,?,20 DUP (?)
;To Display MsgInUname : LEA DX, UserName1+2
FileName1  DB 20,?,20 DUP (?)
Data_segment_name_WelScr ends

Stack_segment_name segment para stack
db 64 dup(0) ;define your stack segment
Stack_segment_name ends

PUBLIC WelScr
Code_segment_name segment

WelScr PROC FAR
assume SS:Stack_segment_name,CS:Code_segment_name,DS:Data_segment_name_WelScr,ES:Data_segment_name_WelScr

	;;;;;;;;;;;;;;;; Module Specific
	;;;;; Type : Return from Module to Main
	
    PUSH BP
	PUSH DS
	;Save BP,DS ;any changes to BP,DS here 
	;shouldn't reflect main program

	MOV AX,Data_segment_name_WelScr ; load the starting address of the data
	MOV DS,AX ; segment into DS reg.	
	MOV BP,SP
	;To  Pass a value from here  	
	;Through the stack to the main program
	;Store them in the allocated area beyond CS,IP,BP 
	
	;i.e. MOV [BP]+44+(6),Data2 to store first char in first allocated string :user name 
	;i.e. MOV [BP]+44+(6)-i,Data2 to store i+1 th char in first allocated string :user name 
	
	;i.e. MOV [BP]+22+(6),Data2 to store first char in second allocated string :file name 
	;i.e. MOV [BP]+22+(6)-i,Data2 to store i+1 th char in second allocated string :file name 
	;;;;;;;;;;;;;;;;; Module Specific End
	

	
	;Set the Video Mode [Text Mode]
	;VGA Card 80*25   9*16 ResPerChar
	MOV AL,03H
	MOV AH,00H
	INT 10H
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Display The Welcome Screen
	;Set the cursor position 
	MOV DH,8;Row
	MOV DL,10;Column
	MOV AH,2
	INT 10H
	;Write the String
	LEA DX,MsgWelcome
	MOV AH,09H
	INT 21H
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Display The UserName Input Message
	;Set the cursor position 
	MOV DH,10;Row
	MOV DL,20;Column
	MOV AH,2
	INT 10H
	;Write the String
	LEA DX,MsgInUname
	MOV AH,09H
	INT 21H
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Read the User Name
	LEA DX,UserName1
	MOV AH,0Ah
	INT 21H
	;MsgInUname first byte is max size 
	;Second byte is actual size after invoking above interrupt
	;Append $ at the end of the string
	MOV BH,00H
	MOV BL,UserName1[1]
	MOV UserName1[BX+2],'$'
	;; %% Debug Point 
	;LEA DX,UserName1+2
	;MOV AH,09H
	;INT 21H
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Display The ProjectName Input Message
	;Set the cursor position 
	MOV DH,13;Row
	MOV DL,20;Column
	MOV AH,2
	INT 10H
	;Write the String
	LEA DX, MsgInFileName
	MOV AH,09H
	INT 21H
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;Read the User Name
	LEA DX,FileName1
	MOV AH,0Ah
	INT 21H
	;MsgInUname first byte is max size 
	;Second byte is actual size after invoking above interrupt
	;Append $ at the end of the string
	MOV BH,00H
	MOV BL, FileName1[1]
	MOV FileName1 [BX+2],'$'
	
	
	;;;;;;;;;;;;;;;; Module Specific
	;;;;; Prepare Value be passed to main
	;Loop Over UserName1 Length
	;MOV CH,00H
	;MOV CL,UserName1[1]

	;i.e. MOV [BP]+44+(6),Data2 to store first char in first allocated string :user name 
	;i.e. MOV [BP]+44+(6)-i,Data2 to store i+1 th char in first allocated string :user name 
	
	;i.e. MOV [BP]+22+(6),Data2 to store first char in second allocated string :file name 
	;i.e. MOV [BP]+22+(6)-i,Data2 to store i+1 th char in second allocated string :file name 
	
	MOV CX,22
	;Transfer UserM
	MOV SI,00
	MOV DI,Str1Offset
TRA1:
	MOV AL,UserName1[SI]
	MOV SS:[BP+DI],AL 
	INC SI
	DEC DI
	LOOP TRA1
	
	; to store first returned value
	;Loop Over UserName1 Length
	;MOV CH,00H
	
	;MOV CL, FileName1[1]
	MOV CX,22
	;Transfer UserM
	MOV SI, 00
	MOV DI, Str2Offset
TRA2:
	MOV AL,FileName1 [SI]
	MOV SS:[BP+DI], AL
	INC SI
	DEC DI
	LOOP TRA2
	;;;;
	POP DS
	POP BP
	;;;;;;;;;;;;;;;;; Module Specific End
	RETF ; RET Will Make a near return   
WelScr  ENDP
Code_segment_name ends
end