global ft_memcpy: function

default rel

%use smartalign
ALIGNMODE p6

%define  BYTE_SIZE  1
%define  WORD_SIZE  2
%define DWORD_SIZE  4
%define QWORD_SIZE  8
%define OWORD_SIZE 16
%define YWORD_SIZE 32

%macro VZEROUPPER_RET 0
	vzeroupper
	ret
%endmacro

%macro COPY_FIRST_AND_LAST_YWORD_AND_ALIGN_DESTINATION_POINTER 0
; copy the first and the last yword
	sub rdx, YWORD_SIZE ; corresponds to the last yword that is about to be copied
	vmovdqu ymm0, [ rsi ]
	vmovdqu ymm1, [ rsi + rdx ]
	vmovdqu [ rdi ], ymm0
	vmovdqu [ rdi + rdx ], ymm1
; calculate how far the destination area is from its next yword boundary
	mov rcx, rdi
	neg rcx
	and rcx, YWORD_SIZE - 1
; advance both pointers by the calculated distance
	add rdi, rcx
	add rsi, rcx
; update the number of bytes to copy
	sub rdx, rcx
%endmacro

section .text
; Copies N bytes from a memory area to another.
; The memory areas are assumed to not overlap.
;
; Parameters
; rdi: the address of the destination memory area. (assumed to be a valid address)
; rsi: the address of the source memory area. (assumed to be a valid address)
; rdx: the number of bytes to copy.
;
; Return:
; rax: the address of the destination memory area.
align 16
ft_memcpy:
; preliminary initialization
	mov rax, rdi
; check if we can do a small copy
	cmp rdx, YWORD_SIZE * 2 + 1
	jb .copy_less_than_65_bytes
	COPY_FIRST_AND_LAST_YWORD_AND_ALIGN_DESTINATION_POINTER
.copy_next_16_intermediate_ywords:
; update the number of intermediate bytes to copy
	sub rdx, YWORD_SIZE * 16
	jc .copy_less_than_16_intermediate_ywords
; load the next 16 intermediate ywords from the source memory area
	vmovdqu ymm0,  [ rsi + YWORD_SIZE *  0 ]
	vmovdqu ymm1,  [ rsi + YWORD_SIZE *  1 ]
	vmovdqu ymm2,  [ rsi + YWORD_SIZE *  2 ]
	vmovdqu ymm3,  [ rsi + YWORD_SIZE *  3 ]
	vmovdqu ymm4,  [ rsi + YWORD_SIZE *  4 ]
	vmovdqu ymm5,  [ rsi + YWORD_SIZE *  5 ]
	vmovdqu ymm6,  [ rsi + YWORD_SIZE *  6 ]
	vmovdqu ymm7,  [ rsi + YWORD_SIZE *  7 ]
	vmovdqu ymm8,  [ rsi + YWORD_SIZE *  8 ]
	vmovdqu ymm9,  [ rsi + YWORD_SIZE *  9 ]
	vmovdqu ymm10, [ rsi + YWORD_SIZE * 10 ]
	vmovdqu ymm11, [ rsi + YWORD_SIZE * 11 ]
	vmovdqu ymm12, [ rsi + YWORD_SIZE * 12 ]
	vmovdqu ymm13, [ rsi + YWORD_SIZE * 13 ]
	vmovdqu ymm14, [ rsi + YWORD_SIZE * 14 ]
	vmovdqu ymm15, [ rsi + YWORD_SIZE * 15 ]
; store the next 16 intermediate ywords to the destination memory area
	vmovdqa [ rdi + YWORD_SIZE *  0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE *  1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE *  2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE *  3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE *  4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE *  5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE *  6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE *  7 ], ymm7
	vmovdqa [ rdi + YWORD_SIZE *  8 ], ymm8
	vmovdqa [ rdi + YWORD_SIZE *  9 ], ymm9
	vmovdqa [ rdi + YWORD_SIZE * 10 ], ymm10
	vmovdqa [ rdi + YWORD_SIZE * 11 ], ymm11
	vmovdqa [ rdi + YWORD_SIZE * 12 ], ymm12
	vmovdqa [ rdi + YWORD_SIZE * 13 ], ymm13
	vmovdqa [ rdi + YWORD_SIZE * 14 ], ymm14
	vmovdqa [ rdi + YWORD_SIZE * 15 ], ymm15
; update the pointers
	add rdi, YWORD_SIZE * 16
	add rsi, YWORD_SIZE * 16
; repeat until there are less than 16 intermediate ywords to copy
	jmp .copy_next_16_intermediate_ywords

align 16
.copy_less_than_16_intermediate_ywords:
; calculate how many intermediate ywords remain to be copied
	add rdx, YWORD_SIZE * 16
	shr rdx, 5 ; divide by YWORD_SIZE
; copy the remaining intermediate ywords
	lea rcx, [ .intermediate_yword_copy_jump_table ]
	jmp [ rcx + rdx * QWORD_SIZE ]

align 16
.copy_less_than_65_bytes:
	cmp edx, 32
	ja .copy_between_33_and_64_bytes
	cmp edx, 16
	ja .copy_between_17_and_32_bytes
	cmp edx, 8
	ja .copy_between_9_and_16_bytes
	cmp edx, 4
	ja .copy_between_5_and_8_bytes
	cmp edx, 2
	ja .copy_between_3_and_4_bytes
	test edx, edx
	jnz .copy_between_1_and_2_bytes
	ret

align 16
.copy_between_1_and_2_bytes:
	mov cl, [ rsi ]
	mov sil, [ rsi + rdx - BYTE_SIZE ]
	mov [ rdi ], cl
	mov [ rdi + rdx - BYTE_SIZE ], sil
	ret

align 16
.copy_between_3_and_4_bytes:
	mov cx, [ rsi ]
	mov si, [ rsi + rdx - WORD_SIZE ]
	mov [ rdi ], cx
	mov [ rdi + rdx - WORD_SIZE ], si
	ret

align 16
.copy_between_5_and_8_bytes:
	mov ecx, [ rsi ]
	mov esi, [ rsi + rdx - DWORD_SIZE ]
	mov [ rdi ], ecx
	mov [ rdi + rdx - DWORD_SIZE ], esi
	ret

align 16
.copy_between_9_and_16_bytes:
	mov rcx, [ rsi ]
	mov rsi, [ rsi + rdx - QWORD_SIZE ]
	mov [ rdi ], rcx
	mov [ rdi + rdx - QWORD_SIZE ], rsi
	ret

align 16
.copy_between_17_and_32_bytes:
	movdqu xmm0, [ rsi ]
	movdqu xmm1, [ rsi + rdx - OWORD_SIZE ]
	movdqu [ rdi ], xmm0
	movdqu [ rdi + rdx - OWORD_SIZE ], xmm1
	ret

align 16
.copy_between_33_and_64_bytes:
	vmovdqu ymm0, [ rsi ]
	vmovdqu ymm1, [ rsi + rdx - YWORD_SIZE ]
	vmovdqu [ rdi ], ymm0
	vmovdqu [ rdi + rdx - YWORD_SIZE ], ymm1
	VZEROUPPER_RET

align 16
.copy_1_yword:
	vmovdqu ymm0, [ rsi ]
	vmovdqa [ rdi ], ymm0
	VZEROUPPER_RET

align 16
.copy_2_ywords:
	vmovdqu ymm0, [ rsi + YWORD_SIZE * 0 ]
	vmovdqu ymm1, [ rsi + YWORD_SIZE * 1 ]
	vmovdqa [ rdi + YWORD_SIZE * 0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE * 1 ], ymm1
	VZEROUPPER_RET

align 16
.copy_3_ywords:
	vmovdqu ymm0, [ rsi + YWORD_SIZE * 0 ]
	vmovdqu ymm1, [ rsi + YWORD_SIZE * 1 ]
	vmovdqu ymm2, [ rsi + YWORD_SIZE * 2 ]
	vmovdqa [ rdi + YWORD_SIZE * 0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE * 1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE * 2 ], ymm2
	VZEROUPPER_RET

align 16
.copy_4_ywords:
	vmovdqu ymm0, [ rsi + YWORD_SIZE * 0 ]
	vmovdqu ymm1, [ rsi + YWORD_SIZE * 1 ]
	vmovdqu ymm2, [ rsi + YWORD_SIZE * 2 ]
	vmovdqu ymm3, [ rsi + YWORD_SIZE * 3 ]
	vmovdqa [ rdi + YWORD_SIZE * 0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE * 1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE * 2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE * 3 ], ymm3
	VZEROUPPER_RET

align 16
.copy_5_ywords:
	vmovdqu ymm0, [ rsi + YWORD_SIZE * 0 ]
	vmovdqu ymm1, [ rsi + YWORD_SIZE * 1 ]
	vmovdqu ymm2, [ rsi + YWORD_SIZE * 2 ]
	vmovdqu ymm3, [ rsi + YWORD_SIZE * 3 ]
	vmovdqu ymm4, [ rsi + YWORD_SIZE * 4 ]
	vmovdqa [ rdi + YWORD_SIZE * 0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE * 1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE * 2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE * 3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE * 4 ], ymm4
	VZEROUPPER_RET

align 16
.copy_6_ywords:
	vmovdqu ymm0, [ rsi + YWORD_SIZE * 0 ]
	vmovdqu ymm1, [ rsi + YWORD_SIZE * 1 ]
	vmovdqu ymm2, [ rsi + YWORD_SIZE * 2 ]
	vmovdqu ymm3, [ rsi + YWORD_SIZE * 3 ]
	vmovdqu ymm4, [ rsi + YWORD_SIZE * 4 ]
	vmovdqu ymm5, [ rsi + YWORD_SIZE * 5 ]
	vmovdqa [ rdi + YWORD_SIZE * 0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE * 1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE * 2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE * 3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE * 4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE * 5 ], ymm5
	VZEROUPPER_RET

align 16
.copy_7_ywords:
	vmovdqu ymm0, [ rsi + YWORD_SIZE * 0 ]
	vmovdqu ymm1, [ rsi + YWORD_SIZE * 1 ]
	vmovdqu ymm2, [ rsi + YWORD_SIZE * 2 ]
	vmovdqu ymm3, [ rsi + YWORD_SIZE * 3 ]
	vmovdqu ymm4, [ rsi + YWORD_SIZE * 4 ]
	vmovdqu ymm5, [ rsi + YWORD_SIZE * 5 ]
	vmovdqu ymm6, [ rsi + YWORD_SIZE * 6 ]
	vmovdqa [ rdi + YWORD_SIZE * 0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE * 1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE * 2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE * 3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE * 4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE * 5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE * 6 ], ymm6
	VZEROUPPER_RET

align 16
.copy_8_ywords:
	vmovdqu ymm0, [ rsi + YWORD_SIZE * 0 ]
	vmovdqu ymm1, [ rsi + YWORD_SIZE * 1 ]
	vmovdqu ymm2, [ rsi + YWORD_SIZE * 2 ]
	vmovdqu ymm3, [ rsi + YWORD_SIZE * 3 ]
	vmovdqu ymm4, [ rsi + YWORD_SIZE * 4 ]
	vmovdqu ymm5, [ rsi + YWORD_SIZE * 5 ]
	vmovdqu ymm6, [ rsi + YWORD_SIZE * 6 ]
	vmovdqu ymm7, [ rsi + YWORD_SIZE * 7 ]
	vmovdqa [ rdi + YWORD_SIZE * 0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE * 1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE * 2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE * 3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE * 4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE * 5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE * 6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE * 7 ], ymm7
	VZEROUPPER_RET

align 16
.copy_9_ywords:
	vmovdqu ymm0, [ rsi + YWORD_SIZE * 0 ]
	vmovdqu ymm1, [ rsi + YWORD_SIZE * 1 ]
	vmovdqu ymm2, [ rsi + YWORD_SIZE * 2 ]
	vmovdqu ymm3, [ rsi + YWORD_SIZE * 3 ]
	vmovdqu ymm4, [ rsi + YWORD_SIZE * 4 ]
	vmovdqu ymm5, [ rsi + YWORD_SIZE * 5 ]
	vmovdqu ymm6, [ rsi + YWORD_SIZE * 6 ]
	vmovdqu ymm7, [ rsi + YWORD_SIZE * 7 ]
	vmovdqu ymm8, [ rsi + YWORD_SIZE * 8 ]
	vmovdqa [ rdi + YWORD_SIZE * 0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE * 1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE * 2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE * 3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE * 4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE * 5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE * 6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE * 7 ], ymm7
	vmovdqa [ rdi + YWORD_SIZE * 8 ], ymm8
	VZEROUPPER_RET

align 16
.copy_10_ywords:
	vmovdqu ymm0, [ rsi + YWORD_SIZE * 0 ]
	vmovdqu ymm1, [ rsi + YWORD_SIZE * 1 ]
	vmovdqu ymm2, [ rsi + YWORD_SIZE * 2 ]
	vmovdqu ymm3, [ rsi + YWORD_SIZE * 3 ]
	vmovdqu ymm4, [ rsi + YWORD_SIZE * 4 ]
	vmovdqu ymm5, [ rsi + YWORD_SIZE * 5 ]
	vmovdqu ymm6, [ rsi + YWORD_SIZE * 6 ]
	vmovdqu ymm7, [ rsi + YWORD_SIZE * 7 ]
	vmovdqu ymm8, [ rsi + YWORD_SIZE * 8 ]
	vmovdqu ymm9, [ rsi + YWORD_SIZE * 9 ]
	vmovdqa [ rdi + YWORD_SIZE * 0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE * 1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE * 2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE * 3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE * 4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE * 5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE * 6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE * 7 ], ymm7
	vmovdqa [ rdi + YWORD_SIZE * 8 ], ymm8
	vmovdqa [ rdi + YWORD_SIZE * 9 ], ymm9
	VZEROUPPER_RET

align 16
.copy_11_ywords:
	vmovdqu ymm0,  [ rsi + YWORD_SIZE *  0 ]
	vmovdqu ymm1,  [ rsi + YWORD_SIZE *  1 ]
	vmovdqu ymm2,  [ rsi + YWORD_SIZE *  2 ]
	vmovdqu ymm3,  [ rsi + YWORD_SIZE *  3 ]
	vmovdqu ymm4,  [ rsi + YWORD_SIZE *  4 ]
	vmovdqu ymm5,  [ rsi + YWORD_SIZE *  5 ]
	vmovdqu ymm6,  [ rsi + YWORD_SIZE *  6 ]
	vmovdqu ymm7,  [ rsi + YWORD_SIZE *  7 ]
	vmovdqu ymm8,  [ rsi + YWORD_SIZE *  8 ]
	vmovdqu ymm9,  [ rsi + YWORD_SIZE *  9 ]
	vmovdqu ymm10, [ rsi + YWORD_SIZE * 10 ]
	vmovdqa [ rdi + YWORD_SIZE *  0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE *  1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE *  2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE *  3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE *  4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE *  5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE *  6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE *  7 ], ymm7
	vmovdqa [ rdi + YWORD_SIZE *  8 ], ymm8
	vmovdqa [ rdi + YWORD_SIZE *  9 ], ymm9
	vmovdqa [ rdi + YWORD_SIZE * 10 ], ymm10
	VZEROUPPER_RET

align 16
.copy_12_ywords:
	vmovdqu ymm0,  [ rsi + YWORD_SIZE *  0 ]
	vmovdqu ymm1,  [ rsi + YWORD_SIZE *  1 ]
	vmovdqu ymm2,  [ rsi + YWORD_SIZE *  2 ]
	vmovdqu ymm3,  [ rsi + YWORD_SIZE *  3 ]
	vmovdqu ymm4,  [ rsi + YWORD_SIZE *  4 ]
	vmovdqu ymm5,  [ rsi + YWORD_SIZE *  5 ]
	vmovdqu ymm6,  [ rsi + YWORD_SIZE *  6 ]
	vmovdqu ymm7,  [ rsi + YWORD_SIZE *  7 ]
	vmovdqu ymm8,  [ rsi + YWORD_SIZE *  8 ]
	vmovdqu ymm9,  [ rsi + YWORD_SIZE *  9 ]
	vmovdqu ymm10, [ rsi + YWORD_SIZE * 10 ]
	vmovdqu ymm11, [ rsi + YWORD_SIZE * 11 ]
	vmovdqa [ rdi + YWORD_SIZE *  0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE *  1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE *  2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE *  3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE *  4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE *  5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE *  6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE *  7 ], ymm7
	vmovdqa [ rdi + YWORD_SIZE *  8 ], ymm8
	vmovdqa [ rdi + YWORD_SIZE *  9 ], ymm9
	vmovdqa [ rdi + YWORD_SIZE * 10 ], ymm10
	vmovdqa [ rdi + YWORD_SIZE * 11 ], ymm11
	VZEROUPPER_RET

align 16
.copy_13_ywords:
	vmovdqu ymm0,  [ rsi + YWORD_SIZE *  0 ]
	vmovdqu ymm1,  [ rsi + YWORD_SIZE *  1 ]
	vmovdqu ymm2,  [ rsi + YWORD_SIZE *  2 ]
	vmovdqu ymm3,  [ rsi + YWORD_SIZE *  3 ]
	vmovdqu ymm4,  [ rsi + YWORD_SIZE *  4 ]
	vmovdqu ymm5,  [ rsi + YWORD_SIZE *  5 ]
	vmovdqu ymm6,  [ rsi + YWORD_SIZE *  6 ]
	vmovdqu ymm7,  [ rsi + YWORD_SIZE *  7 ]
	vmovdqu ymm8,  [ rsi + YWORD_SIZE *  8 ]
	vmovdqu ymm9,  [ rsi + YWORD_SIZE *  9 ]
	vmovdqu ymm10, [ rsi + YWORD_SIZE * 10 ]
	vmovdqu ymm11, [ rsi + YWORD_SIZE * 11 ]
	vmovdqu ymm12, [ rsi + YWORD_SIZE * 12 ]
	vmovdqa [ rdi + YWORD_SIZE *  0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE *  1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE *  2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE *  3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE *  4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE *  5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE *  6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE *  7 ], ymm7
	vmovdqa [ rdi + YWORD_SIZE *  8 ], ymm8
	vmovdqa [ rdi + YWORD_SIZE *  9 ], ymm9
	vmovdqa [ rdi + YWORD_SIZE * 10 ], ymm10
	vmovdqa [ rdi + YWORD_SIZE * 11 ], ymm11
	vmovdqa [ rdi + YWORD_SIZE * 12 ], ymm12
	VZEROUPPER_RET

align 16
.copy_14_ywords:
	vmovdqu ymm0,  [ rsi + YWORD_SIZE *  0 ]
	vmovdqu ymm1,  [ rsi + YWORD_SIZE *  1 ]
	vmovdqu ymm2,  [ rsi + YWORD_SIZE *  2 ]
	vmovdqu ymm3,  [ rsi + YWORD_SIZE *  3 ]
	vmovdqu ymm4,  [ rsi + YWORD_SIZE *  4 ]
	vmovdqu ymm5,  [ rsi + YWORD_SIZE *  5 ]
	vmovdqu ymm6,  [ rsi + YWORD_SIZE *  6 ]
	vmovdqu ymm7,  [ rsi + YWORD_SIZE *  7 ]
	vmovdqu ymm8,  [ rsi + YWORD_SIZE *  8 ]
	vmovdqu ymm9,  [ rsi + YWORD_SIZE *  9 ]
	vmovdqu ymm10, [ rsi + YWORD_SIZE * 10 ]
	vmovdqu ymm11, [ rsi + YWORD_SIZE * 11 ]
	vmovdqu ymm12, [ rsi + YWORD_SIZE * 12 ]
	vmovdqu ymm13, [ rsi + YWORD_SIZE * 13 ]
	vmovdqa [ rdi + YWORD_SIZE *  0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE *  1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE *  2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE *  3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE *  4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE *  5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE *  6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE *  7 ], ymm7
	vmovdqa [ rdi + YWORD_SIZE *  8 ], ymm8
	vmovdqa [ rdi + YWORD_SIZE *  9 ], ymm9
	vmovdqa [ rdi + YWORD_SIZE * 10 ], ymm10
	vmovdqa [ rdi + YWORD_SIZE * 11 ], ymm11
	vmovdqa [ rdi + YWORD_SIZE * 12 ], ymm12
	vmovdqa [ rdi + YWORD_SIZE * 13 ], ymm13
	VZEROUPPER_RET

align 16
.copy_15_ywords:
	vmovdqu ymm0,  [ rsi + YWORD_SIZE *  0 ]
	vmovdqu ymm1,  [ rsi + YWORD_SIZE *  1 ]
	vmovdqu ymm2,  [ rsi + YWORD_SIZE *  2 ]
	vmovdqu ymm3,  [ rsi + YWORD_SIZE *  3 ]
	vmovdqu ymm4,  [ rsi + YWORD_SIZE *  4 ]
	vmovdqu ymm5,  [ rsi + YWORD_SIZE *  5 ]
	vmovdqu ymm6,  [ rsi + YWORD_SIZE *  6 ]
	vmovdqu ymm7,  [ rsi + YWORD_SIZE *  7 ]
	vmovdqu ymm8,  [ rsi + YWORD_SIZE *  8 ]
	vmovdqu ymm9,  [ rsi + YWORD_SIZE *  9 ]
	vmovdqu ymm10, [ rsi + YWORD_SIZE * 10 ]
	vmovdqu ymm11, [ rsi + YWORD_SIZE * 11 ]
	vmovdqu ymm12, [ rsi + YWORD_SIZE * 12 ]
	vmovdqu ymm13, [ rsi + YWORD_SIZE * 13 ]
	vmovdqu ymm14, [ rsi + YWORD_SIZE * 14 ]
	vmovdqa [ rdi + YWORD_SIZE *  0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE *  1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE *  2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE *  3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE *  4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE *  5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE *  6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE *  7 ], ymm7
	vmovdqa [ rdi + YWORD_SIZE *  8 ], ymm8
	vmovdqa [ rdi + YWORD_SIZE *  9 ], ymm9
	vmovdqa [ rdi + YWORD_SIZE * 10 ], ymm10
	vmovdqa [ rdi + YWORD_SIZE * 11 ], ymm11
	vmovdqa [ rdi + YWORD_SIZE * 12 ], ymm12
	vmovdqa [ rdi + YWORD_SIZE * 13 ], ymm13
	vmovdqa [ rdi + YWORD_SIZE * 14 ], ymm14
	VZEROUPPER_RET

