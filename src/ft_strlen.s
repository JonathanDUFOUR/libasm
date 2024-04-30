global ft_strlen

section .data

section .bss

section .text
; Calculates the length of a null-terminated string.
;
; Parameters
; rdi: the address of the string to calculate the length of. (assumed to be a valid address)
;
; Return
; rax: the length of string.
ft_strlen:
	mov rax, rdi
.qword_alignment:
; check if the pointer is aligned to a qword boundary
	test rax, 7 ; modulo 8
	jz .qword_check
	mov cl, [rax]
; check if the end of the string has been reached
	test cl, cl
	jz .return
; update the pointer
	inc rax
; repeat until either the end of the string is reached or the pointer is aligned to a qword boundary
	jmp .qword_alignment
.qword_check:
	mov rcx, [rax]
; check if the next qword contains a null byte
	mov rdx, 0x0101010101010101
	sub rcx, rdx
	add rdx, rcx
	not rdx
	and rcx, rdx
	mov rdx, 0x8080808080808080
	and rcx, rdx
	jnz .found_null_byte
; update the pointer
	add rax, 8
; repeat until the next qword contains a null byte
	jmp .qword_check
; advance the pointer to the found null byte
.found_null_byte:
; calculate the position of the null byte using the number of trailing zeros
; REMIND: this is for a little-endian architecture. Use lzcnt instead of tzcnt for big-endian.
	tzcnt rcx, rcx
	shr rcx, 3
; add the position of the null byte to the pointer
	add rax, rcx
.return:
	sub rax, rdi
	ret
