
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/qualification/fixed/m2_hotspot_qualification：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000047b0 <pqcrystals_kyber768_ref_poly_tomsg>:
    47b0:	31 c0                	xor    %eax,%eax
    47b2:	48 83 f8 20          	cmp    $0x20,%rax
    47b6:	74 40                	je     47f8 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
    47b8:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    47bc:	31 c9                	xor    %ecx,%ecx
    47be:	31 d2                	xor    %edx,%edx
    47c0:	48 83 f9 08          	cmp    $0x8,%rcx
    47c4:	74 29                	je     47ef <pqcrystals_kyber768_ref_poly_tomsg+0x3f>
    47c6:	44 0f bf 04 4e       	movswl (%rsi,%rcx,2),%r8d
    47cb:	45 69 c0 f6 75 02 00 	imul   $0x275f6,%r8d,%r8d
    47d2:	41 81 c0 7b 9a 00 08 	add    $0x8009a7b,%r8d
    47d9:	41 c1 e8 1c          	shr    $0x1c,%r8d
    47dd:	41 83 e0 01          	and    $0x1,%r8d
    47e1:	41 d3 e0             	shl    %cl,%r8d
    47e4:	44 08 c2             	or     %r8b,%dl
    47e7:	88 14 07             	mov    %dl,(%rdi,%rax,1)
    47ea:	48 ff c1             	inc    %rcx
    47ed:	eb d1                	jmp    47c0 <pqcrystals_kyber768_ref_poly_tomsg+0x10>
    47ef:	48 ff c0             	inc    %rax
    47f2:	48 83 c6 10          	add    $0x10,%rsi
    47f6:	eb ba                	jmp    47b2 <pqcrystals_kyber768_ref_poly_tomsg+0x2>
    47f8:	c3                   	ret

Disassembly of section .fini:
