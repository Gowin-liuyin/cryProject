
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-sanitize/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000117d38 <pqcrystals_kyber768_ref_polyvec_compress>:
  117d38:	55                   	push   %rbp
  117d39:	48 89 e5             	mov    %rsp,%rbp
  117d3c:	41 57                	push   %r15
  117d3e:	41 56                	push   %r14
  117d40:	41 55                	push   %r13
  117d42:	41 54                	push   %r12
  117d44:	53                   	push   %rbx
  117d45:	48 83 e4 e0          	and    $0xffffffffffffffe0,%rsp
  117d49:	48 81 ec c0 00 00 00 	sub    $0xc0,%rsp
  117d50:	48 89 e3             	mov    %rsp,%rbx
  117d53:	49 89 f0             	mov    %rsi,%r8
  117d56:	49 89 fe             	mov    %rdi,%r14
  117d59:	48 8d 05 10 e5 05 00 	lea    0x5e510(%rip),%rax        # 176270 <__asan_option_detect_stack_use_after_return>
  117d60:	83 38 00             	cmpl   $0x0,(%rax)
  117d63:	74 12                	je     117d77 <pqcrystals_kyber768_ref_polyvec_compress+0x3f>
  117d65:	bf 40 00 00 00       	mov    $0x40,%edi
  117d6a:	4d 89 c7             	mov    %r8,%r15
  117d6d:	e8 ce 91 f2 ff       	call   40f40 <__asan_stack_malloc_0>
  117d72:	4d 89 f8             	mov    %r15,%r8
  117d75:	eb 02                	jmp    117d79 <pqcrystals_kyber768_ref_polyvec_compress+0x41>
  117d77:	31 c0                	xor    %eax,%eax
  117d79:	48 89 c7             	mov    %rax,%rdi
  117d7c:	48 85 c0             	test   %rax,%rax
  117d7f:	75 0e                	jne    117d8f <pqcrystals_kyber768_ref_polyvec_compress+0x57>
  117d81:	48 89 e7             	mov    %rsp,%rdi
  117d84:	48 83 c7 c0          	add    $0xffffffffffffffc0,%rdi
  117d88:	48 83 e7 e0          	and    $0xffffffffffffffe0,%rdi
  117d8c:	48 89 fc             	mov    %rdi,%rsp
  117d8f:	48 89 bb 98 00 00 00 	mov    %rdi,0x98(%rbx)
  117d96:	4c 8d 67 20          	lea    0x20(%rdi),%r12
  117d9a:	48 c7 07 b3 8a b5 41 	movq   $0x41b58ab3,(%rdi)
  117da1:	48 8d 0d ab c0 01 00 	lea    0x1c0ab(%rip),%rcx        # 133e53 <_ZN11__sanitizerL10kExtraRegsE+0x12ca3>
  117da8:	48 89 4f 08          	mov    %rcx,0x8(%rdi)
  117dac:	48 8d 0d 85 ff ff ff 	lea    -0x7b(%rip),%rcx        # 117d38 <pqcrystals_kyber768_ref_polyvec_compress>
  117db3:	48 89 4f 10          	mov    %rcx,0x10(%rdi)
  117db7:	49 89 f9             	mov    %rdi,%r9
  117dba:	49 c1 e9 03          	shr    $0x3,%r9
  117dbe:	48 b9 f1 f1 f1 f1 f8 	movabs $0xf3f3f3f8f1f1f1f1,%rcx
  117dc5:	f3 f3 f3 
  117dc8:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  117dcf:	41 c6 81 04 80 ff 7f 	movb   $0x0,0x7fff8004(%r9)
  117dd6:	00 
  117dd7:	4d 85 c0             	test   %r8,%r8
  117dda:	0f 95 c1             	setne  %cl
  117ddd:	41 f6 c0 01          	test   $0x1,%r8b
  117de1:	41 0f 94 c7          	sete   %r15b
  117de5:	41 20 cf             	and    %cl,%r15b
  117de8:	4c 8d 5f 22          	lea    0x22(%rdi),%r11
  117dec:	48 8d 4f 24          	lea    0x24(%rdi),%rcx
  117df0:	48 89 4b 68          	mov    %rcx,0x68(%rbx)
  117df4:	48 8d 4f 26          	lea    0x26(%rdi),%rcx
  117df8:	48 89 4b 60          	mov    %rcx,0x60(%rbx)
  117dfc:	31 d2                	xor    %edx,%edx
  117dfe:	4d 89 c5             	mov    %r8,%r13
  117e01:	4c 89 c1             	mov    %r8,%rcx
  117e04:	4c 89 f6             	mov    %r14,%rsi
  117e07:	4d 89 c6             	mov    %r8,%r14
  117e0a:	eb 31                	jmp    117e3d <pqcrystals_kyber768_ref_polyvec_compress+0x105>
  117e0c:	0f 1f 40 00          	nopl   0x0(%rax)
  117e10:	48 8b 93 88 00 00 00 	mov    0x88(%rbx),%rdx
  117e17:	48 ff c2             	inc    %rdx
  117e1a:	4c 8b 73 78          	mov    0x78(%rbx),%r14
  117e1e:	49 81 c6 00 02 00 00 	add    $0x200,%r14
  117e25:	4c 8b ab 80 00 00 00 	mov    0x80(%rbx),%r13
  117e2c:	49 81 c5 00 02 00 00 	add    $0x200,%r13
  117e33:	48 83 fa 03          	cmp    $0x3,%rdx
  117e37:	0f 84 54 08 00 00    	je     118691 <pqcrystals_kyber768_ref_polyvec_compress+0x959>
  117e3d:	4d 85 c0             	test   %r8,%r8
  117e40:	0f 95 c1             	setne  %cl
  117e43:	48 89 93 88 00 00 00 	mov    %rdx,0x88(%rbx)
  117e4a:	48 c1 e2 09          	shl    $0x9,%rdx
  117e4e:	4c 01 c2             	add    %r8,%rdx
  117e51:	41 0f 95 c2          	setne  %r10b
  117e55:	48 89 53 58          	mov    %rdx,0x58(%rbx)
  117e59:	4c 39 c2             	cmp    %r8,%rdx
  117e5c:	0f 93 c2             	setae  %dl
  117e5f:	41 20 ca             	and    %cl,%r10b
  117e62:	41 20 d2             	and    %dl,%r10b
  117e65:	44 88 53 57          	mov    %r10b,0x57(%rbx)
  117e69:	4c 89 ab 80 00 00 00 	mov    %r13,0x80(%rbx)
  117e70:	4d 89 ea             	mov    %r13,%r10
  117e73:	4c 89 73 78          	mov    %r14,0x78(%rbx)
  117e77:	4c 89 73 70          	mov    %r14,0x70(%rbx)
  117e7b:	45 31 f6             	xor    %r14d,%r14d
  117e7e:	66 90                	xchg   %ax,%ax
  117e80:	4c 89 b3 90 00 00 00 	mov    %r14,0x90(%rbx)
  117e87:	45 31 ed             	xor    %r13d,%r13d
  117e8a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
  117e90:	45 84 ff             	test   %r15b,%r15b
  117e93:	0f 84 a9 00 00 00    	je     117f42 <pqcrystals_kyber768_ref_polyvec_compress+0x20a>
  117e99:	80 7b 57 00          	cmpb   $0x0,0x57(%rbx)
  117e9d:	0f 84 ee 00 00 00    	je     117f91 <pqcrystals_kyber768_ref_polyvec_compress+0x259>
  117ea3:	45 84 ff             	test   %r15b,%r15b
  117ea6:	0f 84 37 01 00 00    	je     117fe3 <pqcrystals_kyber768_ref_polyvec_compress+0x2ab>
  117eac:	48 8b 4b 70          	mov    0x70(%rbx),%rcx
  117eb0:	4e 8d 34 29          	lea    (%rcx,%r13,1),%r14
  117eb4:	4d 85 c0             	test   %r8,%r8
  117eb7:	0f 84 71 01 00 00    	je     11802e <pqcrystals_kyber768_ref_polyvec_compress+0x2f6>
  117ebd:	4d 85 f6             	test   %r14,%r14
  117ec0:	0f 84 68 01 00 00    	je     11802e <pqcrystals_kyber768_ref_polyvec_compress+0x2f6>
  117ec6:	4c 3b 73 58          	cmp    0x58(%rbx),%r14
  117eca:	0f 82 5e 01 00 00    	jb     11802e <pqcrystals_kyber768_ref_polyvec_compress+0x2f6>
  117ed0:	45 84 ff             	test   %r15b,%r15b
  117ed3:	0f 84 a9 01 00 00    	je     118082 <pqcrystals_kyber768_ref_polyvec_compress+0x34a>
  117ed9:	4c 89 f1             	mov    %r14,%rcx
  117edc:	48 c1 e9 03          	shr    $0x3,%rcx
  117ee0:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  117ee7:	84 c9                	test   %cl,%cl
  117ee9:	75 46                	jne    117f31 <pqcrystals_kyber768_ref_polyvec_compress+0x1f9>
  117eeb:	43 0f bf 0c 2a       	movswl (%r10,%r13,1),%ecx
  117ef0:	89 ca                	mov    %ecx,%edx
  117ef2:	c1 ea 0f             	shr    $0xf,%edx
  117ef5:	81 e2 01 0d 00 00    	and    $0xd01,%edx
  117efb:	01 ca                	add    %ecx,%edx
  117efd:	0f b7 ca             	movzwl %dx,%ecx
  117f00:	48 69 c9 00 dc be 4e 	imul   $0x4ebedc00,%rcx,%rcx
  117f07:	ba 37 d5 09 80       	mov    $0x8009d537,%edx
  117f0c:	48 01 d1             	add    %rdx,%rcx
  117f0f:	48 c1 e9 20          	shr    $0x20,%rcx
  117f13:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
  117f19:	66 43 89 0c 2c       	mov    %cx,(%r12,%r13,1)
  117f1e:	49 83 c5 02          	add    $0x2,%r13
  117f22:	49 83 fd 08          	cmp    $0x8,%r13
  117f26:	0f 85 64 ff ff ff    	jne    117e90 <pqcrystals_kyber768_ref_polyvec_compress+0x158>
  117f2c:	e9 9f 01 00 00       	jmp    1180d0 <pqcrystals_kyber768_ref_polyvec_compress+0x398>
  117f31:	44 89 f2             	mov    %r14d,%edx
  117f34:	80 e2 07             	and    $0x7,%dl
  117f37:	fe c2                	inc    %dl
  117f39:	38 ca                	cmp    %cl,%dl
  117f3b:	7c ae                	jl     117eeb <pqcrystals_kyber768_ref_polyvec_compress+0x1b3>
  117f3d:	e9 97 07 00 00       	jmp    1186d9 <pqcrystals_kyber768_ref_polyvec_compress+0x9a1>
  117f42:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  117f46:	48 8d 3d 13 9a 04 00 	lea    0x49a13(%rip),%rdi        # 161960 <_ZL17kSuppressionTypes+0x1f10>
  117f4d:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  117f51:	4c 89 c6             	mov    %r8,%rsi
  117f54:	48 89 43 30          	mov    %rax,0x30(%rbx)
  117f58:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  117f5c:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  117f60:	4d 89 de             	mov    %r11,%r14
  117f63:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  117f67:	e8 04 f0 fe ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  117f6c:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  117f70:	4d 89 f3             	mov    %r14,%r11
  117f73:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  117f77:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  117f7b:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  117f7f:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  117f83:	48 8b 43 30          	mov    0x30(%rbx),%rax
  117f87:	80 7b 57 00          	cmpb   $0x0,0x57(%rbx)
  117f8b:	0f 85 12 ff ff ff    	jne    117ea3 <pqcrystals_kyber768_ref_polyvec_compress+0x16b>
  117f91:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  117f95:	48 8d 3d e4 99 04 00 	lea    0x499e4(%rip),%rdi        # 161980 <_ZL17kSuppressionTypes+0x1f30>
  117f9c:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  117fa0:	4c 89 c6             	mov    %r8,%rsi
  117fa3:	48 8b 53 58          	mov    0x58(%rbx),%rdx
  117fa7:	48 89 43 30          	mov    %rax,0x30(%rbx)
  117fab:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  117faf:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  117fb3:	4d 89 de             	mov    %r11,%r14
  117fb6:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  117fba:	e8 01 26 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  117fbf:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  117fc3:	4d 89 f3             	mov    %r14,%r11
  117fc6:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  117fca:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  117fce:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  117fd2:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  117fd6:	48 8b 43 30          	mov    0x30(%rbx),%rax
  117fda:	45 84 ff             	test   %r15b,%r15b
  117fdd:	0f 85 c9 fe ff ff    	jne    117eac <pqcrystals_kyber768_ref_polyvec_compress+0x174>
  117fe3:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  117fe7:	48 8d 3d a2 99 04 00 	lea    0x499a2(%rip),%rdi        # 161990 <_ZL17kSuppressionTypes+0x1f40>
  117fee:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  117ff2:	48 8b 73 58          	mov    0x58(%rbx),%rsi
  117ff6:	48 89 43 30          	mov    %rax,0x30(%rbx)
  117ffa:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  117ffe:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118002:	4d 89 de             	mov    %r11,%r14
  118005:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118009:	e8 62 ef fe ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  11800e:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118012:	4d 89 f3             	mov    %r14,%r11
  118015:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118019:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11801d:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118021:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118025:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118029:	e9 7e fe ff ff       	jmp    117eac <pqcrystals_kyber768_ref_polyvec_compress+0x174>
  11802e:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118032:	48 8d 3d 77 99 04 00 	lea    0x49977(%rip),%rdi        # 1619b0 <_ZL17kSuppressionTypes+0x1f60>
  118039:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11803d:	48 8b 73 58          	mov    0x58(%rbx),%rsi
  118041:	4c 89 f2             	mov    %r14,%rdx
  118044:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118048:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11804c:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118050:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  118054:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118058:	e8 63 25 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  11805d:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118061:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  118065:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118069:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11806d:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118071:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118075:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118079:	45 84 ff             	test   %r15b,%r15b
  11807c:	0f 85 57 fe ff ff    	jne    117ed9 <pqcrystals_kyber768_ref_polyvec_compress+0x1a1>
  118082:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118086:	48 8d 3d 33 99 04 00 	lea    0x49933(%rip),%rdi        # 1619c0 <_ZL17kSuppressionTypes+0x1f70>
  11808d:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  118091:	4c 89 f6             	mov    %r14,%rsi
  118094:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118098:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11809c:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1180a0:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  1180a4:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1180a8:	e8 c3 ee fe ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  1180ad:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1180b1:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  1180b5:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1180b9:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1180bd:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  1180c1:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1180c5:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1180c9:	e9 0b fe ff ff       	jmp    117ed9 <pqcrystals_kyber768_ref_polyvec_compress+0x1a1>
  1180ce:	66 90                	xchg   %ax,%ax
  1180d0:	45 0f b6 34 24       	movzbl (%r12),%r14d
  1180d5:	48 85 f6             	test   %rsi,%rsi
  1180d8:	0f 84 e4 01 00 00    	je     1182c2 <pqcrystals_kyber768_ref_polyvec_compress+0x58a>
  1180de:	48 89 f1             	mov    %rsi,%rcx
  1180e1:	48 c1 e9 03          	shr    $0x3,%rcx
  1180e5:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1180ec:	84 c9                	test   %cl,%cl
  1180ee:	0f 85 57 01 00 00    	jne    11824b <pqcrystals_kyber768_ref_polyvec_compress+0x513>
  1180f4:	44 88 36             	mov    %r14b,(%rsi)
  1180f7:	41 0f b6 54 24 01    	movzbl 0x1(%r12),%edx
  1180fd:	49 83 fc fe          	cmp    $0xfffffffffffffffe,%r12
  118101:	0f 84 15 02 00 00    	je     11831c <pqcrystals_kyber768_ref_polyvec_compress+0x5e4>
  118107:	45 0f b6 6c 24 02    	movzbl 0x2(%r12),%r13d
  11810d:	4c 8d 76 01          	lea    0x1(%rsi),%r14
  118111:	48 83 fe ff          	cmp    $0xffffffffffffffff,%rsi
  118115:	0f 84 53 02 00 00    	je     11836e <pqcrystals_kyber768_ref_polyvec_compress+0x636>
  11811b:	4c 89 f1             	mov    %r14,%rcx
  11811e:	48 c1 e9 03          	shr    $0x3,%rcx
  118122:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  118129:	84 c9                	test   %cl,%cl
  11812b:	0f 85 2c 01 00 00    	jne    11825d <pqcrystals_kyber768_ref_polyvec_compress+0x525>
  118131:	41 c0 e5 02          	shl    $0x2,%r13b
  118135:	41 08 d5             	or     %dl,%r13b
  118138:	45 88 2e             	mov    %r13b,(%r14)
  11813b:	49 83 fc fe          	cmp    $0xfffffffffffffffe,%r12
  11813f:	0f 84 80 02 00 00    	je     1183c5 <pqcrystals_kyber768_ref_polyvec_compress+0x68d>
  118145:	45 0f b7 6c 24 02    	movzwl 0x2(%r12),%r13d
  11814b:	49 83 fc fc          	cmp    $0xfffffffffffffffc,%r12
  11814f:	0f 83 bb 02 00 00    	jae    118410 <pqcrystals_kyber768_ref_polyvec_compress+0x6d8>
  118155:	45 0f b6 74 24 04    	movzbl 0x4(%r12),%r14d
  11815b:	48 8d 56 02          	lea    0x2(%rsi),%rdx
  11815f:	48 83 fe fe          	cmp    $0xfffffffffffffffe,%rsi
  118163:	0f 83 f5 02 00 00    	jae    11845e <pqcrystals_kyber768_ref_polyvec_compress+0x726>
  118169:	48 89 d1             	mov    %rdx,%rcx
  11816c:	48 c1 e9 03          	shr    $0x3,%rcx
  118170:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  118177:	84 c9                	test   %cl,%cl
  118179:	0f 85 f8 00 00 00    	jne    118277 <pqcrystals_kyber768_ref_polyvec_compress+0x53f>
  11817f:	41 c1 ed 06          	shr    $0x6,%r13d
  118183:	41 c0 e6 04          	shl    $0x4,%r14b
  118187:	45 08 ee             	or     %r13b,%r14b
  11818a:	44 88 32             	mov    %r14b,(%rdx)
  11818d:	49 83 fc fc          	cmp    $0xfffffffffffffffc,%r12
  118191:	0f 83 20 03 00 00    	jae    1184b7 <pqcrystals_kyber768_ref_polyvec_compress+0x77f>
  118197:	45 0f b7 6c 24 04    	movzwl 0x4(%r12),%r13d
  11819d:	49 83 fc fa          	cmp    $0xfffffffffffffffa,%r12
  1181a1:	0f 83 5c 03 00 00    	jae    118503 <pqcrystals_kyber768_ref_polyvec_compress+0x7cb>
  1181a7:	45 0f b6 74 24 06    	movzbl 0x6(%r12),%r14d
  1181ad:	48 8d 56 03          	lea    0x3(%rsi),%rdx
  1181b1:	48 83 fe fd          	cmp    $0xfffffffffffffffd,%rsi
  1181b5:	0f 83 96 03 00 00    	jae    118551 <pqcrystals_kyber768_ref_polyvec_compress+0x819>
  1181bb:	48 89 d1             	mov    %rdx,%rcx
  1181be:	48 c1 e9 03          	shr    $0x3,%rcx
  1181c2:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1181c9:	84 c9                	test   %cl,%cl
  1181cb:	0f 85 c2 00 00 00    	jne    118293 <pqcrystals_kyber768_ref_polyvec_compress+0x55b>
  1181d1:	41 c1 ed 04          	shr    $0x4,%r13d
  1181d5:	41 c0 e6 06          	shl    $0x6,%r14b
  1181d9:	45 08 ee             	or     %r13b,%r14b
  1181dc:	44 88 32             	mov    %r14b,(%rdx)
  1181df:	49 83 fc fa          	cmp    $0xfffffffffffffffa,%r12
  1181e3:	0f 83 c1 03 00 00    	jae    1185aa <pqcrystals_kyber768_ref_polyvec_compress+0x872>
  1181e9:	45 0f b7 6c 24 06    	movzwl 0x6(%r12),%r13d
  1181ef:	4c 8d 76 04          	lea    0x4(%rsi),%r14
  1181f3:	48 83 fe fc          	cmp    $0xfffffffffffffffc,%rsi
  1181f7:	0f 83 f9 03 00 00    	jae    1185f6 <pqcrystals_kyber768_ref_polyvec_compress+0x8be>
  1181fd:	4c 89 f1             	mov    %r14,%rcx
  118200:	48 c1 e9 03          	shr    $0x3,%rcx
  118204:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  11820b:	84 c9                	test   %cl,%cl
  11820d:	0f 85 9c 00 00 00    	jne    1182af <pqcrystals_kyber768_ref_polyvec_compress+0x577>
  118213:	41 c1 ed 02          	shr    $0x2,%r13d
  118217:	44 88 6e 04          	mov    %r13b,0x4(%rsi)
  11821b:	48 83 fe fb          	cmp    $0xfffffffffffffffb,%rsi
  11821f:	4c 8b b3 90 00 00 00 	mov    0x90(%rbx),%r14
  118226:	0f 83 1a 04 00 00    	jae    118646 <pqcrystals_kyber768_ref_polyvec_compress+0x90e>
  11822c:	48 83 c6 05          	add    $0x5,%rsi
  118230:	49 ff c6             	inc    %r14
  118233:	48 83 43 70 08       	addq   $0x8,0x70(%rbx)
  118238:	49 83 c2 08          	add    $0x8,%r10
  11823c:	49 83 fe 40          	cmp    $0x40,%r14
  118240:	0f 85 3a fc ff ff    	jne    117e80 <pqcrystals_kyber768_ref_polyvec_compress+0x148>
  118246:	e9 c5 fb ff ff       	jmp    117e10 <pqcrystals_kyber768_ref_polyvec_compress+0xd8>
  11824b:	89 f2                	mov    %esi,%edx
  11824d:	80 e2 07             	and    $0x7,%dl
  118250:	38 ca                	cmp    %cl,%dl
  118252:	0f 8c 9c fe ff ff    	jl     1180f4 <pqcrystals_kyber768_ref_polyvec_compress+0x3bc>
  118258:	e9 84 04 00 00       	jmp    1186e1 <pqcrystals_kyber768_ref_polyvec_compress+0x9a9>
  11825d:	88 53 40             	mov    %dl,0x40(%rbx)
  118260:	44 89 f2             	mov    %r14d,%edx
  118263:	80 e2 07             	and    $0x7,%dl
  118266:	38 ca                	cmp    %cl,%dl
  118268:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  11826c:	0f 8c bf fe ff ff    	jl     118131 <pqcrystals_kyber768_ref_polyvec_compress+0x3f9>
  118272:	e9 72 04 00 00       	jmp    1186e9 <pqcrystals_kyber768_ref_polyvec_compress+0x9b1>
  118277:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  11827b:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  11827f:	80 e2 07             	and    $0x7,%dl
  118282:	38 ca                	cmp    %cl,%dl
  118284:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  118288:	0f 8c f1 fe ff ff    	jl     11817f <pqcrystals_kyber768_ref_polyvec_compress+0x447>
  11828e:	e9 5e 04 00 00       	jmp    1186f1 <pqcrystals_kyber768_ref_polyvec_compress+0x9b9>
  118293:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  118297:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  11829b:	80 e2 07             	and    $0x7,%dl
  11829e:	38 ca                	cmp    %cl,%dl
  1182a0:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  1182a4:	0f 8c 27 ff ff ff    	jl     1181d1 <pqcrystals_kyber768_ref_polyvec_compress+0x499>
  1182aa:	e9 4a 04 00 00       	jmp    1186f9 <pqcrystals_kyber768_ref_polyvec_compress+0x9c1>
  1182af:	44 89 f2             	mov    %r14d,%edx
  1182b2:	80 e2 07             	and    $0x7,%dl
  1182b5:	38 ca                	cmp    %cl,%dl
  1182b7:	0f 8c 56 ff ff ff    	jl     118213 <pqcrystals_kyber768_ref_polyvec_compress+0x4db>
  1182bd:	e9 3f 04 00 00       	jmp    118701 <pqcrystals_kyber768_ref_polyvec_compress+0x9c9>
  1182c2:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1182c6:	48 8d 3d 13 97 04 00 	lea    0x49713(%rip),%rdi        # 1619e0 <_ZL17kSuppressionTypes+0x1f90>
  1182cd:	49 89 f5             	mov    %rsi,%r13
  1182d0:	31 f6                	xor    %esi,%esi
  1182d2:	31 d2                	xor    %edx,%edx
  1182d4:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1182d8:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  1182dc:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1182e0:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  1182e4:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1182e8:	e8 d3 22 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1182ed:	48 8d 3d fc 96 04 00 	lea    0x496fc(%rip),%rdi        # 1619f0 <_ZL17kSuppressionTypes+0x1fa0>
  1182f4:	4c 89 ee             	mov    %r13,%rsi
  1182f7:	e8 74 ec fe ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  1182fc:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118300:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  118304:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118308:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11830c:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118310:	4c 89 ee             	mov    %r13,%rsi
  118313:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118317:	e9 c2 fd ff ff       	jmp    1180de <pqcrystals_kyber768_ref_polyvec_compress+0x3a6>
  11831c:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118320:	48 8d 3d e9 96 04 00 	lea    0x496e9(%rip),%rdi        # 161a10 <_ZL17kSuppressionTypes+0x1fc0>
  118327:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11832b:	4c 89 e6             	mov    %r12,%rsi
  11832e:	88 53 40             	mov    %dl,0x40(%rbx)
  118331:	4c 89 da             	mov    %r11,%rdx
  118334:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118338:	4d 89 c5             	mov    %r8,%r13
  11833b:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  11833f:	4d 89 de             	mov    %r11,%r14
  118342:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118346:	e8 75 22 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  11834b:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  11834f:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118353:	4d 89 f3             	mov    %r14,%r11
  118356:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11835a:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11835e:	4d 89 e8             	mov    %r13,%r8
  118361:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118365:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118369:	e9 99 fd ff ff       	jmp    118107 <pqcrystals_kyber768_ref_polyvec_compress+0x3cf>
  11836e:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118372:	48 8d 3d a7 96 04 00 	lea    0x496a7(%rip),%rdi        # 161a20 <_ZL17kSuppressionTypes+0x1fd0>
  118379:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11837d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118381:	88 53 40             	mov    %dl,0x40(%rbx)
  118384:	4c 89 f2             	mov    %r14,%rdx
  118387:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11838b:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11838f:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118393:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  118397:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11839b:	e8 20 22 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1183a0:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  1183a4:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1183a8:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  1183ac:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1183b0:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1183b4:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  1183b8:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1183bc:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1183c0:	e9 56 fd ff ff       	jmp    11811b <pqcrystals_kyber768_ref_polyvec_compress+0x3e3>
  1183c5:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1183c9:	48 8d 3d 60 96 04 00 	lea    0x49660(%rip),%rdi        # 161a30 <_ZL17kSuppressionTypes+0x1fe0>
  1183d0:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1183d4:	4c 89 e6             	mov    %r12,%rsi
  1183d7:	4c 89 da             	mov    %r11,%rdx
  1183da:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1183de:	4d 89 c5             	mov    %r8,%r13
  1183e1:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1183e5:	4d 89 de             	mov    %r11,%r14
  1183e8:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1183ec:	e8 cf 21 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1183f1:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1183f5:	4d 89 f3             	mov    %r14,%r11
  1183f8:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1183fc:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118400:	4d 89 e8             	mov    %r13,%r8
  118403:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118407:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11840b:	e9 35 fd ff ff       	jmp    118145 <pqcrystals_kyber768_ref_polyvec_compress+0x40d>
  118410:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118414:	48 8d 3d 25 96 04 00 	lea    0x49625(%rip),%rdi        # 161a40 <_ZL17kSuppressionTypes+0x1ff0>
  11841b:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11841f:	4c 89 e6             	mov    %r12,%rsi
  118422:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  118426:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11842a:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11842e:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118432:	4d 89 de             	mov    %r11,%r14
  118435:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118439:	e8 82 21 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  11843e:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118442:	4d 89 f3             	mov    %r14,%r11
  118445:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118449:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11844d:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118451:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118455:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118459:	e9 f7 fc ff ff       	jmp    118155 <pqcrystals_kyber768_ref_polyvec_compress+0x41d>
  11845e:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118462:	48 8d 3d e7 95 04 00 	lea    0x495e7(%rip),%rdi        # 161a50 <_ZL17kSuppressionTypes+0x2000>
  118469:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11846d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118471:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  118475:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  118479:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11847d:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118481:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118485:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  118489:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11848d:	e8 2e 21 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118492:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  118496:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  11849a:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  11849e:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1184a2:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1184a6:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  1184aa:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1184ae:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1184b2:	e9 b2 fc ff ff       	jmp    118169 <pqcrystals_kyber768_ref_polyvec_compress+0x431>
  1184b7:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1184bb:	48 8d 3d 9e 95 04 00 	lea    0x4959e(%rip),%rdi        # 161a60 <_ZL17kSuppressionTypes+0x2010>
  1184c2:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1184c6:	4c 89 e6             	mov    %r12,%rsi
  1184c9:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  1184cd:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1184d1:	4d 89 c5             	mov    %r8,%r13
  1184d4:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1184d8:	4d 89 de             	mov    %r11,%r14
  1184db:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1184df:	e8 dc 20 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1184e4:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1184e8:	4d 89 f3             	mov    %r14,%r11
  1184eb:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1184ef:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1184f3:	4d 89 e8             	mov    %r13,%r8
  1184f6:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1184fa:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1184fe:	e9 94 fc ff ff       	jmp    118197 <pqcrystals_kyber768_ref_polyvec_compress+0x45f>
  118503:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118507:	48 8d 3d 62 95 04 00 	lea    0x49562(%rip),%rdi        # 161a70 <_ZL17kSuppressionTypes+0x2020>
  11850e:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  118512:	4c 89 e6             	mov    %r12,%rsi
  118515:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  118519:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11851d:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118521:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118525:	4d 89 de             	mov    %r11,%r14
  118528:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11852c:	e8 8f 20 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118531:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118535:	4d 89 f3             	mov    %r14,%r11
  118538:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11853c:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118540:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118544:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118548:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11854c:	e9 56 fc ff ff       	jmp    1181a7 <pqcrystals_kyber768_ref_polyvec_compress+0x46f>
  118551:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118555:	48 8d 3d 24 95 04 00 	lea    0x49524(%rip),%rdi        # 161a80 <_ZL17kSuppressionTypes+0x2030>
  11855c:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  118560:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118564:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  118568:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  11856c:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118570:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118574:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118578:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  11857c:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118580:	e8 3b 20 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118585:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  118589:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  11858d:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  118591:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118595:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118599:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  11859d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1185a1:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1185a5:	e9 11 fc ff ff       	jmp    1181bb <pqcrystals_kyber768_ref_polyvec_compress+0x483>
  1185aa:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1185ae:	48 8d 3d db 94 04 00 	lea    0x494db(%rip),%rdi        # 161a90 <_ZL17kSuppressionTypes+0x2040>
  1185b5:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1185b9:	4c 89 e6             	mov    %r12,%rsi
  1185bc:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  1185c0:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1185c4:	4d 89 c5             	mov    %r8,%r13
  1185c7:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1185cb:	4d 89 de             	mov    %r11,%r14
  1185ce:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1185d2:	e8 e9 1f ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1185d7:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1185db:	4d 89 f3             	mov    %r14,%r11
  1185de:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1185e2:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1185e6:	4d 89 e8             	mov    %r13,%r8
  1185e9:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1185ed:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1185f1:	e9 f3 fb ff ff       	jmp    1181e9 <pqcrystals_kyber768_ref_polyvec_compress+0x4b1>
  1185f6:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1185fa:	48 8d 3d 9f 94 04 00 	lea    0x4949f(%rip),%rdi        # 161aa0 <_ZL17kSuppressionTypes+0x2050>
  118601:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  118605:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118609:	4c 89 f2             	mov    %r14,%rdx
  11860c:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118610:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118614:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118618:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  11861c:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118620:	e8 9b 1f ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118625:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118629:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  11862d:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118631:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118635:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118639:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  11863d:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118641:	e9 b7 fb ff ff       	jmp    1181fd <pqcrystals_kyber768_ref_polyvec_compress+0x4c5>
  118646:	48 8d 56 05          	lea    0x5(%rsi),%rdx
  11864a:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  11864e:	48 8d 3d 5b 94 04 00 	lea    0x4945b(%rip),%rdi        # 161ab0 <_ZL17kSuppressionTypes+0x2060>
  118655:	49 89 f5             	mov    %rsi,%r13
  118658:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11865c:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118660:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118664:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  118668:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11866c:	e8 4f 1f ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118671:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118675:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  118679:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11867d:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118681:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118685:	4c 89 ee             	mov    %r13,%rsi
  118688:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11868c:	e9 9b fb ff ff       	jmp    11822c <pqcrystals_kyber768_ref_polyvec_compress+0x4f4>
  118691:	41 c6 81 04 80 ff 7f 	movb   $0xf8,0x7fff8004(%r9)
  118698:	f8 
  118699:	48 c7 07 0e 36 e0 45 	movq   $0x45e0360e,(%rdi)
  1186a0:	48 85 c0             	test   %rax,%rax
  1186a3:	74 1a                	je     1186bf <pqcrystals_kyber768_ref_polyvec_compress+0x987>
  1186a5:	48 b9 f5 f5 f5 f5 f5 	movabs $0xf5f5f5f5f5f5f5f5,%rcx
  1186ac:	f5 f5 f5 
  1186af:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  1186b6:	48 8b 40 38          	mov    0x38(%rax),%rax
  1186ba:	c6 00 00             	movb   $0x0,(%rax)
  1186bd:	eb 0b                	jmp    1186ca <pqcrystals_kyber768_ref_polyvec_compress+0x992>
  1186bf:	49 c7 81 00 80 ff 7f 	movq   $0x0,0x7fff8000(%r9)
  1186c6:	00 00 00 00 
  1186ca:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  1186ce:	5b                   	pop    %rbx
  1186cf:	41 5c                	pop    %r12
  1186d1:	41 5d                	pop    %r13
  1186d3:	41 5e                	pop    %r14
  1186d5:	41 5f                	pop    %r15
  1186d7:	5d                   	pop    %rbp
  1186d8:	c3                   	ret
  1186d9:	4c 89 f7             	mov    %r14,%rdi
  1186dc:	e8 bf d5 fb ff       	call   d5ca0 <__asan_report_load2>
  1186e1:	48 89 f7             	mov    %rsi,%rdi
  1186e4:	e8 b7 d8 fb ff       	call   d5fa0 <__asan_report_store1>
  1186e9:	4c 89 f7             	mov    %r14,%rdi
  1186ec:	e8 af d8 fb ff       	call   d5fa0 <__asan_report_store1>
  1186f1:	48 89 d7             	mov    %rdx,%rdi
  1186f4:	e8 a7 d8 fb ff       	call   d5fa0 <__asan_report_store1>
  1186f9:	48 89 d7             	mov    %rdx,%rdi
  1186fc:	e8 9f d8 fb ff       	call   d5fa0 <__asan_report_store1>
  118701:	4c 89 f7             	mov    %r14,%rdi
  118704:	e8 97 d8 fb ff       	call   d5fa0 <__asan_report_store1>

Disassembly of section .fini:
