
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000040db <pqcrystals_kyber768_ref_dec>:
    40db:	55                   	push   %rbp
    40dc:	41 57                	push   %r15
    40de:	41 56                	push   %r14
    40e0:	41 55                	push   %r13
    40e2:	41 54                	push   %r12
    40e4:	53                   	push   %rbx
    40e5:	48 81 ec d8 04 00 00 	sub    $0x4d8,%rsp
    40ec:	49 89 d6             	mov    %rdx,%r14
    40ef:	49 89 f7             	mov    %rsi,%r15
    40f2:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
    40f7:	48 8d 7c 24 50       	lea    0x50(%rsp),%rdi
    40fc:	e8 b9 05 00 00       	call   46ba <pqcrystals_kyber768_ref_indcpa_dec>
    4101:	31 c0                	xor    %eax,%eax
    4103:	48 83 f8 20          	cmp    $0x20,%rax
    4107:	74 11                	je     411a <pqcrystals_kyber768_ref_dec+0x3f>
    4109:	41 8a 8c 06 20 09 00 	mov    0x920(%r14,%rax,1),%cl
    4110:	00 
    4111:	88 4c 04 70          	mov    %cl,0x70(%rsp,%rax,1)
    4115:	48 ff c0             	inc    %rax
    4118:	eb e9                	jmp    4103 <pqcrystals_kyber768_ref_dec+0x28>
    411a:	49 8d ae 80 04 00 00 	lea    0x480(%r14),%rbp
    4121:	48 8d 7c 24 10       	lea    0x10(%rsp),%rdi
    4126:	48 8d 5c 24 50       	lea    0x50(%rsp),%rbx
    412b:	6a 40                	push   $0x40
    412d:	5a                   	pop    %rdx
    412e:	48 89 de             	mov    %rbx,%rsi
    4131:	e8 7d 1d 00 00       	call   5eb3 <pqcrystals_kyber_fips202_ref_sha3_512>
    4136:	4c 8d 6c 24 30       	lea    0x30(%rsp),%r13
    413b:	4c 8d a4 24 90 00 00 	lea    0x90(%rsp),%r12
    4142:	00 
    4143:	4c 89 e7             	mov    %r12,%rdi
    4146:	48 89 de             	mov    %rbx,%rsi
    4149:	48 89 ea             	mov    %rbp,%rdx
    414c:	4c 89 e9             	mov    %r13,%rcx
    414f:	e8 a3 03 00 00       	call   44f7 <pqcrystals_kyber768_ref_indcpa_enc>
    4154:	ba 40 04 00 00       	mov    $0x440,%edx
    4159:	4c 89 ff             	mov    %r15,%rdi
    415c:	4c 89 e6             	mov    %r12,%rsi
    415f:	e8 58 0f 00 00       	call   50bc <pqcrystals_kyber768_ref_verify>
    4164:	89 c3                	mov    %eax,%ebx
    4166:	ba 40 04 00 00       	mov    $0x440,%edx
    416b:	4c 89 ef             	mov    %r13,%rdi
    416e:	4c 89 fe             	mov    %r15,%rsi
    4171:	e8 14 14 00 00       	call   558a <pqcrystals_kyber_fips202_ref_sha3_256>
    4176:	49 81 c6 40 09 00 00 	add    $0x940,%r14
    417d:	0f b6 cb             	movzbl %bl,%ecx
    4180:	6a 20                	push   $0x20
    4182:	5b                   	pop    %rbx
    4183:	4c 8d 7c 24 10       	lea    0x10(%rsp),%r15
    4188:	4c 89 ff             	mov    %r15,%rdi
    418b:	4c 89 f6             	mov    %r14,%rsi
    418e:	48 89 da             	mov    %rbx,%rdx
    4191:	e8 47 0f 00 00       	call   50dd <pqcrystals_kyber768_ref_cmov>
    4196:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    419b:	48 89 de             	mov    %rbx,%rsi
    419e:	4c 89 fa             	mov    %r15,%rdx
    41a1:	6a 40                	push   $0x40
    41a3:	59                   	pop    %rcx
    41a4:	e8 75 13 00 00       	call   551e <pqcrystals_kyber_fips202_ref_shake256>
    41a9:	31 c0                	xor    %eax,%eax
    41ab:	48 81 c4 d8 04 00 00 	add    $0x4d8,%rsp
    41b2:	5b                   	pop    %rbx
    41b3:	41 5c                	pop    %r12
    41b5:	41 5d                	pop    %r13
    41b7:	41 5e                	pop    %r14
    41b9:	41 5f                	pop    %r15
    41bb:	5d                   	pop    %rbp
    41bc:	c3                   	ret

Disassembly of section .fini:
