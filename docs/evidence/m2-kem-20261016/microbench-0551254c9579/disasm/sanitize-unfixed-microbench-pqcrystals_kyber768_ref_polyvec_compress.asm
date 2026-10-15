
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-sanitize/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000001196c8 <pqcrystals_kyber768_ref_polyvec_compress>:
  1196c8:	55                   	push   %rbp
  1196c9:	48 89 e5             	mov    %rsp,%rbp
  1196cc:	41 57                	push   %r15
  1196ce:	41 56                	push   %r14
  1196d0:	41 55                	push   %r13
  1196d2:	41 54                	push   %r12
  1196d4:	53                   	push   %rbx
  1196d5:	48 83 e4 e0          	and    $0xffffffffffffffe0,%rsp
  1196d9:	48 81 ec c0 00 00 00 	sub    $0xc0,%rsp
  1196e0:	48 89 e3             	mov    %rsp,%rbx
  1196e3:	49 89 f0             	mov    %rsi,%r8
  1196e6:	49 89 fe             	mov    %rdi,%r14
  1196e9:	48 8d 05 40 ed 05 00 	lea    0x5ed40(%rip),%rax        # 178430 <__asan_option_detect_stack_use_after_return>
  1196f0:	83 38 00             	cmpl   $0x0,(%rax)
  1196f3:	74 12                	je     119707 <pqcrystals_kyber768_ref_polyvec_compress+0x3f>
  1196f5:	bf 40 00 00 00       	mov    $0x40,%edi
  1196fa:	4d 89 c7             	mov    %r8,%r15
  1196fd:	e8 3e 88 f2 ff       	call   41f40 <__asan_stack_malloc_0>
  119702:	4d 89 f8             	mov    %r15,%r8
  119705:	eb 02                	jmp    119709 <pqcrystals_kyber768_ref_polyvec_compress+0x41>
  119707:	31 c0                	xor    %eax,%eax
  119709:	48 89 c7             	mov    %rax,%rdi
  11970c:	48 85 c0             	test   %rax,%rax
  11970f:	75 0e                	jne    11971f <pqcrystals_kyber768_ref_polyvec_compress+0x57>
  119711:	48 89 e7             	mov    %rsp,%rdi
  119714:	48 83 c7 c0          	add    $0xffffffffffffffc0,%rdi
  119718:	48 83 e7 e0          	and    $0xffffffffffffffe0,%rdi
  11971c:	48 89 fc             	mov    %rdi,%rsp
  11971f:	48 89 bb 98 00 00 00 	mov    %rdi,0x98(%rbx)
  119726:	4c 8d 67 20          	lea    0x20(%rdi),%r12
  11972a:	48 c7 07 b3 8a b5 41 	movq   $0x41b58ab3,(%rdi)
  119731:	48 8d 0d ac c7 01 00 	lea    0x1c7ac(%rip),%rcx        # 135ee4 <_ZN11__sanitizerL10kExtraRegsE+0x12d34>
  119738:	48 89 4f 08          	mov    %rcx,0x8(%rdi)
  11973c:	48 8d 0d 85 ff ff ff 	lea    -0x7b(%rip),%rcx        # 1196c8 <pqcrystals_kyber768_ref_polyvec_compress>
  119743:	48 89 4f 10          	mov    %rcx,0x10(%rdi)
  119747:	49 89 f9             	mov    %rdi,%r9
  11974a:	49 c1 e9 03          	shr    $0x3,%r9
  11974e:	48 b9 f1 f1 f1 f1 f8 	movabs $0xf3f3f3f8f1f1f1f1,%rcx
  119755:	f3 f3 f3 
  119758:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  11975f:	41 c6 81 04 80 ff 7f 	movb   $0x0,0x7fff8004(%r9)
  119766:	00 
  119767:	4d 85 c0             	test   %r8,%r8
  11976a:	0f 95 c1             	setne  %cl
  11976d:	41 f6 c0 01          	test   $0x1,%r8b
  119771:	41 0f 94 c7          	sete   %r15b
  119775:	41 20 cf             	and    %cl,%r15b
  119778:	4c 8d 5f 22          	lea    0x22(%rdi),%r11
  11977c:	48 8d 4f 24          	lea    0x24(%rdi),%rcx
  119780:	48 89 4b 68          	mov    %rcx,0x68(%rbx)
  119784:	48 8d 4f 26          	lea    0x26(%rdi),%rcx
  119788:	48 89 4b 60          	mov    %rcx,0x60(%rbx)
  11978c:	31 d2                	xor    %edx,%edx
  11978e:	4d 89 c5             	mov    %r8,%r13
  119791:	4c 89 c1             	mov    %r8,%rcx
  119794:	4c 89 f6             	mov    %r14,%rsi
  119797:	4d 89 c6             	mov    %r8,%r14
  11979a:	eb 31                	jmp    1197cd <pqcrystals_kyber768_ref_polyvec_compress+0x105>
  11979c:	0f 1f 40 00          	nopl   0x0(%rax)
  1197a0:	48 8b 93 88 00 00 00 	mov    0x88(%rbx),%rdx
  1197a7:	48 ff c2             	inc    %rdx
  1197aa:	4c 8b 73 78          	mov    0x78(%rbx),%r14
  1197ae:	49 81 c6 00 02 00 00 	add    $0x200,%r14
  1197b5:	4c 8b ab 80 00 00 00 	mov    0x80(%rbx),%r13
  1197bc:	49 81 c5 00 02 00 00 	add    $0x200,%r13
  1197c3:	48 83 fa 03          	cmp    $0x3,%rdx
  1197c7:	0f 84 54 08 00 00    	je     11a021 <pqcrystals_kyber768_ref_polyvec_compress+0x959>
  1197cd:	4d 85 c0             	test   %r8,%r8
  1197d0:	0f 95 c1             	setne  %cl
  1197d3:	48 89 93 88 00 00 00 	mov    %rdx,0x88(%rbx)
  1197da:	48 c1 e2 09          	shl    $0x9,%rdx
  1197de:	4c 01 c2             	add    %r8,%rdx
  1197e1:	41 0f 95 c2          	setne  %r10b
  1197e5:	48 89 53 58          	mov    %rdx,0x58(%rbx)
  1197e9:	4c 39 c2             	cmp    %r8,%rdx
  1197ec:	0f 93 c2             	setae  %dl
  1197ef:	41 20 ca             	and    %cl,%r10b
  1197f2:	41 20 d2             	and    %dl,%r10b
  1197f5:	44 88 53 57          	mov    %r10b,0x57(%rbx)
  1197f9:	4c 89 ab 80 00 00 00 	mov    %r13,0x80(%rbx)
  119800:	4d 89 ea             	mov    %r13,%r10
  119803:	4c 89 73 78          	mov    %r14,0x78(%rbx)
  119807:	4c 89 73 70          	mov    %r14,0x70(%rbx)
  11980b:	45 31 f6             	xor    %r14d,%r14d
  11980e:	66 90                	xchg   %ax,%ax
  119810:	4c 89 b3 90 00 00 00 	mov    %r14,0x90(%rbx)
  119817:	45 31 ed             	xor    %r13d,%r13d
  11981a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
  119820:	45 84 ff             	test   %r15b,%r15b
  119823:	0f 84 aa 00 00 00    	je     1198d3 <pqcrystals_kyber768_ref_polyvec_compress+0x20b>
  119829:	80 7b 57 00          	cmpb   $0x0,0x57(%rbx)
  11982d:	0f 84 ef 00 00 00    	je     119922 <pqcrystals_kyber768_ref_polyvec_compress+0x25a>
  119833:	45 84 ff             	test   %r15b,%r15b
  119836:	0f 84 38 01 00 00    	je     119974 <pqcrystals_kyber768_ref_polyvec_compress+0x2ac>
  11983c:	48 8b 4b 70          	mov    0x70(%rbx),%rcx
  119840:	4e 8d 34 29          	lea    (%rcx,%r13,1),%r14
  119844:	4d 85 c0             	test   %r8,%r8
  119847:	0f 84 72 01 00 00    	je     1199bf <pqcrystals_kyber768_ref_polyvec_compress+0x2f7>
  11984d:	4d 85 f6             	test   %r14,%r14
  119850:	0f 84 69 01 00 00    	je     1199bf <pqcrystals_kyber768_ref_polyvec_compress+0x2f7>
  119856:	4c 3b 73 58          	cmp    0x58(%rbx),%r14
  11985a:	0f 82 5f 01 00 00    	jb     1199bf <pqcrystals_kyber768_ref_polyvec_compress+0x2f7>
  119860:	45 84 ff             	test   %r15b,%r15b
  119863:	0f 84 aa 01 00 00    	je     119a13 <pqcrystals_kyber768_ref_polyvec_compress+0x34b>
  119869:	4c 89 f1             	mov    %r14,%rcx
  11986c:	48 c1 e9 03          	shr    $0x3,%rcx
  119870:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119877:	84 c9                	test   %cl,%cl
  119879:	75 47                	jne    1198c2 <pqcrystals_kyber768_ref_polyvec_compress+0x1fa>
  11987b:	43 0f bf 0c 2a       	movswl (%r10,%r13,1),%ecx
  119880:	89 ca                	mov    %ecx,%edx
  119882:	c1 ea 0f             	shr    $0xf,%edx
  119885:	81 e2 01 0d 00 00    	and    $0xd01,%edx
  11988b:	01 ca                	add    %ecx,%edx
  11988d:	0f b7 ca             	movzwl %dx,%ecx
  119890:	c1 e1 0a             	shl    $0xa,%ecx
  119893:	81 c1 80 06 00 00    	add    $0x680,%ecx
  119899:	48 69 c9 b5 db d7 09 	imul   $0x9d7dbb5,%rcx,%rcx
  1198a0:	48 c1 e9 27          	shr    $0x27,%rcx
  1198a4:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
  1198aa:	66 43 89 0c 2c       	mov    %cx,(%r12,%r13,1)
  1198af:	49 83 c5 02          	add    $0x2,%r13
  1198b3:	49 83 fd 08          	cmp    $0x8,%r13
  1198b7:	0f 85 63 ff ff ff    	jne    119820 <pqcrystals_kyber768_ref_polyvec_compress+0x158>
  1198bd:	e9 9e 01 00 00       	jmp    119a60 <pqcrystals_kyber768_ref_polyvec_compress+0x398>
  1198c2:	44 89 f2             	mov    %r14d,%edx
  1198c5:	80 e2 07             	and    $0x7,%dl
  1198c8:	fe c2                	inc    %dl
  1198ca:	38 ca                	cmp    %cl,%dl
  1198cc:	7c ad                	jl     11987b <pqcrystals_kyber768_ref_polyvec_compress+0x1b3>
  1198ce:	e9 96 07 00 00       	jmp    11a069 <pqcrystals_kyber768_ref_polyvec_compress+0x9a1>
  1198d3:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1198d7:	48 8d 3d 72 a1 04 00 	lea    0x4a172(%rip),%rdi        # 163a50 <_ZL17kSuppressionTypes+0x2000>
  1198de:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1198e2:	4c 89 c6             	mov    %r8,%rsi
  1198e5:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1198e9:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  1198ed:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1198f1:	4d 89 de             	mov    %r11,%r14
  1198f4:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1198f8:	e8 73 e6 fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  1198fd:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119901:	4d 89 f3             	mov    %r14,%r11
  119904:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119908:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11990c:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119910:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119914:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119918:	80 7b 57 00          	cmpb   $0x0,0x57(%rbx)
  11991c:	0f 85 11 ff ff ff    	jne    119833 <pqcrystals_kyber768_ref_polyvec_compress+0x16b>
  119922:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119926:	48 8d 3d 43 a1 04 00 	lea    0x4a143(%rip),%rdi        # 163a70 <_ZL17kSuppressionTypes+0x2020>
  11992d:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119931:	4c 89 c6             	mov    %r8,%rsi
  119934:	48 8b 53 58          	mov    0x58(%rbx),%rdx
  119938:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11993c:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119940:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119944:	4d 89 de             	mov    %r11,%r14
  119947:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11994b:	e8 70 1c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119950:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119954:	4d 89 f3             	mov    %r14,%r11
  119957:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11995b:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11995f:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119963:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119967:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11996b:	45 84 ff             	test   %r15b,%r15b
  11996e:	0f 85 c8 fe ff ff    	jne    11983c <pqcrystals_kyber768_ref_polyvec_compress+0x174>
  119974:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119978:	48 8d 3d 01 a1 04 00 	lea    0x4a101(%rip),%rdi        # 163a80 <_ZL17kSuppressionTypes+0x2030>
  11997f:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119983:	48 8b 73 58          	mov    0x58(%rbx),%rsi
  119987:	48 89 43 30          	mov    %rax,0x30(%rbx)
  11998b:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  11998f:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119993:	4d 89 de             	mov    %r11,%r14
  119996:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  11999a:	e8 d1 e5 fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  11999f:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1199a3:	4d 89 f3             	mov    %r14,%r11
  1199a6:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1199aa:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1199ae:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  1199b2:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  1199b6:	48 8b 43 30          	mov    0x30(%rbx),%rax
  1199ba:	e9 7d fe ff ff       	jmp    11983c <pqcrystals_kyber768_ref_polyvec_compress+0x174>
  1199bf:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1199c3:	48 8d 3d d6 a0 04 00 	lea    0x4a0d6(%rip),%rdi        # 163aa0 <_ZL17kSuppressionTypes+0x2050>
  1199ca:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  1199ce:	48 8b 73 58          	mov    0x58(%rbx),%rsi
  1199d2:	4c 89 f2             	mov    %r14,%rdx
  1199d5:	48 89 43 30          	mov    %rax,0x30(%rbx)
  1199d9:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  1199dd:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  1199e1:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  1199e5:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  1199e9:	e8 d2 1b ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1199ee:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  1199f2:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  1199f6:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  1199fa:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1199fe:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119a02:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119a06:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119a0a:	45 84 ff             	test   %r15b,%r15b
  119a0d:	0f 85 56 fe ff ff    	jne    119869 <pqcrystals_kyber768_ref_polyvec_compress+0x1a1>
  119a13:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119a17:	48 8d 3d 92 a0 04 00 	lea    0x4a092(%rip),%rdi        # 163ab0 <_ZL17kSuppressionTypes+0x2060>
  119a1e:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119a22:	4c 89 f6             	mov    %r14,%rsi
  119a25:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119a29:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119a2d:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119a31:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119a35:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119a39:	e8 32 e5 fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  119a3e:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119a42:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119a46:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119a4a:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119a4e:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119a52:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119a56:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119a5a:	e9 0a fe ff ff       	jmp    119869 <pqcrystals_kyber768_ref_polyvec_compress+0x1a1>
  119a5f:	90                   	nop
  119a60:	45 0f b6 34 24       	movzbl (%r12),%r14d
  119a65:	48 85 f6             	test   %rsi,%rsi
  119a68:	0f 84 e4 01 00 00    	je     119c52 <pqcrystals_kyber768_ref_polyvec_compress+0x58a>
  119a6e:	48 89 f1             	mov    %rsi,%rcx
  119a71:	48 c1 e9 03          	shr    $0x3,%rcx
  119a75:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119a7c:	84 c9                	test   %cl,%cl
  119a7e:	0f 85 57 01 00 00    	jne    119bdb <pqcrystals_kyber768_ref_polyvec_compress+0x513>
  119a84:	44 88 36             	mov    %r14b,(%rsi)
  119a87:	41 0f b6 54 24 01    	movzbl 0x1(%r12),%edx
  119a8d:	49 83 fc fe          	cmp    $0xfffffffffffffffe,%r12
  119a91:	0f 84 15 02 00 00    	je     119cac <pqcrystals_kyber768_ref_polyvec_compress+0x5e4>
  119a97:	45 0f b6 6c 24 02    	movzbl 0x2(%r12),%r13d
  119a9d:	4c 8d 76 01          	lea    0x1(%rsi),%r14
  119aa1:	48 83 fe ff          	cmp    $0xffffffffffffffff,%rsi
  119aa5:	0f 84 53 02 00 00    	je     119cfe <pqcrystals_kyber768_ref_polyvec_compress+0x636>
  119aab:	4c 89 f1             	mov    %r14,%rcx
  119aae:	48 c1 e9 03          	shr    $0x3,%rcx
  119ab2:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119ab9:	84 c9                	test   %cl,%cl
  119abb:	0f 85 2c 01 00 00    	jne    119bed <pqcrystals_kyber768_ref_polyvec_compress+0x525>
  119ac1:	41 c0 e5 02          	shl    $0x2,%r13b
  119ac5:	41 08 d5             	or     %dl,%r13b
  119ac8:	45 88 2e             	mov    %r13b,(%r14)
  119acb:	49 83 fc fe          	cmp    $0xfffffffffffffffe,%r12
  119acf:	0f 84 80 02 00 00    	je     119d55 <pqcrystals_kyber768_ref_polyvec_compress+0x68d>
  119ad5:	45 0f b7 6c 24 02    	movzwl 0x2(%r12),%r13d
  119adb:	49 83 fc fc          	cmp    $0xfffffffffffffffc,%r12
  119adf:	0f 83 bb 02 00 00    	jae    119da0 <pqcrystals_kyber768_ref_polyvec_compress+0x6d8>
  119ae5:	45 0f b6 74 24 04    	movzbl 0x4(%r12),%r14d
  119aeb:	48 8d 56 02          	lea    0x2(%rsi),%rdx
  119aef:	48 83 fe fe          	cmp    $0xfffffffffffffffe,%rsi
  119af3:	0f 83 f5 02 00 00    	jae    119dee <pqcrystals_kyber768_ref_polyvec_compress+0x726>
  119af9:	48 89 d1             	mov    %rdx,%rcx
  119afc:	48 c1 e9 03          	shr    $0x3,%rcx
  119b00:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119b07:	84 c9                	test   %cl,%cl
  119b09:	0f 85 f8 00 00 00    	jne    119c07 <pqcrystals_kyber768_ref_polyvec_compress+0x53f>
  119b0f:	41 c1 ed 06          	shr    $0x6,%r13d
  119b13:	41 c0 e6 04          	shl    $0x4,%r14b
  119b17:	45 08 ee             	or     %r13b,%r14b
  119b1a:	44 88 32             	mov    %r14b,(%rdx)
  119b1d:	49 83 fc fc          	cmp    $0xfffffffffffffffc,%r12
  119b21:	0f 83 20 03 00 00    	jae    119e47 <pqcrystals_kyber768_ref_polyvec_compress+0x77f>
  119b27:	45 0f b7 6c 24 04    	movzwl 0x4(%r12),%r13d
  119b2d:	49 83 fc fa          	cmp    $0xfffffffffffffffa,%r12
  119b31:	0f 83 5c 03 00 00    	jae    119e93 <pqcrystals_kyber768_ref_polyvec_compress+0x7cb>
  119b37:	45 0f b6 74 24 06    	movzbl 0x6(%r12),%r14d
  119b3d:	48 8d 56 03          	lea    0x3(%rsi),%rdx
  119b41:	48 83 fe fd          	cmp    $0xfffffffffffffffd,%rsi
  119b45:	0f 83 96 03 00 00    	jae    119ee1 <pqcrystals_kyber768_ref_polyvec_compress+0x819>
  119b4b:	48 89 d1             	mov    %rdx,%rcx
  119b4e:	48 c1 e9 03          	shr    $0x3,%rcx
  119b52:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119b59:	84 c9                	test   %cl,%cl
  119b5b:	0f 85 c2 00 00 00    	jne    119c23 <pqcrystals_kyber768_ref_polyvec_compress+0x55b>
  119b61:	41 c1 ed 04          	shr    $0x4,%r13d
  119b65:	41 c0 e6 06          	shl    $0x6,%r14b
  119b69:	45 08 ee             	or     %r13b,%r14b
  119b6c:	44 88 32             	mov    %r14b,(%rdx)
  119b6f:	49 83 fc fa          	cmp    $0xfffffffffffffffa,%r12
  119b73:	0f 83 c1 03 00 00    	jae    119f3a <pqcrystals_kyber768_ref_polyvec_compress+0x872>
  119b79:	45 0f b7 6c 24 06    	movzwl 0x6(%r12),%r13d
  119b7f:	4c 8d 76 04          	lea    0x4(%rsi),%r14
  119b83:	48 83 fe fc          	cmp    $0xfffffffffffffffc,%rsi
  119b87:	0f 83 f9 03 00 00    	jae    119f86 <pqcrystals_kyber768_ref_polyvec_compress+0x8be>
  119b8d:	4c 89 f1             	mov    %r14,%rcx
  119b90:	48 c1 e9 03          	shr    $0x3,%rcx
  119b94:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  119b9b:	84 c9                	test   %cl,%cl
  119b9d:	0f 85 9c 00 00 00    	jne    119c3f <pqcrystals_kyber768_ref_polyvec_compress+0x577>
  119ba3:	41 c1 ed 02          	shr    $0x2,%r13d
  119ba7:	44 88 6e 04          	mov    %r13b,0x4(%rsi)
  119bab:	48 83 fe fb          	cmp    $0xfffffffffffffffb,%rsi
  119baf:	4c 8b b3 90 00 00 00 	mov    0x90(%rbx),%r14
  119bb6:	0f 83 1a 04 00 00    	jae    119fd6 <pqcrystals_kyber768_ref_polyvec_compress+0x90e>
  119bbc:	48 83 c6 05          	add    $0x5,%rsi
  119bc0:	49 ff c6             	inc    %r14
  119bc3:	48 83 43 70 08       	addq   $0x8,0x70(%rbx)
  119bc8:	49 83 c2 08          	add    $0x8,%r10
  119bcc:	49 83 fe 40          	cmp    $0x40,%r14
  119bd0:	0f 85 3a fc ff ff    	jne    119810 <pqcrystals_kyber768_ref_polyvec_compress+0x148>
  119bd6:	e9 c5 fb ff ff       	jmp    1197a0 <pqcrystals_kyber768_ref_polyvec_compress+0xd8>
  119bdb:	89 f2                	mov    %esi,%edx
  119bdd:	80 e2 07             	and    $0x7,%dl
  119be0:	38 ca                	cmp    %cl,%dl
  119be2:	0f 8c 9c fe ff ff    	jl     119a84 <pqcrystals_kyber768_ref_polyvec_compress+0x3bc>
  119be8:	e9 84 04 00 00       	jmp    11a071 <pqcrystals_kyber768_ref_polyvec_compress+0x9a9>
  119bed:	88 53 40             	mov    %dl,0x40(%rbx)
  119bf0:	44 89 f2             	mov    %r14d,%edx
  119bf3:	80 e2 07             	and    $0x7,%dl
  119bf6:	38 ca                	cmp    %cl,%dl
  119bf8:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  119bfc:	0f 8c bf fe ff ff    	jl     119ac1 <pqcrystals_kyber768_ref_polyvec_compress+0x3f9>
  119c02:	e9 72 04 00 00       	jmp    11a079 <pqcrystals_kyber768_ref_polyvec_compress+0x9b1>
  119c07:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  119c0b:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119c0f:	80 e2 07             	and    $0x7,%dl
  119c12:	38 ca                	cmp    %cl,%dl
  119c14:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119c18:	0f 8c f1 fe ff ff    	jl     119b0f <pqcrystals_kyber768_ref_polyvec_compress+0x447>
  119c1e:	e9 5e 04 00 00       	jmp    11a081 <pqcrystals_kyber768_ref_polyvec_compress+0x9b9>
  119c23:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  119c27:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119c2b:	80 e2 07             	and    $0x7,%dl
  119c2e:	38 ca                	cmp    %cl,%dl
  119c30:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119c34:	0f 8c 27 ff ff ff    	jl     119b61 <pqcrystals_kyber768_ref_polyvec_compress+0x499>
  119c3a:	e9 4a 04 00 00       	jmp    11a089 <pqcrystals_kyber768_ref_polyvec_compress+0x9c1>
  119c3f:	44 89 f2             	mov    %r14d,%edx
  119c42:	80 e2 07             	and    $0x7,%dl
  119c45:	38 ca                	cmp    %cl,%dl
  119c47:	0f 8c 56 ff ff ff    	jl     119ba3 <pqcrystals_kyber768_ref_polyvec_compress+0x4db>
  119c4d:	e9 3f 04 00 00       	jmp    11a091 <pqcrystals_kyber768_ref_polyvec_compress+0x9c9>
  119c52:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119c56:	48 8d 3d 73 9e 04 00 	lea    0x49e73(%rip),%rdi        # 163ad0 <_ZL17kSuppressionTypes+0x2080>
  119c5d:	49 89 f5             	mov    %rsi,%r13
  119c60:	31 f6                	xor    %esi,%esi
  119c62:	31 d2                	xor    %edx,%edx
  119c64:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119c68:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119c6c:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119c70:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119c74:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119c78:	e8 43 19 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119c7d:	48 8d 3d 5c 9e 04 00 	lea    0x49e5c(%rip),%rdi        # 163ae0 <_ZL17kSuppressionTypes+0x2090>
  119c84:	4c 89 ee             	mov    %r13,%rsi
  119c87:	e8 e4 e2 fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  119c8c:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119c90:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119c94:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119c98:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119c9c:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119ca0:	4c 89 ee             	mov    %r13,%rsi
  119ca3:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119ca7:	e9 c2 fd ff ff       	jmp    119a6e <pqcrystals_kyber768_ref_polyvec_compress+0x3a6>
  119cac:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119cb0:	48 8d 3d 49 9e 04 00 	lea    0x49e49(%rip),%rdi        # 163b00 <_ZL17kSuppressionTypes+0x20b0>
  119cb7:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119cbb:	4c 89 e6             	mov    %r12,%rsi
  119cbe:	88 53 40             	mov    %dl,0x40(%rbx)
  119cc1:	4c 89 da             	mov    %r11,%rdx
  119cc4:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119cc8:	4d 89 c5             	mov    %r8,%r13
  119ccb:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119ccf:	4d 89 de             	mov    %r11,%r14
  119cd2:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119cd6:	e8 e5 18 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119cdb:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  119cdf:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119ce3:	4d 89 f3             	mov    %r14,%r11
  119ce6:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119cea:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119cee:	4d 89 e8             	mov    %r13,%r8
  119cf1:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119cf5:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119cf9:	e9 99 fd ff ff       	jmp    119a97 <pqcrystals_kyber768_ref_polyvec_compress+0x3cf>
  119cfe:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119d02:	48 8d 3d 07 9e 04 00 	lea    0x49e07(%rip),%rdi        # 163b10 <_ZL17kSuppressionTypes+0x20c0>
  119d09:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119d0d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119d11:	88 53 40             	mov    %dl,0x40(%rbx)
  119d14:	4c 89 f2             	mov    %r14,%rdx
  119d17:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119d1b:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119d1f:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119d23:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119d27:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119d2b:	e8 90 18 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119d30:	0f b6 53 40          	movzbl 0x40(%rbx),%edx
  119d34:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119d38:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119d3c:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119d40:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119d44:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119d48:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119d4c:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119d50:	e9 56 fd ff ff       	jmp    119aab <pqcrystals_kyber768_ref_polyvec_compress+0x3e3>
  119d55:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119d59:	48 8d 3d c0 9d 04 00 	lea    0x49dc0(%rip),%rdi        # 163b20 <_ZL17kSuppressionTypes+0x20d0>
  119d60:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119d64:	4c 89 e6             	mov    %r12,%rsi
  119d67:	4c 89 da             	mov    %r11,%rdx
  119d6a:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119d6e:	4d 89 c5             	mov    %r8,%r13
  119d71:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119d75:	4d 89 de             	mov    %r11,%r14
  119d78:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119d7c:	e8 3f 18 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119d81:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119d85:	4d 89 f3             	mov    %r14,%r11
  119d88:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119d8c:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119d90:	4d 89 e8             	mov    %r13,%r8
  119d93:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119d97:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119d9b:	e9 35 fd ff ff       	jmp    119ad5 <pqcrystals_kyber768_ref_polyvec_compress+0x40d>
  119da0:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119da4:	48 8d 3d 85 9d 04 00 	lea    0x49d85(%rip),%rdi        # 163b30 <_ZL17kSuppressionTypes+0x20e0>
  119dab:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119daf:	4c 89 e6             	mov    %r12,%rsi
  119db2:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  119db6:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119dba:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119dbe:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119dc2:	4d 89 de             	mov    %r11,%r14
  119dc5:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119dc9:	e8 f2 17 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119dce:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119dd2:	4d 89 f3             	mov    %r14,%r11
  119dd5:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119dd9:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119ddd:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119de1:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119de5:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119de9:	e9 f7 fc ff ff       	jmp    119ae5 <pqcrystals_kyber768_ref_polyvec_compress+0x41d>
  119dee:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119df2:	48 8d 3d 47 9d 04 00 	lea    0x49d47(%rip),%rdi        # 163b40 <_ZL17kSuppressionTypes+0x20f0>
  119df9:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119dfd:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119e01:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  119e05:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119e09:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119e0d:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119e11:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119e15:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119e19:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119e1d:	e8 9e 17 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119e22:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119e26:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119e2a:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119e2e:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119e32:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119e36:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119e3a:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119e3e:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119e42:	e9 b2 fc ff ff       	jmp    119af9 <pqcrystals_kyber768_ref_polyvec_compress+0x431>
  119e47:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119e4b:	48 8d 3d fe 9c 04 00 	lea    0x49cfe(%rip),%rdi        # 163b50 <_ZL17kSuppressionTypes+0x2100>
  119e52:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119e56:	4c 89 e6             	mov    %r12,%rsi
  119e59:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  119e5d:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119e61:	4d 89 c5             	mov    %r8,%r13
  119e64:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119e68:	4d 89 de             	mov    %r11,%r14
  119e6b:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119e6f:	e8 4c 17 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119e74:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119e78:	4d 89 f3             	mov    %r14,%r11
  119e7b:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119e7f:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119e83:	4d 89 e8             	mov    %r13,%r8
  119e86:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119e8a:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119e8e:	e9 94 fc ff ff       	jmp    119b27 <pqcrystals_kyber768_ref_polyvec_compress+0x45f>
  119e93:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119e97:	48 8d 3d c2 9c 04 00 	lea    0x49cc2(%rip),%rdi        # 163b60 <_ZL17kSuppressionTypes+0x2110>
  119e9e:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119ea2:	4c 89 e6             	mov    %r12,%rsi
  119ea5:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  119ea9:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119ead:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119eb1:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119eb5:	4d 89 de             	mov    %r11,%r14
  119eb8:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119ebc:	e8 ff 16 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119ec1:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119ec5:	4d 89 f3             	mov    %r14,%r11
  119ec8:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119ecc:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119ed0:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119ed4:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119ed8:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119edc:	e9 56 fc ff ff       	jmp    119b37 <pqcrystals_kyber768_ref_polyvec_compress+0x46f>
  119ee1:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119ee5:	48 8d 3d 84 9c 04 00 	lea    0x49c84(%rip),%rdi        # 163b70 <_ZL17kSuppressionTypes+0x2120>
  119eec:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119ef0:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119ef4:	48 89 53 40          	mov    %rdx,0x40(%rbx)
  119ef8:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119efc:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119f00:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119f04:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119f08:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119f0c:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119f10:	e8 ab 16 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119f15:	48 8b 53 40          	mov    0x40(%rbx),%rdx
  119f19:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119f1d:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119f21:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119f25:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119f29:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119f2d:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119f31:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119f35:	e9 11 fc ff ff       	jmp    119b4b <pqcrystals_kyber768_ref_polyvec_compress+0x483>
  119f3a:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119f3e:	48 8d 3d 3b 9c 04 00 	lea    0x49c3b(%rip),%rdi        # 163b80 <_ZL17kSuppressionTypes+0x2130>
  119f45:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119f49:	4c 89 e6             	mov    %r12,%rsi
  119f4c:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  119f50:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119f54:	4d 89 c5             	mov    %r8,%r13
  119f57:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119f5b:	4d 89 de             	mov    %r11,%r14
  119f5e:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119f62:	e8 59 16 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119f67:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119f6b:	4d 89 f3             	mov    %r14,%r11
  119f6e:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119f72:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119f76:	4d 89 e8             	mov    %r13,%r8
  119f79:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119f7d:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119f81:	e9 f3 fb ff ff       	jmp    119b79 <pqcrystals_kyber768_ref_polyvec_compress+0x4b1>
  119f86:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119f8a:	48 8d 3d ff 9b 04 00 	lea    0x49bff(%rip),%rdi        # 163b90 <_ZL17kSuppressionTypes+0x2140>
  119f91:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  119f95:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119f99:	4c 89 f2             	mov    %r14,%rdx
  119f9c:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119fa0:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119fa4:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119fa8:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119fac:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119fb0:	e8 0b 16 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  119fb5:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  119fb9:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  119fbd:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  119fc1:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  119fc5:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  119fc9:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  119fcd:	48 8b 43 30          	mov    0x30(%rbx),%rax
  119fd1:	e9 b7 fb ff ff       	jmp    119b8d <pqcrystals_kyber768_ref_polyvec_compress+0x4c5>
  119fd6:	48 8d 56 05          	lea    0x5(%rsi),%rdx
  119fda:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  119fde:	48 8d 3d bb 9b 04 00 	lea    0x49bbb(%rip),%rdi        # 163ba0 <_ZL17kSuppressionTypes+0x2150>
  119fe5:	49 89 f5             	mov    %rsi,%r13
  119fe8:	48 89 43 30          	mov    %rax,0x30(%rbx)
  119fec:	4c 89 43 38          	mov    %r8,0x38(%rbx)
  119ff0:	4c 89 4b 18          	mov    %r9,0x18(%rbx)
  119ff4:	4c 89 5b 48          	mov    %r11,0x48(%rbx)
  119ff8:	4c 89 53 10          	mov    %r10,0x10(%rbx)
  119ffc:	e8 bf 15 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  11a001:	4c 8b 53 10          	mov    0x10(%rbx),%r10
  11a005:	4c 8b 5b 48          	mov    0x48(%rbx),%r11
  11a009:	4c 8b 4b 18          	mov    0x18(%rbx),%r9
  11a00d:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11a011:	4c 8b 43 38          	mov    0x38(%rbx),%r8
  11a015:	4c 89 ee             	mov    %r13,%rsi
  11a018:	48 8b 43 30          	mov    0x30(%rbx),%rax
  11a01c:	e9 9b fb ff ff       	jmp    119bbc <pqcrystals_kyber768_ref_polyvec_compress+0x4f4>
  11a021:	41 c6 81 04 80 ff 7f 	movb   $0xf8,0x7fff8004(%r9)
  11a028:	f8 
  11a029:	48 c7 07 0e 36 e0 45 	movq   $0x45e0360e,(%rdi)
  11a030:	48 85 c0             	test   %rax,%rax
  11a033:	74 1a                	je     11a04f <pqcrystals_kyber768_ref_polyvec_compress+0x987>
  11a035:	48 b9 f5 f5 f5 f5 f5 	movabs $0xf5f5f5f5f5f5f5f5,%rcx
  11a03c:	f5 f5 f5 
  11a03f:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  11a046:	48 8b 40 38          	mov    0x38(%rax),%rax
  11a04a:	c6 00 00             	movb   $0x0,(%rax)
  11a04d:	eb 0b                	jmp    11a05a <pqcrystals_kyber768_ref_polyvec_compress+0x992>
  11a04f:	49 c7 81 00 80 ff 7f 	movq   $0x0,0x7fff8000(%r9)
  11a056:	00 00 00 00 
  11a05a:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  11a05e:	5b                   	pop    %rbx
  11a05f:	41 5c                	pop    %r12
  11a061:	41 5d                	pop    %r13
  11a063:	41 5e                	pop    %r14
  11a065:	41 5f                	pop    %r15
  11a067:	5d                   	pop    %rbp
  11a068:	c3                   	ret
  11a069:	4c 89 f7             	mov    %r14,%rdi
  11a06c:	e8 2f cc fb ff       	call   d6ca0 <__asan_report_load2>
  11a071:	48 89 f7             	mov    %rsi,%rdi
  11a074:	e8 27 cf fb ff       	call   d6fa0 <__asan_report_store1>
  11a079:	4c 89 f7             	mov    %r14,%rdi
  11a07c:	e8 1f cf fb ff       	call   d6fa0 <__asan_report_store1>
  11a081:	48 89 d7             	mov    %rdx,%rdi
  11a084:	e8 17 cf fb ff       	call   d6fa0 <__asan_report_store1>
  11a089:	48 89 d7             	mov    %rdx,%rdi
  11a08c:	e8 0f cf fb ff       	call   d6fa0 <__asan_report_store1>
  11a091:	4c 89 f7             	mov    %r14,%rdi
  11a094:	e8 07 cf fb ff       	call   d6fa0 <__asan_report_store1>

Disassembly of section .fini:
