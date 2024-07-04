global ft_strlen: function

%use smartalign
ALIGNMODE p6

; Parameters:
; %1: the label to jump to if the given YMM register contains a null byte.
; %2: the YMM register to check.
%macro JUMP_IF_HAS_NO_NULL_BYTES 2
	vpcmpeqb %2, ymm0, %2
	vptest %2, %2
	jz %1
%endmacro

; Parameters:
; %1: the offset to apply to the pointer before calculating the final length.
; &2: the YMM register from which the position of the first null byte shall be calculated.
%macro RETURN_FINAL_LENGTH 2
; calculate the index of the first null byte in the given YMM register
; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	vpmovmskb rcx, %2
	bsf ecx, ecx
; update the pointer to its final position
	lea rax, [rax+rcx+%1]
; calculate the length
	sub rax, rdi
	ret
%endmacro

section .text
; Checks whether the given 32-bytes chunk %1 contains a null byte.
; If any, calculates the index of the first null byte in the chunk and jumps to %2

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
	jz .align_the_pointer_to_the_starting_yword_boundary
	ret

align 16
.align_the_pointer_to_the_starting_yword_boundary:
	lea rax, [rdi-0xE0]
	and rax, -32 ; TODO: why does `and eax, -32` trigger a segmentation fault
align 16
.check_the_next_256_bytes:
; update the pointer
	add rax, 256
; keep the 32 bytes with the minimum value from all the next 256 bytes
; (see the diagram below for a more visual representation of the process)
	vmovdqa ymm1, [rax+0x00]
	vmovdqa ymm2, [rax+0x40]
	vmovdqa ymm3, [rax+0x80]
	vmovdqa ymm4, [rax+0xC0]
	vpminub ymm5,  ymm1, [rax+0x20]
	vpminub ymm6,  ymm2, [rax+0x60]
	vpminub ymm7,  ymm3, [rax+0xA0]
	vpminub ymm8,  ymm4, [rax+0xE0]
	vpminub ymm9,  ymm5, ymm6
	vpminub ymm10, ymm7, ymm8
	vpminub ymm11, ymm9, ymm10
;                  ,---ymm1  dst[0x00..=0x1F]
;           ,---ymm5
;           |      '-------  dst[0x20..=0x3F]
;     ,--ymm9
;     |     |      ,---ymm2  dst[0x40..=0x5F]
;     |     '---ymm6
;     |            '-------  dst[0x60..=0x7F]
; ymm11
;     |            ,---ymm3  dst[0x80..=0x9F]
;     |      ,--ymm7
;     |      |     '-------  dst[0xA0..=0xBF]
;     '--ymm10
;            |     ,---ymm4  dst[0xC0..=0xDF]
;            '--ymm8
;                  '-------  dst[0xE0..=0xFF]

; repeat until the next 256 bytes contain a null byte
	JUMP_IF_HAS_NO_NULL_BYTES .check_the_next_256_bytes, ymm11
; figure out which chunk contains the first null byte found
	JUMP_IF_HAS_NO_NULL_BYTES .null_byte_index_is_between_0x80_and_0xFF, ymm9
;null byte index is between 0x00 and 0x7F
	JUMP_IF_HAS_NO_NULL_BYTES .null_byte_index_is_between_0x40_and_0x7F, ymm5
;null byte index is between 0x00 and 0x3F
	vpcmpeqb ymm12, ymm0, [rax+0x20]
	JUMP_IF_HAS_NO_NULL_BYTES .null_byte_index_is_between_0x20_and_0x3F, ymm1
;null byte index is between 0x00 and 0x1F
	RETURN_FINAL_LENGTH 0x00, ymm1

align 16
.null_byte_index_is_between_0x80_and_0xFF:
	JUMP_IF_HAS_NO_NULL_BYTES .null_byte_index_is_between_0xC0_and_0xFF, ymm7
;null byte index is between 0x80 and 0xBF
	vpcmpeqb ymm12, ymm0, [rax+0xA0]
	JUMP_IF_HAS_NO_NULL_BYTES .null_byte_index_is_between_0xA0_and_0xBF, ymm3
;null byte index is between 0x80 and 0x9F
	RETURN_FINAL_LENGTH 0x80, ymm3

align 16
.null_byte_index_is_between_0xC0_and_0xFF:
	vpcmpeqb ymm12, ymm0, [rax+0xE0]
	JUMP_IF_HAS_NO_NULL_BYTES .null_byte_index_is_between_0xE0_and_0xFF, ymm4
;null byte index is between 0xC0 and 0xDF
	RETURN_FINAL_LENGTH 0xC0, ymm4

align 16
.null_byte_index_is_between_0xE0_and_0xFF:
	RETURN_FINAL_LENGTH 0xE0, ymm12

align 16
.null_byte_index_is_between_0xA0_and_0xBF:
	RETURN_FINAL_LENGTH 0xA0, ymm12

align 16
.null_byte_index_is_between_0x40_and_0x7F:
	vpcmpeqb ymm12, ymm0, [rax+0x60]
	JUMP_IF_HAS_NO_NULL_BYTES .null_byte_index_is_between_0x60_and_0x7F, ymm2
;null byte index is between 0x40 and 0x5F
	RETURN_FINAL_LENGTH 0x40, ymm2

align 16
.null_byte_index_is_between_0x60_and_0x7F:
	RETURN_FINAL_LENGTH 0x60, ymm12

align 16
.null_byte_index_is_between_0x20_and_0x3F:
	RETURN_FINAL_LENGTH 0x20, ymm12
