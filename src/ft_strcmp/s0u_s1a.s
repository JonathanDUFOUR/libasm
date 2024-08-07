global ft_strcmp_s0u_s1a: function

%use smartalign
ALIGNMODE p6

%define SIZEOF_YWORD 32

%define EQUAL_EACH        01000b
%define NEGATIVE_POLARITY 10000b

; Parameters:
; %1: the label to jump to if the given YMM register contains at least 1 null byte.
; %2: the YMM register to check.
%macro JUMP_IF_HAS_A_NULL_BYTE 2
	vpcmpeqb ymm15, ymm0, %2
	vptest ymm15, ymm15
	jnz %1
%endmacro

%macro CLEAN_RET 0
	vzeroupper
	ret
%endmacro

; Parameters:
; %1: the offset to apply to both pointers before calculating the difference between the first mismatching bytes.
%macro RETURN_DIFF 1
	; calculate the difference between the first mismatching bytes
	movzx eax, byte [rdi+rcx+%1]
	movzx ecx, byte [rsi+rcx+%1]
	sub eax, ecx
	CLEAN_RET
%endmacro

section .text
; Compares two null-terminated strings.
;
; Parameters
; rdi: the address of the first string to compare. (assumed to be a valid address)
; rsi: the address of the second string to compare. (assumed to be a valid address)
;
; Return
; eax:
; - zero if the strings are equal.
; - a negative value if the first string is less than the second.
; - a positive value if the first string is greater than the second.
ft_strcmp_s0u_s1a:
; preliminary initialization
	vpxor ymm0, ymm0, ymm0
; load the first yword of the first string
	vmovdqu ymm1, [rdi]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x1F, ymm1
; compare the first yword of both strings
	vpcmpeqb ymm1, ymm1, [rsi]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x1F, ymm1
; calculate how har the second string is to its next yword boundary
	lea rax, [rsi+SIZEOF_YWORD]
	and rax, -SIZEOF_YWORD
	sub rax, rsi
; advance both the first pointer and the second pointer by the calculated distance
	add rdi, rax
	add rsi, rax
align 16
.check_the_next_8_ywords:
; load the next 8 ywords of the first string
	vmovdqu ymm1, [rdi+0x00]
	vmovdqu ymm2, [rdi+0x20]
	vmovdqu ymm3, [rdi+0x40]
	vmovdqu ymm4, [rdi+0x60]
	vmovdqu ymm5, [rdi+0x80]
	vmovdqu ymm6, [rdi+0xA0]
	vmovdqu ymm7, [rdi+0xC0]
	vmovdqu ymm8, [rdi+0xE0]
; merge the 8 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm9,  ymm1,  ymm2
	vpminub ymm10, ymm3,  ymm4
	vpminub ymm11, ymm5,  ymm6
	vpminub ymm12, ymm7,  ymm8
	vpminub ymm13, ymm9,  ymm10
	vpminub ymm14, ymm11, ymm12
	vpminub ymm15, ymm13, ymm14
;                    ,----ymm1  s0[0x00..=0x1F]
;             ,---ymm9
;             |      '----ymm2  s0[0x20..=0x3F]
;     ,---ymm13
;     |       |       ,---ymm3  s0[0x40..=0x5F]
;     |       '---ymm10
;     |               '---ymm4  s0[0x60..=0x7F]
; ymm15
;     |               ,---ymm5  s0[0x80..=0x9F]
;     |       ,---ymm11
;     |       |       '---ymm6  s0[0xA0..=0xBF]
;     '---ymm14
;             |       ,---ymm7  s0[0xC0..=0xDF]
;             '---ymm12
;                     '---ymm8  s0[0xE0..=0xFF]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0xFF, ymm15
; compare the next 8 ywords of both strings
	vpcmpeqb ymm1, ymm1, [rsi+0x00]
	vpcmpeqb ymm2, ymm2, [rsi+0x20]
	vpcmpeqb ymm3, ymm3, [rsi+0x40]
	vpcmpeqb ymm4, ymm4, [rsi+0x60]
	vpcmpeqb ymm5, ymm5, [rsi+0x80]
	vpcmpeqb ymm6, ymm6, [rsi+0xA0]
	vpcmpeqb ymm7, ymm7, [rsi+0xC0]
	vpcmpeqb ymm8, ymm8, [rsi+0xE0]
; merge the 8 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm9,  ymm1,  ymm2
	vpminub ymm10, ymm3,  ymm4
	vpminub ymm11, ymm5,  ymm6
	vpminub ymm12, ymm7,  ymm8
	vpminub ymm13, ymm9,  ymm10
	vpminub ymm14, ymm11, ymm12
	vpminub ymm15, ymm13, ymm14
;                    ,----ymm1  vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
;             ,---ymm9
;             |      '----ymm2  vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
;     ,---ymm13
;     |       |       ,---ymm3  vpcmpeqb s0[0x40..=0x5F], s1[0x40..=0x5F]
;     |       '---ymm10
;     |               '---ymm4  vpcmpeqb s0[0x60..=0x7F], s1[0x60..=0x7F]
; ymm15
;     |               ,---ymm5  vpcmpeqb s0[0x80..=0x9F], s1[0x80..=0x9F]
;     |       ,---ymm11
;     |       |       '---ymm6  vpcmpeqb s0[0xA0..=0xBF], s1[0xA0..=0xBF]
;     '---ymm14
;             |       ,---ymm7  vpcmpeqb s0[0xC0..=0xDF], s1[0xC0..=0xDF]
;             '---ymm12
;                     '---ymm8  vpcmpeqb s0[0xE0..=0xFF], s1[0xE0..=0xFF]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0xFF, ymm15
; update the pointers
	add rdi, 8 * SIZEOF_YWORD
	add rsi, 8 * SIZEOF_YWORD
; repeat until either the next 8 ywords of the first string contain a null byte
; or the next 8 ywords of both strings differ
	jmp .check_the_next_8_ywords

align 16
.found_a_null_byte_between_the_indices_0x00_and_0xFF:
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x7F, ymm13

;found_a_null_byte_between_the_indices_0x80_and_0xFF
; compare the next 4 ywords of both strings
	vpcmpeqb ymm1, ymm1, [rsi+0x00]
	vpcmpeqb ymm2, ymm2, [rsi+0x20]
	vpcmpeqb ymm3, ymm3, [rsi+0x40]
	vpcmpeqb ymm4, ymm4, [rsi+0x60]
; merge the 4 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm9,  ymm1, ymm2
	vpminub ymm10, ymm3, ymm4
	vpminub ymm13, ymm9, ymm10
;            ,----ymm1 vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
;     ,---ymm9
;     |      '----ymm2 vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
; ymm13
;     |       ,---ymm3 vpcmpeqb s0[0x40..=0x5F], s1[0x40..=0x5F]
;     '---ymm10
;             '---ymm4 vpcmpeqb s0[0x60..=0x7F], s1[0x60..=0x7F]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x7F, ymm13
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x80_and_0xBF, ymm11

;found_a_null_byte_between_the_indices_0xC0_and_0xFF
; compare the next 2 ywords of both strings
	vpcmpeqb ymm5, ymm5, [rsi+0x80]
	vpcmpeqb ymm6, ymm6, [rsi+0xA0]
; merge the 2 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm11,  ymm5, ymm6
;     ,----ymm5 vpcmpeqb s0[0x80..=0x9F], s1[0x80..=0x9F]
; ymm11
;     '----ymm6 vpcmpeqb s0[0xA0..=0xBF], s1[0xA0..=0xBF]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x80_and_0xBF, ymm11
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0xC0_and_0xDF, ymm7

;found_a_null_byte_between_the_indices_0xE0_and_0xFF
; compare the next yword of both strings
	vpcmpeqb ymm7, ymm7, [rsi+0xC0]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0xC0_and_0xDF, ymm7
; figure out which oword contains the first null byte
	pcmpistri xmm8, [rsi+0xE0], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0xF0_and_0xFF

;found_a_null_byte_between_the_indices_0xE0_and_0xEF
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0xE0

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x7F:
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x3F, ymm9
;found_a_null_byte_between_the_indices_0x40_and_0x7F
; compare the next 2 ywords of both strings
	vpcmpeqb ymm1, ymm1, [rsi+0x00]
	vpcmpeqb ymm2, ymm2, [rsi+0x20]
; merge the 2 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm9,  ymm1, ymm2
;    ,----ymm1 vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
; ymm9
;    '----ymm2 vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x3F, ymm9
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x40_and_0x5F, ymm3

;found_a_null_byte_between_the_indices_0x60_and_0x7F
; compare the next yword of both strings
	vpcmpeqb ymm3, ymm3, [rsi+0x40]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x40_and_0x5F, ymm3
; figure out which oword contains the first null byte
	pcmpistri xmm4, [rsi+0x60], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x70_and_0x7F

;found_a_null_byte_between_the_indices_0x60_and_0x6F
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x60

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x3F:
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x1F, ymm1

;found_a_null_byte_between_the_indices_0x20_and_0x3F
; compare the next yword of both strings
	vpcmpeqb ymm1, ymm1, [rsi+0x00]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x1F, ymm1
; figure out which oword contains the first null byte
	pcmpistri xmm2, [rsi+0x20], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x30_and_0x3F

;found_a_null_byte_between_the_indices_0x20_and_0x2F
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x20

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x1F:
; figure out which oword contains the first null byte
	pcmpistri xmm1, [rsi+0x00], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x10_and_0x1F

;found_a_null_byte_between_the_indices_0x00_and_0x0F
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x00

align 16
.found_a_null_byte_between_the_indices_0x10_and_0x1F:
; put the upper bytes of ymm1 into xmm1
	vextracti128 xmm1, ymm1, 1
; compare the next oword of both strings
	pcmpistri xmm1, [rsi+0x10], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x10

align 16
.found_a_null_byte_between_the_indices_0x30_and_0x3F:
; put the upper bytes of ymm2 into xmm2
	vextracti128 xmm2, ymm2, 1
; compare the next oword of both strings
	pcmpistri xmm2, [rsi+0x30], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x30

align 16
.found_a_null_byte_between_the_indices_0x40_and_0x5F:
; figure out which oword contains the first null byte
	pcmpistri xmm3, [rsi+0x40], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x50_and_0x5F

;found_a_null_byte_between_the_indices_0x40_and_0x4F
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x40

align 16
.found_a_null_byte_between_the_indices_0x50_and_0x5F:
; put the upper bytes of ymm3 into xmm3
	vextracti128 xmm3, ymm3, 1
; compare the next oword of both strings
	pcmpistri xmm3, [rsi+0x50], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x50

align 16
.found_a_null_byte_between_the_indices_0x70_and_0x7F:
; put the upper bytes of ymm4 into xmm4
	vextracti128 xmm4, ymm4, 1
; compare the next oword of both strings
	pcmpistri xmm4, [rsi+0x70], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x70

.found_a_null_byte_between_the_indices_0x80_and_0xBF:
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x80_and_0x9F, ymm5

;found_a_null_byte_between_the_indices_0xA0_and_0xBF
; compare the next yword of both strings
	vpcmpeqb ymm5, ymm5, [rsi+0x80]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x80_and_0x9F, ymm5
; figure out which oword contains the first null byte
	pcmpistri xmm6, [rsi+0xA0], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0xB0_and_0xBF

;found_a_null_byte_between_the_indices_0xA0_and_0xAF
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0xA0

align 16
.found_a_null_byte_between_the_indices_0x80_and_0x9F:
; figure out which oword contains the first null byte
	pcmpistri xmm5, [rsi+0x80], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x90_and_0x9F

;found_a_null_byte_between_the_indices_0x80_and_0x8F
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x80

