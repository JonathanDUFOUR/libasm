%ifndef JCC_NULL_BYTE_IN_YMM_NASM
%define JCC_NULL_BYTE_IN_YMM_NASM

%include "define/registers.nasm"

; Parameters
; %1: (None|Some) (case insensitive)
; %2: the target to jump to if the YMM contains (a|no) null byte.
; %3: the YMM to check.
; %4: the GPR in which to extract the bitmask.
%macro JCC_NULL_BYTE_IN_YMM 4
%ifidni %1, None
%define JCC jz
%elifidni %1, Some
%define JCC jnz
%else
%error "Accepted values for %1: (None|Some)"
%endif
%define TARGET %2
%define    YMM %3
%define    GPR %4
	vpcmpeqb YMM, YMM, NULL_YMM
	vpmovmskb GPR, YMM
	test GPR, GPR
	JCC TARGET
%endmacro

%endif
