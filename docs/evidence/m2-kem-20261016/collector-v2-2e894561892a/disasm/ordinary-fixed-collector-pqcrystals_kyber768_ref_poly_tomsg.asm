
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000004990 <pqcrystals_kyber768_ref_poly_tomsg>:
    4990:	31 c0                	xor    %eax,%eax
    4992:	48 83 f8 20          	cmp    $0x20,%rax
    4996:	74 40                	je     49d8 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
    4998:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    499c:	31 c9                	xor    %ecx,%ecx
    499e:	31 d2                	xor    %edx,%edx
    49a0:	48 83 f9 08          	cmp    $0x8,%rcx
    49a4:	74 29                	je     49cf <pqcrystals_kyber768_ref_poly_tomsg+0x3f>
    49a6:	44 0f bf 04 4e       	movswl (%rsi,%rcx,2),%r8d
    49ab:	45 69 c0 f6 75 02 00 	imul   $0x275f6,%r8d,%r8d
    49b2:	41 81 c0 7b 9a 00 08 	add    $0x8009a7b,%r8d
    49b9:	41 c1 e8 1c          	shr    $0x1c,%r8d
    49bd:	41 83 e0 01          	and    $0x1,%r8d
    49c1:	41 d3 e0             	shl    %cl,%r8d
    49c4:	44 08 c2             	or     %r8b,%dl
    49c7:	88 14 07             	mov    %dl,(%rdi,%rax,1)
    49ca:	48 ff c1             	inc    %rcx
    49cd:	eb d1                	jmp    49a0 <pqcrystals_kyber768_ref_poly_tomsg+0x10>
    49cf:	48 ff c0             	inc    %rax
    49d2:	48 83 c6 10          	add    $0x10,%rsi
    49d6:	eb ba                	jmp    4992 <pqcrystals_kyber768_ref_poly_tomsg+0x2>
    49d8:	c3                   	ret

Disassembly of section .fini:
