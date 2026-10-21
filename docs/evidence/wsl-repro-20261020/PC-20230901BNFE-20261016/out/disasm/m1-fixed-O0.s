0000000000004ab0 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4ab0:	push   %rbp
    4ab1:	mov    %rsp,%rbp
    4ab4:	sub    $0x20,%rsp
    4ab8:	mov    %rdi,-0x8(%rbp)
    4abc:	mov    %rsi,-0x10(%rbp)
    4ac0:	movl   $0x0,-0x14(%rbp)
    4ac7:	cmpl   $0x20,-0x14(%rbp)
    4acb:	jae    4b53 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xa3>
    4ad1:	movl   $0x0,-0x18(%rbp)
    4ad8:	cmpl   $0x8,-0x18(%rbp)
    4adc:	jae    4b40 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x90>
    4ae2:	mov    -0x8(%rbp),%rax
    4ae6:	mov    -0x14(%rbp),%ecx
    4ae9:	shl    $0x3,%ecx
    4aec:	add    -0x18(%rbp),%ecx
    4aef:	mov    %ecx,%ecx
    4af1:	movw   $0x0,(%rax,%rcx,2)
    4af7:	mov    -0x8(%rbp),%rdi
    4afb:	mov    -0x14(%rbp),%eax
    4afe:	shl    $0x3,%eax
    4b01:	mov    %eax,%eax
    4b03:	shl    %rax
    4b06:	add    %rax,%rdi
    4b09:	mov    -0x18(%rbp),%eax
    4b0c:	shl    %rax
    4b0f:	add    %rax,%rdi
    4b12:	mov    -0x10(%rbp),%rax
    4b16:	mov    -0x14(%rbp),%ecx
    4b19:	movzbl (%rax,%rcx,1),%eax
    4b1d:	mov    -0x18(%rbp),%ecx
    4b20:	sar    %cl,%eax
    4b22:	and    $0x1,%eax
    4b25:	mov    $0x681,%esi
    4b2a:	movzwl %ax,%edx
    4b2d:	callq  2eb0 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4b32:	mov    -0x18(%rbp),%eax
    4b35:	add    $0x1,%eax
    4b38:	mov    %eax,-0x18(%rbp)
    4b3b:	jmpq   4ad8 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x28>
    4b40:	jmpq   4b45 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x95>
    4b45:	mov    -0x14(%rbp),%eax
    4b48:	add    $0x1,%eax
    4b4b:	mov    %eax,-0x14(%rbp)
    4b4e:	jmpq   4ac7 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x17>
    4b53:	add    $0x20,%rsp
    4b57:	pop    %rbp
    4b58:	retq   
    4b59:	nopl   0x0(%rax)
