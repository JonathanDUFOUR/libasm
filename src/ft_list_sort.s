global ft_list_sort

section .data

section .bss

section .text
; Sort the data of a given list in ascending order,
; using a given function to compare data in the list.
;
; Parameters:
; rdi: the address of a pointer to the first node of the list to sort. (assumed to be a valid address)
; rsi: the address of a function to compare data in the list. (assumed to be a valid address)
ft_list_sort:
; 0 push every data from the list to the stack + count the number of nodes
	xor rcx, rcx
	mov rax, [rdi]
.loop0:
; 0.0 check if the end of the list has been reached
	test rax, rax
	jz .end_of_loop0
; 0.1 push the data from the current node to the top of stack
	push [rax]
; 0.2 increment the counter of nodes
	inc rcx
; 0.3 step to the next node
	mov rax, [rax + 8]
	jmp .loop0
.end_of_loop0:
; 1 sort the stack
	; TODO
; 2 pop every data from the stack to the list
	mov rax, [rdi]
.loop2:
; 2.0 check if the end of the list has been reached
	test rax, rax
	jz .end_of_loop2
; 2.1 pop the data from the top of the stack to the current node
	pop [rax]
; 2.2 step to the next node
	mov rax, [rax + 8]
	jmp .loop2
.end_of_loop2:
	ret