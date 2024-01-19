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
; 0 back up the callee-saved registers
;   + make `rbp` point to the bottom of the stack frame
	push rbp
	push rbx
	push r12
	push r13
	mov rbp, rsp
; 1 push every data from the list onto the stack frame
	mov rax, [rdi]
.loop0:
; 1.0 check if the end of the list has been reached
	test rax, rax
	jz .end_of_loop0
; 1.1 push the data from the current node onto the stack frame
	push qword [rax]
; 1.2 step to the next node
	mov rax, [rax + 8]
	jmp .loop0
.end_of_loop0:
; 2 sort the stack
; 2.0 save the compare function address into a callee-saved register
	mov r12, rsi
; 2.1 set the first range using callee-saved registers
	sub rbp, 8
	mov rbx, rsp
.sort_range:
; 2.2 check if the current range has more than 1 element
; REMIND: maybe should we check that the current range
;         has more than N elements, where N > 1, and make
;         a manual sort if the current range has less
;         than N elements? (because problems may occur
;         if the current range has exactly 2 elements,
;         and is at an extremity of the whole range)
	cmp rbx, rbp
	jae .end_of_sort_range
; 2.3 set the pivot (r13) for the current range using the median of medians algorithm
; TODO
; 2.4 partition the current range into 2 sub-ranges using the pivot (r13)
.loop1:
; 2.4.0 move `lo` (rbx) forward to the first value greater than the pivot (r13)
.loop2:
; 2.4.0.0 compare the value that `lo` (rbx) points to and the pivot (r13)
	mov rdi, [rbx]
	mov rsi, r13
	call r12
; 2.4.0.1 check if the value that `lo` (rbx) points to is greater than the pivot (r13)
	cmp eax, 0
	jg .end_of_loop2
; 2.4.0.2 step to the next value
	add rbx, 8
; 2.4.0.3 repeat until `lo` (rbx) points to a value greater than the pivot (r13)
	jmp .loop2
.end_of_loop2:
; 2.4.1 move `hi` (rbp) backward to the first value less than the pivot (r13)
.loop3:
; 2.4.1.0 compare the value that `hi` (rbp) points to and the pivot (r13)
	mov rdi, [rbp]
	mov rsi, r13
	call r12
; 2.4.1.1 check if the value that `hi` (rbp) points to is less than the pivot (r13)
	cmp eax, 0
	jl .end_of_loop3
; 2.4.1.2 step to the next value
	sub rbp, 8
; 2.4.1.3 repeat until `hi` (rbp) points to a value less than the pivot (r13)
	jmp .loop3
.end_of_loop3:
; 2.4.2 check if `lo` and `hi` have crossed each other
	cmp rsp, rbp
	jae .end_of_loop1
; 2.4.3 swap the values pointed by `lo` and `hi`
	mov rcx, [rsp]
	mov rdx, [rbp]
	mov [rsp], rdx
	mov [rbp], rcx
; 2.4.4 repeat until `lo` and `hi` cross each other
	jmp .loop1
.end_of_loop1:
; 2.5 sort the 2 sub-ranges
; TODO
.end_of_sort_range:
; 3 pop every data from the stack into the list
	mov rax, [rdi]
.loop4:
; 3.0 check if the end of the list has been reached
	test rax, rax
	jz .end_of_loop4
; 3.1 pop the data from the top of the stack to the current node
	pop qword [rax]
; 3.2 step to the next node
	mov rax, [rax + 8]
	jmp .loop4
.end_of_loop4:
; 4 restore the callee-saved registers
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret

;       v
; 1 2 3 4 5
;   ^


; rdi: &list

; list: 0 -> 9 -> 1 -> 8 -> 2 -> 7 -> 3 -> 6 -> 4 -> 5

;   rbp:                   v
; stack: [???] | old_rbp | 0 | 9 | 1 | 8 | 2 | 7 | 3 | 6 | 4 | 5 | [???] (top) (lower addresses)
;   rbx:                                                       ^
