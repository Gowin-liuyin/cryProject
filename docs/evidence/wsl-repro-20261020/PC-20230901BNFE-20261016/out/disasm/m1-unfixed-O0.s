0000000000004a60 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4a60:	push   %rbp
    4a61:	mov    %rsp,%rbp
    4a64:	mov    %rdi,-0x8(%rbp)
    4a68:	mov    %rsi,-0x10(%rbp)
    4a6c:	movl   $0x0,-0x14(%rbp)
    4a73:	cmpl   $0x20,-0x14(%rbp)
    4a77:	jae    4aec <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x8c>
    4a7d:	movl   $0x0,-0x18(%rbp)
    4a84:	cmpl   $0x8,-0x18(%rbp)
    4a88:	jae    4ad9 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x79>
    4a8e:	mov    -0x10(%rbp),%rax
    4a92:	mov    -0x14(%rbp),%ecx
    4a95:	movzbl (%rax,%rcx,1),%eax
    4a99:	mov    -0x18(%rbp),%ecx
    4a9c:	sar    %cl,%eax
    4a9e:	and    $0x1,%eax
    4aa1:	movswl %ax,%ecx
    4aa4:	xor    %eax,%eax
    4aa6:	sub    %ecx,%eax
    4aa8:	mov    %ax,-0x1a(%rbp)
    4aac:	movswl -0x1a(%rbp),%eax
    4ab0:	and    $0x681,%eax
    4ab5:	mov    %ax,%dx
    4ab8:	mov    -0x8(%rbp),%rax
    4abc:	mov    -0x14(%rbp),%ecx
    4abf:	shl    $0x3,%ecx
    4ac2:	add    -0x18(%rbp),%ecx
    4ac5:	mov    %ecx,%ecx
    4ac7:	mov    %dx,(%rax,%rcx,2)
    4acb:	mov    -0x18(%rbp),%eax
    4ace:	add    $0x1,%eax
    4ad1:	mov    %eax,-0x18(%rbp)
    4ad4:	jmpq   4a84 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x24>
    4ad9:	jmpq   4ade <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x7e>
    4ade:	mov    -0x14(%rbp),%eax
    4ae1:	add    $0x1,%eax
    4ae4:	mov    %eax,-0x14(%rbp)
    4ae7:	jmpq   4a73 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x13>
    4aec:	pop    %rbp
    4aed:	retq   
    4aee:	xchg   %ax,%ax
