0000000000001a38 <pqcrystals_kyber768_ref_polyvec_compress>:
    1a38:	31 c9                	xor    %ecx,%ecx
    1a3a:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    1a40:	48 83 f9 03          	cmp    $0x3,%rcx
    1a44:	0f 84 ae 00 00 00    	je     1af8 <pqcrystals_kyber768_ref_polyvec_compress+0xc0>
    1a4a:	49 89 f1             	mov    %rsi,%r9
    1a4d:	45 31 d2             	xor    %r10d,%r10d
    1a50:	49 83 fa 40          	cmp    $0x40,%r10
    1a54:	0f 84 8f 00 00 00    	je     1ae9 <pqcrystals_kyber768_ref_polyvec_compress+0xb1>
    1a5a:	45 31 db             	xor    %r11d,%r11d
    1a5d:	49 83 fb 04          	cmp    $0x4,%r11
    1a61:	74 2f                	je     1a92 <pqcrystals_kyber768_ref_polyvec_compress+0x5a>
    1a63:	43 0f bf 04 59       	movswl (%r9,%r11,2),%eax
    1a68:	89 c2                	mov    %eax,%edx
    1a6a:	c1 ea 0f             	shr    $0xf,%edx
    1a6d:	44 21 c2             	and    %r8d,%edx
    1a70:	01 c2                	add    %eax,%edx
    1a72:	0f b7 c2             	movzwl %dx,%eax
    1a75:	c1 e0 0a             	shl    $0xa,%eax
    1a78:	05 80 06 00 00       	add    $0x680,%eax
    1a7d:	31 d2                	xor    %edx,%edx
    1a7f:	41 f7 f0             	div    %r8d
    1a82:	25 ff 03 00 00       	and    $0x3ff,%eax
    1a87:	66 42 89 44 5c f8    	mov    %ax,-0x8(%rsp,%r11,2)
    1a8d:	49 ff c3             	inc    %r11
    1a90:	eb cb                	jmp    1a5d <pqcrystals_kyber768_ref_polyvec_compress+0x25>
    1a92:	8a 44 24 f8          	mov    -0x8(%rsp),%al
    1a96:	88 07                	mov    %al,(%rdi)
    1a98:	8a 44 24 fa          	mov    -0x6(%rsp),%al
    1a9c:	c0 e0 02             	shl    $0x2,%al
    1a9f:	0a 44 24 f9          	or     -0x7(%rsp),%al
    1aa3:	88 47 01             	mov    %al,0x1(%rdi)
    1aa6:	0f b7 44 24 fa       	movzwl -0x6(%rsp),%eax
    1aab:	c1 e8 06             	shr    $0x6,%eax
    1aae:	8a 54 24 fc          	mov    -0x4(%rsp),%dl
    1ab2:	c0 e2 04             	shl    $0x4,%dl
    1ab5:	08 c2                	or     %al,%dl
    1ab7:	88 57 02             	mov    %dl,0x2(%rdi)
    1aba:	0f b7 44 24 fc       	movzwl -0x4(%rsp),%eax
    1abf:	c1 e8 04             	shr    $0x4,%eax
    1ac2:	8a 54 24 fe          	mov    -0x2(%rsp),%dl
    1ac6:	c0 e2 06             	shl    $0x6,%dl
    1ac9:	08 c2                	or     %al,%dl
    1acb:	88 57 03             	mov    %dl,0x3(%rdi)
    1ace:	0f b7 44 24 fe       	movzwl -0x2(%rsp),%eax
    1ad3:	c1 e8 02             	shr    $0x2,%eax
    1ad6:	88 47 04             	mov    %al,0x4(%rdi)
    1ad9:	48 83 c7 05          	add    $0x5,%rdi
    1add:	49 ff c2             	inc    %r10
    1ae0:	49 83 c1 08          	add    $0x8,%r9
    1ae4:	e9 67 ff ff ff       	jmp    1a50 <pqcrystals_kyber768_ref_polyvec_compress+0x18>
    1ae9:	48 ff c1             	inc    %rcx
    1aec:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    1af3:	e9 48 ff ff ff       	jmp    1a40 <pqcrystals_kyber768_ref_polyvec_compress+0x8>
    1af8:	c3                   	ret

