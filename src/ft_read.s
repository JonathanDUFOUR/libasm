; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags:

global ft_read: function

extern __errno_location: function

%use smartalign
ALIGNMODE p6

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
; set the errno variable
	neg rax
	mov rdi, rax
	call __errno_location wrt ..plt
	mov [ rax ], rdi
; set the return value to -1
	or rax, -1
	ret
