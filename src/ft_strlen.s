; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2, BMI2

global ft_strlen: function

%use smartalign
ALIGNMODE p6

%define YWORD_SIZE 0x20

%define NULL_YMM ymm0

%define    S_00_1F rax + YWORD_SIZE * 0
%define    S_20_3F rax + YWORD_SIZE * 1
%define    S_40_5F rax + YWORD_SIZE * 2
%define    S_60_7F rax + YWORD_SIZE * 3
%define    S_80_9F rax + YWORD_SIZE * 4
%define    S_A0_BF rax + YWORD_SIZE * 5
%define    S_C0_DF rax + YWORD_SIZE * 6
%define    S_E0_FF rax + YWORD_SIZE * 7
%define  YMM_00_1F ymm1
%define  YMM_40_5F ymm2
%define  YMM_80_9F ymm3
%define  YMM_C0_DF ymm4
%define MASK_00_3F ymm5
%define MASK_40_7F ymm6
%define MASK_80_BF ymm7
%define MASK_C0_FF ymm8
%define MASK_00_7F ymm9
%define MASK_80_FF ymm10
%define MASK_00_FF ymm11

; Parameters
; %1: the label to jump to if the given YMM register contains a null byte.
; %2: the yword to check (may be a YMM register or an address).
%macro JUMP_IF_HAS_A_NULL_BYTE 2
%define          LABEL %1
%define YWORD_TO_CHECK %2
	vpcmpeqb ymm12, NULL_YMM, YWORD_TO_CHECK
	vptest ymm12, ymm12
	jnz LABEL
%endmacro

%macro VZEROUPPER_RET 0
	vzeroupper
	ret
%endmacro

; Parameters
; %1: the offset to apply to the pointer before calculating the final length.
%macro RETURN_FINAL_LENGTH 1
%define OFFSET %1
; calculate the index of the 1st null byte in the given YMM register
	vpmovmskb rcx, ymm12
	bsf ecx, ecx
; update the pointer to its final position
	lea rax, [ rax + OFFSET + rcx ]
; calculate the length
	sub rax, rdi
	VZEROUPPER_RET
%endmacro

section .text
; Calculates the length of a null-terminated string.
;
; Parameters
; rdi: S: the address of the string to calculate the length of. (assumed to be a valid address)
;
; Return
; rax: the length of string.
align 16
ft_strlen:
; preliminary initialization
	mov rax, rdi
	vpxor NULL_YMM, NULL_YMM, NULL_YMM
; align S to its previous yword boundary
	and rax, -YWORD_SIZE
; check if the 1st yword contains a null byte
	vpcmpeqb ymm12, NULL_YMM, [S_00_1F]
	vpmovmskb rdx, ymm12
; ignore the unwanted leading bytes
	shrx edx, edx, edi
; calculate the index of the 1st null byte in the 1st yword if any
	bsf edx, edx
	jnz .small_length
; advance S to its next yword boundary
	add rax, YWORD_SIZE
;align_S_to_next_2_yword_boundary:
; check if S is already aligned to a 2-yword boundary
	test rax, YWORD_SIZE
	jz .align_S_to_next_4_yword_boundary
; check if the next yword contains a null byte
	JUMP_IF_HAS_A_NULL_BYTE found_null_byte.in_00_1F, [S_00_1F]
; advance S to its next 2-yword boundary
	add rax, YWORD_SIZE
align 16
.align_S_to_next_4_yword_boundary:
; check if S is already aligned to a 4-yword boundary
	test rax, YWORD_SIZE * 2
	jz .align_S_to_next_8_yword_boundary
;                 ┌──YMM_00_1F──[S_00_1F]
; MASK_00_3F──MINUB
;                 └─────────────[S_20_3F]
	vmovdqa YMM_00_1F, [S_00_1F]
	vpminub MASK_00_3F, YMM_00_1F, [S_20_3F]
; check if there is a null byte
	JUMP_IF_HAS_A_NULL_BYTE found_null_byte.in_00_3F, MASK_00_3F
; advance S to its next 4-yword boundary
	add rax, YWORD_SIZE * 2
align 16
.align_S_to_next_8_yword_boundary:
	test rax, YWORD_SIZE * 4
	jz .check_next_8_ywords
;                                     ┌──YMM_00_1F──[S_00_1F]
;                  ┌──MASK_00_3F──MINUB
;                  │                  └─────────────[S_20_3F]
; MASK_00_7F───MINUB
;                  │                  ┌──YMM_40_5F──[S_40_5F]
;                  └──MASK_40_7F──MINUB
;                                     └─────────────[S_60_7F]
	vmovdqa YMM_00_1F, [S_00_1F]
	vmovdqa YMM_40_5F, [S_40_5F]
	vpminub MASK_00_3F, YMM_00_1F, [S_20_3F]
	vpminub MASK_40_7F, YMM_40_5F, [S_60_7F]
	vpminub MASK_00_7F, MASK_00_3F, MASK_40_7F
; check if there is a null byte
	JUMP_IF_HAS_A_NULL_BYTE found_null_byte.in_00_7F, MASK_00_7F
; advance S to its next 8-yword boundary
	add rax, YWORD_SIZE * 4
align 16
.check_next_8_ywords:
;                                                       ┌──YMM_00_1F──[S_00_1F]
;                                    ┌──MASK_00_3F──MINUB
;                                    │                  └─────────────[S_20_3F]
;                 ┌──MASK_00_7F──MINUB
;                 │                  │                  ┌──YMM_40_5F──[S_40_5F]
;                 │                  └──MASK_40_7F──MINUB
;                 │                                     └─────────────[S_60_7F]
; MASK_00_FF──MINUB
;                 │                                     ┌──YMM_80_9F──[S_80_9F]
;                 │                  ┌──MASK_80_BF──MINUB
;                 │                  │                  └─────────────[S_A0_BF]
;                 └──MASK_80_FF──MINUB
;                                    │                  ┌──YMM_C0_DF──[S_C0_DF]
;                                    └──MASK_C0_FF──MINUB
;                                                       └─────────────[S_E0_FF]
	vmovdqa YMM_00_1F, [S_00_1F]
	vmovdqa YMM_40_5F, [S_40_5F]
	vmovdqa YMM_80_9F, [S_80_9F]
	vmovdqa YMM_C0_DF, [S_C0_DF]
	vpminub MASK_00_3F, YMM_00_1F, [S_20_3F]
	vpminub MASK_40_7F, YMM_40_5F, [S_60_7F]
	vpminub MASK_80_BF, YMM_80_9F, [S_A0_BF]
	vpminub MASK_C0_FF, YMM_C0_DF, [S_E0_FF]
	vpminub MASK_00_7F, MASK_00_3F, MASK_40_7F
	vpminub MASK_80_FF, MASK_80_BF, MASK_C0_FF
	vpminub MASK_00_FF, MASK_00_7F, MASK_80_FF
; check if there is a null byte
	JUMP_IF_HAS_A_NULL_BYTE found_null_byte.in_00_FF, MASK_00_FF
; advance S to its next 8 ywords
	add rax, YWORD_SIZE * 8
; repeat until the next 8 ywords contain a null byte
	jmp .check_next_8_ywords

align 16
.small_length:
	mov rax, rdx
	VZEROUPPER_RET

found_null_byte:

align 16
.in_00_FF:
	JUMP_IF_HAS_A_NULL_BYTE .in_00_7F, MASK_00_7F
;in_80_FF:
	JUMP_IF_HAS_A_NULL_BYTE .in_80_BF, MASK_80_BF
;in_C0_FF:
	JUMP_IF_HAS_A_NULL_BYTE .in_C0_DF, YMM_C0_DF
;in_E0_FF:
	vpcmpeqb ymm12, NULL_YMM, [S_E0_FF]
	RETURN_FINAL_LENGTH 0xE0

align 16
.in_00_7F:
	JUMP_IF_HAS_A_NULL_BYTE .in_00_3F, MASK_00_3F
;in_40_7F:
	JUMP_IF_HAS_A_NULL_BYTE .in_40_5F, YMM_40_5F
;in_60_7F:
	vpcmpeqb ymm12, NULL_YMM, [S_60_7F]
	RETURN_FINAL_LENGTH 0x60

align 16
.in_00_3F:
	JUMP_IF_HAS_A_NULL_BYTE .in_00_1F, [S_00_1F]
;in_20_3F:
	vpcmpeqb ymm12, NULL_YMM, [S_20_3F]
	RETURN_FINAL_LENGTH 0x20

align 16
.in_00_1F:
	RETURN_FINAL_LENGTH 0x00

align 16
.in_40_5F:
	RETURN_FINAL_LENGTH 0x40

align 16
.in_80_BF:
	JUMP_IF_HAS_A_NULL_BYTE .in_80_9F, YMM_80_9F
;in_A0_BF:
	vpcmpeqb ymm12, NULL_YMM, [S_A0_BF]
	RETURN_FINAL_LENGTH 0xA0

align 16
.in_80_9F:
	RETURN_FINAL_LENGTH 0x80

align 16
.in_C0_DF:
	RETURN_FINAL_LENGTH 0xC0
