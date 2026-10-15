
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000049bb <pqcrystals_kyber768_ref_dec>:
    49bb:	55                   	push   %rbp
    49bc:	41 57                	push   %r15
    49be:	41 56                	push   %r14
    49c0:	41 55                	push   %r13
    49c2:	41 54                	push   %r12
    49c4:	53                   	push   %rbx
    49c5:	48 81 ec d8 04 00 00 	sub    $0x4d8,%rsp
    49cc:	49 89 d6             	mov    %rdx,%r14
    49cf:	49 89 f7             	mov    %rsi,%r15
    49d2:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
    49d7:	48 8d 7c 24 50       	lea    0x50(%rsp),%rdi
    49dc:	e8 b9 05 00 00       	call   4f9a <pqcrystals_kyber768_ref_indcpa_dec>
    49e1:	31 c0                	xor    %eax,%eax
    49e3:	48 83 f8 20          	cmp    $0x20,%rax
    49e7:	74 11                	je     49fa <pqcrystals_kyber768_ref_dec+0x3f>
    49e9:	41 8a 8c 06 20 09 00 	mov    0x920(%r14,%rax,1),%cl
    49f0:	00 
    49f1:	88 4c 04 70          	mov    %cl,0x70(%rsp,%rax,1)
    49f5:	48 ff c0             	inc    %rax
    49f8:	eb e9                	jmp    49e3 <pqcrystals_kyber768_ref_dec+0x28>
    49fa:	49 8d ae 80 04 00 00 	lea    0x480(%r14),%rbp
    4a01:	48 8d 7c 24 10       	lea    0x10(%rsp),%rdi
    4a06:	48 8d 5c 24 50       	lea    0x50(%rsp),%rbx
    4a0b:	6a 40                	push   $0x40
    4a0d:	5a                   	pop    %rdx
    4a0e:	48 89 de             	mov    %rbx,%rsi
    4a11:	e8 7d 1d 00 00       	call   6793 <pqcrystals_kyber_fips202_ref_sha3_512>
    4a16:	4c 8d 6c 24 30       	lea    0x30(%rsp),%r13
    4a1b:	4c 8d a4 24 90 00 00 	lea    0x90(%rsp),%r12
    4a22:	00 
    4a23:	4c 89 e7             	mov    %r12,%rdi
    4a26:	48 89 de             	mov    %rbx,%rsi
    4a29:	48 89 ea             	mov    %rbp,%rdx
    4a2c:	4c 89 e9             	mov    %r13,%rcx
    4a2f:	e8 a3 03 00 00       	call   4dd7 <pqcrystals_kyber768_ref_indcpa_enc>
    4a34:	ba 40 04 00 00       	mov    $0x440,%edx
    4a39:	4c 89 ff             	mov    %r15,%rdi
    4a3c:	4c 89 e6             	mov    %r12,%rsi
    4a3f:	e8 58 0f 00 00       	call   599c <pqcrystals_kyber768_ref_verify>
    4a44:	89 c3                	mov    %eax,%ebx
    4a46:	ba 40 04 00 00       	mov    $0x440,%edx
    4a4b:	4c 89 ef             	mov    %r13,%rdi
    4a4e:	4c 89 fe             	mov    %r15,%rsi
    4a51:	e8 14 14 00 00       	call   5e6a <pqcrystals_kyber_fips202_ref_sha3_256>
    4a56:	49 81 c6 40 09 00 00 	add    $0x940,%r14
    4a5d:	0f b6 cb             	movzbl %bl,%ecx
    4a60:	6a 20                	push   $0x20
    4a62:	5b                   	pop    %rbx
    4a63:	4c 8d 7c 24 10       	lea    0x10(%rsp),%r15
    4a68:	4c 89 ff             	mov    %r15,%rdi
    4a6b:	4c 89 f6             	mov    %r14,%rsi
    4a6e:	48 89 da             	mov    %rbx,%rdx
    4a71:	e8 47 0f 00 00       	call   59bd <pqcrystals_kyber768_ref_cmov>
    4a76:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    4a7b:	48 89 de             	mov    %rbx,%rsi
    4a7e:	4c 89 fa             	mov    %r15,%rdx
    4a81:	6a 40                	push   $0x40
    4a83:	59                   	pop    %rcx
    4a84:	e8 75 13 00 00       	call   5dfe <pqcrystals_kyber_fips202_ref_shake256>
    4a89:	31 c0                	xor    %eax,%eax
    4a8b:	48 81 c4 d8 04 00 00 	add    $0x4d8,%rsp
    4a92:	5b                   	pop    %rbx
    4a93:	41 5c                	pop    %r12
    4a95:	41 5d                	pop    %r13
    4a97:	41 5e                	pop    %r14
    4a99:	41 5f                	pop    %r15
    4a9b:	5d                   	pop    %rbp
    4a9c:	c3                   	ret

Disassembly of section .fini:
