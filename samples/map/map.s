.include "ngin/ngin.inc"

.import smb3MapDataHeader
.import testMapDataHeader

; If 1, use the test map. If 0, use the SMB3 map.
kUseTestMap = 0

.segment "BSS"

controller: .byte 0
scrollX: .byte 0
scrollY: .byte 0
; Nametable bit (high bit of scroll) for both X and Y.
; In same format as required by ppu::ctrl.
scrollNametable: .byte 0

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    jsr uploadPalette
    jsr uploadNametable

    .if ::kUseTestMap
        ngin_MapData_load #testMapDataHeader
    .else
        ngin_MapData_load #smb3MapDataHeader
    .endif

    ; Some test routines, need to be run with rendering off.
    ; jsr horizontalTests
    ; jsr verticalTests
    ; jsr combinedTests

    jsr interactiveTest

    jmp *
.endproc

.proc horizontalTests
    ; Horizontal tests:

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollHorizontal #1
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollHorizontal #8
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollHorizontal #8
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollHorizontal #8
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollHorizontal #8
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    ngin_PpuBuffer_startFrame
    ngin_MapScroller_scrollHorizontal #ngin_signedByte -1
    ngin_PpuBuffer_endFrame
    ngin_PpuBuffer_upload

    ngin_PpuBuffer_startFrame
    ngin_MapScroller_scrollHorizontal #ngin_signedByte -8
    ngin_PpuBuffer_endFrame
    ngin_PpuBuffer_upload

    ngin_PpuBuffer_startFrame
    ngin_MapScroller_scrollHorizontal #ngin_signedByte -8
    ngin_PpuBuffer_endFrame
    ngin_PpuBuffer_upload

    ngin_PpuBuffer_startFrame
    ngin_MapScroller_scrollHorizontal #ngin_signedByte -8
    ngin_PpuBuffer_endFrame
    ngin_PpuBuffer_upload

    rts
.endproc

.proc verticalTests
    ; Vertical tests:

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollVertical #1
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollVertical #8
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollVertical #8
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    rts
.endproc

.proc combinedTests
    ; Combined tests:

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollHorizontal #8
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    ; ngin_PpuBuffer_startFrame
    ; ngin_MapScroller_scrollVertical #1
    ; ngin_PpuBuffer_endFrame
    ; ngin_PpuBuffer_upload

    rts
.endproc

.proc interactiveTest
    ; Initialize X scroll to 256, because initializeView scrolls 256 pixels to
    ; the right.
    lda #0
    sta scrollX
    sta scrollY
    ngin_mov8 scrollNametable, #%01

    jsr initializeView

    loop:
        ngin_PpuBuffer_startFrame
        jsr readController
        jsr interactiveLogic
        ngin_PpuBuffer_endFrame

        ngin_pollVBlank
        ngin_PpuBuffer_upload
        ngin_mov8 ppu::scroll, scrollX
        ngin_mov8 ppu::scroll, scrollY
        ngin_mov8 ppu::ctrl, scrollNametable
        ngin_mov8 ppu::mask, #( ppu::mask::kShowBackground | \
                                ppu::mask::kShowBackgroundLeft )
    jmp loop
.endproc

.proc readController
    ngin_Controller_read1
    sta controller

    rts
.endproc

.proc interactiveLogic
    ; Scroll the map based on controller input. Currently can only scroll
    ; one pixel at a time.
    ; PPU scroll coordinates are updated manually here. In practice might be
    ; better to get them from map scroller directly, since it needs to store
    ; them in some format anyways.

    lda controller
    and #ngin_Controller::kLeft
    ngin_branchIfZero notLeft
        ngin_MapScroller_scrollHorizontal #ngin_signedByte -1
        ldx scrollX
        ngin_branchIfNotZero :+
            lda scrollNametable
            eor #%1
            sta scrollNametable
        :
        dex
        stx scrollX
    notLeft:

    lda controller
    and #ngin_Controller::kRight
    ngin_branchIfZero notRight
        ngin_MapScroller_scrollHorizontal #ngin_signedByte 1
        inc scrollX
        ngin_branchIfNotZero :+
            lda scrollNametable
            eor #%1
            sta scrollNametable
        :
    notRight:

    lda controller
    and #ngin_Controller::kUp
    ngin_branchIfZero notUp
        ngin_MapScroller_scrollVertical #ngin_signedByte -1
        ldx scrollY
        ngin_branchIfNotZero :+
            lda scrollNametable
            eor #%10
            sta scrollNametable
            ldx #240
        :
        dex
        stx scrollY
    notUp:

    lda controller
    and #ngin_Controller::kDown
    ngin_branchIfZero notDown
        ngin_MapScroller_scrollVertical #ngin_signedByte 1
        ldx scrollY
        inx
        cpx #240
        bne :+
            lda scrollNametable
            eor #%10
            sta scrollNametable
            ldx #0
        :
        stx scrollY
    notDown:

out:
    rts
.endproc

.proc scrollTileRight
    ngin_PpuBuffer_startFrame
    ngin_MapScroller_scrollHorizontal #8
    ngin_PpuBuffer_endFrame
    ngin_PpuBuffer_upload

    rts
.endproc

.proc scrollTileDown
    ngin_PpuBuffer_startFrame
    ngin_MapScroller_scrollVertical #8
    ngin_PpuBuffer_endFrame
    ngin_PpuBuffer_upload

    rts
.endproc

.proc initializeView
    .pushseg
    .segment "BSS"
    counter: .byte 0
    .popseg

    ; Initialize the view by scrolling 256 pixels to the right.
    ; Assumes that we start from the top left part of the map.
    lda #256/8
    sta counter

    loop:
        jsr scrollTileRight
        ; jsr scrollTileDown
        dec counter
    ngin_branchIfNotZero loop

    rts
.endproc

.proc uploadPalette
    ngin_pollVBlank

    ; Set all palettes to black.
    ngin_setPpuAddress #ppu::backgroundPalette
    ngin_fillPort #ppu::data, #$F, #32

    .if ::kUseTestMap
        ; Set some colors.
        ngin_setPpuAddress #ppu::backgroundPalette+1
        ngin_mov8 ppu::data, #$15
        ngin_mov8 ppu::data, #$29
        ngin_mov8 ppu::data, #$11
        bit ppu::data ; Skip one byte.
        ngin_mov8 ppu::data, #$00
        ngin_mov8 ppu::data, #$10
        ngin_mov8 ppu::data, #$30
    .else
        .pushseg
        .segment "RODATA"
        .proc smb3Palette
            .byte $3C, $0F, $30, $3C
            .byte $3C, $0F, $36, $27
            .byte $3C, $0F, $2A, $1A
            .byte $3C, $0F, $31, $21
        .endproc
        .popseg
        ngin_setPpuAddress #ppu::backgroundPalette
        ngin_copyMemoryToPort #ppu::data, #smb3Palette, #.sizeof( smb3Palette )
    .endif

    rts
.endproc

.proc uploadNametable
    ngin_setPpuAddress #ppu::nametable0
    ngin_fillPort #ppu::data, #0, #4*1024

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "CHR_ROM"

.if kUseTestMap

    ngin_tile "        " \
              "        " \
              "        " \
              "        " \
              "        " \
              "        " \
              "        " \
              "        "

    ngin_tile "........" \
              "........" \
              "........" \
              "........" \
              "........" \
              "........" \
              "........" \
              "........"

    ngin_tile "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::" \
              "::::::::"

    ngin_tile "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########" \
              "########"

    ngin_tile ". . . . " \
              " . . . ." \
              ". . . . " \
              " . . . ." \
              ". . . . " \
              " . . . ." \
              ". . . . " \
              " . . . ."

.else

    .incbin "data/smb3.chr"

.endif