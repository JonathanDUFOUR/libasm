%ifndef NODE_NASM
%define NODE_NASM

struc t_node
	.data: resq 1
	.next: resq 1
endstruc

%endif
