global ft_read: function

%use smartalign
ALIGNMODE p6

extern __errno_location: function

section .text
; Reads N bytes from a file descriptor into a buffer.
; The buffer is assumed to be at least N bytes large.
; In case of error, sets errno properly.
;
; Parameters
; rdi: the file descriptor to read from.
; rsi: the address of the buffer to read into. (assumed to be a valid address)
; rdx: the number of bytes to read.
;
; Return
; rax: the number of bytes read, or -1 if an error occurred.
align 16
ft_read:
; call sys_read
	xor rax, rax
	syscall
; check if sys_read failed
	test rax, rax
	js .error
	ret

align 16
.error:
	neg rax
	mov rdi, rax
	call __errno_location wrt ..plt
	mov [rax], rdi
	or rax, -1
	ret
