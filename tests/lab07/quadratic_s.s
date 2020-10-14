quadratic_s:
    mul r2, r2, r0
    mul r0, r0, r0
    mul r1, r1, r0
    add r0, r1, r2
    add r0, r0, r3
    bx lr
