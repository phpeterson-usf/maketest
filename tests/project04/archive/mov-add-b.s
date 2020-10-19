@ test_basic2_arm.s

.global main

main: 
    mov r0, #1
    mov r1, #2
    add r2, r0, r1
end: 
    b end


