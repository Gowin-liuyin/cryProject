
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_dudect：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

000000000000354b <pqcrystals_kyber768_ref_dec>:
    354b:	55                   	push   %rbp
    354c:	41 57                	push   %r15
    354e:	41 56                	push   %r14
    3550:	41 55                	push   %r13
    3552:	41 54                	push   %r12
    3554:	53                   	push   %rbx
    3555:	48 81 ec d8 04 00 00 	sub    $0x4d8,%rsp
    355c:	49 89 d6             	mov    %rdx,%r14
    355f:	49 89 f7             	mov    %rsi,%r15
    3562:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
    3567:	48 8d 7c 24 50       	lea    0x50(%rsp),%rdi
    356c:	e8 b9 05 00 00       	call   3b2a <pqcrystals_kyber768_ref_indcpa_dec>
    3571:	31 c0                	xor    %eax,%eax
    3573:	48 83 f8 20          	cmp    $0x20,%rax
    3577:	74 11                	je     358a <pqcrystals_kyber768_ref_dec+0x3f>
    3579:	41 8a 8c 06 20 09 00 	mov    0x920(%r14,%rax,1),%cl
    3580:	00 
    3581:	88 4c 04 70          	mov    %cl,0x70(%rsp,%rax,1)
    3585:	48 ff c0             	inc    %rax
    3588:	eb e9                	jmp    3573 <pqcrystals_kyber768_ref_dec+0x28>
    358a:	49 8d ae 80 04 00 00 	lea    0x480(%r14),%rbp
    3591:	48 8d 7c 24 10       	lea    0x10(%rsp),%rdi
    3596:	48 8d 5c 24 50       	lea    0x50(%rsp),%rbx
    359b:	6a 40                	push   $0x40
    359d:	5a                   	pop    %rdx
    359e:	48 89 de             	mov    %rbx,%rsi
    35a1:	e8 95 1d 00 00       	call   533b <pqcrystals_kyber_fips202_ref_sha3_512>
    35a6:	4c 8d 6c 24 30       	lea    0x30(%rsp),%r13
    35ab:	4c 8d a4 24 90 00 00 	lea    0x90(%rsp),%r12
    35b2:	00 
    35b3:	4c 89 e7             	mov    %r12,%rdi
    35b6:	48 89 de             	mov    %rbx,%rsi
    35b9:	48 89 ea             	mov    %rbp,%rdx
    35bc:	4c 89 e9             	mov    %r13,%rcx
    35bf:	e8 a3 03 00 00       	call   3967 <pqcrystals_kyber768_ref_indcpa_enc>
    35c4:	ba 40 04 00 00       	mov    $0x440,%edx
    35c9:	4c 89 ff             	mov    %r15,%rdi
    35cc:	4c 89 e6             	mov    %r12,%rsi
    35cf:	e8 70 0f 00 00       	call   4544 <pqcrystals_kyber768_ref_verify>
    35d4:	89 c3                	mov    %eax,%ebx
    35d6:	ba 40 04 00 00       	mov    $0x440,%edx
    35db:	4c 89 ef             	mov    %r13,%rdi
    35de:	4c 89 fe             	mov    %r15,%rsi
    35e1:	e8 2c 14 00 00       	call   4a12 <pqcrystals_kyber_fips202_ref_sha3_256>
    35e6:	49 81 c6 40 09 00 00 	add    $0x940,%r14
    35ed:	0f b6 cb             	movzbl %bl,%ecx
    35f0:	6a 20                	push   $0x20
    35f2:	5b                   	pop    %rbx
    35f3:	4c 8d 7c 24 10       	lea    0x10(%rsp),%r15
    35f8:	4c 89 ff             	mov    %r15,%rdi
    35fb:	4c 89 f6             	mov    %r14,%rsi
    35fe:	48 89 da             	mov    %rbx,%rdx
    3601:	e8 5f 0f 00 00       	call   4565 <pqcrystals_kyber768_ref_cmov>
    3606:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    360b:	48 89 de             	mov    %rbx,%rsi
    360e:	4c 89 fa             	mov    %r15,%rdx
    3611:	6a 40                	push   $0x40
    3613:	59                   	pop    %rcx
    3614:	e8 8d 13 00 00       	call   49a6 <pqcrystals_kyber_fips202_ref_shake256>
    3619:	31 c0                	xor    %eax,%eax
    361b:	48 81 c4 d8 04 00 00 	add    $0x4d8,%rsp
    3622:	5b                   	pop    %rbx
    3623:	41 5c                	pop    %r12
    3625:	41 5d                	pop    %r13
    3627:	41 5e                	pop    %r14
    3629:	41 5f                	pop    %r15
    362b:	5d                   	pop    %rbp
    362c:	c3                   	ret

Disassembly of section .fini:
