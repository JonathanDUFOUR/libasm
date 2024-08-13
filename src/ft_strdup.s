global ft_strdup: function

%use smartalign
ALIGNMODE p6

extern ft_memcpy: function
extern ft_strlen: function
extern malloc: function

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
align 16
ft_strdup:
; reserve
	push rdi ; preserve the address of the source string
	call ft_strlen
	inc rax ; add 1 for the null-terminator
	push rax ; preserve the number of bytes to allocate and to copy
	mov rdi, rax
	call malloc wrt ..plt
; check if malloc failed
	test rax, rax
	jz .malloc_failed
; copy
	pop rdx ; restore the number of bytes to copy
	pop rsi ; restore the address of the source string
	mov rdi, rax
	jmp ft_memcpy

align 16
.malloc_failed:
	add rsp, 0x10 ; restore the stack pointer
	ret
