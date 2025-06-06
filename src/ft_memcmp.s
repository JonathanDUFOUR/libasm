; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2, BMI1, MOVBE

global ft_memcmp: function

%use smartalign
ALIGNMODE p6

%define  BYTE_SIZE  1
%define  WORD_SIZE  2
%define DWORD_SIZE  4
%define QWORD_SIZE  8
%define OWORD_SIZE 16
%define YWORD_SIZE 32

%define  BYTE_BITS  BYTE_SIZE * 8
%define  WORD_BITS  WORD_SIZE * 8
%define DWORD_BITS DWORD_SIZE * 8

%macro VZEROUPPER_RET 0
	vzeroupper
	ret
%endmacro

; Parameters
; %1: the instruction to use to load the yword(s). (assumed to be either vmovdqa or vmovdqu)
; %2: the address of the 1st yword array to compare.
; %3: the address of the 2nd yword array to compare.
; %4: the number of ywords to compare. (assumed to be either 1, 2, 4, or 8)
; %5: the label to jump to if there is a mismatch.
%macro COMPARE_NEXT_N_YWORDS 5
%define           VMOV %1
%define             S0 %2
%define             S1 %3
%define    YWORD_COUNT %4
%define MISMATCH_LABEL %5
; load the next yword(s) from S0
	VMOV ymm0, [ S0 + YWORD_SIZE * 0 ]
%if YWORD_COUNT > 1
	VMOV ymm1, [ S0 + YWORD_SIZE * 1 ]
%if YWORD_COUNT > 2
	VMOV ymm2, [ S0 + YWORD_SIZE * 2 ]
	VMOV ymm3, [ S0 + YWORD_SIZE * 3 ]
%if YWORD_COUNT > 4
	VMOV ymm4, [ S0 + YWORD_SIZE * 4 ]
	VMOV ymm5, [ S0 + YWORD_SIZE * 5 ]
	VMOV ymm6, [ S0 + YWORD_SIZE * 6 ]
	VMOV ymm7, [ S0 + YWORD_SIZE * 7 ]
%endif
%endif
%endif
; compare them with the next yword(s) of S1
	vpcmpeqb ymm0, ymm0, [ S1 + YWORD_SIZE * 0 ]
%if YWORD_COUNT > 1
	vpcmpeqb ymm1, ymm1, [ S1 + YWORD_SIZE * 1 ]
%if YWORD_COUNT > 2
	vpcmpeqb ymm2, ymm2, [ S1 + YWORD_SIZE * 2 ]
	vpcmpeqb ymm3, ymm3, [ S1 + YWORD_SIZE * 3 ]
%if YWORD_COUNT > 4
	vpcmpeqb ymm4, ymm4, [ S1 + YWORD_SIZE * 4 ]
	vpcmpeqb ymm5, ymm5, [ S1 + YWORD_SIZE * 5 ]
	vpcmpeqb ymm6, ymm6, [ S1 + YWORD_SIZE * 6 ]
	vpcmpeqb ymm7, ymm7, [ S1 + YWORD_SIZE * 7 ]
%endif
%endif
%endif
;                      ,-----ymm0  vpcmpeqb S0[0x00..=0x1F] S1[0x00..=0x1F]
;              ,----ymm8
;              |       '-----ymm1  vpcmpeqb S0[0x20..=0x3F] S1[0x20..=0x3F]
;     ,----ymm12
;     |        |       ,-----ymm2  vpcmpeqb S0[0x40..=0x5F] S1[0x40..=0x5F]
;     |        '----ymm9
;     |                '-----ymm3  vpcmpeqb S0[0x60..=0x7F] S1[0x60..=0x7F]
; ymm14
;     |                 ,----ymm4  vpcmpeqb S0[0x80..=0x9F] S1[0x80..=0x9F]
;     |        ,----ymm10
;     |        |        '----ymm5  vpcmpeqb S0[0xA0..=0xBF] S1[0xA0..=0xBF]
;     '----ymm13
;              |        ,----ymm6  vpcmpeqb S0[0xC0..=0xDF] S1[0xC0..=0xDF]
;              '----ymm11
;                       '----ymm7  vpcmpeqb S0[0xE0..=0xFF] S1[0xE0..=0xFF]
%if YWORD_COUNT > 1
	vpand ymm8,  ymm0,  ymm1
%if YWORD_COUNT > 2
	vpand ymm9,  ymm2,  ymm3
%if YWORD_COUNT > 4
	vpand ymm10, ymm4,  ymm5
	vpand ymm11, ymm6,  ymm7
%endif
	vpand ymm12, ymm8,  ymm9
%if YWORD_COUNT > 4
	vpand ymm13, ymm10, ymm11
	vpand ymm14, ymm12, ymm13
%endif
%endif
%endif
; check if there is a mismatch
%if YWORD_COUNT == 8
%define REG r8d
%define YMM ymm14
%elif YWORD_COUNT == 4
%define REG r9d
%define YMM ymm12
%elif YWORD_COUNT == 2
%define REG r10d
%define YMM ymm8
%elif YWORD_COUNT == 1
%define REG eax
%define YMM ymm0
%endif
	vpmovmskb REG, YMM
	inc REG
	jnz MISMATCH_LABEL
%endmacro

; Parameters
; %1: the number of ywords to compare 2 times. (assumed to either 1, 2, 4, or 8)
%macro USE_2x_N_YWORDS 1
%define YWORD_COUNT %1
%if   YWORD_COUNT == 8
%define MISMATCH_LABEL mismatch.in_00_FF
%elif YWORD_COUNT == 4
%define MISMATCH_LABEL mismatch.in_00_7F
%elif YWORD_COUNT == 2
%define MISMATCH_LABEL mismatch.in_00_3F
%elif YWORD_COUNT == 1
%define MISMATCH_LABEL mismatch.in_00_1F
%endif
	COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rsi, YWORD_COUNT, MISMATCH_LABEL
; advance both S0 and S1 to their last YWORD_COUNT yword(s)
	lea rdi, [ rdi + rdx - YWORD_SIZE * YWORD_COUNT ]
	lea rsi, [ rsi + rdx - YWORD_SIZE * YWORD_COUNT ]
	COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rsi, YWORD_COUNT, MISMATCH_LABEL
%if YWORD_COUNT != 1
	xor eax, eax
%endif
	VZEROUPPER_RET
%endmacro

%macro COMPARE_NEXT_OWORD 0
; load the next oword from S0
	vmovdqu xmm15, [ rdi ]
; compare it with the next oword of S1
	vpcmpeqb xmm15, xmm15, [ rsi ]
; check if there is a mismatch
	vpmovmskb eax, xmm15
	inc ax
	jnz mismatch.in_00_1F
%endmacro

; Parameters
; %1: how far the yword that contains the first mismatching byte is from S0 and S1.
; %2: the register in which the comparison bitmask is.
%macro RETURN_DIFF 2
%define  OFFSET %1
%define BITMASK %2
; calculate the index of the first mismatching byte
	tzcnt r11d, BITMASK
; load the first mismatching byte from both S0 and S1
	movzx eax, byte [ rdi + OFFSET + r11 ]
	movzx ecx, byte [ rsi + OFFSET + r11 ]
; return the difference between the two bytes
	sub eax, ecx
	VZEROUPPER_RET
%endmacro

section .text
; Compares two memory area.
;
; Parameters
; rdi: S0: the address of the 1st memory area to compare. (assumed to be a valid address)
; rsi: S1: the address of the 2nd memory area to compare. (assumed to be a valid address)
; rdx:  N: the number of bytes to compare.
;
; Return
; eax:
; - zero if the first N bytes of S0 match the first N bytes of S1.
; - a negative value if the first mismatching byte among the first N bytes of S0
;   is less than the first one among the first N bytes of S1.
; - a positive value if the first mismatching byte among the N first bytes of S0
;   is greater than the first one among the first N bytes of S1.
align 16
ft_memcmp:
	cmp rdx, YWORD_SIZE * 16
	ja .compare_more_than_16_ywords
	cmp dx, YWORD_SIZE * 8
	ja .use_2x_8_ywords
	cmp dl, YWORD_SIZE * 4
	ja .use_2x_4_ywords
	cmp dl, YWORD_SIZE * 2
	ja .use_2x_2_ywords
	cmp dl, YWORD_SIZE * 1
	ja .use_2x_1_yword
	cmp dl, OWORD_SIZE * 1
	ja .use_2x_1_oword
	cmp dl, QWORD_SIZE * 1
	ja .use_2x_1_qword
	cmp dl, DWORD_SIZE * 1
	ja .use_2x_1_dword
	cmp dl, WORD_SIZE * 1
	ja .use_2x_1_word
	cmp dl, BYTE_SIZE * 1
	ja .use_2x_1_byte
	je .use_1x_1_byte
	xor eax, eax
	ret

align 16
.compare_more_than_16_ywords:
	COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rsi, 1, mismatch.in_00_FF
; set rdx to the last 8 ywords of S0
	lea rdx, [ rdi + rdx - YWORD_SIZE * 8 ]
; calculate the offset between S0 and S1
	sub rsi, rdi
; align S0 to its next yword boundary
	and rdi, -YWORD_SIZE
	add rdi,  YWORD_SIZE
align 16
.compare_next_8_ywords:
	COMPARE_NEXT_N_YWORDS vmovdqa, rdi, rdi + rsi, 8, mismatch
; advance S0 to its next 8 ywords
	add rdi, YWORD_SIZE * 8
; check if S0 reached its last 8 ywords
	cmp rdi, rdx
; repeat until either there is mismatch or S0 reaches its last 8 ywords
	jb .compare_next_8_ywords
; set S0 to its last 8 ywords
	mov rdi, rdx
	COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rdi + rsi, 8, mismatch
	VZEROUPPER_RET

align 16
.use_2x_8_ywords:
	USE_2x_N_YWORDS 8

align 16
.use_2x_4_ywords:
	USE_2x_N_YWORDS 4

align 16
.use_2x_2_ywords:
	USE_2x_N_YWORDS 2

align 16
.use_2x_1_yword:
	USE_2x_N_YWORDS 1

align 16
.use_2x_1_oword:
	COMPARE_NEXT_OWORD
; advance both pointers to their last oword
	lea rdi, [ rdi + rdx - OWORD_SIZE ]
	lea rsi, [ rsi + rdx - OWORD_SIZE ]
	COMPARE_NEXT_OWORD
	ret

align 16
.use_2x_1_qword:
; load the first qword from both S0 and S1 in big-endian
	movbe rax, [ rdi ]
	movbe rcx, [ rsi ]
; calculate the difference between the two qwords if any
	sub rax, rcx
	jnz mismatch.in_rax
; load the last qword from both S0 and S1
	movbe rax, [ rdi + rdx - QWORD_SIZE ]
	movbe rcx, [ rsi + rdx - QWORD_SIZE ]
; calculate the difference between the two qwords if any
	sub rax, rcx
	jnz mismatch.in_rax
	ret

align 16
.use_2x_1_dword:
; load the first and last dwords from both S0 and S1 in big-endian
	movbe eax, [ rdi ]
	movbe ecx, [ rsi ]
	movbe r8d, [ rdi + rdx - DWORD_SIZE ]
	movbe r9d, [ rsi + rdx - DWORD_SIZE ]
; concatenate each pair of dwords into a single qword
	shl rax, DWORD_BITS
	shl rcx, DWORD_BITS
	or eax, r8d
	or ecx, r9d
; calculate the difference between the two qwords if any
	sub rax, rcx
	jnz mismatch.in_rax
	ret

align 16
.use_2x_1_word:
; load the first and last words from both S0 and S1 in big-endian
	movbe ax, [ rdi ]
	movbe cx, [ rsi ]
	movbe r8w, [ rdi + rdx - WORD_SIZE ]
	movbe r9w, [ rsi + rdx - WORD_SIZE ]
; concatenate each pair of words into a single dword
	shl eax, WORD_BITS
	shl ecx, WORD_BITS
	mov ax, r8w
	mov cx, r9w
; calculate the difference between the two dwords if any
	sub eax, ecx
	ret

align 16
.use_2x_1_byte:
; load the first and last bytes from both S0 and S1
	movzx eax, byte [ rdi ]
	movzx ecx, byte [ rsi ]
	mov r8b, [ rdi + rdx - BYTE_SIZE ]
	mov r9b, [ rsi + rdx - BYTE_SIZE ]
; concatenate each pair of bytes into a single word
	shl ax, BYTE_BITS
	shl cx, BYTE_BITS
	mov al, r8b
	mov cl, r9b
; calculate the difference between the two bytes if any
	sub eax, ecx
	ret

align 16
.use_1x_1_byte:
; load the first byte from S0
	movzx eax, byte [ rdi ]
	movzx ecx, byte [ rsi ]
; calculate the difference between the two bytes if any
	sub eax, ecx
	ret

align 16
mismatch:
; restore the S1 pointer
	add rsi, rdi
align 16
.in_00_FF:
	vpmovmskb r9d, ymm12
	inc r9d
	jnz .in_00_7F
;in_80_FF:
	vpmovmskb r10d, ymm10
	inc r10d
	jnz .in_80_BF
;in_C0_FF:
	vpmovmskb eax, ymm6
	inc eax
	jnz .in_C0_DF
;in_E0_FF:
	RETURN_DIFF 0xE0, r8d

align 16
.in_00_7F:
	vpmovmskb r10d, ymm8
	inc r10d
	jnz .in_00_3F
;in_40_7F:
	vpmovmskb eax, ymm2
	inc eax
	jnz .in_40_5F
;in_60_7F:
	RETURN_DIFF 0x60, r9d

align 16
.in_00_3F:
	vpmovmskb eax, ymm0
	inc eax
	jnz .in_00_1F
;in_20_3F:
	RETURN_DIFF 0x20, r10d

align 16
.in_00_1F:
	RETURN_DIFF 0x00, eax

align 16
.in_40_5F:
	RETURN_DIFF 0x40, eax

align 16
.in_80_BF:
	vpmovmskb eax, ymm4
	inc eax
	jnz .in_80_9F
;in_A0_BF:
	RETURN_DIFF 0xA0, r10d

align 16
.in_80_9F:
	RETURN_DIFF 0x80, eax

align 16
.in_C0_DF:
	RETURN_DIFF 0xC0, eax

align 16
.in_rax:
	sbb eax, eax
	or eax, 1
	ret
