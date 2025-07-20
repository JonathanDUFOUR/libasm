%ifndef JCC_YMM_HAS_NULL_BYTE_NASM
%define JCC_YMM_HAS_NULL_BYTE_NASM

%include "define/registers.nasm"

; Parameters
; %1: jz (jump if has no null byte) | jnz (jump if has a null byte)
; %2: the address to jump to if the bitmask check fails.
; %3: the YMM register to check.
; %4: the GPR in which to extract the bitmask.
%macro JCC_YMM_HAS_NULL_BYTE 4
%define      JCC %1
%define   TARGET %2
%define      YMM %3
%define GPR_MASK %4
	vpcmpeqb YMM, YMM, NULL_YWORD
	vpmovmskb GPR_MASK, YMM
	test GPR_MASK, GPR_MASK
	JCC TARGET
%endmacro

%endif
