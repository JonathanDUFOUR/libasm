%ifndef JCC_NULL_BYTE_IN_VECMASK_NASM
%define JCC_NULL_BYTE_IN_VECMASK_NASM

%include "define/registers.nasm"

; Parameters
; %1: (None|Some) (case insensitive)
; %2: the target to jump to if the vecmask contains (a|no) null byte.
; %3: the vecmask to check.
; %4: the general purpose register in which to extract the bitmask.
%macro JCC_NULL_BYTE_IN_VECMASK 4
%ifidni %1, None
%define JCC jz
%elifidni %1, Some
%define JCC jnz
%else
%error "Accepted values for %1: (None|Some)"
%endif
%define  TARGET %2
%define VECMASK %3
%define BITMASK %4
	vpmovmskb BITMASK, VECMASK
	inc BITMASK
	JCC TARGET
%endmacro

%endif
