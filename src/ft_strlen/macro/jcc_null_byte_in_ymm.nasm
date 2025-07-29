%ifndef JCC_NULL_BYTE_IN_YMM_NASM
%define JCC_NULL_BYTE_IN_YMM_NASM

%include "define/registers.nasm"

; Parameters
; %1: jz (contains no null byte) | jnz (contains a null byte)
; %2: the target to jump to if the YMM contains (a|no) null byte.
; %3: the YMM to check.
; %4: the GPR in which to extract the bitmask.
%macro JCC_NULL_BYTE_IN_YMM 4
%define    JCC %1
%define TARGET %2
%define    YMM %3
%define    GPR %4
	vpcmpeqb YMM, YMM, NULL_YMM
	vpmovmskb GPR, YMM
	test GPR, GPR
	JCC TARGET
%endmacro

%endif
