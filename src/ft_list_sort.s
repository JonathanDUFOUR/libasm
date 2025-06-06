; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: CMOV

global ft_list_sort: function

%use smartalign
ALIGNMODE p6

%include "node.s"

%define QWORD_SIZE 8

%define NULL 0

%define TRUE  1
%define FALSE 0

section .text
; Sorts a singly linked list in ascending order, using a function to compare data in the list.
;
; Parameters
; rdi: the address of a pointer to the 1st node of the list to sort. (assumed to be a valid address)
; rsi: the address of a function to compare data in the list. (assumed to be a valid address)
align 16
ft_list_sort:
%define OLD_RBX [ rsp + QWORD_SIZE * 0 ]
%define OLD_R12 [ rsp + QWORD_SIZE * 1 ]
%define OLD_R13 [ rsp + QWORD_SIZE * 2 ]
%define OLD_R14 [ rsp + QWORD_SIZE * 3 ]
%define LIST    [ rsp + QWORD_SIZE * 4 ]
%define STACK_SIZE      QWORD_SIZE * 5
; reserve space for the local variables
	sub rsp, STACK_SIZE
; preserve the non-volatile registers
	mov OLD_RBX, rbx
	mov OLD_R12, r12
; initialize the local variables
	mov LIST, rdi
; check if the list is already sorted
	mov rbx, rsi
	mov rcx, [ rdi ]
	call is_sorted
	test al, al
	jnz .restore_non_volatile_registers
; preserve the non-volatile registers
	mov OLD_R13, r13
	mov OLD_R14, r14
; sort the list
	mov rdi, LIST
	call merge_sort
; restore the non-volatile registers
	mov r14, OLD_R14
	mov r13, OLD_R13
align 16
.restore_non_volatile_registers:
	mov r12, OLD_R12
	mov rbx, OLD_RBX
; restore the stack pointer
	add rsp, STACK_SIZE
	ret

; Checks whether a singly linked list is sorted in ascending order,
; using a function to compare data in the list.
; It is assumed that `r12` has been preserved by the caller.
;
; Parameters
; rbx: the address of the function to compare data in the list. (assumed to be a valid address)
; rcx: the address of the 1st node of the list. (assumed to be a valid address or NULL)
;
; Return:
; al:
; - 0 if the list is not sorted
; - 1 if the list is sorted
align 16
is_sorted:
; check if the list is empty
	test rcx, rcx
	jz .return_true
align 16
.load_next_node:
	mov r12, [ rcx + t_node.next ]
; check if the end of the list is reached
	test r12, r12
	jz .return_true
; check if the current node's data is greater than the next node's data
	mov rdi, [ rcx + t_node.data ]
	mov rsi, [ r12 + t_node.data ]
	call rbx
	cmp eax, 0
	jg .return_false
; set the next node as the current one
	mov rcx, r12
; repeat until either the end of the list is reached or an inversion is found
	jmp .load_next_node

align 16
.return_true:
	mov al, TRUE
	ret

align 16
.return_false:
	mov al, FALSE
	ret

; Sorts a singly linked list in ascending order, using a function to compare data in the list.
; It is assumed that `r12`, `r13`, and `r14` have been preserved by the caller,
; and that the list contains at least 2 elements.
;
; Parameters
; rdi: the address of a pointer to the 1st node of the list. (assumed to be a valid address)
; rbx: the address of the function to compare data in the list. (assumed to be a valid address)
align 16
merge_sort:
%define LIST      [ rsp + QWORD_SIZE * 0 ]
%define SUBLIST_A [ rsp + QWORD_SIZE * 1 ]
%define SUBLIST_B [ rsp + QWORD_SIZE * 2 ]
%define STACK_SIZE        QWORD_SIZE * 3
; reserve space for the local variables
	sub rsp, STACK_SIZE
; initialize the pointers
	mov rax, NULL                ; the 1st node of the sublist A
	mov rcx, NULL                ; the 1st node of the sublist B
	mov r8, [ rdi ]              ; the 1st node of the list
	mov r9, [ r8 + t_node.next ] ; the 2nd node of the list
