global ft_strlen

section .data

section .bss

section .text
; Calculates the length of a nul-terminated string
;
; Parameters
; rdi: the address of the nul-terminated string to calculate the length of
;
; Return
; rax: the length of string
ft_strlen:
	mov rax, rdi
.loop:
	cmp byte [rax], 0
	je .end
	inc rax
	jmp .loop
.end:
	sub rax, rdi
	ret