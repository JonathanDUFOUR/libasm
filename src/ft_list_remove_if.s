global ft_list_remove_if: function

extern free: function

%use smartalign
ALIGNMODE p6

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
; TODO: implement the function
	ret
