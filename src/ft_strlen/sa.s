global ft_strlen_sa: function

%use smartalign
ALIGNMODE p6

%define YWORD_SIZE 32

; Parameters
; %1: the label to jump to if the given YMM register contains a null byte.
; %2: the yword to check (may be a YMM register or an address).
%macro JUMP_IF_HAS_A_NULL_BYTE 2
	vpcmpeqb ymm12, ymm0, %2
	vptest ymm12, ymm12
	jnz %1
%endmacro

%macro VZEROUPPER_RET 0
	vzeroupper
	ret
%endmacro

; Parameters
; %1: the offset to apply to the pointer before calculating the final length.
%macro RETURN_FINAL_LENGTH 1
; calculate the index of the 1st null byte in the given YMM register
	vpmovmskb rcx, ymm12
	bsf ecx, ecx ; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
; update the pointer to its final position
	lea rax, [ rax + %1 + rcx ]
; calculate the length
	sub rax, rdi
	VZEROUPPER_RET
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
ft_strlen_sa:
; preliminary initialization
	mov rax, rdi
	vpxor ymm0, ymm0, ymm0
; align the pointer to the previous yword boundary
	and rax, -YWORD_SIZE
; check if the 1st yword contains a null byte
	vpcmpeqb ymm12, ymm0, [ rax ]
	vpmovmskb rdx, ymm12
; ignore the unwanted leading bytes
	shrx edx, edx, edi ; REMIND: this is for little-endian. Use shlx instead of shrx for big-endian.
; calculate the index of the 1st null byte in the 1st yword if any
	bsf edx, edx ; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	jnz .small_length
; update the pointer to the next yword boundary:
	add rax, YWORD_SIZE
;is_pointer_aligned_to_2_ywords_boundary
	test rax, YWORD_SIZE
	jz .is_pointer_aligned_to_4_ywords_boundary
; check if the next yword contains a null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x1F, [ rax ]
; update the pointer to the next 2-ywords boundary
	add rax, YWORD_SIZE
align 16
.is_pointer_aligned_to_4_ywords_boundary:
	test rax, 2 * YWORD_SIZE
	jz .is_pointer_aligned_to_8_ywords_boundary
; load 1 of the next 2 ywords from the string
	vmovdqa ymm1, [ rax + 0 * YWORD_SIZE ]
; merge the 2 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm5, ymm1, [ rax + 1 * YWORD_SIZE ]
;    ,---ymm1  s[0x00..=0x1F]
; ymm5
;    '-------  s[0x20..=0x3F]
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x3F, ymm5
; update the pointer to the next 4-ywords boundary
	add rax, 2 * YWORD_SIZE
align 16
.is_pointer_aligned_to_8_ywords_boundary:
	test rax, 4 * YWORD_SIZE
	jz .check_the_next_8_ywords
; load 2 of the next 4 ywords from the string
	vmovdqa ymm1, [ rax + 0 * YWORD_SIZE ]
	vmovdqa ymm2, [ rax + 2 * YWORD_SIZE ]
; merge the 4 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm5, ymm1, [ rax + 1 * YWORD_SIZE ]
	vpminub ymm6, ymm2, [ rax + 3 * YWORD_SIZE ]
	vpminub ymm9, ymm5, ymm6
;            ,---ymm1  s[0x00..=0x1F]
;    ,----ymm5
;    |       '-------  s[0x20..=0x3F]
; ymm9
;    |       ,---ymm2  s[0x40..=0x5F]
;    '----ymm6
;            '-------  s[0x60..=0x7F]
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x7F, ymm9
; update the pointer to the next 8-ywords boundary
	add rax, 4 * YWORD_SIZE
align 16
.check_the_next_8_ywords:
; load 4 of the next 8 ywords from the string
	vmovdqa ymm1, [ rax + 0 * YWORD_SIZE ]
	vmovdqa ymm2, [ rax + 2 * YWORD_SIZE ]
	vmovdqa ymm3, [ rax + 4 * YWORD_SIZE ]
	vmovdqa ymm4, [ rax + 6 * YWORD_SIZE ]
; merge the 8 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm5,  ymm1, [ rax + 1 * YWORD_SIZE ]
	vpminub ymm6,  ymm2, [ rax + 3 * YWORD_SIZE ]
	vpminub ymm7,  ymm3, [ rax + 5 * YWORD_SIZE ]
	vpminub ymm8,  ymm4, [ rax + 7 * YWORD_SIZE ]
	vpminub ymm9,  ymm5, ymm6
	vpminub ymm10, ymm7, ymm8
	vpminub ymm11, ymm9, ymm10
;                    ,---ymm1  s[0x00..=0x1F]
;            ,----ymm5
;            |       '-------  s[0x20..=0x3F]
;     ,---ymm9
;     |      |       ,---ymm2  s[0x40..=0x5F]
;     |      '----ymm6
;     |              '-------  s[0x60..=0x7F]
; ymm11
;     |              ,---ymm3  s[0x80..=0x9F]
;     |       ,---ymm7
;     |       |      '-------  s[0xA0..=0xBF]
;     '---ymm10
;             |      ,---ymm4  s[0xC0..=0xDF]
;             '---ymm8
;                    '-------  s[0xE0..=0xFF]
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0xFF, ymm11
; update the pointer
	add rax, 8 * YWORD_SIZE
; repeat until the next 8 ywords contain a null byte
	jmp .check_the_next_8_ywords

;---------------------------------------------+
; figure out which yword contains a null byte |
;             using binary search             |
;---------------------------------------------+

align 16
.found_null_byte_in_0x00_0xFF:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x7F, ymm9
;found_null_byte_in_0x80_0xFF:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x80_0xBF, ymm7
;found_null_byte_in_0xC0_0xFF:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0xC0_0xDF, ymm4
;found_null_byte_in_0xE0_0xFF:
	vpcmpeqb ymm12, ymm0, [ rax + 7 * YWORD_SIZE ]
	RETURN_FINAL_LENGTH 0xE0

align 16
.found_null_byte_in_0x00_0x7F:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x3F, ymm5
;found_null_byte_in_0x40_0x7F:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x40_0x5F, ymm2
;found_null_byte_in_0x60_0x7F:
	vpcmpeqb ymm12, ymm0, [ rax + 3 * YWORD_SIZE ]
	RETURN_FINAL_LENGTH 0x60

align 16
.found_null_byte_in_0x00_0x3F:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x1F, ymm1
;found_null_byte_in_0x20_0x3F:
	vpcmpeqb ymm12, ymm0, [ rax + 1 * YWORD_SIZE ]
	RETURN_FINAL_LENGTH 0x20

align 16
.found_null_byte_in_0x00_0x1F:
	RETURN_FINAL_LENGTH 0x00

align 16
.found_null_byte_in_0x40_0x5F:
	RETURN_FINAL_LENGTH 0x40

align 16
.found_null_byte_in_0x80_0xBF:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x80_0x9F, ymm3
;found_null_byte_in_0xA0_0xBF:
	vpcmpeqb ymm12, ymm0, [ rax + 5 * YWORD_SIZE ]
	RETURN_FINAL_LENGTH 0xA0

align 16
.found_null_byte_in_0x80_0x9F:
	RETURN_FINAL_LENGTH 0x80

align 16
.found_null_byte_in_0xC0_0xDF:
	RETURN_FINAL_LENGTH 0xC0

align 16
.small_length:
	mov rax, rdx
	VZEROUPPER_RET
