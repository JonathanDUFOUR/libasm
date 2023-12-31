global ft_atoi_base

section .data
	arr times 256 db 0xff

section .bss

section .text
; Parses a string into an integer, according to the given base.
; The base must be at least 2 characters long. It must not contain
; any duplicate characters, nor any of the following:
; `%x09-0d / %x20 / %x2a-2b / %x2d / %x2f`
;
; Parameters:
; rdi: the address of the string to parse. (assumed to be a valid address)
; rsi: the address of the string to use as base. (assumed to be a valid address)
;
; Return:
; rax:
; - the parsed integer value if the base is valid.
; - 0 otherwise.
ft_atoi_base:
; 0 check if the base is valid
	lea r8, [rel arr]			; REMIND: why need `rel` keyword
	mov rax, 0xac0100003e00		; the bit field that represents the invalid characters
	xor rdx, rdx
	xor rcx, rcx
; 0.0 check if the base contains invalid character or duplicates
;     + save the value of each digit of the base
.loop0:
	mov dl, [rsi + rcx]
; 0.0.0 check if the end of string has been reached
	test dl, dl
	jz .end_of_loop0
; 0.0.1 check if the current character is any of `%x09-0d / %x20 / %x2a-2b / %x2d / %x2f`
	cmp dl, 0x2f
	jg .check_duplicates
	bt rax, rdx
	jc .ret_zero
.check_duplicates:
; 0.0.2 check if the current character has already been encountered
	cmp byte [r8 + rdx], 0xff	; REMIND: why can't we just do `cmp byte [arr + rdx], 0xff`?
	jne .ret_zero
; 0.0.3 save the value as a digit of the current character
	mov [r8 + rdx], cl			; REMIND: why can't we just do `mov [arr + rdx], cl`?
; 0.0.4 step to the next character
	inc cl
	jmp .loop0
.end_of_loop0:
; 0.1 check if the base is at least 2 characters long
	test cl, 0xfe
	jz .ret_zero
; 1 parse the string
; 1.0 skip leading whitespace(s) `*( %x09-0d / %x20 )`
	mov rax, 0x100003e00
.loop1:
	mov dl, [rdi]
; 1.0.0 check if the end of string has been reached
	test dl, dl
	jz .ret_zero
; 1.0.1 check if the current character is any of `%x09-0d / %x20`
	bt rax, rdx
	jnc .end_of_loop1
; 1.0.2 step to the next character
	inc rdi
	jmp .loop1
.end_of_loop1:
; 1.1 compute the sign
	mov dl, [rdi]
; 1.1.0 check if the first non-whitespace character is a sign `%x2b / %x2d`
	sub dl, 0x2b
	test dl, 0xfd
	jnz .skip_leading_null_digits
; 1.1.1 save whether it is the minus sign `%x2d`
	test dl, dl
	setnz r9b
; 1.1.2 step to the next character
	inc rdi
.skip_leading_null_digits:
; 1.2 skip leading null digit(s)
	mov sil, [rsi]
.loop2:
	mov dl, [rdi]
; 1.2.0 check if the end of string has been reached
	test dl, dl
	jz .ret_zero
; 1.2.1 check if the current character is the null digit
	cmp dl, sil
	jne .end_of_loop2
; 1.2.2 step to the next character
	inc rdi
	jmp .loop2
.end_of_loop2:
; 1.3 compute the significant digits
	xor rax, rax
	xor esi, esi
.loop3:
	mov dl, [rdi]
; 1.3.0 check if the end of string has been reached
	test dl, dl
	jz .end_of_loop3
; 1.3.1 get + check the value as a digit of the current character
	mov sil, [r8 + rdx]		; REMIND: why can't we just do `mov sil, [arr + dl]`?
	cmp sil, 0xff
	je .end_of_loop3
; 1.3.2 compute the current value into the final result
	mul ecx
	add eax, esi
; 1.3.3 step to the next character
	inc rdi
	jmp .loop3
.end_of_loop3:
; 1.4 apply the sign to the final result
	test r9b, r9b
	jz .ret
	neg eax
.ret:
	ret
.ret_zero:
	xor rax, rax
	ret