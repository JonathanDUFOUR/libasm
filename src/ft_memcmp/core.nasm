; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2, MOVBE

global ft_memcmp: function

%use smartalign
ALIGNMODE p6

%include "define/bits.nasm"
%include "define/registers.nasm"
%include "define/sizes.nasm"
%include "macro/compare_1_oword.nasm"
%include "macro/compare_n_ywords.nasm"
%include "macro/jcc_null_byte_in_vecmask.nasm"
%include "macro/return_diff.nasm"
%include "macro/use_2n_ywords.nasm"
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
	cmp rdx, YWORD_SIZE * 16
	ja .compare_more_than_16_ywords
	cmp edx, YWORD_SIZE * 8
	ja .use_2x_8_ywords
	cmp edx, YWORD_SIZE * 4
	ja .use_2x_4_ywords
	cmp edx, YWORD_SIZE * 2
	ja .use_2x_2_ywords
	cmp edx, YWORD_SIZE * 1
	ja .use_2x_1_yword
	cmp edx, OWORD_SIZE * 1
	ja .use_2x_1_oword
	cmp edx, QWORD_SIZE * 1
	ja .use_2x_1_qword
	cmp edx, DWORD_SIZE * 1
	ja .use_2x_1_dword
	cmp edx, WORD_SIZE * 1
	ja .use_2x_1_word
	cmp edx, BYTE_SIZE * 1
	ja .use_2x_1_byte
	je .use_1x_1_byte
	xor eax, eax
	ret

times 0x20 int3
align 16, int3
.compare_more_than_16_ywords:
	COMPARE_N_YWORDS vmovdqu, rdi, rsi, 1, mismatch.in_00_1F
; calculate the address of the last 8 ywords to compare
	lea rdx, [ rdi + rdx - YWORD_SIZE * 8 ]
; align S0 to its next yword boundary + adjust S1 accordingly
	sub rsi, rdi
	and rdi, -YWORD_SIZE
	sub rdi, -YWORD_SIZE
	add rsi, rdi
align CACHE_LINE_SIZE
.compare_next_8_ywords:
	COMPARE_N_YWORDS vmovdqa, rdi, rsi, 8, mismatch.in_00_FF
; advance both S0 and S1 to their respective next 8 ywords
	add rdi, YWORD_SIZE * 8
	add rsi, YWORD_SIZE * 8
; check if S0 has reached its last 8 ywords
	cmp rdi, rdx
	jb .compare_next_8_ywords
; set S0 to its last 8 ywords + adjust S1 accordingly
	sub rsi, rdi
	mov rdi, rdx
	add rsi, rdi
	COMPARE_N_YWORDS vmovdqu, rdi, rsi, 8, mismatch.in_00_FF
	VZEROUPPER_RET

align 16, int3
.use_2x_8_ywords:
	USE_2N_YWORDS 8

align 16, int3
.use_2x_4_ywords:
	USE_2N_YWORDS 4

align 16, int3
.use_2x_2_ywords:
	USE_2N_YWORDS 2

align 16, int3
.use_2x_1_yword:
	USE_2N_YWORDS 1

align 16, int3
.use_2x_1_oword:
; compare the first oword of S0 and S1
	COMPARE_1_OWORD
; advance both pointers to their last oword
	lea rdi, [ rdi + rdx - OWORD_SIZE ]
	lea rsi, [ rsi + rdx - OWORD_SIZE ]
; compare the last oword of S0 and S1
	COMPARE_1_OWORD
	xor eax, eax
	ret

align 16, int3
.use_2x_1_qword:
; load the first qword from both S0 and S1 in big-endian
	movbe rax, [ rdi ]
	movbe rcx, [ rsi ]
; calculate the difference between the two qwords if any
	sub rax, rcx
	jnz mismatch.in_rax
; load the last qword from both S0 and S1
	movbe rax, [ rdi + rdx - QWORD_SIZE ]
	movbe rcx, [ rsi + rdx - QWORD_SIZE ]
