global ft_list_sort: function

%use smartalign
ALIGNMODE p6

%define SIZEOF_QWORD 8

section .text
; Sort the data of a list in ascending order, using a function to compare data in the list.
;
; Parameters:
; rdi: the address of a pointer to the first node of the list to sort. (assumed to be a valid address)
; rsi: the address of a function to compare data in the list. (assumed to be a valid address)
align 16
ft_list_sort:
; preliminary initialization
	mov rax, [ rdi ]
; check if the list is empty
	test rax, rax
	jz .return
; preserve the stack pointer and align it to its previous qword boundary
	mov r10, rsp
	and rsp, -SIZEOF_QWORD
	push r10
; set `rdx` to the address of the last element of the array to sort
	lea rdx, [ rsp - SIZEOF_QWORD ]
align 16
.push_the_data_of_the_next_node:
	push qword [ rax ]
; step to the next node
	mov rax, [ rax + SIZEOF_QWORD ]
; repeat until the end of the list is reached
	test rax, rax
	jnz .push_the_data_of_the_next_node
; preserve the address of the first node of the list
	push qword [ rdi ]
; sort the data on the stack
	lea rdi, [ rsp + SIZEOF_QWORD ]
	call quicksort
; restore the address of the first node of the list
	pop r9
align 16
.pop_the_data_to_the_next_node:
	pop qword [ r9 ]
; step to the next node
	mov r9, [ r9 + SIZEOF_QWORD ]
; repeat until the end of the list is reached
	test r9, r9
	jnz .pop_the_data_to_the_next_node
; restore the stack pointer
	pop r10
	mov rsp, r10
align 16
.return:
	ret

; Sort the data of an array in ascending order, using a function to compare data in the array.
;
; Parameters:
; rdi: the address of the first element of the array to sort. (assumed to be a valid address)
; rsi: the address of a function to compare data in the array. (assumed to be a valid address)
; rdx: the address of the last element of the array to sort. (assumed to be a valid address)
align 16
quicksort:

%define LO      [ rsp + 0 * SIZEOF_QWORD ]
%define HI      [ rsp + 1 * SIZEOF_QWORD ]
%define MID     [ rsp + 2 * SIZEOF_QWORD ]
%define OLD_R12 [ rsp + 3 * SIZEOF_QWORD ]
%define OLD_R13 [ rsp + 4 * SIZEOF_QWORD ]
%define OLD_R14 [ rsp + 5 * SIZEOF_QWORD ]
%define OLD_R15 [ rsp + 6 * SIZEOF_QWORD ]

%define STACK_SIZE 7*SIZEOF_QWORD

; reserve the space for the local variables
	sub rsp, STACK_SIZE
; initialize the local variables
	mov LO, rdi
	mov HI, rdx
; preserve the non-volatile registers
	mov OLD_R12, r12
	mov OLD_R13, r13
	mov OLD_R14, r14
	mov OLD_R15, r15
; initialize the registers for the upcoming partitioning
	mov r12, rsi ; the comparison function
	mov r13, [ rdx ] ; the pivot ;REMIND: ideally, change it to the median of medians later
	lea r14, [ rdi - SIZEOF_QWORD ] ; the iterator starting at LO and moving forward (refered as `i`)
	lea r15, [ rdx + SIZEOF_QWORD ] ; the iterator starting at HI and moving backward (refered as `j`)
; find the next inversion
align 16
.move_i_forward_and_compare_the_ith_element_with_the_pivot:
	add r14, SIZEOF_QWORD
; compare the `i`th element with the pivot
	mov rdi, r13
	mov rsi, [ r14 ]
	call r12
; repeat until the `i`th element is greater than or equal to the pivot
	cmp eax, 0
	jg .move_i_forward_and_compare_the_ith_element_with_the_pivot
align 16
.move_j_backward_and_compare_the_jth_element_with_the_pivot:
	sub r15, SIZEOF_QWORD
; compare the `j`th element with the pivot
	mov rdi, r13
	mov rsi, [ r15 ]
	call r12
; repeat until the `j`th element is lower than or equal to the pivot
	cmp eax, 0
	jl .move_j_backward_and_compare_the_jth_element_with_the_pivot
; check if `i` and `j` have crossed
	cmp r14, r15
	jge .recursively_partition_the_first_partition
; exchange the values of the `i`th element and the `j`th element
	mov r8, [ r14 ]
	mov r9, [ r15 ]
	mov [ r14 ], r9
	mov [ r15 ], r8
; repeat until `i` and `j` cross
	jmp .move_i_forward_and_compare_the_ith_element_with_the_pivot

align 16
.recursively_partition_the_first_partition:
; check if the `i`th element is the HI one
	cmp r14, HI
	jae .recursively_partition_the_second_partition
; recall the quicksort function on the first partition
	mov rdi, r14
	mov rsi, r12
	mov rdx, HI
	call quicksort
align 16
.recursively_partition_the_second_partition:
	sub r14, SIZEOF_QWORD
; check if the `i`th element is the LO one
	cmp r14, LO
	jbe .return
; recall the quicksort function on the second partition
	mov rdi, LO
	mov rsi, r12
	mov rdx, r14
	call quicksort
align 16
.return:
; restore the non-volatile registers
	mov r12, OLD_R12
	mov r13, OLD_R13
	mov r14, OLD_R14
	mov r15, OLD_R15
; restore the stack pointer
	add rsp, STACK_SIZE
	ret
