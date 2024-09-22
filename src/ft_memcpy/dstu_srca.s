global ft_memcpy_dstu_srca: function

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

%macro UPDATE_POINTERS_TO_NEXT_YWORD_BOUNDARY_AND_UPDATE_NUMBER_OF_BYTES_TO_COPY_ACCORDINGLY 0
; copy the first and the last yword
	sub rdx, SIZEOF_YWORD ; corresponds to the last yword that is about to be copied
	vmovdqu ymm0, [rsi]
	vmovdqu ymm1, [rsi+rdx]
	vmovdqu [rdi], ymm0
	vmovdqu [rdi+rdx], ymm1
; calculate how far the source area is to its next yword boundary
	mov rcx, rsi
	neg rcx
	and rcx, 31 ; modulo 32
; advance both pointers by the calculated distance
	add rdi, rcx
	add rsi, rcx
; update the number of bytes to copy
	sub rdx, rcx
%endmacro

default rel

section .text
; Copies N bytes from a memory area to another.
; The memory areas are assumed to not overlap.
;
; Parameters:
; rdi: the address of the destination memory area. (assumed to be a valid address)
; rsi: the address of the source memory area. (assumed to be a valid address)
; rdx: the number of bytes to copy.
;
; Return:
; rax: the address of the destination memory area.
align 16
ft_memcpy_dstu_srca:
; preliminary initialization
	mov rax, rdi
; check if we can do a small copy
	cmp rdx, 545
	jb .copy_less_than_545_bytes
	UPDATE_POINTERS_TO_NEXT_YWORD_BOUNDARY_AND_UPDATE_NUMBER_OF_BYTES_TO_COPY_ACCORDINGLY
align 16
.copy_the_next_16_intermediate_ywords:
; update the number of intermediate bytes to copy
	sub rdx, 512
	jc .copy_less_than_16_intermediate_ywords
; load the next 16 intermediate ywords from the source memory area
	vmovdqa ymm0,  [rsi+0x000]
	vmovdqa ymm1,  [rsi+0x020]
	vmovdqa ymm2,  [rsi+0x040]
	vmovdqa ymm3,  [rsi+0x060]
	vmovdqa ymm4,  [rsi+0x080]
	vmovdqa ymm5,  [rsi+0x0A0]
	vmovdqa ymm6,  [rsi+0x0C0]
	vmovdqa ymm7,  [rsi+0x0E0]
	vmovdqa ymm8,  [rsi+0x100]
	vmovdqa ymm9,  [rsi+0x120]
	vmovdqa ymm10, [rsi+0x140]
	vmovdqa ymm11, [rsi+0x160]
	vmovdqa ymm12, [rsi+0x180]
	vmovdqa ymm13, [rsi+0x1A0]
	vmovdqa ymm14, [rsi+0x1C0]
	vmovdqa ymm15, [rsi+0x1E0]
; store the next 16 intermediate ywords to the destination memory area
	vmovdqu [rdi+0x000], ymm0
	vmovdqu [rdi+0x020], ymm1
	vmovdqu [rdi+0x040], ymm2
	vmovdqu [rdi+0x060], ymm3
	vmovdqu [rdi+0x080], ymm4
	vmovdqu [rdi+0x0A0], ymm5
	vmovdqu [rdi+0x0C0], ymm6
	vmovdqu [rdi+0x0E0], ymm7
	vmovdqu [rdi+0x100], ymm8
	vmovdqu [rdi+0x120], ymm9
	vmovdqu [rdi+0x140], ymm10
	vmovdqu [rdi+0x160], ymm11
	vmovdqu [rdi+0x180], ymm12
	vmovdqu [rdi+0x1A0], ymm13
	vmovdqu [rdi+0x1C0], ymm14
	vmovdqu [rdi+0x1E0], ymm15
; update the pointers
	add rdi, 16 * SIZEOF_YWORD
	add rsi, 16 * SIZEOF_YWORD
; repeat until there are less than 16 intermediate ywords to copy
	jmp .copy_the_next_16_intermediate_ywords

align 16
.copy_less_than_16_intermediate_ywords:
; calculate how many intermediate ywords remain to be copied
	add rdx, 512
	shr rdx, 5 ; divide by 32
; copy the remaining intermediate ywords
	lea rcx, [.small_copy_jump_table]
	jmp [rcx+rdx*SIZEOF_QWORD]

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
	mov cl, [rsi]
	mov sil, [rsi+rdx-SIZEOF_BYTE]
	mov [rdi], cl
	mov [rdi+rdx-SIZEOF_BYTE], sil
	ret

align 16
.copy_between_3_and_4_bytes:
	mov cx, [rsi]
	mov si, [rsi+rdx-SIZEOF_WORD]
	mov [rdi], cx
	mov [rdi+rdx-SIZEOF_WORD], si
	ret

align 16
.copy_between_5_and_8_bytes:
	mov ecx, [rsi]
	mov esi, [rsi+rdx-SIZEOF_DWORD]
	mov [rdi], ecx
	mov [rdi+rdx-SIZEOF_DWORD], esi
	ret

align 16
.copy_between_9_and_16_bytes:
	mov rcx, [rsi]
	mov rsi, [rsi+rdx-SIZEOF_QWORD]
	mov [rdi], rcx
	mov [rdi+rdx-SIZEOF_QWORD], rsi
	ret

align 16
.copy_between_17_and_32_bytes:
	movdqu xmm0, [rsi]
	movdqu xmm1, [rsi+rdx-SIZEOF_OWORD]
	movdqu [rdi], xmm0
	movdqu [rdi+rdx-SIZEOF_OWORD], xmm1
	ret

align 16
.copy_between_33_and_64_bytes:
	vmovdqu ymm0, [rsi]
	vmovdqu ymm1, [rsi+rdx-SIZEOF_YWORD]
	vmovdqu [rdi], ymm0
	vmovdqu [rdi+rdx-SIZEOF_YWORD], ymm1
	CLEAN_RET

align 16
.copy_between_65_and_544_bytes:
	UPDATE_POINTERS_TO_NEXT_YWORD_BOUNDARY_AND_UPDATE_NUMBER_OF_BYTES_TO_COPY_ACCORDINGLY
; calculate how many intermediate ywords shall be copied
	shr rdx, 5 ; divide by 32
	lea rcx, [.small_copy_jump_table]
	jmp [rcx+rdx*SIZEOF_QWORD]

align 16
.copy_1_yword:
	vmovdqa ymm0, [rsi]
	vmovdqu [rdi], ymm0
	CLEAN_RET

align 16
.copy_2_ywords:
	vmovdqa ymm0, [rsi+0x00]
	vmovdqa ymm1, [rsi+0x20]
	vmovdqu [rdi+0x00], ymm0
	vmovdqu [rdi+0x20], ymm1
	CLEAN_RET

align 16
.copy_3_ywords:
	vmovdqa ymm0, [rsi+0x00]
	vmovdqa ymm1, [rsi+0x20]
	vmovdqa ymm2, [rsi+0x40]
	vmovdqu [rdi+0x00], ymm0
	vmovdqu [rdi+0x20], ymm1
	vmovdqu [rdi+0x40], ymm2
	CLEAN_RET

align 16
.copy_4_ywords:
	vmovdqa ymm0, [rsi+0x00]
	vmovdqa ymm1, [rsi+0x20]
	vmovdqa ymm2, [rsi+0x40]
	vmovdqa ymm3, [rsi+0x60]
	vmovdqu [rdi+0x00], ymm0
	vmovdqu [rdi+0x20], ymm1
	vmovdqu [rdi+0x40], ymm2
	vmovdqu [rdi+0x60], ymm3
	CLEAN_RET

align 16
.copy_5_ywords:
	vmovdqa ymm0, [rsi+0x00]
	vmovdqa ymm1, [rsi+0x20]
	vmovdqa ymm2, [rsi+0x40]
	vmovdqa ymm3, [rsi+0x60]
	vmovdqa ymm4, [rsi+0x80]
	vmovdqu [rdi+0x00], ymm0
	vmovdqu [rdi+0x20], ymm1
	vmovdqu [rdi+0x40], ymm2
	vmovdqu [rdi+0x60], ymm3
	vmovdqu [rdi+0x80], ymm4
	CLEAN_RET

align 16
.copy_6_ywords:
	vmovdqa ymm0, [rsi+0x00]
	vmovdqa ymm1, [rsi+0x20]
	vmovdqa ymm2, [rsi+0x40]
	vmovdqa ymm3, [rsi+0x60]
	vmovdqa ymm4, [rsi+0x80]
	vmovdqa ymm5, [rsi+0xA0]
	vmovdqu [rdi+0x00], ymm0
	vmovdqu [rdi+0x20], ymm1
	vmovdqu [rdi+0x40], ymm2
	vmovdqu [rdi+0x60], ymm3
	vmovdqu [rdi+0x80], ymm4
	vmovdqu [rdi+0xA0], ymm5
	CLEAN_RET

