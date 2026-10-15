
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/fixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000051e0 <pqcrystals_kyber768_ref_poly_tomsg>:
    51e0:	31 c0                	xor    %eax,%eax
    51e2:	48 83 f8 20          	cmp    $0x20,%rax
    51e6:	74 40                	je     5228 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
    51e8:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    51ec:	31 c9                	xor    %ecx,%ecx
    51ee:	31 d2                	xor    %edx,%edx
    51f0:	48 83 f9 08          	cmp    $0x8,%rcx
    51f4:	74 29                	je     521f <pqcrystals_kyber768_ref_poly_tomsg+0x3f>
    51f6:	44 0f bf 04 4e       	movswl (%rsi,%rcx,2),%r8d
    51fb:	45 69 c0 f6 75 02 00 	imul   $0x275f6,%r8d,%r8d
    5202:	41 81 c0 7b 9a 00 08 	add    $0x8009a7b,%r8d
    5209:	41 c1 e8 1c          	shr    $0x1c,%r8d
    520d:	41 83 e0 01          	and    $0x1,%r8d
    5211:	41 d3 e0             	shl    %cl,%r8d
    5214:	44 08 c2             	or     %r8b,%dl
    5217:	88 14 07             	mov    %dl,(%rdi,%rax,1)
    521a:	48 ff c1             	inc    %rcx
    521d:	eb d1                	jmp    51f0 <pqcrystals_kyber768_ref_poly_tomsg+0x10>
    521f:	48 ff c0             	inc    %rax
    5222:	48 83 c6 10          	add    $0x10,%rsi
    5226:	eb ba                	jmp    51e2 <pqcrystals_kyber768_ref_poly_tomsg+0x2>
    5228:	c3                   	ret

Disassembly of section .fini:
