; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags:

global ft_list_size: function

%use smartalign
ALIGNMODE p6

%include "node.nasm"

section .text align=16
; Calculates how many nodes a given list contains.
;
; Parameters
; rdi: the address of the 1st node of the list. (assumed to be a valid address or NULL)
;
; Return:
; rax: the number of nodes in the list.
ft_list_size:
; preliminary initialization
	xor rax, rax
align 16
.check_next_node:
; check if the end of the list is reached
	test rdi, rdi
	jz .return
; increment the counter
	inc rax
; step to the next node
	mov rdi, [ rdi + t_node.next ]
; repeat until the end of the list is reached
	jmp .check_next_node

align 16
.return:
	ret
