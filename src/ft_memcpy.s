global ft_memcpy: function

default rel

%use smartalign
ALIGNMODE p6

%define SIZEOF_BYTE 1
%define SIZEOF_WORD 2
%define SIZEOF_DWORD 4
%define SIZEOF_QWORD 8
%define SIZEOF_OWORD 16
%define SIZEOF_YWORD 32

%macro CLEAN_RET 0
	vzeroupper
	ret
%endmacro

%macro COPY_THE_FIRST_YWORD_AND_THE_LAST_YWORD_AND_ALIGN_THE_DESTINATION_POINTER 0
; copy the first and the last yword
	sub rdx, SIZEOF_YWORD ; corresponds to the last yword that is about to be copied
	vmovdqu ymm0, [ rsi ]
	vmovdqu ymm1, [ rsi + rdx ]
	vmovdqu [ rdi ], ymm0
	vmovdqu [ rdi + rdx ], ymm1
; calculate how far the destination area is to its next yword boundary
	mov rcx, rdi
	neg rcx
	and rcx, SIZEOF_YWORD - 1 ; modulo SIZEOF_YWORD
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
	cmp rdx, 545
	jb .copy_less_than_545_bytes
	COPY_THE_FIRST_YWORD_AND_THE_LAST_YWORD_AND_ALIGN_THE_DESTINATION_POINTER
align 16
.copy_the_next_16_intermediate_ywords:
; update the number of intermediate bytes to copy
	sub rdx, 16 * SIZEOF_YWORD
	jc .copy_less_than_16_intermediate_ywords
; load the next 16 intermediate ywords from the source memory area
	vmovdqu ymm0,  [ rsi +  0 * SIZEOF_YWORD ]
	vmovdqu ymm1,  [ rsi +  1 * SIZEOF_YWORD ]
	vmovdqu ymm2,  [ rsi +  2 * SIZEOF_YWORD ]
	vmovdqu ymm3,  [ rsi +  3 * SIZEOF_YWORD ]
	vmovdqu ymm4,  [ rsi +  4 * SIZEOF_YWORD ]
	vmovdqu ymm5,  [ rsi +  5 * SIZEOF_YWORD ]
	vmovdqu ymm6,  [ rsi +  6 * SIZEOF_YWORD ]
	vmovdqu ymm7,  [ rsi +  7 * SIZEOF_YWORD ]
	vmovdqu ymm8,  [ rsi +  8 * SIZEOF_YWORD ]
	vmovdqu ymm9,  [ rsi +  9 * SIZEOF_YWORD ]
	vmovdqu ymm10, [ rsi + 10 * SIZEOF_YWORD ]
	vmovdqu ymm11, [ rsi + 11 * SIZEOF_YWORD ]
	vmovdqu ymm12, [ rsi + 12 * SIZEOF_YWORD ]
	vmovdqu ymm13, [ rsi + 13 * SIZEOF_YWORD ]
	vmovdqu ymm14, [ rsi + 14 * SIZEOF_YWORD ]
	vmovdqu ymm15, [ rsi + 15 * SIZEOF_YWORD ]
; store the next 16 intermediate ywords to the destination memory area
	vmovdqa [ rdi +  0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi +  1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi +  2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi +  3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi +  4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi +  5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi +  6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi +  7 * SIZEOF_YWORD ], ymm7
	vmovdqa [ rdi +  8 * SIZEOF_YWORD ], ymm8
	vmovdqa [ rdi +  9 * SIZEOF_YWORD ], ymm9
	vmovdqa [ rdi + 10 * SIZEOF_YWORD ], ymm10
	vmovdqa [ rdi + 11 * SIZEOF_YWORD ], ymm11
	vmovdqa [ rdi + 12 * SIZEOF_YWORD ], ymm12
	vmovdqa [ rdi + 13 * SIZEOF_YWORD ], ymm13
	vmovdqa [ rdi + 14 * SIZEOF_YWORD ], ymm14
	vmovdqa [ rdi + 15 * SIZEOF_YWORD ], ymm15
; update the pointers
	add rdi, 16 * SIZEOF_YWORD
	add rsi, 16 * SIZEOF_YWORD
; repeat until there are less than 16 intermediate ywords to copy
	jmp .copy_the_next_16_intermediate_ywords

align 16
.copy_less_than_16_intermediate_ywords:
; calculate how many intermediate ywords remain to be copied
	add rdx, 16 * SIZEOF_YWORD
	shr rdx, 5 ; divide by SIZEOF_YWORD
; copy the remaining intermediate ywords
	lea rcx, [ .small_copy_jump_table ]
	jmp [ rcx + rdx * SIZEOF_QWORD ]

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
	mov sil, [ rsi + rdx - SIZEOF_BYTE ]
	mov [ rdi ], cl
	mov [ rdi + rdx - SIZEOF_BYTE ], sil
	ret

align 16
.copy_between_3_and_4_bytes:
	mov cx, [ rsi ]
	mov si, [ rsi + rdx - SIZEOF_WORD ]
	mov [ rdi ], cx
	mov [ rdi + rdx - SIZEOF_WORD ], si
	ret

align 16
.copy_between_5_and_8_bytes:
	mov ecx, [ rsi ]
	mov esi, [ rsi + rdx - SIZEOF_DWORD ]
	mov [ rdi ], ecx
	mov [ rdi + rdx - SIZEOF_DWORD ], esi
	ret

align 16
.copy_between_9_and_16_bytes:
	mov rcx, [ rsi ]
	mov rsi, [ rsi + rdx - SIZEOF_QWORD ]
	mov [ rdi ], rcx
	mov [ rdi + rdx - SIZEOF_QWORD ], rsi
	ret

align 16
.copy_between_17_and_32_bytes:
	movdqu xmm0, [ rsi ]
	movdqu xmm1, [ rsi + rdx - SIZEOF_OWORD ]
	movdqu [ rdi ], xmm0
	movdqu [ rdi + rdx - SIZEOF_OWORD ], xmm1
	ret

align 16
.copy_between_33_and_64_bytes:
	vmovdqu ymm0, [ rsi ]
	vmovdqu ymm1, [ rsi + rdx - SIZEOF_YWORD ]
	vmovdqu [ rdi ], ymm0
	vmovdqu [ rdi + rdx - SIZEOF_YWORD ], ymm1
	CLEAN_RET

align 16
.copy_between_65_and_544_bytes:
	COPY_THE_FIRST_YWORD_AND_THE_LAST_YWORD_AND_ALIGN_THE_DESTINATION_POINTER
; calculate how many intermediate ywords shall be copied
	shr rdx, 5 ; divide by 32
	lea rcx, [ .small_copy_jump_table ]
	jmp [ rcx + rdx * SIZEOF_QWORD ]

align 16
.copy_1_yword:
	vmovdqu ymm0, [ rsi ]
	vmovdqa [ rdi ], ymm0
	CLEAN_RET

align 16
.copy_2_ywords:
	vmovdqu ymm0, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vmovdqa [ rdi + 0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi + 1 * SIZEOF_YWORD ], ymm1
	CLEAN_RET

align 16
.copy_3_ywords:
	vmovdqu ymm0, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vmovdqu ymm2, [ rsi + 2 * SIZEOF_YWORD ]
	vmovdqa [ rdi + 0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi + 1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi + 2 * SIZEOF_YWORD ], ymm2
	CLEAN_RET

align 16
.copy_4_ywords:
	vmovdqu ymm0, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vmovdqu ymm2, [ rsi + 2 * SIZEOF_YWORD ]
	vmovdqu ymm3, [ rsi + 3 * SIZEOF_YWORD ]
	vmovdqa [ rdi + 0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi + 1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi + 2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi + 3 * SIZEOF_YWORD ], ymm3
	CLEAN_RET

align 16
.copy_5_ywords:
	vmovdqu ymm0, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vmovdqu ymm2, [ rsi + 2 * SIZEOF_YWORD ]
	vmovdqu ymm3, [ rsi + 3 * SIZEOF_YWORD ]
	vmovdqu ymm4, [ rsi + 4 * SIZEOF_YWORD ]
	vmovdqa [ rdi + 0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi + 1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi + 2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi + 3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi + 4 * SIZEOF_YWORD ], ymm4
	CLEAN_RET

align 16
.copy_6_ywords:
	vmovdqu ymm0, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vmovdqu ymm2, [ rsi + 2 * SIZEOF_YWORD ]
	vmovdqu ymm3, [ rsi + 3 * SIZEOF_YWORD ]
	vmovdqu ymm4, [ rsi + 4 * SIZEOF_YWORD ]
	vmovdqu ymm5, [ rsi + 5 * SIZEOF_YWORD ]
	vmovdqa [ rdi + 0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi + 1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi + 2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi + 3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi + 4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi + 5 * SIZEOF_YWORD ], ymm5
	CLEAN_RET

align 16
.copy_7_ywords:
	vmovdqu ymm0, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vmovdqu ymm2, [ rsi + 2 * SIZEOF_YWORD ]
	vmovdqu ymm3, [ rsi + 3 * SIZEOF_YWORD ]
	vmovdqu ymm4, [ rsi + 4 * SIZEOF_YWORD ]
	vmovdqu ymm5, [ rsi + 5 * SIZEOF_YWORD ]
	vmovdqu ymm6, [ rsi + 6 * SIZEOF_YWORD ]
	vmovdqa [ rdi + 0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi + 1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi + 2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi + 3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi + 4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi + 5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi + 6 * SIZEOF_YWORD ], ymm6
	CLEAN_RET

align 16
.copy_8_ywords:
	vmovdqu ymm0, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vmovdqu ymm2, [ rsi + 2 * SIZEOF_YWORD ]
	vmovdqu ymm3, [ rsi + 3 * SIZEOF_YWORD ]
	vmovdqu ymm4, [ rsi + 4 * SIZEOF_YWORD ]
	vmovdqu ymm5, [ rsi + 5 * SIZEOF_YWORD ]
	vmovdqu ymm6, [ rsi + 6 * SIZEOF_YWORD ]
	vmovdqu ymm7, [ rsi + 7 * SIZEOF_YWORD ]
	vmovdqa [ rdi + 0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi + 1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi + 2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi + 3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi + 4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi + 5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi + 6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi + 7 * SIZEOF_YWORD ], ymm7
	CLEAN_RET

align 16
.copy_9_ywords:
	vmovdqu ymm0, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vmovdqu ymm2, [ rsi + 2 * SIZEOF_YWORD ]
	vmovdqu ymm3, [ rsi + 3 * SIZEOF_YWORD ]
	vmovdqu ymm4, [ rsi + 4 * SIZEOF_YWORD ]
	vmovdqu ymm5, [ rsi + 5 * SIZEOF_YWORD ]
	vmovdqu ymm6, [ rsi + 6 * SIZEOF_YWORD ]
	vmovdqu ymm7, [ rsi + 7 * SIZEOF_YWORD ]
	vmovdqu ymm8, [ rsi + 8 * SIZEOF_YWORD ]
	vmovdqa [ rdi + 0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi + 1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi + 2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi + 3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi + 4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi + 5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi + 6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi + 7 * SIZEOF_YWORD ], ymm7
	vmovdqa [ rdi + 8 * SIZEOF_YWORD ], ymm8
	CLEAN_RET

align 16
.copy_10_ywords:
	vmovdqu ymm0, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vmovdqu ymm2, [ rsi + 2 * SIZEOF_YWORD ]
	vmovdqu ymm3, [ rsi + 3 * SIZEOF_YWORD ]
	vmovdqu ymm4, [ rsi + 4 * SIZEOF_YWORD ]
	vmovdqu ymm5, [ rsi + 5 * SIZEOF_YWORD ]
	vmovdqu ymm6, [ rsi + 6 * SIZEOF_YWORD ]
	vmovdqu ymm7, [ rsi + 7 * SIZEOF_YWORD ]
	vmovdqu ymm8, [ rsi + 8 * SIZEOF_YWORD ]
	vmovdqu ymm9, [ rsi + 9 * SIZEOF_YWORD ]
	vmovdqa [ rdi + 0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi + 1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi + 2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi + 3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi + 4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi + 5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi + 6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi + 7 * SIZEOF_YWORD ], ymm7
	vmovdqa [ rdi + 8 * SIZEOF_YWORD ], ymm8
	vmovdqa [ rdi + 9 * SIZEOF_YWORD ], ymm9
	CLEAN_RET

align 16
.copy_11_ywords:
	vmovdqu ymm0,  [ rsi +  0 * SIZEOF_YWORD ]
	vmovdqu ymm1,  [ rsi +  1 * SIZEOF_YWORD ]
	vmovdqu ymm2,  [ rsi +  2 * SIZEOF_YWORD ]
	vmovdqu ymm3,  [ rsi +  3 * SIZEOF_YWORD ]
	vmovdqu ymm4,  [ rsi +  4 * SIZEOF_YWORD ]
	vmovdqu ymm5,  [ rsi +  5 * SIZEOF_YWORD ]
	vmovdqu ymm6,  [ rsi +  6 * SIZEOF_YWORD ]
	vmovdqu ymm7,  [ rsi +  7 * SIZEOF_YWORD ]
	vmovdqu ymm8,  [ rsi +  8 * SIZEOF_YWORD ]
	vmovdqu ymm9,  [ rsi +  9 * SIZEOF_YWORD ]
	vmovdqu ymm10, [ rsi + 10 * SIZEOF_YWORD ]
	vmovdqa [ rdi +  0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi +  1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi +  2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi +  3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi +  4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi +  5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi +  6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi +  7 * SIZEOF_YWORD ], ymm7
	vmovdqa [ rdi +  8 * SIZEOF_YWORD ], ymm8
	vmovdqa [ rdi +  9 * SIZEOF_YWORD ], ymm9
	vmovdqa [ rdi + 10 * SIZEOF_YWORD ], ymm10
	CLEAN_RET

align 16
.copy_12_ywords:
	vmovdqu ymm0,  [ rsi +  0 * SIZEOF_YWORD ]
	vmovdqu ymm1,  [ rsi +  1 * SIZEOF_YWORD ]
	vmovdqu ymm2,  [ rsi +  2 * SIZEOF_YWORD ]
	vmovdqu ymm3,  [ rsi +  3 * SIZEOF_YWORD ]
	vmovdqu ymm4,  [ rsi +  4 * SIZEOF_YWORD ]
	vmovdqu ymm5,  [ rsi +  5 * SIZEOF_YWORD ]
	vmovdqu ymm6,  [ rsi +  6 * SIZEOF_YWORD ]
	vmovdqu ymm7,  [ rsi +  7 * SIZEOF_YWORD ]
	vmovdqu ymm8,  [ rsi +  8 * SIZEOF_YWORD ]
	vmovdqu ymm9,  [ rsi +  9 * SIZEOF_YWORD ]
	vmovdqu ymm10, [ rsi + 10 * SIZEOF_YWORD ]
	vmovdqu ymm11, [ rsi + 11 * SIZEOF_YWORD ]
	vmovdqa [ rdi +  0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi +  1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi +  2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi +  3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi +  4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi +  5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi +  6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi +  7 * SIZEOF_YWORD ], ymm7
	vmovdqa [ rdi +  8 * SIZEOF_YWORD ], ymm8
	vmovdqa [ rdi +  9 * SIZEOF_YWORD ], ymm9
	vmovdqa [ rdi + 10 * SIZEOF_YWORD ], ymm10
	vmovdqa [ rdi + 11 * SIZEOF_YWORD ], ymm11
	CLEAN_RET

