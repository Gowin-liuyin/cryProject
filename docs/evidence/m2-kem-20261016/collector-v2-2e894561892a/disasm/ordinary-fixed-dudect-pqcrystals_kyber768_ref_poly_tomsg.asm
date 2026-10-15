
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_dudect：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003d70 <pqcrystals_kyber768_ref_poly_tomsg>:
    3d70:	31 c0                	xor    %eax,%eax
    3d72:	48 83 f8 20          	cmp    $0x20,%rax
    3d76:	74 40                	je     3db8 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
    3d78:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    3d7c:	31 c9                	xor    %ecx,%ecx
    3d7e:	31 d2                	xor    %edx,%edx
    3d80:	48 83 f9 08          	cmp    $0x8,%rcx
    3d84:	74 29                	je     3daf <pqcrystals_kyber768_ref_poly_tomsg+0x3f>
    3d86:	44 0f bf 04 4e       	movswl (%rsi,%rcx,2),%r8d
    3d8b:	45 69 c0 f6 75 02 00 	imul   $0x275f6,%r8d,%r8d
    3d92:	41 81 c0 7b 9a 00 08 	add    $0x8009a7b,%r8d
    3d99:	41 c1 e8 1c          	shr    $0x1c,%r8d
    3d9d:	41 83 e0 01          	and    $0x1,%r8d
    3da1:	41 d3 e0             	shl    %cl,%r8d
    3da4:	44 08 c2             	or     %r8b,%dl
    3da7:	88 14 07             	mov    %dl,(%rdi,%rax,1)
    3daa:	48 ff c1             	inc    %rcx
    3dad:	eb d1                	jmp    3d80 <pqcrystals_kyber768_ref_poly_tomsg+0x10>
    3daf:	48 ff c0             	inc    %rax
    3db2:	48 83 c6 10          	add    $0x10,%rsi
    3db6:	eb ba                	jmp    3d72 <pqcrystals_kyber768_ref_poly_tomsg+0x2>
    3db8:	c3                   	ret

Disassembly of section .fini:
