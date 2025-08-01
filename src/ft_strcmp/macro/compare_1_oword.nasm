%ifndef COMPARE_1_OWORD_NASM
%define COMPARE_1_OWORD_NASM

%include "define/registers.nasm"

; Parameters
; %1: vmovdq(a|u).
;
; Optionnal parameters
; %2: the offset to apply.
%macro COMPARE_1_OWORD 1-2
%define LOAD %1
%if %0 > 1
%define OFFSET %2
%else
%define OFFSET 0
%endif
;                            ┌──NULL_XMM
;         ┌──NOT──xmm1──CMPEQB
; xmm1──AND                  ├──xmm1──[S0+OFFSET]
;         └───────xmm2──CMPEQB
;                            └────────[S1+OFFSET]
	LOAD xmm1, [ rdi + OFFSET ]
	vpcmpeqb xmm2, xmm1, [ rsi + OFFSET ]
	vpcmpeqb xmm1, xmm1, NULL_XMM
	vpandn xmm1, xmm1, xmm2
; check if there is a (mismatching|null) byte
	vpmovmskb ecx, xmm1
	inc cx
	jnz mismatch_or_null_at_edx
%endmacro

%endif