align 16
.copy_16_ywords:
	vmovdqu ymm0,  [ rsi + YWORD_SIZE *  0 ]
	vmovdqu ymm1,  [ rsi + YWORD_SIZE *  1 ]
	vmovdqu ymm2,  [ rsi + YWORD_SIZE *  2 ]
	vmovdqu ymm3,  [ rsi + YWORD_SIZE *  3 ]
	vmovdqu ymm4,  [ rsi + YWORD_SIZE *  4 ]
	vmovdqu ymm5,  [ rsi + YWORD_SIZE *  5 ]
	vmovdqu ymm6,  [ rsi + YWORD_SIZE *  6 ]
	vmovdqu ymm7,  [ rsi + YWORD_SIZE *  7 ]
	vmovdqu ymm8,  [ rsi + YWORD_SIZE *  8 ]
	vmovdqu ymm9,  [ rsi + YWORD_SIZE *  9 ]
	vmovdqu ymm10, [ rsi + YWORD_SIZE * 10 ]
	vmovdqu ymm11, [ rsi + YWORD_SIZE * 11 ]
	vmovdqu ymm12, [ rsi + YWORD_SIZE * 12 ]
	vmovdqu ymm13, [ rsi + YWORD_SIZE * 13 ]
	vmovdqu ymm14, [ rsi + YWORD_SIZE * 14 ]
	vmovdqu ymm15, [ rsi + YWORD_SIZE * 15 ]
	vmovdqa [ rdi + YWORD_SIZE *  0 ], ymm0
	vmovdqa [ rdi + YWORD_SIZE *  1 ], ymm1
	vmovdqa [ rdi + YWORD_SIZE *  2 ], ymm2
	vmovdqa [ rdi + YWORD_SIZE *  3 ], ymm3
	vmovdqa [ rdi + YWORD_SIZE *  4 ], ymm4
	vmovdqa [ rdi + YWORD_SIZE *  5 ], ymm5
	vmovdqa [ rdi + YWORD_SIZE *  6 ], ymm6
	vmovdqa [ rdi + YWORD_SIZE *  7 ], ymm7
	vmovdqa [ rdi + YWORD_SIZE *  8 ], ymm8
	vmovdqa [ rdi + YWORD_SIZE *  9 ], ymm9
	vmovdqa [ rdi + YWORD_SIZE * 10 ], ymm10
	vmovdqa [ rdi + YWORD_SIZE * 11 ], ymm11
	vmovdqa [ rdi + YWORD_SIZE * 12 ], ymm12
	vmovdqa [ rdi + YWORD_SIZE * 13 ], ymm13
	vmovdqa [ rdi + YWORD_SIZE * 14 ], ymm14
	vmovdqa [ rdi + YWORD_SIZE * 15 ], ymm15
	VZEROUPPER_RET

section .rodata
.intermediate_yword_copy_jump_table:
	dq .copy_1_yword
	dq .copy_2_ywords
	dq .copy_3_ywords
	dq .copy_4_ywords
	dq .copy_5_ywords
	dq .copy_6_ywords
	dq .copy_7_ywords
	dq .copy_8_ywords
	dq .copy_9_ywords
	dq .copy_10_ywords
	dq .copy_11_ywords
	dq .copy_12_ywords
	dq .copy_13_ywords
	dq .copy_14_ywords
	dq .copy_15_ywords
	dq .copy_16_ywords
