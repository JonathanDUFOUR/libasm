; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2, BMI2

global ft_strcmp: function

%use smartalign
ALIGNMODE p6

%include "define/chunk_masks.nasm"
%include "define/nops.nasm"
%include "define/registers.nasm"
%include "define/sizes.nasm"
%include "macro/compare_1_chunk.nasm"
%include "macro/compare_1_oword.nasm"
%include "macro/compare_1_yword.nasm"
%include "macro/compare_2_ywords.nasm"
%include "macro/compare_4_ywords.nasm"
%include "macro/jcc_null_byte_in_vecmask.nasm"
%include "macro/jcc_null_byte_in_ymm.nasm"
%include "macro/negate_if_flag.nasm"
%include "macro/return_mismatch_or_null.nasm"
%include "macro/return_mismatch_or_null_maybe_inverted.nasm"

section .text
; Compares two null-terminated strings.
;
; Parameters
; rdi: S0: the address of the 1st string to compare. (assumed to be a valid address)
; rsi: S1: the address of the 2nd string to compare. (assumed to be a valid address)
;
; Return
; eax:
; - zero if S0 and S1 completely match.
; - a negative value if the first mismatching byte in S0 is less than the first one in S1.
; - a positive value if the first mismatching byte in S0 is greater than the first one in S1.
align 16, int3
ft_strcmp:
; preliminary initialization
	xor INVERSION_FLAG, INVERSION_FLAG
	vpxor NULL_XMM, NULL_XMM, NULL_XMM
; check if either S0 or S1 is less than 4 ywords away from its next page boundary
; NOTE: this way to check can lead to false positives, but the performance gain is worth it
	mov eax, edi
	or eax, esi
	and eax, PAGE_SIZE - 1
	cmp eax, PAGE_SIZE - YWORD_SIZE * 4
	ja maybe_less_than_4_ywords_before_either_S0_or_S1_crosses_page_boundary
compare_first_yword:
	COMPARE_1_YWORD vmovdqu, rdi, rsi, YWORD_SIZE * 0
	JCC_NULL_BYTE_IN_VECMASK None, compare_second_yword, MASK_00_1F, ecx
	RETURN_MISMATCH_OR_NULL YWORD_SIZE * 0

align 16, int3
compare_second_yword:
	COMPARE_1_YWORD vmovdqu, rdi, rsi, YWORD_SIZE * 1
	JCC_NULL_BYTE_IN_VECMASK None, compare_third_yword, MASK_00_1F, ecx
	RETURN_MISMATCH_OR_NULL YWORD_SIZE * 1

align 16, int3
compare_third_yword:
	COMPARE_1_YWORD vmovdqu, rdi, rsi, YWORD_SIZE * 2
	JCC_NULL_BYTE_IN_VECMASK None, compare_fourth_yword, MASK_00_1F, ecx
	RETURN_MISMATCH_OR_NULL YWORD_SIZE * 2

align 16, int3
compare_fourth_yword:
	COMPARE_1_YWORD vmovdqu, rdi, rsi, YWORD_SIZE * 3
	JCC_NULL_BYTE_IN_VECMASK None, align_S0_to_previous_4_yword_boundary, MASK_00_1F, ecx
	RETURN_MISMATCH_OR_NULL YWORD_SIZE * 3

align 32, int3
align_S0_to_previous_4_yword_boundary:
	sub rsi, rdi
	and rdi, -YWORD_SIZE * 4
	add rsi, rdi
; check if S1 is aligned to a 4-yword boundary
	test esi, YWORD_SIZE * 4 - 1
	jnz checked_loop_prologue
align CACHE_LINE_SIZE
unchecked_loop:
; advance both S0 and S1 to their respective next 4-yword boundary
	sub rdi, -YWORD_SIZE * 4
	sub rsi, -YWORD_SIZE * 4
; compare the next 4 ywords of S0 with the next 4 ywords of S1
	COMPARE_4_YWORDS rdi, rsi
; repeat until there is a (mismatching|null) byte in the next 4 ywords
	JCC_NULL_BYTE_IN_YMM None, unchecked_loop, MASK_00_7F, ecx
;mismatch_or_null_in_00_7F:
	JCC_NULL_BYTE_IN_YMM Some, mismatch_or_null_in_00_3F, MASK_00_3F, edx
;mismatch_or_null_in_40_7F:
	JCC_NULL_BYTE_IN_YMM Some, mismatch_or_null_in_40_5F, MASK_40_5F, edx
mismatch_or_null_in_60_7F:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED ecx, 0x60

align 16, int3
checked_loop_prologue:
; advance both S0 and S1 to their respective next 4 ywords
	sub rdi, -YWORD_SIZE * 4
	sub rsi, -YWORD_SIZE * 4
; calculate how far S1 is from its next page boundary
	mov eax, esi
	neg eax
	and eax, PAGE_SIZE - 1
; check if S1 is less than 4 ywords away from its next page boundary
	add rax, -YWORD_SIZE * 4
	jnc less_than_4_ywords_before_S1_crosses_page_boundary
align CACHE_LINE_SIZE
checked_loop:
	COMPARE_4_YWORDS rdi, rsi
; check if there is a (mismatching|null) byte in the next 4 ywords
	JCC_NULL_BYTE_IN_YMM Some, mismatch_or_null_in_00_7F, MASK_00_7F, ecx
; advance both S0 and S1 to their respective next 4 ywords
	sub rdi, -YWORD_SIZE * 4
	sub rsi, -YWORD_SIZE * 4
; update the distance between S1 and its next page boundary
	add rax, -YWORD_SIZE * 4
; repeat until either there is a (mismatching|null) byte in the next 4 ywords
; or S1 is less than 4 ywords away from its next page boundary
	jc checked_loop
; compare the last 4 ywords of the current page of S1 with the corresponding 4 ywords of S0
	COMPARE_4_YWORDS rsi, rdi, rax
; update the distance between S1 and its next page boundary if no (mismatching|null) byte was found
	add eax, PAGE_SIZE
; repeat until there is a (mismatching|null) byte in the next 4 ywords
	JCC_NULL_BYTE_IN_YMM None, checked_loop, MASK_00_7F, ecx
; advance S1 to the last 4-yword boundary of its current page + adjust S0 accordingly
	lea rdi, [ rdi + rax - PAGE_SIZE ]
	lea rsi, [ rsi + rax - PAGE_SIZE ]
mismatch_or_null_in_00_7F:
	JCC_NULL_BYTE_IN_YMM Some, mismatch_or_null_in_00_3F, MASK_00_3F, edx
;mismatch_or_null_in_40_7F:
	JCC_NULL_BYTE_IN_YMM None, mismatch_or_null_in_60_7F, MASK_40_5F, edx
mismatch_or_null_in_40_5F:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED edx, 0x40

align 16, int3
less_than_4_ywords_before_S1_crosses_page_boundary:
; check if S1 is at least 2 ywords away from its next page boundary
	cmp eax, -YWORD_SIZE * 2
	jl less_than_2_ywords_before_S1_crosses_page_boundary
; compare the next 2 ywords of S0 with the next 2 ywords of S1
	COMPARE_2_YWORDS rdi, rsi
	JCC_NULL_BYTE_IN_YMM Some, mismatch_or_null_in_00_3F, MASK_00_3F, edx
; update the distance between S1 and its next page boundary
	add eax, PAGE_SIZE
; compare the last 2 ywords of the current page of S1 with the corresponding 2 ywords of S0
	COMPARE_2_YWORDS rsi, rdi, rax - PAGE_SIZE + YWORD_SIZE * 2
	JCC_NULL_BYTE_IN_YMM None, checked_loop, MASK_00_3F, edx
; advance S1 to the last 2-yword boundary of its current page + adjust S0 accordingly
	lea rdi, [ rdi + rax - PAGE_SIZE + YWORD_SIZE * 2 ]
	lea rsi, [ rsi + rax - PAGE_SIZE + YWORD_SIZE * 2 ]
mismatch_or_null_in_00_3F:
	JCC_NULL_BYTE_IN_YMM Some, mismatch_or_null_in_00_1F, MASK_00_1F, ecx
;mismatch_or_null_in_20_3F:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED edx, 0x20

align 16, int3
less_than_2_ywords_before_S1_crosses_page_boundary:
; check if S1 is at least 1 yword away from its next page boundary
	cmp eax, -YWORD_SIZE * 3
	jl less_than_1_yword_before_S1_crosses_page_boundary
; compare the next yword of S0 with the next yword of S1
	COMPARE_1_YWORD vmovdqa, rdi, rsi
	JCC_NULL_BYTE_IN_VECMASK Some, mismatch_or_null_in_00_1F, MASK_00_1F, ecx
; update the distance between S1 and its next page boundary
	add eax, PAGE_SIZE
; compare the last yword of the current page of S1 with the corresponding yword of S0
	COMPARE_1_YWORD vmovdqa, rsi, rdi, rax - PAGE_SIZE + YWORD_SIZE * 3
	JCC_NULL_BYTE_IN_VECMASK None, checked_loop, MASK_00_1F, ecx
; advance S1 to the last yword boundary of its current page + adjust S0 accordingly
	lea rdi, [ rdi + rax - PAGE_SIZE + YWORD_SIZE * 3 ]
	lea rsi, [ rsi + rax - PAGE_SIZE + YWORD_SIZE * 3 ]
mismatch_or_null_in_00_1F:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED ecx, 0x00

align 16, int3
less_than_1_yword_before_S1_crosses_page_boundary:
; prepare the bitmask to ignore the unwanted leading bytes
	mov edx, 0xFFFFFFFF
	shlx edx, edx, esi
	not edx
; update the distance between S1 and its next page boundary
	add eax, PAGE_SIZE
; compare the last yword of the current page of S1 with the corresponding yword of S0
	COMPARE_1_YWORD vmovdqa, rsi, rdi, rax - PAGE_SIZE + YWORD_SIZE * 3
; extract the bitmask of the compared ywords
	vpmovmskb ecx, MASK_00_1F
; ignore the unwanted leading bytes
	or ecx, edx
; check if there is a (mismatching|null) byte
	inc ecx
	jz checked_loop
; advance S1 to the last yword boundary of its current page + adjust S0 accordingly
	lea rdi, [ rdi + rax - PAGE_SIZE + YWORD_SIZE * 3 ]
	lea rsi, [ rsi + rax - PAGE_SIZE + YWORD_SIZE * 3 ]
;mismatch_or_null_in_00_1F:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED ecx, 0x00

align 16, int3
maybe_less_than_4_ywords_before_either_S0_or_S1_crosses_page_boundary:
; check if both S0 and S1 are aligned to a yword boundary
	test eax, YWORD_SIZE - 1
	jz compare_first_yword
; calculate how far both S0 and S1 are from their respective previous page boundary
	mov eax, edi
	mov ecx, esi
	and eax, PAGE_SIZE - 1
	and ecx, PAGE_SIZE - 1
; check which string shall cross a page boundary first
	cmp eax, ecx
	jb S1_shall_cross_page_boundary_before_S0
; check if S0 is at least 4 ywords away from its next page boundary
	sub eax, PAGE_SIZE - YWORD_SIZE * 4
	jbe compare_first_yword
; initialize the offset
	xor edx, edx
; check if S0 is less than 1 yword away from its next page boundary
	sub eax, YWORD_SIZE * 3
	ja less_than_1_yword_before_S0_crosses_page_boundary
at_least_1_yword_before_S0_crosses_page_boundary:
	COMPARE_1_YWORD vmovdqu, rdi, rsi, rdx
	JCC_NULL_BYTE_IN_VECMASK Some, mismatch_or_null_at_edx, MASK_00_1F, ecx
; advance to the next yword of both S0 and S1
	add edx, YWORD_SIZE
; update the distance between S0 and its next page boundary
	add eax, YWORD_SIZE
; repeat until either a (mismatching|null) byte is found
; or S0 is less than 1 yword away from its next page boundary
	jl at_least_1_yword_before_S0_crosses_page_boundary
; set the offset to the last yword of the current S0 page
	sub edx, eax
	COMPARE_1_YWORD vmovdqa, rdi, rsi, rdx
	JCC_NULL_BYTE_IN_VECMASK None, align_S0_to_previous_4_yword_boundary, MASK_00_1F, ecx
mismatch_or_null_at_edx:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED ecx, edx

align 16, int3
S1_shall_cross_page_boundary_before_S0:
; check if S1 is at least 4 ywords away from its next page boundary
	sub ecx, PAGE_SIZE - YWORD_SIZE * 4
	jbe compare_first_yword
; initialize the offset
	xor edx, edx
; swap both S0 and S1 pointers
	xchg rdi, rsi
	mov eax, ecx
; set the inversion flag
	mov INVERSION_FLAG, 0xFFFFFFFF
; check if S0 is at least 1 yword away from its next page boundary
	sub eax, YWORD_SIZE * 3
	jle at_least_1_yword_before_S0_crosses_page_boundary
less_than_1_yword_before_S0_crosses_page_boundary:
; check if S0 is less than 1 oword away from its next page boundary
	cmp eax, OWORD_SIZE
	ja less_than_1_oword_before_S0_crosses_page_boundary
	COMPARE_1_OWORD vmovdqu
; set the offset to the last oword of the current S0 page
	mov edx, OWORD_SIZE
	sub edx, eax
	COMPARE_1_OWORD vmovdqa, rdx
	jmp align_S0_to_previous_4_yword_boundary

align 16, int3
less_than_1_oword_before_S0_crosses_page_boundary:
; check if S0 is less than 1 qword away from its next page boundary
	cmp eax, OWORD_SIZE + QWORD_SIZE
	ja less_than_1_qword_before_S0_crosses_page_boundary
	COMPARE_1_CHUNK vmovq, QWORD_MASK
; set the offset to the last qword of the current S0 page
	mov edx, OWORD_SIZE + QWORD_SIZE
	sub edx, eax
	COMPARE_1_CHUNK vmovq, QWORD_MASK, rdx
	jmp align_S0_to_previous_4_yword_boundary

align 16, int3
less_than_1_qword_before_S0_crosses_page_boundary:
; check if S0 is less than 1 dword away from its next page boundary
	cmp eax, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE
	ja less_than_1_dword_before_S0_crosses_page_boundary
	COMPARE_1_CHUNK vmovd, DWORD_MASK
; set the offset to the last dword of the current S0 page
	mov edx, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE
	sub edx, eax
	COMPARE_1_CHUNK vmovd, DWORD_MASK, rdx
	jmp align_S0_to_previous_4_yword_boundary

align 16, int3
less_than_1_dword_before_S0_crosses_page_boundary:
; check if S0 is less than 1 word away from its next page boundary
	cmp eax, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE + WORD_SIZE
	ja less_than_1_word_before_S0_crosses_page_boundary
	mov rdx, -WORD_SIZE
	COMPARE_1_CHUNK vmovd, WORD_MASK, -WORD_SIZE
; set the offset to the last dword of the current S0 page
	mov edx, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE
	sub rdx, rax
	COMPARE_1_CHUNK vmovd, WORD_MASK, rdx
	jmp align_S0_to_previous_4_yword_boundary

align 16, int3
less_than_1_word_before_S0_crosses_page_boundary:
; load the very first byte from both S0 and S1
	movzx eax, byte [ rdi ]
	movzx ecx, byte [ rsi ]
; calculate the possible difference between them
	sub eax, ecx
	jnz diff_on_very_first_byte
; check if we have reached the end of both S0 and S1
	test ecx, ecx
	jnz align_S0_to_previous_4_yword_boundary
	ret

align 16, int3
diff_on_very_first_byte:
	NEGATE_IF_FLAG eax, INVERSION_FLAG
	ret
