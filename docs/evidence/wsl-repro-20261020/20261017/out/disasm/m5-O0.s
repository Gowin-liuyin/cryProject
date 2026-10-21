0000000000004ad0 <baseline_native_poly_frommsg>:
    4ad0:	push   %rbp
    4ad1:	mov    %rsp,%rbp
    4ad4:	sub    $0x20,%rsp
    4ad8:	mov    %rdi,-0x8(%rbp)
    4adc:	mov    %rsi,-0x10(%rbp)
    4ae0:	movl   $0x0,-0x14(%rbp)
    4ae7:	cmpl   $0x20,-0x14(%rbp)
    4aeb:	jae    4b6e <baseline_native_poly_frommsg+0x9e>
    4af1:	movl   $0x0,-0x18(%rbp)
    4af8:	cmpl   $0x8,-0x18(%rbp)
    4afc:	jae    4b5b <baseline_native_poly_frommsg+0x8b>
    4b02:	mov    -0x18(%rbp),%ecx
    4b05:	mov    $0x1,%eax
    4b0a:	shl    %cl,%eax
    4b0c:	movzbl %al,%edi
    4b0f:	call   4b80 <mlk_value_barrier_u8>
    4b14:	mov    %al,-0x19(%rbp)
    4b17:	mov    -0x10(%rbp),%rax
    4b1b:	mov    -0x14(%rbp),%ecx
    4b1e:	movzbl (%rax,%rcx,1),%eax
    4b22:	movzbl -0x19(%rbp),%ecx
    4b26:	and    %ecx,%eax
    4b28:	mov    $0x681,%edi
    4b2d:	xor    %esi,%esi
    4b2f:	movzwl %ax,%edx
    4b32:	call   4ba0 <mlk_ct_sel_int16>
    4b37:	mov    %ax,%dx
    4b3a:	mov    -0x8(%rbp),%rax
    4b3e:	mov    -0x14(%rbp),%ecx
    4b41:	shl    $0x3,%ecx
    4b44:	add    -0x18(%rbp),%ecx
    4b47:	mov    %ecx,%ecx
    4b49:	mov    %dx,(%rax,%rcx,2)
    4b4d:	mov    -0x18(%rbp),%eax
    4b50:	add    $0x1,%eax
    4b53:	mov    %eax,-0x18(%rbp)
    4b56:	jmp    4af8 <baseline_native_poly_frommsg+0x28>
    4b5b:	jmp    4b60 <baseline_native_poly_frommsg+0x90>
    4b60:	mov    -0x14(%rbp),%eax
    4b63:	add    $0x1,%eax
    4b66:	mov    %eax,-0x14(%rbp)
    4b69:	jmp    4ae7 <baseline_native_poly_frommsg+0x17>
    4b6e:	jmp    4b73 <baseline_native_poly_frommsg+0xa3>
    4b73:	jmp    4b78 <baseline_native_poly_frommsg+0xa8>
    4b78:	add    $0x20,%rsp
    4b7c:	pop    %rbp
    4b7d:	ret
    4b7e:	xchg   %ax,%ax
