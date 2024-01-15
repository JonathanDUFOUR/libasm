global ft_strlen

section .data

section .bss

section .text
; Calculates the length of a string.
; The string is assumed to be null terminated.
;
; Parameters
; rdi: the address of the string to calculate the length of. (assumed to be a valid address)
;
; Return
; rax: the length of string.
ft_strlen:
	mov rax, rdi
.loop:
	mov cl, [rax]
; check if the end of the string has been reached
	test cl, cl
	jz .ret
; step to the next character
	inc rax
	jmp .loop
.ret:
	sub rax, rdi
	ret