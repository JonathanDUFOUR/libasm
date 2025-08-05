%ifndef COMPARE_4_YWORDS_NASM
%define COMPARE_4_YWORDS_NASM

; Parameters
; %1: the address of the 1st string to compare. (assumed to be a valid address)
; %2: the address of the 2nd string to compare. (assumed to be a valid address)
;
; Optional parameters
; %3: the offset to apply.
%macro COMPARE_4_YWORDS 2-3
%define S0 %1
%define S1 %2
%if %0 > 2
%define OFS %3
%else
%define OFS 0
%endif
;                                                     ┌────────────────────────┬──YMM_00_1F──[S0_00_1F]
;                                    ┌──MASK_00_1F──and                        │
;                                    │                └──DIFF_MASK_00_1F──cmpeqb─────────────[S1_00_1F]
;                 ┌──MASK_00_3F──minub
;                 │                  │                ┌────────────────────────┬──YMM_20_3F──[S0_20_3F]
;                 │                  └──MASK_20_3F──and                        │
;                 │                                   └──DIFF_MASK_20_3F──cmpeqb─────────────[S1_20_3F]
; MASK_00_7F──minub
;                 │                                   ┌────────────────────────┬──YMM_40_5F──[S0_40_5F]
;                 │                  ┌──MASK_40_5F──and                        │
;                 │                  │                └──DIFF_MASK_40_5F──cmpeqb─────────────[S1_40_5F]
;                 └──MASK_40_7F──minub
;                                    │                ┌────────────────────────┬──YMM_60_7F──[S0_60_7F]
;                                    └──MASK_60_7F──and                        │
;                                                     └──DIFF_MASK_60_7F──cmpeqb─────────────[S1_60_7F]
	vmovdqa YMM_00_1F, [ S0 + OFS + 0x00 ]
	vmovdqa YMM_20_3F, [ S0 + OFS + 0x20 ]
	vmovdqa YMM_40_5F, [ S0 + OFS + 0x40 ]
	vmovdqa YMM_60_7F, [ S0 + OFS + 0x60 ]
	vpcmpeqb DIFF_MASK_00_1F, YMM_00_1F, [ S1 + OFS + 0x00 ]
	vpcmpeqb DIFF_MASK_20_3F, YMM_20_3F, [ S1 + OFS + 0x20 ]
	vpcmpeqb DIFF_MASK_40_5F, YMM_40_5F, [ S1 + OFS + 0x40 ]
	vpcmpeqb DIFF_MASK_60_7F, YMM_60_7F, [ S1 + OFS + 0x60 ]
	vpand MASK_00_1F, YMM_00_1F, DIFF_MASK_00_1F
	vpand MASK_20_3F, YMM_20_3F, DIFF_MASK_20_3F
	vpand MASK_40_5F, YMM_40_5F, DIFF_MASK_40_5F
	vpand MASK_60_7F, YMM_60_7F, DIFF_MASK_60_7F
	vpminub MASK_00_3F, MASK_00_1F, MASK_20_3F
	vpminub MASK_40_7F, MASK_40_5F, MASK_60_7F
	vpminub MASK_00_7F, MASK_00_3F, MASK_40_7F
%endmacro

%endif
