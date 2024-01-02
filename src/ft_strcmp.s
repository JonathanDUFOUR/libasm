global ft_strcmp

section .data

section .bss

section .text
; Compares two strings.
; Both strings are assumed to be null-terminated.
;
; Parameters
; rdi: the address of the first string to compare. (assumed to be a valid address)
; rsi: the address of the second string to compare. (assumed to be a valid address)
;
; Return
; rax:
; 	- 0 if the strings are equal.
; 	- a negative value if the first string is less than the second.
; 	- a positive value if the first string is greater than the second.
ft_strcmp:
	mov al, byte [rdi]
	cmp al, byte [rsi]
	jg .return_positive
	jl .return_negative
	test al, al
	jz .return_zero
	inc rdi
	inc rsi
	jmp ft_strcmp
.return_negative:
	or rax, -1
	ret
.return_positive:
	mov rax, 1
	ret
.return_zero:
	xor rax, rax
	ret