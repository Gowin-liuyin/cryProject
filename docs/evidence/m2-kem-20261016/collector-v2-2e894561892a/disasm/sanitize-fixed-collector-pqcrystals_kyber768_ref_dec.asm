
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-sanitize/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000112c38 <pqcrystals_kyber768_ref_dec>:
  112c38:	55                   	push   %rbp
  112c39:	48 89 e5             	mov    %rsp,%rbp
  112c3c:	41 57                	push   %r15
  112c3e:	41 56                	push   %r14
  112c40:	41 55                	push   %r13
  112c42:	41 54                	push   %r12
  112c44:	53                   	push   %rbx
  112c45:	48 83 e4 e0          	and    $0xffffffffffffffe0,%rsp
  112c49:	48 81 ec 80 00 00 00 	sub    $0x80,%rsp
  112c50:	48 89 e3             	mov    %rsp,%rbx
  112c53:	49 89 d4             	mov    %rdx,%r12
  112c56:	48 89 7b 48          	mov    %rdi,0x48(%rbx)
  112c5a:	48 8d 05 0f 36 06 00 	lea    0x6360f(%rip),%rax        # 176270 <__asan_option_detect_stack_use_after_return>
  112c61:	83 38 00             	cmpl   $0x0,(%rax)
  112c64:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  112c68:	74 0c                	je     112c76 <pqcrystals_kyber768_ref_dec+0x3e>
  112c6a:	bf a0 05 00 00       	mov    $0x5a0,%edi
  112c6f:	e8 cc 00 f3 ff       	call   42d40 <__asan_stack_malloc_5>
  112c74:	eb 02                	jmp    112c78 <pqcrystals_kyber768_ref_dec+0x40>
  112c76:	31 c0                	xor    %eax,%eax
  112c78:	49 89 c6             	mov    %rax,%r14
  112c7b:	48 89 43 50          	mov    %rax,0x50(%rbx)
  112c7f:	48 85 c0             	test   %rax,%rax
  112c82:	75 11                	jne    112c95 <pqcrystals_kyber768_ref_dec+0x5d>
  112c84:	49 89 e6             	mov    %rsp,%r14
  112c87:	49 81 c6 60 fa ff ff 	add    $0xfffffffffffffa60,%r14
  112c8e:	49 83 e6 e0          	and    $0xffffffffffffffe0,%r14
  112c92:	4c 89 f4             	mov    %r14,%rsp
  112c95:	48 b9 f8 f8 f8 f8 f8 	movabs $0xf8f8f8f8f8f8f8f8,%rcx
  112c9c:	f8 f8 f8 
  112c9f:	4c 89 73 58          	mov    %r14,0x58(%rbx)
  112ca3:	4d 8d 7e 20          	lea    0x20(%r14),%r15
  112ca7:	49 c7 06 b3 8a b5 41 	movq   $0x41b58ab3,(%r14)
  112cae:	48 8d 05 2b 0e 02 00 	lea    0x20e2b(%rip),%rax        # 133ae0 <_ZN11__sanitizerL10kExtraRegsE+0x12930>
  112cb5:	49 89 46 08          	mov    %rax,0x8(%r14)
  112cb9:	48 8d 05 78 ff ff ff 	lea    -0x88(%rip),%rax        # 112c38 <pqcrystals_kyber768_ref_dec>
  112cc0:	49 89 46 10          	mov    %rax,0x10(%r14)
  112cc4:	4d 89 f5             	mov    %r14,%r13
  112cc7:	49 c1 ed 03          	shr    $0x3,%r13
  112ccb:	48 8d 81 f9 f8 f8 f8 	lea    -0x7070707(%rcx),%rax
  112cd2:	49 89 85 00 80 ff 7f 	mov    %rax,0x7fff8000(%r13)
  112cd9:	48 b8 f8 f8 f8 f8 f2 	movabs $0xf2f2f2f2f8f8f8f8,%rax
  112ce0:	f2 f2 f2 
  112ce3:	49 89 85 08 80 ff 7f 	mov    %rax,0x7fff8008(%r13)
  112cea:	49 89 8d 10 80 ff 7f 	mov    %rcx,0x7fff8010(%r13)
  112cf1:	41 c7 85 18 80 ff 7f 	movl   $0xf2f2f2f2,0x7fff8018(%r13)
  112cf8:	f2 f2 f2 f2 
  112cfc:	49 8d bd 1c 80 ff 7f 	lea    0x7fff801c(%r13),%rdi
  112d03:	48 89 7b 10          	mov    %rdi,0x10(%rbx)
  112d07:	be 88 00 00 00       	mov    $0x88,%esi
  112d0c:	e8 8f d5 fb ff       	call   d02a0 <__asan_set_shadow_f8>
  112d11:	48 b8 f3 f3 f3 f3 f3 	movabs $0xf3f3f3f3f3f3f3f3,%rax
  112d18:	f3 f3 f3 
  112d1b:	49 89 85 a4 80 ff 7f 	mov    %rax,0x7fff80a4(%r13)
  112d22:	49 89 85 ac 80 ff 7f 	mov    %rax,0x7fff80ac(%r13)
  112d29:	49 c7 85 04 80 ff 7f 	movq   $0x0,0x7fff8004(%r13)
  112d30:	00 00 00 00 
  112d34:	4c 89 6b 30          	mov    %r13,0x30(%rbx)
  112d38:	49 c7 85 10 80 ff 7f 	movq   $0x0,0x7fff8010(%r13)
  112d3f:	00 00 00 00 
  112d43:	be 88 00 00 00       	mov    $0x88,%esi
  112d48:	48 8b 7b 10          	mov    0x10(%rbx),%rdi
  112d4c:	e8 cf d3 fb ff       	call   d0120 <__asan_set_shadow_00>
  112d51:	4d 8d ac 24 80 04 00 	lea    0x480(%r12),%r13
  112d58:	00 
  112d59:	4d 85 e4             	test   %r12,%r12
  112d5c:	0f 84 4c 02 00 00    	je     112fae <pqcrystals_kyber768_ref_dec+0x376>
  112d62:	49 81 fc 7f fb ff ff 	cmp    $0xfffffffffffffb7f,%r12
  112d69:	0f 87 3f 02 00 00    	ja     112fae <pqcrystals_kyber768_ref_dec+0x376>
  112d6f:	4d 85 ed             	test   %r13,%r13
  112d72:	0f 84 36 02 00 00    	je     112fae <pqcrystals_kyber768_ref_dec+0x376>
  112d78:	4c 89 6b 18          	mov    %r13,0x18(%rbx)
  112d7c:	49 8d 86 80 00 00 00 	lea    0x80(%r14),%rax
  112d83:	48 89 43 10          	mov    %rax,0x10(%rbx)
  112d87:	4c 89 73 40          	mov    %r14,0x40(%rbx)
  112d8b:	49 8d 86 e0 00 00 00 	lea    0xe0(%r14),%rax
  112d92:	48 89 43 38          	mov    %rax,0x38(%rbx)
  112d96:	48 81 43 30 00 80 ff 	addq   $0x7fff8000,0x30(%rbx)
  112d9d:	7f 
  112d9e:	4c 89 ff             	mov    %r15,%rdi
  112da1:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  112da5:	4c 89 e2             	mov    %r12,%rdx
  112da8:	e8 8b 18 00 00       	call   114638 <pqcrystals_kyber768_ref_indcpa_dec>
  112dad:	41 bd 20 09 00 00    	mov    $0x920,%r13d
  112db3:	66 66 66 66 2e 0f 1f 	data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
  112dba:	84 00 00 00 00 00 
  112dc0:	4f 8d 34 2c          	lea    (%r12,%r13,1),%r14
  112dc4:	4d 85 e4             	test   %r12,%r12
  112dc7:	74 46                	je     112e0f <pqcrystals_kyber768_ref_dec+0x1d7>
  112dc9:	4d 85 f6             	test   %r14,%r14
  112dcc:	74 41                	je     112e0f <pqcrystals_kyber768_ref_dec+0x1d7>
  112dce:	4d 39 e6             	cmp    %r12,%r14
  112dd1:	72 3c                	jb     112e0f <pqcrystals_kyber768_ref_dec+0x1d7>
  112dd3:	4c 89 f0             	mov    %r14,%rax
  112dd6:	48 c1 e8 03          	shr    $0x3,%rax
  112dda:	0f b6 80 00 80 ff 7f 	movzbl 0x7fff8000(%rax),%eax
  112de1:	84 c0                	test   %al,%al
  112de3:	75 1b                	jne    112e00 <pqcrystals_kyber768_ref_dec+0x1c8>
  112de5:	43 0f b6 04 2c       	movzbl (%r12,%r13,1),%eax
  112dea:	43 88 84 2f 00 f7 ff 	mov    %al,-0x900(%r15,%r13,1)
  112df1:	ff 
  112df2:	49 ff c5             	inc    %r13
  112df5:	49 81 fd 40 09 00 00 	cmp    $0x940,%r13
  112dfc:	75 c2                	jne    112dc0 <pqcrystals_kyber768_ref_dec+0x188>
  112dfe:	eb 23                	jmp    112e23 <pqcrystals_kyber768_ref_dec+0x1eb>
  112e00:	44 89 f1             	mov    %r14d,%ecx
  112e03:	80 e1 07             	and    $0x7,%cl
  112e06:	38 c1                	cmp    %al,%cl
  112e08:	7c db                	jl     112de5 <pqcrystals_kyber768_ref_dec+0x1ad>
  112e0a:	e9 cd 01 00 00       	jmp    112fdc <pqcrystals_kyber768_ref_dec+0x3a4>
  112e0f:	48 8d 3d ea de 04 00 	lea    0x4deea(%rip),%rdi        # 160d00 <_ZL17kSuppressionTypes+0x12b0>
  112e16:	4c 89 e6             	mov    %r12,%rsi
  112e19:	4c 89 f2             	mov    %r14,%rdx
  112e1c:	e8 9f 77 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  112e21:	eb b0                	jmp    112dd3 <pqcrystals_kyber768_ref_dec+0x19b>
  112e23:	ba 40 00 00 00       	mov    $0x40,%edx
  112e28:	4c 8b 73 10          	mov    0x10(%rbx),%r14
  112e2c:	4c 89 f7             	mov    %r14,%rdi
  112e2f:	4c 89 fe             	mov    %r15,%rsi
  112e32:	e8 b1 d8 00 00       	call   1206e8 <pqcrystals_kyber_fips202_ref_sha3_512>
  112e37:	49 8d 46 20          	lea    0x20(%r14),%rax
  112e3b:	49 83 fe e0          	cmp    $0xffffffffffffffe0,%r14
  112e3f:	48 89 43 20          	mov    %rax,0x20(%rbx)
  112e43:	0f 83 1d 01 00 00    	jae    112f66 <pqcrystals_kyber768_ref_dec+0x32e>
  112e49:	4c 8b 6b 38          	mov    0x38(%rbx),%r13
  112e4d:	4c 89 ef             	mov    %r13,%rdi
  112e50:	4c 89 fe             	mov    %r15,%rsi
  112e53:	48 8b 53 18          	mov    0x18(%rbx),%rdx
  112e57:	48 89 c1             	mov    %rax,%rcx
  112e5a:	e8 d9 11 00 00       	call   114038 <pqcrystals_kyber768_ref_indcpa_enc>
  112e5f:	ba 40 04 00 00       	mov    $0x440,%edx
  112e64:	4c 8b 7b 28          	mov    0x28(%rbx),%r15
  112e68:	4c 89 ff             	mov    %r15,%rdi
  112e6b:	4c 89 ee             	mov    %r13,%rsi
  112e6e:	e8 85 83 00 00       	call   11b1f8 <pqcrystals_kyber768_ref_verify>
  112e73:	89 43 18             	mov    %eax,0x18(%rbx)
  112e76:	49 83 fe e0          	cmp    $0xffffffffffffffe0,%r14
  112e7a:	0f 83 01 01 00 00    	jae    112f81 <pqcrystals_kyber768_ref_dec+0x349>
  112e80:	ba 40 04 00 00       	mov    $0x440,%edx
  112e85:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  112e89:	4c 89 fe             	mov    %r15,%rsi
  112e8c:	e8 27 ac 00 00       	call   11dab8 <pqcrystals_kyber_fips202_ref_sha3_256>
  112e91:	4d 8d b4 24 60 09 00 	lea    0x960(%r12),%r14
  112e98:	00 
  112e99:	4d 85 e4             	test   %r12,%r12
  112e9c:	0f 84 23 01 00 00    	je     112fc5 <pqcrystals_kyber768_ref_dec+0x38d>
  112ea2:	49 81 fc 9f f6 ff ff 	cmp    $0xfffffffffffff69f,%r12
  112ea9:	0f 87 16 01 00 00    	ja     112fc5 <pqcrystals_kyber768_ref_dec+0x38d>
  112eaf:	4d 85 f6             	test   %r14,%r14
  112eb2:	0f 84 0d 01 00 00    	je     112fc5 <pqcrystals_kyber768_ref_dec+0x38d>
  112eb8:	49 8d 56 e0          	lea    -0x20(%r14),%rdx
  112ebc:	49 83 fe 20          	cmp    $0x20,%r14
  112ec0:	4c 8b 6b 10          	mov    0x10(%rbx),%r13
  112ec4:	0f 82 d0 00 00 00    	jb     112f9a <pqcrystals_kyber768_ref_dec+0x362>
  112eca:	48 85 d2             	test   %rdx,%rdx
  112ecd:	0f 84 c7 00 00 00    	je     112f9a <pqcrystals_kyber768_ref_dec+0x362>
  112ed3:	49 81 c4 40 09 00 00 	add    $0x940,%r12
  112eda:	0f b6 4b 18          	movzbl 0x18(%rbx),%ecx
  112ede:	ba 20 00 00 00       	mov    $0x20,%edx
  112ee3:	4c 89 ef             	mov    %r13,%rdi
  112ee6:	4c 89 e6             	mov    %r12,%rsi
  112ee9:	e8 3a 85 00 00       	call   11b428 <pqcrystals_kyber768_ref_cmov>
  112eee:	be 20 00 00 00       	mov    $0x20,%esi
  112ef3:	b9 40 00 00 00       	mov    $0x40,%ecx
  112ef8:	48 8b 7b 48          	mov    0x48(%rbx),%rdi
  112efc:	4c 89 ea             	mov    %r13,%rdx
  112eff:	e8 94 a9 00 00       	call   11d898 <pqcrystals_kyber_fips202_ref_shake256>
  112f04:	4c 8b 73 30          	mov    0x30(%rbx),%r14
  112f08:	49 8d 7e 1c          	lea    0x1c(%r14),%rdi
  112f0c:	be 88 00 00 00       	mov    $0x88,%esi
  112f11:	e8 8a d3 fb ff       	call   d02a0 <__asan_set_shadow_f8>
  112f16:	48 b8 f8 f8 f8 f8 f8 	movabs $0xf8f8f8f8f8f8f8f8,%rax
  112f1d:	f8 f8 f8 
  112f20:	49 89 46 10          	mov    %rax,0x10(%r14)
  112f24:	49 89 46 04          	mov    %rax,0x4(%r14)
  112f28:	48 8b 43 40          	mov    0x40(%rbx),%rax
  112f2c:	48 c7 00 0e 36 e0 45 	movq   $0x45e0360e,(%rax)
  112f33:	48 8b 7b 50          	mov    0x50(%rbx),%rdi
  112f37:	48 85 ff             	test   %rdi,%rdi
  112f3a:	74 0c                	je     112f48 <pqcrystals_kyber768_ref_dec+0x310>
  112f3c:	be a0 05 00 00       	mov    $0x5a0,%esi
  112f41:	e8 1a 05 f3 ff       	call   43460 <__asan_stack_free_5>
  112f46:	eb 0d                	jmp    112f55 <pqcrystals_kyber768_ref_dec+0x31d>
  112f48:	be b4 00 00 00       	mov    $0xb4,%esi
  112f4d:	4c 89 f7             	mov    %r14,%rdi
  112f50:	e8 cb d1 fb ff       	call   d0120 <__asan_set_shadow_00>
  112f55:	31 c0                	xor    %eax,%eax
  112f57:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  112f5b:	5b                   	pop    %rbx
  112f5c:	41 5c                	pop    %r12
  112f5e:	41 5d                	pop    %r13
  112f60:	41 5e                	pop    %r14
  112f62:	41 5f                	pop    %r15
  112f64:	5d                   	pop    %rbp
  112f65:	c3                   	ret
  112f66:	48 8d 3d a3 dd 04 00 	lea    0x4dda3(%rip),%rdi        # 160d10 <_ZL17kSuppressionTypes+0x12c0>
  112f6d:	4c 89 f6             	mov    %r14,%rsi
  112f70:	48 89 c2             	mov    %rax,%rdx
  112f73:	e8 48 76 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  112f78:	48 8b 43 20          	mov    0x20(%rbx),%rax
  112f7c:	e9 c8 fe ff ff       	jmp    112e49 <pqcrystals_kyber768_ref_dec+0x211>
  112f81:	48 8d 3d 98 dd 04 00 	lea    0x4dd98(%rip),%rdi        # 160d20 <_ZL17kSuppressionTypes+0x12d0>
  112f88:	48 8b 73 10          	mov    0x10(%rbx),%rsi
  112f8c:	48 8b 53 20          	mov    0x20(%rbx),%rdx
  112f90:	e8 2b 76 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  112f95:	e9 e6 fe ff ff       	jmp    112e80 <pqcrystals_kyber768_ref_dec+0x248>
  112f9a:	48 8d 3d 9f dd 04 00 	lea    0x4dd9f(%rip),%rdi        # 160d40 <_ZL17kSuppressionTypes+0x12f0>
  112fa1:	4c 89 f6             	mov    %r14,%rsi
  112fa4:	e8 17 76 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  112fa9:	e9 25 ff ff ff       	jmp    112ed3 <pqcrystals_kyber768_ref_dec+0x29b>
  112fae:	48 8d 3d 3b dd 04 00 	lea    0x4dd3b(%rip),%rdi        # 160cf0 <_ZL17kSuppressionTypes+0x12a0>
  112fb5:	4c 89 e6             	mov    %r12,%rsi
  112fb8:	4c 89 ea             	mov    %r13,%rdx
  112fbb:	e8 00 76 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  112fc0:	e9 b3 fd ff ff       	jmp    112d78 <pqcrystals_kyber768_ref_dec+0x140>
  112fc5:	48 8d 3d 64 dd 04 00 	lea    0x4dd64(%rip),%rdi        # 160d30 <_ZL17kSuppressionTypes+0x12e0>
  112fcc:	4c 89 e6             	mov    %r12,%rsi
  112fcf:	4c 89 f2             	mov    %r14,%rdx
  112fd2:	e8 e9 75 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  112fd7:	e9 dc fe ff ff       	jmp    112eb8 <pqcrystals_kyber768_ref_dec+0x280>
  112fdc:	4c 89 f7             	mov    %r14,%rdi
  112fdf:	e8 fc 2b fc ff       	call   d5be0 <__asan_report_load1>

Disassembly of section .fini:
