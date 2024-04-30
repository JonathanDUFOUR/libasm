global ft_list_size

section .data

section .bss

section .text
; Calculates how many nodes a given list contains.
;
; Parameters:
; rdi: the address of the first node of the list. (assumed to be a valid address or NULL)
;
; Return:
; rax: the number of nodes in the list.
ft_list_size:
	xor rax, rax
.loop:
; check if the end of the list has been reached
	test rdi, rdi
	jz .end_of_loop
; increment the counter
	inc rax
; step to the next node
	mov rdi, [rdi + 8]
; repeat until the end of the list is reached
	jmp .loop
.end_of_loop:
	ret
