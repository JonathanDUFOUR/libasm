; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2, BMI2, MOVBE

global ft_memcmp: function

%use smartalign
ALIGNMODE p6

%include "define/bits.nasm"
%include "define/registers.nasm"
%include "define/sizes.nasm"
%include "macro/compare_1_oword.nasm"
%include "macro/compare_n_ywords.nasm"
%include "macro/jcc_null_byte_in_omask.nasm"
%include "macro/jcc_null_byte_in_ymask.nasm"
%include "macro/return_diff.nasm"
%include "macro/vzeroupper_ret.nasm"

section .text
; Compares two memory area.
;
; Parameters
; rdi: S0: the address of the 1st memory area to compare. (assumed to be a valid address)
; rsi: S1: the address of the 2nd memory area to compare. (assumed to be a valid address)
; rdx:  N: the number of bytes to compare.
;
; Return
; eax:
; - zero if the first N bytes of S0 match the first N bytes of S1.
; - a negative value if the first mismatching byte among the first N bytes of S0
;   is less than the first one among the first N bytes of S1.
; - a positive value if the first mismatching byte among the N first bytes of S0
;   is greater than the first one among the first N bytes of S1.
align 16, int3
ft_memcmp:
; check if less than 1 yword remains to be compared
	cmp rdx, YWORD_SIZE
	jb less_than_1_yword
; compare the first yword of both S0 and S1
	COMPARE_N_YWORDS 1, vmovdqu, rdi, rsi
	JCC_NULL_BYTE_IN_YMASK Some, mismatch_in_00_1F, MASK_00_1F, eax
; advance both S0 and S1 to their respective second yword
	add rdi, YWORD_SIZE * 1
	add rsi, YWORD_SIZE * 1
; check if 1 yword or less remains to be compared
	sub rdx, YWORD_SIZE * 2
	jbe compare_last_yword
; compare the second yword of both S0 and S1
	COMPARE_N_YWORDS 1, vmovdqu, rdi, rsi
	JCC_NULL_BYTE_IN_YMASK Some, mismatch_in_00_1F, MASK_00_1F, eax
; advance both S0 and S1 to their respective third yword
	add rdi, YWORD_SIZE * 1
	add rsi, YWORD_SIZE * 1
; check if 2 ywords or less remain to be compared
	sub rdx, YWORD_SIZE * 2
	jbe compare_last_2_ywords
; compare the third and fourth ywords of both S0 and S1
	COMPARE_N_YWORDS 2, vmovdqu, rdi, rsi
	JCC_NULL_BYTE_IN_YMASK Some, mismatch_in_00_3F, MASK_00_3F, ecx
; advance both S0 and S1 to their respective fifth yword
	add rdi, YWORD_SIZE * 2
	add rsi, YWORD_SIZE * 2
; check if 4 ywords or less remain to be compared
	sub rdx, YWORD_SIZE * 4
	jbe compare_last_4_ywords
; align S0 to its previous yword boundary + adjust S1 accordingly + update N accordingly
	mov rcx, rdi
	sub rsi, rdi
	and rdi, -YWORD_SIZE
	add rsi, rdi
	sub rcx, rdi
	add rdx, rcx
	jmp compare_next_4_ywords

align CACHE_LINE_SIZE, int3
compare_next_4_ywords:
	COMPARE_N_YWORDS 4, vmovdqa, rdi, rsi
	JCC_NULL_BYTE_IN_YMASK Some, mismatch_in_00_7F, MASK_00_7F, eax
; advance both S0 and S1 + update N
	sub rdi, -YWORD_SIZE * 4
	sub rsi, -YWORD_SIZE * 4
	add rdx, -YWORD_SIZE * 4
; repeat until either there is a mismatch in the next 4 ywords
; or 4 ywords or less remain to be compared
	jbe compare_next_4_ywords
compare_last_4_ywords:
	COMPARE_N_YWORDS 4, vmovdqu, rdi, rsi, rdx
	JCC_NULL_BYTE_IN_YMASK None, vzeroupper_ret, MASK_00_7F, eax
	add rdi, rdx
	add rsi, rdx
mismatch_in_00_7F:
	JCC_NULL_BYTE_IN_YMASK Some, mismatch_in_00_3F, MASK_00_3F, ecx
;mismatch_in_40_7F:
	JCC_NULL_BYTE_IN_YMASK Some, mismatch_in_40_5F, MASK_40_5F, ecx
;mismatch_in_60_7F:
	RETURN_DIFF eax, 0x60

align 16, int3
mismatch_in_40_5F:
	RETURN_DIFF ecx, 0x40

align 16, int3
compare_last_2_ywords:
	COMPARE_N_YWORDS 2, vmovdqu, rdi, rsi, rdx
	JCC_NULL_BYTE_IN_YMASK None, vzeroupper_ret, MASK_00_3F, ecx
	add rdi, rdx
	add rsi, rdx
mismatch_in_00_3F:
	JCC_NULL_BYTE_IN_YMASK Some, mismatch_in_00_1F, MASK_00_1F, eax
;mismatch_in_20_3F:
	RETURN_DIFF ecx, 0x20

align 16, int3
compare_last_yword:
	COMPARE_N_YWORDS 1, vmovdqu, rdi, rsi, rdx
	JCC_NULL_BYTE_IN_YMASK None, vzeroupper_ret, MASK_00_1F, eax
	add rdi, rdx
	add rsi, rdx
mismatch_in_00_1F:
; calculate the index of the first mismatching byte
	bsf ecx, eax
; load the first mismatching byte from both S0 and S1
	movzx eax, byte [ rdi + rcx ]
	movzx ecx, byte [ rsi + rcx ]
; return the difference between the two bytes
	sub eax, ecx
vzeroupper_ret:
	VZEROUPPER_RET

align 16, int3
less_than_1_yword:
	cmp edx, OWORD_SIZE
	jb less_than_1_oword
; compare the first oword of both S0 and S1
	COMPARE_1_OWORD
	JCC_NULL_BYTE_IN_OMASK Some, mismatch_in_00_1F, xmm0, eax
; advance both S0 and S1 to their respective last oword
	lea rdi, [ rdi + rdx - OWORD_SIZE ]
	lea rsi, [ rsi + rdx - OWORD_SIZE ]
; compare the last oword of both S0 and S1
	COMPARE_1_OWORD
	JCC_NULL_BYTE_IN_OMASK Some, mismatch_in_00_1F, xmm0, eax
return:
	ret

align 16, int3
less_than_1_oword:
	cmp edx, QWORD_SIZE
	jb less_than_1_qword
; compare the first qword of both S0 and S1
	movbe rax, [ rdi ]
	movbe rcx, [ rsi ]
	sub rax, rcx
	jnz diff_in_rax
; compare the last qword of both S0 and S1
	movbe rax, [ rdi + rdx - QWORD_SIZE ]
	movbe rcx, [ rsi + rdx - QWORD_SIZE ]
	sub rax, rcx
	jz return
diff_in_rax:
	sbb eax, eax
	or eax, 1
	ret

align 16, int3
less_than_1_qword:
	cmp edx, DWORD_SIZE
	jb less_than_1_dword
; load the first dword of both S0 and S1
	movbe eax, [ rdi ]
	movbe ecx, [ rsi ]
; load the last dword of both S0 and S1
	movbe edi, [ rdi + rdx - DWORD_SIZE ]
	movbe esi, [ rsi + rdx - DWORD_SIZE ]
; merge each dword pair into a single qword
	shl rax, DWORD_BITS
	shl rcx, DWORD_BITS
	or rax, rdi
	or rcx, rsi
; compare the resulting qword of both S0 and S1
	sub rax, rcx
	jnz diff_in_rax
	ret

align 16, int3
less_than_1_dword:
	cmp edx, WORD_SIZE
	jb less_than_1_word
; load the first word of both S0 and S1
	movbe ax, [ rdi ]
	movbe cx, [ rsi ]
; load the last word of both S0 and S1
	movbe di, [ rdi + rdx - WORD_SIZE ]
	movbe si, [ rsi + rdx - WORD_SIZE ]
; merge each word pair into a single dword
	shl eax, WORD_BITS
	shl ecx, WORD_BITS
	and edi, 0xFFFF
	and esi, 0xFFFF
	or eax, edi
	or ecx, esi
; compare the resulting dword of both S0 and S1
	sub eax, ecx
	ret

align 16, int3
less_than_1_word:
	test edx, edx
	cmovz rdi, rsi
	movzx eax, byte [ rdi ]
	movzx ecx, byte [ rsi ]
	sub eax, ecx
	ret
