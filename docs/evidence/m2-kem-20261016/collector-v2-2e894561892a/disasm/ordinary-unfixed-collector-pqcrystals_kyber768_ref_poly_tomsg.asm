
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

000000000000498a <pqcrystals_kyber768_ref_poly_tomsg>:
    498a:	45 31 c0             	xor    %r8d,%r8d
    498d:	41 b9 01 0d 00 00    	mov    $0xd01,%r9d
    4993:	49 83 f8 20          	cmp    $0x20,%r8
    4997:	74 47                	je     49e0 <pqcrystals_kyber768_ref_poly_tomsg+0x56>
    4999:	42 c6 04 07 00       	movb   $0x0,(%rdi,%r8,1)
    499e:	31 c9                	xor    %ecx,%ecx
    49a0:	45 31 d2             	xor    %r10d,%r10d
    49a3:	48 83 f9 08          	cmp    $0x8,%rcx
    49a7:	74 2e                	je     49d7 <pqcrystals_kyber768_ref_poly_tomsg+0x4d>
    49a9:	0f bf 04 4e          	movswl (%rsi,%rcx,2),%eax
    49ad:	89 c2                	mov    %eax,%edx
    49af:	c1 ea 0f             	shr    $0xf,%edx
    49b2:	44 21 ca             	and    %r9d,%edx
    49b5:	01 c2                	add    %eax,%edx
    49b7:	0f b7 c2             	movzwl %dx,%eax
    49ba:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
    49c1:	31 d2                	xor    %edx,%edx
    49c3:	41 f7 f1             	div    %r9d
    49c6:	83 e0 01             	and    $0x1,%eax
    49c9:	d3 e0                	shl    %cl,%eax
    49cb:	41 08 c2             	or     %al,%r10b
    49ce:	46 88 14 07          	mov    %r10b,(%rdi,%r8,1)
    49d2:	48 ff c1             	inc    %rcx
    49d5:	eb cc                	jmp    49a3 <pqcrystals_kyber768_ref_poly_tomsg+0x19>
    49d7:	49 ff c0             	inc    %r8
    49da:	48 83 c6 10          	add    $0x10,%rsi
    49de:	eb b3                	jmp    4993 <pqcrystals_kyber768_ref_poly_tomsg+0x9>
    49e0:	c3                   	ret

Disassembly of section .fini:
