; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2, BMI2

global ft_strlen: function

%use smartalign
ALIGNMODE p6

%include "define/registers.nasm"
%include "define/sizes.nasm"
%include "macro/jcc_null_byte_in_ymm.nasm"
%include "macro/set_masks_for_next_n_ywords.nasm"
%include "macro/return_final_length.nasm"
%include "macro/vzeroupper_ret.nasm"

section .text
; Calculates the length of a null-terminated string.
;
; Parameters
; rdi: S: the address of the string to calculate the length of. (assumed to be a valid address)
;
; Return
; rax: the length of string.
align 16, int3
ft_strlen:
; preliminary initialization
	mov rax, rdi
	vpxor NULL_YMM, NULL_YMM, NULL_YMM
; align S to its previous yword boundary
	and rax, -YWORD_SIZE
; check if there is a null byte in the next yword
	vpcmpeqb ymm1, NULL_YMM, [ rax ]
	vpmovmskb ecx, ymm1
; ignore the unwanted leading bytes
	shrx ecx, ecx, edi
; calculate the index of the first null byte in the first yword if any
	bsf ecx, ecx
	jz advance_S_to_next_yword_boundary
	mov rax, rcx
	VZEROUPPER_RET

align 16, int3
advance_S_to_next_yword_boundary:
	add rax, YWORD_SIZE
; check if S is already aligned to a 2-yword boundary
	test rax, YWORD_SIZE
	jz check_if_S_is_aligned_to_4_yword_boundary
; check if there is a null byte in the next yword
	vpcmpeqb ymm1, NULL_YMM, [ rax ]
	vpmovmskb ecx, ymm1
	test ecx, ecx
	jz advance_S_to_next_2_yword_boundary
null_byte_in_00_1F:
	RETURN_FINAL_LENGTH ecx, 0x00

align 16, int3
advance_S_to_next_2_yword_boundary:
	add rax, YWORD_SIZE
check_if_S_is_aligned_to_4_yword_boundary:
	test rax, YWORD_SIZE * 2
	jz check_if_S_is_aligned_to_8_yword_boundary
; check if there is a null byte in the next 2 ywords
	SET_MASKS_FOR_NEXT_N_YWORDS 2
	JCC_NULL_BYTE_IN_YMM jz, advance_S_to_next_4_yword_boundary, MASK_00_3F, edx
null_byte_in_00_3F:
	JCC_NULL_BYTE_IN_YMM jnz, null_byte_in_00_1F, YMM_00_1F, ecx
;null_byte_in_20_3F:
	RETURN_FINAL_LENGTH edx, 0x20

align 16, int3
advance_S_to_next_4_yword_boundary:
	add rax, YWORD_SIZE * 2
check_if_S_is_aligned_to_8_yword_boundary:
	test rax, YWORD_SIZE * 4
	jz retreat_S_to_previous_8_yword_boundary
; check if there is a null byte in the next 4 ywords
	SET_MASKS_FOR_NEXT_N_YWORDS 4
	JCC_NULL_BYTE_IN_YMM jz, retreat_S_to_previous_8_yword_boundary, MASK_00_7F, ecx
null_byte_in_00_7F:
	JCC_NULL_BYTE_IN_YMM jnz, null_byte_in_00_3F, MASK_00_3F, edx
;null_byte_in_40_7F
	JCC_NULL_BYTE_IN_YMM jnz, null_byte_in_40_5F, YMM_40_5F, edx
;null_byte_in_60_7F:
	RETURN_FINAL_LENGTH ecx, 0x60

align 16, int3
null_byte_in_40_5F:
	RETURN_FINAL_LENGTH edx, 0x40

align 16, int3
retreat_S_to_previous_8_yword_boundary:
	dec rax
	and rax, -YWORD_SIZE * 8
align CACHE_LINE_SIZE
advance_S_to_next_8_yword_boundary:
	add rax, YWORD_SIZE * 8
; check if there is a null byte in the next 8 ywords
	SET_MASKS_FOR_NEXT_N_YWORDS 8
	JCC_NULL_BYTE_IN_YMM jz, advance_S_to_next_8_yword_boundary, MASK_00_FF, edx
;null_byte_in_00_FF:
	JCC_NULL_BYTE_IN_YMM jnz, null_byte_in_00_7F, MASK_00_7F, ecx
;null_byte_in_80_FF:
	JCC_NULL_BYTE_IN_YMM jnz, null_byte_in_80_BF, MASK_80_BF, ecx
;null_byte_in_C0_FF:
	JCC_NULL_BYTE_IN_YMM jnz, null_byte_in_C0_DF, YMM_C0_DF, ecx
;null_byte_in_E0_FF:
	RETURN_FINAL_LENGTH edx, 0xE0

align 16, int3
null_byte_in_C0_DF:
	RETURN_FINAL_LENGTH ecx, 0xC0

align 16, int3
null_byte_in_80_BF:
	JCC_NULL_BYTE_IN_YMM jnz, null_byte_in_80_9F, YMM_80_9F, edx
;null_byte_in_A0_BF:
	RETURN_FINAL_LENGTH ecx, 0xA0

align 16, int3
null_byte_in_80_9F:
	RETURN_FINAL_LENGTH edx, 0x80
