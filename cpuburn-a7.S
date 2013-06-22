/*
 * Copyright © 2013 Siarhei Siamashka <siarhei.siamashka@gmail.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice (including the next
 * paragraph) shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

/*
 * This program tries to stress ARM Cortex-A7 processor to generate as
 * much heat as possible.
 * WARNING: improperly cooled or otherwise flawed hardware may potentially
 * overheat and fail. Use at your own risk.
 *
 * Compilation instructions:
 *     $ arm-linux-gnueabihf-gcc -o cpuburn-a7 cpuburn-a7.S
 *
 * See http://ssvb.github.io/2012/04/10/cpuburn-arm-cortex-a9.html
 * for more details.
 */

    .syntax unified
    .text
    .arch armv7-a
    .fpu neon
    .arm

    .global main
    .global sysconf
    .global fork
    .global malloc

#define LOOP_UNROLL_FACTOR 120

.func main
.type main, %function
main:
        push        {r4-r12, lr}

#ifdef __linux__
        mov         r0, 84 /* _SC_NPROCESSORS_ONLN */
        bl          sysconf
        mov         r4, r0
        cmp         r4, #2
        blt         1f
        bl          fork /* have at least 2 cores */
        cmp         r4, #4
        blt         1f
        bl          fork /* have at least 4 cores */
1:
#endif
        /* use returned PID as a seed for random */
        mov         r2, r0

        vmov.u8     q2, #1
        vmov.f64    d31, #5.0
        vmov.f64    d28, #7.0
        vsqrt.f64   d29, d31
        vsqrt.f64   d28, d28

        /*
         * Allocate a large memory block (4M) and initialize it by writing
         * at a bunch of random locations. This is done in order to cause
         * artificial fragmentation of physical memory pages and mitigate
         * cache line aliasing effects. We prefer reproducible results.
         */
        mov         r0, #(4 * 1024 * 1024)
        bl          malloc
        mov         lr, r0
        ldr         r0, =12345
        ldr         r1, =1103515245
        mov         ip, #65536
1:      mla         r2, r2, r1, r0
        mov         r3, r3, lsr #(32 - 16)
        str         r2, [lr, r3, lsl #6]
        subs        ip, ip, #1
        bne         1b

        /* Align buffer pointer up to the next page boundary */
        ldr         r0, =4095
        add         lr, lr, r0
        bic         lr, lr, r0

        ldr         r2, =0x55555555
        ldr         r3, =0xCCCCCCCC
        ldr         r5, =(LOOP_UNROLL_FACTOR * 10 * 16 * 4)
        ldr         r9, =(LOOP_UNROLL_FACTOR)
        mov         r8, r9
        b           1f

    .ltorg
    .balign 64

1:
.rept 10
        vsqrt.f64   d30, d31
        pld         [lr, #64]
    .rept 4
        smlalne     r0, r1, r2, r3
        vst2.8      {q2}, [lr, :64]!
        bne         2f
2:
        smlalne     r7, r1, r2, r3
        bne         2f
2:
        vmul.f64    d27, d28, d29
        bne         2f
2:
    .endr
.endr
        subs        r8, #1
        bne         1b
        mov         r8, r9
        subs        lr, lr, r5
        bne         1b
.endfunc
