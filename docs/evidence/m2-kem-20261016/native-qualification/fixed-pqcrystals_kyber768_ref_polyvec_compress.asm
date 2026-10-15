0000000000003878 <pqcrystals_kyber768_ref_polyvec_compress>:
    3878:	31 c0                	xor    %eax,%eax
    387a:	b9 37 d5 09 80       	mov    $0x8009d537,%ecx
    387f:	48 83 f8 03          	cmp    $0x3,%rax
    3883:	0f 84 ce 00 00 00    	je     3957 <pqcrystals_kyber768_ref_polyvec_compress+0xdf>
    3889:	48 89 f2             	mov    %rsi,%rdx
    388c:	45 31 c0             	xor    %r8d,%r8d
    388f:	49 83 f8 40          	cmp    $0x40,%r8
    3893:	0f 84 af 00 00 00    	je     3948 <pqcrystals_kyber768_ref_polyvec_compress+0xd0>
    3899:	45 31 c9             	xor    %r9d,%r9d
    389c:	49 83 f9 04          	cmp    $0x4,%r9
    38a0:	74 3a                	je     38dc <pqcrystals_kyber768_ref_polyvec_compress+0x64>
    38a2:	46 0f bf 14 4a       	movswl (%rdx,%r9,2),%r10d
    38a7:	45 89 d3             	mov    %r10d,%r11d
    38aa:	41 c1 eb 0f          	shr    $0xf,%r11d
    38ae:	41 81 e3 01 0d 00 00 	and    $0xd01,%r11d
    38b5:	45 01 d3             	add    %r10d,%r11d
    38b8:	45 0f b7 d3          	movzwl %r11w,%r10d
    38bc:	4d 69 d2 00 dc be 4e 	imul   $0x4ebedc00,%r10,%r10
    38c3:	49 01 ca             	add    %rcx,%r10
    38c6:	49 c1 ea 20          	shr    $0x20,%r10
    38ca:	41 81 e2 ff 03 00 00 	and    $0x3ff,%r10d
    38d1:	66 46 89 54 4c f8    	mov    %r10w,-0x8(%rsp,%r9,2)
    38d7:	49 ff c1             	inc    %r9
    38da:	eb c0                	jmp    389c <pqcrystals_kyber768_ref_polyvec_compress+0x24>
    38dc:	44 8a 4c 24 f8       	mov    -0x8(%rsp),%r9b
    38e1:	44 88 0f             	mov    %r9b,(%rdi)
    38e4:	44 8a 4c 24 fa       	mov    -0x6(%rsp),%r9b
    38e9:	41 c0 e1 02          	shl    $0x2,%r9b
    38ed:	44 0a 4c 24 f9       	or     -0x7(%rsp),%r9b
    38f2:	44 88 4f 01          	mov    %r9b,0x1(%rdi)
    38f6:	44 0f b7 4c 24 fa    	movzwl -0x6(%rsp),%r9d
    38fc:	41 c1 e9 06          	shr    $0x6,%r9d
    3900:	44 8a 54 24 fc       	mov    -0x4(%rsp),%r10b
    3905:	41 c0 e2 04          	shl    $0x4,%r10b
    3909:	45 08 ca             	or     %r9b,%r10b
    390c:	44 88 57 02          	mov    %r10b,0x2(%rdi)
    3910:	44 0f b7 4c 24 fc    	movzwl -0x4(%rsp),%r9d
    3916:	41 c1 e9 04          	shr    $0x4,%r9d
    391a:	44 8a 54 24 fe       	mov    -0x2(%rsp),%r10b
    391f:	41 c0 e2 06          	shl    $0x6,%r10b
    3923:	45 08 ca             	or     %r9b,%r10b
    3926:	44 88 57 03          	mov    %r10b,0x3(%rdi)
    392a:	44 0f b7 4c 24 fe    	movzwl -0x2(%rsp),%r9d
    3930:	41 c1 e9 02          	shr    $0x2,%r9d
    3934:	44 88 4f 04          	mov    %r9b,0x4(%rdi)
    3938:	48 83 c7 05          	add    $0x5,%rdi
    393c:	49 ff c0             	inc    %r8
    393f:	48 83 c2 08          	add    $0x8,%rdx
    3943:	e9 47 ff ff ff       	jmp    388f <pqcrystals_kyber768_ref_polyvec_compress+0x17>
    3948:	48 ff c0             	inc    %rax
    394b:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    3952:	e9 28 ff ff ff       	jmp    387f <pqcrystals_kyber768_ref_polyvec_compress+0x7>
    3957:	c3                   	ret

