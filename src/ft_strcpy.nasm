; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2

global ft_strcpy: function

%use smartalign
ALIGNMODE p6

%define  BYTE_SIZE  1
%define  WORD_SIZE  2
%define DWORD_SIZE  4
%define QWORD_SIZE  8
%define OWORD_SIZE 16
%define YWORD_SIZE 32

; Parameters
; %1: the label to jump to if the given YMM register contains a null byte.
; %2: the YMM register to check.
%macro JUMP_IF_HAS_A_NULL_BYTE 2
	vpcmpeqb ymm15, ymm0, %2
	vptest ymm15, ymm15
	jnz %1
%endmacro

; Paramters:
; %1: the number of ywords to advance both the destination pointer and the source pointer by.
; %2: the YMM register that contains the 1st null byte.
%macro COPY_THE_LAST_BYTES_UP_TO_32 2
%if %1 > 0
; update the pointers
	add rdi, YWORD_SIZE * %1
	add rsi, YWORD_SIZE * %1
%endif
; calculate the index of the 1st null byte in the given YMM register
	vpcmpeqb ymm0, ymm0, %2
	vpmovmskb rdx, ymm0
	bsf edx, edx
	jmp .copy_last_bytes
%endmacro

%macro VZEROUPPER_RET 0
	vzeroupper
	ret
%endmacro

section .text align=16
; Copies a string to another string.
; The source string is assumed to be null-terminated.
; The destination string is assumed to be large enough
; to hold the source string, including its null terminator.
;
; Parameters
; rdi: the address of the destination string to copy to. (assumed to be a valid address)
; rsi: the address of the source string to copy from. (assumed to be a valid address)
;
; Return:
; rax: the address of the destination string.
ft_strcpy:
; preliminary initialization
	mov rax, rdi
	mov r10, 0x0101010101010101
	mov r11, 0x8080808080808080
	vpxor ymm0, ymm0, ymm0
;is_source_pointer_aligned_to_word_boundary:
	test rsi, BYTE_SIZE
	jz .is_source_pointer_aligned_to_dword_boundary
; load the first byte from the source string
	mov cl, [ rsi ]
; check if it is a null byte
	test cl, cl
	jz .empty_string
; store the first byte to the destination string
	mov [ rdi ], cl
; update the pointers
	add rdi, BYTE_SIZE
	add rsi, BYTE_SIZE
align 16
.is_source_pointer_aligned_to_dword_boundary:
	test rsi, WORD_SIZE
	jz .is_source_pointer_aligned_to_qword_boundary
; load the first aligned word from the source string
	mov cx, [ rsi ]
; check if it contains a null byte
	mov r8w, cx
	mov r9w, cx
	sub r8w, r10w
	not r9w
	and r8w, r9w
	and r8w, r11w
	jnz .small_copy
; store the first aligned word to the destination string
	mov [ rdi ], cx
; update the pointers
	add rdi, WORD_SIZE
	add rsi, WORD_SIZE
align 16
.is_source_pointer_aligned_to_qword_boundary:
	test rsi, DWORD_SIZE
	jz .is_source_pointer_aligned_to_oword_boundary
; load the first aligned dword from the source string
	mov ecx, [ rsi ]
; check if it contains a null byte
	mov r8d, ecx
	mov r9d, ecx
	sub r8d, r10d
	not r9d
	and r8d, r9d
	and r8d, r11d
	jnz .small_copy
; store the first aligned dword to the destination string
	mov [ rdi ], ecx
; update the pointers
	add rdi, DWORD_SIZE
	add rsi, DWORD_SIZE
align 16
.is_source_pointer_aligned_to_oword_boundary:
	test rsi, QWORD_SIZE
	jz .is_source_pointer_aligned_to_yword_boundary
; load the first aligned qword from the source string
	mov rcx, [ rsi ]
; check if it contains a null byte
	mov r8, rcx
	mov r9, rcx
	sub r8, r10
	not r9
	and r8, r9
	and r8, r11
	jnz .small_copy
; store the first aligned qword to the destination string
	mov [ rdi ], rcx
; update the pointers
	add rdi, QWORD_SIZE
	add rsi, QWORD_SIZE
align 16
.is_source_pointer_aligned_to_yword_boundary:
	test rsi, OWORD_SIZE
	jz .is_source_pointer_aligned_to_2_ywords_boundary
; load the first aligned oword from the source string
	movdqa xmm5, [ rsi ]
; check if it contains a null byte
	vpcmpeqb xmm6, xmm0, xmm5
	vpmovmskb rdx, xmm6
	bsf edx, edx
	jnz .copy_last_bytes
; store the first aligned oword to the destination string
	movdqu [ rdi ], xmm5
; update the pointers
	add rdi, OWORD_SIZE
	add rsi, OWORD_SIZE
align 16
.is_source_pointer_aligned_to_2_ywords_boundary:
	test rsi, YWORD_SIZE
	jz .is_source_pointer_aligned_to_4_ywords_boundary
; load the first aligned yword
	vmovdqa ymm1, [ rsi ]
; check if it contains a null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x1F, ymm1
; store the first aligned yword to the destination string
	vmovdqu [ rdi ], ymm1
; update the pointers
	add rdi, YWORD_SIZE
	add rsi, YWORD_SIZE
align 16
.is_source_pointer_aligned_to_4_ywords_boundary:
	test rsi, YWORD_SIZE * 2
	jz .is_source_pointer_aligned_to_8_ywords_boundary
; load the first aligned 2 ywords from the source string
	vmovdqa ymm1, [ rsi + YWORD_SIZE * 0 ]
	vmovdqa ymm2, [ rsi + YWORD_SIZE * 1 ]
; merge the 2 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm9, ymm1, ymm2
;    ,--- ymm1  src[0x00..=0x1F]
; ymm9
;    '--- ymm2  src[0x20..=0x3F]
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x3F, ymm9
; store the first aligned 2 ywords to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 0 ], ymm1
	vmovdqu [ rdi + YWORD_SIZE * 1 ], ymm2
; update pointers
	add rdi, YWORD_SIZE * 2
	add rsi, YWORD_SIZE * 2
align 16
.is_source_pointer_aligned_to_8_ywords_boundary:
	test rsi, YWORD_SIZE * 4
	jz .check_next_8_ywords
; load the first aligned 4 ywords from the source string
	vmovdqa ymm1, [ rsi + YWORD_SIZE * 0 ]
	vmovdqa ymm2, [ rsi + YWORD_SIZE * 1 ]
	vmovdqa ymm3, [ rsi + YWORD_SIZE * 2 ]
	vmovdqa ymm4, [ rsi + YWORD_SIZE * 3 ]
; merge the 4 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm9,  ymm1, ymm2
	vpminub ymm10, ymm3, ymm4
	vpminub ymm13, ymm9, ymm10
;            ,----ymm1  src[0x00..=0x1F]
;     ,---ymm9
;     |      '----ymm2  src[0x20..=0x3F]
; ymm13
;     |       ,---ymm3  src[0x40..=0x5F]
;     '---ymm10
;             '---ymm4  src[0x60..=0x7F]
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x7F, ymm13
; store the first aligned 4 ywords to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 0 ], ymm1
	vmovdqu [ rdi + YWORD_SIZE * 1 ], ymm2
	vmovdqu [ rdi + YWORD_SIZE * 2 ], ymm3
	vmovdqu [ rdi + YWORD_SIZE * 3 ], ymm4
; update pointers
	add rdi, YWORD_SIZE * 4
	add rsi, YWORD_SIZE * 4
align 16
.check_next_8_ywords:
; load the next 8 ywords from the source string
	vmovdqa ymm1, [ rsi + YWORD_SIZE * 0 ]
	vmovdqa ymm2, [ rsi + YWORD_SIZE * 1 ]
	vmovdqa ymm3, [ rsi + YWORD_SIZE * 2 ]
	vmovdqa ymm4, [ rsi + YWORD_SIZE * 3 ]
	vmovdqa ymm5, [ rsi + YWORD_SIZE * 4 ]
	vmovdqa ymm6, [ rsi + YWORD_SIZE * 5 ]
	vmovdqa ymm7, [ rsi + YWORD_SIZE * 6 ]
	vmovdqa ymm8, [ rsi + YWORD_SIZE * 7 ]
; merge the 8 ywords into 1 yword that will contain their minimum byte values
; (see the diagram below for a more visual representation of the process)
	vpminub ymm9,  ymm1,  ymm2
	vpminub ymm10, ymm3,  ymm4
	vpminub ymm11, ymm5,  ymm6
	vpminub ymm12, ymm7,  ymm8
	vpminub ymm13, ymm9,  ymm10
	vpminub ymm14, ymm11, ymm12
	vpminub ymm15, ymm13, ymm14
;                    ,----ymm1  src[0x00..=0x1F]
;             ,---ymm9
;             |      '----ymm2  src[0x20..=0x3F]
;     ,---ymm13
;     |       |       ,---ymm3  src[0x40..=0x5F]
;     |       '---ymm10
;     |               '---ymm4  src[0x60..=0x7F]
; ymm15
;     |               ,---ymm5  src[0x80..=0x9F]
;     |       ,---ymm11
;     |       |       '---ymm6  src[0xA0..=0xBF]
;     '---ymm14
;             |       ,---ymm7  src[0xC0..=0xDF]
;             '---ymm12
;                     '---ymm8  src[0xE0..=0xFF]
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0xFF, ymm15
; store the next 8 ywords to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 0 ], ymm1
	vmovdqu [ rdi + YWORD_SIZE * 1 ], ymm2
	vmovdqu [ rdi + YWORD_SIZE * 2 ], ymm3
	vmovdqu [ rdi + YWORD_SIZE * 3 ], ymm4
	vmovdqu [ rdi + YWORD_SIZE * 4 ], ymm5
	vmovdqu [ rdi + YWORD_SIZE * 5 ], ymm6
	vmovdqu [ rdi + YWORD_SIZE * 6 ], ymm7
	vmovdqu [ rdi + YWORD_SIZE * 7 ], ymm8
