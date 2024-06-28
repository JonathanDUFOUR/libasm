global ft_strlen: function

section .text

%include "macro/nop.s"

; Checks whether the given 32-bytes chunk %1 contains a null byte.
; If any, calculates the index of the first null byte in the chunk and jumps to %2
%macro CHECK_CHUNK 2
	vpcmpeqb %1, ymm0, %1
	vpmovmskb rcx, %1
; calculate the index of the first null byte in the next chunk of bytes if any
; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	bsf ecx, ecx
	jnz %2
%endmacro

; Calculates the length of a null-terminated string.
;
; Parameters
; rdi: the address of the string to calculate the length of. (assumed to be a valid address)
;
; Return
; rax: the length of string.
align 16
ft_strlen:
; preliminary initialization
	vpxor ymm0, ymm0, ymm0
	mov rax, rdi
; set the pointer to the previous 32-bytes boundary
	and rax, -32 ; TODO: why does `and eax, -32` trigger a segmentation fault
; check the first N bytes (N <= 32)
	vpcmpeqb ymm1, ymm0, [rax]
	vpmovmskb rax, ymm1
; ignore unwanted leading bytes
; REMIND: this is for little-endian. Use shlx instead of shrx for big-endian.
	shrx eax, eax, edi ; TODO: why does this work, but not `shrx rax, rax, rdi`?
; calculate the index of the first null byte in the first 32 bytes if any
; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	bsf eax, eax
	jz .align_the_pointer_to_the_first_yword_boundary
	ret

align 16
.align_the_pointer_to_the_first_yword_boundary:
	lea rax, [rdi-0x60]
	and rax, -32 ; TODO: why does `and eax, -32` trigger a segmentation fault
	NOP_8
.check_next:
; update the pointer
	add rax, 0x80
; check the next 32-bytes chunks
	vmovdqa ymm1, [rax]
	vpminub ymm2, ymm1, [rax+0x20]
	vpminub ymm3, ymm2, [rax+0x40]
	vpminub ymm4, ymm3, [rax+0x60]
	vpcmpeqb ymm4, ymm0, ymm4
	vpmovmskb ecx, ymm4
; repeat until the end of the string is reached
	test ecx, ecx
	jz .check_next
; calculate the index of the first null byte found in the next 32-bytes chunks
	CHECK_CHUNK ymm1, .null_byte_is_in_the_next_32_bytes
	CHECK_CHUNK ymm2, .null_byte_is_in_the_next_64_bytes
	CHECK_CHUNK ymm3, .null_byte_is_in_the_next_96_bytes
; null byte is in the next 128 bytes
	vpmovmskb rcx, ymm4
; calculate the index of the first null byte in the next chunk of bytes
; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	bsf ecx, ecx
	add rax, 0x60
	add rax, rcx
	sub rax, rdi
	ret

align 16
.null_byte_is_in_the_next_96_bytes:
	add rax, 0x40
	add rax, rcx
	sub rax, rdi
	ret

align 16
.null_byte_is_in_the_next_64_bytes:
	add rax, 0x20
	add rax, rcx
	sub rax, rdi
	ret

align 16
.null_byte_is_in_the_next_32_bytes:
	add rax, rcx
	sub rax, rdi
	ret
