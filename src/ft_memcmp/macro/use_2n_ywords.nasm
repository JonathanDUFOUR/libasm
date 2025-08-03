%ifndef USE_2N_YWORDS_NASM
%define USE_2N_YWORDS_NASM

%include "macro/compare_n_ywords.nasm"
%include "macro/vzeroupper_ret.nasm"

; Parameters
; %1: the number of ywords to compare 2 times. (1|2|4|8)
%macro USE_2N_YWORDS 1
%define YWORD_COUNT %1
%if   YWORD_COUNT == 8
%define MISMATCH_TARGET mismatch.in_00_FF
%elif YWORD_COUNT == 4
%define MISMATCH_TARGET mismatch.in_00_7F
%elif YWORD_COUNT == 2
%define MISMATCH_TARGET mismatch.in_00_3F
%elif YWORD_COUNT == 1
%define MISMATCH_TARGET mismatch.in_00_1F
%endif
; compare the first YWORD_COUNT ywords of S0 and S1
	COMPARE_N_YWORDS vmovdqu, rdi, rsi, YWORD_COUNT, MISMATCH_TARGET
; advance both S0 and S1 to their last YWORD_COUNT yword(s)
	lea rdi, [ rdi + rdx - YWORD_SIZE * YWORD_COUNT ]
	lea rsi, [ rsi + rdx - YWORD_SIZE * YWORD_COUNT ]
; compare the last YWORD_COUNT ywords of S0 and S1
	COMPARE_N_YWORDS vmovdqu, rdi, rsi, YWORD_COUNT, MISMATCH_TARGET
%if YWORD_COUNT == 1 || YWORD_COUNT == 4
	xor eax, eax
%endif
	VZEROUPPER_RET
%endmacro

%endif
