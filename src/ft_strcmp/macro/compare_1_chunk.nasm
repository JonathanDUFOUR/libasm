%ifndef COMPARE_1_CHUNK_NASM
%define COMPARE_1_CHUNK_NASM

%include "define/registers.nasm"

; Parameters
; %1: vmov(d|q).
; %2: the mask to apply to ecx before incrementing it to check for a (mismatching|null) byte.
;     (assumed to be either DWORD_MASK or QWORD_MASK)
;
; Optionnal parameters
; %3: the offset to apply.
%macro COMPARE_1_CHUNK 2-3
%define LOAD %1
%define MASK %2
%if %0 > 2
%define OFFSET %3
%else
%define OFFSET 0
%endif
;                            ┌──NULL_OWORD
;         ┌──NOT──xmm1──CMPEQB
; xmm1──AND                  ├──xmm1──[S0+OFFSET]
;         └───────xmm2──CMPEQB
;                            └──xmm2──[S1+OFFSET]
	LOAD xmm1, [ rdi + OFFSET ]
	LOAD xmm2, [ rsi + OFFSET ]
	vpcmpeqb xmm2, xmm1, xmm2
	vpcmpeqb xmm1, xmm1, NULL_OWORD
	vpandn xmm1, xmm1, xmm2
; check if there is a (mismatching|null) byte
	vpmovmskb ecx, xmm1
	or ecx, MASK
	inc ecx
	jnz mismatch_or_null_at_edx
%endmacro

%endif
