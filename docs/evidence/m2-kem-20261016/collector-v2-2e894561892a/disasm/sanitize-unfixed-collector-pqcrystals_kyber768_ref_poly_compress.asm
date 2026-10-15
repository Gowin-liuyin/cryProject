
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-sanitize/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000114908 <pqcrystals_kyber768_ref_poly_compress>:
  114908:	55                   	push   %rbp
  114909:	48 89 e5             	mov    %rsp,%rbp
  11490c:	41 57                	push   %r15
  11490e:	41 56                	push   %r14
  114910:	41 55                	push   %r13
  114912:	41 54                	push   %r12
  114914:	53                   	push   %rbx
  114915:	48 83 e4 e0          	and    $0xffffffffffffffe0,%rsp
  114919:	48 81 ec c0 00 00 00 	sub    $0xc0,%rsp
  114920:	48 89 e3             	mov    %rsp,%rbx
  114923:	49 89 f7             	mov    %rsi,%r15
  114926:	49 89 fc             	mov    %rdi,%r12
  114929:	48 8d 05 40 19 06 00 	lea    0x61940(%rip),%rax        # 176270 <__asan_option_detect_stack_use_after_return>
  114930:	83 38 00             	cmpl   $0x0,(%rax)
  114933:	74 0c                	je     114941 <pqcrystals_kyber768_ref_poly_compress+0x39>
  114935:	bf 40 00 00 00       	mov    $0x40,%edi
  11493a:	e8 01 c6 f2 ff       	call   40f40 <__asan_stack_malloc_0>
  11493f:	eb 02                	jmp    114943 <pqcrystals_kyber768_ref_poly_compress+0x3b>
  114941:	31 c0                	xor    %eax,%eax
  114943:	48 89 c7             	mov    %rax,%rdi
  114946:	48 85 c0             	test   %rax,%rax
  114949:	75 0e                	jne    114959 <pqcrystals_kyber768_ref_poly_compress+0x51>
  11494b:	48 89 e7             	mov    %rsp,%rdi
  11494e:	48 83 c7 c0          	add    $0xffffffffffffffc0,%rdi
  114952:	48 83 e7 e0          	and    $0xffffffffffffffe0,%rdi
  114956:	48 89 fc             	mov    %rdi,%rsp
  114959:	48 89 bb 98 00 00 00 	mov    %rdi,0x98(%rbx)
  114960:	4c 8d 4f 20          	lea    0x20(%rdi),%r9
  114964:	48 c7 07 b3 8a b5 41 	movq   $0x41b58ab3,(%rdi)
  11496b:	48 8d 0d 2c f4 01 00 	lea    0x1f42c(%rip),%rcx        # 133d9e <_ZN11__sanitizerL10kExtraRegsE+0x12bee>
  114972:	48 89 4f 08          	mov    %rcx,0x8(%rdi)
  114976:	48 8d 0d 8b ff ff ff 	lea    -0x75(%rip),%rcx        # 114908 <pqcrystals_kyber768_ref_poly_compress>
  11497d:	48 89 4f 10          	mov    %rcx,0x10(%rdi)
  114981:	49 89 f8             	mov    %rdi,%r8
  114984:	49 c1 e8 03          	shr    $0x3,%r8
  114988:	48 b9 f1 f1 f1 f1 f8 	movabs $0xf3f3f3f8f1f1f1f1,%rcx
  11498f:	f3 f3 f3 
  114992:	49 89 88 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r8)
  114999:	41 c6 80 04 80 ff 7f 	movb   $0x0,0x7fff8004(%r8)
  1149a0:	00 
  1149a1:	4d 85 ff             	test   %r15,%r15
  1149a4:	0f 95 c1             	setne  %cl
  1149a7:	41 f6 c7 01          	test   $0x1,%r15b
  1149ab:	41 0f 94 c6          	sete   %r14b
  1149af:	41 20 ce             	and    %cl,%r14b
  1149b2:	4c 8d 57 21          	lea    0x21(%rdi),%r10
  1149b6:	4c 8d 5f 22          	lea    0x22(%rdi),%r11
  1149ba:	48 8d 4f 23          	lea    0x23(%rdi),%rcx
  1149be:	48 89 8b 80 00 00 00 	mov    %rcx,0x80(%rbx)
  1149c5:	48 8d 4f 24          	lea    0x24(%rdi),%rcx
  1149c9:	48 89 4b 78          	mov    %rcx,0x78(%rbx)
  1149cd:	48 8d 4f 25          	lea    0x25(%rdi),%rcx
  1149d1:	48 89 4b 70          	mov    %rcx,0x70(%rbx)
  1149d5:	48 8d 4f 26          	lea    0x26(%rdi),%rcx
  1149d9:	48 89 4b 68          	mov    %rcx,0x68(%rbx)
  1149dd:	48 8d 4f 27          	lea    0x27(%rdi),%rcx
  1149e1:	48 89 4b 60          	mov    %rcx,0x60(%rbx)
  1149e5:	31 c9                	xor    %ecx,%ecx
  1149e7:	4c 89 7b 58          	mov    %r15,0x58(%rbx)
  1149eb:	4d 89 fd             	mov    %r15,%r13
  1149ee:	4c 89 e6             	mov    %r12,%rsi
  1149f1:	66 66 66 66 66 66 2e 	data16 data16 data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
  1149f8:	0f 1f 84 00 00 00 00 
  1149ff:	00 
  114a00:	48 89 8b 90 00 00 00 	mov    %rcx,0x90(%rbx)
  114a07:	4c 89 ab 88 00 00 00 	mov    %r13,0x88(%rbx)
  114a0e:	45 31 e4             	xor    %r12d,%r12d
  114a11:	66 66 66 66 66 66 2e 	data16 data16 data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
  114a18:	0f 1f 84 00 00 00 00 
  114a1f:	00 
  114a20:	45 84 f6             	test   %r14b,%r14b
  114a23:	0f 84 8d 00 00 00    	je     114ab6 <pqcrystals_kyber768_ref_poly_compress+0x1ae>
  114a29:	4d 85 ff             	test   %r15,%r15
  114a2c:	0f 84 d4 00 00 00    	je     114b06 <pqcrystals_kyber768_ref_poly_compress+0x1fe>
  114a32:	4d 85 ed             	test   %r13,%r13
  114a35:	0f 84 cb 00 00 00    	je     114b06 <pqcrystals_kyber768_ref_poly_compress+0x1fe>
  114a3b:	4d 39 fd             	cmp    %r15,%r13
  114a3e:	0f 82 c2 00 00 00    	jb     114b06 <pqcrystals_kyber768_ref_poly_compress+0x1fe>
  114a44:	45 84 f6             	test   %r14b,%r14b
  114a47:	0f 84 0c 01 00 00    	je     114b59 <pqcrystals_kyber768_ref_poly_compress+0x251>
  114a4d:	4c 89 e9             	mov    %r13,%rcx
  114a50:	48 c1 e9 03          	shr    $0x3,%rcx
  114a54:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114a5b:	84 c9                	test   %cl,%cl
  114a5d:	75 46                	jne    114aa5 <pqcrystals_kyber768_ref_poly_compress+0x19d>
  114a5f:	48 8b 4b 58          	mov    0x58(%rbx),%rcx
  114a63:	42 0f bf 0c 61       	movswl (%rcx,%r12,2),%ecx
  114a68:	89 ca                	mov    %ecx,%edx
  114a6a:	c1 ea 0f             	shr    $0xf,%edx
  114a6d:	81 e2 01 0d 00 00    	and    $0xd01,%edx
  114a73:	01 ca                	add    %ecx,%edx
  114a75:	0f b7 ca             	movzwl %dx,%ecx
  114a78:	c1 e1 04             	shl    $0x4,%ecx
  114a7b:	81 c1 80 06 00 00    	add    $0x680,%ecx
  114a81:	48 69 c9 b8 af 13 00 	imul   $0x13afb8,%rcx,%rcx
  114a88:	48 c1 e9 20          	shr    $0x20,%rcx
  114a8c:	80 e1 0f             	and    $0xf,%cl
  114a8f:	43 88 0c 21          	mov    %cl,(%r9,%r12,1)
  114a93:	49 ff c4             	inc    %r12
  114a96:	49 83 c5 02          	add    $0x2,%r13
  114a9a:	49 83 fc 08          	cmp    $0x8,%r12
  114a9e:	75 80                	jne    114a20 <pqcrystals_kyber768_ref_poly_compress+0x118>
  114aa0:	e9 0b 01 00 00       	jmp    114bb0 <pqcrystals_kyber768_ref_poly_compress+0x2a8>
  114aa5:	44 89 ea             	mov    %r13d,%edx
  114aa8:	80 e2 07             	and    $0x7,%dl
  114aab:	fe c2                	inc    %dl
  114aad:	38 ca                	cmp    %cl,%dl
  114aaf:	7c ae                	jl     114a5f <pqcrystals_kyber768_ref_poly_compress+0x157>
  114ab1:	e9 d8 06 00 00       	jmp    11518e <pqcrystals_kyber768_ref_poly_compress+0x886>
  114ab6:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114aba:	48 8d 3d cf c4 04 00 	lea    0x4c4cf(%rip),%rdi        # 160f90 <_ZL17kSuppressionTypes+0x1540>
  114ac1:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114ac5:	4c 89 fe             	mov    %r15,%rsi
  114ac8:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114acc:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  114ad0:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114ad4:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114ad8:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114adc:	e8 8f 24 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  114ae1:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114ae5:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114ae9:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114aed:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  114af1:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114af5:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114af9:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114afd:	4d 85 ff             	test   %r15,%r15
  114b00:	0f 85 2c ff ff ff    	jne    114a32 <pqcrystals_kyber768_ref_poly_compress+0x12a>
  114b06:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114b0a:	48 8d 3d 9f c4 04 00 	lea    0x4c49f(%rip),%rdi        # 160fb0 <_ZL17kSuppressionTypes+0x1560>
  114b11:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114b15:	4c 89 fe             	mov    %r15,%rsi
  114b18:	4c 89 ea             	mov    %r13,%rdx
  114b1b:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114b1f:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  114b23:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114b27:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114b2b:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114b2f:	e8 8c 5a ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114b34:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114b38:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114b3c:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114b40:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  114b44:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114b48:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114b4c:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114b50:	45 84 f6             	test   %r14b,%r14b
  114b53:	0f 85 f4 fe ff ff    	jne    114a4d <pqcrystals_kyber768_ref_poly_compress+0x145>
  114b59:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114b5d:	48 8d 3d 5c c4 04 00 	lea    0x4c45c(%rip),%rdi        # 160fc0 <_ZL17kSuppressionTypes+0x1570>
  114b64:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114b68:	4c 89 ee             	mov    %r13,%rsi
  114b6b:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114b6f:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  114b73:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114b77:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114b7b:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114b7f:	e8 ec 23 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  114b84:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114b88:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114b8c:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114b90:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  114b94:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114b98:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114b9c:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114ba0:	e9 a8 fe ff ff       	jmp    114a4d <pqcrystals_kyber768_ref_poly_compress+0x145>
  114ba5:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
  114bac:	00 00 00 00 
  114bb0:	45 0f b6 21          	movzbl (%r9),%r12d
  114bb4:	49 83 f9 ff          	cmp    $0xffffffffffffffff,%r9
  114bb8:	0f 84 af 01 00 00    	je     114d6d <pqcrystals_kyber768_ref_poly_compress+0x465>
  114bbe:	45 0f b6 69 01       	movzbl 0x1(%r9),%r13d
  114bc3:	48 85 f6             	test   %rsi,%rsi
  114bc6:	0f 84 ee 01 00 00    	je     114dba <pqcrystals_kyber768_ref_poly_compress+0x4b2>
  114bcc:	48 89 f1             	mov    %rsi,%rcx
  114bcf:	48 c1 e9 03          	shr    $0x3,%rcx
  114bd3:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114bda:	84 c9                	test   %cl,%cl
  114bdc:	0f 85 2b 01 00 00    	jne    114d0d <pqcrystals_kyber768_ref_poly_compress+0x405>
  114be2:	41 c0 e5 04          	shl    $0x4,%r13b
  114be6:	45 08 e5             	or     %r12b,%r13b
  114be9:	44 88 2e             	mov    %r13b,(%rsi)
  114bec:	49 83 f9 fe          	cmp    $0xfffffffffffffffe,%r9
  114bf0:	0f 83 21 02 00 00    	jae    114e17 <pqcrystals_kyber768_ref_poly_compress+0x50f>
  114bf6:	41 0f b6 51 02       	movzbl 0x2(%r9),%edx
  114bfb:	49 83 f9 fd          	cmp    $0xfffffffffffffffd,%r9
  114bff:	0f 83 5d 02 00 00    	jae    114e62 <pqcrystals_kyber768_ref_poly_compress+0x55a>
  114c05:	45 0f b6 61 03       	movzbl 0x3(%r9),%r12d
  114c0a:	4c 8d 6e 01          	lea    0x1(%rsi),%r13
  114c0e:	48 83 fe ff          	cmp    $0xffffffffffffffff,%rsi
  114c12:	0f 84 a0 02 00 00    	je     114eb8 <pqcrystals_kyber768_ref_poly_compress+0x5b0>
  114c18:	4c 89 e9             	mov    %r13,%rcx
  114c1b:	48 c1 e9 03          	shr    $0x3,%rcx
  114c1f:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114c26:	84 c9                	test   %cl,%cl
  114c28:	0f 85 f1 00 00 00    	jne    114d1f <pqcrystals_kyber768_ref_poly_compress+0x417>
  114c2e:	41 c0 e4 04          	shl    $0x4,%r12b
  114c32:	41 08 d4             	or     %dl,%r12b
  114c35:	45 88 65 00          	mov    %r12b,0x0(%r13)
  114c39:	49 83 f9 fc          	cmp    $0xfffffffffffffffc,%r9
  114c3d:	0f 83 cc 02 00 00    	jae    114f0f <pqcrystals_kyber768_ref_poly_compress+0x607>
  114c43:	41 0f b6 51 04       	movzbl 0x4(%r9),%edx
  114c48:	49 83 f9 fb          	cmp    $0xfffffffffffffffb,%r9
  114c4c:	0f 83 09 03 00 00    	jae    114f5b <pqcrystals_kyber768_ref_poly_compress+0x653>
  114c52:	45 0f b6 61 05       	movzbl 0x5(%r9),%r12d
  114c57:	4c 8d 6e 02          	lea    0x2(%rsi),%r13
  114c5b:	48 83 fe fe          	cmp    $0xfffffffffffffffe,%rsi
  114c5f:	0f 83 49 03 00 00    	jae    114fae <pqcrystals_kyber768_ref_poly_compress+0x6a6>
  114c65:	4c 89 e9             	mov    %r13,%rcx
  114c68:	48 c1 e9 03          	shr    $0x3,%rcx
  114c6c:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114c73:	84 c9                	test   %cl,%cl
  114c75:	0f 85 be 00 00 00    	jne    114d39 <pqcrystals_kyber768_ref_poly_compress+0x431>
  114c7b:	41 c0 e4 04          	shl    $0x4,%r12b
  114c7f:	41 08 d4             	or     %dl,%r12b
  114c82:	45 88 65 00          	mov    %r12b,0x0(%r13)
  114c86:	49 83 f9 fa          	cmp    $0xfffffffffffffffa,%r9
  114c8a:	0f 83 75 03 00 00    	jae    115005 <pqcrystals_kyber768_ref_poly_compress+0x6fd>
  114c90:	41 0f b6 51 06       	movzbl 0x6(%r9),%edx
  114c95:	49 83 f9 f9          	cmp    $0xfffffffffffffff9,%r9
  114c99:	0f 83 b2 03 00 00    	jae    115051 <pqcrystals_kyber768_ref_poly_compress+0x749>
  114c9f:	45 0f b6 61 07       	movzbl 0x7(%r9),%r12d
  114ca4:	4c 8d 6e 03          	lea    0x3(%rsi),%r13
  114ca8:	48 83 fe fd          	cmp    $0xfffffffffffffffd,%rsi
  114cac:	0f 83 f2 03 00 00    	jae    1150a4 <pqcrystals_kyber768_ref_poly_compress+0x79c>
  114cb2:	4c 89 e9             	mov    %r13,%rcx
  114cb5:	48 c1 e9 03          	shr    $0x3,%rcx
  114cb9:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114cc0:	84 c9                	test   %cl,%cl
  114cc2:	0f 85 8b 00 00 00    	jne    114d53 <pqcrystals_kyber768_ref_poly_compress+0x44b>
  114cc8:	41 c0 e4 04          	shl    $0x4,%r12b
  114ccc:	41 08 d4             	or     %dl,%r12b
  114ccf:	44 88 66 03          	mov    %r12b,0x3(%rsi)
  114cd3:	48 83 fe fc          	cmp    $0xfffffffffffffffc,%rsi
  114cd7:	4c 8b a3 90 00 00 00 	mov    0x90(%rbx),%r12
  114cde:	0f 83 17 04 00 00    	jae    1150fb <pqcrystals_kyber768_ref_poly_compress+0x7f3>
  114ce4:	48 83 c6 04          	add    $0x4,%rsi
  114ce8:	49 ff c4             	inc    %r12
  114ceb:	4c 8b ab 88 00 00 00 	mov    0x88(%rbx),%r13
  114cf2:	49 83 c5 10          	add    $0x10,%r13
  114cf6:	48 83 43 58 10       	addq   $0x10,0x58(%rbx)
  114cfb:	49 83 fc 20          	cmp    $0x20,%r12
  114cff:	4c 89 e1             	mov    %r12,%rcx
  114d02:	0f 85 f8 fc ff ff    	jne    114a00 <pqcrystals_kyber768_ref_poly_compress+0xf8>
  114d08:	e9 39 04 00 00       	jmp    115146 <pqcrystals_kyber768_ref_poly_compress+0x83e>
  114d0d:	89 f2                	mov    %esi,%edx
  114d0f:	80 e2 07             	and    $0x7,%dl
  114d12:	38 ca                	cmp    %cl,%dl
  114d14:	0f 8c c8 fe ff ff    	jl     114be2 <pqcrystals_kyber768_ref_poly_compress+0x2da>
  114d1a:	e9 77 04 00 00       	jmp    115196 <pqcrystals_kyber768_ref_poly_compress+0x88e>
  114d1f:	88 53 1f             	mov    %dl,0x1f(%rbx)
  114d22:	44 89 ea             	mov    %r13d,%edx
  114d25:	80 e2 07             	and    $0x7,%dl
  114d28:	38 ca                	cmp    %cl,%dl
  114d2a:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  114d2e:	0f 8c fa fe ff ff    	jl     114c2e <pqcrystals_kyber768_ref_poly_compress+0x326>
  114d34:	e9 65 04 00 00       	jmp    11519e <pqcrystals_kyber768_ref_poly_compress+0x896>
  114d39:	88 53 1f             	mov    %dl,0x1f(%rbx)
  114d3c:	44 89 ea             	mov    %r13d,%edx
  114d3f:	80 e2 07             	and    $0x7,%dl
  114d42:	38 ca                	cmp    %cl,%dl
  114d44:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  114d48:	0f 8c 2d ff ff ff    	jl     114c7b <pqcrystals_kyber768_ref_poly_compress+0x373>
  114d4e:	e9 53 04 00 00       	jmp    1151a6 <pqcrystals_kyber768_ref_poly_compress+0x89e>
  114d53:	88 53 1f             	mov    %dl,0x1f(%rbx)
  114d56:	44 89 ea             	mov    %r13d,%edx
  114d59:	80 e2 07             	and    $0x7,%dl
  114d5c:	38 ca                	cmp    %cl,%dl
  114d5e:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  114d62:	0f 8c 60 ff ff ff    	jl     114cc8 <pqcrystals_kyber768_ref_poly_compress+0x3c0>
  114d68:	e9 41 04 00 00       	jmp    1151ae <pqcrystals_kyber768_ref_poly_compress+0x8a6>
  114d6d:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114d71:	48 8d 3d 68 c2 04 00 	lea    0x4c268(%rip),%rdi        # 160fe0 <_ZL17kSuppressionTypes+0x1590>
  114d78:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114d7c:	4c 89 ce             	mov    %r9,%rsi
  114d7f:	4c 89 d2             	mov    %r10,%rdx
  114d82:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114d86:	4d 89 c5             	mov    %r8,%r13
  114d89:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114d8d:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114d91:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114d95:	e8 26 58 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114d9a:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114d9e:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114da2:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114da6:	4d 89 e8             	mov    %r13,%r8
  114da9:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114dad:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114db1:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114db5:	e9 04 fe ff ff       	jmp    114bbe <pqcrystals_kyber768_ref_poly_compress+0x2b6>
  114dba:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114dbe:	48 8d 3d 2b c2 04 00 	lea    0x4c22b(%rip),%rdi        # 160ff0 <_ZL17kSuppressionTypes+0x15a0>
  114dc5:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114dc9:	31 f6                	xor    %esi,%esi
  114dcb:	31 d2                	xor    %edx,%edx
  114dcd:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114dd1:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  114dd5:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114dd9:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114ddd:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114de1:	e8 da 57 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114de6:	48 8d 3d 13 c2 04 00 	lea    0x4c213(%rip),%rdi        # 161000 <_ZL17kSuppressionTypes+0x15b0>
  114ded:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114df1:	e8 7a 21 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  114df6:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114dfa:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114dfe:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114e02:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  114e06:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114e0a:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114e0e:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114e12:	e9 b5 fd ff ff       	jmp    114bcc <pqcrystals_kyber768_ref_poly_compress+0x2c4>
  114e17:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114e1b:	48 8d 3d fe c1 04 00 	lea    0x4c1fe(%rip),%rdi        # 161020 <_ZL17kSuppressionTypes+0x15d0>
  114e22:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114e26:	4c 89 ce             	mov    %r9,%rsi
  114e29:	4c 89 da             	mov    %r11,%rdx
  114e2c:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114e30:	4d 89 c5             	mov    %r8,%r13
  114e33:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114e37:	4d 89 d4             	mov    %r10,%r12
  114e3a:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114e3e:	e8 7d 57 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114e43:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114e47:	4d 89 e2             	mov    %r12,%r10
  114e4a:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114e4e:	4d 89 e8             	mov    %r13,%r8
  114e51:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114e55:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114e59:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114e5d:	e9 94 fd ff ff       	jmp    114bf6 <pqcrystals_kyber768_ref_poly_compress+0x2ee>
  114e62:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114e66:	48 8d 3d c3 c1 04 00 	lea    0x4c1c3(%rip),%rdi        # 161030 <_ZL17kSuppressionTypes+0x15e0>
  114e6d:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114e71:	4c 89 ce             	mov    %r9,%rsi
  114e74:	88 53 1f             	mov    %dl,0x1f(%rbx)
  114e77:	48 8b 93 80 00 00 00 	mov    0x80(%rbx),%rdx
  114e7e:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114e82:	4d 89 c5             	mov    %r8,%r13
  114e85:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114e89:	4d 89 d4             	mov    %r10,%r12
  114e8c:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114e90:	e8 2b 57 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114e95:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  114e99:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114e9d:	4d 89 e2             	mov    %r12,%r10
  114ea0:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114ea4:	4d 89 e8             	mov    %r13,%r8
  114ea7:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114eab:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114eaf:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114eb3:	e9 4d fd ff ff       	jmp    114c05 <pqcrystals_kyber768_ref_poly_compress+0x2fd>
  114eb8:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114ebc:	48 8d 3d 7d c1 04 00 	lea    0x4c17d(%rip),%rdi        # 161040 <_ZL17kSuppressionTypes+0x15f0>
  114ec3:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114ec7:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114ecb:	88 53 1f             	mov    %dl,0x1f(%rbx)
  114ece:	4c 89 ea             	mov    %r13,%rdx
  114ed1:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114ed5:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  114ed9:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114edd:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114ee1:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114ee5:	e8 d6 56 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114eea:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  114eee:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114ef2:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114ef6:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114efa:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  114efe:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114f02:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114f06:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114f0a:	e9 09 fd ff ff       	jmp    114c18 <pqcrystals_kyber768_ref_poly_compress+0x310>
  114f0f:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114f13:	48 8d 3d 36 c1 04 00 	lea    0x4c136(%rip),%rdi        # 161050 <_ZL17kSuppressionTypes+0x1600>
  114f1a:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114f1e:	4c 89 ce             	mov    %r9,%rsi
  114f21:	48 8b 53 78          	mov    0x78(%rbx),%rdx
  114f25:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114f29:	4d 89 c5             	mov    %r8,%r13
  114f2c:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114f30:	4d 89 d4             	mov    %r10,%r12
  114f33:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114f37:	e8 84 56 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114f3c:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114f40:	4d 89 e2             	mov    %r12,%r10
  114f43:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114f47:	4d 89 e8             	mov    %r13,%r8
  114f4a:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114f4e:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114f52:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114f56:	e9 e8 fc ff ff       	jmp    114c43 <pqcrystals_kyber768_ref_poly_compress+0x33b>
  114f5b:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114f5f:	48 8d 3d fa c0 04 00 	lea    0x4c0fa(%rip),%rdi        # 161060 <_ZL17kSuppressionTypes+0x1610>
  114f66:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114f6a:	4c 89 ce             	mov    %r9,%rsi
  114f6d:	88 53 1f             	mov    %dl,0x1f(%rbx)
  114f70:	48 8b 53 70          	mov    0x70(%rbx),%rdx
  114f74:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114f78:	4d 89 c5             	mov    %r8,%r13
  114f7b:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114f7f:	4d 89 d4             	mov    %r10,%r12
  114f82:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114f86:	e8 35 56 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114f8b:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  114f8f:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114f93:	4d 89 e2             	mov    %r12,%r10
  114f96:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114f9a:	4d 89 e8             	mov    %r13,%r8
  114f9d:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114fa1:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114fa5:	48 8b 43 40          	mov    0x40(%rbx),%rax
  114fa9:	e9 a4 fc ff ff       	jmp    114c52 <pqcrystals_kyber768_ref_poly_compress+0x34a>
  114fae:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  114fb2:	48 8d 3d b7 c0 04 00 	lea    0x4c0b7(%rip),%rdi        # 161070 <_ZL17kSuppressionTypes+0x1620>
  114fb9:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  114fbd:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114fc1:	88 53 1f             	mov    %dl,0x1f(%rbx)
  114fc4:	4c 89 ea             	mov    %r13,%rdx
  114fc7:	48 89 43 40          	mov    %rax,0x40(%rbx)
  114fcb:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  114fcf:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  114fd3:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114fd7:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  114fdb:	e8 e0 55 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114fe0:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  114fe4:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  114fe8:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114fec:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  114ff0:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  114ff4:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  114ff8:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  114ffc:	48 8b 43 40          	mov    0x40(%rbx),%rax
  115000:	e9 60 fc ff ff       	jmp    114c65 <pqcrystals_kyber768_ref_poly_compress+0x35d>
  115005:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  115009:	48 8d 3d 70 c0 04 00 	lea    0x4c070(%rip),%rdi        # 161080 <_ZL17kSuppressionTypes+0x1630>
  115010:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  115014:	4c 89 ce             	mov    %r9,%rsi
  115017:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  11501b:	48 89 43 40          	mov    %rax,0x40(%rbx)
  11501f:	4d 89 c5             	mov    %r8,%r13
  115022:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  115026:	4d 89 d4             	mov    %r10,%r12
  115029:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  11502d:	e8 8e 55 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  115032:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  115036:	4d 89 e2             	mov    %r12,%r10
  115039:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  11503d:	4d 89 e8             	mov    %r13,%r8
  115040:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  115044:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  115048:	48 8b 43 40          	mov    0x40(%rbx),%rax
  11504c:	e9 3f fc ff ff       	jmp    114c90 <pqcrystals_kyber768_ref_poly_compress+0x388>
  115051:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  115055:	48 8d 3d 34 c0 04 00 	lea    0x4c034(%rip),%rdi        # 161090 <_ZL17kSuppressionTypes+0x1640>
  11505c:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  115060:	4c 89 ce             	mov    %r9,%rsi
  115063:	88 53 1f             	mov    %dl,0x1f(%rbx)
  115066:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  11506a:	48 89 43 40          	mov    %rax,0x40(%rbx)
  11506e:	4d 89 c5             	mov    %r8,%r13
  115071:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  115075:	4d 89 d4             	mov    %r10,%r12
  115078:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  11507c:	e8 3f 55 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  115081:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  115085:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  115089:	4d 89 e2             	mov    %r12,%r10
  11508c:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  115090:	4d 89 e8             	mov    %r13,%r8
  115093:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  115097:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  11509b:	48 8b 43 40          	mov    0x40(%rbx),%rax
  11509f:	e9 fb fb ff ff       	jmp    114c9f <pqcrystals_kyber768_ref_poly_compress+0x397>
  1150a4:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  1150a8:	48 8d 3d f1 bf 04 00 	lea    0x4bff1(%rip),%rdi        # 1610a0 <_ZL17kSuppressionTypes+0x1650>
  1150af:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  1150b3:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  1150b7:	88 53 1f             	mov    %dl,0x1f(%rbx)
  1150ba:	4c 89 ea             	mov    %r13,%rdx
  1150bd:	48 89 43 40          	mov    %rax,0x40(%rbx)
  1150c1:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  1150c5:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  1150c9:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  1150cd:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  1150d1:	e8 ea 54 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1150d6:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  1150da:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  1150de:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  1150e2:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  1150e6:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  1150ea:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  1150ee:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  1150f2:	48 8b 43 40          	mov    0x40(%rbx),%rax
  1150f6:	e9 b7 fb ff ff       	jmp    114cb2 <pqcrystals_kyber768_ref_poly_compress+0x3aa>
  1150fb:	48 8d 56 04          	lea    0x4(%rsi),%rdx
  1150ff:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  115103:	48 8d 3d a6 bf 04 00 	lea    0x4bfa6(%rip),%rdi        # 1610b0 <_ZL17kSuppressionTypes+0x1660>
  11510a:	49 89 f5             	mov    %rsi,%r13
  11510d:	48 89 43 40          	mov    %rax,0x40(%rbx)
  115111:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  115115:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  115119:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  11511d:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  115121:	e8 9a 54 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  115126:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  11512a:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  11512e:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  115132:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  115136:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  11513a:	4c 89 ee             	mov    %r13,%rsi
  11513d:	48 8b 43 40          	mov    0x40(%rbx),%rax
  115141:	e9 9e fb ff ff       	jmp    114ce4 <pqcrystals_kyber768_ref_poly_compress+0x3dc>
  115146:	41 c6 80 04 80 ff 7f 	movb   $0xf8,0x7fff8004(%r8)
  11514d:	f8 
  11514e:	48 c7 07 0e 36 e0 45 	movq   $0x45e0360e,(%rdi)
  115155:	48 85 c0             	test   %rax,%rax
  115158:	74 1a                	je     115174 <pqcrystals_kyber768_ref_poly_compress+0x86c>
  11515a:	48 b9 f5 f5 f5 f5 f5 	movabs $0xf5f5f5f5f5f5f5f5,%rcx
  115161:	f5 f5 f5 
  115164:	49 89 88 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r8)
  11516b:	48 8b 40 38          	mov    0x38(%rax),%rax
  11516f:	c6 00 00             	movb   $0x0,(%rax)
  115172:	eb 0b                	jmp    11517f <pqcrystals_kyber768_ref_poly_compress+0x877>
  115174:	49 c7 80 00 80 ff 7f 	movq   $0x0,0x7fff8000(%r8)
  11517b:	00 00 00 00 
  11517f:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  115183:	5b                   	pop    %rbx
  115184:	41 5c                	pop    %r12
  115186:	41 5d                	pop    %r13
  115188:	41 5e                	pop    %r14
  11518a:	41 5f                	pop    %r15
  11518c:	5d                   	pop    %rbp
  11518d:	c3                   	ret
  11518e:	4c 89 ef             	mov    %r13,%rdi
  115191:	e8 0a 0b fc ff       	call   d5ca0 <__asan_report_load2>
  115196:	48 89 f7             	mov    %rsi,%rdi
  115199:	e8 02 0e fc ff       	call   d5fa0 <__asan_report_store1>
  11519e:	4c 89 ef             	mov    %r13,%rdi
  1151a1:	e8 fa 0d fc ff       	call   d5fa0 <__asan_report_store1>
  1151a6:	4c 89 ef             	mov    %r13,%rdi
  1151a9:	e8 f2 0d fc ff       	call   d5fa0 <__asan_report_store1>
  1151ae:	4c 89 ef             	mov    %r13,%rdi
  1151b1:	e8 ea 0d fc ff       	call   d5fa0 <__asan_report_store1>

Disassembly of section .fini:
