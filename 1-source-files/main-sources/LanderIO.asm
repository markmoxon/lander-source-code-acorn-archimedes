\ Lander I/O

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

 OSWRCH = &FFEE         \ The address for the OSWRCH routine

 OSBYTE = &FFF4         \ The address for the OSBYTE routine

 OSWORD = &FFF1         \ The address for the OSWORD routine

 OSCLI = &FFF7          \ The address for the OSCLI routine

 WHITE   = %11111010    \ Four mode 1 pixels of colour 3, 2, 3, 2 (cyan/red)

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

.SWAP

 SKIP 1                 \ Temporary storage, used to store a flag that records
                        \ whether or not we had to swap a line's start and end
                        \ coordinates around when clipping the line in routine
                        \ LL145 (the flag is used in places like BLINE to swap
                        \ them back)

.T1

 SKIP 1                 \ Temporary storage, used in a number of places

.COL

 SKIP 1                 \ Temporary storage, used to store colour information
                        \ when drawing pixels in the dashboard

.OSSC

 SKIP 2                 \ When the parasite sends an OSWORD command to the I/O
                        \ processor (i.e. an OSWORD with A = 240 to 255), then
                        \ the relevant handler routine in the I/O processor is
                        \ called with OSSC(1 0) pointing to the OSWORD parameter
                        \ block (i.e. OSSC(1 0) = (Y X) from the original call
                        \ in the I/O processor)

 ORG &0090              \ Set the assembly address to &0090

.XX15

 SKIP 0                 \ Temporary storage, typically used for storing screen
                        \ coordinates in line-drawing routines
                        \
                        \ There are six bytes of storage, from XX15 TO XX15+5.
                        \ The first four bytes have the following aliases:
                        \
                        \   X1 = XX15
                        \   Y1 = XX15+1
                        \   X2 = XX15+2
                        \   Y2 = XX15+3
                        \
                        \ These are typically used for describing lines in terms
                        \ of screen coordinates, i.e. (X1, Y1) to (X2, Y2)
                        \
                        \ The last two bytes of XX15 do not have aliases

.X1

 SKIP 1                 \ Temporary storage, typically used for x-coordinates in
                        \ the line-drawing routines

.Y1

 SKIP 1                 \ Temporary storage, typically used for y-coordinates in
                        \ line-drawing routines

.X2

 SKIP 1                 \ Temporary storage, typically used for x-coordinates in
                        \ the line-drawing routines

.Y2

 SKIP 1                 \ Temporary storage, typically used for y-coordinates in
                        \ line-drawing routines

 SKIP 2                 \ The last 2 bytes of the XX15 block

.SC

 SKIP 1                 \ Screen address (low byte)
                        \
                        \ Elite draws on-screen by poking bytes directly into
                        \ screen memory, and SC(1 0) is typically set to the
                        \ address of the character block containing the pixel
                        \ we want to draw

.SCH

 SKIP 1                 \ Screen address (high byte)

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

 LDA #22                \ Mode 1
 JSR OSWRCH
 LDA #1
 JSR OSWRCH

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

 EQUW SAFE              \            240 (&F0)     0 = Do nothing
 EQUW PIXEL             \            241 (&F1)     1 = Draw space view pixels
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
\       Name: PIXEL
\       Type: Subroutine
\   Category: Drawing pixels
\    Summary: Implement the OSWORD 241 command (draw space view pixels)
\  Deep dive: Drawing colour pixels on the BBC Micro
\
\ ------------------------------------------------------------------------------
\
\ This routine is run when the parasite sends an OSWORD 241 command with
\ parameters in the block at OSSC(1 0). It draws a dot (or collection of dots)
\ in the space view.
\
\ It can draw two types of dot, depending on bits 0-2 of the dot's distance:
\
\   * Draw the dot using the dot's distance to determine both the dot's colour
\     and size. This draws a one-pixel dot, two-pixel dash or four-pixel square
\     in a colour that's determined by the distance (as per the colour table in
\     PXCL). These kinds of dot are sent by the PIXEL3 routine in the parasite,
\     which is used to draw explosion particles.
\
\   * Draw the dot using the dot's distance to determine the dot's size, either
\     a two-pixel dash or four-pixel square. The dot is always drawn in white
\     (which is actually a cyan/red stripe). These kinds of dot are sent by the
\     PIXEL routine in the parasite, which is used to draw stardust particles
\     and dots on the Long-range Chart.
\
\ The parameters match those put into the PBUF/pixbl block in the parasite.
\
\ ------------------------------------------------------------------------------
\
\ Arguments:
\
\   OSSC(1 0)           A parameter block as follows:
\
\                         * Byte #0 = The size of the pixel buffer being sent
\
\                         * Byte #2 = The distance of the first dot
\
\                           * Bits 0-2 clear = Draw a two-pixel dash or
\                             four-pixel square, as determined by the distance,
\                             in white (cyan/red)
\
\                           * Any of bits 0-2 set = Draw a one-pixel dot,
\                             two-pixel dash or four-pixel square in the correct
\                             colour, as determined by the distance
\
\                         * Byte #3 = The x-coordinate of the first dot
\
\                         * Byte #4 = The y-coordinate of the first dot
\
\                         * Byte #5 = The distance of the second dot
\
\                         * Byte #6 = The x-coordinate of the second dot
\
\                         * Byte #7 = The y-coordinate of the second dot
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

 LDA (OSSC),Y           \ Set P to byte #2 from the Y-th pixel block in OSSC,
 STA P                  \ which contains the point's distance value (ZZ)

                        \ If we get here then the pixel's distance value (ZZ) is
                        \ a multiple of 8, as set by the parasite's PIXEL
                        \ routine

 INY                    \ Increment Y to 3

 LDA (OSSC),Y           \ Set X to byte #3 from the Y-th pixel block in OSSC,
 TAX                    \ which contains the pixel's x-coordinate

 INY                    \ Increment Y to 4

 LDA (OSSC),Y           \ Set Y to byte #4 from the Y-th pixel block in OSSC,
 STY T1                 \ which contains the pixel's y-coordinate, and store Y,
 TAY                    \ the index of this pixel's y-coordinate, in T1, so we
                        \ can restore it at the end of the subroutine

 LDA ylookup,Y          \ Look up the page number of the character row that
 STA SC+1               \ contains the pixel with the y-coordinate in Y, and
                        \ store it in the high byte of SC(1 0) at SC+1

 TXA                    \ Each character block contains 8 pixel rows, so to get
 AND #%11111100         \ the address of the first byte in the character block
 ASL A                  \ that we need to draw into, as an offset from the start
                        \ of the row, we clear bits 0-1 and shift left to double
                        \ it (as each character row contains two pages of bytes,
                        \ or 512 bytes, which cover 256 pixels). This also
                        \ shifts bit 7 of the x-coordinate into the C flag

 STA SC                 \ Store the address of the character block in the low
                        \ byte of SC(1 0), so now SC(1 0) points to the
                        \ character block we need to draw into

 BCC P%+4               \ If the C flag is clear then skip the next instruction

 INC SC+1               \ The C flag is set, which means bit 7 of X1 was set
                        \ before the ASL above, so the x-coordinate is in the
                        \ right half of the screen (i.e. in the range 128-255).
                        \ Each row takes up two pages in memory, so the right
                        \ half is in the second page but SC+1 contains the value
                        \ we looked up from ylookup, which is the page number of
                        \ the first memory page for the row... so we need to
                        \ increment SC+1 to point to the correct page

 TYA                    \ Set Y = Y mod 8, which is the pixel row within the
 AND #7                 \ character block at which we want to draw the start of
 TAY                    \ our line (as each character block has 8 rows)

 TXA                    \ Copy bits 0-1 of the x-coordinate to bits 0-1 of X,
 AND #%00000011         \ which will now be in the range 0-3, and will contain
 TAX                    \ the two pixels to show in the character row

 LDA P                  \ Fetch the pixel's distance from P

 CMP #80                \ If the pixel's ZZ distance is >= 80, then the dot is
 BCS PX6                \ a medium distance away, so jump to PX6 to draw a
                        \ single pixel

 LDA TWOS2,X            \ Fetch a mode 1 two-pixel byte with the pixels set as
 AND #WHITE             \ in X, and AND with #WHITE to make it white (i.e.
                        \ cyan/red)

 EOR (SC),Y             \ Draw the pixel on-screen using EOR logic, so we can
 STA (SC),Y             \ remove it later without ruining the background that's
                        \ already on-screen

 DEY                    \ Reduce Y by 1 to point to the pixel row above the one
 BPL P%+4               \ we just plotted, and if it is still positive, skip the
                        \ next instruction

 LDY #1                 \ Reducing Y by 1 made it negative, which means Y was
                        \ 0 before we did the DEY above, so set Y to 1 to point
                        \ to the pixel row after the one we just plotted

                        \ We now draw our second dash

.PX6

 LDA TWOS2,X            \ Fetch a mode 1 two-pixel byte with the pixels set as
 AND #WHITE             \ in X, and AND with #WHITE to make it white (i.e.
                        \ cyan/red)

 EOR (SC),Y             \ Draw the pixel on-screen using EOR logic, so we can
 STA (SC),Y             \ remove it later without ruining the background that's
                        \ already on-screen

 LDY T1                 \ Set Y to the index of this pixel's y-coordinate byte
                        \ in the command block, which we stored in T1 above

 INY                    \ Increment Y, so it now points to the first byte of
                        \ the next pixel in the command block

 CPY Q                  \ If the index has reached the value in Q (which
 BEQ P%+5               \ contains the size of the pixel buffer), skip the next
                        \ instruction

 JMP PXLO               \ We haven't reached the end of the buffer, so loop back
                        \ to PXLO to draw the next pixel in the buffer

 RTS                    \ Return from the subroutine

\ ******************************************************************************
\
\       Name: ylookup
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Lookup table for converting pixel y-coordinate to page number of
\             screen address
\
\ ------------------------------------------------------------------------------
\
\ Elite's screen mode is based on mode 1, so it allocates two pages of screen
\ memory to each character row (where a character row is 8 pixels high). This
\ table enables us to convert a pixel y-coordinate in the range 0-247 into the
\ page number for the start of the character row containing that coordinate.
\
\ Screen memory is from &4000 to &7DFF, so the lookup works like this:
\
\   Y =   0 to  7,  lookup value = &40 (so row 1 is from &4000 to &41FF)
\   Y =   8 to 15,  lookup value = &42 (so row 2 is from &4200 to &43FF)
\   Y =  16 to 23,  lookup value = &44 (so row 3 is from &4400 to &45FF)
\   Y =  24 to 31,  lookup value = &46 (so row 4 is from &4600 to &47FF)
\
\   ...
\
\   Y = 232 to 239, lookup value = &7A (so row 31 is from &7A00 to &7BFF)
\   Y = 240 to 247, lookup value = &7C (so row 32 is from &7C00 to &7DFF)
\
\ There is also a lookup value for y-coordinates from 248 to 255, but that's off
\ the end of the screen, as the special Elite screen mode only has 31 character
\ rows.
\
\ ******************************************************************************

.ylookup

 FOR I%, 0, 255

  EQUB &40 + ((I% DIV 8) * 2)

 NEXT

\ ******************************************************************************
\
\       Name: TWOS2
\       Type: Variable
\   Category: Drawing pixels
\    Summary: Ready-made double-pixel character row bytes for mode 1
\
\ ------------------------------------------------------------------------------
\
\ Ready-made bytes for plotting two-pixel dashes in mode 1 (the top part of the
\ split screen).
\
\ ******************************************************************************

.TWOS2

 EQUB %11001100
 EQUB %01100110
 EQUB %00110011
 EQUB %00110011

\ ******************************************************************************
\
\ Save I.LANDER.bin
\
\ ******************************************************************************

 SAVE "3-assembled-output/I.LANDER.bin", CODE%, P%, LOAD%
