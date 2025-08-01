%ifndef JCC_NULL_BYTE_IN_MASK_00_1F_NASM
%define JCC_NULL_BYTE_IN_MASK_00_1F_NASM

%include "define/registers.nasm"

; Parameters
; %1: (None|Some) (case insensitive)
; %2: the target to jump to if MASK_00_1F contains (a|no) null byte.
%macro JCC_NULL_BYTE_IN_MASK_00_1F 2
%ifidni %1, None
%define JCC jz
%else
%ifidni %1, Some
%define JCC jnz
%else
%error "Accepted values for %1: (None|Some)"
%endif
%endif
%define TARGET %2
	vpmovmskb ecx, MASK_00_1F
	inc ecx
	JCC TARGET
%endmacro

%endif
