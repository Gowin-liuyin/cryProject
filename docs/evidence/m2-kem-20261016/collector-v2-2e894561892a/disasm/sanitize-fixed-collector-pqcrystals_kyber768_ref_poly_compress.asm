
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-sanitize/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


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
  114923:	49 89 f0             	mov    %rsi,%r8
  114926:	49 89 ff             	mov    %rdi,%r15
  114929:	48 8d 05 40 19 06 00 	lea    0x61940(%rip),%rax        # 176270 <__asan_option_detect_stack_use_after_return>
  114930:	83 38 00             	cmpl   $0x0,(%rax)
  114933:	74 12                	je     114947 <pqcrystals_kyber768_ref_poly_compress+0x3f>
  114935:	bf 40 00 00 00       	mov    $0x40,%edi
  11493a:	4d 89 c6             	mov    %r8,%r14
  11493d:	e8 fe c5 f2 ff       	call   40f40 <__asan_stack_malloc_0>
  114942:	4d 89 f0             	mov    %r14,%r8
  114945:	eb 02                	jmp    114949 <pqcrystals_kyber768_ref_poly_compress+0x41>
  114947:	31 c0                	xor    %eax,%eax
  114949:	48 89 c7             	mov    %rax,%rdi
  11494c:	48 85 c0             	test   %rax,%rax
  11494f:	75 0e                	jne    11495f <pqcrystals_kyber768_ref_poly_compress+0x57>
  114951:	48 89 e7             	mov    %rsp,%rdi
  114954:	48 83 c7 c0          	add    $0xffffffffffffffc0,%rdi
  114958:	48 83 e7 e0          	and    $0xffffffffffffffe0,%rdi
  11495c:	48 89 fc             	mov    %rdi,%rsp
  11495f:	48 89 bb 98 00 00 00 	mov    %rdi,0x98(%rbx)
  114966:	4c 8d 57 20          	lea    0x20(%rdi),%r10
  11496a:	48 c7 07 b3 8a b5 41 	movq   $0x41b58ab3,(%rdi)
  114971:	48 8d 0d 20 f4 01 00 	lea    0x1f420(%rip),%rcx        # 133d98 <_ZN11__sanitizerL10kExtraRegsE+0x12be8>
  114978:	48 89 4f 08          	mov    %rcx,0x8(%rdi)
  11497c:	48 8d 0d 85 ff ff ff 	lea    -0x7b(%rip),%rcx        # 114908 <pqcrystals_kyber768_ref_poly_compress>
  114983:	48 89 4f 10          	mov    %rcx,0x10(%rdi)
  114987:	49 89 f9             	mov    %rdi,%r9
  11498a:	49 c1 e9 03          	shr    $0x3,%r9
  11498e:	48 b9 f1 f1 f1 f1 f8 	movabs $0xf3f3f3f8f1f1f1f1,%rcx
  114995:	f3 f3 f3 
  114998:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  11499f:	41 c6 81 04 80 ff 7f 	movb   $0x0,0x7fff8004(%r9)
  1149a6:	00 
  1149a7:	4d 85 c0             	test   %r8,%r8
  1149aa:	0f 95 c1             	setne  %cl
  1149ad:	41 f6 c0 01          	test   $0x1,%r8b
  1149b1:	41 0f 94 c6          	sete   %r14b
  1149b5:	41 20 ce             	and    %cl,%r14b
  1149b8:	4c 8d 5f 21          	lea    0x21(%rdi),%r11
  1149bc:	48 8d 4f 22          	lea    0x22(%rdi),%rcx
  1149c0:	48 89 8b 80 00 00 00 	mov    %rcx,0x80(%rbx)
  1149c7:	48 8d 4f 23          	lea    0x23(%rdi),%rcx
  1149cb:	48 89 4b 78          	mov    %rcx,0x78(%rbx)
  1149cf:	48 8d 4f 24          	lea    0x24(%rdi),%rcx
  1149d3:	48 89 4b 70          	mov    %rcx,0x70(%rbx)
  1149d7:	48 8d 4f 25          	lea    0x25(%rdi),%rcx
  1149db:	48 89 4b 68          	mov    %rcx,0x68(%rbx)
  1149df:	48 8d 4f 26          	lea    0x26(%rdi),%rcx
  1149e3:	48 89 4b 60          	mov    %rcx,0x60(%rbx)
  1149e7:	48 8d 4f 27          	lea    0x27(%rdi),%rcx
  1149eb:	48 89 4b 58          	mov    %rcx,0x58(%rbx)
  1149ef:	45 31 ed             	xor    %r13d,%r13d
  1149f2:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  1149f6:	4c 89 c2             	mov    %r8,%rdx
  1149f9:	4c 89 fe             	mov    %r15,%rsi
  1149fc:	0f 1f 40 00          	nopl   0x0(%rax)
  114a00:	4c 89 ab 90 00 00 00 	mov    %r13,0x90(%rbx)
  114a07:	48 89 93 88 00 00 00 	mov    %rdx,0x88(%rbx)
  114a0e:	49 89 d5             	mov    %rdx,%r13
  114a11:	45 31 e4             	xor    %r12d,%r12d
  114a14:	66 66 66 2e 0f 1f 84 	data16 data16 cs nopw 0x0(%rax,%rax,1)
  114a1b:	00 00 00 00 00 
  114a20:	45 84 f6             	test   %r14b,%r14b
  114a23:	0f 84 95 00 00 00    	je     114abe <pqcrystals_kyber768_ref_poly_compress+0x1b6>
  114a29:	4d 85 c0             	test   %r8,%r8
  114a2c:	0f 84 da 00 00 00    	je     114b0c <pqcrystals_kyber768_ref_poly_compress+0x204>
  114a32:	4d 85 ed             	test   %r13,%r13
  114a35:	0f 84 d1 00 00 00    	je     114b0c <pqcrystals_kyber768_ref_poly_compress+0x204>
  114a3b:	4d 39 c5             	cmp    %r8,%r13
  114a3e:	0f 82 c8 00 00 00    	jb     114b0c <pqcrystals_kyber768_ref_poly_compress+0x204>
  114a44:	45 84 f6             	test   %r14b,%r14b
  114a47:	0f 84 10 01 00 00    	je     114b5d <pqcrystals_kyber768_ref_poly_compress+0x255>
  114a4d:	4c 89 e9             	mov    %r13,%rcx
  114a50:	48 c1 e9 03          	shr    $0x3,%rcx
  114a54:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114a5b:	84 c9                	test   %cl,%cl
  114a5d:	75 4e                	jne    114aad <pqcrystals_kyber768_ref_poly_compress+0x1a5>
  114a5f:	48 8b 4b 50          	mov    0x50(%rbx),%rcx
  114a63:	42 0f bf 0c 61       	movswl (%rcx,%r12,2),%ecx
  114a68:	89 ca                	mov    %ecx,%edx
  114a6a:	c1 ea 0f             	shr    $0xf,%edx
  114a6d:	81 e2 01 0d 00 00    	and    $0xd01,%edx
  114a73:	01 ca                	add    %ecx,%edx
  114a75:	44 0f bf fa          	movswl %dx,%r15d
  114a79:	66 45 85 ff          	test   %r15w,%r15w
  114a7d:	0f 88 24 01 00 00    	js     114ba7 <pqcrystals_kyber768_ref_poly_compress+0x29f>
  114a83:	41 69 cf b0 af 13 00 	imul   $0x13afb0,%r15d,%ecx
  114a8a:	81 c1 7b 9a 00 08    	add    $0x8009a7b,%ecx
  114a90:	c1 e9 1c             	shr    $0x1c,%ecx
  114a93:	43 88 0c 22          	mov    %cl,(%r10,%r12,1)
  114a97:	49 ff c4             	inc    %r12
  114a9a:	49 83 c5 02          	add    $0x2,%r13
  114a9e:	49 83 fc 08          	cmp    $0x8,%r12
  114aa2:	0f 85 78 ff ff ff    	jne    114a20 <pqcrystals_kyber768_ref_poly_compress+0x118>
  114aa8:	e9 53 01 00 00       	jmp    114c00 <pqcrystals_kyber768_ref_poly_compress+0x2f8>
  114aad:	44 89 ea             	mov    %r13d,%edx
  114ab0:	80 e2 07             	and    $0x7,%dl
  114ab3:	fe c2                	inc    %dl
  114ab5:	38 ca                	cmp    %cl,%dl
  114ab7:	7c a6                	jl     114a5f <pqcrystals_kyber768_ref_poly_compress+0x157>
  114ab9:	e9 ec 06 00 00       	jmp    1151aa <pqcrystals_kyber768_ref_poly_compress+0x8a2>
  114abe:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114ac2:	48 8d 3d c7 c4 04 00 	lea    0x4c4c7(%rip),%rdi        # 160f90 <_ZL17kSuppressionTypes+0x1540>
  114ac9:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  114acd:	4c 89 c6             	mov    %r8,%rsi
  114ad0:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114ad4:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  114ad8:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  114adc:	4d 89 d7             	mov    %r10,%r15
  114adf:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114ae3:	e8 88 24 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  114ae8:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114aec:	4d 89 fa             	mov    %r15,%r10
  114aef:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  114af3:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114af7:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  114afb:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  114aff:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114b03:	4d 85 c0             	test   %r8,%r8
  114b06:	0f 85 26 ff ff ff    	jne    114a32 <pqcrystals_kyber768_ref_poly_compress+0x12a>
  114b0c:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114b10:	48 8d 3d 99 c4 04 00 	lea    0x4c499(%rip),%rdi        # 160fb0 <_ZL17kSuppressionTypes+0x1560>
  114b17:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  114b1b:	4c 89 c6             	mov    %r8,%rsi
  114b1e:	4c 89 ea             	mov    %r13,%rdx
  114b21:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114b25:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  114b29:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  114b2d:	4d 89 d7             	mov    %r10,%r15
  114b30:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114b34:	e8 87 5a ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114b39:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114b3d:	4d 89 fa             	mov    %r15,%r10
  114b40:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  114b44:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114b48:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  114b4c:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  114b50:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114b54:	45 84 f6             	test   %r14b,%r14b
  114b57:	0f 85 f0 fe ff ff    	jne    114a4d <pqcrystals_kyber768_ref_poly_compress+0x145>
  114b5d:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114b61:	48 8d 3d 58 c4 04 00 	lea    0x4c458(%rip),%rdi        # 160fc0 <_ZL17kSuppressionTypes+0x1570>
  114b68:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  114b6c:	4c 89 ee             	mov    %r13,%rsi
  114b6f:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114b73:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  114b77:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  114b7b:	4d 89 d7             	mov    %r10,%r15
  114b7e:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114b82:	e8 e9 23 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  114b87:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114b8b:	4d 89 fa             	mov    %r15,%r10
  114b8e:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  114b92:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114b96:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  114b9a:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  114b9e:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114ba2:	e9 a6 fe ff ff       	jmp    114a4d <pqcrystals_kyber768_ref_poly_compress+0x145>
  114ba7:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  114bab:	44 89 fe             	mov    %r15d,%esi
  114bae:	ba 04 00 00 00       	mov    $0x4,%edx
  114bb3:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114bb7:	48 8d 3d 22 c4 04 00 	lea    0x4c422(%rip),%rdi        # 160fe0 <_ZL17kSuppressionTypes+0x1590>
  114bbe:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114bc2:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  114bc6:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  114bca:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114bce:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114bd2:	e8 f9 38 ff ff       	call   1084d0 <__ubsan_handle_shift_out_of_bounds>
  114bd7:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114bdb:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114bdf:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  114be3:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114be7:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  114beb:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  114bef:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114bf3:	e9 8b fe ff ff       	jmp    114a83 <pqcrystals_kyber768_ref_poly_compress+0x17b>
  114bf8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
  114bff:	00 
  114c00:	45 0f b6 22          	movzbl (%r10),%r12d
  114c04:	49 83 fa ff          	cmp    $0xffffffffffffffff,%r10
  114c08:	0f 84 93 01 00 00    	je     114da1 <pqcrystals_kyber768_ref_poly_compress+0x499>
  114c0e:	45 0f b6 6a 01       	movzbl 0x1(%r10),%r13d
  114c13:	48 85 f6             	test   %rsi,%rsi
  114c16:	0f 84 d0 01 00 00    	je     114dec <pqcrystals_kyber768_ref_poly_compress+0x4e4>
  114c1c:	48 89 f1             	mov    %rsi,%rcx
  114c1f:	48 c1 e9 03          	shr    $0x3,%rcx
  114c23:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114c2a:	84 c9                	test   %cl,%cl
  114c2c:	0f 85 24 01 00 00    	jne    114d56 <pqcrystals_kyber768_ref_poly_compress+0x44e>
  114c32:	41 c0 e5 04          	shl    $0x4,%r13b
  114c36:	45 08 e5             	or     %r12b,%r13b
  114c39:	44 88 2e             	mov    %r13b,(%rsi)
  114c3c:	49 83 fa fe          	cmp    $0xfffffffffffffffe,%r10
  114c40:	0f 83 00 02 00 00    	jae    114e46 <pqcrystals_kyber768_ref_poly_compress+0x53e>
  114c46:	45 0f b6 7a 02       	movzbl 0x2(%r10),%r15d
  114c4b:	49 83 fa fd          	cmp    $0xfffffffffffffffd,%r10
  114c4f:	0f 83 3e 02 00 00    	jae    114e93 <pqcrystals_kyber768_ref_poly_compress+0x58b>
  114c55:	45 0f b6 62 03       	movzbl 0x3(%r10),%r12d
  114c5a:	4c 8d 6e 01          	lea    0x1(%rsi),%r13
  114c5e:	48 83 fe ff          	cmp    $0xffffffffffffffff,%rsi
  114c62:	0f 84 7e 02 00 00    	je     114ee6 <pqcrystals_kyber768_ref_poly_compress+0x5de>
  114c68:	4c 89 e9             	mov    %r13,%rcx
  114c6b:	48 c1 e9 03          	shr    $0x3,%rcx
  114c6f:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114c76:	84 c9                	test   %cl,%cl
  114c78:	0f 85 ea 00 00 00    	jne    114d68 <pqcrystals_kyber768_ref_poly_compress+0x460>
  114c7e:	41 c0 e4 04          	shl    $0x4,%r12b
  114c82:	45 08 fc             	or     %r15b,%r12b
  114c85:	45 88 65 00          	mov    %r12b,0x0(%r13)
  114c89:	49 83 fa fc          	cmp    $0xfffffffffffffffc,%r10
  114c8d:	0f 83 a6 02 00 00    	jae    114f39 <pqcrystals_kyber768_ref_poly_compress+0x631>
  114c93:	45 0f b6 7a 04       	movzbl 0x4(%r10),%r15d
  114c98:	49 83 fa fb          	cmp    $0xfffffffffffffffb,%r10
  114c9c:	0f 83 e1 02 00 00    	jae    114f83 <pqcrystals_kyber768_ref_poly_compress+0x67b>
  114ca2:	45 0f b6 62 05       	movzbl 0x5(%r10),%r12d
  114ca7:	4c 8d 6e 02          	lea    0x2(%rsi),%r13
  114cab:	48 83 fe fe          	cmp    $0xfffffffffffffffe,%rsi
  114caf:	0f 83 21 03 00 00    	jae    114fd6 <pqcrystals_kyber768_ref_poly_compress+0x6ce>
  114cb5:	4c 89 e9             	mov    %r13,%rcx
  114cb8:	48 c1 e9 03          	shr    $0x3,%rcx
  114cbc:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114cc3:	84 c9                	test   %cl,%cl
  114cc5:	0f 85 b0 00 00 00    	jne    114d7b <pqcrystals_kyber768_ref_poly_compress+0x473>
  114ccb:	41 c0 e4 04          	shl    $0x4,%r12b
  114ccf:	45 08 fc             	or     %r15b,%r12b
  114cd2:	45 88 65 00          	mov    %r12b,0x0(%r13)
  114cd6:	49 83 fa fa          	cmp    $0xfffffffffffffffa,%r10
  114cda:	0f 83 49 03 00 00    	jae    115029 <pqcrystals_kyber768_ref_poly_compress+0x721>
  114ce0:	45 0f b6 7a 06       	movzbl 0x6(%r10),%r15d
  114ce5:	49 83 fa f9          	cmp    $0xfffffffffffffff9,%r10
  114ce9:	0f 83 84 03 00 00    	jae    115073 <pqcrystals_kyber768_ref_poly_compress+0x76b>
  114cef:	45 0f b6 62 07       	movzbl 0x7(%r10),%r12d
  114cf4:	4c 8d 6e 03          	lea    0x3(%rsi),%r13
  114cf8:	48 83 fe fd          	cmp    $0xfffffffffffffffd,%rsi
  114cfc:	0f 83 c4 03 00 00    	jae    1150c6 <pqcrystals_kyber768_ref_poly_compress+0x7be>
  114d02:	4c 89 e9             	mov    %r13,%rcx
  114d05:	48 c1 e9 03          	shr    $0x3,%rcx
  114d09:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  114d10:	84 c9                	test   %cl,%cl
  114d12:	75 7a                	jne    114d8e <pqcrystals_kyber768_ref_poly_compress+0x486>
  114d14:	41 c0 e4 04          	shl    $0x4,%r12b
  114d18:	45 08 fc             	or     %r15b,%r12b
  114d1b:	44 88 66 03          	mov    %r12b,0x3(%rsi)
  114d1f:	48 83 fe fc          	cmp    $0xfffffffffffffffc,%rsi
  114d23:	4c 8b ab 90 00 00 00 	mov    0x90(%rbx),%r13
  114d2a:	0f 83 e9 03 00 00    	jae    115119 <pqcrystals_kyber768_ref_poly_compress+0x811>
  114d30:	48 83 c6 04          	add    $0x4,%rsi
  114d34:	49 ff c5             	inc    %r13
  114d37:	48 8b 93 88 00 00 00 	mov    0x88(%rbx),%rdx
  114d3e:	48 83 c2 10          	add    $0x10,%rdx
  114d42:	48 83 43 50 10       	addq   $0x10,0x50(%rbx)
  114d47:	49 83 fd 20          	cmp    $0x20,%r13
  114d4b:	0f 85 af fc ff ff    	jne    114a00 <pqcrystals_kyber768_ref_poly_compress+0xf8>
  114d51:	e9 0c 04 00 00       	jmp    115162 <pqcrystals_kyber768_ref_poly_compress+0x85a>
  114d56:	89 f2                	mov    %esi,%edx
  114d58:	80 e2 07             	and    $0x7,%dl
  114d5b:	38 ca                	cmp    %cl,%dl
  114d5d:	0f 8c cf fe ff ff    	jl     114c32 <pqcrystals_kyber768_ref_poly_compress+0x32a>
  114d63:	e9 4a 04 00 00       	jmp    1151b2 <pqcrystals_kyber768_ref_poly_compress+0x8aa>
  114d68:	44 89 ea             	mov    %r13d,%edx
  114d6b:	80 e2 07             	and    $0x7,%dl
  114d6e:	38 ca                	cmp    %cl,%dl
  114d70:	0f 8c 08 ff ff ff    	jl     114c7e <pqcrystals_kyber768_ref_poly_compress+0x376>
  114d76:	e9 3f 04 00 00       	jmp    1151ba <pqcrystals_kyber768_ref_poly_compress+0x8b2>
  114d7b:	44 89 ea             	mov    %r13d,%edx
  114d7e:	80 e2 07             	and    $0x7,%dl
  114d81:	38 ca                	cmp    %cl,%dl
  114d83:	0f 8c 42 ff ff ff    	jl     114ccb <pqcrystals_kyber768_ref_poly_compress+0x3c3>
  114d89:	e9 34 04 00 00       	jmp    1151c2 <pqcrystals_kyber768_ref_poly_compress+0x8ba>
  114d8e:	44 89 ea             	mov    %r13d,%edx
  114d91:	80 e2 07             	and    $0x7,%dl
  114d94:	38 ca                	cmp    %cl,%dl
  114d96:	0f 8c 78 ff ff ff    	jl     114d14 <pqcrystals_kyber768_ref_poly_compress+0x40c>
  114d9c:	e9 29 04 00 00       	jmp    1151ca <pqcrystals_kyber768_ref_poly_compress+0x8c2>
  114da1:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114da5:	48 8d 3d 54 c2 04 00 	lea    0x4c254(%rip),%rdi        # 161000 <_ZL17kSuppressionTypes+0x15b0>
  114dac:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  114db0:	4c 89 d6             	mov    %r10,%rsi
  114db3:	4c 89 da             	mov    %r11,%rdx
  114db6:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114dba:	4d 89 c5             	mov    %r8,%r13
  114dbd:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  114dc1:	4d 89 d7             	mov    %r10,%r15
  114dc4:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114dc8:	e8 f3 57 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114dcd:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114dd1:	4d 89 fa             	mov    %r15,%r10
  114dd4:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  114dd8:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114ddc:	4d 89 e8             	mov    %r13,%r8
  114ddf:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  114de3:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114de7:	e9 22 fe ff ff       	jmp    114c0e <pqcrystals_kyber768_ref_poly_compress+0x306>
  114dec:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114df0:	48 8d 3d 19 c2 04 00 	lea    0x4c219(%rip),%rdi        # 161010 <_ZL17kSuppressionTypes+0x15c0>
  114df7:	49 89 f7             	mov    %rsi,%r15
  114dfa:	31 f6                	xor    %esi,%esi
  114dfc:	31 d2                	xor    %edx,%edx
  114dfe:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114e02:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  114e06:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  114e0a:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114e0e:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114e12:	e8 a9 57 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114e17:	48 8d 3d 02 c2 04 00 	lea    0x4c202(%rip),%rdi        # 161020 <_ZL17kSuppressionTypes+0x15d0>
  114e1e:	4c 89 fe             	mov    %r15,%rsi
  114e21:	e8 4a 21 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  114e26:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114e2a:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114e2e:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  114e32:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114e36:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  114e3a:	4c 89 fe             	mov    %r15,%rsi
  114e3d:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114e41:	e9 d6 fd ff ff       	jmp    114c1c <pqcrystals_kyber768_ref_poly_compress+0x314>
  114e46:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114e4a:	48 8d 3d ef c1 04 00 	lea    0x4c1ef(%rip),%rdi        # 161040 <_ZL17kSuppressionTypes+0x15f0>
  114e51:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  114e55:	4c 89 d6             	mov    %r10,%rsi
  114e58:	48 8b 93 80 00 00 00 	mov    0x80(%rbx),%rdx
  114e5f:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114e63:	4d 89 c5             	mov    %r8,%r13
  114e66:	4d 89 cc             	mov    %r9,%r12
  114e69:	4d 89 d7             	mov    %r10,%r15
  114e6c:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114e70:	e8 4b 57 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114e75:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114e79:	4d 89 fa             	mov    %r15,%r10
  114e7c:	4d 89 e1             	mov    %r12,%r9
  114e7f:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114e83:	4d 89 e8             	mov    %r13,%r8
  114e86:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  114e8a:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114e8e:	e9 b3 fd ff ff       	jmp    114c46 <pqcrystals_kyber768_ref_poly_compress+0x33e>
  114e93:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114e97:	48 8d 3d b2 c1 04 00 	lea    0x4c1b2(%rip),%rdi        # 161050 <_ZL17kSuppressionTypes+0x1600>
  114e9e:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  114ea2:	4c 89 d6             	mov    %r10,%rsi
  114ea5:	48 8b 53 78          	mov    0x78(%rbx),%rdx
  114ea9:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114ead:	4d 89 c5             	mov    %r8,%r13
  114eb0:	4d 89 cc             	mov    %r9,%r12
  114eb3:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  114eb7:	4d 89 d7             	mov    %r10,%r15
  114eba:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114ebe:	e8 fd 56 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114ec3:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114ec7:	4d 89 fa             	mov    %r15,%r10
  114eca:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  114ecf:	4d 89 e1             	mov    %r12,%r9
  114ed2:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114ed6:	4d 89 e8             	mov    %r13,%r8
  114ed9:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  114edd:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114ee1:	e9 6f fd ff ff       	jmp    114c55 <pqcrystals_kyber768_ref_poly_compress+0x34d>
  114ee6:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114eea:	48 8d 3d 6f c1 04 00 	lea    0x4c16f(%rip),%rdi        # 161060 <_ZL17kSuppressionTypes+0x1610>
  114ef1:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  114ef5:	49 89 f7             	mov    %rsi,%r15
  114ef8:	4c 89 ea             	mov    %r13,%rdx
  114efb:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114eff:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  114f03:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  114f07:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114f0b:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114f0f:	e8 ac 56 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114f14:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114f18:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  114f1c:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  114f20:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114f24:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  114f28:	4c 89 fe             	mov    %r15,%rsi
  114f2b:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  114f30:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114f34:	e9 2f fd ff ff       	jmp    114c68 <pqcrystals_kyber768_ref_poly_compress+0x360>
  114f39:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114f3d:	48 8d 3d 2c c1 04 00 	lea    0x4c12c(%rip),%rdi        # 161070 <_ZL17kSuppressionTypes+0x1620>
  114f44:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  114f48:	4c 89 d6             	mov    %r10,%rsi
  114f4b:	48 8b 53 70          	mov    0x70(%rbx),%rdx
  114f4f:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114f53:	4d 89 c5             	mov    %r8,%r13
  114f56:	4d 89 cc             	mov    %r9,%r12
  114f59:	4d 89 d7             	mov    %r10,%r15
  114f5c:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114f60:	e8 5b 56 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114f65:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114f69:	4d 89 fa             	mov    %r15,%r10
  114f6c:	4d 89 e1             	mov    %r12,%r9
  114f6f:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114f73:	4d 89 e8             	mov    %r13,%r8
  114f76:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  114f7a:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114f7e:	e9 10 fd ff ff       	jmp    114c93 <pqcrystals_kyber768_ref_poly_compress+0x38b>
  114f83:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114f87:	48 8d 3d f2 c0 04 00 	lea    0x4c0f2(%rip),%rdi        # 161080 <_ZL17kSuppressionTypes+0x1630>
  114f8e:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  114f92:	4c 89 d6             	mov    %r10,%rsi
  114f95:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  114f99:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114f9d:	4d 89 c5             	mov    %r8,%r13
  114fa0:	4d 89 cc             	mov    %r9,%r12
  114fa3:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  114fa7:	4d 89 d7             	mov    %r10,%r15
  114faa:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114fae:	e8 0d 56 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  114fb3:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  114fb7:	4d 89 fa             	mov    %r15,%r10
  114fba:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  114fbf:	4d 89 e1             	mov    %r12,%r9
  114fc2:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114fc6:	4d 89 e8             	mov    %r13,%r8
  114fc9:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  114fcd:	48 8b 43 28          	mov    0x28(%rbx),%rax
  114fd1:	e9 cc fc ff ff       	jmp    114ca2 <pqcrystals_kyber768_ref_poly_compress+0x39a>
  114fd6:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  114fda:	48 8d 3d af c0 04 00 	lea    0x4c0af(%rip),%rdi        # 161090 <_ZL17kSuppressionTypes+0x1640>
  114fe1:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  114fe5:	49 89 f7             	mov    %rsi,%r15
  114fe8:	4c 89 ea             	mov    %r13,%rdx
  114feb:	48 89 43 28          	mov    %rax,0x28(%rbx)
  114fef:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  114ff3:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  114ff7:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  114ffb:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  114fff:	e8 bc 55 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  115004:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  115008:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  11500c:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  115010:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  115014:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  115018:	4c 89 fe             	mov    %r15,%rsi
  11501b:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  115020:	48 8b 43 28          	mov    0x28(%rbx),%rax
  115024:	e9 8c fc ff ff       	jmp    114cb5 <pqcrystals_kyber768_ref_poly_compress+0x3ad>
  115029:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  11502d:	48 8d 3d 6c c0 04 00 	lea    0x4c06c(%rip),%rdi        # 1610a0 <_ZL17kSuppressionTypes+0x1650>
  115034:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  115038:	4c 89 d6             	mov    %r10,%rsi
  11503b:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  11503f:	48 89 43 28          	mov    %rax,0x28(%rbx)
  115043:	4d 89 c5             	mov    %r8,%r13
  115046:	4d 89 cc             	mov    %r9,%r12
  115049:	4d 89 d7             	mov    %r10,%r15
  11504c:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  115050:	e8 6b 55 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  115055:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  115059:	4d 89 fa             	mov    %r15,%r10
  11505c:	4d 89 e1             	mov    %r12,%r9
  11505f:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  115063:	4d 89 e8             	mov    %r13,%r8
  115066:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  11506a:	48 8b 43 28          	mov    0x28(%rbx),%rax
  11506e:	e9 6d fc ff ff       	jmp    114ce0 <pqcrystals_kyber768_ref_poly_compress+0x3d8>
  115073:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  115077:	48 8d 3d 32 c0 04 00 	lea    0x4c032(%rip),%rdi        # 1610b0 <_ZL17kSuppressionTypes+0x1660>
  11507e:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  115082:	4c 89 d6             	mov    %r10,%rsi
  115085:	48 8b 53 58          	mov    0x58(%rbx),%rdx
  115089:	48 89 43 28          	mov    %rax,0x28(%rbx)
  11508d:	4d 89 c5             	mov    %r8,%r13
  115090:	4d 89 cc             	mov    %r9,%r12
  115093:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  115097:	4d 89 d7             	mov    %r10,%r15
  11509a:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  11509e:	e8 1d 55 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1150a3:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  1150a7:	4d 89 fa             	mov    %r15,%r10
  1150aa:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  1150af:	4d 89 e1             	mov    %r12,%r9
  1150b2:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1150b6:	4d 89 e8             	mov    %r13,%r8
  1150b9:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  1150bd:	48 8b 43 28          	mov    0x28(%rbx),%rax
  1150c1:	e9 29 fc ff ff       	jmp    114cef <pqcrystals_kyber768_ref_poly_compress+0x3e7>
  1150c6:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1150ca:	48 8d 3d ef bf 04 00 	lea    0x4bfef(%rip),%rdi        # 1610c0 <_ZL17kSuppressionTypes+0x1670>
  1150d1:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  1150d5:	49 89 f7             	mov    %rsi,%r15
  1150d8:	4c 89 ea             	mov    %r13,%rdx
  1150db:	48 89 43 28          	mov    %rax,0x28(%rbx)
  1150df:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  1150e3:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  1150e7:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  1150eb:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  1150ef:	e8 cc 54 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1150f4:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  1150f8:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  1150fc:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  115100:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  115104:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  115108:	4c 89 fe             	mov    %r15,%rsi
  11510b:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  115110:	48 8b 43 28          	mov    0x28(%rbx),%rax
  115114:	e9 e9 fb ff ff       	jmp    114d02 <pqcrystals_kyber768_ref_poly_compress+0x3fa>
  115119:	48 8d 56 04          	lea    0x4(%rsi),%rdx
  11511d:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  115121:	48 8d 3d a8 bf 04 00 	lea    0x4bfa8(%rip),%rdi        # 1610d0 <_ZL17kSuppressionTypes+0x1680>
  115128:	49 89 f4             	mov    %rsi,%r12
  11512b:	48 89 43 28          	mov    %rax,0x28(%rbx)
  11512f:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  115133:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  115137:	4d 89 d7             	mov    %r10,%r15
  11513a:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  11513e:	e8 7d 54 ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  115143:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  115147:	4d 89 fa             	mov    %r15,%r10
  11514a:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  11514e:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  115152:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  115156:	4c 89 e6             	mov    %r12,%rsi
  115159:	48 8b 43 28          	mov    0x28(%rbx),%rax
  11515d:	e9 ce fb ff ff       	jmp    114d30 <pqcrystals_kyber768_ref_poly_compress+0x428>
  115162:	41 c6 81 04 80 ff 7f 	movb   $0xf8,0x7fff8004(%r9)
  115169:	f8 
  11516a:	48 c7 07 0e 36 e0 45 	movq   $0x45e0360e,(%rdi)
  115171:	48 85 c0             	test   %rax,%rax
  115174:	74 1a                	je     115190 <pqcrystals_kyber768_ref_poly_compress+0x888>
  115176:	48 b9 f5 f5 f5 f5 f5 	movabs $0xf5f5f5f5f5f5f5f5,%rcx
  11517d:	f5 f5 f5 
  115180:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  115187:	48 8b 40 38          	mov    0x38(%rax),%rax
  11518b:	c6 00 00             	movb   $0x0,(%rax)
  11518e:	eb 0b                	jmp    11519b <pqcrystals_kyber768_ref_poly_compress+0x893>
  115190:	49 c7 81 00 80 ff 7f 	movq   $0x0,0x7fff8000(%r9)
  115197:	00 00 00 00 
  11519b:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  11519f:	5b                   	pop    %rbx
  1151a0:	41 5c                	pop    %r12
  1151a2:	41 5d                	pop    %r13
  1151a4:	41 5e                	pop    %r14
  1151a6:	41 5f                	pop    %r15
  1151a8:	5d                   	pop    %rbp
  1151a9:	c3                   	ret
  1151aa:	4c 89 ef             	mov    %r13,%rdi
  1151ad:	e8 ee 0a fc ff       	call   d5ca0 <__asan_report_load2>
  1151b2:	48 89 f7             	mov    %rsi,%rdi
  1151b5:	e8 e6 0d fc ff       	call   d5fa0 <__asan_report_store1>
  1151ba:	4c 89 ef             	mov    %r13,%rdi
  1151bd:	e8 de 0d fc ff       	call   d5fa0 <__asan_report_store1>
  1151c2:	4c 89 ef             	mov    %r13,%rdi
  1151c5:	e8 d6 0d fc ff       	call   d5fa0 <__asan_report_store1>
  1151ca:	4c 89 ef             	mov    %r13,%rdi
  1151cd:	e8 ce 0d fc ff       	call   d5fa0 <__asan_report_store1>

Disassembly of section .fini:
