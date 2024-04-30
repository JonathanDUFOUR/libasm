global ft_strcpy

section .data

section .bss

section .text
; Copy a string to another string.
; The source string is assumed to be null-terminated.
; The destination string is assumed to be large enough
; to hold the source string, including its null terminator.
;
; Parameters:
; rdi: the address of the destination string to copy to. (assumed to be a valid address)
; rsi: the address of the source string to copy from. (assumed to be a valid address)
;
; Return:
; rax: the address of the destination string.
ft_strcpy:
	mov rax, rdi
	mov rcx, rdi
	mov rdx, rsi
; check if both pointers can be aligned to a qword boundary
	and rcx, 7 ; modulo 8
	and rdx, 7 ; modulo 8
	cmp rcx, rdx
	je .qword_alignment
; check if both pointers can be aligned to a dword boundary
	and rcx, 3 ; modulo 4
	and rdx, 3 ; modulo 4
	cmp rcx, rdx
	je .dword_alignment
; check if both pointers can be aligned to a word boundary
	and rcx, 1 ; modulo 2
	and rdx, 1 ; modulo 2
	cmp rcx, rdx
	je .word_alignment
.byte_copy:
; copy 1 byte
	mov cl, [rsi]
	mov [rdi], cl
; check if the end of the string is reached
	test cl, cl
	jz .return
; update the pointers
	inc rdi
	inc rsi
; repeat until the end of the source string is reached
	jmp .byte_copy
.word_alignment:
; check if both pointers are aligned to a word boundary
	test rdi, 1 ; modulo 2
	jz .word_copy
; copy 1 byte
	mov cl, [rsi]
	mov [rdi], cl
; check if the end of the string is reached
	test cl, cl
	jz .return
; update the pointers
	inc rdi
	inc rsi
; repeat until either the pointers are aligned to a word boundary
; or the end of the string is reached
	jmp .word_alignment
.word_copy:
	mov cx, [rsi]
	mov dx, cx
; check if the next word contains a null byte
	sub dx, 0x0101
	not cx
	and dx, cx
	and dx, 0x8080
	jnz .last_byte_copy
	not cx
; copy 2 bytes
	mov [rdi], cx
; update the pointers
	add rdi, 2
	add rsi, 2
; repeat until the next word contains a null byte
	jmp .word_copy
.dword_alignment:
; check if both pointers are aligned to a dword boundary
	test rdi, 3 ; modulo 4
	jz .dword_copy
; copy 1 byte
	mov cl, [rsi]
	mov [rdi], cl
; check if the end of the string is reached
	test cl, cl
	jz .return
; update the pointers
	inc rdi
	inc rsi
; repeat until either the pointers are aligned to a dword boundary
; or the end of the string is reached
	jmp .dword_alignment
.dword_copy:
	mov ecx, [rsi]
	mov edx, ecx
; check if the next dword contains a null byte
	sub edx, 0x01010101
	not ecx
	and edx, ecx
	and edx, 0x80808080
	jnz .last_word_copy
	not ecx
; copy 4 bytes
	mov [rdi], ecx
; update the pointers
	add rdi, 4
	add rsi, 4
; repeat until the next dword contains a null byte
	jmp .dword_copy
.qword_alignment:
; check if both pointers are aligned to a qword boundary
	test rdi, 7 ; modulo 8
	jz .qword_copy
; copy 1 byte
	mov cl, [rsi]
	mov [rdi], cl
; check if the end of the string is reached
	test cl, cl
	jz .return
; update the pointers
	inc rdi
	inc rsi
; repeat until either the pointers are aligned to a qword boundary
; or the end of the string is reached
	jmp .qword_alignment
.qword_copy:
	mov rcx, [rsi]
	mov rdx, rcx
	mov r8, rcx
; check if the next qword contains a null byte
	mov r8, 0x0101010101010101
	sub rdx, r8
	add r8, rdx
	not r8
	and rdx, r8
	mov r8, 0x8080808080808080
	and rdx, r8
	jnz .last_dword_copy
; copy 8 bytes
	mov [rdi], rcx
; update the pointers
	add rdi, 8
	add rsi, 8
; repeat until the next qword contains a null byte
	jmp .qword_copy
.last_dword_copy:
	mov ecx, [rsi]
	mov edx, ecx
; check if the next dword contains a null byte
	sub edx, 0x01010101
	not ecx
	and edx, ecx
	and edx, 0x80808080
	jnz .last_word_copy
	not ecx
; copy 4 bytes
	mov [rdi], ecx
; update the pointers
	add rdi, 4
	add rsi, 4
.last_word_copy:
	mov cx, [rsi]
	mov dx, cx
; check if the next word contains a null byte
	sub dx, 0x0101
	not cx
	and dx, cx
	and dx, 0x8080
	jnz .last_byte_copy
	not cx
; copy 2 bytes
	mov [rdi], cx
; update the pointers
	add rdi, 2
	add rsi, 2
.last_byte_copy:
	mov cl, [rsi]
; check if the next byte is null
	test cl, cl
	jz .null_terminator
; copy 1 byte
	mov [rdi], cl
; update the destination pointer
	inc rdi
.null_terminator:
	mov byte [rdi], 0
.return:
	ret
