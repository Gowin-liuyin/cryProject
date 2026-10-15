00000000000016a8 <pqcrystals_kyber768_ref_poly_compress>:
    16a8:	31 c0                	xor    %eax,%eax
    16aa:	48 83 f8 20          	cmp    $0x20,%rax
    16ae:	0f 84 80 00 00 00    	je     1734 <pqcrystals_kyber768_ref_poly_compress+0x8c>
    16b4:	31 c9                	xor    %ecx,%ecx
    16b6:	48 83 f9 08          	cmp    $0x8,%rcx
    16ba:	74 31                	je     16ed <pqcrystals_kyber768_ref_poly_compress+0x45>
    16bc:	0f bf 14 4e          	movswl (%rsi,%rcx,2),%edx
    16c0:	41 89 d0             	mov    %edx,%r8d
    16c3:	41 c1 e8 0f          	shr    $0xf,%r8d
    16c7:	41 81 e0 01 0d 00 00 	and    $0xd01,%r8d
    16ce:	41 01 d0             	add    %edx,%r8d
    16d1:	41 0f bf d0          	movswl %r8w,%edx
    16d5:	69 d2 b0 af 13 00    	imul   $0x13afb0,%edx,%edx
    16db:	81 c2 7b 9a 00 08    	add    $0x8009a7b,%edx
    16e1:	c1 ea 1c             	shr    $0x1c,%edx
    16e4:	88 54 0c f8          	mov    %dl,-0x8(%rsp,%rcx,1)
    16e8:	48 ff c1             	inc    %rcx
    16eb:	eb c9                	jmp    16b6 <pqcrystals_kyber768_ref_poly_compress+0xe>
    16ed:	8a 4c 24 f9          	mov    -0x7(%rsp),%cl
    16f1:	c0 e1 04             	shl    $0x4,%cl
    16f4:	0a 4c 24 f8          	or     -0x8(%rsp),%cl
    16f8:	88 0f                	mov    %cl,(%rdi)
    16fa:	8a 4c 24 fb          	mov    -0x5(%rsp),%cl
    16fe:	c0 e1 04             	shl    $0x4,%cl
    1701:	0a 4c 24 fa          	or     -0x6(%rsp),%cl
    1705:	88 4f 01             	mov    %cl,0x1(%rdi)
    1708:	8a 4c 24 fd          	mov    -0x3(%rsp),%cl
    170c:	c0 e1 04             	shl    $0x4,%cl
    170f:	0a 4c 24 fc          	or     -0x4(%rsp),%cl
    1713:	88 4f 02             	mov    %cl,0x2(%rdi)
    1716:	8a 4c 24 ff          	mov    -0x1(%rsp),%cl
    171a:	c0 e1 04             	shl    $0x4,%cl
    171d:	0a 4c 24 fe          	or     -0x2(%rsp),%cl
    1721:	88 4f 03             	mov    %cl,0x3(%rdi)
    1724:	48 83 c7 04          	add    $0x4,%rdi
    1728:	48 ff c0             	inc    %rax
    172b:	48 83 c6 10          	add    $0x10,%rsi
    172f:	e9 76 ff ff ff       	jmp    16aa <pqcrystals_kyber768_ref_poly_compress+0x2>
    1734:	c3                   	ret

