/*
 * Copyright © 2012 Siarhei Siamashka <siarhei.siamashka@gmail.com>
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
 * This program tries to stress ARM Cortex-A8 processor to generate as
 * much heat as possible.
 * WARNING: improperly cooled or otherwise flawed hardware may potentially
 * overheat and fail. Use at your own risk.
 *
 * Compilation instructions:
 *     $ arm-linux-gnueabihf-gcc -o cpuburn-a8 cpuburn-a8.S
 *
 * See http://ssvb.github.com/2012/04/10/cpuburn-arm-cortex-a9.html
 * for more details.
 */
    .syntax unified
    .text
    .arch armv7-a
    .fpu neon
    .thumb

    .global main

/* optimal value for LOOP_UNROLL_FACTOR seems to be BTB size dependent */
#define LOOP_UNROLL_FACTOR   130
/* 16 seems to be a good choice */
#define STEP                 16

.func main
.thumb_func
main:
        mov         lr, pc
        adds        lr, lr, #63
        bic         lr, lr, #63
        mov         ip, #STEP
    .p2align 2
0:
    .rept LOOP_UNROLL_FACTOR
        vld2.8      {q0}, [lr, :128], ip
        vaba.u8     q4, q4, q3
        bne         1f
1:      vld2.8      {q1}, [lr, :128], ip
        vaba.u8     q5, q5, q0
        vld2.8      {q2}, [lr, :128], ip
        vaba.u8     q6, q6, q1
        bne         1f
1:      vld2.8      {q3}, [lr, :128], ip
        vaba.u8     q7, q7, q2
        smuad       r0, r1, r2
        subs        lr, lr, #(STEP * 4)
    .endr
        bne         0b
.endfunc
