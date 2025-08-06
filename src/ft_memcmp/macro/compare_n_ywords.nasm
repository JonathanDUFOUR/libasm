%ifndef COMPARE_N_YWORDS_NASM
%define COMPARE_N_YWORDS_NASM

%include "define/registers.nasm"

; Parameters
; %1: the number of ywords to compare. (1|2|4)
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
;                                                    ┌──YMM_00_1F──[S0_00_1F]
;                                ┌──MASK_00_1F──cmpeqb
;                                │                   └─────────────[S1_00_1F]
;               ┌──MASK_00_3F──and
;               │                │                   ┌──YMM_20_3F──[S0_20_3F]
;               │                └──MASK_20_3F──cmpeqb
;               │                                    └─────────────[S1_20_3F]
; MASK_00_7F──and
;               │                                    ┌──YMM_40_5F──[S0_40_5F]
;               │                ┌──MASK_40_5F──cmpeqb
;               │                │                   └─────────────[S1_40_5F]
;               └──MASK_40_7F──and
;                                │                   ┌──YMM_60_7F──[S0_60_7F]
;                                └──MASK_60_7F──cmpeqb
;                                                    └─────────────[S1_60_7F]
%if N = 1
	LOAD YMM_00_1F, [ S0 + OFS + 0x00 ]
	vpcmpeqb MASK_00_1F, YMM_00_1F, [ S1 + OFS + 0x00 ]
%elif N = 2
	LOAD YMM_00_1F, [ S0 + OFS + 0x00 ]
	LOAD YMM_20_3F, [ S0 + OFS + 0x20 ]
	vpcmpeqb MASK_00_1F, YMM_00_1F, [ S1 + OFS + 0x00 ]
	vpcmpeqb MASK_20_3F, YMM_20_3F, [ S1 + OFS + 0x20 ]
	vpand MASK_00_3F, MASK_00_1F, MASK_20_3F
%elif N = 4
	LOAD YMM_00_1F, [ S0 + OFS + 0x00 ]
	LOAD YMM_20_3F, [ S0 + OFS + 0x20 ]
	LOAD YMM_40_5F, [ S0 + OFS + 0x40 ]
	LOAD YMM_60_7F, [ S0 + OFS + 0x60 ]
	vpcmpeqb MASK_00_1F, YMM_00_1F, [ S1 + OFS + 0x00 ]
	vpcmpeqb MASK_20_3F, YMM_20_3F, [ S1 + OFS + 0x20 ]
	vpcmpeqb MASK_40_5F, YMM_40_5F, [ S1 + OFS + 0x40 ]
	vpcmpeqb MASK_60_7F, YMM_60_7F, [ S1 + OFS + 0x60 ]
	vpand MASK_00_3F, MASK_00_1F, MASK_20_3F
	vpand MASK_40_7F, MASK_40_5F, MASK_60_7F
	vpand MASK_00_7F, MASK_00_3F, MASK_40_7F
%else
%error "N must be 1, 2, or 4"
%endif
%endmacro

%endif
