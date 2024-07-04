global ft_memcpy: function

%use smartalign
ALIGNMODE p6

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
ft_memcpy:
; preliminary initialization
	mov rax, rdi
; check if we can do a small copy
	cmp rdx, 545
	jb .copy_less_than_545_bytes
; copy the first 32 bytes and the last 32 bytes
	vmovdqu ymm0, [rsi]
	vmovdqu ymm1, [rsi+rdx-32]
	vmovdqu [rdi], ymm0
	vmovdqu [rdi+rdx-32], ymm1
; calculate how far the destination pointer is to its next yword boundary
	lea rcx, [rdi+32]
	and rcx, -32
	sub rcx, rdi
; advance both the destination pointer and the source pointer by the calculated distance
	add rdi, rcx
	add rsi, rcx
; calculate how many intermediate bytes shall be copied
	sub rdx, rcx
	sub rdx, 32 ; corresponds to the already copied last 32 bytes
align 16
.copy_the_next_512_intermediate_bytes:
; update the number of intermediate bytes to copy
	sub rdx, 512
	jc .copy_less_than_512_intermediate_bytes
; copy 512 intermediate bytes at a time
	vmovdqu ymm0,  [rsi+0x000]
	vmovdqu ymm1,  [rsi+0x020]
	vmovdqu ymm2,  [rsi+0x040]
	vmovdqu ymm3,  [rsi+0x060]
	vmovdqu ymm4,  [rsi+0x080]
	vmovdqu ymm5,  [rsi+0x0A0]
	vmovdqu ymm6,  [rsi+0x0C0]
	vmovdqu ymm7,  [rsi+0x0E0]
	vmovdqu ymm8,  [rsi+0x100]
	vmovdqu ymm9,  [rsi+0x120]
	vmovdqu ymm10, [rsi+0x140]
	vmovdqu ymm11, [rsi+0x160]
	vmovdqu ymm12, [rsi+0x180]
	vmovdqu ymm13, [rsi+0x1A0]
	vmovdqu ymm14, [rsi+0x1C0]
	vmovdqu ymm15, [rsi+0x1E0]
	vmovdqa [rdi+0x000], ymm0
	vmovdqa [rdi+0x020], ymm1
	vmovdqa [rdi+0x040], ymm2
	vmovdqa [rdi+0x060], ymm3
	vmovdqa [rdi+0x080], ymm4
	vmovdqa [rdi+0x0A0], ymm5
	vmovdqa [rdi+0x0C0], ymm6
	vmovdqa [rdi+0x0E0], ymm7
	vmovdqa [rdi+0x100], ymm8
	vmovdqa [rdi+0x120], ymm9
	vmovdqa [rdi+0x140], ymm10
	vmovdqa [rdi+0x160], ymm11
	vmovdqa [rdi+0x180], ymm12
	vmovdqa [rdi+0x1A0], ymm13
	vmovdqa [rdi+0x1C0], ymm14
	vmovdqa [rdi+0x1E0], ymm15
; update the pointers
	add rdi, 512
	add rsi, 512
; repeat until there are less than 512 intermediate bytes to copy
	jmp .copy_the_next_512_intermediate_bytes

align 16
.copy_less_than_512_intermediate_bytes:
; calculate how many intermediate 32-bytes chunks remain to be copied
	add rdx, 512
	shr rdx, 5 ; divide by 32
; copy the remaining intermediate 32-bytes chunks
	lea rcx, [.small_copy_jump_table]
	jmp [rcx+rdx*8]

align 16
.copy_less_than_545_bytes:
	cmp rdx, 64
	ja .copy_between_65_and_544_bytes
	cmp rdx, 32
	ja .copy_between_33_and_64_bytes
	cmp rdx, 16
	ja .copy_between_17_and_32_bytes
	cmp rdx, 8
	ja .copy_between_9_and_16_bytes
	cmp rdx, 4
	ja .copy_between_5_and_8_bytes
	cmp rdx, 2
	ja .copy_between_3_and_4_bytes
	test rdx, rdx
	jnz .copy_between_1_and_2_bytes
	ret

align 16
.copy_between_1_and_2_bytes:
	mov cl, [rsi]
	mov sil, [rsi+rdx-1]
	mov [rdi], cl
	mov [rdi+rdx-1], sil
	ret

align 16
.copy_between_3_and_4_bytes:
	mov cx, [rsi]
	mov si, [rsi+rdx-2]
	mov [rdi], cx
	mov [rdi+rdx-2], si
	ret

align 16
.copy_between_5_and_8_bytes:
	mov ecx, [rsi]
	mov esi, [rsi+rdx-4]
	mov [rdi], ecx
	mov [rdi+rdx-4], esi
	ret

align 16
.copy_between_9_and_16_bytes:
	mov rcx, [rsi]
	mov rsi, [rsi+rdx-8]
	mov [rdi], rcx
	mov [rdi+rdx-8], rsi
	ret

align 16
.copy_between_17_and_32_bytes:
	movdqu xmm0, [rsi]
	movdqu xmm1, [rsi+rdx-16]
	movdqu [rdi], xmm0
	movdqu [rdi+rdx-16], xmm1
	ret

align 16
.copy_between_33_and_64_bytes:
	vmovdqu ymm0, [rsi]
	vmovdqu ymm1, [rsi+rdx-32]
	vmovdqu [rdi], ymm0
	vmovdqu [rdi+rdx-32], ymm1
	ret

align 16
.copy_between_65_and_544_bytes:
; copy the first 32 bytes and the last 32 bytes
	vmovdqu ymm0, [rsi]
	vmovdqu ymm1, [rsi+rdx-32]
	vmovdqu [rdi], ymm0
	vmovdqu [rdi+rdx-32], ymm1
; calculate how far the destination pointer is to its next yword boundary
	mov rcx, rdi
	neg rcx
	and rcx, 31 ; modulo 32
; advance both the destination pointer and the source pointer by the calculated distance
	add rdi, rcx
	add rsi, rcx
; calculate how many intermediate 32-bytes chunks shall be copied
	sub rdx, rcx
	sub rdx, 32
	shr rdx, 5 ; divide by 32
	lea rcx, [.small_copy_jump_table]
	jmp [rcx+rdx*8]

align 16
.copy_1_chunk:
	vmovdqu ymm0, [rsi]
	vmovdqa [rdi], ymm0
	ret

align 16
.copy_2_chunks:
	vmovdqu ymm0, [rsi+0x00]
	vmovdqu ymm1, [rsi+0x20]
	vmovdqa [rdi+0x00], ymm0
	vmovdqa [rdi+0x20], ymm1
	ret

align 16
.copy_3_chunks:
	vmovdqu ymm0, [rsi+0x00]
	vmovdqu ymm1, [rsi+0x20]
	vmovdqu ymm2, [rsi+0x40]
	vmovdqa [rdi+0x00], ymm0
	vmovdqa [rdi+0x20], ymm1
	vmovdqa [rdi+0x40], ymm2
	ret

align 16
.copy_4_chunks:
	vmovdqu ymm0, [rsi+0x00]
	vmovdqu ymm1, [rsi+0x20]
	vmovdqu ymm2, [rsi+0x40]
	vmovdqu ymm3, [rsi+0x60]
	vmovdqa [rdi+0x00], ymm0
	vmovdqa [rdi+0x20], ymm1
	vmovdqa [rdi+0x40], ymm2
	vmovdqa [rdi+0x60], ymm3
	ret

align 16
.copy_5_chunks:
	vmovdqu ymm0, [rsi+0x00]
	vmovdqu ymm1, [rsi+0x20]
	vmovdqu ymm2, [rsi+0x40]
	vmovdqu ymm3, [rsi+0x60]
	vmovdqu ymm4, [rsi+0x80]
	vmovdqa [rdi+0x00], ymm0
	vmovdqa [rdi+0x20], ymm1
	vmovdqa [rdi+0x40], ymm2
	vmovdqa [rdi+0x60], ymm3
	vmovdqa [rdi+0x80], ymm4
	ret

align 16
.copy_6_chunks:
	vmovdqu ymm0, [rsi+0x00]
	vmovdqu ymm1, [rsi+0x20]
	vmovdqu ymm2, [rsi+0x40]
	vmovdqu ymm3, [rsi+0x60]
	vmovdqu ymm4, [rsi+0x80]
	vmovdqu ymm5, [rsi+0xA0]
	vmovdqa [rdi+0x00], ymm0
	vmovdqa [rdi+0x20], ymm1
	vmovdqa [rdi+0x40], ymm2
	vmovdqa [rdi+0x60], ymm3
	vmovdqa [rdi+0x80], ymm4
	vmovdqa [rdi+0xA0], ymm5
	ret

