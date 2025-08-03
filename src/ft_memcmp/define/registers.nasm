%ifndef REGISTERS_NASM
%define REGISTERS_NASM

%define YMM_00_1F ymm0
%define YMM_20_3F ymm1
%define YMM_40_5F ymm2
%define YMM_60_7F ymm3
%define YMM_80_9F ymm4
%define YMM_A0_BF ymm5
%define YMM_C0_DF ymm6
%define YMM_E0_FF ymm7

%define MASK_00_1F ymm0
%define MASK_20_3F ymm1
%define MASK_40_5F ymm2
%define MASK_60_7F ymm3
%define MASK_80_9F ymm4
%define MASK_A0_BF ymm5
%define MASK_C0_DF ymm6
%define MASK_E0_FF ymm7

%define MASK_00_3F ymm1
%define MASK_40_7F ymm3
%define MASK_80_BF ymm5
%define MASK_C0_FF ymm7

%define MASK_00_7F ymm3
%define MASK_80_FF ymm7

%define MASK_00_FF ymm7

%endif