align 16
.copy_7_ywords:
	vmovdqa ymm0, [rsi+0x00]
	vmovdqa ymm1, [rsi+0x20]
	vmovdqa ymm2, [rsi+0x40]
	vmovdqa ymm3, [rsi+0x60]
	vmovdqa ymm4, [rsi+0x80]
	vmovdqa ymm5, [rsi+0xA0]
	vmovdqa ymm6, [rsi+0xC0]
	vmovdqu [rdi+0x00], ymm0
	vmovdqu [rdi+0x20], ymm1
	vmovdqu [rdi+0x40], ymm2
	vmovdqu [rdi+0x60], ymm3
	vmovdqu [rdi+0x80], ymm4
	vmovdqu [rdi+0xA0], ymm5
	vmovdqu [rdi+0xC0], ymm6
	CLEAN_RET

align 16
.copy_8_ywords:
	vmovdqa ymm0, [rsi+0x00]
	vmovdqa ymm1, [rsi+0x20]
	vmovdqa ymm2, [rsi+0x40]
	vmovdqa ymm3, [rsi+0x60]
	vmovdqa ymm4, [rsi+0x80]
	vmovdqa ymm5, [rsi+0xA0]
	vmovdqa ymm6, [rsi+0xC0]
	vmovdqa ymm7, [rsi+0xE0]
	vmovdqu [rdi+0x00], ymm0
	vmovdqu [rdi+0x20], ymm1
	vmovdqu [rdi+0x40], ymm2
	vmovdqu [rdi+0x60], ymm3
	vmovdqu [rdi+0x80], ymm4
	vmovdqu [rdi+0xA0], ymm5
	vmovdqu [rdi+0xC0], ymm6
	vmovdqu [rdi+0xE0], ymm7
	CLEAN_RET

align 16
.copy_9_ywords:
	vmovdqa ymm0, [rsi+0x000]
	vmovdqa ymm1, [rsi+0x020]
	vmovdqa ymm2, [rsi+0x040]
	vmovdqa ymm3, [rsi+0x060]
	vmovdqa ymm4, [rsi+0x080]
	vmovdqa ymm5, [rsi+0x0A0]
	vmovdqa ymm6, [rsi+0x0C0]
	vmovdqa ymm7, [rsi+0x0E0]
	vmovdqa ymm8, [rsi+0x100]
	vmovdqu [rdi+0x000], ymm0
	vmovdqu [rdi+0x020], ymm1
	vmovdqu [rdi+0x040], ymm2
	vmovdqu [rdi+0x060], ymm3
	vmovdqu [rdi+0x080], ymm4
	vmovdqu [rdi+0x0A0], ymm5
	vmovdqu [rdi+0x0C0], ymm6
	vmovdqu [rdi+0x0E0], ymm7
	vmovdqu [rdi+0x100], ymm8
	CLEAN_RET

align 16
.copy_10_ywords:
	vmovdqa ymm0, [rsi+0x000]
	vmovdqa ymm1, [rsi+0x020]
	vmovdqa ymm2, [rsi+0x040]
	vmovdqa ymm3, [rsi+0x060]
	vmovdqa ymm4, [rsi+0x080]
	vmovdqa ymm5, [rsi+0x0A0]
	vmovdqa ymm6, [rsi+0x0C0]
	vmovdqa ymm7, [rsi+0x0E0]
	vmovdqa ymm8, [rsi+0x100]
	vmovdqa ymm9, [rsi+0x120]
	vmovdqu [rdi+0x000], ymm0
	vmovdqu [rdi+0x020], ymm1
	vmovdqu [rdi+0x040], ymm2
	vmovdqu [rdi+0x060], ymm3
	vmovdqu [rdi+0x080], ymm4
	vmovdqu [rdi+0x0A0], ymm5
	vmovdqu [rdi+0x0C0], ymm6
	vmovdqu [rdi+0x0E0], ymm7
	vmovdqu [rdi+0x100], ymm8
	vmovdqu [rdi+0x120], ymm9
	CLEAN_RET

align 16
.copy_11_ywords:
	vmovdqa ymm0,  [rsi+0x000]
	vmovdqa ymm1,  [rsi+0x020]
	vmovdqa ymm2,  [rsi+0x040]
	vmovdqa ymm3,  [rsi+0x060]
	vmovdqa ymm4,  [rsi+0x080]
	vmovdqa ymm5,  [rsi+0x0A0]
	vmovdqa ymm6,  [rsi+0x0C0]
	vmovdqa ymm7,  [rsi+0x0E0]
	vmovdqa ymm8,  [rsi+0x100]
	vmovdqa ymm9,  [rsi+0x120]
	vmovdqa ymm10, [rsi+0x140]
	vmovdqu [rdi+0x000], ymm0
	vmovdqu [rdi+0x020], ymm1
	vmovdqu [rdi+0x040], ymm2
	vmovdqu [rdi+0x060], ymm3
	vmovdqu [rdi+0x080], ymm4
	vmovdqu [rdi+0x0A0], ymm5
	vmovdqu [rdi+0x0C0], ymm6
	vmovdqu [rdi+0x0E0], ymm7
	vmovdqu [rdi+0x100], ymm8
	vmovdqu [rdi+0x120], ymm9
	vmovdqu [rdi+0x140], ymm10
	CLEAN_RET

align 16
.copy_12_ywords:
	vmovdqa ymm0,  [rsi+0x000]
	vmovdqa ymm1,  [rsi+0x020]
	vmovdqa ymm2,  [rsi+0x040]
	vmovdqa ymm3,  [rsi+0x060]
	vmovdqa ymm4,  [rsi+0x080]
	vmovdqa ymm5,  [rsi+0x0A0]
	vmovdqa ymm6,  [rsi+0x0C0]
	vmovdqa ymm7,  [rsi+0x0E0]
	vmovdqa ymm8,  [rsi+0x100]
	vmovdqa ymm9,  [rsi+0x120]
	vmovdqa ymm10, [rsi+0x140]
	vmovdqa ymm11, [rsi+0x160]
	vmovdqu [rdi+0x000], ymm0
	vmovdqu [rdi+0x020], ymm1
	vmovdqu [rdi+0x040], ymm2
	vmovdqu [rdi+0x060], ymm3
	vmovdqu [rdi+0x080], ymm4
	vmovdqu [rdi+0x0A0], ymm5
	vmovdqu [rdi+0x0C0], ymm6
	vmovdqu [rdi+0x0E0], ymm7
	vmovdqu [rdi+0x100], ymm8
	vmovdqu [rdi+0x120], ymm9
	vmovdqu [rdi+0x140], ymm10
	vmovdqu [rdi+0x160], ymm11
	CLEAN_RET

align 16
.copy_13_ywords:
	vmovdqa ymm0,  [rsi+0x000]
	vmovdqa ymm1,  [rsi+0x020]
	vmovdqa ymm2,  [rsi+0x040]
	vmovdqa ymm3,  [rsi+0x060]
	vmovdqa ymm4,  [rsi+0x080]
	vmovdqa ymm5,  [rsi+0x0A0]
	vmovdqa ymm6,  [rsi+0x0C0]
	vmovdqa ymm7,  [rsi+0x0E0]
	vmovdqa ymm8,  [rsi+0x100]
	vmovdqa ymm9,  [rsi+0x120]
	vmovdqa ymm10, [rsi+0x140]
	vmovdqa ymm11, [rsi+0x160]
	vmovdqa ymm12, [rsi+0x180]
	vmovdqu [rdi+0x000], ymm0
	vmovdqu [rdi+0x020], ymm1
	vmovdqu [rdi+0x040], ymm2
	vmovdqu [rdi+0x060], ymm3
	vmovdqu [rdi+0x080], ymm4
	vmovdqu [rdi+0x0A0], ymm5
	vmovdqu [rdi+0x0C0], ymm6
	vmovdqu [rdi+0x0E0], ymm7
	vmovdqu [rdi+0x100], ymm8
	vmovdqu [rdi+0x120], ymm9
	vmovdqu [rdi+0x140], ymm10
	vmovdqu [rdi+0x160], ymm11
	vmovdqu [rdi+0x180], ymm12
	CLEAN_RET

align 16
.copy_14_ywords:
	vmovdqa ymm0,  [rsi+0x000]
	vmovdqa ymm1,  [rsi+0x020]
	vmovdqa ymm2,  [rsi+0x040]
	vmovdqa ymm3,  [rsi+0x060]
	vmovdqa ymm4,  [rsi+0x080]
	vmovdqa ymm5,  [rsi+0x0A0]
	vmovdqa ymm6,  [rsi+0x0C0]
	vmovdqa ymm7,  [rsi+0x0E0]
	vmovdqa ymm8,  [rsi+0x100]
	vmovdqa ymm9,  [rsi+0x120]
	vmovdqa ymm10, [rsi+0x140]
	vmovdqa ymm11, [rsi+0x160]
	vmovdqa ymm12, [rsi+0x180]
	vmovdqa ymm13, [rsi+0x1A0]
	vmovdqu [rdi+0x000], ymm0
	vmovdqu [rdi+0x020], ymm1
	vmovdqu [rdi+0x040], ymm2
	vmovdqu [rdi+0x060], ymm3
	vmovdqu [rdi+0x080], ymm4
	vmovdqu [rdi+0x0A0], ymm5
	vmovdqu [rdi+0x0C0], ymm6
	vmovdqu [rdi+0x0E0], ymm7
	vmovdqu [rdi+0x100], ymm8
	vmovdqu [rdi+0x120], ymm9
	vmovdqu [rdi+0x140], ymm10
	vmovdqu [rdi+0x160], ymm11
	vmovdqu [rdi+0x180], ymm12
	vmovdqu [rdi+0x1A0], ymm13
	CLEAN_RET

align 16
.copy_15_ywords:
	vmovdqa ymm0,  [rsi+0x000]
	vmovdqa ymm1,  [rsi+0x020]
	vmovdqa ymm2,  [rsi+0x040]
	vmovdqa ymm3,  [rsi+0x060]
	vmovdqa ymm4,  [rsi+0x080]
	vmovdqa ymm5,  [rsi+0x0A0]
	vmovdqa ymm6,  [rsi+0x0C0]
	vmovdqa ymm7,  [rsi+0x0E0]
	vmovdqa ymm8,  [rsi+0x100]
	vmovdqa ymm9,  [rsi+0x120]
	vmovdqa ymm10, [rsi+0x140]
	vmovdqa ymm11, [rsi+0x160]
	vmovdqa ymm12, [rsi+0x180]
	vmovdqa ymm13, [rsi+0x1A0]
	vmovdqa ymm14, [rsi+0x1C0]
	vmovdqu [rdi+0x000], ymm0
	vmovdqu [rdi+0x020], ymm1
	vmovdqu [rdi+0x040], ymm2
	vmovdqu [rdi+0x060], ymm3
	vmovdqu [rdi+0x080], ymm4
	vmovdqu [rdi+0x0A0], ymm5
	vmovdqu [rdi+0x0C0], ymm6
	vmovdqu [rdi+0x0E0], ymm7
	vmovdqu [rdi+0x100], ymm8
	vmovdqu [rdi+0x120], ymm9
	vmovdqu [rdi+0x140], ymm10
	vmovdqu [rdi+0x160], ymm11
	vmovdqu [rdi+0x180], ymm12
	vmovdqu [rdi+0x1A0], ymm13
	vmovdqu [rdi+0x1C0], ymm14
	CLEAN_RET

align 16
.copy_16_ywords:
	vmovdqa ymm0,  [rsi+0x000]
	vmovdqa ymm1,  [rsi+0x020]
	vmovdqa ymm2,  [rsi+0x040]
	vmovdqa ymm3,  [rsi+0x060]
	vmovdqa ymm4,  [rsi+0x080]
	vmovdqa ymm5,  [rsi+0x0A0]
	vmovdqa ymm6,  [rsi+0x0C0]
	vmovdqa ymm7,  [rsi+0x0E0]
	vmovdqa ymm8,  [rsi+0x100]
	vmovdqa ymm9,  [rsi+0x120]
	vmovdqa ymm10, [rsi+0x140]
	vmovdqa ymm11, [rsi+0x160]
	vmovdqa ymm12, [rsi+0x180]
	vmovdqa ymm13, [rsi+0x1A0]
	vmovdqa ymm14, [rsi+0x1C0]
	vmovdqa ymm15, [rsi+0x1E0]
	vmovdqu [rdi+0x000], ymm0
	vmovdqu [rdi+0x020], ymm1
	vmovdqu [rdi+0x040], ymm2
	vmovdqu [rdi+0x060], ymm3
	vmovdqu [rdi+0x080], ymm4
	vmovdqu [rdi+0x0A0], ymm5
	vmovdqu [rdi+0x0C0], ymm6
	vmovdqu [rdi+0x0E0], ymm7
	vmovdqu [rdi+0x100], ymm8
	vmovdqu [rdi+0x120], ymm9
	vmovdqu [rdi+0x140], ymm10
	vmovdqu [rdi+0x160], ymm11
	vmovdqu [rdi+0x180], ymm12
	vmovdqu [rdi+0x1A0], ymm13
	vmovdqu [rdi+0x1C0], ymm14
	vmovdqu [rdi+0x1E0], ymm15
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
