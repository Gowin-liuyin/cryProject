
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/qualification/fixed/m2_hotspot_qualification：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000004614 <pqcrystals_kyber768_ref_poly_compress>:
    4614:	31 c0                	xor    %eax,%eax
    4616:	48 83 f8 20          	cmp    $0x20,%rax
    461a:	0f 84 80 00 00 00    	je     46a0 <pqcrystals_kyber768_ref_poly_compress+0x8c>
    4620:	31 c9                	xor    %ecx,%ecx
    4622:	48 83 f9 08          	cmp    $0x8,%rcx
    4626:	74 31                	je     4659 <pqcrystals_kyber768_ref_poly_compress+0x45>
    4628:	0f bf 14 4e          	movswl (%rsi,%rcx,2),%edx
    462c:	41 89 d0             	mov    %edx,%r8d
    462f:	41 c1 e8 0f          	shr    $0xf,%r8d
    4633:	41 81 e0 01 0d 00 00 	and    $0xd01,%r8d
    463a:	41 01 d0             	add    %edx,%r8d
    463d:	41 0f bf d0          	movswl %r8w,%edx
    4641:	69 d2 b0 af 13 00    	imul   $0x13afb0,%edx,%edx
    4647:	81 c2 7b 9a 00 08    	add    $0x8009a7b,%edx
    464d:	c1 ea 1c             	shr    $0x1c,%edx
    4650:	88 54 0c f8          	mov    %dl,-0x8(%rsp,%rcx,1)
    4654:	48 ff c1             	inc    %rcx
    4657:	eb c9                	jmp    4622 <pqcrystals_kyber768_ref_poly_compress+0xe>
    4659:	8a 4c 24 f9          	mov    -0x7(%rsp),%cl
    465d:	c0 e1 04             	shl    $0x4,%cl
    4660:	0a 4c 24 f8          	or     -0x8(%rsp),%cl
    4664:	88 0f                	mov    %cl,(%rdi)
    4666:	8a 4c 24 fb          	mov    -0x5(%rsp),%cl
    466a:	c0 e1 04             	shl    $0x4,%cl
    466d:	0a 4c 24 fa          	or     -0x6(%rsp),%cl
    4671:	88 4f 01             	mov    %cl,0x1(%rdi)
    4674:	8a 4c 24 fd          	mov    -0x3(%rsp),%cl
    4678:	c0 e1 04             	shl    $0x4,%cl
    467b:	0a 4c 24 fc          	or     -0x4(%rsp),%cl
    467f:	88 4f 02             	mov    %cl,0x2(%rdi)
    4682:	8a 4c 24 ff          	mov    -0x1(%rsp),%cl
    4686:	c0 e1 04             	shl    $0x4,%cl
    4689:	0a 4c 24 fe          	or     -0x2(%rsp),%cl
    468d:	88 4f 03             	mov    %cl,0x3(%rdi)
    4690:	48 83 c7 04          	add    $0x4,%rdi
    4694:	48 ff c0             	inc    %rax
    4697:	48 83 c6 10          	add    $0x10,%rsi
    469b:	e9 76 ff ff ff       	jmp    4616 <pqcrystals_kyber768_ref_poly_compress+0x2>
    46a0:	c3                   	ret

Disassembly of section .fini:
