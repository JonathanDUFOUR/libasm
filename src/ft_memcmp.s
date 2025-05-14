global ft_memcmp: function

default rel

%use smartalign
ALIGNMODE p6

%define  BYTE_SIZE  1
%define  WORD_SIZE  2
%define DWORD_SIZE  4
%define QWORD_SIZE  8
%define OWORD_SIZE 16
%define YWORD_SIZE 32

%ifdef LITTLE_ENDIAN
%undef LITTLE_ENDIAN
%endif

%ifdef BIG_ENDIAN
%undef BIG_ENDIAN
%endif

%define    BIG_ENDIAN 0
%define LITTLE_ENDIAN 1

%ifndef BYTE_ORDER
%define BYTE_ORDER LITTLE_ENDIAN
%endif

; Parameters
; %1: the label to jump to if the given YMM register contains a null byte.
; %2: the YMM register to check.
%macro JUMP_IF_HAS_A_NULL_BYTE 2
	vpcmpeqb ymm15, ymm0, %2
	vptest ymm15, ymm15
	jnz %1
%endmacro

; Parameters
; %1: the offset to apply to both pointers
;     before calculating the difference between the first mismatching bytes.
; %2: the YMM register to extract the index of the first mismatching byte from.
%macro RETURN_DIFF 2
	vpmovmskb r8d, %2
	vzeroupper
	not r8d
; calculate the index of the first mismatching byte
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10d, r8d
%else
	bsf r10d, r8d
%endif
; load the first mismatching byte of both memory areas
	movzx eax, byte [ rdi + %1 + r10 ]
	movzx ecx, byte [ rsi + %1 + r10 ]
; return the difference
	sub eax, ecx
	ret
%endmacro

%macro COMPARE_TAIL 0
; load the tail of the 1st memory area
	vmovdqu ymm0, [ rdi + rdx ]
; compare it with the tail of the 2nd memory area
	vpcmpeqb ymm0, ymm0, [ rsi + rdx ]
	vpmovmskb r8d, ymm0
	not r8d
; calculate the index of the first mismatching byte in the tail if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10d, r8d
%else
	bsf r10d, r8d
%endif
	jnz .calculate_and_return_diff
	ret
%endmacro

section .text
; Compares two memory area.
;
; Parameters
; rdi: the address of the 1st memory area to compare. (assumed to be a valid address)
; rsi: the address of the 2nd memory area to compare. (assumed to be a valid address)
; rdx: the number of bytes to compare.
;
; Return:
; eax:
; - zero if the memory areas are equal.
; - a negative value if the 1st memory area is less than the 2nd.
; - a positive value if the 1st memory area is greater than the 2nd.
align 16
ft_memcmp:
; preliminary initialization
	xor rax, rax
	xor r10, r10
; check if we can do a small comparison
	cmp rdx, 2 * YWORD_SIZE
	jbe .small_comparison
; load the first yword of the 1st memory area
	vmovdqu ymm0, [ rdi ]
; compare it with the first yword of the 2nd memory area
	vpcmpeqb ymm0, ymm0, [ rsi ]
	vpmovmskb r8, ymm0
	not r8d
; calculate the index of the first mismatching byte in the head if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10d, r8d
%else
	bsf r10d, r8d
%endif
	cmovnz rdx, rax
	jnz .calculate_and_return_diff
; initialize utility YMM registers
	vpxor ymm0, ymm0, ymm0
; calculate how far the 1st memory area is from its next yword boundary
	mov rcx, rdi
	neg rcx
	and rcx, YWORD_SIZE - 1
; advance both pointers by the calculated distance
	add rdi, rcx
	add rsi, rcx
; update the number of bytes to compare
	sub rdx, rcx
align 16
.compare_next_8_ywords:
; update the number of bytes to compare
	sub rdx, 8 * YWORD_SIZE
	jc .compare_less_than_8_ywords
; load the next 8 ywords of the 1st memory area
	vmovdqa ymm1, [ rdi + 0 * YWORD_SIZE ]
	vmovdqa ymm2, [ rdi + 1 * YWORD_SIZE ]
	vmovdqa ymm3, [ rdi + 2 * YWORD_SIZE ]
	vmovdqa ymm4, [ rdi + 3 * YWORD_SIZE ]
	vmovdqa ymm5, [ rdi + 4 * YWORD_SIZE ]
	vmovdqa ymm6, [ rdi + 5 * YWORD_SIZE ]
	vmovdqa ymm7, [ rdi + 6 * YWORD_SIZE ]
	vmovdqa ymm8, [ rdi + 7 * YWORD_SIZE ]
