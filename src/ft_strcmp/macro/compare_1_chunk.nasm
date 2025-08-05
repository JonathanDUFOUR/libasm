%ifndef COMPARE_1_CHUNK_NASM
%define COMPARE_1_CHUNK_NASM

%include "define/registers.nasm"

; Parameters
; %1: vmov(d|q).
; %2: the dmask to apply to ecx before incrementing it to check for a (mismatching|null) byte.
;
; Optionnal parameters
; %3: the offset to apply.
%macro COMPARE_1_CHUNK 2-3
%define  LOAD %1
%define DMASK %2
%if %0 > 2
%define OFS %3
%else
%define OFS 0
%endif
;                            ┌──NULL_XMM
;         ┌──NOT──xmm1──CMPEQB
; xmm1──AND                  ├──xmm1──[S0+OFS]
;         └───────xmm2──CMPEQB
;                            └──xmm2──[S1+OFS]
	LOAD xmm1, [ rdi + OFS ]
	LOAD xmm2, [ rsi + OFS ]
	vpcmpeqb xmm2, xmm1, xmm2
	vpcmpeqb xmm1, xmm1, NULL_XMM
	vpandn xmm1, xmm1, xmm2
; check if there is a (mismatching|null) byte
	vpmovmskb ecx, xmm1
	or ecx, DMASK
	inc ecx
	jnz mismatch_or_null_at_edx
%endmacro

%endif
