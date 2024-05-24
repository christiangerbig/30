; ##############################
; # Programm: 30.asm           #
; # Autor:    Christian Gerbig #
; # Datum:    17.04.2024       #
; # Version:  1.0 beta         #
; # CPU:      68020+           #
; # FASTMEM:  -                #
; # Chipset:  AGA              #
; # OS:       3.0+             #
; ##############################

; V1.0 beta
; First release

  SECTION code_and_variables,CODE

  MC68040


; ** Library-Includes V.3.x nachladen **
; --------------------------------------
  ;INCDIR  "OMA:include/"
  INCDIR "Daten:include3.5/"

  INCLUDE "dos/dos.i"
  INCLUDE "dos/dosextens.i"
  INCLUDE "libraries/dos_lib.i"

  INCLUDE "exec/exec.i"
  INCLUDE "exec/exec_lib.i"

  INCLUDE "graphics/GFXBase.i"
  INCLUDE "graphics/videocontrol.i"
  INCLUDE "graphics/graphics_lib.i"

  INCLUDE "intuition/intuition.i"
  INCLUDE "intuition/intuition_lib.i"

  INCLUDE "resources/cia_lib.i"

  INCLUDE "hardware/adkbits.i"
  INCLUDE "hardware/blit.i"
  INCLUDE "hardware/cia.i"
  INCLUDE "hardware/custom.i"
  INCLUDE "hardware/dmabits.i"
  INCLUDE "hardware/intbits.i"

  INCDIR "Daten:Asm-Sources.AGA/normsource-includes/"


; ** Konstanten **
; ----------------

  INCLUDE "equals.i"

requires_68030                 EQU FALSE  
requires_68040                 EQU FALSE
requires_68060                 EQU FALSE
requires_fast_memory           EQU FALSE
requires_multiscan_monitor     EQU FALSE

workbench_start                EQU FALSE
workbench_fade                 EQU FALSE
text_output                    EQU FALSE

pt_v3.0b

  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-equals.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-equals.i"
  ENDC
;pt_mute_volume
pt_ciatiming                   EQU TRUE
pt_usedfx                      EQU %1101110000101101
pt_usedefx                     EQU %0000100000000000
pt_finetune                    EQU FALSE
  IFD pt_v3.0b
pt_metronome                   EQU FALSE
  ENDC
pt_track_channel_volumes       EQU TRUE
pt_track_channel_periods       EQU FALSE
pt_music_fader                 EQU TRUE
pt_split_module                EQU TRUE

DMABITS                        EQU DMAF_SPRITE+DMAF_COPPER+DMAF_BLITTER+DMAF_RASTER+DMAF_MASTER+DMAF_SETCLR

  IFEQ pt_ciatiming
INTENABITS                     EQU INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ELSE
INTENABITS                     EQU INTF_VERTB+INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ENDC

CIAAICRBITS                    EQU CIAICRF_SETCLR
  IFEQ pt_ciatiming
CIABICRBITS                    EQU CIAICRF_TA+CIAICRF_TB+CIAICRF_SETCLR
  ELSE
CIABICRBITS                    EQU CIAICRF_TB+CIAICRF_SETCLR
  ENDC

COPCONBITS                     EQU TRUE

pf1_x_size1                    EQU 0
pf1_y_size1                    EQU 0
pf1_depth1                     EQU 0
pf1_x_size2                    EQU 0
pf1_y_size2                    EQU 0
pf1_depth2                     EQU 0
pf1_x_size3                    EQU 0
pf1_y_size3                    EQU 0
pf1_depth3                     EQU 0
pf1_colors_number              EQU 240

pf2_x_size1                    EQU 0
pf2_y_size1                    EQU 0
pf2_depth1                     EQU 0
pf2_x_size2                    EQU 0
pf2_y_size2                    EQU 0
pf2_depth2                     EQU 0
pf2_x_size3                    EQU 0
pf2_y_size3                    EQU 0
pf2_depth3                     EQU 0
pf2_colors_number              EQU 0
pf_colors_number               EQU pf1_colors_number+pf2_colors_number
pf_depth                       EQU pf1_depth3+pf2_depth3

extra_pf_number                EQU 2
extra_pf1_x_size               EQU 384
extra_pf1_y_size               EQU 26
extra_pf1_depth                EQU 1
extra_pf2_x_size               EQU 384
extra_pf2_y_size               EQU 26
extra_pf2_depth                EQU 1

spr_number                     EQU 8
spr_x_size1                    EQU 0
spr_x_size2                    EQU 64
spr_depth                      EQU 2
spr_colors_number              EQU 16
spr_odd_color_table_select     EQU 2
spr_even_color_table_select    EQU 2
spr_used_number                EQU 8

  IFD pt_v2.3a
audio_memory_size              EQU 0
  ENDC
  IFD pt_v3.0b
audio_memory_size              EQU 2
  ENDC

disk_memory_size               EQU 0

extra_memory_size              EQU 0

chip_memory_size               EQU 0

AGA_OS_Version                 EQU 39

  IFEQ pt_ciatiming
CIABCRABITS                    EQU CIACRBF_LOAD
  ENDC
CIABCRBBITS                    EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;Oneshot mode
CIAA_TA_value                  EQU 0
CIAA_TB_value                  EQU 0
  IFEQ pt_ciatiming
CIAB_TA_value                  EQU 14187 ;= 0.709379 MHz * [20000 µs = 50 Hz duration for one frame on a PAL machine]
;CIAB_TA_value                  EQU 14318 ;= 0.715909 MHz * [20000 µs = 50 Hz duration for one frame on a NTSC machine]
  ELSE
CIAB_TA_value                  EQU 0
  ENDC
CIAB_TB_value                  EQU 362 ;= 0.709379 MHz * [511.43 µs = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [506.76 µs = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
CIAA_TA_continuous             EQU FALSE
CIAA_TB_continuous             EQU FALSE
  IFEQ pt_ciatiming
CIAB_TA_continuous             EQU TRUE
  ELSE
CIAB_TA_continuous             EQU FALSE
  ENDC
CIAB_TB_continuous             EQU FALSE

beam_position                  EQU $133 ;Wegen Music-Fader

MINROW                         EQU VSTART_256_lines

display_window_HSTART          EQU HSTART_320_pixel
display_window_VSTART          EQU MINROW
DIWSTRTBITS                    EQU ((display_window_VSTART&$ff)*DIWSTRTF_V0)+(display_window_HSTART&$ff)
display_window_HSTOP           EQU HSTOP_320_pixel
display_window_VSTOP           EQU MINROW+26 ;VSTOP_256_lines
DIWSTOPBITS                    EQU ((display_window_VSTOP&$ff)*DIWSTOPF_V0)+(display_window_HSTOP&$ff)

spr_pixel_per_datafetch        EQU 64 ;4x

; **** Viewport 1 ****
vp1_pixel_per_line             EQU 320
vp1_visible_pixels_number      EQU 320
vp1_visible_lines_number       EQU 26

vp1_VSTART                     EQU MINROW
vp1_VSTOP                      EQU vp1_VSTART+vp1_visible_lines_number

vp1_pf_pixel_per_datafetch     EQU 64 ;4x
vp1_DDFSTRTBITS                EQU DDFSTART_320_pixel
vp1_DDFSTOPBITS                EQU DDFSTOP_320_pixel_4x

vp1_pf1_depth                  EQU 1
vp1_pf1_colors_number          EQU 2

extra_pf1_plane_width          EQU extra_pf1_x_size/8
extra_pf2_plane_width          EQU extra_pf2_x_size/8
vp1_data_fetch_width           EQU vp1_pixel_per_line/8
vp1_pf1_plane_moduli           EQU (extra_pf1_plane_width*(extra_pf1_depth-1))+extra_pf1_plane_width-vp1_data_fetch_width

BPLCON0BITS                    EQU BPLCON0F_ECSENA+((pf_depth>>3)*BPLCON0F_BPU3)+(BPLCON0F_COLOR)+((pf_depth&$07)*BPLCON0F_BPU0) ;lores
BPLCON3BITS1                   EQU BPLCON3F_SPRES0
BPLCON3BITS2                   EQU BPLCON3BITS1+BPLCON3F_LOCT
BPLCON4BITS                    EQU (BPLCON4F_OSPRM4*spr_odd_color_table_select)+(BPLCON4F_ESPRM4*spr_even_color_table_select)
DIWHIGHBITS                    EQU (((display_window_HSTOP&$100)>>8)*DIWHIGHF_HSTOP8)+(((display_window_VSTOP&$700)>>8)*DIWHIGHF_VSTOP8)+(((display_window_HSTART&$100)>>8)*DIWHIGHF_HSTART8)+((display_window_VSTART&$700)>>8)
FMODEBITS                      EQU FMODEF_SPR32+FMODEF_SPAGEM+FMODEF_SSCAN2
COLOR00BITS                    EQU $001122

vp1_BPLCON0BITS                EQU BPLCON0F_ECSENA+((extra_pf1_depth>>3)*BPLCON0F_BPU3)+(BPLCON0F_COLOR)+((extra_pf1_depth&$07)*BPLCON0F_BPU0) ;lores
vp1_BPLCON1BITS                EQU TRUE
vp1_BPLCON2BITS                EQU TRUE
vp1_BPLCON3BITS1               EQU BPLCON3BITS1
vp1_BPLCON3BITS2               EQU vp1_BPLCON3BITS1+BPLCON3F_LOCT
vp1_BPLCON4BITS                EQU BPLCON4BITS
vp1_FMODEBITS                  EQU FMODEBITS+FMODEF_BPL32+FMODEF_BPAGEM
vp1_COLOR00BITS                EQU COLOR00BITS
vp1_COLOR01HIGHBITS            EQU $012
vp1_COLOR01LOWBITS             EQU $012

cl2_HSTART1                    EQU $00
cl2_VSTART1                    EQU MINROW
cl2_HSTART2                    EQU $00
cl2_VSTART2                    EQU beam_position&$ff

sine_table_length              EQU 256

; **** PT-Replay ****
pt_fade_out_delay              EQU 2 ;Ticks

; **** Hintergrundbild ****
bg_image_x_size                EQU 256
bg_image_plane_width           EQU bg_image_x_size/8
bg_image_y_size                EQU 208
bg_image_depth                 EQU 4
bg_image_x_position            EQU 16
bg_image_y_position            EQU MINROW

; **** Horiz-Scrolltext ****
hst_image_x_size               EQU 320
hst_image_plane_width          EQU hst_image_x_size/8
hst_image_depth                EQU 1
hst_origin_character_x_size    EQU 32
hst_origin_character_y_size    EQU 26

hst_text_character_x_size      EQU 16
hst_text_character_width       EQU hst_text_character_x_size/8
hst_text_character_y_size      EQU hst_origin_character_y_size
hst_text_character_depth       EQU hst_image_depth

hst_horiz_scroll_window_x_size EQU vp1_visible_pixels_number+hst_text_character_x_size
hst_horiz_scroll_window_width  EQU hst_horiz_scroll_window_x_size/8
hst_horiz_scroll_window_y_size EQU hst_text_character_y_size
hst_horiz_scroll_window_depth  EQU hst_image_depth
hst_horiz_scroll_speed         EQU 2

hst_text_character_x_restart   EQU hst_horiz_scroll_window_x_size
hst_text_characters_number     EQU hst_horiz_scroll_window_x_size/hst_text_character_x_size

hst_text_x_position            EQU 32
hst_text_y_position            EQU 0

; **** Bounce-VU-Meter ****
bvm_bar_height                 EQU 6
bvm_bars_number                EQU 4
bvm_max_amplitude              EQU vp1_visible_lines_number-bvm_bar_height
bvm_y_centre                   EQU vp1_visible_lines_number-bvm_bar_height
bvm_y_angle_speed              EQU 4


vp1_pf1_bitplanes_x_offset     EQU 1*vp1_pf_pixel_per_datafetch
vp1_pf1_bitplanes_y_offset     EQU 0


; ## Makrobefehle ##
; ------------------

  INCLUDE "macros.i"


; ** Struktur, die alle Exception-Vektoren-Offsets enthält **
; -----------------------------------------------------------

  INCLUDE "except-vectors-offsets.i"


; ** Struktur, die alle Eigenschaften des Extra-Playfields enthält **
; -------------------------------------------------------------------

  INCLUDE "extra-pf-attributes-structure.i"


; ** Struktur, die alle Eigenschaften der Sprites enthält **
; ----------------------------------------------------------

  INCLUDE "sprite-attributes-structure.i"


; ** Struktur, die alle Registeroffsets der ersten Copperliste enthält **
; -----------------------------------------------------------------------
  RSRESET

cl1_begin            RS.B 0

  INCLUDE "copperlist1-offsets.i"

cl1_COPJMP2          RS.L 1

copperlist1_SIZE     RS.B 0


; ** Struktur, die alle Registeroffsets der zweiten Copperliste enthält **
; ------------------------------------------------------------------------
  RSRESET

cl2_extension1      RS.B 0

cl2_ext1_DDFSTRT    RS.L 1
cl2_ext1_DDFSTOP    RS.L 1
cl2_ext1_BPLCON1    RS.L 1
cl2_ext1_BPLCON2    RS.L 1
cl2_ext1_BPLCON3_1  RS.L 1
cl2_ext1_BPL1MOD    RS.L 1
cl2_ext1_BPL2MOD    RS.L 1
cl2_ext1_BPLCON4    RS.L 1
cl2_ext1_FMODE      RS.L 1
cl2_ext1_BPL1PTH    RS.L 1
cl2_ext1_BPL1PTL    RS.L 1

cl2_extension1_SIZE RS.B 0


  RSRESET

cl2_extension2        RS.B 0

cl2_ext2_WAIT         RS.L 1
cl2_ext2_BPLCON3_1    RS.L 1
cl2_ext2_COLOR01_high RS.L 1
cl2_ext2_BPLCON3_2    RS.L 1
cl2_ext2_COLOR01_low  RS.L 1
cl2_ext2_BPLCON4      RS.L 1

cl2_extension2_SIZE   RS.B 0


  RSRESET

cl2_begin            RS.B 0

; **** Viewport 1 ****
cl2_extension1_entry RS.B cl2_extension1_SIZE
cl2_WAIT1            RS.L 1
cl2_BPLCON0_1        RS.L 1
cl2_extension2_entry RS.B cl2_extension2_SIZE*vp1_visible_lines_number

cl1_WAIT1            RS.L 1
cl1_WAIT2            RS.L 1
cl1_INTREQ           RS.L 1

cl2_end              RS.L 1

copperlist2_SIZE     RS.B 0


; ** Konstanten für die größe der Copperlisten **
; -----------------------------------------------
cl1_size1              EQU 0
cl1_size2              EQU 0
cl1_size3              EQU copperlist1_SIZE
cl2_size1              EQU 0
cl2_size2              EQU copperlist2_SIZE
cl2_size3              EQU copperlist2_SIZE


; ** Sprite0-Zusatzstruktur **
; ----------------------------
  RSRESET

spr0_extension1       RS.B 0

spr0_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr0_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg_image_y_size

spr0_extension1_SIZE  RS.B 0

; ** Sprite0-Hauptstruktur **
; ---------------------------
  RSRESET

spr0_begin            RS.B 0

spr0_extension1_entry RS.B spr0_extension1_SIZE

spr0_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite0_SIZE          RS.B 0

; ** Sprite1-Zusatzstruktur **
; ----------------------------
  RSRESET

spr1_extension1       RS.B 0

spr1_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr1_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg_image_y_size

spr1_extension1_SIZE  RS.B 0

; ** Sprite1-Hauptstruktur **
; ---------------------------
  RSRESET

spr1_begin            RS.B 0

spr1_extension1_entry RS.B spr1_extension1_SIZE

spr1_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite1_SIZE          RS.B 0

; ** Sprite2-Zusatzstruktur **
; ----------------------------
  RSRESET

spr2_extension1       RS.B 0

spr2_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr2_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg_image_y_size

spr2_extension1_SIZE  RS.B 0

; ** Sprite2-Hauptstruktur **
; ---------------------------
  RSRESET

spr2_begin            RS.B 0

spr2_extension1_entry RS.B spr2_extension1_SIZE

spr2_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite2_SIZE          RS.B 0

; ** Sprite3-Zusatzstruktur **
; ----------------------------
  RSRESET

spr3_extension1       RS.B 0

spr3_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr3_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg_image_y_size

spr3_extension1_SIZE  RS.B 0

; ** Sprite3-Hauptstruktur **
; ---------------------------
  RSRESET

spr3_begin            RS.B 0

spr3_extension1_entry RS.B spr3_extension1_SIZE

spr3_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite3_SIZE          RS.B 0

; ** Sprite4-Zusatzstruktur **
; ----------------------------
  RSRESET

spr4_extension1       RS.B 0

spr4_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr4_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg_image_y_size

spr4_extension1_SIZE  RS.B 0

; ** Sprite4-Hauptstruktur **
; ---------------------------
  RSRESET

spr4_begin            RS.B 0

spr4_extension1_entry RS.B spr4_extension1_SIZE

spr4_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite4_SIZE          RS.B 0

; ** Sprite5-Zusatzstruktur **
; ----------------------------
  RSRESET

spr5_extension1       RS.B 0

spr5_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr5_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg_image_y_size

spr5_extension1_SIZE  RS.B 0

; ** Sprite5-Hauptstruktur **
; ---------------------------
  RSRESET

spr5_begin            RS.B 0

spr5_extension1_entry RS.B spr5_extension1_SIZE

spr5_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite5_SIZE          RS.B 0

; ** Sprite6-Zusatzstruktur **
; ----------------------------
  RSRESET

spr6_extension1       RS.B 0

spr6_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr6_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg_image_y_size

spr6_extension1_SIZE  RS.B 0

; ** Sprite6-Hauptstruktur **
; ---------------------------
  RSRESET

spr6_begin            RS.B 0

spr6_extension1_entry RS.B spr6_extension1_SIZE

spr6_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite6_SIZE          RS.B 0

; ** Sprite7-Zusatzstruktur **
; ----------------------------
  RSRESET

spr7_extension1       RS.B 0

spr7_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr7_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg_image_y_size

spr7_extension1_SIZE  RS.B 0

; ** Sprite7-Hauptstruktur **
; ---------------------------
  RSRESET

spr7_begin            RS.B 0

spr7_extension1_entry RS.B spr7_extension1_SIZE

spr7_end              RS.L 1*(spr_pixel_per_datafetch/16)

sprite7_SIZE          RS.B 0


; ** Konstanten für die Größe der Spritestrukturen **
; ---------------------------------------------------
spr0_x_size1        EQU spr_x_size1
spr0_y_size1        EQU 0
spr1_x_size1        EQU spr_x_size1
spr1_y_size1        EQU 0
spr2_x_size1        EQU spr_x_size1
spr2_y_size1        EQU 0
spr3_x_size1        EQU spr_x_size1
spr3_y_size1        EQU 0
spr4_x_size1        EQU spr_x_size1
spr4_y_size1        EQU 0
spr5_x_size1        EQU spr_x_size1
spr5_y_size1        EQU 0
spr6_x_size1        EQU spr_x_size1
spr6_y_size1        EQU 0
spr7_x_size1        EQU spr_x_size1
spr7_y_size1        EQU 0

spr0_x_size2        EQU spr_x_size2
spr0_y_size2        EQU sprite0_SIZE/(spr_x_size2/8)
spr1_x_size2        EQU spr_x_size2
spr1_y_size2        EQU sprite1_SIZE/(spr_x_size2/8)
spr2_x_size2        EQU spr_x_size2
spr2_y_size2        EQU sprite2_SIZE/(spr_x_size2/8)
spr3_x_size2        EQU spr_x_size2
spr3_y_size2        EQU sprite3_SIZE/(spr_x_size2/8)
spr4_x_size2        EQU spr_x_size2
spr4_y_size2        EQU sprite4_SIZE/(spr_x_size2/8)
spr5_x_size2        EQU spr_x_size2
spr5_y_size2        EQU sprite5_SIZE/(spr_x_size2/8)
spr6_x_size2        EQU spr_x_size2
spr6_y_size2        EQU sprite6_SIZE/(spr_x_size2/8)
spr7_x_size2        EQU spr_x_size2
spr7_y_size2        EQU sprite7_SIZE/(spr_x_size2/8)


; ** Struktur, die alle Variablenoffsets enthält **
; -------------------------------------------------

  INCLUDE "variables-offsets.i"

; ** Relative offsets for variables **
; ------------------------------------

; **** PT-Replay ****
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-variables-offsets.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-variables-offsets.i"
  ENDC

; **** Viewport 1 ****
vp1_pf1_construction2      RS.L 1
vp1_pf1_display            RS.L 1

; **** Horiz-Scrolltext ****
hst_image                  RS.L 1
hst_text_table_start       RS.W 1
hst_text_BLTCON0BITS       RS.W 1
hst_character_toggle_image RS.W 1

variables_SIZE             RS.B 0


; **** PT-Replay ****
; ** PT-Song-Structure **
; -----------------------
  INCLUDE "music-tracker/pt-song-structure.i"

; ** Temporary channel structure **
; ---------------------------------
  INCLUDE "music-tracker/pt-temp-channel-structure.i"

; **** Bounce-VU-Meter ****
; ** Structure for channel info **
; --------------------------------
  RSRESET

bvm_audchaninfo      RS.B 0

bvm_aci_yangle       RS.W 1
bvm_aci_amplitude    RS.W 1

bvm_audchaninfo_SIZE RS.B 0


; ## Beginn des Initialisierungsprogramms ##
; ------------------------------------------

  INCLUDE "sys-init.i"

; ** Eigene Variablen initialisieren **
; -------------------------------------
  CNOP 0,4
init_own_variables

; **** PT-Replay ****
  IFD pt_v2.3a
    PT2_INIT_VARIABLES
  ENDC
  IFD pt_v3.0b
    PT3_INIT_VARIABLES
  ENDC

; **** Viewport 1 ****
  move.l  extra_pf1(a3),vp1_pf1_construction2(a3)
  move.l  extra_pf2(a3),vp1_pf1_display(a3)

; **** Horiz-Scrolltext ****
  lea     hst_image_data,a0
  move.l  a0,hst_image(a3)
  moveq   #TRUE,d0
  move.w  d0,hst_text_table_start(a3)
  move.w  d0,hst_text_BLTCON0BITS(a3)
  move.w  d0,hst_character_toggle_image(a3)
  rts

; ** Alle Initialisierungsroutinen ausführen **
; ---------------------------------------------
  CNOP 0,4
init_all
  bsr.s   pt_DetectSysFrequ
  bsr.s   init_CIA_timers
  bsr     pt_InitRegisters
  bsr     pt_InitAudTempStrucs
  bsr     pt_ExamineSongStruc
  IFEQ pt_finetune
    bsr     pt_InitFtuPeriodTableStarts
  ENDC
  bsr     init_sprites
  bsr     hst_init_characters_offsets
  bsr     hst_init_characters_x_positions
  bsr     hst_init_characters_images
  bsr     bvm_init_audio_channel_info_tables
  bsr     bvm_init_color_table
  bsr     init_first_copperlist
  bra     init_second_copperlist

; ** Detect system frequency NTSC/PAL **
; --------------------------------------
  PT_DETECT_SYS_FREQUENCY

; ** CIA-Timer initialisieren **
; ------------------------------
  CNOP 0,4
init_CIA_timers

; **** PT-Replay ****
  PT_INIT_TIMERS
  rts

; ** Audioregister initialisieren **
; ----------------------------------
   PT_INIT_REGISTERS

; ** Temporäre Audio-Kanal-Struktur initialisieren **
; ---------------------------------------------------
   PT_INIT_AUDIO_TEMP_STRUCTURES

; ** Höchstes Pattern ermitteln und Tabelle mit Zeigern auf Samples initialisieren **
; -----------------------------------------------------------------------------------
   PT_EXAMINE_SONG_STRUCTURE

  IFEQ pt_finetune
; ** FineTuning-Offset-Tabelle initialisieren **
; ----------------------------------------------
    PT_INIT_FINETUNING_PERIOD_TABLE_STARTS
  ENDC

; ** Sprites initialisieren **
; ----------------------------
  CNOP 0,4
init_sprites
  bsr.s   spr_init_pointers_table
  bra.s   bg_init_attached_sprites_cluster

; ** Tabelle mit Zeigern auf Sprites initialisieren **
; ----------------------------------------------------
  INIT_SPRITE_POINTERS_TABLE

; ** Spritestrukturen initialisieren **
; -------------------------------------
  INIT_ATTACHED_SPRITES_CLUSTER bg,spr_pointers_display,bg_image_x_position,bg_image_y_position,spr_x_size2,bg_image_y_size,,,REPEAT

; **** Horiz-Scrolltext ****
; ** Offsets der Buchstaben im Characters-Pic berechnen **
; --------------------------------------------------------
  INIT_CHARACTERS_OFFSETS.W hst

; ** X-Positionen der Chars berechnen **
; --------------------------------------
  INIT_CHARACTERS_X_POSITIONS hst,LORES

; ** Laufschrift initialisieren **
; --------------------------------
  INIT_CHARACTERS_IMAGES hst

; **** Bouncing-VU-Meter ****
; ** Audiochannel-Info-Tabellen initialisieren **
; -----------------------------------------------
  CNOP 0,4
bvm_init_audio_channel_info_tables
  lea     bvm_audio_channel1_info(pc),a0
  moveq   #sine_table_length/4,d0 ;90 Grad = Maximaler Ausschlag der Sinuskurve
  move.w  d0,(a0)+           ;Y-Winkel
  moveq   #TRUE,d1
  move.w  d1,(a0)            ;Amplitude = 0
  lea     bvm_audio_channel2_info(pc),a0
  move.w  d0,(a0)+
  move.w  d1,(a0)
  lea     bvm_audio_channel3_info(pc),a0
  move.w  d0,(a0)+
  move.w  d1,(a0)
  lea     bvm_audio_channel4_info(pc),a0
  move.w  d0,(a0)+
  move.w  d1,(a0)
  rts

; ** Farbwerte der Bar initialisieren **
; --------------------------------------
  CNOP 0,4
bvm_init_color_table
  move.l  #COLOR00BITS,d1
  lea     bvm_color_gradients(pc),a0 ;Quelle Farbverlauf
  lea     bvm_color_table(pc),a1 ;Ziel
  moveq   #bvm_bars_number-1,d7 ;Anzahl der Abschnitte
bvm_init_color_table_loop1
  moveq   #(bvm_bar_height/2)-1,d6 ;Anzahl der Zeilen
bvm_init_color_table_loop2
  move.l  (a0)+,d0           ;RGB8-Farbwert
  move.l  d1,(a1)+           ;COLOR00
  moveq   #(spr_colors_number-1)-1,d5 ;Anzahl der Farbwerte pro Palettenabschnitt
bvm_init_color_table_loop3
  move.l  d0,(a1)+           ;Farbwert eintragen
  dbf     d5,bvm_init_color_table_loop3
  dbf     d6,bvm_init_color_table_loop2
  dbf     d7,bvm_init_color_table_loop1
  rts


; ** 1. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_first_copperlist
  move.l  cl1_display(a3),a0
  bsr.s   cl1_init_playfield_registers
  bsr     cl1_init_sprite_pointers
  bsr     cl1_init_color_registers
  COPMOVEQ TRUE,COPJMP2
  bra     cl1_set_sprite_pointers

  COP_INIT_PLAYFIELD_REGISTERS cl1,NOBITPLANESSPR

  COP_INIT_SPRITE_POINTERS cl1

  CNOP 0,4
cl1_init_color_registers
  COP_INIT_COLORHI COLOR00,1,pf1_color_table
  COP_SELECT_COLORHI_BANK 1
  COP_INIT_COLORHI COLOR00,16,spr_color_table
  COP_INIT_COLORHI COLOR16,16,bvm_color_table
  COP_SELECT_COLORHI_BANK 2
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 3
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 4
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 5
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 6
  COP_INIT_COLORHI COLOR00,32
  COP_SELECT_COLORHI_BANK 7
  COP_INIT_COLORHI COLOR00,16

  COP_INIT_COLORLO COLOR00,1,pf1_color_table
  COP_SELECT_COLORLO_BANK 0
  COP_INIT_COLORLO COLOR00,1,pf1_color_table
  COP_SELECT_COLORLO_BANK 1
  COP_INIT_COLORLO COLOR00,16,spr_color_table
  COP_INIT_COLORLO COLOR16,16,bvm_color_table
  COP_SELECT_COLORLO_BANK 2
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 3
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 4
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 5
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 6
  COP_INIT_COLORLO COLOR00,32
  COP_SELECT_COLORLO_BANK 7
  COP_INIT_COLORLO COLOR00,16
  rts

  COP_INIT_BITPLANE_POINTERS cl1

  COP_SET_SPRITE_POINTERS cl1,display,spr_number


; ** 2. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_second_copperlist
  move.l  cl2_construction2(a3),a0
; **** Viewport 1 ****
  bsr     cl2_vp1_init_playfield_registers
  bsr     cl2_vp1_init_bitplane_pointers
  COPWAIT 0,vp1_VSTART
  COPMOVEQ vp1_BPLCON0BITS,BPLCON0
  bsr     cl2_vp1_init_color_gradient_registers
; **** Copper-Interrupt ****
  bsr     cl2_init_copint
  COPLISTEND
  bsr     cl2_vp1_set_bitplane_pointers
  bsr     cl2_vp1_set_color_gradient
  bsr     copy_second_copperlist
  bsr     swap_second_copperlist
  bra     swap_vp1_playfield1

; **** Viewport 1 ****
  COP_INIT_PLAYFIELD_REGISTERS cl2,,vp1

  CNOP 0,4
cl2_vp1_init_bitplane_pointers
  MOVEF.W BPL1PTH,d0
  moveq   #(vp1_pf1_depth*2)-1,d7 ;Anzahl der Bitplanes
cl2_vp1_init_bitplane_pointers_loop
  move.w  d0,(a0)            ;BPLxPTH/L
  addq.w  #2,d0              ;nächstes Register
  addq.w  #4,a0              ;nächster Eintrag in CL
  dbf     d7,cl2_vp1_init_bitplane_pointers_loop
  rts

  CNOP 0,4
cl2_vp1_init_color_gradient_registers
  move.l  #(((cl2_VSTART1<<24)|(((cl2_HSTART1/4)*2)<<16))|$10000)|$fffe,d0 ;WAIT-Befehl
  move.l  #(BPLCON3<<16)|vp1_BPLCON3BITS1,d1 ;High-Werte
  move.l  #(COLOR01<<16)|vp1_COLOR01HIGHBITS,d2
  move.l  #(BPLCON3<<16)|vp1_BPLCON3BITS2,d3 ;Low-RGB-Werte
  move.l  #(COLOR01<<16)|vp1_COLOR01LOWBITS,d4
  move.l  #(BPLCON4<<16)|vp1_BPLCON4BITS,d5
  moveq   #1,d6
  ror.l   #8,d6              ;$01000000 Additionswert
  MOVEF.W vp1_visible_lines_number-1,d7 ;Anzahl der Zeilen
cl2_vp1_init_color_gradient_registers_loop
  move.l  d0,(a0)+           ;WAIT x,y
  move.l  d1,(a0)+           ;High-Werte
  move.l  d2,(a0)+           ;COLOR01
  move.l  d3,(a0)+           ;Low-Werte
  move.l  d4,(a0)+           ;COLOR01
  add.l   d6,d0              ;nächste Zeile
  move.l  d5,(a0)+           ;BPLCON4
  dbf     d7,cl2_vp1_init_color_gradient_registers_loop
  rts

  COP_INIT_COPINT cl2,cl2_HSTART2,cl2_VSTART2,YWRAP

  CNOP 0,4
cl2_vp1_set_bitplane_pointers
  move.l  cl2_display(a3),a0 ;CL
  ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1PTH+2,a0
  move.l  vp1_pf1_display(a3),a1 ;Zeiger auf erste Plane
  moveq   #vp1_pf1_depth-1,d7 ;Anzahl der Bitplanes
cl2_vp1_set_bitplane_pointers_loop
  move.w  (a1)+,(a0)         ;High-Wert
  addq.w  #8,a0              ;nächter Playfieldzeiger
  move.w  (a1)+,4-8(a0)      ;Low-Wert
  dbf     d7,cl2_vp1_set_bitplane_pointers_loop
  rts

  CNOP 0,4
cl2_vp1_set_color_gradient
  move.w  #$0f0f,d3          ;RGB-Maske
  lea     hst_color_gradient(pc),a0
  move.l  cl2_construction2(a3),a1
  ADDF.W  cl2_extension2_entry+cl2_ext2_COLOR01_high+2,a1
  move.w  #cl2_extension2_SIZE,a2
  MOVEF.W vp1_visible_lines_number-1,d7
cl2_vp1_set_color_gradient_loop
  move.l  (a0)+,d0
  move.l  d0,d2
  RGB8_TO_RGB4HI d0,d1,d3
  move.w  d0,(a1)            ;High-Werte
  RGB8_TO_RGB4LO d2,d1,d3
  move.w  d2,cl2_ext2_COLOR01_low-cl2_ext2_COLOR01_high(a1) ;Low-Werte
  add.l   a2,a1
  dbf     d7,cl2_vp1_set_color_gradient_loop
  rts

  COPY_COPPERLIST cl2,2


; ** CIA-Timer starten **
; -----------------------

  INCLUDE "continuous-timers-start.i"


; ## Hauptprogramm ##
; -------------------
; a3 ... Basisadresse aller Variablen
; a4 ... CIA-A-Base
; a5 ... CIA-B-Base
; a6 ... DMACONR
  CNOP 0,4
main_routine
  bsr.s   no_sync_routines
  bra.s   beam_routines


; ## Routinen, die nicht mit der Bildwiederholfrequenz gekoppelt sind ##
; ----------------------------------------------------------------------
  CNOP 0,4
no_sync_routines
  rts


; ## Rasterstahl-Routinen ##
; --------------------------
  CNOP 0,4
beam_routines
  bsr     wait_copint
  bsr     swap_second_copperlist
  bsr     swap_vp1_playfield1
  bsr     horiz_scrolltext
  bsr     hst_horiz_scroll
  bsr     bvm_get_channels_amplitudes
  bsr     bvm_clear_second_copperlist
  bsr     bvm_set_bars
  IFEQ pt_music_fader
    bsr     pt_mouse_handler
  ENDC
  btst    #CIAB_GAMEPORT0,CIAPRA(a4) ;Auf linke Maustaste warten
  bne.s   beam_routines
  rts


; ** Copperlisten vertauschen **
; ------------------------------
  SWAP_COPPERLIST cl2,2

; ** Playfield1 vertauschen **
; ----------------------------
  CNOP 0,4
swap_vp1_playfield1
  move.l  cl2_display(a3),a0
  move.l  vp1_pf1_construction2(a3),a1
  ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1PTH+2,a0
  move.l  vp1_pf1_display(a3),vp1_pf1_construction2(a3)
  MOVEF.L (vp1_pf1_bitplanes_x_offset/8)+(vp1_pf1_bitplanes_y_offset*extra_pf1_plane_width*vp1_pf1_depth),d1
  move.l  a1,vp1_pf1_display(a3)
  moveq   #vp1_pf1_depth-1,d7   ;Anzahl der Planes
swap_vp1_playfield1_loop
  move.l  (a1)+,d0
  add.l   d1,d0
  move.w  d0,4(a0)           ;BPLxPTL
  swap    d0                 ;High
  move.w  d0,(a0)            ;BPLxPTH
  addq.w  #8,a0
  dbf     d7,swap_vp1_playfield1_loop
  rts


; ** Laufschrift **
; -----------------
  CNOP 0,4
horiz_scrolltext
  movem.l a4-a5,-(a7)
  bsr.s   hst_init_character_blit
  move.l  vp1_pf1_construction2(a3),a0
  MOVEF.L (hst_text_x_position/8)+(hst_text_y_position*extra_pf1_plane_width*vp1_pf1_depth),d3
  add.l   (a0),d3
  move.w  #(hst_text_character_y_size*hst_text_character_depth*64)+(hst_text_character_x_size/16),d4 ;BLTSIZE
  move.w  #hst_text_character_x_restart,d5
  lea     hst_characters_x_positions(pc),a0 ;X-Positionen der Chars
  lea     hst_characters_image_pointers(pc),a1 ;Zeiger auf Adressen der Chars-Images
  lea     BLTAPT-DMACONR(a6),a2    ;Offset der Blitterregister auf Null setzen
  lea     BLTDPT-DMACONR(a6),a4
  lea     BLTSIZE-DMACONR(a6),a5
  bsr.s   hst_get_text_softscroll
  moveq   #hst_text_characters_number-1,d7 ;Anzahl der Chars
horiz_scrolltext_loop
  moveq   #TRUE,d0           ;Langwort-Zugriff
  move.w  (a0),d0            ;X-Position
  move.w  d0,d2              ;X retten
  lsr.w   #3,d0              ;X/8
  add.l   d3,d0              ;X-Offset
  WAITBLITTER
  move.l  (a1)+,(a2)         ;Char-Image
  move.l  d0,(a4)            ;Playfield
  move.w  d4,(a5)            ;Blitter starten
  subq.w  #hst_horiz_scroll_speed,d2 ;X-Position verringern
  bpl.s   hst_set_character_x_position ;Wenn positiv -> verzweige
hst_new_character_image
  move.l  a0,-(a7)
  bsr.s   hst_get_new_character_image
  move.l  (a7)+,a0
  move.l  d0,-4(a1)          ;Neues Bild für Character
  add.w   d5,d2              ;X-Pos Neustart
hst_set_character_x_position
  move.w  d2,(a0)+           ;X-Pos retten
  dbf     d7,horiz_scrolltext_loop
  movem.l (a7)+,a4-a5
  move.w  #DMAF_BLITHOG,DMACON-DMACONR(a6) ;BLTPRI aus
  rts
  CNOP 0,4
hst_init_character_blit
  move.w  #DMAF_BLITHOG+DMAF_SETCLR,DMACON-DMACONR(a6) ;BLTPRI an
  WAITBLITTER
  move.l  #(BC0F_SRCA+BC0F_DEST+ANBNC+ANBC+ABNC+ABC)<<16,BLTCON0-DMACONR(a6) ;Minterm D=A
  moveq   #FALSE,d0
  move.l  d0,BLTAFWM-DMACONR(a6) ;keine Ausmaskierung
  move.l  #((hst_image_plane_width-hst_text_character_width)<<16)+(extra_pf1_plane_width-hst_text_character_width),BLTAMOD-DMACONR(a6) ;A-Mod + D-Mod
  rts

; ** Softscrollwert berechen **
; -----------------------------
  CNOP 0,4
hst_get_text_softscroll
  moveq   #hst_text_character_x_size-1,d0
  and.w   (a0),d0            ;X-Pos.&$f
  ror.w   #4,d0              ;Bits in richtige Position bringen
  or.w    #BC0F_SRCA+BC0F_DEST+ANBNC+ANBC+ABNC+ABC,d0 ;Minterm  D=A
  move.w  d0,hst_text_BLTCON0BITS(a3) ;retten
  rts

; ** Neues Image für Character ermitteln **
; -----------------------------------------
  GET_NEW_CHARACTER_IMAGE hst

; ** Laufschrift bewegen **
; -------------------------
  CNOP 0,4
hst_horiz_scroll
  move.l  vp1_pf1_construction2(a3),a0
  move.l  (a0),a0
  ADDF.W  (hst_text_x_position/8)+(hst_text_y_position*extra_pf1_plane_width*vp1_pf1_depth),a0
  WAITBLITTER
  move.w  hst_text_BLTCON0BITS(a3),BLTCON0-DMACONR(a6)
  move.l  a0,BLTAPT-DMACONR(a6) ;Quelle
  addq.w  #2,a0              ;16 Pixel überspringen
  move.l  a0,BLTDPT-DMACONR(a6) ;Ziel
  move.l  #((extra_pf1_plane_width-hst_horiz_scroll_window_width)<<16)+(extra_pf1_plane_width-hst_horiz_scroll_window_width),BLTAMOD-DMACONR(a6) ;A-Mod + D-Mod
  move.w  #(hst_horiz_scroll_window_y_size*hst_horiz_scroll_window_depth*64)+(hst_horiz_scroll_window_x_size/16),BLTSIZE-DMACONR(a6) ;Blitter starten
  rts

; ** Amplituden der einzelnen Kanäle in Erfahrung bringen **
; ----------------------------------------------------------
  CNOP 0,4
bvm_get_channels_amplitudes
  MOVEF.W bvm_max_amplitude,d2
  moveq   #sine_table_length/4,d3
  lea	  pt_audchan1temp(pc),a0 ;Zeiger auf temporäre Struktur des 1. Kanals
  lea     bvm_audio_channel1_info(pc),a1
  bsr.s   bvm_get_channel_amplitude
  lea	  pt_audchan2temp(pc),a0 ;Zeiger auf temporäre Struktur des 2. Kanals
  bsr.s   bvm_get_channel_amplitude
  lea	  pt_audchan3temp(pc),a0 ;Zeiger auf temporäre Struktur des 3. Kanals
  bsr.s   bvm_get_channel_amplitude
  lea	  pt_audchan4temp(pc),a0 ;Zeiger auf temporäre Struktur des 4. Kanals

; ** Routine get-channel-amplitude **
; d2 ... Maximale Amplitude
; d3 ... Y-Winkel 90 Grad
; a0 ... Temporäre Struktur des Audiokanals
; a1 ... Zeiger auf Amplitudenwert des Kanals
bvm_get_channel_amplitude
  tst.b   n_note_trigger(a0) ;Neue Note angespielt ?
  bne.s   bvm_no_get_channel_amplitude ;Nein -> verzweige
  moveq   #TRUE,d0           ;NULL wegen Wortzugriff
  move.b  n_volume(a0),d0    ;Aktuelle Lautstärke
  moveq   #FALSE,d1
  move.b  d1,n_note_trigger(a0) ;Note Trigger Flag zurücksetzen
  MULUF.W bvm_max_amplitude,d0,d1 ;Aktuelle Lautstärke * maximale Amplitude
  lsr.w   #6,d0              ;/maximale Lautstärke
  cmp.w	  d2,d0              ;Amplitude <= maximale Amplitude ?
  ble.s   bvm_set_amplitude  ;Ja -> verzweige
  move.w  d2,d0              ;Maximale Amplitude setzen
bvm_set_amplitude
  move.w  d3,(a1)+           ;Y-Winkel retten
  move.w  d0,(a1)+           ;Amplitudenwert retten
bvm_no_get_channel_amplitude
  rts

; ** Switchwerte in Copperliste löschen **
; ----------------------------------------
  CNOP 0,4
bvm_clear_second_copperlist
  MOVEF.W vp1_BPLCON4BITS&FALSEB,d0
  move.l  cl2_construction2(a3),a0
  ADDF.W  cl2_extension2_entry+cl2_ext2_BPLCON4+3,a0
  move.w  #cl2_extension2_SIZE,a1
  moveq   #vp1_visible_lines_number-1,d7
bvm_clear_second_copperlist_loop
  move.b  d0,(a0)            ;BPLCON4-Low
  add.l   a1,a0              ;nächste Rasterzeile
  dbf     d7,bvm_clear_second_copperlist_loop
  rts

; ** Bars darstellen **
; ---------------------
  CNOP 0,4
bvm_set_bars
  movem.l a3-a6,-(a7)
  moveq   #(sine_table_length/2)-1,d5
  lea     sine_table(pc),a0  
  lea     bvm_audio_channel1_info(pc),a1 ;Zeiger auf Amplitude und Y-Winkeldes Kanals
  lea     bvm_switch_table(pc),a4 ;Zeiger auf Switchtabelle
  move.l  cl2_construction2(a3),a5 ;CL
  ADDF.W  cl2_extension2_entry+cl2_ext2_BPLCON4+3,a5
  move.w  #bvm_y_centre,a3
  move.w  #cl2_extension2_SIZE,a6
  moveq   #bvm_bars_number-1,d7 ;Anzahl der Bars
bvm_set_bars_loop1
  move.w  (a1)+,d3           ;Y-Winkel
  move.w  (a0,d3.w*2),d0     ;sin(w)
  addq.w  #bvm_y_angle_speed,d3 ;nächster Y-Winkel
  muls.w  (a1)+,d0           ;y'=(yr*sin(w))/2^15
  MULUF.L 2,d0
  swap    d0
  cmp.w   d5,d3              ;180 Grad erreicht ?
  ble.s   bvm_y_angle_ok     ;Nein -> verzweige
  lsr.w   -2(a1)             ;Amplitude/2
bvm_y_angle_ok
  and.w   d5,d3              ;Überlauf bei 180 Grad
  move.w  d3,-4(a1)          ;Y-Winkel retten
  add.w   a3,d0              ;y' + Y-Mittelpunkt
  MULUF.W cl2_extension2_SIZE/4,d0,d1 ;Y-Offset in CL
  lea     (a5,d0.w*4),a2     ;Y-Offset
  moveq   #bvm_bar_height-1,d6 ;Höhe der Bar
bvm_set_bars_loop2
  move.b  (a4)+,(a2)         ;BPLCON4-Low
  add.l   a6,a2              ;nächste Rasterzeile in CL
  dbf     d6,bvm_set_bars_loop2
  dbf     d7,bvm_set_bars_loop1
  movem.l (a7)+,a3-a6
  rts


  IFEQ pt_music_fader
; ** Mouse-Handler **
; -------------------
    CNOP 0,4
pt_mouse_handler
    btst    #POTINPB_DATLY,POTINP-DMACONR(a6) ;Rechte Mustaste gedrückt?
    bne.s   pt_no_mouse_handler ;Nein -> verzweige
    clr.w   pt_fade_out_music_state(a3) ;Fader an
pt_no_mouse_handler
    rts
  ENDC


; ## Interrupt-Routinen ##
; ------------------------
  
  INCLUDE "int-autovectors-handlers.i"

  IFEQ pt_ciatiming
; ** CIA-B timer A interrupt server **
; ------------------------------------
  CNOP 0,4
CIAB_TA_int_server
  ENDC

  IFNE pt_ciatiming
; ** Vertical blank interrupt server **
; -------------------------------------
  CNOP 0,4
VERTB_int_server
  ENDC

  IFEQ pt_music_fader
    bsr.s   pt_fade_out_music
    bra.s   pt_PlayMusic

; ** Musik ausblenden **
; ----------------------
    PT_FADE_OUT

    CNOP 0,4
  ENDC

; ** PT-replay routine **
; -----------------------
  IFD pt_v2.3a
    PT2_REPLAY
  ENDC
  IFD pt_v3.0b
    PT3_REPLAY
  ENDC

; ** CIA-B Timer B interrupt server **
  CNOP 0,4
CIAB_TB_int_server
  PT_TIMER_INTERRUPT_SERVER

; ** Level-6-Interrupt-Server **
; ------------------------------
  CNOP 0,4
EXTER_int_server
  rts

; ** Level-7-Interrupt-Server **
; ------------------------------
  CNOP 0,4
NMI_int_server
  rts


; ** Timer stoppen **
; -------------------

  INCLUDE "continuous-timers-stop.i"


; ## System wieder in Ausganszustand zurücksetzen ##
; --------------------------------------------------

  INCLUDE "sys-return.i"


; ## Hilfsroutinen ##
; -------------------

  INCLUDE "help-routines.i"


; ## Speicherstellen für Tabellen und Strukturen ##
; -------------------------------------------------

  INCLUDE "sys-structures.i"

; ** Farben des ersten Playfields **
; ----------------------------------
  CNOP 0,4
pf1_color_table
  DC.L COLOR00BITS

; ** Farben der Sprites **
; ------------------------
spr_color_table
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/256x208x16-Desert-Sunset2.ct"

; ** Adressen der Sprites **
; --------------------------
spr_pointers_display
  DS.L spr_number

; ** Sinus / Cosinustabelle **
; ----------------------------
  CNOP 0,2
sine_table
  INCLUDE "sine-table-256x16.i"

; **** PT-Replay ****
; ** Tables for effect commands **
; --------------------------------
; ** "Invert Loop" **
  INCLUDE "music-tracker/pt-invert-table.i"

; ** "Vibrato/Tremolo" **
  INCLUDE "music-tracker/pt-vibrato-tremolo-table.i"

; ** "Arpeggio/Tone Portamento" **
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-period-table.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-period-table.i"
  ENDC

; ** Temporary channel structures **
; ----------------------------------
  INCLUDE "music-tracker/pt-temp-channel-data-tables.i"

; ** Pointers to samples **
; -------------------------
  INCLUDE "music-tracker/pt-sample-starts-table.i"

; ** Pionters to priod tables for different tuning **
; ---------------------------------------------------
  INCLUDE "music-tracker/pt-finetune-starts-table.i"

; **** Horiz-Scrolltext ****
hst_color_gradient
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/26-Colorgradient.ct"

; ** ASCII-Buchstaben **
; ----------------------
hst_ASCII
  DC.B "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?-'():\/#+>< "
hst_ASCII_end
  EVEN

; ** Offsets der einzelnen Chars **
; ---------------------------------
  CNOP 0,2
hst_characters_offsets
  DS.W hst_ASCII_end-hst_ASCII
  
; ** X-Koordinaten der einzelnen Chars der Laufschrift **
; -------------------------------------------------------
hst_characters_x_positions
  DS.W hst_text_characters_number

; ** Tabelle für Chars-Image-Adressen **
; --------------------------------------
  CNOP 0,4
hst_characters_image_pointers
  DS.L hst_text_characters_number

; **** Bounce-VU-Meter ****
; ** Farbverlauf **
; -----------------
bvm_color_gradients
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/4x3-Colorgradient3.ct"

; ** Farbtabelle **
; -----------------
bvm_color_table
  DS.L spr_colors_number*(bvm_bar_height/2)*bvm_bars_number

; ** Tabelle mit Switchwerten **
; ------------------------------
bvm_switch_table
  DC.B $33,$44,$55,$55,$44,$33 ;Bar1
  DC.B $66,$77,$88,$88,$77,$66 ;Bar2
  DC.B $99,$aa,$bb,$bb,$aa,$99 ;Bar3
  DC.B $cc,$dd,$ee,$ee,$dd,$cc ;Bar4

; Tabellen mit Amplituden und Y-Winkeln der einzelnen Kanäle **
; -------------------------------------------------------------
  CNOP 0,2
bvm_audio_channel1_info
  DS.B bvm_audchaninfo_SIZE

bvm_audio_channel2_info
  DS.B bvm_audchaninfo_SIZE

bvm_audio_channel3_info
  DS.B bvm_audchaninfo_SIZE

bvm_audio_channel4_info
  DS.B bvm_audchaninfo_SIZE


; ## Speicherstellen allgemein ##
; -------------------------------

  INCLUDE "sys-variables.i"


; ## Speicherstellen für Namen ##
; -------------------------------

  INCLUDE "sys-names.i"


; ## Speicherstellen für Texte ##
; -------------------------------

  INCLUDE "error-texts.i"

; ** Programmversion für Version-Befehl **
; ----------------------------------------
prg_version DC.B "$VER: RSE-30 1.0 beta (17.5.24)",TRUE
  EVEN

; **** Horiz-Scrolltext ****
; ** Text für Laufschrift **
; --------------------------
hst_text
  REPT hst_text_characters_number/(hst_origin_character_x_size/hst_text_character_x_size)
    DC.B " "
  ENDR
  DC.B "RESISTANCE CELEBRATES THE 35TH ANNIVERSARY!"
  DC.B FALSE
  EVEN


; ## Audiodaten nachladen ##
; --------------------------

; **** PT-Replay ****
  IFEQ pt_split_module
pt_auddata SECTION pt_audio,DATA
    INCBIN "Daten:Asm-Sources.AGA/30/modules/MOD.lhs_brd.song"
pt_audsmps SECTION pt_audio2,DATA_C
    INCBIN "Daten:Asm-Sources.AGA/30/modules/MOD.lhs_brd.smps"
  ELSE
pt_auddata SECTION pt_audio,DATA_C
    INCBIN "Daten:Asm-Sources.AGA/30/modules/MOD.lhs_brd"
  ENDC


; ## Grafikdaten nachladen ##
; ---------------------------

; **** Hintergrundbild ****
bg_image_data SECTION bg_gfx,DATA
  INCBIN "Daten:Asm-Sources.AGA/30/graphics/256x208x16-Desert-Sunset2.rawblit"

; **** Horiz-Scrolltext ****
hst_image_data SECTION hst_gfx,DATA_C
  INCBIN "Daten:Asm-Sources.AGA/30/fonts/32x26x2-Font.rawblit"

  END
