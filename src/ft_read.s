section .data

section .bss

section .text
	global ft_read

; Reads N bytes from a file descriptor and store them in a buffer.
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
	mov rax, 0	; sys_read
	syscall
	; TODO: check for errors and set errno