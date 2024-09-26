global ft_strdup: function

extern ft_memcpy: function
extern ft_strlen: function
extern malloc: function

%use smartalign
ALIGNMODE p6

%define SIZEOF_QWORD 8

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
; preserve the volatile registers
	push rdi
; calculate how many bytes we need to allocate
	call ft_strlen
	inc rax ; add 1 for the null-terminator
; preserve the volatile registers
	push rax
; allocate the new string
	mov rdi, rax
	call malloc wrt ..plt
; check if malloc failed
	test rax, rax
	jz .malloc_failed
; restore the volatile registers
	pop rdx
	pop rsi
; copy the source string into the new string
	mov rdi, rax
	jmp ft_memcpy

align 16
.malloc_failed:
	add rsp, 2 * SIZEOF_QWORD ; restore the stack pointer
	ret
