0000000000001a30 <pqcrystals_kyber768_ref_polyvec_compress>:
    1a30:	31 c0                	xor    %eax,%eax
    1a32:	b9 37 d5 09 80       	mov    $0x8009d537,%ecx
    1a37:	48 83 f8 03          	cmp    $0x3,%rax
    1a3b:	0f 84 ce 00 00 00    	je     1b0f <pqcrystals_kyber768_ref_polyvec_compress+0xdf>
    1a41:	48 89 f2             	mov    %rsi,%rdx
    1a44:	45 31 c0             	xor    %r8d,%r8d
    1a47:	49 83 f8 40          	cmp    $0x40,%r8
    1a4b:	0f 84 af 00 00 00    	je     1b00 <pqcrystals_kyber768_ref_polyvec_compress+0xd0>
    1a51:	45 31 c9             	xor    %r9d,%r9d
    1a54:	49 83 f9 04          	cmp    $0x4,%r9
    1a58:	74 3a                	je     1a94 <pqcrystals_kyber768_ref_polyvec_compress+0x64>
    1a5a:	46 0f bf 14 4a       	movswl (%rdx,%r9,2),%r10d
    1a5f:	45 89 d3             	mov    %r10d,%r11d
    1a62:	41 c1 eb 0f          	shr    $0xf,%r11d
    1a66:	41 81 e3 01 0d 00 00 	and    $0xd01,%r11d
    1a6d:	45 01 d3             	add    %r10d,%r11d
    1a70:	45 0f b7 d3          	movzwl %r11w,%r10d
    1a74:	4d 69 d2 00 dc be 4e 	imul   $0x4ebedc00,%r10,%r10
    1a7b:	49 01 ca             	add    %rcx,%r10
    1a7e:	49 c1 ea 20          	shr    $0x20,%r10
    1a82:	41 81 e2 ff 03 00 00 	and    $0x3ff,%r10d
    1a89:	66 46 89 54 4c f8    	mov    %r10w,-0x8(%rsp,%r9,2)
    1a8f:	49 ff c1             	inc    %r9
    1a92:	eb c0                	jmp    1a54 <pqcrystals_kyber768_ref_polyvec_compress+0x24>
    1a94:	44 8a 4c 24 f8       	mov    -0x8(%rsp),%r9b
    1a99:	44 88 0f             	mov    %r9b,(%rdi)
    1a9c:	44 8a 4c 24 fa       	mov    -0x6(%rsp),%r9b
    1aa1:	41 c0 e1 02          	shl    $0x2,%r9b
    1aa5:	44 0a 4c 24 f9       	or     -0x7(%rsp),%r9b
    1aaa:	44 88 4f 01          	mov    %r9b,0x1(%rdi)
    1aae:	44 0f b7 4c 24 fa    	movzwl -0x6(%rsp),%r9d
    1ab4:	41 c1 e9 06          	shr    $0x6,%r9d
    1ab8:	44 8a 54 24 fc       	mov    -0x4(%rsp),%r10b
    1abd:	41 c0 e2 04          	shl    $0x4,%r10b
    1ac1:	45 08 ca             	or     %r9b,%r10b
    1ac4:	44 88 57 02          	mov    %r10b,0x2(%rdi)
    1ac8:	44 0f b7 4c 24 fc    	movzwl -0x4(%rsp),%r9d
    1ace:	41 c1 e9 04          	shr    $0x4,%r9d
    1ad2:	44 8a 54 24 fe       	mov    -0x2(%rsp),%r10b
    1ad7:	41 c0 e2 06          	shl    $0x6,%r10b
    1adb:	45 08 ca             	or     %r9b,%r10b
    1ade:	44 88 57 03          	mov    %r10b,0x3(%rdi)
    1ae2:	44 0f b7 4c 24 fe    	movzwl -0x2(%rsp),%r9d
    1ae8:	41 c1 e9 02          	shr    $0x2,%r9d
    1aec:	44 88 4f 04          	mov    %r9b,0x4(%rdi)
    1af0:	48 83 c7 05          	add    $0x5,%rdi
    1af4:	49 ff c0             	inc    %r8
    1af7:	48 83 c2 08          	add    $0x8,%rdx
    1afb:	e9 47 ff ff ff       	jmp    1a47 <pqcrystals_kyber768_ref_polyvec_compress+0x17>
    1b00:	48 ff c0             	inc    %rax
    1b03:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    1b0a:	e9 28 ff ff ff       	jmp    1a37 <pqcrystals_kyber768_ref_polyvec_compress+0x7>
    1b0f:	c3                   	ret

