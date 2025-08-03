%ifndef COMPARE_1_OWORD_NASM
%define COMPARE_1_OWORD_NASM

%macro COMPARE_1_OWORD 0
; load the next oword from S0
	vmovdqu xmm0, [ rdi ]
; compare it with the next oword of S1
	vpcmpeqb xmm1, xmm0, [ rsi ]
; check if there is a mismatch
	vpmovmskb ecx, xmm1
	inc cx
	jnz mismatch.in_00_1F
%endmacro

%endif
