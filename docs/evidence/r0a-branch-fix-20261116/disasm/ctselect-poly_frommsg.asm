
/home/ubuntu/cryProject-work/build/m2-branchfix-work/ctselect-driver:     file format elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000002b9b <pqcrystals_kyber768_ref_poly_frommsg>:
    2b9b:	push   %r15
    2b9d:	push   %r14
    2b9f:	push   %r12
    2ba1:	push   %rbx
    2ba2:	push   %rax
    2ba3:	mov    %rsi,%rbx
    2ba6:	mov    %rdi,%r14
    2ba9:	xor    %r15d,%r15d
    2bac:	cmp    $0x20,%r15
    2bb0:	je     2be3 <pqcrystals_kyber768_ref_poly_frommsg+0x48>
    2bb2:	xor    %r12d,%r12d
    2bb5:	cmp    $0x8,%r12
    2bb9:	je     2bda <pqcrystals_kyber768_ref_poly_frommsg+0x3f>
    2bbb:	movzbl (%rbx,%r15,1),%eax
    2bc0:	bt     %r12d,%eax
    2bc4:	mov    $0x0,%edi
    2bc9:	sbb    %edi,%edi
    2bcb:	call   2bef <mask_select_int16>
    2bd0:	mov    %ax,(%r14,%r12,2)
    2bd5:	inc    %r12
    2bd8:	jmp    2bb5 <pqcrystals_kyber768_ref_poly_frommsg+0x1a>
    2bda:	inc    %r15
    2bdd:	add    $0x10,%r14
    2be1:	jmp    2bac <pqcrystals_kyber768_ref_poly_frommsg+0x11>
    2be3:	add    $0x8,%rsp
    2be7:	pop    %rbx
    2be8:	pop    %r12
    2bea:	pop    %r14
    2bec:	pop    %r15
    2bee:	ret

Disassembly of section .fini:
