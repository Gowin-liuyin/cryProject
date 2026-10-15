000000000000368c <pqcrystals_kyber768_ref_poly_tomsg>:
    368c:	31 c0                	xor    %eax,%eax
    368e:	48 83 f8 20          	cmp    $0x20,%rax
    3692:	74 40                	je     36d4 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
    3694:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    3698:	31 c9                	xor    %ecx,%ecx
    369a:	31 d2                	xor    %edx,%edx
    369c:	48 83 f9 08          	cmp    $0x8,%rcx
    36a0:	74 29                	je     36cb <pqcrystals_kyber768_ref_poly_tomsg+0x3f>
    36a2:	44 0f bf 04 4e       	movswl (%rsi,%rcx,2),%r8d
    36a7:	45 69 c0 f6 75 02 00 	imul   $0x275f6,%r8d,%r8d
    36ae:	41 81 c0 7b 9a 00 08 	add    $0x8009a7b,%r8d
    36b5:	41 c1 e8 1c          	shr    $0x1c,%r8d
    36b9:	41 83 e0 01          	and    $0x1,%r8d
    36bd:	41 d3 e0             	shl    %cl,%r8d
    36c0:	44 08 c2             	or     %r8b,%dl
    36c3:	88 14 07             	mov    %dl,(%rdi,%rax,1)
    36c6:	48 ff c1             	inc    %rcx
    36c9:	eb d1                	jmp    369c <pqcrystals_kyber768_ref_poly_tomsg+0x10>
    36cb:	48 ff c0             	inc    %rax
    36ce:	48 83 c6 10          	add    $0x10,%rsi
    36d2:	eb ba                	jmp    368e <pqcrystals_kyber768_ref_poly_tomsg+0x2>
    36d4:	c3                   	ret

