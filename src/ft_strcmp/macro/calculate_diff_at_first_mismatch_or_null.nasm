%ifndef CALCULATE_DIFF_AT_FIRST_MISMATCH_OR_NULL_NASM
%define CALCULATE_DIFF_AT_FIRST_MISMATCH_OR_NULL_NASM

; Parameters
; %1: the dmask from which to calculate the index of the first (mismatching|null) byte is.
; %2: the offset to apply (r32|imm32)
%macro CALCULATE_DIFF_AT_FIRST_MISMATCH_OR_NULL 2
%define DMASK %1
%define   OFS %2
; calculate the index of the first (mismatching|null) byte
	bsf ecx, DMASK
%if OFS != 0
	add ecx, OFS
%endif
; load the first (mismatching|null) byte from both S0 and S1
	movzx eax, byte [ rdi + rcx ]
	movzx ecx, byte [ rsi + rcx ]
; calculate the possible difference between them
	sub eax, ecx
%endmacro

%endif
