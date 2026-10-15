00000000000034f0 <pqcrystals_kyber768_ref_poly_compress>:
    34f0:	31 c9                	xor    %ecx,%ecx
    34f2:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    34f8:	48 83 f9 20          	cmp    $0x20,%rcx
    34fc:	74 78                	je     3576 <pqcrystals_kyber768_ref_poly_compress+0x86>
    34fe:	45 31 c9             	xor    %r9d,%r9d
    3501:	49 83 f9 08          	cmp    $0x8,%r9
    3505:	74 2b                	je     3532 <pqcrystals_kyber768_ref_poly_compress+0x42>
    3507:	42 0f bf 04 4e       	movswl (%rsi,%r9,2),%eax
    350c:	89 c2                	mov    %eax,%edx
    350e:	c1 ea 0f             	shr    $0xf,%edx
    3511:	44 21 c2             	and    %r8d,%edx
    3514:	01 c2                	add    %eax,%edx
    3516:	0f b7 c2             	movzwl %dx,%eax
    3519:	c1 e0 04             	shl    $0x4,%eax
    351c:	05 80 06 00 00       	add    $0x680,%eax
    3521:	31 d2                	xor    %edx,%edx
    3523:	41 f7 f0             	div    %r8d
    3526:	24 0f                	and    $0xf,%al
    3528:	42 88 44 0c f8       	mov    %al,-0x8(%rsp,%r9,1)
    352d:	49 ff c1             	inc    %r9
    3530:	eb cf                	jmp    3501 <pqcrystals_kyber768_ref_poly_compress+0x11>
    3532:	8a 44 24 f9          	mov    -0x7(%rsp),%al
    3536:	c0 e0 04             	shl    $0x4,%al
    3539:	0a 44 24 f8          	or     -0x8(%rsp),%al
    353d:	88 07                	mov    %al,(%rdi)
    353f:	8a 44 24 fb          	mov    -0x5(%rsp),%al
    3543:	c0 e0 04             	shl    $0x4,%al
    3546:	0a 44 24 fa          	or     -0x6(%rsp),%al
    354a:	88 47 01             	mov    %al,0x1(%rdi)
    354d:	8a 44 24 fd          	mov    -0x3(%rsp),%al
    3551:	c0 e0 04             	shl    $0x4,%al
    3554:	0a 44 24 fc          	or     -0x4(%rsp),%al
    3558:	88 47 02             	mov    %al,0x2(%rdi)
    355b:	8a 44 24 ff          	mov    -0x1(%rsp),%al
    355f:	c0 e0 04             	shl    $0x4,%al
    3562:	0a 44 24 fe          	or     -0x2(%rsp),%al
    3566:	88 47 03             	mov    %al,0x3(%rdi)
    3569:	48 83 c7 04          	add    $0x4,%rdi
    356d:	48 ff c1             	inc    %rcx
    3570:	48 83 c6 10          	add    $0x10,%rsi
    3574:	eb 82                	jmp    34f8 <pqcrystals_kyber768_ref_poly_compress+0x8>
    3576:	c3                   	ret

