global ft_list_push_front: function

extern malloc: function

%use smartalign
ALIGNMODE p6

%define SIZEOF_QWORD 8
%define SIZEOF_NODE 2*SIZEOF_QWORD

section .text
; Allocates a new node and prepends it to a given linked-list.
; In case of error, sets errno properly.
;
; Parameters:
; rdi: the address of a pointer to the first node of the list to push to. (assumed to be a valid address)
; rsi: the address of the data to store in the new node to push.
align 16
ft_list_push_front:
; preserve the volatile registers
	push rdi
	push rsi
; allocate the new node
	mov rdi, SIZEOF_NODE
	call malloc wrt ..plt
; check if malloc failed
	test rax, rax
	jz .malloc_failed
; restore the volatile registers
	pop rsi
	pop rdi
; initialize the `data` field
	mov [rax], rsi
; initialize the `next` field
	mov rsi, [rdi]
	mov [rax+SIZEOF_QWORD], rsi
; update the head of the list
	mov [rdi], rax
	ret

align 16
.malloc_failed:
	add rsp, 0x10 ; restore the stack pointer
	ret
