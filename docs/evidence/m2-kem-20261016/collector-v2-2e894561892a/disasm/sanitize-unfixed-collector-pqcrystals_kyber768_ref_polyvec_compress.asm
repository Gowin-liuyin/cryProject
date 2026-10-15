
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-sanitize/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000117d28 <pqcrystals_kyber768_ref_polyvec_compress>:
  117d28:	55                   	push   %rbp
  117d29:	48 89 e5             	mov    %rsp,%rbp
  117d2c:	41 57                	push   %r15
  117d2e:	41 56                	push   %r14
  117d30:	41 55                	push   %r13
  117d32:	41 54                	push   %r12
  117d34:	53                   	push   %rbx
  117d35:	48 83 e4 e0          	and    $0xffffffffffffffe0,%rsp
  117d39:	48 81 ec c0 00 00 00 	sub    $0xc0,%rsp
  117d40:	48 89 e3             	mov    %rsp,%rbx
  117d43:	49 89 f0             	mov    %rsi,%r8
  117d46:	49 89 fe             	mov    %rdi,%r14
  117d49:	48 8d 05 20 e5 05 00 	lea    0x5e520(%rip),%rax        # 176270 <__asan_option_detect_stack_use_after_return>
  117d50:	83 38 00             	cmpl   $0x0,(%rax)
  117d53:	74 12                	je     117d67 <pqcrystals_kyber768_ref_polyvec_compress+0x3f>
  117d55:	bf 40 00 00 00       	mov    $0x40,%edi
  117d5a:	4d 89 c7             	mov    %r8,%r15
  117d5d:	e8 de 91 f2 ff       	call   40f40 <__asan_stack_malloc_0>
  117d62:	4d 89 f8             	mov    %r15,%r8
  117d65:	eb 02                	jmp    117d69 <pqcrystals_kyber768_ref_polyvec_compress+0x41>
  117d67:	31 c0                	xor    %eax,%eax
  117d69:	48 89 c7             	mov    %rax,%rdi
  117d6c:	48 85 c0             	test   %rax,%rax
  117d6f:	75 0e                	jne    117d7f <pqcrystals_kyber768_ref_polyvec_compress+0x57>
  117d71:	48 89 e7             	mov    %rsp,%rdi
  117d74:	48 83 c7 c0          	add    $0xffffffffffffffc0,%rdi
  117d78:	48 83 e7 e0          	and    $0xffffffffffffffe0,%rdi
  117d7c:	48 89 fc             	mov    %rdi,%rsp
  117d7f:	48 89 bb 98 00 00 00 	mov    %rdi,0x98(%rbx)
  117d86:	4c 8d 67 20          	lea    0x20(%rdi),%r12
  117d8a:	48 c7 07 b3 8a b5 41 	movq   $0x41b58ab3,(%rdi)
  117d91:	48 8d 0d c3 c0 01 00 	lea    0x1c0c3(%rip),%rcx        # 133e5b <_ZN11__sanitizerL10kExtraRegsE+0x12cab>
  117d98:	48 89 4f 08          	mov    %rcx,0x8(%rdi)
  117d9c:	48 8d 0d 85 ff ff ff 	lea    -0x7b(%rip),%rcx        # 117d28 <pqcrystals_kyber768_ref_polyvec_compress>
  117da3:	48 89 4f 10          	mov    %rcx,0x10(%rdi)
  117da7:	49 89 f9             	mov    %rdi,%r9
  117daa:	49 c1 e9 03          	shr    $0x3,%r9
  117dae:	48 b9 f1 f1 f1 f1 f8 	movabs $0xf3f3f3f8f1f1f1f1,%rcx
  117db5:	f3 f3 f3 
  117db8:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  117dbf:	41 c6 81 04 80 ff 7f 	movb   $0x0,0x7fff8004(%r9)
  117dc6:	00 
  117dc7:	4d 85 c0             	test   %r8,%r8
  117dca:	0f 95 c1             	setne  %cl
  117dcd:	41 f6 c0 01          	test   $0x1,%r8b
  117dd1:	41 0f 94 c7          	sete   %r15b
  117dd5:	41 20 cf             	and    %cl,%r15b
  117dd8:	4c 8d 5f 22          	lea    0x22(%rdi),%r11
  117ddc:	48 8d 4f 24          	lea    0x24(%rdi),%rcx
  117de0:	48 89 4b 68          	mov    %rcx,0x68(%rbx)
  117de4:	48 8d 4f 26          	lea    0x26(%rdi),%rcx
  117de8:	48 89 4b 60          	mov    %rcx,0x60(%rbx)
  117dec:	31 d2                	xor    %edx,%edx
  117dee:	4d 89 c5             	mov    %r8,%r13
  117df1:	4c 89 c1             	mov    %r8,%rcx
  117df4:	4c 89 f6             	mov    %r14,%rsi
  117df7:	4d 89 c6             	mov    %r8,%r14
  117dfa:	eb 31                	jmp    117e2d <pqcrystals_kyber768_ref_polyvec_compress+0x105>
  117dfc:	0f 1f 40 00          	nopl   0x0(%rax)
  117e00:	48 8b 93 88 00 00 00 	mov    0x88(%rbx),%rdx
  117e07:	48 ff c2             	inc    %rdx
  117e0a:	4c 8b 73 78          	mov    0x78(%rbx),%r14
  117e0e:	49 81 c6 00 02 00 00 	add    $0x200,%r14
  117e15:	4c 8b ab 80 00 00 00 	mov    0x80(%rbx),%r13
  117e1c:	49 81 c5 00 02 00 00 	add    $0x200,%r13
  117e23:	48 83 fa 03          	cmp    $0x3,%rdx
  117e27:	0f 84 54 08 00 00    	je     118681 <pqcrystals_kyber768_ref_polyvec_compress+0x959>
  117e2d:	4d 85 c0             	test   %r8,%r8
  117e30:	0f 95 c1             	setne  %cl
  117e33:	48 89 93 88 00 00 00 	mov    %rdx,0x88(%rbx)
  117e3a:	48 c1 e2 09          	shl    $0x9,%rdx
  117e3e:	4c 01 c2             	add    %r8,%rdx
  117e41:	41 0f 95 c2          	setne  %r10b
  117e45:	48 89 53 58          	mov    %rdx,0x58(%rbx)
  117e49:	4c 39 c2             	cmp    %r8,%rdx
  117e4c:	0f 93 c2             	setae  %dl
  117e4f:	41 20 ca             	and    %cl,%r10b
  117e52:	41 20 d2             	and    %dl,%r10b
  117e55:	44 88 53 57          	mov    %r10b,0x57(%rbx)
  117e59:	4c 89 ab 80 00 00 00 	mov    %r13,0x80(%rbx)
  117e60:	4d 89 ea             	mov    %r13,%r10
  117e63:	4c 89 73 78          	mov    %r14,0x78(%rbx)
  117e67:	4c 89 73 70          	mov    %r14,0x70(%rbx)
  117e6b:	45 31 f6             	xor    %r14d,%r14d
  117e6e:	66 90                	xchg   %ax,%ax
  117e70:	4c 89 b3 90 00 00 00 	mov    %r14,0x90(%rbx)
  117e77:	45 31 ed             	xor    %r13d,%r13d
  117e7a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
  117e80:	45 84 ff             	test   %r15b,%r15b
  117e83:	0f 84 aa 00 00 00    	je     117f33 <pqcrystals_kyber768_ref_polyvec_compress+0x20b>
  117e89:	80 7b 57 00          	cmpb   $0x0,0x57(%rbx)
  117e8d:	0f 84 ef 00 00 00    	je     117f82 <pqcrystals_kyber768_ref_polyvec_compress+0x25a>
  117e93:	45 84 ff             	test   %r15b,%r15b
  117e96:	0f 84 38 01 00 00    	je     117fd4 <pqcrystals_kyber768_ref_polyvec_compress+0x2ac>
  117e9c:	48 8b 4b 70          	mov    0x70(%rbx),%rcx
  117ea0:	4e 8d 34 29          	lea    (%rcx,%r13,1),%r14
  117ea4:	4d 85 c0             	test   %r8,%r8
  117ea7:	0f 84 72 01 00 00    	je     11801f <pqcrystals_kyber768_ref_polyvec_compress+0x2f7>
  117ead:	4d 85 f6             	test   %r14,%r14
  117eb0:	0f 84 69 01 00 00    	je     11801f <pqcrystals_kyber768_ref_polyvec_compress+0x2f7>
  117eb6:	4c 3b 73 58          	cmp    0x58(%rbx),%r14
  117eba:	0f 82 5f 01 00 00    	jb     11801f <pqcrystals_kyber768_ref_polyvec_compress+0x2f7>
  117ec0:	45 84 ff             	test   %r15b,%r15b
  117ec3:	0f 84 aa 01 00 00    	je     118073 <pqcrystals_kyber768_ref_polyvec_compress+0x34b>
  117ec9:	4c 89 f1             	mov    %r14,%rcx
  117ecc:	48 c1 e9 03          	shr    $0x3,%rcx
  117ed0:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  117ed7:	84 c9                	test   %cl,%cl
  117ed9:	75 47                	jne    117f22 <pqcrystals_kyber768_ref_polyvec_compress+0x1fa>
  117edb:	43 0f bf 0c 2a       	movswl (%r10,%r13,1),%ecx
  117ee0:	89 ca                	mov    %ecx,%edx
  117ee2:	c1 ea 0f             	shr    $0xf,%edx
  117ee5:	81 e2 01 0d 00 00    	and    $0xd01,%edx
  117eeb:	01 ca                	add    %ecx,%edx
  117eed:	0f b7 ca             	movzwl %dx,%ecx
  117ef0:	c1 e1 0a             	shl    $0xa,%ecx
  117ef3:	81 c1 80 06 00 00    	add    $0x680,%ecx
  117ef9:	48 69 c9 b5 db d7 09 	imul   $0x9d7dbb5,%rcx,%rcx
  117f00:	48 c1 e9 27          	shr    $0x27,%rcx
  117f04:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
  117f0a:	66 43 89 0c 2c       	mov    %cx,(%r12,%r13,1)
  117f0f:	49 83 c5 02          	add    $0x2,%r13
  117f13:	49 83 fd 08          	cmp    $0x8,%r13
  117f17:	0f 85 63 ff ff ff    	jne    117e80 <pqcrystals_kyber768_ref_polyvec_compress+0x158>
  117f1d:	e9 9e 01 00 00       	jmp    1180c0 <pqcrystals_kyber768_ref_polyvec_compress+0x398>
  117f22:	44 89 f2             	mov    %r14d,%edx
  117f25:	80 e2 07             	and    $0x7,%dl
  117f28:	fe c2                	inc    %dl
  117f2a:	38 ca                	cmp    %cl,%dl
  117f2c:	7c ad                	jl     117edb <pqcrystals_kyber768_ref_polyvec_compress+0x1b3>
  117f2e:	e9 96 07 00 00       	jmp    1186c9 <pqcrystals_kyber768_ref_polyvec_compress+0x9a1>
  117f33:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  117f37:	48 8d 3d 02 9a 04 00 	lea    0x49a02(%rip),%rdi        # 161940 <_ZL17kSuppressionTypes+0x1ef0>
  117f3e:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  117f42:	4c 89 c6             	mov    %r8,%rsi
  117f45:	48 89 43 30          	mov    %rax,0x30(%rbx)
  117f49:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  117f4d:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  117f51:	4d 89 de             	mov    %r11,%r14
  117f54:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  117f58:	e8 13 f0 fe ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  117f5d:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  117f61:	4d 89 f3             	mov    %r14,%r11
  117f64:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  117f68:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  117f6c:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  117f70:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  117f74:	48 8b 43 30          	mov    0x30(%rbx),%rax
  117f78:	80 7b 57 00          	cmpb   $0x0,0x57(%rbx)
  117f7c:	0f 85 11 ff ff ff    	jne    117e93 <pqcrystals_kyber768_ref_polyvec_compress+0x16b>
  117f82:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  117f86:	48 8d 3d d3 99 04 00 	lea    0x499d3(%rip),%rdi        # 161960 <_ZL17kSuppressionTypes+0x1f10>
  117f8d:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  117f91:	4c 89 c6             	mov    %r8,%rsi
  117f94:	48 8b 53 58          	mov    0x58(%rbx),%rdx
  117f98:	48 89 43 30          	mov    %rax,0x30(%rbx)
  117f9c:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  117fa0:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  117fa4:	4d 89 de             	mov    %r11,%r14
  117fa7:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  117fab:	e8 10 26 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  117fb0:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  117fb4:	4d 89 f3             	mov    %r14,%r11
  117fb7:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  117fbb:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  117fbf:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  117fc3:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  117fc7:	48 8b 43 30          	mov    0x30(%rbx),%rax
  117fcb:	45 84 ff             	test   %r15b,%r15b
  117fce:	0f 85 c8 fe ff ff    	jne    117e9c <pqcrystals_kyber768_ref_polyvec_compress+0x174>
  117fd4:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  117fd8:	48 8d 3d 91 99 04 00 	lea    0x49991(%rip),%rdi        # 161970 <_ZL17kSuppressionTypes+0x1f20>
  117fdf:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  117fe3:	48 8b 73 58          	mov    0x58(%rbx),%rsi
  117fe7:	48 89 43 30          	mov    %rax,0x30(%rbx)
  117feb:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  117fef:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  117ff3:	4d 89 de             	mov    %r11,%r14
  117ff6:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  117ffa:	e8 71 ef fe ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  117fff:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118003:	4d 89 f3             	mov    %r14,%r11
  118006:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11800a:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11800e:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118012:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118016:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11801a:	e9 7d fe ff ff       	jmp    117e9c <pqcrystals_kyber768_ref_polyvec_compress+0x174>
  11801f:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118023:	48 8d 3d 66 99 04 00 	lea    0x49966(%rip),%rdi        # 161990 <_ZL17kSuppressionTypes+0x1f40>
  11802a:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11802e:	48 8b 73 58          	mov    0x58(%rbx),%rsi
  118032:	4c 89 f2             	mov    %r14,%rdx
  118035:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118039:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11803d:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118041:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  118045:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118049:	e8 72 25 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  11804e:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118052:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  118056:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11805a:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11805e:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118062:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118066:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11806a:	45 84 ff             	test   %r15b,%r15b
  11806d:	0f 85 56 fe ff ff    	jne    117ec9 <pqcrystals_kyber768_ref_polyvec_compress+0x1a1>
  118073:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118077:	48 8d 3d 22 99 04 00 	lea    0x49922(%rip),%rdi        # 1619a0 <_ZL17kSuppressionTypes+0x1f50>
  11807e:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  118082:	4c 89 f6             	mov    %r14,%rsi
  118085:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118089:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11808d:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118091:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  118095:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118099:	e8 d2 ee fe ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  11809e:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1180a2:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  1180a6:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1180aa:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1180ae:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  1180b2:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1180b6:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1180ba:	e9 0a fe ff ff       	jmp    117ec9 <pqcrystals_kyber768_ref_polyvec_compress+0x1a1>
  1180bf:	90                   	nop
  1180c0:	45 0f b6 34 24       	movzbl (%r12),%r14d
  1180c5:	48 85 f6             	test   %rsi,%rsi
  1180c8:	0f 84 e4 01 00 00    	je     1182b2 <pqcrystals_kyber768_ref_polyvec_compress+0x58a>
  1180ce:	48 89 f1             	mov    %rsi,%rcx
  1180d1:	48 c1 e9 03          	shr    $0x3,%rcx
  1180d5:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1180dc:	84 c9                	test   %cl,%cl
  1180de:	0f 85 57 01 00 00    	jne    11823b <pqcrystals_kyber768_ref_polyvec_compress+0x513>
  1180e4:	44 88 36             	mov    %r14b,(%rsi)
  1180e7:	41 0f b6 54 24 01    	movzbl 0x1(%r12),%edx
  1180ed:	49 83 fc fe          	cmp    $0xfffffffffffffffe,%r12
  1180f1:	0f 84 15 02 00 00    	je     11830c <pqcrystals_kyber768_ref_polyvec_compress+0x5e4>
  1180f7:	45 0f b6 6c 24 02    	movzbl 0x2(%r12),%r13d
  1180fd:	4c 8d 76 01          	lea    0x1(%rsi),%r14
  118101:	48 83 fe ff          	cmp    $0xffffffffffffffff,%rsi
  118105:	0f 84 53 02 00 00    	je     11835e <pqcrystals_kyber768_ref_polyvec_compress+0x636>
  11810b:	4c 89 f1             	mov    %r14,%rcx
  11810e:	48 c1 e9 03          	shr    $0x3,%rcx
  118112:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  118119:	84 c9                	test   %cl,%cl
  11811b:	0f 85 2c 01 00 00    	jne    11824d <pqcrystals_kyber768_ref_polyvec_compress+0x525>
  118121:	41 c0 e5 02          	shl    $0x2,%r13b
  118125:	41 08 d5             	or     %dl,%r13b
  118128:	45 88 2e             	mov    %r13b,(%r14)
  11812b:	49 83 fc fe          	cmp    $0xfffffffffffffffe,%r12
  11812f:	0f 84 80 02 00 00    	je     1183b5 <pqcrystals_kyber768_ref_polyvec_compress+0x68d>
  118135:	45 0f b7 6c 24 02    	movzwl 0x2(%r12),%r13d
  11813b:	49 83 fc fc          	cmp    $0xfffffffffffffffc,%r12
  11813f:	0f 83 bb 02 00 00    	jae    118400 <pqcrystals_kyber768_ref_polyvec_compress+0x6d8>
  118145:	45 0f b6 74 24 04    	movzbl 0x4(%r12),%r14d
  11814b:	48 8d 56 02          	lea    0x2(%rsi),%rdx
  11814f:	48 83 fe fe          	cmp    $0xfffffffffffffffe,%rsi
  118153:	0f 83 f5 02 00 00    	jae    11844e <pqcrystals_kyber768_ref_polyvec_compress+0x726>
  118159:	48 89 d1             	mov    %rdx,%rcx
  11815c:	48 c1 e9 03          	shr    $0x3,%rcx
  118160:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  118167:	84 c9                	test   %cl,%cl
  118169:	0f 85 f8 00 00 00    	jne    118267 <pqcrystals_kyber768_ref_polyvec_compress+0x53f>
  11816f:	41 c1 ed 06          	shr    $0x6,%r13d
  118173:	41 c0 e6 04          	shl    $0x4,%r14b
  118177:	45 08 ee             	or     %r13b,%r14b
  11817a:	44 88 32             	mov    %r14b,(%rdx)
  11817d:	49 83 fc fc          	cmp    $0xfffffffffffffffc,%r12
  118181:	0f 83 20 03 00 00    	jae    1184a7 <pqcrystals_kyber768_ref_polyvec_compress+0x77f>
  118187:	45 0f b7 6c 24 04    	movzwl 0x4(%r12),%r13d
  11818d:	49 83 fc fa          	cmp    $0xfffffffffffffffa,%r12
  118191:	0f 83 5c 03 00 00    	jae    1184f3 <pqcrystals_kyber768_ref_polyvec_compress+0x7cb>
  118197:	45 0f b6 74 24 06    	movzbl 0x6(%r12),%r14d
  11819d:	48 8d 56 03          	lea    0x3(%rsi),%rdx
  1181a1:	48 83 fe fd          	cmp    $0xfffffffffffffffd,%rsi
  1181a5:	0f 83 96 03 00 00    	jae    118541 <pqcrystals_kyber768_ref_polyvec_compress+0x819>
  1181ab:	48 89 d1             	mov    %rdx,%rcx
  1181ae:	48 c1 e9 03          	shr    $0x3,%rcx
  1181b2:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1181b9:	84 c9                	test   %cl,%cl
  1181bb:	0f 85 c2 00 00 00    	jne    118283 <pqcrystals_kyber768_ref_polyvec_compress+0x55b>
  1181c1:	41 c1 ed 04          	shr    $0x4,%r13d
  1181c5:	41 c0 e6 06          	shl    $0x6,%r14b
  1181c9:	45 08 ee             	or     %r13b,%r14b
  1181cc:	44 88 32             	mov    %r14b,(%rdx)
  1181cf:	49 83 fc fa          	cmp    $0xfffffffffffffffa,%r12
  1181d3:	0f 83 c1 03 00 00    	jae    11859a <pqcrystals_kyber768_ref_polyvec_compress+0x872>
  1181d9:	45 0f b7 6c 24 06    	movzwl 0x6(%r12),%r13d
  1181df:	4c 8d 76 04          	lea    0x4(%rsi),%r14
  1181e3:	48 83 fe fc          	cmp    $0xfffffffffffffffc,%rsi
  1181e7:	0f 83 f9 03 00 00    	jae    1185e6 <pqcrystals_kyber768_ref_polyvec_compress+0x8be>
  1181ed:	4c 89 f1             	mov    %r14,%rcx
  1181f0:	48 c1 e9 03          	shr    $0x3,%rcx
  1181f4:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1181fb:	84 c9                	test   %cl,%cl
  1181fd:	0f 85 9c 00 00 00    	jne    11829f <pqcrystals_kyber768_ref_polyvec_compress+0x577>
  118203:	41 c1 ed 02          	shr    $0x2,%r13d
  118207:	44 88 6e 04          	mov    %r13b,0x4(%rsi)
  11820b:	48 83 fe fb          	cmp    $0xfffffffffffffffb,%rsi
  11820f:	4c 8b b3 90 00 00 00 	mov    0x90(%rbx),%r14
  118216:	0f 83 1a 04 00 00    	jae    118636 <pqcrystals_kyber768_ref_polyvec_compress+0x90e>
  11821c:	48 83 c6 05          	add    $0x5,%rsi
  118220:	49 ff c6             	inc    %r14
  118223:	48 83 43 70 08       	addq   $0x8,0x70(%rbx)
  118228:	49 83 c2 08          	add    $0x8,%r10
  11822c:	49 83 fe 40          	cmp    $0x40,%r14
  118230:	0f 85 3a fc ff ff    	jne    117e70 <pqcrystals_kyber768_ref_polyvec_compress+0x148>
  118236:	e9 c5 fb ff ff       	jmp    117e00 <pqcrystals_kyber768_ref_polyvec_compress+0xd8>
  11823b:	89 f2                	mov    %esi,%edx
  11823d:	80 e2 07             	and    $0x7,%dl
  118240:	38 ca                	cmp    %cl,%dl
  118242:	0f 8c 9c fe ff ff    	jl     1180e4 <pqcrystals_kyber768_ref_polyvec_compress+0x3bc>
  118248:	e9 84 04 00 00       	jmp    1186d1 <pqcrystals_kyber768_ref_polyvec_compress+0x9a9>
  11824d:	88 53 40             	mov    %dl,0x40(%rbx)
  118250:	44 89 f2             	mov    %r14d,%edx
  118253:	80 e2 07             	and    $0x7,%dl
  118256:	38 ca                	cmp    %cl,%dl
  118258:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  11825c:	0f 8c bf fe ff ff    	jl     118121 <pqcrystals_kyber768_ref_polyvec_compress+0x3f9>
  118262:	e9 72 04 00 00       	jmp    1186d9 <pqcrystals_kyber768_ref_polyvec_compress+0x9b1>
  118267:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  11826b:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  11826f:	80 e2 07             	and    $0x7,%dl
  118272:	38 ca                	cmp    %cl,%dl
  118274:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  118278:	0f 8c f1 fe ff ff    	jl     11816f <pqcrystals_kyber768_ref_polyvec_compress+0x447>
  11827e:	e9 5e 04 00 00       	jmp    1186e1 <pqcrystals_kyber768_ref_polyvec_compress+0x9b9>
  118283:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  118287:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  11828b:	80 e2 07             	and    $0x7,%dl
  11828e:	38 ca                	cmp    %cl,%dl
  118290:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  118294:	0f 8c 27 ff ff ff    	jl     1181c1 <pqcrystals_kyber768_ref_polyvec_compress+0x499>
  11829a:	e9 4a 04 00 00       	jmp    1186e9 <pqcrystals_kyber768_ref_polyvec_compress+0x9c1>
  11829f:	44 89 f2             	mov    %r14d,%edx
  1182a2:	80 e2 07             	and    $0x7,%dl
  1182a5:	38 ca                	cmp    %cl,%dl
  1182a7:	0f 8c 56 ff ff ff    	jl     118203 <pqcrystals_kyber768_ref_polyvec_compress+0x4db>
  1182ad:	e9 3f 04 00 00       	jmp    1186f1 <pqcrystals_kyber768_ref_polyvec_compress+0x9c9>
  1182b2:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1182b6:	48 8d 3d 03 97 04 00 	lea    0x49703(%rip),%rdi        # 1619c0 <_ZL17kSuppressionTypes+0x1f70>
  1182bd:	49 89 f5             	mov    %rsi,%r13
  1182c0:	31 f6                	xor    %esi,%esi
  1182c2:	31 d2                	xor    %edx,%edx
  1182c4:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1182c8:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  1182cc:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1182d0:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  1182d4:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1182d8:	e8 e3 22 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1182dd:	48 8d 3d ec 96 04 00 	lea    0x496ec(%rip),%rdi        # 1619d0 <_ZL17kSuppressionTypes+0x1f80>
  1182e4:	4c 89 ee             	mov    %r13,%rsi
  1182e7:	e8 84 ec fe ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  1182ec:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1182f0:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  1182f4:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1182f8:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1182fc:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118300:	4c 89 ee             	mov    %r13,%rsi
  118303:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118307:	e9 c2 fd ff ff       	jmp    1180ce <pqcrystals_kyber768_ref_polyvec_compress+0x3a6>
  11830c:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118310:	48 8d 3d d9 96 04 00 	lea    0x496d9(%rip),%rdi        # 1619f0 <_ZL17kSuppressionTypes+0x1fa0>
  118317:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11831b:	4c 89 e6             	mov    %r12,%rsi
  11831e:	88 53 40             	mov    %dl,0x40(%rbx)
  118321:	4c 89 da             	mov    %r11,%rdx
  118324:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118328:	4d 89 c5             	mov    %r8,%r13
  11832b:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  11832f:	4d 89 de             	mov    %r11,%r14
  118332:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118336:	e8 85 22 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  11833b:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  11833f:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118343:	4d 89 f3             	mov    %r14,%r11
  118346:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11834a:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11834e:	4d 89 e8             	mov    %r13,%r8
  118351:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118355:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118359:	e9 99 fd ff ff       	jmp    1180f7 <pqcrystals_kyber768_ref_polyvec_compress+0x3cf>
  11835e:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118362:	48 8d 3d 97 96 04 00 	lea    0x49697(%rip),%rdi        # 161a00 <_ZL17kSuppressionTypes+0x1fb0>
  118369:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11836d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118371:	88 53 40             	mov    %dl,0x40(%rbx)
  118374:	4c 89 f2             	mov    %r14,%rdx
  118377:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11837b:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11837f:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118383:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  118387:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11838b:	e8 30 22 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118390:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  118394:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118398:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  11839c:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1183a0:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1183a4:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  1183a8:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1183ac:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1183b0:	e9 56 fd ff ff       	jmp    11810b <pqcrystals_kyber768_ref_polyvec_compress+0x3e3>
  1183b5:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1183b9:	48 8d 3d 50 96 04 00 	lea    0x49650(%rip),%rdi        # 161a10 <_ZL17kSuppressionTypes+0x1fc0>
  1183c0:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1183c4:	4c 89 e6             	mov    %r12,%rsi
  1183c7:	4c 89 da             	mov    %r11,%rdx
  1183ca:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1183ce:	4d 89 c5             	mov    %r8,%r13
  1183d1:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1183d5:	4d 89 de             	mov    %r11,%r14
  1183d8:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1183dc:	e8 df 21 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1183e1:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1183e5:	4d 89 f3             	mov    %r14,%r11
  1183e8:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1183ec:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1183f0:	4d 89 e8             	mov    %r13,%r8
  1183f3:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1183f7:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1183fb:	e9 35 fd ff ff       	jmp    118135 <pqcrystals_kyber768_ref_polyvec_compress+0x40d>
  118400:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118404:	48 8d 3d 15 96 04 00 	lea    0x49615(%rip),%rdi        # 161a20 <_ZL17kSuppressionTypes+0x1fd0>
  11840b:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11840f:	4c 89 e6             	mov    %r12,%rsi
  118412:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  118416:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11841a:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11841e:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118422:	4d 89 de             	mov    %r11,%r14
  118425:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118429:	e8 92 21 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  11842e:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118432:	4d 89 f3             	mov    %r14,%r11
  118435:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118439:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11843d:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118441:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118445:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118449:	e9 f7 fc ff ff       	jmp    118145 <pqcrystals_kyber768_ref_polyvec_compress+0x41d>
  11844e:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118452:	48 8d 3d d7 95 04 00 	lea    0x495d7(%rip),%rdi        # 161a30 <_ZL17kSuppressionTypes+0x1fe0>
  118459:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  11845d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118461:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  118465:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  118469:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11846d:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118471:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118475:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  118479:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11847d:	e8 3e 21 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118482:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  118486:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  11848a:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  11848e:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118492:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118496:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  11849a:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  11849e:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1184a2:	e9 b2 fc ff ff       	jmp    118159 <pqcrystals_kyber768_ref_polyvec_compress+0x431>
  1184a7:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1184ab:	48 8d 3d 8e 95 04 00 	lea    0x4958e(%rip),%rdi        # 161a40 <_ZL17kSuppressionTypes+0x1ff0>
  1184b2:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1184b6:	4c 89 e6             	mov    %r12,%rsi
  1184b9:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  1184bd:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1184c1:	4d 89 c5             	mov    %r8,%r13
  1184c4:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1184c8:	4d 89 de             	mov    %r11,%r14
  1184cb:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1184cf:	e8 ec 20 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1184d4:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1184d8:	4d 89 f3             	mov    %r14,%r11
  1184db:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1184df:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1184e3:	4d 89 e8             	mov    %r13,%r8
  1184e6:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1184ea:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1184ee:	e9 94 fc ff ff       	jmp    118187 <pqcrystals_kyber768_ref_polyvec_compress+0x45f>
  1184f3:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1184f7:	48 8d 3d 52 95 04 00 	lea    0x49552(%rip),%rdi        # 161a50 <_ZL17kSuppressionTypes+0x2000>
  1184fe:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  118502:	4c 89 e6             	mov    %r12,%rsi
  118505:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  118509:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11850d:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118511:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118515:	4d 89 de             	mov    %r11,%r14
  118518:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11851c:	e8 9f 20 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118521:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118525:	4d 89 f3             	mov    %r14,%r11
  118528:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11852c:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118530:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118534:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118538:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11853c:	e9 56 fc ff ff       	jmp    118197 <pqcrystals_kyber768_ref_polyvec_compress+0x46f>
  118541:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  118545:	48 8d 3d 14 95 04 00 	lea    0x49514(%rip),%rdi        # 161a60 <_ZL17kSuppressionTypes+0x2010>
  11854c:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  118550:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118554:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  118558:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  11855c:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118560:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118564:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118568:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  11856c:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118570:	e8 4b 20 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118575:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  118579:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  11857d:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  118581:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118585:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118589:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  11858d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  118591:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118595:	e9 11 fc ff ff       	jmp    1181ab <pqcrystals_kyber768_ref_polyvec_compress+0x483>
  11859a:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  11859e:	48 8d 3d cb 94 04 00 	lea    0x494cb(%rip),%rdi        # 161a70 <_ZL17kSuppressionTypes+0x2020>
  1185a5:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1185a9:	4c 89 e6             	mov    %r12,%rsi
  1185ac:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  1185b0:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1185b4:	4d 89 c5             	mov    %r8,%r13
  1185b7:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1185bb:	4d 89 de             	mov    %r11,%r14
  1185be:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1185c2:	e8 f9 1f ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1185c7:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1185cb:	4d 89 f3             	mov    %r14,%r11
  1185ce:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1185d2:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1185d6:	4d 89 e8             	mov    %r13,%r8
  1185d9:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1185dd:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1185e1:	e9 f3 fb ff ff       	jmp    1181d9 <pqcrystals_kyber768_ref_polyvec_compress+0x4b1>
  1185e6:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1185ea:	48 8d 3d 8f 94 04 00 	lea    0x4948f(%rip),%rdi        # 161a80 <_ZL17kSuppressionTypes+0x2030>
  1185f1:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1185f5:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1185f9:	4c 89 f2             	mov    %r14,%rdx
  1185fc:	48 89 43 30          	mov    %rax,0x30(%rbx)
  118600:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118604:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118608:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  11860c:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  118610:	e8 ab 1f ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118615:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118619:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  11861d:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  118621:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118625:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118629:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  11862d:	48 8b 43 30          	mov    0x30(%rbx),%rax
  118631:	e9 b7 fb ff ff       	jmp    1181ed <pqcrystals_kyber768_ref_polyvec_compress+0x4c5>
  118636:	48 8d 56 05          	lea    0x5(%rsi),%rdx
  11863a:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  11863e:	48 8d 3d 4b 94 04 00 	lea    0x4944b(%rip),%rdi        # 161a90 <_ZL17kSuppressionTypes+0x2040>
  118645:	49 89 f5             	mov    %rsi,%r13
  118648:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11864c:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  118650:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  118654:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  118658:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11865c:	e8 5f 1f ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  118661:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  118665:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  118669:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11866d:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  118671:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  118675:	4c 89 ee             	mov    %r13,%rsi
  118678:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11867c:	e9 9b fb ff ff       	jmp    11821c <pqcrystals_kyber768_ref_polyvec_compress+0x4f4>
  118681:	41 c6 81 04 80 ff 7f 	movb   $0xf8,0x7fff8004(%r9)
  118688:	f8 
  118689:	48 c7 07 0e 36 e0 45 	movq   $0x45e0360e,(%rdi)
  118690:	48 85 c0             	test   %rax,%rax
  118693:	74 1a                	je     1186af <pqcrystals_kyber768_ref_polyvec_compress+0x987>
  118695:	48 b9 f5 f5 f5 f5 f5 	movabs $0xf5f5f5f5f5f5f5f5,%rcx
  11869c:	f5 f5 f5 
  11869f:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  1186a6:	48 8b 40 38          	mov    0x38(%rax),%rax
  1186aa:	c6 00 00             	movb   $0x0,(%rax)
  1186ad:	eb 0b                	jmp    1186ba <pqcrystals_kyber768_ref_polyvec_compress+0x992>
  1186af:	49 c7 81 00 80 ff 7f 	movq   $0x0,0x7fff8000(%r9)
  1186b6:	00 00 00 00 
  1186ba:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  1186be:	5b                   	pop    %rbx
  1186bf:	41 5c                	pop    %r12
  1186c1:	41 5d                	pop    %r13
  1186c3:	41 5e                	pop    %r14
  1186c5:	41 5f                	pop    %r15
  1186c7:	5d                   	pop    %rbp
  1186c8:	c3                   	ret
  1186c9:	4c 89 f7             	mov    %r14,%rdi
  1186cc:	e8 cf d5 fb ff       	call   d5ca0 <__asan_report_load2>
  1186d1:	48 89 f7             	mov    %rsi,%rdi
  1186d4:	e8 c7 d8 fb ff       	call   d5fa0 <__asan_report_store1>
  1186d9:	4c 89 f7             	mov    %r14,%rdi
  1186dc:	e8 bf d8 fb ff       	call   d5fa0 <__asan_report_store1>
  1186e1:	48 89 d7             	mov    %rdx,%rdi
  1186e4:	e8 b7 d8 fb ff       	call   d5fa0 <__asan_report_store1>
  1186e9:	48 89 d7             	mov    %rdx,%rdi
  1186ec:	e8 af d8 fb ff       	call   d5fa0 <__asan_report_store1>
  1186f1:	4c 89 f7             	mov    %r14,%rdi
  1186f4:	e8 a7 d8 fb ff       	call   d5fa0 <__asan_report_store1>

Disassembly of section .fini:
