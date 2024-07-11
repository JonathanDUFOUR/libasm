global ft_strcpy: function

%use smartalign
ALIGNMODE p6

%define SIZEOF_YWORD 32

; Parameters:
; %1: the label to jump to if the given YMM register contains at least 1 null byte.
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
ft_strcpy:
; preliminary initialization
	mov rax, rdi
	vpxor ymm0, ymm0, ymm0
; load the first yword from the soure string
	vmovdqu ymm1, [rsi]
; check if the first yword contains a null byte
	vpcmpeqb ymm2, ymm0, ymm1
	vpmovmskb rdx, ymm2
; calculate the index of the first null byte in the first yword if any
; REMIND: this is for little-endian. Use bsr instead of bsf for big-endian.
	bsf edx, edx
	jnz .copy_between_1_and_32_bytes
; store the first yword to the destination string
	vmovdqu [rdi], ymm1
; calculate how har the destination pointer is to its next yword boundary
	lea rcx, [rdi + SIZEOF_YWORD]
	and rcx, -SIZEOF_YWORD
	sub rcx, rdi
; advance both the destination pointer and the source pointer by the calculated distance
	add rdi, rcx
	add rsi, rcx
align 16
.check_the_next_8_ywords:
; load the next 8 ywords from the source string
	vmovdqu ymm1, [rsi+0x00]
	vmovdqu ymm2, [rsi+0x20]
	vmovdqu ymm3, [rsi+0x40]
	vmovdqu ymm4, [rsi+0x60]
	vmovdqu ymm5, [rsi+0x80]
	vmovdqu ymm6, [rsi+0xA0]
	vmovdqu ymm7, [rsi+0xC0]
	vmovdqu ymm8, [rsi+0xE0]
; keep the 32 bytes with the minimum values from all the next 8 ywords of the source string
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

; check if the resulting 32 bytes contain a null byte
	JUMP_IF_HAS_A_NULL_BYTE .copy_the_last_ywords_up_to_8, ymm15
; store the next 8 ywords to the destination string
	vmovdqa [rdi+0x00], ymm1
	vmovdqa [rdi+0x20], ymm2
	vmovdqa [rdi+0x40], ymm3
	vmovdqa [rdi+0x60], ymm4
	vmovdqa [rdi+0x80], ymm5
	vmovdqa [rdi+0xA0], ymm6
	vmovdqa [rdi+0xC0], ymm7
	vmovdqa [rdi+0xE0], ymm8
; update the pointers
	add rdi, 8 * SIZEOF_YWORD
	add rsi, 8 * SIZEOF_YWORD
; repeat until the next 8 ywords contain a null byte
	jmp .check_the_next_8_ywords

align 16
.copy_the_last_ywords_up_to_8:
	JUMP_IF_HAS_A_NULL_BYTE .copy_the_last_ywords_up_to_4, ymm13
; copy the next 128 bytes
	vmovdqa [rdi+0x00], ymm1
	vmovdqa [rdi+0x20], ymm2
	vmovdqa [rdi+0x40], ymm3
	vmovdqa [rdi+0x60], ymm4
	JUMP_IF_HAS_A_NULL_BYTE .copy_the_last_ywords_up_to_6, ymm11
; copy the next 64 bytes
	vmovdqa [rdi+0x80], ymm5
	vmovdqa [rdi+0xA0], ymm6
	JUMP_IF_HAS_A_NULL_BYTE .copy_the_last_ywords_up_to_7, ymm7
; copy the next 32 bytes
	vmovdqa [rdi+0xC0], ymm7
	COPY_THE_LAST_BYTES_UP_TO_32 7, ymm8

align 16
.copy_the_last_ywords_up_to_7:
	COPY_THE_LAST_BYTES_UP_TO_32 6, ymm7

align 16
.copy_the_last_ywords_up_to_6:
	JUMP_IF_HAS_A_NULL_BYTE .copy_the_last_ywords_up_to_5, ymm5
; copy the next 32 bytes
	vmovdqa [rdi+0x80], ymm5
	COPY_THE_LAST_BYTES_UP_TO_32 5, ymm6

align 16
.copy_the_last_ywords_up_to_5:
	COPY_THE_LAST_BYTES_UP_TO_32 4, ymm5

align 16
.copy_the_last_ywords_up_to_4:
	JUMP_IF_HAS_A_NULL_BYTE .copy_the_last_ywords_up_to_2, ymm9
; copy the next 64 bytes
	vmovdqa [rdi+0x00], ymm1
	vmovdqa [rdi+0x20], ymm2
	JUMP_IF_HAS_A_NULL_BYTE .copy_the_last_ywords_up_to_3, ymm3
; copy the next 32 bytes
	vmovdqa [rdi+0x40], ymm3
	COPY_THE_LAST_BYTES_UP_TO_32 3, ymm4

align 16
.copy_the_last_ywords_up_to_3:
	COPY_THE_LAST_BYTES_UP_TO_32 2, ymm3

align 16
.copy_the_last_ywords_up_to_2:
	JUMP_IF_HAS_A_NULL_BYTE .copy_the_last_ywords_up_to_1, ymm1
; copy the next 32 bytes
	vmovdqa [rdi+0x00], ymm1
	COPY_THE_LAST_BYTES_UP_TO_32 1, ymm2

align 16
.copy_the_last_ywords_up_to_1:
	COPY_THE_LAST_BYTES_UP_TO_32 0, ymm1

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
	mov sil, [rsi+rdx-1]
	mov [rdi], cl
	mov [rdi+rdx-1], sil
	ret

align 16
.copy_between_3_and_4_bytes:
	mov cx, [rsi]
	mov si, [rsi+rdx-2]
	mov [rdi], cx
	mov [rdi+rdx-2], si
	ret

align 16
.copy_between_5_and_8_bytes:
	mov ecx, [rsi]
	mov esi, [rsi+rdx-4]
	mov [rdi], ecx
	mov [rdi+rdx-4], esi
	ret

align 16
.copy_between_9_and_16_bytes:
	mov rcx, [rsi]
	mov rsi, [rsi+rdx-8]
	mov [rdi], rcx
	mov [rdi+rdx-8], rsi
	ret

align 16
.copy_between_17_and_32_bytes:
	movdqu xmm3, [rsi]
	movdqu xmm4, [rsi+rdx-16]
	movdqu [rdi], xmm3
	movdqu [rdi+rdx-16], xmm4
	ret
