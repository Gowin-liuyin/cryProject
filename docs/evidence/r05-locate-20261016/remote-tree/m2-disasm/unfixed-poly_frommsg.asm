
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2/unfixed/measure：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003651 <pqcrystals_kyber768_ref_poly_frommsg>:
    3651:	31 c0                	xor    %eax,%eax
    3653:	48 83 f8 20          	cmp    $0x20,%rax
    3657:	74 2c                	je     3685 <pqcrystals_kyber768_ref_poly_frommsg+0x34>
    3659:	31 c9                	xor    %ecx,%ecx
    365b:	48 83 f9 08          	cmp    $0x8,%rcx
    365f:	74 1b                	je     367c <pqcrystals_kyber768_ref_poly_frommsg+0x2b>
    3661:	44 0f b6 04 06       	movzbl (%rsi,%rax,1),%r8d
    3666:	31 d2                	xor    %edx,%edx
    3668:	41 0f a3 c8          	bt     %ecx,%r8d
    366c:	73 05                	jae    3673 <pqcrystals_kyber768_ref_poly_frommsg+0x22>
    366e:	ba 81 06 00 00       	mov    $0x681,%edx
    3673:	66 89 14 4f          	mov    %dx,(%rdi,%rcx,2)
    3677:	48 ff c1             	inc    %rcx
    367a:	eb df                	jmp    365b <pqcrystals_kyber768_ref_poly_frommsg+0xa>
    367c:	48 ff c0             	inc    %rax
    367f:	48 83 c7 10          	add    $0x10,%rdi
    3683:	eb ce                	jmp    3653 <pqcrystals_kyber768_ref_poly_frommsg+0x2>
    3685:	c3                   	ret

Disassembly of section .fini:
