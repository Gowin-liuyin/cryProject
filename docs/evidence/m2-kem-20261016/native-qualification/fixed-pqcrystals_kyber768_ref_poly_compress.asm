00000000000034f0 <pqcrystals_kyber768_ref_poly_compress>:
    34f0:	31 c0                	xor    %eax,%eax
    34f2:	48 83 f8 20          	cmp    $0x20,%rax
    34f6:	0f 84 80 00 00 00    	je     357c <pqcrystals_kyber768_ref_poly_compress+0x8c>
    34fc:	31 c9                	xor    %ecx,%ecx
    34fe:	48 83 f9 08          	cmp    $0x8,%rcx
    3502:	74 31                	je     3535 <pqcrystals_kyber768_ref_poly_compress+0x45>
    3504:	0f bf 14 4e          	movswl (%rsi,%rcx,2),%edx
    3508:	41 89 d0             	mov    %edx,%r8d
    350b:	41 c1 e8 0f          	shr    $0xf,%r8d
    350f:	41 81 e0 01 0d 00 00 	and    $0xd01,%r8d
    3516:	41 01 d0             	add    %edx,%r8d
    3519:	41 0f bf d0          	movswl %r8w,%edx
    351d:	69 d2 b0 af 13 00    	imul   $0x13afb0,%edx,%edx
    3523:	81 c2 7b 9a 00 08    	add    $0x8009a7b,%edx
    3529:	c1 ea 1c             	shr    $0x1c,%edx
    352c:	88 54 0c f8          	mov    %dl,-0x8(%rsp,%rcx,1)
    3530:	48 ff c1             	inc    %rcx
    3533:	eb c9                	jmp    34fe <pqcrystals_kyber768_ref_poly_compress+0xe>
    3535:	8a 4c 24 f9          	mov    -0x7(%rsp),%cl
    3539:	c0 e1 04             	shl    $0x4,%cl
    353c:	0a 4c 24 f8          	or     -0x8(%rsp),%cl
    3540:	88 0f                	mov    %cl,(%rdi)
    3542:	8a 4c 24 fb          	mov    -0x5(%rsp),%cl
    3546:	c0 e1 04             	shl    $0x4,%cl
    3549:	0a 4c 24 fa          	or     -0x6(%rsp),%cl
    354d:	88 4f 01             	mov    %cl,0x1(%rdi)
    3550:	8a 4c 24 fd          	mov    -0x3(%rsp),%cl
    3554:	c0 e1 04             	shl    $0x4,%cl
    3557:	0a 4c 24 fc          	or     -0x4(%rsp),%cl
    355b:	88 4f 02             	mov    %cl,0x2(%rdi)
    355e:	8a 4c 24 ff          	mov    -0x1(%rsp),%cl
    3562:	c0 e1 04             	shl    $0x4,%cl
    3565:	0a 4c 24 fe          	or     -0x2(%rsp),%cl
    3569:	88 4f 03             	mov    %cl,0x3(%rdi)
    356c:	48 83 c7 04          	add    $0x4,%rdi
    3570:	48 ff c0             	inc    %rax
    3573:	48 83 c6 10          	add    $0x10,%rsi
    3577:	e9 76 ff ff ff       	jmp    34f2 <pqcrystals_kyber768_ref_poly_compress+0x2>
    357c:	c3                   	ret

