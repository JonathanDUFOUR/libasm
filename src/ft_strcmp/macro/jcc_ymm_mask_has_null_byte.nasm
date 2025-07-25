%ifndef JCC_YMM_MASK_HAS_NULL_BYTE_NASM
%define JCC_YMM_MASK_HAS_NULL_BYTE_NASM

%include "define/registers.nasm"

; Parameters
; %1: jz (jump if has no null byte) | jnz (jump if has a null byte)
; %2: the address to jump to if the bitmask check fails.
%macro JCC_YMM_MASK_HAS_NULL_BYTE 2
%define      JCC %1
%define   TARGET %2
	vpmovmskb ecx, MASK_00_1F
	inc ecx
	JCC TARGET
%endmacro

%endif
