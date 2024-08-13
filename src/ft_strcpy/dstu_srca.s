global ft_strcpy_dstu_srca: function

%use smartalign
ALIGNMODE p6

%define SIZEOF_BYTE 1
%define SIZEOF_WORD 2
%define SIZEOF_DWORD 4
%define SIZEOF_QWORD 8
%define SIZEOF_OWORD 16
%define SIZEOF_YWORD 32

; Parameters:
; %1: the label to jump to if the given YMM register contains a null byte.
; %2: the YMM register to check.
%macro JUMP_IF_HAS_A_NULL_BYTE 2
	vpcmpeqb ymm15, ymm0, %2
	vptest ymm15, ymm15
	jnz %1
%endmacro

; Paramters:
; %1: the number of ywords to advance both the destination pointer and the source pointer by.
; %2: the YMM register that contains the first null byte.
%macro COPY_THE_LAST_BYTES_UP_TO_32 2
; update the pointers
	add rdi, %1 * SIZEOF_YWORD
	add rsi, %1 * SIZEOF_YWORD
; calculate the index of the first null byte in the given YMM register
	vpcmpeqb ymm0, ymm0, %2
	vpmovmskb rdx, ymm0
; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	bsf edx, edx
	jmp .copy_between_1_and_32_bytes
%endmacro

%macro CLEAN_RET 0
	vzeroupper
	ret
%endmacro

section .text
; Copies a string to another string.
; The source string is assumed to be null-terminated.
; The destination string is assumed to be large enough
; to hold the source string, including its null terminator.
;
; Parameters:
; rdi: the address of the destination string to copy to. (assumed to be a valid address)
; rsi: the address of the source string to copy from. (assumed to be a valid address)
;
; Return:
; rax: the address of the destination string.
align 16
ft_strcpy_dstu_srca:
; preliminary initialization
	mov rax, rdi
	vpxor ymm0, ymm0, ymm0
; load the first yword of the soure string
	vmovdqu ymm1, [rsi]
; calculate the index of the first null byte in the first yword if any
	vpcmpeqb ymm2, ymm0, ymm1
	vpmovmskb rdx, ymm2
; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	bsf edx, edx
	jnz .copy_between_1_and_32_bytes
; store the first yword to the destination string
	vmovdqu [rdi], ymm1
; calculate how har the source string is to its next yword boundary
	mov rcx, rsi
	neg rcx
	and rcx, 31 ; modulo 32
; advance both the destination pointer and the source pointer by the calculated distance
	add rdi, rcx
	add rsi, rcx
align 16
.check_the_next_8_ywords:
; load the next 8 ywords of the source string
	vmovdqa ymm1, [rsi+0x00]
	vmovdqa ymm2, [rsi+0x20]
	vmovdqa ymm3, [rsi+0x40]
	vmovdqa ymm4, [rsi+0x60]
	vmovdqa ymm5, [rsi+0x80]
	vmovdqa ymm6, [rsi+0xA0]
	vmovdqa ymm7, [rsi+0xC0]
	vmovdqa ymm8, [rsi+0xE0]
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
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0xFF, ymm15
; store the next 8 ywords to the destination string
	vmovdqu [rdi+0x00], ymm1
	vmovdqu [rdi+0x20], ymm2
	vmovdqu [rdi+0x40], ymm3
	vmovdqu [rdi+0x60], ymm4
	vmovdqu [rdi+0x80], ymm5
	vmovdqu [rdi+0xA0], ymm6
	vmovdqu [rdi+0xC0], ymm7
	vmovdqu [rdi+0xE0], ymm8
; update the pointers
	add rdi, 8 * SIZEOF_YWORD
	add rsi, 8 * SIZEOF_YWORD
; repeat until the next 8 ywords contain a null byte
	jmp .check_the_next_8_ywords

align 16
.found_a_null_byte_between_the_indices_0x00_and_0xFF:
; figure out which yword contains the null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x7F, ymm13

;found_a_null_byte_between_the_indices_0x80_and_0xFF:
; store the next 4 ywords to the destination string
	vmovdqu [rdi+0x00], ymm1
	vmovdqu [rdi+0x20], ymm2
	vmovdqu [rdi+0x40], ymm3
	vmovdqu [rdi+0x60], ymm4
; figure out which yword contains the null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x80_and_0xBF, ymm11

