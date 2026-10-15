0000000000003686 <pqcrystals_kyber768_ref_poly_tomsg>:
    3686:	45 31 c0             	xor    %r8d,%r8d
    3689:	41 b9 01 0d 00 00    	mov    $0xd01,%r9d
    368f:	49 83 f8 20          	cmp    $0x20,%r8
    3693:	74 47                	je     36dc <pqcrystals_kyber768_ref_poly_tomsg+0x56>
    3695:	42 c6 04 07 00       	movb   $0x0,(%rdi,%r8,1)
    369a:	31 c9                	xor    %ecx,%ecx
    369c:	45 31 d2             	xor    %r10d,%r10d
    369f:	48 83 f9 08          	cmp    $0x8,%rcx
    36a3:	74 2e                	je     36d3 <pqcrystals_kyber768_ref_poly_tomsg+0x4d>
    36a5:	0f bf 04 4e          	movswl (%rsi,%rcx,2),%eax
    36a9:	89 c2                	mov    %eax,%edx
    36ab:	c1 ea 0f             	shr    $0xf,%edx
    36ae:	44 21 ca             	and    %r9d,%edx
    36b1:	01 c2                	add    %eax,%edx
    36b3:	0f b7 c2             	movzwl %dx,%eax
    36b6:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
    36bd:	31 d2                	xor    %edx,%edx
    36bf:	41 f7 f1             	div    %r9d
    36c2:	83 e0 01             	and    $0x1,%eax
    36c5:	d3 e0                	shl    %cl,%eax
    36c7:	41 08 c2             	or     %al,%r10b
    36ca:	46 88 14 07          	mov    %r10b,(%rdi,%r8,1)
    36ce:	48 ff c1             	inc    %rcx
    36d1:	eb cc                	jmp    369f <pqcrystals_kyber768_ref_poly_tomsg+0x19>
    36d3:	49 ff c0             	inc    %r8
    36d6:	48 83 c6 10          	add    $0x10,%rsi
    36da:	eb b3                	jmp    368f <pqcrystals_kyber768_ref_poly_tomsg+0x9>
    36dc:	c3                   	ret

