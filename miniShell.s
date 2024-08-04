.section .text
.global _start

_start:
    bl main

main:
    bl showPrompt
    bl readUserInput
    bl displayUserInput
    bl executeCommand
    b main  @Infinity loop

@ Ask user to prompt with outputing "$ " on the display
@ Addtional parameters are not needed
showPrompt:
    push {lr}
    ldr r0, =prompt @"$ "
    bl printf
    pop {pc} @ return

@ Simulate C's printf function
@ Take r0 as input
printf:
    @push {lr} @ No use of volatile registers
    push {r4-r11, lr} @ fixed, make sure to follow arm convention
    mov r1, r0  @ Load input string
    bl strlen
    mov r2, r0  @ r2 = length of the given string

    @ write to stdout
    mov r0, #1 @ stdout fd
    mov r1, r1 @ pinter to the string
    mov r2, r2 @ length of the string
    mov r7, #4 @ sys_write
    svc #0

    pop {r4-r11, pc}

@ Simulate C's strlen function
@ Take r0 as input
strlen:
    push {r4-r11, lr}
    mov r1, r0  @ Load input string
    mov r2, #0  @ Length

_strlenLoop:
    ldrb r3, [r1, r2]
    cmp r3, #0  @If == '\0'
    beq _strlenLoopEnd
    @ else
    add r2, r2, #1  @length++
    b _strlenLoop

_strlenLoopEnd:
    mov r0, r2
    pop {r4-r11, pc}


readUserInput:
    push {r4-r11, lr}

    @ read from stdin
    mov r0, #0  @ stdin fd
    ldr r1, =buffer @ pointer to the buffer
    mov r2, #128    @ maximum load size
    mov r7, #3  @ sys_read
    svc #0

    @ add '\0' for null terminated(replacing '\n' with '\0')
    @ move r1 to the end of the string(+1)
    add r1, r1, r0  @r0 store the return value of numbers of bytes read
    mov r2, #0
    sub r3, r1, #1
    ldrb r4, [r3]   @ note: we can't directly use cmp to compare value with registers
    cmp r4, #0xa    @ compare it with '\n'
    bne endReadUserInput
        strb r2, [r3]
        pop {r4-r11, pc}

    endReadUserInput:
        strb r2, [r1]
        pop {r4-r11, pc}

displayUserInput:
    push {r4-r11, lr}
    ldr r0, =buffer
    bl printf
    ldr r0, =newline
    bl printf
    pop {r4-r11, pc}


executeCommand:
    push {r4-r11, lr}
    ldr r0, =buffer
    @ parse the command for later execution
    bl parseCommand

    cmp r0, #-1  @ make sure the parse is done correctly
    beq endExecute
    @ else
    bl fork
    cmp r0, #0  @ return 0 if a child process, pid a parent process
    beq child   @ if we're in child process, run child
    bl wait @ if we're in parent process, wait until child process ends

    endExecute:
        pop {r4-r11, pc}

@TODO: parse the command
@ returns 0 if parsed correctly
parseCommand:
    push {r4-r11, lr}
    mov r0, r0 @ load the command

    pop {r4-r11, pc}

@ call sys_fork for forking
fork:
    push {r4-r11, lr}
    mov r7, #2  @ sys_fork
    svc #0
    pop {r4-r11, pc}

@ call sys_execve
child:
    push {r4-r11, lr}
    ldr r0, =buffer
    mov r1, #0
    mov r2, #0  @ place for environment pointer
    mov r7, #11  @ sys_execve
    svc #0

    @ only run if execve somehow failed
    mov r7, #1
    svc #0

wait:
    mov r7, #0x72   @ sys_wait(for arm linux kernel, sys_wait4)
    mov r0, #-1 @ wait for any child
    mov r1, #0  @ no options
    mov r2, #0  @ no status
    svc #0
    pop {r4-r11, pc}

.section .data
@ Used by showPrompt()
prompt:
    .asciz "$ " @ Null terminated string

newline:
    .asciz "\n" @ for printing a newline

@ Used for reading user input, allocated with 128bytes
buffer:
    .space 128
