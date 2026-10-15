
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/qualification/unfixed/m2_hotspot_qualification：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000047aa <pqcrystals_kyber768_ref_poly_tomsg>:
    47aa:	45 31 c0             	xor    %r8d,%r8d
    47ad:	41 b9 01 0d 00 00    	mov    $0xd01,%r9d
    47b3:	49 83 f8 20          	cmp    $0x20,%r8
    47b7:	74 47                	je     4800 <pqcrystals_kyber768_ref_poly_tomsg+0x56>
    47b9:	42 c6 04 07 00       	movb   $0x0,(%rdi,%r8,1)
    47be:	31 c9                	xor    %ecx,%ecx
    47c0:	45 31 d2             	xor    %r10d,%r10d
    47c3:	48 83 f9 08          	cmp    $0x8,%rcx
    47c7:	74 2e                	je     47f7 <pqcrystals_kyber768_ref_poly_tomsg+0x4d>
    47c9:	0f bf 04 4e          	movswl (%rsi,%rcx,2),%eax
    47cd:	89 c2                	mov    %eax,%edx
    47cf:	c1 ea 0f             	shr    $0xf,%edx
    47d2:	44 21 ca             	and    %r9d,%edx
    47d5:	01 c2                	add    %eax,%edx
    47d7:	0f b7 c2             	movzwl %dx,%eax
    47da:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
    47e1:	31 d2                	xor    %edx,%edx
    47e3:	41 f7 f1             	div    %r9d
    47e6:	83 e0 01             	and    $0x1,%eax
    47e9:	d3 e0                	shl    %cl,%eax
    47eb:	41 08 c2             	or     %al,%r10b
    47ee:	46 88 14 07          	mov    %r10b,(%rdi,%r8,1)
    47f2:	48 ff c1             	inc    %rcx
    47f5:	eb cc                	jmp    47c3 <pqcrystals_kyber768_ref_poly_tomsg+0x19>
    47f7:	49 ff c0             	inc    %r8
    47fa:	48 83 c6 10          	add    $0x10,%rsi
    47fe:	eb b3                	jmp    47b3 <pqcrystals_kyber768_ref_poly_tomsg+0x9>
    4800:	c3                   	ret

Disassembly of section .fini:
