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
.loop:
; copy the current character from the source string to the destination string
	mov cl, [rsi]
	mov [rdi], cl
; check if the end of the source string has been reached
	test cl, cl
	jz .end_of_loop
; step to the next character
	inc rdi
	inc rsi
; repeat until the end of the source string has been reached
	jmp .loop
.end_of_loop:
	ret