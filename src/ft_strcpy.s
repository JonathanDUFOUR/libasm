global ft_strcpy: function

%use smartalign
ALIGNMODE p6

extern ft_strlen: function
extern ft_memcpy: function

section .text
; Copies a string to another string.
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
; calculate the length of the source string
	xchg rdi, rsi
align 16
	call ft_strlen
; copy the source string to the destination string
	xchg rdi, rsi
	lea rdx, [rax + 1]
	jmp ft_memcpy