align 16
.load_address_of_3rd_node_of_list:
	mov r10, [ r9 + t_node.next ]
; dispatch the first 2 nodes of the list
	mov [ r8 + t_node.next ], rax ; prepend to the sublist A
	mov [ r9 + t_node.next ], rcx ; prepend to the sublist B
; update the pointers
	mov rax, r8 ; the new 1st node of the sublist A
	mov rcx, r9 ; the new 1st node of the sublist B
; check if the list is empty
	test r10, r10
	jz .initialize_local_variables
; check if the list contains at least 2 elements
	cmp qword [ r10 + t_node.next ], NULL
	je .dispatch_last_node_of_list
; update the pointers
	mov r8, r10                   ; the new 1st node of the list
	mov r9, [ r10 + t_node.next ] ; the new 2nd node of the list
; repeat until the list contains less than 2 elements
	jmp .load_address_of_3rd_node_of_list

align 16
.dispatch_last_node_of_list:
	mov [ r10 + t_node.next ], rax ; prepend to the sublist A
; update the pointers
	mov rax, r10 ; the new 1st node of the sublist A
align 16
.initialize_local_variables:
	mov LIST, rdi
	mov SUBLIST_A, rax
	mov SUBLIST_B, rcx
; check if the sublist A contains at least 2 elements
	cmp qword [ rax + t_node.next ], NULL
	je .check_if_sublist_B_contains_at_least_2_elements
; recursively call the `merge_sort` function on the sublist A
	lea rdi, SUBLIST_A
	call merge_sort
; load the address of the 1st node of the sublist B
	mov rcx, SUBLIST_B
align 16
.check_if_sublist_B_contains_at_least_2_elements:
	cmp qword [ rcx + t_node.next ], NULL
	je .load_local_variables
; recursively call the `merge_sort` function on the sublist B
	lea rdi, SUBLIST_B
	call merge_sort
align 16
.load_local_variables:
	mov r11, LIST
	mov r12, SUBLIST_A
	mov r13, SUBLIST_B
; compare the 1st node's data of both sublists
	mov rdi, [ r12 + t_node.data ]
	mov rsi, [ r13 + t_node.data ]
	call rbx
	cmp eax, 0
; determine which sublist has the smallest 1st node
	cmovle r14, r12 ; if <= 0 then the node to append(`r14`) is the 1st node of the sublist A
	cmovg  r14, r13 ; if  > 0 then the node to append(`r14`) is the 1st node of the sublist B
; initialize the merged list
	mov [ r11 ], r14
align 16
.update_head_of_sublist_from_which_node_was_detached:
	cmovle r12, [ r12 + t_node.next ] ; if <= 0 then the new 1st node of the sublist A is its current 2nd node
	cmovg  r13, [ r13 + t_node.next ] ; if  > 0 then the new 1st node of the sublist B is its current 2nd node
; check if the sublist B is empty
	test r13, r13
	jz .append_sublist_A_to_merged_list
; check if the sublist A is empty
	test r12, r12
	jz .append_sublist_B_to_merged_list
; compare the 1st node's data of both sublists
	mov rdi, [ r12 + t_node.data ]
	mov rsi, [ r13 + t_node.data ]
	call rbx
	cmp eax, 0
; determine which sublist has the smallest 1st node
	cmovle rdx, r12 ; if <= 0 then the node to append(`rdx`) is the 1st node of the sublist A
	cmovg  rdx, r13 ; if  > 0 then the node to append(`rdx`) is the 1st node of the sublist B
; append the smallest 1st node of the sublists to the merged list
	mov [ r14 + t_node.next ], rdx
; update the pointers
	mov r14, rdx ; the new last node of the merged list
; repeat until either the sublist A or the sublist B is empty
	jmp .update_head_of_sublist_from_which_node_was_detached

align 16
.append_sublist_A_to_merged_list:
	mov [ r14 + t_node.next ], r12
; restore the stack pointer
	add rsp, STACK_SIZE
	ret

align 16
.append_sublist_B_to_merged_list:
	mov [ r14 + t_node.next ], r13
; restore the stack pointer
	add rsp, STACK_SIZE
	ret
