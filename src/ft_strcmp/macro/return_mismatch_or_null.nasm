%ifndef RETURN_MISMATCH_OR_NULL_NASM
%define RETURN_MISMATCH_OR_NULL_NASM

%include "macro/calculate_diff_at_first_mismatch_or_null.nasm"
%include "macro/vzeroupper_ret.nasm"

; Parameters
; %1: the offset to apply
%macro RETURN_MISMATCH_OR_NULL 1
%define OFFSET %1
	CALCULATE_DIFF_AT_FIRST_MISMATCH_OR_NULL ecx, OFFSET
	VZEROUPPER_RET
%endmacro

%endif

