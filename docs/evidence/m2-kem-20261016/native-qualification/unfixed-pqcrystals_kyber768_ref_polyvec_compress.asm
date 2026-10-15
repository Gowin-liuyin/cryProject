0000000000003880 <pqcrystals_kyber768_ref_polyvec_compress>:
    3880:	31 c9                	xor    %ecx,%ecx
    3882:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    3888:	48 83 f9 03          	cmp    $0x3,%rcx
    388c:	0f 84 ae 00 00 00    	je     3940 <pqcrystals_kyber768_ref_polyvec_compress+0xc0>
    3892:	49 89 f1             	mov    %rsi,%r9
    3895:	45 31 d2             	xor    %r10d,%r10d
    3898:	49 83 fa 40          	cmp    $0x40,%r10
    389c:	0f 84 8f 00 00 00    	je     3931 <pqcrystals_kyber768_ref_polyvec_compress+0xb1>
    38a2:	45 31 db             	xor    %r11d,%r11d
    38a5:	49 83 fb 04          	cmp    $0x4,%r11
    38a9:	74 2f                	je     38da <pqcrystals_kyber768_ref_polyvec_compress+0x5a>
    38ab:	43 0f bf 04 59       	movswl (%r9,%r11,2),%eax
    38b0:	89 c2                	mov    %eax,%edx
    38b2:	c1 ea 0f             	shr    $0xf,%edx
    38b5:	44 21 c2             	and    %r8d,%edx
    38b8:	01 c2                	add    %eax,%edx
    38ba:	0f b7 c2             	movzwl %dx,%eax
    38bd:	c1 e0 0a             	shl    $0xa,%eax
    38c0:	05 80 06 00 00       	add    $0x680,%eax
    38c5:	31 d2                	xor    %edx,%edx
    38c7:	41 f7 f0             	div    %r8d
    38ca:	25 ff 03 00 00       	and    $0x3ff,%eax
    38cf:	66 42 89 44 5c f8    	mov    %ax,-0x8(%rsp,%r11,2)
    38d5:	49 ff c3             	inc    %r11
    38d8:	eb cb                	jmp    38a5 <pqcrystals_kyber768_ref_polyvec_compress+0x25>
    38da:	8a 44 24 f8          	mov    -0x8(%rsp),%al
    38de:	88 07                	mov    %al,(%rdi)
    38e0:	8a 44 24 fa          	mov    -0x6(%rsp),%al
    38e4:	c0 e0 02             	shl    $0x2,%al
    38e7:	0a 44 24 f9          	or     -0x7(%rsp),%al
    38eb:	88 47 01             	mov    %al,0x1(%rdi)
    38ee:	0f b7 44 24 fa       	movzwl -0x6(%rsp),%eax
    38f3:	c1 e8 06             	shr    $0x6,%eax
    38f6:	8a 54 24 fc          	mov    -0x4(%rsp),%dl
    38fa:	c0 e2 04             	shl    $0x4,%dl
    38fd:	08 c2                	or     %al,%dl
    38ff:	88 57 02             	mov    %dl,0x2(%rdi)
    3902:	0f b7 44 24 fc       	movzwl -0x4(%rsp),%eax
    3907:	c1 e8 04             	shr    $0x4,%eax
    390a:	8a 54 24 fe          	mov    -0x2(%rsp),%dl
    390e:	c0 e2 06             	shl    $0x6,%dl
    3911:	08 c2                	or     %al,%dl
    3913:	88 57 03             	mov    %dl,0x3(%rdi)
    3916:	0f b7 44 24 fe       	movzwl -0x2(%rsp),%eax
    391b:	c1 e8 02             	shr    $0x2,%eax
    391e:	88 47 04             	mov    %al,0x4(%rdi)
    3921:	48 83 c7 05          	add    $0x5,%rdi
    3925:	49 ff c2             	inc    %r10
    3928:	49 83 c1 08          	add    $0x8,%r9
    392c:	e9 67 ff ff ff       	jmp    3898 <pqcrystals_kyber768_ref_polyvec_compress+0x18>
    3931:	48 ff c1             	inc    %rcx
    3934:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    393b:	e9 48 ff ff ff       	jmp    3888 <pqcrystals_kyber768_ref_polyvec_compress+0x8>
    3940:	c3                   	ret

