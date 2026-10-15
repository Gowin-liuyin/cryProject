
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

000000000000416b <pqcrystals_kyber768_ref_dec>:
    416b:	55                   	push   %rbp
    416c:	41 57                	push   %r15
    416e:	41 56                	push   %r14
    4170:	41 55                	push   %r13
    4172:	41 54                	push   %r12
    4174:	53                   	push   %rbx
    4175:	48 81 ec d8 04 00 00 	sub    $0x4d8,%rsp
    417c:	49 89 d6             	mov    %rdx,%r14
    417f:	49 89 f7             	mov    %rsi,%r15
    4182:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
    4187:	48 8d 7c 24 50       	lea    0x50(%rsp),%rdi
    418c:	e8 b9 05 00 00       	call   474a <pqcrystals_kyber768_ref_indcpa_dec>
    4191:	31 c0                	xor    %eax,%eax
    4193:	48 83 f8 20          	cmp    $0x20,%rax
    4197:	74 11                	je     41aa <pqcrystals_kyber768_ref_dec+0x3f>
    4199:	41 8a 8c 06 20 09 00 	mov    0x920(%r14,%rax,1),%cl
    41a0:	00 
    41a1:	88 4c 04 70          	mov    %cl,0x70(%rsp,%rax,1)
    41a5:	48 ff c0             	inc    %rax
    41a8:	eb e9                	jmp    4193 <pqcrystals_kyber768_ref_dec+0x28>
    41aa:	49 8d ae 80 04 00 00 	lea    0x480(%r14),%rbp
    41b1:	48 8d 7c 24 10       	lea    0x10(%rsp),%rdi
    41b6:	48 8d 5c 24 50       	lea    0x50(%rsp),%rbx
    41bb:	6a 40                	push   $0x40
    41bd:	5a                   	pop    %rdx
    41be:	48 89 de             	mov    %rbx,%rsi
    41c1:	e8 7d 1d 00 00       	call   5f43 <pqcrystals_kyber_fips202_ref_sha3_512>
    41c6:	4c 8d 6c 24 30       	lea    0x30(%rsp),%r13
    41cb:	4c 8d a4 24 90 00 00 	lea    0x90(%rsp),%r12
    41d2:	00 
    41d3:	4c 89 e7             	mov    %r12,%rdi
    41d6:	48 89 de             	mov    %rbx,%rsi
    41d9:	48 89 ea             	mov    %rbp,%rdx
    41dc:	4c 89 e9             	mov    %r13,%rcx
    41df:	e8 a3 03 00 00       	call   4587 <pqcrystals_kyber768_ref_indcpa_enc>
    41e4:	ba 40 04 00 00       	mov    $0x440,%edx
    41e9:	4c 89 ff             	mov    %r15,%rdi
    41ec:	4c 89 e6             	mov    %r12,%rsi
    41ef:	e8 58 0f 00 00       	call   514c <pqcrystals_kyber768_ref_verify>
    41f4:	89 c3                	mov    %eax,%ebx
    41f6:	ba 40 04 00 00       	mov    $0x440,%edx
    41fb:	4c 89 ef             	mov    %r13,%rdi
    41fe:	4c 89 fe             	mov    %r15,%rsi
    4201:	e8 14 14 00 00       	call   561a <pqcrystals_kyber_fips202_ref_sha3_256>
    4206:	49 81 c6 40 09 00 00 	add    $0x940,%r14
    420d:	0f b6 cb             	movzbl %bl,%ecx
    4210:	6a 20                	push   $0x20
    4212:	5b                   	pop    %rbx
    4213:	4c 8d 7c 24 10       	lea    0x10(%rsp),%r15
    4218:	4c 89 ff             	mov    %r15,%rdi
    421b:	4c 89 f6             	mov    %r14,%rsi
    421e:	48 89 da             	mov    %rbx,%rdx
    4221:	e8 47 0f 00 00       	call   516d <pqcrystals_kyber768_ref_cmov>
    4226:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    422b:	48 89 de             	mov    %rbx,%rsi
    422e:	4c 89 fa             	mov    %r15,%rdx
    4231:	6a 40                	push   $0x40
    4233:	59                   	pop    %rcx
    4234:	e8 75 13 00 00       	call   55ae <pqcrystals_kyber_fips202_ref_shake256>
    4239:	31 c0                	xor    %eax,%eax
    423b:	48 81 c4 d8 04 00 00 	add    $0x4d8,%rsp
    4242:	5b                   	pop    %rbx
    4243:	41 5c                	pop    %r12
    4245:	41 5d                	pop    %r13
    4247:	41 5e                	pop    %r14
    4249:	41 5f                	pop    %r15
    424b:	5d                   	pop    %rbp
    424c:	c3                   	ret

Disassembly of section .fini:
