global ft_strdup: function

extern ft_memcpy: function
extern ft_strlen: function
extern malloc: function

%use smartalign
ALIGNMODE p6

%define QWORD_SIZE 8

section .text
; Duplicates a string, using dynamic memory allocation.
; The source string is assumed to be null-terminated.
; In case of error, sets errno properly.
;
; Parameters
; rdi: the address of the source string to duplicate. (assumed to be a valid address)
;
; Return:
; rax: the address of the newly allocated string, or NULL in case of error.
align 16
ft_strdup:

%define S   [ rsp + QWORD_SIZE * 0 ]
%define LEN [ rsp + QWORD_SIZE * 1 ]
%define STACK_SIZE  QWORD_SIZE * 2

; calculate how many bytes shall be allocated
	call ft_strlen
	inc rax ; add 1 for the null-terminator
; reserve space for the local variables
	sub rsp, STACK_SIZE
; initialize the local variables
	mov S, rdi
	mov LEN, rax
; allocate the new string
	mov rdi, rax
	call malloc wrt ..plt
; check if malloc failed
	test rax, rax
	jz .malloc_failed
; load the arguments for the upcoming copy
	mov rdi, rax
	mov rsi, S
	mov rdx, LEN
; restore the stack pointer
	add rsp, STACK_SIZE
; copy the source string into the new string
	jmp ft_memcpy

align 16
.malloc_failed:
; restore the stack pointer
	add rsp, STACK_SIZE
	ret
