\ ******************************************************************************
\
\ LANDER I/O PROCESSOR GAME SOURCE
\
\ Lander was written by David Braben and is copyright D.J.Braben 1987
\
\ The code on this site has been reconstructed from a disassembly of the game on
\ the Arthur, RISC OS 2 and RISC OS 3.00 application discs
\
\ The commentary is copyright Mark Moxon, and any misunderstandings or mistakes
\ in the documentation are entirely my fault
\
\ The terminology and notations used in this commentary are explained at
\ https://lander.bbcelite.com/terminology
\
\ The deep dive articles referred to in this commentary can be found at
\ https://lander.bbcelite.com/deep_dives
\
\ ------------------------------------------------------------------------------
\
\ This source file contains the I/O Processor code for Lander.
\
\ ------------------------------------------------------------------------------
\
\ This source file produces the following binary file:
\
\   * Lander.bin
\
\ ******************************************************************************

 GUARD &3000            \ Guard against assembling over screen memory

\ ******************************************************************************
\
\ Configuration variables
\
\ ******************************************************************************

 CODE% = &2400          \ The assembly address of the main I/O processor code

 LOAD% = &2400          \ The load address of the main I/O processor code

 WORDV = &020C          \ The WORDV vector that we intercept to implement our
                        \ own custom OSWORD commands for communicating over the
                        \ Tube

 VIA = &FE00            \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

 OSBYTE = &FFF4         \ The address for the OSBYTE routine

 OSWORD = &FFF1         \ The address for the OSWORD routine

\ ******************************************************************************
\
\       Name: ZP
\       Type: Workspace
\    Address: &0080 to &0097
\   Category: Workspaces
\    Summary: Important variables used by the I/O processor
\
\ ******************************************************************************

 ORG &0080              \ Set the assembly address to &0080

.ZP

 SKIP 0                 \ The start of the zero page workspace

.OSSC

 SKIP 2                 \ When the parasite sends an OSWORD command to the I/O
                        \ processor (i.e. an OSWORD with A = 240 to 255), then
                        \ the relevant handler routine in the I/O processor is
                        \ called with OSSC(1 0) pointing to the OSWORD parameter
                        \ block (i.e. OSSC(1 0) = (Y X) from the original call
                        \ in the I/O processor)

.SC

 SKIP 2                 \ Screen address

.P

 SKIP 1                 \ Temporary storage, used in a number of places

.Q

 SKIP 1                 \ Temporary storage, used in a number of places

.R

 SKIP 1                 \ Temporary storage, used in a number of places

.S

 SKIP 1                 \ Temporary storage, used in a number of places

.T

 SKIP 1                 \ Temporary storage, used in a number of places

 PRINT "ZP workspace (I/O processor) from ", ~ZP, "to ", ~P%-1, "inclusive"

\ ******************************************************************************
\
\       Name: STARTUP
\       Type: Subroutine
\   Category: Loader
\    Summary: Set the various vectors, interrupts and timers, and terminate the
\             loading process so the vector handlers can take over
\
\ ******************************************************************************

 ORG CODE%

.STARTUP

 LDA WORDV              \ Store the current WORDV vector in notours(2 1)
 STA notours+1
 LDA WORDV+1
 STA notours+2

 LDA #LO(NWOSWD)        \ Disable interrupts and set WORDV to NWOSWD, so calls
 SEI                    \ to OSWORD are now handled by NWOSWD, which lets us
 STA WORDV              \ implement all our custom OSWORD commands
 LDA #HI(NWOSWD)
 STA WORDV+1

 CLI                    \ Enable interrupts again

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: OSWVECS
\       Type: Variable
\   Category: Tube
\    Summary: The lookup table for OSWORD jump commands (240-255)
\  Deep dive: 6502 Second Processor Tube communication
\
\ ------------------------------------------------------------------------------
\
\ On entry into these routines, OSSC(1 0) points to the parameter block passed
\ to the OSWORD call in (Y X). OSSC must not be changed by the routines, as it
\ is used by NWOSWD to preserve the values of X and Y through the revectored
\ OSWORD call. OSSC(1 0) can be copied into SC(1 0) to avoid changing it.
\
\ ******************************************************************************

.OSWVECS

 EQUW CLS               \            240 (&F0)     0 = Clear screen
 EQUW PIXEL             \            241 (&F1)     1 = Draw pixel
 EQUW SETMODE           \            242 (&F2)     2 = Do nothing
 EQUW SAFE              \            243 (&F3)     3 = Do nothing
 EQUW SAFE              \            244 (&F4)     4 = Do nothing
 EQUW SAFE              \            245 (&F5)     5 = Do nothing
 EQUW SAFE              \            246 (&F6)     6 = Do nothing
 EQUW SAFE              \            247 (&F7)     7 = Do nothing
 EQUW SAFE              \            248 (&F8)     8 = Do nothing
 EQUW SAFE              \            249 (&F9)     9 = Do nothing
 EQUW SAFE              \            250 (&FA)    10 = Do nothing
 EQUW SAFE              \            251 (&FB)    11 = Do nothing
 EQUW SAFE              \            252 (&FC)    12 = Do nothing
 EQUW SAFE              \            253 (&FD)    13 = Do nothing
 EQUW SAFE              \            254 (&FE)    14 = Do nothing
 EQUW SAFE              \            255 (&FF)    15 = Do nothing

\ ******************************************************************************
\
\       Name: NWOSWD
\       Type: Subroutine
\   Category: Tube
\    Summary: The custom OSWORD routine
\  Deep dive: 6502 Second Processor Tube communication
\
\ ------------------------------------------------------------------------------
\
\ WORDV is set to point to this routine in the STARTUP routine that runs when
\ the I/O processor code first loads.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The OSWORD call to perform:
\
\                         * 240-255: Run the jump command in A (see OSWVECS)
\
\                         * All others: Call the standard OSWORD routine
\
\   (Y X)               The address of the associated OSWORD parameter block
\
\ ------------------------------------------------------------------------------
\
\ Other entry points:
\
\   SAFE                Contains an RTS
\
\ ******************************************************************************

.NWOSWD

 CMP #240               \ If A < 240, this is not a special jump command call,
 BCC notours            \ so jump to notours to pass it to the standard OSWORD
                        \ handler

 STX OSSC               \ Store X in OSCC so we can retrieve it later

 STY OSSC+1             \ Store Y in OSCC+1 so we can retrieve it later

 PHA                    \ Store A on the stack so we can retrieve it later

 SBC #240               \ Set X = (A - 240) * 2
 ASL A                  \
 TAX                    \ so X can be used as an index into a jump table, where
                        \ the table entries correspond to original values of A
                        \ of 240 for entry 0, 241 for entry 1, 242 for entry 2,
                        \ and so on

 LDA OSWVECS,X          \ Fetch the OSWVECS jump table address pointed to by X,
 STA JSRV+1             \ and store it in JSRV(2 1). This modifies the address
 LDA OSWVECS+1,X        \ of the JSR instruction at JSRV below, so it will call
 STA JSRV+2             \ the subroutine from the jump table

 LDX OSSC               \ Restore the value of X we stored in OSSC, so now both
                        \ X and Y have the values from the original OSWORD call

.JSRV

 JSR &FFFC              \ This address is overwritten by the code above to point
                        \ to the relevant jump command from the OSWVECS jump
                        \ table, so this instruction runs the jump command

 PLA                    \ Retrieve A from the stack

 LDX OSSC               \ Retrieve X from OSSC

 LDY OSSC+1             \ Retrieve Y from OSSC+1

.SAFE

 RTS                    \ Return from the subroutine

.notours

 JMP &FFFC              \ This address is overwritten by the STARTUP routine to
                        \ contain the original value of WORDV, so this call acts
                        \ just like a standard JMP OSWORD call and is used to
                        \ process OSWORD calls that aren't our custom calls

\ ******************************************************************************
\
\       Name: PIXEL
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Implement the OSWORD 241 command (draw pixel)
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   OSSC(1 0)           A parameter block as follows:
\
\                         * Byte #0 = The size of the pixel buffer being sent
\
\                         * Bytes #2-#3 = The screen address of the byte
\                                         containing the pixel
\
\                         * Byte #4 = The pixel byte to ORA into the screen
\
\                         * Byte #5-#7 = Next pixel
\
\                       and so on
\
\ ******************************************************************************

.PIXEL

 LDY #0                 \ Set Q to byte #0 from the block pointed to by OSSC,
 LDA (OSSC),Y           \ which contains the size of the pixel buffer
 STA Q

 INY                    \ Increment Y to 2, so y now points at the data for the
 INY                    \ first pixel in the command block

.PXLO

 LDA (OSSC),Y           \ Set SC(1 0) to bytes #2-#3 from the Y-th pixel block
 STA SC                 \ in OSSC, which contains the screen offset, and add to
 INY                    \ &3000 for mode 1 screen memory
 LDA (OSSC),Y
 STA SC+1

 INY                    \ Increment Y to 4

 STY P                  \ Store Y in P

 LDA (OSSC),Y           \ Set A to byte #4 from the Y-th pixel block in OSSC,
                        \ which contains the pixel byte

 LDY #0                 \ Draw the pixel on-screen using OR logic
 ORA (SC),Y
 STA (SC),Y

 LDY P                  \ Set Y to the index of this pixel's y-coordinate byte
                        \ in the command block, which we stored in P above

 INY                    \ Increment Y, so it now points to the first byte of
                        \ the next pixel in the command block

 CPY Q                  \ If the index has reached the value in Q (which
 BEQ P%+4               \ contains the size of the pixel buffer), skip the next
                        \ instruction

 BNE PXLO               \ We haven't reached the end of the buffer, so loop back
                        \ to PXLO to draw the next pixel in the buffer (this BNE
                        \ is effectively a JMP as we just passed through a BEQ)

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: CLS
\       Type: Subroutine
\   Category: Drawing the screen
\    Summary: Clear the screen
\
\ ******************************************************************************

.CLS

 LDY #2                 \ Fetch the argument (0 or 1)
 LDA (OSSC),Y

 BNE bank1              \ If argument is zero jump to bank1

                        \ Display main memory on screen and switch drawing to
                        \ shadow RAM

 LDA #%00000110         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA &34 to switch shadow RAM into &3000-&7FFF and
                        \ switch drawing to shadow RAM
                        \
                        \ Clear bit 0 to display main memory on screen

 JMP bank2              \ Jump to bank3 to clear the screen (this BNE is
                        \ effectively a JMP as A is never zero)

.bank1

                        \ Display shadow RAM on screen and switch drawing to
                        \ main memory

 LDA #%00000001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA &34 to switch main memory into &3000-&7FFF and
                        \ switch drawing to main memory
                        \
                        \ Set bit 0 to display shadow RAM on screen

.bank2

 LDA #&35               \ Set P(1 0) = &3500
 STA P+1
 LDA #&00
 STA P

 LDX #&80-&35           \ The number of pages in screen memory, starting at
                        \ &3500 (just below the two lines of scores)

 LDY #0                 \ We want to zero one page of memory, so set Y as a byte
                        \ counter

.bank3

 STA (P),Y              \ Zero the Y-th byte of the P(1 0) memory block

 DEY                    \ Decrement the byte counter

 BNE bank3              \ Loop back to copy the next byte until we have done a
                        \ whole page of 256 bytes

 INC P+1                \ Increment the high byte of the source address to point
                        \ to the next page

 DEX                    \ Decrement the page counter

 BPL bank3              \ Loop back to copy the next page until we have done X
                        \ pages

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SETMODE
\       Type: Subroutine
\   Category: Drawing the screen
\    Summary: Clear the screen
\
\ ******************************************************************************

.SETMODE

 LDA #LO(B%)            \ Set the low byte of P(1 0) to point to the VDU code
 STA P                  \ table at B%

 LDA #HI(B%)            \ Set the high byte of P(1 0) to point to the VDU code
 STA P+1                \ table at B%

 LDY #0                 \ We are now going to send the VDU bytes in the table
                        \ at B% to OSWRCH to set up the screen mode

.mode1

 LDA (P),Y              \ Set A to the Y-th byte of the B% table

 CMP #&FF               \ If we have reached the end of the table, jump to mode2
 BEQ mode2              \ to return from the subroutine

 JSR OSWRCH             \ Print the Y-th byte of the VDU command

 INY                    \ Increment the loop counter

 JMP mode1              \ Loop back for the next byte

.mode2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: B%
\       Type: Variable
\   Category: Drawing the screen
\    Summary: VDU commands for setting up the mode 1 screen
\
\ ******************************************************************************

.B%

 EQUB 22, 129           \ Switch to screen mode 129 (shadow mode 1)

 EQUB 23, 0, 10, 32     \ Set 6845 register R10 = %00100000 = 32
 EQUB 0, 0, 0           \
 EQUB 0, 0, 0           \ This is the "cursor start" register, and bits 5 and 6
                        \ define the "cursor display mode", as follows:
                        \
                        \   * %00 = steady, non-blinking cursor
                        \
                        \   * %01 = do not display a cursor
                        \
                        \   * %10 = fast blinking cursor (blink at 1/16 of the
                        \           field rate)
                        \
                        \   * %11 = slow blinking cursor (blink at 1/32 of the
                        \           field rate)
                        \
                        \ We can therefore turn off the cursor completely by
                        \ setting cursor display mode %01, with bit 6 of R10
                        \ clear and bit 5 of R10 set

 EQUB 19, 2, 2          \ Define logical colour 2 as green
 EQUB 0, 0, 0

 EQUB 19, 3, 4          \ Define logical colour 3 as blue
 EQUB 0, 0, 0

 EQUB 255               \ End of commands

\ ******************************************************************************
\
\ Save Lander.bin
\
\ ******************************************************************************

 SAVE "3-assembled-output/Lander.bin", CODE%, P%, LOAD%
