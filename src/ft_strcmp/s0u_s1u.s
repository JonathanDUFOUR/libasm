global ft_strcmp_s0u_s1u: function

%use smartalign
ALIGNMODE p6

%define OWORD_SIZE 16
%define YWORD_SIZE 32

%define EQUAL_EACH        01000_b
%define NEGATIVE_POLARITY 10000_b

; Parameters
; %1: the label to jump to if the given YMM register contains a null byte.
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

; Parameters
; %1: the offset to apply to both pointers
;     before calculating the difference between the 1st mismatching bytes.
%macro RETURN_DIFF 1
	; calculate the difference between the 1st mismatching bytes
	movzx eax, byte [ rdi + %1 + rcx ]
	movzx ecx, byte [ rsi + %1 + rcx ]
	sub eax, ecx
	CLEAN_RET
%endmacro

section .text
; Compares two null-terminated strings.
;
; Parameters
; rdi: the address of the 1st string to compare. (assumed to be a valid address)
; rsi: the address of the 2nd string to compare. (assumed to be a valid address)
;
; Return
; eax:
; - zero if the strings are equal.
; - a negative value if the 1st string is less than the 2nd.
; - a positive value if the 1st string is greater than the 2nd.
align 16
ft_strcmp_s0u_s1u:
; preliminary initialization
	vpxor ymm0, ymm0, ymm0
align 16
.check_the_next_8_ywords:
; load the next 8 ywords of the 1st string
	vmovdqu ymm1, [ rdi + 0 * YWORD_SIZE ]
	vmovdqu ymm2, [ rdi + 1 * YWORD_SIZE ]
	vmovdqu ymm3, [ rdi + 2 * YWORD_SIZE ]
	vmovdqu ymm4, [ rdi + 3 * YWORD_SIZE ]
	vmovdqu ymm5, [ rdi + 4 * YWORD_SIZE ]
	vmovdqu ymm6, [ rdi + 5 * YWORD_SIZE ]
	vmovdqu ymm7, [ rdi + 6 * YWORD_SIZE ]
	vmovdqu ymm8, [ rdi + 7 * YWORD_SIZE ]
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

; check if the resulting yword contains a null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0xFF, ymm15
; compare the next 8 ywords of both strings
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	vpcmpeqb ymm2, ymm2, [ rsi + 1 * YWORD_SIZE ]
	vpcmpeqb ymm3, ymm3, [ rsi + 2 * YWORD_SIZE ]
	vpcmpeqb ymm4, ymm4, [ rsi + 3 * YWORD_SIZE ]
	vpcmpeqb ymm5, ymm5, [ rsi + 4 * YWORD_SIZE ]
	vpcmpeqb ymm6, ymm6, [ rsi + 5 * YWORD_SIZE ]
	vpcmpeqb ymm7, ymm7, [ rsi + 6 * YWORD_SIZE ]
	vpcmpeqb ymm8, ymm8, [ rsi + 7 * YWORD_SIZE ]
; merge the 8 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm9,  ymm1,  ymm2
	vpand ymm10, ymm3,  ymm4
	vpand ymm11, ymm5,  ymm6
	vpand ymm12, ymm7,  ymm8
	vpand ymm13, ymm9,  ymm10
	vpand ymm14, ymm11, ymm12
	vpand ymm15, ymm13, ymm14
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

; check if the resulting yword contains a null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0xFF, ymm15
; update the pointers
	add rdi, 8 * YWORD_SIZE
	add rsi, 8 * YWORD_SIZE
; repeat until either the next 8 ywords of the 1st string contain a null byte
; or the next 8 ywords of both strings differ
	jmp .check_the_next_8_ywords

align 16
.found_a_null_byte_between_the_indices_0x00_and_0xFF:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x7F, ymm13
;found_a_null_byte_between_the_indices_0x80_and_0xFF:
; compare the next 4 ywords of both strings
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	vpcmpeqb ymm2, ymm2, [ rsi + 1 * YWORD_SIZE ]
	vpcmpeqb ymm3, ymm3, [ rsi + 2 * YWORD_SIZE ]
	vpcmpeqb ymm4, ymm4, [ rsi + 3 * YWORD_SIZE ]
; merge the 4 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm9,  ymm1, ymm2
	vpand ymm10, ymm3, ymm4
	vpand ymm13, ymm9, ymm10
;            ,----ymm1 vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
;     ,---ymm9
;     |      '----ymm2 vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
; ymm13
;     |       ,---ymm3 vpcmpeqb s0[0x40..=0x5F], s1[0x40..=0x5F]
;     '---ymm10
;             '---ymm4 vpcmpeqb s0[0x60..=0x7F], s1[0x60..=0x7F]

; check if the resulting yword contains a null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x7F, ymm13
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x80_and_0xBF, ymm11
;found_a_null_byte_between_the_indices_0xC0_and_0xFF:
; compare the next 2 ywords of both strings
	vpcmpeqb ymm5, ymm5, [ rsi + 4 * YWORD_SIZE ]
	vpcmpeqb ymm6, ymm6, [ rsi + 5 * YWORD_SIZE ]
; merge the 2 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm11, ymm5, ymm6
;     ,----ymm5 vpcmpeqb s0[0x80..=0x9F], s1[0x80..=0x9F]
; ymm11
;     '----ymm6 vpcmpeqb s0[0xA0..=0xBF], s1[0xA0..=0xBF]

; check if the resulting yword contains a null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x80_and_0xBF, ymm11
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0xC0_and_0xDF, ymm7
;found_a_null_byte_between_the_indices_0xE0_and_0xFF:
; compare the next yword of both strings
	vpcmpeqb ymm7, ymm7, [ rsi + 6 * YWORD_SIZE ]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0xC0_and_0xDF, ymm7
; figure out which oword contains the 1st null byte
	pcmpistri xmm8, [ rsi + 14 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0xF0_and_0xFF
;found_a_null_byte_between_the_indices_0xE0_and_0xEF:
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0xE0

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x7F:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x3F, ymm9
;found_a_null_byte_between_the_indices_0x40_and_0x7F:
; compare the next 2 ywords of both strings
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	vpcmpeqb ymm2, ymm2, [ rsi + 1 * YWORD_SIZE ]
; merge the 2 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm9, ymm1, ymm2
;    ,----ymm1 vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
; ymm9
;    '----ymm2 vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]

; check if the resulting yword contains a null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x3F, ymm9
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x40_and_0x5F, ymm3
;found_a_null_byte_between_the_indices_0x60_and_0x7F:
; compare the next yword of both strings
	vpcmpeqb ymm3, ymm3, [ rsi + 2 * YWORD_SIZE ]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x40_and_0x5F, ymm3
; figure out which oword contains the 1st null byte
	pcmpistri xmm4, [ rsi + 6 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x70_and_0x7F
;found_a_null_byte_between_the_indices_0x60_and_0x6F:
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x60

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x3F:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x1F, ymm1
;found_a_null_byte_between_the_indices_0x20_and_0x3F:
; compare the next yword of both strings
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x1F, ymm1
; figure out which oword contains the 1st null byte
	pcmpistri xmm2, [ rsi + 2 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x30_and_0x3F
;found_a_null_byte_between_the_indices_0x20_and_0x2F:
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x20

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x1F:
; figure out which oword contains the 1st null byte
	pcmpistri xmm1, [ rsi + 0 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x10_and_0x1F
;found_a_null_byte_between_the_indices_0x00_and_0x0F:
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x00

align 16
.found_a_null_byte_between_the_indices_0x10_and_0x1F:
; put the upper bytes of ymm1 into xmm1
	vextracti128 xmm1, ymm1, 1
; compare the next oword of both strings
	pcmpistri xmm1, [ rsi + 1 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x10

align 16
.found_a_null_byte_between_the_indices_0x30_and_0x3F:
; put the upper bytes of ymm2 into xmm2
	vextracti128 xmm2, ymm2, 1
; compare the next oword of both strings
	pcmpistri xmm2, [ rsi + 3 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x30

align 16
.found_a_null_byte_between_the_indices_0x40_and_0x5F:
; figure out which oword contains the 1st null byte
	pcmpistri xmm3, [ rsi + 4 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x50_and_0x5F
;found_a_null_byte_between_the_indices_0x40_and_0x4F:
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x40

align 16
.found_a_null_byte_between_the_indices_0x50_and_0x5F:
; put the upper bytes of ymm3 into xmm3
	vextracti128 xmm3, ymm3, 1
; compare the next oword of both strings
	pcmpistri xmm3, [ rsi + 5 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x50

align 16
.found_a_null_byte_between_the_indices_0x70_and_0x7F:
; put the upper bytes of ymm4 into xmm4
	vextracti128 xmm4, ymm4, 1
; compare the next oword of both strings
	pcmpistri xmm4, [ rsi + 7 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x70

.found_a_null_byte_between_the_indices_0x80_and_0xBF:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x80_and_0x9F, ymm5
;found_a_null_byte_between_the_indices_0xA0_and_0xBF:
; compare the next yword of both strings
	vpcmpeqb ymm5, ymm5, [ rsi + 4 * YWORD_SIZE ]
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x80_and_0x9F, ymm5
; figure out which oword contains the 1st null byte
	pcmpistri xmm6, [ rsi + 10 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0xB0_and_0xBF
;found_a_null_byte_between_the_indices_0xA0_and_0xAF:
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0xA0

align 16
.found_a_null_byte_between_the_indices_0x80_and_0x9F:
; figure out which oword contains the 1st null byte
	pcmpistri xmm5, [ rsi + 8 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0x90_and_0x9F
;found_a_null_byte_between_the_indices_0x80_and_0x8F:
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0x80

align 16
.found_a_null_byte_between_the_indices_0x90_and_0x9F:
; put the upper bytes of ymm5 into xmm5
	vextracti128 xmm5, ymm5, 1
; compare the next oword of both strings
	pcmpistri xmm5, [ rsi + 9 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0x90

align 16
.found_a_null_byte_between_the_indices_0xB0_and_0xBF:
; put the upper bytes of ymm6 into xmm6
	vextracti128 xmm6, ymm6, 1
; compare the next oword of both strings
	pcmpistri xmm6, [ rsi + 11 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0xB0

align 16
.found_a_null_byte_between_the_indices_0xC0_and_0xDF:
; figure out which oword contains the 1st null byte
	pcmpistri xmm7, [ rsi + 12 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_null_byte_between_the_indices_0xD0_and_0xDF
;found_a_null_byte_between_the_indices_0xC0_and_0xCF:
; compare the next oword of both strings
	jnc .both_strings_completely_match
	RETURN_DIFF 0xC0

align 16
.found_a_null_byte_between_the_indices_0xD0_and_0xDF:
; put the upper bytes of ymm7 into xmm7
	vextracti128 xmm7, ymm7, 1
; compare the next oword of both strings
	pcmpistri xmm7, [ rsi + 13 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0xD0

align 16
.found_a_null_byte_between_the_indices_0xF0_and_0xFF:
; put the upper bytes of ymm8 into xmm8
	vextracti128 xmm8, ymm8, 1
; compare the next oword of both strings
	pcmpistri xmm8, [ rsi + 15 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	jnc .both_strings_completely_match
	RETURN_DIFF 0xF0

align 16
.found_a_difference_between_the_indices_0x00_and_0xFF:
; figure out which yword contains the 1st mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x7F, ymm13
;found_a_difference_between_the_indices_0x80_and_0xFF:
; figure out which yword contains the 1st mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x80_and_0xBF, ymm11
;found_a_difference_between_the_indices_0xC0_and_0xFF:
; figure out which yword contains the 1st mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0xC0_and_0xDF, ymm7
;found_a_difference_between_the_indices_0xE0_and_0xFF:
; load the yword of the 1st string that contains the mismatching byte
	vmovdqu ymm8, [ rdi + 7 * YWORD_SIZE ]
; figure out which oword contains the 1st mismatching byte
	pcmpistri xmm8, [ rsi + 14 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0xF0_and_0xFF
;found_a_difference_between_the_indices_0xE0_and_0xEF:
	RETURN_DIFF 0xE0

align 16
.found_a_difference_between_the_indices_0x00_and_0x7F:
; figure out which yword contains the 1st mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x3F, ymm9
;found_a_difference_between_the_indices_0x40_and_0x7F:
; figure out which yword contains the 1st mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x40_and_0x5F, ymm3
;found_a_difference_between_the_indices_0x60_and_0x7F:
; load the yword of the 1st string that contains the mismatching byte
	vmovdqu ymm4, [ rdi + 3 * YWORD_SIZE ]
; figure out which oword contains the 1st mismatching byte
	pcmpistri xmm4, [ rsi + 6 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x70_and_0x7F
;found_a_difference_between_the_indices_0x60_and_0x6F:
	RETURN_DIFF 0x60

align 16
.found_a_difference_between_the_indices_0x00_and_0x3F:
; figure out which yword contains the 1st mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x00_and_0x1F, ymm1
;found_a_difference_between_the_indices_0x20_and_0x3F:
; load the yword of the 1st string that contains the mismatching byte
	vmovdqu ymm2, [ rdi + 1 * YWORD_SIZE ]
; figure out which oword contains the 1st mismatching byte
	pcmpistri xmm2, [ rsi + 2 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x30_and_0x3F
;found_a_difference_between_the_indices_0x20_and_0x2F:
	RETURN_DIFF 0x20

align 16
.found_a_difference_between_the_indices_0x00_and_0x1F:
; load the yword of the 1st string that contains the mismatching byte
	vmovdqu ymm1, [ rdi + 0 * YWORD_SIZE ]
; figure out which oword contains the 1st mismatching byte
	pcmpistri xmm1, [ rsi + 0 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x10_and_0x1F
;found_a_difference_between_the_indices_0x00_and_0x0F:
	RETURN_DIFF 0x00

align 16
.found_a_difference_between_the_indices_0x10_and_0x1F:
; put the upper bytes of ymm1 into xmm1
	vextracti128 xmm1, ymm1, 1
; compare the next oword of both strings
	pcmpistri xmm1, [ rsi + 1 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x10

align 16
.found_a_difference_between_the_indices_0x30_and_0x3F:
; put the upper bytes of ymm2 into xmm2
	vextracti128 xmm2, ymm2, 1
; compare the next oword of both strings
	pcmpistri xmm2, [ rsi + 3 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x30

align 16
.found_a_difference_between_the_indices_0x40_and_0x5F:
; load the yword of the 1st string that contains the mismatching byte
	vmovdqu ymm3, [ rdi + 2 * YWORD_SIZE ]
; figure out which oword contains the 1st mismatching byte
	pcmpistri xmm3, [ rsi + 4 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x50_and_0x5F
;found_a_difference_between_the_indices_0x40_and_0x4F:
	RETURN_DIFF 0x40

align 16
.found_a_difference_between_the_indices_0x50_and_0x5F:
; put the upper bytes of ymm3 into xmm3
	vextracti128 xmm3, ymm3, 1
; compare the next oword of both strings
	pcmpistri xmm3, [ rsi + 5 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x50

align 16
.found_a_difference_between_the_indices_0x70_and_0x7F:
; put the upper bytes of ymm4 into xmm4
	vextracti128 xmm4, ymm4, 1
; compare the next oword of both strings
	pcmpistri xmm4, [ rsi + 7 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x70

align 16
.found_a_difference_between_the_indices_0x80_and_0xBF:
; figure out which yword contains the 1st mismatching byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_difference_between_the_indices_0x80_and_0x9F, ymm5
;found_a_difference_between_the_indices_0xA0_and_0xBF:
; load the yword of the 1st string that contains the mismatching byte
	vmovdqu ymm6, [ rdi + 5 * YWORD_SIZE ]
; figure out which oword contains the 1st mismatching byte
	pcmpistri xmm6, [ rsi + 10 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0xB0_and_0xBF
;found_a_difference_between_the_indices_0xA0_and_0xAF:
	RETURN_DIFF 0xA0

align 16
.found_a_difference_between_the_indices_0x80_and_0x9F:
; load the yword of the 1st string that contains the mismatching byte
	vmovdqu ymm5, [ rdi + 4 * YWORD_SIZE ]
; figure out which oword contains the 1st mismatching byte
	pcmpistri xmm5, [ rsi + 8 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0x90_and_0x9F
;found_a_difference_between_the_indices_0x80_and_0x8F:
	RETURN_DIFF 0x80

align 16
.found_a_difference_between_the_indices_0x90_and_0x9F:
; put the upper bytes of ymm5 into xmm5
	vextracti128 xmm5, ymm5, 1
; compare the next oword of both strings
	pcmpistri xmm5, [ rsi + 9 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0x90

.found_a_difference_between_the_indices_0xB0_and_0xBF:
; put the upper bytes of ymm6 into xmm6
	vextracti128 xmm6, ymm6, 1
; compare the next oword of both strings
	pcmpistri xmm6, [ rsi + 11 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0xB0

align 16
.found_a_difference_between_the_indices_0xC0_and_0xDF:
; load the yword of the 1st string that contains the mismatching byte
	vmovdqu ymm7, [ rdi + 6 * YWORD_SIZE ]
; figure out which oword contains the 1st mismatching byte
	pcmpistri xmm7, [ rsi + 12 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	ja .found_a_difference_between_the_indices_0xD0_and_0xDF
;found_a_difference_between_the_indices_0xC0_and_0xCF:
	RETURN_DIFF 0xC0

align 16
.found_a_difference_between_the_indices_0xD0_and_0xDF:
; put the upper bytes of ymm7 into xmm7
	vextracti128 xmm7, ymm7, 1
; compare the next oword of both strings
	pcmpistri xmm7, [ rsi + 13 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0xD0

align 16
.found_a_difference_between_the_indices_0xF0_and_0xFF:
; put the upper bytes of ymm8 into xmm8
	vextracti128 xmm8, ymm8, 1
; compare the next oword of both strings
	pcmpistri xmm8, [ rsi + 15 * OWORD_SIZE ], EQUAL_EACH + NEGATIVE_POLARITY
	RETURN_DIFF 0xF0

align 16
.both_strings_completely_match:
	xor eax, eax
	CLEAN_RET
