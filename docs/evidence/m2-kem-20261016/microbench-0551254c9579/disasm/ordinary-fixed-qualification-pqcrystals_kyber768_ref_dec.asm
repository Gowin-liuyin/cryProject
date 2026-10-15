
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/qualification/fixed/m2_hotspot_qualification：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003f8b <pqcrystals_kyber768_ref_dec>:
    3f8b:	55                   	push   %rbp
    3f8c:	41 57                	push   %r15
    3f8e:	41 56                	push   %r14
    3f90:	41 55                	push   %r13
    3f92:	41 54                	push   %r12
    3f94:	53                   	push   %rbx
    3f95:	48 81 ec d8 04 00 00 	sub    $0x4d8,%rsp
    3f9c:	49 89 d6             	mov    %rdx,%r14
    3f9f:	49 89 f7             	mov    %rsi,%r15
    3fa2:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
    3fa7:	48 8d 7c 24 50       	lea    0x50(%rsp),%rdi
    3fac:	e8 b9 05 00 00       	call   456a <pqcrystals_kyber768_ref_indcpa_dec>
    3fb1:	31 c0                	xor    %eax,%eax
    3fb3:	48 83 f8 20          	cmp    $0x20,%rax
    3fb7:	74 11                	je     3fca <pqcrystals_kyber768_ref_dec+0x3f>
    3fb9:	41 8a 8c 06 20 09 00 	mov    0x920(%r14,%rax,1),%cl
    3fc0:	00 
    3fc1:	88 4c 04 70          	mov    %cl,0x70(%rsp,%rax,1)
    3fc5:	48 ff c0             	inc    %rax
    3fc8:	eb e9                	jmp    3fb3 <pqcrystals_kyber768_ref_dec+0x28>
    3fca:	49 8d ae 80 04 00 00 	lea    0x480(%r14),%rbp
    3fd1:	48 8d 7c 24 10       	lea    0x10(%rsp),%rdi
    3fd6:	48 8d 5c 24 50       	lea    0x50(%rsp),%rbx
    3fdb:	6a 40                	push   $0x40
    3fdd:	5a                   	pop    %rdx
    3fde:	48 89 de             	mov    %rbx,%rsi
    3fe1:	e8 95 1d 00 00       	call   5d7b <pqcrystals_kyber_fips202_ref_sha3_512>
    3fe6:	4c 8d 6c 24 30       	lea    0x30(%rsp),%r13
    3feb:	4c 8d a4 24 90 00 00 	lea    0x90(%rsp),%r12
    3ff2:	00 
    3ff3:	4c 89 e7             	mov    %r12,%rdi
    3ff6:	48 89 de             	mov    %rbx,%rsi
    3ff9:	48 89 ea             	mov    %rbp,%rdx
    3ffc:	4c 89 e9             	mov    %r13,%rcx
    3fff:	e8 a3 03 00 00       	call   43a7 <pqcrystals_kyber768_ref_indcpa_enc>
    4004:	ba 40 04 00 00       	mov    $0x440,%edx
    4009:	4c 89 ff             	mov    %r15,%rdi
    400c:	4c 89 e6             	mov    %r12,%rsi
    400f:	e8 70 0f 00 00       	call   4f84 <pqcrystals_kyber768_ref_verify>
    4014:	89 c3                	mov    %eax,%ebx
    4016:	ba 40 04 00 00       	mov    $0x440,%edx
    401b:	4c 89 ef             	mov    %r13,%rdi
    401e:	4c 89 fe             	mov    %r15,%rsi
    4021:	e8 2c 14 00 00       	call   5452 <pqcrystals_kyber_fips202_ref_sha3_256>
    4026:	49 81 c6 40 09 00 00 	add    $0x940,%r14
    402d:	0f b6 cb             	movzbl %bl,%ecx
    4030:	6a 20                	push   $0x20
    4032:	5b                   	pop    %rbx
    4033:	4c 8d 7c 24 10       	lea    0x10(%rsp),%r15
    4038:	4c 89 ff             	mov    %r15,%rdi
    403b:	4c 89 f6             	mov    %r14,%rsi
    403e:	48 89 da             	mov    %rbx,%rdx
    4041:	e8 5f 0f 00 00       	call   4fa5 <pqcrystals_kyber768_ref_cmov>
    4046:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    404b:	48 89 de             	mov    %rbx,%rsi
    404e:	4c 89 fa             	mov    %r15,%rdx
    4051:	6a 40                	push   $0x40
    4053:	59                   	pop    %rcx
    4054:	e8 8d 13 00 00       	call   53e6 <pqcrystals_kyber_fips202_ref_shake256>
    4059:	31 c0                	xor    %eax,%eax
    405b:	48 81 c4 d8 04 00 00 	add    $0x4d8,%rsp
    4062:	5b                   	pop    %rbx
    4063:	41 5c                	pop    %r12
    4065:	41 5d                	pop    %r13
    4067:	41 5e                	pop    %r14
    4069:	41 5f                	pop    %r15
    406b:	5d                   	pop    %rbp
    406c:	c3                   	ret

Disassembly of section .fini:
