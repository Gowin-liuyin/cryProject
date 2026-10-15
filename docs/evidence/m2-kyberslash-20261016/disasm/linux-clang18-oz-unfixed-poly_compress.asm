00000000000016a8 <pqcrystals_kyber768_ref_poly_compress>:
    16a8:	31 c9                	xor    %ecx,%ecx
    16aa:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    16b0:	48 83 f9 20          	cmp    $0x20,%rcx
    16b4:	74 78                	je     172e <pqcrystals_kyber768_ref_poly_compress+0x86>
    16b6:	45 31 c9             	xor    %r9d,%r9d
    16b9:	49 83 f9 08          	cmp    $0x8,%r9
    16bd:	74 2b                	je     16ea <pqcrystals_kyber768_ref_poly_compress+0x42>
    16bf:	42 0f bf 04 4e       	movswl (%rsi,%r9,2),%eax
    16c4:	89 c2                	mov    %eax,%edx
    16c6:	c1 ea 0f             	shr    $0xf,%edx
    16c9:	44 21 c2             	and    %r8d,%edx
    16cc:	01 c2                	add    %eax,%edx
    16ce:	0f b7 c2             	movzwl %dx,%eax
    16d1:	c1 e0 04             	shl    $0x4,%eax
    16d4:	05 80 06 00 00       	add    $0x680,%eax
    16d9:	31 d2                	xor    %edx,%edx
    16db:	41 f7 f0             	div    %r8d
    16de:	24 0f                	and    $0xf,%al
    16e0:	42 88 44 0c f8       	mov    %al,-0x8(%rsp,%r9,1)
    16e5:	49 ff c1             	inc    %r9
    16e8:	eb cf                	jmp    16b9 <pqcrystals_kyber768_ref_poly_compress+0x11>
    16ea:	8a 44 24 f9          	mov    -0x7(%rsp),%al
    16ee:	c0 e0 04             	shl    $0x4,%al
    16f1:	0a 44 24 f8          	or     -0x8(%rsp),%al
    16f5:	88 07                	mov    %al,(%rdi)
    16f7:	8a 44 24 fb          	mov    -0x5(%rsp),%al
    16fb:	c0 e0 04             	shl    $0x4,%al
    16fe:	0a 44 24 fa          	or     -0x6(%rsp),%al
    1702:	88 47 01             	mov    %al,0x1(%rdi)
    1705:	8a 44 24 fd          	mov    -0x3(%rsp),%al
    1709:	c0 e0 04             	shl    $0x4,%al
    170c:	0a 44 24 fc          	or     -0x4(%rsp),%al
    1710:	88 47 02             	mov    %al,0x2(%rdi)
    1713:	8a 44 24 ff          	mov    -0x1(%rsp),%al
    1717:	c0 e0 04             	shl    $0x4,%al
    171a:	0a 44 24 fe          	or     -0x2(%rsp),%al
    171e:	88 47 03             	mov    %al,0x3(%rdi)
    1721:	48 83 c7 04          	add    $0x4,%rdi
    1725:	48 ff c1             	inc    %rcx
    1728:	48 83 c6 10          	add    $0x10,%rsi
    172c:	eb 82                	jmp    16b0 <pqcrystals_kyber768_ref_poly_compress+0x8>
    172e:	c3                   	ret

