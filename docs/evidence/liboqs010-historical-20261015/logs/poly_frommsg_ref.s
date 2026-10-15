000000000000015f <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
 15f:	55                   	push   %rbp
 160:	48 89 e5             	mov    %rsp,%rbp
 163:	31 c0                	xor    %eax,%eax
 165:	31 c9                	xor    %ecx,%ecx
 167:	44 0f b6 04 06       	movzbl (%rsi,%rax,1),%r8d
 16c:	31 d2                	xor    %edx,%edx
 16e:	41 0f a3 c8          	bt     %ecx,%r8d
 172:	73 05                	jae    179 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x1a>
 174:	ba 81 06 00 00       	mov    $0x681,%edx
 179:	66 89 14 4f          	mov    %dx,(%rdi,%rcx,2)
 17d:	48 ff c1             	inc    %rcx
 180:	48 83 f9 08          	cmp    $0x8,%rcx
 184:	75 e1                	jne    167 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x8>
 186:	48 ff c0             	inc    %rax
 189:	48 83 c7 10          	add    $0x10,%rdi
 18d:	48 83 f8 20          	cmp    $0x20,%rax
 191:	75 d2                	jne    165 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x6>
 193:	5d                   	pop    %rbp
 194:	c3                   	ret

