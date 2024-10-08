global ft_atoi_base: function

default rel

%use smartalign
ALIGNMODE p6

%define SIZEOF_BYTE  1
%define SIZEOF_QWORD 8
%define SIZEOF_YWORD 32

; Parameters
; %1: the label to jump to if the given YMM register contains no null byte
; %3: the yword to use as mask
; %2: the yword to check
;
; Note: ymm0 is assumed to be filled with zeros.
%macro JUMP_IF_HAS_NO_NULL_BYTE 3
	vpcmpeqb %2, ymm0, %3
	vptest %2, %2
	jz %1
%endmacro

section .text
; Parses a string into an integer, using a custom base.
; The base must be at least 2 characters long. It must not contain
; any duplicate characters, nor any of the following:
; `%x09-0D / %x20 / %x2B / %x2D`
;
; Parameters
; rdi: the address of the string to parse. (assumed to be a valid address)
; rsi: the address of the string to use as base. (assumed to be a valid address)
;
; Return:
; eax:
; - the parsed integer value if the base is valid.
; - 0 otherwise.
align 16
ft_atoi_base:

%define SIZEOF_ARRAY_OF_DIGITS 256*SIZEOF_BYTE

; preserve the stack pointer and align it to its previous yword boundary
	mov rdx, rsp
	and rsp, -SIZEOF_YWORD ; modulo SIZEOF_YWORD
; reserve space for the local constants/variables
	sub rsp, SIZEOF_ARRAY_OF_DIGITS
; preliminary initialization
	xor eax, eax
	vpxor ymm0, ymm0, ymm0
	vpcmpeqb ymm11, ymm11, ymm11
%assign offset 0
%rep 8
	vmovdqa [ rsp + offset ], ymm11
	%assign offset offset + SIZEOF_YWORD
%endrep
; load 4 of the maximum 8 ywords of the base
; (a valid base can contain at most 247 characters, which always fit 8 ywords)
	vmovdqu ymm1, [ rsi + 0 * SIZEOF_YWORD ]
	vmovdqu ymm2, [ rsi + 2 * SIZEOF_YWORD ]
	vmovdqu ymm3, [ rsi + 4 * SIZEOF_YWORD ]
	vmovdqu ymm4, [ rsi + 6 * SIZEOF_YWORD ]
; merge the ywords into one that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm5,  ymm1, [ rsi + 1 * SIZEOF_YWORD ]
	vpminub ymm6,  ymm2, [ rsi + 3 * SIZEOF_YWORD ]
	vpminub ymm7,  ymm3, [ rsi + 5 * SIZEOF_YWORD ]
	vpminub ymm8,  ymm4, [ rsi + 7 * SIZEOF_YWORD ]
	vpminub ymm9,  ymm5, ymm6
	vpminub ymm10, ymm7, ymm8
	vpminub ymm11, ymm9, ymm10
;                    ,---ymm1  base[0x00..=0x1F]
;            ,----ymm5
;            |       '-------  base[0x20..=0x3F]
;     ,---ymm9
;     |      |       ,---ymm2  base[0x40..=0x5F]
;     |      '----ymm6
;     |              '-------  base[0x60..=0x7F]
; ymm11
;     |              ,---ymm3  base[0x80..=0x9F]
;     |       ,---ymm7
;     |       |      '-------  base[0xA0..=0xBF]
;     '---ymm10
;             |      ,---ymm4  base[0xC0..=0xDF]
;             '---ymm8
;                    '-------  base[0xE0..=0xFF]

; check that the resulting yword contains a null byte
	JUMP_IF_HAS_NO_NULL_BYTE .return, ymm12, ymm11
;found_a_null_byte_in_the_base_between_the_indices_0x00_and_0xFF:
; initialize registers for the upcoming processing
	xor rcx, rcx
	xor r8, r8 ; the base length
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_NO_NULL_BYTE .found_a_null_byte_in_the_base_between_the_indices_0x80_and_0xFF, ymm13, ymm9
;found_a_null_byte_in_the_base_between_the_indices_0x00_and_0x7F:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_NO_NULL_BYTE .found_a_null_byte_in_the_base_between_the_indices_0x40_and_0x7F, ymm14, ymm5
;found_a_null_byte_in_the_base_between_the_indices_0x00_and_0x3F:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_NO_NULL_BYTE .found_a_null_byte_in_the_base_between_the_indices_0x20_and_0x3F, ymm15, ymm1
;found_a_null_byte_in_the_base_between_the_indices_0x00_and_0x1F:
	vpmovmskb r9, ymm15
	jmp .check_and_save_the_last_partial_yword_of_the_base_as_digits

align 16
.found_a_null_byte_in_the_base_between_the_indices_0x80_and_0xFF:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_NO_NULL_BYTE .found_a_null_byte_in_the_base_between_the_indices_0xC0_and_0xFF, ymm14, ymm7
;found_a_null_byte_in_the_base_between_the_indices_0x80_and_0xBF:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_NO_NULL_BYTE .found_a_null_byte_in_the_base_between_the_indices_0xA0_and_0xBF, ymm15, ymm3
;found_a_null_byte_in_the_base_between_the_indices_0x80_and_0x9F:
	mov r11b, 4
	vpmovmskb r9, ymm15
	vpxor ymm15, ymm15, ymm15
	jmp .check_and_save_the_next_yword_of_the_base_as_digits

align 16
.found_a_null_byte_in_the_base_between_the_indices_0xC0_and_0xFF:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_NO_NULL_BYTE .found_a_null_byte_in_the_base_between_the_indices_0xE0_and_0xFF, ymm15, ymm4
;found_a_null_byte_in_the_base_between_the_indices_0xC0_and_0xDF:
	mov r11b, 6
	vpmovmskb r9, ymm15
	vpxor ymm15, ymm15, ymm15
	jmp .check_and_save_the_next_yword_of_the_base_as_digits

align 16
.found_a_null_byte_in_the_base_between_the_indices_0xE0_and_0xFF:
	mov r11b, 7
	vpmovmskb r9, ymm12
	vpxor ymm15, ymm15, ymm15
	jmp .check_and_save_the_next_yword_of_the_base_as_digits

align 16
.found_a_null_byte_in_the_base_between_the_indices_0xA0_and_0xBF:
	mov r11b, 5
	vpmovmskb r9, ymm14
	vpxor ymm15, ymm15, ymm15
	jmp .check_and_save_the_next_yword_of_the_base_as_digits

align 16
.found_a_null_byte_in_the_base_between_the_indices_0x40_and_0x7F:
; figure out which yword contains the 1st null byte
	JUMP_IF_HAS_NO_NULL_BYTE .found_a_null_byte_in_the_base_between_the_indices_0x60_and_0x7F, ymm15, ymm2
;found_a_null_byte_in_the_base_between_the_indices_0x40_and_0x5F:
	mov r11b, 2
	vpmovmskb r9, ymm15
	vpxor ymm15, ymm15, ymm15
	jmp .check_and_save_the_next_yword_of_the_base_as_digits

align 16
.found_a_null_byte_in_the_base_between_the_indices_0x60_and_0x7F:
	mov r11b, 3
	vpmovmskb r9, ymm13
	vpxor ymm15, ymm15, ymm15
	jmp .check_and_save_the_next_yword_of_the_base_as_digits

align 16
.found_a_null_byte_in_the_base_between_the_indices_0x20_and_0x3F:
	mov r11b, 1
	vpmovmskb r9, ymm14
	vpxor ymm15, ymm15, ymm15
	jmp .check_and_save_the_next_yword_of_the_base_as_digits

align 16
.check_and_save_the_next_yword_of_the_base_as_digits:
; load the next yword from the base
	vmovdqu ymm0, [ rsi + r8 ]
; compare the yword with the forbidden characters
	vpcmpeqb ymm1, ymm0, [ HT ]
	vpcmpeqb ymm2, ymm0, [ VT ]
	vpcmpeqb ymm3, ymm0, [ CR ]
	vpcmpeqb ymm4, ymm0, [ LF ]
	vpcmpeqb ymm5, ymm0, [ FF ]
	vpcmpeqb ymm6, ymm0, [ space ]
	vpcmpeqb ymm7, ymm0, [ plus_sign ]
	vpcmpeqb ymm8, ymm0, [ minus_sign ]
; merge the comparison results into 1 yword
; (see the diagram below for a more visual representation of the process)
	vpor ymm9,  ymm1,  ymm2
	vpor ymm10, ymm3,  ymm4
	vpor ymm11, ymm5,  ymm6
	vpor ymm12, ymm7,  ymm8
	vpor ymm13, ymm9,  ymm10
	vpor ymm14, ymm11, ymm12
	vpor ymm15, ymm13, ymm14
;                    ,----ymm1  vpcmpeqb ymm0, [ HT ]
;             ,---ymm9
;             |      '----ymm2  vpcmpeqb ymm0, [ VT ]
;     ,---ymm13
;     |       |       ,---ymm3  vpcmpeqb ymm0, [ CR ]
;     |       '---ymm10
;     |               '---ymm4  vpcmpeqb ymm0, [ LF ]
; ymm15
;     |               ,---ymm5  vpcmpeqb ymm0, [ FF ]
;     |       ,---ymm11
;     |       |       '---ymm6  vpcmpeqb ymm0, [ space ]
;     '---ymm14
;             |       ,---ymm7  vpcmpeqb ymm0, [ plus_sign ]
;             '---ymm12
;                     '---ymm8  vpcmpeqb ymm0, [ minus_sign ]

; check that the yword contains no forbidden characters
	vptest ymm15, ymm15
	jnz .return
; iterate over each byte of the current ywordd
	mov ecx, SIZEOF_YWORD
align 16
.check_and_save_the_next_digit_of_the_current_yword:
; load the next digit from the base
	movzx r10, byte [ rsi + r8 ]
; check for duplicate
	cmp byte [ rsp + r10 ], -1
	jne .return
; save the digit in the internal array
	mov [ rsp + r10 ], r8b
; update the base pointer and the digit value
	inc r8b
; repeat until the entire yword is processed
	loop .check_and_save_the_next_digit_of_the_current_yword
; update the number of ywords to check and save as digits
	dec r11b
; repeat until all the ywords are processed
	jnz .check_and_save_the_next_yword_of_the_base_as_digits
align 16
.check_and_save_the_last_partial_yword_of_the_base_as_digits:
; calculate the index of the null byte in the last partial yword of the base
	bsf ecx, r9d ; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	test ecx, ecx
	jz .parse_the_string
; load the next yword from the base
	vmovdqu ymm0, [ rsi + r8 ]
; compare the yword with the forbidden characters
	vpcmpeqb ymm1, ymm0, [ HT ]
	vpcmpeqb ymm2, ymm0, [ VT ]
	vpcmpeqb ymm3, ymm0, [ CR ]
	vpcmpeqb ymm4, ymm0, [ LF ]
	vpcmpeqb ymm5, ymm0, [ FF ]
	vpcmpeqb ymm6, ymm0, [ space ]
	vpcmpeqb ymm7, ymm0, [ plus_sign ]
	vpcmpeqb ymm8, ymm0, [ minus_sign ]
; merge the comparison results into 1 yword
; (see the diagram below for a more visual representation of the process)
	vpor ymm9,  ymm1,  ymm2
	vpor ymm10, ymm3,  ymm4
	vpor ymm11, ymm5,  ymm6
	vpor ymm12, ymm7,  ymm8
	vpor ymm13, ymm9,  ymm10
	vpor ymm14, ymm11, ymm12
	vpor ymm15, ymm13, ymm14
;                    ,----ymm1  vpcmpeqb ymm0, [ HT ]
;             ,---ymm9
;             |      '----ymm2  vpcmpeqb ymm0, [ VT ]
;     ,---ymm13
;     |       |       ,---ymm3  vpcmpeqb ymm0, [ CR ]
;     |       '---ymm10
;     |               '---ymm4  vpcmpeqb ymm0, [ LF ]
; ymm15
;     |               ,---ymm5  vpcmpeqb ymm0, [ FF ]
;     |       ,---ymm11
;     |       |       '---ymm6  vpcmpeqb ymm0, [ space ]
;     '---ymm14
;             |       ,---ymm7  vpcmpeqb ymm0, [ plus_sign ]
;             '---ymm12
;                     '---ymm8  vpcmpeqb ymm0, [ minus_sign ]

; extract the bit mask of the comparison
	vpmovmskb r11, ymm15
; ignore the unwanted trailing bytes
	mov r10b, SIZEOF_YWORD
	sub r10b, cl
	shlx r11d, r11d, r10d ; REMIND: this is for little-endian. Use shrx instead of shlx for big-endian.
; check that the partial yword contains no forbidden characters
	test r11d, r11d
	jnz .return
align 16
.check_and_save_the_next_digit_of_the_last_partial_yword:
; load the next digit from the base
	movzx r10, byte [ rsi + r8 ]
; check for duplicate
	cmp byte [ rsp + r10 ], -1
	jne .return
; save the digit in the internal array
	mov [ rsp + r10 ], r8b
; update the base pointer and the digit value
	inc r8b
; repeat until the entire yword is processed
	loop .check_and_save_the_next_digit_of_the_last_partial_yword
; check that the base is at least 2 digits long
	cmp r8b, 2
	jb .return
align 16
.parse_the_string:
; load the 1st yword from the string
	vmovdqu ymm12, [ rdi ]
; compare the yword with the whitespaces
	vpcmpeqb ymm1,  ymm12, [ HT ]
	vpcmpeqb ymm3,  ymm12, [ VT ]
	vpcmpeqb ymm5,  ymm12, [ CR ]
	vpcmpeqb ymm7,  ymm12, [ LF ]
	vpcmpeqb ymm9,  ymm12, [ FF ]
	vpcmpeqb ymm11, ymm12, [ space ]
; merge the comparison results into 1 yword
; (see the diagram below for a more visual representation of the process)
	vpor ymm2,  ymm1, ymm3
	vpor ymm6,  ymm5, ymm7
	vpor ymm10, ymm9, ymm11
	vpor ymm4,  ymm2, ymm6
	vpor ymm8,  ymm4, ymm10
;                  ,----ymm1   vpcmpeqb ymm12, [ HT ]
;           ,---ymm2
;           |      '----ymm3   vpcmpeqb ymm12, [ VT ]
;    ,---ymm4
;    |      |      ,----ymm5   vpcmpeqb ymm12, [ CR ]
;    |      '---ymm6
;    |             '----ymm7   vpcmpeqb ymm12, [ LF ]
; ymm8
;    |              ,---ymm9   vpcmpeqb ymm12, [ FF ]
;    '----------ymm10
;                   '---ymm11  vpcmpeqb ymm12, [ space ]

; extract the bit mask of the comparison
	vpmovmskb r9, ymm8
; check if the yword contains a non-whitespace character
	cmp r9d, -1
	jne .advance_to_the_1st_non_whitespace_character
; align the string pointer to the next yword boundary
	add rdi,  SIZEOF_YWORD
	and rdi, -SIZEOF_YWORD ; modulo SIZEOF_YWORD
align 16
.look_for_non_whitespace_characters_in_the_next_yword:
; load the next yword from the string
	vmovdqa ymm12, [ rdi ]
; compare the yword with the whitespaces
	vpcmpeqb ymm1,  ymm12, [ HT ]
	vpcmpeqb ymm3,  ymm12, [ VT ]
	vpcmpeqb ymm5,  ymm12, [ CR ]
	vpcmpeqb ymm7,  ymm12, [ LF ]
	vpcmpeqb ymm9,  ymm12, [ FF ]
	vpcmpeqb ymm11, ymm12, [ space ]
; merge the comparison results into 1 yword
; (see the diagram below for a more visual representation of the process)
	vpor ymm2,  ymm1, ymm3
	vpor ymm6,  ymm5, ymm7
	vpor ymm10, ymm9, ymm11
	vpor ymm4,  ymm2, ymm6
	vpor ymm8,  ymm4, ymm10
;                  ,----ymm1   vpcmpeqb ymm12, [ HT ]
;           ,---ymm2
;           |      '----ymm3   vpcmpeqb ymm12, [ VT ]
;    ,---ymm4
;    |      |      ,----ymm5   vpcmpeqb ymm12, [ CR ]
;    |      '---ymm6
;    |             '----ymm7   vpcmpeqb ymm12, [ LF ]
; ymm8
;    |              ,---ymm9   vpcmpeqb ymm12, [ FF ]
;    '----------ymm10
;                   '---ymm11  vpcmpeqb ymm12, [ space ]

; extract the bit mask of the comparison
	vpmovmskb r9, ymm8
; check if the yword contains a non-whitespace character
	cmp r9d, -1
	jne .advance_to_the_1st_non_whitespace_character
; update the string pointer
	add rdi, SIZEOF_YWORD
; repeat until a non-whitespace character is found
	jmp .look_for_non_whitespace_characters_in_the_next_yword

align 16
.advance_to_the_1st_non_whitespace_character:
; calculate the index of the 1st non-whitespace character in the next yword of the string
	not r9d
	bsf ecx, r9d ; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
; update the string pointer
	add rdi, rcx
; broadcast the zero-digit to the YMM register for the upcoming comparisons
	vpbroadcastb ymm0, [ rsi ]
; initialize the number of minus signs encountered
	xor rsi, rsi
; calculate how far the string pointer is to its previous yword boundary
	mov r9, rdi
	and r9, SIZEOF_YWORD - 1 ; modulo SIZEOF_YWORD
; align the string pointer to its previous yword boundary
	and rdi, -SIZEOF_YWORD
; load the 1st aligned yword from the string that contains a sign
	vmovdqa ymm13, [ rdi ]
; compare the yword with the signs
	vpcmpeqb ymm5, ymm13, [ plus_sign ]
	vpcmpeqb ymm7, ymm13, [ minus_sign ]
; merge the comparison results into 1 yword
; (see the diagram below for a more visual representation of the process)
	vpor ymm6, ymm5, ymm7
;    ,---ymm5   vpcmpeqb ymm13, [ plus_sign ]
; ymm6
;    '---ymm7   vpcmpeqb ymm13, [ minus_sign ]

; extract the bit masks of the comparisons
	vpmovmskb r10, ymm6
	vpmovmskb r11, ymm7
; reverse the sign-mask to represent the non-sign characters
	not r10d
; ignore the unwanted leading bytes
	shrx r10d, r10d, r9d ; REMIND: this is for little-endian. Use shlx instead of shrx for big-endian.
	shrx r11d, r11d, r9d ; REMIND: this is for little-endian. Use shlx instead of shrx for big-endian.
; check if the yword contains a non-sign character
	test r10d, r10d
	jz .process_the_signs
; update the string pointer
	add rdi, r9
	jmp .advance_to_the_1st_non_sign_character

align 16
.process_the_signs:
	popcnt r11d, r11d
	add rsi, r11
; update the string pointer
	add rdi, SIZEOF_YWORD
; load the next yword from the string
	vmovdqa ymm13, [ rdi ]
; compare the yword with the signs
	vpcmpeqb ymm5, ymm13, [ plus_sign ]
	vpcmpeqb ymm7, ymm13, [ minus_sign ]
; merge the comparison results into 1 yword
; (see the diagram below for a more visual representation of the process)
	vpor ymm6, ymm5, ymm7
;    ,---ymm5   vpcmpeqb ymm13, [ plus_sign ]
; ymm6
;    '---ymm7   vpcmpeqb ymm13, [ minus_sign ]

; extract the bit masks of the comparisons
	vpmovmskb r10, ymm6
	vpmovmskb r11, ymm7
; reverse the sign-mask to represent the non-sign characters
	not r10d
; check if the yword contains a non-sign character
	test r10d, r10d
	jz .process_the_signs
align 16
.advance_to_the_1st_non_sign_character:
; calculate the index of the 1st non-sign character in the next yword of the string
	bsf ecx, r10d ; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
; ignore the unwanted trailing bytes
	mov r9b, SIZEOF_YWORD-1
	sub r9b, cl
	shlx r11d, r11d, r9d ; REMIND: this is for little-endian. Use shrx instead of shlx for big-endian.
; process the minus signs
	popcnt r11d, r11d
	add rsi, r11
; update the string pointer
	add rdi, rcx
align 16
.process_the_leading_zeros:
; load the next yword from the string
	vmovdqu ymm14, [ rdi ]
; compare the yword with the zero-digit
	vpcmpeqb ymm1, ymm14, ymm0
; check if the yword contains a non-zero-digit character
	vpmovmskb r9, ymm1
	cmp r9d, -1
	jne .advance_to_the_1st_non_zero_digit_character
; align the string pointer to the next yword boundary
	add rdi,  SIZEOF_YWORD
	and rdi, -SIZEOF_YWORD ; modulo SIZEOF_YWORD
align 16
.look_for_non_zero_digit_characters_in_the_next_yword:
; load the next yword from the string
	vmovdqa ymm14, [ rdi ]
; compare the yword with the zero-digit
	vpcmpeqb ymm1, ymm14, ymm0
; check if the yword contains a non-zero-digit character
	vpmovmskb r9, ymm1
	cmp r9d, -1
	jne .advance_to_the_1st_non_zero_digit_character
; update the string pointer
	add rdi, SIZEOF_YWORD
; repeat until a non-zero-digit character is found
	jmp .look_for_non_zero_digit_characters_in_the_next_yword

align 16
.advance_to_the_1st_non_zero_digit_character:
; calculate the index of the 1st non-zero-digit character in the next yword of the string
	not r9d
	bsf ecx, r9d ; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
; update the string pointer
	add rdi, rcx
align 16
.process_the_next_character:
; load the digit value of the next character of the string
	movzx r10, byte [ rdi ]
	movzx r10, byte [ rsp + r10 ]
; check if the character is a digit
	cmp r10b, -1
	je .apply_the_sign
; update the integer value
	imul eax, r8d
	add eax, r10d
; update the string pointer
	inc rdi
; repeat until the next character is not a digit
	jmp .process_the_next_character

align 16
.apply_the_sign:
	and rsi, 1 ; modulo 2
	test rsi, rsi
	jz .return
	neg eax
align 16
.return:
; clean the upper part of the YMM registers
	vzeroupper
; restore the stack pointer
	mov rsp, rdx
	ret

section .rodata
        HT: times SIZEOF_YWORD db 0x09
        VT: times SIZEOF_YWORD db 0x0B
        CR: times SIZEOF_YWORD db 0x0D
        LF: times SIZEOF_YWORD db 0x0A
        FF: times SIZEOF_YWORD db 0x0C
     space: times SIZEOF_YWORD db 0x20
 plus_sign: times SIZEOF_YWORD db 0x2B
minus_sign: times SIZEOF_YWORD db 0x2D
