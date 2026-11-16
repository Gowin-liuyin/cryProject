
/home/ubuntu/cryProject-work/build/m2-branchfix-work/volatile-driver:     file format elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000002b9b <pqcrystals_kyber768_ref_poly_frommsg>:
    2b9b:	xor    %eax,%eax
    2b9d:	cmp    $0x20,%rax
    2ba1:	je     2bdb <pqcrystals_kyber768_ref_poly_frommsg+0x40>
    2ba3:	xor    %ecx,%ecx
    2ba5:	cmp    $0x8,%rcx
    2ba9:	je     2bd2 <pqcrystals_kyber768_ref_poly_frommsg+0x37>
    2bab:	movzbl (%rsi,%rax,1),%edx
    2baf:	bt     %ecx,%edx
    2bb2:	mov    $0x0,%edx
    2bb7:	sbb    %edx,%edx
    2bb9:	mov    %dx,-0x2(%rsp)
    2bbe:	movzwl -0x2(%rsp),%edx
    2bc3:	and    $0x681,%edx
    2bc9:	mov    %dx,(%rdi,%rcx,2)
    2bcd:	inc    %rcx
    2bd0:	jmp    2ba5 <pqcrystals_kyber768_ref_poly_frommsg+0xa>
    2bd2:	inc    %rax
    2bd5:	add    $0x10,%rdi
    2bd9:	jmp    2b9d <pqcrystals_kyber768_ref_poly_frommsg+0x2>
    2bdb:	ret

Disassembly of section .fini:
