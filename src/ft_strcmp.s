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
; eax:
; - 0 if the strings are equal.
; - a negative value if the first string is less than the second.
; - a positive value if the first string is greater than the second.
ft_strcmp:
	xor eax, eax
	xor ecx, ecx
.loop:
; check if the 2 current characters are the same
	mov al, [rdi]
	mov cl, [rsi]
	sub eax, ecx
	jnz .end_of_loop
; check if the end of the string has been reached
	test cl, cl
	jz .end_of_loop
; step to the next character of each string
	inc rdi
	inc rsi
; repeat until either the current characters differ or the end of the string has been reached
	jmp .loop
.end_of_loop:
	ret