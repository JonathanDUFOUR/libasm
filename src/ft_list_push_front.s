global ft_list_push_front
extern malloc

section .data

section .bss

section .text
; Allocates a new node and push it front to a given list.
; In case of error, sets errno properly.
;
; Parameters:
; rdi: the address of a pointer to the first node of the list to push to. (assumed to be a valid address)
; rsi: the address of the data to store in the new node to push.
ft_list_push_front:
; reserve
	push rdi
	push rsi
	mov rdi, 16
	call malloc wrt ..plt
; check if malloc failed
	test rax, rax
	jz .return
	pop rsi
	pop rdi
; initialize the `data` field
	mov [rax], rsi
; initialize the `next` field
	mov rsi, [rdi]
	mov [rax + 8], rsi
; update the list head
	mov [rdi], rax
.return:
	ret
