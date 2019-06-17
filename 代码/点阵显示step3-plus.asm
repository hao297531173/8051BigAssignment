;==================================
;程序名：51单片机控制16*16LED点阵显示
;作者：  呼啦啦
;完成时间：  2019-6-10
;step 3 
;完成功能：使用外部中断控制显示模式
;==================================

;============================================
;基本功能介绍：
;使用74HC154进行列选通，p2.0-p2.3作为地址输入口
;一共有16个输出位，分别控制16列
;p0口作为上8行字形码输出口
;p1口作为下8行字形码输出口
;============================================

;==========
;常量表
;常量表报错
;不知道为什么
;==========


;===========
;中断向量表
;===========
ORG   0000H
    SJMP MAIN   ;跳转到主程序
ORG   0003H     ;外中断0
    SJMP EXP0    
ORG   000BH     ;定时器0
    SJMP ETP0
ORG   0013H     ;外中断1
    SJMP EXP1
ORG   001BH     ;定时器1
    RETI
ORG   0023H     ;串行口中断
    RETI

;==========
;初始化程序
;==========
MAIN:   MOV SP, #5FH    ;初始化堆栈指针
        MOV IE, #85H    ;1000 0101B,开外部中断0和1
        SETB EX0        ;开中断
        SETB EX1
        SETB ET0        ;开定时器0中断
        SETB TR0       
        SETB PX0        ;设置外部中断优先级为高优先级
        SETB PX1 
        MOV TMOD, #10H  ;设置工作模式为1,16位计数模式
        MOV TH0, #00H   ;计数64k*1us进行一次中断
        MOV TH1, #00H   ;64ms也就是0.064秒
        MOV R5, #1
M1:     DJNZ R5, M2 
        SETB ET0        ;开定时器0中断 
        MOV R5, #1
M2:     ACALL DISPLAY   ;不断显示初始开机画面
        SJMP M1


;================
;定时器0中断程序
;================
ETP0:   PUSH 07H
        CLR ET0         ;关定时器0中断
        MOV R7, #1       ;*****这里控制显示的次数******
ET11:   ACALL DISPLAYET
        DJNZ R7, ET11
        MOV TH0, #00H   ;计数64k*1us进行一次中断
        MOV TH1, #00H   ;64ms也就是0.064秒
        POP 07H
        RETI


;================
;外部中断0中断程序
;控制汉字滚动显示
;=================
EXP0:   CLR ET0 
E1:    MOV R7, #4H     ;****这里控制要显示的字数****
        MOV R6, #00H    ;这是DPTR的偏移量，这个值不需要修改
E2:     ACALL DISPLAY1
        DJNZ R7, E2
        SETB ET0
        RETI

;=================
;外部中断1中断程序
;控制汉字闪烁显示
;================
EXP1:   CLR ET0
H1:     MOV R7, #4H     ;****这里控制要显示的字数****
        
H2:     ACALL DISPLAY2
        DJNZ R7, H2
        SETB ET0
        RETI

;===============================
;显示主程序
;显存为30H开始的32个内存单元
;P0口控制低8位字形码
;P1口控制高8位字形码
;P2口控制字位码
;P2.7口为高电平的时候不选通任何一列
;先送字形码，后送字位码
;然后调用延时子程序后再显示下一列
;显示完一个字后
;================================
;这是定时器0触发中断时进入的显示程序
DISPLAYET:  ACALL GET0       ;先将下一帧送入显存
            PUSH 00H
            PUSH 01H
            PUSH 02H
            PUSH 03H
            PUSH 04H
            MOV R4, #20H   ;****这里控制循环次数****
            ;初始化部分
D001:       MOV R0, #30H    ;用作上半部分显示内容指针
            MOV R1, #30H+10H;用作下半部分显示内容指针
            MOV R2, #10H    ;进行显示内容控制
            MOV R3, #00H    ;用作字位码
            CLR A
            MOV P0, A
            MOV P1, A
            SETB P2.7
            ;显示部分
D002:       MOV P0, @R0     ;将低8位字形码送入P0口
            MOV P1, @R1     ;将高8位字形码送入P1口
            MOV P2, R3      ;将字位码送入P2口
            CLR P2.7        ;将P2.7口置0表示可以显示
            ACALL DELAY5    ;延时0.5ms
            SETB P2.7       ;关闭显示
            INC R0
            INC R1
            INC R3
            DJNZ R2, D002
            DJNZ R4, D001
            POP 04H
            POP 03H
            POP 02H
            POP 01H
            POP 00H
            RET




;这是没有触发中断时的显示
DISPLAY:    
            ACALL GET       ;先将下一帧送入显存
            PUSH 00H
            PUSH 01H
            PUSH 02H
            PUSH 03H
            PUSH 04H
            MOV R4, #20H   ;****这里控制循环次数****
            ;初始化部分
D01:         MOV R0, #30H    ;用作上半部分显示内容指针
            MOV R1, #30H+10H;用作下半部分显示内容指针
            MOV R2, #10H    ;进行显示内容控制
            MOV R3, #00H    ;用作字位码
            CLR A
            MOV P0, A
            MOV P1, A
            SETB P2.7
            ;显示部分
D02:         MOV P0, @R0     ;将低8位字形码送入P0口
            MOV P1, @R1     ;将高8位字形码送入P1口
            MOV P2, R3      ;将字位码送入P2口
            CLR P2.7        ;将P2.7口置0表示可以显示
            ACALL DELAY5    ;延时0.5ms
            SETB P2.7       ;关闭显示
            INC R0
            INC R1
            INC R3
            DJNZ R2, D02
            DJNZ R4, D01
            POP 04H
            POP 03H
            POP 02H
            POP 01H
            POP 00H
            RET


;这是滚动显示
DISPLAY1:    
            PUSH 00H
            PUSH 01H
            PUSH 02H
            PUSH 03H
            PUSH 04H
            PUSH 05H
            MOV R5, #10H    ;一个字显示16次能显示完，每次都向左偏移一个单位
D13:         ACALL GET1     ;先将下一帧送入显存
            MOV R4, #10H   ;****这里控制循环次数，也就是一个字显示多久****
            ;初始化部分
D11:         MOV R0, #30H    ;用作上半部分显示内容指针
            MOV R1, #30H+10H;用作下半部分显示内容指针
            MOV R2, #10H    ;进行显示内容控制
            MOV R3, #00H    ;用作字位码
            CLR A
            MOV P0, A
            MOV P1, A
            SETB P2.7
            ;显示部分
D12:         MOV P0, @R0     ;将低8位字形码送入P0口
            MOV P1, @R1     ;将高8位字形码送入P1口
            MOV P2, R3      ;将字位码送入P2口
            CLR P2.7        ;将P2.7口置0表示可以显示
            ACALL DELAY5    ;延时0.5ms
            SETB P2.7       ;关闭显示
            INC R0
            INC R1
            INC R3
            DJNZ R2, D12
            DJNZ R4, D11
            DJNZ R5, D13     ;控制一个字显示16次，每次偏移一个单位
            POP 05H
            POP 04H
            POP 03H
            POP 02H
            POP 01H
            POP 00H
            RET


;这是闪烁显示程序
DISPLAY2:    ACALL GET2       ;先将下一帧送入显存
            PUSH 00H
            PUSH 01H
            PUSH 02H
            PUSH 03H
            PUSH 04H
            MOV R4, #20H   ;****这里控制循环次数****
            ;初始化部分
D21:         MOV R0, #30H    ;用作上半部分显示内容指针
            MOV R1, #30H+10H;用作下半部分显示内容指针
            MOV R2, #10H    ;进行显示内容控制
            MOV R3, #00H    ;用作字位码
            CLR A
            MOV P0, A
            MOV P1, A
            SETB P2.7
            ;显示部分
D22:         MOV P0, @R0     ;将低8位字形码送入P0口
            MOV P1, @R1     ;将高8位字形码送入P1口
            MOV P2, R3      ;将字位码送入P2口
            CLR P2.7        ;将P2.7口置0表示可以显示
            ACALL DELAY5    ;延时0.5ms
            SETB P2.7       ;关闭显示
            INC R0
            INC R1
            INC R3
            DJNZ R2, D22
            DJNZ R4, D21
            POP 04H
            POP 03H
            POP 02H
            POP 01H
            POP 00H
            RET








;================================
;子程序名：送数子程序
;将字形码送入30H开始的32个内存单元
;实现滚动只要是修改这部分代码
;用到R1 R2 A DPTR
;================================
;触发了定时器中断的时候的送数
GET0:   PUSH 01H    ;将R1的值入栈
        PUSH 02H    ;将R2的值入栈
        MOV R1, #30H ;指向显存的起始地址
        MOV R2, #20H ;控制送数个数
        MOV DPTR, #INIT0
G001:     CLR A
        MOVC A, @A+DPTR
        MOV @R1, A
        INC DPTR
        INC R1
        DJNZ R2, G001
        POP 02H
        POP 01H
        RET

;没有触发中断时候的送数
GET:    PUSH 01H    ;将R1的值入栈
        PUSH 02H    ;将R2的值入栈
        MOV R1, #30H ;指向显存的起始地址
        MOV R2, #20H ;控制送数个数
        MOV DPTR, #INIT
G01:     CLR A
        MOVC A, @A+DPTR
        MOV @R1, A
        INC DPTR
        INC R1
        DJNZ R2, G01
        POP 02H
        POP 01H
        RET


;滚动显示送数
GET1:    PUSH 01H    ;将R1的值入栈
        PUSH 02H    ;将R2的值入栈
        PUSH 03H
        ;先送上16个字节
        MOV R1, #30H ;指向显存的起始地址
        MOV R2, #10H ;控制送数个数
        MOV DPTR, #TAB1   ;每一帧都比上一帧偏移一个单位
        PUSH 06H
I11:     INC DPTR        ;加上偏移量
        DJNZ R6, I11
        POP 06H
G11:     CLR A
        MOVC A, @A+DPTR
        MOV @R1, A
        INC DPTR
        INC R1
        DJNZ R2, G11
        ;接着送下16字节
        MOV R2, #10H    ;控制送数个数
        MOV DPTR, #TAB2
        PUSH 06H
I12:     INC DPTR        ;加上偏移量
        DJNZ R6, I12
        POP 06H
G12:     CLR A
        MOVC A, @A+DPTR
        MOV @R1, A
        INC DPTR
        INC R1
        DJNZ R2, G12
        
        ;完成出栈后返回
        POP 03H
        POP 02H
        POP 01H
        INC R6
        RET

;这是闪烁显示送数
GET2:   PUSH 01H    ;将R1的值入栈
        PUSH 02H    ;将R2的值入栈
        MOV R1, #30H ;指向显存的起始地址
        MOV R2, #20H ;控制送数个数
G21:     CLR A
        MOVC A, @A+DPTR
        MOV @R1, A
        INC DPTR
        INC R1
        DJNZ R2, G21
        POP 02H
        POP 01H
        RET

;=============================
;子程序名：延时约0.5ms
;51单片机频率为12MHz
;时钟周期为1/12M s
;一个机器周期等于12个时钟周期
;所以一个机器周期为1us
;想要延时5ms就需要执行500条指令
;需要修改延时时间只要修改R7和R6即可
;=============================
DELAY5: PUSH 07H
        PUSH 06H
        MOV R6, #2
LAB1:   MOV R7, #250
LAB2:   DJNZ R7, LAB2
        DJNZ R6, LAB1
        POP 06H
        POP 07H
        RET             ;子程序返回


;================================
;字位码表，用于控制列选通
;只有选通的那一列是低电平
;其他列都是高电平
;这些数值都要送入P2口进行字位选通信号
;=================================
;字位码一直是从0-16，所以不用存了


;=============
;这里储存字形码
;=============
ORG 1000H
;一开始屏幕一半亮一半暗
INIT: db 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH
      db 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH
      db 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        db 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
;触发定时器0中断的时候的显示内容
INIT0:  db 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        db 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
        db 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH
      db 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH, 0FFH
;这是闪烁显示
TAB: db  08h, 28h, 48h, 88h, 68h, 18h, 00h,0FCh     ;"鸡"
	 db	 06h, 15h, 44h, 84h, 7Eh, 04h, 00h, 00h
	 db	 10h, 08h, 06h, 01h, 02h, 14h, 10h, 13h
	 db	 12h, 12h, 1Ah, 52h, 82h, 7Fh, 02h, 00h

	db   40h, 20h,0F8h, 07h, 40h, 20h, 18h, 0Fh     ;"你"
	db	 08h,0C8h, 08h, 08h, 28h, 18h, 00h, 00h
	db	 00h, 00h,0FFh, 00h, 00h, 08h, 04h, 43h
	db	 80h, 7Fh, 00h, 01h, 06h, 0Ch, 00h, 00h

	db   20h, 20h, 20h, 20h, 20h, 20h, 20h,0FFh     ;"太"
	db	 20h, 20h, 20h, 20h, 20h, 30h, 20h, 00h
	db	 40h, 40h, 20h, 20h, 10h, 0Ch, 0Bh, 30h
	db	 03h, 0Ch, 10h, 10h, 20h, 60h, 20h, 00h

	db   80h, 88h,0A8h,0A8h,0A9h,0AAh,0AEh,0F8h     ;"美"
	db	 0ACh,0AAh,0ABh,0A8h,0ACh, 88h, 80h, 00h
	db	 80h, 84h, 84h, 44h, 44h, 24h, 14h, 0Fh
	db	 14h, 24h, 24h, 44h, 46h,0C4h, 40h, 00h


;这是滚动显示
;这是上半部分
TAB1: db  08h, 28h, 48h, 88h, 68h, 18h, 00h,0FCh     ;"鸡"
	 db	 06h, 15h, 44h, 84h, 7Eh, 04h, 00h, 00h

	 

	db   40h, 20h,0F8h, 07h, 40h, 20h, 18h, 0Fh     ;"你"
	db	 08h,0C8h, 08h, 08h, 28h, 18h, 00h, 00h

	

	db   20h, 20h, 20h, 20h, 20h, 20h, 20h,0FFh     ;"太"
	db	 20h, 20h, 20h, 20h, 20h, 30h, 20h, 00h

	

	db   80h, 88h,0A8h,0A8h,0A9h,0AAh,0AEh,0F8h     ;"美"
	db	 0ACh,0AAh,0ABh,0A8h,0ACh, 88h, 80h, 00h

    ;这是中间需要预留的一部分
    DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
    DB 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H

;这是下半部分
TAB2: db	 10h, 08h, 06h, 01h, 02h, 14h, 10h, 13h ;"鸡"
	 db	 12h, 12h, 1Ah, 52h, 82h, 7Fh, 02h, 00h

     db	 00h, 00h,0FFh, 00h, 00h, 08h, 04h, 43h     ;"你"
	db	 80h, 7Fh, 00h, 01h, 06h, 0Ch, 00h, 00h

    db	 40h, 40h, 20h, 20h, 10h, 0Ch, 0Bh, 30h     ;"太"
	db	 03h, 0Ch, 10h, 10h, 20h, 60h, 20h, 00h

    db	 80h, 84h, 84h, 44h, 44h, 24h, 14h, 0Fh     ;"美"
	db	 14h, 24h, 24h, 44h, 46h,0C4h, 40h, 00h
END

