0000000000000059 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>:
  59:	55                   	push   %rbp
  5a:	48 89 e5             	mov    %rsp,%rbp
  5d:	f7 da                	neg    %edx
  5f:	0f b7 07             	movzwl (%rdi),%eax
  62:	31 c6                	xor    %eax,%esi
  64:	21 d6                	and    %edx,%esi
  66:	31 c6                	xor    %eax,%esi
  68:	66 89 37             	mov    %si,(%rdi)
  6b:	5d                   	pop    %rbp
  6c:	c3                   	ret
