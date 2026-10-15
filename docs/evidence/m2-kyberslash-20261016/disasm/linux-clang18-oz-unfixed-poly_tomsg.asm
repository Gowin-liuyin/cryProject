000000000000183e <pqcrystals_kyber768_ref_poly_tomsg>:
    183e:	45 31 c0             	xor    %r8d,%r8d
    1841:	41 b9 01 0d 00 00    	mov    $0xd01,%r9d
    1847:	49 83 f8 20          	cmp    $0x20,%r8
    184b:	74 47                	je     1894 <pqcrystals_kyber768_ref_poly_tomsg+0x56>
    184d:	42 c6 04 07 00       	movb   $0x0,(%rdi,%r8,1)
    1852:	31 c9                	xor    %ecx,%ecx
    1854:	45 31 d2             	xor    %r10d,%r10d
    1857:	48 83 f9 08          	cmp    $0x8,%rcx
    185b:	74 2e                	je     188b <pqcrystals_kyber768_ref_poly_tomsg+0x4d>
    185d:	0f bf 04 4e          	movswl (%rsi,%rcx,2),%eax
    1861:	89 c2                	mov    %eax,%edx
    1863:	c1 ea 0f             	shr    $0xf,%edx
    1866:	44 21 ca             	and    %r9d,%edx
    1869:	01 c2                	add    %eax,%edx
    186b:	0f b7 c2             	movzwl %dx,%eax
    186e:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
    1875:	31 d2                	xor    %edx,%edx
    1877:	41 f7 f1             	div    %r9d
    187a:	83 e0 01             	and    $0x1,%eax
    187d:	d3 e0                	shl    %cl,%eax
    187f:	41 08 c2             	or     %al,%r10b
    1882:	46 88 14 07          	mov    %r10b,(%rdi,%r8,1)
    1886:	48 ff c1             	inc    %rcx
    1889:	eb cc                	jmp    1857 <pqcrystals_kyber768_ref_poly_tomsg+0x19>
    188b:	49 ff c0             	inc    %r8
    188e:	48 83 c6 10          	add    $0x10,%rsi
    1892:	eb b3                	jmp    1847 <pqcrystals_kyber768_ref_poly_tomsg+0x9>
    1894:	c3                   	ret

