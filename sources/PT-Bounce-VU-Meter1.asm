; #####################################
; # Programm: PT-Bounce-VU-Meter1.asm #
; # Autor:    Christian Gerbig        #
; # Datum:    25.11.2023              #
; # Version:  1.3                     #
; # CPU:      68020+                  #
; # FASTMEM:  -                       #
; # Chipset:  AGA                     #
; # OS:       3.0+                    #
; #####################################

; Schnellere Replay-Routine für 31-Samples-Module des Protracker 1.x/2.x
; pt_ciatiming: TRUE = Abspielen durch Benutzung des CIA-B timer A Interrupts
;                      mit variablen 32..255 BPM bei gleichem Tempo auf 50 Hz
;                      PAL Amigas und 60 Hz NTSC-Amigas
; pt_ciatiming: FALSE = Abspielen durch Benutzung des VBlank Interrupts mit
;                       festen 125 BPM auf 50 Hz PAL-Amigas oder mit festen
;                       150 BPM auf 60 Hz NTSC-Amigas
; Der passende Code wird durch die Zuweisung von pt_ciatiming=TRUE/FALSE
; erzeugt
; Bei den Loop-Samples ist der Repeat-Point im Modul in Worten angegeben.
; Samples werden beim ersten Anspielen vom Beginn an bis zum Schleifenende
; spielt und danach ab dem Repeat-Point, der im Modul in Worten angegeben
; ist. Wenn der Repeat-Point = NULL ist, jedoch eine Repeat-Length angegeben
; ist, dann wird das Sample beim ersten Anspielen vom Beginn bis zum Sample-
; ende und danach die Schleife gespielt.
; Bei den Loopsamples wird nun die Repeat-Length auf > 1 Wort geprüft. Somit
; werden auch Loopsamples mit dem Repeat-Point = NULL korrekt abgespielt
; RetrigNote/Note Delay-Befehl: DMA-Warteschleifen komplett per CIA-B timer B
; Interrupt erzeugt
; Benutzung des CIA-A-Level-2-Interrupts nicht mehr notwendig
; Wenn die Labels pt_v2.3a oder pt_v3.0b gesetzt sind, dann wird der Code
; angepasst
; Das Modul wird bei Druck der rechten Maustaste  durch die Zuweisung
; pt_fademusic = TRUE ausgeblendet und der entsprechende Code eingefügt
; Das Anspielen einer Note auf einzelnen Kanäle wird durch dotzende Copper-
; bars dargestellt

; Folgende Effekte werden unterstützt:
; 0 - Normal play or Arpeggio
; 1 - Portamento Up
; 2 - Portamento Down
; 3 - Tone Portamento
; 4 - Vibrato
; 5 - Tone Portamento + Volume Slide
; 6 - Vibrato + Volume Slide
; 7 - Tremolo
; 8 - NOT USED
; 9 - Set Sample Offset
; A - Volume Slide
; B - Position Jump
; C - Set Volume
; D - Pattern Break
; E - Extended commands
;   E0 - Set Filter
;   E1 - Fine Portamento Up
;   E2 - Fine Portamento Down
;   E3 - Set Glissando Control
;   E4 - Set Vibrato Waveform
;   E5 - Set Sample Finetune
;   E6 - Jump to Loop
;   E7 - Set Tremolo Waveform
;   E8 - NOT USED / Karplus Strong
;   E9 - Retrig Note
;   EA - Fine Volume Slide Up
;   EB - Fine Volume Slide Down
;   EC - Note Cut
;   ED - Note Delay
;   EE - Pattern Delay
;   EF - Invert Loop
; F - Set Speed

; Ausführungszeit 68020: n Rasterzeilen

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

requires_68030             EQU FALSE
requires_68040             EQU FALSE
requires_68060             EQU FALSE
requires_fast_memory       EQU FALSE
requires_multiscan_monitor EQU FALSE

workbench_start            EQU FALSE
workbench_fade             EQU FALSE
text_output                EQU FALSE

color_gradient_RGB8

pt_v3.0b
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-equals.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-equals.i"
  ENDC
pt_ciatiming               EQU TRUE
pt_usedfx                  EQU pt_allusedfx
pt_usedefx                 EQU pt_allusedefx
pt_finetune                EQU TRUE
  IFD pt_v3.0b
pt_metronome               EQU TRUE
  ENDC
pt_track_channel_volumes   EQU TRUE
pt_track_channel_periods   EQU FALSE
pt_music_fader             EQU FALSE
pt_split_module            EQU FALSE

DMABITS                    EQU DMAF_COPPER+DMAF_MASTER+DMAF_SETCLR

  IFEQ pt_ciatiming
INTENABITS                 EQU INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ELSE
INTENABITS                 EQU INTF_VERTB+INTF_EXTER+INTF_INTEN+INTF_SETCLR
  ENDC

CIAAICRBITS                EQU CIAICRF_SETCLR
  IFEQ pt_ciatiming
CIABICRBITS                EQU CIAICRF_TA+CIAICRF_TB+CIAICRF_SETCLR
  ELSE
CIABICRBITS                EQU CIAICRF_TB+CIAICRF_SETCLR
  ENDC

COPCONBITS                 EQU TRUE

pf1_x_size1                EQU 0
pf1_y_size1                EQU 0
pf1_depth1                 EQU 0
pf1_x_size2                EQU 0
pf1_y_size2                EQU 0
pf1_depth2                 EQU 0
pf1_x_size3                EQU 0
pf1_y_size3                EQU 0
pf1_depth3                 EQU 0
pf1_colors_number          EQU 0 ;1

pf2_x_size1                EQU 0
pf2_y_size1                EQU 0
pf2_depth1                 EQU 0
pf2_x_size2                EQU 0
pf2_y_size2                EQU 0
pf2_depth2                 EQU 0
pf2_x_size3                EQU 0
pf2_y_size3                EQU 0
pf2_depth3                 EQU 0
pf2_colors_number          EQU 0
pf_colors_number           EQU pf1_colors_number+pf2_colors_number
pf_depth                   EQU pf1_depth3+pf2_depth3

extra_pf_number            EQU 0

spr_number                 EQU 0
spr_x_size1                EQU 0
spr_y_size1                EQU 0
spr_x_size2                EQU 0
spr_y_size2                EQU 0
spr_depth                  EQU 0
spr_colors_number          EQU 0

  IFD pt_v2.3a
audio_memory_size          EQU 0
  ENDC
  IFD pt_v3.0b
audio_memory_size          EQU 2
  ENDC

disk_memory_size           EQU 0

chip_memory_size           EQU 0

AGA_OS_Version             EQU 39

  IFEQ pt_ciatiming
CIABCRABITS                EQU CIACRBF_LOAD
  ENDC
CIABCRBBITS                EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;Oneshot mode
CIAA_TA_value              EQU 0
CIAA_TB_value              EQU 0
  IFEQ pt_ciatiming
CIAB_TA_value              EQU 14187 ;= 0.709379 MHz * [20000 µs = 50 Hz duration for one frame on a PAL machine]
;CIAB_TA_value              EQU 14318 ;= 0.715909 MHz * [20000 µs = 50 Hz duration for one frame on a NTSC machine]
  ELSE
CIAB_TA_value              EQU 0
  ENDC
CIAB_TB_value              EQU 362 ;= 0.709379 MHz * [511.43 µs = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [506.76 µs = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
CIAA_TA_continuous         EQU FALSE
CIAA_TB_continuous         EQU FALSE
  IFEQ pt_ciatiming
CIAB_TA_continuous         EQU TRUE
  ELSE
CIAB_TA_continuous         EQU FALSE
  ENDC
CIAB_TB_continuous         EQU FALSE

beam_position              EQU $136

BPLCON0BITS                EQU BPLCON0F_ECSENA+((pf_depth>>3)*BPLCON0F_BPU3)+(BPLCON0F_COLOR)+((pf_depth&$07)*BPLCON0F_BPU0) ;lores
BPLCON3BITS1               EQU TRUE
BPLCON3BITS2               EQU BPLCON3BITS1+BPLCON3F_LOCT
BPLCON4BITS                EQU TRUE
COLOR00BITS                EQU $001122
COLOR00HIGHBITS            EQU $012
COLOR00LOWBITS             EQU $012

cl2_display_x_size         EQU 0
cl2_display_width          EQU cl2_display_x_size/2
cl2_display_y_size         EQU 256
cl2_HSTART1                EQU $00
cl2_VSTART1                EQU VSTART_256_lines
cl2_HSTART2                EQU $00
cl2_VSTART2                EQU beam_position&$ff

sine_table_length          EQU 256

; **** PT-Replay ****
pt_fade_out_delay          EQU 2 ;Ticks

; **** Bounce-VU-Meter ****
bvm_bar_height             EQU 6
bvm_max_amplitude          EQU 22-bvm_bar_height
bvm_y_centre               EQU 22-bvm_bar_height
bvm_y_angle_speed          EQU 4


color_step1                EQU 256/(bvm_bar_height/2)
color_values_number1       EQU bvm_bar_height/2
segments_number1           EQU pt_chansnum*2

ct_size1                   EQU color_values_number1*segments_number1

extra_memory_size          EQU ct_size1*LONGWORDSIZE


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

cl1_begin        RS.B 0

  INCLUDE "copperlist1-offsets.i"

cl1_COPJMP2      RS.L 1

copperlist1_SIZE RS.B 0


; ** Struktur, die alle Registeroffsets der zweiten Copperliste enthält **
; ------------------------------------------------------------------------
  RSRESET

cl2_extension1        RS.B 0

cl2_ext1_WAIT         RS.L 1
cl2_ext1_BPLCON3_1    RS.L 1
cl2_ext1_COLOR00_high RS.L 1
cl2_ext1_BPLCON3_2    RS.L 1
cl2_ext1_COLOR00_low  RS.L 1
cl2_ext1_NOOP         RS.L 1

cl2_extension1_SIZE   RS.B 0


  RSRESET

cl2_extension2        RS.B 0

cl2_ext2_WAIT         RS.L 1
cl2_ext2_BPLCON3_1    RS.L 1
cl2_ext2_COLOR00_high RS.L 1
cl2_ext2_BPLCON3_2    RS.L 1
cl2_ext2_COLOR00_low  RS.L 1

cl2_extension2_SIZE   RS.B 0


  RSRESET

cl2_begin             RS.B 0

cl2_extension1_entry  RS.B cl2_extension1_SIZE*cl2_display_y_size
cl2_extension2_entry  RS.B cl2_extension2_SIZE

cl2_WAIT              RS.L 1
cl2_INTREQ            RS.L 1

cl2_end               RS.L 1

copperlist2_SIZE      RS.B 0


; ** Konstanten für die größe der Copperlisten **
; -----------------------------------------------
cl1_size1        EQU 0
cl1_size2        EQU 0
cl1_size3        EQU copperlist1_SIZE
cl2_size1        EQU 0
cl2_size2        EQU copperlist2_SIZE
cl2_size3        EQU copperlist2_SIZE


; ** Konstanten für die Größe der Spritestrukturen **
; ---------------------------------------------------
spr0_x_size1     EQU spr_x_size1
spr0_y_size1     EQU 0
spr1_x_size1     EQU spr_x_size1
spr1_y_size1     EQU 0
spr2_x_size1     EQU spr_x_size1
spr2_y_size1     EQU 0
spr3_x_size1     EQU spr_x_size1
spr3_y_size1     EQU 0
spr4_x_size1     EQU spr_x_size1
spr4_y_size1     EQU 0
spr5_x_size1     EQU spr_x_size1
spr5_y_size1     EQU 0
spr6_x_size1     EQU spr_x_size1
spr6_y_size1     EQU 0
spr7_x_size1     EQU spr_x_size1
spr7_y_size1     EQU 0

spr0_x_size2     EQU spr_x_size2
spr0_y_size2     EQU 0
spr1_x_size2     EQU spr_x_size2
spr1_y_size2     EQU 0
spr2_x_size2     EQU spr_x_size2
spr2_y_size2     EQU 0
spr3_x_size2     EQU spr_x_size2
spr3_y_size2     EQU 0
spr4_x_size2     EQU spr_x_size2
spr4_y_size2     EQU 0
spr5_x_size2     EQU spr_x_size2
spr5_y_size2     EQU 0
spr6_x_size2     EQU spr_x_size2
spr6_y_size2     EQU 0
spr7_x_size2     EQU spr_x_size2
spr7_y_size2     EQU 0


; ** Struktur, die alle Variablenoffsets enthält **
; -------------------------------------------------

  INCLUDE "variables-offsets.i"

; **** PT-Replay ****
  IFD pt_v2.3a
    INCLUDE "music-tracker/pt2-variables-offsets.i"
  ENDC
  IFD pt_v3.0b
    INCLUDE "music-tracker/pt3-variables-offsets.i"
  ENDC

variables_SIZE RS.B 0


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
  rts

; ** Alle Initialisierungsroutinen ausführen **
; ---------------------------------------------
  CNOP 0,4
init_all
  bsr.s   pt_DetectSysFrequ
  bsr.s   init_CIA_timers
  bsr.s   init_color_registers
  bsr     pt_InitRegisters
  bsr     pt_InitAudTempStrucs
  bsr     pt_ExamineSongStruc
  IFEQ pt_finetune
    bsr     pt_InitFtuPeriodTableStarts
  ENDC
  bsr     bvm_init_color_table
  bsr     bvm_InitAudChanDataStrucs
  bsr     init_first_copperlist
  bsr     init_second_copperlist
  bsr     copy_second_copperlist
  bra     swap_second_copperlist

; **** PT-Replay****
; ** Detect system frequency NTSC/PAL **
; --------------------------------------
  PT_DETECT_SYS_FREQUENCY

; ** CIA-Timer initialisieren **
; ------------------------------
  CNOP 0,4
init_CIA_timers

; **** PT-Replay****
  PT_INIT_TIMERS
  rts

; ** Farbregister initialisieren **
; ---------------------------------
  CNOP 0,4
init_color_registers
  CPU_SELECT_COLORHI_BANK 0
  CPU_INIT_COLORHI COLOR00,1,pf1_color_table

  CPU_SELECT_COLORLO_BANK 0
  CPU_INIT_COLORLO COLOR00,1,pf1_color_table
  rts

; **** PT-Replay ****
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

; **** Bounce-VU-Meter ****
; ** Farbtabelle initialisieren **
; --------------------------------
  CNOP 0,4
bvm_init_color_table
  movem.l a4-a5,-(a7)
; ** blauer Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $000001,$0000ff,color_values_number1,color_step1,extra_memory,a3,0,1
  INIT_COLOR_GRADIENT_RGB8 $0000ff,$000001,color_values_number1
; ** gelber Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $010100,$ffff00,color_values_number1
  INIT_COLOR_GRADIENT_RGB8 $ffff00,$010100,color_values_number1
; ** roter Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $010000,$ff0000,color_values_number1
  INIT_COLOR_GRADIENT_RGB8 $ff0000,$010000,color_values_number1
; ** violetter Farbverlauf **
  INIT_COLOR_GRADIENT_RGB8 $010001,$ff00ff,color_values_number1
  INIT_COLOR_GRADIENT_RGB8 $ff00ff,$010001,color_values_number1
  movem.l (a7)+,a4-a5
  rts

; ** Audiochandata-Strukturen initialisieren **
; ---------------------------------------------
  CNOP 0,4
bvm_InitAudChanDataStrucs
  lea     bvm_audio_channel1_info(pc),a0
  moveq   #sine_table_length/4,d0 ;Winkel 90 Grad = Maximaler Ausschlag der Sinuskurve
  move.w  d0,(a0)+           ;Y-Winkel
  moveq   #TRUE,d1
  move.w  d1,(a0)+           ;Amplitude
  move.w  d0,(a0)+
  move.w  d1,(a0)+
  move.w  d0,(a0)+
  move.w  d1,(a0)+
  move.w  d0,(a0)+
  move.w  d1,(a0)
  rts


; ** 1. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_first_copperlist
  move.l  cl1_display(a3),a0 ;Darstellen-CL
  bsr.s   cl1_init_playfield_registers
  COPMOVEQ TRUE,COPJMP2
  rts

  COP_INIT_PLAYFIELD_REGISTERS cl1,BLANK

; ** 2. Copperliste initialisieren **
; -----------------------------------
  CNOP 0,4
init_second_copperlist
  move.l  cl2_construction2(a3),a0 ;Aufbau-CL
  bsr.s   cl2_init_COLOR00_registers
  bsr.s   cl2_reset_COLOR00
  bsr.s   cl2_init_copint
  COPLISTEND
  rts

  COP_INIT_COLOR00_REGISTERS cl2,YWRAP

  COP_RESET_COLOR00 cl2,0,cl2_VSTART1+cl2_display_y_size

  COP_INIT_COPINT cl2,cl2_HSTART2,cl2_VSTART2

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
  bsr.s   swap_second_copperlist
  bsr.s   get_channels_amplitudes
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

; ** Amplituden der einzelnen Kanäle in Erfahrung bringen **
; ----------------------------------------------------------
  CNOP 0,4
get_channels_amplitudes
  MOVEF.W bvm_max_amplitude,d2
  moveq   #sine_table_length/4,d3
  lea	  pt_audchan1temp(pc),a0 ;Zeiger auf temporäre Struktur des 1. Kanals
  lea     bvm_audio_channel1_info(pc),a1
  bsr.s   get_channel_amplitude
  lea	  pt_audchan2temp(pc),a0 ;Zeiger auf temporäre Struktur des 2. Kanals
  bsr.s   get_channel_amplitude
  lea	  pt_audchan3temp(pc),a0 ;Zeiger auf temporäre Struktur des 3. Kanals
  bsr.s   get_channel_amplitude
  lea	  pt_audchan4temp(pc),a0 ;Zeiger auf temporäre Struktur des 4. Kanals

; ** Routine get-channel-amplitude **
; d2 ... Maximale Amplitude
; d3 ... Y-Winkel 90 Grad
; a0 ... Temporäre Struktur des Audiokanals
; a1 ... Zeiger auf Amplitudenwert des Kanals
get_channel_amplitude
  tst.b   n_note_trigger(a0) ;Neue Note angespielt ?
  bne.s   no_get_channel_amplitude ;Nein -> verzweige
  moveq   #TRUE,d0           ;NULL wegen Wortzugriff
  move.b  n_volume(a0),d0    ;Aktuelle Lautstärke
  moveq   #FALSE,d1
  move.b  d1,n_note_trigger(a0) ;Note Trigger Flag zurücksetzen
  MULUF.W bvm_max_amplitude,d0,d1 ;Aktuelle Lautstärke * maximale Amplitude
  lsr.w   #6,d0              ;/maximale Lautstärke
  cmp.w	  d2,d0              ;Amplitude <= maximale Amplitude ?
  ble.s   bvm_set_amplitude ;Ja -> verzweige
  move.w  d2,d0              ;Maximale Amplitude setzen
bvm_set_amplitude
  move.w  d3,(a1)+           ;Y-Winkel retten
  move.w  d0,(a1)+           ;Amplitudenwert retten
no_get_channel_amplitude
  rts

; ** Farbwerte der Farbe00 in Copperliste löschen **
; --------------------------------------------------
  CLEAR_COLOR00_SCREEN bvm,cl2,construction2,extension1,16

; ** Bars darstellen **
; ---------------------
  CNOP 0,4
bvm_set_bars
  movem.l a3-a6,-(a7)
  move.w  #$0f0f,d4          ;Maske für High/Low-Bits
  moveq   #(sine_table_length/2)-1,d5
  lea     sine_table(pc),a0  
  lea     bvm_audio_channel1_info(pc),a1 ;Zeiger auf Amplitude und Y-Winkeldes Kanals
  move.l  extra_memory(a3),a4 ;Zeiger auf Farbtabelle
  move.l  cl2_construction2(a3),a5 ;CL
  move.w  #bvm_y_centre,a3
  ADDF.W  cl2_extension1_entry+cl2_ext1_COLOR00_high+2,a5
  move.w  #cl2_extension1_SIZE,a6
  moveq   #pt_chansnum-1,d7  ;Anzahl der Kanäle
bvm_set_bars_loop1
  move.w  (a1)+,d3           ;Y-Winkel
  move.w  (a0,d3.w*2),d0     ;sin(w)
  addq.w  #bvm_y_angle_speed,d3 ;nächster Y-Winkel
  muls.w  (a1)+,d0           ;y'=(yr*sin(w))/2^15
  add.l   d0,d0
  swap    d0
  cmp.w   d5,d3              ;180 Grad erreicht ?
  ble.s   bvm_y_angle_ok     ;Nein -> verzweige
  lsr.w   -2(a1)             ;Amplitude/2
bvm_y_angle_ok
  and.w   d5,d3              ;Überlauf bei 180 Grad
  move.w  d3,-4(a1)          ;Y-Winkel retten
  add.w   a3,d0              ;y' + Y-Mittelpunkt
  MULUF.W cl2_extension1_SIZE/8,d0,d1 ;Y-Offset in CL
  lea     (a5,d0.w*8),a2     ;Y-Offset
  moveq   #bvm_bar_height-1,d6 ;Höhe der Bar
bvm_set_bars_loop2
  move.l  (a4)+,d0           ;RGB-Farbwert
  move.l  d0,d2              ;retten
  RGB8_TO_RGB4HI d0,d1,d4
  move.w  d0,(a2)            ;COLOR00 High-Bits
  RGB8_TO_RGB4LO d2,d1,d4
  move.w  d2,cl2_ext1_COLOR00_low-cl2_ext1_COLOR00_high(a2) ;COLOR00 Low-Bits
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
  ELSE
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

; ** Pointers to priod tables for different tuning **
; ---------------------------------------------------
  INCLUDE "music-tracker/pt-finetune-starts-table.i"

; **** Bounce-VU-Meter ****
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
prg_version DC.B "$VER: PT-Bounce-VU-Meter1 1.3 (25.11.23)",TRUE
  EVEN


; ## Audiodaten nachladen ##
; --------------------------

; **** PT-Replay ****
  IFEQ pt_split_module
pt_auddata SECTION audio,DATA
    INCBIN "Audio.AGA:Modules/MOD.condom_corruption.song"
pt_audsmps SECTION audio2,DATA_C
    INCBIN "Audio.AGA:Modules/MOD.condom_corruption.smps"
  ELSE
pt_auddata SECTION audio,DATA_C
     INCBIN "Daten:Asm-Sources.AGA/30/modules/MOD.lhs_brd"
  ENDC

  END
