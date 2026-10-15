
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-sanitize/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000116508 <pqcrystals_kyber768_ref_poly_tomsg>:
  116508:	55                   	push   %rbp
  116509:	48 89 e5             	mov    %rsp,%rbp
  11650c:	41 57                	push   %r15
  11650e:	41 56                	push   %r14
  116510:	41 55                	push   %r13
  116512:	41 54                	push   %r12
  116514:	53                   	push   %rbx
  116515:	48 83 ec 38          	sub    $0x38,%rsp
  116519:	48 85 f6             	test   %rsi,%rsi
  11651c:	0f 95 c0             	setne  %al
  11651f:	40 f6 c6 01          	test   $0x1,%sil
  116523:	41 0f 94 c5          	sete   %r13b
  116527:	41 20 c5             	and    %al,%r13b
  11652a:	45 31 c0             	xor    %r8d,%r8d
  11652d:	4c 8d 0d 5c af 04 00 	lea    0x4af5c(%rip),%r9        # 161490 <_ZL17kSuppressionTypes+0x1a40>
  116534:	4c 8d 15 45 af 04 00 	lea    0x4af45(%rip),%r10        # 161480 <_ZL17kSuppressionTypes+0x1a30>
  11653b:	4c 8d 1d 1e af 04 00 	lea    0x4af1e(%rip),%r11        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  116542:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  116546:	49 89 f7             	mov    %rsi,%r15
  116549:	eb 1f                	jmp    11656a <pqcrystals_kyber768_ref_poly_tomsg+0x62>
  11654b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
  116550:	49 ff c0             	inc    %r8
  116553:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  116557:	49 83 c7 10          	add    $0x10,%r15
  11655b:	48 83 45 a0 10       	addq   $0x10,-0x60(%rbp)
  116560:	49 83 f8 20          	cmp    $0x20,%r8
  116564:	0f 84 c0 02 00 00    	je     11682a <pqcrystals_kyber768_ref_poly_tomsg+0x322>
  11656a:	48 85 ff             	test   %rdi,%rdi
  11656d:	0f 95 c0             	setne  %al
  116570:	48 89 fa             	mov    %rdi,%rdx
  116573:	4c 01 c2             	add    %r8,%rdx
  116576:	0f 95 c3             	setne  %bl
  116579:	48 39 fa             	cmp    %rdi,%rdx
  11657c:	0f 93 c1             	setae  %cl
  11657f:	20 c3                	and    %al,%bl
  116581:	20 cb                	and    %cl,%bl
  116583:	88 5d d7             	mov    %bl,-0x29(%rbp)
  116586:	48 89 55 b0          	mov    %rdx,-0x50(%rbp)
  11658a:	4c 89 7d a8          	mov    %r15,-0x58(%rbp)
  11658e:	0f 84 08 02 00 00    	je     11679c <pqcrystals_kyber768_ref_poly_tomsg+0x294>
  116594:	48 85 ff             	test   %rdi,%rdi
  116597:	0f 84 48 02 00 00    	je     1167e5 <pqcrystals_kyber768_ref_poly_tomsg+0x2dd>
  11659d:	49 89 d6             	mov    %rdx,%r14
  1165a0:	49 c1 ee 03          	shr    $0x3,%r14
  1165a4:	41 0f b6 86 00 80 ff 	movzbl 0x7fff8000(%r14),%eax
  1165ab:	7f 
  1165ac:	84 c0                	test   %al,%al
  1165ae:	0f 85 d6 01 00 00    	jne    11678a <pqcrystals_kyber768_ref_poly_tomsg+0x282>
  1165b4:	c6 02 00             	movb   $0x0,(%rdx)
  1165b7:	45 31 e4             	xor    %r12d,%r12d
  1165ba:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  1165be:	66 90                	xchg   %ax,%ax
  1165c0:	45 84 ed             	test   %r13b,%r13b
  1165c3:	0f 84 a7 00 00 00    	je     116670 <pqcrystals_kyber768_ref_poly_tomsg+0x168>
  1165c9:	48 85 f6             	test   %rsi,%rsi
  1165cc:	0f 84 e4 00 00 00    	je     1166b6 <pqcrystals_kyber768_ref_poly_tomsg+0x1ae>
  1165d2:	4d 85 ff             	test   %r15,%r15
  1165d5:	0f 84 db 00 00 00    	je     1166b6 <pqcrystals_kyber768_ref_poly_tomsg+0x1ae>
  1165db:	49 39 f7             	cmp    %rsi,%r15
  1165de:	0f 82 d2 00 00 00    	jb     1166b6 <pqcrystals_kyber768_ref_poly_tomsg+0x1ae>
  1165e4:	45 84 ed             	test   %r13b,%r13b
  1165e7:	0f 84 12 01 00 00    	je     1166ff <pqcrystals_kyber768_ref_poly_tomsg+0x1f7>
  1165ed:	4c 89 f8             	mov    %r15,%rax
  1165f0:	48 c1 e8 03          	shr    $0x3,%rax
  1165f4:	0f b6 80 00 80 ff 7f 	movzbl 0x7fff8000(%rax),%eax
  1165fb:	84 c0                	test   %al,%al
  1165fd:	75 50                	jne    11664f <pqcrystals_kyber768_ref_poly_tomsg+0x147>
  1165ff:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  116603:	42 0f bf 04 60       	movswl (%rax,%r12,2),%eax
  116608:	69 d8 f6 75 02 00    	imul   $0x275f6,%eax,%ebx
  11660e:	81 c3 7b 9a 00 08    	add    $0x8009a7b,%ebx
  116614:	c1 eb 1c             	shr    $0x1c,%ebx
  116617:	83 e3 01             	and    $0x1,%ebx
  11661a:	44 89 e1             	mov    %r12d,%ecx
  11661d:	d3 e3                	shl    %cl,%ebx
  11661f:	84 d2                	test   %dl,%dl
  116621:	0f 84 19 01 00 00    	je     116740 <pqcrystals_kyber768_ref_poly_tomsg+0x238>
  116627:	41 0f b6 86 00 80 ff 	movzbl 0x7fff8000(%r14),%eax
  11662e:	7f 
  11662f:	84 c0                	test   %al,%al
  116631:	75 2d                	jne    116660 <pqcrystals_kyber768_ref_poly_tomsg+0x158>
  116633:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  116637:	08 18                	or     %bl,(%rax)
  116639:	49 ff c4             	inc    %r12
  11663c:	49 83 c7 02          	add    $0x2,%r15
  116640:	49 83 fc 08          	cmp    $0x8,%r12
  116644:	0f 85 76 ff ff ff    	jne    1165c0 <pqcrystals_kyber768_ref_poly_tomsg+0xb8>
  11664a:	e9 01 ff ff ff       	jmp    116550 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
  11664f:	44 89 f9             	mov    %r15d,%ecx
  116652:	80 e1 07             	and    $0x7,%cl
  116655:	fe c1                	inc    %cl
  116657:	38 c1                	cmp    %al,%cl
  116659:	7c a4                	jl     1165ff <pqcrystals_kyber768_ref_poly_tomsg+0xf7>
  11665b:	e9 d9 01 00 00       	jmp    116839 <pqcrystals_kyber768_ref_poly_tomsg+0x331>
  116660:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  116664:	80 e1 07             	and    $0x7,%cl
  116667:	38 c1                	cmp    %al,%cl
  116669:	7c c8                	jl     116633 <pqcrystals_kyber768_ref_poly_tomsg+0x12b>
  11666b:	e9 d1 01 00 00       	jmp    116841 <pqcrystals_kyber768_ref_poly_tomsg+0x339>
  116670:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  116674:	4c 89 df             	mov    %r11,%rdi
  116677:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11667b:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  11667f:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  116683:	e8 e8 08 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  116688:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  11668c:	4c 8d 1d cd ad 04 00 	lea    0x4adcd(%rip),%r11        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  116693:	4c 8d 15 e6 ad 04 00 	lea    0x4ade6(%rip),%r10        # 161480 <_ZL17kSuppressionTypes+0x1a30>
  11669a:	4c 8d 0d ef ad 04 00 	lea    0x4adef(%rip),%r9        # 161490 <_ZL17kSuppressionTypes+0x1a40>
  1166a1:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  1166a5:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  1166a9:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1166ad:	48 85 f6             	test   %rsi,%rsi
  1166b0:	0f 85 1c ff ff ff    	jne    1165d2 <pqcrystals_kyber768_ref_poly_tomsg+0xca>
  1166b6:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  1166ba:	4c 89 d7             	mov    %r10,%rdi
  1166bd:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  1166c1:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1166c5:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  1166c9:	4c 89 fa             	mov    %r15,%rdx
  1166cc:	e8 ef 3e ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1166d1:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  1166d5:	4c 8d 1d 84 ad 04 00 	lea    0x4ad84(%rip),%r11        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  1166dc:	4c 8d 15 9d ad 04 00 	lea    0x4ad9d(%rip),%r10        # 161480 <_ZL17kSuppressionTypes+0x1a30>
  1166e3:	4c 8d 0d a6 ad 04 00 	lea    0x4ada6(%rip),%r9        # 161490 <_ZL17kSuppressionTypes+0x1a40>
  1166ea:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  1166ee:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  1166f2:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1166f6:	45 84 ed             	test   %r13b,%r13b
  1166f9:	0f 85 ee fe ff ff    	jne    1165ed <pqcrystals_kyber768_ref_poly_tomsg+0xe5>
  1166ff:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  116703:	4c 89 cf             	mov    %r9,%rdi
  116706:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11670a:	4c 89 fe             	mov    %r15,%rsi
  11670d:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  116711:	e8 5a 08 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  116716:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  11671a:	4c 8d 1d 3f ad 04 00 	lea    0x4ad3f(%rip),%r11        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  116721:	4c 8d 15 58 ad 04 00 	lea    0x4ad58(%rip),%r10        # 161480 <_ZL17kSuppressionTypes+0x1a30>
  116728:	4c 8d 0d 61 ad 04 00 	lea    0x4ad61(%rip),%r9        # 161490 <_ZL17kSuppressionTypes+0x1a40>
  11672f:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  116733:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  116737:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  11673b:	e9 ad fe ff ff       	jmp    1165ed <pqcrystals_kyber768_ref_poly_tomsg+0xe5>
  116740:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  116744:	48 8d 3d 65 ad 04 00 	lea    0x4ad65(%rip),%rdi        # 1614b0 <_ZL17kSuppressionTypes+0x1a60>
  11674b:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11674f:	48 8b 75 c0          	mov    -0x40(%rbp),%rsi
  116753:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  116757:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  11675b:	e8 60 3e ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  116760:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  116764:	4c 8d 1d f5 ac 04 00 	lea    0x4acf5(%rip),%r11        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  11676b:	4c 8d 15 0e ad 04 00 	lea    0x4ad0e(%rip),%r10        # 161480 <_ZL17kSuppressionTypes+0x1a30>
  116772:	4c 8d 0d 17 ad 04 00 	lea    0x4ad17(%rip),%r9        # 161490 <_ZL17kSuppressionTypes+0x1a40>
  116779:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  11677d:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  116781:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  116785:	e9 9d fe ff ff       	jmp    116627 <pqcrystals_kyber768_ref_poly_tomsg+0x11f>
  11678a:	89 d1                	mov    %edx,%ecx
  11678c:	80 e1 07             	and    $0x7,%cl
  11678f:	38 c1                	cmp    %al,%cl
  116791:	0f 8c 1d fe ff ff    	jl     1165b4 <pqcrystals_kyber768_ref_poly_tomsg+0xac>
  116797:	e9 ae 00 00 00       	jmp    11684a <pqcrystals_kyber768_ref_poly_tomsg+0x342>
  11679c:	49 89 ff             	mov    %rdi,%r15
  11679f:	48 8d 3d 8a ac 04 00 	lea    0x4ac8a(%rip),%rdi        # 161430 <_ZL17kSuppressionTypes+0x19e0>
  1167a6:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  1167aa:	4c 89 fe             	mov    %r15,%rsi
  1167ad:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  1167b1:	4c 89 cb             	mov    %r9,%rbx
  1167b4:	4d 89 de             	mov    %r11,%r14
  1167b7:	e8 04 3e ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1167bc:	4d 89 f3             	mov    %r14,%r11
  1167bf:	4c 8d 15 ba ac 04 00 	lea    0x4acba(%rip),%r10        # 161480 <_ZL17kSuppressionTypes+0x1a30>
  1167c6:	49 89 d9             	mov    %rbx,%r9
  1167c9:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  1167cd:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  1167d1:	4c 89 ff             	mov    %r15,%rdi
  1167d4:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  1167d8:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1167dc:	48 85 ff             	test   %rdi,%rdi
  1167df:	0f 85 b8 fd ff ff    	jne    11659d <pqcrystals_kyber768_ref_poly_tomsg+0x95>
  1167e5:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  1167e9:	48 8d 3d 50 ac 04 00 	lea    0x4ac50(%rip),%rdi        # 161440 <_ZL17kSuppressionTypes+0x19f0>
  1167f0:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  1167f4:	48 89 d6             	mov    %rdx,%rsi
  1167f7:	4d 89 c7             	mov    %r8,%r15
  1167fa:	4c 89 cb             	mov    %r9,%rbx
  1167fd:	4d 89 d6             	mov    %r10,%r14
  116800:	e8 6b 07 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  116805:	4c 8d 1d 54 ac 04 00 	lea    0x4ac54(%rip),%r11        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  11680c:	4d 89 f2             	mov    %r14,%r10
  11680f:	49 89 d9             	mov    %rbx,%r9
  116812:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  116816:	4d 89 f8             	mov    %r15,%r8
  116819:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  11681d:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  116821:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  116825:	e9 73 fd ff ff       	jmp    11659d <pqcrystals_kyber768_ref_poly_tomsg+0x95>
  11682a:	48 83 c4 38          	add    $0x38,%rsp
  11682e:	5b                   	pop    %rbx
  11682f:	41 5c                	pop    %r12
  116831:	41 5d                	pop    %r13
  116833:	41 5e                	pop    %r14
  116835:	41 5f                	pop    %r15
  116837:	5d                   	pop    %rbp
  116838:	c3                   	ret
  116839:	4c 89 ff             	mov    %r15,%rdi
  11683c:	e8 5f f4 fb ff       	call   d5ca0 <__asan_report_load2>
  116841:	48 8b 7d b0          	mov    -0x50(%rbp),%rdi
  116845:	e8 96 f3 fb ff       	call   d5be0 <__asan_report_load1>
  11684a:	48 89 d7             	mov    %rdx,%rdi
  11684d:	e8 4e f7 fb ff       	call   d5fa0 <__asan_report_store1>

Disassembly of section .fini:
