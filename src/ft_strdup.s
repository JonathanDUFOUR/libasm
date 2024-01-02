global ft_strdup
extern ft_strcpy
extern ft_strlen
extern malloc

section .data

section .bss

section .text
; Duplicates a string, using dynamic memory allocation.
; The source string is assumed to be null-terminated.
; In case of error, sets errno properly.
;
; Parameters:
; rdi: the address of the source string to duplicate. (assumed to be a valid address)
;
; Return:
; rax: the address of the newly allocated string, or NULL in case of error.
ft_strdup:
.reserve:
	push rdi
	call ft_strlen
	inc rax
	mov rdi, rax
	call malloc wrt ..plt
	test rax, rax
	jz .return
.copy:
	mov rdi, rax
	pop rsi
	call ft_strcpy
.return:
	ret