
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_dudect：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003bd4 <pqcrystals_kyber768_ref_poly_compress>:
    3bd4:	31 c9                	xor    %ecx,%ecx
    3bd6:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    3bdc:	48 83 f9 20          	cmp    $0x20,%rcx
    3be0:	74 78                	je     3c5a <pqcrystals_kyber768_ref_poly_compress+0x86>
    3be2:	45 31 c9             	xor    %r9d,%r9d
    3be5:	49 83 f9 08          	cmp    $0x8,%r9
    3be9:	74 2b                	je     3c16 <pqcrystals_kyber768_ref_poly_compress+0x42>
    3beb:	42 0f bf 04 4e       	movswl (%rsi,%r9,2),%eax
    3bf0:	89 c2                	mov    %eax,%edx
    3bf2:	c1 ea 0f             	shr    $0xf,%edx
    3bf5:	44 21 c2             	and    %r8d,%edx
    3bf8:	01 c2                	add    %eax,%edx
    3bfa:	0f b7 c2             	movzwl %dx,%eax
    3bfd:	c1 e0 04             	shl    $0x4,%eax
    3c00:	05 80 06 00 00       	add    $0x680,%eax
    3c05:	31 d2                	xor    %edx,%edx
    3c07:	41 f7 f0             	div    %r8d
    3c0a:	24 0f                	and    $0xf,%al
    3c0c:	42 88 44 0c f8       	mov    %al,-0x8(%rsp,%r9,1)
    3c11:	49 ff c1             	inc    %r9
    3c14:	eb cf                	jmp    3be5 <pqcrystals_kyber768_ref_poly_compress+0x11>
    3c16:	8a 44 24 f9          	mov    -0x7(%rsp),%al
    3c1a:	c0 e0 04             	shl    $0x4,%al
    3c1d:	0a 44 24 f8          	or     -0x8(%rsp),%al
    3c21:	88 07                	mov    %al,(%rdi)
    3c23:	8a 44 24 fb          	mov    -0x5(%rsp),%al
    3c27:	c0 e0 04             	shl    $0x4,%al
    3c2a:	0a 44 24 fa          	or     -0x6(%rsp),%al
    3c2e:	88 47 01             	mov    %al,0x1(%rdi)
    3c31:	8a 44 24 fd          	mov    -0x3(%rsp),%al
    3c35:	c0 e0 04             	shl    $0x4,%al
    3c38:	0a 44 24 fc          	or     -0x4(%rsp),%al
    3c3c:	88 47 02             	mov    %al,0x2(%rdi)
    3c3f:	8a 44 24 ff          	mov    -0x1(%rsp),%al
    3c43:	c0 e0 04             	shl    $0x4,%al
    3c46:	0a 44 24 fe          	or     -0x2(%rsp),%al
    3c4a:	88 47 03             	mov    %al,0x3(%rdi)
    3c4d:	48 83 c7 04          	add    $0x4,%rdi
    3c51:	48 ff c1             	inc    %rcx
    3c54:	48 83 c6 10          	add    $0x10,%rsi
    3c58:	eb 82                	jmp    3bdc <pqcrystals_kyber768_ref_poly_compress+0x8>
    3c5a:	c3                   	ret

Disassembly of section .fini:
