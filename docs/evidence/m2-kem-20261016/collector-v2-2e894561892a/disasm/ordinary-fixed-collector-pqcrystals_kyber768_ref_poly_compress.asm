
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000047f4 <pqcrystals_kyber768_ref_poly_compress>:
    47f4:	31 c0                	xor    %eax,%eax
    47f6:	48 83 f8 20          	cmp    $0x20,%rax
    47fa:	0f 84 80 00 00 00    	je     4880 <pqcrystals_kyber768_ref_poly_compress+0x8c>
    4800:	31 c9                	xor    %ecx,%ecx
    4802:	48 83 f9 08          	cmp    $0x8,%rcx
    4806:	74 31                	je     4839 <pqcrystals_kyber768_ref_poly_compress+0x45>
    4808:	0f bf 14 4e          	movswl (%rsi,%rcx,2),%edx
    480c:	41 89 d0             	mov    %edx,%r8d
    480f:	41 c1 e8 0f          	shr    $0xf,%r8d
    4813:	41 81 e0 01 0d 00 00 	and    $0xd01,%r8d
    481a:	41 01 d0             	add    %edx,%r8d
    481d:	41 0f bf d0          	movswl %r8w,%edx
    4821:	69 d2 b0 af 13 00    	imul   $0x13afb0,%edx,%edx
    4827:	81 c2 7b 9a 00 08    	add    $0x8009a7b,%edx
    482d:	c1 ea 1c             	shr    $0x1c,%edx
    4830:	88 54 0c f8          	mov    %dl,-0x8(%rsp,%rcx,1)
    4834:	48 ff c1             	inc    %rcx
    4837:	eb c9                	jmp    4802 <pqcrystals_kyber768_ref_poly_compress+0xe>
    4839:	8a 4c 24 f9          	mov    -0x7(%rsp),%cl
    483d:	c0 e1 04             	shl    $0x4,%cl
    4840:	0a 4c 24 f8          	or     -0x8(%rsp),%cl
    4844:	88 0f                	mov    %cl,(%rdi)
    4846:	8a 4c 24 fb          	mov    -0x5(%rsp),%cl
    484a:	c0 e1 04             	shl    $0x4,%cl
    484d:	0a 4c 24 fa          	or     -0x6(%rsp),%cl
    4851:	88 4f 01             	mov    %cl,0x1(%rdi)
    4854:	8a 4c 24 fd          	mov    -0x3(%rsp),%cl
    4858:	c0 e1 04             	shl    $0x4,%cl
    485b:	0a 4c 24 fc          	or     -0x4(%rsp),%cl
    485f:	88 4f 02             	mov    %cl,0x2(%rdi)
    4862:	8a 4c 24 ff          	mov    -0x1(%rsp),%cl
    4866:	c0 e1 04             	shl    $0x4,%cl
    4869:	0a 4c 24 fe          	or     -0x2(%rsp),%cl
    486d:	88 4f 03             	mov    %cl,0x3(%rdi)
    4870:	48 83 c7 04          	add    $0x4,%rdi
    4874:	48 ff c0             	inc    %rax
    4877:	48 83 c6 10          	add    $0x10,%rsi
    487b:	e9 76 ff ff ff       	jmp    47f6 <pqcrystals_kyber768_ref_poly_compress+0x2>
    4880:	c3                   	ret

Disassembly of section .fini:
