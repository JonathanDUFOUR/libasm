; Architecture: x86-64
; Endianness: little-endian
; CPUID feature flags: AVX2

global ft_strcmp: function

default rel

%use smartalign
ALIGNMODE p6

%define  WORD_SIZE    2
%define DWORD_SIZE    4
%define QWORD_SIZE    8
%define OWORD_SIZE   16
%define YWORD_SIZE   32
%define  PAGE_SIZE 4096

; Parameters
; %1: S0: the address of the 1st string to compare. (assumed to be a valid address)
; %2: S1: the address of the 2nd string to compare. (assumed to be a valid address)
; %3: the instruction to use to load the yword from S0. (assumed to be either vmovdqa or vmovdqu)
;
; Optionnal parameters
; %4: the offset to apply before loading the next yword from both S0 and S1.
%macro CHECK_AND_COMPARE_YWORD 3-4
%define     S0 %1
%define     S1 %2
%define VMOVDQ %3
%if %0 > 3
%define OFFSET %4
%else
%define OFFSET 0
%endif
;         ┌─────────────┬──ymm1──(S0+OFFSET)[..YWORD_SIZE]
; ymm4──AND             │
;         └──ymm3──CMPEQB────────(S1+OFFSET)[..YWORD_SIZE]
	VMOVDQ ymm1, [ S0 + OFFSET ]
	vpcmpeqb ymm3, ymm1, [ S1 + OFFSET ]
	vpand ymm4, ymm3, ymm1
; check if there is a (mismatching|null) byte
	vpcmpeqb ymm6, ymm4, ymm0
	vptest ymm6, ymm6
%endmacro

; Parameters
; %1: the index of the yword in which the first (mismatching|null) byte is located. (starts from 0)
%macro MISMATCH_OR_NULL_IN_NTH_YWORD 1
%define N %1
; extract bitmask of the (mismatching|null) bytes
	vpmovmskb ecx, ymm6
; calculate the index of the first (mismatching|null) byte
	bsf ecx, ecx
; load the first (mismatching|null) byte from both S0 and S1
	movzx eax, byte [ rdi + rcx + YWORD_SIZE * N ]
	movzx ecx, byte [ rsi + rcx + YWORD_SIZE * N ]
; calculate the possible difference between them
	sub eax, ecx
; take into account the possible inversion
	xor eax, r8d
	sub eax, r8d
; clear the upper bits of the YMM registers to avoid performance penalties
	vzeroupper
	ret
%endmacro

; Parameters
; %1: the instruction to use to load the oword. (assumed to be either vmovdqa or vmovdqu)
;
; Optionnal parameters
; %2: the offset to apply before loading the next oword from both S0 and S1.
%macro CHECK_AND_COMPARE_OWORD 1-2
%define VMOVDQ %1
%if %0 == 1
%define OFFSET 0
%else
%define OFFSET %2
%endif
;         ┌─────────────┬──xmm1──(S0+OFFSET)[..OWORD_SIZE]
; xmm4──AND             │
;         └──xmm3──CMPEQB────────(S1+OFFSET)[..OWORD_SIZE]
	VMOVDQ xmm1, [ rdi + OFFSET ]
	vpcmpeqb xmm3, xmm1, [ rsi + OFFSET ]
	vpand xmm4, xmm3, xmm1
; check if there is a (mismatching|null) byte
	vpcmpeqb xmm6, xmm4, xmm0
	vptest xmm6, xmm6
	jnz mismatch_or_null_mask_in_ymm6
%endmacro

; Parameters
; %1: the instruction to use to load the chunks. (assumed to be either vmovd or vmovq)
;
; Optionnal parameters
; %2: the offset to apply before loading the next chunks.
%macro CHECK_AND_COMPARE_CHUNK 1-2
%define VMOV %1
%if %0 == 1
%define OFFSET 0
%else
%define OFFSET %2
%endif
;         ┌─────────────┬──xmm1──(S0+OFFSET)[..CHUNK_SIZE]
; xmm4──AND             │
;         └──xmm3──CMPEQB──xmm2──(S1+OFFSET)[..CHUNK_SIZE]
	VMOV xmm1, [ rdi + OFFSET ]
	VMOV xmm2, [ rsi + OFFSET ]
	vpcmpeqb xmm3, xmm1, xmm2
	vpand xmm4, xmm1, xmm3
; check if there is a (mismatching|null) byte
	vpcmpeqb xmm6, xmm4, xmm5
	vptest xmm6, xmm6
	jnz mismatch_or_null_mask_in_ymm6
%endmacro

; TODO: check for a more efficient way using AVX2
; Optional parameters
; %1: the offset to apply before loading the next word from both S0 and S1.
%macro CHECK_AND_COMPARE_WORD 0-1
%if %0 > 0
%define OFFSET %1
%else
%define OFFSET 0
%endif
; load the next word from both S0 and S1
	movzx ecx, word [ rdi + OFFSET ]
	movzx r9d, word [ rsi + OFFSET ]
; check if there is a (mismatching|null) byte
	mov r10d, ecx
	mov r11d, r9d
	sub r10d, 0x0101
	sub r11d, 0x0101
	not ecx
	not r9d
	and r10d, ecx
	and r11d, r9d
	and r10d, 0x8080
	and r11d, 0x8080
	or r10d, r11d
	not ecx
	not r9d
	sub ecx, r9d
	or ecx, r10d
	and ecx, 0xFFFF
	jnz mismatch_or_null_mask_in_ecx
%endmacro

; Parameters
; %1: the index of the yword in which the first (mismatching|null) byte is located. (starts from 0)
%macro MISMATCH_OR_NULL_IN_NTH_TO_LAST_YWORD_OF_S1_PAGE 1
%define N %1
; extract bitmask of the (mismatching|null) bytes
	vpmovmskb ecx, ymm6
; calculate the index of the first (mismatching|null) byte
	bsf ecx, ecx
	add rcx, rax
; load the first (mismatching|null) byte from both S0 and S1
	movzx eax, byte [ rdi + rcx + YWORD_SIZE * N ]
	movzx ecx, byte [ rsi + rcx + YWORD_SIZE * N ]
; calculate the possible difference between them
	sub eax, ecx
; take into account the possible inversion
	xor eax, r8d
	sub eax, r8d
; clear the upper bits of the YMM registers to avoid performance penalties
	vzeroupper
	ret
%endmacro

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
; preliminary initialization
	vpxor xmm0, xmm0, xmm0 ; YWORD_CHECKER
	xor edx, edx ; yword selector index
	xor r8d, r8d ; inversion flag
; check if either S0 or S1 is less than 4 ywords away from its next page boundary
; NOTE: this way to check can lead to false positives, but the performance gain is worth it
	mov eax, edi
	or eax, esi
	and eax, PAGE_SIZE - 1
	cmp eax, PAGE_SIZE - YWORD_SIZE * 4
	ja maybe_page_crossing_at_start
align 16
SEQ_check_4_ywords_at_start:
	CHECK_AND_COMPARE_YWORD rdi, rsi, vmovdqu, YWORD_SIZE * 0
	jnz mismatch_or_null_in_1st_yword
	CHECK_AND_COMPARE_YWORD rdi, rsi, vmovdqu, YWORD_SIZE * 1
	jnz mismatch_or_null_in_2nd_yword
	CHECK_AND_COMPARE_YWORD rdi, rsi, vmovdqu, YWORD_SIZE * 2
	jnz mismatch_or_null_in_3rd_yword
	CHECK_AND_COMPARE_YWORD rdi, rsi, vmovdqu, YWORD_SIZE * 3
	jnz mismatch_or_null_in_4th_yword
align 16
align_S0_and_adjust_S1:
	sub rsi, rdi
	and rdi, -YWORD_SIZE * 4 ; previous 4-yword boundary
	add rsi, rdi
; calculate how far (S1+YWORD_SIZE×4) is from its next page boundary
	mov eax, -YWORD_SIZE * 4
	sub eax, esi
	and eax, PAGE_SIZE - 1
align 16
advance_to_next_4_ywords:
	add rdi, YWORD_SIZE * 4
	add rsi, YWORD_SIZE * 4
	sub rax, YWORD_SIZE * 4
	jc at_most_4_ywords_before_S1_crosses
align 16
ILP_check_4_next_ywords_no_page_crossing:
;                                      ┌─────────────┬──ymm1──(S0+YWORD_SIZE×0)[..YWORD_SIZE]
;                          ┌──ymm9───AND             │
;                          │           └──ymm5──CMPEQB────────(S1+YWORD_SIZE×0)[..YWORD_SIZE]
;            ┌──ymm13──MINUB
;            │             │           ┌─────────────┬──ymm2──(S0+YWORD_SIZE×1)[..YWORD_SIZE]
;            │             └──ymm10──AND             │
;            │                         └──ymm6──CMPEQB────────(S1+YWORD_SIZE×1)[..YWORD_SIZE]
; ymm15──MINUB
;            │                         ┌─────────────┬──ymm3──(S0+YWORD_SIZE×2)[..YWORD_SIZE]
;            │             ┌──ymm11──AND             │
;            │             │           └──ymm7──CMPEQB────────(S1+YWORD_SIZE×2)[..YWORD_SIZE]
;            └──ymm14──MINUB
;                          │           ┌─────────────┬──ymm4──(S0+YWORD_SIZE×3)[..YWORD_SIZE]
;                          └──ymm12──AND             │
;                                      └──ymm8──CMPEQB────────(S1+YWORD_SIZE×3)[..YWORD_SIZE]
	vmovdqa ymm1, [ rdi + YWORD_SIZE * 0 ]
	vmovdqa ymm2, [ rdi + YWORD_SIZE * 1 ]
	vmovdqa ymm3, [ rdi + YWORD_SIZE * 2 ]
	vmovdqa ymm4, [ rdi + YWORD_SIZE * 3 ]
	vpcmpeqb ymm5, ymm1, [ rsi + YWORD_SIZE * 0 ]
	vpcmpeqb ymm6, ymm2, [ rsi + YWORD_SIZE * 1 ]
	vpcmpeqb ymm7, ymm3, [ rsi + YWORD_SIZE * 2 ]
	vpcmpeqb ymm8, ymm4, [ rsi + YWORD_SIZE * 3 ]
	vpand ymm9,  ymm1, ymm5
	vpand ymm10, ymm2, ymm6
	vpand ymm11, ymm3, ymm7
	vpand ymm12, ymm4, ymm8
	vpminub ymm13, ymm9,  ymm10
	vpminub ymm14, ymm11, ymm12
	vpminub ymm15, ymm13, ymm14
; check if there is a (mismatching|null) byte
	vpcmpeqb ymm1, ymm15, ymm0
	vptest ymm1, ymm1
	jz advance_to_next_4_ywords
; check if the first (mismatching|null) byte is in the 1st yword
	vpcmpeqb ymm6, ymm9, ymm0
	vptest ymm6, ymm6
	jnz mismatch_or_null_in_1st_yword
; check if the first (mismatching|null) byte is in the 2nd yword
	vpcmpeqb ymm6, ymm10, ymm0
	vptest ymm6, ymm6
	jnz mismatch_or_null_in_2nd_yword
; check if the first (mismatching|null) byte is in the 3rd yword
	vpcmpeqb ymm6, ymm11, ymm0
	vptest ymm6, ymm6
	jnz mismatch_or_null_in_3rd_yword
	vmovdqa ymm6, ymm1
align 16
mismatch_or_null_in_4th_yword:
	MISMATCH_OR_NULL_IN_NTH_YWORD 3

align 16
mismatch_or_null_in_3rd_yword:
	MISMATCH_OR_NULL_IN_NTH_YWORD 2

align 16
mismatch_or_null_in_2nd_yword:
	MISMATCH_OR_NULL_IN_NTH_YWORD 1

align 16
mismatch_or_null_in_1st_yword:
	MISMATCH_OR_NULL_IN_NTH_YWORD 0

align 16
maybe_page_crossing_at_start:
; check if both S0 and S1 are aligned to a yword boundary
	test eax, YWORD_SIZE - 1
	jz SEQ_check_4_ywords_at_start
; calculate how far both S0 and S1 are from their respective next page boundaries
	mov eax, edi
	mov ecx, esi
	and eax, PAGE_SIZE - 1
	and ecx, PAGE_SIZE - 1
; check which string shall cross a page boundary first
	cmp eax, ecx
	jb S1_shall_cross_before_S0
; check if S0 is at least 4 ywords away from its next page boundary
	sub eax, PAGE_SIZE - YWORD_SIZE * 4
	jbe SEQ_check_4_ywords_at_start
; check if S0 is less than 1 yword away from its next page boundary
	sub eax, YWORD_SIZE * 3
	ja less_than_1_yword_before_S0_crosses
align 16
at_least_1_yword_before_S0_crosses:
	CHECK_AND_COMPARE_YWORD rdi, rsi, vmovdqu, rdx
	jnz mismatch_or_null_mask_in_ymm6
; advance to the next yword of both S0 and S1
	add edx, YWORD_SIZE
; update the distance between S0 and its next page boundary
	add eax, YWORD_SIZE
; repeat until either a (mismatching|null) byte is found
; or S0 is less than 1 yword away from its next page boundary
	jl at_least_1_yword_before_S0_crosses
; set the index to the last yword of the current S0 page
	sub edx, eax
	CHECK_AND_COMPARE_YWORD rdi, rsi, vmovdqa, rdx
	jz align_S0_and_adjust_S1
align 16
mismatch_or_null_mask_in_ymm6:
; extract bitmask of the (mismatching|null) bytes
	vpmovmskb ecx, ymm6
; calculate the index of the first (mismatching|null) byte
	bsf ecx, ecx
	add edx, ecx
; load the first (mismatching|null) byte from both S0 and S1
	movzx eax, byte [ rdi + rdx ]
	movzx ecx, byte [ rsi + rdx ]
; calculate the possible difference between them
	sub eax, ecx
; take into account the possible inversion
	xor eax, r8d
	sub eax, r8d
; clear the upper bits of the YMM registers to avoid performance penalties
	vzeroupper
	ret

align 16
S1_shall_cross_before_S0:
; check if S1 is at least 4 ywords away from its next page boundary
	sub ecx, PAGE_SIZE - YWORD_SIZE * 4
	jbe SEQ_check_4_ywords_at_start
; swap both S0 and S1 pointers
	xchg rdi, rsi
	mov eax, ecx
	not r8d
; check if S0 is at least 1 yword away from its next page boundary
	sub eax, YWORD_SIZE * 3
	jle at_least_1_yword_before_S0_crosses
align 16
less_than_1_yword_before_S0_crosses:
; check if S0 is less than 1 oword away from its next page boundary
	cmp eax, OWORD_SIZE
	ja less_than_1_oword_before_S0_crosses
	CHECK_AND_COMPARE_OWORD vmovdqu
; set the index to the last oword of the current S0 page
	mov edx, OWORD_SIZE
	sub edx, eax
	CHECK_AND_COMPARE_OWORD vmovdqa, rdx
	jmp align_S0_and_adjust_S1

align 16
less_than_1_oword_before_S0_crosses:
; check if S0 is less than 1 qword away from its next page boundary
	cmp eax, OWORD_SIZE + QWORD_SIZE
	ja less_than_1_qword_before_S0_crosses
	vmovdqa xmm5, [ QWORD_CHECKER ]
	CHECK_AND_COMPARE_CHUNK vmovq
; set the index to the last qword of the current S0 page
	mov edx, OWORD_SIZE + QWORD_SIZE
	sub edx, eax
	CHECK_AND_COMPARE_CHUNK vmovq, rdx
	jmp align_S0_and_adjust_S1

align 16
less_than_1_qword_before_S0_crosses:
; check if S0 is less than 1 dword away from its next page boundary
	cmp eax, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE
	ja less_than_1_dword_before_S0_crosses
	vmovdqa xmm5, [ DWORD_CHECKER ]
	CHECK_AND_COMPARE_CHUNK vmovd
; set the index to the last dword of the current S0 page
	mov edx, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE
	sub edx, eax
	CHECK_AND_COMPARE_CHUNK vmovd, rdx
	jmp align_S0_and_adjust_S1

align 16
less_than_1_dword_before_S0_crosses:
; check if S0 is less than 1 word away from its next page boundary
	cmp eax, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE + WORD_SIZE
	ja less_than_1_word_before_S0_crosses
	CHECK_AND_COMPARE_WORD
; set the index to the last word of the current S0 page
	mov edx, OWORD_SIZE + QWORD_SIZE + DWORD_SIZE + WORD_SIZE
	sub edx, eax
	CHECK_AND_COMPARE_WORD rdx
	jmp align_S0_and_adjust_S1

align 16
less_than_1_word_before_S0_crosses:
; load the very first byte from both S0 and S1
	movzx eax, byte [ rdi ]
	movzx ecx, byte [ rsi ]
; calculate the possible difference between them
	sub eax, ecx
	jnz diff_on_very_first_byte
; check if we have reached the end of both S0 and S1
	test ecx, ecx
	jnz align_S0_and_adjust_S1
	ret

align 16
diff_on_very_first_byte:
; take into account the possible inversion
	xor eax, r8d
	sub eax, r8d
	ret

align 16
mismatch_or_null_mask_in_ecx:
; calculate the index of the first (mismatching|null) byte
	bsf ecx, ecx
	shr ecx, 3 ; divide by 8
	add edx, ecx
; load the first (mismatching|null) byte from both S0 and S1
	movzx eax, byte [ rdi + rdx ]
	movzx ecx, byte [ rsi + rdx ]
; calculate the possible difference between them
	sub eax, ecx
; take into account the possible inversion
	xor eax, r8d
	sub eax, r8d
	ret

align 16
at_most_4_ywords_before_S1_crosses:
; NOTE: at this point, rax contains the S1 offset to the last 4-yword boundary of its page
; check if S1 is aligned to a 4-yword boundary
	cmp eax, -YWORD_SIZE * 4
	je ILP_check_4_next_ywords_no_page_crossing
; check if S1 is at most 1 yword away from its next page boundary
	cmp eax, -YWORD_SIZE * 3
	jle at_most_1_yword_before_S1_crosses
	CHECK_AND_COMPARE_YWORD rdi, rsi, vmovdqa
	jnz mismatch_or_null_in_1st_yword
; check if S1 is more than 2 ywords away from its next page boundary
	cmp eax, -YWORD_SIZE * 2
	jg more_than_2_ywords_and_less_than_4_ywords_before_S1_crosses
align 16
at_most_1_yword_before_S1_crosses:
	CHECK_AND_COMPARE_YWORD rsi, rdi, vmovdqa, rax + YWORD_SIZE * 3
	jnz mismatch_or_null_in_last_yword_of_S1_page
; calculate how far S1 is from its next page boundary
	add rax, PAGE_SIZE
	jmp ILP_check_4_next_ywords_no_page_crossing

more_than_2_ywords_and_less_than_4_ywords_before_S1_crosses:
	CHECK_AND_COMPARE_YWORD rdi, rsi, vmovdqa, YWORD_SIZE
	jnz mismatch_or_null_in_2nd_yword
	CHECK_AND_COMPARE_YWORD rsi, rdi, vmovdqa, rax + YWORD_SIZE * 2
	jnz mismatch_or_null_in_penultimate_yword_of_S1_page
	CHECK_AND_COMPARE_YWORD rsi, rdi, vmovdqa, rax + YWORD_SIZE * 3
	jnz mismatch_or_null_in_last_yword_of_S1_page
; calculate how far S1 is from its next page boundary
	add rax, PAGE_SIZE
	jmp ILP_check_4_next_ywords_no_page_crossing

align 16
mismatch_or_null_in_last_yword_of_S1_page:
	MISMATCH_OR_NULL_IN_NTH_TO_LAST_YWORD_OF_S1_PAGE 3

align 16
mismatch_or_null_in_penultimate_yword_of_S1_page:
	MISMATCH_OR_NULL_IN_NTH_TO_LAST_YWORD_OF_S1_PAGE 2

section .rodata align=16

QWORD_CHECKER:
	times              QWORD_SIZE db 0x00
	times OWORD_SIZE - QWORD_SIZE db 0xFF

DWORD_CHECKER:
	times              DWORD_SIZE db 0x00
	times OWORD_SIZE - DWORD_SIZE db 0xFF
