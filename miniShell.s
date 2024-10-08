.section .text
.global _start

_start:
    bl main

main:
    bl showPrompt
    bl readUserInput
    @ bl displayUserInput @ temporarily kept for testing
    bl clearArgs
    bl executeCommand
    b main  @Infinity loop


@ Ask user to prompt with outputing "$ " on the display
@ Addtional parameters are not needed
showPrompt:
    push {r4-r11, lr}   @ follow arm convention
    ldr r0, =prompt @"$ "
    bl printf
    pop {r4-r11, pc} @ return


@ Simulate C's printf function
@ Take r0 as input(pointer to the string)
printf:
    push {r4-r11, lr}
    mov r1, r0  @ Load input string to r1
    bl strlen   @ get the length of the string
    mov r2, r0  @ r2 = length of the given string

    @ write to stdout
    mov r0, #1 @ stdout fd
    mov r1, r1 @ pinter to the string
    mov r2, r2 @ length of the string
    mov r7, #4 @ sys_write
    svc #0

    pop {r4-r11, pc}


@ Simulate C's strlen function
@ Take r0 as input(pointer to the string)
strlen:
    push {r4-r11, lr}
    mov r4, r0  @ Load input string(pointer to the string)
    mov r5, #0  @ Length

    @ iterate through the string
    strlenLoop:
        ldrb r6, [r4, r5]   @ load the data in the address of r4 offset by r5
        cmp r6, #0
        @ if == '\0'
        beq strlenLoopEnd
        @ else
        add r5, r5, #1  @ length++
        b strlenLoop

    strlenLoopEnd:
        mov r0, r5  @ return length, follow arm convention
        pop {r4-r11, pc}


@ Simulate C's strcpy function
@ Take r0 as source string, r1 as destination string
@ Return the pointer to the des string
strcpy:
    push {r4-r11, lr}
    mov r4, r0  @ load source string
    mov r5, r1  @ load destination string

    strcpyLoop:
        ldrb r6, [r4]
        strb r6, [r5]
        cmp r6, #0
        beq strcpyEnd
        add r4, r4, #1
        add r5, r5, #1
        b strcpyLoop

    strcpyEnd:
        mov r0, r1  @ return pointer to des string
        pop {r4-r11, pc}


@ Simulate C's strcat function
@ Take r0 as source string, r1 as string to append
@ Return the pointer to the source string
strcat:
    push {r4-r11, lr}
    mov r4, r0  @ load source string
    mov r5, r1  @ load string to append
    bl strlen
    mov r6, r0  @ load length of the source string
    add r4, r6  @ move pointer to the end of the source string

    strcatLoop:
        ldrb r6, [r5]
        strb r6, [r4]
        cmp r6, #0
        beq strcatEnd
        add r4, r4, #1
        add r5, r5, #1
        b strcatLoop

    strcatEnd:
        mov r0, r0  @ return pointer to source string
        pop {r4-r11, pc}


@ Simulate C's strcmp function
@ Take r0 as first string, r1 as second string
strcmp:
    push {r4-r11, lr}
    strcmpLoop:
        ldrb r2, [r0]
        ldrb r3, [r1]
        cmp r2, r3
        bne strcmpNotEqual
        add r0, r0, #1
        add r1, r1, #1
        cmp r2, #0  @check if the string ends
        beq strcmpEqual
        b strcmpLoop

    strcmpNotEqual:
        mov r0, #1
        pop {r4-r11, pc}

    strcmpEqual:
        mov r0, #0
        pop {r4-r11, pc}



@ read user' s input by calling sys_read
@ bufferUser will be updated
@ Addtional parameters are not needed
readUserInput:
    push {r4-r11, lr}

    @ read from stdin
    mov r0, #0  @ stdin fd
    ldr r1, =bufferUser @ pointer to the buffer
    mov r2, #127    @ maximum load size(1 additional space for '\0')
    mov r7, #3  @ sys_read
    svc #0

    @ add '\0' for null terminated(or replacing '\n' with '\0')
    @ move r1 to the end of the string(+1)
    add r1, r1, r0  @ r0 store the return value of numbers of bytes read(return from sys_read)
    mov r2, #0  @ for null terminated
    sub r3, r1, #1  @ offset 1 address
    ldrb r4, [r3]   @ note: we can't directly use cmp to compare value with registers, so we load it to a register
    cmp r4, #0xa    @ compare it with '\n'
    @ if not '\n', directly add '\0'; otherwise, replace it
    bne endReadUserInput
        strb r2, [r3]
        pop {r4-r11, pc}

    endReadUserInput:
        strb r2, [r1]
        pop {r4-r11, pc}

@ prints the user input in the terminal(new line added for readability)
displayUserInput:
    push {r4-r11, lr}
    ldr r0, =bufferUser
    bl printf
    ldr r0, =newline
    bl printf
    pop {r4-r11, pc}


@ handing commands with fork, child, parent and wait
@ Addtional parameters are not needed
executeCommand:
    push {r4-r11, lr}
    ldr r0, =bufferUser

    @ parse the command for later execution
    bl parseCommand
    cmp r0, #0  @ make sure the parse is done correctly
    bne endExecute

    @ test code for checking parsed result
    @ldr r0, =bufferUser
    @ldr r0, =bufferFilename
    @ldr r0, =arg0
    @ldr r0, =arg1
    @bl printf

    @ check if command is 'cd'
    ldr r0, =arg0
    ldr r1, =cdCommand
    bl strcmp
    @ if true, handle cd command separately
    cmp r0, #0
    bne notCdCommand
    bl cd
    b endExecute

notCdCommand:
    @ prepend '/usr/bin/' to arg0
    bl checkPath

    @ else, fork the process
    bl fork
    cmp r0, #0  @ fork returns 0 if a child process, pid a parent process
    beq child   @ if we're in child process, run child
    bl wait @ if we're in parent process, wait until child process ends

    endExecute:
        pop {r4-r11, pc}


@ see if user specified a path, otherwise add '/usr/bin/ at the beginning
@ can be extend for advanced parsing in the future
@ Addtional parameters are not needed
checkPath:
    push {r4-r11, lr}
    ldr r4, =arg0   @ load string
    ldrb r5, [r4]   @ read first byte
    cmp r5, #'/'    @ check if already specified
    beq endCheckPath
    bl addPath

    endCheckPath:
        pop {r4-r11, pc}


@ add '/usr/bin/ at the beginning of the given string
@ Addtional parameters are not needed
addPath:
    push {r4-r11, lr}
    @ copy bin path to buffer filename
    @ load parameters, r0: src, r1:dst
    ldr r0, =binPath
    ldr r1, =bufferFilename
    bl strcpy

    @ append arguments to buffer filename
    @ load parameters, r0: src, r1:str for cat
    ldr r0, =bufferFilename
    ldr r1, =arg0
    bl strcat

    pop {r4-r11, pc}


@ call sys_fork for forking
@ Addtional parameters are not needed
fork:
    push {r4-r11, lr}
    mov r7, #2  @ sys_fork
    svc #0
    pop {r4-r11, pc}


@ call sys_chdir for changing directory
cd:
    push {r4-r11, lr}
    ldr r0, =arg1   @ r0 for storing the file directory, which is arg1 in our case
    mov r7, #12  @ sys_chdir
    svc #0
    pop {r4-r11, pc}


@ call sys_execve
@ int execve(const char *filename, const char *const *argv, const char *const *envp);
child:
    push {r4-r11, lr}
    ldr r0, =bufferFilename
    ldr r1, =argv  @ place for argv
    @ mov r1, #0  @ place for argv, for no argument usage
    mov r2, #0  @ place for envp(environment pointer), hardcoded 0 for minimal usage
    mov r7, #0xb  @ sys_execve
    svc #0

    @ only run if execve fails
    mov r7, #1  @ sys_exit
    svc #0


@ call sys_wait for a parent
@ wait4(int *stat_addr, int options, struct rusage *ru)
wait:
    mov r7, #0x72   @ sys_wait(for arm linux kernel, sys_wait4)
    @ wait for any child for any status
    mov r0, #-1
    mov r1, #0     @ no status (NULL)
    mov r2, #0     @ no options
    mov r3, #0     @ no rusage (NULL)

    svc #0
    pop {r4-r11, pc}


@ parse the command to get the arguments for operation
@ returns 0 if parsed correctly
parseCommand:
    push {r4-r11, lr}
    ldr r0, =bufferUser
    ldr r1, =arg0  @ place for arg0(command)
    ldr r2, =arg1  @ place for arg1
    mov r3, #0  @ flag: 0 for command, 1 for argument

    parseCommandLoop:
        ldrb r4, [r0]   @ load the char
        cmp r4, #0  @ check if hits '\0'
        beq parseCommandEnd
        cmp r4, #' '  @ check if hits ' '
        beq parseSpace
        cmp r3, #0  @ check state
        bne loadArgs
        strb r4, [r1]   @ store the char to command
        add r0, r0, #1  @ increment
        add r1, r1, #1  @ increment
        b parseCommandLoop

    parseSpace:
        cmp r3, #0  @ check state
        bne inArg   @ if it's parsing arguments, then skip
        @ else, update flag to 1
        add r3, r3, #1
        mov r4, #0
        strb r4, [r1]   @ null terminated arg0(the command)
        add r0, r0, #1  @ increment
        add r1, r1, #1  @ increment
        b parseCommandLoop

    loadArgs:
        strb r4, [r2]   @ store the char
        add r0, r0, #1  @ increment
        add r2, r2, #1  @ increment
        b parseCommandLoop

    inArg:
        add r0, r0, #1  @ increment
        b parseCommandLoop

    parseCommandEnd:
        strb r4, [r1]   @ null terminated arg0
        strb r4, [r2]   @ null terminated arg1
        @ Reload the pointers
        ldr r3, =argv
        ldr r4, =arg0
        str r4, [r3]    @ assign index 0 the pointer to arg0(command)
        ldr r4, =arg1
        @ check if arg1 is empty
        ldrb r5, [r4]
        cmp r5, #0
        @ if is empty, we skip it
        beq skipArg1
        str r4, [r3, #4]    @ assign index 1 the pointer to arg1(argument)

        skipArg1:
            mov r0, #0
            pop {r4-r11, pc}

@ clear args before usage(arg1)
clearArgs:
    push {r4-r11, lr}
    ldr r4, =argv
    mov r5, #0
    str r5, [r4, #4]  @ clear arg1
    pop {r4-r11, pc}


.section .data
@ Used by showPrompt
prompt:
    .asciz "$ " @ Null terminated string

newline:
    .asciz "\n" @ for printing a newline

@ Used for reading user input, allocated with 128bytes
bufferUser:
    .space 128
bufferStrcpy:
    .space 128
bufferFilename:
    .space 128

@ Used for handling command 'cd'
cdCommand:
    .asciz "cd"

binPath:
    .asciz "/usr/bin/"

@ spaces for arguments, used for parsing arguments
@ current specs for allowing only 0/1 arguments
arg0:
    .space 128
arg1:
    .space 128

@ pointer to the pointers to arguments
argv:
    .word arg0
    .word 0
    .word 0
