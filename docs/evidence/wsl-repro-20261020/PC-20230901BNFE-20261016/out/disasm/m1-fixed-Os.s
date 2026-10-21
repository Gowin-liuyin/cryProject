0000000000003ecb <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    3ecb:	push   %rbp
    3ecc:	mov    %rsp,%rbp
    3ecf:	push   %r15
    3ed1:	push   %r14
    3ed3:	push   %r13
    3ed5:	push   %r12
    3ed7:	push   %rbx
    3ed8:	push   %rax
    3ed9:	mov    %rsi,%rbx
    3edc:	mov    %rdi,%r14
    3edf:	xor    %r12d,%r12d
    3ee2:	mov    %r14,%r15
    3ee5:	xor    %r13d,%r13d
    3ee8:	movw   $0x0,(%r15)
    3eee:	movzbl (%rbx,%r12,1),%eax
    3ef3:	xor    %edx,%edx
    3ef5:	bt     %r13d,%eax
    3ef9:	setb   %dl
    3efc:	mov    %r15,%rdi
    3eff:	mov    $0x681,%esi
    3f04:	callq  2c79 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    3f09:	inc    %r13
    3f0c:	add    $0x2,%r15
    3f10:	cmp    $0x8,%r13
    3f14:	jne    3ee8 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x1d>
    3f16:	inc    %r12
    3f19:	add    $0x10,%r14
    3f1d:	cmp    $0x20,%r12
    3f21:	jne    3ee2 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x17>
    3f23:	add    $0x8,%rsp
    3f27:	pop    %rbx
    3f28:	pop    %r12
    3f2a:	pop    %r13
    3f2c:	pop    %r14
    3f2e:	pop    %r15
    3f30:	pop    %rbp
    3f31:	retq   
