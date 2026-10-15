
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000004764 <pqcrystals_kyber768_ref_poly_compress>:
    4764:	31 c9                	xor    %ecx,%ecx
    4766:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    476c:	48 83 f9 20          	cmp    $0x20,%rcx
    4770:	74 78                	je     47ea <pqcrystals_kyber768_ref_poly_compress+0x86>
    4772:	45 31 c9             	xor    %r9d,%r9d
    4775:	49 83 f9 08          	cmp    $0x8,%r9
    4779:	74 2b                	je     47a6 <pqcrystals_kyber768_ref_poly_compress+0x42>
    477b:	42 0f bf 04 4e       	movswl (%rsi,%r9,2),%eax
    4780:	89 c2                	mov    %eax,%edx
    4782:	c1 ea 0f             	shr    $0xf,%edx
    4785:	44 21 c2             	and    %r8d,%edx
    4788:	01 c2                	add    %eax,%edx
    478a:	0f b7 c2             	movzwl %dx,%eax
    478d:	c1 e0 04             	shl    $0x4,%eax
    4790:	05 80 06 00 00       	add    $0x680,%eax
    4795:	31 d2                	xor    %edx,%edx
    4797:	41 f7 f0             	div    %r8d
    479a:	24 0f                	and    $0xf,%al
    479c:	42 88 44 0c f8       	mov    %al,-0x8(%rsp,%r9,1)
    47a1:	49 ff c1             	inc    %r9
    47a4:	eb cf                	jmp    4775 <pqcrystals_kyber768_ref_poly_compress+0x11>
    47a6:	8a 44 24 f9          	mov    -0x7(%rsp),%al
    47aa:	c0 e0 04             	shl    $0x4,%al
    47ad:	0a 44 24 f8          	or     -0x8(%rsp),%al
    47b1:	88 07                	mov    %al,(%rdi)
    47b3:	8a 44 24 fb          	mov    -0x5(%rsp),%al
    47b7:	c0 e0 04             	shl    $0x4,%al
    47ba:	0a 44 24 fa          	or     -0x6(%rsp),%al
    47be:	88 47 01             	mov    %al,0x1(%rdi)
    47c1:	8a 44 24 fd          	mov    -0x3(%rsp),%al
    47c5:	c0 e0 04             	shl    $0x4,%al
    47c8:	0a 44 24 fc          	or     -0x4(%rsp),%al
    47cc:	88 47 02             	mov    %al,0x2(%rdi)
    47cf:	8a 44 24 ff          	mov    -0x1(%rsp),%al
    47d3:	c0 e0 04             	shl    $0x4,%al
    47d6:	0a 44 24 fe          	or     -0x2(%rsp),%al
    47da:	88 47 03             	mov    %al,0x3(%rdi)
    47dd:	48 83 c7 04          	add    $0x4,%rdi
    47e1:	48 ff c1             	inc    %rcx
    47e4:	48 83 c6 10          	add    $0x10,%rsi
    47e8:	eb 82                	jmp    476c <pqcrystals_kyber768_ref_poly_compress+0x8>
    47ea:	c3                   	ret

Disassembly of section .fini:
