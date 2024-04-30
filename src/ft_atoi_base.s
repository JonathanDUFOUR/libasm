global ft_atoi_base

section .data
	array times 256 db 0xff

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
; eax:
; - the parsed integer value if the base is valid.
; - 0 otherwise.
ft_atoi_base:
; check if the base is valid
	lea r8, [rel array] ; REMIND: why need `rel` keyword?
	mov rax, 0x0000ac0100003e00 ; the bit field that represents the invalid characters
	xor rdx, rdx
	xor rcx, rcx
.check_base_characters:
	mov dl, [rsi + rcx]
; check if the end of string has been reached
	test dl, dl
	jz .check_base_length
; check if the current character is any of `%x09-0d / %x20 / %x2a-2b / %x2d / %x2f`
	cmp dl, 0x2f
	ja .check_duplicate
	bt rax, rdx
	jc .return_zero
.check_duplicate:
; check if the current character has already been encountered
	cmp byte [r8 + rdx], 0xff ; REMIND: why can't we just do `cmp byte [array + rdx], 0xff`?
	jne .return_zero
; save the value as a digit of the current character
	mov [r8 + rdx], cl ; REMIND: why can't we just do `mov [array + rdx], cl`?
; update the base index
	inc cl
; repeat until either the end of the string is reached or an invalid character is encountered
	jmp .check_base_characters
.check_base_length:
; check if the base is at least 2 characters long
	test cl, 0xfe
	jz .return_zero
; parse the string
	mov rax, 0x100003e00 ; the bit field that represents the whitespace characters
.skip_whitespaces:
	mov dl, [rdi]
; check if the end of string has been reached
	test dl, dl
	jz .return_zero
; check if the current character is any of `%x09-0d / %x20`
	bt rax, rdx
	jnc .compute_sign
; update the string pointer
	inc rdi
; repeat until either the end of string is reached or a non-whitespace character is encountered
	jmp .skip_whitespaces
.compute_sign:
	xor r9b, r9b
	mov r10b, [rsi] ; save the null digit for later operations
; check if the first non-whitespace character is a sign `%x2b / %x2d`
	sub dl, 0x2b
	test dl, 0xfd
	jnz .skip_leading_null_digits
; save whether it is the minus sign `%x2d`
	test dl, dl
	setnz r9b
; update the string pointer
	inc rdi
.skip_leading_null_digits:
	mov dl, [rdi]
; check if the end of string has been reached
	test dl, dl
	jz .return_zero
; check if the current character is the null digit
	cmp dl, r10b
	jne .no_more_leading_null_digit
; update the string pointer
	inc rdi
; repeat until either the end of string is reached or a non-null digit character is encountered
	jmp .skip_leading_null_digits
.no_more_leading_null_digit:
	xor rax, rax
	xor r10d, r10d
.compute_significant_digits:
; check if the end of string has been reached
	test dl, dl
	jz .no_more_significant_digit
; get + check the value as a digit of the current character
	mov r10b, [r8 + rdx] ; REMIND: why can't we just do `mov r10b, [array + dl]`?
	cmp r10b, 0xff
	je .no_more_significant_digit
; compute the current value into the final result
	mul ecx
	add eax, r10d
; step to the next character
	inc rdi
	mov dl, [rdi]
; repeat until either the end of string is reached or a non-digit character is encountered
	jmp .compute_significant_digits
.no_more_significant_digit:
; apply the sign to the final result
	test r9b, r9b
	jz .restore_array_values
	neg eax
.restore_array_values:
; check if every previously set value has been cleared
	test cl, cl
	jz .return
; reset the default value for the `cl`th characters of the base
	dec cl
	mov dl, [rsi + rcx]
	mov byte [r8 + rdx], 0xff
; repeat until every previously set value is cleared
	jmp .restore_array_values
.return:
	ret
.return_zero:
	xor rax, rax
	jmp .restore_array_values
