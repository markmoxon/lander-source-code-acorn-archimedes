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

 WRCHV = &020E          \ The WRCHV vector that we intercept to implement our
                        \ own custom OSWRCH commands for communicating over the
                        \ Tube

 WORDV = &020C          \ The WORDV vector that we intercept to implement our
                        \ own custom OSWORD commands for communicating over the
                        \ Tube

 VIA = &FE00            \ Memory-mapped space for accessing internal hardware,
                        \ such as the video ULA, 6845 CRTC and 6522 VIAs (also
                        \ known as SHEILA)

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

 OSBYTE = &FFF4         \ The address for the OSBYTE routine

 OSWORD = &FFF1         \ The address for the OSWORD routine

 OSCLI = &FFF7          \ The address for the OSCLI routine

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

.LINTAB

 SKIP 1                 \ The offset of the first free byte in the TABLE buffer,
                        \ which stores bytes in the current pixel as they are
                        \ transmitted from the parasite using the OSWRCH
                        \ commands

.LINMAX

 SKIP 1                 \ The number of pixels currently being transmitted from
                        \ the parasite using the OSWRCH commands

 PRINT "ZP workspace (I/O processor) from ", ~ZP, "to ", ~P%-1, "inclusive"

\ ******************************************************************************
\
\       Name: TABLE
\       Type: Variable
\   Category: Drawing pixels
\    Summary: The pixel buffer for pixel data transmitted from the parasite
\
\ ******************************************************************************

 ORG CODE% - 256        \ Set the assembly address to the page before CODE%

.TABLE

 SKIP 256

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

 LDA #200               \ Call OSBYTE with A = 200, X = 3 and Y = 0 to disable
 LDX #3                 \ the ESCAPE key and clear memory if the BREAK key is
 LDY #0                 \ pressed
 JSR OSBYTE

 LDA #13                \ Call OSBYTE with A = 13, X = 2 and Y = 0 to disable
 LDX #2                 \ the "character entering buffer" event
 LDY #0
 JSR OSBYTE

 LDA #%00111001         \ Set 6522 System VIA interrupt enable register IER
 STA VIA+&4E            \ (SHEILA &4E) bits 0 and 3-5 (i.e. disable the Timer1,
                        \ CB1, CB2 and CA2 interrupts from the System VIA)

 LDA #%01111111         \ Set 6522 User VIA interrupt enable register IER
 STA &FE6E              \ (SHEILA &6E) bits 0-7 (i.e. disable all hardware
                        \ interrupts from the User VIA)

 LDA #20                \ Call OSBYTE with A = 20, X = 0 and Y = 0 to implode
 LDX #0                 \ the soft character definitions, so they don't take up
 LDY #0                 \ extra memory (by default, having a Second Processor
 JSR OSBYTE             \ present explodes the soft character definitions, so
                        \ this reclaims 6 pages of memory)

 LDA #4                 \ Call OSBYTE with A = 4, X = 1 and Y = 0 to disable
 LDX #1                 \ cursor editing, so the cursor keys return ASCII values
 LDY #0                 \ and can therefore be used in-game
 JSR OSBYTE

 LDA WRCHV              \ Store the current WRCHV vector in OHMYGOD(4 3)
 STA OHMYGOD+3
 LDA WRCHV+1
 STA OHMYGOD+4

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

 JSR PUTBACK            \ Call PUTBACK to point WRCHV to USOSWRCH, so from now
                        \ on the handlers pointed to by the vectors will handle
                        \ all character writes

 LDX #LO(MESS1)         \ Set (Y X) to point to MESS1 ("RUN P.LANDER")
 LDY #HI(MESS1)

 JMP OSCLI              \ Call OSCLI to run the OS command in MESS1, which *RUNs
                        \ the parasite code in RUN P.LANDER, returning from the
                        \ subroutine using a tail call

\ ******************************************************************************
\
\       Name: MESS1
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for running the parasite code in P.LANDER
\
\ ******************************************************************************

.MESS1

 EQUS "RUN P.LANDER"
 EQUB 13

\ ******************************************************************************
\
\       Name: PUTBACK
\       Type: Subroutine
\   Category: Tube
\    Summary: Reset the OSWRCH vector in WRCHV to point to USOSWRCH
\  Deep dive: 6502 Second Processor Tube communication
\
\ ******************************************************************************

.PUTBACK

 LDA #128               \ Set A = 128 to denote the first entry in JMPTAB, i.e.
                        \ USOSWRCH

                        \ Fall through into USOSWRCH to set WRCHV to the first
                        \ entry in JMPTAB - in other words, put WRCHV back to
                        \ its original value of USOSWRCH

\ ******************************************************************************
\
\       Name: USOSWRCH
\       Type: Subroutine
\   Category: Tube
\    Summary: The custom OSWRCH routine for writing characters and implementing
\             jump table commands
\  Deep dive: 6502 Second Processor Tube communication
\
\ ------------------------------------------------------------------------------
\
\ WRCHV is set to point to this routine in the STARTUP routine that runs when
\ the I/O processor code first loads (it's set via a call to PUTBACK).
\
\ This routine prints characters to the I/O processor's screen. For special jump
\ table commands with characters in the range 128-147, the routine calls the
\ corresponding routines in the JMPTAB table; all other characters are printed
\ normally using the original OSWRCH.
\
\ To implement the special jump table commands, this routine sets the address
\ in WRCHV so that calls to OSWRCH get vectored via the appropriate address from
\ JMPTAB. The routine does the following, depending on the value in A:
\
\   * If A is in the range 128-147, it sets WRCHV to entry number A - 128 in
\     the JMPTAB table (so 128 is the first entry, 129 the second, and so on)
\
\   * Otherwise it prints the character in A by calling the original OSWRCH
\
\ The vector can be reset to USOSWRCH by calling the PUTBACK routine, which is
\ done at the end of all of the routines that are pointed to by JMPTAB.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The character to print:
\
\                         * 128-147: Run the jump command in A (see JMPTAB)
\
\                         * All others: Print the character in A
\
\ ******************************************************************************

.USOSWRCH

 STX SC                 \ Store X in SC so we can retrieve it later

 TAX                    \ Store A in X

 BPL OHMYGOD            \ If A < 128 jump to OHMYGOD to print the character in A

 CPX #129               \ Also jump to OHMYGOD if we are printing character 129,
 BEQ OHMYGOD            \ as we use that to change screen mode to shadow mode 1

 ASL A                  \ Set X = A << 2
 TAX                    \       = (A - 128) * 2 (because A >= 128)
                        \
                        \ so X can be used as an index into a jump table, where
                        \ the table entries correspond to original values of A
                        \ of 128 for entry 0, 129 for entry 1, 130 for entry 2,
                        \ and so on

 CPX #39                \ If X >= 39 then it is past the end of the jump table
 BCS OHMYGOD            \ (JMPTAB contains addresses 0-19, so the last entry is
                        \ for X = 38), so jump to OHMYGOD to print the
                        \ character in A

 LDA JMPTAB,X           \ Fetch the low byte of the jump table address pointed
                        \ to by X from JMPTAB + X

 SEI                    \ Disable interrupts while we update the WRCHV vector

 STA WRCHV              \ Store the low byte of the jump table entry in the low
                        \ byte of WRCHV

 LDA JMPTAB+1,X         \ Fetch the high byte of the jump table address pointed
 STA WRCHV+1            \ to by X from JMPTAB+1 + X, and store it in the high
                        \ byte of WRCHV

 CLI                    \ Enable interrupts again

 RTS                    \ Return from the subroutine

.OHMYGOD

 LDX SC                 \ Retrieve X from SC

 JMP OSWRCH             \ Jump to OSWRCH to print the character in A, returning
                        \ from the subroutine using a tail call (this address is
                        \ updated in STARTUP to point to the original OSWRCH
                        \ routine)

\ ******************************************************************************
\
\       Name: JMPTAB
\       Type: Variable
\   Category: Tube
\    Summary: The lookup table for OSWRCH jump commands (128-147)
\  Deep dive: 6502 Second Processor Tube communication
\
\ ------------------------------------------------------------------------------
\
\ Once they have finished, routines in this table should reset WRCHV to point
\ back to USOSWRCH again by calling the PUTBACK routine with a JMP as their last
\ instruction.
\
\ ******************************************************************************

.JMPTAB

 EQUW USOSWRCH          \ 128 (&80)     0 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 129 (&81)     1 = Reserved for VDU code for mode 128+1
 EQUW SetScreenBank     \ 130 (&82)     2 = Set screen bank to main or shadow
 EQUW ClearScreen       \ 131 (&83)     3 = Switch screen bank and clear screen
 EQUW USOSWRCH          \ 132 (&84)     4 = Reserved for VDU code for mode 128+4
 EQUW SetScreenMode     \ 133 (&85)     5 = Set up the game's screen mode
 EQUW BeginPixels       \ 134 (&86)     6 = Start receiving pixels
 EQUW AddPixel          \ 135 (&87)     7 = Receive a pixel to draw
 EQUW USOSWRCH          \ 136 (&88)     8 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 137 (&89)     9 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 138 (&8A)    10 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 139 (&8B)    11 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 140 (&8C)    12 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 141 (&8D)    13 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 142 (&8E)    14 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 143 (&8F)    15 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 144 (&90)    16 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 145 (&91)    17 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 146 (&92)    18 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 147 (&93)    19 = Put back to USOSWRCH

\ ******************************************************************************
\
\       Name: SetScreenBank
\       Type: Subroutine
\   Category: Screen
\    Summary: Implement the #Tube_SetScreenBank <param> command (set screen bank)
\
\ ------------------------------------------------------------------------------
\
\ This routine is run when the parasite sends a #Tube_SetScreenBank <param>
\ command. It switches the screen bank between shadow RAM and main memory.
\
\ Arguments:
\
\   A                   The screen bank
\
\                         * 0 = Draw into shadow RAM, display main memory
\
\                         * 1 = Draw into main memory, display shadow RAM
\
\ ******************************************************************************

.SetScreenBank

 JSR SetScreenBankToA   \ Switch the screen bank to the argument in A

 JMP PUTBACK            \ Jump to PUTBACK to restore the USOSWRCH handler and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: SetScreenBankToA
\       Type: Subroutine
\   Category: Screen
\    Summary: Switch the screen bank according to the value of A
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The screen bank
\
\                         * 0 = Draw into shadow RAM, display main memory
\
\                         * 1 = Draw into main memory, display shadow RAM
\
\ ******************************************************************************

.SetScreenBankToA

 CMP #0                 \ If argument is zero jump to sban1
 BNE sban1

                        \ Display main memory on screen and switch drawing to
                        \ shadow RAM

 LDA #%00000110         \ Set bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA &34 to switch shadow RAM into &3000-&7FFF and
                        \ switch drawing to shadow RAM
                        \
                        \ Clear bit 0 to display main memory on screen

 RTS                    \ Return from the subroutine

.sban1

                        \ Display shadow RAM on screen and switch drawing to
                        \ main memory

 LDA #%00000001         \ Clear bits 1 and 2 of the Access Control Register at
 STA VIA+&34            \ SHEILA &34 to switch main memory into &3000-&7FFF and
                        \ switch drawing to main memory
                        \
                        \ Set bit 0 to display shadow RAM on screen

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ClearScreen
\       Type: Subroutine
\   Category: Drawing the screen
\    Summary: Clear the screen
\
\ ------------------------------------------------------------------------------
\
\ This routine is run when the parasite sends a #Tube_ClearScreen <param>
\ command. It switches the screen bank and clears the bank that's no longer
\ being displayed.
\
\ Arguments:
\
\   A                   The screen bank
\
\                         * 0 = Draw into shadow RAM, display main memory
\
\                         * 1 = Draw into main memory, display shadow RAM
\
\ ******************************************************************************

.ClearScreen

 JSR SetScreenBankToA   \ Switch the screen bank to the argument in A

 LDA #&35               \ Set P(1 0) = &3500
 STA P+1
 LDA #&00
 STA P

 LDX #&80-&35           \ The number of pages in screen memory, starting at
                        \ &3500 (just below the two lines of scores)

 LDY #0                 \ We want to zero one page of memory, so set Y as a byte
                        \ counter

.clsc1

 STA (P),Y              \ Zero the Y-th byte of the P(1 0) memory block

 DEY                    \ Decrement the byte counter

 BNE clsc1              \ Loop back to copy the next byte until we have done a
                        \ whole page of 256 bytes

 INC P+1                \ Increment the high byte of the source address to point
                        \ to the next page

 DEX                    \ Decrement the page counter

 BPL clsc1              \ Loop back to copy the next page until we have done X
                        \ pages

 JMP PUTBACK            \ Jump to PUTBACK to restore the USOSWRCH handler and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: SetScreenMode
\       Type: Subroutine
\   Category: Drawing the screen
\    Summary: Set up the game's screen mode
\
\ ******************************************************************************

.SetScreenMode

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

 JSR OHMYGOD+2          \ Print the Y-th byte of the VDU command by calling the
                        \ original OSWRCH address in the JMP instruction at
                        \ OHMYGOD+2 (this ensures the reserved mode numbers can
                        \ be printed properly)

 INY                    \ Increment the loop counter

 JMP mode1              \ Loop back for the next byte

.mode2

 JMP PUTBACK            \ Jump to PUTBACK to restore the USOSWRCH handler and
                        \ return from the subroutine using a tail call

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

 EQUB 19, 1, 1          \ Define logical colour 1 as red
 EQUB 0, 0, 0

 EQUB 19, 2, 2          \ Define logical colour 2 as green
 EQUB 0, 0, 0

 EQUB 19, 3, 4          \ Define logical colour 3 as blue
 EQUB 0, 0, 0

 EQUB 255               \ End of commands

\ ******************************************************************************
\
\       Name: BeginPixels
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Implement the #BeginPixels <size> command (start receiving a new
\             batch of pixels to draw)
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number of bytes to expect + 1
\
\ ******************************************************************************

.BeginPixels

 STA LINMAX             \ Set LINMAX to the number of bytes to expect + 1

 LDA #0                 \ Set LINTAB = 0 to point to the position of the next
 STA LINTAB             \ free byte in the TABLE buffer (i.e. the first byte, as
                        \ we have just reset the buffer)

 LDA #135               \ Execute a USOSWRCH 135 command so subsequent OSWRCH
 JMP USOSWRCH           \ calls from the parasite can send pixels that get
                        \ added to TABLE, and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: AddPixel
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Implement the #AddPixel <byte> command (add a byte to a pixel and
\             draw all pixels in the buffer once all bytes are received)
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The byte to be added to the pixel that's currently being
\                       transmitted to the I/O processor
\
\ ******************************************************************************

.RTS1

 RTS                    \ Return from the subroutine (this is called below)

.AddPixel

 INC LINTAB             \ LINTAB points to the last free byte in TABLE, which is
                        \ where we're about to store the new byte in A, so
                        \ increment LINTAB to point to the byte after this one

 LDX LINTAB             \ Store the new byte in A at position LINTAB-1 in TABLE
 STA TABLE-1,X          \ (which was the last free byte before we incremented
                        \ LINTAB above)

 INX                    \ Increment X, so it now points to the byte after the
                        \ last free byte in TABLE (i.e. LINTAB + 1)

 CPX LINMAX             \ If X < LINMAX, jump up to RTS1 to return from the
 BCC RTS1               \ subroutine, as the data isn't complete yet (because
                        \ LINMAX contains the number of bytes + 1)

                        \ If we get here then X = LINMAX and we have received
                        \ all the pixel data from the parasite, so now we draw
                        \ them

 LDX #0                 \ We are going to loop through all the pixels in the
                        \ block, so set a counter in X, starting from 0

 DEC LINMAX             \ Decrement LINMAX so it now contains 2 * number of
                        \ points

.LL27

 STY R                  \ Store the loop counter in R so we can retrieve it
                        \ after we draw the pixel

 LDA TABLE,X            \ Set SC(1 0) to bytes #0 and #1 from the Y-th pixel
 STA SC                 \ block, which contains the screen address of the pixel
 LDA TABLE+1,X
 STA SC+1

 LDA TABLE+2,X          \ Set P to byte #2, which contains the pixel byte
 STA P

 LDA TABLE+3,X          \ Set Q to byte #3, which contains the pixel mask
 STA Q

 LDY #0                 \ Draw the pixel on-screen by clearing the relevant bits
 LDA (SC),Y             \ with the mask in Q and inserting the relevant bits
 AND Q                  \ from the pixel byte in P
 ORA P
 STA (SC),Y

 INX                    \ Set X = X + 4 to move on to the next pixel
 INX
 INX
 INX

 CPX LINMAX             \ Loop back to LL27 to draw the next line segment, until
 BCC LL27               \ the loop counter has reached LINMAX (which contains
                        \ 2 * number of points, so this is when we have run out
                        \ of points)

 JMP PUTBACK            \ Jump to PUTBACK to restore the USOSWRCH handler and
                        \ return from the subroutine using a tail call

\ ******************************************************************************
\
\       Name: OSWVECS
\       Type: Variable
\   Category: Tube
\    Summary: The lookup table for OSWORD jump commands (240-255)
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

 EQUW ReadKeyboard      \            240 (&F0)     0 = Read keyboard
 EQUW SAFE              \            241 (&F1)     1 = Do nothing
 EQUW SAFE              \            242 (&F2)     2 = Do nothing
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
\       Name: DKS4
\       Type: Macro
\   Category: Keyboard
\    Summary: Scan the keyboard to see if a specific key is being pressed
\  Deep dive: The key logger
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The internal number of the key to check (see page 142 of
\                       the "Advanced User Guide for the BBC Micro" by Bray,
\                       Dickens and Holmes for a list of internal key numbers)
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   A                   If the key in A is being pressed, A contains the
\                       original argument A, but with bit 7 set (i.e. A + 128).
\                       If the key in A is not being pressed, the value in A is
\                       unchanged
\
\ ******************************************************************************

MACRO DKS4

 LDX #3                 \ Set X to 3, so it's ready to send to SHEILA once
                        \ interrupts have been disabled

 SEI                    \ Disable interrupts so we can scan the keyboard
                        \ without being hijacked

 STX VIA+&40            \ Set 6522 System VIA output register ORB (SHEILA &40)
                        \ to %00000011 to stop auto scan of keyboard

 LDX #%01111111         \ Set 6522 System VIA data direction register DDRA
 STX VIA+&43            \ (SHEILA &43) to %01111111. This sets the A registers
                        \ (IRA and ORA) so that:
                        \
                        \   * Bits 0-6 of ORA will be sent to the keyboard
                        \
                        \   * Bit 7 of IRA will be read from the keyboard

 STA VIA+&4F            \ Set 6522 System VIA output register ORA (SHEILA &4F)
                        \ to A, the key we want to scan for; bits 0-6 will be
                        \ sent to the keyboard, of which bits 0-3 determine the
                        \ keyboard column, and bits 4-6 the keyboard row

 LDA VIA+&4F            \ Read 6522 System VIA output register IRA (SHEILA &4F)
                        \ into A; bit 7 is the only bit that will have changed.
                        \ If the key is pressed, then bit 7 will be set,
                        \ otherwise it will be clear

 LDX #%00001011         \ Set 6522 System VIA output register ORB (SHEILA &40)
 STX VIA+&40            \ to %00001011 to restart auto scan of keyboard

 CLI                    \ Allow interrupts again

ENDMACRO

\ ******************************************************************************
\
\       Name: KYTB
\       Type: Variable
\   Category: Keyboard
\    Summary: Lookup table for keyboard controls
\
\ ******************************************************************************

.KYTB

 EQUB &70               \ ESCAPE    KYTB+0      Quit
 EQUB &68               \ ?         KYTB+1      Hover
 EQUB &62               \ Space     KYTB+2      Thrust
 EQUB &66               \ <         KYTB+3      Yaw left
 EQUB &67               \ >         KYTB+4      Yaw right
 EQUB &42               \ X         KYTB+5      Pull up
 EQUB &51               \ S         KYTB+6      Pitch down
 EQUB &41               \ A         KYTB+7      Fire

\ ******************************************************************************
\
\       Name: ReadKeyboard
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Implement the OSWORD 243 command (scan the keyboard)
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   OSSC                The address of the table in which to log the key presses
\
\ ------------------------------------------------------------------------------
\
\ Returns:
\
\   OSSC                The table is updated as follows:
\
\                         * Byte #2: ESCAPE is being pressed (0 = no, &FF = yes)
\
\                         * Byte #3: "?" is being pressed (0 = no, &FF = yes)
\
\                         * Byte #4: Space is being pressed (0 = no, &FF = yes)
\
\                         * Byte #5: "<" is being pressed (0 = no, &FF = yes)
\
\                         * Byte #6: ">" is being pressed (0 = no, &FF = yes)
\
\                         * Byte #7: "X" is being pressed (0 = no, &FF = yes)
\
\                         * Byte #8: "S" is being pressed (0 = no, &FF = yes)
\
\                         * Byte #9: "A" is being pressed (0 = no, &FF = yes)
\
\ ******************************************************************************

.ReadKeyboard

 LDY #9                 \ We're going to loop through the eight keys in KYTB and
                        \ update the block pointed to by OSSC with their details
                        \
                        \ We want to store the results in bytes #2 to #9 in the
                        \ block, so we set a loop counter in Y to count down
                        \ from 9 to 2, so we can use this as an index into both
                        \ the OSSC block and the KYTB table

.DKL2

 LDA KYTB-2,Y           \ Set A to the relevant internal key number from the
                        \ KYTB table (we add Y to KYTB-2 rather than KYTB as Y
                        \ is looping from 9 down to 2, so this grabs the key
                        \ numbers from 7 to 1, i.e. from "A" to "?"

 DKS4                   \ Include macro DKS4 to check whether the key in A is
                        \ being pressed, and if it is, set bit 7 of A

 ASL A                  \ Shift bit 7 of A into the C flag

 LDA #0                 \ Set A = 0 + &FF + C
 ADC #&FF               \
                        \ If the C flag is set (i.e. the key is being pressed)
                        \ then this sets A = 0, otherwise it sets A = &FF

 EOR #%11111111         \ Flip all the bits in A, so now A = &FF if the key is
                        \ being pressed, or A = 0 if it isn't

 STA (OSSC),Y           \ Store A in the Y-th byte of the block pointed to by
                        \ OSSC

 DEY                    \ Decrement the loop counter

 CPY #1                 \ Loop back until we have processed all the keys
 BNE DKL2

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\ Save Lander.bin
\
\ ******************************************************************************

 SAVE "3-assembled-output/Lander.bin", CODE%, P%, LOAD%
