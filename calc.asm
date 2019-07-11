INCLUDE library.inc

STACK SEGMENT
     DB 128 DUP(?)
STACK ENDS

DATA SEGMENT
     RESULT  DW 10 DUP(0)
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, SS:STACK, DS:DATA
 START:   
     MOV AX, DATA
     MOV DS, AX  ; DATA -> DS

     MOV ES, AX

	 MOV AX,0030H  ; 0030H对应字符0
     PUSH AX
     PUSH AX
	 PUSH AX
	 PUSH AX    

     MOV CL, 0 
; 读第一个操作数   
  COUNT_READ:    
     CALL CHECKNUM  ; 键盘读取字符
     CMP AL,0DH     
     JZ COUNT_READ
     CMP AL, 008H
     JNZ CONTINUE
     PRINT 0DH
     MOV CL, 0
     JMP START
  CONTINUE:  
     PRINT AL       ; 输出AL中的内容
     ; 判断操作符以更改DI中的值
     ;  DI  OP
     ;   0   -
     ;   1   +
     ;   2   *
     ;   3   /

     CMP AL, '-'    
     JNZ NEXT1      
     MOV DI, 0    
     JMP DONE2
  NEXT1:CMP AL, '+'      ; 是否为加号
     JNZ NEXT2     ; 不为加号跳到NEXT2
     MOV DI, 1    
     JMP DONE2 
  NEXT2:CMP AL, '*'
     JNZ NEXT3
     MOV DI, 2
     JMP DONE2
  NEXT3:CMP AL, '/'
     JNZ NEXT4
     MOV DI, 3
     JMP DONE2
  NEXT4:  ; 是数字的话入栈
     MOV AH, 0
     PUSH AX  ; 数字入栈

     INC CL  
     CMP CL, 4       ; 16bit最多4位16进制数
     JNZ COUNT_READ
 FORCE_OP:
     CALL CHECKNUM           
     CMP AL, '-' 
     JNZ CHECKP    
     MOV DI, 0    
     JMP FIN
  CHECKP:
     CMP AL, '+'
     JNZ CHECKM
     MOV DI, 1
     JMP FIN
  CHECKM:
     CMP AL, '*'
     JNZ CHECKD
     MOV DI, 2
     JMP FIN
  CHECKD:
     CMP AL, '/'
     JNZ FORCE_OP
     MOV DI, 3
 FIN:
     PRINT AL

; 输入了第一个操作数和操作符之后
; POP出栈中字符，转为数值存到BX                   
   DONE2:            
     POP AX
     POP CX
     MOV CH,CL
	 MOV CL,0
     OR AX, CX
     CALL THE_TWO    
     MOV BL, AL
     POP AX
     POP CX
     MOV CH,CL
	 MOV CL,0
     OR AX, CX   
     CALL THE_TWO
     MOV BH, AL   
                          
     MOV AX,0030H
     PUSH AX
     PUSH AX
	 PUSH AX
	 PUSH AX      
     MOV CL, 0

;读第二个操作数
 COUNT_READ2: 
     CALL CHECKNUM  
     CMP AL,'-'
     JZ COUNT_READ2
     CMP AL,'+'     
     JZ COUNT_READ2
     CMP AL, 0DH      ; 回车以计算
     JZ DONE3
     PRINT AL 
     MOV AH, 0
     PUSH AX
     INC CL  
     CMP CL, 4      
     JNZ COUNT_READ2
  FORCE_ENTER:      
     CALL CHECKNUM
     CMP AL, 0DH
     JNZ FORCE_ENTER
                 
   DONE3:           
     POP AX
     POP DX
     MOV DH,DL
	 MOV DL,0
     OR AX, DX
     CALL THE_TWO    
     MOV CL, AL
     POP AX
     POP DX
     MOV DH,DL
	 MOV DL,0
     OR AX, DX   
     CALL THE_TWO
     MOV CH, AL  
     ; CX中存放了第二个操作数
              
         
     PRINT '='

     CMP DI, 0         
     JZ  SUBTRACTION
     CMP DI, 1
	 JZ  ADDITION
     CMP DI, 2
     JZ MULTIPLICATION
     CMP DI, 3
     JZ DIVISION

 ADDITION:
     PRINT '+'
     ADD BX, CX          
     JMP NEXT0

 SUBTRACTION:
     CMP BX,CX  ; BX < CX的时候产生借位
     JNC DOSUB  ; JNC 无进位时转移
     PRINT '-'
     MOV DI,5   ; 表明为负数
     SUB BX,CX
     NEG BX     ; 取补码
     JMP NEXT0
          
    DOSUB:SUB BX,CX

 MULTIPLICATION:
     MOV AL, BL
     MUL CL
     MOV BX, AX
     JMP NEXT0
     
 DIVISION:
     MOV AX, BX
     DIV CL
     MOV BL, AL
     MOV BH, 0
     JMP NEXT0
; 计算完结果后存放在BX中       
 NEXT0:
	 MOV DX,0		
     MOV AL, BH          
     CALL THE_ONE       
	 CMP AH,'0'
	 JNZ MOV1
	 INC DL
	 JMP MOV2
MOV1:PRINT AH	
MOV2:CMP AL,'0'
	 JNZ MOV3
	 CMP DL,1
	 JNZ MOV3
	 INC DL
	 JMP MOV4
MOV3:PRINT AL
MOV4:MOV AL, BL        
     CALL THE_ONE
   	 CMP AH,'0'
	 JNZ MOV5
	 CMP DL,2
	 JNZ MOV5
	 JMP MOV6
MOV5:PRINT AH		
MOV6:PRINT AL
MOV AL, BL         
              
              
          
     PRINT '='      
     CMP DI,5
     JNZ NO_MINUS       
     PRINT '-' 
 NO_MINUS:     
     CALL SHOW_BCD
      
                                        
     PRINT 0AH
     PRINT 0DH                                        
     JMP START                          

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;                                                                    

; 输入：AL，两个十六进制数，比如，A9
; 输出：AX，两个十六进制数的ASCII码，'A' '9'
THE_ONE:    
          PUSH BX
          MOV BL, AL         
          AND AL, 0F0H    
		  
		  MOV AH,0
          PUSH DX
		  MOV BH,16
		  DIV BH
		  POP DX
		  
          CMP AL, 9H        
          JLE ISDEC       
          ADD AL, 37H       
          JMP OK
    ISDEC:ADD AL, 30H        
    OK:   MOV AH, AL          
          MOV AL, BL
          AND AL, 0FH         
          CMP AL, 9H
          JLE ISDEC2
          ADD AL, 37H
          JMP OK2
   ISDEC2:ADD AL, 30H              
          OK2:                    
          POP BX
          RET
    
; 输入：AX AH和AL中各一个字符，比如： 'A' '9'
; 输出：AL 数值， A9
THE_TWO:    
          CMP AL, 39H         ; 字符9
          JLE ARITHMOS
          CMP AL, 46H         ; 字符F
          JLE MIKR
          SUB AL, 57H         ; 字符f
          JMP NEXT
                                    
  MIKR:   SUB AL, 37H        
          JMP NEXT

 ARITHMOS:SUB AL, 30H   

  NEXT:   CMP AH, 39H   
          JLE ARITHMOT
          CMP AH, 46H
          JLE MIKRO2
          SUB AL, 57H
          JMP TDONE

 MIKRO2:  SUB AH, 37H
          JMP TDONE

 ARITHMOT:SUB AH, 30H

  TDONE:  PUSH DX
		  PUSH BX
		  MOV BL,AL
		  MOV AL,AH
		  MOV AH,0
          ; 乘法左移4位
		  MOV DX,16  
		  MUL DX    ; 高位在DX中 低位在AX中
          OR AL, BL     
		  POP BX
		  POP DX
          RET


; 减10法
DEGRADE:        
    CMP AX,10  
    JC thend
    INC DX
    SUB AX,10
    JMP DEGRADE
   thend:
    ret

SHOW_BCD:  
    MOV AX,BX
    MOV DX,0
    call DEGRADE  
    PUSH AX     ; units @ stack
    MOV AX,DX
    MOV DX,0 
    call DEGRADE
    PUSH AX      ; tens @ stack
    MOV AX,DX
    MOV DX,0
    call DEGRADE ; 
    PUSH AX     ; hundreds @ stack 
    MOV AX,DX
    MOV DX,0
    call DEGRADE ; 
    PUSH AX     ; thousands @ stack
    MOV AX,DX
    MOV DX,0
    call DEGRADE ; ten-thousands @ AL
    
	
	MOV BX,0	
	CMP AL,0
	JNZ MOD1
	INC BL
	JMP MOD2
MOD1:ADD AL,'0'
    PRINT AL   ;show ten-thousands
MOD2:POP DX
	CMP DL,0
	JNZ MOD3
	CMP BL,1
	JNZ MOD3
	INC BL
	JMP MOD4
MOD3:ADD DL,'0'
    PRINT DL   ; show thousands
MOD4:POP DX
	CMP DL,0
	JNZ MOD5
	CMP BL,2
	JNZ MOD5
	INC BL
	JMP MOD6
MOD5:ADD DL,'0'
    PRINT DL   ;show hundreds
MOD6:POP DX
	CMP DL,0
	JNZ MOD7
	CMP BL,3
	JNZ MOD7
	JMP MOD8
MOD7:ADD DL,'0'
    PRINT DL   ;show tens
MOD8:POP DX
    ADD DL,'0'
    PRINT DL   ;show units
    RET        

CHECKNUM: 
     MOV AH, 8
     INT 21H
     CMP AL, 1BH
     JZ THE_END
     CMP AL, 08H
     JZ DONE0
     CMP AL, '-'
     JZ DONE0
     CMP AL, '+'
     JZ DONE0
     CMP AL, '*'
     JZ DONE0
     CMP AL, '/'
     JZ DONE0    
     CMP AL, 0DH  ; 回车
     JZ DONE0
     CMP AL, 30H  ; 字符0
     JL ERROR
     CMP AL, 30H
     JL ERROR
     CMP AL, 39H  ; 字符9
     JLE DONE0
     CMP AL, 41H  ; 字符A
     JL ERROR
     CMP AL, 46H  ; 字符F
     JLE DONE0
     CMP AL, 61H  ; 字符a
     JL ERROR
     CMP AL, 66H  ; 字符f
     JLE DONE0
   ERROR:    JMP CHECKNUM
   DONE0:    RET              

		  
THE_END:
	MOV AH,4CH
	INT 21H
CODE ENDS
END
