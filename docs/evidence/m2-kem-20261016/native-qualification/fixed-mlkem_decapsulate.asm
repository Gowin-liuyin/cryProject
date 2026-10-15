00000000000022e0 <mlkem_decapsulate>:
    22e0:	49 81 f9 60 09 00 00 	cmp    $0x960,%r9
    22e7:	75 29                	jne    2312 <mlkem_decapsulate+0x32>
    22e9:	48 81 f9 40 04 00 00 	cmp    $0x440,%rcx
    22f0:	75 20                	jne    2312 <mlkem_decapsulate+0x32>
    22f2:	48 83 fe 20          	cmp    $0x20,%rsi
    22f6:	75 1a                	jne    2312 <mlkem_decapsulate+0x32>
    22f8:	48 85 ff             	test   %rdi,%rdi
    22fb:	74 15                	je     2312 <mlkem_decapsulate+0x32>
    22fd:	48 85 d2             	test   %rdx,%rdx
    2300:	74 10                	je     2312 <mlkem_decapsulate+0x32>
    2302:	4d 85 c0             	test   %r8,%r8
    2305:	74 0b                	je     2312 <mlkem_decapsulate+0x32>
    2307:	48 89 d6             	mov    %rdx,%rsi
    230a:	4c 89 c2             	mov    %r8,%rdx
    230d:	e9 55 0b 00 00       	jmp    2e67 <pqcrystals_kyber768_ref_dec>
    2312:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    2317:	c3                   	ret
    2318:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    231f:	00 

