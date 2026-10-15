
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/qualification/unfixed/m2_hotspot_qualification：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000004614 <pqcrystals_kyber768_ref_poly_compress>:
    4614:	31 c9                	xor    %ecx,%ecx
    4616:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    461c:	48 83 f9 20          	cmp    $0x20,%rcx
    4620:	74 78                	je     469a <pqcrystals_kyber768_ref_poly_compress+0x86>
    4622:	45 31 c9             	xor    %r9d,%r9d
    4625:	49 83 f9 08          	cmp    $0x8,%r9
    4629:	74 2b                	je     4656 <pqcrystals_kyber768_ref_poly_compress+0x42>
    462b:	42 0f bf 04 4e       	movswl (%rsi,%r9,2),%eax
    4630:	89 c2                	mov    %eax,%edx
    4632:	c1 ea 0f             	shr    $0xf,%edx
    4635:	44 21 c2             	and    %r8d,%edx
    4638:	01 c2                	add    %eax,%edx
    463a:	0f b7 c2             	movzwl %dx,%eax
    463d:	c1 e0 04             	shl    $0x4,%eax
    4640:	05 80 06 00 00       	add    $0x680,%eax
    4645:	31 d2                	xor    %edx,%edx
    4647:	41 f7 f0             	div    %r8d
    464a:	24 0f                	and    $0xf,%al
    464c:	42 88 44 0c f8       	mov    %al,-0x8(%rsp,%r9,1)
    4651:	49 ff c1             	inc    %r9
    4654:	eb cf                	jmp    4625 <pqcrystals_kyber768_ref_poly_compress+0x11>
    4656:	8a 44 24 f9          	mov    -0x7(%rsp),%al
    465a:	c0 e0 04             	shl    $0x4,%al
    465d:	0a 44 24 f8          	or     -0x8(%rsp),%al
    4661:	88 07                	mov    %al,(%rdi)
    4663:	8a 44 24 fb          	mov    -0x5(%rsp),%al
    4667:	c0 e0 04             	shl    $0x4,%al
    466a:	0a 44 24 fa          	or     -0x6(%rsp),%al
    466e:	88 47 01             	mov    %al,0x1(%rdi)
    4671:	8a 44 24 fd          	mov    -0x3(%rsp),%al
    4675:	c0 e0 04             	shl    $0x4,%al
    4678:	0a 44 24 fc          	or     -0x4(%rsp),%al
    467c:	88 47 02             	mov    %al,0x2(%rdi)
    467f:	8a 44 24 ff          	mov    -0x1(%rsp),%al
    4683:	c0 e0 04             	shl    $0x4,%al
    4686:	0a 44 24 fe          	or     -0x2(%rsp),%al
    468a:	88 47 03             	mov    %al,0x3(%rdi)
    468d:	48 83 c7 04          	add    $0x4,%rdi
    4691:	48 ff c1             	inc    %rcx
    4694:	48 83 c6 10          	add    $0x10,%rsi
    4698:	eb 82                	jmp    461c <pqcrystals_kyber768_ref_poly_compress+0x8>
    469a:	c3                   	ret

Disassembly of section .fini:
