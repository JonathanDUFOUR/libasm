global ft_memcpy

section .data

section .bss

section .text
; Copies N bytes from a memory area to another.
; The memory areas must not overlap.
;
; Parameters:
; rdi: the address of the destination memory area. (assumed to be a valid address)
; rsi: the address of the source memory area. (assumed to be a valid address)
; rdx: the number of bytes to copy.
;
; Return:
; rax: the address of the destination memory area.
ft_memcpy:
	mov rax, rdi
; 0 copy bytes using chunks of 8 bytes while it fits the remaining number of bytes to copy.
.copy_8_bytes:
; 0.0 check if the remaining number of bytes to copy is less than 8.
	cmp rdx, 8
	jb .copy_4_bytes
; 0.1 copy 8 bytes from the source memory area to the destination memory area.
	mov rcx, [rsi]
	mov [rdi], rcx
; 0.2 step to the next areas + update the remaining number of bytes to copy.
	add rdi, 8
	add rsi, 8
	sub rdx, 8
; 0.5 repeat until the remaining number of bytes to copy is less than 8.
	jmp .copy_8_bytes
; 1 copy bytes using a chunk of 4 bytes if it fits the remaining number of bytes to copy.
.copy_4_bytes:
; 1.0 check if the remaining number of bytes to copy is less than 4.
	cmp rdx, 4
	jb .copy_2_bytes
; 1.1 copy 4 bytes from the source memory area to the destination memory area.
	mov ecx, [rsi]
	mov [rdi], ecx
; 1.2 step to the next areas + update the remaining number of bytes to copy.
	add rdi, 4
	add rsi, 4
	sub rdx, 4
; 2 copy bytes using a chunk of 2 bytes if it fits the remaining number of bytes to copy.
.copy_2_bytes:
; 2.0 check if the remaining number of bytes to copy is less than 2.
	cmp rdx, 2
	jb .copy_1_byte
; 2.1 copy 2 bytes from the source memory area to the destination memory area.
	mov cx, [rsi]
	mov [rdi], cx
; 2.2 step to the next areas + update the remaining number of bytes to copy.
	add rdi, 2
	add rsi, 2
	sub rdx, 2
; 3 copy the last byte if it fits the remaining number of bytes to copy.
.copy_1_byte:
; 3.0 check if the remaining number of bytes to copy is 0.
	test rdx, rdx
	jz .return
; 3.1 copy the last byte from the source memory area to the destination memory area.
	mov cl, [rsi]
	mov [rdi], cl
.return
	ret