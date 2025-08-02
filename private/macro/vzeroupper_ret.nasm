%ifndef VZEROUPPER_RET_NASM
%define VZEROUPPER_RET_NASM

%macro VZEROUPPER_RET 0
; clear the upper bits of the YMM registers to avoid performance penalties
	vzeroupper
	ret
%endmacro

%endif
