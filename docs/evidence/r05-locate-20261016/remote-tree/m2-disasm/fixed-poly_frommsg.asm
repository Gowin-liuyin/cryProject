
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2/fixed/measure：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003657 <pqcrystals_kyber768_ref_poly_frommsg>:
    3657:	31 c0                	xor    %eax,%eax
    3659:	48 83 f8 20          	cmp    $0x20,%rax
    365d:	74 2c                	je     368b <pqcrystals_kyber768_ref_poly_frommsg+0x34>
    365f:	31 c9                	xor    %ecx,%ecx
    3661:	48 83 f9 08          	cmp    $0x8,%rcx
    3665:	74 1b                	je     3682 <pqcrystals_kyber768_ref_poly_frommsg+0x2b>
    3667:	44 0f b6 04 06       	movzbl (%rsi,%rax,1),%r8d
    366c:	31 d2                	xor    %edx,%edx
    366e:	41 0f a3 c8          	bt     %ecx,%r8d
    3672:	73 05                	jae    3679 <pqcrystals_kyber768_ref_poly_frommsg+0x22>
    3674:	ba 81 06 00 00       	mov    $0x681,%edx
    3679:	66 89 14 4f          	mov    %dx,(%rdi,%rcx,2)
    367d:	48 ff c1             	inc    %rcx
    3680:	eb df                	jmp    3661 <pqcrystals_kyber768_ref_poly_frommsg+0xa>
    3682:	48 ff c0             	inc    %rax
    3685:	48 83 c7 10          	add    $0x10,%rdi
    3689:	eb ce                	jmp    3659 <pqcrystals_kyber768_ref_poly_frommsg+0x2>
    368b:	c3                   	ret

Disassembly of section .fini:
