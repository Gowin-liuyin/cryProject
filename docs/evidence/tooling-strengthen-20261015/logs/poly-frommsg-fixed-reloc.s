000000000000015f <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
 15f:	55                   	push   %rbp
 160:	48 89 e5             	mov    %rsp,%rbp
 163:	41 57                	push   %r15
 165:	41 56                	push   %r14
 167:	41 55                	push   %r13
 169:	41 54                	push   %r12
 16b:	53                   	push   %rbx
 16c:	50                   	push   %rax
 16d:	48 89 f3             	mov    %rsi,%rbx
 170:	49 89 fe             	mov    %rdi,%r14
 173:	45 31 e4             	xor    %r12d,%r12d
 176:	4d 89 f7             	mov    %r14,%r15
 179:	45 31 ed             	xor    %r13d,%r13d
 17c:	66 41 c7 07 00 00    	movw   $0x0,(%r15)
 182:	42 0f b6 04 23       	movzbl (%rbx,%r12,1),%eax
 187:	31 d2                	xor    %edx,%edx
 189:	44 0f a3 e8          	bt     %r13d,%eax
 18d:	0f 92 c2             	setb   %dl
 190:	4c 89 ff             	mov    %r15,%rdi
 193:	be 81 06 00 00       	mov    $0x681,%esi
 198:	e8 00 00 00 00       	call   19d <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x3e>
			199: R_X86_64_PLT32	pqcrystals_ml_kem_768_ipd_ref_cmov_int16-0x4
 19d:	49 ff c5             	inc    %r13
 1a0:	49 83 c7 02          	add    $0x2,%r15
 1a4:	49 83 fd 08          	cmp    $0x8,%r13
 1a8:	75 d2                	jne    17c <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x1d>
 1aa:	49 ff c4             	inc    %r12
 1ad:	49 83 c6 10          	add    $0x10,%r14
 1b1:	49 83 fc 20          	cmp    $0x20,%r12
 1b5:	75 bf                	jne    176 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x17>
 1b7:	48 83 c4 08          	add    $0x8,%rsp
 1bb:	5b                   	pop    %rbx
 1bc:	41 5c                	pop    %r12
 1be:	41 5d                	pop    %r13
 1c0:	41 5e                	pop    %r14
 1c2:	41 5f                	pop    %r15
 1c4:	5d                   	pop    %rbp
 1c5:	c3                   	ret
