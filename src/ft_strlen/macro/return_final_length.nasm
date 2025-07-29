%ifndef RETURN_FINAL_LENGTH_NASM
%define RETURN_FINAL_LENGTH_NASM

%include "macro/vzeroupper_ret.nasm"

; Parameters
; %1: the mask register from which to calculate the index of the first null byte.
; %2: the offset to apply to the pointer before calculating the final length.
%macro RETURN_FINAL_LENGTH 2
%define GPR_MASK %1
%define   OFFSET %2
; calculate the index of the 1st null byte in the given YMM register
	bsf ecx, GPR_MASK
; update the pointer to its final position
%if OFFSET != 0
	add rax, OFFSET
%endif
	add rax, rcx
; calculate the length
	sub rax, rdi
	VZEROUPPER_RET
%endmacro

%endif
