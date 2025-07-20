%ifndef JCC_YMM_MASK_HAS_NULL_BYTE_NASM
%define JCC_YMM_MASK_HAS_NULL_BYTE_NASM

; Parameters
; %1: jz (jump if has no null byte) | jnz (jump if has a null byte)
; %2: the address to jump to if the bitmask check fails.
; %3: the YMM register from which to extract the bitmask.
; %4: the GPR in which to extract the bitmask.
%macro JCC_YMM_MASK_HAS_NULL_BYTE 4
%define      JCC %1
%define   TARGET %2
%define YMM_MASK %3
%define GPR_MASK %4
	vpmovmskb GPR_MASK, YMM_MASK
	inc GPR_MASK
	JCC TARGET
%endmacro

%endif
