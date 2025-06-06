; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2

global ft_strcmp: function

default rel

%use smartalign
ALIGNMODE p6

%define  BYTE_SIZE    1
%define  WORD_SIZE    2
%define DWORD_SIZE    4
%define QWORD_SIZE    8
%define OWORD_SIZE   16
%define YWORD_SIZE   32
%define  PAGE_SIZE 4096

section .text
; Compares two null-terminated strings.
;
; Parameters
; rdi: S0: the address of the 1st string to compare. (assumed to be a valid address)
; rsi: S1: the address of the 2nd string to compare. (assumed to be a valid address)
;
; Return
; eax:
; - zero if S0 and S1 completely match.
; - a negative value if the first mismatching byte in S0 is less than the first one in S1.
; - a positive value if the first mismatching byte in S0 is greater than the first one in S1.
align 16
ft_strcmp:
%define OLD_RBX [ rsp + QWORD_SIZE * 0 ]
%define OLD_R12 [ rsp + QWORD_SIZE * 1 ]
%define STACK_SIZE      QWORD_SIZE * 2
; reserve space for the local variables
	sub rsp, STACK_SIZE
; preserve the non-volatile registers
	mov OLD_RBX, rbx
	mov OLD_R12, r12
; preliminary initialization
	vpxor ymm0, ymm0, ymm0
; check if both strings are as far from their next 4-ywords boundary as each other
	mov ax, di
	mov dx, si
	and ax, YWORD_SIZE * 4 - 1
	and dx, YWORD_SIZE * 4 - 1
	cmp ax, dx
	je align_S0_and_S1
; calculate the distance from the next page boundary for both S0 and S1
	mov r8w, di
	mov r9w, si
	not r8w
	not r9w
	and r8w, PAGE_SIZE - 1
	and r9w, PAGE_SIZE - 1
	inc r8w
	inc r9w
; check which string is closer to its next page boundary
	cmp r8w, r9w
	jb  align_S0
	jmp align_S1

; Parameters
; %1: the 16-bit register from which to calculate the distance to the next page boundary.
%macro CALCULATE_DISTANCE_FROM_NEXT_PAGE_BOUNDARY 1
%define REG16 %1
; calculate how far the address in REG16 is from its next page boundary
	movzx rbx, REG16
	not bx
	and bx, PAGE_SIZE - 1
	inc bx
%endmacro

; Parameters
; %1: the label to jump to if the given YMM register contains a null byte.
; %2: the YMM register to check.
%macro JUMP_IF_HAS_NULL_BYTE 2
%define LABEL %1
%define YMM   %2
	vpcmpeqb YMM, YMM, ymm0
	vptest YMM, YMM
	jnz LABEL
%endmacro

; Parameters
; %1: the instruction to use to load the yword(s) (assumed to be either vmovdqa or vmovdqu).
; %2: the address to load the yword(s) from.
; %3: the address at which to compare the yword(s).
; %4: the number of ywords to compare. (assumed to be either 1, 2, or 4)
%macro CHECK_AND_COMPARE_NEXT_N_YWORDS 4
%define                   VMOV %1
%define                     S0 %2
%define                     S1 %3
%define            YWORD_COUNT %4
; load the next yword(s) from S0
	VMOV ymm2, [ S0 + YWORD_SIZE * 0 ]
%if YWORD_COUNT > 1
	VMOV ymm4, [ S0 + YWORD_SIZE * 1 ]
%if YWORD_COUNT > 2
	VMOV ymm6, [ S0 + YWORD_SIZE * 2 ]
	VMOV ymm8, [ S0 + YWORD_SIZE * 3 ]
%endif
%endif
; compare them with the next yword(s) of S1
	vpcmpeqb ymm1, ymm2, [ S1 + YWORD_SIZE * 0 ]
%if YWORD_COUNT > 1
	vpcmpeqb ymm3, ymm4, [ S1 + YWORD_SIZE * 1 ]
%if YWORD_COUNT > 2
	vpcmpeqb ymm5, ymm6, [ S1 + YWORD_SIZE * 2 ]
	vpcmpeqb ymm7, ymm8, [ S1 + YWORD_SIZE * 3 ]
%endif
%endif
;                                        ,----ymm1  vpcmpeqb S0[0x00..=0x1F] S1[0x00..=0x1F]
;                          ,----ymm9---AND
;                          |             '----ymm2  S0[0x00..=0x1F]
;           ,----ymm13---MIN
;           |              |             ,----ymm3  vpcmpeqb S0[0x20..=0x3F] S1[0x20..=0x3F]
;           |              '----ymm10--AND
;           |                            '----ymm4  S0[0x20..=0x3F]
; ymm15---MIN
;           |                            ,----ymm5  vpcmpeqb S0[0x40..=0x5F] S1[0x40..=0x5F]
;           |              ,----ymm11--AND
;           |              |             '----ymm6  S0[0x40..=0x5F]
;           '----ymm14---MIN
;                          |             ,----ymm7  vpcmpeqb S0[0x60..=0x7F] S1[0x60..=0x7F]
;                          '----ymm12--AND
;                                        '----ymm8  S0[0x60..=0x7F]
	vpand ymm9,  ymm1, ymm2
%if YWORD_COUNT > 1
	vpand ymm10, ymm3, ymm4
%if YWORD_COUNT > 2
	vpand ymm11, ymm5, ymm6
	vpand ymm12, ymm7, ymm8
%endif
%endif
%if YWORD_COUNT > 1
	vpminub ymm13, ymm9,  ymm10
%if YWORD_COUNT > 2
	vpminub ymm14, ymm11, ymm12
	vpminub ymm15, ymm13, ymm14
%endif
%endif
; check if there is a (mismatching|null) byte
%if YWORD_COUNT == 1
%define LABEL mismatch_or_null.in_00_1F
%define YMM ymm9
%elif YWORD_COUNT == 2
%define LABEL mismatch_or_null.in_00_3F
%define YMM ymm13
%elif YWORD_COUNT == 4
%define LABEL mismatch_or_null.in_00_7F
%define YMM ymm15
%else
%error "Unsupported number of ywords: %4"
%endif
	JUMP_IF_HAS_NULL_BYTE LABEL, YMM
%endmacro

align 16
align_S0_and_S1:
	lea r12, [ .aligned_S0_and_S1_loop ]
	CALCULATE_DISTANCE_FROM_NEXT_PAGE_BOUNDARY di
; check if loading 4 ywords from S(0|1) would cross a page boundary
	sub bx, YWORD_SIZE * 4
	jc page_crossing
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rsi, 4
; align both S0 and S1 to their respective next 4-ywords boundary
	and bx, YWORD_SIZE * 4 - 1
	add rdi, rbx
	add rsi, rbx
align 16
.aligned_S0_and_S1_loop:
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqa, rdi, rsi, 4
; advance to the next 4 ywords
	add rdi, YWORD_SIZE * 4
	add rsi, YWORD_SIZE * 4
; repeat until a (mismatching|null) byte is found
	jmp .aligned_S0_and_S1_loop

align 16
align_S0:
; save the S0 distance from its next page boundary in rbx
	movzx rbx, r8w
; update the jump target for the next page crossing
	lea r12, [ align_S0.loop_prologue ]
; check if loading 4 ywords from S0 would cross a page boundary
	sub bx, YWORD_SIZE * 4
	jc page_crossing
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rsi, 4
; calculate how far S0 is from its next 4-yword boundary
	and bx, YWORD_SIZE * 4 - 1
; advance both S0 and S1 by the calculated distance
	add rdi, rbx
	add rsi, rbx
align 16
.loop_prologue:
	CALCULATE_DISTANCE_FROM_NEXT_PAGE_BOUNDARY si
; update the jump target for the next page crossing
	lea r12, [ align_S1.loop_prologue ]
align 16
.aligned_S0_loop:
; check if loading 4 ywords from S1 would cross a page boundary
	sub bx, YWORD_SIZE * 4
	jc page_crossing
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqa, rdi, rsi, 4
; advance both S0 and S1 to their respective next 4 ywords
	add rdi, YWORD_SIZE * 4
	add rsi, YWORD_SIZE * 4
; repeat until a (mismatching|null) byte is found
	jmp .aligned_S0_loop

align 16
align_S1:
; save the S1 distance from its next page boundary in rbx
	movzx rbx, r9w
; update the jump target for the next page crossing
	lea r12, [ align_S1.loop_prologue ]
; check if loading 4 ywords from S1 would cross a page boundary
	sub bx, YWORD_SIZE * 4
	jc page_crossing
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqu, rsi, rdi, 4
; calculate how far S1 is from its next 4-yword boundary
	and bx, YWORD_SIZE * 4 - 1
; advance both S0 and S1 by the calculated distance
	add rdi, rbx
	add rsi, rbx
align 16
.loop_prologue:
	CALCULATE_DISTANCE_FROM_NEXT_PAGE_BOUNDARY di
; update the jump target for the next page crossing
	lea r12, [ align_S0.loop_prologue ]
align 16
.aligned_S1_loop:
; check if loading 4 ywords from S0 would cross a page boundary
	sub bx, YWORD_SIZE * 4
	jc page_crossing
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqa, rsi, rdi, 4
; advance both S0 and S1 to their respective next 4 ywords
	add rdi, YWORD_SIZE * 4
	add rsi, YWORD_SIZE * 4
; repeat until a (mismatching|null) byte is found
	jmp .aligned_S1_loop

align 16
page_crossing:
	add bx, YWORD_SIZE * 4
	cmp bl, YWORD_SIZE * 2
	ja .use_2x_2_ywords
	cmp bl, YWORD_SIZE
	ja .use_2x_1_yword
	cmp bl, OWORD_SIZE
	ja .use_2x_1_oword
	cmp bl, QWORD_SIZE
	ja .use_2x_1_qword
	cmp bl, DWORD_SIZE
	ja .use_2x_1_dword
	cmp bl, WORD_SIZE
	ja .use_2x_1_word
	cmp bl, BYTE_SIZE
	ja .use_1x_1_word
;use_1x_1_byte:
	movzx eax, byte [ rdi ]
	movzx ecx, byte [ rsi ]
	sub eax, ecx
	jnz return
	test cl, cl
	jz return
	inc rdi
	inc rsi
	jmp r12

align 16
.use_2x_2_ywords:
; check and compare the next 2 ywords of both S0 and S1
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rsi, 2
; advance both S0 and S1 as far as it's safe to load 2 more ywords
	lea rdi, [ rdi + rbx - YWORD_SIZE * 2 ]
	lea rsi, [ rsi + rbx - YWORD_SIZE * 2 ]
; check and compare the next 2 ywords of both S0 and S1
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rsi, 2
; advance to the next unchecked byte
	add rdi, YWORD_SIZE * 2
	add rsi, YWORD_SIZE * 2
; run the main loop
	jmp r12

align 16
.use_2x_1_yword:
; check and compare the next yword of both S0 and S1
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rsi, 1
; advance both S0 and S1 as far as it's safe to load 1 more yword
	lea rdi, [ rdi + rbx - YWORD_SIZE ]
	lea rsi, [ rsi + rbx - YWORD_SIZE ]
; check and compare the next yword of both S0 and S1
	CHECK_AND_COMPARE_NEXT_N_YWORDS vmovdqu, rdi, rsi, 1
; advance to the next unchecked byte
	add rdi, YWORD_SIZE
	add rsi, YWORD_SIZE
; run the main loop
	jmp r12

%macro CHECK_AND_COMPARE_NEXT_OWORD 0
; load the next oword from S0
	vmovdqu xmm2, [ rdi ]
; compare it with the next oword of S1
	vpcmpeqb xmm1, xmm2, [ rsi ]
;          ,----xmm1  vpcmpeqb S0[0x00..=0x0F] S1[0x00..=0x0F]
; xmm9---AND
;          '----xmm2  S0[0x00..=0x0F]
	vpand xmm9, xmm1, xmm2
; check if there is a (mismatching|null) byte
	vpcmpeqb xmm9, xmm9, xmm0
	vptest xmm9, xmm9
	jnz mismatch_or_null.in_00_1F
%endmacro

align 16
.use_2x_1_oword:
; check and compare the next oword of both S0 and S1
	CHECK_AND_COMPARE_NEXT_OWORD
; advance both S0 and S1 as far as it's safe to load 1 more oword
	lea rdi, [ rdi + rbx - OWORD_SIZE ]
	lea rsi, [ rsi + rbx - OWORD_SIZE ]
; check and compare the next oword of both S0 and S1
	CHECK_AND_COMPARE_NEXT_OWORD
; advance to the next unchecked byte
	add rdi, OWORD_SIZE
	add rsi, OWORD_SIZE
; run the main loop
	jmp r12

; Parameters
; %1: the size of 1 chunk. (assumed to be either WORD_SIZE, DWORD_SIZE, or QWORD_SIZE)
%macro CHECK_AND_COMPARE_NEXT_CHUNK 1
%define SIZE %1
%if SIZE == WORD_SIZE
%define      LSB_MASK_REG ax
%define      MSB_MASK_REG cx
%define      MON_MASK_REG dx
%define      S0_CHUNK_REG r8w
%define      S1_CHUNK_REG r9w
%define S0_CHUNK_COPY_REG r10w
%define S1_CHUNK_COPY_REG r11w
%define          LSB_MASK 0x0101
%define          MSB_MASK 0x8080
%elif SIZE == DWORD_SIZE
%define      LSB_MASK_REG eax
%define      MSB_MASK_REG ecx
%define      MON_MASK_REG edx
%define      S0_CHUNK_REG r8d
%define      S1_CHUNK_REG r9d
%define S0_CHUNK_COPY_REG r10d
%define S1_CHUNK_COPY_REG r11d
%define          LSB_MASK 0x01010101
%define          MSB_MASK 0x80808080
%elif SIZE == QWORD_SIZE
%define      LSB_MASK_REG rax
%define      MSB_MASK_REG rcx
%define      MON_MASK_REG rdx
%define      S0_CHUNK_REG r8
%define      S1_CHUNK_REG r9
%define S0_CHUNK_COPY_REG r10
%define S1_CHUNK_COPY_REG r11
%define          LSB_MASK 0x0101010101010101
%define          MSB_MASK 0x8080808080808080
%else
%error "Unsupported chunk size: %1"
%endif
; load the next chunk from both S0 and S1
	mov S0_CHUNK_REG, [ rdi ]
	mov S1_CHUNK_REG, [ rsi ]
; check if there is a (mismatching|null) byte
	mov LSB_MASK_REG, LSB_MASK
	mov MSB_MASK_REG, MSB_MASK
	mov S0_CHUNK_COPY_REG, S0_CHUNK_REG
	mov S1_CHUNK_COPY_REG, S1_CHUNK_REG
	mov MON_MASK_REG, S0_CHUNK_REG
	sub MON_MASK_REG, S1_CHUNK_REG
	sub S0_CHUNK_COPY_REG, LSB_MASK_REG
	sub S1_CHUNK_COPY_REG, LSB_MASK_REG
	not S0_CHUNK_REG
	not S1_CHUNK_REG
	and S0_CHUNK_COPY_REG, S0_CHUNK_REG
	and S1_CHUNK_COPY_REG, S1_CHUNK_REG
	and S0_CHUNK_COPY_REG, MSB_MASK_REG
	and S1_CHUNK_COPY_REG, MSB_MASK_REG
	or MON_MASK_REG, S0_CHUNK_COPY_REG
	or MON_MASK_REG, S1_CHUNK_COPY_REG
	jnz mismatch_or_null.in_rdx
%endmacro

align 16
.use_2x_1_qword:
; check and compare the next qword of both S0 and S1
	CHECK_AND_COMPARE_NEXT_CHUNK QWORD_SIZE
; advance both S0 and S1 as far as it's safe to load 1 more qword
	lea rdi, [ rdi + rbx - QWORD_SIZE ]
	lea rsi, [ rsi + rbx - QWORD_SIZE ]
; check and compare the next qword of both S0 and S1
	CHECK_AND_COMPARE_NEXT_CHUNK QWORD_SIZE
; advance to the next unchecked byte
	add rdi, QWORD_SIZE
	add rsi, QWORD_SIZE
; run the main loop
	jmp r12

align 16
.use_2x_1_dword:
; check and compare the next dword of both S0 and S1
	CHECK_AND_COMPARE_NEXT_CHUNK DWORD_SIZE
; advance both S0 and S1 as far as it's safe to load 1 more dword
	lea rdi, [ rdi + rbx - DWORD_SIZE ]
	lea rsi, [ rsi + rbx - DWORD_SIZE ]
; check and compare the next dword of both S0 and S1
	CHECK_AND_COMPARE_NEXT_CHUNK DWORD_SIZE
; advance to the next unchecked byte
	add rdi, DWORD_SIZE
	add rsi, DWORD_SIZE
; run the main loop
	jmp r12

align 16
.use_2x_1_word:
; check and compare the next word of both S0 and S1
	CHECK_AND_COMPARE_NEXT_CHUNK WORD_SIZE
; advance both S0 and S1 as far as it's safe to load 1 more word
	lea rdi, [ rdi + rbx - WORD_SIZE ]
	lea rsi, [ rsi + rbx - WORD_SIZE ]
align 16
.use_1x_1_word:
; check and compare the next word of both S0 and S1
	CHECK_AND_COMPARE_NEXT_CHUNK WORD_SIZE
; advance to the next unchecked byte
	add rdi, WORD_SIZE
	add rsi, WORD_SIZE
; run the main loop
	jmp r12

%macro RESTORE_STACK_FRAME_AND_RETURN 0
; restore the non-volatile registers
	mov r12, OLD_R12
	mov rbx, OLD_RBX
; restore the stack pointer
	add rsp, STACK_SIZE
	ret
%endmacro

; Parameters
; %1: how far the yword that contains the first (mismatching|null) byte is from S0 and S1.
; %2: the YMM register from which to extract the comparison bitmask.
%macro RETURN_DIFF 2
%define OFFSET  %1
%define YMM     %2
; extract the comparison bitmask
	vpmovmskb rdx, YMM
; clear the upper bits of the YMM registers to avoid performance penalties
	vzeroupper
; calculate the index of the first (mismatching|null) byte
	bsf edx, edx
; load the first (mismatching|null) byte from both S0 and S1
	movzx eax, byte [ rdi + OFFSET + rdx ]
	movzx ecx, byte [ rsi + OFFSET + rdx ]
; calculate and return the difference between the two bytes if any
	sub eax, ecx
	RESTORE_STACK_FRAME_AND_RETURN
%endmacro

mismatch_or_null:
align 16
.in_00_7F:
	JUMP_IF_HAS_NULL_BYTE .in_00_3F, ymm13
;in_40_7F:
	vpcmpeqb ymm12, ymm12, ymm0
	JUMP_IF_HAS_NULL_BYTE .in_40_5F, ymm11
;in_60_7F:
	RETURN_DIFF 0x60, ymm12

align 16
.in_00_3F:
	vpcmpeqb ymm10, ymm10, ymm0
	JUMP_IF_HAS_NULL_BYTE .in_00_1F, ymm9
;in_20_3F:
	RETURN_DIFF 0x20, ymm10

align 16
.in_00_1F:
	RETURN_DIFF 0x00, ymm9

align 16
.in_40_5F:
	RETURN_DIFF 0x40, ymm11

align 16
.in_rdx:
; calculate the index of the first (mismatching|null) byte
	bsf rdx, rdx
	shr rdx, 3 ; divide by 8
; load the first (mismatching|null) byte from both S0 and S1
	movzx eax, byte [ rdi + rdx ]
	movzx ecx, byte [ rsi + rdx ]
; calculate the difference between the two bytes if any
	sub eax, ecx
align 16
return:
	RESTORE_STACK_FRAME_AND_RETURN
