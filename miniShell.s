.section .text
.global _start

_start:
    bl main

main:
    bl showPrompt
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
    push {lr} @ No use of volatile registers
    mov r1, r0  @ Load input string
    bl strlen
    mov r2, r0  @ r2 = length of the given string

    @ write to stdout
    mov r0, #1 @ stdout
    mov r1, r1 @ pinter to the string
    mov r2, r2 @ length of the string
    mov r7, #4 @ sys_write
    svc #0

    pop {pc}

@ Simulate C's strlen function
@ Take r0 as input
strlen:
    push {lr}   @ No use of volatile registers
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
    pop {pc}


.section .data
@ Used by showPrompt()
prompt:
    .asciz "$ " @Null terminated string
