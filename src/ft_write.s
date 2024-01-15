global ft_write
extern __errno_location

section .data

section .bss

section .text
; Writes N bytes from a buffer into a file descriptor.
; In case of error, sets errno properly.
;
; Parameters
; rdi: the file descriptor to write to.
; rsi: the address of the buffer to write from. (assumed to be a valid address)
; rdx: the number of bytes to write.
;
; Return
; rax: the number of bytes written, or -1 if an error occurred.
ft_write:
; call sys_write
	mov rax, 1
	syscall
; check if sys_write failed
	test rax, rax
	jns .ret
; handle the error
	neg rax
	mov rdi, rax
	call __errno_location wrt ..plt
	mov [rax], rdi
	or rax, -1
.ret:
	ret