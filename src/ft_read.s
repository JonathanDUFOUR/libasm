global ft_read
extern __errno_location

section .data

section .bss

section .text
; Reads N bytes from a file descriptor into a buffer.
; In case of any error, sets errno properly.
;
; Parameters
; rdi: the file descriptor to read from
; rsi: the address of the buffer to read into
; rdx: the number of bytes to read
;
; Return
; rax: the number of bytes read, or -1 if an error occurred
ft_read:
	xor rax, rax	; sys_read
	syscall
	test rax, rax
	jns .return
.error:
	neg rax
	mov rdi, rax
	call __errno_location wrt ..plt
	mov [rax], rdi
	or rax, -1
.return:
	ret