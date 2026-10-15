
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_dudect：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003bd4 <pqcrystals_kyber768_ref_poly_compress>:
    3bd4:	31 c0                	xor    %eax,%eax
    3bd6:	48 83 f8 20          	cmp    $0x20,%rax
    3bda:	0f 84 80 00 00 00    	je     3c60 <pqcrystals_kyber768_ref_poly_compress+0x8c>
    3be0:	31 c9                	xor    %ecx,%ecx
    3be2:	48 83 f9 08          	cmp    $0x8,%rcx
    3be6:	74 31                	je     3c19 <pqcrystals_kyber768_ref_poly_compress+0x45>
    3be8:	0f bf 14 4e          	movswl (%rsi,%rcx,2),%edx
    3bec:	41 89 d0             	mov    %edx,%r8d
    3bef:	41 c1 e8 0f          	shr    $0xf,%r8d
    3bf3:	41 81 e0 01 0d 00 00 	and    $0xd01,%r8d
    3bfa:	41 01 d0             	add    %edx,%r8d
    3bfd:	41 0f bf d0          	movswl %r8w,%edx
    3c01:	69 d2 b0 af 13 00    	imul   $0x13afb0,%edx,%edx
    3c07:	81 c2 7b 9a 00 08    	add    $0x8009a7b,%edx
    3c0d:	c1 ea 1c             	shr    $0x1c,%edx
    3c10:	88 54 0c f8          	mov    %dl,-0x8(%rsp,%rcx,1)
    3c14:	48 ff c1             	inc    %rcx
    3c17:	eb c9                	jmp    3be2 <pqcrystals_kyber768_ref_poly_compress+0xe>
    3c19:	8a 4c 24 f9          	mov    -0x7(%rsp),%cl
    3c1d:	c0 e1 04             	shl    $0x4,%cl
    3c20:	0a 4c 24 f8          	or     -0x8(%rsp),%cl
    3c24:	88 0f                	mov    %cl,(%rdi)
    3c26:	8a 4c 24 fb          	mov    -0x5(%rsp),%cl
    3c2a:	c0 e1 04             	shl    $0x4,%cl
    3c2d:	0a 4c 24 fa          	or     -0x6(%rsp),%cl
    3c31:	88 4f 01             	mov    %cl,0x1(%rdi)
    3c34:	8a 4c 24 fd          	mov    -0x3(%rsp),%cl
    3c38:	c0 e1 04             	shl    $0x4,%cl
    3c3b:	0a 4c 24 fc          	or     -0x4(%rsp),%cl
    3c3f:	88 4f 02             	mov    %cl,0x2(%rdi)
    3c42:	8a 4c 24 ff          	mov    -0x1(%rsp),%cl
    3c46:	c0 e1 04             	shl    $0x4,%cl
    3c49:	0a 4c 24 fe          	or     -0x2(%rsp),%cl
    3c4d:	88 4f 03             	mov    %cl,0x3(%rdi)
    3c50:	48 83 c7 04          	add    $0x4,%rdi
    3c54:	48 ff c0             	inc    %rax
    3c57:	48 83 c6 10          	add    $0x10,%rsi
    3c5b:	e9 76 ff ff ff       	jmp    3bd6 <pqcrystals_kyber768_ref_poly_compress+0x2>
    3c60:	c3                   	ret

Disassembly of section .fini:
