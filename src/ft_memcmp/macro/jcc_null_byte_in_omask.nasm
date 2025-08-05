%ifndef JCC_NULL_BYTE_IN_OMASK_NASM
%define JCC_NULL_BYTE_IN_OMASK_NASM

; Parameters
; %1: (None|Some) (case sensitive)
; %2: the target to jump to if the omask contains (a|no) null byte.
; %3: the omask to check.
; %4: the 32-bit general purpose register in which to extract the bitmask.
%macro JCC_NULL_BYTE_IN_OMASK 4
%ifidn %1, None
%define JCC jz
%elifidn %1, Some
%define JCC jnz
%else
%error "Accepted values for %1: (None|Some)"
%endif
%define TARGET %2
%define  OMASK %3
%define  DMASK %4
	vpmovmskb DMASK, OMASK
	sub DMASK, 0xFFFF
	JCC TARGET
%endmacro

%endif
