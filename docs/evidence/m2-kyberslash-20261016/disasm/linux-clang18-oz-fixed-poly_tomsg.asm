0000000000001844 <pqcrystals_kyber768_ref_poly_tomsg>:
    1844:	31 c0                	xor    %eax,%eax
    1846:	48 83 f8 20          	cmp    $0x20,%rax
    184a:	74 40                	je     188c <pqcrystals_kyber768_ref_poly_tomsg+0x48>
    184c:	c6 04 07 00          	movb   $0x0,(%rdi,%rax,1)
    1850:	31 c9                	xor    %ecx,%ecx
    1852:	31 d2                	xor    %edx,%edx
    1854:	48 83 f9 08          	cmp    $0x8,%rcx
    1858:	74 29                	je     1883 <pqcrystals_kyber768_ref_poly_tomsg+0x3f>
    185a:	44 0f bf 04 4e       	movswl (%rsi,%rcx,2),%r8d
    185f:	45 69 c0 f6 75 02 00 	imul   $0x275f6,%r8d,%r8d
    1866:	41 81 c0 7b 9a 00 08 	add    $0x8009a7b,%r8d
    186d:	41 c1 e8 1c          	shr    $0x1c,%r8d
    1871:	41 83 e0 01          	and    $0x1,%r8d
    1875:	41 d3 e0             	shl    %cl,%r8d
    1878:	44 08 c2             	or     %r8b,%dl
    187b:	88 14 07             	mov    %dl,(%rdi,%rax,1)
    187e:	48 ff c1             	inc    %rcx
    1881:	eb d1                	jmp    1854 <pqcrystals_kyber768_ref_poly_tomsg+0x10>
    1883:	48 ff c0             	inc    %rax
    1886:	48 83 c6 10          	add    $0x10,%rsi
    188a:	eb ba                	jmp    1846 <pqcrystals_kyber768_ref_poly_tomsg+0x2>
    188c:	c3                   	ret

