.global main

main:   str r5, [sp]
        ldr r5, [sp]
        str r6, [sp, #-4]
        ldr r6, [sp, #-4]
        str r7, [sp, #8]
        ldr r7, [sp, #8]
        bx lr
