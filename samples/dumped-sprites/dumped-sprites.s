.include "ngin/ngin.inc"

.segment "RODATA"

.include "data/dump.ppumem-metasprites.inc"

.proc palette
    .incbin "data/dump.ppumem-palette.pal"
.endproc

; -----------------------------------------------------------------------------

.segment "CODE"

ngin_entryPoint start
.proc start
    jsr uploadPalette
    jsr renderSprites

    ngin_Ppu_pollVBlank
    ngin_ShadowOam_upload
    ngin_mov8 ppu::ctrl, #ppu::ctrl::kSpriteSize8x16
    ngin_mov8 ppu::mask, #( ppu::mask::kShowSprites | \
                            ppu::mask::kShowSpritesLeft )

    jmp *
.endproc

.proc uploadPalette
    ngin_Ppu_pollVBlank

    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_copyMemoryToPort #ppu::data, #palette, #.sizeof( palette )

    ; Change the background color.
    ngin_Ppu_setAddress #ppu::backgroundPalette
    ngin_mov8 ppu::data, #$21

    rts
.endproc

.proc renderSprites
    ngin_ShadowOam_startFrame

    ngin_SpriteRenderer_render #metasprite0, \
        #ngin_immVector2_16 ngin_SpriteRenderer_kOriginX+32, \
                                  ngin_SpriteRenderer_kOriginY

    ngin_SpriteRenderer_render #metasprite1, \
        #ngin_immVector2_16 ngin_SpriteRenderer_kOriginX-32, \
                                  ngin_SpriteRenderer_kOriginY

    ngin_ShadowOam_endFrame

    rts
.endproc

; -----------------------------------------------------------------------------

.segment "GRAPHICS"

.incbin "data/dump.ppumem-tiles.chr"
