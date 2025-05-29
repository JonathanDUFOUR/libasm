; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags:

global ft_write: function

extern __errno_location: function

%use smartalign
ALIGNMODE p6

section .text
; Writes N bytes from a buffer into a file descriptor.
; The buffer is assumed to be at least N bytes large.
; In case of error, sets errno properly.
;
; Parameters
; rdi: the file descriptor to write to.
; rsi: the address of the buffer to write from. (assumed to be a valid address)
; rdx: the number of bytes to write.
;
; Return
; rax: the number of bytes written, or -1 if an error occurred.
align 16
ft_write:
; call sys_write
	mov rax, 1
	syscall
; check if sys_write failed
	test rax, rax
	js .error
	ret

align 16
.error:
; set the errno variable
	neg rax
	mov rdi, rax
	call __errno_location wrt ..plt
	mov [ rax ], rdi
; set the return value to -1
	or rax, -1
	ret