align 16
.found_a_null_byte_between_the_indices_0x90_and_0x9F:
; put the upper bytes of ymm5 into xmm5
	vextracti128 xmm5, ymm5, 1
; compare the next oword of both strings
	pcmpistri xmm5, [rsi+0x90], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x90

align 16
.found_a_null_byte_between_the_indices_0xB0_and_0xBF:
; put the upper bytes of ymm6 into xmm6
	vextracti128 xmm6, ymm6, 1
; compare the next oword of both strings
	pcmpistri xmm6, [rsi+0xB0], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0xB0

align 16
.found_a_null_byte_between_the_indices_0xC0_and_0xDF:
; figure out which oword contains the first null byte
	pcmpistri xmm7, [rsi+0xC0], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0xD0_and_0xDF

;found_a_null_byte_between_the_indices_0xC0_and_0xCF
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0xC0

align 16
.found_a_null_byte_between_the_indices_0xD0_and_0xDF:
; put the upper bytes of ymm7 into xmm7
	vextracti128 xmm7, ymm7, 1
; compare the next oword of both strings
	pcmpistri xmm7, [rsi+0xD0], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0xD0

align 16
.found_a_null_byte_between_the_indices_0xF0_and_0xFF:
; put the upper bytes of ymm8 into xmm8
	vextracti128 xmm8, ymm8, 1
; compare the next oword of both strings
	pcmpistri xmm8, [rsi+0xF0], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0xF0

align 16
.found_a_difference_between_the_indices_0x00_and_0xFF:
; figure out which yword contains the first mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x7F, ymm13

;found_a_difference_between_the_indices_0x80_and_0xFF
; figure out which yword contains the first mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x80_and_0xBF, ymm11

;found_a_difference_between_the_indices_0xC0_and_0xFF
; figure out which yword contains the first mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0xC0_and_0xDF, ymm7

;found_a_difference_between_the_indices_0xE0_and_0xFF
; load the yword of the first string that contains the mismatching byte
	vmovdqu ymm8, [rdi+0xE0]
; figure out which oword contains the first mismatching byte
	pcmpistri xmm8, [rsi+0xE0], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0xF0_and_0xFF

;found_a_difference_between_the_indices_0xE0_and_0xEF:
	RETURN_DIFF 0xE0

align 16
.found_a_difference_between_the_indices_0x00_and_0x7F:
; figure out which yword contains the first mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x3F, ymm9

;found_a_difference_between_the_indices_0x40_and_0x7F
; figure out which yword contains the first mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x40_and_0x5F, ymm3

;found_a_difference_between_the_indices_0x60_and_0x7F
; load the yword of the first string that contains the mismatching byte
	vmovdqu ymm4, [rdi+0x60]
; figure out which oword contains the first mismatching byte
	pcmpistri xmm4, [rsi+0x60], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x70_and_0x7F

;found_a_difference_between_the_indices_0x60_and_0x6F:
	RETURN_DIFF 0x60

align 16
.found_a_difference_between_the_indices_0x00_and_0x3F:
; figure out which yword contains the first mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x1F, ymm1

;found_a_difference_between_the_indices_0x20_and_0x3F
; load the yword of the first string that contains the mismatching byte
	vmovdqu ymm2, [rdi+0x20]
; figure out which oword contains the first mismatching byte
	pcmpistri xmm2, [rsi+0x20], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x30_and_0x3F

;found_a_difference_between_the_indices_0x20_and_0x2F
	RETURN_DIFF 0x20

align 16
.found_a_difference_between_the_indices_0x00_and_0x1F:
; load the yword of the first string that contains the mismatching byte
	vmovdqu ymm1, [rdi+0x00]
; figure out which oword contains the first mismatching byte
	pcmpistri xmm1, [rsi+0x00], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x10_and_0x1F

;found_a_difference_between_the_indices_0x00_and_0x0F
	RETURN_DIFF 0x00

align 16
.found_a_difference_between_the_indices_0x10_and_0x1F:
; put the upper bytes of ymm1 into xmm1
	vextracti128 xmm1, ymm1, 1
; compare the next oword of both strings
	pcmpistri xmm1, [rsi+0x10], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x10

align 16
.found_a_difference_between_the_indices_0x30_and_0x3F:
; put the upper bytes of ymm2 into xmm2
	vextracti128 xmm2, ymm2, 1
; compare the next oword of both strings
	pcmpistri xmm2, [rsi+0x30], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x30

align 16
.found_a_difference_between_the_indices_0x40_and_0x5F:
; load the yword of the first string that contains the mismatching byte
	vmovdqu ymm3, [rdi+0x40]
; figure out which oword contains the first mismatching byte
	pcmpistri xmm3, [rsi+0x40], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x50_and_0x5F

;found_a_difference_between_the_indices_0x40_and_0x4F
	RETURN_DIFF 0x40

align 16
.found_a_difference_between_the_indices_0x50_and_0x5F:
; put the upper bytes of ymm3 into xmm3
	vextracti128 xmm3, ymm3, 1
; compare the next oword of both strings
	pcmpistri xmm3, [rsi+0x50], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x50

align 16
.found_a_difference_between_the_indices_0x70_and_0x7F:
; put the upper bytes of ymm4 into xmm4
	vextracti128 xmm4, ymm4, 1
; compare the next oword of both strings
	pcmpistri xmm4, [rsi+0x70], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x70

align 16
.found_a_difference_between_the_indices_0x80_and_0xBF:
; figure out which yword contains the first mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x80_and_0x9F, ymm5

;found_a_difference_between_the_indices_0xA0_and_0xBF
; load the yword of the first string that contains the mismatching byte
	vmovdqu ymm6, [rdi+0xA0]
; figure out which oword contains the first mismatching byte
	pcmpistri xmm6, [rsi+0xA0], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0xB0_and_0xBF

;found_a_difference_between_the_indices_0xA0_and_0xAF
	RETURN_DIFF 0xA0

align 16
.found_a_difference_between_the_indices_0x80_and_0x9F:
; load the yword of the first string that contains the mismatching byte
	vmovdqu ymm5, [rdi+0x80]
; figure out which oword contains the first mismatching byte
	pcmpistri xmm5, [rsi+0x80], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x90_and_0x9F

;found_a_difference_between_the_indices_0x80_and_0x8F
	RETURN_DIFF 0x80

align 16
.found_a_difference_between_the_indices_0x90_and_0x9F:
; put the upper bytes of ymm5 into xmm5
	vextracti128 xmm5, ymm5, 1
; compare the next oword of both strings
	pcmpistri xmm5, [rsi+0x90], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x90

.found_a_difference_between_the_indices_0xB0_and_0xBF:
; put the upper bytes of ymm6 into xmm6
	vextracti128 xmm6, ymm6, 1
; compare the next oword of both strings
	pcmpistri xmm6, [rsi+0xB0], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0xB0

align 16
.found_a_difference_between_the_indices_0xC0_and_0xDF:
; load the yword of the first string that contains the mismatching byte
	vmovdqu ymm7, [rdi+0xC0]
; figure out which oword contains the first mismatching byte
	pcmpistri xmm7, [rsi+0xC0], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0xD0_and_0xDF

;found_a_difference_between_the_indices_0xC0_and_0xCF
	RETURN_DIFF 0xC0

align 16
.found_a_difference_between_the_indices_0xD0_and_0xDF:
; put the upper bytes of ymm7 into xmm7
	vextracti128 xmm7, ymm7, 1
; compare the next oword of both strings
	pcmpistri xmm7, [rsi+0xD0], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0xD0

align 16
.found_a_difference_between_the_indices_0xF0_and_0xFF:
; put the upper bytes of ymm8 into xmm8
	vextracti128 xmm8, ymm8, 1
; compare the next oword of both strings
	pcmpistri xmm8, [rsi+0xF0], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0xF0

align 16
.both_strings_completely_match:
	xor eax, eax
	CLEAN_RET
