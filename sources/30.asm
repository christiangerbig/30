; Requirements
; 68020+
; AGA PAL
; 3.0+


; History / Changes

; V.1.0 beta
; - 1st release

; V.1.1 beta
; - CWAIT for VP2 corrected so that the color gradient of the checkerboard for
; the 1st row is still within the horizontal blanking interval.
; VP1 now uses COLOR28-31
; VP3 now uses COLOR16-23 for P1 and COLOR24-28 for PF2
; - The colors for VP1/PF1 and VP3/PF2 are no longer initialized separately
; by the Copper, as the color gradients for VP1 and VP3 are initialized
; line by line.
; In total, only 240 colors are initialized in the vertical blanking interval.
; - Vector balls: Fade in and fade to other colors with interval and changing
; the z coordinates
; - Use of the PT 8xy command for the fader routines

; V.1.2 beta
; - Maze's module integrated
; - Fader-Cross: Bugfix, the wrong buffer color table was addressed.
; - vp2_pf1 instead of vp2_pf2
; - New fx commands: 880/890
; - Morphing is now triggered by the module via command 890. Delay counter
; is superfluous.
; - Sprite-Fader-In: Timing changed

; V.1.3 beta
; - Scrolling text now starts later
; - The chessboard stands still at 1st and is animated later
; - New Fx command: 8a0

; V.1.4 beta
; - Fx command revised
; - 880 Enable Skip-Commands
; - 89n Set-Chessboars-Speed: Chessboard 1st stands still and then moves,
; when the music changes. It slows down when the music slows down.

; V.1.5 beta
; - Crossfader: Crossfade slows down
; - With Grass' temple + sunrise graphics
; - Credits added
; - Color gradient of the scroll text changed

; V.1.6 beta
; - With completely reworked font
; - Scroll text changed

; V.1.7 beta
; - With Grass'Ball graphics and color gradients
; - Shadow color changed
; - Crossfader: Interval changed

; V.1.8 beta
; - Background color adjusted
; - Bugfix font: "'" + "G", "Q","O",".","#" adjusted
; - 4pLaY's text added

; V.1.0
; - with adf
; - with screen fader
; - WB start considered

; V.1.1
; - "Y" and "'" centered in font
; - all colortables optimized

; V.1.2
; - with Lunix' updated icon

; V.1.3
; - final version
; - with updated includes
; - with updated nfo file
; - exe file crunched with Powerpacker


; PT 8xy command
; 810	Start fade bars in
; 820	Start fade image in (temple)
; 830	Start fade chessboard in
; 840	Start fade sprites in
; 850	Start fade balls in
; 860	Start cross fader
; 870	Start scrolltext
; 880	Enable skip fx commands
; 89n	Set chessboars speed
; 8a0	Trigger balls morphing


; Execution time 68020: 240 rasterlines


	MC68040


	INCDIR "include3.5:"

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


	INCDIR "custom-includes-aga:"


PROTRACKER_VERSION_3		SET 1


	INCLUDE "macros.i"


	INCLUDE "equals.i"

requires_030_cpu		EQU FALSE
requires_040_cpu		EQU FALSE
requires_060_cpu		EQU FALSE
requires_fast_memory		EQU FALSE
requires_multiscan_monitor	EQU FALSE

workbench_start_enabled		EQU FALSE ; [TRUE]
screen_fader_enabled		EQU TRUE
text_output_enabled		EQU FALSE

; PT-Replay
pt_ciatiming_enabled		EQU TRUE
pt_usedfx			EQU %1101010101011110
pt_usedefx			EQU %0000001001000000
pt_mute_enabled			EQU FALSE
pt_music_fader_enabled		EQU TRUE
pt_fade_out_delay		EQU 1	; tick
pt_split_module_enabled		EQU TRUE
pt_track_notes_played_enabled	EQU TRUE
pt_track_volumes_enabled	EQU TRUE
pt_track_periods_enabled	EQU FALSE
pt_track_data_enabled		EQU FALSE
	IFD PROTRACKER_VERSION_3
pt_metronome_enabled		EQU FALSE
pt_metrochanbits		EQU pt_metrochan1
pt_metrospeedbits		EQU pt_metrospeed4th
	ENDC

; Morph-Vector-Balls
mvb_premorph_enabled		EQU TRUE
mvb_morph_loop_enabled		EQU TRUE

; Colors-Fader-Cross 
cfc_rgb8_prefade_enabled	EQU TRUE

dma_bits			EQU DMAF_SPRITE|DMAF_COPPER|DMAF_BLITTER|DMAF_RASTER|DMAF_MASTER|DMAF_SETCLR

	IFEQ pt_ciatiming_enabled
intena_bits			EQU INTF_EXTER|INTF_INTEN|INTF_SETCLR
	ELSE
intena_bits			EQU INTF_VERTB|INTF_EXTER|INTF_INTEN|INTF_SETCLR
	ENDC

ciaa_icr_bits			EQU CIAICRF_SETCLR
	IFEQ pt_ciatiming_enabled
ciab_icr_bits			EQU CIAICRF_TA|CIAICRF_TB|CIAICRF_SETCLR
	ELSE
ciab_icr_bits			EQU CIAICRF_TB|CIAICRF_SETCLR
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
; Viewport 1 
; Playfield 1 
extra_pf1_x_size		EQU 384	; double buffering
extra_pf1_y_size		EQU 26
extra_pf1_depth			EQU 2
extra_pf2_x_size		EQU 384
extra_pf2_y_size		EQU 26
extra_pf2_depth			EQU 2
; Viewport 2 
; Playfield 1 
extra_pf3_x_size		EQU 320
extra_pf3_y_size		EQU 182
extra_pf3_depth			EQU 4
; Playfield 2 
extra_pf4_x_size		EQU 320	; tripple buffering
extra_pf4_y_size		EQU 182
extra_pf4_depth			EQU 3
extra_pf5_x_size		EQU 320
extra_pf5_y_size		EQU 182
extra_pf5_depth			EQU 3
extra_pf6_x_size		EQU 320
extra_pf6_y_size		EQU 182
extra_pf6_depth			EQU 3
; Viewport 3 
extra_pf7_x_size		EQU 960
extra_pf7_y_size		EQU 1
extra_pf7_depth			EQU 2
; Playfield 2 
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

	IFD PROTRACKER_VERSION_2 
audio_memory_size		EQU 0
	ENDC
	IFD PROTRACKER_VERSION_3
audio_memory_size		EQU 1*WORD_SIZE
	ENDC

disk_memory_size		EQU 0

chip_memory_size		EQU 0

	IFEQ pt_ciatiming_enabled
ciab_cra_bits			EQU CIACRBF_LOAD
	ENDC
ciab_crb_bits			EQU CIACRBF_LOAD|CIACRBF_RUNMODE ; oneshot mode
ciaa_ta_time			EQU 0
ciaa_tb_time			EQU 0
	IFEQ pt_ciatiming_enabled
ciab_ta_time			EQU 14187 ; = 0.709379 MHz * [20000 탎 = 50 Hz duration for one frame on a PAL machine]
; ciab_ta_time			EQU 14318 ; = 0.715909 MHz * [20000 탎 = 50 Hz duration for one frame on a NTSC machine]
	ELSE
ciab_ta_time			EQU 0
	ENDC
ciab_tb_time			EQU 362	; = 0.709379 MHz * [511.43 탎 = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
					; = 0.715909 MHz * [506.76 탎 = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
ciaa_ta_continuous_enabled	EQU FALSE
ciaa_tb_continuous_enabled	EQU FALSE
	IFEQ pt_ciatiming_enabled
ciab_ta_continuous_enabled	EQU TRUE
	ELSE
ciab_ta_continuous_enabled	EQU FALSE
	ENDC
ciab_tb_continuous_enabled	EQU FALSE

beam_position			EQU $133

MINROW				EQU VSTART_256_LINES

; View
display_window_hstart		EQU HSTART_320_PIXEL
display_window_vstart		EQU MINROW
display_window_hstop		EQU HSTOP_320_PIXEL
display_window_vstop		EQU VSTOP_256_LINES

spr_pixel_per_datafetch		EQU 64	; 4x

; Viewport 1 
vp1_pixel_per_line		EQU 320
vp1_visible_pixels_number	EQU 320
vp1_visible_lines_number	EQU 26

vp1_hstart			EQU 0
vp1_vstart			EQU MINROW
vp1_vstop			EQU vp1_vstart+vp1_visible_lines_number

vp1_pf1_depth			EQU 2
vp1_pf_depth			EQU vp1_pf1_depth

vp1_pf1_colors_number		EQU 4
vp1_pf_colors_number		EQU vp1_pf1_colors_number

vp1_pf_pixel_per_datafetch	EQU 64	; 4x

; Viewport 2 
vp2_pixel_per_line		EQU 320
vp2_visible_pixels_number	EQU 320
vp2_visible_lines_number	EQU 182

vp2_hstart			EQU HSTOP_320_PIXEL-(4*CMOVE_SLOT_PERIOD)
vp2_vstart			EQU vp1_vstop
vp2_vstop			EQU vp2_vstart+vp2_visible_lines_number

vp2_pf1_depth			EQU 4
vp2_pf2_depth			EQU 3
vp2_pf_depth			EQU vp2_pf1_depth+vp2_pf2_depth

vp2_pf1_colors_number		EQU 16
vp2_pf2_colors_number		EQU 8
vp2_pf_colors_number		EQU vp2_pf1_colors_number+vp2_pf2_colors_number

vp2_pf_pixel_per_datafetch	EQU 64	; 4x

; Viewport 3 
vp3_pixel_per_line		EQU 320
vp3_visible_pixels_number	EQU 320
vp3_visible_lines_number	EQU 48

vp3_hstart			EQU HSTOP_320_PIXEL-(9*CMOVE_SLOT_PERIOD)
vp3_vstart			EQU vp2_vstop
vp3_vstop			EQU vp3_vstart+vp3_visible_lines_number

vp3_pf1_depth			EQU 3
vp3_pf2_depth			EQU 2
vp3_pf_depth			EQU vp3_pf1_depth+vp3_pf2_depth

vp3_pf1_colors_number		EQU 8
vp3_pf2_colors_number		EQU 4
vp3_pf_colors_number		EQU vp3_pf1_colors_number+vp3_pf2_colors_number

vp3_pf_pixel_per_datafetch	EQU 64	; 4x


; Viewport 1 
; Playfield 1 
extra_pf1_plane_width		EQU extra_pf1_x_size/8 ; double buffering
extra_pf2_plane_width		EQU extra_pf2_x_size/8

; Viewport 2
; Playfield 1
extra_pf3_plane_width		EQU extra_pf3_x_size/8
; Playfield 2
extra_pf4_plane_width		EQU extra_pf4_x_size/8 ; tripple buffering
extra_pf5_plane_width		EQU extra_pf5_x_size/8
extra_pf6_plane_width		EQU extra_pf6_x_size/8

; Viewport 3
; Playfield 1 & 2
extra_pf7_plane_width		EQU extra_pf7_x_size/8
extra_pf8_plane_width		EQU extra_pf8_x_size/8


; Viewport 1 
vp1_data_fetch_width		EQU vp1_pixel_per_line/8
vp1_pf1_plane_moduli		EQU (extra_pf1_plane_width*(extra_pf1_depth-1))+extra_pf1_plane_width-vp1_data_fetch_width

; Viewport 2
vp2_data_fetch_width		EQU vp2_pixel_per_line/8
vp2_pf1_plane_moduli		EQU (extra_pf3_plane_width*(extra_pf3_depth-1))+extra_pf3_plane_width-vp2_data_fetch_width
vp2_pf2_plane_moduli		EQU (extra_pf4_plane_width*(extra_pf4_depth-1))+extra_pf4_plane_width-vp2_data_fetch_width

; Viewport 3
vp3_data_fetch_width		EQU vp3_pixel_per_line/8
vp3_pf1_plane_moduli		EQU vp3_data_fetch_width*8
vp3_pf2_plane_moduli		EQU (extra_pf8_plane_width*(extra_pf8_depth-1))+extra_pf8_plane_width-vp3_data_fetch_width


; View 
diwstrt_bits			EQU ((display_window_vstart&$ff)*DIWSTRTF_V0)|(display_window_hstart&$ff)
diwstop_bits			EQU ((display_window_vstop&$ff)*DIWSTOPF_V0)|(display_window_hstop&$ff)
bplcon0_bits			EQU BPLCON0F_ECSENA|((pf_depth>>3)*BPLCON0F_BPU3)|BPLCON0F_COLOR|((pf_depth&$07)*BPLCON0F_BPU0)
bplcon3_bits1			EQU BPLCON3F_SPRES0
bplcon3_bits2			EQU bplcon3_bits1|BPLCON3F_LOCT
bplcon4_bits			EQU (BPLCON4F_OSPRM4*spr_odd_color_table_select)|(BPLCON4F_ESPRM4*spr_even_color_table_select)
diwhigh_bits			EQU (((display_window_hstop&$100)>>8)*DIWHIGHF_HSTOP8)|(((display_window_vstop&$700)>>8)*DIWHIGHF_VSTOP8)|(((display_window_hstart&$100)>>8)*DIWHIGHF_HSTART8)|((display_window_vstart&$700)>>8)
fmode_bits			EQU FMODEF_SPR32|FMODEF_SPAGEM|FMODEF_SSCAN2
color00_bits			EQU $040921
color00_high_bits		EQU $002
color00_low_bits		EQU $491

; Viewport 1
vp1_ddfstrt_bits		EQU DDFSTRT_320_PIXEL
vp1_ddfstop_bits		EQU DDFSTOP_320_PIXEL_4X
vp1_bplcon0_bits		EQU BPLCON0F_ECSENA|((vp1_pf_depth>>3)*BPLCON0F_BPU3)|BPLCON0F_COLOR|((vp1_pf_depth&$07)*BPLCON0F_BPU0)
vp1_bplcon1_bits		EQU 0
vp1_bplcon2_bits		EQU 0
vp1_bplcon3_bits1		EQU bplcon3_bits1
vp1_bplcon3_bits2		EQU vp1_bplcon3_bits1|BPLCON3F_LOCT
vp1_bplcon3_bits3		EQU vp1_bplcon3_bits1|(BPLCON3F_BANK0*7)
vp1_bplcon3_bits4		EQU vp1_bplcon3_bits3|BPLCON3F_LOCT
vp1_bplcon4_bits		EQU bplcon4_bits|(BPLCON4F_BPLAM0*252)
vp1_fmode_bits			EQU fmode_bits|FMODEF_BPL32|FMODEF_BPAGEM
vp1_color00_bits		EQU color00_bits

; Viewport 2
vp2_ddfstrt_bits		EQU DDFSTRT_320_PIXEL
vp2_ddfstop_bits		EQU DDFSTOP_320_PIXEL_4X
vp2_bplcon0_bits		EQU BPLCON0F_ECSENA|((vp2_pf_depth>>3)*BPLCON0F_BPU3)|BPLCON0F_COLOR|BPLCON0F_DPF|((vp2_pf_depth&$07)*BPLCON0F_BPU0)
vp2_bplcon1_bits		EQU 0
vp2_bplcon2_bits		EQU BPLCON2F_PF2PRI
vp2_bplcon3_bits1		EQU bplcon3_bits1|BPLCON3F_PF2OF2
vp2_bplcon3_bits2		EQU vp2_bplcon3_bits1|BPLCON3F_LOCT
vp2_bplcon4_bits		EQU bplcon4_bits
vp2_fmode_bits			EQU fmode_bits|FMODEF_BPL32|FMODEF_BPAGEM
vp2_color00_bits		EQU color00_bits

; Viewport 3
vp3_ddfstrt_bits		EQU DDFSTRT_320_PIXEL
vp3_ddfstop_bits		EQU DDFSTOP_320_PIXEL_4X
vp3_bplcon0_bits		EQU BPLCON0F_ECSENA|((vp3_pf_depth>>3)*BPLCON0F_BPU3)|BPLCON0F_COLOR|BPLCON0F_DPF|((vp3_pf_depth&$07)*BPLCON0F_BPU0)
vp3_bplcon1_bits		EQU 0
vp3_bplcon2_bits		EQU 0
vp3_bplcon3_bits1		EQU bplcon3_bits1|BPLCON3F_PF2OF0|BPLCON3F_PF2OF1
vp3_bplcon3_bits2		EQU vp3_bplcon3_bits1|BPLCON3F_LOCT
vp3_bplcon3_bits3		EQU vp3_bplcon3_bits1|(BPLCON3F_BANK0*7)
vp3_bplcon3_bits4		EQU vp3_bplcon3_bits3|BPLCON3F_LOCT
vp3_bplcon4_bits		EQU bplcon4_bits|(BPLCON4F_BPLAM0*240)
vp3_fmode_bits			EQU fmode_bits|FMODEF_BPL32|FMODEF_BPAGEM
vp3_color00_bits		EQU color00_bits


; Viewport 1 
cl2_hstart1			EQU 0
cl2_vstart1			EQU vp1_vstart

; Viewport 3
cl2_hstart2			EQU 0
cl2_vstart2			EQU vp3_vstart

; Copper-Interrupt
cl2_hstart3			EQU 0
cl2_vstart3			EQU beam_position&CL_Y_WRAPPING


sine_table_length		EQU 512

; Background-Image 1 
bg1_image_x_size		EQU 256
bg1_image_plane_width		EQU bg1_image_x_size/8
bg1_image_y_size		EQU 208
bg1_image_depth			EQU 4
bg1_image_x_position		EQU 16
bg1_image_y_position		EQU MINROW

; Background-Image 2 
bg2_image_x_size		EQU 320
bg2_image_plane_width		EQU bg2_image_x_size/8
bg2_image_y_size		EQU 182
bg2_image_depth			EQU 4

; Ball-Image 
mvb_image_x_size		EQU 16
mvb_image_width			EQU mvb_image_x_size/8
mvb_image_y_size		EQU 11
mvb_image_depth			EQU 3
mvb_image_objects_number	EQU 4

; Horiz-Scrolltext 
hst_image_x_size		EQU 320
hst_image_plane_width		EQU hst_image_x_size/8
hst_image_depth			EQU 2
hst_origin_char_x_size		EQU 32
hst_origin_char_y_size		EQU 26

hst_text_char_x_size		EQU 16
hst_text_char_width		EQU hst_text_char_x_size/8
hst_text_char_y_size		EQU hst_origin_char_y_size
hst_text_char_depth		EQU hst_image_depth

hst_horiz_scroll_window_x_size	EQU vp1_visible_pixels_number+hst_text_char_x_size
hst_horiz_scroll_window_width	EQU hst_horiz_scroll_window_x_size/8
hst_horiz_scroll_window_y_size	EQU hst_text_char_y_size
hst_horiz_scroll_window_depth	EQU hst_image_depth
hst_horiz_scroll_speed1		EQU 2
hst_horiz_scroll_speed2		EQU 8

hst_text_char_x_restart		EQU hst_horiz_scroll_window_x_size
hst_text_chars_number		EQU hst_horiz_scroll_window_x_size/hst_text_char_x_size

hst_text_x_position		EQU 32
hst_text_y_position		EQU 0

; Bounce-VU-Meter 
bvm_bar_height			EQU 6
bvm_bars_number			EQU 4
bvm_max_amplitude		EQU vp1_visible_lines_number-bvm_bar_height
bvm_y_center			EQU vp1_visible_lines_number-bvm_bar_height
bvm_y_angle_speed		EQU 8

; Morph-Vector-Balls 
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
mvb_z_plane1			EQU (-32)+mvb_observer_z
mvb_z_plane2			EQU 0+mvb_observer_z
mvb_z_plane3			EQU 32+mvb_observer_z
mvb_z_plane4			EQU 64+mvb_observer_z

mvb_clear_blit_x_size		EQU extra_pf4_x_size
mvb_clear_blit_y_size		EQU extra_pf4_y_size*(extra_pf4_depth-2)

mvb_copy_blit_x_size		EQU mvb_image_x_size+16
mvb_copy_blit_y_size		EQU mvb_image_y_size*mvb_image_depth

; Chessboard 
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

; Bar-Fader 
bf_rgb8_start_color		EQU 16
bf_rgb8_color_table_offset	EQU 0
bf_rgb8_colors_number		EQU spr_colors_number*(bvm_bar_height/2)*bvm_bars_number

; Bar-Fader-In 
bfi_rgb8_fader_speed_max	EQU 6
bfi_rgb8_fader_radius		EQU bfi_rgb8_fader_speed_max
bfi_rgb8_fader_center		EQU bfi_rgb8_fader_speed_max+1
bfi_rgb8_fader_angle_speed	EQU 3

; Bar-Fader-Out 
bfo_rgb8_fader_speed_max	EQU 6
bfo_rgb8_fader_radius		EQU bfo_rgb8_fader_speed_max
bfo_rgb8_fader_center		EQU bfo_rgb8_fader_speed_max+1
bfo_rgb8_fader_angle_speed	EQU 3

; Image-Fader 
if_rgb8_start_color		EQU 1
if_rgb8_color_table_offset	EQU 1
if_rgb8_colors_number		EQU vp2_pf1_colors_number-1

; Image-Fader-In 
ifi_rgb8_fader_speed_max	EQU 8
ifi_rgb8_fader_radius		EQU ifi_rgb8_fader_speed_max
ifi_rgb8_fader_center		EQU ifi_rgb8_fader_speed_max+1
ifi_rgb8_fader_angle_speed	EQU 4

; Image-Fader-Out 
ifo_rgb8_fader_speed_max	EQU 8
ifo_rgb8_fader_radius		EQU ifo_rgb8_fader_speed_max
ifo_rgb8_fader_center		EQU ifo_rgb8_fader_speed_max+1
ifo_rgb8_fader_angle_speed	EQU 3

; Chessboard-Fader 
cf_rgb8_color_table_offset	EQU 0
cf_rgb8_colors_number		EQU vp3_visible_lines_number*2

; Chessboard-Fader-In 
cfi_rgb8_fader_speed_max	EQU 10
cfi_rgb8_fader_radius		EQU cfi_rgb8_fader_speed_max
cfi_rgb8_fader_center		EQU cfi_rgb8_fader_speed_max+1
cfi_rgb8_fader_angle_speed	EQU 6

; Chessboard-Fader-Out 
cfo_rgb8_fader_speed_max	EQU 10
cfo_rgb8_fader_radius		EQU cfo_rgb8_fader_speed_max
cfo_rgb8_fader_center		EQU cfo_rgb8_fader_speed_max+1
cfo_rgb8_fader_angle_speed	EQU 4

; Sprite-Fader 
sprf_rgb8_start_color		EQU 1
sprf_rgb8_color_table_offset	EQU 1
sprf_rgb8_colors_number		EQU spr_colors_number-1

; Sprite-Fader-In 
sprfi_rgb8_fader_speed_max	EQU 1
sprfi_rgb8_fader_radius		EQU sprfi_rgb8_fader_speed_max
sprfi_rgb8_fader_center		EQU sprfi_rgb8_fader_speed_max+1
sprfi_rgb8_fader_angle_speed	EQU 1

; Sprite-Fader-Out 
sprfo_rgb8_fader_speed_max	EQU 8
sprfo_rgb8_fader_radius		EQU sprfo_rgb8_fader_speed_max
sprfo_rgb8_fader_center		EQU sprfo_rgb8_fader_speed_max+1
sprfo_rgb8_fader_angle_speed	EQU 4

; Fade-Balls-In 
fbi_delay			EQU 10

; Fade-Balls-Out 
fbo_delay			EQU 5

; Colors-Fader-Cross 
cfc_rgb8_start_color		EQU 17
cfc_rgb8_color_table_offset	EQU 1
cfc_rgb8_colors_number		EQU vp2_pf2_colors_number-1
cfc_rgb8_color_tables_number	EQU 4
cfc_rgb8_fader_speed_max	EQU 6
cfc_rgb8_fader_radius		EQU cfc_rgb8_fader_speed_max
cfc_rgb8_fader_center		EQU cfc_rgb8_fader_speed_max+1
cfc_rgb8_fader_angle_speed	EQU 1
cfc_rgb8_fader_delay		EQU 9*PAL_FPS ; 9 seconds


vp1_pf1_plane_x_offset		EQU 1*vp1_pf_pixel_per_datafetch
vp1_pf1_plane_y_offset		EQU 0


	INCLUDE "except-vectors.i"


	INCLUDE "extra-pf-attributes.i"


	INCLUDE "sprite-attributes.i"


; PT-Replay
	INCLUDE "music-tracker/pt-song.i"

	INCLUDE "music-tracker/pt-temp-channel.i"


; Bounce-VU-Meter 
	RSRESET

audio_channel_info		RS.B 0

aci_yangle			RS.W 1
aci_amplitude			RS.W 1

audio_channel_info_size		RS.B 0


; Morph-Vector-Balls 
	RSRESET

mvb_morph_shape			RS.B 0

mvb_morph_shape_object_table	RS.L 1

mvb_morph_shape_size		RS.B 0


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

	INCLUDE "copperlist1.i"

cl1_extension1_entry		RS.B cl1_extension1_size

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
cl2_ext1_WAIT1			RS.L 1
cl2_ext1_BPLCON0		RS.L 1

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

cl2_extension3_size		RS.B 0


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

cl2_extension4_size		RS.B 0


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

; Viewport 1 
cl2_extension1_entry		RS.B cl2_extension1_size
cl2_extension2_entry		RS.B cl2_extension2_size*vp1_visible_lines_number

; Viewport 2
cl2_extension3_entry		RS.B cl2_extension3_size

; Viewport 3
cl2_extension4_entry		RS.B cl2_extension4_size
cl2_extension5_entry		RS.B cl2_extension5_size*vp3_visible_lines_number

; Copper-Interrupt
cl1_WAIT			RS.L 1
cl1_INTREQ			RS.L 1

cl2_end				RS.L 1

copperlist2_size		RS.B 0


cl1_size1			EQU 0
cl1_size2			EQU 0
cl1_size3			EQU copperlist1_size

cl2_size1			EQU 0
cl2_size2			EQU copperlist2_size
cl2_size3			EQU copperlist2_size


; Sprite0 additional structure 
	RSRESET

spr0_extension1			RS.B 0

spr0_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr0_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*bg1_image_y_size

spr0_extension1_size		RS.B 0

; Sprite0 main structure 
	RSRESET

spr0_begin			RS.B 0

spr0_extension1_entry		RS.B spr0_extension1_size

spr0_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite0_size			RS.B 0

; Sprite1 additional structure 
	RSRESET

spr1_extension1			RS.B 0

spr1_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr1_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*bg1_image_y_size

spr1_extension1_size		RS.B 0

; sprite1 main structure 
	RSRESET

spr1_begin			RS.B 0

spr1_extension1_entry		RS.B spr1_extension1_size

spr1_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite1_size			RS.B 0

; Sprite2 additional structure 
	RSRESET

spr2_extension1			RS.B 0

spr2_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr2_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*bg1_image_y_size

spr2_extension1_size		RS.B 0

; Sprite2 main structure 
	RSRESET

spr2_begin			RS.B 0

spr2_extension1_entry		RS.B spr2_extension1_size

spr2_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite2_size			RS.B 0

; Sprite3 additional structure 
	RSRESET

spr3_extension1			RS.B 0

spr3_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr3_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*bg1_image_y_size

spr3_extension1_size		RS.B 0

; Sprite3 main structure 
	RSRESET

spr3_begin			RS.B 0

spr3_extension1_entry		RS.B spr3_extension1_size

spr3_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite3_size			RS.B 0

; Sprite4 additional structure 
	RSRESET

spr4_extension1			RS.B 0

spr4_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr4_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*bg1_image_y_size

spr4_extension1_size		RS.B 0

; Sprite4 main structure 
	RSRESET

spr4_begin			RS.B 0

spr4_extension1_entry		RS.B spr4_extension1_size

spr4_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite4_size			RS.B 0

; Sprite5 additional structure 
	RSRESET

spr5_extension1			RS.B 0

spr5_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr5_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*bg1_image_y_size

spr5_extension1_size		RS.B 0

; Sprite5 main structure 
	RSRESET

spr5_begin			RS.B 0

spr5_extension1_entry		RS.B spr5_extension1_size

spr5_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite5_size			RS.B 0

; Sprite6 additional structure 
	RSRESET

spr6_extension1			RS.B 0

spr6_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr6_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*bg1_image_y_size

spr6_extension1_size		RS.B 0

; Sprite6 main structure 
	RSRESET

spr6_begin			RS.B 0

spr6_extension1_entry		RS.B spr6_extension1_size

spr6_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite6_size			RS.B 0

; Sprite7 additional structure 
	RSRESET

spr7_extension1			RS.B 0

spr7_ext1_header		RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)
spr7_ext1_planedata		RS.L (spr_pixel_per_datafetch/WORD_BITS)*bg1_image_y_size

spr7_extension1_size		RS.B 0

; Sprite7 main structure 
	RSRESET

spr7_begin			RS.B 0

spr7_extension1_entry		RS.B spr7_extension1_size

spr7_end			RS.L 1*(spr_pixel_per_datafetch/WORD_BITS)

sprite7_size			RS.B 0


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
spr0_y_size2			EQU sprite0_size/(spr_x_size2/4)
spr1_x_size2			EQU spr_x_size2
spr1_y_size2			EQU sprite1_size/(spr_x_size2/4)
spr2_x_size2			EQU spr_x_size2
spr2_y_size2			EQU sprite2_size/(spr_x_size2/4)
spr3_x_size2			EQU spr_x_size2
spr3_y_size2			EQU sprite3_size/(spr_x_size2/4)
spr4_x_size2			EQU spr_x_size2
spr4_y_size2			EQU sprite4_size/(spr_x_size2/4)
spr5_x_size2			EQU spr_x_size2
spr5_y_size2			EQU sprite5_size/(spr_x_size2/4)
spr6_x_size2			EQU spr_x_size2
spr6_y_size2			EQU sprite6_size/(spr_x_size2/4)
spr7_x_size2			EQU spr_x_size2
spr7_y_size2			EQU sprite7_size/(spr_x_size2/4)


; Extra-Memory 
	RSRESET

em_bitmap_table			RS.B cb_source_x_size*cb_destination_y_size
	RS_ALIGN_LONGWORD
em_rgb8_color_table		RS.L vp3_visible_lines_number*2
extra_memory_size		RS.B 0


	RSRESET

	INCLUDE "main-variables.i"

save_a7				RS.L 1

; PT-Replay 
	IFD PROTRACKER_VERSION_2 
		INCLUDE "music-tracker/pt2-variables.i"
	ENDC
	IFD PROTRACKER_VERSION_3
		INCLUDE "music-tracker/pt3-variables.i"
	ENDC

pt_effects_handler_active	RS.W 1
pt_skip_commands_enabled	RS.W 1

; Viewport 1 
	RS_ALIGN_LONGWORD
vp1_pf1_construction2		RS.L 1
vp1_pf1_display			RS.L 1

; Viewport 2 
vp2_pf2_construction1		RS.L 1
vp2_pf2_construction2		RS.L 1
vp2_pf2_display			RS.L 1

; Horiz-Scrolltext 
hst_active			RS.W 1
	RS_ALIGN_LONGWORD
hst_image			RS.L 1
hst_text_table_start		RS.W 1
hst_text_BLTCON0_bits		RS.W 1
hst_char_toggle_image		RS.W 1
hst_horiz_scroll_speed		RS.W 1

; Morph-Vector-Balls 
mvb_rotation_x_angle		RS.W 1
mvb_rotation_y_angle		RS.W 1
mvb_rotation_z_angle		RS.W 1

mvb_morph_active		RS.W 1
mvb_morph_shapes_table_start	RS.W 1

mvb_mask			RS.W 1

; Chessboard 
cb_stripes_y_angle		RS.W 1
cb_stripes_y_angle_speed	RS.W 1

; Bar-Fader 
bf_rgb8_colors_counter		RS.W 1
bf_rgb8_copy_colors_active	RS.W 1

; Bar-Fader-In 
bfi_rgb8_active			RS.W 1
bfi_rgb8_fader_angle		RS.W 1

; Bar-Fader-Out 
bfo_rgb8_active			RS.W 1
bfo_rgb8_fader_angle		RS.W 1

; Image-Fader 
if_rgb8_colors_counter		RS.W 1
if_rgb8_copy_colors_active	RS.W 1

; Image-Fader-In 
ifi_rgb8_active			RS.W 1
ifi_rgb8_fader_angle		RS.W 1

; Image-Fader-Out 
ifo_rgb8_active			RS.W 1
ifo_rgb8_fader_angle		RS.W 1

; Chessboard-Fader 
cf_rgb8_colors_counter		RS.W 1

; Chessboard-Fader-In 
cfi_rgb8_active			RS.W 1
cfi_rgb8_fader_angle		RS.W 1

; Chessboard-Fader-Out 
cfo_rgb8_active			RS.W 1
cfo_rgb8_fader_angle		RS.W 1

; Sprite-Fader 
sprf_rgb8_colors_counter	RS.W 1
sprf_rgb8_copy_colors_active	RS.W 1

; Sprite-Fader-In 
sprfi_rgb8_active		RS.W 1
sprfi_rgb8_fader_angle		RS.W 1

; Sprite-Fader-Out 
sprfo_rgb8_active		RS.W 1
sprfo_rgb8_fader_angle		RS.W 1

; Fade-Balls 
fb_mask				RS.W 1

; Fade-Balls-In 
fbi_active			RS.W 1
fbi_delay_counter		RS.W 1

; Fade-Balls-Out 
fbo_active			RS.W 1
fbo_delay_counter		RS.W 1

; Colors-Fader-Cross 
cfc_rgb8_active			RS.W 1
cfc_rgb8_fader_angle		RS.W 1
cfc_rgb8_fader_delay_counter	RS.W 1
cfc_rgb8_color_table_start	RS.W 1
cfc_rgb8_colors_counter		RS.W 1
cfc_rgb8_copy_colors_active	RS.W 1

; Main 
stop_fx_active			RS.W 1
quit_active			RS.W 1

variables_size			RS.B 0


	SECTION code,CODE


	INCLUDE "sys-wrapper.i"


	CNOP 0,4
init_main_variables

; Viewport 1
	move.l	extra_pf1(a3),vp1_pf1_construction2(a3)
	move.l	extra_pf2(a3),vp1_pf1_display(a3)

; Viewport 2
	move.l	extra_pf4(a3),vp2_pf2_construction1(a3)
	move.l	extra_pf5(a3),vp2_pf2_construction2(a3)
	move.l	extra_pf6(a3),vp2_pf2_display(a3)

; PT-Replay
	IFD PROTRACKER_VERSION_2 
		PT2_INIT_VARIABLES
	ENDC

	IFD PROTRACKER_VERSION_3
		PT3_INIT_VARIABLES
	ENDC

	moveq	#TRUE,d0
	move.w	d0,pt_effects_handler_active(a3)
	moveq	#FALSE,d1
	move.w	d1,pt_skip_commands_enabled(a3)

; Horiz-Scrolltext
	move.w	d1,hst_active(a3)
	lea	hst_image_data,a0
	move.l	a0,hst_image(a3)
	move.w	d0,hst_text_table_start(a3)
	move.w	d0,hst_text_bltcon0_bits(a3)
	move.w	d0,hst_char_toggle_image(a3)
	moveq	#hst_horiz_scroll_speed1,d2
	move.w	d2,hst_horiz_scroll_speed(a3)

; Morph-Vector-Balls
	move.w	d0,mvb_rotation_x_angle(a3)
	move.w	d0,mvb_rotation_y_angle(a3)
	move.w	d0,mvb_rotation_z_angle(a3)

	IFEQ mvb_premorph_enabled
		move.w	d0,mvb_morph_active(a3)
	ELSE
		move.w	d1,mvb_morph_active(a3)
	ENDC
	move.w	d0,mvb_morph_shapes_table_start(a3)

	move.w	d0,mvb_mask(a3)

; Chessboard 
	move.w	d0,cb_stripes_y_angle(a3)
	move.w	#cb_stripes_y_angle_speed1,cb_stripes_y_angle_speed(a3)

; Bar-Fader 
	move.w	d0,bf_rgb8_colors_counter(a3)
	move.w	d1,bf_rgb8_copy_colors_active(a3)

; Bar-Fader-In 
	move.w	d1,bfi_rgb8_active(a3)
	MOVEF.W sine_table_length/4,d2
	move.w	d2,bfi_rgb8_fader_angle(a3) ; 90�

; Bar-Fader-Out 
	move.w	d1,bfo_rgb8_active(a3)
	move.w	d2,bfo_rgb8_fader_angle(a3) ; 90�

; Image-Fader 
	move.w	d0,if_rgb8_colors_counter(a3)
	move.w	d1,if_rgb8_copy_colors_active(a3)

; Image-Fader-In 
	move.w	d1,ifi_rgb8_active(a3)
	move.w	d2,ifi_rgb8_fader_angle(a3) ; 90�

; Image-Fader-Out 
	move.w	d1,ifo_rgb8_active(a3)
	move.w	d2,ifo_rgb8_fader_angle(a3) ; 90�

; Chessboard-Fader 
	move.w	d0,cf_rgb8_colors_counter(a3)

; Chessboard-Fader-In 
	move.w	d1,cfi_rgb8_active(a3)
	move.w	d2,cfi_rgb8_fader_angle(a3) ; 90�

; Chessboard-Fader-Out 
	move.w	d1,cfo_rgb8_active(a3)
	move.w	d2,cfo_rgb8_fader_angle(a3) ; 90�

; Sprite-Fader 
	move.w	d0,sprf_rgb8_colors_counter(a3)
	move.w	d1,sprf_rgb8_copy_colors_active(a3)

; Sprite-Fader-In 
	move.w	d1,sprfi_rgb8_active(a3)
	MOVEF.W sine_table_length/4,d2
	move.w	d2,sprfi_rgb8_fader_angle(a3) ; 90�

; Sprite-Fader-Out 
	move.w	d1,sprfo_rgb8_active(a3)
	move.w	d2,sprfo_rgb8_fader_angle(a3) ; 90�

; Fade-Balls 
	move.w	#$8888,fb_mask(a3)

; Fade-Balls-In 
	move.w	d1,fbi_active(a3)
	move.w	d1,fbi_delay_counter(a3)

; Fade-Balls-Out 
	move.w	d1,fbo_active(a3)
	move.w	d1,fbo_delay_counter(a3)

; Colors-Fader-Cross 
	IFEQ cfc_rgb8_prefade_enabled
		move.w	d0,cfc_rgb8_active(a3)
		move.w	#cfc_rgb8_colors_number*3,cfc_rgb8_colors_counter(a3)
		move.w	d0,cfc_rgb8_copy_colors_active(a3)
	ELSE
		move.w	d1,cfc_rgb8_active(a3)
		move.w	d0,cfc_rgb8_colors_counter(a3)
		move.w	d1,cfc_rgb8_copy_colors_active(a3)
	ENDC
	move.w	d2,cfc_rgb8_fader_angle(a3) ; 90�
	move.w	d1,cfc_rgb8_fader_delay_counter(a3)
	move.w	d0,cfc_rgb8_color_table_start(a3)

; Main 
	move.w	d1,stop_fx_active(a3)
	move.w	d1,quit_active(a3)
	rts


	CNOP 0,4
init_main
	bsr.s	pt_DetectSysFrequ
	bsr.s	pt_InitRegisters
	bsr	pt_InitAudTempStrucs
	bsr	pt_ExamineSongStruc
	bsr	pt_InitFtuPeriodTableStarts

	bsr	hst_init_chars_offsets
	bsr	hst_init_chars_x_positions
	bsr	hst_init_chars_images

	bsr	bvm_init_audio_channels_info
	bsr	bvm_init_rgb8_color_table

	bsr	bg2_copy_image_to_bitplane

	bsr	mvb_init_object_coordinates
	bsr	mvb_init_morph_shapes
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
	bsr	init_second_copperlist
	rts


; PT-Replay 
	PT_DETECT_SYS_FREQUENCY

	PT_INIT_REGISTERS

	PT_INIT_AUDIO_TEMP_STRUCTURES

	PT_EXAMINE_SONG_STRUCTURE

	PT_INIT_FINETUNE_TABLE_STARTS


; Horiz-Scrolltext 
	INIT_CHARS_OFFSETS.W hst

	INIT_CHARS_X_POSITIONS hst,LORES

	INIT_CHARS_IMAGES hst


; Bouncing-VU-Meter 
	CNOP 0,4
bvm_init_audio_channels_info
	lea	bvm_audio_channel1_info(pc),a0
	move.w	#sine_table_length/4,(a0)+ ; y angle 90� = max amplitude
	moveq	#0,d1
	move.w	d1,(a0)			; amplitude = 0
	lea	bvm_audio_channel2_info(pc),a0
	move.w	d0,(a0)+
	move.w	d1,(a0)
	lea	bvm_audio_channel3_info(pc),a0
	move.w	d0,(a0)+
	move.w	d1,(a0)
	lea	bvm_audio_channel4_info(pc),a0
	move.w	d0,(a0)+
	move.w	d1,(a0)
	rts


	CNOP 0,4
bvm_init_rgb8_color_table
	move.l	#color00_bits,d1
	lea	bvm_rgb8_color_gradients(pc),a0 ; source
	lea	bfi_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination
	moveq	#bvm_bars_number-1,d7
bvm_init_rgb8_color_table_loop1
	moveq	#(bvm_bar_height/2)-1,d6
bvm_init_rgb8_color_table_loop2
	move.l	(a0)+,d0		; RGB8
	move.l	d1,(a1)+		; COLOR00
	moveq	#(spr_colors_number-1)-1,d5 ; number of color values per palette
bvm_init_rgb8_color_table_loop3
	move.l	d0,(a1)+		; RGB8
	dbf	d5,bvm_init_rgb8_color_table_loop3
	dbf	d6,bvm_init_rgb8_color_table_loop2
	dbf	d7,bvm_init_rgb8_color_table_loop1
	rts


; Background-Image2
	COPY_IMAGE_TO_BITPLANE bg2,,,extra_pf3


; Morph-Vector-Balls 
	CNOP 0,4
mvb_init_object_coordinates
	lea	mvb_object_coordinates_offsets(pc),a0
	moveq	#0,d0			; start offset
	moveq	#mvb_object_points_number-1,d7
mvb_init_object_coordinates_loop
	move.w	d0,(a0)+		; offset xyz coordinate
	addq.w	#3,d0			; next xyz coodinate
	dbf	d7,mvb_init_object_coordinates_loop
	rts

	CNOP 0,4
mvb_init_morph_shapes
	lea	mvb_morph_shapes_table(pc),a0
	lea	mvb_object_shape1_coordinates(pc),a1
	move.l	a1,(a0)+		; shape table
	lea	mvb_object_shape2_coordinates(pc),a1
	IFEQ mvb_morph_loop_enabled
		move.l	a1,(a0)		; shape table
	ELSE
		move.l	a1,(a0)+	; shape table
		lea	mvb_object_shape3_coordinates(pc),a1
		move.l	a1,(a0)		; shape table
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


; Chessboard 
	CNOP 0,4
cb_init_chessboard_image
	movem.w cb_fill_pattern(pc),d0-d3 ; fill pattern
	move.l	extra_pf7(a3),a0
	move.l	(a0)+,a1		; bitplane 1
	move.l	(a0),a2			; bitplane 2
	moveq	#(cb_source_x_size/32)-1,d7
cb_init_chessboard_image_loop
	move.w	d0,(a1)+		; 1st word: bitplane 1
	move.w	d1,(a2)+		; 1st word: bitplane 2
	move.w	d2,(a1)+		; 2nd word: bitplane 1
	move.w	d3,(a2)+		; 2nd word: bitplane 2
	dbf	d7,cb_init_chessboard_image_loop
	rts


	CNOP 0,4
cb_init_bitmap_table
	move.l	extra_memory(a3),a0
	ADDF.L	em_bitmap_table,a0
	move.w	#cb_source_x_size,a1
	move.l	a1,d3
	moveq	#(cb_destination_x_size)/16,d4
	swap	d3			; *2^16
	lsl.w	#4,d4
	MOVEF.W cb_destination_y_size-1,d7
cb_init_bitmap_table_loop1
	move.l	d3,d2			; low longword: source width
	moveq	#0,d6			; high longword: source width
	divu.l	d4,d6:d2		; F=width source/width destination
	moveq	#0,d1
	move.w	d4,d6			; width destination
	subq.w	#1,d6			; loop until false
cb_init_bitmap_table_loop2
	move.l	d1,d0			; F
	swap	d0			; /2^16 = bitmap position
	add.l	d2,d1			; decrease F (p*F)
	addq.b	#1,(a0,d0.w)		; set pixel in bitmap table
	dbf	d6,cb_init_bitmap_table_loop2
	add.l	a1,a0			; next line in bitmap table
	addq.l	#cb_destination_plane_width_step,d4 ; decrease width destination
	dbf	d7,cb_init_bitmap_table_loop1
	rts


	CNOP 0,4
cb_init_color_tables
	lea	cb_color_gradient1(pc),a0 ; source1
	lea	cb_color_gradient2(pc),a1 ; source2
	lea	cfi_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a2 ; destination
	moveq	#vp3_visible_lines_number-1,d7
cb_init_color_tables_loop1
	move.l	(a0)+,(a2)+
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
	bsr.s	spr_init_pointers_table
	bsr.s	bg1_init_attached_sprites_cluster
	rts


	INIT_SPRITE_POINTERS_TABLE


	INIT_ATTACHED_SPRITES_CLUSTER bg1,spr_pointers_display,bg1_image_x_position,bg1_image_y_position,spr_x_size2,bg1_image_y_size,,,REPEAT


	CNOP 0,4
init_CIA_timers

; PT-Replay
	PT_INIT_TIMERS
	rts


	CNOP 0,4
init_first_copperlist
	move.l	cl1_display(a3),a0
	bsr.s	cl1_init_playfield_props
	bsr.s	cl1_init_sprite_pointers
	bsr	cl1_init_colors
	bsr	cl1_vp2_init_bitplane_pointers
	COP_MOVEQ 0,COPJMP2
	bsr	cl1_set_sprite_pointers
	bsr	cl1_vp2_pf1_set_bitplane_pointers
	rts


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
cl1_vp2_init_bitplane_pointers
	COP_MOVEQ 0,BPL3PTH
	COP_MOVEQ 0,BPL3PTL
	COP_MOVEQ 0,BPL5PTH
	COP_MOVEQ 0,BPL5PTL
	COP_MOVEQ 0,BPL7PTH
	COP_MOVEQ 0,BPL7PTL
	rts


	COP_SET_SPRITE_POINTERS cl1,display,spr_number


	CNOP 0,4
cl1_vp2_pf1_set_bitplane_pointers
	move.l	cl1_display(a3),a0
	ADDF.L	cl1_extension1_entry+cl1_ext1_BPL3PTH+WORD_SIZE,a0
	move.l	extra_pf3(a3),a1
	addq.w	#LONGWORD_SIZE,a1	; bitplane 2
	moveq	#(vp2_pf1_depth-1)-1,d7
cl1_vp2_pf1_set_bitplane_pointers_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	addq.w	#QUADWORD_SIZE,a0
	move.w	(a1)+,LONGWORD_SIZE-(QUADWORD_SIZE)(a0) ; BPLxPTL
	dbf	d7,cl1_vp2_pf1_set_bitplane_pointers_loop
	rts


	CNOP 0,4
init_second_copperlist
	move.l	cl2_construction2(a3),a0
; Viewport 1
	bsr	cl2_vp1_init_playfield_props
	bsr	cl2_vp1_init_bitplane_pointers
	bsr	cl2_vp1_init_start_display
	bsr	cl2_vp1_init_color_gradient
; Viewport 2
	bsr	cl2_vp2_init_start_display
	bsr	cl2_vp2_init_playfield_props
	bsr	cl2_vp2_init_bitplane_pointers
; Viewport 3
	bsr	cl2_vp3_init_start_display
	bsr	cl2_vp3_init_playfield_props
	bsr	cl2_vp3_init_bitplane_pointers
	bsr	cl2_vp3_init_color_gradient
; Copper-Interrupt
	bsr	cl2_init_copper_interrupt
	COP_LISTEND
; Viewport 1
	bsr	cl2_vp1_pf1_set_bitplane_pointers
	bsr	cl2_vp1_set_fill_gradient
	bsr	cl2_vp1_set_outline_gradient
; Viewport 2
	bsr	cl2_vp2_pf1_set_bitplane_pointers
; Viewport 3
	bsr	cl2_vp3_pf1_set_bitplane_pointers
	bsr	cl2_vp3_pf2_set_bitplane_pointers

	bsr	copy_second_copperlist
	bsr	swap_second_copperlist
	bsr	set_second_copperlist

	bsr	set_vp1_playfield1

	bsr	set_vp2_playfield2
	rts


; Viewport 1 
	COP_INIT_PLAYFIELD_REGISTERS cl2,,vp1

	CNOP 0,4
cl2_vp1_init_bitplane_pointers
	move.w #BPL1PTH,d0
	moveq	#(vp1_pf1_depth*2)-1,d7
cl2_vp1_init_bitplane_pointers_loop
	move.w	d0,(a0)			; BPLxPTH/L
	addq.w	#WORD_SIZE,d0		; next register
	addq.w	#LONGWORD_SIZE,a0	; next bitplane pointer in cl
	dbf	d7,cl2_vp1_init_bitplane_pointers_loop
	rts

	CNOP 0,4
cl2_vp1_init_start_display
	COP_WAIT vp1_hstart,vp1_vstart
	COP_MOVEQ vp1_bplcon0_bits,BPLCON0
	rts

	CNOP 0,4
cl2_vp1_init_color_gradient
	move.l	#(((cl2_vstart1<<24)|(((cl2_hstart1/4)*2)<<16))|$10000)|$fffe,d0 ; CWAIT
	move.l	#(BPLCON3<<16)|vp1_bplcon3_bits3,d1 ; color high
	move.l	#(COLOR29<<16)|color00_high_bits,d2
	move.l	#(COLOR30<<16)|color00_high_bits,d3
	move.l	#(BPLCON3<<16)|vp1_bplcon3_bits4,d4 ; color low
	move.l	#(COLOR29<<16)|color00_low_bits,d5
	move.l	#1<<24,d6		; next line
	move.l	#(COLOR30<<16)|color00_low_bits,a1
	move.l	#(BPLCON4<<16)|vp1_bplcon4_bits,a2
	MOVEF.W vp1_visible_lines_number-1,d7
cl2_vp1_init_color_gradient_loop
	move.l	d0,(a0)+		; CWAIT
	move.l	d1,(a0)+		; BPLCON3 color high
	move.l	d2,(a0)+		; COLOR29
	move.l	d3,(a0)+		; COLOR30
	move.l	d4,(a0)+		; BPLCON3 color low
	move.l	d5,(a0)+		; COLOR39
	move.l	a1,(a0)+		; COLOR30
	add.l	d6,d0			; next line
	move.l	a2,(a0)+		; BPLCON4
	dbf	d7,cl2_vp1_init_color_gradient_loop
	rts


; Viewport 2
	CNOP 0,4
cl2_vp2_init_start_display
	COP_WAIT vp2_hstart,vp2_vstart-1
	rts

	COP_INIT_PLAYFIELD_REGISTERS cl2,,vp2

	CNOP 0,4
cl2_vp2_init_bitplane_pointers
	COP_MOVEQ 0,BPL1PTH
	COP_MOVEQ 0,BPL1PTL
	COP_MOVEQ 0,BPL2PTH
	COP_MOVEQ 0,BPL2PTL
	COP_MOVEQ 0,BPL4PTH
	COP_MOVEQ 0,BPL4PTL
	COP_MOVEQ 0,BPL6PTH
	COP_MOVEQ 0,BPL6PTL
	COP_MOVEQ vp2_bplcon0_bits,BPLCON0
	rts


; Viewport 3
	CNOP 0,4
cl2_vp3_init_start_display
	COP_WAIT vp3_hstart,vp3_vstart-1
	rts

	COP_INIT_PLAYFIELD_REGISTERS cl2,,vp3

	CNOP 0,4
cl2_vp3_init_bitplane_pointers
	COP_MOVEQ 0,BPL1PTH
	COP_MOVEQ 0,BPL1PTL
	COP_MOVEQ 0,BPL2PTH
	COP_MOVEQ 0,BPL2PTL
	COP_MOVEQ 0,BPL3PTH
	COP_MOVEQ 0,BPL3PTL
	COP_MOVEQ 0,BPL4PTH
	COP_MOVEQ 0,BPL4PTL
	COP_MOVEQ 0,BPL5PTH
	COP_MOVEQ 0,BPL5PTL
	COP_MOVEQ vp3_bplcon0_bits,BPLCON0
	rts

	CNOP 0,4
cl2_vp3_init_color_gradient
	move.l	#(((cl2_vstart2<<24)|(((cl2_hstart2/4)*2)<<16))|$10000)|$fffe,d0 ; CWAIT
	move.l	#(BPLCON3<<16)|vp3_bplcon3_bits3,d1 ; color high
	move.l	#(COLOR25<<16)|color00_high_bits,d2
	move.l	#(COLOR26<<16)|color00_high_bits,d3
	move.l	#(BPLCON3<<16)|vp3_bplcon3_bits4,d4 ; color low
	move.l	#(((CL_Y_WRAPPING<<24)|(((cl2_hstart2/4)*2)<<16))|$10000)|$fffe,d5 ; CWAIT
	move.l	#1<<24,d6		; next line
	move.l	#(COLOR25<<16)|color00_low_bits,a1
	move.l	#(COLOR26<<16)|color00_low_bits,a2
	moveq	#vp3_visible_lines_number-1,d7
cl2_vp3_init_color_gradient_loop
	move.l	d0,(a0)+		; CWAIT
	move.l	d1,(a0)+		; BPLCON3 color high
	move.l	d2,(a0)+		; COLOR25
	move.l	d3,(a0)+		; COLOR26
	move.l	d4,(a0)+		; BPLCON3 color low
	move.l	a1,(a0)+		; COLOR25
	move.l	a2,(a0)+		; COLOR26
	COP_MOVEQ 0,NOOP
	cmp.l	d5,d0			; y wrapping ?
	bne.s	cl2_vp3_init_color_gradient_skip
	subq.w	#LONGWORD_SIZE,a0
	COP_WAIT CL_X_WRAPPING,CL_Y_WRAPPING ; patch cl
cl2_vp3_init_color_gradient_skip
	add.l	d6,d0			; next line
	dbf	d7,cl2_vp3_init_color_gradient_loop
	rts


	COP_INIT_COPINT cl2,cl2_hstart3,cl2_vstart3


; Viewport 1 
	CNOP 0,4
cl2_vp1_pf1_set_bitplane_pointers
	move.l	cl2_display(a3),a0 
	ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1PTH+WORD_SIZE,a0
	move.l	vp1_pf1_display(a3),a1
	moveq	#vp1_pf1_depth-1,d7
cl2_vp1_pf1_set_bitplane_pointers_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	addq.w	#QUADWORD_SIZE,a0
	move.w	(a1)+,LONGWORD_SIZE-QUADWORD_SIZE(a0) ; BPLxPTL
	dbf	d7,cl2_vp1_pf1_set_bitplane_pointers_loop
	rts

	CNOP 0,4
cl2_vp1_set_fill_gradient
	move.w	#RB_NIBBLES_MASK,d3
	lea	hst_fill_gradient(pc),a0
	move.l	cl2_construction2(a3),a1
	ADDF.W	cl2_extension2_entry+cl2_ext2_COLOR29_high8+WORD_SIZE,a1
	move.w	#cl2_extension2_size,a2
	lea	(a1,a2.l*2),a1		; skip two rasterlines
	MOVEF.W (vp1_visible_lines_number-4)-1,d7
cl2_vp1_set_fill_gradient_loop
	move.l	(a0)+,d0
	move.l	d0,d2
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(a1)			; color high
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,cl2_ext2_COLOR29_low8-cl2_ext2_COLOR29_high8(a1) ; color low
	add.l	a2,a1
	dbf	d7,cl2_vp1_set_fill_gradient_loop
	rts

	CNOP 0,4
cl2_vp1_set_outline_gradient
	move.w	#RB_NIBBLES_MASK,d3
	lea	hst_outline_gradient(pc),a0
	move.l	cl2_construction2(a3),a1
	ADDF.W	cl2_extension2_entry+cl2_ext2_COLOR30_high8+WORD_SIZE,a1
	move.w	#cl2_extension2_size,a2
	MOVEF.W vp1_visible_lines_number-1,d7
cl2_vp1_set_outline_gradient_loop
	move.l	(a0)+,d0
	move.l	d0,d2
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(a1)			; color high
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,cl2_ext2_COLOR30_low8-cl2_ext2_COLOR30_high8(a1) ; color low
	add.l	a2,a1
	dbf	d7,cl2_vp1_set_outline_gradient_loop
	rts


; Viewport 2 
	CNOP 0,4
cl2_vp2_pf1_set_bitplane_pointers
	move.l	cl2_construction2(a3),a0
	ADDF.L	cl2_extension3_entry+cl2_ext3_BPL1PTH+WORD_SIZE,a0
	move.l	extra_pf3(a3),a1
	moveq	#(vp2_pf1_depth-3)-1,d7
cl2_vp2_pf1_set_bitplane_pointers_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	addq.w	#QUADWORD_SIZE,a0
	move.w	(a1)+,LONGWORD_SIZE-QUADWORD_SIZE(a0) ; BPLxPTL
	dbf	d7,cl2_vp2_pf1_set_bitplane_pointers_loop
	rts


; Viewport 3 
	CNOP 0,4
cl2_vp3_pf1_set_bitplane_pointers
	move.l	cl2_construction2(a3),a0
	ADDF.L	cl2_extension4_entry+cl2_ext4_BPL1PTH+WORD_SIZE,a0
	move.l	extra_pf4(a3),a1
	moveq	#vp3_pf1_depth-1,d7
cl2_vp3_pf1_set_bitplane_pointers_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	ADDF.W	QUADWORD_SIZE*2,a0
	move.w	(a1)+,LONGWORD_SIZE-(QUADWORD_SIZE*2)(a0) ; BPLxPTL
	dbf	d7,cl2_vp3_pf1_set_bitplane_pointers_loop
	rts

	CNOP 0,4
cl2_vp3_pf2_set_bitplane_pointers
	move.l	cl2_construction2(a3),a0
	ADDF.L	cl2_extension4_entry+cl2_ext4_BPL2PTH+WORD_SIZE,a0
	move.l	extra_pf8(a3),a1
	moveq	#vp3_pf2_depth-1,d7
cl2_vp3_pf2_set_bitplane_pointers_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	ADDF.W	QUADWORD_SIZE*2,a0
	move.w	(a1)+,LONGWORD_SIZE-(QUADWORD_SIZE*2)(a0) ; BPLxPTL
	dbf	d7,cl2_vp3_pf2_set_bitplane_pointers_loop
	rts


	COPY_COPPERLIST cl2,2


	CNOP 0,4
main
	bsr.s	no_sync_routines
	bsr	beam_routines
	rts


	CNOP 0,4
no_sync_routines
	IFEQ cfc_rgb8_prefade_enabled
		bsr	cfc_rgb8_init_start_colors
	ENDC
	bsr	cb_scale_image
	rts


	IFEQ cfc_rgb8_prefade_enabled
; Color-Fader-Cross
		CNOP 0,4
cfc_rgb8_init_start_colors
		bsr	cfc_rgb8_copy_color_table
		bsr	rgb8_colors_fader_cross
		tst.w	cfc_rgb8_copy_colors_active(a3)
		beq.s	cfc_rgb8_init_start_colors
		move.w	#FALSE,cfc_rgb8_copy_colors_active(a3)
		rts
	ENDC


; Chessboard
	CNOP 0,4
cb_scale_image
	movem.l a4-a5,-(a7)
	moveq	#0,d4			; 1st x coordinate destination image
	move.l	extra_memory(a3),a0
	ADDF.L	em_bitmap_table,a0
	move.l	extra_pf7(a3),a1	
	move.l	(a1),a1			; source image
	move.l	extra_pf8(a3),a2
	move.l	(a2),a2     		; destination image
	move.w	#cb_x_max,a4		; destination image
	move.w	#1*extra_pf8_plane_width*extra_pf8_depth,a5
	moveq	#cb_destination_y_size-1,d7
cb_scale_image_loop1
	moveq	#0,d2			; 1st x coordinate source image
	move.w	d4,d3			; x coordinate destination image
	MOVEF.W cb_source_x_size-1,d6
cb_scale_image_loop2
	tst.b	(a0)+			; set pixel ?
	beq.s	cb_scale_image_skip4
	move.w	d3,d1			; x coordinate destination image
	bmi.s	cb_scale_image_skip3
	cmp.w	a4,d1			; x >= max ?
	bge.s	cb_scale_image_skip3
	move.w	d2,d0			; x coordinate source
	lsr.w	#3,d0			; x offset source
	not.b	d2			; x shift source byte
	lsr.w	#3,d1			; x offset destination
	not.b	d3			; x shift destination byte
	btst	d2,(a1,d0.w)		; pixel set in source byte ?
	beq.s	cb_scale_image_skip1
	bset	d3,(a2,d1.w)		; set pixel destination byte
cb_scale_image_skip1
	btst	d2,(extra_pf7_plane_width,a1,d0.w) ; pixel set in source byte ?
	beq.s	cb_scale_image_skip2
	bset	d3,extra_pf8_plane_width(a2,d1.w) ; set pixel destination byte
cb_scale_image_skip2
	not.b	d3			; convert bit number back to x coordinate destination
	not.b	d2			; convert bit number back to x coordinate source
cb_scale_image_skip3
	addq.w	#1,d3			; next pixel in destination
cb_scale_image_skip4
	addq.w	#1,d2			; next pixel in source
	dbf	d6,cb_scale_image_loop2
	add.l	a5,a2			; next line in destination
	subq.w	#cb_destination_x_size_step,d4 ; decrease x position destination
	dbf	d7,cb_scale_image_loop1
	movem.l (a7)+,a4-a5
	rts


	CNOP 0,4
beam_routines
	bsr	wait_copint
	bsr	swap_second_copperlist
	bsr	set_second_copperlist
	bsr	swap_vp1_playfield1
	bsr	set_vp1_playfield1
	bsr	swap_vp2_playfield2
	bsr	set_vp2_playfield2
	bsr	set_vp3_playfield1
	bsr	horiz_scrolltext
	bsr	hst_horiz_scroll
	bsr	mvb_clear_playfield1_2
	bsr	bvm_get_channels_amplitudes
	bsr	bvm_clear_second_copperlist
	bsr	bvm_set_bars
	bsr	fade_balls_in
	bsr	fade_balls_out
	bsr	set_vector_balls
	bsr	mvb_clear_playfield1_1
	bsr	mvb_rotation
	bsr	mvb_morph_object
	movem.l a4-a6,-(a7)
	bsr	mvb_quicksort_coordinates
	movem.l (a7)+,a4-a6
	bsr	cb_get_stripes_y_coordinates
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
	tst.w	stop_fx_active(a3)
	bne	beam_routines
	rts


	SWAP_COPPERLIST cl2,2


	SET_COPPERLIST cl2


	CNOP 0,4
swap_vp1_playfield1
	move.l	vp1_pf1_construction2(a3),a0
	move.l	vp1_pf1_display(a3),vp1_pf1_construction2(a3)
	move.l	a0,vp1_pf1_display(a3)
	rts


	CNOP 0,4
set_vp1_playfield1
	MOVEF.L (vp1_pf1_plane_x_offset/8)+(vp1_pf1_plane_y_offset*extra_pf1_plane_width*vp1_pf1_depth),d1
	move.l	cl2_display(a3),a0
	ADDF.W	cl2_extension1_entry+cl2_ext1_BPL1PTH+WORD_SIZE,a0
	move.l	vp1_pf1_display(a3),a1
	moveq	#vp1_pf1_depth-1,d7
set_vp1_playfield1_loop
	move.l	(a1)+,d0
	add.l	d1,d0
	move.w	d0,LONGWORD_SIZE(a0)	; BPLxPTL
	swap	d0
	move.w	d0,(a0)			; BPLxPTH
	addq.w	#QUADWORD_SIZE,a0
	dbf	d7,set_vp1_playfield1_loop
	rts


	CNOP 0,4
swap_vp2_playfield2
	move.l	vp2_pf2_construction1(a3),a0
	move.l	vp2_pf2_construction2(a3),a1
	move.l	vp2_pf2_display(a3),vp2_pf2_construction1(a3)
	move.l	a0,vp2_pf2_construction2(a3)
	move.l	a1,vp2_pf2_display(a3)
	rts


	CNOP 0,4
set_vp2_playfield2
	move.l	cl2_display(a3),a0
	ADDF.W	cl2_extension3_entry+cl2_ext3_BPL2PTH+WORD_SIZE,a0
	move.l	vp2_pf2_display(a3),a1
	moveq	#vp2_pf2_depth-1,d7
set_vp2_playfield2_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	addq.w	#QUADWORD_SIZE,a0
	move.w	(a1)+,LONGWORD_SIZE-QUADWORD_SIZE(a0) ; BPLxPTL
	dbf	d7,set_vp2_playfield2_loop
	rts


	CNOP 0,4
set_vp3_playfield1
	move.l	cl2_display(a3),a0
	ADDF.W	cl2_extension4_entry+cl2_ext4_BPL1PTH+WORD_SIZE,a0
	move.l	vp2_pf2_display(a3),a1
	moveq	#vp3_pf1_depth-1,d7
set_vp3_playfield1_loop
	move.w	(a1)+,(a0)		; BPLxPTH
	ADDF.W	QUADWORD_SIZE*2,a0
	move.w	(a1)+,LONGWORD_SIZE-(QUADWORD_SIZE*2)(a0) ; BPLxPTL
	dbf	d7,set_vp3_playfield1_loop
	rts


	CNOP 0,4
horiz_scrolltext
	movem.l a4-a5,-(a7)
	tst.w	hst_active(a3)
	bne.s	horiz_scrolltext_quit
	bsr.s	horiz_scrolltext_init
	move.l	vp1_pf1_construction2(a3),a0
	MOVEF.L (hst_text_x_position/8)+(hst_text_y_position*extra_pf1_plane_width*vp1_pf1_depth),d3
	add.l	(a0),d3
	move.w	#((hst_text_char_y_size*hst_text_char_depth)<<6)|(hst_text_char_x_size/WORD_BITS),d4 ; BLTSIZE
	move.w	#hst_text_char_x_restart,d5
	lea	hst_chars_x_positions(pc),a0
	lea	hst_chars_image_pointers(pc),a1
	lea	BLTAPT-DMACONR(a6),a2
	lea	BLTDPT-DMACONR(a6),a4
	lea	BLTSIZE-DMACONR(a6),a5
	bsr.s	hst_get_text_softscroll
	moveq	#hst_text_chars_number-1,d7
horiz_scrolltext_loop
	moveq	#0,d0
	move.w	(a0),d0			; x
	move.w	d0,d2	
	lsr.w	#3,d0			; byte offset
	add.l	d3,d0			; add playfield address
	WAITBLIT
	move.l	(a1)+,(a2)		; character image
	move.l	d0,(a4)			; playfield write
	move.w	d4,(a5)			; start blitter operation
	sub.w	hst_horiz_scroll_speed(a3),d2
	bpl.s	horiz_scrolltext_skip
	move.l	a0,-(a7)
	bsr.s		hst_get_new_char_image
	move.l	(a7)+,a0
	move.l	d0,-LONGWORD_SIZE(a1)	; new character image
	add.w	d5,d2			; restart x position
horiz_scrolltext_skip
	move.w	d2,(a0)+
	dbf	d7,horiz_scrolltext_loop
	move.w	#DMAF_BLITHOG,DMACON-DMACONR(a6)
horiz_scrolltext_quit
	movem.l (a7)+,a4-a5
	rts
	CNOP 0,4
horiz_scrolltext_init
	move.w	#DMAF_BLITHOG|DMAF_SETCLR,DMACON-DMACONR(a6)
	WAITBLIT
	move.l	#(BC0F_SRCA|BC0F_DEST|ANBNC|ANBC|ABNC|ABC)<<16,BLTCON0-DMACONR(a6) ; minterm D = A
	moveq	#-1,d0
	move.l	d0,BLTAFWM-DMACONR(a6)
	move.l	#((hst_image_plane_width-hst_text_char_width)<<16)|(extra_pf1_plane_width-hst_text_char_width),BLTAMOD-DMACONR(a6) ; A&D-moduli
	rts


	CNOP 0,4
hst_get_text_softscroll
	moveq	#hst_text_char_x_size-1,d0
	and.w	(a0),d0			; x
	ror.w	#4,d0			; adjust shift bits
	or.w	#BC0F_SRCA|BC0F_DEST|ANBNC|ANBC|ABNC|ABC,d0 ; minterm D = A
	move.w	d0,hst_text_bltcon0_bits(a3) 
	rts


	GET_NEW_CHAR_IMAGE.W hst,hst_check_control_codes


; Input
; d0.b	ASCII code
; Result
; d0.l	return code
	CNOP 0,4
hst_check_control_codes
	cmp.b	#ASCII_CTRL_S,d0
	beq.s	hst_stop_scrolltext
	rts
	CNOP 0,4
hst_stop_scrolltext
	move.w	#FALSE,hst_active(a3)	; stop scrolltext
	tst.w	quit_active(a3)		; quit intro ?
	bne.s	hst_stop_scrolltext_quit
	clr.w	pt_music_fader_active(a3)
	clr.w	fbo_active(a3)
	move.w	#fbo_delay,fbo_delay_counter(a3)
	move.w	#$8888,fb_mask(a3)
	clr.w	sprfo_rgb8_active(a3)
	move.w	#sprf_rgb8_colors_number*3,sprf_rgb8_colors_counter(a3)
	clr.w	sprf_rgb8_copy_colors_active(a3)
	clr.w	ifo_rgb8_active(a3)
	move.w	#if_rgb8_colors_number*3,if_rgb8_colors_counter(a3)
	clr.w	if_rgb8_copy_colors_active(a3)
	clr.w	cfo_rgb8_active(a3)
	clr.w	bfo_rgb8_active(a3)
	move.w	#bf_rgb8_colors_number*3,bf_rgb8_colors_counter(a3)
	clr.w	bf_rgb8_copy_colors_active(a3)
hst_stop_scrolltext_quit
	moveq	#RETURN_OK,d0
	rts


	CNOP 0,4
hst_horiz_scroll
	tst.w	hst_active(a3)
	bne.s	hst_horiz_scroll_quit
	move.l	vp1_pf1_construction2(a3),a0
	move.l	(a0),a0
	ADDF.W	(hst_text_x_position/8)+(hst_text_y_position*extra_pf1_plane_width*vp1_pf1_depth),a0
	WAITBLIT
	move.w	hst_text_bltcon0_bits(a3),BLTCON0-DMACONR(a6)
	move.l	a0,BLTAPT-DMACONR(a6)	; source
	addq.w	#WORD_SIZE,a0		; skip 16 pixel
	move.l	a0,BLTDPT-DMACONR(a6)	; destination
	move.l	#((extra_pf1_plane_width-hst_horiz_scroll_window_width)<<16)|(extra_pf1_plane_width-hst_horiz_scroll_window_width),BLTAMOD-DMACONR(a6) ; A&D moduli
	move.w	#((hst_horiz_scroll_window_y_size*hst_horiz_scroll_window_depth)<<6)|(hst_horiz_scroll_window_x_size/WORD_BITS),BLTSIZE-DMACONR(a6)
hst_horiz_scroll_quit
	rts


	CNOP 0,4
bvm_get_channels_amplitudes
	MOVEF.W bvm_max_amplitude,d2
	MOVEF.W sine_table_length/4,d3
	lea	pt_audchan1temp(pc),a0
	lea	bvm_audio_channel1_info(pc),a1
	bsr.s	bvm_get_channel_amplitude
	lea	pt_audchan2temp(pc),a0
	lea	bvm_audio_channel2_info(pc),a1
	bsr.s	bvm_get_channel_amplitude
	lea	pt_audchan3temp(pc),a0
	lea	bvm_audio_channel3_info(pc),a1
	bsr.s	bvm_get_channel_amplitude
	lea	pt_audchan4temp(pc),a0
	lea	bvm_audio_channel4_info(pc),a1
	bsr.s	bvm_get_channel_amplitude
	rts


; Input
; d2.w	Max amplitude
; d3.w	Y angle 90�
; a0.l	Pointer temporary audio channel structure
; a1.l	Pointer audio channel info structure
; Result
	CNOP 0,4
bvm_get_channel_amplitude
	tst.b	n_notetrigger(a0)	; new note played ?
	bne.s	bvm_get_channel_amplitude_quit
	move.w	n_currentvolume(a0),d0
	move.b	#FALSE,n_notetrigger(a0)
	MULUF.W bvm_max_amplitude,d0,d1
	lsr.w	#6,d0
	cmp.w	d2,d0			; amplitude <= max amplitude ?
	ble.s	bvm_get_channel_amplitude_skip
	move.w	d2,d0			; max amplitude
bvm_get_channel_amplitude_skip
	move.w	d3,(a1)+                ; angle
	move.w	d0,(a1)			; amplitude
bvm_get_channel_amplitude_quit
	rts


	CNOP 0,4
bvm_clear_second_copperlist
	MOVEF.W vp1_bplcon4_bits&FALSE_BYTE,d0
	move.l	cl2_construction2(a3),a0
	ADDF.W	cl2_extension2_entry+cl2_ext2_BPLCON4+WORD_SIZE+BYTE_SIZE,a0
	move.w	#cl2_extension2_size,a1
	moveq	#vp1_visible_lines_number-1,d7
bvm_clear_second_copperlist_loop
	move.b	d0,(a0)			; BPLCON4 low
	add.l	a1,a0			; next rasterline in cl
	dbf	d7,bvm_clear_second_copperlist_loop
	rts


	CNOP 0,4
bvm_set_bars
	movem.l a3-a6,-(a7)
	MOVEF.W (sine_table_length/2)-1,d5 ; overflow 180�
	lea	sine_table(pc),a0	
	lea	bvm_audio_channel1_info(pc),a1
	lea	bvm_sprm_table(pc),a4
	move.l	cl2_construction2(a3),a5 
	ADDF.W	cl2_extension2_entry+cl2_ext2_BPLCON4+WORD_SIZE+BYTE_SIZE,a5
	move.w	#bvm_y_center,a3
	move.w	#cl2_extension2_size,a6
	moveq	#bvm_bars_number-1,d7
bvm_set_bars_loop1
	move.w	(a1)+,d3		; y angle
	move.w	WORD_SIZE(a0,d3.w*4),d0	; sin(w)
	addq.w	#bvm_y_angle_speed,d3	; next y angle
	muls.w	(a1)+,d0		; y'=(yr*sin(w))/2^15
	MULUF.L 2,d0,d1
	swap	d0
	cmp.w	d5,d3			; 180� ?
	ble.s	bvm_set_bars_skip
	lsr.w	-WORD_SIZE(a1)		; amplitude/2
bvm_set_bars_skip
	and.w	d5,d3			; remove overflow
	move.w	d3,-LONGWORD_SIZE(a1)	
	add.w	a3,d0			; y' + y center
	MULUF.W cl2_extension2_size/LONGWORD_SIZE,d0,d1
	lea	(a5,d0.w*4),a2		; y offset in cl
	moveq	#bvm_bar_height-1,d6
bvm_set_bars_loop2
	move.b	(a4)+,(a2)		; BPLCON4 low
	add.l	a6,a2			; next rasterline in cl
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
	move.w	#((mvb_clear_blit_y_size)<<6)|(mvb_clear_blit_x_size/WORD_BITS),BLTSIZE-DMACONR(a6)
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
	ADDF.L	extra_pf4_plane_width*extra_pf4_y_size*extra_pf4_depth,a7 ; end of bitplanes
	move.l	d0,a3
	moveq	#5-1,d7			; number of runs
mvb_clear_playfield1_2_loop
	REPT ((extra_pf4_plane_width*extra_pf4_y_size*(extra_pf4_depth-1))/56)/5
		movem.l d0-d6/a0-a6,-(a7) ; clear 56 bytes
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
	move.w	WORD_SIZE(a2,d0.w*4),d4	; sin(a)
	move.w	#sine_table_length/4,a4
	IFEQ sine_table_length-512
		MOVEF.W sine_table_length-1,d3 ; overflow 360�
	ELSE
		MOVEF.W sine_table_length,d3 ; overflow 360 �
	ENDC
	add.w	a4,d0			; + 90�
	swap	d4 			; high word:  sin(a)
	IFEQ sine_table_length-512
		and.w	d3,d0		; remove overflow
	ELSE
		cmp.w	d3,d0		; 360� ?
		blt.s	mvb_rotation_skip1
		sub.w	d3,d0
mvb_rotation_skip1
	ENDC
	move.w	WORD_SIZE(a2,d0.w*4),d4	; low word: cos(a)
	addq.w	#mvb_rotation_x_angle_speed,d1 ; next x angle
	IFEQ sine_table_length-512
		and.w	d3,d1		; remove overflow
	ELSE
		cmp.w	d3,d1		; 360� ?
		blt.s	mvb_rotation_skip2
		sub.w	d3,d1
mvb_rotation_skip2
	ENDC
	move.w	d1,mvb_rotation_x_angle(a3) 
	move.w	mvb_rotation_y_angle(a3),d1
	move.w	d1,d0	
	move.w	WORD_SIZE(a2,d0.w*4),d5	; sin(b)
	add.w	a4,d0			; + 90�
	swap	d5 			; high word: sin(b)
	IFEQ sine_table_length-512
		and.w	d3,d0		; remove overflow
	ELSE
		cmp.w	d3,d0		; 360� ?
		blt.s	mvb_rotation_skip3
		sub.w	d3,d0		; restart
mvb_rotation_skip3
	ENDC
	move.w	WORD_SIZE(a2,d0.w*4),d5	; low word: cos(b)
	addq.w	#mvb_rotation_y_angle_speed,d1 ; next y angle
	IFEQ sine_table_length-512
		and.w	d3,d1		; remove overflow
	ELSE
		cmp.w	d3,d1		; 360� ?
		blt.s	mvb_rotation_skip4
		sub.w	d3,d1		; restart
mvb_rotation_skip4
	ENDC
	move.w	d1,mvb_rotation_y_angle(a3) 
	move.w	mvb_rotation_z_angle(a3),d1
	move.w	d1,d0	
	move.w	WORD_SIZE(a2,d0.w*4),d6	; sin(c)
	add.w	a4,d0			; + 90�
	swap	d6 			; high word: sin(c)
	IFEQ sine_table_length-512
		and.w	d3,d0		; remove overflow
	ELSE
		cmp.w	d3,d0		; 360� ?
		blt.s	mvb_rotation_skip5
		sub.w	d3,d0		; restart
mvb_rotation_skip5
	ENDC
	move.w	WORD_SIZE(a2,d0.w*4),d6	; low word: cos(c)
	addq.w	#mvb_rotation_z_angle_speed,d1 ; next z angle
	IFEQ sine_table_length-512
		and.w	d3,d1		; remove overflow
	ELSE
		cmp.w	d3,d1		; 360� ?
		blt.s	mvb_rotation_skip6
		sub.w	d3,d1
mvb_rotation_skip6
	ENDC
	move.w	d1,mvb_rotation_z_angle(a3) 
	lea	mvb_object_coordinates(pc),a0
	lea	mvb_rotation_xyz_coordinates(pc),a1
	move.w	#mvb_rotation_d*8,a4
	move.w	#mvb_rotation_x_center,a5
	move.w	#mvb_rotation_y_center,a6
	moveq	#mvb_object_points_number-1,d7
mvb_rotation_loop
	move.w	(a0)+,d0		; x
	move.l	d7,a2	
	move.w	(a0)+,d1		; y
	move.w	(a0)+,d2		; z
	ROTATE_X_AXIS
	ROTATE_Y_AXIS
	ROTATE_Z_AXIS
; Projection and translation
	move.w	d2,d3			; z
	ext.l	d0
	add.w	a4,d3			; z+d
	MULUF.L mvb_rotation_d,d0,d7	; x projection
	ext.l	d1
	divs.w	d3,d0			; x'=(x*d)/(z+d)
	MULUF.L mvb_rotation_d,d1,d7	; y projection
	add.w	a5,d0			; x' + x center
	move.w	d0,(a1)+		; x position
	divs.w	d3,d1			; y'=(y*d)/(z+d)
	add.w	a6,d1			; y' + y center
	move.w	d1,(a1)+		; y position
	asr.w	#3,d2			; z/8
	move.l	a2,d7			; loop counter
	move.w	d2,(a1)+		; z position
	dbf	d7,mvb_rotation_loop
	movem.l (a7)+,a4-a6
	rts


	CNOP 0,4
mvb_morph_object
	tst.w	mvb_morph_active(a3)
	bne.s	mvb_morph_object_quit
	move.w	mvb_morph_shapes_table_start(a3),d1
	moveq	#0,d2			; coordinates counter
	lea	mvb_object_coordinates(pc),a0
	lea	mvb_morph_shapes_table(pc),a1
	move.l	(a1,d1.w*4),a1		; shape table
	MOVEF.W mvb_object_points_number*3-1,d7
mvb_morph_object_loop
	move.w	(a0),d0                 ; current coordinate
	cmp.w	(a1)+,d0		; destination coordinate reached ?
	beq.s	mvb_morph_object_skip3
	bgt.s	mvb_morph_object_skip1
	addq.w	#mvb_morph_speed,d0	; increase current coordinate
	bra.s	mvb_morph_object_skip2
	CNOP 0,4
mvb_morph_object_skip1
	subq.w	#mvb_morph_speed,d0	; decrease current coordinate
mvb_morph_object_skip2
	move.w	d0,(a0)
	addq.w	#1,d2			; increase coordinates counter
mvb_morph_object_skip3
	addq.w	#WORD_SIZE,a0		; next coordinate
	dbf	d7,mvb_morph_object_loop
	tst.w	d2			; morphing finished ?
	bne.s	mvb_morph_object_quit
	addq.w	#1,d1			; next entry
	cmp.w	#mvb_morph_shapes_number,d1 ; end of table ?
	IFEQ mvb_morph_loop_enabled
		bne.s	mvb_morph_object_skip4
		moveq	#0,d1		; restart
mvb_morph_object_skip4
	ELSE
		beq.s	mvb_morph_object_skip5
	ENDC
	move.w	d1,mvb_morph_shapes_table_start(a3) 
mvb_morph_object_skip5
	move.w	#FALSE,mvb_morph_active(a3)
mvb_morph_object_quit
	rts


	CNOP 0,4
mvb_quicksort_coordinates
	moveq	#-2,d2			; mask to clear bit 0
	lea	mvb_object_coordinates_offsets(pc),a0
	move.l	a0,a1
	lea	(mvb_object_points_number-1)*2(a0),a2 ; last entry
	move.l	a2,a5
	lea	mvb_rotation_xyz_coordinates(pc),a6
mvb_quicks
	move.l	a5,d0			; 1st entry
	add.l	a0,d0			; + last entry
	lsr.l	#1,d0
	and.b	d2,d0			; only even address
	move.l	d0,a4			; middle of table
	move.w	(a4),d1			; xyz offset
	move.w	4(a6,d1.w*2),d0		; z
mvb_quick
	move.w	(a1)+,d1		; xyz offset
	cmp.w	4(a6,d1.w*2),d0		; 1st z < middle z ?
	blt.s	mvb_quick
	addq.w	#WORD_SIZE,a2		; next xyz offset
	subq.w	#WORD_SIZE,a1		; set back pointer
mvb_quick2
	move.w	-(a2),d1		; xyz offset
	cmp.w	4(a6,d1.w*2),d0		; previous z > middle z ?
	bgt.s	mvb_quick2
mvb_quick3
	cmp.l	a2,a1			; table end > pointer tabble beginning ?
	bgt.s	mvb_quick4
	move.w	(a2),d1			; last offset
	move.w	(a1),(a2)		; 1st offset -> last offset
	subq.w	#WORD_SIZE,a2		; penultimate offset
	move.w	d1,(a1)+		; last offset -> 1st offset
mvb_quick4
	cmp.l	a2,a1			; table start <= pointer table end ?
	ble.s	mvb_quick
	cmp.l	a2,a0			; tablwe start >= pointer table end ?
	bge.s	mvb_quick5
	move.l	a5,-(a7)
	move.l	a2,a5			; table end
	move.l	a0,a1
	bsr.s	mvb_quicks
	move.l	(a7)+,a5
mvb_quick5
	cmp.l	a5,a1			; table start >= pointer table end ?
	bge.s	mvb_quick6
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
	bsr	set_vector_balls_init
	move.w	#BC0F_SRCA|BC0F_SRCB|BC0F_SRCC|BC0F_DEST+NANBC|NABC|ABNC|ABC,d3 ; minterm D = A+B
	move.w	#((mvb_copy_blit_y_size)<<6)|(mvb_copy_blit_x_size/WORD_BITS),a4
	move.l	vp2_pf2_construction2(a3),a0
	move.l	(a0),d4
	lea	mvb_object_coordinates_offsets(pc),a0
	lea	mvb_rotation_xyz_coordinates(pc),a1
	move.w	#mvb_z_plane1,a2
	move.w	#mvb_z_plane2,a3
	lea	mvb_image_data,a5
	lea	mvb_image_mask,a7
	MOVEF.W mvb_balls_number-1,d7
set_vector_balls_loop
	move.w	(a0)+,d0		; xyz coordinate start
	moveq	#0,d5
	movem.w (a1,d0.w*2),d0-d2	; x,y,z
	cmp.w	a2,d2			; 1st z plane ?
	blt.s	set_vector_balls_skip3
	cmp.w	a3,d2			; 2nd z plane ?
	blt.s	set_vector_balls_skip2
	cmp.w	#mvb_z_plane3,d2	; 3rd z plane ?
	blt.s	set_vector_balls_skip1
	ADDF.W	mvb_image_width,d5
set_vector_balls_skip1
	ADDF.W	mvb_image_width,d5
set_vector_balls_skip2
	ADDF.W	mvb_image_width,d5
set_vector_balls_skip3
	MULUF.W (extra_pf4_plane_width*extra_pf4_depth)/2,d1,d2
	ror.l	#4,d0			; adjust shift bits
	move.l	d5,d6
	add.w	d0,d1			; add y offset
	add.l	a5,d5			; add image address
	MULUF.L 2,d1,d2			; xy offset
	swap	d0			; shift bits
	add.l	d4,d1			; add playfield address
	add.l	a7,d6			; add masks address
	WAITBLIT
	move.w	d0,BLTCON1-DMACONR(a6)
	or.w	d3,d0			; remaining BLTCON0 bits
	move.w	d0,BLTCON0-DMACONR(a6)
	move.l	d1,BLTCPT-DMACONR(a6)	; playfield read
	move.l	d5,BLTBPT-DMACONR(a6)	; image
	move.l	d6,BLTAPT-DMACONR(a6)	; mask
	move.l	d1,BLTDPT-DMACONR(a6)	; playfield write
	move.w	a4,BLTSIZE-DMACONR(a6)
	dbf	d7,set_vector_balls_loop
	move.w	#DMAF_BLITHOG,DMACON-DMACONR(a6)
	move.l	variables+save_a7(pc),a7
	movem.l (a7)+,a3-a5
	rts
	CNOP 0,4
set_vector_balls_init
	move.w	#DMAF_BLITHOG|DMAF_SETCLR,DMACON-DMACONR(a6)
	WAITBLIT
	move.w	mvb_mask(a3),BLTAFWM-DMACONR(a6)
	moveq	#0,d0
	move.w	d0,BLTALWM-DMACONR(a6)
	move.l	#((extra_pf4_plane_width-(mvb_image_width+2))<<16)|((mvb_image_width*mvb_image_objects_number)-(mvb_image_width+2)),BLTCMOD-DMACONR(a6) ; C&B moduli
	move.l	#(((mvb_image_width*mvb_image_objects_number)-(mvb_image_width+2))<<16)|(extra_pf4_plane_width-(mvb_image_width+2)),BLTAMOD-DMACONR(a6) ; A&D moduli
	rts


	CNOP 0,4
cb_get_stripes_y_coordinates
	move.w	cb_stripes_y_angle(a3),d2
	move.w	d2,d0
	MOVEF.W (sine_table_length/4)-1,d4 ; overflow 90�
	sub.w	cb_stripes_y_angle_speed(a3),d0 ; next y angle
	and.w	d4,d0			; remove overflow
	move.w	d0,cb_stripes_y_angle(a3) 
	moveq	#cb_stripes_y_center,d3
	lea	sine_table(pc),a0
	lea	cb_stripes_y_coordinates(pc),a1
	moveq	#(cb_stripes_number*cb_stripe_height)-1,d7 ; number of lines
cb_get_stripes_y_coordinates_loop
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L cb_stripes_y_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	add.w	d3,d0			; y' + y center
	move.w	d0,(a1)+
	addq.w	#cb_stripes_y_step,d2	; next y angle
	and.w	d4,d2			; remove overflow
	dbf	d7,cb_get_stripes_y_coordinates_loop
	rts


	CNOP 0,4
cb_make_color_offsets
	moveq	#$00000001,d1		; low word: color offset 1st stripe, high word: color offset 2nd stripe
	lea	cb_stripes_y_coordinates(pc),a0
	lea	cb_color_offsets_table(pc),a1
	moveq	#cb_stripes_number-1,d7
cb_make_color_offsets_loop1
	moveq	#cb_stripe_height-1,d6
cb_make_color_offsets_loop2
	move.w	(a0)+,d0		; y offset
	move.l	d1,(a1,d0.w*4)		; color offset
	dbf	d6,cb_make_color_offsets_loop2
	swap	d1			; swap color offsets
	dbf	d7,cb_make_color_offsets_loop1
	rts


	CNOP 0,4
cb_move_chessboard
	move.l	a4,-(a7)
	move.w	#RB_NIBBLES_MASK,d3
	lea	cb_color_offsets_table(pc),a0
	move.l	extra_memory(a3),a1
	ADDF.L	em_rgb8_color_table,a1
	move.l	cl2_construction2(a3),a2
	ADDF.W	cl2_extension5_entry+cl2_ext5_COLOR25_high8+WORD_SIZE,a2
	move.w	#cl2_extension5_size,a4
	moveq	#vp3_visible_lines_number-1,d7
cb_move_chessboard_loop
	move.w	(a0)+,d0		; color offset
	move.l	(a1,d0.w*4),d0		; RGB8
	move.l	d0,d2	
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(a2)			; color high
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,cl2_ext5_COLOR25_low8-cl2_ext5_COLOR25_high8(a2) ; color low
	add.l	a4,a2			; next line
	move.w	(a0)+,d0		; color offset
	move.l	(a1,d0.w*4),d0		; RGB8
	move.l	d0,d2	
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(cl2_ext5_COLOR26_high8-cl2_ext5_COLOR25_high8)-cl2_extension5_size(a2) ; color high
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,(cl2_ext5_COLOR26_low8-cl2_ext5_COLOR25_high8)-cl2_extension5_size(a2) ; color low
	addq.w	#QUADWORD_SIZE,a1	; next entry
	dbf	d7,cb_move_chessboard_loop
	move.l	(a7)+,a4
	rts


	CNOP 0,4
rgb8_bar_fader_in
	movem.l a4-a6,-(a7)
	tst.w	bfi_rgb8_active(a3)
	bne.s	rgb8_bar_fader_in_quit
	move.w	bfi_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	bfi_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	rgb8_bar_fader_in_skip
	MOVEF.W sine_table_length/2,d0
rgb8_bar_fader_in_skip
	move.w	d0,bfi_rgb8_fader_angle(a3) 
	MOVEF.W bf_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L bfi_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	bfi_rgb8_fader_center,d0
	lea	bvm_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; colors buffer
	lea	bfi_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination colors
	move.w	d0,a5			; increase/decrease blue
	swap	d0			
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W bf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	move.w	d6,bf_rgb8_colors_counter(a3)
	bne.s	rgb8_bar_fader_in_quit
	move.w	#FALSE,bfi_rgb8_active(a3)
rgb8_bar_fader_in_quit
	movem.l (a7)+,a4-a6
	rts


	CNOP 0,4
rgb8_bar_fader_out
	movem.l a4-a6,-(a7)
	tst.w	bfo_rgb8_active(a3)
	bne.s	rgb8_bar_fader_out_quit
	move.w	bfo_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	bfo_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	rgb8_bar_fader_out_skip
	MOVEF.W sine_table_length/2,d0
rgb8_bar_fader_out_skip
	move.w	d0,bfo_rgb8_fader_angle(a3) 
	MOVEF.W bf_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L bfo_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	bfo_rgb8_fader_center,d0
	lea	bvm_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; colors buffer
	lea	bfo_rgb8_color_table+(bf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination colors
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W bf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	move.w	d6,bf_rgb8_colors_counter(a3)
	bne.s	rgb8_bar_fader_out_quit
	move.w	#FALSE,bfo_rgb8_active(a3)
rgb8_bar_fader_out_quit
	movem.l (a7)+,a4-a6
	rts


	COPY_RGB8_COLORS_TO_COPPERLIST bf,bvm,cl1,cl1_COLOR00_high2,cl1_COLOR00_low2


; Fade in temple
	CNOP 0,4
rgb8_image_fader_in
	movem.l a4-a6,-(a7)
	tst.w	ifi_rgb8_active(a3)
	bne.s	rgb8_image_fader_in_quit
	move.w	ifi_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	ifi_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0 ; 180� ?
	ble.s	rgb8_image_fader_in_skip
	MOVEF.W sine_table_length/2,d0
rgb8_image_fader_in_skip
	move.w	d0,ifi_rgb8_fader_angle(a3) 
	MOVEF.W if_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L ifi_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	ifi_rgb8_fader_center,d0
	lea	vp2_pf1_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; colors buffer
	lea	ifi_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination colors
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W if_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	move.w	d6,if_rgb8_colors_counter(a3)
	bne.s	rgb8_image_fader_in_quit
	move.w	#FALSE,ifi_rgb8_active(a3)
rgb8_image_fader_in_quit
	movem.l (a7)+,a4-a6
	rts


; Fade out temple
	CNOP 0,4
rgb8_image_fader_out
	movem.l a4-a6,-(a7)
	tst.w	ifo_rgb8_active(a3)
	bne.s	rgb8_image_fader_out_quit
	move.w	ifo_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	ifo_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	rgb8_image_fader_out_skip
	MOVEF.W sine_table_length/2,d0
rgb8_image_fader_out_skip
	move.w	d0,ifo_rgb8_fader_angle(a3) 
	MOVEF.W if_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0	;sin(w)
	MULUF.L ifo_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	ifo_rgb8_fader_center,d0
	lea	vp2_pf1_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; colors buffer
	lea	ifo_rgb8_color_table+(if_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination colors
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W if_rgb8_colors_number-1,d7
	bsr.s	if_rgb8_fader_loop
	move.w	d6,if_rgb8_colors_counter(a3)
	bne.s	rgb8_image_fader_out_quit
	move.w	#FALSE,ifo_rgb8_active(a3)
rgb8_image_fader_out_quit
	movem.l (a7)+,a4-a6
	rts


	RGB8_COLOR_FADER if


	COPY_RGB8_COLORS_TO_COPPERLIST if,vp2_pf1,cl1,cl1_COLOR00_high1,cl1_COLOR00_low1


	CNOP 0,4
rgb8_chessboard_fader_in
	movem.l a4-a6,-(a7)
	tst.w	cfi_rgb8_active(a3)
	bne.s	rgb8_chessboard_fader_in_quit
	move.w	cfi_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	cfi_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	rgb8_chessboard_fader_in_skip
	MOVEF.W sine_table_length/2,d0
rgb8_chessboard_fader_in_skip
	move.w	d0,cfi_rgb8_fader_angle(a3)
	MOVEF.W cf_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L cfi_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	cfi_rgb8_fader_center,d0
	move.l	extra_memory(a3),a0
	ADDF.L	em_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE),a0 ; colors buffer
	lea	cfi_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination colors
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W cf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	move.w	d6,cf_rgb8_colors_counter(a3)
	bne.s	rgb8_chessboard_fader_in_quit
	move.w	#FALSE,cfi_rgb8_active(a3)
rgb8_chessboard_fader_in_quit
	movem.l (a7)+,a4-a6
	rts


	CNOP 0,4
rgb8_chessboard_fader_out
	movem.l a4-a6,-(a7)
	tst.w	cfo_rgb8_active(a3)
	bne.s	rgb8_chessboard_fader_out_quit
	move.w	cfo_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	cfo_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	rgb8_chessboard_fader_out_skip
	MOVEF.W sine_table_length/2,d0
rgb8_chessboard_fader_out_skip
	move.w	d0,cfo_rgb8_fader_angle(a3)
	MOVEF.W cf_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L cfo_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	cfo_rgb8_fader_center,d0
	move.l	extra_memory(a3),a0
	ADDF.L	em_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE),a0 ; colors buffer
	lea	cfo_rgb8_color_table+(cf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination colors
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W cf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	move.w	d6,cf_rgb8_colors_counter(a3)
	bne.s	rgb8_chessboard_fader_out_quit
	move.w	#FALSE,cfo_rgb8_active(a3)
rgb8_chessboard_fader_out_quit
	movem.l (a7)+,a4-a6
	rts


	CNOP 0,4
rgb8_sprite_fader_in
	movem.l a4-a6,-(a7)
	tst.w	sprfi_rgb8_active(a3)
	bne.s	rgb8_sprite_fader_in_quit
	move.w	sprfi_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	sprfi_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	rgb8_sprite_fader_in_skip
	MOVEF.W sine_table_length/2,d0
rgb8_sprite_fader_in_skip
	move.w	d0,sprfi_rgb8_fader_angle(a3) 
	MOVEF.W sprf_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L sprfi_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	sprfi_rgb8_fader_center,d0
	lea	spr_rgb8_color_table+(sprf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; colors buffer
	lea	sprfi_rgb8_color_table+(sprf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination colors
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W sprf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	move.w	d6,sprf_rgb8_colors_counter(a3)
	bne.s	rgb8_sprite_fader_in_quit
	move.w	#FALSE,sprfi_rgb8_active(a3)
rgb8_sprite_fader_in_quit
	movem.l (a7)+,a4-a6
	rts


	CNOP 0,4
rgb8_sprite_fader_out
	movem.l a4-a6,-(a7)
	tst.w	sprfo_rgb8_active(a3)
	bne.s	rgb8_sprite_fader_out_quit
	move.w	sprfo_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	sprfo_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	rgb8_sprite_fader_out_skip
	MOVEF.W sine_table_length/2,d0
rgb8_sprite_fader_out_skip
	move.w	d0,sprfo_rgb8_fader_angle(a3) 
	MOVEF.W sprf_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L sprfo_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	sprfo_rgb8_fader_center,d0
	lea	spr_rgb8_color_table+(sprf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; colors buffer
	lea	sprfo_rgb8_color_table+(sprf_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination colors
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W sprf_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	move.w	d6,sprf_rgb8_colors_counter(a3)
	bne.s	rgb8_sprite_fader_out_quit
	move.w	#FALSE,sprfo_rgb8_active(a3)
rgb8_sprite_fader_out_quit
	movem.l (a7)+,a4-a6
	rts


	COPY_RGB8_COLORS_TO_COPPERLIST sprf,spr,cl1,cl1_COLOR00_high2,cl1_COLOR00_low2


	CNOP 0,4
fade_balls_in
	tst.w	fbi_active(a3)
	bne.s	fade_balls_in_quit
	subq.w	#1,fbi_delay_counter(a3)
	bne.s	fade_balls_in_quit
	move.w	#fbi_delay,fbi_delay_counter(a3)
	move.w	mvb_mask(a3),d0 	; current mask
	move.w	fb_mask(a3),d1		; 2nd mask
	eor.w	d1,d0			; merge masks
	move.w	d0,mvb_mask(a3)
	cmp.w	#-1,d0			; mask end ?
	bne.s	fade_balls_in_skip
	move.w	#FALSE,fbi_active(a3)
	bra.s	fade_balls_in_quit
	CNOP 0,4
fade_balls_in_skip
	lsr.w	#1,d1			; shift 2nd mask
	move.w	d1,fb_mask(a3)	
fade_balls_in_quit
	rts


	CNOP 0,4
fade_balls_out
	tst.w	fbo_active(a3)
	bne.s	fade_balls_out_quit
	subq.w	#1,fbo_delay_counter(a3)
	bne.s	fade_balls_out_quit
	move.w	#fbo_delay,fbo_delay_counter(a3)
	move.w	mvb_mask(a3),d0 	; current mask
	move.w	fb_mask(a3),d1		; 2nd mask
	eor.w	d1,d0			; merge masks
	move.w	d0,mvb_mask(a3) 	; mask end ?
	bne.s	fade_balls_out_skip
	move.w	#FALSE,fbo_active(a3)
	bra.s	fade_balls_out_quit
	CNOP 0,4
fade_balls_out_skip
	lsr.w	#1,d1			; shift 2nd mask
	move.w	d1,fb_mask(a3)	
fade_balls_out_quit
	rts


	CNOP 0,4
rgb8_colors_fader_cross
	movem.l a4-a6,-(a7)
	tst.w	cfc_rgb8_active(a3)
	bne.s	rgb8_colors_fader_cross_quit
	move.w	cfc_rgb8_fader_angle(a3),d2
	move.w	d2,d0
	ADDF.W	cfc_rgb8_fader_angle_speed,d0
	cmp.w	#sine_table_length/2,d0	; 180� ?
	ble.s	rgb8_colors_fader_cross_skip
	MOVEF.W sine_table_length/2,d0
rgb8_colors_fader_cross_skip
	move.w	d0,cfc_rgb8_fader_angle(a3) 
	MOVEF.W cfc_rgb8_colors_number*3,d6 ; RGB counter
	lea	sine_table(pc),a0	
	move.l	(a0,d2.w*4),d0		; sin(w)
	MULUF.L cfc_rgb8_fader_radius*2,d0,d1 ; y'=(yr*sin(w))/2^15
	swap	d0
	ADDF.W	cfc_rgb8_fader_center,d0
	lea	vp2_pf2_rgb8_color_table+(cfc_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; colors buffer
	lea	cfc_rgb8_color_table+(cfc_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a1 ; destination colors
	move.w	cfc_rgb8_color_table_start(a3),d1
	MULUF.W LONGWORD_SIZE,d1	; *32
	lea	(a1,d1.w*8),a1
	move.w	d0,a5			; increase/decrease blue
	swap	d0
	clr.w	d0
	move.l	d0,a2			; increase/decrease red
	lsr.l	#8,d0
	move.l	d0,a4			; increase/decrease green
	MOVEF.W cfc_rgb8_colors_number-1,d7
	bsr	if_rgb8_fader_loop
	move.w	d6,cfc_rgb8_colors_counter(a3)
	bne.s	rgb8_colors_fader_cross_quit
	move.w	#FALSE,cfc_rgb8_active(a3)
rgb8_colors_fader_cross_quit
	movem.l (a7)+,a4-a6
	rts


	CNOP 0,4
cfc_rgb8_copy_color_table
	IFNE cl1_size2
		move.l	a4,-(a7)
	ENDC
	tst.w	cfc_rgb8_copy_colors_active(a3)
	bne.s	cfc_rgb8_copy_color_table_quit
	move.w	#RB_NIBBLES_MASK,d3
	IFGT cfc_rgb8_colors_number-32
		moveq	#cfc_rgb8_start_color<<3,d4 ; color registers counter
	ENDC
	lea	vp2_pf2_rgb8_color_table+(cfc_rgb8_color_table_offset*LONGWORD_SIZE)(pc),a0 ; colors buffer
	move.l	cl1_display(a3),a1 
	ADDF.W	cl1_COLOR00_high1+(cfc_rgb8_start_color*LONGWORD_SIZE)+WORD_SIZE,a1
	IFNE cl1_size1
		move.l	cl1_construction1(a3),a2 
		ADDF.W	cl1_COLOR00_high1+(cfc_rgb8_start_color*LONGWORD_SIZE)+WORD_SIZE,a2
	ENDC
	IFNE cl1_size2
		move.l	cl1_construction2(a3),a4 
		ADDF.W	cl1_COLOR00_high1+(cfc_rgb8_start_color*LONGWORD_SIZE)+WORD_SIZE,a4
	ENDC
	MOVEF.W cfc_rgb8_colors_number-1,d7
cfc_rgb8_copy_color_table_loop
	move.l	(a0)+,d0		; RGB8
	move.l	d0,d2	
	RGB8_TO_RGB4_HIGH d0,d1,d3
	move.w	d0,(a1)			; color high
	IFNE cl1_size1
		move.w	d0,(a2)		; color high
	ENDC
	IFNE cl1_size2
		move.w	d0,(a4)		; color high
	ENDC
	RGB8_TO_RGB4_LOW d2,d1,d3
	move.w	d2,cl1_COLOR00_low1-cl1_COLOR00_high1(a1) ; color low
	addq.w	#LONGWORD_SIZE,a1	; next color register
	IFNE cl1_size1
		move.w	d2,cl1_COLOR00_low1-cl1_COLOR00_high1(a2) ; color low
		addq.w	#LONGWORD_SIZE,a2 ; next color register
	ENDC
	IFNE cl1_size2
		move.w	d2,cl1_COLOR00_low1-cl1_COLOR00_high1(a4) ; color low
		addq.w	#LONGWORD_SIZE,a4 ; next color register
	ENDC
	IFGT cfc_rgb8_colors_number-32
		addq.b	#1<<3,d4	; increase color registers counter
		bne.s	cfc_rgb8_copy_color_table_skip
		addq.w	#LONGWORD_SIZE,a1 ; skip CMOVE
		IFNE cl1_size1
			addq.w	#LONGWORD_SIZE,a2 ; skip CMOVE
		ENDC
		IFNE cl1_size2
			addq.w	#LONGWORD_SIZE,a4 ; skip CMOVE
		ENDC
cfc_rgb8_copy_color_table_skip
	ENDC
	dbf	d7,cfc_rgb8_copy_color_table_loop
	tst.w	cfc_rgb8_colors_counter(a3) ; fading finished ?
	bne.s	cfc_rgb8_copy_color_table_quit
	move.w	#FALSE,cfc_rgb8_copy_colors_active(a3)
	move.w	#cfc_rgb8_fader_delay,cfc_rgb8_fader_delay_counter(a3)
	move.w	cfc_rgb8_color_table_start(a3),d0
	addq.w	#1,d0			; next color table
	and.w	#cfc_rgb8_color_tables_number-1,d0 ; remove overflow
	move.w	d0,cfc_rgb8_color_table_start(a3)
cfc_rgb8_copy_color_table_quit
	IFNE cl1_size2
		move.l	(a7)+,a4
	ENDC
	rts


	CNOP 0,4
control_counters
	move.w	cfc_rgb8_fader_delay_counter(a3),d0
	bmi.s	control_counters_quit
	subq.w	#1,d0
	bpl.s	control_counters_skip
	move.w	#cfc_rgb8_colors_number*3,cfc_rgb8_colors_counter(a3)
	clr.w	cfc_rgb8_copy_colors_active(a3)
	clr.w	cfc_rgb8_active(a3)
	move.w	#sine_table_length/4,cfc_rgb8_fader_angle(a3) ; 90�
control_counters_skip
	move.w	d0,cfc_rgb8_fader_delay_counter(a3) 
control_counters_quit
	rts


	CNOP 0,4
mouse_handler
	btst	#CIAB_GAMEPORT0,CIAPRA(a4) ; LMB pressed ?
	beq.s	mh_exit_demo
	rts
	CNOP 0,4
mh_exit_demo
	move.w	#FALSE,pt_effects_handler_active(a3)
	tst.w	hst_active(a3)
	bne.s	mh_exit_demo_skip1
	move.w	#hst_horiz_scroll_speed2,hst_horiz_scroll_speed(a3) ; scrolltext double speed
	move.w	#hst_stop_text-hst_text,hst_text_table_start(a3) ; end of text
	clr.w	quit_active(a3)		; quit intro after text stop
	bra	mh_exit_demo_quit
	CNOP 0,4
mh_exit_demo_skip1
	clr.w	pt_music_fader_active(a3)
	tst.w	fbi_active(a3)
	bne.s	mh_exit_demo_skip2
	move.w	#FALSE,fbi_active(a3)
mh_exit_demo_skip2
	tst.w	mvb_mask(a3)
	beq.s	mh_exit_demo_skip3
	clr.w	fbo_active(a3)
	move.w	#fbo_delay,fbo_delay_counter(a3)
	move.w	#$8888,fb_mask(a3)
mh_exit_demo_skip3
	move.w	#sprf_rgb8_colors_number*3,sprf_rgb8_colors_counter(a3)
	tst.w	sprfi_rgb8_active(a3)
	bne.s	mh_exit_demo_skip4
	move.w	#FALSE,sprfi_rgb8_active(a3)
mh_exit_demo_skip4
	moveq	#TRUE,d0
	move.w	d0,sprfo_rgb8_active(a3)
	move.w	#sprf_rgb8_colors_number*3,sprf_rgb8_colors_counter(a3)
	move.w	d0,sprf_rgb8_copy_colors_active(a3)
	tst.w	ifi_rgb8_active(a3)
	bne.s	mh_exit_demo_skip5
	move.w	#FALSE,ifi_rgb8_active(a3)
mh_exit_demo_skip5
	move.w	d0,ifo_rgb8_active(a3)
	move.w	#if_rgb8_colors_number*3,if_rgb8_colors_counter(a3)
	move.w	d0,if_rgb8_copy_colors_active(a3)
	tst.w	cfi_rgb8_active(a3)
	bne.s	mh_exit_demo_skip6
	move.w	#FALSE,cfi_rgb8_active(a3)
mh_exit_demo_skip6
	move.w	d0,cfo_rgb8_active(a3)
	tst.w	bfi_rgb8_active(a3)
	bne.s	mh_exit_demo_skip7
	move.w	#FALSE,bfi_rgb8_active(a3)
mh_exit_demo_skip7
	move.w	d0,bfo_rgb8_active(a3)
	move.w	d0,bf_rgb8_colors_counter(a3)
	move.w	d0,bf_rgb8_copy_colors_active(a3)
mh_exit_demo_quit
	rts


	INCLUDE "int-autovectors-handlers.i"

	IFEQ pt_ciatiming_enabled
		CNOP 0,4
ciab_ta_server
	ENDC

	IFNE pt_ciatiming_enabled
		CNOP 0,4
VERTB_server
	ENDC


; PT-Replay
	IFEQ pt_music_fader_enabled
		bsr.s	pt_music_fader
		bsr.s	pt_PlayMusic
		rts

		PT_FADE_OUT_VOLUME stop_fx_active
		CNOP 0,4
	ENDC

	IFD PROTRACKER_VERSION_2 
		PT2_REPLAY pt_effects_handler
	ENDC
	IFD PROTRACKER_VERSION_3
		PT3_REPLAY pt_effects_handler
	ENDC

	CNOP 0,4
pt_effects_handler
	tst.w	pt_effects_handler_active(a3)
	bne.s	pt_effects_handler_quit
	move.b	n_cmdlo(a2),d0
	lsr.b	#4,d0			; x
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
pt_effects_handler_quit
	rts
	CNOP 0,4
pt_start_fade_bars_in
	clr.w	bfi_rgb8_active(a3)
	move.w	#bf_rgb8_colors_number*3,bf_rgb8_colors_counter(a3)
	clr.w	bf_rgb8_copy_colors_active(a3)
	rts
	CNOP 0,4
pt_start_image_fader_in
	clr.w	ifi_rgb8_active(a3)
	move.w	#if_rgb8_colors_number*3,if_rgb8_colors_counter(a3)
	clr.w	if_rgb8_copy_colors_active(a3)
	rts
	CNOP 0,4
pt_start_fade_chessboard_in
	clr.w	cfi_rgb8_active(a3)
	rts
	CNOP 0,4
pt_start_fade_sprites_in
	clr.w	sprfi_rgb8_active(a3)
	move.w	#sprf_rgb8_colors_number*3,sprf_rgb8_colors_counter(a3)
	clr.w	sprf_rgb8_copy_colors_active(a3)
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
	clr.w	hst_active(a3)
	rts
	CNOP 0,4
pt_enable_skip_commands
	clr.w	pt_skip_commands_enabled(a3)
	rts
	CNOP 0,4
pt_set_stripes_y_angle_speed
	moveq	#NIBBLE_MASK_LOW,d0
	and.b	n_cmdlo(a2),d0
	move.w	d0,cb_stripes_y_angle_speed(a3)
	rts
	CNOP 0,4
pt_trigger_morphing
	clr.w	mvb_morph_active(a3)
	rts

	CNOP 0,4
ciab_tb_server
	PT_TIMER_INTERRUPT_SERVER

	CNOP 0,4
EXTER_server
	rts

	CNOP 0,4
nmi_server
	rts


	INCLUDE "help-routines.i"


	INCLUDE "sys-structures.i"


; View 
	CNOP 0,4
pf1_rgb8_color_table
	DC.L color00_bits

; Viewport 2
	CNOP 0,4
vp2_pf1_rgb8_color_table
	REPT vp2_visible_lines_number
		DC.L color00_bits
	ENDR
	CNOP 0,4
vp2_pf2_rgb8_color_table
	REPT vp2_pf2_colors_number*2
		DC.L color00_bits
	ENDR

; Viewport 3
	CNOP 0,4
vp3_pf1_rgb8_color_table
	DC.L color00_bits
	REPT vp3_pf1_colors_number-1
		DC.L $202020		; balls shadow color
	ENDR


	CNOP 0,4
spr_rgb8_color_table
	REPT spr_colors_number
		DC.L color00_bits
	ENDR

	CNOP 0,4
spr_pointers_display
	DS.L spr_number


	CNOP 0,4
sine_table
	INCLUDE "sine-table-512x32.i"


; PT-Replay 
	INCLUDE "music-tracker/pt-invert-table.i"

	INCLUDE "music-tracker/pt-vibrato-tremolo-table.i"

	IFD PROTRACKER_VERSION_2 
		INCLUDE "music-tracker/pt2-period-table.i"
	ENDC
	IFD PROTRACKER_VERSION_3
		INCLUDE "music-tracker/pt3-period-table.i"
	ENDC

	INCLUDE "music-tracker/pt-temp-channel-data-tables.i"

	INCLUDE "music-tracker/pt-sample-starts-table.i"

	INCLUDE "music-tracker/pt-finetune-starts-table.i"


; Horiz-Scrolltext 
	CNOP 0,4
hst_fill_gradient
	INCLUDE "30:colortables/24-Colorgradient.ct"

	CNOP 0,4
hst_outline_gradient
	INCLUDE "30:colortables/26-Colorgradient.ct"

hst_ascii
	DC.B "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.!?-'():\/#+<>",ASCII_CTRL_O," "
hst_ascii_end
	EVEN

	CNOP 0,2
hst_chars_offsets
	DS.W hst_ascii_end-hst_ascii

	CNOP 0,2
hst_chars_x_positions
	DS.W hst_text_chars_number

	CNOP 0,4
hst_chars_image_pointers
	DS.L hst_text_chars_number


; Bounce-VU-Meter 
	CNOP 0,4
bvm_rgb8_color_gradients
	INCLUDE "30:colortables/4x3-Colorgradient.ct"

	CNOP 0,4
bvm_rgb8_color_table
	REPT spr_colors_number*(bvm_bar_height/2)*bvm_bars_number
		DC.L color00_bits
	ENDR

bvm_sprm_table
	DC.B $33,$44,$55,$55,$44,$33	; bar1
	DC.B $66,$77,$88,$88,$77,$66	; bar2
	DC.B $99,$aa,$bb,$bb,$aa,$99	; bar3
	DC.B $cc,$dd,$ee,$ee,$dd,$cc	; bar4

	CNOP 0,2
bvm_audio_channel1_info
	DS.B audio_channel_info_size

	CNOP 0,2
bvm_audio_channel2_info
	DS.B audio_channel_info_size

	CNOP 0,2
bvm_audio_channel3_info
	DS.B audio_channel_info_size

	CNOP 0,2
bvm_audio_channel4_info
	DS.B audio_channel_info_size


; Morp-Vector-Balls 
	CNOP 0,2
mvb_object_coordinates
; Zoom-In
	DS.W mvb_object_points_number*3

; Shape 1 
	CNOP 0,2
mvb_object_shape1_coordinates
; Letter "R"
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
; Letter "S"
	DC.W -(19*8),-(25*8),25*8	; P11
	DC.W -(19*8),-(13*8),25*8	; P12
	DC.W -(19*8),19*8,25*8		; P13

	DC.W -(6*8),-(32*8),25*8	; P13
	DC.W -(6*8),-(6*8),25*8		; P15
	DC.W -(6*8),19*8,25*8		; P16

	DC.W 6*8,-(32*8),25*8		; P16
	DC.W 6*8,0,25*8			; P18
	DC.W 6*8,13*8,25*8		; P19
; Letter "E"
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

; Shape 2 
	CNOP 0,2
mvb_object_shape2_coordinates
; Letter "3"
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
; Letter "0"
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

	DC.W 38*8,32*8,25*8		; P29 (left over)

	IFNE mvb_morph_loop_enabled
; Shape 3
		CNOP 0,2
mvb_object_shape3_coordinates
; Zoom-Out
		DS.W mvb_object_points_number*3
	ENDC

	CNOP 0,2
mvb_object_coordinates_offsets
	DS.W mvb_object_points_number

	CNOP 0,2
mvb_rotation_xyz_coordinates
	DS.W mvb_object_points_number*3

	CNOP 0,4
mvb_morph_shapes_table
	DS.B mvb_morph_shape_size*mvb_morph_shapes_number


; Chessboard
	CNOP 0,4
cb_color_gradient1
	INCLUDE "30:colortables/48-ColorgradientA.ct"

	CNOP 0,4
cb_color_gradient2
	INCLUDE "30:colortables/48-ColorgradientB.ct"

	CNOP 0,2
cb_fill_pattern
	DC.W $ffff,$0000,$0000,$ffff

	CNOP 0,2
cb_stripes_y_coordinates
	DS.W cb_stripe_height*cb_stripes_number

	CNOP 0,2
cb_color_offsets_table
	DS.W cb_stripe_height*cb_stripes_number*2


; Bar-Fader
	CNOP 0,4
bfi_rgb8_color_table
	DS.L spr_colors_number*(bvm_bar_height/2)*bvm_bars_number

	CNOP 0,4
bfo_rgb8_color_table
	REPT spr_colors_number*(bvm_bar_height/2)*bvm_bars_number
		DC.L color00_bits
	ENDR

	CNOP 0,4
bf_rgb8_color_cache
	REPT spr_colors_number*(bvm_bar_height/2)*bvm_bars_number
		DC.L color00_bits
	ENDR


; Image-Fader
	CNOP 0,4
ifi_rgb8_color_table
	INCLUDE "30:colortables/320x182x16-Temple.ct"m

	CNOP 0,4
ifo_rgb8_color_table
	REPT vp2_pf1_colors_number
		DC.L color00_bits
	ENDR


; Chessboard-Fader
	CNOP 0,4
cfi_rgb8_color_table
	REPT vp3_visible_lines_number*2
		DC.L color00_bits
	ENDR

	CNOP 0,4
cfo_rgb8_color_table
	REPT vp3_visible_lines_number*2
		DC.L color00_bits
	ENDR


; Sprite-Fader
	CNOP 0,4
sprfi_rgb8_color_table
	INCLUDE "30:colortables/256x208x16-Desert-Sunset.ct"

	CNOP 0,4
sprfo_rgb8_color_table
	REPT spr_colors_number
		DC.L color00_bits
	ENDR


; Color-Fader-Cross
	CNOP 0,4
cfc_rgb8_color_table
	INCLUDE "30:colortables/4x16x11x8-BallsDarkBlue.ct"
	INCLUDE "30:colortables/4x16x11x8-BallsGreen.ct"
	INCLUDE "30:colortables/4x16x11x8-BallsOrange.ct"
	INCLUDE "30:colortables/4x16x11x8-BallsLightBlue.ct"


	INCLUDE "sys-variables.i"


	INCLUDE "sys-names.i"


	INCLUDE "error-texts.i"


; Horiz-Scrolltext 
hst_text
	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B "WE ARE CELEBRATING 30 YEARS OF DEMOS FUN AND SHARED ACHIEVEMENTS TOGETHER IN RESISTANCE"

	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B "FROM THE VERY FIRST STEPS WE TOOK TOGETHER TO THE CHALLENGES WE'VE OVERCOME AND THE VICTORIES WE'VE CELEBRATED THIS JOURNEY HAS BEEN FUN!"

	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B "WE HAVE ALL CONTRIBUTED TO MAKING THIS GROUP WHAT IT IS TODAY"

	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B "IT'S NOT JUST THE ACCOMPLISHMENTS BUT THE MEMORIES THE FRIENDSHIPS AND THE SPIRIT OF COLLABORATION THAT HAVE SHAPED US INTO A GROUP OF STRENGTH AND SUPPORT"

	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B "AS WE REFLECT ON THE DECADES TOGETHER LET'S TAKE PRIDE IN HOW FAR WE HAVE COME BUT ALSO LOOK FORWARD TO THE EXCITING POSSIBILITIES AHEAD"

	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B "THE NEXT CHAPTER IS OURS TO WRITE AND WITH THE SAME PASSION AND DEDICATION THAT GOT US HERE THE BEST IS YET TO COME"

	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B "THANK YOU ALL FOR BEING A PART OF THIS JOURNEY"

	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B "SIGNED 4PLAY"

	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B "CODING BY DISSIDENT       GRAPHICS BY GRASS       MUSIC BY MA2E"

	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR

	DC.B FALSE
hst_stop_text
	REPT (hst_text_chars_number/(hst_origin_char_x_size/hst_text_char_x_size))+1
		DC.B " "
	ENDR
	DC.B ASCII_CTRL_S," "
	EVEN


	DC.B "$VER: "
	DC.B "RSE-30 1.3  "
	DC.B "(18.4.25) "
	DC.B "� 2025 by Resistance",0
	EVEN


; Audio data

; PT-Replay
	IFEQ pt_split_module_enabled
pt_auddata			SECTION pt_audio,DATA
		INCBIN "30:trackermodules/MOD.run in neon lights.song"
pt_audsmps			SECTION pt_audio2,DATA_C
		INCBIN "30:trackermodules/MOD.run in neon lights.smps"
	ELSE
pt_auddata			SECTION pt_audio,DATA_C
		INCBIN "30:trackermodules/MOD.run in neon lights"
	ENDC


; Gfx data

; Background-Image1 
bg1_image_data			SECTION bg1_gfx,DATA
	INCBIN "30:graphics/256x208x16-Desert-Sunset.rawblit"

; Background-Image2 
bg2_image_data			SECTION bg2_gfx,DATA
	INCBIN "30:graphics/320x182x16-Temple.rawblit"

; Horiz-Scrolltext 
hst_image_data			SECTION hst_gfx,DATA_C
	INCBIN "30:fonts/32x26x4-Font.rawblit"

; Morph-Vector-Balls 
mvb_image_data			SECTION mvb_gfx1,DATA_C
	INCBIN "30:graphics/4x16x11x8-Balls.rawblit"

mvb_image_mask			SECTION mvb_gfx2,DATA_C
	INCBIN "30:graphics/4x16x11x8-Balls.mask"

	END