; update the pointers
	add rdi, YWORD_SIZE * 8
	add rsi, YWORD_SIZE * 8
; repeat until the next 8 ywords contain a null byte
	jmp .check_next_8_ywords

;---------------------------------------------+
; figure out which yword contains a null byte |
;             using binary search             |
;---------------------------------------------+

align 16
.found_null_byte_in_0x00_0xFF:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x7F, ymm13
;found_null_byte_in_0x80_0xFF:
; store the next 4 ywords to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 0 ], ymm1
	vmovdqu [ rdi + YWORD_SIZE * 1 ], ymm2
	vmovdqu [ rdi + YWORD_SIZE * 2 ], ymm3
	vmovdqu [ rdi + YWORD_SIZE * 3 ], ymm4
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x80_0xBF, ymm11
;found_null_byte_in_0xC0_0xFF:
; store the next 2 ywords to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 4 ], ymm5
	vmovdqu [ rdi + YWORD_SIZE * 5 ], ymm6
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0xC0_0xDF, ymm7
;found_null_byte_in_0xE0_0xFF:
; store the next yword to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 6 ], ymm7
	COPY_THE_LAST_BYTES_UP_TO_32 7, ymm8

align 16
.found_null_byte_in_0x00_0x7F:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x3F, ymm9
;found_null_byte_in_0x40_0x7F:
; store the next 2 ywords to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 0 ], ymm1
	vmovdqu [ rdi + YWORD_SIZE * 1 ], ymm2
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x40_0x5F, ymm3
;found_null_byte_in_0x60_0x7F:
; store the next yword to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 2 ], ymm3
	COPY_THE_LAST_BYTES_UP_TO_32 3, ymm4

align 16
.found_null_byte_in_0x00_0x3F:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x00_0x1F, ymm1
;found_null_byte_in_0x20_0x3F:
; store the next yword to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 0 ], ymm1
	COPY_THE_LAST_BYTES_UP_TO_32 1, ymm2

align 16
.found_null_byte_in_0x00_0x1F:
	COPY_THE_LAST_BYTES_UP_TO_32 0, ymm1

align 16
.found_null_byte_in_0x40_0x5F:
	COPY_THE_LAST_BYTES_UP_TO_32 2, ymm3

align 16
.found_null_byte_in_0x80_0xBF:
	JUMP_IF_HAS_A_NULL_BYTE .found_null_byte_in_0x80_0x9F, ymm5
;found_null_byte_in_0xA0_0xBF:
; store the next yword to the destination string
	vmovdqu [ rdi + YWORD_SIZE * 4 ], ymm5
	COPY_THE_LAST_BYTES_UP_TO_32 5, ymm6

align 16
.found_null_byte_in_0x80_0x9F:
	COPY_THE_LAST_BYTES_UP_TO_32 4, ymm5

align 16
.found_null_byte_in_0xC0_0xDF:
	COPY_THE_LAST_BYTES_UP_TO_32 6, ymm7

;------------+
; edge cases |
;------------+

align 16
.empty_string:
	mov [ rdi ], cl
	ret

align 16
.small_copy:
; calculate the index of the 1st null byte in the 1st aligned word
	bsf rdx, r8
	shr rdx, 3 ; divide by 8

;-------------------------------+
;      copy the last bytes      |
; including the null-terminator |
;-------------------------------+

align 16
.copy_last_bytes:
	inc edx
	cmp edx, OWORD_SIZE
	ja .copy_last_2_owords
	cmp edx, QWORD_SIZE
	ja .copy_last_2_qwords
	cmp edx, DWORD_SIZE
	ja .copy_last_2_dwords
	cmp edx, WORD_SIZE
	ja .copy_last_2_words
;copy_last_2_bytes:
	mov cl,  [ rsi ]
	mov sil, [ rsi + rdx - BYTE_SIZE ]
	mov [ rdi ], cl
	mov [ rdi + rdx - BYTE_SIZE ], sil
	VZEROUPPER_RET

align 16
.copy_last_2_owords:
	movdqu xmm3, [ rsi ]
	movdqu xmm4, [ rsi + rdx - OWORD_SIZE ]
	movdqu [ rdi ], xmm3
	movdqu [ rdi + rdx - OWORD_SIZE ], xmm4
	VZEROUPPER_RET

align 16
.copy_last_2_qwords:
	mov rcx, [ rsi ]
	mov rsi, [ rsi + rdx - QWORD_SIZE ]
	mov [ rdi ], rcx
	mov [ rdi + rdx - QWORD_SIZE ], rsi
	VZEROUPPER_RET

align 16
.copy_last_2_dwords:
	mov ecx, [ rsi ]
	mov esi, [ rsi + rdx - DWORD_SIZE ]
	mov [ rdi ], ecx
	mov [ rdi + rdx - DWORD_SIZE ], esi
	VZEROUPPER_RET

align 16
.copy_last_2_words:
	mov cx, [ rsi ]
	mov si, [ rsi + rdx - WORD_SIZE ]
	mov [ rdi ], cx
	mov [ rdi + rdx - WORD_SIZE ], si
	VZEROUPPER_RET
