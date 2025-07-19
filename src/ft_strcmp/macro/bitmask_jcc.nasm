%ifndef BITMASK_JCC_NASM
%define BITMASK_JCC_NASM

; Parameters
; %1: jn?e
; %2: the address to jump to if the bitmask check fails.
; %3: the YMM register from which to extract the bitmask.
; %4: the GPR in which to extract the bitmask.
%macro BITMASK_JCC 4
%define      JCC %1
%define   TARGET %2
%define YMM_MASK %3
%define GPR_MASK %4
	vpmovmskb GPR_MASK, YMM_MASK
	inc GPR_MASK
	JCC TARGET
%endmacro

%endif
