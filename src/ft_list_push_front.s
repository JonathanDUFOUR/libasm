global ft_list_push_front: function

extern malloc: function

%use smartalign
ALIGNMODE p6

%include "node.s"

%define SIZEOF_QWORD 8

%define SIZEOF_NODE t_node_size

section .text
; Allocates a new node and prepends it to a given linked-list.
; In case of error, sets errno properly.
;
; Parameters
; rdi: the address of a pointer to the 1st node of the list to push to. (assumed to be a valid address)
; rsi: the address of the data to store in the new node to push.
align 16
ft_list_push_front:

%define LIST [ rsp + 0 * SIZEOF_QWORD ]
%define DATA [ rsp + 1 * SIZEOF_QWORD ]
%define STACK_SIZE   2 * SIZEOF_QWORD

; reserve space for the local variables
	sub rsp, STACK_SIZE
; initialize the local variables
	mov LIST, rdi
	mov DATA, rsi
; allocate the new node
	mov rdi, SIZEOF_NODE
	call malloc wrt ..plt
; check if malloc failed
	test rax, rax
	jz .return
; load the local variables
	mov rcx, LIST
	mov rdx, DATA
; initialize the fields of the new node
	mov [ rax + t_node.data ], rdx
	mov r8, [ rcx ]
	mov [ rax + t_node.next ], r8
; update the head of the list
	mov [ rcx ], rax
align 16
.return:
; restore the stack pointer
	add rsp, STACK_SIZE
	ret
