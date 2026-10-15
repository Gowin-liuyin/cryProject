0000000000002e67 <pqcrystals_kyber768_ref_dec>:
    2e67:	55                   	push   %rbp
    2e68:	41 57                	push   %r15
    2e6a:	41 56                	push   %r14
    2e6c:	41 55                	push   %r13
    2e6e:	41 54                	push   %r12
    2e70:	53                   	push   %rbx
    2e71:	48 81 ec d8 04 00 00 	sub    $0x4d8,%rsp
    2e78:	49 89 d6             	mov    %rdx,%r14
    2e7b:	49 89 f7             	mov    %rsi,%r15
    2e7e:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
    2e83:	48 8d 7c 24 50       	lea    0x50(%rsp),%rdi
    2e88:	e8 b9 05 00 00       	call   3446 <pqcrystals_kyber768_ref_indcpa_dec>
    2e8d:	31 c0                	xor    %eax,%eax
    2e8f:	48 83 f8 20          	cmp    $0x20,%rax
    2e93:	74 11                	je     2ea6 <pqcrystals_kyber768_ref_dec+0x3f>
    2e95:	41 8a 8c 06 20 09 00 	mov    0x920(%r14,%rax,1),%cl
    2e9c:	00 
    2e9d:	88 4c 04 70          	mov    %cl,0x70(%rsp,%rax,1)
    2ea1:	48 ff c0             	inc    %rax
    2ea4:	eb e9                	jmp    2e8f <pqcrystals_kyber768_ref_dec+0x28>
    2ea6:	49 8d ae 80 04 00 00 	lea    0x480(%r14),%rbp
    2ead:	48 8d 7c 24 10       	lea    0x10(%rsp),%rdi
    2eb2:	48 8d 5c 24 50       	lea    0x50(%rsp),%rbx
    2eb7:	6a 40                	push   $0x40
    2eb9:	5a                   	pop    %rdx
    2eba:	48 89 de             	mov    %rbx,%rsi
    2ebd:	e8 95 1d 00 00       	call   4c57 <pqcrystals_kyber_fips202_ref_sha3_512>
    2ec2:	4c 8d 6c 24 30       	lea    0x30(%rsp),%r13
    2ec7:	4c 8d a4 24 90 00 00 	lea    0x90(%rsp),%r12
    2ece:	00 
    2ecf:	4c 89 e7             	mov    %r12,%rdi
    2ed2:	48 89 de             	mov    %rbx,%rsi
    2ed5:	48 89 ea             	mov    %rbp,%rdx
    2ed8:	4c 89 e9             	mov    %r13,%rcx
    2edb:	e8 a3 03 00 00       	call   3283 <pqcrystals_kyber768_ref_indcpa_enc>
    2ee0:	ba 40 04 00 00       	mov    $0x440,%edx
    2ee5:	4c 89 ff             	mov    %r15,%rdi
    2ee8:	4c 89 e6             	mov    %r12,%rsi
    2eeb:	e8 70 0f 00 00       	call   3e60 <pqcrystals_kyber768_ref_verify>
    2ef0:	89 c3                	mov    %eax,%ebx
    2ef2:	ba 40 04 00 00       	mov    $0x440,%edx
    2ef7:	4c 89 ef             	mov    %r13,%rdi
    2efa:	4c 89 fe             	mov    %r15,%rsi
    2efd:	e8 2c 14 00 00       	call   432e <pqcrystals_kyber_fips202_ref_sha3_256>
    2f02:	49 81 c6 40 09 00 00 	add    $0x940,%r14
    2f09:	0f b6 cb             	movzbl %bl,%ecx
    2f0c:	6a 20                	push   $0x20
    2f0e:	5b                   	pop    %rbx
    2f0f:	4c 8d 7c 24 10       	lea    0x10(%rsp),%r15
    2f14:	4c 89 ff             	mov    %r15,%rdi
    2f17:	4c 89 f6             	mov    %r14,%rsi
    2f1a:	48 89 da             	mov    %rbx,%rdx
    2f1d:	e8 5f 0f 00 00       	call   3e81 <pqcrystals_kyber768_ref_cmov>
    2f22:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    2f27:	48 89 de             	mov    %rbx,%rsi
    2f2a:	4c 89 fa             	mov    %r15,%rdx
    2f2d:	6a 40                	push   $0x40
    2f2f:	59                   	pop    %rcx
    2f30:	e8 8d 13 00 00       	call   42c2 <pqcrystals_kyber_fips202_ref_shake256>
    2f35:	31 c0                	xor    %eax,%eax
    2f37:	48 81 c4 d8 04 00 00 	add    $0x4d8,%rsp
    2f3e:	5b                   	pop    %rbx
    2f3f:	41 5c                	pop    %r12
    2f41:	41 5d                	pop    %r13
    2f43:	41 5e                	pop    %r14
    2f45:	41 5f                	pop    %r15
    2f47:	5d                   	pop    %rbp
    2f48:	c3                   	ret
    2f49:	0f 1f 00             	nopl   (%rax)