; compare them with the next 8 ywords of the 2nd memory areas
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
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0xFF, ymm15
; update the pointers
	add rdi, 8 * YWORD_SIZE
	add rsi, 8 * YWORD_SIZE
; repeat until either the next 8 ywords of both memory areas differ
; or the number of bytes to compare is less than 8 ywords
	jmp .compare_next_8_ywords

align 16
.compare_less_than_8_ywords:
	add rdx, 7 * YWORD_SIZE
; calculate how many intermediate ywords remain to be compared
	lea r10, [ .last_comparisons_jump_table ]
	lea r11, [ rdx + YWORD_SIZE ]
	shr r11, 5 ; divide by YWORD_SIZE
	jmp [ r10 + r11 * QWORD_SIZE ]

align 16
.small_comparison:
	cmp dl, YWORD_SIZE
	jae .compare_using_2_ywords
	cmp dl, OWORD_SIZE
	jae .compare_using_2_owords
	cmp dl, QWORD_SIZE
	jae .compare_using_2_qwords
	cmp dl, DWORD_SIZE
	jae .compare_using_2_dwords
	cmp dl, WORD_SIZE
	jae .compare_using_2_words
	cmp dl, BYTE_SIZE
	cmove dx, ax
	je .calculate_and_return_diff
	ret

align 16
.compare_using_2_ywords:
	sub dl, YWORD_SIZE
; load the head and tail of the 1st memory area
	vmovdqu ymm0, [ rdi ]
	vmovdqu ymm1, [ rdi + rdx ]
; compare them with those of the 2nd memory area
	vpcmpeqb ymm0, ymm0, [ rsi ]
	vpcmpeqb ymm1, ymm1, [ rsi + rdx ]
	vpmovmskb r8d, ymm0
	vpmovmskb r9d, ymm1
	vzeroupper
	not r8d
	not r9d
; calculate the index of the first mismatching byte in the head if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10d, r8d
%else
	bsf r10d, r8d
%endif
	cmovnz dx, ax
	jnz .calculate_and_return_diff
; calculate the index of the first mismatching byte in the tail if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10d, r9d
%else
	bsf r10d, r9d
%endif
	jnz .calculate_and_return_diff
	ret

align 16
.compare_using_2_owords:
	sub dl, OWORD_SIZE
; load the head and tail of the 1st memory area
	vmovdqu xmm0, [ rdi ]
	vmovdqu xmm1, [ rdi + rdx ]
; compare them with those of the 2nd memory area
	vpcmpeqb xmm0, [ rsi ]
	vpcmpeqb xmm1, [ rsi + rdx ]
	vpmovmskb r8, xmm0
	vpmovmskb r9, xmm1
	not r8w
	not r9w
; calculate the index of the first mismatching byte in the head if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10w, r8w
%else
	bsf r10w, r8w
%endif
	cmovnz dx, ax
	jnz .calculate_and_return_diff
; calculate the index of the first mismatching byte in the tail if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10w, r9w
%else
	bsf r10w, r9w
%endif
	jnz .calculate_and_return_diff
	ret

align 16
.compare_using_2_qwords:
	sub dl, QWORD_SIZE
	mov rcx, 3
; load the head and tail of the 1st memory area
	mov r8, [ rdi ]
	mov r9, [ rdi + rdx ]
; compare them with the those of the 2nd memory area
	xor r8, [ rsi ]
	xor r9, [ rsi + rdx ]
; calculate the index of the first mismatching byte in the head if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10, r8
%else
	bsf r10, r8
%endif
	shrx r10, r10, rcx ; `rcx` is 3 => divide by 8
	cmovnz dx, ax
	jnz .calculate_and_return_diff
; calculate the index of the first mismatching byte in the tail if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10, r9
%else
	bsf r10, r9
%endif
	shrx r10, r10, rcx ; `rcx` is 3 => divide by 8
	jnz .calculate_and_return_diff
	ret

align 16
.compare_using_2_dwords:
	sub dl, DWORD_SIZE
	mov rcx, 3
; load the head and tail of the 1st memory area
	mov r8d, [ rdi ]
	mov r9d, [ rdi + rdx ]
; compare them with the those of the 2nd memory area
	xor r8d, [ rsi ]
	xor r9d, [ rsi + rdx ]
; calculate the index of the first mismatching byte in the head if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10d, r8d
%else
	bsf r10d, r8d
%endif
	shrx r10, r10, rcx ; `rcx` is 3 => divide by 8
	cmovnz dx, ax
	jnz .calculate_and_return_diff
; calculate the index of the first mismatching byte in the tail if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10d, r9d
%else
	bsf r10d, r9d
%endif
	shrx r10, r10, rcx ; `rcx` is 3 => divide by 8
	jnz .calculate_and_return_diff
	ret

align 16
.compare_using_2_words:
	sub dl, WORD_SIZE
	mov rcx, 3
; load the head and tail of the 1st memory area
	mov r8w, [ rdi ]
	mov r9w, [ rdi + rdx ]
; compare them with the those of the 2nd memory area
	xor r8w, [ rsi ]
	xor r9w, [ rsi + rdx ]
; calculate the index of the first mismatching byte in the head if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10w, r8w
%else
	bsf r10w, r8w
%endif
	shrx r10, r10, rcx ; `rcx` is 3 => divide by 8
	cmovnz dx, ax
	jnz .calculate_and_return_diff
; calculate the index of the first mismatching byte in the tail if any
%if BYTE_ORDER == BIG_ENDIAN
	bsr r10w, r9w
%else
	bsf r10w, r9w
%endif
	shrx r10, r10, rcx ; `rcx` is 3 => divide by 8
	jnz .calculate_and_return_diff
	ret

align 16
.calculate_and_return_diff:
	add rdx, r10
; load the first mismatching byte of both memory areas
	movzx eax, byte [ rdi + rdx ]
	movzx ecx, byte [ rsi + rdx ]
; return the difference
	sub eax, ecx
	ret

align 16
.found_diff_in_0x00_0xFF:
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x7F, ymm13
;found_diff_in_0x80_0xFF
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x80_0xBF, ymm11
;found_diff_in_0xC0_0xFF
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0xC0_0xDF, ymm7
;found_diff_in_0xE0_0xFF
	RETURN_DIFF 0xE0, ymm8

align 16
.found_diff_in_0x00_0x7F:
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x3F, ymm9
;found_diff_in_0x40_0x7F:
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x40_0x5F, ymm3
;found_diff_in_0x60_0x7F:
	RETURN_DIFF 0x60, ymm4

align 16
.found_diff_in_0x00_0x3F:
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x1F, ymm1
;found_diff_in_0x20_0x3F:
	RETURN_DIFF 0x20, ymm2

align 16
.found_diff_in_0x00_0x1F:
	RETURN_DIFF 0x00, ymm1

align 16
.found_diff_in_0x40_0x5F:
	RETURN_DIFF 0x40, ymm3

align 16
.found_diff_in_0x80_0xBF:
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x80_0x9F, ymm5
;found_diff_in_0xA0_0xBF:
	RETURN_DIFF 0xA0, ymm6

align 16
.found_diff_in_0x80_0x9F:
	RETURN_DIFF 0x80, ymm5

align 16
.found_diff_in_0xC0_0xDF:
	RETURN_DIFF 0xC0, ymm7

align 16
.compare_0_intermediate_ywords_then_tail:
	COMPARE_TAIL

align 16
.compare_1_intermediate_yword_then_tail:
; load the next 1 yword of the 1st memory area
	vmovdqa ymm1, [ rdi ]
; compare it with the next 1 yword of the 2nd memory area
	vpcmpeqb ymm1, ymm1, [ rsi ]
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x1F, ymm1
	COMPARE_TAIL

align 16
.compare_2_intermediate_ywords_then_tail:
; load the next 2 ywords of the 1st memory area
	vmovdqa ymm1, [ rdi + 0 * YWORD_SIZE ]
	vmovdqa ymm2, [ rdi + 1 * YWORD_SIZE ]
; compare them with the next 2 ywords of the 2nd memory area
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	vpcmpeqb ymm2, ymm2, [ rsi + 1 * YWORD_SIZE ]
; merge the 2 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm9, ymm1, ymm2
;    ,---ymm1  vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
; ymm9
;    '---ymm2  vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x3F, ymm9
	COMPARE_TAIL

align 16
.compare_3_intermediate_ywords_then_tail:
; load the next 3 ywords of the 1st memory area
	vmovdqa ymm1, [ rdi + 0 * YWORD_SIZE ]
	vmovdqa ymm2, [ rdi + 1 * YWORD_SIZE ]
	vmovdqa ymm3, [ rdi + 2 * YWORD_SIZE ]
; compare them with the next 3 ywords of the 2nd memory area
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	vpcmpeqb ymm2, ymm2, [ rsi + 1 * YWORD_SIZE ]
	vpcmpeqb ymm3, ymm3, [ rsi + 2 * YWORD_SIZE ]
; merge the first 2 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm9, ymm1, ymm2
;    ,---ymm1  vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
; ymm9
;    '---ymm2  vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x3F, ymm9
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x40_0x5F, ymm3
	COMPARE_TAIL

align 16
.compare_4_intermediate_ywords_then_tail:
; load the next 4 ywords of the 1st memory area
	vmovdqa ymm1, [ rdi + 0 * YWORD_SIZE ]
	vmovdqa ymm2, [ rdi + 1 * YWORD_SIZE ]
	vmovdqa ymm3, [ rdi + 2 * YWORD_SIZE ]
	vmovdqa ymm4, [ rdi + 3 * YWORD_SIZE ]
; compare them with the next 4 ywords of the 2nd memory area
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	vpcmpeqb ymm2, ymm2, [ rsi + 1 * YWORD_SIZE ]
	vpcmpeqb ymm3, ymm3, [ rsi + 2 * YWORD_SIZE ]
	vpcmpeqb ymm4, ymm4, [ rsi + 3 * YWORD_SIZE ]
; merge the 4 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm9,  ymm1, ymm2
	vpand ymm10, ymm3, ymm4
	vpand ymm13, ymm9, ymm10
;            ,----ymm1  vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
;     ,---ymm9
;     |      '----ymm2  vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
; ymm13
;     |       ,---ymm3  vpcmpeqb s0[0x40..=0x5F], s1[0x40..=0x5F]
;     '---ymm10
;             '---ymm4  vpcmpeqb s0[0x60..=0x7F], s1[0x60..=0x7F]
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x7F, ymm13
	COMPARE_TAIL

align 16
.compare_5_intermediate_ywords_then_tail:
; load the next 5 ywords of the 1st memory area
	vmovdqa ymm1, [ rdi + 0 * YWORD_SIZE ]
	vmovdqa ymm2, [ rdi + 1 * YWORD_SIZE ]
	vmovdqa ymm3, [ rdi + 2 * YWORD_SIZE ]
	vmovdqa ymm4, [ rdi + 3 * YWORD_SIZE ]
	vmovdqa ymm5, [ rdi + 4 * YWORD_SIZE ]
; compare them with the next 5 ywords of the 2nd memory area
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	vpcmpeqb ymm2, ymm2, [ rsi + 1 * YWORD_SIZE ]
	vpcmpeqb ymm3, ymm3, [ rsi + 2 * YWORD_SIZE ]
	vpcmpeqb ymm4, ymm4, [ rsi + 3 * YWORD_SIZE ]
	vpcmpeqb ymm5, ymm5, [ rsi + 4 * YWORD_SIZE ]
; merge the first 4 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm9,  ymm1, ymm2
	vpand ymm10, ymm3, ymm4
	vpand ymm13, ymm9, ymm10
;            ,----ymm1  vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
;     ,---ymm9
;     |      '----ymm2  vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
; ymm13
;     |       ,---ymm3  vpcmpeqb s0[0x40..=0x5F], s1[0x40..=0x5F]
;     '---ymm10
;             '---ymm4  vpcmpeqb s0[0x60..=0x7F], s1[0x60..=0x7F]
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x7F, ymm13
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x80_0x9F, ymm5
	COMPARE_TAIL

align 16
.compare_6_intermediate_ywords_then_tail:
; load the next 6 ywords of the 1st memory area
	vmovdqa ymm1, [ rdi + 0 * YWORD_SIZE ]
	vmovdqa ymm2, [ rdi + 1 * YWORD_SIZE ]
	vmovdqa ymm3, [ rdi + 2 * YWORD_SIZE ]
	vmovdqa ymm4, [ rdi + 3 * YWORD_SIZE ]
	vmovdqa ymm5, [ rdi + 4 * YWORD_SIZE ]
	vmovdqa ymm6, [ rdi + 5 * YWORD_SIZE ]
; compare them with the next 6 ywords of the 2nd memory area
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	vpcmpeqb ymm2, ymm2, [ rsi + 1 * YWORD_SIZE ]
	vpcmpeqb ymm3, ymm3, [ rsi + 2 * YWORD_SIZE ]
	vpcmpeqb ymm4, ymm4, [ rsi + 3 * YWORD_SIZE ]
	vpcmpeqb ymm5, ymm5, [ rsi + 4 * YWORD_SIZE ]
	vpcmpeqb ymm6, ymm6, [ rsi + 5 * YWORD_SIZE ]
; merge the 6 ywords into 2 ywords that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm9,  ymm1, ymm2
	vpand ymm10, ymm3, ymm4
	vpand ymm11, ymm5, ymm6
	vpand ymm13, ymm9, ymm10
;            ,----ymm1  vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
;     ,---ymm9
;     |      '----ymm2  vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
; ymm13
;     |       ,---ymm3  vpcmpeqb s0[0x40..=0x5F], s1[0x40..=0x5F]
;     '---ymm10
;             '---ymm4  vpcmpeqb s0[0x60..=0x7F], s1[0x60..=0x7F]
;
;             ,---ymm5  vpcmpeqb s0[0x80..=0x9F], s1[0x80..=0x9F]
;         ymm11
;             '---ymm6  vpcmpeqb s0[0xA0..=0xBF], s1[0xA0..=0xBF]
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x7F, ymm13
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x80_0xBF, ymm11
	COMPARE_TAIL

align 16
.compare_7_intermediate_ywords_then_tail:
; load the next 7 ywords of the 1st memory area
	vmovdqa ymm1, [ rdi + 0 * YWORD_SIZE ]
	vmovdqa ymm2, [ rdi + 1 * YWORD_SIZE ]
	vmovdqa ymm3, [ rdi + 2 * YWORD_SIZE ]
	vmovdqa ymm4, [ rdi + 3 * YWORD_SIZE ]
	vmovdqa ymm5, [ rdi + 4 * YWORD_SIZE ]
	vmovdqa ymm6, [ rdi + 5 * YWORD_SIZE ]
	vmovdqa ymm7, [ rdi + 6 * YWORD_SIZE ]
; compare them with the next 7 ywords of the 2nd memory area
	vpcmpeqb ymm1, ymm1, [ rsi + 0 * YWORD_SIZE ]
	vpcmpeqb ymm2, ymm2, [ rsi + 1 * YWORD_SIZE ]
	vpcmpeqb ymm3, ymm3, [ rsi + 2 * YWORD_SIZE ]
	vpcmpeqb ymm4, ymm4, [ rsi + 3 * YWORD_SIZE ]
	vpcmpeqb ymm5, ymm5, [ rsi + 4 * YWORD_SIZE ]
	vpcmpeqb ymm6, ymm6, [ rsi + 5 * YWORD_SIZE ]
	vpcmpeqb ymm7, ymm7, [ rsi + 6 * YWORD_SIZE ]
; merge the first 6 ywords into 2 ywords that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpand ymm9,  ymm1, ymm2
	vpand ymm10, ymm3, ymm4
	vpand ymm11, ymm5, ymm6
	vpand ymm13, ymm9, ymm10
;            ,----ymm1  vpcmpeqb s0[0x00..=0x1F], s1[0x00..=0x1F]
;     ,---ymm9
;     |      '----ymm2  vpcmpeqb s0[0x20..=0x3F], s1[0x20..=0x3F]
; ymm13
;     |       ,---ymm3  vpcmpeqb s0[0x40..=0x5F], s1[0x40..=0x5F]
;     '---ymm10
;             '---ymm4  vpcmpeqb s0[0x60..=0x7F], s1[0x60..=0x7F]
;
;             ,---ymm5  vpcmpeqb s0[0x80..=0x9F], s1[0x80..=0x9F]
;         ymm11
;             '---ymm6  vpcmpeqb s0[0xA0..=0xBF], s1[0xA0..=0xBF]
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x00_0x7F, ymm13
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0x80_0xBF, ymm11
	JUMP_IF_HAS_A_NULL_BYTE .found_diff_in_0xC0_0xDF, ymm7
	COMPARE_TAIL

section .rodata
.last_comparisons_jump_table:
	dq .compare_0_intermediate_ywords_then_tail
	dq .compare_1_intermediate_yword_then_tail
	dq .compare_2_intermediate_ywords_then_tail
	dq .compare_3_intermediate_ywords_then_tail
	dq .compare_4_intermediate_ywords_then_tail
	dq .compare_5_intermediate_ywords_then_tail
	dq .compare_6_intermediate_ywords_then_tail
	dq .compare_7_intermediate_ywords_then_tail
