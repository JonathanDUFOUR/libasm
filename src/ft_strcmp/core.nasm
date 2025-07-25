; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2, BMI2

global ft_strcmp: function

%use smartalign
ALIGNMODE p6

%include "define/sizes.nasm"
%include "define/chunk_masks.nasm"
%include "define/registers.nasm"
%include "macro/check_and_compare_1_chunk.nasm"
%include "macro/check_and_compare_1_oword.nasm"
%include "macro/check_and_compare_1_yword.nasm"
%include "macro/check_and_compare_2_ywords.nasm"
%include "macro/check_and_compare_4_ywords.nasm"
%include "macro/jcc_ymm_mask_has_null_byte.nasm"
%include "macro/jump_if_ymm_has_null_byte.nasm"
%include "macro/negate_if_flag.nasm"
%include "macro/return_mismatch_or_null.nasm"
%include "macro/return_mismatch_or_null_maybe_inverted.nasm"
%include "macro/vzeroupper_ret.nasm"

section .text align=16
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
ft_strcmp:
; preliminary initialization
	vpxor NULL_OWORD, NULL_OWORD, NULL_OWORD
; check if either S0 or S1 is less than 4 ywords away from its next page boundary
; NOTE: this way to check can lead to false positives, but the performance gain is worth it
	mov eax, edi
	or eax, esi
	and eax, PAGE_SIZE - 1
	cmp eax, PAGE_SIZE - YWORD_SIZE * 4
	ja maybe_less_than_4_ywords_before_either_S0_or_S1_crosses_page_boundary
align 16
check_first_4_ywords_from_start_one_by_one:
; first yword from start
	CHECK_AND_COMPARE_1_YWORD vmovdqu, rdi, rsi, 0x00
	JCC_YMM_MASK_HAS_NULL_BYTE jnz, mismatch_or_null.in_1st_yword_from_start
; second yword from start
	CHECK_AND_COMPARE_1_YWORD vmovdqu, rdi, rsi, 0x20
	JCC_YMM_MASK_HAS_NULL_BYTE jnz, mismatch_or_null.in_2nd_yword_from_start
; third yword from start
	CHECK_AND_COMPARE_1_YWORD vmovdqu, rdi, rsi, 0x40
	JCC_YMM_MASK_HAS_NULL_BYTE jnz, mismatch_or_null.in_3rd_yword_from_start
; fourth yword from start
	CHECK_AND_COMPARE_1_YWORD vmovdqu, rdi, rsi, 0x60
	JCC_YMM_MASK_HAS_NULL_BYTE jnz, mismatch_or_null.in_4th_yword_from_start
; clear the inversion flag
	xor INVERSION_FLAG, INVERSION_FLAG
align 16
loop_prologue:
; align S0 to its next 4-yword boundary + adjust S1 accordingly
	sub rsi, rdi
	and rdi, -YWORD_SIZE * 4
	add rdi,  YWORD_SIZE * 4
	add rsi, rdi
; check if S1 is aligned to a 4-yword boundary
	test esi, YWORD_SIZE * 4 - 1
	jz unchecked_loop
; calculate how far S1 is from its next page boundary
	mov eax, esi
	neg eax
	and eax, PAGE_SIZE - 1
; calculate how far S1 is from its previous 4-yword boundary
	mov r9d, esi
	and r9d, YWORD_SIZE * 4 - 1
; check if S1 is less than 4 ywords away from its next page boundary
	sub eax, YWORD_SIZE * 4
	jc less_than_4_ywords_before_S1_crosses_page_boundary
; calculate the offset between S1 and S0
	sub rsi, rdi
align 16
checked_loop:
	CHECK_AND_COMPARE_4_YWORDS rdi, rdi + rsi, mismatch_or_null.restore_S1_pointer
; advance both S0 and S1 to their respective next 4 ywords
	add rdi, YWORD_SIZE * 4
; update the distance between S1 and its next page boundary
	sub eax, YWORD_SIZE * 4
; repeat until either there is a (mismatching|null) byte in the next 4 ywords
; or S1 is less than 4 ywords away from its next page boundary
	jnc checked_loop
; adjust S0 to the last 4-yword boundary of the current S1 page
	sub rdi, r9
	CHECK_AND_COMPARE_4_YWORDS rdi + rsi, rdi, mismatch_or_null.restore_S1_pointer
; restore the S0 pointer
	add rdi, r9
; update the distance between S1 and its next page boundary
	add eax, PAGE_SIZE
; repeat until there is a (mismatching|null) byte in the next 4 ywords
	jmp checked_loop

align 16
less_than_4_ywords_before_S1_crosses_page_boundary:
; check if S1 is at least 2 ywords away from its next page boundary
	cmp eax, -YWORD_SIZE * 2
	jl less_than_2_ywords_before_S1_crosses_page_boundary
	CHECK_AND_COMPARE_2_YWORDS rdi, rsi
; advance S1 to the last 2-yword boundary of its current page + adjust S0 accordingly
	sub rdi, r9
	add rdi, YWORD_SIZE * 2
	sub rsi, r9
	add rsi, YWORD_SIZE * 2
	CHECK_AND_COMPARE_2_YWORDS rsi, rdi
; calculate the offset between S1 and S0
	sub rsi, rdi
; align S0 to its previous 4-yword boundary
	and rdi, -YWORD_SIZE * 4
; update the distance between S1 and its next page boundary
	add eax, PAGE_SIZE
	jmp checked_loop

align 16
less_than_2_ywords_before_S1_crosses_page_boundary:
; check if S1 is at least 1 yword away from its next page boundary
	cmp eax, -YWORD_SIZE * 3
	jl less_than_1_yword_before_S1_crosses_page_boundary
	CHECK_AND_COMPARE_1_YWORD vmovdqa, rdi, rsi
	JCC_YMM_MASK_HAS_NULL_BYTE jnz, mismatch_or_null.in_00_1F
; advance S1 to the last yword boundary of its current page + adjust S0 accordingly
	sub rdi, r9
	add rdi, YWORD_SIZE * 3
	sub rsi, r9
	add rsi, YWORD_SIZE * 3
	CHECK_AND_COMPARE_1_YWORD vmovdqa, rsi, rdi
	JCC_YMM_MASK_HAS_NULL_BYTE jnz, mismatch_or_null.in_00_1F
; calculate the offset between S1 and S0
	sub rsi, rdi
; align S0 to its previous 4-yword boundary
	and rdi, -YWORD_SIZE * 4
; update the distance between S1 and its next page boundary
	add eax, PAGE_SIZE
	jmp checked_loop

align 16
less_than_1_yword_before_S1_crosses_page_boundary:
; prepare the bitmask to ignore the unwanted leading bytes
	mov edx, 0xFFFFFFFF
	shlx edx, edx, esi
	not edx
; retreat S1 to the last yword boundary of its current page + adjust S0 accordingly
	sub rdi, r9
	add rdi, YWORD_SIZE * 3
	sub rsi, r9
	add rsi, YWORD_SIZE * 3
	CHECK_AND_COMPARE_1_YWORD vmovdqa, rsi, rdi
; extract the bitmask of the next yword
	vpmovmskb ecx, MASK_00_1F
; ignore the unwanted leading bytes
	or ecx, edx
; check if there is a (mismatching|null) byte
	inc ecx
	jnz mismatch_or_null.in_00_1F
; calculate the offset between S1 and S0
	sub rsi, rdi
; align S0 to its next 4-yword boundary
	and rdi, -YWORD_SIZE * 4
	add rdi,  YWORD_SIZE * 4
; update the distance between S1 and its next page boundary
	add eax, PAGE_SIZE
	jmp checked_loop

align 16
unchecked_loop:
	CHECK_AND_COMPARE_4_YWORDS rdi, rsi, mismatch_or_null.in_00_7F
; advance both S0 and S1 to their respective next 4 ywords
	add rdi, YWORD_SIZE * 4
	add rsi, YWORD_SIZE * 4
; repeat until there is a (mismatching|null) byte in the next 4 ywords
	jmp unchecked_loop

mismatch_or_null:
align 16
.in_1st_yword_from_start:
	RETURN_MISMATCH_OR_NULL 0x00

align 16
.in_2nd_yword_from_start:
	RETURN_MISMATCH_OR_NULL 0x20

align 16
.in_3rd_yword_from_start:
	RETURN_MISMATCH_OR_NULL 0x40

align 16
.in_4th_yword_from_start:
	RETURN_MISMATCH_OR_NULL 0x60

align 16
.restore_S1_pointer:
	add rsi, rdi
align 16
.in_00_7F:
	JUMP_IF_YMM_HAS_NULL_BYTE .in_00_3F, MASK_00_3F, edx
;in_40_7F:
	JUMP_IF_YMM_HAS_NULL_BYTE .in_40_5F, MASK_40_5F, edx
;in_60_7F:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED ecx, 0x60

align 16
.in_40_5F:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED edx, 0x40

align 16
.in_00_3F:
	JUMP_IF_YMM_HAS_NULL_BYTE .in_00_1F, MASK_00_1F, ecx
;in_20_3F:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED edx, 0x20

align 16
.in_00_1F:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED ecx, 0x00

align 16
maybe_less_than_4_ywords_before_either_S0_or_S1_crosses_page_boundary:
; check if both S0 and S1 are aligned to a yword boundary
	test eax, YWORD_SIZE - 1
	jz check_first_4_ywords_from_start_one_by_one
; calculate how far both S0 and S1 are from their respective next page boundaries
	mov eax, edi
	mov ecx, esi
	and eax, PAGE_SIZE - 1
	and ecx, PAGE_SIZE - 1
; check which string shall cross a page boundary first
	cmp eax, ecx
	jb S1_shall_cross_page_boundary_before_S0
; check if S0 is at least 4 ywords away from its next page boundary
	sub eax, PAGE_SIZE - YWORD_SIZE * 4
	jbe check_first_4_ywords_from_start_one_by_one
; initialize the offset
	xor edx, edx
; clear the inversion flag
	xor INVERSION_FLAG, INVERSION_FLAG
; check if S0 is less than 1 yword away from its next page boundary
	sub eax, YWORD_SIZE * 3
	ja less_than_1_yword_before_S0_crosses_page_boundary
align 16
at_least_1_yword_before_S0_crosses_page_boundary:
	CHECK_AND_COMPARE_1_YWORD vmovdqu, rdi, rsi, rdx
	JCC_YMM_MASK_HAS_NULL_BYTE jnz, mismatch_or_null_at_edx
; advance to the next yword of both S0 and S1
	add edx, YWORD_SIZE
; update the distance between S0 and its next page boundary
	add eax, YWORD_SIZE
; repeat until either a (mismatching|null) byte is found
; or S0 is less than 1 yword away from its next page boundary
	jl at_least_1_yword_before_S0_crosses_page_boundary
; set the offset to the last yword of the current S0 page
	sub edx, eax
	CHECK_AND_COMPARE_1_YWORD vmovdqa, rdi, rsi, rdx
	JCC_YMM_MASK_HAS_NULL_BYTE jz, loop_prologue
align 16
mismatch_or_null_at_edx:
	RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED ecx, edx

align 16
S1_shall_cross_page_boundary_before_S0:
; check if S1 is at least 4 ywords away from its next page boundary
	sub ecx, PAGE_SIZE - YWORD_SIZE * 4
	jbe check_first_4_ywords_from_start_one_by_one
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
align 16
less_than_1_yword_before_S0_crosses_page_boundary:
; check if S0 is less than 1 oword away from its next page boundary
	cmp eax, OWORD_SIZE
	ja less_than_1_oword_before_S0_crosses_page_boundary
	CHECK_AND_COMPARE_1_OWORD vmovdqu
; set the offset to the last oword of the current S0 page
	mov edx, OWORD_SIZE
	sub edx, eax
	CHECK_AND_COMPARE_1_OWORD vmovdqa, rdx
	jmp loop_prologue

align 16
less_than_1_oword_before_S0_crosses_page_boundary:
; check if S0 is less than 1 qword away from its next page boundary
	cmp eax, OWORD_SIZE + QWORD_SIZE
	ja less_than_1_qword_before_S0_crosses_page_boundary
	CHECK_AND_COMPARE_1_CHUNK vmovq, QWORD_MASK
; set the offset to the last qword of the current S0 page
	mov edx, OWORD_SIZE + QWORD_SIZE
	sub edx, eax
	CHECK_AND_COMPARE_1_CHUNK vmovq, QWORD_MASK, rdx
	jmp loop_prologue

align 16
less_than_1_qword_before_S0_crosses_page_boundary:
; check if S0 is less than 1 dword away from its next page boundary
	cmp eax, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE
	ja less_than_1_dword_before_S0_crosses_page_boundary
	CHECK_AND_COMPARE_1_CHUNK vmovd, DWORD_MASK
; set the offset to the last dword of the current S0 page
	mov edx, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE
	sub edx, eax
	CHECK_AND_COMPARE_1_CHUNK vmovd, DWORD_MASK, rdx
	jmp loop_prologue

align 16
less_than_1_dword_before_S0_crosses_page_boundary:
; check if S0 is less than 1 word away from its next page boundary
	cmp eax, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE + WORD_SIZE
	ja less_than_1_word_before_S0_crosses_page_boundary
	mov rdx, -WORD_SIZE
	CHECK_AND_COMPARE_1_CHUNK vmovd, WORD_MASK, -WORD_SIZE
; set the offset to the last dword of the current S0 page
	mov edx, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE
	sub rdx, rax
	CHECK_AND_COMPARE_1_CHUNK vmovd, WORD_MASK, rdx
	jmp loop_prologue

align 16
less_than_1_word_before_S0_crosses_page_boundary:
; load the very first byte from both S0 and S1
	movzx eax, byte [ rdi ]
	movzx ecx, byte [ rsi ]
; calculate the possible difference between them
	sub eax, ecx
	jnz diff_on_first_byte_from_start
; check if we have reached the end of both S0 and S1
	test ecx, ecx
	jnz loop_prologue
	ret

align 16
diff_on_first_byte_from_start:
	NEGATE_IF_FLAG eax, INVERSION_FLAG
	ret
