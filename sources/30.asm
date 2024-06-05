; ##############################
; # Programm: 30.asm           #
; # Autor:    Christian Gerbig #
; # Datum:    02.06.2024       #
; # Version:  1.1 beta         #
; # CPU:      68020+           #
; # FASTMEM:  -                #
; # Chipset:  AGA              #
; # OS:       3.0+             #
; ##############################

; V1.0 beta
; First release

; V1.1 beta
; - CWAIT für VP2 korrigiert, damit der Farbverlauf des Schachbretts für die
;   erste Zeile noch innerhalb der horizontalen Austastlücke erfolgt.
; - VP1 nutzt jetzt COLOR28-31
;   VP3 nutzt jetzt COLOR16-23 für P1 und COLOR24-28 für PF2
; - Die Farben für VP1/PF1 und VP3/PF2 werden nicht mehr vom Copper separat
;   initialisiert, da die Farbverläufe für VP1 und VP3 sowieso zeilenweise
;   initialisiert werden. Insgesamt werden nur noch 240 Farben in der verti-
;   kalen Austastlücke initialisiert.
; - Vektor-Bälle: Einblenden und Überblenden zu anderen Farben mit Intervall
;                 und Änderung der Z-Koorinaten
; - Nutzung des PT 8xy-Befehls für die Fader-Routinen


; PT 8xy-Befehl
; 801 Disable-Trigger-FX
; 810 Start-Fade-Bars-In
; 820 Start-Fade-Image-In (Tempel)
; 830 Start-Fade-Chessboard-In
; 840 Start-Fade-Sprites-In
; 850 Start-Fade-Balls-In
; 860 Start-Fade-Cross
; 870 Start-Scrolltext

; 68020: 187 Rasterzeilen

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

requires_68030                        EQU FALSE  
requires_68040                        EQU FALSE
requires_68060                        EQU FALSE
requires_fast_memory                  EQU FALSE
requires_multiscan_monitor            EQU FALSE

workbench_start                       EQU FALSE
workbench_fade                        EQU FALSE
text_output                           EQU FALSE

pt_v3.0b

  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-equals.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-equals.i"
  ENDC
;pt_mute_volume
pt_ciatiming                          EQU TRUE
pt_usedfx                             EQU %1101110100101101
pt_usedefx                            EQU %0000100000000000
pt_finetune                           EQU FALSE
  IFD pt_v3.0b
pt_metronome                          EQU FALSE
  ENDC
pt_track_channel_volumes              EQU TRUE
pt_track_channel_periods              EQU FALSE
pt_music_fader                        EQU TRUE
pt_split_module                       EQU TRUE

mvb_premorph_start_shape              EQU TRUE
mvb_morph_loop                        EQU TRUE

cfc_prefade                           EQU TRUE

DMABITS                               EQU DMAF_SPRITE+DMAF_COPPER+DMAF_BLITTER+DMAF_RASTER+DMAF_MASTER+DMAF_SETCLR

  IFEQ pt_ciatiming
INTENABITS                            EQU INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ELSE
INTENABITS                            EQU INTF_VERTB+INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ENDC

CIAAICRBITS                           EQU CIAICRF_SETCLR
  IFEQ pt_ciatiming
CIABICRBITS                           EQU CIAICRF_TA+CIAICRF_TB+CIAICRF_SETCLR
  ELSE
CIABICRBITS                           EQU CIAICRF_TB+CIAICRF_SETCLR
  ENDC

COPCONBITS                            EQU TRUE

pf1_x_size1                           EQU 0
pf1_y_size1                           EQU 0
pf1_depth1                            EQU 0
pf1_x_size2                           EQU 0
pf1_y_size2                           EQU 0
pf1_depth2                            EQU 0
pf1_x_size3                           EQU 0
pf1_y_size3                           EQU 0
pf1_depth3                            EQU 0
pf1_colors_number                     EQU 240

pf2_x_size1                           EQU 0
pf2_y_size1                           EQU 0
pf2_depth1                            EQU 0
pf2_x_size2                           EQU 0
pf2_y_size2                           EQU 0
pf2_depth2                            EQU 0
pf2_x_size3                           EQU 0
pf2_y_size3                           EQU 0
pf2_depth3                            EQU 0
pf2_colors_number                     EQU 0
pf_colors_number                      EQU pf1_colors_number+pf2_colors_number
pf_depth                              EQU pf1_depth3+pf2_depth3

extra_pf_number                       EQU 8
; **** Viewport 1 ****
; ** Playfield 1 **
extra_pf1_x_size                      EQU 384
extra_pf1_y_size                      EQU 26
extra_pf1_depth                       EQU 2
extra_pf2_x_size                      EQU 384
extra_pf2_y_size                      EQU 26
extra_pf2_depth                       EQU 2
; **** Viewport 2 ****
; ** Playfield 1 **
extra_pf3_x_size                      EQU 320
extra_pf3_y_size                      EQU 182
extra_pf3_depth                       EQU 4
; ** Playfield 2 **
extra_pf4_x_size                      EQU 320
extra_pf4_y_size                      EQU 182
extra_pf4_depth                       EQU 3
extra_pf5_x_size                      EQU 320
extra_pf5_y_size                      EQU 182
extra_pf5_depth                       EQU 3
extra_pf6_x_size                      EQU 320
extra_pf6_y_size                      EQU 182
extra_pf6_depth                       EQU 3
; **** Viewport 3 ****
extra_pf7_x_size                      EQU 960
extra_pf7_y_size                      EQU 1
extra_pf7_depth                       EQU 2
; ** Playfield 2 **
extra_pf8_x_size                      EQU 320
extra_pf8_y_size                      EQU 48
extra_pf8_depth                       EQU 2


spr_number                            EQU 8
spr_x_size1                           EQU 0
spr_x_size2                           EQU 64
spr_depth                             EQU 2
spr_colors_number                     EQU 16
spr_odd_color_table_select            EQU 2
spr_even_color_table_select           EQU 2
spr_used_number                       EQU 8

  IFD pt_v2.3a
audio_memory_size                     EQU 0
  ENDC
  IFD pt_v3.0b
audio_memory_size                     EQU 2
  ENDC

disk_memory_size                      EQU 0

chip_memory_size                      EQU 0

AGA_OS_Version                        EQU 39

  IFEQ pt_ciatiming
CIABCRABITS                           EQU CIACRBF_LOAD
  ENDC
CIABCRBBITS                           EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;Oneshot mode
CIAA_TA_value                         EQU 0
CIAA_TB_value                         EQU 0
  IFEQ pt_ciatiming
CIAB_TA_value                         EQU 14187 ;= 0.709379 MHz * [20000 µs = 50 Hz duration for one frame on a PAL machine]
;CIAB_TA_value                         EQU 14318 ;= 0.715909 MHz * [20000 µs = 50 Hz duration for one frame on a NTSC machine]
  ELSE
CIAB_TA_value                         EQU 0
  ENDC
CIAB_TB_value                         EQU 362 ;= 0.709379 MHz * [511.43 µs = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
                                              ;= 0.715909 MHz * [506.76 µs = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
CIAA_TA_continuous                    EQU FALSE
CIAA_TB_continuous                    EQU FALSE
  IFEQ pt_ciatiming
CIAB_TA_continuous                    EQU TRUE
  ELSE
CIAB_TA_continuous                    EQU FALSE
  ENDC
CIAB_TB_continuous                    EQU FALSE

beam_position                         EQU $133 ;Wegen Music-Fader

MINROW                                EQU VSTART_256_lines

display_window_HSTART                 EQU HSTART_320_pixel
display_window_VSTART                 EQU MINROW
DIWSTRTBITS                           EQU ((display_window_VSTART&$ff)*DIWSTRTF_V0)+(display_window_HSTART&$ff)
display_window_HSTOP                  EQU HSTOP_320_pixel
display_window_VSTOP                  EQU VSTOP_256_lines
DIWSTOPBITS                           EQU ((display_window_VSTOP&$ff)*DIWSTOPF_V0)+(display_window_HSTOP&$ff)

spr_pixel_per_datafetch               EQU 64 ;4x

; **** Viewport 1 ****
vp1_pixel_per_line                    EQU 320
vp1_visible_pixels_number             EQU 320
vp1_visible_lines_number              EQU 26

vp1_VSTART                            EQU MINROW
vp1_VSTOP                             EQU vp1_VSTART+vp1_visible_lines_number

vp1_pf_pixel_per_datafetch            EQU 64 ;4x
vp1_DDFSTRTBITS                       EQU DDFSTART_320_pixel
vp1_DDFSTOPBITS                       EQU DDFSTOP_320_pixel_4x

vp1_pf1_depth                         EQU 2
vp1_pf_depth                          EQU vp1_pf1_depth
vp1_pf1_colors_number                 EQU 4
vp1_pf_colors_number                  EQU vp1_pf1_colors_number

; **** Viewport 2 ****
vp2_pixel_per_line                    EQU 320
vp2_visible_pixels_number             EQU 320
vp2_visible_lines_number              EQU 182

vp2_VSTART                            EQU vp1_VSTOP
vp2_VSTOP                             EQU vp2_VSTART+vp2_visible_lines_number

vp2_pf_pixel_per_datafetch            EQU 64 ;4x
vp2_DDFSTRTBITS                       EQU DDFSTART_320_pixel
vp2_DDFSTOPBITS                       EQU DDFSTOP_320_pixel_4x

vp2_pf1_depth                         EQU 4
vp2_pf2_depth                         EQU 3
vp2_pf_depth                          EQU vp2_pf1_depth+vp2_pf2_depth
vp2_pf1_colors_number                 EQU 16
vp2_pf2_colors_number                 EQU 8
vp2_pf_colors_number                  EQU vp2_pf1_colors_number+vp2_pf2_colors_number

; **** Viewport 3 ****
vp3_pixel_per_line                    EQU 320
vp3_visible_pixels_number             EQU 320
vp3_visible_lines_number              EQU 48

vp3_VSTART                            EQU vp2_VSTOP
vp3_VSTOP                             EQU vp3_VSTART+vp3_visible_lines_number

vp3_pf_pixel_per_datafetch            EQU 64 ;4x
vp3_DDFSTRTBITS                       EQU DDFSTART_320_pixel
vp3_DDFSTOPBITS                       EQU DDFSTOP_320_pixel_4x

vp3_pf1_depth                         EQU 3
vp3_pf2_depth                         EQU 2
vp3_pf_depth                          EQU vp3_pf1_depth+vp3_pf2_depth
vp3_pf1_colors_number                 EQU 8
vp3_pf2_colors_number                 EQU 4
vp3_pf_colors_number                  EQU vp3_pf1_colors_number+vp3_pf2_colors_number


; **** Viewport 1 ****
; ** Playfield 1 **
extra_pf1_plane_width                 EQU extra_pf1_x_size/8
extra_pf2_plane_width                 EQU extra_pf2_x_size/8
; **** Viewport 2 ****
; ** Playfield1 **
extra_pf3_plane_width                 EQU extra_pf3_x_size/8
; ** Playfield2 **
extra_pf4_plane_width                 EQU extra_pf4_x_size/8
extra_pf5_plane_width                 EQU extra_pf5_x_size/8
extra_pf6_plane_width                 EQU extra_pf6_x_size/8
; **** Viewport 3 ****
extra_pf7_plane_width                 EQU extra_pf7_x_size/8
; ** Playfield2 **
extra_pf8_plane_width                 EQU extra_pf8_x_size/8

; **** Viewport 1 ****
vp1_data_fetch_width                  EQU vp1_pixel_per_line/8
vp1_pf1_plane_moduli                  EQU (extra_pf1_plane_width*(extra_pf1_depth-1))+extra_pf1_plane_width-vp1_data_fetch_width
; **** Viewport 2 ****
vp2_data_fetch_width                  EQU vp2_pixel_per_line/8
vp2_pf1_plane_moduli                  EQU (extra_pf3_plane_width*(extra_pf3_depth-1))+extra_pf3_plane_width-vp2_data_fetch_width
vp2_pf2_plane_moduli                  EQU (extra_pf4_plane_width*(extra_pf4_depth-1))+extra_pf4_plane_width-vp2_data_fetch_width
; **** Viewport 3 ****
vp3_data_fetch_width                  EQU vp3_pixel_per_line/8
vp3_pf1_plane_moduli                  EQU (40*8)  ;-(extra_pf4_plane_width-(extra_pf4_plane_width-vp3_data_fetch_width))
vp3_pf2_plane_moduli                  EQU (extra_pf8_plane_width*(extra_pf8_depth-1))+extra_pf8_plane_width-vp3_data_fetch_width

; **** View ****
BPLCON0BITS                           EQU BPLCON0F_ECSENA+((pf_depth>>3)*BPLCON0F_BPU3)+(BPLCON0F_COLOR)+((pf_depth&$07)*BPLCON0F_BPU0) ;lores
BPLCON3BITS1                          EQU BPLCON3F_SPRES0
BPLCON3BITS2                          EQU BPLCON3BITS1|BPLCON3F_LOCT
BPLCON4BITS                           EQU (BPLCON4F_OSPRM4*spr_odd_color_table_select)|(BPLCON4F_ESPRM4*spr_even_color_table_select)
DIWHIGHBITS                           EQU (((display_window_HSTOP&$100)>>8)*DIWHIGHF_HSTOP8)|(((display_window_VSTOP&$700)>>8)*DIWHIGHF_VSTOP8)|(((display_window_HSTART&$100)>>8)*DIWHIGHF_HSTART8)|((display_window_VSTART&$700)>>8)
FMODEBITS                             EQU FMODEF_SPR32|FMODEF_SPAGEM|FMODEF_SSCAN2
COLOR00BITS                           EQU $001122
COLOR00HIGHBITS                       EQU $012
COLOR00LOWBITS                        EQU $012
; **** Viewport 1 ****
vp1_BPLCON0BITS                       EQU BPLCON0F_ECSENA|((vp1_pf_depth>>3)*BPLCON0F_BPU3)|(BPLCON0F_COLOR)|((vp1_pf_depth&$07)*BPLCON0F_BPU0)
vp1_BPLCON1BITS                       EQU TRUE
vp1_BPLCON2BITS                       EQU TRUE
vp1_BPLCON3BITS1                      EQU BPLCON3BITS1
vp1_BPLCON3BITS2                      EQU vp1_BPLCON3BITS1|BPLCON3F_LOCT
vp1_BPLCON3BITS3                      EQU vp1_BPLCON3BITS1|(BPLCON3F_BANK0*7)
vp1_BPLCON3BITS4                      EQU vp1_BPLCON3BITS3|BPLCON3F_LOCT
vp1_BPLCON4BITS                       EQU BPLCON4BITS|(BPLCON4F_BPLAM0*252)
vp1_FMODEBITS                         EQU FMODEBITS|FMODEF_BPL32|FMODEF_BPAGEM
vp1_COLOR00BITS                       EQU COLOR00BITS
; **** Viewport 2 ****
vp2_BPLCON0BITS                       EQU BPLCON0F_ECSENA|((vp2_pf_depth>>3)*BPLCON0F_BPU3)|(BPLCON0F_COLOR)|BPLCON0F_DPF|((vp2_pf_depth&$07)*BPLCON0F_BPU0)
vp2_BPLCON1BITS                       EQU TRUE
vp2_BPLCON2BITS                       EQU BPLCON2F_PF2PRI
vp2_BPLCON3BITS1                      EQU BPLCON3BITS1|BPLCON3F_PF2OF2
vp2_BPLCON3BITS2                      EQU vp2_BPLCON3BITS1|BPLCON3F_LOCT
vp2_BPLCON4BITS                       EQU BPLCON4BITS
vp2_FMODEBITS                         EQU FMODEBITS|FMODEF_BPL32|FMODEF_BPAGEM
vp2_COLOR00BITS                       EQU COLOR00BITS
; **** Viewport 3 ****
vp3_BPLCON0BITS                       EQU BPLCON0F_ECSENA|((vp3_pf_depth>>3)*BPLCON0F_BPU3)|(BPLCON0F_COLOR)|BPLCON0F_DPF|((vp3_pf_depth&$07)*BPLCON0F_BPU0)
vp3_BPLCON1BITS                       EQU TRUE
vp3_BPLCON2BITS                       EQU TRUE ;BPLCON2F_PF2PRI
vp3_BPLCON3BITS1                      EQU BPLCON3BITS1|BPLCON3F_PF2OF0|BPLCON3F_PF2OF1
vp3_BPLCON3BITS2                      EQU vp3_BPLCON3BITS1|BPLCON3F_LOCT
vp3_BPLCON3BITS3                      EQU vp3_BPLCON3BITS1|(BPLCON3F_BANK0*7)
vp3_BPLCON3BITS4                      EQU vp3_BPLCON3BITS3|BPLCON3F_LOCT
vp3_BPLCON4BITS                       EQU BPLCON4BITS|(BPLCON4F_BPLAM0*240)
vp3_FMODEBITS                         EQU FMODEBITS|FMODEF_BPL32|FMODEF_BPAGEM
vp3_COLOR00BITS                       EQU COLOR00BITS

; **** Viewport 1 ****
cl2_vp1_HSTART1                       EQU $00
cl2_vp1_VSTART1                       EQU MINROW
cl2_vp1_HSTART2                       EQU $00
cl2_vp1_VSTART2                       EQU MINROW
; **** Viewport 2 ****
cl2_vp2_HSTART                        EQU HSTOP_320_pixel-(4*CMOVE_slot_period)
cl2_vp2_VSTART                        EQU vp1_VSTOP-1
; **** Viewport 3 ****
cl2_vp3_HSTART1                       EQU HSTOP_320_pixel-(9*CMOVE_slot_period)
cl2_vp3_VSTART1                       EQU vp2_VSTOP-1
cl2_vp3_HSTART2                       EQU $00
cl2_vp3_VSTART2                       EQU vp2_VSTOP
; **** Copper-Interrupt ****
cl2_HSTART                            EQU $00
cl2_VSTART                            EQU beam_position&$ff

sine_table_length                     EQU 512

; **** Background-Image 1 ****
bg1_image_x_size                      EQU 256
bg1_image_plane_width                 EQU bg1_image_x_size/8
bg1_image_y_size                      EQU 208
bg1_image_depth                       EQU 4
bg1_image_x_position                  EQU 16
bg1_image_y_position                  EQU MINROW

; **** Background-Image 2 ****
bg2_image_x_size                      EQU 320
bg2_image_plane_width                 EQU bg2_image_x_size/8
bg2_image_y_size                      EQU 182
bg2_image_depth                       EQU 4

; **** Ball-Image ****
mvb_image_x_size                      EQU 16
mvb_image_width                       EQU mvb_image_x_size/8
mvb_image_y_size                      EQU 11
mvb_image_depth                       EQU 3
mvb_image_objects_number              EQU 4

; **** PT-Replay ****
pt_fade_out_delay                     EQU 2 ;Ticks

; **** Horiz-Scrolltext ****
hst_image_x_size                      EQU 320
hst_image_plane_width                 EQU hst_image_x_size/8
hst_image_depth                       EQU 2
hst_origin_character_x_size           EQU 32
hst_origin_character_y_size           EQU 26

hst_text_character_x_size             EQU 16
hst_text_character_width              EQU hst_text_character_x_size/8
hst_text_character_y_size             EQU hst_origin_character_y_size
hst_text_character_depth              EQU hst_image_depth

hst_horiz_scroll_window_x_size        EQU vp1_visible_pixels_number+hst_text_character_x_size
hst_horiz_scroll_window_width         EQU hst_horiz_scroll_window_x_size/8
hst_horiz_scroll_window_y_size        EQU hst_text_character_y_size
hst_horiz_scroll_window_depth         EQU hst_image_depth
hst_horiz_scroll_speed1               EQU 2
hst_horiz_scroll_speed2               EQU 8

hst_text_character_x_restart          EQU hst_horiz_scroll_window_x_size
hst_text_characters_number            EQU hst_horiz_scroll_window_x_size/hst_text_character_x_size

hst_text_x_position                   EQU 32
hst_text_y_position                   EQU 0

; **** Bounce-VU-Meter ****
bvm_bar_height                        EQU 6
bvm_bars_number                       EQU 4
bvm_max_amplitude                     EQU vp1_visible_lines_number-bvm_bar_height
bvm_y_centre                          EQU vp1_visible_lines_number-bvm_bar_height
bvm_y_angle_speed                     EQU 8

; **** Morph-Vector-Balls ****
mvb_balls_number                      EQU 30

mvb_rotation_d                        EQU 256
mvb_rotation_x_center                 EQU (extra_pf4_x_size-mvb_image_x_size)/2
mvb_rotation_y_center                 EQU (extra_pf4_y_size-mvb_image_y_size)/2
mvb_rotation_x_angle_speed            EQU 4
mvb_rotation_y_angle_speed            EQU 1
mvb_rotation_z_angle_speed            EQU 1

mvb_object_points_number              EQU mvb_balls_number

  IFEQ mvb_morph_loop
mvb_morph_shapes_number               EQU 2
  ELSE
mvb_morph_shapes_number               EQU 3
  ENDC
mvb_morph_speed                       EQU 8
mvb_morph_delay                       EQU 6*PALFPS

mvb_observer_z                        EQU 35
mvb_z_plane1                          EQU -32+mvb_observer_z
mvb_z_plane2                          EQU 0+mvb_observer_z
mvb_z_plane3                          EQU 32+mvb_observer_z
mvb_z_plane4                          EQU 64+mvb_observer_z

mvb_clear_blit_x_size                 EQU extra_pf4_x_size
mvb_clear_blit_y_size                 EQU extra_pf4_y_size*(extra_pf4_depth-2)

mvb_copy_blit_x_size                  EQU mvb_image_x_size+16
mvb_copy_blit_y_size                  EQU mvb_image_y_size*mvb_image_depth

; **** Chessboard ****
cb_destination_image_x_size           EQU vp3_visible_pixels_number
cb_destination_image_y_size           EQU vp3_visible_lines_number
cb_destination_image_plane_width_step EQU 8
cb_destination_image_x_size_step      EQU cb_destination_image_plane_width_step/2
cb_source_image_x_size                EQU vp3_visible_pixels_number+(extra_pf8_y_size*cb_destination_image_plane_width_step)

cb_x_min                              EQU 0
cb_x_max                              EQU vp3_visible_pixels_number

cb_stripes_y_radius                   EQU vp3_visible_lines_number-1
cb_stripes_y_center                   EQU vp3_visible_lines_number-1
cb_stripes_y_step                     EQU 1
cb_stripes_y_angle_speed              EQU 3
cb_stripes_number                     EQU 8
cb_stripe_height                      EQU 16

; **** Bar-Fader ****
bf_start_color                        EQU 16
bf_color_table_offset                 EQU 0
bf_colors_number                      EQU spr_colors_number*(bvm_bar_height/2)*bvm_bars_number

; **** Bar-Fader-In ****
bfi_fader_speed_max                   EQU 6
bfi_fader_radius                      EQU bfi_fader_speed_max
bfi_fader_center                      EQU bfi_fader_speed_max+1
bfi_fader_angle_speed                 EQU 3

; **** Bar-Fader-Out ****
bfo_fader_speed_max                   EQU 6
bfo_fader_radius                      EQU bfo_fader_speed_max
bfo_fader_center                      EQU bfo_fader_speed_max+1
bfo_fader_angle_speed                 EQU 3

; **** Image-Fader ****
if_start_color                        EQU 1
if_color_table_offset                 EQU 1
if_colors_number                      EQU vp2_pf1_colors_number-1

; **** Image-Fader-In ****
ifi_fader_speed_max                   EQU 16
ifi_fader_radius                      EQU ifi_fader_speed_max
ifi_fader_center                      EQU ifi_fader_speed_max+1
ifi_fader_angle_speed                 EQU 7

; **** Image-Fader-Out ****
ifo_fader_speed_max                   EQU 10
ifo_fader_radius                      EQU ifo_fader_speed_max
ifo_fader_center                      EQU ifo_fader_speed_max+1
ifo_fader_angle_speed                 EQU 6

; **** Chessboard-Fader ****
cf_color_table_offset                 EQU 0
cf_colors_number                      EQU vp3_visible_lines_number*2

; **** Chessboard-Fader-In ****
cfi_fader_speed_max                   EQU 10
cfi_fader_radius                      EQU cfi_fader_speed_max
cfi_fader_center                      EQU cfi_fader_speed_max+1
cfi_fader_angle_speed                 EQU 6

; **** Chessboard-Fader-Out ****
cfo_fader_speed_max                   EQU 10
cfo_fader_radius                      EQU cfo_fader_speed_max
cfo_fader_center                      EQU cfo_fader_speed_max+1
cfo_fader_angle_speed                 EQU 4

; **** Sprite-Fader ****
sprf_start_color                      EQU 1
sprf_color_table_offset               EQU 1
sprf_colors_number                    EQU spr_colors_number-1

; **** Sprite-Fader-In ****
sprfi_fader_speed_max                 EQU 6
sprfi_fader_radius                    EQU sprfi_fader_speed_max
sprfi_fader_center                    EQU sprfi_fader_speed_max+1
sprfi_fader_angle_speed               EQU 2

; **** Sprite-Fader-Out ****
sprfo_fader_speed_max                 EQU 8
sprfo_fader_radius                    EQU sprfo_fader_speed_max
sprfo_fader_center                    EQU sprfo_fader_speed_max+1
sprfo_fader_angle_speed               EQU 4

; **** Fade-Balls-In ****
fbi_delay                             EQU 10

; **** Fade-Balls-Out ****
fbo_delay                             EQU 5

; **** Colors-Fader-Cross ****
cfc_start_color                       EQU 17
cfc_color_table_offset                EQU 1
cfc_colors_number                     EQU vp2_pf2_colors_number-1
cfc_color_tables_number               EQU 4
cfc_fader_speed_max                   EQU 8
cfc_fader_radius                      EQU cfc_fader_speed_max
cfc_fader_center                      EQU cfc_fader_speed_max+1
cfc_fader_angle_speed                 EQU 4
cfc_fader_delay                       EQU 3*PALFPS


vp1_pf1_bitplanes_x_offset            EQU 1*vp1_pf_pixel_per_datafetch
vp1_pf1_bitplanes_y_offset            EQU 0


; ## Makrobefehle ##
; ------------------

  INCLUDE "macros.i"


; ** Extra-Memory-Abschnitte **
; ----------------------------
  RSRESET

em_bitmap_table   RS.B cb_source_image_x_size*cb_destination_image_y_size
  RS_ALIGN_LONGWORD
em_color_table    RS.L vp3_visible_lines_number*2
extra_memory_size RS.B 0


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

cl1_extension1      RS.B 0

cl1_ext1_BPL3PTH    RS.L 1
cl1_ext1_BPL3PTL    RS.L 1
cl1_ext1_BPL5PTH    RS.L 1
cl1_ext1_BPL5PTL    RS.L 1
cl1_ext1_BPL7PTH    RS.L 1
cl1_ext1_BPL7PTL    RS.L 1

cl1_extension1_SIZE RS.B 0


  RSRESET

cl1_begin            RS.B 0

  INCLUDE "copperlist1-offsets.i"

cl1_extension1_entry RS.B cl1_extension1_SIZE

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
cl2_ext1_BPL2PTH    RS.L 1
cl2_ext1_BPL2PTL    RS.L 1

cl2_extension1_SIZE RS.B 0


  RSRESET

cl2_extension2         RS.B 0

cl2_ext2_WAIT          RS.L 1
cl2_ext2_BPLCON3_1     RS.L 1
cl2_ext2_COLOR29_high8 RS.L 1
cl2_ext2_COLOR30_high8 RS.L 1
cl2_ext2_BPLCON3_2     RS.L 1
cl2_ext2_COLOR29_low8  RS.L 1
cl2_ext2_COLOR30_low8  RS.L 1
cl2_ext2_BPLCON4       RS.L 1

cl2_extension2_SIZE    RS.B 0


  RSRESET

cl2_extension3      RS.B 0

cl2_ext3_WAIT       RS.L 1
cl2_ext3_DDFSTRT    RS.L 1
cl2_ext3_DDFSTOP    RS.L 1
cl2_ext3_BPLCON1    RS.L 1
cl2_ext3_BPLCON2    RS.L 1
cl2_ext3_BPLCON3_1  RS.L 1
cl2_ext3_BPL1MOD    RS.L 1
cl2_ext3_BPL2MOD    RS.L 1
cl2_ext3_BPLCON4    RS.L 1
cl2_ext3_FMODE      RS.L 1
cl2_ext3_BPL1PTH    RS.L 1
cl2_ext3_BPL1PTL    RS.L 1
cl2_ext3_BPL2PTH    RS.L 1
cl2_ext3_BPL2PTL    RS.L 1
cl2_ext3_BPL4PTH    RS.L 1
cl2_ext3_BPL4PTL    RS.L 1
cl2_ext3_BPL6PTH    RS.L 1
cl2_ext3_BPL6PTL    RS.L 1
cl2_ext3_BPLCON0    RS.L 1

cl2_extension3_SIZE RS.B 0


  RSRESET

cl2_extension4      RS.B 0

cl2_ext4_WAIT       RS.L 1
cl2_ext4_DDFSTRT    RS.L 1
cl2_ext4_DDFSTOP    RS.L 1
cl2_ext4_BPLCON1    RS.L 1
cl2_ext4_BPLCON2    RS.L 1
cl2_ext4_BPLCON3_1  RS.L 1
cl2_ext4_BPL1MOD    RS.L 1
cl2_ext4_BPL2MOD    RS.L 1
cl2_ext4_BPLCON4    RS.L 1
cl2_ext4_FMODE      RS.L 1
cl2_ext4_BPL1PTH    RS.L 1
cl2_ext4_BPL1PTL    RS.L 1
cl2_ext4_BPL2PTH    RS.L 1
cl2_ext4_BPL2PTL    RS.L 1
cl2_ext4_BPL3PTH    RS.L 1
cl2_ext4_BPL3PTL    RS.L 1
cl2_ext4_BPL4PTH    RS.L 1
cl2_ext4_BPL4PTL    RS.L 1
cl2_ext4_BPL5PTH    RS.L 1
cl2_ext4_BPL5PTL    RS.L 1
cl2_ext4_BPLCON0    RS.L 1

cl2_extension4_SIZE RS.B 0


  RSRESET

cl2_extension5         RS.B 0

cl2_ext5_WAIT          RS.L 1
cl2_ext5_BPLCON3_1     RS.L 1
cl2_ext5_COLOR25_high8 RS.L 1
cl2_ext5_COLOR26_high8 RS.L 1
cl2_ext5_BPLCON3_2     RS.L 1
cl2_ext5_COLOR25_low8  RS.L 1
cl2_ext5_COLOR26_low8  RS.L 1
cl2_ext5_NOOP          RS.L 1

cl2_extension5_SIZE    RS.B 0


  RSRESET

cl2_begin            RS.B 0

; **** Viewport 1 ****
cl2_extension1_entry RS.B cl2_extension1_SIZE
cl2_WAIT1            RS.L 1
cl2_BPLCON0_1        RS.L 1
cl2_extension2_entry RS.B cl2_extension2_SIZE*vp1_visible_lines_number
; **** Viewport 2 ****
cl2_extension3_entry RS.B cl2_extension3_SIZE
; **** Viewport 3 ****
cl2_extension4_entry RS.B cl2_extension4_SIZE
cl2_extension5_entry RS.B cl2_extension5_SIZE*vp3_visible_lines_number
; **** Copper-Interrupt ****
cl1_WAIT             RS.L 1
cl1_INTREQ           RS.L 1

cl2_end              RS.L 1

copperlist2_SIZE     RS.B 0


; ** Konstanten für die größe der Copperlisten **
; -----------------------------------------------
cl1_size1                     EQU 0
cl1_size2                     EQU 0
cl1_size3                     EQU copperlist1_SIZE
cl2_size1                     EQU 0
cl2_size2                     EQU copperlist2_SIZE
cl2_size3                     EQU copperlist2_SIZE


; ** Sprite0-Zusatzstruktur **
; ----------------------------
  RSRESET

spr0_extension1       RS.B 0

spr0_ext1_header      RS.L 1*(spr_pixel_per_datafetch/16)
spr0_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

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
spr1_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

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
spr2_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

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
spr3_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

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
spr4_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

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
spr5_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

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
spr6_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

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
spr7_ext1_planedata   RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

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
spr0_x_size1               EQU spr_x_size1
spr0_y_size1               EQU 0
spr1_x_size1               EQU spr_x_size1
spr1_y_size1               EQU 0
spr2_x_size1               EQU spr_x_size1
spr2_y_size1               EQU 0
spr3_x_size1               EQU spr_x_size1
spr3_y_size1               EQU 0
spr4_x_size1               EQU spr_x_size1
spr4_y_size1               EQU 0
spr5_x_size1               EQU spr_x_size1
spr5_y_size1               EQU 0
spr6_x_size1               EQU spr_x_size1
spr6_y_size1               EQU 0
spr7_x_size1               EQU spr_x_size1
spr7_y_size1               EQU 0

spr0_x_size2               EQU spr_x_size2
spr0_y_size2               EQU sprite0_SIZE/(spr_x_size2/8)
spr1_x_size2               EQU spr_x_size2
spr1_y_size2               EQU sprite1_SIZE/(spr_x_size2/8)
spr2_x_size2               EQU spr_x_size2
spr2_y_size2               EQU sprite2_SIZE/(spr_x_size2/8)
spr3_x_size2               EQU spr_x_size2
spr3_y_size2               EQU sprite3_SIZE/(spr_x_size2/8)
spr4_x_size2               EQU spr_x_size2
spr4_y_size2               EQU sprite4_SIZE/(spr_x_size2/8)
spr5_x_size2               EQU spr_x_size2
spr5_y_size2               EQU sprite5_SIZE/(spr_x_size2/8)
spr6_x_size2               EQU spr_x_size2
spr6_y_size2               EQU sprite6_SIZE/(spr_x_size2/8)
spr7_x_size2               EQU spr_x_size2
spr7_y_size2               EQU sprite7_SIZE/(spr_x_size2/8)


; ** Struktur, die alle Variablenoffsets enthält **
; -------------------------------------------------

  INCLUDE "variables-offsets.i"

save_a7                         RS.L 1

; **** PT-Replay ****
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-variables-offsets.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-variables-offsets.i"
  ENDC

pt_trigger_fx_state             RS.W 1

; **** Viewport 1 ****
vp1_pf1_construction2           RS.L 1
vp1_pf1_display                 RS.L 1

; **** Viewport 2 ****
vp2_pf2_construction1           RS.L 1
vp2_pf2_construction2           RS.L 1
vp2_pf2_display                 RS.L 1

; **** Horiz-Scrolltext ****
hst_image                       RS.L 1
hst_state                       RS.W 1
hst_text_table_start            RS.W 1
hst_text_BLTCON0BITS            RS.W 1
hst_character_toggle_image      RS.W 1
hst_variable_horiz_scroll_speed RS.W 1

; **** Morph-Vector-Balls ****
mvb_rotation_x_angle            RS.W 1
mvb_rotation_y_angle            RS.W 1
mvb_rotation_z_angle            RS.W 1

mvb_morph_state                 RS.W 1
mvb_morph_shapes_table_start    RS.W 1
mvb_morph_delay_counter         RS.W 1

; **** Chessboard ****
cb_stripes_y_angle              RS.W 1

; **** Bar-Fader ****
bf_colors_counter               RS.W 1
bf_copy_colors_state            RS.W 1

; **** Bar-Fader-In ****
bfi_state                       RS.W 1
bfi_fader_angle                 RS.W 1

; **** Bar-Fader-Out ****
bfo_state                       RS.W 1
bfo_fader_angle                 RS.W 1

; **** Image-Fader ****
if_colors_counter               RS.W 1
if_copy_colors_state            RS.W 1

; **** Image-Fader-In ****
ifi_state                       RS.W 1
ifi_fader_angle                 RS.W 1

; **** Image-Fader-Out ****
ifo_state                       RS.W 1
ifo_fader_angle                 RS.W 1

; **** Chessboard-Fader ****
cf_colors_counter               RS.W 1

; **** Chessboard-Fader-In ****
cfi_state                       RS.W 1
cfi_fader_angle                 RS.W 1

; **** Chessboard-Fader-Out ****
cfo_state                       RS.W 1
cfo_fader_angle                 RS.W 1

; **** Sprite-Fader ****
sprf_colors_counter             RS.W 1
sprf_copy_colors_state          RS.W 1

; **** Sprite-Fader-In ****
sprfi_state                     RS.W 1
sprfi_fader_angle               RS.W 1

; **** Sprite-Fader-Out ****
sprfo_state                     RS.W 1
sprfo_fader_angle               RS.W 1

; **** Fade-Balls ****
fb_mask                         RS.W 1
vb_copy_blit_mask               RS.W 1

; **** Fade-Balls-In ****
fbi_state                       RS.W 1
fbi_delay_counter               RS.W 1

; **** Fade-Balls-Out ****
fbo_state                       RS.W 1
fbo_delay_counter               RS.W 1

; **** Colors-Fader-Cross ****
cfc_state                       RS.W 1
cfc_fader_angle                 RS.W 1
cfc_fader_delay_counter         RS.W 1
cfc_color_table_start           RS.W 1
cfc_colors_counter              RS.W 1
cfc_copy_colors_state           RS.W 1

; **** Main ****
fx_state                        RS.W 1
quit_state                      RS.W 1

variables_SIZE                  RS.B 0


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

; **** Morph-Vector-Balls ****
; ** Morph-Shape-Struktur **
; --------------------------
  RSRESET

mvb_morph_shape              RS.B 0

mvb_morph_shape_object_table RS.L 1

mvb_morph_shape_SIZE         RS.B 0


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

  moveq   #TRUE,d0
  move.w  d0,pt_trigger_fx_state(a3)

; **** Viewport 1 ****
  move.l  extra_pf1(a3),vp1_pf1_construction2(a3)
  move.l  extra_pf2(a3),vp1_pf1_display(a3)

; **** Viewport 2 ****
  move.l  extra_pf4(a3),vp2_pf2_construction1(a3)
  move.l  extra_pf5(a3),vp2_pf2_construction2(a3)
  move.l  extra_pf6(a3),vp2_pf2_display(a3)

; **** Horiz-Scrolltext ****
  lea     hst_image_data,a0
  move.l  a0,hst_image(a3)
  moveq   #FALSE,d1
  move.w  d1,hst_state(a3)
  move.w  d0,hst_text_table_start(a3)
  move.w  d0,hst_text_BLTCON0BITS(a3)
  move.w  d0,hst_character_toggle_image(a3)
  moveq   #hst_horiz_scroll_speed1,d2
  move.w  d2,hst_variable_horiz_scroll_speed(a3)

; **** Morph-Vector-Balls *****
  move.w  d0,mvb_rotation_x_angle(a3)
  move.w  d0,mvb_rotation_y_angle(a3)
  move.w  d0,mvb_rotation_z_angle(a3)

  IFEQ mvb_premorph_start_shape
    move.w  d0,mvb_morph_state(a3)
  ELSE
    move.w  d1,mvb_morph_state(a3)
  ENDC
  move.w  d0,mvb_morph_shapes_table_start(a3)
  IFEQ mvb_premorph_start_shape
    move.w  d1,mvb_morph_delay_counter(a3) ;Delay-Counter deaktivieren
  ELSE
    moveq   #1,d2
    move.w  d2,mvb_morph_delay_counter(a3) ;Delay-Counter aktivieren
  ENDC

; **** Chessboard ****
  move.w  d0,cb_stripes_y_angle(a3)

; **** Bar-Fader ****
  move.w  d0,bf_colors_counter(a3)
  move.w  d1,bf_copy_colors_state(a3)

; **** Bar-Fader-In ****
  move.w  d1,bfi_state(a3)
  MOVEF.W sine_table_length/4,d2
  move.w  d2,bfi_fader_angle(a3) ;90 Grad

; **** Bar-Fader-Out ****
  move.w  d1,bfo_state(a3)
  move.w  d2,bfo_fader_angle(a3) ;90 Grad

; **** Image-Fader ****
  move.w  d0,if_colors_counter(a3)
  move.w  d1,if_copy_colors_state(a3)

; **** Image-Fader-In ****
  move.w  d1,ifi_state(a3)
  move.w  d2,ifi_fader_angle(a3) ;90 Grad

; **** Image-Fader-Out ****
  move.w  d1,ifo_state(a3)
  move.w  d2,ifo_fader_angle(a3) ;90 Grad

; **** Chessboard-Fader ****
  move.w  d0,cf_colors_counter(a3)

; **** Chessboard-Fader-In ****
  move.w  d1,cfi_state(a3)
  move.w  d2,cfi_fader_angle(a3) ;90 Grad

; **** Chessboard-Fader-Out ****
  move.w  d1,cfo_state(a3)
  move.w  d2,cfo_fader_angle(a3) ;90 Grad

; **** Sprite-Fader ****
  move.w  d0,sprf_colors_counter(a3)
  move.w  d1,sprf_copy_colors_state(a3)

; **** Sprite-Fader-In ****
  move.w  d1,sprfi_state(a3)
  MOVEF.W sine_table_length/4,d2
  move.w  d2,sprfi_fader_angle(a3) ;90 Grad

; **** Sprite-Fader-Out ****
  move.w  d1,sprfo_state(a3)
  move.w  d2,sprfo_fader_angle(a3) ;90 Grad

; **** Fade-Balls ****
  move.w  #$8888,fb_mask(a3)
  move.w  #TRUE,vb_copy_blit_mask(a3)

; **** Fade-Balls-In ****
  move.w  d1,fbi_state(a3)
  move.w  d1,fbi_delay_counter(a3)

; **** Fade-Balls-Out ****
  move.w  d1,fbo_state(a3)
  move.w  d1,fbo_delay_counter(a3)

; **** Colors-Fader-Cross ****
  IFEQ cfc_prefade
    move.w  d0,cfc_state(a3)
    move.w  #cfc_colors_number*3,cfc_colors_counter(a3)
    move.w  d0,cfc_copy_colors_state(a3)
  ELSE
    move.w  d1,cfc_state(a3)
    move.w  d0,cfc_copy_colors_counter(a3)
    move.w  d1,cfc_copy_colors_state(a3)
  ENDC
  move.w  #sine_table_length/4,cfc_fader_angle(a3) ;90 Grad
  move.w  d2,cfc_fader_delay_counter(a3) ;Delay-Counter aktivieren
  move.w  d0,cfc_color_table_start(a3)

; **** Main ****
  move.w  d1,fx_state(a3)
  move.w  d1,quit_state(a3)
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
  bsr     init_color_registers
  bsr     init_sprites
  bsr     hst_init_characters_offsets
  bsr     hst_init_characters_x_positions
  bsr     hst_init_characters_images
  bsr     bvm_init_audio_channel_info_tables
  bsr     bvm_init_color_table
  bsr     bg2_copy_image_to_bitplane
  bsr     mvb_init_object_coordinates_offsets
  bsr     mvb_init_morph_shapes_table
  IFEQ mvb_premorph_start_shape
    bsr     mvb_init_start_shape
  ENDC
  bsr     mvb_rotation
  bsr     cb_init_chessboard_image
  bsr     cb_init_bitmap_table
  bsr     cb_init_color_tables
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

  CNOP 0,4
init_color_registers
  CPU_SELECT_COLORHI_BANK 7
  CPU_INIT_COLORHI COLOR16,8,vp3_pf1_color_table

  CPU_SELECT_COLORLO_BANK 7
  CPU_INIT_COLORLO COLOR16,8,vp3_pf1_color_table
  rts

; ** Sprites initialisieren **
; ----------------------------
  CNOP 0,4
init_sprites
  bsr.s   spr_init_pointers_table
  bra.s   bg1_init_attached_sprites_cluster

; ** Tabelle mit Zeigern auf Sprites initialisieren **
; ----------------------------------------------------
  INIT_SPRITE_POINTERS_TABLE

; ** Spritestrukturen initialisieren **
; -------------------------------------
  INIT_ATTACHED_SPRITES_CLUSTER bg1,spr_pointers_display,bg1_image_x_position,bg1_image_y_position,spr_x_size2,bg1_image_y_size,,,REPEAT

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
  move.w  #sine_table_length/4,(a0)+ ;Y-Winkel 90 Grad = maximaler Ausschlag
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
  lea     bfi_color_table+(bf_color_table_offset*LONGWORDSIZE)(pc),a1 ;Ziel
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

; **** Background-Image-2 ****
; ** Objekt ins Playfield kopieren **
; -----------------------------------
  COPY_IMAGE_TO_BITPLANE bg2,,,extra_pf3

; **** Morph-Vector-Balls ****
; ** XYZ-Koordinaten-Offsets initialisieren **
; --------------------------------------------
  CNOP 0,4
mvb_init_object_coordinates_offsets
  lea     mvb_object_coordinates_offsets(pc),a0 ;Zeiger auf Offset-Tabelle
  moveq   #TRUE,d0           ;Startwert
  moveq   #mvb_object_points_number-1,d7 ;Anzahl der Einträge
mvb_init_object_coordinates_offsets_loop
  move.w  d0,(a0)+           ;Startwert eintragen
  addq.w  #3,d0              ;nächste XYZ-Koordinate
  dbf     d7,mvb_init_object_coordinates_offsets_loop
  rts

; ** Object-Tabelle initialisieren **
; -----------------------------------
  CNOP 0,4
mvb_init_morph_shapes_table
; ** Form 1 **
  lea     mvb_object_shape1_coordinates(pc),a0 ;Zeiger auf 1. Form
  lea     mvb_morph_shapes_table(pc),a1 ;Tabelle mit Zeigern auf Objektdaten
  move.l  a0,(a1)+           ;Zeiger auf Form-Tabelle
; ** Form 2 **
  lea     mvb_object_shape2_coordinates(pc),a0 ;Zeiger auf 2. Form
  IFEQ mvb_morph_loop
    move.l  a0,(a1)         ;Zeiger auf Form-Tabelle
  ELSE
    move.l  a0,(a1)+        ;Zeiger auf Form-Tabelle
; ** Form 3 **
    lea     mvb_object_shape3_coordinates(pc),a0 ;Zeiger auf 6. Form
    move.l  a0,(a1)         ;Zeiger auf Form-Tabelle
  ENDC
  rts

  IFEQ mvb_premorph_start_shape
    CNOP 0,4
mvb_init_start_shape
    bsr     mvb_morph_object
    tst.w   mvb_morph_state(a3) ;Morphing beendet?
    beq.s   mvb_init_start_shape ;Nein -> verzweige
    rts
  ENDC

; **** Chessboard ****
; ** Schachbrettmuster initialisieren **
; --------------------------------------
  CNOP 0,4
cb_init_chessboard_image
  movem.w cb_fill_pattern(pc),d0-d3 ;Füllmuster High&Low 1. Wort, High&Low 2. Wort
  move.l  extra_pf7(a3),a0
  move.l  (a0)+,a1           ;BP0
  move.l  (a0),a2            ;BP1
  moveq   #(cb_source_image_x_size/32)-1,d7 ;Anzahl der Wiederholungen des Musters
cb_init_chessboard_image_loop
  move.w  d0,(a1)+           ;High 1. Wort
  move.w  d1,(a2)+           ;High 2. Wort
  move.w  d2,(a1)+           ;Low 1. Wort
  move.w  d3,(a2)+           ;Low 2. Wort
  dbf     d7,cb_init_chessboard_image_loop
  rts

; ** Bitmap-Tabelle für die Spalten initialisieren **
; ---------------------------------------------------
  CNOP 0,4
cb_init_bitmap_table
  move.l  extra_memory(a3),a0
  ADDF.L  em_bitmap_table,a0 ;Zeiger auf Bitmap-Tabelle
  move.w  #cb_source_image_x_size,a1 ;Breite des QuellPlayfieldes in Pixeln
  move.l  a1,d3
  moveq   #(cb_destination_image_x_size)/16,d4 ;Breite des Zielbildes in Pixeln
  swap    d3                 ;*2^16
  lsl.w   #4,d4
  MOVEF.W cb_destination_image_y_size-1,d7 ;Anzahl der Zeilen in Bitmap-Tabelle
cb_init_bitmap_table_loop1
  move.l  d3,d2              ;Breite des Quellbildes untere 32 Bit
  moveq   #TRUE,d6           ;Breite des Quellbildes obere 32 Bit
  divu.l  d4,d6:d2           ;F=Breite des Quellbildes/Breite der Zielbildes
  moveq   #TRUE,d1
  move.w  d4,d6              ;Breite des Zielbilds holen
  subq.w  #1,d6              ;wegen dbf
cb_init_bitmap_table_loop2
  move.l  d1,d0              ;F holen
  swap    d0                 ;/2^16 = Bitmapposition
  add.l   d2,d1              ;F erhöhen (p*F)
  addq.b  #1,(a0,d0.w)       ;Pixel in Tabelle setzen
  dbf     d6,cb_init_bitmap_table_loop2
  add.l   a1,a0              ;nächste Zeile in Bitmap-Tabelle
  addq.l  #cb_destination_image_plane_width_step,d4 ;Breite des Zielbilds erhöhen
  dbf     d7,cb_init_bitmap_table_loop1
  rts

; ** Farbtabellen initialisieren **
; ---------------------------------
  CNOP 0,4
cb_init_color_tables
  lea     cb_color_gradient1(pc),a0 ;Quelle1
  lea     cb_color_gradient2(pc),a1 ;Quelle2
  lea     cfi_color_table+(cf_color_table_offset*LONGWORDSIZE)(pc),a2 ;Ziel
  moveq   #vp3_visible_lines_number-1,d7
cb_init_color_tables_loop1
  move.l  (a0)+,(a2)+        ;Farbwerte verschachteln
  move.l  (a1)+,(a2)+
  dbf     d7,cb_init_color_tables_loop1

  move.l  #COLOR00BITS,d0
  move.l  extra_memory(a3),a0
  ADDF.L  em_color_table,a0
  moveq   #(vp3_visible_lines_number*2)-1,d7
cb_init_color_tables_loop2
  move.l  d0,(a0)+
  dbf     d7,cb_init_color_tables_loop2
  rts


; ** 1. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_first_copperlist
  move.l  cl1_display(a3),a0
  bsr.s   cl1_init_playfield_registers
  bsr     cl1_init_sprite_pointers
  bsr     cl1_init_color_registers
  bsr     cl1_vp2_init_bitplane_pointers
  COPMOVEQ TRUE,COPJMP2
  bsr     cl1_set_sprite_pointers
  bra     cl1_vp2_pf1_set_bitplane_pointers

  COP_INIT_PLAYFIELD_REGISTERS cl1,NOBITPLANESSPR

  COP_INIT_SPRITE_POINTERS cl1

  CNOP 0,4
cl1_init_color_registers
  COP_INIT_COLORHI COLOR00,16,vp2_pf1_color_table
  COP_INIT_COLORHI COLOR16,16,vp2_pf2_color_table
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

  COP_SELECT_COLORLO_BANK 0
  COP_INIT_COLORLO COLOR00,16,vp2_pf1_color_table
  COP_INIT_COLORLO COLOR16,16,vp2_pf2_color_table
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

  CNOP 0,4
cl1_vp2_init_bitplane_pointers
  COPMOVEQ TRUE,BPL3PTH
  COPMOVEQ TRUE,BPL3PTL
  COPMOVEQ TRUE,BPL5PTH
  COPMOVEQ TRUE,BPL5PTL
  COPMOVEQ TRUE,BPL7PTH
  COPMOVEQ TRUE,BPL7PTL
  rts

  COP_SET_SPRITE_POINTERS cl1,display,spr_number

  CNOP 0,4
cl1_vp2_pf1_set_bitplane_pointers
  move.l  cl1_display(a3),a0
  ADDF.L  cl1_extension1_entry+cl1_ext1_BPL3PTH+2,a0
  move.l  extra_pf3(a3),a1
  addq.w  #4,a1              ;Zeiger auf zweite Plane
  moveq   #(vp2_pf1_depth-1)-1,d7 ;Anzahl der Bitplanes
cl1_vp2_pf1_set_bitplane_pointers_loop
  move.w  (a1)+,(a0)         ;High-Wert
  addq.w  #8,a0              ;nächter Playfieldzeiger
  move.w  (a1)+,4-8(a0)      ;Low-Wert
  dbf     d7,cl1_vp2_pf1_set_bitplane_pointers_loop
  rts

; ** 2. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_second_copperlist
  move.l  cl2_construction2(a3),a0
; **** Viewport 1 ****
  bsr     cl2_vp1_init_playfield_registers
  bsr     cl2_vp1_init_bitplane_pointers
  COPWAIT cl2_vp1_HSTART1,cl2_vp1_VSTART1
  COPMOVEQ vp1_BPLCON0BITS,BPLCON0
  bsr     cl2_vp1_init_color_gradient_registers
; **** Viewport 2 ****
  COPWAIT cl2_vp2_HSTART,cl2_vp2_VSTART
  bsr     cl2_vp2_init_playfield_registers
  bsr     cl2_vp2_init_bitplane_pointers
; **** Viewport 3 ****
  COPWAIT cl2_vp3_HSTART1,cl2_vp3_VSTART1
  bsr     cl2_vp3_init_playfield_registers
  bsr     cl2_vp3_init_bitplane_pointers
  bsr     cl2_vp3_init_color_gradient_registers
; **** Copper-Interrupt ****
  bsr     cl2_init_copint
  COPLISTEND
  bsr     cl2_vp1_pf1_set_bitplane_pointers
  bsr     cl2_vp1_set_fill_color_gradient
  bsr     cl2_vp1_set_outline_color_gradient
  bsr     cl2_vp2_pf1_set_bitplane_pointers
  bsr     cl2_vp3_pf1_set_bitplane_pointers
  bsr     cl2_vp3_pf2_set_bitplane_pointers
  bsr     copy_second_copperlist
  bsr     swap_second_copperlist
  bsr     swap_vp1_playfield1
  bra     swap_vp2_playfield2

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
  move.l  #(((cl2_vp1_VSTART2<<24)|(((cl2_vp1_HSTART2/4)*2)<<16))|$10000)|$fffe,d0 ;WAIT-Befehl
  move.l  #(BPLCON3<<16)|vp1_BPLCON3BITS3,d1 ;High-Werte
  move.l  #(COLOR29<<16)|COLOR00HIGHBITS,d2
  move.l  #(COLOR30<<16)|COLOR00HIGHBITS,d3
  move.l  #(BPLCON3<<16)|vp1_BPLCON3BITS4,d4 ;Low-RGB-Werte
  move.l  #(COLOR29<<16)|COLOR00LOWBITS,d5
  moveq   #1,d6
  ror.l   #8,d6              ;$01000000 Additionswert
  move.l  #(COLOR30<<16)|COLOR00LOWBITS,a1
  move.l  #(BPLCON4<<16)|vp1_BPLCON4BITS,a2
  MOVEF.W vp1_visible_lines_number-1,d7 ;Anzahl der Zeilen
cl2_vp1_init_color_gradient_registers_loop
  move.l  d0,(a0)+           ;WAIT x,y
  move.l  d1,(a0)+           ;BPLCON3 High-Werte
  move.l  d2,(a0)+           ;COLOR29
  move.l  d3,(a0)+           ;COLOR30
  move.l  d4,(a0)+           ;BPLCON3 Low-Werte
  move.l  d5,(a0)+           ;COLOR39
  move.l  a1,(a0)+           ;COLOR30
  add.l   d6,d0              ;nächste Zeile
  move.l  a2,(a0)+           ;BPLCON4
  dbf     d7,cl2_vp1_init_color_gradient_registers_loop
  rts

; **** Viewport 2 ****
  COP_INIT_PLAYFIELD_REGISTERS cl2,,vp2

  CNOP 0,4
cl2_vp2_init_bitplane_pointers
  COPMOVEQ TRUE,BPL1PTH
  COPMOVEQ TRUE,BPL1PTL
  COPMOVEQ TRUE,BPL2PTH
  COPMOVEQ TRUE,BPL2PTL
  COPMOVEQ TRUE,BPL4PTH
  COPMOVEQ TRUE,BPL4PTL
  COPMOVEQ TRUE,BPL6PTH
  COPMOVEQ TRUE,BPL6PTL
  COPMOVEQ vp2_BPLCON0BITS,BPLCON0
  rts

; **** Viewport 3 ****
  COP_INIT_PLAYFIELD_REGISTERS cl2,,vp3

  CNOP 0,4
cl2_vp3_init_bitplane_pointers
  COPMOVEQ TRUE,BPL1PTH
  COPMOVEQ TRUE,BPL1PTL
  COPMOVEQ TRUE,BPL2PTH
  COPMOVEQ TRUE,BPL2PTL
  COPMOVEQ TRUE,BPL3PTH
  COPMOVEQ TRUE,BPL3PTL
  COPMOVEQ TRUE,BPL4PTH
  COPMOVEQ TRUE,BPL4PTL
  COPMOVEQ TRUE,BPL5PTH
  COPMOVEQ TRUE,BPL5PTL
  COPMOVEQ vp3_BPLCON0BITS,BPLCON0
  rts

  CNOP 0,4
cl2_vp3_init_color_gradient_registers
  move.l  #(((cl2_vp3_VSTART2<<24)|(((cl2_vp3_HSTART2/4)*2)<<16))|$10000)|$fffe,d0 ;WAIT-Befehl
  move.l  #(BPLCON3<<16)|vp3_BPLCON3BITS3,d1 ;High-Werte
  move.l  #(COLOR25<<16)|COLOR00HIGHBITS,d2
  move.l  #(COLOR26<<16)|COLOR00HIGHBITS,d3
  move.l  #(BPLCON3<<16)|vp3_BPLCON3BITS4,d4 ;Low-Werte
  move.l  #(((cl_y_wrap<<24)|(((cl2_vp3_HSTART2/4)*2)<<16))|$10000)|$fffe,d5 ;WAIT-Befehl
  moveq   #1,d6
  ror.l   #8,d6              ;$01000000 Additionswert
  move.l  #(COLOR25<<16)|COLOR00LOWBITS,a1
  move.l  #(COLOR26<<16)|COLOR00LOWBITS,a2
  moveq   #vp3_visible_lines_number-1,d7 ;Anzahl der Zeilen
cl2_vp3_init_color_gradient_registers_loop
  move.l  d0,(a0)+           ;WAIT x,y
  move.l  d1,(a0)+           ;High-Werte
  move.l  d2,(a0)+           ;COLOR25
  move.l  d3,(a0)+           ;COLOR26
  move.l  d4,(a0)+           ;Low-Werte
  move.l  a1,(a0)+           ;COLOR25
  move.l  a2,(a0)+           ;COLOR26
  cmp.l   d5,d0              ;Rasterzeile $ff erreicht ?
  bne.s   no_patch_copperlist2 ;Nein -> verzweige
patch_copperlist2
  COPWAIT cl_x_wrap,cl_y_wrap ;Copperliste patchen
  bra.s   cl2_vp3_init_color_gradient_registers_skip
  CNOP 0,4
no_patch_copperlist2
  COPMOVEQ TRUE,NOOP
cl2_vp3_init_color_gradient_registers_skip
  add.l   d6,d0              ;nächste Zeile
  dbf     d7,cl2_vp3_init_color_gradient_registers_loop
  rts

  COP_INIT_COPINT cl2,cl2_HSTART,cl2_VSTART

; **** Viewport 1 ****
  CNOP 0,4
cl2_vp1_pf1_set_bitplane_pointers
  move.l  cl2_display(a3),a0 
  ADDF.W  cl2_extension1_entry+cl2_ext1_BPL1PTH+2,a0
  move.l  vp1_pf1_display(a3),a1 ;Zeiger auf erste Plane
  moveq   #vp1_pf1_depth-1,d7 ;Anzahl der Bitplanes
cl2_vp1_pf1_set_bitplane_pointers_loop
  move.w  (a1)+,(a0)         ;High-Wert
  addq.w  #8,a0              ;nächter Playfieldzeiger
  move.w  (a1)+,4-8(a0)      ;Low-Wert
  dbf     d7,cl2_vp1_pf1_set_bitplane_pointers_loop
  rts

  CNOP 0,4
cl2_vp1_set_fill_color_gradient
  move.w  #$0f0f,d3          ;RGB-Maske
  lea     hst_fill_color_gradient(pc),a0
  move.l  cl2_construction2(a3),a1
  ADDF.W  cl2_extension2_entry+cl2_ext2_COLOR29_high8+2,a1
  move.w  #cl2_extension2_SIZE,a2
  lea     (a1,a2.l*2),a1     ;Zwei Rasterzeilen überspringen
  MOVEF.W (vp1_visible_lines_number-4)-1,d7
cl2_vp1_set_fill_color_gradient_loop
  move.l  (a0)+,d0
  move.l  d0,d2
  RGB8_TO_RGB4HI d0,d1,d3
  move.w  d0,(a1)            ;High-Werte
  RGB8_TO_RGB4LO d2,d1,d3
  move.w  d2,cl2_ext2_COLOR29_low8-cl2_ext2_COLOR29_high8(a1) ;Low-Werte
  add.l   a2,a1
  dbf     d7,cl2_vp1_set_fill_color_gradient_loop
  rts

  CNOP 0,4
cl2_vp1_set_outline_color_gradient
  move.w  #$0f0f,d3          ;RGB-Maske
  lea     hst_outline_color_gradient(pc),a0
  move.l  cl2_construction2(a3),a1
  ADDF.W  cl2_extension2_entry+cl2_ext2_COLOR30_high8+2,a1
  move.w  #cl2_extension2_SIZE,a2
  MOVEF.W vp1_visible_lines_number-1,d7
cl2_vp1_set_outline_color_gradient_loop
  move.l  (a0)+,d0
  move.l  d0,d2
  RGB8_TO_RGB4HI d0,d1,d3
  move.w  d0,(a1)            ;High-Werte
  RGB8_TO_RGB4LO d2,d1,d3
  move.w  d2,cl2_ext2_COLOR30_low8-cl2_ext2_COLOR30_high8(a1) ;Low-Werte
  add.l   a2,a1
  dbf     d7,cl2_vp1_set_outline_color_gradient_loop
  rts

; **** Viewport 2 ****
  CNOP 0,4
cl2_vp2_pf1_set_bitplane_pointers
  move.l  cl2_construction2(a3),a0
  ADDF.L  cl2_extension3_entry+cl2_ext3_BPL1PTH+2,a0
  move.l  extra_pf3(a3),a1   ;Zeiger auf erste Plane
  moveq   #(vp2_pf1_depth-3)-1,d7 ;Anzahl der Bitplanes
cl2_vp2_pf1_set_bitplane_pointers_loop
  move.w  (a1)+,(a0)         ;High-Wert
  addq.w  #8,a0              ;nächter Playfieldzeiger
  move.w  (a1)+,4-8(a0)      ;Low-Wert
  dbf     d7,cl2_vp2_pf1_set_bitplane_pointers_loop
  rts

; **** Viewport 3 ****
  CNOP 0,4
cl2_vp3_pf1_set_bitplane_pointers
  move.l  cl2_construction2(a3),a0
  ADDF.L  cl2_extension4_entry+cl2_ext4_BPL1PTH+2,a0
  move.l  extra_pf4(a3),a1   ;Zeiger auf erste Plane
  moveq   #vp3_pf1_depth-1,d7 ;Anzahl der Bitplanes
cl2_vp3_pf1_set_bitplane_pointers_loop
  move.w  (a1)+,(a0)         ;High-Wert
  ADDF.W  16,a0              ;nächter Playfieldzeiger
  move.w  (a1)+,4-16(a0)     ;Low-Wert
  dbf     d7,cl2_vp3_pf1_set_bitplane_pointers_loop
  rts

  CNOP 0,4
cl2_vp3_pf2_set_bitplane_pointers
  move.l  cl2_construction2(a3),a0
  ADDF.L  cl2_extension4_entry+cl2_ext4_BPL2PTH+2,a0
  move.l  extra_pf8(a3),a1   ;Zeiger auf erste Plane
  moveq   #vp3_pf2_depth-1,d7 ;Anzahl der Bitplanes
cl2_vp3_pf2_set_bitplane_pointers_loop
  move.w  (a1)+,(a0)         ;High-Wert
  ADDF.W  16,a0              ;nächter Playfieldzeiger
  move.w  (a1)+,4-16(a0)     ;Low-Wert
  dbf     d7,cl2_vp3_pf2_set_bitplane_pointers_loop
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
  bra     beam_routines


; ## Routinen, die nicht mit der Bildwiederholfrequenz gekoppelt sind ##
; ----------------------------------------------------------------------
  CNOP 0,4
no_sync_routines
  IFEQ cfc_prefade
    bsr     cfc_init_start_colors
  ENDC

; ** Playfield skalieren **
; --------------------
cb_scale_image
  movem.l a4-a5,-(a7)
  moveq   #TRUE,d4           ;1. X-Koord in Zielbild
  move.l  extra_memory(a3),a0
  ADDF.L  em_bitmap_table,a0 ;Zeiger auf Bitmap-Tabelle
  move.l  extra_pf7(a3),a1   ;Zeiger auf Quellbild
  move.l  (a1),a1            ;BP0
  move.l  extra_pf8(a3),a2   ;Zeiger auf Zielbild
  move.l  (a2),a2            ;BP0
  move.w  #cb_x_max,a4       ;X-Max in Zielbild
  move.w  #1*extra_pf8_plane_width*extra_pf8_depth,a5
  moveq   #cb_destination_image_y_size-1,d7 ;Höhe des Zielbildes
cb_scale_image_loop1
  moveq   #TRUE,d2           ;1. X-Koord in Quellbild
  move.w  d4,d3              ;X-Koord in Zielbild holen
  MOVEF.W cb_source_image_x_size-1,d6 ;Breite des Quellbildes
cb_scale_image_loop2
  tst.b   (a0)+              ;Spalte setzen ?
  beq.s   cb_skip_column     ;Nein -> verzweige
  move.w  d3,d1              ;X-Koord in Zielbild holen
  bmi.s   cb_column_outside  ;Wenn < X-Min -> verzweige
  cmp.w   a4,d1
  bge.s   cb_column_outside  ;Wenn >= X-Max -> verzweige
  move.w  d2,d0              ;X-Koord in Quellbild holen
  lsr.w   #3,d0              ;/8 X-Offset in Quellbild
  not.b   d2                 ;Shiftwert für Quellbyte ermitteln
  lsr.w   #3,d1              ;/8 X-Offset in Zielbild
  not.b   d3                 ;Shiftwert für Zielbyte ermitteln
  btst    d2,(a1,d0.w)       ;Pixel in Quellbyte gesetzt ?
  beq.s   cb_bitplane0_no_pixel_set ;Nein -> verzweige
  bset    d3,(a2,d1.w)       ;Pixel setzen
cb_bitplane0_no_pixel_set
  btst    d2,(extra_pf7_plane_width,a1,d0.w) ;Pixel in Quellbyte gesetzt ?
  beq.s   cb_bitplane1_no_pixel_set ;Nein -> verzweige
  bset    d3,extra_pf8_plane_width(a2,d1.w) ;Pixel setzen
cb_bitplane1_no_pixel_set
  not.b   d3                 ;Bitnummer wieder in X-Koord Zielbild umwandeln
  not.b   d2                 ;Bitnummer wieder in X-Koord Quellbild umwandeln
cb_column_outside
  addq.w  #1,d3              ;nächstes Pixel in Zielbild
cb_skip_column
  addq.w  #1,d2              ;nächstes Pixel in Quellbild
  dbf     d6,cb_scale_image_loop2
  add.l   a5,a2              ;nächste Zeile in Zielbild
  subq.w  #cb_destination_image_x_size_step,d4 ;X-Pos in Zielbild reduzieren
  dbf     d7,cb_scale_image_loop1
  movem.l (a7)+,a4-a5
  rts

  IFEQ cfc_prefade
    CNOP 0,4
cfc_init_start_colors
    bsr     cfc_copy_color_table
    bsr     colors_fader_cross
    tst.w   cfc_copy_colors_state(a3) ;Kopieren der Farbwerte beendet?
    beq.s   cfc_init_start_colors ;Nein -> verzweige
    moveq   #FALSE,d0
    move.w  d0,cfc_copy_colors_state(a3) ;Verzögerungszähler desktivieren
    rts
  ENDC


; ## Rasterstahl-Routinen ##
; --------------------------
  CNOP 0,4
beam_routines
  bsr     wait_copint
  bsr     swap_second_copperlist
  bsr     swap_vp1_playfield1
  bsr     swap_vp2_playfield2
  bsr     horiz_scrolltext
  bsr     hst_horiz_scroll
  bsr     mvb_clear_playfield1_2
  bsr     bvm_get_channels_amplitudes
  bsr     bvm_clear_second_copperlist
  bsr     bvm_set_bars
  bsr     fade_balls_in
  bsr     fade_balls_out
  bsr     set_vector_balls
  bsr     mvb_clear_playfield1_1
  bsr     mvb_rotation
  bsr     mvb_morph_object
  movem.l a4-a6,-(a7)
  bsr     mvb_quicksort_coordinates
  movem.l (a7)+,a4-a6
  bsr     cb_get_stripes_y_coordinates
  bsr     cb_make_color_offsets_table
  bsr     cb_move_chessboard
  bsr     control_counters
  bsr     bar_fader_in
  bsr     bar_fader_out
  bsr     bf_copy_color_table
  bsr     image_fader_in
  bsr     image_fader_out
  bsr     if_copy_color_table
  bsr     chessboard_fader_in
  bsr     chessboard_fader_out
  bsr     sprite_fader_in
  bsr     sprite_fader_out
  bsr     sprf_copy_color_table
  bsr     colors_fader_cross
  bsr     cfc_copy_color_table
  bsr     mouse_handler
  tst.w   fx_state(a3)       ;Effekte beendet ?
  bne     beam_routines      ;Nein -> verzweige
  rts


; ** Copperlisten vertauschen **
; ------------------------------
  SWAP_COPPERLIST cl2,2

; ** VP1-Playfield1 vertauschen **
; --------------------------------
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

; ** VP2-Playfield2 vertauschen **
; --------------------------------
  CNOP 0,4
swap_vp2_playfield2
  move.l  cl2_display(a3),a0
  move.l  vp2_pf2_construction1(a3),a1
  move.l  vp2_pf2_construction2(a3),a2
  move.l  vp2_pf2_display(a3),vp2_pf2_construction1(a3)
  move.l  a1,vp2_pf2_construction2(a3)
  ADDF.W  cl2_extension3_entry+cl2_ext3_BPL2PTH+2,a0
  move.l  a2,vp2_pf2_display(a3)
  move.l  a2,a1
  moveq   #vp2_pf2_depth-1,d7 ;Anzahl der Planes
swap_vp2_playfield2_loop
  move.w  (a2)+,(a0)         ;BPLxPTH
  addq.w  #8,a0
  move.w  (a2)+,4-8(a0)      ;BPLxPTL
  dbf     d7,swap_vp2_playfield2_loop

  move.l  cl2_display(a3),a0
  ADDF.W  cl2_extension4_entry+cl2_ext4_BPL1PTH+2,a0
  moveq   #vp3_pf1_depth-1,d7 ;Anzahl der Planes
swap_vp3_playfield1_loop
  move.w  (a1)+,(a0)         ;High-Wert
  ADDF.W  16,a0              ;nächter Playfieldzeiger
  move.w  (a1)+,4-16(a0)     ;Low-Wert
  dbf     d7,swap_vp3_playfield1_loop
  rts


; ** Laufschrift **
; -----------------
  CNOP 0,4
horiz_scrolltext
  tst.w   hst_state(a3)      ;Laufschrift an ?
  bne.s   no_horiz_scrolltext ;Nein -> verweige
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
  sub.w   hst_variable_horiz_scroll_speed(a3),d2 ;X-Position verringern
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
no_horiz_scrolltext
  rts
  CNOP 0,4
hst_init_character_blit
  move.w  #DMAF_BLITHOG|DMAF_SETCLR,DMACON-DMACONR(a6) ;BLTPRI an
  WAITBLITTER
  move.l  #(BC0F_SRCA|BC0F_DEST|ANBNC+ANBC|ABNC+ABC)<<16,BLTCON0-DMACONR(a6) ;Minterm D=A
  moveq   #FALSE,d0
  move.l  d0,BLTAFWM-DMACONR(a6) ;keine Ausmaskierung
  move.l  #((hst_image_plane_width-hst_text_character_width)<<16)|(extra_pf1_plane_width-hst_text_character_width),BLTAMOD-DMACONR(a6) ;A-Mod + D-Mod
  rts

; ** Softscrollwert berechen **
; -----------------------------
  CNOP 0,4
hst_get_text_softscroll
  moveq   #hst_text_character_x_size-1,d0
  and.w   (a0),d0            ;X-Pos.&$f
  ror.w   #4,d0              ;Bits in richtige Position bringen
  or.w    #BC0F_SRCA+BC0F_DEST+ANBNC+ANBC+ABNC+ABC,d0 ;Minterm  D=A
  move.w  d0,hst_text_BLTCON0BITS(a3) 
  rts

; ** Neues Image für Character ermitteln **
; -----------------------------------------
  GET_NEW_CHARACTER_IMAGE.W hst,hst_check_control_codes,NORESTART

  CNOP 0,4
hst_check_control_codes
  cmp.b   #"",d0
  beq.s   hst_restart_scrolltext
  cmp.b   #"",d0
  beq.s   hst_stop_scrolltext
  rts
  CNOP 0,4
hst_restart_scrolltext
  moveq   #TRUE,d0           ;Rückgabewert = Steuerungscode gefunden
  move.w   d0,hst_text_table_start(a3) ;Startwert zurücksetzen
  rts
  CNOP 0,4
hst_stop_scrolltext
  moveq   #FALSE,d0
  move.w  d0,hst_state(a3)   ;Text stoppen
  moveq   #TRUE,d0           ;Rückgabewert TRUE = Steuerungscode gefunden
  tst.w   quit_state(a3)     ;Soll Intro beendet werden?
  bne.s   hst_normal_stop_scrolltext ;Nein -> verzweige
hst_quit_and_stop_scrolltext
  move.w  d0,pt_fade_out_music_state(a3) ;Musik ausfaden

  move.w  d0,fbo_state(a3)   ;Fade-Balls-Out an
  move.w  #fbo_delay,fbo_delay_counter(a3)
  move.w  #$8888,fb_mask(a3)

  move.w  #sprf_colors_number*3,sprf_colors_counter(a3)
  move.w  d0,sprfo_state(a3) ;Sprite-Fader-Out an
  move.w  d0,sprf_copy_colors_state(a3) ;Kopieren der Farben an

  move.w  #if_colors_number*3,if_colors_counter(a3)
  move.w  d0,ifo_state(a3)   ;Image-Fader-Out an
  move.w  d0,if_copy_colors_state(a3) ;Kopieren der Farben an

  move.w  d0,cfo_state(a3)   ;Chessboard-Fader-Out an

  move.w  #bf_colors_number*3,bf_colors_counter(a3)
  move.w  d0,bfo_state(a3)   ;Bar-Fader-Out an
  move.w  d0,bf_copy_colors_state(a3) ;Kopieren der Farben an

hst_normal_stop_scrolltext
  rts

; ** Laufschrift bewegen **
; -------------------------
  CNOP 0,4
hst_horiz_scroll
  tst.w   hst_state(a3)      ;Laufschrift an ?
  bne.s   hst_no_horiz_scroll ;Nein -> verweige
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
hst_no_horiz_scroll
  rts

; ** Amplituden der einzelnen Kanäle in Erfahrung bringen **
; ----------------------------------------------------------
  CNOP 0,4
bvm_get_channels_amplitudes
  MOVEF.W bvm_max_amplitude,d2
  MOVEF.W sine_table_length/4,d3
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
  MOVEF.W (sine_table_length/2)-1,d5
  lea     sine_table(pc),a0  
  lea     bvm_audio_channel1_info(pc),a1 ;Zeiger auf Amplitude und Y-Winkeldes Kanals
  lea     bvm_switch_table(pc),a4 ;Zeiger auf Switchtabelle
  move.l  cl2_construction2(a3),a5 
  ADDF.W  cl2_extension2_entry+cl2_ext2_BPLCON4+3,a5
  move.w  #bvm_y_centre,a3
  move.w  #cl2_extension2_SIZE,a6
  moveq   #bvm_bars_number-1,d7 ;Anzahl der Bars
bvm_set_bars_loop1
  move.w  (a1)+,d3           ;Y-Winkel
  move.w  2(a0,d3.w*4),d0    ;sin(w)
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

; ** Playfield löschen (Blitter) **
; ---------------------------------
  CNOP 0,4
mvb_clear_playfield1_1
  move.l  vp2_pf2_construction1(a3),a0
  WAITBLITTER
  move.l  #BC0F_DEST<<16,BLTCON0-DMACONR(a6)
  move.l  (a0),BLTDPT-DMACONR(a6)
  moveq   #TRUE,d0
  move.w  d0,BLTDMOD-DMACONR(a6) ;D-Mod
  move.w  #(mvb_clear_blit_y_size*64)+(mvb_clear_blit_x_size/16),BLTSIZE-DMACONR(a6) ;Blitter starten
  rts

; ** Playfield löschen (CPU) **
; -----------------------------
  CNOP 0,4
mvb_clear_playfield1_2
  movem.l a3-a6,-(a7)
  move.l  a7,save_a7(a3)     ;Stackpointer retten
  moveq   #TRUE,d0
  moveq   #TRUE,d1
  moveq   #TRUE,d2
  moveq   #TRUE,d3
  moveq   #TRUE,d4
  moveq   #TRUE,d5
  moveq   #TRUE,d6
  move.l  d0,a0
  move.l  d0,a1
  move.l  d0,a2
  move.l  d0,a4
  move.l  d0,a5
  move.l  d0,a6
  move.l  vp2_pf2_construction1(a3),a7 ;Zeiger erste Plane
  move.l  (a7),a7
  ADDF.L  extra_pf4_plane_width*extra_pf4_y_size*extra_pf4_depth,a7 ;Ende des Playfields
  move.l  d0,a3
  moveq   #5-1,d7            ;Anzahl der Durchläufe
mvb_clear_playfield1_2_loop
  REPT ((extra_pf4_plane_width*extra_pf4_y_size*(extra_pf4_depth-1))/56)/5
  movem.l d0-d6/a0-a6,-(a7)  ;56 Bytes löschen
  ENDR
  dbf     d7,mvb_clear_playfield1_2_loop
  move.l  variables+save_a7(pc),a7 ;Alter Stack
  movem.l (a7)+,a3-a6
  rts

; ** Rotate-Routine **
; --------------------
  CNOP 0,4
mvb_rotation
  movem.l a4-a6,-(a7)
  move.w  mvb_rotation_x_angle(a3),d1 ;X-Winkel
  move.w  d1,d0              ;X-Winkel -> d7
  lea     sine_table(pc),a2  ;Sinus-Tabelle
  move.w  2(a2,d0.w*4),d4    ;sin(a)
  move.w  #sine_table_length/4,a4
  IFEQ sine_table_length-512
    MOVEF.W sine_table_length-1,d3
  ELSE
    MOVEF.W sine_table_length,d3
  ENDC
  add.w   a4,d0              ;+ 90 Grad
  swap    d4                 ;Bits 16-31 = sin(a)
  IFEQ sine_table_length-512
    and.w   d3,d0            ;Übertrag entfernen
  ELSE
    cmp.w   d3,d0            ;360 Grad erreicht ?
    blt.s   mvb_rotation_no_x_angle_restart1
    sub.w   d3,d0            ;Neustart
mvb_rotation_no_x_angle_restart1
  ENDC
  move.w  2(a2,d0.w*4),d4    ;Bits  0-15 = cos(a)
  addq.w  #mvb_rotation_x_angle_speed,d1 ;nächster X-Winkel
  IFEQ sine_table_length-512
    and.w   d3,d1            ;Übertrag entfernen
  ELSE
    cmp.w   d3,d1            ;360 Grad erreicht ?
    blt.s   mvb_rotation_no_x_angle_restart2
    sub.w   d3,d1            ;Neustart
mvb_rotation_no_x_angle_restart2
  ENDC
  move.w  d1,mvb_rotation_x_angle(a3) ;X-Winkel retten
  move.w  mvb_rotation_y_angle(a3),d1 ;Y-Winkel
  move.w  d1,d0              
  move.w  2(a2,d0.w*4),d5    ;sin(b)
  add.w   a4,d0              ;+ 90 Grad
  swap    d5                 ;Bits 16-31 = sin(b)
  IFEQ sine_table_length-512
    and.w   d3,d0            ;Übertrag entfernen
  ELSE
    cmp.w   d3,d0            ;360 Grad erreicht ?
    blt.s   mvb_rotation_no_y_angle_restart1
    sub.w   d3,d0            ;Neustart
mvb_rotation_no_y_angle_restart1
  ENDC
  move.w  2(a2,d0.w*4),d5    ;Bits  0-15 = cos(b)
  addq.w  #mvb_rotation_y_angle_speed,d1 ;nächster Y-Winkel
  IFEQ sine_table_length-512
    and.w   d3,d1            ;Übertrag entfernen
  ELSE
    cmp.w   d3,d1            ;360 Grad erreicht ?
    blt.s   mvb_rotation_no_y_angle_restart2
    sub.w   d3,d1            ;Neustart
mvb_rotation_no_y_angle_restart2
  ENDC
  move.w  d1,mvb_rotation_y_angle(a3) ;Y-Winkel retten
  move.w  mvb_rotation_z_angle(a3),d1 ;Z-Winkel
  move.w  d1,d0              
  move.w  2(a2,d0.w*4),d6    ;sin(c)
  add.w   a4,d0              ;+ 90 Grad
  swap    d6                 ;Bits 16-31 = sin(c)
  IFEQ sine_table_length-512
    and.w   d3,d0            ;Übertrag entfernen
  ELSE
    cmp.w   d3,d0            ;360 Grad erreicht ?
    blt.s   mvb_rotation_no_z_angle_restart1
    sub.w   d3,d0            ;Neustart
mvb_rotation_no_z_angle_restart1
  ENDC
  move.w  2(a2,d0.w*4),d6    ;Bits  0-15 = cos(c)
  addq.w  #mvb_rotation_z_angle_speed,d1 ;nächster Z-Winkel
  IFEQ sine_table_length-512
    and.w   d3,d1            ;Übertrag entfernen
  ELSE
    cmp.w   d3,d1            ;360 Grad erreicht ?
    blt.s   mvb_rotation_no_z_angle_restart2
    sub.w   d3,d1            ;Neustart
mvb_rotation_no_z_angle_restart2
  ENDC
  move.w  d1,mvb_rotation_z_angle(a3) ;Z-Winkel retten
  lea     mvb_object_coordinates(pc),a0 ;Koordinaten der Linien
  lea     mvb_rotation_xyz_coordinates(pc),a1 ;Koord.-Tab.
  move.w  #mvb_rotation_d*8,a4 ;d
  move.w  #mvb_rotation_x_center,a5 ;X-Mittelpunkt
  move.w  #mvb_rotation_y_center,a6 ;Y-Mittelpunkt
  moveq   #mvb_object_points_number-1,d7 ;Anzahl der Punkte
mvb_rotation_loop
  move.w  (a0)+,d0           ;X-Koord.
  move.l  d7,a2              ;Schleifenzähler retten
  move.w  (a0)+,d1           ;Y-Koord.
  move.w  (a0)+,d2           ;Z-Koord.
  ROTATE_X_AXIS
  ROTATE_Y_AXIS
  ROTATE_Z_AXIS
; ** Zentralprojektion und Translation **
  move.w  d2,d3              ;z -> d3
  ext.l   d0                 ;Auf 32 Bit erweitern
  add.w   a4,d3              ;z+d
  MULUF.L mvb_rotation_d,d0,d7 ;x*d  X-Projektion
  ext.l   d1                 ;Auf 32 Bit erweitern
  divs.w  d3,d0              ;x'=(x*d)/(z+d)
  MULUF.L mvb_rotation_d,d1,d7 ;y*d  Y-Projektion
  add.w   a5,d0              ;x' + X-Mittelpunkt
  move.w  d0,(a1)+           ;X-Pos.
  divs.w  d3,d1              ;y'=(y*d)/(z+d)
  add.w   a6,d1              ;y' + Y-Mittelpunkt
  move.w  d1,(a1)+           ;Y-Pos.
  asr.w   #3,d2              ;Z/8
  move.l  a2,d7              ;Schleifenzähler holen
  move.w  d2,(a1)+           ;Z-Pos.
  dbf     d7,mvb_rotation_loop
  movem.l (a7)+,a4-a6
  rts

; ** Form des Objekts ändern **
; -----------------------------
  CNOP 0,4
mvb_morph_object
  tst.w   mvb_morph_state(a3) ;Morphing an ?
  bne.s   mvb_no_morph_object ;Nein -> verzweige
  move.w  mvb_morph_shapes_table_start(a3),d1 ;Startwert
  moveq   #TRUE,d2           ;Koordinatenzähler
  lea     mvb_object_coordinates(pc),a0 ;Aktuelle Objektdaten
  lea     mvb_morph_shapes_table(pc),a1 ;Tabelle mit Adressen der Formen-Tabellen
  move.l  (a1,d1.w*4),a1     ;Zeiger auf Tabelle holen
  MOVEF.W mvb_object_points_number*3-1,d7 ;Anzahl der Koordinaten
mvb_morph_object_loop
  move.w  (a0),d0            ;aktuelle Koordinate lesen
  cmp.w   (a1)+,d0           ;mit Ziel-Koordinate vergleichen
  beq.s   mvb_morph_object_next_coordinate ;Wenn aktuelle Koordinate = Ziel-Koordinate, dann verzweige
  bgt.s   mvb_morph_object_zoom_size ;Wenn aktuelle Koordinate < Ziel-Koordinate, dann Koordinate erhöhen
mvb_morph_object_reduce_size
  addq.w  #mvb_morph_speed,d0 ;aktuelle Koordinate erhöhen
  bra.s   mvb_morph_object_save_coordinate
  CNOP 0,4
mvb_morph_object_zoom_size
  subq.w  #mvb_morph_speed,d0 ;aktuelle Koordinate verringern
mvb_morph_object_save_coordinate
  move.w  d0,(a0)            ;und retten
  addq.w  #1,d2              ;Koordinatenzähler erhöhen
mvb_morph_object_next_coordinate
  addq.w  #2,a0              ;Nächste Koordinate
  dbf     d7,mvb_morph_object_loop

  tst.w   d2                 ;Morphing beendet?
  bne.s   mvb_no_morph_object ;Nein -> verzweige
  addq.w  #1,d1              ;nächster Eintrag in Objekttablelle
  cmp.w   #mvb_morph_shapes_number,d1 ;Ende der Tabelle ?
  IFEQ mvb_morph_loop
    bne.s   mvb_save_morph_shapes_table_start ;Nein -> verzweige
    moveq   #TRUE,d1         ;Neustart
mvb_save_morph_shapes_table_start
  ELSE
    beq.s   mvb_morph_object_disable ;Ja -> verzweige
  ENDC
  move.w  d1,mvb_morph_shapes_table_start(a3) 
  move.w  #mvb_morph_delay,mvb_morph_delay_counter(a3) ;Zähler zurücksetzen
mvb_morph_object_disable
  moveq   #FALSE,d0
  move.w  d0,mvb_morph_state(a3) ;Morhing aus
mvb_no_morph_object
  rts

; ** Z-Koordinaten sortieren **
; -----------------------------
  CNOP 0,4
mvb_quicksort_coordinates
  moveq   #-2,d2             ;Maske, um Bit 0 zu löschen
  lea     mvb_object_coordinates_offsets(pc),a0 ;Zeiger auf XYZ-Offsets-Tabelle
  move.l  a0,a1              ;Zeiger -> a1
  lea     (mvb_object_points_number-1)*2(a0),a2 ;Letzter Eintrag
  move.l  a2,a5
  lea     mvb_rotation_xyz_coordinates(pc),a6 ;Zeiger auf XYZ-Koords
mvb_quicks
  move.l  a5,d0              ;Zeiger auf letzten Eintrag
  add.l   a0,d0              ;Adr. des ersten Eintrags + Adr. des letzten Eintrags
  lsr.l   #1,d0              ;Adresse / 2
  and.b   d2,d0              ;Nur gerade Werte
  move.l  d0,a4              ;Adresse der Mitte der Tabelle -> a4
  move.w  (a4),d1            ;XYZ-Offset lesen
  move.w  4(a6,d1.w*2),d0    ;Z-Wert lesen
mvb_quick
  move.w  (a1)+,d1           ;XYZ-Offset lesen
  cmp.w   4(a6,d1.w*2),d0    ;1. Z-Wert < mittlerer Z-Wert ?
  blt.s   mvb_quick          ;Ja -> weiter
  addq.w  #2,a2              ;nächstes XYZ-Offset
  subq.w  #2,a1              ;Zeiger wieder zurücksetzen
mvb_quick2
  move.w  -(a2),d1           ;XYZ-Offset
  cmp.w   4(a6,d1.w*2),d0    ;vorletzter Z-Wert > mittlerer Z-Wert
  bgt.s   mvb_quick2         ;Ja -> weiter
mvb_quick3
  cmp.l   a2,a1              ;Zeiger auf Ende der Tab > Zeiger auf Anfang der Tab. ?
  bgt.s   mvb_quick4         ;Ja -> verzweige
  move.w  (a2),d1            ;letztes Offset holen
  move.w  (a1),(a2)          ;erstes Offset -> letztes Offset
  subq.w  #2,a2              ;vorletztes Offset
  move.w  d1,(a1)+           ;letztes Offset -> erstes Offset
mvb_quick4
  cmp.l   a2,a1              ;Zeiger auf Anfang <= Zeiger auf Ende der Tab. ?
  ble.s   mvb_quick          ;Ja -> verzweige
  cmp.l   a2,a0              ;Zeiger auf Anfang >= Zeiger auf Ende der Tab. ?
  bge.s   mvb_quick5         ;Ja -> verzweige
  move.l  a5,-(a7)
  move.l  a2,a5              ;Zeiger auf Ende der Tab. -> a5
  move.l  a0,a1
  bsr.s   mvb_quicks
  move.l  (a7)+,a5
mvb_quick5
  cmp.l   a5,a1              ;Zeiger auf Anfang >= Zeiger auf Ende der Tab. ?
  bge.s   mvb_quick6         ;Ja -> verzweige
  move.l  a0,-(a7)
  move.l  a1,a0
  move.l  a5,a2
  bsr.s   mvb_quicks
  move.l  (a7)+,a0
mvb_quick6
  rts

; ** Vektor-Bälle in Playfield kopieren **
; ----------------------------------------
  CNOP 0,4
set_vector_balls
  movem.l a3-a5,-(a7)
  move.l  a7,save_a7(a3)     ;Stackpointer retten
  bsr     mvb_init_balls_blit
  move.w  #BC0F_SRCA+BC0F_SRCB+BC0F_SRCC+BC0F_DEST+NANBC+NABC+ABNC+ABC,d3 ;Minterm D=A+B
  move.w  #(mvb_copy_blit_y_size*64)+(mvb_copy_blit_x_size/16),a4
  move.l  vp2_pf2_construction2(a3),a0
  move.l  (a0),d4
  lea     mvb_object_coordinates_offsets(pc),a0
  lea     mvb_rotation_xyz_coordinates(pc),a1
  move.w  #mvb_z_plane1,a2
  move.w  #mvb_z_plane2,a3
  lea     mvb_image_data,a5  ;Ball-Grafik
  lea     mvb_image_mask,a7  ;Ball-Maske
  MOVEF.W mvb_balls_number-1,d7 ;Anzahl der Bälle
set_vector_balls_loop
  move.w  (a0)+,d0           ;Startwert für XY-Koordinate
  moveq   #TRUE,d5
  movem.w (a1,d0.w*2),d0-d2  ;XYZ lesen
mvb_check_z_plane1
  cmp.w   a2,d2              ;1. Z-Plane ?
  blt.s   mvb_z_plane1_found ;Ja -> verzweige
mvb_check_z_plane2
  cmp.w   a3,d2              ;2. Z-Plane ?
  blt.s   mvb_z_plane2_found ;Ja -> verzweige
mvb_check_z_plane3
  cmp.w   #mvb_z_plane3,d2   ;3. Z-Plane ?
  blt.s   mvb_z_plane3_found ;Ja -> verzweige
  ADDF.W  mvb_image_width,d5
mvb_z_plane3_found
  ADDF.W  mvb_image_width,d5
mvb_z_plane2_found
  ADDF.W  mvb_image_width,d5
mvb_z_plane1_found
  MULUF.W (extra_pf4_plane_width*extra_pf4_depth)/2,d1,d2 ;Y-Offset in Playfield
  ror.l   #4,d0              ;Shift-Bits in richtige Position bringen
  move.l  d5,d6
  add.w   d0,d1              ;+ Y-Offset
  add.l   a5,d5              ;+ Adresse Ball-Grafiken
  MULUF.L 2,d1               ;*2 = XY-Offset
  swap    d0                 ;Shift-Bits holen
  add.l   d4,d1              ;+ Playfield-Adresse
  add.l   a7,d6              ;+ Adresse Ball-Masken
  WAITBLITTER
  move.w  d0,BLTCON1-DMACONR(a6)
  or.w    d3,d0              ;restliche Bits von BLTCON0
  move.w  d0,BLTCON0-DMACONR(a6)
  move.l  d1,BLTCPT-DMACONR(a6) ;Playfield lesen
  move.l  d5,BLTBPT-DMACONR(a6) ;Ball-Grafiken
  move.l  d6,BLTAPT-DMACONR(a6) ;Ball-Masken
  move.l  d1,BLTDPT-DMACONR(a6) ;Playfield schreiben
  move.w  a4,BLTSIZE-DMACONR(a6) ;Blitter starten
  dbf     d7,set_vector_balls_loop
  move.w  #DMAF_BLITHOG,DMACON-DMACONR(a6) ;BLTPRI aus
  move.l  variables+save_a7(pc),a7 ;Alter Stackpointer
  movem.l (a7)+,a3-a5
  rts
  CNOP 0,4
mvb_init_balls_blit
  move.w  #DMAF_BLITHOG+DMAF_SETCLR,DMACON-DMACONR(a6) ;BLTPRI an
  WAITBLITTER
  move.w  vb_copy_blit_mask(a3),BLTAFWM-DMACONR(a6) ;Ausmaskierung
  moveq   #TRUE,d0
  move.w  d0,BLTALWM-DMACONR(a6)
  move.l  #((extra_pf4_plane_width-(mvb_image_width+2))<<16)+((mvb_image_width*mvb_image_objects_number)-(mvb_image_width+2)),BLTCMOD-DMACONR(a6) ;C+B-Moduli
  move.l  #(((mvb_image_width*mvb_image_objects_number)-(mvb_image_width+2))<<16)+(extra_pf4_plane_width-(mvb_image_width+2)),BLTAMOD-DMACONR(a6) ;A+D-Moduli
  rts

; ** Y-Positionen der Streifen berechnen **
; -----------------------------------------
  CNOP 0,4
cb_get_stripes_y_coordinates
  move.w  cb_stripes_y_angle(a3),d2 ;1. Y-Winkel
  move.w  d2,d0
  MOVEF.W (sine_table_length/4)-1,d4 ;Überlauf
  subq.w  #cb_stripes_y_angle_speed,d0 ;nächster Y-Winkel
  and.w   d4,d0              ;Überlauf entfernen
  move.w  d0,cb_stripes_y_angle(a3) 
  moveq   #cb_stripes_y_center,d3
  lea     sine_table(pc),a0  
  lea     cb_stripes_y_coordinates(pc),a1 ;Zeiger auf Y-Koordinatentabelle
  moveq   #(cb_stripes_number*cb_stripe_height)-1,d7 ;Anzahl der Zeilen
cb_get_stripes_y_coordinates_loop
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L cb_stripes_y_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  add.w   d3,d0              ;y' + Y-Mittelpunkt
  move.w  d0,(a1)+           
  addq.w  #cb_stripes_y_step,d2 ;nächster Y-Winkel
  and.w   d4,d2              ;Überlauf entfernen
  dbf     d7,cb_get_stripes_y_coordinates_loop
  rts

; ** Farboffsettsabelle initialisieren **
; ---------------------------------------
  CNOP 0,4
cb_make_color_offsets_table
  moveq   #$00000001,d1      ;Farboffset des ersten und zweiten Streifens
  lea     cb_stripes_y_coordinates(pc),a0 ;Zeiger auf Y-Koords
  lea     cb_color_offsets_table(pc),a1 ;Zeiger auf Farboffsetstabelle
  moveq   #cb_stripes_number-1,d7 ;Anzahl der Streifen
cb_make_color_offsets_table_loop1
  moveq   #cb_stripe_height-1,d6 ;Höhe eines Streifens
cb_make_color_offsets_table_loop2
  move.w  (a0)+,d0           ;Y-Offset holen
  move.l  d1,(a1,d0.w*4)     ;Farboffset eintragen
  dbf     d6,cb_make_color_offsets_table_loop2
  swap    d1                 ;Farboffsets vertauschen
  dbf     d7,cb_make_color_offsets_table_loop1
  rts

; ** 3D-Farbverlauf in Copperliste kopieren **
; --------------------------------------------
  CNOP 0,4
cb_move_chessboard
  move.l  a4,-(a7)
  move.w  #$0f0f,d3          ;Maske
  lea     cb_color_offsets_table(pc),a0 ;Zeiger auf Farboffsetstabelle
  move.l  extra_memory(a3),a1
  ADDF.L  em_color_table,a1  ;Zeiger auf Farbtabelle
  move.l  cl2_construction2(a3),a2
  ADDF.W  cl2_extension5_entry+cl2_ext5_COLOR25_high8+2,a2 
  move.w  #cl2_extension5_SIZE,a4
  moveq   #vp3_visible_lines_number-1,d7 ;Anzahl der Zeilen
cb_move_chessboard_loop
  move.w  (a0)+,d0           ;Farboffset holen
  move.l  (a1,d0.w*4),d0     ;RGB8-Farbwert holen
  move.l  d0,d2              
  RGB8_TO_RGB4HI d0,d1,d3
  move.w  d0,(a2)            ;COLOR29 High-Bits
  RGB8_TO_RGB4LO d2,d1,d3
  move.w  d2,cl2_ext5_COLOR25_low8-cl2_ext5_COLOR25_high8(a2) ;COLOR01 Low-Bits
  add.l   a4,a2              ;nächste Zeile
  move.w  (a0)+,d0           ;Farboffset holen
  move.l  (a1,d0.w*4),d0     ;RGB8-Farbwert holen
  move.l  d0,d2              
  RGB8_TO_RGB4HI d0,d1,d3
  move.w  d0,(cl2_ext5_COLOR26_high8-cl2_ext5_COLOR25_high8)-cl2_extension5_SIZE(a2) ;COLOR02 High-Bits
  RGB8_TO_RGB4LO d2,d1,d3
  move.w  d2,(cl2_ext5_COLOR26_low8-cl2_ext5_COLOR25_high8)-cl2_extension5_SIZE(a2) ;COLOR02 Low-Bits
  addq.w  #8,a1              ;Nächster Farbwert in Farbtabelle
  dbf     d7,cb_move_chessboard_loop
  move.l  (a7)+,a4
  rts


; ** Bars einblenden **
; ---------------------
  CNOP 0,4
bar_fader_in
  tst.w   bfi_state(a3)      ;Bar-Fader-In an ?
  bne.s   no_bar_fader_in    ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  bfi_fader_angle(a3),d2 ;Fader-Winkel holen
  move.w  d2,d0
  ADDF.W  bfi_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   bfi_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
bfi_no_restart_fader_angle
  move.w  d0,bfi_fader_angle(a3) ;Fader-Winkel retten
  MOVEF.W bf_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  ;Sinus-Tabelle
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L bfi_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  bfi_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     bvm_color_table+(bf_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  lea     bfi_color_table+(bf_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W bf_colors_number-1,d7 ;Anzahl der Farben
  bsr     if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,bf_colors_counter(a3) ;Image-Fader-In fertig ?
  bne.s   no_bar_fader_in    ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,bfi_state(a3)   ;Image-Fader-In aus
no_bar_fader_in
  rts

; ** Bars ausblenden **
; ---------------------
  CNOP 0,4
bar_fader_out
  tst.w   bfo_state(a3)      ;Bar-Fader-Out an ?
  bne.s   no_bar_fader_out   ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  bfo_fader_angle(a3),d2 ;Fader-Winkel holen
  move.w  d2,d0
  ADDF.W  bfo_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   bfo_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
bfo_no_restart_fader_angle
  move.w  d0,bfo_fader_angle(a3) ;Fader-Winkel retten
  MOVEF.W bf_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  ;Sinus-Tabelle
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L bfo_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  bfo_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     bvm_color_table+(bf_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  lea     bfo_color_table+(bf_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W bf_colors_number-1,d7 ;Anzahl der Farben
  bsr     if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,bf_colors_counter(a3) ;Image-Fader-Out fertig ?
  bne.s   no_bar_fader_out ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,bfo_state(a3)   ;Image-Fader-Out aus
no_bar_fader_out
  rts

; ** Farbwerte in Copperliste kopieren **
; ---------------------------------------
  COPY_COLOR_TABLE_TO_COPPERLIST bf,bvm,cl1,cl1_COLOR16_high2,cl1_COLOR16_low2

; ** Tempel einblenden **
; -----------------------
  CNOP 0,4
image_fader_in
  tst.w   ifi_state(a3)      ;Image-Fader-In an ?
  bne.s   no_image_fader_in  ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  ifi_fader_angle(a3),d2 ;Fader-Winkel holen
  move.w  d2,d0
  ADDF.W  ifi_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   ifi_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
ifi_no_restart_fader_angle
  move.w  d0,ifi_fader_angle(a3) ;Fader-Winkel retten
  MOVEF.W if_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  ;Sinus-Tabelle
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L ifi_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  ifi_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     vp2_pf1_color_table+(if_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  lea     ifi_color_table+(if_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W if_colors_number-1,d7 ;Anzahl der Farben
  bsr     if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,if_colors_counter(a3) ;Image-Fader-In fertig ?
  bne.s   no_image_fader_in  ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,ifi_state(a3)   ;Image-Fader-In aus
no_image_fader_in
  rts

; ** Tempel ausblenden **
; -----------------------
  CNOP 0,4
image_fader_out
  tst.w   ifo_state(a3)      ;Image-Fader-Out an ?
  bne.s   no_image_fader_out ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  ifo_fader_angle(a3),d2 ;Fader-Winkel holen
  move.w  d2,d0
  ADDF.W  ifo_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   ifo_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
ifo_no_restart_fader_angle
  move.w  d0,ifo_fader_angle(a3) ;Fader-Winkel retten
  MOVEF.W if_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  ;Sinus-Tabelle
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L ifo_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  ifo_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     vp2_pf1_color_table+(if_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  lea     ifo_color_table+(if_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W if_colors_number-1,d7 ;Anzahl der Farben
  bsr.s   if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,if_colors_counter(a3) ;Image-Fader-Out fertig ?
  bne.s   no_image_fader_out ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,ifo_state(a3)   ;Image-Fader-Out aus
no_image_fader_out
  rts

  COLOR_FADER if

; ** Farbwerte in Copperliste kopieren **
; ---------------------------------------
  COPY_COLOR_TABLE_TO_COPPERLIST if,vp2_pf1,cl1,cl1_COLOR01_high1,cl1_COLOR01_low1

; ** Chessboard einblenden **
; ---------------------------
  CNOP 0,4
chessboard_fader_in
  tst.w   cfi_state(a3)      ;Chessboard-Fader-In an ?
  bne.s   no_chessboard_fader_in ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  cfi_fader_angle(a3),d2 ;Fader-Winkel holen
  move.w  d2,d0
  ADDF.W  cfi_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   cfi_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
cfi_no_restart_fader_angle
  move.w  d0,cfi_fader_angle(a3) ;Fader-Winkel retten
  MOVEF.W cf_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  ;Sinus-Tabelle
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L cfi_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  cfi_fader_center,d0 ;+ Fader-Mittelpunkt
  move.l  extra_memory(a3),a0
  ADDF.L  em_color_table+(cf_color_table_offset*LONGWORDSIZE),a0  ;Puffer für Farbwerte
  lea     cfi_color_table+(cf_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W cf_colors_number-1,d7 ;Anzahl der Farben
  bsr     if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,cf_colors_counter(a3) ;Chessboard-Fader-In fertig ?
  bne.s   no_chessboard_fader_in  ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,cfi_state(a3)   ;Chessboard-Fader-In aus
no_chessboard_fader_in
  rts

; ** Chessboard ausblenden **
; ---------------------------
  CNOP 0,4
chessboard_fader_out
  tst.w   cfo_state(a3)      ;Chessboard-Fader-Out an ?
  bne.s   no_chessboard_fader_out ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  cfo_fader_angle(a3),d2 ;Fader-Winkel holen
  move.w  d2,d0
  ADDF.W  cfo_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   cfo_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
cfo_no_restart_fader_angle
  move.w  d0,cfo_fader_angle(a3) ;Fader-Winkel retten
  MOVEF.W cf_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  ;Sinus-Tabelle
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L cfo_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  cfo_fader_center,d0 ;+ Fader-Mittelpunkt
  move.l  extra_memory(a3),a0
  ADDF.L  em_color_table+(cf_color_table_offset*LONGWORDSIZE),a0  ;Puffer für Farbwerte
  lea     cfo_color_table+(cf_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W cf_colors_number-1,d7 ;Anzahl der Farben
  bsr     if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,cf_colors_counter(a3) ;Image-Fader-Out fertig ?
  bne.s   no_chessboard_fader_out ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,cfo_state(a3)   ;Chessboard-Fader-Out aus
no_chessboard_fader_out
  rts

; ** Sprites einblenden **
; ------------------------
  CNOP 0,4
sprite_fader_in
  tst.w   sprfi_state(a3)    ;Sprite-Fader-In an ?
  bne.s   no_sprite_fader_in ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  sprfi_fader_angle(a3),d2 ;Fader-Winkel holen
  move.w  d2,d0
  ADDF.W  sprfi_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   sprfi_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
sprfi_no_restart_fader_angle
  move.w  d0,sprfi_fader_angle(a3) ;Fader-Winkel retten
  MOVEF.W sprf_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  ;Sinus-Tabelle
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L sprfi_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  sprfi_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     spr_color_table+(sprf_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  lea     sprfi_color_table+(sprf_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W sprf_colors_number-1,d7 ;Anzahl der Farben
  bsr     if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,sprf_colors_counter(a3) ;Image-Fader-In fertig ?
  bne.s   no_sprite_fader_in  ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,sprfi_state(a3) ;Sprite-Fader-In aus
no_sprite_fader_in
  rts

; ** Sprites ausblenden **
; ------------------------
  CNOP 0,4
sprite_fader_out
  tst.w   sprfo_state(a3)    ;Sprite-Fader-Out an ?
  bne.s   no_sprite_fader_out ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  sprfo_fader_angle(a3),d2 ;Fader-Winkel holen
  move.w  d2,d0
  ADDF.W  sprfo_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   sprfo_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
sprfo_no_restart_fader_angle
  move.w  d0,sprfo_fader_angle(a3) ;Fader-Winkel retten
  MOVEF.W sprf_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  ;Sinus-Tabelle
  move.l  (a0,d2.w*4),d0     ;sin(w)
  MULUF.L sprfo_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  sprfo_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     spr_color_table+(sprf_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  lea     sprfo_color_table+(sprf_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W sprf_colors_number-1,d7 ;Anzahl der Farben
  bsr     if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,sprf_colors_counter(a3) ;Image-Fader-Out fertig ?
  bne.s   no_sprite_fader_out ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,sprfo_state(a3) ;Sprite-Fader-Out aus
no_sprite_fader_out
  rts

; ** Farbwerte in Copperliste kopieren **
; ---------------------------------------
  COPY_COLOR_TABLE_TO_COPPERLIST sprf,spr,cl1,cl1_COLOR01_high2,cl1_COLOR01_low2

; ** Bälle einblenden **
; ----------------------
  CNOP 0,4
fade_balls_in
  tst.w   fbi_state(a3)      ;Fade-Balls-In an?
  bne.s   no_fade_balls_in   ;Nein -> verzweige
  subq.w  #1,fbi_delay_counter(a3) ;Verzögerungszähler verringrern
  bne.s   no_fade_balls_in   ;Nein -> verzweige
  move.w  #fbi_delay,fbi_delay_counter(a3) ;Zähler zurücksetzen
  move.w  vb_copy_blit_mask(a3),d0 ;Aktuelle Maske
  move.w  fb_mask(a3),d1     ;2. Maske
  eor.w   d1,d0              ;Masken miteinander verknüpfen
  move.w  d0,vb_copy_blit_mask(a3)
  cmp.w   #FALSEW,d0         ;Maske fertig?
  beq.s   fbi_finished       ;Ja -> verzweige
  lsr.w   #1,d1              ;2. Maske verschieben
  move.w  d1,fb_mask(a3)     
no_fade_balls_in
  rts
  CNOP 0,4
fbi_finished
  moveq   #FALSE,d0
  move.w  d0,fbi_state(a3)   ;Fade-Balls-In aus
  rts

; ** Bälle ausblenden **
; ----------------------
  CNOP 0,4
fade_balls_out
  tst.w   fbo_state(a3)      ;Fade-Balls-Out an?
  bne.s   no_fade_balls_out  ;Nein -> verzweige
  subq.w  #1,fbo_delay_counter(a3) ;Verzögerungszähler verringern
  bne.s   no_fade_balls_out  ;Nein -> verzweige
  move.w  #fbo_delay,fbo_delay_counter(a3) ;Zähler zurücksetzen
  move.w  vb_copy_blit_mask(a3),d0 ;Aktuelle Maske
  move.w  fb_mask(a3),d1     ;2. Maske
  eor.w   d1,d0              ;Masken verknüpfen
  move.w  d0,vb_copy_blit_mask(a3)
  beq.s   fbo_finished       ;Wenn Maske fertig -> verzweige
  lsr.w   #1,d1              ;2. Maske verschieben
  move.w  d1,fb_mask(a3)     
no_fade_balls_out
  rts
  CNOP 0,4
fbo_finished
  moveq   #FALSE,d0
  move.w  d0,fbo_state(a3)   ;Fade-Balls-Out aus
  rts

; ** Farben überblenden **
; ------------------------
  CNOP 0,4
colors_fader_cross
  tst.w   cfc_state(a3)      ;Colors-Fader-Cross an ?
  bne.s   no_colors_fader_cross ;Nein -> verzweige
  movem.l a4-a6,-(a7)
  move.w  cfc_fader_angle(a3),d2 ;Fader-Winkel holen
  move.w  d2,d0
  ADDF.W  cfc_fader_angle_speed,d0 ;nächster Fader-Winkel
  cmp.w   #sine_table_length/2,d0 ;Y-Winkel <= 180 Grad ?
  ble.s   cfc_no_restart_fader_angle ;Ja -> verzweige
  MOVEF.W sine_table_length/2,d0 ;180 Grad
cfc_no_restart_fader_angle
  move.w  d0,cfc_fader_angle(a3) ;Fader-Winkel retten
  MOVEF.W cfc_colors_number*3,d6 ;Zähler
  lea     sine_table(pc),a0  ;Sinus-Tabelle
  move.l  (a0,d2.w*4),d0    ;sin(w)
  MULUF.L cfc_fader_radius*2,d0,d1 ;y'=(yr*sin(w))/2^15
  swap    d0
  ADDF.W  cfc_fader_center,d0 ;+ Fader-Mittelpunkt
  lea     vp2_pf1_color_table+(cfc_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  lea     cfc_color_table+(cfc_color_table_offset*LONGWORDSIZE)(pc),a1 ;Sollwerte
  move.w  cfc_color_table_start(a3),d1
  MULUF.W LONGWORDSIZE,d1
  lea     (a1,d1.w*8),a1
  move.w  d0,a5              ;Additions-/Subtraktionswert für Blau
  swap    d0                 ;WORDSHIFT
  clr.w   d0                 ;Bits 0-15 löschen
  move.l  d0,a2              ;Additions-/Subtraktionswert für Rot
  lsr.l   #8,d0              ;BYTESHIFT
  move.l  d0,a4              ;Additions-/Subtraktionswert für Grün
  MOVEF.W cfc_colors_number-1,d7 ;Anzahl der Farben
  bsr     if_fader_loop
  movem.l (a7)+,a4-a6
  move.w  d6,cfc_colors_counter(a3) ;Color-Fader-Cross fertig ?
  bne.s   no_colors_fader_cross ;Nein -> verzweige
  moveq   #FALSE,d0
  move.w  d0,cfc_state(a3)   ;Color-Fader-Cross aus
no_colors_fader_cross
  rts

; ** Farbwerte in Copperliste kopieren **
; ---------------------------------------
  CNOP 0,4
cfc_copy_color_table
  IFNE cl1_size2
    move.l  a4,-(a7)
  ENDC
  tst.w   cfc_copy_colors_state(a3)  ;Kopieren der Farbwerte beendet ?
  bne.s   cfc_no_copy_color_table ;Ja -> verzweige
  move.w  #$0f0f,d3          ;Maske für RGB-Nibbles
  IFGT cfc_colors_number-32
    moveq   #cfc_start_xolor*8,d4 ;Color-Bank Farbregisterzähler
  ENDC
  lea     vp2_pf1_color_table+(cfc_color_table_offset*LONGWORDSIZE)(pc),a0 ;Puffer für Farbwerte
  move.l  cl1_display(a3),a1 
  ADDF.W  cl1_COLOR17_high1+2,a1
  IFNE cl1_size1
    move.l  cl1_construction1(a3),a2 
    ADDF.W  cl1_COLOR17_high1+2,a2
  ENDC
  IFNE cl1_size2
    move.l  cl1_construction2(a3),a4 
    ADDF.W  cl1_COLOR17_high1+2,a4
  ENDC
  MOVEF.W cfc_colors_number-1,d7 ;Anzahl der Farben
cfc_copy_color_table_loop
  move.l  (a0)+,d0           ;RGB8-Farbwert
  move.l  d0,d2              
  RGB8_TO_RGB4HI d0,d1,d3
  move.w  d0,(a1)            ;COLORxx High-Bits
  IFNE cl1_size1
    move.w  d0,(a2)          ;COLORxx High-Bits
  ENDC
  IFNE cl1_size2
    move.w  d0,(a4)          ;COLORxx High-Bits
  ENDC
  RGB8_TO_RGB4LO d2,d1,d3
  move.w  d2,cl1_COLOR17_low1-cl1_COLOR17_high1(a1) ;Low-Bits COLORxx
  addq.w  #4,a1              ;nächstes Farbregister
  IFNE cl1_size1
    move.w  d2,cl1_COLOR17_low1-cl1_COLOR17_high1(a2) ;Low-Bits COLORxx
    addq.w  #4,a2            ;nächstes Farbregister
  ENDC
  IFNE cl1_size2
    move.w  d2,cl1_COLOR17_low1-cl1_COLOR17_high1(a4) ;Low-Bits COLORxx
    addq.w  #4,a4            ;nächstes Farbregister
  ENDC
  IFGT cfc_colors_number-32
    addq.b  #1*8,d4          ;Farbregister-Zähler erhöhen
    bne.s   cfc_no_restart_color_bank ;Nein -> verzweige
    addq.w  #4,a1            ;CMOVE überspringen
    IFNE cl1_size1
      addq.w  #4,a2          ;CMOVE überspringen
    ENDC
    IFNE cl1_size2
      addq.w  #4,a4          ;CMOVE überspringen
    ENDC
cfc_no_restart_color_bank
  ENDC
  dbf     d7,cfc_copy_color_table_loop
  tst.w   cfc_colors_counter(a3) ;Fading beendet ?
  bne.s   cfc_no_copy_color_table ;Nein -> verzweige
cfc_disable_copy_color_table
  moveq   #FALSE,d0
  move.w  d0,cfc_copy_colors_state(a3) ;Kopieren beendet
cfc_next_entry
  move.w  #cfc_fader_delay,cfc_fader_delay_counter(a3) ;Zähler zurücksetzen
  move.w  cfc_color_table_start(a3),d0
  addq.w  #1,d0              ;nächste Farbtabelle
  and.w   #cfc_color_tables_number-1,d0 ;Überlauf entfernen
  move.w  d0,cfc_color_table_start(a3)
cfc_no_copy_color_table
  IFNE cl1_size2
    move.l  (a7)+,a4
  ENDC
  rts

; ** Zähler kontrollieren **
; --------------------------
  CNOP 0,4
control_counters
  move.w  mvb_morph_delay_counter(a3),d0
  bmi.s   mvb_morph_no_delay_counter ;Wenn Zähler negativ -> verzweige
  subq.w  #1,d0
  bpl.s   mvb_morph_save_delay_counter ;Wenn Zähler positiv -> verzweige
mvb_morph_enable
  clr.w   mvb_morph_state(a3) ;Morphing an
mvb_morph_save_delay_counter
  move.w  d0,mvb_morph_delay_counter(a3) 
mvb_morph_no_delay_counter

  move.w  cfc_fader_delay_counter(a3),d0
  bmi.s   cfc_no_fader_delay_counter ;Wenn Zähler negativ -> verzweige
  subq.w  #1,d0
  bpl.s   cfc_save_fader_delay_counter ;Wenn Zähler positiv -> verzweige
cfc_fader_enable
  move.w  #cfc_colors_number*3,cfc_colors_counter(a3)
  moveq   #TRUE,d1
  move.w  d1,cfc_copy_colors_state(a3)
  move.w  d1,cfc_state(a3)
  move.w  #sine_table_length/4,cfc_fader_angle(a3) ;90 Grad
cfc_save_fader_delay_counter
  move.w  d0,cfc_fader_delay_counter(a3) 
cfc_no_fader_delay_counter
  rts


; ** Mouse-Handler **
; -------------------
  CNOP 0,4
mouse_handler
  btst    #CIAB_GAMEPORT0,CIAPRA(a4) ;Linke Maustaste gedrückt ?
  beq.s   mh_quit            ;Ja -> verzweige
  rts
  CNOP 0,4
mh_quit
  moveq   #FALSE,d1
  move.w  d1,pt_trigger_fx_state(a3) ;FX-Abfrage aus
  moveq   #TRUE,d0
  tst.w   hst_state(a3)      ;Scrolltext aktiv ?
  beq.s   mh_quit_with_scrolltext ;Ja -> verzweige
mh_quit_without_scrolltext
  move.w  d0,pt_fade_out_music_state(a3) ;Musik ausfaden

  tst.w   fbi_state(a3)      ;Fade-Balls-In aktiv ?
  bne.s   mh_skip1           ;Nein -> verzweige
  move.w  d1,fbi_state(a3)   ;Fade-Balls-In aus
mh_skip1
  tst.w   vb_copy_blit_mask(a3)
  beq.s   skip2
  move.w  d0,fbo_state(a3)   ;Fade-Balls-Out an
  move.w  #fbo_delay,fbo_delay_counter(a3)
  move.w  #$8888,fb_mask(a3)
skip2

  move.w  #sprf_colors_number*3,sprf_colors_counter(a3)
  tst.w   sprfi_state(a3)    ;Sprite-Fader-In aktiv ?
  bne.s   mh_skip3           ;Nein -> verzweige
  move.w  d1,sprfi_state(a3) ;Sprite-Fader-In aus
mh_skip3
  move.w  d0,sprfo_state(a3) ;Sprite-Fader-Out an
  move.w  d0,sprf_copy_colors_state(a3) ;Kopieren der Farben an

  move.w  #if_colors_number*3,if_colors_counter(a3)
  tst.w   ifi_state(a3)      ;Image-Fader-In aktiv ?
  bne.s   mh_skip4           ;Nein -> verzweige
  move.w  d1,ifi_state(a3)   ;Image-Fader-In aus
mh_skip4
  move.w  d0,ifo_state(a3)   ;Image-Fader-Out an
  move.w  d0,if_copy_colors_state(a3) ;Kopieren der Farben an

  tst.w   cfi_state(a3)      ;Chessboard-Fader-In aktiv ?
  bne.s   mh_skip5           ;Nein -> verzweige
  move.w  d1,cfi_state(a3)   ;Chessboard-Fader-In aus
mh_skip5
  move.w  d0,cfo_state(a3)   ;Chessboard-Fader-Out an

  move.w  #bf_colors_number*3,bf_colors_counter(a3)
  tst.w   bfi_state(a3)      ;Bar-Fader-In aktiv ?
  bne.s   mh_skip6           ;Nein -> verzweige
  move.w  d1,bfi_state(a3)   ;Bar-Fader-In aus
mh_skip6
  move.w  d0,bfo_state(a3)   ;Bar-Fader-Out an
  move.w  d0,bf_copy_colors_state(a3) ;Kopieren der Farben an

  rts
  CNOP 0,4
mh_quit_with_scrolltext
  moveq   #hst_horiz_scroll_speed2,d2
  move.w  d2,hst_variable_horiz_scroll_speed(a3) ;Doppelte Geschwindigkeit für Laufschrift
  move.w  #hst_stop_text-hst_text,hst_text_table_start(a3) ;Scrolltext beenden
  move.w  d0,quit_state(a3)  ;Intro soll nach Text-Stopp beendet werden
  rts


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
    PT_FADE_OUT fx_state

    CNOP 0,4
  ENDC

; ** PT-replay routine **
; -----------------------
  IFD pt_v2.3a
    PT2_REPLAY pt_trigger_fx
  ENDC
  IFD pt_v3.0b
    PT3_REPLAY pt_trigger_fx
  ENDC

;--> 8xy "Not used/custom" <--
  CNOP 0,4
pt_trigger_fx
  tst.w   pt_trigger_fx_state(a3) ;Check enabled?
  bne.s   pt_no_trigger_fx   ;No -> skip
  move.b  n_cmdlo(a2),d0     ;Get command data x = Effekt y = TRUE/FALSE
  cmp.b   #$01,d0
  beq.s   pt_disable_trigger_fx
  cmp.b   #$10,d0
  beq.s   pt_start_fade_bars_in
  cmp.b   #$20,d0
  beq.s   pt_start_image_fader_in
  cmp.b   #$30,d0
  beq.s   pt_start_fade_chessboard_in
  cmp.b   #$40,d0
  beq.s   pt_start_fade_sprites_in
  cmp.b   #$50,d0
  beq.s   pt_start_fade_balls_in
  cmp.b   #$60,d0
  beq.s   pt_start_colors_fader_scross
  cmp.b   #$70,d0
  beq.s   pt_start_scrolltext
pt_no_trigger_fx
  rts
  CNOP 0,4
pt_disable_trigger_fx
  moveq   #FALSE,d0
  move.w  d0,pt_trigger_fx_state(a3) ;8xy-Abfrage aus
  rts
  CNOP 0,4
pt_start_fade_bars_in
  move.w  #bf_colors_number*3,bf_colors_counter(a3)
  moveq   #TRUE,d0
  move.w  d0,bfi_state(a3)   ;Bar-Fader-In an
  move.w  d0,bf_copy_colors_state(a3) ;Kopieren der Farben an
  rts
  CNOP 0,4
pt_start_image_fader_in
  move.w  #if_colors_number*3,if_colors_counter(a3)
  moveq   #TRUE,d0
  move.w  d0,ifi_state(a3)   ;Image-Fader-In an
  move.w  d0,if_copy_colors_state(a3) ;Kopieren der Farben an
  rts
  CNOP 0,4
pt_start_fade_chessboard_in
  clr.w   cfi_state(a3)      ;Chessboard-Fader-In an
  rts
  CNOP 0,4
pt_start_fade_sprites_in
  move.w  #sprf_colors_number*3,sprf_colors_counter(a3)
  moveq   #TRUE,d0
  move.w  d0,sprfi_state(a3) ;Sprite-Fader-In an
  move.w  d0,sprf_copy_colors_state(a3) ;Kopieren der Farben an
  rts
  CNOP 0,4
pt_start_fade_balls_in
  clr.w   fbi_state(a3)
  move.w  #fbi_delay,fbi_delay_counter(a3)
  rts
  CNOP 0,4
pt_start_colors_fader_scross
  move.w  #cfc_fader_delay,cfc_fader_delay_counter(a3) ;Zähler zurücksetzen
  rts
  CNOP 0,4
pt_start_scrolltext
  clr.w   hst_state(a3)      ;Laufschrift an
  rts

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

; ** Farben der Playfields **
; ---------------------------
; **** View ****
  CNOP 0,4
pf1_color_table
  DC.L COLOR00BITS
; **** Viewport 2 ****
vp2_pf1_color_table
  REPT vp2_visible_lines_number
    DC.L COLOR00BITS
  ENDR
vp2_pf2_color_table
  REPT vp2_pf2_colors_number*2
    DC.L COLOR00BITS
  ENDR
; **** Viewport 3 ****
vp3_pf1_color_table
    DC.L COLOR00BITS
  REPT vp3_pf1_colors_number-1
    DC.L $000000
  ENDR

; ** Farben der Sprites **
; ------------------------
spr_color_table
  REPT spr_colors_number
    DC.L COLOR00BITS
  ENDR

; ** Adressen der Sprites **
; --------------------------
spr_pointers_display
  DS.L spr_number

; ** Sinus / Cosinustabelle **
; ----------------------------
  CNOP 0,2
sine_table
  INCLUDE "sine-table-512x32.i"

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

; ** Pointers to priod tables for different tuning **
; ---------------------------------------------------
  INCLUDE "music-tracker/pt-finetune-starts-table.i"

; **** Horiz-Scrolltext ****
hst_fill_color_gradient
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/24-Colorgradient.ct"

hst_outline_color_gradient
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/26-Colorgradient2.ct"

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
  REPT spr_colors_number*(bvm_bar_height/2)*bvm_bars_number
    DC.L COLOR00BITS
  ENDR

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

; **** Morp-Vector-Balls ****
; ** Objektdaten **
; -----------------
  CNOP 0,2
mvb_object_coordinates
; * Zoom-In *
  DS.W mvb_object_points_number*3

; ** Formen des Objekts **
; ------------------------
; ** Form 1 **
mvb_object_shape1_coordinates
; * "R" *
  DC.W -(69*8),-(32*8),25*8   ;P0
  DC.W -(69*8),-(19*8),25*8   ;P1
  DC.W -(69*8),-(6*8),25*8    ;P2
  DC.W -(69*8),6*8,25*8       ;P3
  DC.W -(69*8),19*8,25*8      ;P4

  DC.W -(57*8),-(32*8),25*8   ;P5
  DC.W -(57*8),-(6*8),25*8    ;P6

  DC.W -(44*8),-(25*8),25*8   ;P6
  DC.W -(44*8),-(13*8),25*8   ;P8
  DC.W -(44*8),6*8,25*8       ;P9
  DC.W -(44*8),19*8,25*8      ;P10

; * "S" *
  DC.W -(19*8),-(25*8),25*8   ;P11
  DC.W -(19*8),-(13*8),25*8   ;P12
  DC.W -(19*8),19*8,25*8      ;P13

  DC.W -(6*8),-(32*8),25*8    ;P13
  DC.W -(6*8),-(6*8),25*8     ;P15
  DC.W -(6*8),19*8,25*8       ;P16

  DC.W 6*8,-(32*8),25*8       ;P16
  DC.W 6*8,0,25*8             ;P18
  DC.W 6*8,13*8,25*8          ;P19

; * "E" *
  DC.W 32*8,-(32*8),25*8      ;P20
  DC.W 32*8,-(19*8),25*8      ;P19
  DC.W 32*8,-(6*8),25*8       ;P22
  DC.W 32*8,6*8,25*8          ;P23
  DC.W 32*8,19*8,25*8         ;P24

  DC.W 44*8,-(32*8),25*8      ;P25
  DC.W 44*8,-(6*8),25*8       ;P26
  DC.W 44*8,19*8,25*8         ;P26

  DC.W 57*8,-(32*8),25*8      ;P25
  DC.W 57*8,19*8,25*8         ;P29

; ** Form 2 **
mvb_object_shape2_coordinates
; * "3" *
  DC.W -(44*8),-(44*8),25*8   ;P0
  DC.W -(38*8),-(6*8),25*8    ;P1
  DC.W -(44*8),32*8,25*8      ;P2

  DC.W -(32*8),-(44*8),25*8   ;P3
  DC.W -(25*8),-(6*8),25*8    ;P4
  DC.W -(32*8),32*8,25*8      ;P5

  DC.W -(19*8),-(44*8),25*8   ;P6
  DC.W -(13*8),-(32*8),25*8   ;P6
  DC.W -(13*8),-(19*8),25*8   ;P8
  DC.W -(13*8),-(6*8),25*8    ;P9
  DC.W -(13*8),6*8,25*8       ;P10
  DC.W -(13*8),19*8,25*8      ;P11
  DC.W -(19*8),32*8,25*8      ;P12

; * "0" *
  DC.W 13*8,-(44*8),25*8      ;P13
  DC.W 6*8,-(32*8),25*8       ;P13
  DC.W 6*8,-(19*8),25*8       ;P15
  DC.W 6*8,-(6*8),25*8        ;P16
  DC.W 6*8,6*8,25*8           ;P16
  DC.W 6*8,19*8,25*8          ;P18
  DC.W 13*8,32*8,25*8         ;P19

  DC.W 25*8,-(44*8),25*8      ;P20
  DC.W 25*8,32*8,25*8         ;P19

  DC.W 38*8,-(44*8),25*8      ;P22
  DC.W 44*8,-(32*8),25*8      ;P23
  DC.W 44*8,-(19*8),25*8      ;P24
  DC.W 44*8,-(6*8),25*8       ;P25
  DC.W 44*8,6*8,25*8          ;P26
  DC.W 44*8,19*8,25*8         ;P26
  DC.W 38*8,32*8,25*8         ;P25

  DC.W 38*8,32*8,25*8         ;P29 überzählig

  IFNE mvb_morph_loop
; ** Form 3 **
mvb_object_shape3_coordinates
; * Zoom-Out *
    DS.W mvb_object_points_number*3
  ENDC

; ** Tabelle mit Offsetwerten der XYZ-Koordinaten **
; --------------------------------------------------
mvb_object_coordinates_offsets
  DS.W mvb_object_points_number

; ** Tabelle mit XYZ-Koordinaten **
; ---------------------------------
mvb_rotation_xyz_coordinates
  DS.W mvb_object_points_number*4

; ** Tabelle mit Adressen der Objekttabellen **
; ---------------------------------------------
  CNOP 0,4
mvb_morph_shapes_table
  DS.B mvb_morph_shape_SIZE*mvb_morph_shapes_number

; **** Chessboard ****
; ** Farbverläufe **
; ------------------
cb_color_gradient1
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/48-Colorgradient1.ct"

cb_color_gradient2
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/48-Colorgradient2.ct"

; ** Füllmuster **
; ----------------
  CNOP 0,2
cb_fill_pattern
  DC.W $ffff,$0000,$0000,$ffff

; ** Y-Koordinaten der Streifen **
; --------------------------------
cb_stripes_y_coordinates
  DS.W cb_stripe_height*cb_stripes_number

; ** Farboffsets **
; -----------------
cb_color_offsets_table
  DS.W cb_stripe_height*cb_stripes_number*2

; **** Bar-Fader ****
; ** Zielfarbwerte für Bar-Fader-In **
; ------------------------------------
  CNOP 0,4
bfi_color_table
  DS.L spr_colors_number*(bvm_bar_height/2)*bvm_bars_number

; ** Zielfarbwerte für Bar-Fader-Out **
; -------------------------------------                                           p
bfo_color_table
  REPT spr_colors_number*(bvm_bar_height/2)*bvm_bars_number
    DC.L COLOR00BITS
  ENDR

; ** Puffer für Farbwerte **
; --------------------------
bf_color_cache
  REPT spr_colors_number*(bvm_bar_height/2)*bvm_bars_number
    DC.L COLOR00BITS
  ENDR

; **** Image-Fader ****
; ** Zielfarbwerte für Image-Fader-In **
; --------------------------------------
  CNOP 0,4
ifi_color_table
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/320x182x16-Temple2.ct"

; ** Zielfarbwerte für Image-Fader-Out **
; ---------------------------------------
ifo_color_table
  REPT vp2_pf1_colors_number
    DC.L COLOR00BITS
  ENDR

; **** Chessboard-Fader ****
; ** Zielfarbwerte für Chessboard-Fader-In **
; -------------------------------------------
  CNOP 0,4
cfi_color_table
  REPT vp3_visible_lines_number*2
    DC.L COLOR00BITS
  ENDR

; ** Zielfarbwerte für Chessboard-Fader-Out **
; --------------------------------------------                                           p
cfo_color_table
  REPT vp3_visible_lines_number*2
    DC.L COLOR00BITS
  ENDR

; **** Sprite-Fader ****
; ** Zielfarbwerte für Sprite-Fader-In **
; ---------------------------------------
  CNOP 0,4
sprfi_color_table
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/256x208x16-Desert-Sunset2.ct"

; ** Zielfarbwerte für Sprite-Fader-Out **
; ----------------------------------------
sprfo_color_table
  REPT spr_colors_number
    DC.L COLOR00BITS
  ENDR

; **** Color-Fader-Cross ****
; ** Zielfarbwerte für Color-Fader-Cross **
; -----------------------------------------
  CNOP 0,4
cfc_color_table
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/4x16x11x8-Balls4.ct"
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/4x16x11x8-Balls6.ct"
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/4x16x11x8-Balls5.ct"
  INCLUDE "Daten:Asm-Sources.AGA/30/colortables/4x16x11x8-Balls7.ct"



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
prg_version DC.B "$VER: RSE-30 1.1 beta (2.6.24)",TRUE
  EVEN

; **** Horiz-Scrolltext ****
; ** Text für Laufschrift **
; --------------------------
hst_text
  REPT (hst_text_characters_number/(hst_origin_character_x_size/hst_text_character_x_size))+1
    DC.B " "
  ENDR

  DC.B "RESISTANCE CELEBRATES THE 30TH ANNIVERSARY!   "
  DC.B " "

hst_stop_text
  REPT (hst_text_characters_number/(hst_origin_character_x_size/hst_text_character_x_size))+1
    DC.B " "
  ENDR
  DC.B " "
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

; **** Background-Image-1 ****
bg1_image_data SECTION bg1_gfx,DATA
  INCBIN "Daten:Asm-Sources.AGA/30/graphics/256x208x16-Desert-Sunset2.rawblit"

; **** Background-Image-2 ****
bg2_image_data SECTION bg2_gfx,DATA
  INCBIN "Daten:Asm-Sources.AGA/30/graphics/320x182x16-Temple2.rawblit"

; **** Horiz-Scrolltext ****
hst_image_data SECTION hst_gfx,DATA_C
  INCBIN "Daten:Asm-Sources.AGA/30/fonts/32x26x4-Font.rawblit"

; **** Morph-Vector-Balls ****
mvb_image_data SECTION mvb_gfx1,DATA_C
  INCBIN "Daten:Asm-Sources.AGA/30/graphics/4x16x11x8-Balls.rawblit"

mvb_image_mask SECTION mvb_gfx2,DATA_C
  INCBIN "Daten:Asm-Sources.AGA/30/graphics/4x16x11x8-Balls.mask"

  END
