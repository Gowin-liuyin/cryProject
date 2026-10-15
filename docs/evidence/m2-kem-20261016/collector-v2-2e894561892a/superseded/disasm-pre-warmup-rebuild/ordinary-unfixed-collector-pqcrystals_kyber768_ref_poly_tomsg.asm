
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000048fa <pqcrystals_kyber768_ref_poly_tomsg>:
    48fa:	45 31 c0             	xor    %r8d,%r8d
    48fd:	41 b9 01 0d 00 00    	mov    $0xd01,%r9d
    4903:	49 83 f8 20          	cmp    $0x20,%r8
    4907:	74 47                	je     4950 <pqcrystals_kyber768_ref_poly_tomsg+0x56>
    4909:	42 c6 04 07 00       	movb   $0x0,(%rdi,%r8,1)
    490e:	31 c9                	xor    %ecx,%ecx
    4910:	45 31 d2             	xor    %r10d,%r10d
    4913:	48 83 f9 08          	cmp    $0x8,%rcx
    4917:	74 2e                	je     4947 <pqcrystals_kyber768_ref_poly_tomsg+0x4d>
    4919:	0f bf 04 4e          	movswl (%rsi,%rcx,2),%eax
    491d:	89 c2                	mov    %eax,%edx
    491f:	c1 ea 0f             	shr    $0xf,%edx
    4922:	44 21 ca             	and    %r9d,%edx
    4925:	01 c2                	add    %eax,%edx
    4927:	0f b7 c2             	movzwl %dx,%eax
    492a:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
    4931:	31 d2                	xor    %edx,%edx
    4933:	41 f7 f1             	div    %r9d
    4936:	83 e0 01             	and    $0x1,%eax
    4939:	d3 e0                	shl    %cl,%eax
    493b:	41 08 c2             	or     %al,%r10b
    493e:	46 88 14 07          	mov    %r10b,(%rdi,%r8,1)
    4942:	48 ff c1             	inc    %rcx
    4945:	eb cc                	jmp    4913 <pqcrystals_kyber768_ref_poly_tomsg+0x19>
    4947:	49 ff c0             	inc    %r8
    494a:	48 83 c6 10          	add    $0x10,%rsi
    494e:	eb b3                	jmp    4903 <pqcrystals_kyber768_ref_poly_tomsg+0x9>
    4950:	c3                   	ret

Disassembly of section .fini:
