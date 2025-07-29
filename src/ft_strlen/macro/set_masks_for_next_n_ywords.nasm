%ifndef SET_MASKS_FOR_NEXT_N_YWORDS_NASM
%define SET_MASKS_FOR_NEXT_N_YWORDS_NASM

; Parameters
; %1: the number of ywords to set masks for (2|4|8).
%macro SET_MASKS_FOR_NEXT_N_YWORDS 1
%define YWORD_COUNT %1
;                                                       ┌──YMM_00_1F──[S_00_1F]
;                                    ┌──MASK_00_3F──MINUB
;                                    │                  └─────────────[S_20_3F]
;                 ┌──MASK_00_7F──MINUB
;                 │                  │                  ┌──YMM_40_5F──[S_40_5F]
;                 │                  └──MASK_40_7F──MINUB
;                 │                                     └─────────────[S_60_7F]
; MASK_00_FF──MINUB
;                 │                                     ┌──YMM_80_9F──[S_80_9F]
;                 │                  ┌──MASK_80_BF──MINUB
;                 │                  │                  └─────────────[S_A0_BF]
;                 └──MASK_80_FF──MINUB
;                                    │                  ┌──YMM_C0_DF──[S_C0_DF]
;                                    └──MASK_C0_FF──MINUB
;                                                       └─────────────[S_E0_FF]
	vmovdqa YMM_00_1F, [ rax + 0x00 ]
%if YWORD_COUNT > 2
	vmovdqa YMM_40_5F, [ rax + 0x40 ]
%if YWORD_COUNT > 4
	vmovdqa YMM_80_9F, [ rax + 0x80 ]
	vmovdqa YMM_C0_DF, [ rax + 0xC0 ]
%endif
%endif
	vpminub MASK_00_3F, YMM_00_1F, [ rax + 0x20 ]
%if YWORD_COUNT > 2
	vpminub MASK_40_7F, YMM_40_5F, [ rax + 0x60 ]
%if YWORD_COUNT > 4
	vpminub MASK_80_BF, YMM_80_9F, [ rax + 0xA0 ]
	vpminub MASK_C0_FF, YMM_C0_DF, [ rax + 0xE0 ]
%endif
	vpminub MASK_00_7F, MASK_00_3F, MASK_40_7F
%if YWORD_COUNT > 4
	vpminub MASK_80_FF, MASK_80_BF, MASK_C0_FF
	vpminub MASK_00_FF, MASK_00_7F, MASK_80_FF
%endif
%endif
%endmacro

%endif
