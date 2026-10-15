
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-sanitize/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000001162a8 <pqcrystals_kyber768_ref_poly_compress>:
  1162a8:	55                   	push   %rbp
  1162a9:	48 89 e5             	mov    %rsp,%rbp
  1162ac:	41 57                	push   %r15
  1162ae:	41 56                	push   %r14
  1162b0:	41 55                	push   %r13
  1162b2:	41 54                	push   %r12
  1162b4:	53                   	push   %rbx
  1162b5:	48 83 e4 e0          	and    $0xffffffffffffffe0,%rsp
  1162b9:	48 81 ec c0 00 00 00 	sub    $0xc0,%rsp
  1162c0:	48 89 e3             	mov    %rsp,%rbx
  1162c3:	49 89 f7             	mov    %rsi,%r15
  1162c6:	49 89 fc             	mov    %rdi,%r12
  1162c9:	48 8d 05 60 21 06 00 	lea    0x62160(%rip),%rax        # 178430 <__asan_option_detect_stack_use_after_return>
  1162d0:	83 38 00             	cmpl   $0x0,(%rax)
  1162d3:	74 0c                	je     1162e1 <pqcrystals_kyber768_ref_poly_compress+0x39>
  1162d5:	bf 40 00 00 00       	mov    $0x40,%edi
  1162da:	e8 61 bc f2 ff       	call   41f40 <__asan_stack_malloc_0>
  1162df:	eb 02                	jmp    1162e3 <pqcrystals_kyber768_ref_poly_compress+0x3b>
  1162e1:	31 c0                	xor    %eax,%eax
  1162e3:	48 89 c7             	mov    %rax,%rdi
  1162e6:	48 85 c0             	test   %rax,%rax
  1162e9:	75 0e                	jne    1162f9 <pqcrystals_kyber768_ref_poly_compress+0x51>
  1162eb:	48 89 e7             	mov    %rsp,%rdi
  1162ee:	48 83 c7 c0          	add    $0xffffffffffffffc0,%rdi
  1162f2:	48 83 e7 e0          	and    $0xffffffffffffffe0,%rdi
  1162f6:	48 89 fc             	mov    %rdi,%rsp
  1162f9:	48 89 bb 98 00 00 00 	mov    %rdi,0x98(%rbx)
  116300:	4c 8d 4f 20          	lea    0x20(%rdi),%r9
  116304:	48 c7 07 b3 8a b5 41 	movq   $0x41b58ab3,(%rdi)
  11630b:	48 8d 0d 29 fb 01 00 	lea    0x1fb29(%rip),%rcx        # 135e3b <_ZN11__sanitizerL10kExtraRegsE+0x12c8b>
  116312:	48 89 4f 08          	mov    %rcx,0x8(%rdi)
  116316:	48 8d 0d 8b ff ff ff 	lea    -0x75(%rip),%rcx        # 1162a8 <pqcrystals_kyber768_ref_poly_compress>
  11631d:	48 89 4f 10          	mov    %rcx,0x10(%rdi)
  116321:	49 89 f8             	mov    %rdi,%r8
  116324:	49 c1 e8 03          	shr    $0x3,%r8
  116328:	48 b9 f1 f1 f1 f1 f8 	movabs $0xf3f3f3f8f1f1f1f1,%rcx
  11632f:	f3 f3 f3 
  116332:	49 89 88 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r8)
  116339:	41 c6 80 04 80 ff 7f 	movb   $0x0,0x7fff8004(%r8)
  116340:	00 
  116341:	4d 85 ff             	test   %r15,%r15
  116344:	0f 95 c1             	setne  %cl
  116347:	41 f6 c7 01          	test   $0x1,%r15b
  11634b:	41 0f 94 c6          	sete   %r14b
  11634f:	41 20 ce             	and    %cl,%r14b
  116352:	4c 8d 57 21          	lea    0x21(%rdi),%r10
  116356:	4c 8d 5f 22          	lea    0x22(%rdi),%r11
  11635a:	48 8d 4f 23          	lea    0x23(%rdi),%rcx
  11635e:	48 89 8b 80 00 00 00 	mov    %rcx,0x80(%rbx)
  116365:	48 8d 4f 24          	lea    0x24(%rdi),%rcx
  116369:	48 89 4b 78          	mov    %rcx,0x78(%rbx)
  11636d:	48 8d 4f 25          	lea    0x25(%rdi),%rcx
  116371:	48 89 4b 70          	mov    %rcx,0x70(%rbx)
  116375:	48 8d 4f 26          	lea    0x26(%rdi),%rcx
  116379:	48 89 4b 68          	mov    %rcx,0x68(%rbx)
  11637d:	48 8d 4f 27          	lea    0x27(%rdi),%rcx
  116381:	48 89 4b 60          	mov    %rcx,0x60(%rbx)
  116385:	31 c9                	xor    %ecx,%ecx
  116387:	4c 89 7b 58          	mov    %r15,0x58(%rbx)
  11638b:	4d 89 fd             	mov    %r15,%r13
  11638e:	4c 89 e6             	mov    %r12,%rsi
  116391:	66 66 66 66 66 66 2e 	data16 data16 data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
  116398:	0f 1f 84 00 00 00 00 
  11639f:	00 
  1163a0:	48 89 8b 90 00 00 00 	mov    %rcx,0x90(%rbx)
  1163a7:	4c 89 ab 88 00 00 00 	mov    %r13,0x88(%rbx)
  1163ae:	45 31 e4             	xor    %r12d,%r12d
  1163b1:	66 66 66 66 66 66 2e 	data16 data16 data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
  1163b8:	0f 1f 84 00 00 00 00 
  1163bf:	00 
  1163c0:	45 84 f6             	test   %r14b,%r14b
  1163c3:	0f 84 8d 00 00 00    	je     116456 <pqcrystals_kyber768_ref_poly_compress+0x1ae>
  1163c9:	4d 85 ff             	test   %r15,%r15
  1163cc:	0f 84 d4 00 00 00    	je     1164a6 <pqcrystals_kyber768_ref_poly_compress+0x1fe>
  1163d2:	4d 85 ed             	test   %r13,%r13
  1163d5:	0f 84 cb 00 00 00    	je     1164a6 <pqcrystals_kyber768_ref_poly_compress+0x1fe>
  1163db:	4d 39 fd             	cmp    %r15,%r13
  1163de:	0f 82 c2 00 00 00    	jb     1164a6 <pqcrystals_kyber768_ref_poly_compress+0x1fe>
  1163e4:	45 84 f6             	test   %r14b,%r14b
  1163e7:	0f 84 0c 01 00 00    	je     1164f9 <pqcrystals_kyber768_ref_poly_compress+0x251>
  1163ed:	4c 89 e9             	mov    %r13,%rcx
  1163f0:	48 c1 e9 03          	shr    $0x3,%rcx
  1163f4:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1163fb:	84 c9                	test   %cl,%cl
  1163fd:	75 46                	jne    116445 <pqcrystals_kyber768_ref_poly_compress+0x19d>
  1163ff:	48 8b 4b 58          	mov    0x58(%rbx),%rcx
  116403:	42 0f bf 0c 61       	movswl (%rcx,%r12,2),%ecx
  116408:	89 ca                	mov    %ecx,%edx
  11640a:	c1 ea 0f             	shr    $0xf,%edx
  11640d:	81 e2 01 0d 00 00    	and    $0xd01,%edx
  116413:	01 ca                	add    %ecx,%edx
  116415:	0f b7 ca             	movzwl %dx,%ecx
  116418:	c1 e1 04             	shl    $0x4,%ecx
  11641b:	81 c1 80 06 00 00    	add    $0x680,%ecx
  116421:	48 69 c9 b8 af 13 00 	imul   $0x13afb8,%rcx,%rcx
  116428:	48 c1 e9 20          	shr    $0x20,%rcx
  11642c:	80 e1 0f             	and    $0xf,%cl
  11642f:	43 88 0c 21          	mov    %cl,(%r9,%r12,1)
  116433:	49 ff c4             	inc    %r12
  116436:	49 83 c5 02          	add    $0x2,%r13
  11643a:	49 83 fc 08          	cmp    $0x8,%r12
  11643e:	75 80                	jne    1163c0 <pqcrystals_kyber768_ref_poly_compress+0x118>
  116440:	e9 0b 01 00 00       	jmp    116550 <pqcrystals_kyber768_ref_poly_compress+0x2a8>
  116445:	44 89 ea             	mov    %r13d,%edx
  116448:	80 e2 07             	and    $0x7,%dl
  11644b:	fe c2                	inc    %dl
  11644d:	38 ca                	cmp    %cl,%dl
  11644f:	7c ae                	jl     1163ff <pqcrystals_kyber768_ref_poly_compress+0x157>
  116451:	e9 d8 06 00 00       	jmp    116b2e <pqcrystals_kyber768_ref_poly_compress+0x886>
  116456:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  11645a:	48 8d 3d 3f cc 04 00 	lea    0x4cc3f(%rip),%rdi        # 1630a0 <_ZL17kSuppressionTypes+0x1650>
  116461:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  116465:	4c 89 fe             	mov    %r15,%rsi
  116468:	48 89 43 40          	mov    %rax,0x40(%rbx)
  11646c:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  116470:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  116474:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  116478:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  11647c:	e8 ef 1a ff ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  116481:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  116485:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  116489:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  11648d:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  116491:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  116495:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  116499:	48 8b 43 40          	mov    0x40(%rbx),%rax
  11649d:	4d 85 ff             	test   %r15,%r15
  1164a0:	0f 85 2c ff ff ff    	jne    1163d2 <pqcrystals_kyber768_ref_poly_compress+0x12a>
  1164a6:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  1164aa:	48 8d 3d 0f cc 04 00 	lea    0x4cc0f(%rip),%rdi        # 1630c0 <_ZL17kSuppressionTypes+0x1670>
  1164b1:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  1164b5:	4c 89 fe             	mov    %r15,%rsi
  1164b8:	4c 89 ea             	mov    %r13,%rdx
  1164bb:	48 89 43 40          	mov    %rax,0x40(%rbx)
  1164bf:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  1164c3:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  1164c7:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  1164cb:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  1164cf:	e8 ec 50 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1164d4:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  1164d8:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  1164dc:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  1164e0:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  1164e4:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  1164e8:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  1164ec:	48 8b 43 40          	mov    0x40(%rbx),%rax
  1164f0:	45 84 f6             	test   %r14b,%r14b
  1164f3:	0f 85 f4 fe ff ff    	jne    1163ed <pqcrystals_kyber768_ref_poly_compress+0x145>
  1164f9:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  1164fd:	48 8d 3d cc cb 04 00 	lea    0x4cbcc(%rip),%rdi        # 1630d0 <_ZL17kSuppressionTypes+0x1680>
  116504:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  116508:	4c 89 ee             	mov    %r13,%rsi
  11650b:	48 89 43 40          	mov    %rax,0x40(%rbx)
  11650f:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  116513:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  116517:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  11651b:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  11651f:	e8 4c 1a ff ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  116524:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  116528:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  11652c:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  116530:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  116534:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  116538:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  11653c:	48 8b 43 40          	mov    0x40(%rbx),%rax
  116540:	e9 a8 fe ff ff       	jmp    1163ed <pqcrystals_kyber768_ref_poly_compress+0x145>
  116545:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
  11654c:	00 00 00 00 
  116550:	45 0f b6 21          	movzbl (%r9),%r12d
  116554:	49 83 f9 ff          	cmp    $0xffffffffffffffff,%r9
  116558:	0f 84 af 01 00 00    	je     11670d <pqcrystals_kyber768_ref_poly_compress+0x465>
  11655e:	45 0f b6 69 01       	movzbl 0x1(%r9),%r13d
  116563:	48 85 f6             	test   %rsi,%rsi
  116566:	0f 84 ee 01 00 00    	je     11675a <pqcrystals_kyber768_ref_poly_compress+0x4b2>
  11656c:	48 89 f1             	mov    %rsi,%rcx
  11656f:	48 c1 e9 03          	shr    $0x3,%rcx
  116573:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  11657a:	84 c9                	test   %cl,%cl
  11657c:	0f 85 2b 01 00 00    	jne    1166ad <pqcrystals_kyber768_ref_poly_compress+0x405>
  116582:	41 c0 e5 04          	shl    $0x4,%r13b
  116586:	45 08 e5             	or     %r12b,%r13b
  116589:	44 88 2e             	mov    %r13b,(%rsi)
  11658c:	49 83 f9 fe          	cmp    $0xfffffffffffffffe,%r9
  116590:	0f 83 21 02 00 00    	jae    1167b7 <pqcrystals_kyber768_ref_poly_compress+0x50f>
  116596:	41 0f b6 51 02       	movzbl 0x2(%r9),%edx
  11659b:	49 83 f9 fd          	cmp    $0xfffffffffffffffd,%r9
  11659f:	0f 83 5d 02 00 00    	jae    116802 <pqcrystals_kyber768_ref_poly_compress+0x55a>
  1165a5:	45 0f b6 61 03       	movzbl 0x3(%r9),%r12d
  1165aa:	4c 8d 6e 01          	lea    0x1(%rsi),%r13
  1165ae:	48 83 fe ff          	cmp    $0xffffffffffffffff,%rsi
  1165b2:	0f 84 a0 02 00 00    	je     116858 <pqcrystals_kyber768_ref_poly_compress+0x5b0>
  1165b8:	4c 89 e9             	mov    %r13,%rcx
  1165bb:	48 c1 e9 03          	shr    $0x3,%rcx
  1165bf:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1165c6:	84 c9                	test   %cl,%cl
  1165c8:	0f 85 f1 00 00 00    	jne    1166bf <pqcrystals_kyber768_ref_poly_compress+0x417>
  1165ce:	41 c0 e4 04          	shl    $0x4,%r12b
  1165d2:	41 08 d4             	or     %dl,%r12b
  1165d5:	45 88 65 00          	mov    %r12b,0x0(%r13)
  1165d9:	49 83 f9 fc          	cmp    $0xfffffffffffffffc,%r9
  1165dd:	0f 83 cc 02 00 00    	jae    1168af <pqcrystals_kyber768_ref_poly_compress+0x607>
  1165e3:	41 0f b6 51 04       	movzbl 0x4(%r9),%edx
  1165e8:	49 83 f9 fb          	cmp    $0xfffffffffffffffb,%r9
  1165ec:	0f 83 09 03 00 00    	jae    1168fb <pqcrystals_kyber768_ref_poly_compress+0x653>
  1165f2:	45 0f b6 61 05       	movzbl 0x5(%r9),%r12d
  1165f7:	4c 8d 6e 02          	lea    0x2(%rsi),%r13
  1165fb:	48 83 fe fe          	cmp    $0xfffffffffffffffe,%rsi
  1165ff:	0f 83 49 03 00 00    	jae    11694e <pqcrystals_kyber768_ref_poly_compress+0x6a6>
  116605:	4c 89 e9             	mov    %r13,%rcx
  116608:	48 c1 e9 03          	shr    $0x3,%rcx
  11660c:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  116613:	84 c9                	test   %cl,%cl
  116615:	0f 85 be 00 00 00    	jne    1166d9 <pqcrystals_kyber768_ref_poly_compress+0x431>
  11661b:	41 c0 e4 04          	shl    $0x4,%r12b
  11661f:	41 08 d4             	or     %dl,%r12b
  116622:	45 88 65 00          	mov    %r12b,0x0(%r13)
  116626:	49 83 f9 fa          	cmp    $0xfffffffffffffffa,%r9
  11662a:	0f 83 75 03 00 00    	jae    1169a5 <pqcrystals_kyber768_ref_poly_compress+0x6fd>
  116630:	41 0f b6 51 06       	movzbl 0x6(%r9),%edx
  116635:	49 83 f9 f9          	cmp    $0xfffffffffffffff9,%r9
  116639:	0f 83 b2 03 00 00    	jae    1169f1 <pqcrystals_kyber768_ref_poly_compress+0x749>
  11663f:	45 0f b6 61 07       	movzbl 0x7(%r9),%r12d
  116644:	4c 8d 6e 03          	lea    0x3(%rsi),%r13
  116648:	48 83 fe fd          	cmp    $0xfffffffffffffffd,%rsi
  11664c:	0f 83 f2 03 00 00    	jae    116a44 <pqcrystals_kyber768_ref_poly_compress+0x79c>
  116652:	4c 89 e9             	mov    %r13,%rcx
  116655:	48 c1 e9 03          	shr    $0x3,%rcx
  116659:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  116660:	84 c9                	test   %cl,%cl
  116662:	0f 85 8b 00 00 00    	jne    1166f3 <pqcrystals_kyber768_ref_poly_compress+0x44b>
  116668:	41 c0 e4 04          	shl    $0x4,%r12b
  11666c:	41 08 d4             	or     %dl,%r12b
  11666f:	44 88 66 03          	mov    %r12b,0x3(%rsi)
  116673:	48 83 fe fc          	cmp    $0xfffffffffffffffc,%rsi
  116677:	4c 8b a3 90 00 00 00 	mov    0x90(%rbx),%r12
  11667e:	0f 83 17 04 00 00    	jae    116a9b <pqcrystals_kyber768_ref_poly_compress+0x7f3>
  116684:	48 83 c6 04          	add    $0x4,%rsi
  116688:	49 ff c4             	inc    %r12
  11668b:	4c 8b ab 88 00 00 00 	mov    0x88(%rbx),%r13
  116692:	49 83 c5 10          	add    $0x10,%r13
  116696:	48 83 43 58 10       	addq   $0x10,0x58(%rbx)
  11669b:	49 83 fc 20          	cmp    $0x20,%r12
  11669f:	4c 89 e1             	mov    %r12,%rcx
  1166a2:	0f 85 f8 fc ff ff    	jne    1163a0 <pqcrystals_kyber768_ref_poly_compress+0xf8>
  1166a8:	e9 39 04 00 00       	jmp    116ae6 <pqcrystals_kyber768_ref_poly_compress+0x83e>
  1166ad:	89 f2                	mov    %esi,%edx
  1166af:	80 e2 07             	and    $0x7,%dl
  1166b2:	38 ca                	cmp    %cl,%dl
  1166b4:	0f 8c c8 fe ff ff    	jl     116582 <pqcrystals_kyber768_ref_poly_compress+0x2da>
  1166ba:	e9 77 04 00 00       	jmp    116b36 <pqcrystals_kyber768_ref_poly_compress+0x88e>
  1166bf:	88 53 1f             	mov    %dl,0x1f(%rbx)
  1166c2:	44 89 ea             	mov    %r13d,%edx
  1166c5:	80 e2 07             	and    $0x7,%dl
  1166c8:	38 ca                	cmp    %cl,%dl
  1166ca:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  1166ce:	0f 8c fa fe ff ff    	jl     1165ce <pqcrystals_kyber768_ref_poly_compress+0x326>
  1166d4:	e9 65 04 00 00       	jmp    116b3e <pqcrystals_kyber768_ref_poly_compress+0x896>
  1166d9:	88 53 1f             	mov    %dl,0x1f(%rbx)
  1166dc:	44 89 ea             	mov    %r13d,%edx
  1166df:	80 e2 07             	and    $0x7,%dl
  1166e2:	38 ca                	cmp    %cl,%dl
  1166e4:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  1166e8:	0f 8c 2d ff ff ff    	jl     11661b <pqcrystals_kyber768_ref_poly_compress+0x373>
  1166ee:	e9 53 04 00 00       	jmp    116b46 <pqcrystals_kyber768_ref_poly_compress+0x89e>
  1166f3:	88 53 1f             	mov    %dl,0x1f(%rbx)
  1166f6:	44 89 ea             	mov    %r13d,%edx
  1166f9:	80 e2 07             	and    $0x7,%dl
  1166fc:	38 ca                	cmp    %cl,%dl
  1166fe:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  116702:	0f 8c 60 ff ff ff    	jl     116668 <pqcrystals_kyber768_ref_poly_compress+0x3c0>
  116708:	e9 41 04 00 00       	jmp    116b4e <pqcrystals_kyber768_ref_poly_compress+0x8a6>
  11670d:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  116711:	48 8d 3d d8 c9 04 00 	lea    0x4c9d8(%rip),%rdi        # 1630f0 <_ZL17kSuppressionTypes+0x16a0>
  116718:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  11671c:	4c 89 ce             	mov    %r9,%rsi
  11671f:	4c 89 d2             	mov    %r10,%rdx
  116722:	48 89 43 40          	mov    %rax,0x40(%rbx)
  116726:	4d 89 c5             	mov    %r8,%r13
  116729:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  11672d:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  116731:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  116735:	e8 86 4e ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  11673a:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  11673e:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  116742:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  116746:	4d 89 e8             	mov    %r13,%r8
  116749:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  11674d:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  116751:	48 8b 43 40          	mov    0x40(%rbx),%rax
  116755:	e9 04 fe ff ff       	jmp    11655e <pqcrystals_kyber768_ref_poly_compress+0x2b6>
  11675a:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  11675e:	48 8d 3d 9b c9 04 00 	lea    0x4c99b(%rip),%rdi        # 163100 <_ZL17kSuppressionTypes+0x16b0>
  116765:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  116769:	31 f6                	xor    %esi,%esi
  11676b:	31 d2                	xor    %edx,%edx
  11676d:	48 89 43 40          	mov    %rax,0x40(%rbx)
  116771:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  116775:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  116779:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  11677d:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  116781:	e8 3a 4e ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116786:	48 8d 3d 83 c9 04 00 	lea    0x4c983(%rip),%rdi        # 163110 <_ZL17kSuppressionTypes+0x16c0>
  11678d:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  116791:	e8 da 17 ff ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  116796:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  11679a:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  11679e:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  1167a2:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  1167a6:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  1167aa:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  1167ae:	48 8b 43 40          	mov    0x40(%rbx),%rax
  1167b2:	e9 b5 fd ff ff       	jmp    11656c <pqcrystals_kyber768_ref_poly_compress+0x2c4>
  1167b7:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  1167bb:	48 8d 3d 6e c9 04 00 	lea    0x4c96e(%rip),%rdi        # 163130 <_ZL17kSuppressionTypes+0x16e0>
  1167c2:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  1167c6:	4c 89 ce             	mov    %r9,%rsi
  1167c9:	4c 89 da             	mov    %r11,%rdx
  1167cc:	48 89 43 40          	mov    %rax,0x40(%rbx)
  1167d0:	4d 89 c5             	mov    %r8,%r13
  1167d3:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  1167d7:	4d 89 d4             	mov    %r10,%r12
  1167da:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  1167de:	e8 dd 4d ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1167e3:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  1167e7:	4d 89 e2             	mov    %r12,%r10
  1167ea:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  1167ee:	4d 89 e8             	mov    %r13,%r8
  1167f1:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  1167f5:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  1167f9:	48 8b 43 40          	mov    0x40(%rbx),%rax
  1167fd:	e9 94 fd ff ff       	jmp    116596 <pqcrystals_kyber768_ref_poly_compress+0x2ee>
  116802:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  116806:	48 8d 3d 33 c9 04 00 	lea    0x4c933(%rip),%rdi        # 163140 <_ZL17kSuppressionTypes+0x16f0>
  11680d:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  116811:	4c 89 ce             	mov    %r9,%rsi
  116814:	88 53 1f             	mov    %dl,0x1f(%rbx)
  116817:	48 8b 93 80 00 00 00 	mov    0x80(%rbx),%rdx
  11681e:	48 89 43 40          	mov    %rax,0x40(%rbx)
  116822:	4d 89 c5             	mov    %r8,%r13
  116825:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  116829:	4d 89 d4             	mov    %r10,%r12
  11682c:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  116830:	e8 8b 4d ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116835:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  116839:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  11683d:	4d 89 e2             	mov    %r12,%r10
  116840:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  116844:	4d 89 e8             	mov    %r13,%r8
  116847:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  11684b:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  11684f:	48 8b 43 40          	mov    0x40(%rbx),%rax
  116853:	e9 4d fd ff ff       	jmp    1165a5 <pqcrystals_kyber768_ref_poly_compress+0x2fd>
  116858:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  11685c:	48 8d 3d ed c8 04 00 	lea    0x4c8ed(%rip),%rdi        # 163150 <_ZL17kSuppressionTypes+0x1700>
  116863:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  116867:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  11686b:	88 53 1f             	mov    %dl,0x1f(%rbx)
  11686e:	4c 89 ea             	mov    %r13,%rdx
  116871:	48 89 43 40          	mov    %rax,0x40(%rbx)
  116875:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  116879:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  11687d:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  116881:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  116885:	e8 36 4d ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  11688a:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  11688e:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  116892:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  116896:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  11689a:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  11689e:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  1168a2:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  1168a6:	48 8b 43 40          	mov    0x40(%rbx),%rax
  1168aa:	e9 09 fd ff ff       	jmp    1165b8 <pqcrystals_kyber768_ref_poly_compress+0x310>
  1168af:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  1168b3:	48 8d 3d a6 c8 04 00 	lea    0x4c8a6(%rip),%rdi        # 163160 <_ZL17kSuppressionTypes+0x1710>
  1168ba:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  1168be:	4c 89 ce             	mov    %r9,%rsi
  1168c1:	48 8b 53 78          	mov    0x78(%rbx),%rdx
  1168c5:	48 89 43 40          	mov    %rax,0x40(%rbx)
  1168c9:	4d 89 c5             	mov    %r8,%r13
  1168cc:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  1168d0:	4d 89 d4             	mov    %r10,%r12
  1168d3:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  1168d7:	e8 e4 4c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1168dc:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  1168e0:	4d 89 e2             	mov    %r12,%r10
  1168e3:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  1168e7:	4d 89 e8             	mov    %r13,%r8
  1168ea:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  1168ee:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  1168f2:	48 8b 43 40          	mov    0x40(%rbx),%rax
  1168f6:	e9 e8 fc ff ff       	jmp    1165e3 <pqcrystals_kyber768_ref_poly_compress+0x33b>
  1168fb:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  1168ff:	48 8d 3d 6a c8 04 00 	lea    0x4c86a(%rip),%rdi        # 163170 <_ZL17kSuppressionTypes+0x1720>
  116906:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  11690a:	4c 89 ce             	mov    %r9,%rsi
  11690d:	88 53 1f             	mov    %dl,0x1f(%rbx)
  116910:	48 8b 53 70          	mov    0x70(%rbx),%rdx
  116914:	48 89 43 40          	mov    %rax,0x40(%rbx)
  116918:	4d 89 c5             	mov    %r8,%r13
  11691b:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  11691f:	4d 89 d4             	mov    %r10,%r12
  116922:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  116926:	e8 95 4c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  11692b:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  11692f:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  116933:	4d 89 e2             	mov    %r12,%r10
  116936:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  11693a:	4d 89 e8             	mov    %r13,%r8
  11693d:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  116941:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  116945:	48 8b 43 40          	mov    0x40(%rbx),%rax
  116949:	e9 a4 fc ff ff       	jmp    1165f2 <pqcrystals_kyber768_ref_poly_compress+0x34a>
  11694e:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  116952:	48 8d 3d 27 c8 04 00 	lea    0x4c827(%rip),%rdi        # 163180 <_ZL17kSuppressionTypes+0x1730>
  116959:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  11695d:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  116961:	88 53 1f             	mov    %dl,0x1f(%rbx)
  116964:	4c 89 ea             	mov    %r13,%rdx
  116967:	48 89 43 40          	mov    %rax,0x40(%rbx)
  11696b:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  11696f:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  116973:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  116977:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  11697b:	e8 40 4c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116980:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  116984:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  116988:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  11698c:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  116990:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  116994:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  116998:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  11699c:	48 8b 43 40          	mov    0x40(%rbx),%rax
  1169a0:	e9 60 fc ff ff       	jmp    116605 <pqcrystals_kyber768_ref_poly_compress+0x35d>
  1169a5:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  1169a9:	48 8d 3d e0 c7 04 00 	lea    0x4c7e0(%rip),%rdi        # 163190 <_ZL17kSuppressionTypes+0x1740>
  1169b0:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  1169b4:	4c 89 ce             	mov    %r9,%rsi
  1169b7:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  1169bb:	48 89 43 40          	mov    %rax,0x40(%rbx)
  1169bf:	4d 89 c5             	mov    %r8,%r13
  1169c2:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  1169c6:	4d 89 d4             	mov    %r10,%r12
  1169c9:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  1169cd:	e8 ee 4b ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1169d2:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  1169d6:	4d 89 e2             	mov    %r12,%r10
  1169d9:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  1169dd:	4d 89 e8             	mov    %r13,%r8
  1169e0:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  1169e4:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  1169e8:	48 8b 43 40          	mov    0x40(%rbx),%rax
  1169ec:	e9 3f fc ff ff       	jmp    116630 <pqcrystals_kyber768_ref_poly_compress+0x388>
  1169f1:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  1169f5:	48 8d 3d a4 c7 04 00 	lea    0x4c7a4(%rip),%rdi        # 1631a0 <_ZL17kSuppressionTypes+0x1750>
  1169fc:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  116a00:	4c 89 ce             	mov    %r9,%rsi
  116a03:	88 53 1f             	mov    %dl,0x1f(%rbx)
  116a06:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  116a0a:	48 89 43 40          	mov    %rax,0x40(%rbx)
  116a0e:	4d 89 c5             	mov    %r8,%r13
  116a11:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  116a15:	4d 89 d4             	mov    %r10,%r12
  116a18:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  116a1c:	e8 9f 4b ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116a21:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  116a25:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  116a29:	4d 89 e2             	mov    %r12,%r10
  116a2c:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  116a30:	4d 89 e8             	mov    %r13,%r8
  116a33:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  116a37:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  116a3b:	48 8b 43 40          	mov    0x40(%rbx),%rax
  116a3f:	e9 fb fb ff ff       	jmp    11663f <pqcrystals_kyber768_ref_poly_compress+0x397>
  116a44:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  116a48:	48 8d 3d 61 c7 04 00 	lea    0x4c761(%rip),%rdi        # 1631b0 <_ZL17kSuppressionTypes+0x1760>
  116a4f:	48 89 73 20          	mov    %rsi,0x20(%rbx)
  116a53:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  116a57:	88 53 1f             	mov    %dl,0x1f(%rbx)
  116a5a:	4c 89 ea             	mov    %r13,%rdx
  116a5d:	48 89 43 40          	mov    %rax,0x40(%rbx)
  116a61:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  116a65:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  116a69:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  116a6d:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  116a71:	e8 4a 4b ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116a76:	0f b6 53 1f          	movzbl 0x1f(%rbx),%edx
  116a7a:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  116a7e:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  116a82:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  116a86:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  116a8a:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  116a8e:	48 8b 73 20          	mov    0x20(%rbx),%rsi
  116a92:	48 8b 43 40          	mov    0x40(%rbx),%rax
  116a96:	e9 b7 fb ff ff       	jmp    116652 <pqcrystals_kyber768_ref_poly_compress+0x3aa>
  116a9b:	48 8d 56 04          	lea    0x4(%rsi),%rdx
  116a9f:	48 89 7b 38          	mov    %rdi,0x38(%rbx)
  116aa3:	48 8d 3d 16 c7 04 00 	lea    0x4c716(%rip),%rdi        # 1631c0 <_ZL17kSuppressionTypes+0x1770>
  116aaa:	49 89 f5             	mov    %rsi,%r13
  116aad:	48 89 43 40          	mov    %rax,0x40(%rbx)
  116ab1:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  116ab5:	4c 89 4b 30          	mov    %r9,0x30(%rbx)
  116ab9:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  116abd:	4c 89 5b 28          	mov    %r11,0x28(%rbx)
  116ac1:	e8 fa 4a ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116ac6:	4c 8b 5b 28          	mov    0x28(%rbx),%r11
  116aca:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  116ace:	4c 8b 4b 30          	mov    0x30(%rbx),%r9
  116ad2:	4c 8b 43 50          	mov    0x50(%rbx),%r8
  116ad6:	48 8b 7b 38          	mov    0x38(%rbx),%rdi
  116ada:	4c 89 ee             	mov    %r13,%rsi
  116add:	48 8b 43 40          	mov    0x40(%rbx),%rax
  116ae1:	e9 9e fb ff ff       	jmp    116684 <pqcrystals_kyber768_ref_poly_compress+0x3dc>
  116ae6:	41 c6 80 04 80 ff 7f 	movb   $0xf8,0x7fff8004(%r8)
  116aed:	f8 
  116aee:	48 c7 07 0e 36 e0 45 	movq   $0x45e0360e,(%rdi)
  116af5:	48 85 c0             	test   %rax,%rax
  116af8:	74 1a                	je     116b14 <pqcrystals_kyber768_ref_poly_compress+0x86c>
  116afa:	48 b9 f5 f5 f5 f5 f5 	movabs $0xf5f5f5f5f5f5f5f5,%rcx
  116b01:	f5 f5 f5 
  116b04:	49 89 88 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r8)
  116b0b:	48 8b 40 38          	mov    0x38(%rax),%rax
  116b0f:	c6 00 00             	movb   $0x0,(%rax)
  116b12:	eb 0b                	jmp    116b1f <pqcrystals_kyber768_ref_poly_compress+0x877>
  116b14:	49 c7 80 00 80 ff 7f 	movq   $0x0,0x7fff8000(%r8)
  116b1b:	00 00 00 00 
  116b1f:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  116b23:	5b                   	pop    %rbx
  116b24:	41 5c                	pop    %r12
  116b26:	41 5d                	pop    %r13
  116b28:	41 5e                	pop    %r14
  116b2a:	41 5f                	pop    %r15
  116b2c:	5d                   	pop    %rbp
  116b2d:	c3                   	ret
  116b2e:	4c 89 ef             	mov    %r13,%rdi
  116b31:	e8 6a 01 fc ff       	call   d6ca0 <__asan_report_load2>
  116b36:	48 89 f7             	mov    %rsi,%rdi
  116b39:	e8 62 04 fc ff       	call   d6fa0 <__asan_report_store1>
  116b3e:	4c 89 ef             	mov    %r13,%rdi
  116b41:	e8 5a 04 fc ff       	call   d6fa0 <__asan_report_store1>
  116b46:	4c 89 ef             	mov    %r13,%rdi
  116b49:	e8 52 04 fc ff       	call   d6fa0 <__asan_report_store1>
  116b4e:	4c 89 ef             	mov    %r13,%rdi
  116b51:	e8 4a 04 fc ff       	call   d6fa0 <__asan_report_store1>

Disassembly of section .fini:
