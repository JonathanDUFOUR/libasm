global ft_memcpy

section .data

section .bss

section .text
; Copies N bytes from a memory area to another.
; The memory areas must not overlap.
;
; Parameters:
; rdi: the address of the destination memory area. (assumed to be a valid address)
; rsi: the address of the source memory area. (assumed to be a valid address)
; rdx: the number of bytes to copy.
;
; Return:
; rax: the address of the destination memory area.
ft_memcpy:
	mov rax, rdi
; check if both pointers can be aligned to a qword boundary
	mov rcx, rdi
	mov r8, rsi
	and rcx, 7 ; modulo 8
	and r8, 7 ; modulo 8
	cmp rcx, r8
	je .qword_alignment
; check if both pointers can be aligned to a dword boundary
	and rcx, 3 ; modulo 4
	and r8, 3 ; modulo 4
	cmp rcx, r8
	je .dword_alignment
; check if both pointers can be aligned to a word boundary
	and rcx, 1 ; modulo 2
	and r8, 1 ; modulo 2
	cmp rcx, r8
	je .word_alignment
.byte_copy:
; check if the number of bytes to copy is 0
	test rdx, rdx
	jz .return
; copy 1 byte
	mov cl, [rsi]
	mov [rdi], cl
; update the pointers and the number of bytes to copy
	inc rdi
	inc rsi
	dec rdx
; repeat until the number of bytes to copy is 0
	jmp .byte_copy
.word_alignment:
; check if both pointers are aligned to a word boundary
	test rdi, 1 ; modulo 2
	jz .word_copy
; check if the number of bytes to copy is 0
	test rdx, rdx
	jz .return
; copy 1 byte
	mov cl, [rsi]
	mov [rdi], cl
; update the pointers and the number of bytes to copy
	inc rdi
	inc rsi
	dec rdx
; repeat until either the pointers are aligned to a word boundary
; or the number of bytes to copy is 0
	jmp .word_alignment
.word_copy:
; check if the number of bytes to copy is less than 2
	cmp rdx, 2
	jb .last_byte_copy
; copy 2 bytes
	mov cx, [rsi]
	mov [rdi], cx
; update the pointers and the number of bytes to copy
	add rdi, 2
	add rsi, 2
	sub rdx, 2
; repeat until the number of bytes to copy is less than 2
	jmp .word_copy
.dword_alignment:
; check if both pointers are aligned to a dword boundary
	test rdi, 3 ; modulo 4
	jz .dword_copy
; check if the number of bytes to copy is 0
	test rdx, rdx
	jz .return
; copy 1 byte
	mov cl, [rsi]
	mov [rdi], cl
; update the pointers and the number of bytes to copy
	inc rdi
	inc rsi
	dec rdx
; repeat until either the pointers are aligned to a dword boundary
; or the number of bytes to copy is 0
	jmp .dword_alignment
.dword_copy:
; check if the number of bytes to copy is less than 4
	cmp rdx, 4
	jb .last_word_copy
; copy 4 bytes
	mov ecx, [rsi]
	mov [rdi], ecx
; update the pointers and the number of bytes to copy
	add rdi, 4
	add rsi, 4
	sub rdx, 4
; repeat until the number of bytes to copy is less than 4
	jmp .dword_copy
.qword_alignment:
; check if both pointers are aligned to a qword boundary
	test rdi, 7 ; modulo 8
	jz .qword_copy
; check if the number of bytes to copy is 0
	test rdx, rdx
	jz .return
; copy 1 byte
	mov cl, [rsi]
	mov [rdi], cl
; update the pointers and the number of bytes to copy
	inc rdi
	inc rsi
	dec rdx
; repeat until either the pointers are aligned to a qword boundary
; or the number of bytes to copy is 0
	jmp .qword_alignment
.qword_copy:
; check if the number of bytes to copy is less than 8
	cmp rdx, 8
	jb .last_dword_copy
; copy 8 bytes
	mov rcx, [rsi]
	mov [rdi], rcx
; update the pointers and the number of bytes to copy
	add rdi, 8
	add rsi, 8
	sub rdx, 8
; repeat until the number of bytes to copy is less than 8
	jmp .qword_copy
.last_dword_copy:
; check if the number of bytes to copy is less than 4
	cmp rdx, 4
	jb .last_word_copy
; copy 4 bytes
	mov ecx, [rsi]
	mov [rdi], ecx
; update the pointers and the number of bytes to copy
	add rdi, 4
	add rsi, 4
	sub rdx, 4
.last_word_copy:
; check if the number of bytes to copy is less than 2
	cmp rdx, 2
	jb .last_byte_copy
; copy 2 bytes
	mov cx, [rsi]
	mov [rdi], cx
; update the pointers and the number of bytes to copy
	add rdi, 2
	add rsi, 2
	sub rdx, 2
.last_byte_copy:
; check if the number of bytes to copy is 0
	test rdx, rdx
	jz .return
; copy 1 byte
	mov cl, [rsi]
	mov [rdi], cl
.return:
	ret
