%ifndef RETURN_DIFF_NASM
%define RETURN_DIFF_NASM

%include "macro/vzeroupper_ret.nasm"

; Parameters
; %1: the 32-bit general purpose register in which the comparison bitmask is.
; %2: how far the yword that contains the first mismatching byte is from S0 and S1.
%macro RETURN_DIFF 2
%define DMASK %1
%define   OFS %2
; calculate the index of the first mismatching byte
	bsf ecx, DMASK
; load the first mismatching byte from both S0 and S1
	movzx eax, byte [ rdi + OFS + rcx ]
	movzx ecx, byte [ rsi + OFS + rcx ]
; return the difference between the two bytes
	sub eax, ecx
	VZEROUPPER_RET
%endmacro

%endif
