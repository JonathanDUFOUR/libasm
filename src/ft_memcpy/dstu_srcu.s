global ft_memcpy_dstu_srcu: function

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

%macro COPY_THE_LAST_YWORD 0
	sub rdx, YWORD_SIZE ; corresponds to the last yword that is about to be copied
	vmovdqu ymm0, [ rsi + rdx ]
	vmovdqu [ rdi + rdx ], ymm0
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
ft_memcpy_dstu_srcu:
; preliminary initialization
	mov rax, rdi
; check if we can do a small copy
	cmp rdx, 545
	jb .copy_less_than_545_bytes
	COPY_THE_LAST_YWORD
align 16
.copy_next_16_intermediate_ywords:
; update the number of intermediate bytes to copy
	sub rdx, 512
	jc .copy_less_than_16_intermediate_ywords
; load the next 16 intermediate ywords from the source memory area
	vmovdqu ymm0,  [ rsi +  0 * YWORD_SIZE ]
	vmovdqu ymm1,  [ rsi +  1 * YWORD_SIZE ]
	vmovdqu ymm2,  [ rsi +  2 * YWORD_SIZE ]
	vmovdqu ymm3,  [ rsi +  3 * YWORD_SIZE ]
	vmovdqu ymm4,  [ rsi +  4 * YWORD_SIZE ]
	vmovdqu ymm5,  [ rsi +  5 * YWORD_SIZE ]
	vmovdqu ymm6,  [ rsi +  6 * YWORD_SIZE ]
	vmovdqu ymm7,  [ rsi +  7 * YWORD_SIZE ]
	vmovdqu ymm8,  [ rsi +  8 * YWORD_SIZE ]
	vmovdqu ymm9,  [ rsi +  9 * YWORD_SIZE ]
	vmovdqu ymm10, [ rsi + 10 * YWORD_SIZE ]
	vmovdqu ymm11, [ rsi + 11 * YWORD_SIZE ]
	vmovdqu ymm12, [ rsi + 12 * YWORD_SIZE ]
	vmovdqu ymm13, [ rsi + 13 * YWORD_SIZE ]
	vmovdqu ymm14, [ rsi + 14 * YWORD_SIZE ]
	vmovdqu ymm15, [ rsi + 15 * YWORD_SIZE ]
; store the next 16 intermediate ywords to the destination memory area
	vmovdqu [ rdi +  0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi +  1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi +  2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi +  3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi +  4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi +  5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi +  6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi +  7 * YWORD_SIZE ], ymm7
	vmovdqu [ rdi +  8 * YWORD_SIZE ], ymm8
	vmovdqu [ rdi +  9 * YWORD_SIZE ], ymm9
	vmovdqu [ rdi + 10 * YWORD_SIZE ], ymm10
	vmovdqu [ rdi + 11 * YWORD_SIZE ], ymm11
	vmovdqu [ rdi + 12 * YWORD_SIZE ], ymm12
	vmovdqu [ rdi + 13 * YWORD_SIZE ], ymm13
	vmovdqu [ rdi + 14 * YWORD_SIZE ], ymm14
	vmovdqu [ rdi + 15 * YWORD_SIZE ], ymm15
; update the pointers
	add rdi, 16 * YWORD_SIZE
	add rsi, 16 * YWORD_SIZE
; repeat until there are less than 16 intermediate ywords to copy
	jmp .copy_next_16_intermediate_ywords

align 16
.copy_less_than_16_intermediate_ywords:
; calculate how many intermediate ywords remain to be copied
	add rdx, 512
	shr rdx, 5 ; divide by 32
; copy the remaining intermediate ywords
	lea rcx, [ .small_copy_jump_table ]
	jmp [ rcx + rdx*QWORD_SIZE ]

align 16
.copy_less_than_545_bytes:
	cmp edx, 64
	ja .copy_between_65_and_544_bytes
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
.copy_between_65_and_544_bytes:
	COPY_THE_LAST_YWORD
; calculate how many intermediate ywords shall be copied
	shr rdx, 5 ; divide by 32
	lea rcx, [ .small_copy_jump_table ]
	jmp [ rcx + rdx*QWORD_SIZE ]

align 16
.copy_1_yword:
	vmovdqu ymm0, [ rsi ]
	vmovdqu [ rdi ], ymm0
	VZEROUPPER_RET

align 16
.copy_2_ywords:
	vmovdqu ymm0, [ rsi + 0 * YWORD_SIZE ]
	vmovdqu ymm1, [ rsi + 1 * YWORD_SIZE ]
	vmovdqu [ rdi + 0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi + 1 * YWORD_SIZE ], ymm1
	VZEROUPPER_RET

align 16
.copy_3_ywords:
	vmovdqu ymm0, [ rsi + 0 * YWORD_SIZE ]
	vmovdqu ymm1, [ rsi + 1 * YWORD_SIZE ]
	vmovdqu ymm2, [ rsi + 2 * YWORD_SIZE ]
	vmovdqu [ rdi + 0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi + 1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi + 2 * YWORD_SIZE ], ymm2
	VZEROUPPER_RET

align 16
.copy_4_ywords:
	vmovdqu ymm0, [ rsi + 0 * YWORD_SIZE ]
	vmovdqu ymm1, [ rsi + 1 * YWORD_SIZE ]
	vmovdqu ymm2, [ rsi + 2 * YWORD_SIZE ]
	vmovdqu ymm3, [ rsi + 3 * YWORD_SIZE ]
	vmovdqu [ rdi + 0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi + 1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi + 2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi + 3 * YWORD_SIZE ], ymm3
	VZEROUPPER_RET

align 16
.copy_5_ywords:
	vmovdqu ymm0, [ rsi + 0 * YWORD_SIZE ]
	vmovdqu ymm1, [ rsi + 1 * YWORD_SIZE ]
	vmovdqu ymm2, [ rsi + 2 * YWORD_SIZE ]
	vmovdqu ymm3, [ rsi + 3 * YWORD_SIZE ]
	vmovdqu ymm4, [ rsi + 4 * YWORD_SIZE ]
	vmovdqu [ rdi + 0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi + 1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi + 2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi + 3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi + 4 * YWORD_SIZE ], ymm4
	VZEROUPPER_RET

align 16
.copy_6_ywords:
	vmovdqu ymm0, [ rsi + 0 * YWORD_SIZE ]
	vmovdqu ymm1, [ rsi + 1 * YWORD_SIZE ]
	vmovdqu ymm2, [ rsi + 2 * YWORD_SIZE ]
	vmovdqu ymm3, [ rsi + 3 * YWORD_SIZE ]
	vmovdqu ymm4, [ rsi + 4 * YWORD_SIZE ]
	vmovdqu ymm5, [ rsi + 5 * YWORD_SIZE ]
	vmovdqu [ rdi + 0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi + 1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi + 2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi + 3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi + 4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi + 5 * YWORD_SIZE ], ymm5
	VZEROUPPER_RET

align 16
.copy_7_ywords:
	vmovdqu ymm0, [ rsi + 0 * YWORD_SIZE ]
	vmovdqu ymm1, [ rsi + 1 * YWORD_SIZE ]
	vmovdqu ymm2, [ rsi + 2 * YWORD_SIZE ]
	vmovdqu ymm3, [ rsi + 3 * YWORD_SIZE ]
	vmovdqu ymm4, [ rsi + 4 * YWORD_SIZE ]
	vmovdqu ymm5, [ rsi + 5 * YWORD_SIZE ]
	vmovdqu ymm6, [ rsi + 6 * YWORD_SIZE ]
	vmovdqu [ rdi + 0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi + 1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi + 2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi + 3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi + 4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi + 5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi + 6 * YWORD_SIZE ], ymm6
	VZEROUPPER_RET

align 16
.copy_8_ywords:
	vmovdqu ymm0, [ rsi + 0 * YWORD_SIZE ]
	vmovdqu ymm1, [ rsi + 1 * YWORD_SIZE ]
	vmovdqu ymm2, [ rsi + 2 * YWORD_SIZE ]
	vmovdqu ymm3, [ rsi + 3 * YWORD_SIZE ]
	vmovdqu ymm4, [ rsi + 4 * YWORD_SIZE ]
	vmovdqu ymm5, [ rsi + 5 * YWORD_SIZE ]
	vmovdqu ymm6, [ rsi + 6 * YWORD_SIZE ]
	vmovdqu ymm7, [ rsi + 7 * YWORD_SIZE ]
	vmovdqu [ rdi + 0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi + 1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi + 2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi + 3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi + 4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi + 5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi + 6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi + 7 * YWORD_SIZE ], ymm7
	VZEROUPPER_RET

align 16
.copy_9_ywords:
	vmovdqu ymm0, [ rsi + 0 * YWORD_SIZE ]
	vmovdqu ymm1, [ rsi + 1 * YWORD_SIZE ]
	vmovdqu ymm2, [ rsi + 2 * YWORD_SIZE ]
	vmovdqu ymm3, [ rsi + 3 * YWORD_SIZE ]
	vmovdqu ymm4, [ rsi + 4 * YWORD_SIZE ]
	vmovdqu ymm5, [ rsi + 5 * YWORD_SIZE ]
	vmovdqu ymm6, [ rsi + 6 * YWORD_SIZE ]
	vmovdqu ymm7, [ rsi + 7 * YWORD_SIZE ]
	vmovdqu ymm8, [ rsi + 8 * YWORD_SIZE ]
	vmovdqu [ rdi + 0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi + 1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi + 2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi + 3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi + 4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi + 5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi + 6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi + 7 * YWORD_SIZE ], ymm7
	vmovdqu [ rdi + 8 * YWORD_SIZE ], ymm8
	VZEROUPPER_RET

align 16
.copy_10_ywords:
	vmovdqu ymm0, [ rsi + 0 * YWORD_SIZE ]
	vmovdqu ymm1, [ rsi + 1 * YWORD_SIZE ]
	vmovdqu ymm2, [ rsi + 2 * YWORD_SIZE ]
	vmovdqu ymm3, [ rsi + 3 * YWORD_SIZE ]
	vmovdqu ymm4, [ rsi + 4 * YWORD_SIZE ]
	vmovdqu ymm5, [ rsi + 5 * YWORD_SIZE ]
	vmovdqu ymm6, [ rsi + 6 * YWORD_SIZE ]
	vmovdqu ymm7, [ rsi + 7 * YWORD_SIZE ]
	vmovdqu ymm8, [ rsi + 8 * YWORD_SIZE ]
	vmovdqu ymm9, [ rsi + 9 * YWORD_SIZE ]
	vmovdqu [ rdi + 0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi + 1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi + 2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi + 3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi + 4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi + 5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi + 6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi + 7 * YWORD_SIZE ], ymm7
	vmovdqu [ rdi + 8 * YWORD_SIZE ], ymm8
	vmovdqu [ rdi + 9 * YWORD_SIZE ], ymm9
	VZEROUPPER_RET

align 16
.copy_11_ywords:
	vmovdqu ymm0,  [ rsi +  0 * YWORD_SIZE ]
	vmovdqu ymm1,  [ rsi +  1 * YWORD_SIZE ]
	vmovdqu ymm2,  [ rsi +  2 * YWORD_SIZE ]
	vmovdqu ymm3,  [ rsi +  3 * YWORD_SIZE ]
	vmovdqu ymm4,  [ rsi +  4 * YWORD_SIZE ]
	vmovdqu ymm5,  [ rsi +  5 * YWORD_SIZE ]
	vmovdqu ymm6,  [ rsi +  6 * YWORD_SIZE ]
	vmovdqu ymm7,  [ rsi +  7 * YWORD_SIZE ]
	vmovdqu ymm8,  [ rsi +  8 * YWORD_SIZE ]
	vmovdqu ymm9,  [ rsi +  9 * YWORD_SIZE ]
	vmovdqu ymm10, [ rsi + 10 * YWORD_SIZE ]
	vmovdqu [ rdi +  0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi +  1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi +  2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi +  3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi +  4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi +  5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi +  6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi +  7 * YWORD_SIZE ], ymm7
	vmovdqu [ rdi +  8 * YWORD_SIZE ], ymm8
	vmovdqu [ rdi +  9 * YWORD_SIZE ], ymm9
	vmovdqu [ rdi + 10 * YWORD_SIZE ], ymm10
	VZEROUPPER_RET

align 16
.copy_12_ywords:
	vmovdqu ymm0,  [ rsi +  0 * YWORD_SIZE ]
	vmovdqu ymm1,  [ rsi +  1 * YWORD_SIZE ]
	vmovdqu ymm2,  [ rsi +  2 * YWORD_SIZE ]
	vmovdqu ymm3,  [ rsi +  3 * YWORD_SIZE ]
	vmovdqu ymm4,  [ rsi +  4 * YWORD_SIZE ]
	vmovdqu ymm5,  [ rsi +  5 * YWORD_SIZE ]
	vmovdqu ymm6,  [ rsi +  6 * YWORD_SIZE ]
	vmovdqu ymm7,  [ rsi +  7 * YWORD_SIZE ]
	vmovdqu ymm8,  [ rsi +  8 * YWORD_SIZE ]
	vmovdqu ymm9,  [ rsi +  9 * YWORD_SIZE ]
	vmovdqu ymm10, [ rsi + 10 * YWORD_SIZE ]
	vmovdqu ymm11, [ rsi + 11 * YWORD_SIZE ]
	vmovdqu [ rdi +  0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi +  1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi +  2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi +  3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi +  4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi +  5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi +  6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi +  7 * YWORD_SIZE ], ymm7
	vmovdqu [ rdi +  8 * YWORD_SIZE ], ymm8
	vmovdqu [ rdi +  9 * YWORD_SIZE ], ymm9
	vmovdqu [ rdi + 10 * YWORD_SIZE ], ymm10
	vmovdqu [ rdi + 11 * YWORD_SIZE ], ymm11
	VZEROUPPER_RET

align 16
.copy_13_ywords:
	vmovdqu ymm0,  [ rsi +  0 * YWORD_SIZE ]
	vmovdqu ymm1,  [ rsi +  1 * YWORD_SIZE ]
	vmovdqu ymm2,  [ rsi +  2 * YWORD_SIZE ]
	vmovdqu ymm3,  [ rsi +  3 * YWORD_SIZE ]
	vmovdqu ymm4,  [ rsi +  4 * YWORD_SIZE ]
	vmovdqu ymm5,  [ rsi +  5 * YWORD_SIZE ]
	vmovdqu ymm6,  [ rsi +  6 * YWORD_SIZE ]
	vmovdqu ymm7,  [ rsi +  7 * YWORD_SIZE ]
	vmovdqu ymm8,  [ rsi +  8 * YWORD_SIZE ]
	vmovdqu ymm9,  [ rsi +  9 * YWORD_SIZE ]
	vmovdqu ymm10, [ rsi + 10 * YWORD_SIZE ]
	vmovdqu ymm11, [ rsi + 11 * YWORD_SIZE ]
	vmovdqu ymm12, [ rsi + 12 * YWORD_SIZE ]
	vmovdqu [ rdi +  0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi +  1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi +  2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi +  3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi +  4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi +  5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi +  6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi +  7 * YWORD_SIZE ], ymm7
	vmovdqu [ rdi +  8 * YWORD_SIZE ], ymm8
	vmovdqu [ rdi +  9 * YWORD_SIZE ], ymm9
	vmovdqu [ rdi + 10 * YWORD_SIZE ], ymm10
	vmovdqu [ rdi + 11 * YWORD_SIZE ], ymm11
	vmovdqu [ rdi + 12 * YWORD_SIZE ], ymm12
	VZEROUPPER_RET

align 16
.copy_14_ywords:
	vmovdqu ymm0,  [ rsi +  0 * YWORD_SIZE ]
	vmovdqu ymm1,  [ rsi +  1 * YWORD_SIZE ]
	vmovdqu ymm2,  [ rsi +  2 * YWORD_SIZE ]
	vmovdqu ymm3,  [ rsi +  3 * YWORD_SIZE ]
	vmovdqu ymm4,  [ rsi +  4 * YWORD_SIZE ]
	vmovdqu ymm5,  [ rsi +  5 * YWORD_SIZE ]
	vmovdqu ymm6,  [ rsi +  6 * YWORD_SIZE ]
	vmovdqu ymm7,  [ rsi +  7 * YWORD_SIZE ]
	vmovdqu ymm8,  [ rsi +  8 * YWORD_SIZE ]
	vmovdqu ymm9,  [ rsi +  9 * YWORD_SIZE ]
	vmovdqu ymm10, [ rsi + 10 * YWORD_SIZE ]
	vmovdqu ymm11, [ rsi + 11 * YWORD_SIZE ]
	vmovdqu ymm12, [ rsi + 12 * YWORD_SIZE ]
	vmovdqu ymm13, [ rsi + 13 * YWORD_SIZE ]
	vmovdqu [ rdi +  0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi +  1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi +  2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi +  3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi +  4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi +  5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi +  6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi +  7 * YWORD_SIZE ], ymm7
	vmovdqu [ rdi +  8 * YWORD_SIZE ], ymm8
	vmovdqu [ rdi +  9 * YWORD_SIZE ], ymm9
	vmovdqu [ rdi + 10 * YWORD_SIZE ], ymm10
	vmovdqu [ rdi + 11 * YWORD_SIZE ], ymm11
	vmovdqu [ rdi + 12 * YWORD_SIZE ], ymm12
	vmovdqu [ rdi + 13 * YWORD_SIZE ], ymm13
	VZEROUPPER_RET

align 16
.copy_15_ywords:
	vmovdqu ymm0,  [ rsi +  0 * YWORD_SIZE ]
	vmovdqu ymm1,  [ rsi +  1 * YWORD_SIZE ]
	vmovdqu ymm2,  [ rsi +  2 * YWORD_SIZE ]
	vmovdqu ymm3,  [ rsi +  3 * YWORD_SIZE ]
	vmovdqu ymm4,  [ rsi +  4 * YWORD_SIZE ]
	vmovdqu ymm5,  [ rsi +  5 * YWORD_SIZE ]
	vmovdqu ymm6,  [ rsi +  6 * YWORD_SIZE ]
	vmovdqu ymm7,  [ rsi +  7 * YWORD_SIZE ]
	vmovdqu ymm8,  [ rsi +  8 * YWORD_SIZE ]
	vmovdqu ymm9,  [ rsi +  9 * YWORD_SIZE ]
	vmovdqu ymm10, [ rsi + 10 * YWORD_SIZE ]
	vmovdqu ymm11, [ rsi + 11 * YWORD_SIZE ]
	vmovdqu ymm12, [ rsi + 12 * YWORD_SIZE ]
	vmovdqu ymm13, [ rsi + 13 * YWORD_SIZE ]
	vmovdqu ymm14, [ rsi + 14 * YWORD_SIZE ]
	vmovdqu [ rdi +  0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi +  1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi +  2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi +  3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi +  4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi +  5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi +  6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi +  7 * YWORD_SIZE ], ymm7
	vmovdqu [ rdi +  8 * YWORD_SIZE ], ymm8
	vmovdqu [ rdi +  9 * YWORD_SIZE ], ymm9
	vmovdqu [ rdi + 10 * YWORD_SIZE ], ymm10
	vmovdqu [ rdi + 11 * YWORD_SIZE ], ymm11
	vmovdqu [ rdi + 12 * YWORD_SIZE ], ymm12
	vmovdqu [ rdi + 13 * YWORD_SIZE ], ymm13
	vmovdqu [ rdi + 14 * YWORD_SIZE ], ymm14
	VZEROUPPER_RET

align 16
.copy_16_ywords:
	vmovdqu ymm0,  [ rsi +  0 * YWORD_SIZE ]
	vmovdqu ymm1,  [ rsi +  1 * YWORD_SIZE ]
	vmovdqu ymm2,  [ rsi +  2 * YWORD_SIZE ]
	vmovdqu ymm3,  [ rsi +  3 * YWORD_SIZE ]
	vmovdqu ymm4,  [ rsi +  4 * YWORD_SIZE ]
	vmovdqu ymm5,  [ rsi +  5 * YWORD_SIZE ]
	vmovdqu ymm6,  [ rsi +  6 * YWORD_SIZE ]
	vmovdqu ymm7,  [ rsi +  7 * YWORD_SIZE ]
	vmovdqu ymm8,  [ rsi +  8 * YWORD_SIZE ]
	vmovdqu ymm9,  [ rsi +  9 * YWORD_SIZE ]
	vmovdqu ymm10, [ rsi + 10 * YWORD_SIZE ]
	vmovdqu ymm11, [ rsi + 11 * YWORD_SIZE ]
	vmovdqu ymm12, [ rsi + 12 * YWORD_SIZE ]
	vmovdqu ymm13, [ rsi + 13 * YWORD_SIZE ]
	vmovdqu ymm14, [ rsi + 14 * YWORD_SIZE ]
	vmovdqu ymm15, [ rsi + 15 * YWORD_SIZE ]
	vmovdqu [ rdi +  0 * YWORD_SIZE ], ymm0
	vmovdqu [ rdi +  1 * YWORD_SIZE ], ymm1
	vmovdqu [ rdi +  2 * YWORD_SIZE ], ymm2
	vmovdqu [ rdi +  3 * YWORD_SIZE ], ymm3
	vmovdqu [ rdi +  4 * YWORD_SIZE ], ymm4
	vmovdqu [ rdi +  5 * YWORD_SIZE ], ymm5
	vmovdqu [ rdi +  6 * YWORD_SIZE ], ymm6
	vmovdqu [ rdi +  7 * YWORD_SIZE ], ymm7
	vmovdqu [ rdi +  8 * YWORD_SIZE ], ymm8
	vmovdqu [ rdi +  9 * YWORD_SIZE ], ymm9
	vmovdqu [ rdi + 10 * YWORD_SIZE ], ymm10
	vmovdqu [ rdi + 11 * YWORD_SIZE ], ymm11
	vmovdqu [ rdi + 12 * YWORD_SIZE ], ymm12
	vmovdqu [ rdi + 13 * YWORD_SIZE ], ymm13
	vmovdqu [ rdi + 14 * YWORD_SIZE ], ymm14
	vmovdqu [ rdi + 15 * YWORD_SIZE ], ymm15
	VZEROUPPER_RET

section .rodata
.small_copy_jump_table:
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
