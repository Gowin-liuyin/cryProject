
/home/ubuntu/cryProject-work/build/m2-branchfix-work/baseline-driver:     file format elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000002b9b <pqcrystals_kyber768_ref_poly_frommsg>:
    2b9b:	xor    %eax,%eax
    2b9d:	cmp    $0x20,%rax
    2ba1:	je     2bcf <pqcrystals_kyber768_ref_poly_frommsg+0x34>
    2ba3:	xor    %ecx,%ecx
    2ba5:	cmp    $0x8,%rcx
    2ba9:	je     2bc6 <pqcrystals_kyber768_ref_poly_frommsg+0x2b>
    2bab:	movzbl (%rsi,%rax,1),%r8d
    2bb0:	xor    %edx,%edx
    2bb2:	bt     %ecx,%r8d
    2bb6:	jae    2bbd <pqcrystals_kyber768_ref_poly_frommsg+0x22>
    2bb8:	mov    $0x681,%edx
    2bbd:	mov    %dx,(%rdi,%rcx,2)
    2bc1:	inc    %rcx
    2bc4:	jmp    2ba5 <pqcrystals_kyber768_ref_poly_frommsg+0xa>
    2bc6:	inc    %rax
    2bc9:	add    $0x10,%rdi
    2bcd:	jmp    2b9d <pqcrystals_kyber768_ref_poly_frommsg+0x2>
    2bcf:	ret

Disassembly of section .fini:
