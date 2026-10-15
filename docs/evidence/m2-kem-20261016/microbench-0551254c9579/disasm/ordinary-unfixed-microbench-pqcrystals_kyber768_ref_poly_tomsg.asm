
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000051da <pqcrystals_kyber768_ref_poly_tomsg>:
    51da:	45 31 c0             	xor    %r8d,%r8d
    51dd:	41 b9 01 0d 00 00    	mov    $0xd01,%r9d
    51e3:	49 83 f8 20          	cmp    $0x20,%r8
    51e7:	74 47                	je     5230 <pqcrystals_kyber768_ref_poly_tomsg+0x56>
    51e9:	42 c6 04 07 00       	movb   $0x0,(%rdi,%r8,1)
    51ee:	31 c9                	xor    %ecx,%ecx
    51f0:	45 31 d2             	xor    %r10d,%r10d
    51f3:	48 83 f9 08          	cmp    $0x8,%rcx
    51f7:	74 2e                	je     5227 <pqcrystals_kyber768_ref_poly_tomsg+0x4d>
    51f9:	0f bf 04 4e          	movswl (%rsi,%rcx,2),%eax
    51fd:	89 c2                	mov    %eax,%edx
    51ff:	c1 ea 0f             	shr    $0xf,%edx
    5202:	44 21 ca             	and    %r9d,%edx
    5205:	01 c2                	add    %eax,%edx
    5207:	0f b7 c2             	movzwl %dx,%eax
    520a:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
    5211:	31 d2                	xor    %edx,%edx
    5213:	41 f7 f1             	div    %r9d
    5216:	83 e0 01             	and    $0x1,%eax
    5219:	d3 e0                	shl    %cl,%eax
    521b:	41 08 c2             	or     %al,%r10b
    521e:	46 88 14 07          	mov    %r10b,(%rdi,%r8,1)
    5222:	48 ff c1             	inc    %rcx
    5225:	eb cc                	jmp    51f3 <pqcrystals_kyber768_ref_poly_tomsg+0x19>
    5227:	49 ff c0             	inc    %r8
    522a:	48 83 c6 10          	add    $0x10,%rsi
    522e:	eb b3                	jmp    51e3 <pqcrystals_kyber768_ref_poly_tomsg+0x9>
    5230:	c3                   	ret

Disassembly of section .fini:
