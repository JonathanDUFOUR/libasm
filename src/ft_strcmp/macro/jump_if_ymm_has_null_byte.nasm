%ifndef JUMP_IF_YMM_HAS_NULL_BYTE_NASM
%define JUMP_IF_YMM_HAS_NULL_BYTE_NASM

%include "define/registers.nasm"

; Parameters
; %1: the address to jump to if the YMM register contains a null byte.
; %2: the YMM register to check.
; %3: the GPR in which to extract the bitmask.
%macro JUMP_IF_YMM_HAS_NULL_BYTE 3
%define TARGET %1
%define    YMM %2
%define    GPR %3
	vpcmpeqb YMM, YMM, NULL_YWORD
	vpmovmskb GPR, YMM
	test GPR, GPR
	jnz TARGET
%endmacro

%endif