align 16
.copy_13_ywords:
	vmovdqu ymm0,  [ rsi +  0 * SIZEOF_YWORD ]
	vmovdqu ymm1,  [ rsi +  1 * SIZEOF_YWORD ]
	vmovdqu ymm2,  [ rsi +  2 * SIZEOF_YWORD ]
	vmovdqu ymm3,  [ rsi +  3 * SIZEOF_YWORD ]
	vmovdqu ymm4,  [ rsi +  4 * SIZEOF_YWORD ]
	vmovdqu ymm5,  [ rsi +  5 * SIZEOF_YWORD ]
	vmovdqu ymm6,  [ rsi +  6 * SIZEOF_YWORD ]
	vmovdqu ymm7,  [ rsi +  7 * SIZEOF_YWORD ]
	vmovdqu ymm8,  [ rsi +  8 * SIZEOF_YWORD ]
	vmovdqu ymm9,  [ rsi +  9 * SIZEOF_YWORD ]
	vmovdqu ymm10, [ rsi + 10 * SIZEOF_YWORD ]
	vmovdqu ymm11, [ rsi + 11 * SIZEOF_YWORD ]
	vmovdqu ymm12, [ rsi + 12 * SIZEOF_YWORD ]
	vmovdqa [ rdi +  0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi +  1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi +  2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi +  3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi +  4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi +  5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi +  6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi +  7 * SIZEOF_YWORD ], ymm7
	vmovdqa [ rdi +  8 * SIZEOF_YWORD ], ymm8
	vmovdqa [ rdi +  9 * SIZEOF_YWORD ], ymm9
	vmovdqa [ rdi + 10 * SIZEOF_YWORD ], ymm10
	vmovdqa [ rdi + 11 * SIZEOF_YWORD ], ymm11
	vmovdqa [ rdi + 12 * SIZEOF_YWORD ], ymm12
	CLEAN_RET

align 16
.copy_14_ywords:
	vmovdqu ymm0,  [ rsi +  0 * SIZEOF_YWORD ]
	vmovdqu ymm1,  [ rsi +  1 * SIZEOF_YWORD ]
	vmovdqu ymm2,  [ rsi +  2 * SIZEOF_YWORD ]
	vmovdqu ymm3,  [ rsi +  3 * SIZEOF_YWORD ]
	vmovdqu ymm4,  [ rsi +  4 * SIZEOF_YWORD ]
	vmovdqu ymm5,  [ rsi +  5 * SIZEOF_YWORD ]
	vmovdqu ymm6,  [ rsi +  6 * SIZEOF_YWORD ]
	vmovdqu ymm7,  [ rsi +  7 * SIZEOF_YWORD ]
	vmovdqu ymm8,  [ rsi +  8 * SIZEOF_YWORD ]
	vmovdqu ymm9,  [ rsi +  9 * SIZEOF_YWORD ]
	vmovdqu ymm10, [ rsi + 10 * SIZEOF_YWORD ]
	vmovdqu ymm11, [ rsi + 11 * SIZEOF_YWORD ]
	vmovdqu ymm12, [ rsi + 12 * SIZEOF_YWORD ]
	vmovdqu ymm13, [ rsi + 13 * SIZEOF_YWORD ]
	vmovdqa [ rdi +  0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi +  1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi +  2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi +  3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi +  4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi +  5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi +  6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi +  7 * SIZEOF_YWORD ], ymm7
	vmovdqa [ rdi +  8 * SIZEOF_YWORD ], ymm8
	vmovdqa [ rdi +  9 * SIZEOF_YWORD ], ymm9
	vmovdqa [ rdi + 10 * SIZEOF_YWORD ], ymm10
	vmovdqa [ rdi + 11 * SIZEOF_YWORD ], ymm11
	vmovdqa [ rdi + 12 * SIZEOF_YWORD ], ymm12
	vmovdqa [ rdi + 13 * SIZEOF_YWORD ], ymm13
	CLEAN_RET

align 16
.copy_15_ywords:
	vmovdqu ymm0,  [ rsi +  0 * SIZEOF_YWORD ]
	vmovdqu ymm1,  [ rsi +  1 * SIZEOF_YWORD ]
	vmovdqu ymm2,  [ rsi +  2 * SIZEOF_YWORD ]
	vmovdqu ymm3,  [ rsi +  3 * SIZEOF_YWORD ]
	vmovdqu ymm4,  [ rsi +  4 * SIZEOF_YWORD ]
	vmovdqu ymm5,  [ rsi +  5 * SIZEOF_YWORD ]
	vmovdqu ymm6,  [ rsi +  6 * SIZEOF_YWORD ]
	vmovdqu ymm7,  [ rsi +  7 * SIZEOF_YWORD ]
	vmovdqu ymm8,  [ rsi +  8 * SIZEOF_YWORD ]
	vmovdqu ymm9,  [ rsi +  9 * SIZEOF_YWORD ]
	vmovdqu ymm10, [ rsi + 10 * SIZEOF_YWORD ]
	vmovdqu ymm11, [ rsi + 11 * SIZEOF_YWORD ]
	vmovdqu ymm12, [ rsi + 12 * SIZEOF_YWORD ]
	vmovdqu ymm13, [ rsi + 13 * SIZEOF_YWORD ]
	vmovdqu ymm14, [ rsi + 14 * SIZEOF_YWORD ]
	vmovdqa [ rdi +  0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi +  1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi +  2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi +  3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi +  4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi +  5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi +  6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi +  7 * SIZEOF_YWORD ], ymm7
	vmovdqa [ rdi +  8 * SIZEOF_YWORD ], ymm8
	vmovdqa [ rdi +  9 * SIZEOF_YWORD ], ymm9
	vmovdqa [ rdi + 10 * SIZEOF_YWORD ], ymm10
	vmovdqa [ rdi + 11 * SIZEOF_YWORD ], ymm11
	vmovdqa [ rdi + 12 * SIZEOF_YWORD ], ymm12
	vmovdqa [ rdi + 13 * SIZEOF_YWORD ], ymm13
	vmovdqa [ rdi + 14 * SIZEOF_YWORD ], ymm14
	CLEAN_RET

align 16
.copy_16_ywords:
	vmovdqu ymm0,  [ rsi +  0 * SIZEOF_YWORD ]
	vmovdqu ymm1,  [ rsi +  1 * SIZEOF_YWORD ]
	vmovdqu ymm2,  [ rsi +  2 * SIZEOF_YWORD ]
	vmovdqu ymm3,  [ rsi +  3 * SIZEOF_YWORD ]
	vmovdqu ymm4,  [ rsi +  4 * SIZEOF_YWORD ]
	vmovdqu ymm5,  [ rsi +  5 * SIZEOF_YWORD ]
	vmovdqu ymm6,  [ rsi +  6 * SIZEOF_YWORD ]
	vmovdqu ymm7,  [ rsi +  7 * SIZEOF_YWORD ]
	vmovdqu ymm8,  [ rsi +  8 * SIZEOF_YWORD ]
	vmovdqu ymm9,  [ rsi +  9 * SIZEOF_YWORD ]
	vmovdqu ymm10, [ rsi + 10 * SIZEOF_YWORD ]
	vmovdqu ymm11, [ rsi + 11 * SIZEOF_YWORD ]
	vmovdqu ymm12, [ rsi + 12 * SIZEOF_YWORD ]
	vmovdqu ymm13, [ rsi + 13 * SIZEOF_YWORD ]
	vmovdqu ymm14, [ rsi + 14 * SIZEOF_YWORD ]
	vmovdqu ymm15, [ rsi + 15 * SIZEOF_YWORD ]
	vmovdqa [ rdi +  0 * SIZEOF_YWORD ], ymm0
	vmovdqa [ rdi +  1 * SIZEOF_YWORD ], ymm1
	vmovdqa [ rdi +  2 * SIZEOF_YWORD ], ymm2
	vmovdqa [ rdi +  3 * SIZEOF_YWORD ], ymm3
	vmovdqa [ rdi +  4 * SIZEOF_YWORD ], ymm4
	vmovdqa [ rdi +  5 * SIZEOF_YWORD ], ymm5
	vmovdqa [ rdi +  6 * SIZEOF_YWORD ], ymm6
	vmovdqa [ rdi +  7 * SIZEOF_YWORD ], ymm7
	vmovdqa [ rdi +  8 * SIZEOF_YWORD ], ymm8
	vmovdqa [ rdi +  9 * SIZEOF_YWORD ], ymm9
	vmovdqa [ rdi + 10 * SIZEOF_YWORD ], ymm10
	vmovdqa [ rdi + 11 * SIZEOF_YWORD ], ymm11
	vmovdqa [ rdi + 12 * SIZEOF_YWORD ], ymm12
	vmovdqa [ rdi + 13 * SIZEOF_YWORD ], ymm13
	vmovdqa [ rdi + 14 * SIZEOF_YWORD ], ymm14
	vmovdqa [ rdi + 15 * SIZEOF_YWORD ], ymm15
	CLEAN_RET

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
