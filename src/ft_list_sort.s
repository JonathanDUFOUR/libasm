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
	push rbp
	mov rbp, rsp
; 0 push every data from the list to the stack
	mov rax, [rdi]
.loop0:
; 0.0 check if the end of the list has been reached
	test rax, rax
	jz .end_of_loop0
; 0.1 push the data from the current node to the top of stack
	push qword [rax]
; 0.2 step to the next node
	mov rax, [rax + 8]
	jmp .loop0
.end_of_loop0:
; 1 sort the stack
; 1.0 set the current range to the whole stack
	sub rbp, 8
.sort_range:
; 1.1 check if the current range has more than 1 node
	cmp rbp, rsp
	jbe .end_of_sort_range
; 1.2 set the pivot for the current range using the median of medians algorithm
; TODO
; 1.3 partition the current range into 2 sub-ranges using the pivot
; TODO
.loop1:
; 1.3.0 increment `lo` (rsp) until it points to a value greater than the pivot (rax)
.loop2:
; TODO
.end_of_loop2:
; 1.3.1 decrement `hi` (rbp) until it points to a value lower than the pivot (rax)
.loop3:
; TODO
.end_of_loop3:
; 1.3.2 check if `lo` and `hi` have crossed each other
	cmp rsp, rbp
	jae .end_of_loop1
; 1.3.3 swap the values pointed by `lo` and `hi`
	mov rcx, [rsp]
	mov rdx, [rbp]
	mov [rsp], rdx
	mov [rbp], rcx
; 1.3.4 repeat until `lo` and `hi` have crossed each other
	jmp .loop1
.end_of_loop1:
; 1.4 sort the 2 sub-ranges
; TODO
.end_of_sort_range:
; 2 pop every data from the stack to the list
	mov rax, [rdi]
.loop4:
; 2.0 check if the end of the list has been reached
	test rax, rax
	jz .end_of_loop4
; 2.1 pop the data from the top of the stack to the current node
	pop qword [rax]
; 2.2 step to the next node
	mov rax, [rax + 8]
	jmp .loop4
.end_of_loop4:
	pop rbp
	ret

;       v
; 1 2 3 4 5
;   ^


; rdi: &list

; list: 0 -> 9 -> 1 -> 8 -> 2 -> 7 -> 3 -> 6 -> 4 -> 5

;   rbp:                   v
; stack: [???] | old_rbp | 0 | 9 | 1 | 8 | 2 | 7 | 3 | 6 | 4 | 5 | [???] (top) (lower addresses)
;   rsp:                                                       ^


; rcx: 10 (number of nodes)
; rsi: 2 (number of sub-medians)

; add rsp, rcx
; dec rsp

; push rdi
; push rsi
; rdi: [rax]
; rsi: [rax + 8]