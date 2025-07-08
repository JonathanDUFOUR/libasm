; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2, MOVBE

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

%define  YMM_00_1F ymm0
%define  YMM_20_3F ymm1
%define  YMM_40_5F ymm2
%define  YMM_60_7F ymm3
%define  YMM_80_9F ymm4
%define  YMM_A0_BF ymm5
%define  YMM_C0_DF ymm6
%define  YMM_E0_FF ymm7
%define MASK_00_1F ymm8
%define MASK_20_3F ymm9
%define MASK_40_5F ymm10
%define MASK_60_7F ymm11
%define MASK_80_9F ymm12
%define MASK_A0_BF ymm13
%define MASK_C0_DF ymm14
%define MASK_E0_FF ymm15
%define MASK_00_3F ymm0
%define MASK_40_7F ymm1
%define MASK_80_BF ymm2
%define MASK_C0_FF ymm3
%define MASK_00_7F ymm4
%define MASK_80_FF ymm5
%define MASK_00_FF ymm6

%define GPR_00_FF r8d
%define GPR_00_7F r9d
%define GPR_00_3F r10d
%define GPR_80_BF r10d
%define GPR_00_1F eax
%define GPR_40_5F eax
%define GPR_80_9F eax
%define GPR_C0_DF eax

; Parameters
; %1: the instruction to use to load the yword(s). (assumed to be either vmovdqa or vmovdqu)
; %2: the address of the 1st yword array to compare.
; %3: the address of the 2nd yword array to compare.
; %4: the number of ywords to compare. (assumed to be either 1, 2, 4, or 8)
; %5: the label to jump to if there is a mismatch.
%macro COMPARE_NEXT_N_YWORDS 5
%define         VMOVDQ %1
%define             S0 %2
%define             S1 %3
%define    YWORD_COUNT %4
%define MISMATCH_LABEL %5
;                                                                     ┌──YMM_00_1F──[S0_00_1F]
;                                                 ┌──MASK_00_1F──CMPEQB
;                                                 │                   └─────────────[S1_00_1F]
;                                ┌──MASK_00_3F──AND
;                                │                │                   ┌──YMM_20_3F──[S0_20_3F]
;                                │                └──MASK_20_3F──CMPEQB
;                                │                                    └─────────────[S1_20_3F]
;               ┌──MASK_00_7F──AND
;               │                │                                    ┌──YMM_40_5F──[S0_40_5F]
;               │                │                ┌──MASK_40_5F──CMPEQB
;               │                │                │                   └─────────────[S1_40_5F]
;               │                └──MASK_40_7F──AND
;               │                                 │                   ┌──YMM_60_7F──[S0_60_7F]
;               │                                 └──MASK_60_7F──CMPEQB
;               │                                                     └─────────────[S1_60_7F]
; MASK_00_FF──AND
;               │                                                     ┌──YMM_80_9F──[S0_80_9F]
;               │                                 ┌──MASK_80_9F──CMPEQB
;               │                                 │                   └─────────────[S1_80_9F]
;               │                ┌──MASK_80_BF──AND
;               │                │                │                   ┌──YMM_A0_BF──[S0_A0_BF]
;               │                │                └──MASK_A0_BF──CMPEQB   
;               │                │                                    └─────────────[S1_A0_BF]
;               └──MASK_80_FF──AND
;                                │                                    ┌──YMM_C0_DF──[S0_C0_DF]
;                                │                ┌──MASK_C0_DF──CMPEQB
;                                │                │                   └─────────────[S1_C0_DF]
;                                └──MASK_C0_FF──AND
;                                                 │                   ┌──YMM_E0_FF──[S0_E0_FF]
;                                                 └──MASK_E0_FF──CMPEQB
;                                                                     └─────────────[S1_E0_FF]
	VMOVDQ YMM_00_1F, [ S0 + YWORD_SIZE * 0 ]
%if YWORD_COUNT > 1
	VMOVDQ YMM_20_3F, [ S0 + YWORD_SIZE * 1 ]
%if YWORD_COUNT > 2
	VMOVDQ YMM_40_5F, [ S0 + YWORD_SIZE * 2 ]
	VMOVDQ YMM_60_7F, [ S0 + YWORD_SIZE * 3 ]
%if YWORD_COUNT > 4
	VMOVDQ YMM_80_9F, [ S0 + YWORD_SIZE * 4 ]
	VMOVDQ YMM_A0_BF, [ S0 + YWORD_SIZE * 5 ]
	VMOVDQ YMM_C0_DF, [ S0 + YWORD_SIZE * 6 ]
	VMOVDQ YMM_E0_FF, [ S0 + YWORD_SIZE * 7 ]
%endif
%endif
%endif
	vpcmpeqb MASK_00_1F, YMM_00_1F, [ S1 + YWORD_SIZE * 0 ]
%if YWORD_COUNT > 1
	vpcmpeqb MASK_20_3F, YMM_20_3F, [ S1 + YWORD_SIZE * 1 ]
%if YWORD_COUNT > 2
	vpcmpeqb MASK_40_5F, YMM_40_5F, [ S1 + YWORD_SIZE * 2 ]
	vpcmpeqb MASK_60_7F, YMM_60_7F, [ S1 + YWORD_SIZE * 3 ]
