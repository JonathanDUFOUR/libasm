%ifndef REGISTERS_NASM
%define REGISTERS_NASM

%define INVERSION_FLAG r8d

%define NULL_YMM ymm0
%define NULL_XMM xmm0

%define       YMM_00_1F ymm1
%define       YMM_20_3F ymm2
%define       YMM_40_5F ymm3
%define       YMM_60_7F ymm4
%define DIFF_MASK_00_1F ymm5
%define DIFF_MASK_20_3F ymm6
%define DIFF_MASK_40_5F ymm7
%define DIFF_MASK_60_7F ymm8
%define NULL_MASK_00_1F ymm1
%define NULL_MASK_20_3F ymm2
%define NULL_MASK_40_5F ymm3
%define NULL_MASK_60_7F ymm4
%define      MASK_00_1F ymm5
%define      MASK_20_3F ymm6
%define      MASK_40_5F ymm7
%define      MASK_60_7F ymm8
%define      MASK_00_3F ymm1
%define      MASK_40_7F ymm2
%define      MASK_00_7F ymm3

%endif
