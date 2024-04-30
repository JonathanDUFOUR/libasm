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
; back up the callee-saved registers
;   + make `rbp` point to the bottom of the stack frame
	push rbp
	push rbx
	push r12
	push r13
	push r14
	mov rbp, rsp
; push every data from the list onto the stack frame
	mov rax, [rdi]
.loop0:
; check if the end of the list has been reached
	test rax, rax
	jz .end_of_loop0
; push the data from the current node onto the stack frame
	push qword [rax]
; step to the next node
	mov rax, [rax + 8]
	jmp .loop0
.end_of_loop0:
; sort the data in the stack frame
;   rbx: lo
;   rbp: hi
;   r12: fn_cmp
;   r13: pivot
;   r14: depth
; save the compare function address into a callee-saved register
	mov r12, rsi
; set the first range to the whole data in the stack frame using callee-saved registers
	sub rbp, 8
	mov rbx, rsp
; set the depth level to 0
	mov r14, 0
.sort_range:
; save the current range bounds onto the stack frame
	push rbp
	push rbx
; check if the current range has less than 2 element
; REMIND: maybe should we check that the current range has less than N elements, where N > 2,
;         and make a manual sort if the current range has N elements or less?
;         (because problems may occur if the current range has exactly 2 elements
;         and is at an extremity of the whole range)
	cmp rbp, rbx
	jbe .end_of_sort_range
; set the pivot for the current range using the median of medians algorithm
; TODO
; partition the current range into 2 sub-ranges using the pivot
.loop1:
; move `lo` forward to the first value greater than the pivot
.loop2:
; compare the value that `lo` points to and the pivot
	mov rdi, [rbx]
	mov rsi, r13
	call r12
; check if the value that `lo` points to is greater than the pivot
	cmp eax, 0
	jg .end_of_loop2
; step to the next value
	add rbx, 8
; repeat until `lo` points to a value greater than the pivot
	jmp .loop2
.end_of_loop2:
; move `hi` backward to the first value less than the pivot
.loop3:
; compare the value that `hi` points to and the pivot
	mov rdi, [rbp]
	mov rsi, r13
	call r12
; check if the value that `hi` points to is less than the pivot
	cmp eax, 0
	jl .end_of_loop3
; step to the next value
	sub rbp, 8
; repeat until `hi` points to a value less than the pivot
	jmp .loop3
.end_of_loop3:
; check if `lo` and `hi` have crossed each other
	cmp rbx, rbp
	jae .end_of_loop1
; swap the values pointed by `lo` and `hi`
	mov rcx, [rsp]
	mov rdx, [rbp]
	mov [rsp], rdx
	mov [rbp], rcx
; step to the next values for `lo` and `hi`
	add rbx, 8
	sub rbp, 8
; repeat until `lo` and `hi` cross each other
	jmp .loop1
.end_of_loop1:
; sort the first sub-range
; increment the current depth level
	inc r14
; swap the low bound saved on the top of the stack frame with `lo`
	pop rax
	push rbx
	mov rbx, rax
; repeat the range sorting until a resulting sub-range has less than 2 elements
	jmp .sort_range
.end_of_sort_range:
; pop every data from the stack into the list
	mov rax, [rdi]
.loop4:
; check if the end of the list has been reached
	test rax, rax
	jz .end_of_loop4
; pop the data from the top of the stack to the current node
	pop qword [rax]
; step to the next node
	mov rax, [rax + 8]
	jmp .loop4
.end_of_loop4:
; restore the callee-saved registers
	pop r14
	pop r13
	pop r12
	pop rbx
	pop rbp
	ret
