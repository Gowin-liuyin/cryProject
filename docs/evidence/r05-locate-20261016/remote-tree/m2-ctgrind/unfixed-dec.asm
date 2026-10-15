
/home/nss-marker/yhr/Cry/r05-locate-20261016-6039f84e5a09/m2-ctgrind/probe/probe_unfixed：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003690 <pqcrystals_kyber768_ref_dec>:
    3690:	55                   	push   %rbp
    3691:	41 57                	push   %r15
    3693:	41 56                	push   %r14
    3695:	41 55                	push   %r13
    3697:	41 54                	push   %r12
    3699:	53                   	push   %rbx
    369a:	48 81 ec d8 04 00 00 	sub    $0x4d8,%rsp
    36a1:	49 89 d6             	mov    %rdx,%r14
    36a4:	49 89 f4             	mov    %rsi,%r12
    36a7:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
    36ac:	4c 8d 6c 24 50       	lea    0x50(%rsp),%r13
    36b1:	4c 89 ef             	mov    %r13,%rdi
    36b4:	e8 07 fe ff ff       	call   34c0 <pqcrystals_kyber768_ref_indcpa_dec>
    36b9:	41 0f 10 86 20 09 00 	movups 0x920(%r14),%xmm0
    36c0:	00 
    36c1:	41 0f 10 8e 30 09 00 	movups 0x930(%r14),%xmm1
    36c8:	00 
    36c9:	0f 29 8c 24 80 00 00 	movaps %xmm1,0x80(%rsp)
    36d0:	00 
    36d1:	0f 29 44 24 70       	movaps %xmm0,0x70(%rsp)
    36d6:	49 8d ae 80 04 00 00 	lea    0x480(%r14),%rbp
    36dd:	48 8d 7c 24 10       	lea    0x10(%rsp),%rdi
    36e2:	ba 40 00 00 00       	mov    $0x40,%edx
    36e7:	4c 89 ee             	mov    %r13,%rsi
    36ea:	e8 71 f6 ff ff       	call   2d60 <pqcrystals_kyber_fips202_ref_sha3_512>
    36ef:	48 8d 5c 24 30       	lea    0x30(%rsp),%rbx
    36f4:	4c 8d bc 24 90 00 00 	lea    0x90(%rsp),%r15
    36fb:	00 
    36fc:	4c 89 ff             	mov    %r15,%rdi
    36ff:	4c 89 ee             	mov    %r13,%rsi
    3702:	48 89 ea             	mov    %rbp,%rdx
    3705:	48 89 d9             	mov    %rbx,%rcx
    3708:	e8 d3 fb ff ff       	call   32e0 <pqcrystals_kyber768_ref_indcpa_enc>
    370d:	ba 40 04 00 00       	mov    $0x440,%edx
    3712:	4c 89 e7             	mov    %r12,%rdi
    3715:	4c 89 fe             	mov    %r15,%rsi
    3718:	e8 f3 0b 00 00       	call   4310 <pqcrystals_kyber768_ref_verify>
    371d:	89 c5                	mov    %eax,%ebp
    371f:	ba 40 04 00 00       	mov    $0x440,%edx
    3724:	48 89 df             	mov    %rbx,%rdi
    3727:	4c 89 e6             	mov    %r12,%rsi
    372a:	e8 71 eb ff ff       	call   22a0 <pqcrystals_kyber_fips202_ref_sha3_256>
    372f:	49 81 c6 40 09 00 00 	add    $0x940,%r14
    3736:	40 0f b6 cd          	movzbl %bpl,%ecx
    373a:	ba 20 00 00 00       	mov    $0x20,%edx
    373f:	48 8d 5c 24 10       	lea    0x10(%rsp),%rbx
    3744:	48 89 df             	mov    %rbx,%rdi
    3747:	4c 89 f6             	mov    %r14,%rsi
    374a:	e8 f1 0b 00 00       	call   4340 <pqcrystals_kyber768_ref_cmov>
    374f:	be 20 00 00 00       	mov    $0x20,%esi
    3754:	b9 40 00 00 00       	mov    $0x40,%ecx
    3759:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    375e:	48 89 da             	mov    %rbx,%rdx
    3761:	e8 9a e8 ff ff       	call   2000 <pqcrystals_kyber_fips202_ref_shake256>
    3766:	31 c0                	xor    %eax,%eax
    3768:	48 81 c4 d8 04 00 00 	add    $0x4d8,%rsp
    376f:	5b                   	pop    %rbx
    3770:	41 5c                	pop    %r12
    3772:	41 5d                	pop    %r13
    3774:	41 5e                	pop    %r14
    3776:	41 5f                	pop    %r15
    3778:	5d                   	pop    %rbp
    3779:	c3                   	ret

Disassembly of section .fini:
