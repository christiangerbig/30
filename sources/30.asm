; Programm:	30
; Autor:	Christian Gerbig
; Datum:	15.07.2024
; Version:	1.4 beta

; Requirements
; CPU:		68020+
; Fast-Memory:	nein
; Chipset:	AGA
; OS:		3.0+


; History / Changes

; V.1.0 beta
; - First release

; V.1.1 beta
; - CWAIT für VP2 korrigiert, damit der Farbverlauf des Schachbretts für die
;	erste Zeile noch innerhalb der horizontalen Austastlücke erfolgt.
; - VP1 nutzt jetzt COLOR28-31
;	VP3 nutzt jetzt COLOR16-23 für P1 und COLOR24-28 für PF2
; - Die Farben für VP1/PF1 und VP3/PF2 werden nicht mehr vom Copper separat
;	initialisiert, da die Farbverläufe für VP1 und VP3 sowieso zeilenweise
;	initialisiert werden. Insgesamt werden nur noch 240 Farben in der verti-
;	kalen Austastlücke initialisiert.
; - Vektor-Bälle: Einblenden und Überblenden zu anderen Farben mit Intervall
;	und Änderung der Z-Koorinaten
; - Nutzung des PT 8xy-Befehls für die Fader-Routinen

; V.1.2 beta
; - Maze's Modul integriert
; - Fader-Cross: Bugfix, es wurde die falsche Puffer-Farbtabelle angesprochen.
; - vp2_pf1 anstatt vp2_pf2
; - Neue Fx-Befehle: 880/890
; - Morphing wird jetzt über den Befehl 890 vom Modul ausgelöst. Delay-Counter
;	ist überflüssig.
; - Sprite-Fader-In: Timing geändert

; V.1.3 beta
; - Laufschrift setzt jetzt später ein
; - Das Schachbrett steht erst still und wird dabb später animiert
; - Neuer Fx-Befehl: 8a0

; V.1.4 beta
; - FX-Befele überarbeitet
; - 880 Enable Skip-Commands
; - 89n Set-Chessboars-Speed: Schachbrett steht erst still und bewegt sich,
;   wenn sich die Musik ändert. Es wird langsamer, wenn die Musik langsamer
;   wird

; V.1.5 beta
; - Crossfader: Überblenden verlangsamt
; - Mit Grass' Tempel + Sonnenaufgangs-Grafiken
; - Credits hinzugefügt
; - Farbverlauf des Scrolltexts geändert


; PT 8xy-Befehl
; 810 Start-Fade-Bars-In
; 820 Start-Fade-Image-In (Tempel)
; 830 Start-Fade-Chessboard-In
; 840 Start-Fade-Sprites-In
; 850 Start-Fade-Balls-In
; 860 Start-Fade-Cross
; 870 Start-Scrolltext
; 880 Enable Skip-Commands
; 89n Set-Chessboars-Speed
; 8a0 Trigger-Morphing

; Ausführungszeit 68020: 187 Rasterzeilen


	SECTION code_and_variables,CODE

	MC68040


	INCDIR "Daten:include3.5/"

	INCLUDE "exec/exec.i"
	INCLUDE "exec/exec_lib.i"

	INCLUDE "dos/dos.i"
	INCLUDE "dos/dos_lib.i"
	INCLUDE "dos/dosextens.i"

	INCLUDE "graphics/gfxbase.i"
	INCLUDE "graphics/graphics_lib.i"
	INCLUDE "graphics/videocontrol.i"

	INCLUDE "intuition/intuition.i"
	INCLUDE "intuition/intuition_lib.i"

	INCLUDE "libraries/any_lib.i"

	INCLUDE "resources/cia_lib.i"

	INCLUDE "hardware/adkbits.i"
	INCLUDE "hardware/blit.i"
	INCLUDE "hardware/cia.i"
	INCLUDE "hardware/custom.i"
	INCLUDE "hardware/dmabits.i"
	INCLUDE "hardware/intbits.i"


	INCDIR "Daten:Asm-Sources.AGA/normsource-includes/"


PROTRACKER_VERSION_3.0B		SET 1


	INCLUDE "macros.i"


	INCLUDE "equals.i"

requires_030_cpu		EQU FALSE
requires_040_cpu		EQU FALSE
requires_060_cpu		EQU FALSE
requires_fast_memory		EQU FALSE
requires_multiscan_monitor	EQU FALSE

workbench_start_enabled		EQU FALSE
screen_fader_enabled		EQU FALSE
text_output_enabled		EQU FALSE

pt_ciatiming_enabled		EQU TRUE
pt_finetune_enabled		EQU FALSE
pt_metronome_enabled		EQU FALSE
pt_mute_enabled			EQU FALSE
pt_track_volumes_enabled	EQU TRUE
pt_track_periods_enabled	EQU FALSE
pt_music_fader_enabled		EQU TRUE
pt_split_module_enabled		EQU TRUE
pt_usedfx			EQU %1101010101011110
pt_usedefx			EQU %0000001001000000

mvb_premorph_enabled		EQU TRUE
mvb_morph_loop_enabled		EQU TRUE

cfc_rgb8_prefade_enabled	EQU TRUE

dma_bits			EQU DMAF_SPRITE+DMAF_COPPER+DMAF_BLITTER+DMAF_RASTER+DMAF_MASTER+DMAF_SETCLR

	IFEQ pt_ciatiming_enabled
intena_bits			EQU INTF_EXTER+INTF_INTEN+INTF_SETCLR
	ELSE
intena_bits			EQU INTF_VERTB+INTF_EXTER+INTF_INTEN+INTF_SETCLR
	ENDC

ciaa_icr_bits			EQU CIAICRF_SETCLR
	IFEQ pt_ciatiming_enabled
ciab_icr_bits			EQU CIAICRF_TA+CIAICRF_TB+CIAICRF_SETCLR
	ELSE
ciab_icr_bits			EQU CIAICRF_TB+CIAICRF_SETCLR
	ENDC

copcon_bits			EQU 0

pf1_x_size1			EQU 0
pf1_y_size1			EQU 0
pf1_depth1			EQU 0
pf1_x_size2			EQU 0
pf1_y_size2			EQU 0
pf1_depth2			EQU 0
pf1_x_size3			EQU 0
pf1_y_size3			EQU 0
pf1_depth3			EQU 0
pf1_colors_number		EQU 240

pf2_x_size1			EQU 0
pf2_y_size1			EQU 0
pf2_depth1			EQU 0
pf2_x_size2			EQU 0
pf2_y_size2			EQU 0
pf2_depth2			EQU 0
pf2_x_size3			EQU 0
pf2_y_size3			EQU 0
pf2_depth3			EQU 0
pf2_colors_number		EQU 0
pf_colors_number		EQU pf1_colors_number+pf2_colors_number
pf_depth			EQU pf1_depth3+pf2_depth3

pf_extra_number			EQU 8
; **** Viewport 1 ****
; ** Playfield 1 **
extra_pf1_x_size		EQU 384
extra_pf1_y_size		EQU 26
extra_pf1_depth			EQU 2
extra_pf2_x_size		EQU 384
extra_pf2_y_size		EQU 26
extra_pf2_depth			EQU 2
; **** Viewport 2 ****
; ** Playfield 1 **
extra_pf3_x_size		EQU 320
extra_pf3_y_size		EQU 182
extra_pf3_depth			EQU 4
; ** Playfield 2 **
extra_pf4_x_size		EQU 320
extra_pf4_y_size		EQU 182
extra_pf4_depth			EQU 3
extra_pf5_x_size		EQU 320
extra_pf5_y_size		EQU 182
extra_pf5_depth			EQU 3
extra_pf6_x_size		EQU 320
extra_pf6_y_size		EQU 182
extra_pf6_depth			EQU 3
; **** Viewport 3 ****
extra_pf7_x_size		EQU 960
extra_pf7_y_size		EQU 1
extra_pf7_depth			EQU 2
; ** Playfield 2 **
extra_pf8_x_size		EQU 320
extra_pf8_y_size		EQU 48
extra_pf8_depth			EQU 2

spr_number			EQU 8
spr_x_size1			EQU 0
spr_x_size2			EQU 64
spr_depth			EQU 2
spr_colors_number		EQU 16
spr_odd_color_table_select	EQU 2
spr_even_color_table_select	EQU 2
spr_used_number			EQU 8

	IFD PROTRACKER_VERSION_2.3A 
audio_memory_size		EQU 0
	ENDC
	IFD PROTRACKER_VERSION_3.0B
audio_memory_size		EQU 1*WORD_SIZE
	ENDC

disk_memory_size		EQU 0

chip_memory_size		EQU 0
	IFEQ pt_ciatiming_enabled
ciab_cra_bits			EQU CIACRBF_LOAD
	ENDC
ciab_crb_bits			EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;Oneshot mode
ciaa_ta_time			EQU 0
ciaa_tb_time			EQU 0
	IFEQ pt_ciatiming_enabled
ciab_ta_time			EQU 14187 ; = 0.709379 MHz * [20000 µs = 50 Hz duration for one frame on a PAL machine]
;ciab_ta_time			EQU 14318 ; = 0.715909 MHz * [20000 µs = 50 Hz duration for one frame on a NTSC machine]
	ELSE
ciab_ta_time			EQU 0
	ENDC
ciab_tb_time			EQU 362	; = 0.709379 MHz * [511.43 µs = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
					; = 0.715909 MHz * [506.76 µs = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
ciaa_ta_continuous_enabled	EQU FALSE
ciaa_tb_continuous_enabled	EQU FALSE
	IFEQ pt_ciatiming_enabled
ciab_ta_continuous_enabled	EQU TRUE
	ELSE
ciab_ta_continuous_enabled	EQU FALSE
	ENDC
ciab_tb_continuous_enabled	EQU FALSE

beam_position			EQU $133 ;Wegen Music-Fader

MINROW				EQU VSTART_256_LINES

display_window_hstart		EQU HSTART_320_PIXEL
display_window_vstart		EQU MINROW
display_window_hstop		EQU HSTOP_320_PIXEL
display_window_vstop		EQU VSTOP_256_LINES

spr_pixel_per_datafetch		EQU 64 ;4x

; **** Viewport 1 ****
vp1_pixel_per_line		EQU 320
vp1_visible_pixels_number	EQU 320
vp1_visible_lines_number	EQU 26

vp1_vstart			EQU MINROW
vp1_vstop			EQU vp1_VSTART+vp1_visible_lines_number

vp1_pf_pixel_per_datafetch	EQU 64	; 4x

vp1_pf1_depth			EQU 2
vp1_pf_depth			EQU vp1_pf1_depth
vp1_pf1_colors_number		EQU 4
vp1_pf_colors_number		EQU vp1_pf1_colors_number

; **** Viewport 2 ****
vp2_pixel_per_line		EQU 320
vp2_visible_pixels_number	EQU 320
vp2_visible_lines_number	EQU 182

vp2_vstart			EQU vp1_VSTOP
vp2_vstop			EQU vp2_VSTART+vp2_visible_lines_number

vp2_pf_pixel_per_datafetch	EQU 64	; 4x

vp2_pf1_depth			EQU 4
vp2_pf2_depth			EQU 3
vp2_pf_depth			EQU vp2_pf1_depth+vp2_pf2_depth
vp2_pf1_colors_number		EQU 16
vp2_pf2_colors_number		EQU 8
vp2_pf_colors_number		EQU vp2_pf1_colors_number+vp2_pf2_colors_number

; **** Viewport 3 ****
vp3_pixel_per_line		EQU 320
vp3_visible_pixels_number	EQU 320
vp3_visible_lines_number	EQU 48

vp3_vstart			EQU vp2_VSTOP
vp3_vstop			EQU vp3_VSTART+vp3_visible_lines_number

vp3_pf_pixel_per_datafetch	EQU 64	; 4x

vp3_pf1_depth			EQU 3
vp3_pf2_depth			EQU 2
vp3_pf_depth			EQU vp3_pf1_depth+vp3_pf2_depth
vp3_pf1_colors_number		EQU 8
vp3_pf2_colors_number		EQU 4
vp3_pf_colors_number		EQU vp3_pf1_colors_number+vp3_pf2_colors_number


; **** Viewport 1 ****
; ** Playfield 1 **
extra_pf1_plane_width		EQU extra_pf1_x_size/8
extra_pf2_plane_width		EQU extra_pf2_x_size/8
; **** Viewport 2 ****
; ** Playfield1 **
extra_pf3_plane_width		EQU extra_pf3_x_size/8
; ** Playfield2 **
extra_pf4_plane_width		EQU extra_pf4_x_size/8
extra_pf5_plane_width		EQU extra_pf5_x_size/8
extra_pf6_plane_width		EQU extra_pf6_x_size/8
; **** Viewport 3 ****
extra_pf7_plane_width		EQU extra_pf7_x_size/8
; ** Playfield2 **
extra_pf8_plane_width		EQU extra_pf8_x_size/8

; **** Viewport 1 ****
vp1_data_fetch_width		EQU vp1_pixel_per_line/8
vp1_pf1_plane_moduli		EQU (extra_pf1_plane_width*(extra_pf1_depth-1))+extra_pf1_plane_width-vp1_data_fetch_width
; **** Viewport 2 ****
vp2_data_fetch_width		EQU vp2_pixel_per_line/8
vp2_pf1_plane_moduli		EQU (extra_pf3_plane_width*(extra_pf3_depth-1))+extra_pf3_plane_width-vp2_data_fetch_width
vp2_pf2_plane_moduli		EQU (extra_pf4_plane_width*(extra_pf4_depth-1))+extra_pf4_plane_width-vp2_data_fetch_width
; **** Viewport 3 ****
vp3_data_fetch_width		EQU vp3_pixel_per_line/8
vp3_pf1_plane_moduli		EQU vp3_data_fetch_width*8
vp3_pf2_plane_moduli		EQU (extra_pf8_plane_width*(extra_pf8_depth-1))+extra_pf8_plane_width-vp3_data_fetch_width

; **** View ****
diwstrt_bits			EQU ((display_window_vstart&$ff)*DIWSTRTF_V0)+(display_window_hstart&$ff)
diwstop_bits			EQU ((display_window_vstop&$ff)*DIWSTOPF_V0)+(display_window_hstop&$ff)
bplcon0_bits			EQU BPLCON0F_ECSENA+((pf_depth>>3)*BPLCON0F_BPU3)+(BPLCON0F_COLOR)+((pf_depth&$07)*BPLCON0F_BPU0)
bplcon3_bits1			EQU BPLCON3F_SPRES0
bplcon3_bits2			EQU bplcon3_bits1|BPLCON3F_LOCT
bplcon4_bits			EQU (BPLCON4F_OSPRM4*spr_odd_color_table_select)|(BPLCON4F_ESPRM4*spr_even_color_table_select)
diwhigh_bits			EQU (((display_window_hstop&$100)>>8)*DIWHIGHF_HSTOP8)|(((display_window_vstop&$700)>>8)*DIWHIGHF_VSTOP8)|(((display_window_hstart&$100)>>8)*DIWHIGHF_HSTART8)|((display_window_vstart&$700)>>8)
fmode_bits			EQU FMODEF_SPR32|FMODEF_SPAGEM|FMODEF_SSCAN2
color00_bits			EQU $001122
color00_high_bits		EQU $012
color00_low_bits		EQU $012
; **** Viewport 1 ****
vp1_ddfstrt_bits		EQU DDFSTART_320_PIXEL
vp1_ddfstop_bits		EQU DDFSTOP_320_PIXEL_4X
vp1_bplcon0_bits		EQU BPLCON0F_ECSENA|((vp1_pf_depth>>3)*BPLCON0F_BPU3)|(BPLCON0F_COLOR)|((vp1_pf_depth&$07)*BPLCON0F_BPU0)
vp1_bplcon1_bits		EQU 0
vp1_bplcon2_bits		EQU 0
vp1_bplcon3_bits1		EQU bplcon3_bits1
vp1_bplcon3_bits2		EQU vp1_bplcon3_bits1|BPLCON3F_LOCT
vp1_bplcon3_bits3		EQU vp1_bplcon3_bits1|(BPLCON3F_BANK0*7)
vp1_bplcon3_bits4		EQU vp1_bplcon3_bits3|BPLCON3F_LOCT
vp1_bplcon4_bits		EQU bplcon4_bits|(BPLCON4F_BPLAM0*252)
vp1_fmode_bits			EQU fmode_bits|FMODEF_BPL32|FMODEF_BPAGEM
vp1_color00_bits		EQU color00_bits
; **** Viewport 2 ****
vp2_ddfstrt_bits		EQU DDFSTART_320_PIXEL
vp2_ddfstop_bits		EQU DDFSTOP_320_PIXEL_4X
vp2_bplcon0_bits		EQU BPLCON0F_ECSENA|((vp2_pf_depth>>3)*BPLCON0F_BPU3)|(BPLCON0F_COLOR)|BPLCON0F_DPF|((vp2_pf_depth&$07)*BPLCON0F_BPU0)
vp2_bplcon1_bits		EQU 0
vp2_bplcon2_bits		EQU BPLCON2F_PF2PRI
vp2_bplcon3_bits1		EQU bplcon3_bits1|BPLCON3F_PF2OF2
vp2_bplcon3_bits2		EQU vp2_bplcon3_bits1|BPLCON3F_LOCT
vp2_bplcon4_bits		EQU bplcon4_bits
vp2_fmode_bits			EQU fmode_bits|FMODEF_BPL32|FMODEF_BPAGEM
vp2_color00_bits		EQU color00_bits
; **** Viewport 3 ****
vp3_ddfstrt_bits		EQU DDFSTART_320_PIXEL
vp3_ddfstop_bits		EQU DDFSTOP_320_PIXEL_4X
vp3_bplcon0_bits		EQU BPLCON0F_ECSENA|((vp3_pf_depth>>3)*BPLCON0F_BPU3)|(BPLCON0F_COLOR)|BPLCON0F_DPF|((vp3_pf_depth&$07)*BPLCON0F_BPU0)
vp3_bplcon1_bits		EQU 0
vp3_bplcon2_bits		EQU 0
vp3_bplcon3_bits1		EQU bplcon3_bits1|BPLCON3F_PF2OF0|BPLCON3F_PF2OF1
vp3_bplcon3_bits2		EQU vp3_bplcon3_bits1|BPLCON3F_LOCT
vp3_bplcon3_bits3		EQU vp3_bplcon3_bits1|(BPLCON3F_BANK0*7)
vp3_bplcon3_bits4		EQU vp3_bplcon3_bits3|BPLCON3F_LOCT
vp3_bplcon4_bits		EQU bplcon4_bits|(BPLCON4F_BPLAM0*240)
vp3_fmode_bits			EQU fmode_bits|FMODEF_BPL32|FMODEF_BPAGEM
vp3_color00_bits		EQU color00_bits

; **** Viewport 1 ****
cl2_vp1_hstart1			EQU $00
cl2_vp1_vstart1			EQU MINROW
cl2_vp1_hstart2			EQU $00
cl2_vp1_vstart2			EQU MINROW
; **** Viewport 2 ****
cl2_vp2_hstart			EQU HSTOP_320_PIXEL-(4*CMOVE_SLOT_PERIOD)
cl2_vp2_vstart			EQU vp1_VSTOP-1
; **** Viewport 3 ****
cl2_vp3_hstart1			EQU HSTOP_320_PIXEL-(9*CMOVE_SLOT_PERIOD)
cl2_vp3_vstart1			EQU vp2_VSTOP-1
cl2_vp3_hstart2			EQU $00
cl2_vp3_vstart2			EQU vp2_VSTOP
; **** Copper-Interrupt ****
cl2_hstart			EQU $00
cl2_vstart			EQU beam_position&$ff

sine_table_length		EQU 512

; **** Background-Image 1 ****
bg1_image_x_size		EQU 256
bg1_image_plane_width		EQU bg1_image_x_size/8
bg1_image_y_size		EQU 208
bg1_image_depth			EQU 4
bg1_image_x_position		EQU 16
bg1_image_y_position		EQU MINROW

; **** Background-Image 2 ****
bg2_image_x_size		EQU 320
bg2_image_plane_width		EQU bg2_image_x_size/8
bg2_image_y_size		EQU 182
bg2_image_depth			EQU 4

; **** Ball-Image ****
mvb_image_x_size		EQU 16
mvb_image_width			EQU mvb_image_x_size/8
mvb_image_y_size		EQU 11
mvb_image_depth			EQU 3
mvb_image_objects_number	EQU 4

; **** PT-Replay ****
pt_fade_out_delay		EQU 2 ;Ticks

; **** Horiz-Scrolltext ****
hst_image_x_size		EQU 320
hst_image_plane_width		EQU hst_image_x_size/8
hst_image_depth			EQU 2
hst_origin_character_x_size	EQU 32
hst_origin_character_y_size	EQU 26

hst_text_character_x_size	EQU 16
hst_text_character_width	EQU hst_text_character_x_size/8
hst_text_character_y_size	EQU hst_origin_character_y_size
hst_text_character_depth	EQU hst_image_depth

hst_horiz_scroll_window_x_size	EQU vp1_visible_pixels_number+hst_text_character_x_size
hst_horiz_scroll_window_width	EQU hst_horiz_scroll_window_x_size/8
hst_horiz_scroll_window_y_size	EQU hst_text_character_y_size
hst_horiz_scroll_window_depth	EQU hst_image_depth
hst_horiz_scroll_speed1		EQU 2
hst_horiz_scroll_speed2		EQU 8

hst_text_character_x_restart	EQU hst_horiz_scroll_window_x_size
hst_text_characters_number	EQU hst_horiz_scroll_window_x_size/hst_text_character_x_size

hst_text_x_position		EQU 32
hst_text_y_position		EQU 0

; **** Bounce-VU-Meter ****
bvm_bar_height			EQU 6
bvm_bars_number			EQU 4
bvm_max_amplitude		EQU vp1_visible_lines_number-bvm_bar_height
bvm_y_centre			EQU vp1_visible_lines_number-bvm_bar_height
bvm_y_angle_speed		EQU 8

; **** Morph-Vector-Balls ****
mvb_balls_number		EQU 30

mvb_rotation_d			EQU 256
mvb_rotation_x_center		EQU (extra_pf4_x_size-mvb_image_x_size)/2
mvb_rotation_y_center		EQU (extra_pf4_y_size-mvb_image_y_size)/2
mvb_rotation_x_angle_speed	EQU 5
mvb_rotation_y_angle_speed	EQU 2
mvb_rotation_z_angle_speed	EQU 2

mvb_object_points_number	EQU mvb_balls_number
	IFEQ mvb_morph_loop_enabled
mvb_morph_shapes_number		EQU 2
	ELSE
mvb_morph_shapes_number		EQU 3
	ENDC
mvb_morph_speed			EQU 8

mvb_observer_z			EQU 35
mvb_z_plane1			EQU -32+mvb_observer_z
mvb_z_plane2			EQU 0+mvb_observer_z
mvb_z_plane3			EQU 32+mvb_observer_z
mvb_z_plane4			EQU 64+mvb_observer_z

mvb_clear_blit_x_size		EQU extra_pf4_x_size
mvb_clear_blit_y_size		EQU extra_pf4_y_size*(extra_pf4_depth-2)

mvb_copy_blit_x_size		EQU mvb_image_x_size+16
mvb_copy_blit_y_size		EQU mvb_image_y_size*mvb_image_depth

; **** Chessboard ****
cb_destination_x_size		EQU vp3_visible_pixels_number
cb_destination_y_size		EQU vp3_visible_lines_number
cb_destination_plane_width_step	EQU 8
cb_destination_x_size_step	EQU cb_destination_plane_width_step/2
cb_source_x_size		EQU vp3_visible_pixels_number+(extra_pf8_y_size*cb_destination_plane_width_step)

cb_x_min			EQU 0
cb_x_max			EQU vp3_visible_pixels_number

cb_stripes_y_radius		EQU vp3_visible_lines_number-1
cb_stripes_y_center		EQU vp3_visible_lines_number-1
cb_stripes_y_step		EQU 1
cb_stripes_y_angle_speed1	EQU 0
cb_stripes_y_angle_speed2	EQU 3
cb_stripes_number		EQU 8
cb_stripe_height		EQU 16

; **** Bar-Fader ****
bf_rgb8_start_color		EQU 16
bf_rgb8_color_table_offset	EQU 0
bf_rgb8_colors_number		EQU spr_colors_number*(bvm_bar_height/2)*bvm_bars_number

; **** Bar-Fader-In ****
bfi_rgb8_fader_speed_max	EQU 6
bfi_rgb8_fader_radius		EQU bfi_rgb8_fader_speed_max
bfi_rgb8_fader_center		EQU bfi_rgb8_fader_speed_max+1
bfi_rgb8_fader_angle_speed	EQU 3

; **** Bar-Fader-Out ****
bfo_rgb8_fader_speed_max	EQU 6
bfo_rgb8_fader_radius		EQU bfo_rgb8_fader_speed_max
bfo_rgb8_fader_center		EQU bfo_rgb8_fader_speed_max+1
bfo_rgb8_fader_angle_speed	EQU 3

; **** Image-Fader ****
if_rgb8_start_color		EQU 1
if_rgb8_color_table_offset	EQU 1
if_rgb8_colors_number		EQU vp2_pf1_colors_number-1

; **** Image-Fader-In ****
ifi_rgb8_fader_speed_max	EQU 8
ifi_rgb8_fader_radius		EQU ifi_rgb8_fader_speed_max
ifi_rgb8_fader_center		EQU ifi_rgb8_fader_speed_max+1
ifi_rgb8_fader_angle_speed	EQU 4

; **** Image-Fader-Out ****
ifo_rgb8_fader_speed_max	EQU 8
ifo_rgb8_fader_radius		EQU ifo_rgb8_fader_speed_max
ifo_rgb8_fader_center		EQU ifo_rgb8_fader_speed_max+1
ifo_rgb8_fader_angle_speed	EQU 3

; **** Chessboard-Fader ****
cf_rgb8_color_table_offset	EQU 0
cf_rgb8_colors_number		EQU vp3_visible_lines_number*2

; **** Chessboard-Fader-In ****
cfi_rgb8_fader_speed_max	EQU 10
cfi_rgb8_fader_radius		EQU cfi_rgb8_fader_speed_max
cfi_rgb8_fader_center		EQU cfi_rgb8_fader_speed_max+1
cfi_rgb8_fader_angle_speed	EQU 6

; **** Chessboard-Fader-Out ****
cfo_rgb8_fader_speed_max	EQU 10
cfo_rgb8_fader_radius		EQU cfo_rgb8_fader_speed_max
cfo_rgb8_fader_center		EQU cfo_rgb8_fader_speed_max+1
cfo_rgb8_fader_angle_speed	EQU 4

; **** Sprite-Fader ****
sprf_rgb8_start_color		EQU 1
sprf_rgb8_color_table_offset	EQU 1
sprf_rgb8_colors_number		EQU spr_colors_number-1

; **** Sprite-Fader-In ****
sprfi_rgb8_fader_speed_max	EQU 1
sprfi_rgb8_fader_radius		EQU sprfi_rgb8_fader_speed_max
sprfi_rgb8_fader_center		EQU sprfi_rgb8_fader_speed_max+1
sprfi_rgb8_fader_angle_speed	EQU 1

; **** Sprite-Fader-Out ****
sprfo_rgb8_fader_speed_max	EQU 8
sprfo_rgb8_fader_radius		EQU sprfo_rgb8_fader_speed_max
sprfo_rgb8_fader_center		EQU sprfo_rgb8_fader_speed_max+1
sprfo_rgb8_fader_angle_speed	EQU 4

; **** Fade-Balls-In ****
fbi_delay			EQU 10

; **** Fade-Balls-Out ****
fbo_delay			EQU 5

; **** Colors-Fader-Cross ****
cfc_rgb8_start_color		EQU 17
cfc_rgb8_color_table_offset	EQU 1
cfc_rgb8_colors_number		EQU vp2_pf2_colors_number-1
cfc_rgb8_color_tables_number	EQU 4
cfc_rgb8_fader_speed_max	EQU 4
cfc_rgb8_fader_radius		EQU cfc_rgb8_fader_speed_max
cfc_rgb8_fader_center		EQU cfc_rgb8_fader_speed_max+1
cfc_rgb8_fader_angle_speed	EQU 2
cfc_rgb8_fader_delay		EQU 3*PAL_FPS


vp1_pf1_planes_x_offset		EQU 1*vp1_pf_pixel_per_datafetch
vp1_pf1_planes_y_offset		EQU 0


	INCLUDE "except-vectors-offsets.i"


	INCLUDE "extra-pf-attributes.i"


	INCLUDE "sprite-attributes.i"


	RSRESET

cl1_extension1			RS.B 0

cl1_ext1_BPL3PTH		RS.L 1
cl1_ext1_BPL3PTL		RS.L 1
cl1_ext1_BPL5PTH		RS.L 1
cl1_ext1_BPL5PTL		RS.L 1
cl1_ext1_BPL7PTH		RS.L 1
cl1_ext1_BPL7PTL		RS.L 1

cl1_extension1_size		RS.B 0


	RSRESET

cl1_begin			RS.B 0

	INCLUDE "copperlist1-offsets.i"

cl1_extension1_entry 		RS.B cl1_extension1_size

cl1_COPJMP2			RS.L 1

copperlist1_size		RS.B 0


	RSRESET

cl2_extension1			RS.B 0

cl2_ext1_DDFSTRT		RS.L 1
cl2_ext1_DDFSTOP		RS.L 1
cl2_ext1_BPLCON1		RS.L 1
cl2_ext1_BPLCON2		RS.L 1
cl2_ext1_BPLCON3_1		RS.L 1
cl2_ext1_BPL1MOD		RS.L 1
cl2_ext1_BPL2MOD		RS.L 1
cl2_ext1_BPLCON4		RS.L 1
cl2_ext1_FMODE			RS.L 1
cl2_ext1_BPL1PTH		RS.L 1
cl2_ext1_BPL1PTL		RS.L 1
cl2_ext1_BPL2PTH		RS.L 1
cl2_ext1_BPL2PTL		RS.L 1

cl2_extension1_size		RS.B 0


	RSRESET

cl2_extension2			RS.B 0

cl2_ext2_WAIT			RS.L 1
cl2_ext2_BPLCON3_1		RS.L 1
cl2_ext2_COLOR29_high8		RS.L 1
cl2_ext2_COLOR30_high8		RS.L 1
cl2_ext2_BPLCON3_2		RS.L 1
cl2_ext2_COLOR29_low8		RS.L 1
cl2_ext2_COLOR30_low8		RS.L 1
cl2_ext2_BPLCON4		RS.L 1

cl2_extension2_size		RS.B 0


	RSRESET

cl2_extension3			RS.B 0

cl2_ext3_WAIT			RS.L 1
cl2_ext3_DDFSTRT		RS.L 1
cl2_ext3_DDFSTOP		RS.L 1
cl2_ext3_BPLCON1		RS.L 1
cl2_ext3_BPLCON2		RS.L 1
cl2_ext3_BPLCON3_1		RS.L 1
cl2_ext3_BPL1MOD		RS.L 1
cl2_ext3_BPL2MOD		RS.L 1
cl2_ext3_BPLCON4		RS.L 1
cl2_ext3_FMODE			RS.L 1
cl2_ext3_BPL1PTH		RS.L 1
cl2_ext3_BPL1PTL		RS.L 1
cl2_ext3_BPL2PTH		RS.L 1
cl2_ext3_BPL2PTL		RS.L 1
cl2_ext3_BPL4PTH		RS.L 1
cl2_ext3_BPL4PTL		RS.L 1
cl2_ext3_BPL6PTH		RS.L 1
cl2_ext3_BPL6PTL		RS.L 1
cl2_ext3_BPLCON0		RS.L 1

cl2_extension3_size 		RS.B 0


	RSRESET

cl2_extension4			RS.B 0

cl2_ext4_WAIT			RS.L 1
cl2_ext4_DDFSTRT		RS.L 1
cl2_ext4_DDFSTOP		RS.L 1
cl2_ext4_BPLCON1		RS.L 1
cl2_ext4_BPLCON2		RS.L 1
cl2_ext4_BPLCON3_1		RS.L 1
cl2_ext4_BPL1MOD		RS.L 1
cl2_ext4_BPL2MOD		RS.L 1
cl2_ext4_BPLCON4		RS.L 1
cl2_ext4_FMODE			RS.L 1
cl2_ext4_BPL1PTH		RS.L 1
cl2_ext4_BPL1PTL		RS.L 1
cl2_ext4_BPL2PTH		RS.L 1
cl2_ext4_BPL2PTL		RS.L 1
cl2_ext4_BPL3PTH		RS.L 1
cl2_ext4_BPL3PTL		RS.L 1
cl2_ext4_BPL4PTH		RS.L 1
cl2_ext4_BPL4PTL		RS.L 1
cl2_ext4_BPL5PTH		RS.L 1
cl2_ext4_BPL5PTL		RS.L 1
cl2_ext4_BPLCON0		RS.L 1

cl2_extension4_size 		RS.B 0


	RSRESET

cl2_extension5			RS.B 0

cl2_ext5_WAIT			RS.L 1
cl2_ext5_BPLCON3_1		RS.L 1
cl2_ext5_COLOR25_high8		RS.L 1
cl2_ext5_COLOR26_high8		RS.L 1
cl2_ext5_BPLCON3_2		RS.L 1
cl2_ext5_COLOR25_low8		RS.L 1
cl2_ext5_COLOR26_low8		RS.L 1
cl2_ext5_NOOP			RS.L 1

cl2_extension5_size		RS.B 0


	RSRESET

cl2_begin			RS.B 0

; **** Viewport 1 ****
cl2_extension1_entry		RS.B cl2_extension1_size
cl2_WAIT1			RS.L 1
cl2_bplcon0_1			RS.L 1
cl2_extension2_entry 		RS.B cl2_extension2_size*vp1_visible_lines_number
; **** Viewport 2 ****
cl2_extension3_entry		RS.B cl2_extension3_size
; **** Viewport 3 ****
cl2_extension4_entry		RS.B cl2_extension4_size
cl2_extension5_entry		RS.B cl2_extension5_size*vp3_visible_lines_number
; **** Copper-Interrupt ****
cl1_WAIT			RS.L 1
cl1_INTREQ			RS.L 1

cl2_end				RS.L 1

copperlist2_size		RS.B 0


; ** Konstanten für die größe der Copperlisten **
cl1_size1			EQU 0
cl1_size2			EQU 0
cl1_size3			EQU copperlist1_size
cl2_size1			EQU 0
cl2_size2			EQU copperlist2_size
cl2_size3			EQU copperlist2_size


; ** Sprite0 Zusatzstruktur **
	RSRESET

spr0_extension1			RS.B 0

spr0_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr0_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

spr0_extension1_size		RS.B 0

; ** Sprite0 Hauptstruktur **
	RSRESET

spr0_begin			RS.B 0

spr0_extension1_entry		RS.B spr0_extension1_size

spr0_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite0_size			RS.B 0

; ** Sprite1 Zusatzstruktur **
	RSRESET

spr1_extension1			RS.B 0

spr1_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr1_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

spr1_extension1_size		RS.B 0

; ** Sprite1 Hauptstruktur **
	RSRESET

spr1_begin			RS.B 0

spr1_extension1_entry		RS.B spr1_extension1_size

spr1_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite1_size			RS.B 0

; ** Sprite2 Zusatzstruktur **
	RSRESET

spr2_extension1			RS.B 0

spr2_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr2_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

spr2_extension1_size		RS.B 0

; ** Sprite2 Hauptstruktur **
	RSRESET

spr2_begin			RS.B 0

spr2_extension1_entry 		RS.B spr2_extension1_size

spr2_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite2_size			RS.B 0

; ** Sprite3 Zusatzstruktur **
	RSRESET

spr3_extension1			RS.B 0

spr3_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr3_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

spr3_extension1_size		RS.B 0

; ** Sprite3 Hauptstruktur **
	RSRESET

spr3_begin			RS.B 0

spr3_extension1_entry		RS.B spr3_extension1_size

spr3_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite3_size			RS.B 0

; ** Sprite4 Zusatzstruktur **
	RSRESET

spr4_extension1			RS.B 0

spr4_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr4_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

spr4_extension1_size		RS.B 0

; ** Sprite4 Hauptstruktur **
	RSRESET

spr4_begin			RS.B 0

spr4_extension1_entry 		RS.B spr4_extension1_size

spr4_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite4_size			RS.B 0

; ** Sprite5 Zusatzstruktur **
	RSRESET

spr5_extension1			RS.B 0

spr5_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr5_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

spr5_extension1_size		RS.B 0

; ** Sprite5 Hauptstruktur **
	RSRESET

spr5_begin			RS.B 0

spr5_extension1_entry		RS.B spr5_extension1_size

spr5_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite5_size			RS.B 0

; ** Sprite6 Zusatzstruktur **
	RSRESET

spr6_extension1			RS.B 0

spr6_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr6_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

spr6_extension1_size		RS.B 0

; ** Sprite6 Hauptstruktur **
	RSRESET

spr6_begin			RS.B 0

spr6_extension1_entry		RS.B spr6_extension1_size

spr6_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite6_size			RS.B 0

; ** Sprite7 Zusatzstruktur **
	RSRESET

spr7_extension1			RS.B 0

spr7_ext1_header		RS.L 1*(spr_pixel_per_datafetch/16)
spr7_ext1_planedata		RS.L (spr_pixel_per_datafetch/16)*bg1_image_y_size

spr7_extension1_size		RS.B 0

; ** Sprite7 Hauptstruktur **
	RSRESET

spr7_begin			RS.B 0

spr7_extension1_entry		RS.B spr7_extension1_size

spr7_end			RS.L 1*(spr_pixel_per_datafetch/16)

sprite7_size			RS.B 0


; ** Konstanten für die Größe der Spritestrukturen **
spr0_x_size1			EQU spr_x_size1
spr0_y_size1			EQU 0
spr1_x_size1			EQU spr_x_size1
spr1_y_size1			EQU 0
spr2_x_size1			EQU spr_x_size1
spr2_y_size1			EQU 0
spr3_x_size1			EQU spr_x_size1
spr3_y_size1			EQU 0
spr4_x_size1			EQU spr_x_size1
spr4_y_size1			EQU 0
spr5_x_size1			EQU spr_x_size1
spr5_y_size1			EQU 0
spr6_x_size1			EQU spr_x_size1
spr6_y_size1			EQU 0
spr7_x_size1			EQU spr_x_size1
spr7_y_size1			EQU 0

spr0_x_size2			EQU spr_x_size2
spr0_y_size2			EQU sprite0_size/(spr_x_size2/8)
spr1_x_size2			EQU spr_x_size2
spr1_y_size2			EQU sprite1_size/(spr_x_size2/8)
spr2_x_size2			EQU spr_x_size2
spr2_y_size2			EQU sprite2_size/(spr_x_size2/8)
spr3_x_size2			EQU spr_x_size2
spr3_y_size2			EQU sprite3_size/(spr_x_size2/8)
spr4_x_size2			EQU spr_x_size2
spr4_y_size2			EQU sprite4_size/(spr_x_size2/8)
spr5_x_size2			EQU spr_x_size2
spr5_y_size2			EQU sprite5_size/(spr_x_size2/8)
spr6_x_size2			EQU spr_x_size2
spr6_y_size2			EQU sprite6_size/(spr_x_size2/8)
spr7_x_size2			EQU spr_x_size2
spr7_y_size2			EQU sprite7_size/(spr_x_size2/8)


; ** Extra-Memory **
	RSRESET

em_bitmap_table			RS.B cb_source_x_size*cb_destination_y_size
	RS_ALIGN_LONGWORD
em_rgb8_color_table		RS.L vp3_visible_lines_number*2
extra_memory_size		RS.B 0


	RSRESET

	INCLUDE "variables-offsets.i"

save_a7				RS.L 1

; **** PT-Replay ****
	IFD PROTRACKER_VERSION_2.3A 
		INCLUDE "music-tracker/pt2-variables-offsets.i"
	ENDC
	IFD PROTRACKER_VERSION_3.0B
		INCLUDE "music-tracker/pt3-variables-offsets.i"
	ENDC

pt_effects_handler_active	RS.W 1
pt_skip_commands_enabled	RS.W 1

; **** Viewport 1 ****
vp1_pf1_construction2		RS.L 1
vp1_pf1_display			RS.L 1

; **** Viewport 2 ****
vp2_pf2_construction1		RS.L 1
vp2_pf2_construction2		RS.L 1
vp2_pf2_display			RS.L 1

; **** Horiz-Scrolltext ****
hst_image			RS.L 1
hst_enabled			RS.W 1
hst_text_table_start		RS.W 1
hst_text_BLTCON0_bits		RS.W 1
hst_character_toggle_image	RS.W 1
hst_horiz_scroll_speed		RS.W 1

; **** Morph-Vector-Balls ****
mvb_rotation_x_angle		RS.W 1
mvb_rotation_y_angle		RS.W 1
mvb_rotation_z_angle		RS.W 1

mvb_morph_active		RS.W 1
mvb_morph_shapes_table_start	RS.W 1

; **** Chessboard ****
cb_stripes_y_angle		RS.W 1
cb_stripes_y_angle_speed	RS.W 1

; **** Bar-Fader ****
bf_rgb8_colors_counter		RS.W 1
bf_rgb8_copy_colors_active	RS.W 1

; **** Bar-Fader-In ****
bfi_rgb8_active			RS.W 1
bfi_rgb8_fader_angle		RS.W 1

; **** Bar-Fader-Out ****
bfo_rgb8_active			RS.W 1
bfo_rgb8_fader_angle		RS.W 1

; **** Image-Fader ****
if_rgb8_colors_counter		RS.W 1
if_rgb8_copy_colors_active	RS.W 1

; **** Image-Fader-In ****
ifi_rgb8_active			RS.W 1
ifi_rgb8_fader_angle		RS.W 1

; **** Image-Fader-Out ****
ifo_rgb8_active			RS.W 1
ifo_rgb8_fader_angle		RS.W 1

; **** Chessboard-Fader ****
cf_rgb8_colors_counter		RS.W 1

; **** Chessboard-Fader-In ****
cfi_rgb8_active			RS.W 1
cfi_rgb8_fader_angle		RS.W 1

; **** Chessboard-Fader-Out ****
cfo_rgb8_active			RS.W 1
cfo_rgb8_fader_angle		RS.W 1

; **** Sprite-Fader ****
sprf_rgb8_colors_counter	RS.W 1
sprf_rgb8_copy_colors_active	RS.W 1

; **** Sprite-Fader-In ****
sprfi_rgb8_active		RS.W 1
sprfi_rgb8_fader_angle		RS.W 1

; **** Sprite-Fader-Out ****
sprfo_rgb8_active		RS.W 1
sprfo_rgb8_fader_angle		RS.W 1

; **** Fade-Balls ****
fb_mask				RS.W 1
vb_copy_blit_mask		RS.W 1

; **** Fade-Balls-In ****
fbi_active			RS.W 1
fbi_delay_counter		RS.W 1

; **** Fade-Balls-Out ****
fbo_active			RS.W 1
fbo_delay_counter		RS.W 1

; **** Colors-Fader-Cross ****
cfc_rgb8_active			RS.W 1
cfc_rgb8_fader_angle		RS.W 1
cfc_rgb8_fader_delay_counter	RS.W 1
cfc_rgb8_color_table_start	RS.W 1
cfc_rgb8_colors_counter		RS.W 1
cfc_rgb8_copy_colors_active	RS.W 1

; **** Main ****
fx_active			RS.W 1
quit_active			RS.W 1

variables_size			RS.B 0


; **** PT-Replay ****
	INCLUDE "music-tracker/pt-song.i"

	INCLUDE "music-tracker/pt-temp-channel.i"


; **** Bounce-VU-Meter ****
	RSRESET

bvm_audchaninfo			RS.B 0

bvm_aci_yangle			RS.W 1
bvm_aci_amplitude		RS.W 1

bvm_audchaninfo_size		RS.B 0


; **** Morph-Vector-Balls ****
	RSRESET

mvb_morph_shape			RS.B 0

mvb_morph_shape_object_table	RS.L 1

mvb_morph_shape_size		RS.B 0


	INCLUDE "sys-wrapper.i"

	CNOP 0,4
init_main_variables

; **** Viewport 1 ****
	move.l	extra_pf1(a3),vp1_pf1_construction2(a3)
	move.l	extra_pf2(a3),vp1_pf1_display(a3)

; **** Viewport 2 ****
	move.l	extra_pf4(a3),vp2_pf2_construction1(a3)
	move.l	extra_pf5(a3),vp2_pf2_construction2(a3)
	move.l	extra_pf6(a3),vp2_pf2_display(a3)

; **** PT-Replay ****
	IFD PROTRACKER_VERSION_2.3A 
		PT2_INIT_VARIABLES
	ENDC
	IFD PROTRACKER_VERSION_3.0B
		PT3_INIT_VARIABLES
	ENDC

	moveq	#TRUE,d0
	move.w	d0,pt_effects_handler_active(a3)
	moveq	#FALSE,d1
	move.w	d1,pt_skip_commands_enabled(a3)

; **** Horiz-Scrolltext ****
	lea	hst_image_data,a0
	move.l	a0,hst_image(a3)
	move.w	d1,hst_enabled(a3)
	move.w	d0,hst_text_table_start(a3)
	move.w	d0,hst_text_bltcon0_bits(a3)
	move.w	d0,hst_character_toggle_image(a3)
	moveq	#hst_horiz_scroll_speed1,d2
	move.w	d2,hst_horiz_scroll_speed(a3)

; **** Morph-Vector-Balls *****
	move.w	d0,mvb_rotation_x_angle(a3)
	move.w	d0,mvb_rotation_y_angle(a3)
	move.w	d0,mvb_rotation_z_angle(a3)

	IFEQ mvb_premorph_enabled
		move.w	d0,mvb_morph_active(a3)
	ELSE
		move.w	d1,mvb_morph_active(a3)
	ENDC
	move.w	d0,mvb_morph_shapes_table_start(a3)

; **** Chessboard ****
	move.w	d0,cb_stripes_y_angle(a3)
	move.w	#cb_stripes_y_angle_speed1,cb_stripes_y_angle_speed(a3)

; **** Bar-Fader ****
	move.w	d0,bf_rgb8_colors_counter(a3)
	move.w	d1,bf_rgb8_copy_colors_active(a3)

; **** Bar-Fader-In ****
	move.w	d1,bfi_rgb8_active(a3)
	MOVEF.W sine_table_length/4,d2
	move.w	d2,bfi_rgb8_fader_angle(a3) ; 90 Grad

; **** Bar-Fader-Out ****
	move.w	d1,bfo_rgb8_active(a3)
	move.w	d2,bfo_rgb8_fader_angle(a3) ; 90 Grad

; **** Image-Fader ****
	move.w	d0,if_rgb8_colors_counter(a3)
	move.w	d1,if_rgb8_copy_colors_active(a3)

; **** Image-Fader-In ****
	move.w	d1,ifi_rgb8_active(a3)
	move.w	d2,ifi_rgb8_fader_angle(a3) ; 90 Grad

; **** Image-Fader-Out ****
	move.w	d1,ifo_rgb8_active(a3)
	move.w	d2,ifo_rgb8_fader_angle(a3) ; 90 Grad

; **** Chessboard-Fader ****
	move.w	d0,cf_rgb8_colors_counter(a3)

; **** Chessboard-Fader-In ****
	move.w	d1,cfi_rgb8_active(a3)
	move.w	d2,cfi_rgb8_fader_angle(a3) ; 90 Grad

; **** Chessboard-Fader-Out ****
	move.w	d1,cfo_rgb8_active(a3)
	move.w	d2,cfo_rgb8_fader_angle(a3) ; 90 Grad

; **** Sprite-Fader ****
	move.w	d0,sprf_rgb8_colors_counter(a3)
	move.w	d1,sprf_rgb8_copy_colors_active(a3)

; **** Sprite-Fader-In ****
	move.w	d1,sprfi_rgb8_active(a3)
	MOVEF.W sine_table_length/4,d2
	move.w	d2,sprfi_rgb8_fader_angle(a3) ; 90 Grad

; **** Sprite-Fader-Out ****
	move.w	d1,sprfo_rgb8_active(a3)
	move.w	d2,sprfo_rgb8_fader_angle(a3) ; 90 Grad

; **** Fade-Balls ****
	move.w	#$8888,fb_mask(a3)
	move.w	#TRUE,vb_copy_blit_mask(a3)

; **** Fade-Balls-In ****
	move.w	d1,fbi_active(a3)
	move.w	d1,fbi_delay_counter(a3)

; **** Fade-Balls-Out ****
	move.w	d1,fbo_active(a3)
	move.w	d1,fbo_delay_counter(a3)

; **** Colors-Fader-Cross ****
	IFEQ cfc_rgb8_prefade_enabled
		move.w	d0,cfc_rgb8_active(a3)
		move.w	#cfc_rgb8_colors_number*3,cfc_rgb8_colors_counter(a3)
		move.w	d0,cfc_rgb8_copy_colors_active(a3)
	ELSE
		move.w	d1,cfc_rgb8_active(a3)
		ove.w	d0,cfc_rgb8_copy_colors_counter(a3)
		move.w	d1,cfc_rgb8_copy_colors_active(a3)
	ENDC
	move.w	d2,cfc_rgb8_fader_angle(a3) ; 90 Grad
	move.w	d1,cfc_rgb8_fader_delay_counter(a3)
	move.w	d0,cfc_rgb8_color_table_start(a3)

; **** Main ****
	move.w	d1,fx_active(a3)
	move.w	d1,quit_active(a3)
	rts


	CNOP 0,4
init_main
	bsr.s	pt_DetectSysFrequ
	bsr.s	pt_InitRegisters
	bsr	pt_InitAudTempStrucs
	bsr	pt_ExamineSongStruc
	IFEQ pt_finetune_enabled
		bsr	pt_InitFtuPeriodTableStarts
	ENDC
	bsr	hst_init_characters_offsets
	bsr	hst_init_characters_x_positions
	bsr	hst_init_characters_images
	bsr	bvm_init_audio_chan_info_tables
	bsr	bvm_init_rgb8_color_table
	bsr	bg2_copy_image_to_plane
	bsr	mvb_init_object_coords_offsets
	bsr	mvb_init_morph_shapes_table
	IFEQ mvb_premorph_enabled
		bsr	mvb_init_start_shape
	ENDC
	bsr	mvb_rotation
	bsr	cb_init_chessboard_image
	bsr	cb_init_bitmap_table
	bsr	cb_init_color_tables
	bsr	init_colors
	bsr	init_sprites
	bsr	init_CIA_timers
	bsr	init_first_copperlist
	bra	init_second_copperlist

; **** PT-Replay ****
	PT_DETECT_SYS_FREQUENCY

	PT_INIT_REGISTERS

	PT_INIT_AUDIO_TEMP_STRUCTURES

	PT_EXAMINE_SONG_STRUCTURE

	IFEQ pt_finetune_enabled
		PT_INIT_FINETUNE_TABLE_STARTS
	ENDC

; **** Horiz-Scrolltext ****
	INIT_CHARACTERS_OFFSETS.W hst

	INIT_CHARACTERS_X_POSITIONS hst,LORES

	INIT_CHARACTERS_IMAGES hst

; **** Bouncing-VU-Meter ****
	CNOP 0,4
bvm_init_audio_chan_info_tables
	lea	bvm_audio_chan1_info(pc),a0
	move.w	#sine_table_length/4,(a0)+ ; Y-Winkel 90 Grad = maximaler Ausschlag
	moveq	#0,d1
	move.w	d1,(a0);Amplitude = 0
	lea	bvm_audio_chan2_info(pc),a0
	move.w	d0,(a0)+
	move.w	d1,(a0)
	lea	bvm_audio_chan3_info(pc),a0
	move.w	d0,(a0)+
	move.w	d1,(a0)
	lea	bvm_audio_chan4_info(pc),a0
	move.w	d0,(a0)+
	move.w	d1,(a0)
	rts

	CNOP 0,4
bvm_init_rgb8_color_table
	move.l	#color00_bits,d1
	lea	bvm_rgb8_color_gradients(pc),a0 ; Quelle Farbverlauf
	lea	bfi_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Ziel
	moveq	#bvm_bars_number-1,d7	; Anzahl der Abschnitte
bvm_init_rgb8_color_table_loop1
	moveq	#(bvm_bar_height/2)-1,d6 ; Anzahl der Zeilen
bvm_init_rgb8_color_table_loop2
	move.l	(a0)+,d0		; RGB8-Farbwert
	move.l	d1,(a1)+;COLOR00
	moveq	#(spr_colors_number-1)-1,d5 ; Anzahl der Farbwerte pro Palettenabschnitt
bvm_init_rgb8_color_table_loop3
	move.l	d0,(a1)+;Farbwert eintragen
	dbf	d5,bvm_init_rgb8_color_table_loop3
	dbf	d6,bvm_init_rgb8_color_table_loop2
	dbf	d7,bvm_init_rgb8_color_table_loop1
	rts

; **** Background-Image-2 ****
	COPY_IMAGE_TO_BITPLANE bg2,,,extra_pf3

; **** Morph-Vector-Balls ****
	CNOP 0,4
mvb_init_object_coords_offsets
	lea	mvb_object_coords_offsets(pc),a0 ; Zeiger auf Offset-Tabelle
	moveq	#0,d0			; Startwert
	moveq	#mvb_object_points_number-1,d7
mvb_init_object_coords_offsets_loop
	move.w	d0,(a0)+		; Startwert
	addq.w	#3,d0			; nächste XYZ-Koordinate
	dbf	d7,mvb_init_object_coords_offsets_loop
	rts

	CNOP 0,4
mvb_init_morph_shapes_table
; ** Form 1 **
	lea	mvb_object_shape1_coords(pc),a0 ; Zeiger auf 1. Form
	lea	mvb_morph_shapes_table(pc),a1 ; Tabelle mit Zeigern auf Objektdaten
	move.l	a0,(a1)+;Zeiger auf Form-Tabelle
; ** Form 2 **
	lea	mvb_object_shape2_coords(pc),a0 ; Zeiger auf 2. Form
	IFEQ mvb_morph_loop_enabled
		move.l	a0,(a1)		; Zeiger auf Form-Tabelle
	ELSE
		move.l	a0,(a1)+	; Zeiger auf Form-Tabelle
; ** Form 3 **
		lea	mvb_object_shape3_coords(pc),a0 ; Zeiger auf 6. Form
		move.l	a0,(a1)		; Zeiger auf Form-Tabelle
	ENDC
	rts

	IFEQ mvb_premorph_enabled
		CNOP 0,4
mvb_init_start_shape
		bsr	mvb_morph_object
		tst.w	mvb_morph_active(a3)
		beq.s	mvb_init_start_shape
		rts
	ENDC

; **** Chessboard ****
	CNOP 0,4
cb_init_chessboard_image
	movem.w cb_fill_pattern(pc),d0-d3 ; Füllmuster High&Low 1. Wort, High&Low 2. Wort
	move.l	extra_pf7(a3),a0
	move.l	(a0)+,a1;BP0
	move.l	(a0),a2;BP1
	moveq	#(cb_source_x_size/32)-1,d7 ; Anzahl der Wiederholungen des Musters
cb_init_chessboard_image_loop
	move.w	d0,(a1)+		; High 1. Wort
	move.w	d1,(a2)+		; High 2. Wort
	move.w	d2,(a1)+		; Low 1. Wort
	move.w	d3,(a2)+		; Low 2. Wort
	dbf	d7,cb_init_chessboard_image_loop
	rts

	CNOP 0,4
cb_init_bitmap_table
	move.l	extra_memory(a3),a0
	ADDF.L	em_bitmap_table,a0	; Zeiger auf Bitmap-Tabelle
	move.w	#cb_source_x_size,a1	; Breite des QuellPlayfieldes in Pixeln
	move.l	a1,d3
	moveq	#(cb_destination_x_size)/16,d4 ; Breite des Zielbildes in Pixeln
	swap	d3			; *2^16
	lsl.w	#4,d4
	MOVEF.W cb_destination_y_size-1,d7 ; Anzahl der Zeilen in Bitmap-Tabelle
cb_init_bitmap_table_loop1
	move.l	d3,d2			; Breite des Quellbildes untere 32 Bit
	moveq	#TRUE,d6		; Breite des Quellbildes obere 32 Bit
	divu.l	d4,d6:d2		; F=Breite des Quellbildes/Breite der Zielbildes
	moveq	#TRUE,d1
	move.w	d4,d6			; Breite des Zielbilds
	subq.w	#1,d6			; wegen dbf
cb_init_bitmap_table_loop2
	move.l	d1,d0			; F
	swap	d0			; /2^16 = Bitmapposition
	add.l	d2,d1			; F erhöhen (p*F)
	addq.b	#1,(a0,d0.w)		; Pixel in Tabelle setzen
	dbf	d6,cb_init_bitmap_table_loop2
	add.l	a1,a0			; nächste Zeile in Bitmap-Tabelle
	addq.l	#cb_destination_plane_width_step,d4 ; Breite des Zielbilds erhöhen
	dbf	d7,cb_init_bitmap_table_loop1
	rts

	CNOP 0,4
cb_init_color_tables
	lea	cb_color_gradient1(pc),a0 ; Quelle1
	lea	cb_color_gradient2(pc),a1 ; Quelle2
	lea	cfi_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a2 ; Ziel
	moveq	#vp3_visible_lines_number-1,d7
cb_init_color_tables_loop1
	move.l	(a0)+,(a2)+		; Farbwerte verschachteln
	move.l	(a1)+,(a2)+
	dbf	d7,cb_init_color_tables_loop1

	move.l	#color00_bits,d0
	move.l	extra_memory(a3),a0
	ADDF.L	em_rgb8_color_table,a0
	moveq	#(vp3_visible_lines_number*2)-1,d7
cb_init_color_tables_loop2
	move.l	d0,(a0)+
	dbf	d7,cb_init_color_tables_loop2
	rts


	CNOP 0,4
init_colors
	CPU_SELECT_COLOR_HIGH_BANK 7
	CPU_INIT_COLOR_HIGH COLOR16,8,vp3_pf1_rgb8_color_table

	CPU_SELECT_COLOR_LOW_BANK 7
	CPU_INIT_COLOR_LOW COLOR16,8,vp3_pf1_rgb8_color_table
	rts


	CNOP 0,4
init_sprites
	bsr.s	spr_init_ptrs_table
	bra.s	bg1_init_attached_sprites_cluster

	INIT_SPRITE_POINTERS_TABLE

	INIT_ATTACHED_SPRITES_CLUSTER bg1,spr_ptrs_display,bg1_image_x_position,bg1_image_y_position,spr_x_size2,bg1_image_y_size,,,REPEAT


	CNOP 0,4
init_CIA_timers
	PT_INIT_TIMERS
	rts


	CNOP 0,4
init_first_copperlist
	move.l	cl1_display(a3),a0
	bsr.s	cl1_init_playfield_props
	bsr	cl1_init_sprite_ptrs
	bsr	cl1_init_colors
	bsr	cl1_vp2_init_plane_ptrs
	COP_MOVEQ TRUE,COPJMP2
	bsr	cl1_set_sprite_ptrs
	bra	cl1_vp2_pf1_set_plane_ptrs

	COP_INIT_PLAYFIELD_REGISTERS cl1,NOBITPLANESSPR

	COP_INIT_SPRITE_POINTERS cl1

	CNOP 0,4
cl1_init_colors
	COP_INIT_COLOR_HIGH COLOR00,16,vp2_pf1_rgb8_color_table
	COP_INIT_COLOR_HIGH COLOR16,16,vp2_pf2_rgb8_color_table
	COP_SELECT_COLOR_HIGH_BANK 1
	COP_INIT_COLOR_HIGH COLOR00,16,spr_rgb8_color_table
	COP_INIT_COLOR_HIGH COLOR16,16,bvm_rgb8_color_table
	COP_SELECT_COLOR_HIGH_BANK 2
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 3
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 4
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 5
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 6
	COP_INIT_COLOR_HIGH COLOR00,32
	COP_SELECT_COLOR_HIGH_BANK 7
	COP_INIT_COLOR_HIGH COLOR00,16

	COP_SELECT_COLOR_LOW_BANK 0
	COP_INIT_COLOR_LOW COLOR00,16,vp2_pf1_rgb8_color_table
	COP_INIT_COLOR_LOW COLOR16,16,vp2_pf2_rgb8_color_table
	COP_SELECT_COLOR_LOW_BANK 1
	COP_INIT_COLOR_LOW COLOR00,16,spr_rgb8_color_table
	COP_INIT_COLOR_LOW COLOR16,16,bvm_rgb8_color_table
	COP_SELECT_COLOR_LOW_BANK 2
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 3
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 4
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 5
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 6
	COP_INIT_COLOR_LOW COLOR00,32
	COP_SELECT_COLOR_LOW_BANK 7
	COP_INIT_COLOR_LOW COLOR00,16
	rts

	CNOP 0,4
cl1_vp2_init_plane_ptrs
	COP_MOVEQ TRUE,BPL3PTH
	COP_MOVEQ TRUE,BPL3PTL
	COP_MOVEQ TRUE,BPL5PTH
	COP_MOVEQ TRUE,BPL5PTL
	COP_MOVEQ TRUE,BPL7PTH
	COP_MOVEQ TRUE,BPL7PTL
	rts

	COP_SET_SPRITE_POINTERS cl1,display,spr_number

	CNOP 0,4
cl1_vp2_pf1_set_plane_ptrs
	move.l	cl1_display(a3),a0
	ADDF.L	cl1_extension1_entry+cl1_ext1_BPL3PTH+2,a0
	move.l	extra_pf3(a3),a1
	addq.w	#LONGWORD_SIZE,a1	; Zeiger auf zweite Plane
	moveq	#(vp2_pf1_depth-1)-1,d7	; Anzahl der Bitplanes
cl1_vp2_pf1_set_plane_ptrs_loop
	move.w	(a1)+,(a0)		; High-Wert
	addq.w	#2*LONGWORD_SIZE,a0	; nächter Bitplanezeiger
	move.w	(a1)+,LONGWORD_SIZE-(2*LONGWORD_SIZE)(a0) ; Low-Wert
	dbf	d7,cl1_vp2_pf1_set_plane_ptrs_loop
	rts

	CNOP 0,4
init_second_copperlist
	move.l	cl2_construction2(a3),a0
; **** Viewport 1 ****
	bsr	cl2_vp1_init_playfield_props
	bsr	cl2_vp1_init_plane_ptrs
	COP_WAIT cl2_vp1_hstart1,cl2_vp1_vstart1
	COP_MOVEQ vp1_bplcon0_bits,BPLCON0
	bsr	cl2_vp1_init_color_gradient
; **** Viewport 2 ****
	COP_WAIT cl2_vp2_HSTART,cl2_vp2_VSTART
	bsr	cl2_vp2_init_playfield_props
	bsr	cl2_vp2_init_plane_ptrs
; **** Viewport 3 ****
	COP_WAIT cl2_vp3_hstart1,cl2_vp3_vstart1
	bsr	cl2_vp3_init_playfield_props
	bsr	cl2_vp3_init_plane_ptrs
	bsr	cl2_vp3_init_color_gradient
; **** Copper-Interrupt ****
	bsr	cl2_init_copper_interrupt
	COP_LISTEND
	bsr	cl2_vp1_pf1_set_plane_ptrs
	bsr	cl2_vp1_set_fill_gradient
	bsr	cl2_vp1_set_outline_gradient
	bsr	cl2_vp2_pf1_set_plane_ptrs
	bsr	cl2_vp3_pf1_set_plane_ptrs
	bsr	cl2_vp3_pf2_set_plane_ptrs
	bsr	copy_second_copperlist
	bsr	swap_second_copperlist
	bsr	swap_vp1_playfield1
	bra	swap_vp2_playfield2

; **** Viewport 1 ****
	COP_INIT_PLAYFIELD_REGISTERS cl2,,vp1

	CNOP 0,4
cl2_vp1_init_plane_ptrs
	MOVEF.W BPL1PTH,d0
	moveq	#(vp1_pf1_depth*2)-1,d7	; Anzahl der Bitplanes
cl2_vp1_init_plane_ptrs_loop
	move.w	d0,(a0)			; BPLxPTH/L
	addq.w	#WORD_SIZE,d0		; nächstes Register
	addq.w	#LONGWORD_SIZE,a0	; nächster Eintrag in CL
	dbf	d7,cl2_vp1_init_plane_ptrs_loop
	rts

	CNOP 0,4
cl2_vp1_init_color_gradient
	move.l	#(((cl2_vp1_vstart2<<24)|(((cl2_vp1_hstart2/4)*2)<<16))|$10000)|$fffe,d0 ; WAIT-Befehl
	move.l	#(BPLCON3<<16)|vp1_bplcon3_bits3,d1 ; High-Werte
	move.l	#(COLOR29<<16)+color00_high_bits,d2
	move.l	#(COLOR30<<16)+color00_high_bits,d3
	move.l	#(BPLCON3<<16)|vp1_bplcon3_bits4,d4 ; Low-RGB-Werte
	move.l	#(COLOR29<<16)+color00_low_bits,d5
	moveq	#1,d6
	ror.l	#8,d6			; Additionswert
	move.l	#(COLOR30<<16)+color00_low_bits,a1
	move.l	#(BPLCON4<<16)|vp1_bplcon4_bits,a2
	MOVEF.W vp1_visible_lines_number-1,d7
cl2_vp1_init_color_gradient_loop
	move.l	d0,(a0)+		; WAIT x,y
	move.l	d1,(a0)+		; BPLCON3 High-Werte
	move.l	d2,(a0)+		; COLOR29
	move.l	d3,(a0)+		; COLOR30
	move.l	d4,(a0)+		; BPLCON3 Low-Werte
	move.l	d5,(a0)+		; COLOR39
	move.l	a1,(a0)+		; COLOR30
	add.l	d6,d0			; nächste Zeile
	move.l	a2,(a0)+		; BPLCON4
	dbf	d7,cl2_vp1_init_color_gradient_loop
	rts

; **** Viewport 2 ****
	COP_INIT_PLAYFIELD_REGISTERS cl2,,vp2

	CNOP 0,4
cl2_vp2_init_plane_ptrs
	COP_MOVEQ TRUE,BPL1PTH
	COP_MOVEQ TRUE,BPL1PTL
	COP_MOVEQ TRUE,BPL2PTH
	COP_MOVEQ TRUE,BPL2PTL
	COP_MOVEQ TRUE,BPL4PTH
	COP_MOVEQ TRUE,BPL4PTL
	COP_MOVEQ TRUE,BPL6PTH
	COP_MOVEQ TRUE,BPL6PTL
	COP_MOVEQ vp2_bplcon0_bits,BPLCON0
	rts

; **** Viewport 3 ****
	COP_INIT_PLAYFIELD_REGISTERS cl2,,vp3

	CNOP 0,4
cl2_vp3_init_plane_ptrs
	COP_MOVEQ TRUE,BPL1PTH
	COP_MOVEQ TRUE,BPL1PTL
	COP_MOVEQ TRUE,BPL2PTH
	COP_MOVEQ TRUE,BPL2PTL
	COP_MOVEQ TRUE,BPL3PTH
	COP_MOVEQ TRUE,BPL3PTL
	COP_MOVEQ TRUE,BPL4PTH
	COP_MOVEQ TRUE,BPL4PTL
	COP_MOVEQ TRUE,BPL5PTH
	COP_MOVEQ TRUE,BPL5PTL
	COP_MOVEQ vp3_bplcon0_bits,BPLCON0
	rts

	CNOP 0,4
cl2_vp3_init_color_gradient
	move.l	#(((cl2_vp3_vstart2<<24)|(((cl2_vp3_hstart2/4)*2)<<16))|$10000)|$fffe,d0 ; WAIT-Befehl
	move.l	#(BPLCON3<<16)|vp3_bplcon3_bits3,d1 ; High-Werte
	move.l	#(COLOR25<<16)+color00_high_bits,d2
	move.l	#(COLOR26<<16)+color00_high_bits,d3
	move.l	#(BPLCON3<<16)|vp3_bplcon3_bits4,d4 ; Low-Werte
	move.l	#(((CL_Y_WRAP<<24)|(((cl2_vp3_hstart2/4)*2)<<16))|$10000)|$fffe,d5 ; WAIT-Befehl
	moveq	#1,d6
	ror.l	#8,d6			; Additionswert nächste Zeile
	move.l	#(COLOR25<<16)+color00_low_bits,a1
	move.l	#(COLOR26<<16)+color00_low_bits,a2
	moveq	#vp3_visible_lines_number-1,d7
cl2_vp3_init_color_gradient_loop
	move.l	d0,(a0)+		; WAIT x,y
	move.l	d1,(a0)+		; High-Werte
	move.l	d2,(a0)+		; COLOR25
	move.l	d3,(a0)+		; COLOR26
	move.l	d4,(a0)+		; Low-Werte
	move.l	a1,(a0)+		; COLOR25
	move.l	a2,(a0)+		; COLOR26
	cmp.l	d5,d0			; Rasterzeile $ff erreicht ?
	bne.s	no_patch_copperlist2	; Nein -> verzweige
patch_copperlist2
	COP_WAIT CL_X_WRAP,CL_Y_WRAP	; Copperliste patchen
	bra.s	cl2_vp3_init_color_gradient_skip
	CNOP 0,4
no_patch_copperlist2
	COP_MOVEQ TRUE,NOOP
cl2_vp3_init_color_gradient_skip
	add.l	d6,d0			; nächste Zeile
	dbf	d7,cl2_vp3_init_color_gradient_loop
	rts

	COP_INIT_COPINT cl2,cl2_HSTART,cl2_VSTART

; **** Viewport 1 ****
	CNOP 0,4
cl2_vp1_pf1_set_plane_ptrs
	move.l	cl2_display(a3),a0 
	ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1PTH+2,a0
	move.l	vp1_pf1_display(a3),a1 	; Zeiger auf erste Plane
	moveq	#vp1_pf1_depth-1,d7	; Anzahl der Bitplanes
cl2_vp1_pf1_set_plane_ptrs_loop
	move.w	(a1)+,(a0)		; High-Wert
	addq.w	#2*LONGWORD_SIZE,a0	; nächter Bitplanezeiger
	move.w	(a1)+,LONGWORD_SIZE-(2*LONGWORD_SIZE)(a0) ; Low-Wert
	dbf	d7,cl2_vp1_pf1_set_plane_ptrs_loop
	rts

	CNOP 0,4
cl2_vp1_set_fill_gradient
	move.w	#GB_NIBBLES_MASK,d3
	lea	hst_fill_gradient(pc),a0
	move.l	cl2_construction2(a3),a1
	ADDF.W	cl2_extension2_entry+cl2_ext2_COLOR29_high8+2,a1
	move.w	#cl2_extension2_size,a2
	lea	(a1,a2.l*2),a1		; Zwei Rasterzeilen überspringen
	MOVEF.W (vp1_visible_lines_number-4)-1,d7
cl2_vp1_set_fill_gradient_loop
	move.l	(a0)+,d0
	move.l	d0,d2
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(a1)			; High-Werte
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,cl2_ext2_COLOR29_low8-cl2_ext2_COLOR29_high8(a1) ; Low-Werte
	add.l	a2,a1
	dbf	d7,cl2_vp1_set_fill_gradient_loop
	rts

	CNOP 0,4
cl2_vp1_set_outline_gradient
	move.w	#GB_NIBBLES_MASK,d3
	lea	hst_outline_gradient(pc),a0
	move.l	cl2_construction2(a3),a1
	ADDF.W	cl2_extension2_entry+cl2_ext2_COLOR30_high8+2,a1
	move.w	#cl2_extension2_size,a2
	MOVEF.W vp1_visible_lines_number-1,d7
cl2_vp1_set_outline_gradient_loop
	move.l	(a0)+,d0
	move.l	d0,d2
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(a1)			; High-Werte
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,cl2_ext2_COLOR30_low8-cl2_ext2_COLOR30_high8(a1) ; Low-Werte
	add.l	a2,a1
	dbf	d7,cl2_vp1_set_outline_gradient_loop
	rts

; **** Viewport 2 ****
	CNOP 0,4
cl2_vp2_pf1_set_plane_ptrs
	move.l	cl2_construction2(a3),a0
	ADDF.L	cl2_extension3_entry+cl2_ext3_BPL1PTH+2,a0
	move.l	extra_pf3(a3),a1	; Zeiger auf erste Plane
	moveq	#(vp2_pf1_depth-3)-1,d7	; Anzahl der Bitplanes
cl2_vp2_pf1_set_plane_ptrs_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	addq.w	#2*LONGWORD_SIZE,a0	; nächter Bitplanezeiger
	move.w	(a1)+,LONGWORD_SIZE-(2*LONGWORD_SIZE)(a0) ; BPLxPTL
	dbf	d7,cl2_vp2_pf1_set_plane_ptrs_loop
	rts

; **** Viewport 3 ****
	CNOP 0,4
cl2_vp3_pf1_set_plane_ptrs
	move.l	cl2_construction2(a3),a0
	ADDF.L	cl2_extension4_entry+cl2_ext4_BPL1PTH+2,a0
	move.l	extra_pf4(a3),a1	; Zeiger auf erste Plane
	moveq	#vp3_pf1_depth-1,d7	; Anzahl der Bitplanes
cl2_vp3_pf1_set_plane_ptrs_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	ADDF.W	4*LONGWORD_SIZE,a0	; nächter Playfieldzeiger
	move.w	(a1)+,LONGWORD_SIZE-(4*LONGWORD_SIZE)(a0) ; BPLxPTL
	dbf	d7,cl2_vp3_pf1_set_plane_ptrs_loop
	rts

	CNOP 0,4
cl2_vp3_pf2_set_plane_ptrs
	move.l	cl2_construction2(a3),a0
	ADDF.L	cl2_extension4_entry+cl2_ext4_BPL2PTH+2,a0
	move.l	extra_pf8(a3),a1	; Zeiger auf erste Plane
	moveq	#vp3_pf2_depth-1,d7	; Anzahl der Bitplanes
cl2_vp3_pf2_set_plane_ptrs_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	ADDF.W	4*LONGWORD_SIZE,a0	; nächter Playfieldzeiger
	move.w	(a1)+,LONGWORD_SIZE-(4*LONGWORD_SIZE)(a0) ; BPLxPTL
	dbf	d7,cl2_vp3_pf2_set_plane_ptrs_loop
	rts

	COPY_COPPERLIST cl2,2


	CNOP 0,4
main
	bsr.s	no_sync_routines
	bra	beam_routines


	CNOP 0,4
no_sync_routines
	IFEQ cfc_rgb8_prefade_enabled
		bsr	cfc_rgb8_init_start_colors
	ENDC
	bra	cb_scale_image

	IFEQ cfc_rgb8_prefade_enabled
		CNOP 0,4
cfc_rgb8_init_start_colors
		bsr	cfc_rgb8_copy_color_table
		bsr	rgb8_colors_fader_cross
		tst.w	cfc_rgb8_copy_colors_active(a3) ; Kopieren der Farbwerte beendet?
		beq.s	cfc_rgb8_init_start_colors ; Nein -> verzweige
		move.w	#-1,cfc_rgb8_copy_colors_active(a3) ; Verzögerungszähler desktivieren
		rts
	ENDC

	CNOP 0,4
cb_scale_image
	movem.l a4-a5,-(a7)
	moveq	#TRUE,d4		; 1. X-Koord in Zielbild
	move.l	extra_memory(a3),a0
	ADDF.L	em_bitmap_table,a0	; Zeiger auf Bitmap-Tabelle
	move.l	extra_pf7(a3),a1	
	move.l	(a1),a1			; Zeiger auf Quellbild
	move.l	extra_pf8(a3),a2
	move.l	(a2),a2         	; Zeiger auf Zielbild
	move.w	#cb_x_max,a4		; X-Max in Zielbild
	move.w	#1*extra_pf8_plane_width*extra_pf8_depth,a5
	moveq	#cb_destination_y_size-1,d7 ; Höhe des Zielbildes
cb_scale_image_loop1
	moveq	#0,d2			; 1. X-Koord in Quellbild
	move.w	d4,d3			; X-Koord in Zielbild
	MOVEF.W cb_source_x_size-1,d6	; Breite des Quellbildes
cb_scale_image_loop2
	tst.b	(a0)+			; Spalte setzen ?
	beq.s	cb_skip_column		; Nein -> verzweige
	move.w	d3,d1			; X-Koord in Zielbild
	bmi.s	cb_column_outside	; Wenn < X-Min -> verzweige
	cmp.w	a4,d1
	bge.s	cb_column_outside	; Wenn >= X-Max -> verzweige
	move.w	d2,d0			; X-Koord in Quellbild
	lsr.w	#3,d0			; /8 X-Offset in Quellbild
	not.b	d2			; Shiftwert für Quellbyte ermitteln
	lsr.w	#3,d1			; /8 X-Offset in Zielbild
	not.b	d3			; Shiftwert für Zielbyte ermitteln
	btst	d2,(a1,d0.w)		; Pixel in Quellbyte gesetzt ?
	beq.s	cb_plane0_no_pixel_set	; Nein -> verzweige
	bset	d3,(a2,d1.w)		; Pixel setzen
cb_plane0_no_pixel_set
	btst	d2,(extra_pf7_plane_width,a1,d0.w) ; Pixel in Quellbyte gesetzt ?
	beq.s	cb_plane1_no_pixel_set	; Nein -> verzweige
	bset	d3,extra_pf8_plane_width(a2,d1.w) ; Pixel setzen
cb_plane1_no_pixel_set
	not.b	d3			; Bitnummer wieder in X-Koord Zielbild umwandeln
	not.b	d2			; Bitnummer wieder in X-Koord Quellbild umwandeln
cb_column_outside
	addq.w	#1,d3			; nächstes Pixel in Zielbild
cb_skip_column
	addq.w	#1,d2			; nächstes Pixel in Quellbild
	dbf	d6,cb_scale_image_loop2
	add.l	a5,a2			; nächste Zeile in Zielbild
	subq.w	#cb_destination_x_size_step,d4 ; X-Pos in Zielbild reduzieren
	dbf	d7,cb_scale_image_loop1
	movem.l (a7)+,a4-a5
	rts


	CNOP 0,4
beam_routines
	bsr	wait_copint
	bsr	swap_second_copperlist
	bsr	swap_vp1_playfield1
	bsr	swap_vp2_playfield2
	bsr	horiz_scrolltext
	bsr	hst_horiz_scroll
	bsr	mvb_clear_playfield1_2
	bsr	bvm_get_chans_amplitudes
	bsr	bvm_clear_second_copperlist
	bsr	bvm_set_bars
	bsr	fade_balls_in
	bsr	fade_balls_out
	bsr	set_vector_balls
	bsr	mvb_clear_playfield1_1
	bsr	mvb_rotation
	bsr	mvb_morph_object
	movem.l a4-a6,-(a7)
	bsr	mvb_quicksort_coords
	movem.l (a7)+,a4-a6
	bsr	cb_get_stripes_y_coords
	bsr	cb_make_color_offsets
	bsr	cb_move_chessboard
	bsr	rgb8_bar_fader_in
	bsr	rgb8_bar_fader_out
	bsr	bf_rgb8_copy_color_table
	bsr	rgb8_image_fader_in
	bsr	rgb8_image_fader_out
	bsr	if_rgb8_copy_color_table
	bsr	rgb8_chessboard_fader_in
	bsr	rgb8_chessboard_fader_out
	bsr	rgb8_sprite_fader_in
	bsr	rgb8_sprite_fader_out
	bsr	sprf_rgb8_copy_color_table
	bsr	rgb8_colors_fader_cross
	bsr	cfc_rgb8_copy_color_table
	bsr	control_counters
	bsr	mouse_handler
	tst.w	fx_active(a3)
	bne	beam_routines
	rts


	SWAP_COPPERLIST cl2,2

	CNOP 0,4
swap_vp1_playfield1
	move.l	cl2_display(a3),a0
	move.l	vp1_pf1_construction2(a3),a1
	ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1PTH+2,a0
	move.l	vp1_pf1_display(a3),vp1_pf1_construction2(a3)
	MOVEF.L (vp1_pf1_planes_x_offset/8)+(vp1_pf1_planes_y_offset*extra_pf1_plane_width*vp1_pf1_depth),d1
	move.l	a1,vp1_pf1_display(a3)
	moveq	#vp1_pf1_depth-1,d7
swap_vp1_playfield1_loop
	move.l	(a1)+,d0
	add.l	d1,d0
	move.w	d0,4(a0);BPLxPTL
	swap	d0	;High
	move.w	d0,(a0);BPLxPTH
	addq.w	#8,a0
	dbf	d7,swap_vp1_playfield1_loop
	rts

	CNOP 0,4
swap_vp2_playfield2
	move.l	cl2_display(a3),a0
	move.l	vp2_pf2_construction1(a3),a1
	move.l	vp2_pf2_construction2(a3),a2
	move.l	vp2_pf2_display(a3),vp2_pf2_construction1(a3)
	move.l	a1,vp2_pf2_construction2(a3)
	ADDF.W	cl2_extension3_entry+cl2_ext3_BPL2PTH+2,a0
	move.l	a2,vp2_pf2_display(a3)
	move.l	a2,a1
	moveq	#vp2_pf2_depth-1,d7
swap_vp2_playfield2_loop
	move.w	(a2)+,(a0)		; BPLxPTH
	addq.w	#2*LONGWORD_SIZE,a0
	move.w	(a2)+,LONGWORD_SIZE-(2*LONGWORD_SIZE)(a0) ; BPLxPTL
	dbf	d7,swap_vp2_playfield2_loop

	move.l	cl2_display(a3),a0
	ADDF.W	cl2_extension4_entry+cl2_ext4_BPL1PTH+2,a0
	moveq	#vp3_pf1_depth-1,d7	; Anzahl der Planes
swap_vp3_playfield1_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	ADDF.W	4*LONGWORD_SIZE,a0
	move.w	(a1)+,LONGWORD_SIZE-(4*LONGWORD_SIZE)(a0) ; BPLxPTL
	dbf	d7,swap_vp3_playfield1_loop
	rts


	CNOP 0,4
horiz_scrolltext
	tst.w	hst_enabled(a3)
	bne.s	no_horiz_scrolltext
	movem.l a4-a5,-(a7)
	bsr.s	hst_init_character_blit
	move.l	vp1_pf1_construction2(a3),a0
	MOVEF.L (hst_text_x_position/8)+(hst_text_y_position*extra_pf1_plane_width*vp1_pf1_depth),d3
	add.l	(a0),d3
	move.w	#(hst_text_character_y_size*hst_text_character_depth*64)+(hst_text_character_x_size/16),d4 ; BLTSIZE
	move.w	#hst_text_character_x_restart,d5
	lea	hst_characters_x_positions(pc),a0
	lea	hst_characters_image_ptrs(pc),a1 ; Zeiger auf Adressen der Chars-Images
	lea	BLTAPT-DMACONR(a6),a2
	lea	BLTDPT-DMACONR(a6),a4
	lea	BLTSIZE-DMACONR(a6),a5
	bsr.s	hst_get_text_softscroll
	moveq	#hst_text_characters_number-1,d7
horiz_scrolltext_loop
	moveq	#0,d0
	move.w	(a0),d0			; X-Position
	move.w	d0,d2	
	lsr.w	#3,d0			; X/8
	add.l	d3,d0			; X-Offset
	WAITBLIT
	move.l	(a1)+,(a2)		; Char-Image
	move.l	d0,(a4)			; Playfield
	move.w	d4,(a5)			; Blitter starten
	sub.w	hst_horiz_scroll_speed(a3),d2
	bpl.s	hst_set_character_x_position
	move.l	a0,-(a7)
	bsr.s	hst_get_new_character_image
	move.l	(a7)+,a0
	move.l	d0,-4(a1)		; Neues Bild für Character
	add.w	d5,d2			; X-Pos. Neustart
hst_set_character_x_position
	move.w	d2,(a0)+
	dbf	d7,horiz_scrolltext_loop
	movem.l (a7)+,a4-a5
	move.w	#DMAF_BLITHOG,DMACON-DMACONR(a6)
no_horiz_scrolltext
	rts
	CNOP 0,4
hst_init_character_blit
	move.w	#DMAF_BLITHOG|DMAF_SETCLR,DMACON-DMACONR(a6)
	WAITBLIT
	move.l	#(BC0F_SRCA|BC0F_DEST|ANBNC+ANBC|ABNC+ABC)<<16,BLTCON0-DMACONR(a6) ; Minterm D=A
	moveq	#-1,d0
	move.l	d0,BLTAFWM-DMACONR(a6)	; keine Ausmaskierung
	move.l	#((hst_image_plane_width-hst_text_character_width)<<16)|(extra_pf1_plane_width-hst_text_character_width),BLTAMOD-DMACONR(a6) ; A-Mod + D-Mod
	rts

	CNOP 0,4
hst_get_text_softscroll
	moveq	#hst_text_character_x_size-1,d0
	and.w	(a0),d0			; X-Pos
	ror.w	#4,d0			; Bits in richtige Position bringen
	or.w	#BC0F_SRCA+BC0F_DEST+ANBNC+ANBC+ABNC+ABC,d0 ; Minterm D=A
	move.w	d0,hst_text_bltcon0_bits(a3) 
	rts

	GET_NEW_CHARACTER_IMAGE.W hst,hst_check_control_codes,NORESTART

	CNOP 0,4
hst_check_control_codes
	cmp.b	#"",d0
	beq.s	hst_restart_scrolltext
	cmp.b	#"",d0
	beq.s	hst_stop_scrolltext
	rts
	CNOP 0,4
hst_restart_scrolltext
	moveq	#TRUE,d0		; Steuerungscode gefunden
	move.w	d0,hst_text_table_start(a3)
	rts
	CNOP 0,4
hst_stop_scrolltext
	move.w	#FALSE,hst_enabled(a3)	; Text stoppen
	moveq	#TRUE,d0		; Steuerungscode gefunden
	tst.w	quit_active(a3)		; Soll Intro beendet werden?
	bne.s	hst_normal_stop_scrolltext ; Nein -> verzweige
	move.w	d0,pt_music_fader_active(a3)

	move.w	d0,fbo_active(a3)
	move.w	#fbo_delay,fbo_delay_counter(a3)
	move.w	#$8888,fb_mask(a3)

	move.w	#sprf_rgb8_colors_number*3,sprf_rgb8_colors_counter(a3)
	move.w	d0,sprfo_rgb8_active(a3)
	move.w	d0,sprf_rgb8_copy_colors_active(a3)

	move.w	#if_rgb8_colors_number*3,if_rgb8_colors_counter(a3)
	move.w	d0,ifo_rgb8_active(a3)
	move.w	d0,if_rgb8_copy_colors_active(a3)

	move.w	d0,cfo_rgb8_active(a3)

	move.w	#bf_rgb8_colors_number*3,bf_rgb8_colors_counter(a3)
	move.w	d0,bfo_rgb8_active(a3)
	move.w	d0,bf_rgb8_copy_colors_active(a3)
hst_normal_stop_scrolltext
	rts

	CNOP 0,4
hst_horiz_scroll
	tst.w	hst_enabled(a3)
	bne.s	hst_horiz_scroll_quit
	move.l	vp1_pf1_construction2(a3),a0
	move.l	(a0),a0
	ADDF.W	(hst_text_x_position/8)+(hst_text_y_position*extra_pf1_plane_width*vp1_pf1_depth),a0
	WAITBLIT
	move.w	hst_text_bltcon0_bits(a3),BLTCON0-DMACONR(a6)
	move.l	a0,BLTAPT-DMACONR(a6)	; Quelle
	addq.w	#WORD_SIZE,a0		; 16 Pixel überspringen
	move.l	a0,BLTDPT-DMACONR(a6)	; Ziel
	move.l	#((extra_pf1_plane_width-hst_horiz_scroll_window_width)<<16)+(extra_pf1_plane_width-hst_horiz_scroll_window_width),BLTAMOD-DMACONR(a6) ; A-Mod + D-Mod
	move.w	#(hst_horiz_scroll_window_y_size*hst_horiz_scroll_window_depth*64)+(hst_horiz_scroll_window_x_size/16),BLTSIZE-DMACONR(a6) ; Blitter starten
hst_horiz_scroll_quit
	rts

	CNOP 0,4
bvm_get_chans_amplitudes
	MOVEF.W bvm_max_amplitude,d2
	MOVEF.W sine_table_length/4,d3
	lea	pt_audchan1temp(pc),a0
	lea	bvm_audio_chan1_info(pc),a1
	bsr.s	bvm_get_chan_amplitude
	lea	pt_audchan2temp(pc),a0
	bsr.s	bvm_get_chan_amplitude
	lea	pt_audchan3temp(pc),a0
	bsr.s	bvm_get_chan_amplitude
	lea	pt_audchan4temp(pc),a0
	bsr.s	bvm_get_chan_amplitude
	rts


; Input
; d2.w	... Maximale Amplitude
; d3.w	... Y-Winkel 90 Grad
; a0	... Temporäre Struktur des Audiokanals
; a1	... Zeiger auf Amplitudenwert des Kanals
; Result
; d0.l	... Kein Rückgabewert
	CNOP 0,4
bvm_get_chan_amplitude
	tst.b	n_note_trigger(a0)
	bne.s	bvm_get_chan_amplitude_quit
	moveq	#0,d0
	move.b	n_volume(a0),d0		; Aktuelle Lautstärke
	move.w	#FALSE,n_note_trigger(a0)
	MULUF.W bvm_max_amplitude,d0,d1
	lsr.w	#6,d0
	cmp.w	d2,d0			; Amplitude <= maximale Amplitude ?
	ble.s	bvm_get_chan_amplitude_set ; Ja -> verzweige
	move.w	d2,d0			; Maximale Amplitude
bvm_get_chan_amplitude_set
	move.w	d3,(a1)+                ; Winkel
	move.w	d0,(a1)+		; Amplitudenwert
bvm_get_chan_amplitude_quit
	rts

	CNOP 0,4
bvm_clear_second_copperlist
	MOVEF.W vp1_bplcon4_bits&FALSE_BYTE,d0
	move.l	cl2_construction2(a3),a0
	ADDF.W	cl2_extension2_entry+cl2_ext2_BPLCON4+3,a0
	move.w	#cl2_extension2_size,a1
	moveq	#vp1_visible_lines_number-1,d7
bvm_clear_second_copperlist_loop
	move.b	d0,(a0)			; BPLCON4-Low
	add.l	a1,a0			; nächste Rasterzeile
	dbf	d7,bvm_clear_second_copperlist_loop
	rts

	CNOP 0,4
bvm_set_bars
	movem.l a3-a6,-(a7)
	MOVEF.W (sine_table_length/2)-1,d5
	lea	sine_table(pc),a0	
	lea	bvm_audio_chan1_info(pc),a1 ; Zeiger auf Amplitude und Y-Winkeldes Kanals
	lea	bvm_switch_table(pc),a4
	move.l	cl2_construction2(a3),a5 
	ADDF.W	cl2_extension2_entry+cl2_ext2_BPLCON4+3,a5
	move.w	#bvm_y_centre,a3
	move.w	#cl2_extension2_size,a6
	moveq	#bvm_bars_number-1,d7
bvm_set_bars_loop1
	move.w	(a1)+,d3		; Y-Winkel
	move.w	2(a0,d3.w*4),d0		; sin(w)
	addq.w	#bvm_y_angle_speed,d3	; nächster Y-Winkel
	muls.w	(a1)+,d0		; y'=(yr*sin(w))/2^15
	MULUF.L 2,d0
	swap	d0
	cmp.w	d5,d3			; 180 Grad erreicht ?
	ble.s	bvm_y_angle_ok		; Nein -> verzweige
	lsr.w	-2(a1)			; Amplitude/2
bvm_y_angle_ok
	and.w	d5,d3			; Überlauf bei 180 Grad
	move.w	d3,-4(a1)	
	add.w	a3,d0			; y' + Y-Mittelpunkt
	MULUF.W cl2_extension2_size/4,d0,d1 ; Y-Offset in CL
	lea	(a5,d0.w*4),a2		; Y-Offset
	moveq	#bvm_bar_height-1,d6
bvm_set_bars_loop2
	move.b	(a4)+,(a2)		; BPLCON4-Low
	add.l	a6,a2			; nächste Rasterzeile in CL
	dbf	d6,bvm_set_bars_loop2
	dbf	d7,bvm_set_bars_loop1
	movem.l (a7)+,a3-a6
	rts

	CNOP 0,4
mvb_clear_playfield1_1
	move.l	vp2_pf2_construction1(a3),a0
	WAITBLIT
	move.l	#BC0F_DEST<<16,BLTCON0-DMACONR(a6)
	move.l	(a0),BLTDPT-DMACONR(a6)
	moveq	#0,d0
	move.w	d0,BLTDMOD-DMACONR(a6)
	move.w	#(mvb_clear_blit_y_size*64)+(mvb_clear_blit_x_size/16),BLTSIZE-DMACONR(a6) ; Blitter starten
	rts

	CNOP 0,4
mvb_clear_playfield1_2
	movem.l a3-a6,-(a7)
	move.l	a7,save_a7(a3)	
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2
	moveq	#0,d3
	moveq	#0,d4
	moveq	#0,d5
	moveq	#0,d6
	move.l	d0,a0
	move.l	d0,a1
	move.l	d0,a2
	move.l	d0,a4
	move.l	d0,a5
	move.l	d0,a6
	move.l	vp2_pf2_construction1(a3),a7
	move.l	(a7),a7
	ADDF.L	extra_pf4_plane_width*extra_pf4_y_size*extra_pf4_depth,a7 ; Ende der Bitplanes
	move.l	d0,a3
	moveq	#5-1,d7			; Anzahl der Durchläufe
mvb_clear_playfield1_2_loop
	REPT ((extra_pf4_plane_width*extra_pf4_y_size*(extra_pf4_depth-1))/56)/5
		movem.l d0-d6/a0-a6,-(a7) ; 56 Bytes löschen
	ENDR
	dbf	d7,mvb_clear_playfield1_2_loop
	move.l	variables+save_a7(pc),a7
	movem.l (a7)+,a3-a6
	rts

	CNOP 0,4
mvb_rotation
	movem.l a4-a6,-(a7)
	move.w	mvb_rotation_x_angle(a3),d1
	move.w	d1,d0	
	lea	sine_table(pc),a2	
	move.w	2(a2,d0.w*4),d4		; sin(a)
	move.w	#sine_table_length/4,a4
	IFEQ sine_table_length-512
		MOVEF.W sine_table_length-1,d3
	ELSE
		MOVEF.W sine_table_length,d3
	ENDC
	add.w	a4,d0			; + 90 Grad
	swap	d4			; Bits 16-31 = sin(a)
	IFEQ sine_table_length-512
		and.w	d3,d0		; Übertrag entfernen
	ELSE
		cmp.w	d3,d0		; 360 Grad erreicht ?
		blt.s	mvb_rotation_save_x_angle1
		sub.w	d3,d0		; Neustart
mvb_rotation_save_x_angle1
	ENDC
	move.w	2(a2,d0.w*4),d4		; Bits 0-15 = cos(a)
	addq.w	#mvb_rotation_x_angle_speed,d1 ;nächster X-Winkel
	IFEQ sine_table_length-512
		and.w	d3,d1		; Übertrag entfernen
	ELSE
		cmp.w	d3,d1		; 360 Grad erreicht ?
		blt.s	mvb_rotation_save_x_angle2
		sub.w	d3,d1		; Neustart
mvb_rotation_save_x_angle2
	ENDC
	move.w	d1,mvb_rotation_x_angle(a3) 
	move.w	mvb_rotation_y_angle(a3),d1 ; Y-Winkel
	move.w	d1,d0	
	move.w	2(a2,d0.w*4),d5		; sin(b)
	add.w	a4,d0			; + 90 Grad
	swap	d5			; Bits 16-31 = sin(b)
	IFEQ sine_table_length-512
		and.w	d3,d0		; Übertrag entfernen
	ELSE
		cmp.w	d3,d0		; 360 Grad erreicht ?
		blt.s	mvb_rotation_save_y_angle1
		sub.w	d3,d0		; Neustart
mvb_rotation_save_y_angle1
	ENDC
	move.w	2(a2,d0.w*4),d5		; Bits 0-15 = cos(b)
	addq.w	#mvb_rotation_y_angle_speed,d1 ; nächster Y-Winkel
	IFEQ sine_table_length-512
		and.w	d3,d1		; Übertrag entfernen
	ELSE
		cmp.w	d3,d1		; 360 Grad erreicht ?
		blt.s	mvb_rotation_save_y_angle2
		sub.w	d3,d1		; Neustart
mvb_rotation_save_y_angle2
	ENDC
	move.w	d1,mvb_rotation_y_angle(a3) 
	move.w	mvb_rotation_z_angle(a3),d1 ; Z-Winkel
	move.w	d1,d0	
	move.w	2(a2,d0.w*4),d6		; sin(c)
	add.w	a4,d0			; + 90 Grad
	swap	d6			; Bits 16-31 = sin(c)
	IFEQ sine_table_length-512
		and.w	d3,d0		; Übertrag entfernen
	ELSE
		cmp.w	d3,d0		; 360 Grad erreicht ?
		blt.s	mvb_rotation_save_z_angle1
		sub.w	d3,d0		; Neustart
mvb_rotation_save_z_angle1
	ENDC
	move.w	2(a2,d0.w*4),d6		; Bits 0-15 = cos(c)
	addq.w	#mvb_rotation_z_angle_speed,d1 ; nächster Z-Winkel
	IFEQ sine_table_length-512
		and.w	d3,d1		; Übertrag entfernen
	ELSE
		cmp.w	d3,d1		; 360 Grad erreicht ?
		blt.s	mvb_rotation_save_z_angle2
		sub.w	d3,d1		; Neustart
mvb_rotation_save_z_angle2
	ENDC
	move.w	d1,mvb_rotation_z_angle(a3) 
	lea	mvb_object_coords(pc),a0
	lea	mvb_rotation_xyz_coords(pc),a1
	move.w	#mvb_rotation_d*8,a4
	move.w	#mvb_rotation_x_center,a5
	move.w	#mvb_rotation_y_center,a6
	moveq	#mvb_object_points_number-1,d7
mvb_rotation_loop
	move.w	(a0)+,d0		; X-Koord.
	move.l	d7,a2	
	move.w	(a0)+,d1		; Y-Koord.
	move.w	(a0)+,d2		; Z-Koord.
	ROTATE_X_AXIS
	ROTATE_Y_AXIS
	ROTATE_Z_AXIS
; ** Zentralprojektion und Translation **
	move.w	d2,d3			; z retten
	ext.l	d0
	add.w	a4,d3			; z+d
	MULUF.L mvb_rotation_d,d0,d7 	; X-Projektion
	ext.l	d1
	divs.w	d3,d0			; x'=(x*d)/(z+d)
	MULUF.L mvb_rotation_d,d1,d7 	; Y-Projektion
	add.w	a5,d0			; x' + X-Mittelpunkt
	move.w	d0,(a1)+		; X-Pos.
	divs.w	d3,d1			; y'=(y*d)/(z+d)
	add.w	a6,d1			; y' + Y-Mittelpunkt
	move.w	d1,(a1)+		; Y-Pos.
	asr.w	#3,d2			; Z/8
	move.l	a2,d7
	move.w	d2,(a1)+		; Z-Pos.
	dbf	d7,mvb_rotation_loop
	movem.l (a7)+,a4-a6
	rts

	CNOP 0,4
mvb_morph_object
	tst.w	mvb_morph_active(a3)
	bne.s	mvb_morph_object_quit
	move.w	mvb_morph_shapes_table_start(a3),d1
	moveq	#TRUE,d2		; Koordinatenzähler
	lea	mvb_object_coords(pc),a0 ; Aktuelle Objektdaten
	lea	mvb_morph_shapes_table(pc),a1 ; Tabelle mit Adressen der Formen-Tabellen
	move.l	(a1,d1.w*4),a1		; Zeiger auf Tabelle
	MOVEF.W mvb_object_points_number*3-1,d7
mvb_morph_object_loop
	move.w	(a0),d0			; aktuelle Koordinate lesen
	cmp.w	(a1)+,d0		; mit Ziel-Koordinate vergleichen
	beq.s	mvb_morph_object_skip1
	bgt.s	mvb_morph_object_zoom_size
	addq.w	#mvb_morph_speed,d0	; aktuelle Koordinate erhöhen
	bra.s	mvb_morph_object_save
	CNOP 0,4
mvb_morph_object_zoom_size
	subq.w	#mvb_morph_speed,d0	; aktuelle Koordinate verringern
mvb_morph_object_save
	move.w	d0,(a0)
	addq.w	#1,d2			; Koordinatenzähler erhöhen
mvb_morph_object_skip1
	addq.w	#WORD_SIZE,a0		; Nächste Koordinate
	dbf	d7,mvb_morph_object_loop
	tst.w	d2			; Morphing beendet?
	bne.s	mvb_morph_object_quit
	addq.w	#1,d1			; nächster Eintrag in Objekttablelle
	cmp.w	#mvb_morph_shapes_number,d1 ; Ende der Tabelle ?
	IFEQ mvb_morph_loop_enabled
		bne.s	mvb_morph_object_skip2
		moveq	#0,d1		; Neustart
mvb_morph_object_skip2
	ELSE
		beq.s	mvb_morph_object_disable
	ENDC
	move.w	d1,mvb_morph_shapes_table_start(a3) 
mvb_morph_object_disable
	move.w	#FALSE,mvb_morph_active(a3)
mvb_morph_object_quit
	rts

	CNOP 0,4
mvb_quicksort_coords
	moveq	#-2,d2			; Maske, um Bit 0 zu löschen
	lea	mvb_object_coords_offsets(pc),a0
	move.l	a0,a1
	lea	(mvb_object_points_number-1)*2(a0),a2 ; Letzter Eintrag
	move.l	a2,a5
	lea	mvb_rotation_xyz_coords(pc),a6
mvb_quicks
	move.l	a5,d0			; Zeiger auf letzten Eintrag
	add.l	a0,d0			; Erster Eintrag + letzter Eintrag
	lsr.l	#1,d0
	and.b	d2,d0			; Nur gerade Werte
	move.l	d0,a4			; Mitte der Tabelle
	move.w	(a4),d1			; XYZ-Offset
	move.w	4(a6,d1.w*2),d0		; Z-Wert
mvb_quick
	move.w	(a1)+,d1		; XYZ-Offset
	cmp.w	4(a6,d1.w*2),d0		; 1. Z-Wert < mittlerer Z-Wert ?
	blt.s	mvb_quick		; Ja -> weiter
	addq.w	#2,a2			; nächstes XYZ-Offset
	subq.w	#2,a1			; Zeiger zurücksetzen
mvb_quick2
	move.w	-(a2),d1		; XYZ-Offset
	cmp.w	4(a6,d1.w*2),d0		; vorletzter Z-Wert > mittlerer Z-Wert
	bgt.s	mvb_quick2		; Ja -> weiter
mvb_quick3
	cmp.l	a2,a1			; Zeiger auf Ende der Tab > Zeiger auf Anfang der Tab. ?
	bgt.s	mvb_quick4		; Ja -> verzweige
	move.w	(a2),d1			; letztes Offset
	move.w	(a1),(a2)		; erstes Offset -> letztes Offset
	subq.w	#2,a2			; vorletztes Offset
	move.w	d1,(a1)+		; letztes Offset -> erstes Offset
mvb_quick4
	cmp.l	a2,a1			; Zeiger auf Anfang <= Zeiger auf Ende der Tab. ?
	ble.s	mvb_quick		; Ja -> verzweige
	cmp.l	a2,a0			; Zeiger auf Anfang >= Zeiger auf Ende der Tab. ?
	bge.s	mvb_quick5		; Ja -> verzweige
	move.l	a5,-(a7)
	move.l	a2,a5			; Zeiger auf Ende der Tabelle
	move.l	a0,a1
	bsr.s	mvb_quicks
	move.l	(a7)+,a5
mvb_quick5
	cmp.l	a5,a1			; Zeiger auf Anfang >= Zeiger auf Ende der Tab. ?
	bge.s	mvb_quick6		; Ja -> verzweige
	move.l	a0,-(a7)
	move.l	a1,a0
	move.l	a5,a2
	bsr.s	mvb_quicks
	move.l	(a7)+,a0
mvb_quick6
	rts

	CNOP 0,4
set_vector_balls
	movem.l a3-a5,-(a7)
	move.l	a7,save_a7(a3)	
	bsr	mvb_init_balls_blit
	move.w	#BC0F_SRCA+BC0F_SRCB+BC0F_SRCC+BC0F_DEST+NANBC+NABC+ABNC+ABC,d3 ; Minterm D=A+B
	move.w	#(mvb_copy_blit_y_size*64)+(mvb_copy_blit_x_size/16),a4
	move.l	vp2_pf2_construction2(a3),a0
	move.l	(a0),d4
	lea	mvb_object_coords_offsets(pc),a0
	lea	mvb_rotation_xyz_coords(pc),a1
	move.w	#mvb_z_plane1,a2
	move.w	#mvb_z_plane2,a3
	lea	mvb_image_data,a5	; Grafik
	lea	mvb_image_mask,a7	; Maske
	MOVEF.W mvb_balls_number-1,d7
set_vector_balls_loop
	move.w	(a0)+,d0		; Startwert für XY-Koordinate
	moveq	#0,d5
	movem.w (a1,d0.w*2),d0-d2	; XYZ lesen
	cmp.w	a2,d2			; 1. Z-Plane ?
	blt.s	set_vector_balls_skip3  ; Ja -> verzweige
	cmp.w	a3,d2			; 2. Z-Plane ?
	blt.s	set_vector_balls_skip2 	; Ja -> verzweige
	cmp.w	#mvb_z_plane3,d2	; 3. Z-Plane ?
	blt.s	set_vector_balls_skip1 	; Ja -> verzweige
	ADDF.W	mvb_image_width,d5
set_vector_balls_skip1
	ADDF.W	mvb_image_width,d5
set_vector_balls_skip2
	ADDF.W	mvb_image_width,d5
set_vector_balls_skip3
	MULUF.W (extra_pf4_plane_width*extra_pf4_depth)/2,d1,d2 ; Y-Offset in Playfield
	ror.l	#4,d0			; Shift-Bits in richtige Position bringen
	move.l	d5,d6
	add.w	d0,d1			; + Y-Offset
	add.l	a5,d5			; + Adresse Grafiken
	MULUF.L 2,d1			; XY-Offset
	swap	d0			; Shift-Bits
	add.l	d4,d1			; + Bitplanes
	add.l	a7,d6			; + Masken
	WAITBLIT
	move.w	d0,BLTCON1-DMACONR(a6)
	or.w	d3,d0			; restliche Bits von BLTCON0
	move.w	d0,BLTCON0-DMACONR(a6)
	move.l	d1,BLTCPT-DMACONR(a6)	; Bitplanes lesen
	move.l	d5,BLTBPT-DMACONR(a6)	; Grafiken
	move.l	d6,BLTAPT-DMACONR(a6)	; Masken
	move.l	d1,BLTDPT-DMACONR(a6)	; Bitplanes schreiben
	move.w	a4,BLTSIZE-DMACONR(a6)	; Blitter starten
	dbf	d7,set_vector_balls_loop
	move.w	#DMAF_BLITHOG,DMACON-DMACONR(a6)
	move.l	variables+save_a7(pc),a7
	movem.l (a7)+,a3-a5
	rts
	CNOP 0,4
mvb_init_balls_blit
	move.w	#DMAF_BLITHOG+DMAF_SETCLR,DMACON-DMACONR(a6)
	WAITBLIT
	move.w	vb_copy_blit_mask(a3),BLTAFWM-DMACONR(a6) ; Ausmaskierung
	moveq	#0,d0
	move.w	d0,BLTALWM-DMACONR(a6)
	move.l	#((extra_pf4_plane_width-(mvb_image_width+2))<<16)+((mvb_image_width*mvb_image_objects_number)-(mvb_image_width+2)),BLTCMOD-DMACONR(a6) ; C+B-Moduli
	move.l	#(((mvb_image_width*mvb_image_objects_number)-(mvb_image_width+2))<<16)+(extra_pf4_plane_width-(mvb_image_width+2)),BLTAMOD-DMACONR(a6) ; A+D-Moduli
	rts

	CNOP 0,4
cb_get_stripes_y_coords
	move.w	cb_stripes_y_angle(a3),d2
	move.w	d2,d0
	MOVEF.W (sine_table_length/4)-1,d4 ; Überlauf
	sub.w	cb_stripes_y_angle_speed(a3),d0 ; nächster Y-Winkel
	and.w	d4,d0			; Überlauf entfernen
	move.w	d0,cb_stripes_y_angle(a3) 
	moveq	#cb_stripes_y_center,d3
	lea	sine_table(pc),a0
	lea	cb_stripes_y_coords(pc),a1
	moveq	#(cb_stripes_number*cb_stripe_height)-1,d7 ; Anzahl der Zeilen
cb_get_stripes_y_coords_loop
	move.l	(a0,d2.w*4),d0	; sin(w)
	MULUF.L cb_stripes_y_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	add.w	d3,d0			; y' + Y-Mittelpunkt
	move.w	d0,(a1)+
	addq.w	#cb_stripes_y_step,d2 	; nächster Y-Winkel
	and.w	d4,d2			; Überlauf entfernen
	dbf	d7,cb_get_stripes_y_coords_loop
	rts

	CNOP 0,4
cb_make_color_offsets
	moveq	#$00000001,d1		; Farboffset des ersten und zweiten Streifens
	lea	cb_stripes_y_coords(pc),a0
	lea	cb_color_offsets_table(pc),a1
	moveq	#cb_stripes_number-1,d7
cb_make_color_offsets_loop1
	moveq	#cb_stripe_height-1,d6
cb_make_color_offsets_loop2
	move.w	(a0)+,d0		; Y-Offset
	move.l	d1,(a1,d0.w*4)		; Farboffset
	dbf	d6,cb_make_color_offsets_loop2
	swap	d1			; Farboffsets vertauschen
	dbf	d7,cb_make_color_offsets_loop1
	rts

	CNOP 0,4
cb_move_chessboard
	move.l	a4,-(a7)
	move.w	#GB_NIBBLES_MASK,d3
	lea	cb_color_offsets_table(pc),a0
	move.l	extra_memory(a3),a1
	ADDF.L	em_rgb8_color_table,a1
	move.l	cl2_construction2(a3),a2
	ADDF.W	cl2_extension5_entry+cl2_ext5_COLOR25_high8+2,a2 
	move.w	#cl2_extension5_size,a4
	moveq	#vp3_visible_lines_number-1,d7
cb_move_chessboard_loop
	move.w	(a0)+,d0;Farboffset 
	move.l	(a1,d0.w*4),d0		; RGB8-Farbwert
	move.l	d0,d2	
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(a2);COLOR29 High-Bits
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,cl2_ext5_COLOR25_low8-cl2_ext5_COLOR25_high8(a2) ; COLOR01 Low-Bits
	add.l	a4,a2			; nächste Zeile
	move.w	(a0)+,d0		; Farboffset
	move.l	(a1,d0.w*4),d0		; RGB8-Farbwert
	move.l	d0,d2	
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(cl2_ext5_COLOR26_high8-cl2_ext5_COLOR25_high8)-cl2_extension5_size(a2) ; COLOR02 High-Bits
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,(cl2_ext5_COLOR26_low8-cl2_ext5_COLOR25_high8)-cl2_extension5_size(a2) ; COLOR02 Low-Bits
	addq.w	#2*LONGWORD_SIZE,a1	; Nächster Farbwert in Farbtabelle
	dbf	d7,cb_move_chessboard_loop
	move.l	(a7)+,a4
	rts


	CNOP 0,4
rgb8_bar_fader_in
	tst.w	bfi_rgb8_active(a3)
	bne.s	rgb8_bar_fader_in_quit
	movem.l a4-a6,-(a7)
	move.w	bfi_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	bfi_rgb8_fader_angle_speed,d0 ; nächster Fader-Winkel
	cmp.w	#sine_table_length/2,d0	; Y-Winkel <= 180 Grad ?
	ble.s	rgb8_bar_fader_in_skip	; Ja -> verzweige
	MOVEF.W sine_table_length/2,d0	; 180 Grad
rgb8_bar_fader_in_skip
	move.w	d0,bfi_rgb8_fader_angle(a3) 
	MOVEF.W bf_rgb8_colors_number*3,d6 ; Zähler
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0	;sin(w)
	MULUF.L bfi_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	bfi_rgb8_fader_center,d0
	lea	bvm_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer für Farbwerte
	lea	bfi_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; Additions-/Subtraktionswert für Blau
	swap	d0			
	clr.w	d0
	move.l	d0,a2			; Additions-/Subtraktionswert für Rot
	lsr.l	#8,d0
	move.l	d0,a4			; Additions-/Subtraktionswert für Grün
	MOVEF.W bf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	movem.l (a7)+,a4-a6
	move.w	d6,bf_rgb8_colors_counter(a3)
	bne.s	rgb8_bar_fader_in_quit
	move.w	#FALSE,bfi_rgb8_active(a3)
rgb8_bar_fader_in_quit
	rts

	CNOP 0,4
rgb8_bar_fader_out
	tst.w	bfo_rgb8_active(a3)
	bne.s	rgb8_bar_fader_out_quit
	movem.l a4-a6,-(a7)
	move.w	bfo_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	bfo_rgb8_fader_angle_speed,d0 ; nächster Fader-Winkel
	cmp.w	#sine_table_length/2,d0	; Y-Winkel <= 180 Grad ?
	ble.s	rgb8_bar_fader_out_skip ; Ja -> verzweige
	MOVEF.W sine_table_length/2,d0	; 180 Grad
rgb8_bar_fader_out_skip
	move.w	d0,bfo_rgb8_fader_angle(a3) 
	MOVEF.W bf_rgb8_colors_number*3,d6 ; Zähler
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0	;sin(w)
	MULUF.L bfo_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	bfo_rgb8_fader_center,d0 ; + Fader-Mittelpunkt
	lea	bvm_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer für Farbwerte
	lea	bfo_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; Additions-/Subtraktionswert für Blau
	swap	d0
	clr.w	d0
	move.l	d0,a2			; Additions-/Subtraktionswert für Rot
	lsr.l	#8,d0
	move.l	d0,a4			; Additions-/Subtraktionswert für Grün
	MOVEF.W bf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	movem.l (a7)+,a4-a6
	move.w	d6,bf_rgb8_colors_counter(a3)
	bne.s	rgb8_bar_fader_out_quit
	move.w	#FALSE,bfo_rgb8_active(a3)
rgb8_bar_fader_out_quit
	rts

	COPY_RGB8_COLORS_TO_COPPERLIST bf,bvm,cl1,cl1_COLOR16_high2,cl1_COLOR16_low2

; ** Tempel einblenden **
	CNOP 0,4
rgb8_image_fader_in
	tst.w	ifi_rgb8_active(a3)
	bne.s	rgb8_image_fader_in_quit
	movem.l a4-a6,-(a7)
	move.w	ifi_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	ifi_rgb8_fader_angle_speed,d0 ; nächster Fader-Winkel
	cmp.w	#sine_table_length/2,d0 ; Y-Winkel <= 180 Grad ?
	ble.s	rgb8_image_fader_in_skip ; Ja -> verzweige
	MOVEF.W sine_table_length/2,d0	; 180 Grad
rgb8_image_fader_in_skip
	move.w	d0,ifi_rgb8_fader_angle(a3) 
	MOVEF.W if_rgb8_colors_number*3,d6 ; Zähler
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L ifi_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	ifi_rgb8_fader_center,d0
	lea	vp2_pf1_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer für Farbwerte
	lea	ifi_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; Additions-/Subtraktionswert für Blau
	swap	d0
	clr.w	d0
	move.l	d0,a2			; Additions-/Subtraktionswert für Rot
	lsr.l	#8,d0
	move.l	d0,a4			; Additions-/Subtraktionswert für Grün
	MOVEF.W if_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	movem.l (a7)+,a4-a6
	move.w	d6,if_rgb8_colors_counter(a3)
	bne.s	rgb8_image_fader_in_quit
	move.w	#FALSE,ifi_rgb8_active(a3)
rgb8_image_fader_in_quit
	rts

; ** Tempel ausblenden **
	CNOP 0,4
rgb8_image_fader_out
	tst.w	ifo_rgb8_active(a3)
	bne.s	rgb8_image_fader_out_quit
	movem.l a4-a6,-(a7)
	move.w	ifo_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	ifo_rgb8_fader_angle_speed,d0 ; nächster Fader-Winkel
	cmp.w	#sine_table_length/2,d0	; Y-Winkel <= 180 Grad ?
	ble.s	rgb8_image_fader_out_skip ; Ja -> verzweige
	MOVEF.W sine_table_length/2,d0	; 180 Grad
rgb8_image_fader_out_skip
	move.w	d0,ifo_rgb8_fader_angle(a3) 
	MOVEF.W if_rgb8_colors_number*3,d6 ; Zähler
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0	;sin(w)
	MULUF.L ifo_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	ifo_rgb8_fader_center,d0
	lea	vp2_pf1_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer für Farbwerte
	lea	ifo_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; Additions-/Subtraktionswert für Blau
	swap	d0
	clr.w	d0
	move.l	d0,a2			; Additions-/Subtraktionswert für Rot
	lsr.l	#8,d0
	move.l	d0,a4			; Additions-/Subtraktionswert für Grün
	MOVEF.W if_rgb8_colors_number-1,d7
	bsr.s	if_rgb8_fader_loop
	movem.l (a7)+,a4-a6
	move.w	d6,if_rgb8_colors_counter(a3)
	bne.s	rgb8_image_fader_out_quit
	move.w	#FALSE,ifo_rgb8_active(a3)
rgb8_image_fader_out_quit
	rts

	RGB8_COLOR_FADER if

	COPY_RGB8_COLORS_TO_COPPERLIST if,vp2_pf1,cl1,cl1_COLOR01_high1,cl1_COLOR01_low1

	CNOP 0,4
rgb8_chessboard_fader_in
	tst.w	cfi_rgb8_active(a3)
	bne.s	rgb8_chessboard_fader_in_quit
	movem.l a4-a6,-(a7)
	move.w	cfi_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	cfi_rgb8_fader_angle_speed,d0 ; nächster Fader-Winkel
	cmp.w	#sine_table_length/2,d0	; Y-Winkel <= 180 Grad ?
	ble.s	rgb8_chessboard_fader_in_skip ; Ja -> verzweige
	MOVEF.W sine_table_length/2,d0	; 180 Grad
rgb8_chessboard_fader_in_skip
	move.w	d0,cfi_rgb8_fader_angle(a3)
	MOVEF.W cf_rgb8_colors_number*3,d6 ; Zähler
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L cfi_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	cfi_rgb8_fader_center,d0
	move.l	extra_memory(a3),a0
	ADDF.L	em_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE),a0	; Puffer für Farbwerte
	lea	cfi_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; Additions-/Subtraktionswert für Blau
	swap	d0
	clr.w	d0
	move.l	d0,a2			; Additions-/Subtraktionswert für Rot
	lsr.l	#8,d0
	move.l	d0,a4			; Additions-/Subtraktionswert für Grün
	MOVEF.W cf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	movem.l (a7)+,a4-a6
	move.w	d6,cf_rgb8_colors_counter(a3)
	bne.s	rgb8_chessboard_fader_in_quit
	move.w	#FALSE,cfi_rgb8_active(a3)
rgb8_chessboard_fader_in_quit
	rts

	CNOP 0,4
rgb8_chessboard_fader_out
	tst.w	cfo_rgb8_active(a3)
	bne.s	rgb8_chessboard_fader_out_quit
	movem.l a4-a6,-(a7)
	move.w	cfo_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	cfo_rgb8_fader_angle_speed,d0 ; nächster Fader-Winkel
	cmp.w	#sine_table_length/2,d0	; Y-Winkel <= 180 Grad ?
	ble.s	rgb8_chessboard_fader_out_skip ; Ja -> verzweige
	MOVEF.W sine_table_length/2,d0	; 180 Grad
rgb8_chessboard_fader_out_skip
	move.w	d0,cfo_rgb8_fader_angle(a3)
	MOVEF.W cf_rgb8_colors_number*3,d6 ; Zähler
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L cfo_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	cfo_rgb8_fader_center,d0
	move.l	extra_memory(a3),a0
	ADDF.L	em_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE),a0	; Puffer für Farbwerte
	lea	cfo_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; Additions-/Subtraktionswert für Blau
	swap	d0
	clr.w	d0
	move.l	d0,a2			; Additions-/Subtraktionswert für Rot
	lsr.l	#8,d0
	move.l	d0,a4			; Additions-/Subtraktionswert für Grün
	MOVEF.W cf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	movem.l (a7)+,a4-a6
	move.w	d6,cf_rgb8_colors_counter(a3)
	bne.s	rgb8_chessboard_fader_out_quit
	move.w	#FALSE,cfo_rgb8_active(a3)
rgb8_chessboard_fader_out_quit
	rts

	CNOP 0,4
rgb8_sprite_fader_in
	tst.w	sprfi_rgb8_active(a3)
	bne.s	rgb8_sprite_fader_in_quit
	movem.l a4-a6,-(a7)
	move.w	sprfi_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	sprfi_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0	; Y-Winkel <= 180 Grad ?
	ble.s	rgb8_sprite_fader_in_skip ; Ja -> verzweige
	MOVEF.W sine_table_length/2,d0	; 180 Grad
rgb8_sprite_fader_in_skip
	move.w	d0,sprfi_rgb8_fader_angle(a3) 
	MOVEF.W sprf_rgb8_colors_number*3,d6 ; Zähler
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L sprfi_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	sprfi_rgb8_fader_center,d0
	lea	spr_rgb8_color_table+(sprf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer für Farbwerte
	lea	sprfi_rgb8_color_table+(sprf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; Additions-/Subtraktionswert für Blau
	swap	d0
	clr.w	d0
	move.l	d0,a2			; Additions-/Subtraktionswert für Rot
	lsr.l	#8,d0
	move.l	d0,a4			; Additions-/Subtraktionswert für Grün
	MOVEF.W sprf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	movem.l (a7)+,a4-a6
	move.w	d6,sprf_rgb8_colors_counter(a3)
	bne.s	rgb8_sprite_fader_in_quit
	move.w	#FALSE,sprfi_rgb8_active(a3)
rgb8_sprite_fader_in_quit
	rts

	CNOP 0,4
rgb8_sprite_fader_out
	tst.w	sprfo_rgb8_active(a3)
	bne.s	rgb8_sprite_fader_out_quit
	movem.l a4-a6,-(a7)
	move.w	sprfo_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	sprfo_rgb8_fader_angle_speed,d0 ; nächster Fader-Winkel
	cmp.w	#sine_table_length/2,d0	; Y-Winkel <= 180 Grad ?
	ble.s	rgb8_sprite_fader_out_skip ; Ja -> verzweige
	MOVEF.W sine_table_length/2,d0	; 180 Grad
rgb8_sprite_fader_out_skip
	move.w	d0,sprfo_rgb8_fader_angle(a3) 
	MOVEF.W sprf_rgb8_colors_number*3,d6 ; Zähler
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L sprfo_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	sprfo_rgb8_fader_center,d0
	lea	spr_rgb8_color_table+(sprf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer für Farbwerte
	lea	sprfo_rgb8_color_table+(sprf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	d0,a5			; Additions-/Subtraktionswert für Blau
	swap	d0
	clr.w	d0
	move.l	d0,a2			; Additions-/Subtraktionswert für Rot
	lsr.l	#8,d0
	move.l	d0,a4			; Additions-/Subtraktionswert für Grün
	MOVEF.W sprf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	movem.l (a7)+,a4-a6
	move.w	d6,sprf_rgb8_colors_counter(a3)
	bne.s	rgb8_sprite_fader_out_quit
	move.w	#FALSE,sprfo_rgb8_active(a3)
rgb8_sprite_fader_out_quit
	rts

	COPY_RGB8_COLORS_TO_COPPERLIST sprf,spr,cl1,cl1_COLOR01_high2,cl1_COLOR01_low2

	CNOP 0,4
fade_balls_in
	tst.w	fbi_active(a3)
	bne.s	fade_balls_in_quit
	subq.w	#1,fbi_delay_counter(a3)
	bne.s	fade_balls_in_quit
	move.w	#fbi_delay,fbi_delay_counter(a3)
	move.w	vb_copy_blit_mask(a3),d0 ; Aktuelle Maske
	move.w	fb_mask(a3),d1		; 2. Maske
	eor.w	d1,d0			; Masken miteinander verknüpfen
	move.w	d0,vb_copy_blit_mask(a3)
	cmp.w	#-1,d0			; Maske fertig?
	beq.s	fade_balls_in_skip	; Ja -> verzweige
	lsr.w	#1,d1			; 2. Maske verschieben
	move.w	d1,fb_mask(a3)	
fade_balls_in_quit
	rts
	CNOP 0,4
fade_balls_in_skip
	move.w	#FALSE,fbi_active(a3)
	rts

	CNOP 0,4
fade_balls_out
	tst.w	fbo_active(a3)
	bne.s	fade_balls_out_quit
	subq.w	#1,fbo_delay_counter(a3)
	bne.s	fade_balls_out_quit
	move.w	#fbo_delay,fbo_delay_counter(a3)
	move.w	vb_copy_blit_mask(a3),d0 ; Aktuelle Maske
	move.w	fb_mask(a3),d1		; 2. Maske
	eor.w	d1,d0			; Masken verknüpfen
	move.w	d0,vb_copy_blit_mask(a3)
	beq.s	fade_balls_out_skip	; Wenn Maske fertig -> verzweige
	lsr.w	#1,d1			; 2. Maske verschieben
	move.w	d1,fb_mask(a3)	
fade_balls_out_quit
	rts
	CNOP 0,4
fade_balls_out_skip
	move.w	#FALSE,fbo_active(a3)
	rts

	CNOP 0,4
rgb8_colors_fader_cross
	tst.w	cfc_rgb8_active(a3)
	bne.s	rgb8_colors_fader_cross_quit
	movem.l a4-a6,-(a7)
	move.w	cfc_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	cfc_rgb8_fader_angle_speed,d0 ; nächster Fader-Winkel
	cmp.w	#sine_table_length/2,d0	; Y-Winkel <= 180 Grad ?
	ble.s	rgb8_colors_fader_cross_skip ; Ja -> verzweige
	MOVEF.W sine_table_length/2,d0	; 180 Grad
rgb8_colors_fader_cross_skip
	move.w	d0,cfc_rgb8_fader_angle(a3) 
	MOVEF.W cfc_rgb8_colors_number*3,d6 ; Zähler
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0;sin(w)
	MULUF.L cfc_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	cfc_rgb8_fader_center,d0
	lea	vp2_pf2_rgb8_color_table+(cfc_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer für Farbwerte
	lea	cfc_rgb8_color_table+(cfc_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; Sollwerte
	move.w	cfc_rgb8_color_table_start(a3),d1
	MULUF.W LONGWORD_SIZE,d1
	lea	(a1,d1.w*8),a1
	move.w	d0,a5			; Additions-/Subtraktionswert für Blau
	swap	d0
	clr.w	d0
	move.l	d0,a2			; Additions-/Subtraktionswert für Rot
	lsr.l	#8,d0
	move.l	d0,a4			; Additions-/Subtraktionswert für Grün
	MOVEF.W cfc_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	movem.l (a7)+,a4-a6
	move.w	d6,cfc_rgb8_colors_counter(a3)
	bne.s	rgb8_colors_fader_cross_quit
	move.w	#FALSE,cfc_rgb8_active(a3)
rgb8_colors_fader_cross_quit
	rts

	CNOP 0,4
cfc_rgb8_copy_color_table
	IFNE cl1_size2
		move.l	a4,-(a7)
	ENDC
	tst.w	cfc_rgb8_copy_colors_active(a3)
	bne.s	cfc_rgb8_copy_color_table_skip2
	move.w	#GB_NIBBLES_MASK,d3
	IFGT cfc_rgb8_colors_number-32
		moveq	#cfc_rgb8_start_color*8,d4 ; Color-Bank Farbregisterzähler
	ENDC
	lea	vp2_pf2_rgb8_color_table+(cfc_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; Puffer für Farbwerte
	move.l	cl1_display(a3),a1 
	ADDF.W	cl1_COLOR17_high1+2,a1
	IFNE cl1_size1
		move.l	cl1_construction1(a3),a2 
		ADDF.W	cl1_COLOR17_high1+2,a2
	ENDC
	IFNE cl1_size2
		move.l	cl1_construction2(a3),a4 
		ADDF.W	cl1_COLOR17_high1+2,a4
	ENDC
	MOVEF.W cfc_rgb8_colors_number-1,d7
cfc_rgb8_copy_color_table_loop
	move.l	(a0)+,d0		; RGB8-Farbwert
	move.l	d0,d2	
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(a1)			; COLORxx High-Bits
	IFNE cl1_size1
		move.w	d0,(a2)		; COLORxx High-Bits
	ENDC
	IFNE cl1_size2
		move.w	d0,(a4)		; COLORxx High-Bits
	ENDC
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,cl1_COLOR17_low1-cl1_COLOR17_high1(a1) ; Low-Bits COLORxx
	addq.w	#LONGWORD_SIZE,a1	; nächstes Farbregister
	IFNE cl1_size1
		move.w	d2,cl1_COLOR17_low1-cl1_COLOR17_high1(a2) ; Low-Bits COLORxx
		addq.w	#LONGWOD_SIZE,a2 ; nächstes Farbregister
	ENDC
		IFNE cl1_size2
			move.w	d2,cl1_COLOR17_low1-cl1_COLOR17_high1(a4) ;Low-Bits COLORxx
			addq.w	#4,a4;nächstes Farbregister
		ENDC
	IFGT cfc_rgb8_colors_number-32
		addq.b	#1<<3,d4	; Farbregister-Zähler erhöhen
		bne.s	cfc_rgb8_copy_color_table_skip1
		addq.w	#LONGWORD_SIZE,a1 ; CMOVE überspringen
		IFNE cl1_size1
			addq.w	#LONGWORD_SIZE,a2 ; CMOVE überspringen
		ENDC
		IFNE cl1_size2
			addq.w	#LONGWORD_SIZE,a4 ; CMOVE überspringen
		ENDC
cfc_rgb8_copy_color_table_skip1
	ENDC
	dbf	d7,cfc_rgb8_copy_color_table_loop
	tst.w	cfc_rgb8_colors_counter(a3) ; Fading beendet ?
	bne.s	cfc_rgb8_copy_color_table_skip2
	move.w	#FALSE,cfc_rgb8_copy_colors_active(a3)
	move.w	#cfc_rgb8_fader_delay,cfc_rgb8_fader_delay_counter(a3)
	move.w	cfc_rgb8_color_table_start(a3),d0
	addq.w	#1,d0			; nächste Farbtabelle
	and.w	#cfc_rgb8_color_tables_number-1,d0 ; Überlauf entfernen
	move.w	d0,cfc_rgb8_color_table_start(a3)
cfc_rgb8_copy_color_table_skip2
	IFNE cl1_size2
		move.l	(a7)+,a4
	ENDC
	rts


	CNOP 0,4
control_counters
	move.w	cfc_rgb8_fader_delay_counter(a3),d0
	bmi.s	cfc_rgb8_no_fader_delay_counter
	subq.w	#1,d0
	bpl.s	cfc_rgb8_save_fader_delay_counter
cfc_rgb8_fader_enable
	move.w	#cfc_rgb8_colors_number*3,cfc_rgb8_colors_counter(a3)
	moveq	#TRUE,d1
	move.w	d1,cfc_rgb8_copy_colors_active(a3)
	move.w	d1,cfc_rgb8_active(a3)
	move.w	#sine_table_length/4,cfc_rgb8_fader_angle(a3) ; 90 Grad
cfc_rgb8_save_fader_delay_counter
	move.w	d0,cfc_rgb8_fader_delay_counter(a3) 
cfc_rgb8_no_fader_delay_counter
	rts

	CNOP 0,4
mouse_handler
	btst	#CIAB_GAMEPORT0,CIAPRA(a4) ; Linke Maustaste gedrückt ?
	beq.s	mouse_handler_quit1
	rts
	CNOP 0,4
mouse_handler_quit1
	moveq	#FALSE,d1
	move.w	d1,pt_effects_handler_active(a3)
	moveq	#TRUE,d0
	tst.w	hst_enabled(a3)
	beq.s	mouse_handler_quit2
	move.w	d0,pt_music_fader_active(a3)
	tst.w	fbi_active(a3)
	bne.s	mouse_handler_skip1
	move.w	d1,fbi_active(a3)
mouse_handler_skip1
	tst.w	vb_copy_blit_mask(a3)
	beq.s	mouse_handler_skip2
	move.w	d0,fbo_active(a3)
	move.w	#fbo_delay,fbo_delay_counter(a3)
	move.w	#$8888,fb_mask(a3)
mouse_handler_skip2
	move.w	#sprf_rgb8_colors_number*3,sprf_rgb8_colors_counter(a3)
	tst.w	sprfi_rgb8_active(a3)
	bne.s	mouse_handler_skip3
	move.w	d1,sprfi_rgb8_active(a3)
mouse_handler_skip3
	move.w	d0,sprfo_rgb8_active(a3)
	move.w	d0,sprf_rgb8_copy_colors_active(a3)
	move.w	#if_rgb8_colors_number*3,if_rgb8_colors_counter(a3)
	tst.w	ifi_rgb8_active(a3)
	bne.s	mouse_handler_skip4
	move.w	d1,ifi_rgb8_active(a3)
mouse_handler_skip4
	move.w	d0,ifo_rgb8_active(a3)
	move.w	d0,if_rgb8_copy_colors_active(a3)
	tst.w	cfi_rgb8_active(a3)
	bne.s	mouse_handler_skip5
	move.w	d1,cfi_rgb8_active(a3)
mouse_handler_skip5
	move.w	d0,cfo_rgb8_active(a3)
	move.w	#bf_rgb8_colors_number*3,bf_rgb8_colors_counter(a3)
	tst.w	bfi_rgb8_active(a3)
	bne.s	mouse_handler_skip6
	move.w	d1,bfi_rgb8_active(a3)
mouse_handler_skip6
	move.w	d0,bfo_rgb8_active(a3)
	move.w	d0,bf_rgb8_copy_colors_active(a3)
	rts
	CNOP 0,4
mouse_handler_quit2
	move.w	#hst_horiz_scroll_speed2,hst_horiz_scroll_speed(a3) ; Doppelte Geschwindigkeit für Laufschrift
	move.w	#hst_stop_text-hst_text,hst_text_table_start(a3) ; Scrolltext beenden
	move.w	d0,quit_active(a3)	; Intro nach Text-Stopp beenden
	rts


	INCLUDE "int-autovectors-handlers.i"

; ** CIA-B timer A interrupt server **
	IFEQ pt_ciatiming_enabled
	CNOP 0,4
ciab_ta_int_server
	ENDC

; ** Vertical blank interrupt server **
	IFNE pt_ciatiming_enabled
		CNOP 0,4
VERTB_int_server
	ENDC

	IFEQ pt_music_fader_enabled
		bsr.s	pt_music_fader
		bra.s	pt_PlayMusic

		PT_FADE_OUT_VOLUME fx_active
		CNOP 0,4
	ENDC

; ** PT-replay routine **
	IFD PROTRACKER_VERSION_2.3A 
		PT2_REPLAY pt_effects_handler
	ENDC
	IFD PROTRACKER_VERSION_3.0B
		PT3_REPLAY pt_effects_handler
	ENDC

; --> 8xy "Not used/custom" <--
	CNOP 0,4
pt_effects_handler
	tst.w	pt_effects_handler_active(a3)
	bne.s	pt_effects_handler_skip2
	move.b	n_cmdlo(a2),d0
	lsr.b	#4,d0
	tst.w	pt_skip_commands_enabled(a3)
	beq.s	pt_effects_handler_skip1
	cmp.b	#$1,d0
	beq.s	pt_start_fade_bars_in
	cmp.b	#$2,d0
	beq.s	pt_start_image_fader_in
	cmp.b	#$3,d0
	beq.s	pt_start_fade_chessboard_in
	cmp.b	#$4,d0
	beq.s	pt_start_fade_sprites_in
	cmp.b	#$5,d0
	beq.s	pt_start_fade_balls_in
	cmp.b	#$6,d0
	beq.s	pt_start_colors_fader_scross
	cmp.b	#$7,d0
	beq.s	pt_start_scrolltext
	cmp.b	#$8,d0
	beq.s	pt_enable_skip_commands
pt_effects_handler_skip1
	cmp.b	#$9,d0
	beq.s	pt_set_stripes_y_angle_speed
	cmp.b	#$a,d0
	beq.s	pt_trigger_morphing
pt_effects_handler_skip2
	rts
	CNOP 0,4
pt_start_fade_bars_in
	move.w	#bf_rgb8_colors_number*3,bf_rgb8_colors_counter(a3)
	moveq	#TRUE,d0
	move.w	d0,bfi_rgb8_active(a3)
	move.w	d0,bf_rgb8_copy_colors_active(a3)
	rts
	CNOP 0,4
pt_start_image_fader_in
	move.w	#if_rgb8_colors_number*3,if_rgb8_colors_counter(a3)
	moveq	#TRUE,d0
	move.w	d0,ifi_rgb8_active(a3)
	move.w	d0,if_rgb8_copy_colors_active(a3)
	rts
	CNOP 0,4
pt_start_fade_chessboard_in
	clr.w	cfi_rgb8_active(a3)
	rts
	CNOP 0,4
pt_start_fade_sprites_in
	move.w	#sprf_rgb8_colors_number*3,sprf_rgb8_colors_counter(a3)
	moveq	#TRUE,d0
	move.w	d0,sprfi_rgb8_active(a3)
	move.w	d0,sprf_rgb8_copy_colors_active(a3)
	rts
	CNOP 0,4
pt_start_fade_balls_in
	clr.w	fbi_active(a3)
	move.w	#fbi_delay,fbi_delay_counter(a3)
	rts
	CNOP 0,4
pt_start_colors_fader_scross
	move.w	#cfc_rgb8_fader_delay,cfc_rgb8_fader_delay_counter(a3)
	rts
	CNOP 0,4
pt_start_scrolltext
	clr.w	hst_enabled(a3)
	rts
	CNOP 0,4
pt_enable_skip_commands
	clr.w	pt_skip_commands_enabled(a3)
	rts
	CNOP 0,4
pt_set_stripes_y_angle_speed
	moveq	#$f,d0
	and.b	n_cmdlo(a2),d0
	move.w	d0,cb_stripes_y_angle_speed(a3)
	rts
	CNOP 0,4
pt_trigger_morphing
	clr.w	mvb_morph_active(a3)
	rts


; ** CIA-B Timer B interrupt server **
	CNOP 0,4
ciab_tb_int_server
	PT_TIMER_INTERRUPT_SERVER

; ** Level-6-Interrupt-Server **
	CNOP 0,4
EXTER_int_server
	rts

; ** Level-7-Interrupt-Server **
	CNOP 0,4
NMI_int_server
	rts


	INCLUDE "help-routines.i"


	INCLUDE "sys-structures.i"


; ** Farben der Playfields **
; **** View ****
	CNOP 0,4
pf1_rgb8_color_table
	DC.L color00_bits
; **** Viewport 2 ****
vp2_pf1_rgb8_color_table
	REPT vp2_visible_lines_number
		DC.L color00_bits
	ENDR
vp2_pf2_rgb8_color_table
	REPT vp2_pf2_colors_number*2
		DC.L color00_bits
	ENDR
; **** Viewport 3 ****
vp3_pf1_rgb8_color_table
	DC.L color00_bits
	REPT vp3_pf1_colors_number-1
		DC.L $000000
	ENDR

; ** Farben der Sprites **
spr_rgb8_color_table
	REPT spr_colors_number
		DC.L color00_bits
	ENDR

; ** Adressen der Sprites **
spr_ptrs_display
	DS.L spr_number

	CNOP 0,2
sine_table
	INCLUDE "sine-table-512x32.i"

; **** PT-Replay ****
	INCLUDE "music-tracker/pt-invert-table.i"

	INCLUDE "music-tracker/pt-vibrato-tremolo-table.i"

	IFD PROTRACKER_VERSION_2.3A 
		INCLUDE "music-tracker/pt2-period-table.i"
	ENDC
	IFD PROTRACKER_VERSION_3.0B
		INCLUDE "music-tracker/pt3-period-table.i"
	ENDC

	INCLUDE "music-tracker/pt-temp-channel-data-tables.i"

	INCLUDE "music-tracker/pt-sample-starts-table.i"

	INCLUDE "music-tracker/pt-finetune-starts-table.i"

; **** Horiz-Scrolltext ****
hst_fill_gradient
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/24-Colorgradient3.ct"

hst_outline_gradient
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/26-Colorgradient3.ct"

hst_ascii
	DC.B "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?-'():\/#+>< "
hst_ascii_end
	EVEN

	CNOP 0,2
hst_characters_offsets
	DS.W hst_ascii_end-hst_ascii
	
hst_characters_x_positions
	DS.W hst_text_characters_number

	CNOP 0,4
hst_characters_image_ptrs
	DS.L hst_text_characters_number

; **** Bounce-VU-Meter ****
bvm_rgb8_color_gradients
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/4x3-Colorgradient4.ct"

bvm_rgb8_color_table
	REPT spr_colors_number*(bvm_bar_height/2)*bvm_bars_number
		DC.L color00_bits
	ENDR

bvm_switch_table
	DC.B $33,$44,$55,$55,$44,$33 	; Bar1
	DC.B $66,$77,$88,$88,$77,$66	; Bar2
	DC.B $99,$aa,$bb,$bb,$aa,$99	; Bar3
	DC.B $cc,$dd,$ee,$ee,$dd,$cc	; Bar4

	CNOP 0,2
bvm_audio_chan1_info
	DS.B bvm_audchaninfo_size

bvm_audio_chan2_info
	DS.B bvm_audchaninfo_size

bvm_audio_chan3_info
	DS.B bvm_audchaninfo_size

bvm_audio_chan4_info
	DS.B bvm_audchaninfo_size

; **** Morp-Vector-Balls ****
	CNOP 0,2
mvb_object_coords
; * Zoom-In *
	DS.W mvb_object_points_number*3

; ** Formen des Objekts **
; ** Form 1 **
mvb_object_shape1_coords
; * "R" *
	DC.W -(69*8),-(32*8),25*8	; P0
	DC.W -(69*8),-(19*8),25*8	; P1
	DC.W -(69*8),-(6*8),25*8	; P2
	DC.W -(69*8),6*8,25*8		; P3
	DC.W -(69*8),19*8,25*8		; P4

	DC.W -(57*8),-(32*8),25*8	; P5
	DC.W -(57*8),-(6*8),25*8	; P6

	DC.W -(44*8),-(25*8),25*8	; P6
	DC.W -(44*8),-(13*8),25*8	; P8
	DC.W -(44*8),6*8,25*8		; P9
	DC.W -(44*8),19*8,25*8		; P10

; * "S" *
	DC.W -(19*8),-(25*8),25*8	; P11
	DC.W -(19*8),-(13*8),25*8	; P12
	DC.W -(19*8),19*8,25*8		; P13

	DC.W -(6*8),-(32*8),25*8	; P13
	DC.W -(6*8),-(6*8),25*8		; P15
	DC.W -(6*8),19*8,25*8		; P16

	DC.W 6*8,-(32*8),25*8		; P16
	DC.W 6*8,0,25*8			; P18
	DC.W 6*8,13*8,25*8		; P19

; * "E" *
	DC.W 32*8,-(32*8),25*8		; P20
	DC.W 32*8,-(19*8),25*8		; P19
	DC.W 32*8,-(6*8),25*8		; P22
	DC.W 32*8,6*8,25*8		; P23
	DC.W 32*8,19*8,25*8		; P24

	DC.W 44*8,-(32*8),25*8		; P25
	DC.W 44*8,-(6*8),25*8		; P26
	DC.W 44*8,19*8,25*8		; P26

	DC.W 57*8,-(32*8),25*8		; P25
	DC.W 57*8,19*8,25*8		; P29

; ** Form 2 **
mvb_object_shape2_coords
; * "3" *
	DC.W -(44*8),-(44*8),25*8	; P0
	DC.W -(38*8),-(6*8),25*8	; P1
	DC.W -(44*8),32*8,25*8		; P2

	DC.W -(32*8),-(44*8),25*8	; P3
	DC.W -(25*8),-(6*8),25*8	; P4
	DC.W -(32*8),32*8,25*8		; P5

	DC.W -(19*8),-(44*8),25*8	; P6
	DC.W -(13*8),-(32*8),25*8	; P6
	DC.W -(13*8),-(19*8),25*8	; P8
	DC.W -(13*8),-(6*8),25*8	; P9
	DC.W -(13*8),6*8,25*8		; P10
	DC.W -(13*8),19*8,25*8		; P11
	DC.W -(19*8),32*8,25*8		; P12

; * "0" *
	DC.W 13*8,-(44*8),25*8		; P13
	DC.W 6*8,-(32*8),25*8		; P13
	DC.W 6*8,-(19*8),25*8		; P15
	DC.W 6*8,-(6*8),25*8		; P16
	DC.W 6*8,6*8,25*8		; P16
	DC.W 6*8,19*8,25*8		; P18
	DC.W 13*8,32*8,25*8		; P19

	DC.W 25*8,-(44*8),25*8		; P20
	DC.W 25*8,32*8,25*8		; P19

	DC.W 38*8,-(44*8),25*8		; P22
	DC.W 44*8,-(32*8),25*8		; P23
	DC.W 44*8,-(19*8),25*8		; P24
	DC.W 44*8,-(6*8),25*8		; P25
	DC.W 44*8,6*8,25*8		; P26
	DC.W 44*8,19*8,25*8		; P26
	DC.W 38*8,32*8,25*8		; P25

	DC.W 38*8,32*8,25*8		; P29 überzählig

	IFNE mvb_morph_loop_enabled
; ** Form 3 **
mvb_object_shape3_coords
; * Zoom-Out *
		DS.W mvb_object_points_number*3
	ENDC

; ** Tabelle mit Offsetwerten der XYZ-Koordinaten **
mvb_object_coords_offsets
	DS.W mvb_object_points_number

; ** Tabelle mit XYZ-Koordinaten **
mvb_rotation_xyz_coords
	DS.W mvb_object_points_number*4

; ** Tabelle mit Adressen der Objekttabellen **
	CNOP 0,4
mvb_morph_shapes_table
	DS.B mvb_morph_shape_size*mvb_morph_shapes_number

; **** Chessboard ****
cb_color_gradient1
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/48-Colorgradient3.ct"

cb_color_gradient2
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/48-Colorgradient4.ct"

	CNOP 0,2
cb_fill_pattern
	DC.W $ffff,$0000,$0000,$ffff

cb_stripes_y_coords
	DS.W cb_stripe_height*cb_stripes_number

cb_color_offsets_table
	DS.W cb_stripe_height*cb_stripes_number*2

; **** Bar-Fader ****
	CNOP 0,4
bfi_rgb8_color_table
	DS.L spr_colors_number*(bvm_bar_height/2)*bvm_bars_number

bfo_rgb8_color_table
	REPT spr_colors_number*(bvm_bar_height/2)*bvm_bars_number
		DC.L color00_bits
	ENDR

bf_rgb8_color_cache
	REPT spr_colors_number*(bvm_bar_height/2)*bvm_bars_number
		DC.L color00_bits
	ENDR

; **** Image-Fader ****
	CNOP 0,4
ifi_rgb8_color_table
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/320x182x16-Temple.ct"

ifo_rgb8_color_table
	REPT vp2_pf1_colors_number
		DC.L color00_bits
	ENDR

; **** Chessboard-Fader ****
	CNOP 0,4
cfi_rgb8_color_table
	REPT vp3_visible_lines_number*2
		DC.L color00_bits
	ENDR

cfo_rgb8_color_table
	REPT vp3_visible_lines_number*2
		DC.L color00_bits
	ENDR

; **** Sprite-Fader ****
	CNOP 0,4
sprfi_rgb8_color_table
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/256x208x16-Desert-Sunset.ct"

sprfo_rgb8_color_table
	REPT spr_colors_number
		DC.L color00_bits
	ENDR

; **** Color-Fader-Cross ****
	CNOP 0,4
cfc_rgb8_color_table
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/4x16x11x8-Balls4.ct"
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/4x16x11x8-Balls6.ct"
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/4x16x11x8-Balls5.ct"
	INCLUDE "Daten:Asm-Sources.AGA/projects/30/colortables/4x16x11x8-Balls7.ct"


	INCLUDE "sys-variables.i"


	INCLUDE "sys-names.i"


	INCLUDE "error-texts.i"

; **** Horiz-Scrolltext ****
hst_text
	REPT (hst_text_characters_number/(hst_origin_character_x_size/hst_text_character_x_size))+1
		DC.B " "
	ENDR

	DC.B "RESISTANCE CELEBRATES THE 30TH ANNIVERSARY!     CODING - DISSIDENT    GRAPHICS - GRASS    MUSIC - MA2E     "
	DC.B " "

hst_stop_text
	REPT (hst_text_characters_number/(hst_origin_character_x_size/hst_text_character_x_size))+1
		DC.B " "
	ENDR
	DC.B " "
	EVEN


	DC.B "$VER: RSE-30 1.4 beta (15.7.24)",0
	EVEN


; ** Audiodaten nachladen **
	IFEQ pt_split_module_enabled
pt_auddata SECTION pt_audio,DATA
		INCBIN "Daten:Asm-Sources.AGA/projects/30/modules/MOD.run in neon lights.song"
pt_audsmps SECTION pt_audio2,DATA_C
		INCBIN "Daten:Asm-Sources.AGA/projects/30/modules/MOD.run in neon lights.smps"
	ELSE
pt_auddata SECTION pt_audio,DATA_C
		INCBIN "Daten:Asm-Sources.AGA/projects/30/modules/MOD.run in neon lights"
	ENDC


; ** Grafikdaten nachladen **
bg1_image_data SECTION bg1_gfx,DATA
	INCBIN "Daten:Asm-Sources.AGA/projects/30/graphics/256x208x16-Desert-Sunset.rawblit"

bg2_image_data SECTION bg2_gfx,DATA
	INCBIN "Daten:Asm-Sources.AGA/projects/30/graphics/320x182x16-Temple.rawblit"

hst_image_data SECTION hst_gfx,DATA_C
	INCBIN "Daten:Asm-Sources.AGA/projects/30/fonts/32x26x4-Font.rawblit"

; **** Morph-Vector-Balls ****
mvb_image_data SECTION mvb_gfx1,DATA_C
	INCBIN "Daten:Asm-Sources.AGA/projects/30/graphics/4x16x11x8-Balls.rawblit"

mvb_image_mask SECTION mvb_gfx2,DATA_C
	INCBIN "Daten:Asm-Sources.AGA/projects/30/graphics/4x16x11x8-Balls.mask"

	END
