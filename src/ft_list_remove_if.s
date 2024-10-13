global ft_list_remove_if: function

extern free: function

%use smartalign
ALIGNMODE p6

%define SIZEOF_QWORD 8

%define NULL 0

struc t_node
	.data: resq 1
	.next: resq 1
endstruc

section .text
; Conditionally removes nodes from a singly linked list by using a comparison function
; to decide if a node's data matches the reference data and should be removed.
; The data of the removed nodes is properly freed using a drop function.
;
; Parameters
; rdi: the address of a pointer to the 1st node of the list (assumed to be a valid address)
; rsi: the address of a the reference data (assumed to be a valid address)
; rdx: the address of the comparison function (assumed to be a valid address)
; rcx: the address of the drop function (assumed to be a valid address)
align 16
ft_list_remove_if:

%define OLD_RBX [ rsp + 0 * SIZEOF_QWORD ]
%define OLD_RBP [ rsp + 1 * SIZEOF_QWORD ]
%define OLD_R12 [ rsp + 2 * SIZEOF_QWORD ]
%define OLD_R13 [ rsp + 3 * SIZEOF_QWORD ]
%define OLD_R14 [ rsp + 4 * SIZEOF_QWORD ]
%define OLD_R15 [ rsp + 5 * SIZEOF_QWORD ]
%define STACK_SIZE	    6 * SIZEOF_QWORD

; check if the list is empty
	cmp qword [ rdi ], NULL
	je .return
; reserve space for the local variables
	sub rsp, STACK_SIZE
; preserve the non-volatile registers
	mov OLD_RBX, rbx
	mov OLD_RBP, rbp
	mov OLD_R12, r12
	mov OLD_R13, r13
	mov OLD_R14, r14
	mov OLD_R15, r15
; load the arguments in non-volatile registers
	mov rbx, rdi ; the address of the 1st node of the list
	mov rbp, rsi ; the address of the reference data
	mov r12, rdx ; the address of the comparison function
	mov r13, rcx ; the address of the drop function
; load the address of the 1st node of the list in a non-volatile register
	mov r14, [ rdi ]
; compare the data of the current node with the reference data
	mov rdi, [ r14 + t_node.data ]
	mov rsi, rbp
	call r12
	test eax, eax
	jnz .find_the_next_matching_node
align 16
.load_the_address_of_the_2nd_node_of_the_list:
	mov r15, [ r14 + t_node.next ]
; drop the data of the 1st node
	mov rdi, [ r14 + t_node.data ]
	call r13
; free the current node
	mov rdi, r14
	call free wrt ..plt
; check if the end of the list is reached
	test r15, r15
	jz .set_the_1st_node_of_the_list_to_null
; update the pointers
	mov r14, r15 ; the new 1st node of the list
; compare the data of the current node with the reference data
	mov rdi, [ r14 + t_node.data ]
	mov rsi, rbp
	call r12
	test eax, eax
; repeat until either the end of the list is reached or a node's data does not match the reference data
	jz .load_the_address_of_the_2nd_node_of_the_list
; update the pointers
	mov [ rbx ], r14 ; the new 1st node of the list
align 16
.find_the_next_matching_node:
; update the pointers
	mov rbx, [ r14 + t_node.next ] ; the new current node
; check if the end of the list is reached
	test rbx, rbx
	jz .restore_the_non_volatile_registers
; compare the data of the current node with the reference data
	mov rdi, [ rbx + t_node.data ]
	mov rsi, rbp
	call r12
	test eax, eax
	jz .find_the_next_mismatching_node
; update the pointers
	mov r14, rbx ; the new previous node
; repeat until either the end of the list is reached or a node's data matches the reference data
	jmp .find_the_next_matching_node

align 16
.find_the_next_mismatching_node:
; update the pointers
	mov r15, [ rbx + t_node.next ] ; the new next node
; drop the data of the current node
	mov rdi, [ rbx + t_node.data ]
	call r13
; free the current node
	mov rdi, rbx
	call free wrt ..plt
; check if the end of the list is reached
	test r15, r15
	jz .set_the_previous_node_as_the_last_node_of_the_list
; compare the data of the next node with the reference data
	mov rdi, [ r15 + t_node.data ]
	mov rsi, rbp
	call r12
	test eax, eax
	jnz .link_the_previous_node_to_the_next_node
; update the pointers
	mov rbx, r15 ; the new current node
; repeat until either the end of the list is reached or a node's data does not match the reference data
	jmp .find_the_next_mismatching_node

align 16
.link_the_previous_node_to_the_next_node:
	mov [ r14 + t_node.next ], r15
; update the pointers
	mov r14, r15 ; the new previous node
; repeat the entire process until the end of the list is reached
	jmp .find_the_next_matching_node

align 16
.set_the_previous_node_as_the_last_node_of_the_list:
	mov qword [ r14 + t_node.next ], NULL
; restore the non-volatile registers
	mov r15, OLD_R15
	mov r14, OLD_R14
	mov r13, OLD_R13
	mov r12, OLD_R12
	mov rbp, OLD_RBP
	mov rbx, OLD_RBX
; restore the stack pointer
	add rsp, STACK_SIZE
	ret

align 16
.set_the_1st_node_of_the_list_to_null:
	mov qword [ rbx ], NULL
; restore the non-volatile registers
	mov r15, OLD_R15
	mov r14, OLD_R14
	mov r13, OLD_R13
	mov r12, OLD_R12
	mov rbp, OLD_RBP
	mov rbx, OLD_RBX
; restore the stack pointer
	add rsp, STACK_SIZE
	ret

align 16
.restore_the_non_volatile_registers:
	mov r15, OLD_R15
	mov r14, OLD_R14
	mov r13, OLD_R13
	mov r12, OLD_R12
	mov rbp, OLD_RBP
	mov rbx, OLD_RBX
; restore the stack pointer
	add rsp, STACK_SIZE
	ret

align 16
.return:
	ret
