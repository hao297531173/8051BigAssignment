#8051大片机大作业
###写在前面的话
这个项目致力于帮助迷途中的孩子完成单片机大作业，我将分成三步给出代码<br>
- step1：基本的闪烁显示字符
- step2：滚动显示字符
- step3：中断按钮切换显示模式
###试验环境
试验需要用到的软件我都放到[软件都在我这](https://github.com/hao297531173/8051BigAssignment/tree/master/%E8%BD%AF%E4%BB%B6%E9%83%BD%E5%9C%A8%E6%88%91%E8%BF%99)文件夹了，仿真电路图是`16X16.DSN`，我连的线应该是存在`16X16.PWI`，反正按照那个思路连线就对了，你可以下载原版电路图自己连线，编写汇编代码我推荐使用vscode，嗯，就这些。下面我们就进入正题<br>
###step1：基本的闪烁显示字符
[原代码点我](https://github.com/hao297531173/8051BigAssignment/blob/master/%E7%82%B9%E9%98%B5%E6%98%BE%E7%A4%BAstep1.asm)<br>
我们先来看一下电路图<br>
![](https://github.com/hao297531173/8051BigAssignment/blob/master/%E7%94%B5%E8%B7%AF%E5%9B%BE.PNG)<br>
可以看到，我将P0口和P1口用来控制灯的亮灭，用P2口的低4位来控制选通那一列<br>
地址译码的时候我们用到74HC154 4-16路译码器，他的真值表如下<br>
![](https://github.com/hao297531173/8051BigAssignment/blob/master/74HC154%E7%9C%9F%E5%80%BC%E8%A1%A8.PNG)<br>
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
![](https://github.com/hao297531173/8051BigAssignment/blob/master/step1Output.gif)<br>
