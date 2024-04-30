global ft_strcmp

section .data

section .bss

section .text
; Compares two null-terminated strings.
;
; Parameters
; rdi: the address of the first string to compare. (assumed to be a valid address)
; rsi: the address of the second string to compare. (assumed to be a valid address)
;
; Return
; eax:
; - zero if the strings are equal.
; - a negative value if the first string is less than the second.
; - a positive value if the first string is greater than the second.
ft_strcmp:
	xor eax, eax
	xor ecx, ecx
.loop:
; compare the 2 current characters
	mov al, [rdi]
	mov cl, [rsi]
	sub eax, ecx
	jnz .end_of_loop
; check if the end of the second string is reached
	test cl, cl
	jz .end_of_loop
; step to the next character of each string
	inc rdi
	inc rsi
; repeat until either the current characters differ or the end of one of the strings is reached
	jmp .loop
.end_of_loop:
	ret
