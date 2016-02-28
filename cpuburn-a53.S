/*
 * Copyright © 2016 Siarhei Siamashka <siarhei.siamashka@gmail.com>
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
 * This program tries to stress ARM Cortex-A53 processor to generate as
 * much heat as possible.
 * WARNING: improperly cooled or otherwise flawed hardware may potentially
 * overheat and fail. Use at your own risk.
 *
 * Compilation instructions:
 *     $ aarch64-linux-gnu-gcc -o cpuburn-a53 cpuburn-a53.S
 * or
 *     $ arm-linux-gnueabihf-gcc -o cpuburn-a53 cpuburn-a53.S
 *
 * See http://ssvb.github.io/2012/04/10/cpuburn-arm-cortex-a9.html
 * for more details.
 */

#define LOOP_UNROLL_FACTOR   100

#ifdef __aarch64__

/****************************************************************************/
/* 64-bit implementation                                                    */
/****************************************************************************/

    .cpu cortex-a53+fp+simd
    .text
    .align 2
    .global main
    .type main, %function

main:
        stp         x29, x30, [sp, #-16]!

#ifdef __linux__
        mov         w0, #84 /* _SC_NPROCESSORS_ONLN */
        bl          sysconf
        mov         w29, w0
        cmp         w29, #2
        blt         1f
        bl          fork /* have at least 2 cores */
        cmp         w29, #4
        blt         1f
        bl          fork /* have at least 4 cores */
        cmp         w29, #8
        blt         1f
        bl          fork /* have at least 8 cores */
1:
#endif

        movi        v28.16b, #0xff
        movi        v29.16b, #0xff
        movi        v30.16b, #0xff
        movi        v31.16b, #0xff

        adr         x4, 9f
        add         x4, x4, #1
        mov         x1, #0
        mov         x2, #(64 / 4)

        b           0f

    .ltorg
9:
    .rept 64
        .long 0xffffffff
    .endr

    .balign 64
0:
    .rept LOOP_UNROLL_FACTOR
        uaba        v8.4s, v28.4s, v29.4s
        bne         1f
1:      uaba        v9.4s, v30.4s, v31.4s
        ldr         w0, [x4, x1, lsl #2]
        uaba        v10.4s, v28.4s, v29.4s
        bne         1f
1:      uaba        v11.4s, v30.4s, v31.4s
        ldr         w0, [x4, x2, lsl #2]
    .endr
        b           0b

        mov         w0, #0
        ldp         x29, x30, [sp], #16
        ret

/****************************************************************************/

#else

/****************************************************************************/
/* 32-bit implementation                                                    */
/****************************************************************************/

    .syntax unified
    .text
    .arch armv7-a
    .fpu neon
    .global main
    .type main, %function
    .align 2
    .arm

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
        cmp         r4, #8
        blt         1f
        bl          fork /* have at least 8 cores */
1:
#endif

        vmov.u8     q12, #0xff
        vmov.u8     q13, #0xff
        vmov.u8     q14, #0xff
        vmov.u8     q15, #0xff

        adr         lr, 9f
        add         lr, lr, #1
        mov         r1, #(64 / 4)
        mov         r2, #(-64 / 4)

        b           0f

    .ltorg
9:
    .rept 64
        .long 0xffffffff
    .endr

    .balign 64
0:
    .rept LOOP_UNROLL_FACTOR
        vaba.u32    q8, q12, q13
        bne         1f
1:      vaba.u32    q9, q14, q15
        ldrne       r0, [lr, r1, lsl #2]!
        vaba.u32    q10, q12, q13
        bne         1f
1:      vaba.u32    q11, q14, q15
        ldrne       r0, [lr, r2, lsl #2]!
    .endr
        b           0b

        mov         r0, #0
        pop         {r4-r12, pc}

/****************************************************************************/

#endif
