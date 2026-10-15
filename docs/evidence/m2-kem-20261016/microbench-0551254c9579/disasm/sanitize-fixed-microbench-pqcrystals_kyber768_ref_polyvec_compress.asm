
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-sanitize/microbench/fixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000001196d8 <pqcrystals_kyber768_ref_polyvec_compress>:
  1196d8:	55                   	push   %rbp
  1196d9:	48 89 e5             	mov    %rsp,%rbp
  1196dc:	41 57                	push   %r15
  1196de:	41 56                	push   %r14
  1196e0:	41 55                	push   %r13
  1196e2:	41 54                	push   %r12
  1196e4:	53                   	push   %rbx
  1196e5:	48 83 e4 e0          	and    $0xffffffffffffffe0,%rsp
  1196e9:	48 81 ec c0 00 00 00 	sub    $0xc0,%rsp
  1196f0:	48 89 e3             	mov    %rsp,%rbx
  1196f3:	49 89 f0             	mov    %rsi,%r8
  1196f6:	49 89 fe             	mov    %rdi,%r14
  1196f9:	48 8d 05 70 ed 05 00 	lea    0x5ed70(%rip),%rax        # 178470 <__asan_option_detect_stack_use_after_return>
  119700:	83 38 00             	cmpl   $0x0,(%rax)
  119703:	74 12                	je     119717 <pqcrystals_kyber768_ref_polyvec_compress+0x3f>
  119705:	bf 40 00 00 00       	mov    $0x40,%edi
  11970a:	4d 89 c7             	mov    %r8,%r15
  11970d:	e8 2e 88 f2 ff       	call   41f40 <__asan_stack_malloc_0>
  119712:	4d 89 f8             	mov    %r15,%r8
  119715:	eb 02                	jmp    119719 <pqcrystals_kyber768_ref_polyvec_compress+0x41>
  119717:	31 c0                	xor    %eax,%eax
  119719:	48 89 c7             	mov    %rax,%rdi
  11971c:	48 85 c0             	test   %rax,%rax
  11971f:	75 0e                	jne    11972f <pqcrystals_kyber768_ref_polyvec_compress+0x57>
  119721:	48 89 e7             	mov    %rsp,%rdi
  119724:	48 83 c7 c0          	add    $0xffffffffffffffc0,%rdi
  119728:	48 83 e7 e0          	and    $0xffffffffffffffe0,%rdi
  11972c:	48 89 fc             	mov    %rdi,%rsp
  11972f:	48 89 bb 98 00 00 00 	mov    %rdi,0x98(%rbx)
  119736:	4c 8d 67 20          	lea    0x20(%rdi),%r12
  11973a:	48 c7 07 b3 8a b5 41 	movq   $0x41b58ab3,(%rdi)
  119741:	48 8d 0d 94 c7 01 00 	lea    0x1c794(%rip),%rcx        # 135edc <_ZN11__sanitizerL10kExtraRegsE+0x12d2c>
  119748:	48 89 4f 08          	mov    %rcx,0x8(%rdi)
  11974c:	48 8d 0d 85 ff ff ff 	lea    -0x7b(%rip),%rcx        # 1196d8 <pqcrystals_kyber768_ref_polyvec_compress>
  119753:	48 89 4f 10          	mov    %rcx,0x10(%rdi)
  119757:	49 89 f9             	mov    %rdi,%r9
  11975a:	49 c1 e9 03          	shr    $0x3,%r9
  11975e:	48 b9 f1 f1 f1 f1 f8 	movabs $0xf3f3f3f8f1f1f1f1,%rcx
  119765:	f3 f3 f3 
  119768:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  11976f:	41 c6 81 04 80 ff 7f 	movb   $0x0,0x7fff8004(%r9)
  119776:	00 
  119777:	4d 85 c0             	test   %r8,%r8
  11977a:	0f 95 c1             	setne  %cl
  11977d:	41 f6 c0 01          	test   $0x1,%r8b
  119781:	41 0f 94 c7          	sete   %r15b
  119785:	41 20 cf             	and    %cl,%r15b
  119788:	4c 8d 5f 22          	lea    0x22(%rdi),%r11
  11978c:	48 8d 4f 24          	lea    0x24(%rdi),%rcx
  119790:	48 89 4b 68          	mov    %rcx,0x68(%rbx)
  119794:	48 8d 4f 26          	lea    0x26(%rdi),%rcx
  119798:	48 89 4b 60          	mov    %rcx,0x60(%rbx)
  11979c:	31 d2                	xor    %edx,%edx
  11979e:	4d 89 c5             	mov    %r8,%r13
  1197a1:	4c 89 c1             	mov    %r8,%rcx
  1197a4:	4c 89 f6             	mov    %r14,%rsi
  1197a7:	4d 89 c6             	mov    %r8,%r14
  1197aa:	eb 31                	jmp    1197dd <pqcrystals_kyber768_ref_polyvec_compress+0x105>
  1197ac:	0f 1f 40 00          	nopl   0x0(%rax)
  1197b0:	48 8b 93 88 00 00 00 	mov    0x88(%rbx),%rdx
  1197b7:	48 ff c2             	inc    %rdx
  1197ba:	4c 8b 73 78          	mov    0x78(%rbx),%r14
  1197be:	49 81 c6 00 02 00 00 	add    $0x200,%r14
  1197c5:	4c 8b ab 80 00 00 00 	mov    0x80(%rbx),%r13
  1197cc:	49 81 c5 00 02 00 00 	add    $0x200,%r13
  1197d3:	48 83 fa 03          	cmp    $0x3,%rdx
  1197d7:	0f 84 54 08 00 00    	je     11a031 <pqcrystals_kyber768_ref_polyvec_compress+0x959>
  1197dd:	4d 85 c0             	test   %r8,%r8
  1197e0:	0f 95 c1             	setne  %cl
  1197e3:	48 89 93 88 00 00 00 	mov    %rdx,0x88(%rbx)
  1197ea:	48 c1 e2 09          	shl    $0x9,%rdx
  1197ee:	4c 01 c2             	add    %r8,%rdx
  1197f1:	41 0f 95 c2          	setne  %r10b
  1197f5:	48 89 53 58          	mov    %rdx,0x58(%rbx)
  1197f9:	4c 39 c2             	cmp    %r8,%rdx
  1197fc:	0f 93 c2             	setae  %dl
  1197ff:	41 20 ca             	and    %cl,%r10b
  119802:	41 20 d2             	and    %dl,%r10b
  119805:	44 88 53 57          	mov    %r10b,0x57(%rbx)
  119809:	4c 89 ab 80 00 00 00 	mov    %r13,0x80(%rbx)
  119810:	4d 89 ea             	mov    %r13,%r10
  119813:	4c 89 73 78          	mov    %r14,0x78(%rbx)
  119817:	4c 89 73 70          	mov    %r14,0x70(%rbx)
  11981b:	45 31 f6             	xor    %r14d,%r14d
  11981e:	66 90                	xchg   %ax,%ax
  119820:	4c 89 b3 90 00 00 00 	mov    %r14,0x90(%rbx)
  119827:	45 31 ed             	xor    %r13d,%r13d
  11982a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
  119830:	45 84 ff             	test   %r15b,%r15b
  119833:	0f 84 a9 00 00 00    	je     1198e2 <pqcrystals_kyber768_ref_polyvec_compress+0x20a>
  119839:	80 7b 57 00          	cmpb   $0x0,0x57(%rbx)
  11983d:	0f 84 ee 00 00 00    	je     119931 <pqcrystals_kyber768_ref_polyvec_compress+0x259>
  119843:	45 84 ff             	test   %r15b,%r15b
  119846:	0f 84 37 01 00 00    	je     119983 <pqcrystals_kyber768_ref_polyvec_compress+0x2ab>
  11984c:	48 8b 4b 70          	mov    0x70(%rbx),%rcx
  119850:	4e 8d 34 29          	lea    (%rcx,%r13,1),%r14
  119854:	4d 85 c0             	test   %r8,%r8
  119857:	0f 84 71 01 00 00    	je     1199ce <pqcrystals_kyber768_ref_polyvec_compress+0x2f6>
  11985d:	4d 85 f6             	test   %r14,%r14
  119860:	0f 84 68 01 00 00    	je     1199ce <pqcrystals_kyber768_ref_polyvec_compress+0x2f6>
  119866:	4c 3b 73 58          	cmp    0x58(%rbx),%r14
  11986a:	0f 82 5e 01 00 00    	jb     1199ce <pqcrystals_kyber768_ref_polyvec_compress+0x2f6>
  119870:	45 84 ff             	test   %r15b,%r15b
  119873:	0f 84 a9 01 00 00    	je     119a22 <pqcrystals_kyber768_ref_polyvec_compress+0x34a>
  119879:	4c 89 f1             	mov    %r14,%rcx
  11987c:	48 c1 e9 03          	shr    $0x3,%rcx
  119880:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119887:	84 c9                	test   %cl,%cl
  119889:	75 46                	jne    1198d1 <pqcrystals_kyber768_ref_polyvec_compress+0x1f9>
  11988b:	43 0f bf 0c 2a       	movswl (%r10,%r13,1),%ecx
  119890:	89 ca                	mov    %ecx,%edx
  119892:	c1 ea 0f             	shr    $0xf,%edx
  119895:	81 e2 01 0d 00 00    	and    $0xd01,%edx
  11989b:	01 ca                	add    %ecx,%edx
  11989d:	0f b7 ca             	movzwl %dx,%ecx
  1198a0:	48 69 c9 00 dc be 4e 	imul   $0x4ebedc00,%rcx,%rcx
  1198a7:	ba 37 d5 09 80       	mov    $0x8009d537,%edx
  1198ac:	48 01 d1             	add    %rdx,%rcx
  1198af:	48 c1 e9 20          	shr    $0x20,%rcx
  1198b3:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
  1198b9:	66 43 89 0c 2c       	mov    %cx,(%r12,%r13,1)
  1198be:	49 83 c5 02          	add    $0x2,%r13
  1198c2:	49 83 fd 08          	cmp    $0x8,%r13
  1198c6:	0f 85 64 ff ff ff    	jne    119830 <pqcrystals_kyber768_ref_polyvec_compress+0x158>
  1198cc:	e9 9f 01 00 00       	jmp    119a70 <pqcrystals_kyber768_ref_polyvec_compress+0x398>
  1198d1:	44 89 f2             	mov    %r14d,%edx
  1198d4:	80 e2 07             	and    $0x7,%dl
  1198d7:	fe c2                	inc    %dl
  1198d9:	38 ca                	cmp    %cl,%dl
  1198db:	7c ae                	jl     11988b <pqcrystals_kyber768_ref_polyvec_compress+0x1b3>
  1198dd:	e9 97 07 00 00       	jmp    11a079 <pqcrystals_kyber768_ref_polyvec_compress+0x9a1>
  1198e2:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1198e6:	48 8d 3d 83 a1 04 00 	lea    0x4a183(%rip),%rdi        # 163a70 <_ZL17kSuppressionTypes+0x2020>
  1198ed:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1198f1:	4c 89 c6             	mov    %r8,%rsi
  1198f4:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1198f8:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  1198fc:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119900:	4d 89 de             	mov    %r11,%r14
  119903:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119907:	e8 64 e6 fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  11990c:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119910:	4d 89 f3             	mov    %r14,%r11
  119913:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119917:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11991b:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  11991f:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119923:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119927:	80 7b 57 00          	cmpb   $0x0,0x57(%rbx)
  11992b:	0f 85 12 ff ff ff    	jne    119843 <pqcrystals_kyber768_ref_polyvec_compress+0x16b>
  119931:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119935:	48 8d 3d 54 a1 04 00 	lea    0x4a154(%rip),%rdi        # 163a90 <_ZL17kSuppressionTypes+0x2040>
  11993c:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119940:	4c 89 c6             	mov    %r8,%rsi
  119943:	48 8b 53 58          	mov    0x58(%rbx),%rdx
  119947:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11994b:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11994f:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119953:	4d 89 de             	mov    %r11,%r14
  119956:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11995a:	e8 61 1c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  11995f:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119963:	4d 89 f3             	mov    %r14,%r11
  119966:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11996a:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11996e:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119972:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119976:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11997a:	45 84 ff             	test   %r15b,%r15b
  11997d:	0f 85 c9 fe ff ff    	jne    11984c <pqcrystals_kyber768_ref_polyvec_compress+0x174>
  119983:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119987:	48 8d 3d 12 a1 04 00 	lea    0x4a112(%rip),%rdi        # 163aa0 <_ZL17kSuppressionTypes+0x2050>
  11998e:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119992:	48 8b 73 58          	mov    0x58(%rbx),%rsi
  119996:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11999a:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11999e:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1199a2:	4d 89 de             	mov    %r11,%r14
  1199a5:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1199a9:	e8 c2 e5 fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  1199ae:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1199b2:	4d 89 f3             	mov    %r14,%r11
  1199b5:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1199b9:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1199bd:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  1199c1:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1199c5:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1199c9:	e9 7e fe ff ff       	jmp    11984c <pqcrystals_kyber768_ref_polyvec_compress+0x174>
  1199ce:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1199d2:	48 8d 3d e7 a0 04 00 	lea    0x4a0e7(%rip),%rdi        # 163ac0 <_ZL17kSuppressionTypes+0x2070>
  1199d9:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1199dd:	48 8b 73 58          	mov    0x58(%rbx),%rsi
  1199e1:	4c 89 f2             	mov    %r14,%rdx
  1199e4:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1199e8:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  1199ec:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1199f0:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  1199f4:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1199f8:	e8 c3 1b ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1199fd:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119a01:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119a05:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119a09:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119a0d:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119a11:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119a15:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119a19:	45 84 ff             	test   %r15b,%r15b
  119a1c:	0f 85 57 fe ff ff    	jne    119879 <pqcrystals_kyber768_ref_polyvec_compress+0x1a1>
  119a22:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119a26:	48 8d 3d a3 a0 04 00 	lea    0x4a0a3(%rip),%rdi        # 163ad0 <_ZL17kSuppressionTypes+0x2080>
  119a2d:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119a31:	4c 89 f6             	mov    %r14,%rsi
  119a34:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119a38:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119a3c:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119a40:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119a44:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119a48:	e8 23 e5 fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  119a4d:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119a51:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119a55:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119a59:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119a5d:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119a61:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119a65:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119a69:	e9 0b fe ff ff       	jmp    119879 <pqcrystals_kyber768_ref_polyvec_compress+0x1a1>
  119a6e:	66 90                	xchg   %ax,%ax
  119a70:	45 0f b6 34 24       	movzbl (%r12),%r14d
  119a75:	48 85 f6             	test   %rsi,%rsi
  119a78:	0f 84 e4 01 00 00    	je     119c62 <pqcrystals_kyber768_ref_polyvec_compress+0x58a>
  119a7e:	48 89 f1             	mov    %rsi,%rcx
  119a81:	48 c1 e9 03          	shr    $0x3,%rcx
  119a85:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119a8c:	84 c9                	test   %cl,%cl
  119a8e:	0f 85 57 01 00 00    	jne    119beb <pqcrystals_kyber768_ref_polyvec_compress+0x513>
  119a94:	44 88 36             	mov    %r14b,(%rsi)
  119a97:	41 0f b6 54 24 01    	movzbl 0x1(%r12),%edx
  119a9d:	49 83 fc fe          	cmp    $0xfffffffffffffffe,%r12
  119aa1:	0f 84 15 02 00 00    	je     119cbc <pqcrystals_kyber768_ref_polyvec_compress+0x5e4>
  119aa7:	45 0f b6 6c 24 02    	movzbl 0x2(%r12),%r13d
  119aad:	4c 8d 76 01          	lea    0x1(%rsi),%r14
  119ab1:	48 83 fe ff          	cmp    $0xffffffffffffffff,%rsi
  119ab5:	0f 84 53 02 00 00    	je     119d0e <pqcrystals_kyber768_ref_polyvec_compress+0x636>
  119abb:	4c 89 f1             	mov    %r14,%rcx
  119abe:	48 c1 e9 03          	shr    $0x3,%rcx
  119ac2:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119ac9:	84 c9                	test   %cl,%cl
  119acb:	0f 85 2c 01 00 00    	jne    119bfd <pqcrystals_kyber768_ref_polyvec_compress+0x525>
  119ad1:	41 c0 e5 02          	shl    $0x2,%r13b
  119ad5:	41 08 d5             	or     %dl,%r13b
  119ad8:	45 88 2e             	mov    %r13b,(%r14)
  119adb:	49 83 fc fe          	cmp    $0xfffffffffffffffe,%r12
  119adf:	0f 84 80 02 00 00    	je     119d65 <pqcrystals_kyber768_ref_polyvec_compress+0x68d>
  119ae5:	45 0f b7 6c 24 02    	movzwl 0x2(%r12),%r13d
  119aeb:	49 83 fc fc          	cmp    $0xfffffffffffffffc,%r12
  119aef:	0f 83 bb 02 00 00    	jae    119db0 <pqcrystals_kyber768_ref_polyvec_compress+0x6d8>
  119af5:	45 0f b6 74 24 04    	movzbl 0x4(%r12),%r14d
  119afb:	48 8d 56 02          	lea    0x2(%rsi),%rdx
  119aff:	48 83 fe fe          	cmp    $0xfffffffffffffffe,%rsi
  119b03:	0f 83 f5 02 00 00    	jae    119dfe <pqcrystals_kyber768_ref_polyvec_compress+0x726>
  119b09:	48 89 d1             	mov    %rdx,%rcx
  119b0c:	48 c1 e9 03          	shr    $0x3,%rcx
  119b10:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119b17:	84 c9                	test   %cl,%cl
  119b19:	0f 85 f8 00 00 00    	jne    119c17 <pqcrystals_kyber768_ref_polyvec_compress+0x53f>
  119b1f:	41 c1 ed 06          	shr    $0x6,%r13d
  119b23:	41 c0 e6 04          	shl    $0x4,%r14b
  119b27:	45 08 ee             	or     %r13b,%r14b
  119b2a:	44 88 32             	mov    %r14b,(%rdx)
  119b2d:	49 83 fc fc          	cmp    $0xfffffffffffffffc,%r12
  119b31:	0f 83 20 03 00 00    	jae    119e57 <pqcrystals_kyber768_ref_polyvec_compress+0x77f>
  119b37:	45 0f b7 6c 24 04    	movzwl 0x4(%r12),%r13d
  119b3d:	49 83 fc fa          	cmp    $0xfffffffffffffffa,%r12
  119b41:	0f 83 5c 03 00 00    	jae    119ea3 <pqcrystals_kyber768_ref_polyvec_compress+0x7cb>
  119b47:	45 0f b6 74 24 06    	movzbl 0x6(%r12),%r14d
  119b4d:	48 8d 56 03          	lea    0x3(%rsi),%rdx
  119b51:	48 83 fe fd          	cmp    $0xfffffffffffffffd,%rsi
  119b55:	0f 83 96 03 00 00    	jae    119ef1 <pqcrystals_kyber768_ref_polyvec_compress+0x819>
  119b5b:	48 89 d1             	mov    %rdx,%rcx
  119b5e:	48 c1 e9 03          	shr    $0x3,%rcx
  119b62:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119b69:	84 c9                	test   %cl,%cl
  119b6b:	0f 85 c2 00 00 00    	jne    119c33 <pqcrystals_kyber768_ref_polyvec_compress+0x55b>
  119b71:	41 c1 ed 04          	shr    $0x4,%r13d
  119b75:	41 c0 e6 06          	shl    $0x6,%r14b
  119b79:	45 08 ee             	or     %r13b,%r14b
  119b7c:	44 88 32             	mov    %r14b,(%rdx)
  119b7f:	49 83 fc fa          	cmp    $0xfffffffffffffffa,%r12
  119b83:	0f 83 c1 03 00 00    	jae    119f4a <pqcrystals_kyber768_ref_polyvec_compress+0x872>
  119b89:	45 0f b7 6c 24 06    	movzwl 0x6(%r12),%r13d
  119b8f:	4c 8d 76 04          	lea    0x4(%rsi),%r14
  119b93:	48 83 fe fc          	cmp    $0xfffffffffffffffc,%rsi
  119b97:	0f 83 f9 03 00 00    	jae    119f96 <pqcrystals_kyber768_ref_polyvec_compress+0x8be>
  119b9d:	4c 89 f1             	mov    %r14,%rcx
  119ba0:	48 c1 e9 03          	shr    $0x3,%rcx
  119ba4:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119bab:	84 c9                	test   %cl,%cl
  119bad:	0f 85 9c 00 00 00    	jne    119c4f <pqcrystals_kyber768_ref_polyvec_compress+0x577>
  119bb3:	41 c1 ed 02          	shr    $0x2,%r13d
  119bb7:	44 88 6e 04          	mov    %r13b,0x4(%rsi)
  119bbb:	48 83 fe fb          	cmp    $0xfffffffffffffffb,%rsi
  119bbf:	4c 8b b3 90 00 00 00 	mov    0x90(%rbx),%r14
  119bc6:	0f 83 1a 04 00 00    	jae    119fe6 <pqcrystals_kyber768_ref_polyvec_compress+0x90e>
  119bcc:	48 83 c6 05          	add    $0x5,%rsi
  119bd0:	49 ff c6             	inc    %r14
  119bd3:	48 83 43 70 08       	addq   $0x8,0x70(%rbx)
  119bd8:	49 83 c2 08          	add    $0x8,%r10
  119bdc:	49 83 fe 40          	cmp    $0x40,%r14
  119be0:	0f 85 3a fc ff ff    	jne    119820 <pqcrystals_kyber768_ref_polyvec_compress+0x148>
  119be6:	e9 c5 fb ff ff       	jmp    1197b0 <pqcrystals_kyber768_ref_polyvec_compress+0xd8>
  119beb:	89 f2                	mov    %esi,%edx
  119bed:	80 e2 07             	and    $0x7,%dl
  119bf0:	38 ca                	cmp    %cl,%dl
  119bf2:	0f 8c 9c fe ff ff    	jl     119a94 <pqcrystals_kyber768_ref_polyvec_compress+0x3bc>
  119bf8:	e9 84 04 00 00       	jmp    11a081 <pqcrystals_kyber768_ref_polyvec_compress+0x9a9>
  119bfd:	88 53 40             	mov    %dl,0x40(%rbx)
  119c00:	44 89 f2             	mov    %r14d,%edx
  119c03:	80 e2 07             	and    $0x7,%dl
  119c06:	38 ca                	cmp    %cl,%dl
  119c08:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  119c0c:	0f 8c bf fe ff ff    	jl     119ad1 <pqcrystals_kyber768_ref_polyvec_compress+0x3f9>
  119c12:	e9 72 04 00 00       	jmp    11a089 <pqcrystals_kyber768_ref_polyvec_compress+0x9b1>
  119c17:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  119c1b:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119c1f:	80 e2 07             	and    $0x7,%dl
  119c22:	38 ca                	cmp    %cl,%dl
  119c24:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119c28:	0f 8c f1 fe ff ff    	jl     119b1f <pqcrystals_kyber768_ref_polyvec_compress+0x447>
  119c2e:	e9 5e 04 00 00       	jmp    11a091 <pqcrystals_kyber768_ref_polyvec_compress+0x9b9>
  119c33:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  119c37:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119c3b:	80 e2 07             	and    $0x7,%dl
  119c3e:	38 ca                	cmp    %cl,%dl
  119c40:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119c44:	0f 8c 27 ff ff ff    	jl     119b71 <pqcrystals_kyber768_ref_polyvec_compress+0x499>
  119c4a:	e9 4a 04 00 00       	jmp    11a099 <pqcrystals_kyber768_ref_polyvec_compress+0x9c1>
  119c4f:	44 89 f2             	mov    %r14d,%edx
  119c52:	80 e2 07             	and    $0x7,%dl
  119c55:	38 ca                	cmp    %cl,%dl
  119c57:	0f 8c 56 ff ff ff    	jl     119bb3 <pqcrystals_kyber768_ref_polyvec_compress+0x4db>
  119c5d:	e9 3f 04 00 00       	jmp    11a0a1 <pqcrystals_kyber768_ref_polyvec_compress+0x9c9>
  119c62:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119c66:	48 8d 3d 83 9e 04 00 	lea    0x49e83(%rip),%rdi        # 163af0 <_ZL17kSuppressionTypes+0x20a0>
  119c6d:	49 89 f5             	mov    %rsi,%r13
  119c70:	31 f6                	xor    %esi,%esi
  119c72:	31 d2                	xor    %edx,%edx
  119c74:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119c78:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119c7c:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119c80:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119c84:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119c88:	e8 33 19 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119c8d:	48 8d 3d 6c 9e 04 00 	lea    0x49e6c(%rip),%rdi        # 163b00 <_ZL17kSuppressionTypes+0x20b0>
  119c94:	4c 89 ee             	mov    %r13,%rsi
  119c97:	e8 d4 e2 fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  119c9c:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119ca0:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119ca4:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119ca8:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119cac:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119cb0:	4c 89 ee             	mov    %r13,%rsi
  119cb3:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119cb7:	e9 c2 fd ff ff       	jmp    119a7e <pqcrystals_kyber768_ref_polyvec_compress+0x3a6>
  119cbc:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119cc0:	48 8d 3d 59 9e 04 00 	lea    0x49e59(%rip),%rdi        # 163b20 <_ZL17kSuppressionTypes+0x20d0>
  119cc7:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119ccb:	4c 89 e6             	mov    %r12,%rsi
  119cce:	88 53 40             	mov    %dl,0x40(%rbx)
  119cd1:	4c 89 da             	mov    %r11,%rdx
  119cd4:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119cd8:	4d 89 c5             	mov    %r8,%r13
  119cdb:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119cdf:	4d 89 de             	mov    %r11,%r14
  119ce2:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119ce6:	e8 d5 18 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119ceb:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  119cef:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119cf3:	4d 89 f3             	mov    %r14,%r11
  119cf6:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119cfa:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119cfe:	4d 89 e8             	mov    %r13,%r8
  119d01:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119d05:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119d09:	e9 99 fd ff ff       	jmp    119aa7 <pqcrystals_kyber768_ref_polyvec_compress+0x3cf>
  119d0e:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119d12:	48 8d 3d 17 9e 04 00 	lea    0x49e17(%rip),%rdi        # 163b30 <_ZL17kSuppressionTypes+0x20e0>
  119d19:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119d1d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119d21:	88 53 40             	mov    %dl,0x40(%rbx)
  119d24:	4c 89 f2             	mov    %r14,%rdx
  119d27:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119d2b:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119d2f:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119d33:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119d37:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119d3b:	e8 80 18 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119d40:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  119d44:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119d48:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119d4c:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119d50:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119d54:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119d58:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119d5c:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119d60:	e9 56 fd ff ff       	jmp    119abb <pqcrystals_kyber768_ref_polyvec_compress+0x3e3>
  119d65:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119d69:	48 8d 3d d0 9d 04 00 	lea    0x49dd0(%rip),%rdi        # 163b40 <_ZL17kSuppressionTypes+0x20f0>
  119d70:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119d74:	4c 89 e6             	mov    %r12,%rsi
  119d77:	4c 89 da             	mov    %r11,%rdx
  119d7a:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119d7e:	4d 89 c5             	mov    %r8,%r13
  119d81:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119d85:	4d 89 de             	mov    %r11,%r14
  119d88:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119d8c:	e8 2f 18 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119d91:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119d95:	4d 89 f3             	mov    %r14,%r11
  119d98:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119d9c:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119da0:	4d 89 e8             	mov    %r13,%r8
  119da3:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119da7:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119dab:	e9 35 fd ff ff       	jmp    119ae5 <pqcrystals_kyber768_ref_polyvec_compress+0x40d>
  119db0:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119db4:	48 8d 3d 95 9d 04 00 	lea    0x49d95(%rip),%rdi        # 163b50 <_ZL17kSuppressionTypes+0x2100>
  119dbb:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119dbf:	4c 89 e6             	mov    %r12,%rsi
  119dc2:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  119dc6:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119dca:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119dce:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119dd2:	4d 89 de             	mov    %r11,%r14
  119dd5:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119dd9:	e8 e2 17 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119dde:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119de2:	4d 89 f3             	mov    %r14,%r11
  119de5:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119de9:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119ded:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119df1:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119df5:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119df9:	e9 f7 fc ff ff       	jmp    119af5 <pqcrystals_kyber768_ref_polyvec_compress+0x41d>
  119dfe:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119e02:	48 8d 3d 57 9d 04 00 	lea    0x49d57(%rip),%rdi        # 163b60 <_ZL17kSuppressionTypes+0x2110>
  119e09:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119e0d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119e11:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  119e15:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119e19:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119e1d:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119e21:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119e25:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119e29:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119e2d:	e8 8e 17 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119e32:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119e36:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119e3a:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119e3e:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119e42:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119e46:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119e4a:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119e4e:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119e52:	e9 b2 fc ff ff       	jmp    119b09 <pqcrystals_kyber768_ref_polyvec_compress+0x431>
  119e57:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119e5b:	48 8d 3d 0e 9d 04 00 	lea    0x49d0e(%rip),%rdi        # 163b70 <_ZL17kSuppressionTypes+0x2120>
  119e62:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119e66:	4c 89 e6             	mov    %r12,%rsi
  119e69:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  119e6d:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119e71:	4d 89 c5             	mov    %r8,%r13
  119e74:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119e78:	4d 89 de             	mov    %r11,%r14
  119e7b:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119e7f:	e8 3c 17 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119e84:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119e88:	4d 89 f3             	mov    %r14,%r11
  119e8b:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119e8f:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119e93:	4d 89 e8             	mov    %r13,%r8
  119e96:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119e9a:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119e9e:	e9 94 fc ff ff       	jmp    119b37 <pqcrystals_kyber768_ref_polyvec_compress+0x45f>
  119ea3:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119ea7:	48 8d 3d d2 9c 04 00 	lea    0x49cd2(%rip),%rdi        # 163b80 <_ZL17kSuppressionTypes+0x2130>
  119eae:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119eb2:	4c 89 e6             	mov    %r12,%rsi
  119eb5:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  119eb9:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119ebd:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119ec1:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119ec5:	4d 89 de             	mov    %r11,%r14
  119ec8:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119ecc:	e8 ef 16 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119ed1:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119ed5:	4d 89 f3             	mov    %r14,%r11
  119ed8:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119edc:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119ee0:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119ee4:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119ee8:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119eec:	e9 56 fc ff ff       	jmp    119b47 <pqcrystals_kyber768_ref_polyvec_compress+0x46f>
  119ef1:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119ef5:	48 8d 3d 94 9c 04 00 	lea    0x49c94(%rip),%rdi        # 163b90 <_ZL17kSuppressionTypes+0x2140>
  119efc:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119f00:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119f04:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  119f08:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119f0c:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119f10:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119f14:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119f18:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119f1c:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119f20:	e8 9b 16 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119f25:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119f29:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119f2d:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119f31:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119f35:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119f39:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119f3d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119f41:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119f45:	e9 11 fc ff ff       	jmp    119b5b <pqcrystals_kyber768_ref_polyvec_compress+0x483>
  119f4a:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119f4e:	48 8d 3d 4b 9c 04 00 	lea    0x49c4b(%rip),%rdi        # 163ba0 <_ZL17kSuppressionTypes+0x2150>
  119f55:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119f59:	4c 89 e6             	mov    %r12,%rsi
  119f5c:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  119f60:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119f64:	4d 89 c5             	mov    %r8,%r13
  119f67:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119f6b:	4d 89 de             	mov    %r11,%r14
  119f6e:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119f72:	e8 49 16 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119f77:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119f7b:	4d 89 f3             	mov    %r14,%r11
  119f7e:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119f82:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119f86:	4d 89 e8             	mov    %r13,%r8
  119f89:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119f8d:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119f91:	e9 f3 fb ff ff       	jmp    119b89 <pqcrystals_kyber768_ref_polyvec_compress+0x4b1>
  119f96:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119f9a:	48 8d 3d 0f 9c 04 00 	lea    0x49c0f(%rip),%rdi        # 163bb0 <_ZL17kSuppressionTypes+0x2160>
  119fa1:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119fa5:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119fa9:	4c 89 f2             	mov    %r14,%rdx
  119fac:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119fb0:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119fb4:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119fb8:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119fbc:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119fc0:	e8 fb 15 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119fc5:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119fc9:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119fcd:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119fd1:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119fd5:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119fd9:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119fdd:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119fe1:	e9 b7 fb ff ff       	jmp    119b9d <pqcrystals_kyber768_ref_polyvec_compress+0x4c5>
  119fe6:	48 8d 56 05          	lea    0x5(%rsi),%rdx
  119fea:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119fee:	48 8d 3d cb 9b 04 00 	lea    0x49bcb(%rip),%rdi        # 163bc0 <_ZL17kSuppressionTypes+0x2170>
  119ff5:	49 89 f5             	mov    %rsi,%r13
  119ff8:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119ffc:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11a000:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  11a004:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  11a008:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11a00c:	e8 af 15 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  11a011:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  11a015:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  11a019:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11a01d:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11a021:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  11a025:	4c 89 ee             	mov    %r13,%rsi
  11a028:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11a02c:	e9 9b fb ff ff       	jmp    119bcc <pqcrystals_kyber768_ref_polyvec_compress+0x4f4>
  11a031:	41 c6 81 04 80 ff 7f 	movb   $0xf8,0x7fff8004(%r9)
  11a038:	f8 
  11a039:	48 c7 07 0e 36 e0 45 	movq   $0x45e0360e,(%rdi)
  11a040:	48 85 c0             	test   %rax,%rax
  11a043:	74 1a                	je     11a05f <pqcrystals_kyber768_ref_polyvec_compress+0x987>
  11a045:	48 b9 f5 f5 f5 f5 f5 	movabs $0xf5f5f5f5f5f5f5f5,%rcx
  11a04c:	f5 f5 f5 
  11a04f:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  11a056:	48 8b 40 38          	mov    0x38(%rax),%rax
  11a05a:	c6 00 00             	movb   $0x0,(%rax)
  11a05d:	eb 0b                	jmp    11a06a <pqcrystals_kyber768_ref_polyvec_compress+0x992>
  11a05f:	49 c7 81 00 80 ff 7f 	movq   $0x0,0x7fff8000(%r9)
  11a066:	00 00 00 00 
  11a06a:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  11a06e:	5b                   	pop    %rbx
  11a06f:	41 5c                	pop    %r12
  11a071:	41 5d                	pop    %r13
  11a073:	41 5e                	pop    %r14
  11a075:	41 5f                	pop    %r15
  11a077:	5d                   	pop    %rbp
  11a078:	c3                   	ret
  11a079:	4c 89 f7             	mov    %r14,%rdi
  11a07c:	e8 1f cc fb ff       	call   d6ca0 <__asan_report_load2>
  11a081:	48 89 f7             	mov    %rsi,%rdi
  11a084:	e8 17 cf fb ff       	call   d6fa0 <__asan_report_store1>
  11a089:	4c 89 f7             	mov    %r14,%rdi
  11a08c:	e8 0f cf fb ff       	call   d6fa0 <__asan_report_store1>
  11a091:	48 89 d7             	mov    %rdx,%rdi
  11a094:	e8 07 cf fb ff       	call   d6fa0 <__asan_report_store1>
  11a099:	48 89 d7             	mov    %rdx,%rdi
  11a09c:	e8 ff ce fb ff       	call   d6fa0 <__asan_report_store1>
  11a0a1:	4c 89 f7             	mov    %r14,%rdi
  11a0a4:	e8 f7 ce fb ff       	call   d6fa0 <__asan_report_store1>

Disassembly of section .fini:
