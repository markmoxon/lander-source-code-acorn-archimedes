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
\ Most of the code in this source file is taken from the 6502 Second Processor
\ version of Elite, from these files:
\
\   * elite-loader1.asm
\   * elite-loader1.asm
\   * elite--z.asm
\
\ Modifications to the above code are marked up with comments.
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

 NVOSWRCH = &FFCB       \ The address for the non-vectored OSWRCH routine

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

                        \ --- Mod: Code added for AES: ------------------------>

 JSR PUTBACK            \ Call PUTBACK to point WRCHV to USOSWRCH, so from now
                        \ on the handlers pointed to by the vectors will handle
                        \ all character writes

                        \ --- End of added code ------------------------------->

 LDX #LO(MESS3)         \ Set (Y X) to point to MESS3 ("R.P.CODE")
 LDY #HI(MESS3)

 JMP OSCLI              \ Call OSCLI to run the OS command in MESS3, which *RUNs
                        \ the main parasite game code in P.CODE, returning from
                        \ the subroutine using a tail call

\ ******************************************************************************
\
\       Name: MESS3
\       Type: Variable
\   Category: Loader
\    Summary: The OS command string for running the parasite's main game code
\             in file P.CODE
\
\ ******************************************************************************

.MESS3

 EQUS "R.P.CODE"        \ This is short for "*RUN P.CODE"
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

                        \ --- Mod: Code added for AES: ------------------------>

 CPX #129               \ Also jump to OHMYGOD if we are printing character 129,
 BEQ OHMYGOD            \ as we use that to change screen mode to shadow mode 1

                        \ --- End of added code ------------------------------->

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

                        \ --- Mod: Code removed for AES: ---------------------->

\JMP TT26               \ Jump to TT26 to print the character in A, returning
\                       \ from the subroutine using a tail call

                        \ --- And replaced by: -------------------------------->

 JMP NVOSWRCH           \ Jump to the non-vectored OSWRCH to print the character
                        \ in A, returning from the subroutine using a tail call

                        \ --- End of replacement ------------------------------>

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

                        \ --- Mod: Code removed for AES: ---------------------->

\EQUW USOSWRCH          \              128 (&80)     0 = Put back to USOSWRCH
\EQUW BEGINLIN          \              129 (&81)     1 = Begin drawing a line
\EQUW ADDBYT            \              130 (&82)     2 = Add line byte/draw line
\EQUW DOFE21            \ #DOFE21    = 131 (&83)     3 = Show energy bomb effect
\EQUW DOHFX             \ #DOhfx     = 132 (&84)     4 = Show hyperspace colours
\EQUW SETXC             \ #SETXC     = 133 (&85)     5 = Set text cursor column
\EQUW SETYC             \ #SETYC     = 134 (&86)     6 = Set text cursor row
\EQUW CLYNS             \ #clyns     = 135 (&87)     7 = Clear bottom of screen
\EQUW RDPARAMS          \ #RDPARAMS  = 136 (&88)     8 = Update dashboard
\EQUW ADPARAMS          \              137 (&89)     9 = Add dashboard parameter
\EQUW DODIALS           \ #DODIALS   = 138 (&8A)    10 = Show or hide dashboard
\EQUW DOVIAE            \ #VIAE      = 139 (&8B)    11 = Set 6522 System VIA IER
\EQUW DOBULB            \ #DOBULB    = 140 (&8C)    12 = Toggle dashboard bulb
\EQUW DOCATF            \ #DOCATF    = 141 (&8D)    13 = Set disc catalogue flag
\EQUW DOCOL             \ #SETCOL    = 142 (&8E)    14 = Set the current colour
\EQUW SETVDU19          \ #SETVDU19  = 143 (&8F)    15 = Change mode 1 palette
\EQUW DOSVN             \ #DOsvn     = 144 (&90)    16 = Set file saving flag
\EQUW DOBRK             \              145 (&91)    17 = Execute BRK instruction
\EQUW printer           \ #printcode = 146 (&92)    18 = Write to printer/screen
\EQUW prilf             \ #prilf     = 147 (&93)    19 = Blank line on printer

                        \ --- And replaced by: -------------------------------->

 EQUW USOSWRCH          \ 128 (&80)     0 = Put back to USOSWRCH
 EQUW USOSWRCH          \ 129 (&81)     1 = Reserved for VDU code for mode 128+1
 EQUW ADDBYT            \ 130 (&82)     2 = Receive a pixel to draw
 EQUW BEGINLIN          \ 131 (&83)     3 = Start receiving pixels
 EQUW SetScreenBank     \ 132 (&84)     4 = Set screen bank to main or shadow
 EQUW ClearScreen       \ 133 (&85)     5 = Switch screen bank and clear screen
 EQUW SetScreenMode     \ 134 (&86)     6 = Set up the game's screen mode
 EQUW USOSWRCH          \ 135 (&87)     7 = Put back to USOSWRCH
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

                        \ --- End of replacement ------------------------------>

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

 LDA VIA+&34            \ Set bits 1 and 2 of the Access Control Register at
 AND #%11111000         \ SHEILA &34 to switch shadow RAM into &3000-&7FFF and
 ORA #%00000110         \ switch drawing to shadow RAM
 STA VIA+&34            \
                        \ Clear bit 0 to display main memory on screen

 RTS                    \ Return from the subroutine

.sban1

                        \ Display shadow RAM on screen and switch drawing to
                        \ main memory

 LDA VIA+&34            \ Clear bits 1 and 2 of the Access Control Register at
 AND #%11111000         \ SHEILA &34 to switch main memory into &3000-&7FFF and
 ORA #%00000001         \ switch drawing to main memory
 STA VIA+&34            \
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

 LDA minScreenAddr      \ Set P(1 0) = minScreenAddr(1 0)
 STA P
 LDA minScreenAddr+1
 STA P+1

 LDY #0                 \ Set Y = 0 so we can use STA (P),Y to mean STA (P)

 TYA                    \ Set A = 0 to use when clearing the screen

.clsc1

 STA (P),Y              \ Zero screen memory at P(1 0)

 INC P                  \ Increment the low byte of P(1 0)

 BNE clsc1              \ Loop back until we have reached the end of the page
                        \ containing P(1 0)

 INC P+1                \ Increment the high byte of P(1 0) so it points to the
                        \ start of the next page

                        \ We now blank the full pages in the range

 LDA maxScreenAddr+1    \ Set A to the number of pages in screen memory between
 SEC                    \ maxScreenAddr(1 0) and P(1 0)
 SBC P+1

 BEQ clsc3              \ If there are no full pages, jump to clsc3 to clear the
                        \ partial page at maxScreenAddr(1 0)

                        \ Otherwise we have A full pages to blank at P(1 0)

 TAX                    \ Set X to the number of pages in screen memory between
                        \ maxScreenAddr and minScreenAddr

 LDY #0                 \ Set Y = 0 as a byte counter for each page

 TYA                    \ Set A = 0 to use when clearing the screen

.clsc2

 STA (P),Y              \ Zero the Y-th byte of the P(1 0) memory block

 DEY                    \ Decrement the byte counter

 BNE clsc2              \ Loop back to copy the next byte until we have done a
                        \ whole page of 256 bytes

 INC P+1                \ Increment the high byte of the source address to point
                        \ to the next page

 DEX                    \ Decrement the page counter

 BNE clsc2              \ Loop back to copy the next page until we have done X
                        \ pages

.clsc3

                        \ We now clear the partial page from P(1 0) to
                        \ maxScreenAddr(1 0)

 LDA maxScreenAddr      \ Set A to the number of bytes in screen memory between
 SEC                    \ P(1 0) and maxScreenAddr(1 0), given that the high
 SBC P                  \ bytes match
 
 BEQ clsc5              \ If there are no bytes pages, jump to clsc5 to finish

                        \ Otherwise we have A bytes to blank at P(1 0)

 TAY                    \ Set Y to the number of bytes in screen memory between
                        \ P(1 0) and maxScreenAddr(1 0)

 LDA #0                 \ Set A = 0 to use when clearing the screen

.clsc4

 STA (P),Y              \ Zero the Y-th byte of the P(1 0) memory block

 DEY                    \ Decrement the byte counter

 BNE clsc4              \ Loop back to copy the next byte until we have done the
                        \ whole partial page

 STA (P),Y              \ Zero the byte at P(1 0)

.clsc5

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

 EQUB 19, 1, 5          \ Define logical colour 1 as magenta
 EQUB 0, 0, 0

 EQUB 19, 2, 2          \ Define logical colour 2 as green
 EQUB 0, 0, 0

 EQUB 19, 3, 4          \ Define logical colour 3 as blue
 EQUB 0, 0, 0

 EQUB 255               \ End of commands

\ ******************************************************************************
\
\       Name: BEGINLIN
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Implement the OSWRCH 129 <size> command (start receiving a new
\             line to draw)
\
\ ------------------------------------------------------------------------------
\
\ The parasite asks the I/O processor to draw a line by first sending an OSWRCH
\ 129 command to the I/O processor, to tell it to start receiving a new line to
\ draw. That call runs this routine on the receiving I/O processor. The next
\ parameter to this call (sent with the next OSWRCH) contains the number of
\ bytes we are going to send containing the line's coordinates, plus 1.
\
\ This routine then executes an OSWRCH 130 command, which calls the ADDBYT
\ routine to start the I/O processor listening for more bytes from the parasite.
\ These get added to the TABLE buffer, and when the parasite has sent all the
\ coordinates, we draw the line.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The number of points in the new line + 1
\
\ ******************************************************************************

.BEGINLIN

 STA LINMAX             \ Set LINMAX to the number of points in the new line + 1

 LDA #0                 \ Set LINTAB = 0 to point to the position of the next
 STA LINTAB             \ free byte in the TABLE buffer (i.e. the first byte, as
                        \ we have just reset the buffer)

 LDA #130               \ Execute a USOSWRCH 130 command so subsequent OSWRCH
 JMP USOSWRCH           \ calls from the parasite can send coordinates that get
                        \ added to TABLE, and return from the subroutine using a
                        \ tail call

\ ******************************************************************************
\
\       Name: ADDBYT
\       Type: Subroutine
\   Category: Drawing lines
\    Summary: Implement the OSWRCH 130 <byte> command (add a byte to a line and
\             draw it when all bytes are received)
\
\ ------------------------------------------------------------------------------
\
\ This routine receives bytes from the parasite, each of which is a coordinate
\ in the line that is currently being drawn (following a call from the parasite
\ to OSWRCH 129, which starts the I/O processor listening for line bytes). They
\ are stored in the buffer at TABLE, where LINTAB points to the first free byte
\ in the table, and LINMAX contains double the number of points we are expecting
\ plus 1.
\
\ If the byte received is the last one in the line, then the line segments are
\ drawn by sending them to the LOIN routine.
\
\ If a laser line is sent by the parasite, it will be the first line segment
\ sent, and will be preceded by a dummy pair of coordinates where the Y2 value
\ is 255, which is not in the space view (as the maximum y-coordinate in the
\ space view is 191). Laser lines are drawn in red.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   A                   The byte to be added to the line that's currently being
\                       transmitted to the I/O processor
\
\ ******************************************************************************

.RTS1

 RTS                    \ Return from the subroutine (this is called below)

.ADDBYT

 INC LINTAB             \ LINTAB points to the last free byte in TABLE, which is
                        \ where we're about to store the new byte in A, so
                        \ increment LINTAB to point to the byte after this one

 LDX LINTAB             \ Store the new byte in A at position LINTAB-1 in TABLE
 STA TABLE-1,X          \ (which was the last free byte before we incremented
                        \ LINTAB above)

 INX                    \ Increment X, so it now points to the byte after the
                        \ last free byte in TABLE (i.e. LINTAB + 1)

 CPX LINMAX             \ If X < LINMAX, jump up to RTS1 to return from the
 BCC RTS1               \ subroutine, as the line isn't complete yet (because
                        \ LINMAX contains the 2 * number of points + 1)

                        \ If we get here then X = LINMAX and we have received
                        \ all the pixel data from the parasite, so now we draw
                        \ them

                        \ --- Mod: Code removed for AES: ---------------------->

\LDY #0                 \ We are going to loop through all the points in the
\                       \ line, so set a counter in Y, starting from 0

                        \ --- And replaced by: -------------------------------->

 LDX #0                 \ We are going to loop through all the pixels in the
                        \ block, so set a counter in X, starting from 0

                        \ --- End of replacement ------------------------------>

 DEC LINMAX             \ Decrement LINMAX so it now contains 2 * number of
                        \ points

                        \ --- Mod: Code removed for AES: ---------------------->

\LDA TABLE+3            \ If TABLE+3 = 255, jump to doalaser to draw this line,
\CMP #255               \ as this denotes that the following segment is a laser
\BEQ doalaser           \ line, which should be drawn in red

                        \ --- End of removed code ----------------------------->

.LL27

                        \ --- Mod: Code removed for AES: ---------------------->

\LDA TABLE,Y            \ Set X1 to the Y-th byte from TABLE
\STA X1
\
\LDA TABLE+1,Y          \ Set Y1 to the Y+1-th byte from TABLE
\STA Y1
\
\LDA TABLE+2,Y          \ Set X2 to the Y+2-th byte from TABLE
\STA X2
\
\LDA TABLE+3,Y          \ Set Y2 to the Y+3-th byte from TABLE
\STA Y2
\
\STY T1                 \ Store the loop counter in T1 so we can retrieve it
\                       \ after the call to LOIN
\
\JSR LOIN               \ Draw a line from (X1, Y1) to (X2, Y2)
\
\LDA T1                 \ Retrieve the loop counter from T1
\
\CLC                    \ Set A = A + 4
\ADC #4
\
\.Ivedonealaser
\
\TAY                    \ Transfer the updated loop counter from A into Y
\
\CMP LINMAX             \ Loop back to LL27 to draw the next line segment, until
\BCC LL27               \ we the loop counter has reached LINMAX (which contains
\                       \ 2 * number of points, so this is when we have run out
\                       \ of points)

                        \ --- And replaced by: -------------------------------->

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

                        \ --- End of replacement ------------------------------>

.DRLR1

 JMP PUTBACK            \ Jump to PUTBACK to restore the USOSWRCH handler and
                        \ return from the subroutine using a tail call

                        \ --- Mod: Code removed for AES: ---------------------->

\.doalaser
\
\LDA COL                \ Store the current line colour on the stack, so we can
\PHA                    \ restore it below
\
\LDA #RED               \ Set the laser colour to red
\STA COL
\
\                       \ The coordinates at bytes Y to Y+3 were used up with
\                       \ the indicator bytes to say this is a laser line, so
\                       \ we need to fetch the following bytes to get the line's
\                       \ coordinates to draw
\
\LDA TABLE+4            \ Set X1 to the Y+4-th byte from TABLE
\STA X1
\
\LDA TABLE+5            \ Set Y1 to the Y+5-th byte from TABLE
\STA Y1
\
\LDA TABLE+6            \ Set X2 to the Y+6-th byte from TABLE
\STA X2
\
\LDA TABLE+7            \ Set Y2 to the Y+7-th byte from TABLE
\STA Y2
\
\JSR LOIN               \ Draw a line from (X1, Y1) to (X2, Y2)
\
\PLA                    \ Restore the original line colour from the stack
\STA COL
\
\LDA #8                 \ Jump up to Ivedonealaser with A set to 8, which will
\BNE Ivedonealaser      \ point to the rest of the lines as the laser line is
\                       \ always the first to be transmitted from the parasite
\                       \ (this BNE is effectively a JMP as A is never zero)

                        \ --- End of removed code ----------------------------->

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

 EQUW KEYBOARD          \            240 (&F0)     0 = Scan the keyboard

                        \ --- Mod: Code removed for AES: ---------------------->

\EQUW PIXEL             \            241 (&F1)     1 = Draw space view pixels
\EQUW MSBAR             \ #DOmsbar = 242 (&F2)     2 = Update missile indicators
\EQUW WSCAN             \ #wscn    = 243 (&F3)     3 = Wait for vertical sync
\EQUW SC48              \ #onescan = 244 (&F4)     4 = Draw ship on 3D scanner
\EQUW DOT               \ #DOdot   = 245 (&F5)     5 = Draw a dot on the compass
\EQUW DODKS4            \ #DODKS4  = 246 (&F6)     6 = Scan for a specific key

                        \ --- And replaced by: -------------------------------->

 EQUW SetScreenRange    \            241 (&F1)     1 = Set max/min screen addrs
 EQUW ScanKeyboard      \            242 (&F2)     2 = Scan keyboard for any key
 EQUW SAFE              \            243 (&F3)     3 = Do nothing
 EQUW SAFE              \            244 (&F4)     4 = Do nothing
 EQUW SAFE              \            245 (&F5)     5 = Do nothing
 EQUW SAFE              \            246 (&F6)     6 = Do nothing

                        \ --- End of replacement ------------------------------>

 EQUW SAFE              \            247 (&F7)     7 = Do nothing
 EQUW SAFE              \            248 (&F8)     8 = Do nothing
 EQUW SAFE              \            249 (&F9)     9 = Do nothing
 EQUW SAFE              \            250 (&FA)    10 = Do nothing
 EQUW SAFE              \            251 (&FB)    11 = Do nothing
 EQUW SAFE              \            252 (&FC)    12 = Do nothing
 EQUW SAFE              \            253 (&FD)    13 = Do nothing
 EQUW SAFE              \            254 (&FE)    14 = Do nothing
 EQUW SAFE              \            255 (&FF)    15 = Do nothing

                        \ --- Mod: Code removed for AES: ---------------------->

\EQUW SAFE              \ These addresses are never used and have no effect, as
\EQUW SAFE              \ they are out of range for one-byte OSWORD numbers
\EQUW SAFE

                        \ --- End of removed code ----------------------------->

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

                        \ --- Mod: Code removed for AES: ---------------------->

\BIT svn                \ If bit 7 of svn is set, jump to notours to process
\BMI notours            \ this call with the standard OSWORD handler

                        \ --- End of removed code ----------------------------->

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
\    Summary: Lookup table for in-flight keyboard controls
\  Deep dive: The key logger
\
\ ------------------------------------------------------------------------------
\
\ Keyboard table for in-flight controls. This table contains the internal key
\ codes for the flight keys (see page 142 of the "Advanced User Guide for the
\ BBC Micro" by Bray, Dickens and Holmes for a list of internal key numbers).
\
\ The pitch, roll, speed and laser keys (i.e. the seven primary flight
\ control keys) have bit 7 set, so they have 128 added to their internal
\ values. This doesn't appear to be used anywhere.
\
\ Note that KYTB actually points to the byte before the start of the table, so
\ the offset of the first key value is 1 (i.e. KYTB+1), not 0.
\
\ ******************************************************************************

.KYTB

                        \ --- Mod: Code removed for AES: ---------------------->

\EQUB 0                 \ Pad the table out so that the first key is at KYTB+1
\
\                       \ These are the primary flight controls (pitch, roll,
\                       \ speed and lasers):
\
\EQUB &68 + 128         \ ?         KYTB+1      Slow down
\EQUB &62 + 128         \ Space     KYTB+2      Speed up
\EQUB &66 + 128         \ <         KYTB+3      Roll left
\EQUB &67 + 128         \ >         KYTB+4      Roll right
\EQUB &42 + 128         \ X         KYTB+5      Pull up
\EQUB &51 + 128         \ S         KYTB+6      Pitch down
\EQUB &41 + 128         \ A         KYTB+7      Fire lasers
\
\                       \ These are the secondary flight controls:
\
\EQUB &60               \ TAB       KYTB+8      Energy bomb
\EQUB &70               \ ESCAPE    KYTB+9      Launch escape pod
\EQUB &23               \ T         KYTB+10     Target missile
\EQUB &35               \ U         KYTB+11     Unarm missile
\EQUB &65               \ M         KYTB+12     Fire missile
\EQUB &22               \ E         KYTB+13     E.C.M.
\EQUB &45               \ J         KYTB+14     In-system jump
\EQUB &52               \ C         KYTB+15     Docking computer
\
\NOP                    \ In the parasite's version of this table, this byte
\                       \ maps to "P", the key to cancel the docking computer,
\                       \ but because the I/O processor only uses this table for
\                       \ the primary flight keys, this byte isn't used

                        \ --- And replaced by: -------------------------------->

 EQUB &70               \ ESCAPE    KYTB+0      Quit
 EQUB &68               \ ?         KYTB+1      Hover
 EQUB &62               \ Space     KYTB+2      Thrust
 EQUB &66               \ <         KYTB+3      Yaw left
 EQUB &67               \ >         KYTB+4      Yaw right
 EQUB &42               \ X         KYTB+5      Pull up
 EQUB &51               \ S         KYTB+6      Pitch down
 EQUB &41               \ A         KYTB+7      Fire

                        \ --- End of replacement ------------------------------>


\ ******************************************************************************
\
\       Name: KEYBOARD
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Implement the OSWORD 240 command (scan the keyboard and joystick
\             and log the results)
\
\ ------------------------------------------------------------------------------
\
\ This routine is run when the parasite sends an OSWORD 240 command. It scans
\ the keyboard and joystick and stores the results in the key logger buffer
\ pointed to by OSSC, which is then sent across the Tube to the parasite's own
\ key logger buffer at KTRAN.
\
\ First, it scans the keyboard for the primary flight keys. If any of the
\ primary flight keys are pressed, the corresponding byte in the key logger is
\ set to &FF, otherwise it is set to 0. If multiple flight keys are being
\ pressed, they are all logged.
\
\ Next, it scans the keyboard for any other key presses, starting with internal
\ key number 16 ("Q") and working through the set of internal key numbers (see
\ page 142 of the "Advanced User Guide for the BBC Micro" by Bray, Dickens and
\ Holmes for a list of internal key numbers). If a key press is detected, the
\ internal key number is stored in byte #2 of the key logger table and scanning
\ stops.
\
\ Finally, the joystick is read for X, Y and fire button values. The rotation
\ value is also read from the Bitstik.
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
\                         * Byte #2: If a non-primary flight control key is
\                           being pressed, its internal key number is put here
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
\                         * Byte #10: Joystick X value (high byte)
\
\                         * Byte #11: Joystick Y value (high byte)
\
\                         * Byte #12: Bitstik rotation value (high byte)
\
\                         * Byte #14: Joystick 1 fire button is being pressed
\                           (Bit 4 set = no, Bit 4 clear = yes)
\
\ ******************************************************************************

.KEYBOARD

 LDY #9                 \ We're going to loop through the seven primary flight
                        \ controls in KYTB and update the block pointed to by
                        \ OSSC with their details. We want to store the seven
                        \ results in bytes #2 to #9 in the block, so we set a
                        \ loop counter in Y to count down from 9 to 3, so we can
                        \ use this as an index into both the OSSC block and the
                        \ KYTB table

.DKL2

 LDA KYTB-2,Y           \ Set A to the relevant internal key number from the
                        \ KYTB table (we add Y to KYTB-2 rather than KYTB as Y
                        \ is looping from 9 down to 3, so this grabs the key
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

                        \ --- Mod: Code removed for AES: ---------------------->

\CPY #2                 \ Loop back until we have processed all seven primary
\BNE DKL2               \ flight keys, leaving the loop with Y = 2

                        \ --- And replaced by: -------------------------------->

 CPY #1                 \ Loop back until we have processed all eight primary
 BNE DKL2               \ flight keys

 RTS                    \ Return from the subroutine

.ScanKeyboard

                        \ --- End of replacement ------------------------------>

 LDA #16                \ We start scanning from internal key number 16 ("Q"),
                        \ so we set A as a loop counter

 SED                    \ Set the D flag to enter decimal mode. Because
                        \ internal key numbers are all valid BCD (Binary Coded
                        \ Decimal) numbers, setting this flag ensures we only
                        \ loop through valid key numbers. To put this another
                        \ way, when written in hexadecimal, internal key numbers
                        \ only use the digits 0-9 and none of the letters A-F,
                        \ and setting the D flag makes the following loop
                        \ iterate through the following values of A:
                        \
                        \ &10, &11, &12, &13, &14, &15, &16, &17, &18, &19,
                        \ &20, &21, &22, &23, &24, &25, &26, &27, &28, &29,
                        \ &30, &31...
                        \
                        \ and so on up to &79, and then &80, at which point the
                        \ loop terminates. This lets us efficiently work our
                        \ way through all the internal key numbers without
                        \ wasting time on numbers that aren't valid in BCD

.DKL3

 DKS4                   \ Include macro DKS4 to check whether the key in A is
                        \ being pressed, and if it is, set bit 7 of A

 TAX                    \ Copy the key press result into X

 BMI DK1                \ If bit 7 is set, i.e. the key is being pressed, skip
                        \ to DK1

 CLC                    \ Otherwise this key is not being pressed, so increment
 ADC #1                 \ the loop counter in A. We couldn't use an INX or INY
                        \ instruction here because the only instructions that
                        \ support decimal mode are ADC and SBC. INX and INY
                        \ always increment in binary mode, whatever the setting
                        \ of the D flag, so instead we have to use an ADC

 BPL DKL3               \ Loop back to test the next key, ending the loop when
                        \ A is negative (i.e. A = &80 = 128 = %10000000)

.DK1

 CLD                    \ Clear the D flag to return to binary mode

 EOR #%10000000         \ EOR A with #%10000000 to flip bit 7, so A now contains
                        \ 0 if no key has been pressed, or the internal key
                        \ number if a key has been pressed

                        \ --- Mod: Code added for AES: ------------------------>

 LDY #2                 \ Set Y = 2 so we store the result in byte #2 of the
                        \ block pointed to by OSSC

                        \ --- End of added code ------------------------------->

 STA (OSSC),Y           \ We exited the first loop above with Y = 2, so this
                        \ stores the "other key" result in byte #2 of the block
                        \ pointed to by OSSC

                        \ --- Mod: Code removed for AES: ---------------------->

\                       \ We now check the joystick or Bitstik
\
\LDX #1                 \ Call OSBYTE with A = 128 to fetch the 16-bit value
\LDA #128               \ from ADC channel 1 (the joystick X value), returning
\JSR OSBYTE             \ the value in (Y X)
\                       \
\                       \   * Channel 1 is the x-axis: 0 = right, 65520 = left
\
\TYA                    \ Copy Y to A, so the result is now in (A X)
\
\LDY #10                \ Store the high byte of the joystick X value in byte
\STA (OSSC),Y           \ #10 of the block pointed to by OSSC
\
\LDX #2                 \ Call OSBYTE with A = 128 to fetch the 16-bit value
\LDA #128               \ from ADC channel 2 (the joystick Y value), returning
\JSR OSBYTE             \ the value in (Y X)
\                       \
\                       \   * Channel 2 is the y-axis: 0 = down,  65520 = up
\
\TYA                    \ Copy Y to A, so the result is now in (A X)
\
\LDY #11                \ Store the high byte of the joystick Y value in byte
\STA (OSSC),Y           \ #11 of the block pointed to by OSSC
\
\LDX #3                 \ Call OSBYTE with A = 128 to fetch the 16-bit value
\LDA #128               \ from ADC channel 3 (the Bitstik rotation value),
\JSR OSBYTE             \ returning the value in (Y X)
\
\TYA                    \ Copy Y to A, so the result is now in (A X)
\
\LDY #12                \ Store the high byte of the Bitstik rotation value in
\STA (OSSC),Y           \ byte #12 of the block pointed to by OSSC
\
\LDY #14                \ Read 6522 System VIA input register IRB (SHEILA &40),
\LDA &FE40              \ which has bit 4 clear if joystick 1's fire button is
\STA (OSSC),Y           \ pressed (otherwise it's set), and store the value in
\                       \ byte #14 of the block pointed to by OSSC
\
\.DK2

                        \ --- End of removed code ----------------------------->

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: SetScreenRange
\       Type: Subroutine
\   Category: Keyboard
\    Summary: Implement the OSWORD 241 command (set the maximum and minimum
\             address for the current frame)
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   OSSC                The address of the table in which to log the key presses
\
\ ******************************************************************************

                        \ --- Mod: Code added for AES: ------------------------>

.SetScreenRange

 LDY #2                 \ Fetch bytes #2 and #3 from the parameter block and
 LDA (OSSC),Y           \ store them in minScreenAddr(1 0)
 STA minScreenAddr
 INY
 LDA (OSSC),Y
 STA minScreenAddr+1

 INY                    \ Fetch bytes #4 and #5 from the parameter block and
 LDA (OSSC),Y           \ store them in maxScreenAddr(1 0)
 STA maxScreenAddr
 INY
 LDA (OSSC),Y
 STA maxScreenAddr+1

 RTS                    \ Return from the subroutine

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: minScreenAddr
\       Type: Variable
\   Category: Keyboard
\    Summary: The lowest screen address containing content in this frame
\
\ ******************************************************************************

                        \ --- Mod: Code added for AES: ------------------------>

.minScreenAddr

 EQUW &3780

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\       Name: maxScreenAddr
\       Type: Variable
\   Category: Keyboard
\    Summary: The highest screen address containing content in this frame
\
\ ******************************************************************************

                        \ --- Mod: Code added for AES: ------------------------>

.maxScreenAddr

 EQUW &7FFF

                        \ --- End of added code ------------------------------->

\ ******************************************************************************
\
\ Save Lander.bin
\
\ ******************************************************************************

 SAVE "3-assembled-output/Lander.bin", CODE%, P%, LOAD%
