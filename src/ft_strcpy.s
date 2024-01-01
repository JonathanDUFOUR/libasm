global ft_strcpy

section .data

section .bss

section .text
; Copy a string to another string.
; The source string must be null-terminated.
; The destination string must be large enough
; to hold the source string, including its null terminator.
;
; Parameters:
; rdi: the address of the destination string to copy to
; rsi: the address of the source string to copy from
;
; Return:
; rax: the address of the destination string
ft_strcpy:
	mov rax, rdi
.loop:
	mov cl, [rsi]
	mov [rdi], cl
	test cl, cl
	jz .ret
	inc rdi
	inc rsi
	jmp .loop
.ret:
	ret