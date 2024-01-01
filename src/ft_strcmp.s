global ft_strcmp

section .data

section .bss

section .text
; Compares two strings.
; Both strings must be null-terminated.
;
; Parameters
; rdi: The address of the first string to compare
; rsi: The address of the second string to compare
;
; Return
; rax:
; 	- 0 if the strings are equal
; 	- a negative value if the first string is less than the second
; 	- a positive value if the first string is greater than the second
ft_strcmp:
	mov ah, byte [rdi]
	cmp ah, byte [rsi]
	jg .positive_return
	jl .negative_return
	test ah, ah
	jz .zero_return
	inc rdi
	inc rsi
	jmp ft_strcmp
.negative_return:
	or rax, -1
	ret
.positive_return:
	mov rax, 1
	ret
.zero_return:
	xor rax, rax
	ret