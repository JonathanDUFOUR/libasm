%ifndef CHECK_AND_COMPARE_2_YWORDS_NASM
%define CHECK_AND_COMPARE_2_YWORDS_NASM

%include "macro/jump_if_ymm_has_null_byte.nasm"

; Parameters
; %1: the address of the 1st string to compare. (assumed to be a valid address)
; %2: the address of the 2nd string to compare. (assumed to be a valid address)
;
; Optional parameters
; %3: the offset to apply.
%macro CHECK_AND_COMPARE_2_YWORDS 2-3
%define S0 %1
%define S1 %2
%if %0 > 2
%define OFFSET %3
%else
%define OFFSET 0
%endif
;                                  ┌────────────────────────┬──YMM_00_1F──[S0_00_1F]
;                 ┌──MASK_00_1F──and                        │
;                 │                └──DIFF_MASK_00_1F──cmpeqb─────────────[S1_00_1F]
; MASK_00_3F──minub
;                 │                ┌────────────────────────┬──YMM_20_3F──[S0_20_3F]
;                 └──MASK_20_3F──and                        │
;                                  └──DIFF_MASK_20_3F──cmpeqb─────────────[S1_20_3F]
	vmovdqa YMM_00_1F, [ S0 + OFFSET + 0x00 ]
	vmovdqa YMM_20_3F, [ S0 + OFFSET + 0x20 ]
	vpcmpeqb DIFF_MASK_00_1F, YMM_00_1F, [ S1 + OFFSET + 0x00 ]
	vpcmpeqb DIFF_MASK_20_3F, YMM_20_3F, [ S1 + OFFSET + 0x20 ]
	vpand MASK_00_1F, YMM_00_1F, DIFF_MASK_00_1F
	vpand MASK_20_3F, YMM_20_3F, DIFF_MASK_20_3F
	vpminub MASK_00_3F, MASK_00_1F, MASK_20_3F
; check if there is a (mismatching|null) byte
	JUMP_IF_YMM_HAS_NULL_BYTE mismatch_or_null.in_00_3F, MASK_00_3F, edx
%endmacro

%endif
