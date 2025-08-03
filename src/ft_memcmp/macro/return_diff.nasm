%ifndef RETURN_DIFF_NASM
%define RETURN_DIFF_NASM

; Parameters
; %1: how far the yword that contains the first mismatching byte is from S0 and S1.
; %2: the register in which the comparison bitmask is.
%macro RETURN_DIFF 2
%define  OFFSET %1
%define BITMASK %2
; calculate the index of the first mismatching byte
	bsf ecx, BITMASK
; load the first mismatching byte from both S0 and S1
	movzx eax, byte [ rdi + OFFSET + rcx ]
	movzx ecx, byte [ rsi + OFFSET + rcx ]
; return the difference between the two bytes
	sub eax, ecx
; clear the upper bits of the YMM registers to avoid performance penalties
	vzeroupper
	ret
%endmacro

%endif
