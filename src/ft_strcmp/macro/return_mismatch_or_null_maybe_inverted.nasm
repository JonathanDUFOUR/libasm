%ifndef RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED_NASM
%define RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED_NASM

%include "define/registers.nasm"
%include "macro/calculate_diff_at_first_mismatch_or_null.nasm"
%include "macro/negate_if_flag.nasm"
%include "macro/vzeroupper_ret.nasm"

; Parameters
; %1: the bitmask from which to calculate the index of the first (mismatching|null) byte is.
; %2: the offset to apply
%macro RETURN_MISMATCH_OR_NULL_MAYBE_INVERTED 2
%define BITMASK %1
%define  OFFSET %2
	CALCULATE_DIFF_AT_FIRST_MISMATCH_OR_NULL BITMASK, OFFSET
	NEGATE_IF_FLAG eax, INVERSION_FLAG
	VZEROUPPER_RET
%endmacro

%endif
