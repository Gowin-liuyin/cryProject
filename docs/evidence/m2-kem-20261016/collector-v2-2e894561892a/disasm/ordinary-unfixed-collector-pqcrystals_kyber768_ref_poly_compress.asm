
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000047f4 <pqcrystals_kyber768_ref_poly_compress>:
    47f4:	31 c9                	xor    %ecx,%ecx
    47f6:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    47fc:	48 83 f9 20          	cmp    $0x20,%rcx
    4800:	74 78                	je     487a <pqcrystals_kyber768_ref_poly_compress+0x86>
    4802:	45 31 c9             	xor    %r9d,%r9d
    4805:	49 83 f9 08          	cmp    $0x8,%r9
    4809:	74 2b                	je     4836 <pqcrystals_kyber768_ref_poly_compress+0x42>
    480b:	42 0f bf 04 4e       	movswl (%rsi,%r9,2),%eax
    4810:	89 c2                	mov    %eax,%edx
    4812:	c1 ea 0f             	shr    $0xf,%edx
    4815:	44 21 c2             	and    %r8d,%edx
    4818:	01 c2                	add    %eax,%edx
    481a:	0f b7 c2             	movzwl %dx,%eax
    481d:	c1 e0 04             	shl    $0x4,%eax
    4820:	05 80 06 00 00       	add    $0x680,%eax
    4825:	31 d2                	xor    %edx,%edx
    4827:	41 f7 f0             	div    %r8d
    482a:	24 0f                	and    $0xf,%al
    482c:	42 88 44 0c f8       	mov    %al,-0x8(%rsp,%r9,1)
    4831:	49 ff c1             	inc    %r9
    4834:	eb cf                	jmp    4805 <pqcrystals_kyber768_ref_poly_compress+0x11>
    4836:	8a 44 24 f9          	mov    -0x7(%rsp),%al
    483a:	c0 e0 04             	shl    $0x4,%al
    483d:	0a 44 24 f8          	or     -0x8(%rsp),%al
    4841:	88 07                	mov    %al,(%rdi)
    4843:	8a 44 24 fb          	mov    -0x5(%rsp),%al
    4847:	c0 e0 04             	shl    $0x4,%al
    484a:	0a 44 24 fa          	or     -0x6(%rsp),%al
    484e:	88 47 01             	mov    %al,0x1(%rdi)
    4851:	8a 44 24 fd          	mov    -0x3(%rsp),%al
    4855:	c0 e0 04             	shl    $0x4,%al
    4858:	0a 44 24 fc          	or     -0x4(%rsp),%al
    485c:	88 47 02             	mov    %al,0x2(%rdi)
    485f:	8a 44 24 ff          	mov    -0x1(%rsp),%al
    4863:	c0 e0 04             	shl    $0x4,%al
    4866:	0a 44 24 fe          	or     -0x2(%rsp),%al
    486a:	88 47 03             	mov    %al,0x3(%rdi)
    486d:	48 83 c7 04          	add    $0x4,%rdi
    4871:	48 ff c1             	inc    %rcx
    4874:	48 83 c6 10          	add    $0x10,%rsi
    4878:	eb 82                	jmp    47fc <pqcrystals_kyber768_ref_poly_compress+0x8>
    487a:	c3                   	ret

Disassembly of section .fini:
