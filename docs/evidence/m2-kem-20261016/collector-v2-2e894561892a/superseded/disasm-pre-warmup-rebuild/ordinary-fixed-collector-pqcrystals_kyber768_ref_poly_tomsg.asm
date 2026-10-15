
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000004900 <pqcrystals_kyber768_ref_poly_tomsg>:
    4900:	31 c0                	xor    %eax,%eax
    4902:	48 83 f8 20          	cmp    $0x20,%rax
    4906:	74 40                	je     4948 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
    4908:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    490c:	31 c9                	xor    %ecx,%ecx
    490e:	31 d2                	xor    %edx,%edx
    4910:	48 83 f9 08          	cmp    $0x8,%rcx
    4914:	74 29                	je     493f <pqcrystals_kyber768_ref_poly_tomsg+0x3f>
    4916:	44 0f bf 04 4e       	movswl (%rsi,%rcx,2),%r8d
    491b:	45 69 c0 f6 75 02 00 	imul   $0x275f6,%r8d,%r8d
    4922:	41 81 c0 7b 9a 00 08 	add    $0x8009a7b,%r8d
    4929:	41 c1 e8 1c          	shr    $0x1c,%r8d
    492d:	41 83 e0 01          	and    $0x1,%r8d
    4931:	41 d3 e0             	shl    %cl,%r8d
    4934:	44 08 c2             	or     %r8b,%dl
    4937:	88 14 07             	mov    %dl,(%rdi,%rax,1)
    493a:	48 ff c1             	inc    %rcx
    493d:	eb d1                	jmp    4910 <pqcrystals_kyber768_ref_poly_tomsg+0x10>
    493f:	48 ff c0             	inc    %rax
    4942:	48 83 c6 10          	add    $0x10,%rsi
    4946:	eb ba                	jmp    4902 <pqcrystals_kyber768_ref_poly_tomsg+0x2>
    4948:	c3                   	ret

Disassembly of section .fini:
