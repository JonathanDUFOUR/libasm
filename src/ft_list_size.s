global ft_list_size: function

%use smartalign
ALIGNMODE p6

%include "node.s"

%define SIZEOF_QWORD 8

section .text
; Calculates how many nodes a given list contains.
;
; Parameters
; rdi: the address of the 1st node of the list. (assumed to be a valid address or NULL)
;
; Return:
; rax: the number of nodes in the list.
align 16
ft_list_size:
	xor rax, rax
align 16
.check_the_next_node:
; check if the end of the list is reached
	test rdi, rdi
	jz .return
; increment the counter
	inc rax
; step to the next node
	mov rdi, [ rdi + SIZEOF_QWORD ]
; repeat until the end of the list is reached
	jmp .check_the_next_node

align 16
.return:
	ret
