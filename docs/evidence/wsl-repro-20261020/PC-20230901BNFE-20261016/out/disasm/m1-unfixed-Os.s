0000000000003eb7 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    3eb7:	push   %rbp
    3eb8:	mov    %rsp,%rbp
    3ebb:	xor    %eax,%eax
    3ebd:	xor    %ecx,%ecx
    3ebf:	movzbl (%rsi,%rax,1),%r8d
    3ec4:	xor    %edx,%edx
    3ec6:	bt     %ecx,%r8d
    3eca:	jae    3ed1 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x1a>
    3ecc:	mov    $0x681,%edx
    3ed1:	mov    %dx,(%rdi,%rcx,2)
    3ed5:	inc    %rcx
    3ed8:	cmp    $0x8,%rcx
    3edc:	jne    3ebf <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x8>
    3ede:	inc    %rax
    3ee1:	add    $0x10,%rdi
    3ee5:	cmp    $0x20,%rax
    3ee9:	jne    3ebd <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x6>
    3eeb:	pop    %rbp
    3eec:	retq   
