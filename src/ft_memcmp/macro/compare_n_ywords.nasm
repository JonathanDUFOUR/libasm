%ifndef COMPARE_N_YWORDS_NASM
%define COMPARE_N_YWORDS_NASM

%include "define/registers.nasm"

; Parameters
; %1: the number of ywords to compare. (1|2|4|8)
; %2: the load instruction to use. (vmovdqa|vmovdqu)
; %3: the address of the 1st yword array to compare.
; %4: the address of the 2nd yword array to compare.
;
; Optional parameters
; %5: the offset to apply.
%macro COMPARE_N_YWORDS 4-5
%define    N %1
%define LOAD %2
%define   S0 %3
%define   S1 %4
%if %0 > 4
%define OFS %5
%else
%define OFS 0
%endif
;                                                                     ┌──YMM_00_1F──[S0_00_1F]
;                                                 ┌──MASK_00_1F──cmpeqb
;                                                 │                   └─────────────[S1_00_1F]
;                                ┌──MASK_00_3F──and
;                                │                │                   ┌──YMM_20_3F──[S0_20_3F]
;                                │                └──MASK_20_3F──cmpeqb
;                                │                                    └─────────────[S1_20_3F]
;               ┌──MASK_00_7F──and
;               │                │                                    ┌──YMM_40_5F──[S0_40_5F]
;               │                │                ┌──MASK_40_5F──cmpeqb
;               │                │                │                   └─────────────[S1_40_5F]
;               │                └──MASK_40_7F──and
;               │                                 │                   ┌──YMM_60_7F──[S0_60_7F]
;               │                                 └──MASK_60_7F──cmpeqb
;               │                                                     └─────────────[S1_60_7F]
; MASK_00_FF──and
;               │                                                     ┌──YMM_80_9F──[S0_80_9F]
;               │                                 ┌──MASK_80_9F──cmpeqb
;               │                                 │                   └─────────────[S1_80_9F]
;               │                ┌──MASK_80_BF──and
;               │                │                │                   ┌──YMM_A0_BF──[S0_A0_BF]
;               │                │                └──MASK_A0_BF──cmpeqb   
;               │                │                                    └─────────────[S1_A0_BF]
;               └──MASK_80_FF──and
;                                │                                    ┌──YMM_C0_DF──[S0_C0_DF]
;                                │                ┌──MASK_C0_DF──cmpeqb
;                                │                │                   └─────────────[S1_C0_DF]
;                                └──MASK_C0_FF──and
;                                                 │                   ┌──YMM_E0_FF──[S0_E0_FF]
;                                                 └──MASK_E0_FF──cmpeqb
;                                                                     └─────────────[S1_E0_FF]
%if N <> 1 && N <> 2 && N <> 4 && N <> 8
%error "N must be 1, 2, 4 or 8"
%endif
	LOAD YMM_00_1F, [ S0 + OFS + 0x00 ]
%if N > 1
	LOAD YMM_20_3F, [ S0 + OFS + 0x20 ]
%if N > 2
	LOAD YMM_40_5F, [ S0 + OFS + 0x40 ]
	LOAD YMM_60_7F, [ S0 + OFS + 0x60 ]
%if N > 4
	LOAD YMM_80_9F, [ S0 + OFS + 0x80 ]
	LOAD YMM_A0_BF, [ S0 + OFS + 0xA0 ]
	LOAD YMM_C0_DF, [ S0 + OFS + 0xC0 ]
	LOAD YMM_E0_FF, [ S0 + OFS + 0xE0 ]
%endif
%endif
%endif
	vpcmpeqb MASK_00_1F, YMM_00_1F, [ S1 + OFS + 0x00 ]
%if N > 1
	vpcmpeqb MASK_20_3F, YMM_20_3F, [ S1 + OFS + 0x20 ]
%if N > 2
	vpcmpeqb MASK_40_5F, YMM_40_5F, [ S1 + OFS + 0x40 ]
	vpcmpeqb MASK_60_7F, YMM_60_7F, [ S1 + OFS + 0x60 ]
%if N > 4
	vpcmpeqb MASK_80_9F, YMM_80_9F, [ S1 + OFS + 0x80 ]
	vpcmpeqb MASK_A0_BF, YMM_A0_BF, [ S1 + OFS + 0xA0 ]
	vpcmpeqb MASK_C0_DF, YMM_C0_DF, [ S1 + OFS + 0xC0 ]
	vpcmpeqb MASK_E0_FF, YMM_E0_FF, [ S1 + OFS + 0xE0 ]
%endif
%endif
	vpand MASK_00_3F, MASK_00_1F, MASK_20_3F
%if N > 2
	vpand MASK_40_7F, MASK_40_5F, MASK_60_7F
%if N > 4
	vpand MASK_80_BF, MASK_80_9F, MASK_A0_BF
	vpand MASK_C0_FF, MASK_C0_DF, MASK_E0_FF
%endif
	vpand MASK_00_7F, MASK_00_3F, MASK_40_7F
%if N > 4
	vpand MASK_80_FF, MASK_80_BF, MASK_C0_FF
	vpand MASK_00_FF, MASK_00_7F, MASK_80_FF
%endif
%endif
%endif
%endmacro

%endif
