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

	retasm