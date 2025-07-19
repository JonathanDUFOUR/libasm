%ifndef CHECK_AND_COMPARE_N_YWORDS_NASM
%define CHECK_AND_COMPARE_N_YWORDS_NASM

%include "macro/bitmask_jcc.nasm"

; Parameters
; %1: vmovdqa(a|u).
; %2: the address of the 1st string to compare. (assumed to be a valid address)
; %3: the address of the 2nd string to compare. (assumed to be a valid address)
; %4: the number of ywords to compare. (1|2|4)
; %5: jn?e
; %6: the address to jump if the bitmask check fails.
;
; Optional parameters
; %7: the offset to apply.
%macro CHECK_AND_COMPARE_N_YWORDS 6-7
%define        LOAD %1
%define          S0 %2
%define          S1 %3
%define YWORD_COUNT %4
%define         JCC %5
%define      TARGET %6
%if %0 > 6
%define OFFSET %7
%else
%define OFFSET 0
%endif
;                                                                               ┌──NULL_YWORD
;                                                 ┌──not──NULL_MASK_00_1F──cmpeqb
;                                ┌──MASK_00_1F──and                             ├──YMM_00_1F──[S0_00_1F]
;                                │                └───────DIFF_MASK_00_1F──cmpeqb
;                                │                                              └─────────────[S1_00_1F]
;               ┌──MASK_00_3F──and
;               │                │                                              ┌──NULL_YWORD
;               │                │                ┌──not──NULL_MASK_20_3F──cmpeqb
;               │                └──MASK_20_3F──and                             ├──YMM_20_3F──[S0_20_3F]
;               │                                 └───────DIFF_MASK_20_3F──cmpeqb
;               │                                                               └─────────────[S1_20_3F]
; MASK_00_7F──and
;               │                                                               ┌──NULL_YWORD
;               │                                 ┌──not──NULL_MASK_40_5F──cmpeqb
;               │                ┌──MASK_40_5F──and                             ├──YMM_40_5F──[S0_40_5F]
;               │                │                └───────DIFF_MASK_40_5F──cmpeqb
;               │                │                                              └─────────────[S1_40_5F]
;               └──MASK_40_7F──and
;                                │                                              ┌──NULL_YWORD
;                                │                ┌──not──NULL_MASK_60_7F──cmpeqb
;                                └──MASK_60_7F──and                             ├──YMM_60_7F──[S0_60_7F]
;                                                 └───────DIFF_MASK_60_7F──cmpeqb
;                                                                               └─────────────[S1_60_7F]
	LOAD YMM_00_1F, [ S0 + OFFSET + 0x00 ]
%if YWORD_COUNT > 1
	LOAD YMM_20_3F, [ S0 + OFFSET + 0x20 ]
%if YWORD_COUNT > 2
	LOAD YMM_40_5F, [ S0 + OFFSET + 0x40 ]
	LOAD YMM_60_7F, [ S0 + OFFSET + 0x60 ]
%endif
%endif
	vpcmpeqb NULL_MASK_00_1F, YMM_00_1F, NULL_YWORD
%if YWORD_COUNT > 1
	vpcmpeqb NULL_MASK_20_3F, YMM_20_3F, NULL_YWORD
%if YWORD_COUNT > 2
	vpcmpeqb NULL_MASK_40_5F, YMM_40_5F, NULL_YWORD
	vpcmpeqb NULL_MASK_60_7F, YMM_60_7F, NULL_YWORD
%endif
%endif
	vpcmpeqb DIFF_MASK_00_1F, YMM_00_1F, [ S1 + OFFSET + 0x00 ]
%if YWORD_COUNT > 1
	vpcmpeqb DIFF_MASK_20_3F, YMM_20_3F, [ S1 + OFFSET + 0x20 ]
%if YWORD_COUNT > 2
	vpcmpeqb DIFF_MASK_40_5F, YMM_40_5F, [ S1 + OFFSET + 0x40 ]
	vpcmpeqb DIFF_MASK_60_7F, YMM_60_7F, [ S1 + OFFSET + 0x60 ]
%endif
%endif
	vpandn MASK_00_1F, NULL_MASK_00_1F, DIFF_MASK_00_1F
%if YWORD_COUNT > 1
	vpandn MASK_20_3F, NULL_MASK_20_3F, DIFF_MASK_20_3F
%if YWORD_COUNT > 2
	vpandn MASK_40_5F, NULL_MASK_40_5F, DIFF_MASK_40_5F
	vpandn MASK_60_7F, NULL_MASK_60_7F, DIFF_MASK_60_7F
%endif
	vpand MASK_00_3F, MASK_00_1F, MASK_20_3F
%if YWORD_COUNT > 2
	vpand MASK_40_7F, MASK_40_5F, MASK_60_7F
	vpand MASK_00_7F, MASK_00_3F, MASK_40_7F
%endif
%endif
; check if there is a (mismatching|null) byte
%if YWORD_COUNT == 1
	BITMASK_JCC JCC, TARGET, MASK_00_1F, ecx
%elif YWORD_COUNT == 2
	BITMASK_JCC JCC, TARGET, MASK_00_3F, edx
%elif YWORD_COUNT == 4
	BITMASK_JCC JCC, TARGET, MASK_00_7F, ecx
%else
%error "Unsupported YWORD_COUNT: %d" YWORD_COUNT
%endif
%endmacro

%endif
