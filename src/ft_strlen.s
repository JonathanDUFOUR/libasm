global ft_strlen: function

%use smartalign
ALIGNMODE p6

%define SIZEOF_YWORD 32

; Parameters:
; %1: the label to jump to if the given YMM register contains a null byte.
; %2: the yword to check (may be a YMM register or an address).
%macro JUMP_IF_HAS_A_NULL_BYTE 2
	vpcmpeqb ymm12, ymm0, %2
	vptest ymm12, ymm12
	jnz %1
%endmacro

%macro CLEAN_RET 0
	vzeroupper
	ret
%endmacro

; Parameters:
; %1: the offset to apply to the pointer before calculating the final length.
%macro RETURN_FINAL_LENGTH 1
; calculate the index of the first null byte in the given YMM register
; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	vpmovmskb rcx, ymm12
	bsf ecx, ecx
; update the pointer to its final position
	lea rax, [rax+rcx+%1]
; calculate the length
	sub rax, rdi
	CLEAN_RET
%endmacro

section .text
; Calculates the length of a null-terminated string.
;
; Parameters
; rdi: the address of the string to calculate the length of. (assumed to be a valid address)
;
; Return
; rax: the length of string.
align 16
ft_strlen:
; preliminary initializations
	mov rax, rdi
	vpxor ymm0, ymm0, ymm0
; align the pointer to the previous yword boundary
	and rax, -SIZEOF_YWORD
; check if the first yword contains a null byte
	vpcmpeqb ymm12, ymm0, [rax]
	vpmovmskb eax, ymm12
; ignore the unwanted leading bytes
	shrx eax, eax, edi
; calculate the index of the first null byte in the first yword if any
; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	bsf eax, eax
	jz .align_the_pointer_to_the_next_yword_boundary
	CLEAN_RET

.align_the_pointer_to_the_next_yword_boundary:
	lea rax, [rdi+SIZEOF_YWORD]
	and rax, -SIZEOF_YWORD
align 16
.check_the_next_8_ywords:
; load 4 of the next 8 ywords
	vmovdqa ymm1, [rax+0x20]
	vmovdqa ymm2, [rax+0x60]
	vmovdqa ymm3, [rax+0xA0]
	vmovdqa ymm4, [rax+0xE0]
; merge the 8 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm5,  ymm1, [rax+0x00]
	vpminub ymm6,  ymm2, [rax+0x40]
	vpminub ymm7,  ymm3, [rax+0x80]
	vpminub ymm8,  ymm4, [rax+0xC0]
	vpminub ymm9,  ymm5, ymm6
	vpminub ymm10, ymm7, ymm8
	vpminub ymm11, ymm9, ymm10
;                    ,-------  s[0x00..=0x1F]
;            ,----ymm5
;            |       '---ymm1  s[0x20..=0x3F]
;     ,---ymm9
;     |      |       ,-------  s[0x40..=0x5F]
;     |      '----ymm6
;     |              '---ymm2  s[0x60..=0x7F]
; ymm11
;     |              ,-------  s[0x80..=0x9F]
;     |       ,---ymm7
;     |       |      '---ymm3  s[0xA0..=0xBF]
;     '---ymm10
;             |      ,-------  s[0xC0..=0xDF]
;             '---ymm8
;                    '---ymm4  s[0xE0..=0xFF]

; check if the resulting yword contains a null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0xFF, ymm11
; update the pointer
	add rax, 8 * SIZEOF_YWORD
; repeat until the next 8 ywords contain a null byte
	jmp .check_the_next_8_ywords

align 16
.found_a_null_byte_between_the_indices_0x00_and_0xFF:
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x7F, ymm9
;found_a_null_byte_between_the_indices_0x80_and_0xFF
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x80_and_0xBF, ymm7
;found_a_null_byte_between_the_indices_0xC0_and_0xFF
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0xC0_and_0xDF, [rax+0xC0]
;found_a_null_byte_between_the_indices_0xE0_and_0xFF
	vpcmpeqb ymm12, ymm0, ymm4
	RETURN_FINAL_LENGTH 0xE0

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x7F:
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x3F, ymm5
;found_a_null_byte_between_the_indices_0x40_and_0x7F
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x40_and_0x5F, [rax+0x40]
;found_a_null_byte_between_the_indices_0x60_and_0x7F
	vpcmpeqb ymm12, ymm0, ymm2
	RETURN_FINAL_LENGTH 0x60

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x3F:
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x1F, [rax+0x00]
;found_a_null_byte_between_the_indices_0x20_and_0x3F
	vpcmpeqb ymm12, ymm0, ymm1
	RETURN_FINAL_LENGTH 0x20

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x1F:
	RETURN_FINAL_LENGTH 0x00

align 16
.found_a_null_byte_between_the_indices_0x40_and_0x5F:
	RETURN_FINAL_LENGTH 0x40

align 16
.found_a_null_byte_between_the_indices_0x80_and_0xBF:
; figure out which yword contains the first null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x80_and_0x9F, [rax+0x80]
;found_a_null_byte_between_the_indices_0xA0_and_0xBF
	vpcmpeqb ymm12, ymm0, ymm3
	RETURN_FINAL_LENGTH 0xA0

align 16
.found_a_null_byte_between_the_indices_0x80_and_0x9F:
	RETURN_FINAL_LENGTH 0x80

align 16
.found_a_null_byte_between_the_indices_0xC0_and_0xDF:
	RETURN_FINAL_LENGTH 0xC0
