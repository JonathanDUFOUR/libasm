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
; check if the base is valid + save the values of each digit of the base
	mov rax, 0xac0100003e00
	xor dx, dx
	xor cl, cl
.loop0:
; check if the end of string has been reached
	mov dl, [rsi + cl]
	test dl, dl
	jz .end_of_loop
; check if the current character is any of `%x09-0d / %x20 / %x2a-2b / %x2d / %x2f`
	bt rax, dx
	jc .ret_invalid_base
; check if the current character has already been encountered
	cmp [arr + dl], 0xff
	jne .ret_invalid_base
; save the value as a digit of the current character
	mov [arr + dl], cl
	inc cl
	jmp .loop0
.end_of_loop0:
; check if the base is at least 2 characters long
	and cl, 0xfffe
	jz .ret_invalid_base
; parse the string
; TODO: set registers as needed before entering the loop
.loop1:
; TODO: parse the string
.end_of_loop1:
.ret:
	ret
.ret_invalid_base:
	xor rax, rax
	ret