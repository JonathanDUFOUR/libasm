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
; - 0 if the strings are equal.
; - a negative value if the first string is less than the second.
; - a positive value if the first string is greater than the second.
ft_strcmp:
	xor rax, rax
	xor rcx, rcx
.loop:
	mov al, [rdi]
	mov cl, [rsi]
	cmp al, cl
	jne .diff
	test al, al
	jz .ret
	inc rdi
	inc rsi
	jmp .loop
.diff:
	sub rax, rcx
.ret:
	ret