%ifndef COMPARE_1_YWORD_NASM
%define COMPARE_1_YWORD_NASM

; Parameters
; %1: vmovdqa(a|u).
; %2: the address of the 1st string to compare. (assumed to be a valid address)
; %3: the address of the 2nd string to compare. (assumed to be a valid address)
;
; Optional parameters
; %4: the offset to apply.
%macro COMPARE_1_YWORD 3-4
%define LOAD %1
%define   S0 %2
%define   S1 %3
%if %0 > 3
%define OFS %4
%else
%define OFS 0
%endif
;                                             ┌──NULL_YMM
;               ┌──not──NULL_MASK_00_1F──cmpeqb
; MASK_00_1F──and                             ├──YMM_00_1F──[S0_00_1F]
;               └───────DIFF_MASK_00_1F──cmpeqb
;                                             └─────────────[S1_00_1F]
	LOAD YMM_00_1F, [ S0 + OFS + 0x00 ]
	vpcmpeqb DIFF_MASK_00_1F, YMM_00_1F, [ S1 + OFS + 0x00 ]
	vpcmpeqb NULL_MASK_00_1F, YMM_00_1F, NULL_YMM
	vpandn MASK_00_1F, NULL_MASK_00_1F, DIFF_MASK_00_1F
%endmacro

%endif
