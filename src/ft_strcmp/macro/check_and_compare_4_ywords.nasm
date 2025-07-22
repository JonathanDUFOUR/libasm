%ifndef CHECK_AND_COMPARE_4_YWORDS_NASM
%define CHECK_AND_COMPARE_4_YWORDS_NASM

%include "macro/jcc_ymm_mask_has_null_byte.nasm"
%include "macro/jcc_ymm_has_null_byte.nasm"

; Parameters
; %1: the address of the 1st string to compare. (assumed to be a valid address)
; %2: the address of the 2nd string to compare. (assumed to be a valid address)
;
; Optional parameters
; %3: the offset to apply.
%macro CHECK_AND_COMPARE_4_YWORDS 2-3
%define S0 %1
%define S1 %2
%if %0 > 2
%define OFFSET %3
%else
%define OFFSET 0
%endif
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;                                                                               ┌──NULL_YWORD
; ;                                                 ┌──not──NULL_MASK_00_1F──cmpeqb
; ;                                ┌──MASK_00_1F──and                             ├──YMM_00_1F──[S0_00_1F]
; ;                                │                └───────DIFF_MASK_00_1F──cmpeqb
; ;                                │                                              └─────────────[S1_00_1F]
; ;               ┌──MASK_00_3F──and
; ;               │                │                                              ┌──NULL_YWORD
; ;               │                │                ┌──not──NULL_MASK_20_3F──cmpeqb
; ;               │                └──MASK_20_3F──and                             ├──YMM_20_3F──[S0_20_3F]
; ;               │                                 └───────DIFF_MASK_20_3F──cmpeqb
; ;               │                                                               └─────────────[S1_20_3F]
; ; MASK_00_7F──and
; ;               │                                                               ┌──NULL_YWORD
; ;               │                                 ┌──not──NULL_MASK_40_5F──cmpeqb
; ;               │                ┌──MASK_40_5F──and                             ├──YMM_40_5F──[S0_40_5F]
; ;               │                │                └───────DIFF_MASK_40_5F──cmpeqb
; ;               │                │                                              └─────────────[S1_40_5F]
; ;               └──MASK_40_7F──and
; ;                                │                                              ┌──NULL_YWORD
; ;                                │                ┌──not──NULL_MASK_60_7F──cmpeqb
; ;                                └──MASK_60_7F──and                             ├──YMM_60_7F──[S0_60_7F]
; ;                                                 └───────DIFF_MASK_60_7F──cmpeqb
; ;                                                                               └─────────────[S1_60_7F]
; 	vmovdqa YMM_00_1F, [ S0 + OFFSET + 0x00 ]
; 	vmovdqa YMM_20_3F, [ S0 + OFFSET + 0x20 ]
; 	vmovdqa YMM_40_5F, [ S0 + OFFSET + 0x40 ]
; 	vmovdqa YMM_60_7F, [ S0 + OFFSET + 0x60 ]
; 	vpcmpeqb DIFF_MASK_00_1F, YMM_00_1F, [ S1 + OFFSET + 0x00 ]
; 	vpcmpeqb DIFF_MASK_20_3F, YMM_20_3F, [ S1 + OFFSET + 0x20 ]
; 	vpcmpeqb DIFF_MASK_40_5F, YMM_40_5F, [ S1 + OFFSET + 0x40 ]
; 	vpcmpeqb DIFF_MASK_60_7F, YMM_60_7F, [ S1 + OFFSET + 0x60 ]
; 	vpcmpeqb NULL_MASK_00_1F, YMM_00_1F, NULL_YWORD
; 	vpcmpeqb NULL_MASK_20_3F, YMM_20_3F, NULL_YWORD
; 	vpcmpeqb NULL_MASK_40_5F, YMM_40_5F, NULL_YWORD
; 	vpcmpeqb NULL_MASK_60_7F, YMM_60_7F, NULL_YWORD
; 	vpandn MASK_00_1F, NULL_MASK_00_1F, DIFF_MASK_00_1F
; 	vpandn MASK_20_3F, NULL_MASK_20_3F, DIFF_MASK_20_3F
; 	vpandn MASK_40_5F, NULL_MASK_40_5F, DIFF_MASK_40_5F
; 	vpandn MASK_60_7F, NULL_MASK_60_7F, DIFF_MASK_60_7F
; 	vpand MASK_00_3F, MASK_00_1F, MASK_20_3F
; 	vpand MASK_40_7F, MASK_40_5F, MASK_60_7F
; 	vpand MASK_00_7F, MASK_00_3F, MASK_40_7F
; ; check if there is a (mismatching|null) byte
; 	JCC_YMM_MASK_HAS_NULL_BYTE jnz, mismatch_or_null.in_00_7F, MASK_00_7F, ecx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
	vmovdqa YMM_00_1F, [ S0 + OFFSET + 0x00 ]
	vmovdqa YMM_20_3F, [ S0 + OFFSET + 0x20 ]
	vmovdqa YMM_40_5F, [ S0 + OFFSET + 0x40 ]
	vmovdqa YMM_60_7F, [ S0 + OFFSET + 0x60 ]
	vpcmpeqb DIFF_MASK_00_1F, YMM_00_1F, [ S1 + OFFSET + 0x00 ]
	vpcmpeqb DIFF_MASK_20_3F, YMM_20_3F, [ S1 + OFFSET + 0x20 ]
	vpcmpeqb DIFF_MASK_40_5F, YMM_40_5F, [ S1 + OFFSET + 0x40 ]
	vpcmpeqb DIFF_MASK_60_7F, YMM_60_7F, [ S1 + OFFSET + 0x60 ]
	vpand MASK_00_1F, YMM_00_1F, DIFF_MASK_00_1F
	vpand MASK_20_3F, YMM_20_3F, DIFF_MASK_20_3F
	vpand MASK_40_5F, YMM_40_5F, DIFF_MASK_40_5F
	vpand MASK_60_7F, YMM_60_7F, DIFF_MASK_60_7F
	vpminub MASK_00_3F, MASK_00_1F, MASK_20_3F
	vpminub MASK_40_7F, MASK_40_5F, MASK_60_7F
	vpminub MASK_00_7F, MASK_00_3F, MASK_40_7F
; check if there is a (mismatching|null) byte
	JCC_YMM_HAS_NULL_BYTE jnz, mismatch_or_null.in_00_7F, MASK_00_7F, ecx
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%endmacro

%endif