;found_a_null_byte_between_the_indices_0xC0_and_0xFF:
; store the next 2 ywords to the destination string
	vmovdqu [rdi+0x80], ymm5
	vmovdqu [rdi+0xA0], ymm6
; figure out which yword contains the null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0xC0_and_0xDF, ymm7

;found_a_null_byte_between_the_indices_0xE0_and_0xFF:
; store the next yword to the destination string
	vmovdqu [rdi+0xC0], ymm7
	COPY_THE_LAST_BYTES_UP_TO_32 7, ymm8

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x7F:
; figure out which yword contains the null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x3F, ymm9

;found_a_null_byte_between_the_indices_0x40_and_0x7F:
; store the next 2 ywords to the destination string
	vmovdqu [rdi+0x00], ymm1
	vmovdqu [rdi+0x20], ymm2
; figure out which yword contains the null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x40_and_0x5F, ymm3

;found_a_null_byte_between_the_indices_0x60_and_0x7F:
; store the next yword to the destination string
	vmovdqu [rdi+0x40], ymm3
	COPY_THE_LAST_BYTES_UP_TO_32 3, ymm4

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x3F:
; figure out which yword contains the null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x00_and_0x1F, ymm1

;found_a_null_byte_between_the_indices_0x20_and_0x3F:
; store the next yword to the destination string
	vmovdqu [rdi+0x00], ymm1
	COPY_THE_LAST_BYTES_UP_TO_32 1, ymm2

align 16
.found_a_null_byte_between_the_indices_0x00_and_0x1F:
	COPY_THE_LAST_BYTES_UP_TO_32 0, ymm1

align 16
.found_a_null_byte_between_the_indices_0x40_and_0x5F:
	COPY_THE_LAST_BYTES_UP_TO_32 2, ymm3

align 16
.found_a_null_byte_between_the_indices_0x80_and_0xBF:
; figure out which yword contains the null byte
	JUMP_IF_HAS_A_NULL_BYTE .found_a_null_byte_between_the_indices_0x80_and_0x9F, ymm5

;found_a_null_byte_between_the_indices_0xA0_and_0xBF:
; store the next yword to the destination string
	vmovdqu [rdi+0x80], ymm5
	COPY_THE_LAST_BYTES_UP_TO_32 5, ymm6

align 16
.found_a_null_byte_between_the_indices_0x80_and_0x9F:
	COPY_THE_LAST_BYTES_UP_TO_32 4, ymm5

align 16
.found_a_null_byte_between_the_indices_0xC0_and_0xDF:
	COPY_THE_LAST_BYTES_UP_TO_32 6, ymm7

align 16
.copy_between_1_and_32_bytes:
	inc edx
	cmp edx, 16
	ja .copy_between_17_and_32_bytes
	cmp edx, 8
	ja .copy_between_9_and_16_bytes
	cmp edx, 4
	ja .copy_between_5_and_8_bytes
	cmp edx, 2
	ja .copy_between_3_and_4_bytes
;copy between 1 and 2 bytes:
	mov cl,  [rsi]
	mov sil, [rsi+rdx-SIZEOF_BYTE]
	mov [rdi], cl
	mov [rdi+rdx-SIZEOF_BYTE], sil
	CLEAN_RET

align 16
.copy_between_3_and_4_bytes:
	mov cx, [rsi]
	mov si, [rsi+rdx-SIZEOF_WORD]
	mov [rdi], cx
	mov [rdi+rdx-SIZEOF_WORD], si
	CLEAN_RET

align 16
.copy_between_5_and_8_bytes:
	mov ecx, [rsi]
	mov esi, [rsi+rdx-SIZEOF_DWORD]
	mov [rdi], ecx
	mov [rdi+rdx-SIZEOF_DWORD], esi
	CLEAN_RET

align 16
.copy_between_9_and_16_bytes:
	mov rcx, [rsi]
	mov rsi, [rsi+rdx-SIZEOF_QWORD]
	mov [rdi], rcx
	mov [rdi+rdx-SIZEOF_QWORD], rsi
	CLEAN_RET

align 16
.copy_between_17_and_32_bytes:
	movdqu xmm3, [rsi]
	movdqu xmm4, [rsi+rdx-SIZEOF_OWORD]
	movdqu [rdi], xmm3
	movdqu [rdi+rdx-SIZEOF_OWORD], xmm4
	CLEAN_RET
