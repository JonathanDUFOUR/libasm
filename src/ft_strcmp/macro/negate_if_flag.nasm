%ifndef NEGATE_IF_FLAG_NASM
%define NEGATE_IF_FLAG_NASM

; Parameters
; %1: the value to negate is FLAG is set.
; %2: 0|1
%macro NEGATE_IF_FLAG 2
%define VALUE %1
%define FLAG  %2
	xor VALUE, FLAG
	sub VALUE, FLAG
%endmacro

%endif
