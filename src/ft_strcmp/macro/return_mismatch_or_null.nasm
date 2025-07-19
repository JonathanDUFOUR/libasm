%ifndef RETURN_MISMATCH_OR_NULL_NASM
%define RETURN_MISMATCH_OR_NULL_NASM

%include "macro/calculate_diff_at_first_mismatch_or_null.nasm"
%include "macro/vzeroupper_ret.nasm"

; Parameters
; %1: the mask register from which to calculate the index of the first (mismatching|null) byte.
; %2: the offset to apply
%macro RETURN_MISMATCH_OR_NULL 2
%define GPR_MASK %1
%define   OFFSET %2
	CALCULATE_DIFF_AT_FIRST_MISMATCH_OR_NULL GPR_MASK, OFFSET
	VZEROUPPER_RET
%endmacro

%endif

