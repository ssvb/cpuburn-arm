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
 * This program tries to stress Qualcomm Krait 300/400 processor to generate
 * as much heat as possible.
 * WARNING: improperly cooled or otherwise flawed hardware may potentially
 * overheat and fail. Use at your own risk.
 *
 * Compilation instructions:
 *     $ arm-linux-gnueabihf-gcc -o cpuburn-krait cpuburn-krait.S
 *
 * See http://ssvb.github.io/2012/04/10/cpuburn-arm-cortex-a9.html
 * for more details.
 */

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
        mov         r0, #84 /* _SC_NPROCESSORS_ONLN */
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
        vmov.u8     q8,  #0x0
        vmov.u8     q9,  #0x0
        vmov.u8     q14, #0xff
        vmov.u8     q15, #0xff

        adr         lr, 9f
        mov         r1, #16
        mov         r2, #-16
        mov         ip, #1
        b           0f

    .balign 64
9:
    .rept 64
        .long 0xffffffff
    .endr

    .balign 64
/****************************************************************************/
/* Main loop (2 cycles per loop iteration, reaching peak IPC=3)             */
/****************************************************************************/
0:      vld2.8      {q1}, [lr, :128], r1
        vaba.u8     q8, q2, q14

        vld2.8      {q2}, [lr, :128], r2
        vaba.u8     q9, q1, q15

        subs        ip, ip, #0
        bne         0b
/****************************************************************************/

        mov         r0, #0
        pop         {r4-r12, pc}
