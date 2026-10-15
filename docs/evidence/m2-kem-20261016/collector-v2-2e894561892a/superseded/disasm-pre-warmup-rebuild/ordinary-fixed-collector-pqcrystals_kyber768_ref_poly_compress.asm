
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000004764 <pqcrystals_kyber768_ref_poly_compress>:
    4764:	31 c0                	xor    %eax,%eax
    4766:	48 83 f8 20          	cmp    $0x20,%rax
    476a:	0f 84 80 00 00 00    	je     47f0 <pqcrystals_kyber768_ref_poly_compress+0x8c>
    4770:	31 c9                	xor    %ecx,%ecx
    4772:	48 83 f9 08          	cmp    $0x8,%rcx
    4776:	74 31                	je     47a9 <pqcrystals_kyber768_ref_poly_compress+0x45>
    4778:	0f bf 14 4e          	movswl (%rsi,%rcx,2),%edx
    477c:	41 89 d0             	mov    %edx,%r8d
    477f:	41 c1 e8 0f          	shr    $0xf,%r8d
    4783:	41 81 e0 01 0d 00 00 	and    $0xd01,%r8d
    478a:	41 01 d0             	add    %edx,%r8d
    478d:	41 0f bf d0          	movswl %r8w,%edx
    4791:	69 d2 b0 af 13 00    	imul   $0x13afb0,%edx,%edx
    4797:	81 c2 7b 9a 00 08    	add    $0x8009a7b,%edx
    479d:	c1 ea 1c             	shr    $0x1c,%edx
    47a0:	88 54 0c f8          	mov    %dl,-0x8(%rsp,%rcx,1)
    47a4:	48 ff c1             	inc    %rcx
    47a7:	eb c9                	jmp    4772 <pqcrystals_kyber768_ref_poly_compress+0xe>
    47a9:	8a 4c 24 f9          	mov    -0x7(%rsp),%cl
    47ad:	c0 e1 04             	shl    $0x4,%cl
    47b0:	0a 4c 24 f8          	or     -0x8(%rsp),%cl
    47b4:	88 0f                	mov    %cl,(%rdi)
    47b6:	8a 4c 24 fb          	mov    -0x5(%rsp),%cl
    47ba:	c0 e1 04             	shl    $0x4,%cl
    47bd:	0a 4c 24 fa          	or     -0x6(%rsp),%cl
    47c1:	88 4f 01             	mov    %cl,0x1(%rdi)
    47c4:	8a 4c 24 fd          	mov    -0x3(%rsp),%cl
    47c8:	c0 e1 04             	shl    $0x4,%cl
    47cb:	0a 4c 24 fc          	or     -0x4(%rsp),%cl
    47cf:	88 4f 02             	mov    %cl,0x2(%rdi)
    47d2:	8a 4c 24 ff          	mov    -0x1(%rsp),%cl
    47d6:	c0 e1 04             	shl    $0x4,%cl
    47d9:	0a 4c 24 fe          	or     -0x2(%rsp),%cl
    47dd:	88 4f 03             	mov    %cl,0x3(%rdi)
    47e0:	48 83 c7 04          	add    $0x4,%rdi
    47e4:	48 ff c0             	inc    %rax
    47e7:	48 83 c6 10          	add    $0x10,%rsi
    47eb:	e9 76 ff ff ff       	jmp    4766 <pqcrystals_kyber768_ref_poly_compress+0x2>
    47f0:	c3                   	ret

Disassembly of section .fini:
