# 8051单片机大作业
### 写在前面的话
这个项目致力于帮助迷途中的孩子完成单片机大作业，我将分成三步给出代码<br>
- step1：基本的闪烁显示字符 [戳我看代码](https://github.com/hao297531173/8051BigAssignment/blob/master/%E4%BB%A3%E7%A0%81/%E7%82%B9%E9%98%B5%E6%98%BE%E7%A4%BAstep1.asm)
- step2：滚动显示字符 [戳我看代码](https://github.com/hao297531173/8051BigAssignment/blob/master/%E4%BB%A3%E7%A0%81/%E7%82%B9%E9%98%B5%E6%98%BE%E7%A4%BAstep2-left.asm)
- step3：中断按钮切换显示模式 [戳我看代码](https://github.com/hao297531173/8051BigAssignment/blob/master/%E4%BB%A3%E7%A0%81/%E7%82%B9%E9%98%B5%E6%98%BE%E7%A4%BAstep3.asm)
- step3-plus：定时器0控制无中断时上半部分和下半部分切换显示 [戳我看代码](https://github.com/hao297531173/8051BigAssignment/blob/master/%E4%BB%A3%E7%A0%81/%E7%82%B9%E9%98%B5%E6%98%BE%E7%A4%BAstep3-plus.asm)
### 试验环境
试验需要用到的软件我都放到[软件都在我这](https://github.com/hao297531173/8051BigAssignment/tree/master/%E8%BD%AF%E4%BB%B6%E9%83%BD%E5%9C%A8%E6%88%91%E8%BF%99)文件夹了，仿真电路图是`16X16.DSN`，我连的线应该是存在`16X16.PWI`，反正按照那个思路连线就对了，你可以下载原版电路图自己连线，编写汇编代码我推荐使用vscode，嗯，就这些。下面我们就进入正题<br>
### step1：基本的闪烁显示字符
[原代码点我](https://github.com/hao297531173/8051BigAssignment/blob/master/%E4%BB%A3%E7%A0%81/%E7%82%B9%E9%98%B5%E6%98%BE%E7%A4%BAstep1.asm)<br>
我们先来看一下电路图<br>
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E5%9B%BE%E7%89%87/%E7%94%B5%E8%B7%AF%E5%9B%BE.PNG)<br>
可以看到，我将P0口和P1口用来控制灯的亮灭，用P2口的低4位来控制选通那一列<br>
地址译码的时候我们用到74HC154 4-16路译码器，他的真值表如下<br>
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E5%9B%BE%E7%89%87/74HC154%E7%9C%9F%E5%80%BC%E8%A1%A8.PNG)<br>
我们发现，只有当使能端E1和E2都为低电平的时候译码器才有效，所以我们将E2接P2.7来控制译码器选通和不选通。(这一步其实不做也行)<br>
下面我来简要介绍一下16*16LED电路的控制方式。LED电路一共有16*2个接口，左边16个接口控制灯亮还是灭（P1,P2口），高电平亮，低电平灭；右边的控制选通哪一列有效，低电平有效。<br>
上面的内容都了解了之后就很简单啦，那我就开始说代码了。<br>
我们将30H开始的内存单元作为显存，因为是16*16的led，所以一帧需要32BYTE的显存，我们在显示一帧之前，先将待显示的内容送入显存<br>
```
;================================
;子程序名：送数子程序
;将字形码送入30H开始的32个内存单元
;用到R1 R2 A DPTR
;================================
GET:    PUSH 01H    ;将R1的值入栈
        PUSH 02H    ;将R2的值入栈
        MOV R1, #30H ;指向显存的起始地址
        MOV R2, #20H ;控制送数个数
G1:     CLR A
        MOVC A, @A+DPTR
        MOV @R1, A
        INC DPTR
        INC R1
        DJNZ R2, G1
        POP 02H
        POP 01H
        RET
```
这就是我们之前做过的程序，将程序储存器中的字形表送入数据储存器中30H开始的32个内存单元，注意，取数的时候要用**MOVC A, @A+DPTR**，这是从程序储存器取数的指令，送完数之后就可以开始显示啦。PS:PUSH和POP指令分别是推入堆栈和出栈的指令，后面要跟直接地址，00H就代表的是R0，01H就代表的是R1一次类推，如果要将累加器ACC入栈，那么应该写成PUSH ACC；还有，出栈和入栈的顺序要相反。<br>
```
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
DISPLAY:    ACALL GET       ;先将下一帧送入显存
            PUSH 00H
            PUSH 01H
            PUSH 02H
            PUSH 03H
            PUSH 04H
            MOV R4, #20H   ;****这里控制循环次数****
            ;初始化部分
D1:         MOV R0, #30H    ;用作上半部分显示内容指针
            MOV R1, #30H+10H;用作下半部分显示内容指针
            MOV R2, #10H    ;进行显示内容控制
            MOV R3, #00H    ;用作字位码
            CLR A
            MOV P0, A
            MOV P1, A
            SETB P2.7
            ;显示部分
D2:         MOV P0, @R0     ;将低8位字形码送入P0口
            MOV P1, @R1     ;将高8位字形码送入P1口
            MOV P2, R3      ;将字位码送入P2口
            CLR P2.7        ;将P2.7口置0表示可以显示
            ACALL DELAY5    ;延时0.5ms
            SETB P2.7       ;关闭显示
            INC R0
            INC R1
            INC R3
            DJNZ R2, D2
            DJNZ R4, D1
            POP 04H
            POP 03H
            POP 02H
            POP 01H
            POP 00H
            RET
```
有一个小细节要注意一下，能够用作寄存器间接寻址的寄存器（就是用寄存器当指针在数据储存器中取数）只有R0和R1，所以我们用他们两个来当指针，他们相距10H，R0指向的是上半LED显示的内容，R1指向的是下半LED显示的内容。用R3来控制显示哪一列，这个比较简单，直接赋初值为0，然后加一加一就行了，R2来进行次数控制，一共刷新16行，所以R2赋初值10H，每刷新完一行就减一，R4用来控制一个字显示的遍数，也就是R4可以控制一个字显示多久，刷新完一遍大概需要600条指令，也就是0.6ms，据此就能分析出显示一个字的时间了。<br>
最后再来看一下主程序
```
;==========
;初始化程序
;==========
MAIN:   MOV SP, #5FH    ;初始化堆栈指针
        MOV IE, #82H    ;1000 0010B,表示开总中断和EX1外部中断1
M1:     MOV DPTR, #TAB  ;将字形码其实地址送给DPTR，之后只要一直自增即可
        MOV R7, #4H     ;****这里控制要显示的字数****
M2:     ACALL DISPLAY
        DJNZ R7, M2
        SJMP M1
```
在这里初始化IE是没有必要的，因为没有用到中断，但是SP一定要初始化，因为我们有用到子程序的调用和堆栈。用DPTR+A作为字形表的指针，R7控制显示的字数，也就是说想要改变显示的字数直接改变R7的值就行了。让我们来看一下成果吧<br>
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E5%9B%BE%E7%89%87/step1Output.gif)<br>
#### 使用方法
在MAIN函数中将R7寄存器的值修改成你要显示的汉字数量，然后把要显示的汉字的字形码复制到TAB开始的地方就行了。<br>
[详细的代码解析戳我](https://blog.csdn.net/haohulala/article/details/91372488)<br>
### step2：滚动显示汉字
有了上一步的基础，我们现在就可以很轻松地开始写滚动显示的程序啦，为了方便起见，我们就写左移显示吧。<br>
#### 如何实现滚动
我们以向左滚动为例，实际上仔细观察后就会发现，想要实现向左滚动就是需要将字形码的起始地址向右偏移，这样汉字左边的部分就会消失，后面的汉字由于偏移就会出现出来。更直观一点说，你可以把屏幕想象成一个窗口，字向左滚动就相当于屏幕向右滚动，也就是起始指针向右偏移。<br>
#### 主程序
[源代码戳我](https://github.com/hao297531173/8051BigAssignment/blob/master/%E4%BB%A3%E7%A0%81/%E7%82%B9%E9%98%B5%E6%98%BE%E7%A4%BAstep2-left.asm)
```
;==========
;初始化程序
;==========
MAIN:   MOV SP, #5FH    ;初始化堆栈指针
        MOV IE, #82H    ;1000 0010B,表示开总中断和EX1外部中断1
M1:     MOV R7, #4H     ;****这里控制要显示的字数****
        MOV R6, #00H    ;这是DPTR的偏移量，这个值不需要修改
M2:     ACALL DISPLAY
        DJNZ R7, M2
        SJMP M1
```
主程序比step多了一个R6寄存器，用来存放字形码偏移量，赋初值为0<br>
```
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
DISPLAY:    
            PUSH 00H
            PUSH 01H
            PUSH 02H
            PUSH 03H
            PUSH 04H
            PUSH 05H
            MOV R5, #10H    ;一个字显示16次能显示完，每次都向左偏移一个单位
D3:         ACALL GET       ;先将下一帧送入显存
            MOV R4, #10H   ;****这里控制循环次数，也就是一个字显示多久****
            ;初始化部分
D1:         MOV R0, #30H    ;用作上半部分显示内容指针
            MOV R1, #30H+10H;用作下半部分显示内容指针
            MOV R2, #10H    ;进行显示内容控制
            MOV R3, #00H    ;用作字位码
            CLR A
            MOV P0, A
            MOV P1, A
            SETB P2.7
            ;显示部分
D2:         MOV P0, @R0     ;将低8位字形码送入P0口
            MOV P1, @R1     ;将高8位字形码送入P1口
            MOV P2, R3      ;将字位码送入P2口
            CLR P2.7        ;将P2.7口置0表示可以显示
            ACALL DELAY5    ;延时0.5ms
            SETB P2.7       ;关闭显示
            INC R0
            INC R1
            INC R3
            DJNZ R2, D2
            DJNZ R4, D1
            DJNZ R5, D3     ;控制一个字显示16次，每次偏移一个单位
            POP 05H
            POP 04H
            POP 03H
            POP 02H
            POP 01H
            POP 00H

```
显示程序和step1基本差不多，就是多了一步R5用来控制一个字的显示，每次显示一遍字都会向左移动一格，这样一来循环16次之后，一个字就完全移动出屏幕了，所以我们就用16次来作为一个周期，也就是说一个字一个周期。除此之外，都和step1的代码差不多<br>
```
;================================
;子程序名：送数子程序
;将字形码送入30H开始的32个内存单元
;实现滚动只要是修改这部分代码
;用到R1 R2 A DPTR
;================================
GET:    PUSH 01H    ;将R1的值入栈
        PUSH 02H    ;将R2的值入栈
        PUSH 03H
        ;先送上16个字节
        MOV R1, #30H ;指向显存的起始地址
        MOV R2, #10H ;控制送数个数
        MOV DPTR, #TAB1   ;每一帧都比上一帧偏移一个单位
        PUSH 06H
I1:     INC DPTR        ;加上偏移量
        DJNZ R6, I1
        POP 06H
G1:     CLR A
        MOVC A, @A+DPTR
        MOV @R1, A
        INC DPTR
        INC R1
        DJNZ R2, G1
        ;接着送下16字节
        MOV R2, #10H    ;控制送数个数
        MOV DPTR, #TAB2
        PUSH 06H
I2:     INC DPTR        ;加上偏移量
        DJNZ R6, I2
        POP 06H
G2:     CLR A
        MOVC A, @A+DPTR
        MOV @R1, A
        INC DPTR
        INC R1
        DJNZ R2, G2
        
        ;完成出栈后返回
        POP 03H
        POP 02H
        POP 01H
        INC R6
        RET
```
step1和step2最大的区别就是送数程序了，在step1中只需要简单的将32个数送入显存就行了，step2还需要计算偏移量。<br>

偏移量就是DPTR起始地址距离TAB标签的字节数，没经过一个循环就加一。<br>

但是如果用step1的字形表的话还是会出问题，因为我们直接是加一的，但是字形码的上半部分和下半部分是联合起来作为32个存储单元存储的，这就导致显示完一个字之后会有一个字的上半部分取了上一个字的下半部分；下半部分取了下一个字的上半部分，这样就会出问题。<br>

为了解决这个问题，我们就需要将字形码上半部分和下半部分分开存储，这样只需要一直加一就可以实现滚动了。<br>
```
;=============
;这里储存字形码
;=============
ORG 1000H
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
```
延时程序都是一样的，所以我这里就不介绍了。<br>
#### 来看看显示效果吧
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E5%9B%BE%E7%89%87/step2-output.gif)
### step3：使用外部中断控制显示模式
终于到了最后一步了，如果你看到这里了就说明你的作业快要完成了，✿✿ヽ(°▽°)ノ✿<br>
在这一步，我们要做的就是使用两个外部中断来控制显示模式的切换，具体来说就是，如果没有中断的话，我们就显示全亮。<br>

当外部中断EX0触发，我们就滚动显示汉字；当有外部中断EX1触发，我们就闪烁显示汉字，嗯，就是这么简单。来看一下电路图
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E5%9B%BE%E7%89%87/%E7%94%B5%E8%B7%AF%E5%9B%BEstep3.PNG)
如果你不熟悉51的中断系统，[请戳我](https://blog.csdn.net/haohulala/article/details/90768725)
因为我们要使用外部中断0和外部中断1，所以不仅要开总中断EA, 还要开EX0 和 EX1<br>
```
;==========
;初始化程序
;==========
MAIN:   MOV SP, #5FH    ;初始化堆栈指针
        MOV IE, #85H    ;1000 0101B,开外部中断0和1
        SETB EX0        ;开中断
        SETB EX1
M1:     ACALL DISPLAY   ;不断显示初始开机画面
        SJMP M1
```
然后就是两个中断程序，这个就是之前的滚动显示和闪烁显示的程序，没什么好说的<br>
```
;================
;外部中断0中断程序
;控制汉字滚动显示
;=================
EXP0:    
E1:    MOV R7, #4H     ;****这里控制要显示的字数****
        MOV R6, #00H    ;这是DPTR的偏移量，这个值不需要修改
E2:     ACALL DISPLAY1
        DJNZ R7, E2
        RETI
```
```
;=================
;外部中断1中断程序
;控制汉字闪烁显示
;================
EXP1:    
H1:     MOV R7, #4H     ;****这里控制要显示的字数****
        
H2:     ACALL DISPLAY2
        DJNZ R7, H2
        RETI
```
### 程序流程图如下
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E5%9B%BE%E7%89%87/%E6%B5%81%E7%A8%8B%E5%9B%BE.PNG)
[最终版完整代码请戳我](https://github.com/hao297531173/8051BigAssignment/blob/master/%E4%BB%A3%E7%A0%81/%E7%82%B9%E9%98%B5%E6%98%BE%E7%A4%BAstep3.asm)
#### 最后一期来看一下显示效果吧
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E5%9B%BE%E7%89%87/step3-output.gif)
[欢迎来我的博客围观](https://blog.csdn.net/haohulala/article/details/91401170)
### 最后的最后，来看看如何使用吧
[请点我找需要的字](https://github.com/hao297531173/8051BigAssignment/blob/master/word.txt)
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E5%9B%BE%E7%89%87/how.gif)


### step3-plus:添加了外部使用定时器0中断来控制没有中断时上下切换显示的效果
#### 主要说一下和step3相比改变的部分
#### 初始化程序
由于需要使用到定时器0，所以需要开启定时器0的中断允许触发位，并且开始定时器计时，还有中断寄存器TH0和TH1。同时需要设置外部中断为高优先级中断，这样就可以及时地相应外部中断了。<br>
```
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
```
#### 定时器0中断程序
定时中断程序逻辑上也是取数送数操作，所不同的是在进行中断处理的时候需要先将定时器0中断允许控制位置0。<br>
```
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
```
####  定时器中断0的送数程序
和之前的没有中断时候的送数程序相比只是开始取数的语句标号不同了<br>
```
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
```
#### 定时器0中断的显示程序
和之前没有中断的显示程序相比只是调用的取数子程序不同了<br>
```
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
```
#### 还需要注意的小细节
在外部中断处理程序开始的时候需要关闭定时器0中断，在中断返回之前再开启定时器0中断。<br>
```
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
```
```
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
```
#### 来看一下显示效果吧
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E5%9B%BE%E7%89%87/step3-plus.gif)
[完整代码戳我](https://github.com/hao297531173/8051BigAssignment/blob/master/%E4%BB%A3%E7%A0%81/%E7%82%B9%E9%98%B5%E6%98%BE%E7%A4%BAstep3-plus.asm)<br>
[我的博客](https://blog.csdn.net/haohulala/article/details/92661903)<br>
✿✿ヽ(°▽°)ノ✿<br>
✿✿ヽ(°▽°)ノ✿<br>
✿✿ヽ(°▽°)ノ✿<br>


