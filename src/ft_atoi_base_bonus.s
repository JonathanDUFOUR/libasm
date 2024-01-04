global ft_atoi_base

section .data

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
; check base
	push rdi
	mov rax, rsi
.outer_loop:
	mov cl, [rax]
	test cl, cl
	jz .end_of_outer_loop
; check for invalid characters
	mov ch, cl
	sub ch, 0x09
	cmp ch, 5
	jb .ret_invalid_base
	cmp cl, 0x20
	je .ret_invalid_base
	mov ch, cl
	sub ch, 0x2a
	cmp ch, 2
	jb .ret_invalid_base
	cmp cl, 0x2d
	je .ret_invalid_base
	cmp cl, 0x2f
	je .ret_invalid_base
	mov rdi, rax
.inner_loop:
; check for duplicates
	inc rdi
	mov ch, [rdi]
	test ch, ch
	jz .end_of_inner_loop
	cmp cl, ch
	je .ret_invalid_base
	jmp .inner_loop
.end_of_inner_loop:
	inc rax
	jmp .outer_loop
.end_of_outer_loop:
; check for base length
	sub rax, rsi
	cmp rax, 2
	jl .ret_invalid_base
	pop rdi
; parse string
; TODO
.ret:
	ret
.ret_invalid_base:
	xor rax, rax
	ret