align 16
.copy_7_chunks:
	vmovdqu ymm0, [rsi+0x00]
	vmovdqu ymm1, [rsi+0x20]
	vmovdqu ymm2, [rsi+0x40]
	vmovdqu ymm3, [rsi+0x60]
	vmovdqu ymm4, [rsi+0x80]
	vmovdqu ymm5, [rsi+0xA0]
	vmovdqu ymm6, [rsi+0xC0]
	vmovdqa [rdi+0x00], ymm0
	vmovdqa [rdi+0x20], ymm1
	vmovdqa [rdi+0x40], ymm2
	vmovdqa [rdi+0x60], ymm3
	vmovdqa [rdi+0x80], ymm4
	vmovdqa [rdi+0xA0], ymm5
	vmovdqa [rdi+0xC0], ymm6
	ret

align 16
.copy_8_chunks:
	vmovdqu ymm0, [rsi+0x00]
	vmovdqu ymm1, [rsi+0x20]
	vmovdqu ymm2, [rsi+0x40]
	vmovdqu ymm3, [rsi+0x60]
	vmovdqu ymm4, [rsi+0x80]
	vmovdqu ymm5, [rsi+0xA0]
	vmovdqu ymm6, [rsi+0xC0]
	vmovdqu ymm7, [rsi+0xE0]
	vmovdqa [rdi+0x00], ymm0
	vmovdqa [rdi+0x20], ymm1
	vmovdqa [rdi+0x40], ymm2
	vmovdqa [rdi+0x60], ymm3
	vmovdqa [rdi+0x80], ymm4
	vmovdqa [rdi+0xA0], ymm5
	vmovdqa [rdi+0xC0], ymm6
	vmovdqa [rdi+0xE0], ymm7
	ret

align 16
.copy_9_chunks:
	vmovdqu ymm0, [rsi+0x000]
	vmovdqu ymm1, [rsi+0x020]
	vmovdqu ymm2, [rsi+0x040]
	vmovdqu ymm3, [rsi+0x060]
	vmovdqu ymm4, [rsi+0x080]
	vmovdqu ymm5, [rsi+0x0A0]
	vmovdqu ymm6, [rsi+0x0C0]
	vmovdqu ymm7, [rsi+0x0E0]
	vmovdqu ymm8, [rsi+0x100]
	vmovdqa [rdi+0x000], ymm0
	vmovdqa [rdi+0x020], ymm1
	vmovdqa [rdi+0x040], ymm2
	vmovdqa [rdi+0x060], ymm3
	vmovdqa [rdi+0x080], ymm4
	vmovdqa [rdi+0x0A0], ymm5
	vmovdqa [rdi+0x0C0], ymm6
	vmovdqa [rdi+0x0E0], ymm7
	vmovdqa [rdi+0x100], ymm8
	ret

align 16
.copy_10_chunks:
	vmovdqu ymm0, [rsi+0x000]
	vmovdqu ymm1, [rsi+0x020]
	vmovdqu ymm2, [rsi+0x040]
	vmovdqu ymm3, [rsi+0x060]
	vmovdqu ymm4, [rsi+0x080]
	vmovdqu ymm5, [rsi+0x0A0]
	vmovdqu ymm6, [rsi+0x0C0]
	vmovdqu ymm7, [rsi+0x0E0]
	vmovdqu ymm8, [rsi+0x100]
	vmovdqu ymm9, [rsi+0x120]
	vmovdqa [rdi+0x000], ymm0
	vmovdqa [rdi+0x020], ymm1
	vmovdqa [rdi+0x040], ymm2
	vmovdqa [rdi+0x060], ymm3
	vmovdqa [rdi+0x080], ymm4
	vmovdqa [rdi+0x0A0], ymm5
	vmovdqa [rdi+0x0C0], ymm6
	vmovdqa [rdi+0x0E0], ymm7
	vmovdqa [rdi+0x100], ymm8
	vmovdqa [rdi+0x120], ymm9
	ret

align 16
.copy_11_chunks:
	vmovdqu ymm0,  [rsi+0x000]
	vmovdqu ymm1,  [rsi+0x020]
	vmovdqu ymm2,  [rsi+0x040]
	vmovdqu ymm3,  [rsi+0x060]
	vmovdqu ymm4,  [rsi+0x080]
	vmovdqu ymm5,  [rsi+0x0A0]
	vmovdqu ymm6,  [rsi+0x0C0]
	vmovdqu ymm7,  [rsi+0x0E0]
	vmovdqu ymm8,  [rsi+0x100]
	vmovdqu ymm9,  [rsi+0x120]
	vmovdqu ymm10, [rsi+0x140]
	vmovdqa [rdi+0x000], ymm0
	vmovdqa [rdi+0x020], ymm1
	vmovdqa [rdi+0x040], ymm2
	vmovdqa [rdi+0x060], ymm3
	vmovdqa [rdi+0x080], ymm4
	vmovdqa [rdi+0x0A0], ymm5
	vmovdqa [rdi+0x0C0], ymm6
	vmovdqa [rdi+0x0E0], ymm7
	vmovdqa [rdi+0x100], ymm8
	vmovdqa [rdi+0x120], ymm9
	vmovdqa [rdi+0x140], ymm10
	ret

align 16
.copy_12_chunks:
	vmovdqu ymm0,  [rsi+0x000]
	vmovdqu ymm1,  [rsi+0x020]
	vmovdqu ymm2,  [rsi+0x040]
	vmovdqu ymm3,  [rsi+0x060]
	vmovdqu ymm4,  [rsi+0x080]
	vmovdqu ymm5,  [rsi+0x0A0]
	vmovdqu ymm6,  [rsi+0x0C0]
	vmovdqu ymm7,  [rsi+0x0E0]
	vmovdqu ymm8,  [rsi+0x100]
	vmovdqu ymm9,  [rsi+0x120]
	vmovdqu ymm10, [rsi+0x140]
	vmovdqu ymm11, [rsi+0x160]
	vmovdqa [rdi+0x000], ymm0
	vmovdqa [rdi+0x020], ymm1
	vmovdqa [rdi+0x040], ymm2
	vmovdqa [rdi+0x060], ymm3
	vmovdqa [rdi+0x080], ymm4
	vmovdqa [rdi+0x0A0], ymm5
	vmovdqa [rdi+0x0C0], ymm6
	vmovdqa [rdi+0x0E0], ymm7
	vmovdqa [rdi+0x100], ymm8
	vmovdqa [rdi+0x120], ymm9
	vmovdqa [rdi+0x140], ymm10
	vmovdqa [rdi+0x160], ymm11
	ret

align 16
.copy_13_chunks:
	vmovdqu ymm0,  [rsi+0x000]
	vmovdqu ymm1,  [rsi+0x020]
	vmovdqu ymm2,  [rsi+0x040]
	vmovdqu ymm3,  [rsi+0x060]
	vmovdqu ymm4,  [rsi+0x080]
	vmovdqu ymm5,  [rsi+0x0A0]
	vmovdqu ymm6,  [rsi+0x0C0]
	vmovdqu ymm7,  [rsi+0x0E0]
	vmovdqu ymm8,  [rsi+0x100]
	vmovdqu ymm9,  [rsi+0x120]
	vmovdqu ymm10, [rsi+0x140]
	vmovdqu ymm11, [rsi+0x160]
	vmovdqu ymm12, [rsi+0x180]
	vmovdqa [rdi+0x000], ymm0
	vmovdqa [rdi+0x020], ymm1
	vmovdqa [rdi+0x040], ymm2
	vmovdqa [rdi+0x060], ymm3
	vmovdqa [rdi+0x080], ymm4
	vmovdqa [rdi+0x0A0], ymm5
	vmovdqa [rdi+0x0C0], ymm6
	vmovdqa [rdi+0x0E0], ymm7
	vmovdqa [rdi+0x100], ymm8
	vmovdqa [rdi+0x120], ymm9
	vmovdqa [rdi+0x140], ymm10
	vmovdqa [rdi+0x160], ymm11
	vmovdqa [rdi+0x180], ymm12
	ret

align 16
.copy_14_chunks:
	vmovdqu ymm0,  [rsi+0x000]
	vmovdqu ymm1,  [rsi+0x020]
	vmovdqu ymm2,  [rsi+0x040]
	vmovdqu ymm3,  [rsi+0x060]
	vmovdqu ymm4,  [rsi+0x080]
	vmovdqu ymm5,  [rsi+0x0A0]
	vmovdqu ymm6,  [rsi+0x0C0]
	vmovdqu ymm7,  [rsi+0x0E0]
	vmovdqu ymm8,  [rsi+0x100]
	vmovdqu ymm9,  [rsi+0x120]
	vmovdqu ymm10, [rsi+0x140]
	vmovdqu ymm11, [rsi+0x160]
	vmovdqu ymm12, [rsi+0x180]
	vmovdqu ymm13, [rsi+0x1A0]
	vmovdqa [rdi+0x000], ymm0
	vmovdqa [rdi+0x020], ymm1
	vmovdqa [rdi+0x040], ymm2
	vmovdqa [rdi+0x060], ymm3
	vmovdqa [rdi+0x080], ymm4
	vmovdqa [rdi+0x0A0], ymm5
	vmovdqa [rdi+0x0C0], ymm6
	vmovdqa [rdi+0x0E0], ymm7
	vmovdqa [rdi+0x100], ymm8
	vmovdqa [rdi+0x120], ymm9
	vmovdqa [rdi+0x140], ymm10
	vmovdqa [rdi+0x160], ymm11
	vmovdqa [rdi+0x180], ymm12
	vmovdqa [rdi+0x1A0], ymm13
	ret

align 16
.copy_15_chunks:
	vmovdqu ymm0,  [rsi+0x000]
	vmovdqu ymm1,  [rsi+0x020]
	vmovdqu ymm2,  [rsi+0x040]
	vmovdqu ymm3,  [rsi+0x060]
	vmovdqu ymm4,  [rsi+0x080]
	vmovdqu ymm5,  [rsi+0x0A0]
	vmovdqu ymm6,  [rsi+0x0C0]
	vmovdqu ymm7,  [rsi+0x0E0]
	vmovdqu ymm8,  [rsi+0x100]
	vmovdqu ymm9,  [rsi+0x120]
	vmovdqu ymm10, [rsi+0x140]
	vmovdqu ymm11, [rsi+0x160]
	vmovdqu ymm12, [rsi+0x180]
	vmovdqu ymm13, [rsi+0x1A0]
	vmovdqu ymm14, [rsi+0x1C0]
	vmovdqa [rdi+0x000], ymm0
	vmovdqa [rdi+0x020], ymm1
	vmovdqa [rdi+0x040], ymm2
	vmovdqa [rdi+0x060], ymm3
	vmovdqa [rdi+0x080], ymm4
	vmovdqa [rdi+0x0A0], ymm5
	vmovdqa [rdi+0x0C0], ymm6
	vmovdqa [rdi+0x0E0], ymm7
	vmovdqa [rdi+0x100], ymm8
	vmovdqa [rdi+0x120], ymm9
	vmovdqa [rdi+0x140], ymm10
	vmovdqa [rdi+0x160], ymm11
	vmovdqa [rdi+0x180], ymm12
	vmovdqa [rdi+0x1A0], ymm13
	vmovdqa [rdi+0x1C0], ymm14
	ret

align 16
.copy_16_chunks:
	vmovdqu ymm0,  [rsi+0x000]
	vmovdqu ymm1,  [rsi+0x020]
	vmovdqu ymm2,  [rsi+0x040]
	vmovdqu ymm3,  [rsi+0x060]
	vmovdqu ymm4,  [rsi+0x080]
	vmovdqu ymm5,  [rsi+0x0A0]
	vmovdqu ymm6,  [rsi+0x0C0]
	vmovdqu ymm7,  [rsi+0x0E0]
	vmovdqu ymm8,  [rsi+0x100]
	vmovdqu ymm9,  [rsi+0x120]
	vmovdqu ymm10, [rsi+0x140]
	vmovdqu ymm11, [rsi+0x160]
	vmovdqu ymm12, [rsi+0x180]
	vmovdqu ymm13, [rsi+0x1A0]
	vmovdqu ymm14, [rsi+0x1C0]
	vmovdqu ymm15, [rsi+0x1E0]
	vmovdqa [rdi+0x000], ymm0
	vmovdqa [rdi+0x020], ymm1
	vmovdqa [rdi+0x040], ymm2
	vmovdqa [rdi+0x060], ymm3
	vmovdqa [rdi+0x080], ymm4
	vmovdqa [rdi+0x0A0], ymm5
	vmovdqa [rdi+0x0C0], ymm6
	vmovdqa [rdi+0x0E0], ymm7
	vmovdqa [rdi+0x100], ymm8
	vmovdqa [rdi+0x120], ymm9
	vmovdqa [rdi+0x140], ymm10
	vmovdqa [rdi+0x160], ymm11
	vmovdqa [rdi+0x180], ymm12
	vmovdqa [rdi+0x1A0], ymm13
	vmovdqa [rdi+0x1C0], ymm14
	vmovdqa [rdi+0x1E0], ymm15
	ret

section .rodata
.small_copy_jump_table:
	dq .copy_1_chunk
	dq .copy_2_chunks
	dq .copy_3_chunks
	dq .copy_4_chunks
	dq .copy_5_chunks
	dq .copy_6_chunks
	dq .copy_7_chunks
	dq .copy_8_chunks
	dq .copy_9_chunks
	dq .copy_10_chunks
	dq .copy_11_chunks
	dq .copy_12_chunks
	dq .copy_13_chunks
	dq .copy_14_chunks
	dq .copy_15_chunks
	dq .copy_16_chunks