; calculate the difference between the two qwords if any
	sub rax, rcx
	jnz mismatch.in_rax
	ret

align 16, int3
.use_2x_1_dword:
; load the first and last dwords from both S0 and S1 in big-endian
	movbe eax, [ rdi ]
	movbe ecx, [ rsi ]
	movbe edi, [ rdi + rdx - DWORD_SIZE ]
	movbe esi, [ rsi + rdx - DWORD_SIZE ]
; concatenate each pair of dwords into a single qword
	shl rax, DWORD_BITS
	shl rcx, DWORD_BITS
	or eax, edi
	or ecx, esi
; calculate the difference between the two qwords if any
	sub rax, rcx
	jnz mismatch.in_rax
	ret

align 16, int3
.use_2x_1_word:
; load the first and last words from both S0 and S1 in big-endian
	movbe ax, [ rdi ]
	movbe cx, [ rsi ]
	movbe di, [ rdi + rdx - WORD_SIZE ]
	movbe si, [ rsi + rdx - WORD_SIZE ]
; concatenate each pair of words into a single dword
	shl eax, WORD_BITS
	shl ecx, WORD_BITS
	mov ax, di
	mov cx, si
; calculate the difference between the two dwords if any
	sub eax, ecx
	ret

align 16, int3
.use_2x_1_byte:
; load the first and last bytes from both S0 and S1
	movzx eax, byte [ rdi ]
	movzx ecx, byte [ rsi ]
	movzx edi, byte [ rdi + rdx - BYTE_SIZE ]
	movzx esi, byte [ rsi + rdx - BYTE_SIZE ]
; concatenate each pair of bytes into a single word
	shl eax, BYTE_BITS
	shl ecx, BYTE_BITS
	or eax, edi
	or ecx, esi
; calculate the difference between the two words if any
	sub eax, ecx
	ret

align 16, int3
.use_1x_1_byte:
; load the first byte from S0
	movzx eax, byte [ rdi ]
	movzx ecx, byte [ rsi ]
; calculate the difference between the two bytes if any
	sub eax, ecx
	ret

mismatch:
align 16, int3
.in_00_FF:
	JCC_NULL_BYTE_IN_VECMASK Some, mismatch.in_00_7F, MASK_00_7F, ecx
;in_80_FF:
	JCC_NULL_BYTE_IN_VECMASK Some, mismatch.in_80_BF, MASK_80_BF, ecx
;in_C0_FF:
	JCC_NULL_BYTE_IN_VECMASK Some, mismatch.in_C0_DF, MASK_C0_DF, ecx
;in_E0_FF:
	RETURN_DIFF 0xE0, eax

align 16, int3
.in_C0_DF:
	RETURN_DIFF 0xC0, ecx

align 16, int3
.in_80_BF:
	JCC_NULL_BYTE_IN_VECMASK Some, mismatch.in_80_9F, MASK_80_9F, eax
;in_A0_BF:
	RETURN_DIFF 0xA0, ecx

align 16, int3
.in_80_9F:
	RETURN_DIFF 0x80, eax

align 16, int3
.in_00_7F:
	JCC_NULL_BYTE_IN_VECMASK Some, mismatch.in_00_3F, MASK_00_3F, eax
;in_40_7F:
	JCC_NULL_BYTE_IN_VECMASK Some, mismatch.in_40_5F, MASK_40_5F, eax
;in_60_7F:
	RETURN_DIFF 0x60, ecx

align 16, int3
.in_40_5F:
	RETURN_DIFF 0x40, eax

align 16, int3
.in_00_3F:
	JCC_NULL_BYTE_IN_VECMASK Some, mismatch.in_00_1F, MASK_00_1F, ecx
;in_20_3F:
	RETURN_DIFF 0x20, eax

align 16, int3
.in_00_1F:
	RETURN_DIFF 0x00, ecx

align 16, int3
.in_rax:
	sbb eax, eax
	or eax, 1
	ret