%if YWORD_COUNT > 4
	vpcmpeqb MASK_80_9F, YMM_80_9F, [ S1 + YWORD_SIZE * 4 ]
	vpcmpeqb MASK_A0_BF, YMM_A0_BF, [ S1 + YWORD_SIZE * 5 ]
	vpcmpeqb MASK_C0_DF, YMM_C0_DF, [ S1 + YWORD_SIZE * 6 ]
	vpcmpeqb MASK_E0_FF, YMM_E0_FF, [ S1 + YWORD_SIZE * 7 ]
%endif
%endif
%endif
%if YWORD_COUNT > 1
	vpand MASK_00_3F, MASK_00_1F, MASK_20_3F
%if YWORD_COUNT > 2
	vpand MASK_40_7F, MASK_40_5F, MASK_60_7F
%if YWORD_COUNT > 4
	vpand MASK_80_BF, MASK_80_9F, MASK_A0_BF
	vpand MASK_C0_FF, MASK_C0_DF, MASK_E0_FF
%endif
	vpand MASK_00_7F, MASK_00_3F, MASK_40_7F
%if YWORD_COUNT > 4
	vpand MASK_80_FF, MASK_80_BF, MASK_C0_FF
	vpand MASK_00_FF, MASK_00_7F, MASK_80_FF
%endif
%endif
%endif
; check if there is a mismatch
%if YWORD_COUNT == 8
%define  GPR  GPR_00_FF
%define MASK MASK_00_FF
%elif YWORD_COUNT == 4
%define  GPR  GPR_00_7F
%define MASK MASK_00_7F
%elif YWORD_COUNT == 2
%define  GPR  GPR_00_3F
%define MASK MASK_00_3F
%elif YWORD_COUNT == 1
%define  GPR  GPR_00_1F
%define MASK MASK_00_1F
%endif
	vpmovmskb GPR, MASK
	inc GPR
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
; clear the upper bits of the YMM registers to avoid performance penalties
	vzeroupper
	ret
%endmacro

%macro COMPARE_NEXT_OWORD 0
; load the next oword from S0
	vmovdqu xmm0, [ rdi ]
; compare it with the next oword of S1
	vpcmpeqb xmm1, xmm0, [ rsi ]
; check if there is a mismatch
	vpmovmskb eax, xmm1
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
	bsf r11d, BITMASK
; load the first mismatching byte from both S0 and S1
	movzx eax, byte [ rdi + OFFSET + r11 ]
	movzx ecx, byte [ rsi + OFFSET + r11 ]
; return the difference between the two bytes
	sub eax, ecx
; clear the upper bits of the YMM registers to avoid performance penalties
	vzeroupper
	ret
%endmacro

section .text align=16
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
ft_memcmp:
	cmp rdx, YWORD_SIZE * 16
	ja .compare_more_than_16_ywords
	cmp edx, YWORD_SIZE * 8
	ja .use_2x_8_ywords
	cmp edx, YWORD_SIZE * 4
	ja .use_2x_4_ywords
	cmp edx, YWORD_SIZE * 2
	ja .use_2x_2_ywords
	cmp edx, YWORD_SIZE * 1
	ja .use_2x_1_yword
	cmp edx, OWORD_SIZE * 1
	ja .use_2x_1_oword
	cmp edx, QWORD_SIZE * 1
	ja .use_2x_1_qword
	cmp edx, DWORD_SIZE * 1
	ja .use_2x_1_dword
	cmp edx, WORD_SIZE * 1
	ja .use_2x_1_word
	cmp edx, BYTE_SIZE * 1
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
; clear the upper bits of the YMM registers to avoid performance penalties
	vzeroupper
	ret

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
	vpmovmskb GPR_00_7F, MASK_00_7F
	inc GPR_00_7F
	jnz .in_00_7F
;in_80_FF:
	vpmovmskb GPR_80_BF, MASK_80_BF
	inc GPR_80_BF
	jnz .in_80_BF
;in_C0_FF:
	vpmovmskb GPR_C0_DF, MASK_C0_DF
	inc GPR_C0_DF
	jnz .in_C0_DF
;in_E0_FF:
	RETURN_DIFF 0xE0, GPR_00_FF

align 16
.in_00_7F:
	vpmovmskb GPR_00_3F, MASK_00_3F
	inc GPR_00_3F
	jnz .in_00_3F
;in_40_7F:
	vpmovmskb GPR_40_5F, MASK_40_5F
	inc GPR_40_5F
	jnz .in_40_5F
;in_60_7F:
	RETURN_DIFF 0x60, GPR_00_7F

align 16
.in_00_3F:
	vpmovmskb GPR_00_1F, MASK_00_1F
	inc GPR_00_1F
	jnz .in_00_1F
;in_20_3F:
	RETURN_DIFF 0x20, GPR_00_3F

align 16
.in_00_1F:
	RETURN_DIFF 0x00, GPR_00_1F

align 16
.in_40_5F:
	RETURN_DIFF 0x40, GPR_40_5F

align 16
.in_80_BF:
	vpmovmskb GPR_80_9F, MASK_80_9F
	inc GPR_80_9F
	jnz .in_80_9F
;in_A0_BF:
	RETURN_DIFF 0xA0, GPR_80_BF

align 16
.in_80_9F:
	RETURN_DIFF 0x80, GPR_80_9F

align 16
.in_C0_DF:
	RETURN_DIFF 0xC0, GPR_C0_DF

align 16
.in_rax:
	sbb eax, eax
	or eax, 1
	ret
