
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-sanitize/microbench/fixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


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
  1162c3:	49 89 f0             	mov    %rsi,%r8
  1162c6:	49 89 ff             	mov    %rdi,%r15
  1162c9:	48 8d 05 a0 21 06 00 	lea    0x621a0(%rip),%rax        # 178470 <__asan_option_detect_stack_use_after_return>
  1162d0:	83 38 00             	cmpl   $0x0,(%rax)
  1162d3:	74 12                	je     1162e7 <pqcrystals_kyber768_ref_poly_compress+0x3f>
  1162d5:	bf 40 00 00 00       	mov    $0x40,%edi
  1162da:	4d 89 c6             	mov    %r8,%r14
  1162dd:	e8 5e bc f2 ff       	call   41f40 <__asan_stack_malloc_0>
  1162e2:	4d 89 f0             	mov    %r14,%r8
  1162e5:	eb 02                	jmp    1162e9 <pqcrystals_kyber768_ref_poly_compress+0x41>
  1162e7:	31 c0                	xor    %eax,%eax
  1162e9:	48 89 c7             	mov    %rax,%rdi
  1162ec:	48 85 c0             	test   %rax,%rax
  1162ef:	75 0e                	jne    1162ff <pqcrystals_kyber768_ref_poly_compress+0x57>
  1162f1:	48 89 e7             	mov    %rsp,%rdi
  1162f4:	48 83 c7 c0          	add    $0xffffffffffffffc0,%rdi
  1162f8:	48 83 e7 e0          	and    $0xffffffffffffffe0,%rdi
  1162fc:	48 89 fc             	mov    %rdi,%rsp
  1162ff:	48 89 bb 98 00 00 00 	mov    %rdi,0x98(%rbx)
  116306:	4c 8d 57 20          	lea    0x20(%rdi),%r10
  11630a:	48 c7 07 b3 8a b5 41 	movq   $0x41b58ab3,(%rdi)
  116311:	48 8d 0d 1d fb 01 00 	lea    0x1fb1d(%rip),%rcx        # 135e35 <_ZN11__sanitizerL10kExtraRegsE+0x12c85>
  116318:	48 89 4f 08          	mov    %rcx,0x8(%rdi)
  11631c:	48 8d 0d 85 ff ff ff 	lea    -0x7b(%rip),%rcx        # 1162a8 <pqcrystals_kyber768_ref_poly_compress>
  116323:	48 89 4f 10          	mov    %rcx,0x10(%rdi)
  116327:	49 89 f9             	mov    %rdi,%r9
  11632a:	49 c1 e9 03          	shr    $0x3,%r9
  11632e:	48 b9 f1 f1 f1 f1 f8 	movabs $0xf3f3f3f8f1f1f1f1,%rcx
  116335:	f3 f3 f3 
  116338:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  11633f:	41 c6 81 04 80 ff 7f 	movb   $0x0,0x7fff8004(%r9)
  116346:	00 
  116347:	4d 85 c0             	test   %r8,%r8
  11634a:	0f 95 c1             	setne  %cl
  11634d:	41 f6 c0 01          	test   $0x1,%r8b
  116351:	41 0f 94 c6          	sete   %r14b
  116355:	41 20 ce             	and    %cl,%r14b
  116358:	4c 8d 5f 21          	lea    0x21(%rdi),%r11
  11635c:	48 8d 4f 22          	lea    0x22(%rdi),%rcx
  116360:	48 89 8b 80 00 00 00 	mov    %rcx,0x80(%rbx)
  116367:	48 8d 4f 23          	lea    0x23(%rdi),%rcx
  11636b:	48 89 4b 78          	mov    %rcx,0x78(%rbx)
  11636f:	48 8d 4f 24          	lea    0x24(%rdi),%rcx
  116373:	48 89 4b 70          	mov    %rcx,0x70(%rbx)
  116377:	48 8d 4f 25          	lea    0x25(%rdi),%rcx
  11637b:	48 89 4b 68          	mov    %rcx,0x68(%rbx)
  11637f:	48 8d 4f 26          	lea    0x26(%rdi),%rcx
  116383:	48 89 4b 60          	mov    %rcx,0x60(%rbx)
  116387:	48 8d 4f 27          	lea    0x27(%rdi),%rcx
  11638b:	48 89 4b 58          	mov    %rcx,0x58(%rbx)
  11638f:	45 31 ed             	xor    %r13d,%r13d
  116392:	4c 89 43 50          	mov    %r8,0x50(%rbx)
  116396:	4c 89 c2             	mov    %r8,%rdx
  116399:	4c 89 fe             	mov    %r15,%rsi
  11639c:	0f 1f 40 00          	nopl   0x0(%rax)
  1163a0:	4c 89 ab 90 00 00 00 	mov    %r13,0x90(%rbx)
  1163a7:	48 89 93 88 00 00 00 	mov    %rdx,0x88(%rbx)
  1163ae:	49 89 d5             	mov    %rdx,%r13
  1163b1:	45 31 e4             	xor    %r12d,%r12d
  1163b4:	66 66 66 2e 0f 1f 84 	data16 data16 cs nopw 0x0(%rax,%rax,1)
  1163bb:	00 00 00 00 00 
  1163c0:	45 84 f6             	test   %r14b,%r14b
  1163c3:	0f 84 95 00 00 00    	je     11645e <pqcrystals_kyber768_ref_poly_compress+0x1b6>
  1163c9:	4d 85 c0             	test   %r8,%r8
  1163cc:	0f 84 da 00 00 00    	je     1164ac <pqcrystals_kyber768_ref_poly_compress+0x204>
  1163d2:	4d 85 ed             	test   %r13,%r13
  1163d5:	0f 84 d1 00 00 00    	je     1164ac <pqcrystals_kyber768_ref_poly_compress+0x204>
  1163db:	4d 39 c5             	cmp    %r8,%r13
  1163de:	0f 82 c8 00 00 00    	jb     1164ac <pqcrystals_kyber768_ref_poly_compress+0x204>
  1163e4:	45 84 f6             	test   %r14b,%r14b
  1163e7:	0f 84 10 01 00 00    	je     1164fd <pqcrystals_kyber768_ref_poly_compress+0x255>
  1163ed:	4c 89 e9             	mov    %r13,%rcx
  1163f0:	48 c1 e9 03          	shr    $0x3,%rcx
  1163f4:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1163fb:	84 c9                	test   %cl,%cl
  1163fd:	75 4e                	jne    11644d <pqcrystals_kyber768_ref_poly_compress+0x1a5>
  1163ff:	48 8b 4b 50          	mov    0x50(%rbx),%rcx
  116403:	42 0f bf 0c 61       	movswl (%rcx,%r12,2),%ecx
  116408:	89 ca                	mov    %ecx,%edx
  11640a:	c1 ea 0f             	shr    $0xf,%edx
  11640d:	81 e2 01 0d 00 00    	and    $0xd01,%edx
  116413:	01 ca                	add    %ecx,%edx
  116415:	44 0f bf fa          	movswl %dx,%r15d
  116419:	66 45 85 ff          	test   %r15w,%r15w
  11641d:	0f 88 24 01 00 00    	js     116547 <pqcrystals_kyber768_ref_poly_compress+0x29f>
  116423:	41 69 cf b0 af 13 00 	imul   $0x13afb0,%r15d,%ecx
  11642a:	81 c1 7b 9a 00 08    	add    $0x8009a7b,%ecx
  116430:	c1 e9 1c             	shr    $0x1c,%ecx
  116433:	43 88 0c 22          	mov    %cl,(%r10,%r12,1)
  116437:	49 ff c4             	inc    %r12
  11643a:	49 83 c5 02          	add    $0x2,%r13
  11643e:	49 83 fc 08          	cmp    $0x8,%r12
  116442:	0f 85 78 ff ff ff    	jne    1163c0 <pqcrystals_kyber768_ref_poly_compress+0x118>
  116448:	e9 53 01 00 00       	jmp    1165a0 <pqcrystals_kyber768_ref_poly_compress+0x2f8>
  11644d:	44 89 ea             	mov    %r13d,%edx
  116450:	80 e2 07             	and    $0x7,%dl
  116453:	fe c2                	inc    %dl
  116455:	38 ca                	cmp    %cl,%dl
  116457:	7c a6                	jl     1163ff <pqcrystals_kyber768_ref_poly_compress+0x157>
  116459:	e9 ec 06 00 00       	jmp    116b4a <pqcrystals_kyber768_ref_poly_compress+0x8a2>
  11645e:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116462:	48 8d 3d 37 cc 04 00 	lea    0x4cc37(%rip),%rdi        # 1630a0 <_ZL17kSuppressionTypes+0x1650>
  116469:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  11646d:	4c 89 c6             	mov    %r8,%rsi
  116470:	48 89 43 28          	mov    %rax,0x28(%rbx)
  116474:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  116478:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  11647c:	4d 89 d7             	mov    %r10,%r15
  11647f:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  116483:	e8 e8 1a ff ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  116488:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  11648c:	4d 89 fa             	mov    %r15,%r10
  11648f:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  116493:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116497:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  11649b:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  11649f:	48 8b 43 28          	mov    0x28(%rbx),%rax
  1164a3:	4d 85 c0             	test   %r8,%r8
  1164a6:	0f 85 26 ff ff ff    	jne    1163d2 <pqcrystals_kyber768_ref_poly_compress+0x12a>
  1164ac:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1164b0:	48 8d 3d 09 cc 04 00 	lea    0x4cc09(%rip),%rdi        # 1630c0 <_ZL17kSuppressionTypes+0x1670>
  1164b7:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  1164bb:	4c 89 c6             	mov    %r8,%rsi
  1164be:	4c 89 ea             	mov    %r13,%rdx
  1164c1:	48 89 43 28          	mov    %rax,0x28(%rbx)
  1164c5:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  1164c9:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  1164cd:	4d 89 d7             	mov    %r10,%r15
  1164d0:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  1164d4:	e8 e7 50 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1164d9:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  1164dd:	4d 89 fa             	mov    %r15,%r10
  1164e0:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  1164e4:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1164e8:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  1164ec:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  1164f0:	48 8b 43 28          	mov    0x28(%rbx),%rax
  1164f4:	45 84 f6             	test   %r14b,%r14b
  1164f7:	0f 85 f0 fe ff ff    	jne    1163ed <pqcrystals_kyber768_ref_poly_compress+0x145>
  1164fd:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116501:	48 8d 3d c8 cb 04 00 	lea    0x4cbc8(%rip),%rdi        # 1630d0 <_ZL17kSuppressionTypes+0x1680>
  116508:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  11650c:	4c 89 ee             	mov    %r13,%rsi
  11650f:	48 89 43 28          	mov    %rax,0x28(%rbx)
  116513:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  116517:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  11651b:	4d 89 d7             	mov    %r10,%r15
  11651e:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  116522:	e8 49 1a ff ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  116527:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  11652b:	4d 89 fa             	mov    %r15,%r10
  11652e:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  116532:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116536:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  11653a:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  11653e:	48 8b 43 28          	mov    0x28(%rbx),%rax
  116542:	e9 a6 fe ff ff       	jmp    1163ed <pqcrystals_kyber768_ref_poly_compress+0x145>
  116547:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  11654b:	44 89 fe             	mov    %r15d,%esi
  11654e:	ba 04 00 00 00       	mov    $0x4,%edx
  116553:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116557:	48 8d 3d 92 cb 04 00 	lea    0x4cb92(%rip),%rdi        # 1630f0 <_ZL17kSuppressionTypes+0x16a0>
  11655e:	48 89 43 28          	mov    %rax,0x28(%rbx)
  116562:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  116566:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  11656a:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  11656e:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  116572:	e8 59 2f ff ff       	call   1094d0 <__ubsan_handle_shift_out_of_bounds>
  116577:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  11657b:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  11657f:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  116583:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116587:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  11658b:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  11658f:	48 8b 43 28          	mov    0x28(%rbx),%rax
  116593:	e9 8b fe ff ff       	jmp    116423 <pqcrystals_kyber768_ref_poly_compress+0x17b>
  116598:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
  11659f:	00 
  1165a0:	45 0f b6 22          	movzbl (%r10),%r12d
  1165a4:	49 83 fa ff          	cmp    $0xffffffffffffffff,%r10
  1165a8:	0f 84 93 01 00 00    	je     116741 <pqcrystals_kyber768_ref_poly_compress+0x499>
  1165ae:	45 0f b6 6a 01       	movzbl 0x1(%r10),%r13d
  1165b3:	48 85 f6             	test   %rsi,%rsi
  1165b6:	0f 84 d0 01 00 00    	je     11678c <pqcrystals_kyber768_ref_poly_compress+0x4e4>
  1165bc:	48 89 f1             	mov    %rsi,%rcx
  1165bf:	48 c1 e9 03          	shr    $0x3,%rcx
  1165c3:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1165ca:	84 c9                	test   %cl,%cl
  1165cc:	0f 85 24 01 00 00    	jne    1166f6 <pqcrystals_kyber768_ref_poly_compress+0x44e>
  1165d2:	41 c0 e5 04          	shl    $0x4,%r13b
  1165d6:	45 08 e5             	or     %r12b,%r13b
  1165d9:	44 88 2e             	mov    %r13b,(%rsi)
  1165dc:	49 83 fa fe          	cmp    $0xfffffffffffffffe,%r10
  1165e0:	0f 83 00 02 00 00    	jae    1167e6 <pqcrystals_kyber768_ref_poly_compress+0x53e>
  1165e6:	45 0f b6 7a 02       	movzbl 0x2(%r10),%r15d
  1165eb:	49 83 fa fd          	cmp    $0xfffffffffffffffd,%r10
  1165ef:	0f 83 3e 02 00 00    	jae    116833 <pqcrystals_kyber768_ref_poly_compress+0x58b>
  1165f5:	45 0f b6 62 03       	movzbl 0x3(%r10),%r12d
  1165fa:	4c 8d 6e 01          	lea    0x1(%rsi),%r13
  1165fe:	48 83 fe ff          	cmp    $0xffffffffffffffff,%rsi
  116602:	0f 84 7e 02 00 00    	je     116886 <pqcrystals_kyber768_ref_poly_compress+0x5de>
  116608:	4c 89 e9             	mov    %r13,%rcx
  11660b:	48 c1 e9 03          	shr    $0x3,%rcx
  11660f:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  116616:	84 c9                	test   %cl,%cl
  116618:	0f 85 ea 00 00 00    	jne    116708 <pqcrystals_kyber768_ref_poly_compress+0x460>
  11661e:	41 c0 e4 04          	shl    $0x4,%r12b
  116622:	45 08 fc             	or     %r15b,%r12b
  116625:	45 88 65 00          	mov    %r12b,0x0(%r13)
  116629:	49 83 fa fc          	cmp    $0xfffffffffffffffc,%r10
  11662d:	0f 83 a6 02 00 00    	jae    1168d9 <pqcrystals_kyber768_ref_poly_compress+0x631>
  116633:	45 0f b6 7a 04       	movzbl 0x4(%r10),%r15d
  116638:	49 83 fa fb          	cmp    $0xfffffffffffffffb,%r10
  11663c:	0f 83 e1 02 00 00    	jae    116923 <pqcrystals_kyber768_ref_poly_compress+0x67b>
  116642:	45 0f b6 62 05       	movzbl 0x5(%r10),%r12d
  116647:	4c 8d 6e 02          	lea    0x2(%rsi),%r13
  11664b:	48 83 fe fe          	cmp    $0xfffffffffffffffe,%rsi
  11664f:	0f 83 21 03 00 00    	jae    116976 <pqcrystals_kyber768_ref_poly_compress+0x6ce>
  116655:	4c 89 e9             	mov    %r13,%rcx
  116658:	48 c1 e9 03          	shr    $0x3,%rcx
  11665c:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  116663:	84 c9                	test   %cl,%cl
  116665:	0f 85 b0 00 00 00    	jne    11671b <pqcrystals_kyber768_ref_poly_compress+0x473>
  11666b:	41 c0 e4 04          	shl    $0x4,%r12b
  11666f:	45 08 fc             	or     %r15b,%r12b
  116672:	45 88 65 00          	mov    %r12b,0x0(%r13)
  116676:	49 83 fa fa          	cmp    $0xfffffffffffffffa,%r10
  11667a:	0f 83 49 03 00 00    	jae    1169c9 <pqcrystals_kyber768_ref_poly_compress+0x721>
  116680:	45 0f b6 7a 06       	movzbl 0x6(%r10),%r15d
  116685:	49 83 fa f9          	cmp    $0xfffffffffffffff9,%r10
  116689:	0f 83 84 03 00 00    	jae    116a13 <pqcrystals_kyber768_ref_poly_compress+0x76b>
  11668f:	45 0f b6 62 07       	movzbl 0x7(%r10),%r12d
  116694:	4c 8d 6e 03          	lea    0x3(%rsi),%r13
  116698:	48 83 fe fd          	cmp    $0xfffffffffffffffd,%rsi
  11669c:	0f 83 c4 03 00 00    	jae    116a66 <pqcrystals_kyber768_ref_poly_compress+0x7be>
  1166a2:	4c 89 e9             	mov    %r13,%rcx
  1166a5:	48 c1 e9 03          	shr    $0x3,%rcx
  1166a9:	0f b6 89 00 80 ff 7f 	movzbl 0x7fff8000(%rcx),%ecx
  1166b0:	84 c9                	test   %cl,%cl
  1166b2:	75 7a                	jne    11672e <pqcrystals_kyber768_ref_poly_compress+0x486>
  1166b4:	41 c0 e4 04          	shl    $0x4,%r12b
  1166b8:	45 08 fc             	or     %r15b,%r12b
  1166bb:	44 88 66 03          	mov    %r12b,0x3(%rsi)
  1166bf:	48 83 fe fc          	cmp    $0xfffffffffffffffc,%rsi
  1166c3:	4c 8b ab 90 00 00 00 	mov    0x90(%rbx),%r13
  1166ca:	0f 83 e9 03 00 00    	jae    116ab9 <pqcrystals_kyber768_ref_poly_compress+0x811>
  1166d0:	48 83 c6 04          	add    $0x4,%rsi
  1166d4:	49 ff c5             	inc    %r13
  1166d7:	48 8b 93 88 00 00 00 	mov    0x88(%rbx),%rdx
  1166de:	48 83 c2 10          	add    $0x10,%rdx
  1166e2:	48 83 43 50 10       	addq   $0x10,0x50(%rbx)
  1166e7:	49 83 fd 20          	cmp    $0x20,%r13
  1166eb:	0f 85 af fc ff ff    	jne    1163a0 <pqcrystals_kyber768_ref_poly_compress+0xf8>
  1166f1:	e9 0c 04 00 00       	jmp    116b02 <pqcrystals_kyber768_ref_poly_compress+0x85a>
  1166f6:	89 f2                	mov    %esi,%edx
  1166f8:	80 e2 07             	and    $0x7,%dl
  1166fb:	38 ca                	cmp    %cl,%dl
  1166fd:	0f 8c cf fe ff ff    	jl     1165d2 <pqcrystals_kyber768_ref_poly_compress+0x32a>
  116703:	e9 4a 04 00 00       	jmp    116b52 <pqcrystals_kyber768_ref_poly_compress+0x8aa>
  116708:	44 89 ea             	mov    %r13d,%edx
  11670b:	80 e2 07             	and    $0x7,%dl
  11670e:	38 ca                	cmp    %cl,%dl
  116710:	0f 8c 08 ff ff ff    	jl     11661e <pqcrystals_kyber768_ref_poly_compress+0x376>
  116716:	e9 3f 04 00 00       	jmp    116b5a <pqcrystals_kyber768_ref_poly_compress+0x8b2>
  11671b:	44 89 ea             	mov    %r13d,%edx
  11671e:	80 e2 07             	and    $0x7,%dl
  116721:	38 ca                	cmp    %cl,%dl
  116723:	0f 8c 42 ff ff ff    	jl     11666b <pqcrystals_kyber768_ref_poly_compress+0x3c3>
  116729:	e9 34 04 00 00       	jmp    116b62 <pqcrystals_kyber768_ref_poly_compress+0x8ba>
  11672e:	44 89 ea             	mov    %r13d,%edx
  116731:	80 e2 07             	and    $0x7,%dl
  116734:	38 ca                	cmp    %cl,%dl
  116736:	0f 8c 78 ff ff ff    	jl     1166b4 <pqcrystals_kyber768_ref_poly_compress+0x40c>
  11673c:	e9 29 04 00 00       	jmp    116b6a <pqcrystals_kyber768_ref_poly_compress+0x8c2>
  116741:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116745:	48 8d 3d c4 c9 04 00 	lea    0x4c9c4(%rip),%rdi        # 163110 <_ZL17kSuppressionTypes+0x16c0>
  11674c:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  116750:	4c 89 d6             	mov    %r10,%rsi
  116753:	4c 89 da             	mov    %r11,%rdx
  116756:	48 89 43 28          	mov    %rax,0x28(%rbx)
  11675a:	4d 89 c5             	mov    %r8,%r13
  11675d:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  116761:	4d 89 d7             	mov    %r10,%r15
  116764:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  116768:	e8 53 4e ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  11676d:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  116771:	4d 89 fa             	mov    %r15,%r10
  116774:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  116778:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  11677c:	4d 89 e8             	mov    %r13,%r8
  11677f:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  116783:	48 8b 43 28          	mov    0x28(%rbx),%rax
  116787:	e9 22 fe ff ff       	jmp    1165ae <pqcrystals_kyber768_ref_poly_compress+0x306>
  11678c:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116790:	48 8d 3d 89 c9 04 00 	lea    0x4c989(%rip),%rdi        # 163120 <_ZL17kSuppressionTypes+0x16d0>
  116797:	49 89 f7             	mov    %rsi,%r15
  11679a:	31 f6                	xor    %esi,%esi
  11679c:	31 d2                	xor    %edx,%edx
  11679e:	48 89 43 28          	mov    %rax,0x28(%rbx)
  1167a2:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  1167a6:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  1167aa:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  1167ae:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  1167b2:	e8 09 4e ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1167b7:	48 8d 3d 72 c9 04 00 	lea    0x4c972(%rip),%rdi        # 163130 <_ZL17kSuppressionTypes+0x16e0>
  1167be:	4c 89 fe             	mov    %r15,%rsi
  1167c1:	e8 aa 17 ff ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  1167c6:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  1167ca:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  1167ce:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  1167d2:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1167d6:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  1167da:	4c 89 fe             	mov    %r15,%rsi
  1167dd:	48 8b 43 28          	mov    0x28(%rbx),%rax
  1167e1:	e9 d6 fd ff ff       	jmp    1165bc <pqcrystals_kyber768_ref_poly_compress+0x314>
  1167e6:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1167ea:	48 8d 3d 5f c9 04 00 	lea    0x4c95f(%rip),%rdi        # 163150 <_ZL17kSuppressionTypes+0x1700>
  1167f1:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  1167f5:	4c 89 d6             	mov    %r10,%rsi
  1167f8:	48 8b 93 80 00 00 00 	mov    0x80(%rbx),%rdx
  1167ff:	48 89 43 28          	mov    %rax,0x28(%rbx)
  116803:	4d 89 c5             	mov    %r8,%r13
  116806:	4d 89 cc             	mov    %r9,%r12
  116809:	4d 89 d7             	mov    %r10,%r15
  11680c:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  116810:	e8 ab 4d ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116815:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  116819:	4d 89 fa             	mov    %r15,%r10
  11681c:	4d 89 e1             	mov    %r12,%r9
  11681f:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116823:	4d 89 e8             	mov    %r13,%r8
  116826:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  11682a:	48 8b 43 28          	mov    0x28(%rbx),%rax
  11682e:	e9 b3 fd ff ff       	jmp    1165e6 <pqcrystals_kyber768_ref_poly_compress+0x33e>
  116833:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116837:	48 8d 3d 22 c9 04 00 	lea    0x4c922(%rip),%rdi        # 163160 <_ZL17kSuppressionTypes+0x1710>
  11683e:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  116842:	4c 89 d6             	mov    %r10,%rsi
  116845:	48 8b 53 78          	mov    0x78(%rbx),%rdx
  116849:	48 89 43 28          	mov    %rax,0x28(%rbx)
  11684d:	4d 89 c5             	mov    %r8,%r13
  116850:	4d 89 cc             	mov    %r9,%r12
  116853:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  116857:	4d 89 d7             	mov    %r10,%r15
  11685a:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  11685e:	e8 5d 4d ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116863:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  116867:	4d 89 fa             	mov    %r15,%r10
  11686a:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  11686f:	4d 89 e1             	mov    %r12,%r9
  116872:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116876:	4d 89 e8             	mov    %r13,%r8
  116879:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  11687d:	48 8b 43 28          	mov    0x28(%rbx),%rax
  116881:	e9 6f fd ff ff       	jmp    1165f5 <pqcrystals_kyber768_ref_poly_compress+0x34d>
  116886:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  11688a:	48 8d 3d df c8 04 00 	lea    0x4c8df(%rip),%rdi        # 163170 <_ZL17kSuppressionTypes+0x1720>
  116891:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  116895:	49 89 f7             	mov    %rsi,%r15
  116898:	4c 89 ea             	mov    %r13,%rdx
  11689b:	48 89 43 28          	mov    %rax,0x28(%rbx)
  11689f:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  1168a3:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  1168a7:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  1168ab:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  1168af:	e8 0c 4d ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1168b4:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  1168b8:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  1168bc:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  1168c0:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1168c4:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  1168c8:	4c 89 fe             	mov    %r15,%rsi
  1168cb:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  1168d0:	48 8b 43 28          	mov    0x28(%rbx),%rax
  1168d4:	e9 2f fd ff ff       	jmp    116608 <pqcrystals_kyber768_ref_poly_compress+0x360>
  1168d9:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1168dd:	48 8d 3d 9c c8 04 00 	lea    0x4c89c(%rip),%rdi        # 163180 <_ZL17kSuppressionTypes+0x1730>
  1168e4:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  1168e8:	4c 89 d6             	mov    %r10,%rsi
  1168eb:	48 8b 53 70          	mov    0x70(%rbx),%rdx
  1168ef:	48 89 43 28          	mov    %rax,0x28(%rbx)
  1168f3:	4d 89 c5             	mov    %r8,%r13
  1168f6:	4d 89 cc             	mov    %r9,%r12
  1168f9:	4d 89 d7             	mov    %r10,%r15
  1168fc:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  116900:	e8 bb 4c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116905:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  116909:	4d 89 fa             	mov    %r15,%r10
  11690c:	4d 89 e1             	mov    %r12,%r9
  11690f:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116913:	4d 89 e8             	mov    %r13,%r8
  116916:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  11691a:	48 8b 43 28          	mov    0x28(%rbx),%rax
  11691e:	e9 10 fd ff ff       	jmp    116633 <pqcrystals_kyber768_ref_poly_compress+0x38b>
  116923:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116927:	48 8d 3d 62 c8 04 00 	lea    0x4c862(%rip),%rdi        # 163190 <_ZL17kSuppressionTypes+0x1740>
  11692e:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  116932:	4c 89 d6             	mov    %r10,%rsi
  116935:	48 8b 53 68          	mov    0x68(%rbx),%rdx
  116939:	48 89 43 28          	mov    %rax,0x28(%rbx)
  11693d:	4d 89 c5             	mov    %r8,%r13
  116940:	4d 89 cc             	mov    %r9,%r12
  116943:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  116947:	4d 89 d7             	mov    %r10,%r15
  11694a:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  11694e:	e8 6d 4c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116953:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  116957:	4d 89 fa             	mov    %r15,%r10
  11695a:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  11695f:	4d 89 e1             	mov    %r12,%r9
  116962:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116966:	4d 89 e8             	mov    %r13,%r8
  116969:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  11696d:	48 8b 43 28          	mov    0x28(%rbx),%rax
  116971:	e9 cc fc ff ff       	jmp    116642 <pqcrystals_kyber768_ref_poly_compress+0x39a>
  116976:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  11697a:	48 8d 3d 1f c8 04 00 	lea    0x4c81f(%rip),%rdi        # 1631a0 <_ZL17kSuppressionTypes+0x1750>
  116981:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  116985:	49 89 f7             	mov    %rsi,%r15
  116988:	4c 89 ea             	mov    %r13,%rdx
  11698b:	48 89 43 28          	mov    %rax,0x28(%rbx)
  11698f:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  116993:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  116997:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  11699b:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  11699f:	e8 1c 4c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1169a4:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  1169a8:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  1169ac:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  1169b0:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  1169b4:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  1169b8:	4c 89 fe             	mov    %r15,%rsi
  1169bb:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  1169c0:	48 8b 43 28          	mov    0x28(%rbx),%rax
  1169c4:	e9 8c fc ff ff       	jmp    116655 <pqcrystals_kyber768_ref_poly_compress+0x3ad>
  1169c9:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  1169cd:	48 8d 3d dc c7 04 00 	lea    0x4c7dc(%rip),%rdi        # 1631b0 <_ZL17kSuppressionTypes+0x1760>
  1169d4:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  1169d8:	4c 89 d6             	mov    %r10,%rsi
  1169db:	48 8b 53 60          	mov    0x60(%rbx),%rdx
  1169df:	48 89 43 28          	mov    %rax,0x28(%rbx)
  1169e3:	4d 89 c5             	mov    %r8,%r13
  1169e6:	4d 89 cc             	mov    %r9,%r12
  1169e9:	4d 89 d7             	mov    %r10,%r15
  1169ec:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  1169f0:	e8 cb 4b ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1169f5:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  1169f9:	4d 89 fa             	mov    %r15,%r10
  1169fc:	4d 89 e1             	mov    %r12,%r9
  1169ff:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116a03:	4d 89 e8             	mov    %r13,%r8
  116a06:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  116a0a:	48 8b 43 28          	mov    0x28(%rbx),%rax
  116a0e:	e9 6d fc ff ff       	jmp    116680 <pqcrystals_kyber768_ref_poly_compress+0x3d8>
  116a13:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116a17:	48 8d 3d a2 c7 04 00 	lea    0x4c7a2(%rip),%rdi        # 1631c0 <_ZL17kSuppressionTypes+0x1770>
  116a1e:	48 89 73 30          	mov    %rsi,0x30(%rbx)
  116a22:	4c 89 d6             	mov    %r10,%rsi
  116a25:	48 8b 53 58          	mov    0x58(%rbx),%rdx
  116a29:	48 89 43 28          	mov    %rax,0x28(%rbx)
  116a2d:	4d 89 c5             	mov    %r8,%r13
  116a30:	4d 89 cc             	mov    %r9,%r12
  116a33:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  116a37:	4d 89 d7             	mov    %r10,%r15
  116a3a:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  116a3e:	e8 7d 4b ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116a43:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  116a47:	4d 89 fa             	mov    %r15,%r10
  116a4a:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  116a4f:	4d 89 e1             	mov    %r12,%r9
  116a52:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116a56:	4d 89 e8             	mov    %r13,%r8
  116a59:	48 8b 73 30          	mov    0x30(%rbx),%rsi
  116a5d:	48 8b 43 28          	mov    0x28(%rbx),%rax
  116a61:	e9 29 fc ff ff       	jmp    11668f <pqcrystals_kyber768_ref_poly_compress+0x3e7>
  116a66:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116a6a:	48 8d 3d 5f c7 04 00 	lea    0x4c75f(%rip),%rdi        # 1631d0 <_ZL17kSuppressionTypes+0x1780>
  116a71:	44 88 7b 17          	mov    %r15b,0x17(%rbx)
  116a75:	49 89 f7             	mov    %rsi,%r15
  116a78:	4c 89 ea             	mov    %r13,%rdx
  116a7b:	48 89 43 28          	mov    %rax,0x28(%rbx)
  116a7f:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  116a83:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  116a87:	4c 89 53 48          	mov    %r10,0x48(%rbx)
  116a8b:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  116a8f:	e8 2c 4b ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116a94:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  116a98:	4c 8b 53 48          	mov    0x48(%rbx),%r10
  116a9c:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  116aa0:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116aa4:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  116aa8:	4c 89 fe             	mov    %r15,%rsi
  116aab:	44 0f b6 7b 17       	movzbl 0x17(%rbx),%r15d
  116ab0:	48 8b 43 28          	mov    0x28(%rbx),%rax
  116ab4:	e9 e9 fb ff ff       	jmp    1166a2 <pqcrystals_kyber768_ref_poly_compress+0x3fa>
  116ab9:	48 8d 56 04          	lea    0x4(%rsi),%rdx
  116abd:	48 89 7b 20          	mov    %rdi,0x20(%rbx)
  116ac1:	48 8d 3d 18 c7 04 00 	lea    0x4c718(%rip),%rdi        # 1631e0 <_ZL17kSuppressionTypes+0x1790>
  116ac8:	49 89 f4             	mov    %rsi,%r12
  116acb:	48 89 43 28          	mov    %rax,0x28(%rbx)
  116acf:	4c 89 43 40          	mov    %r8,0x40(%rbx)
  116ad3:	4c 89 4b 38          	mov    %r9,0x38(%rbx)
  116ad7:	4d 89 d7             	mov    %r10,%r15
  116ada:	4c 89 5b 18          	mov    %r11,0x18(%rbx)
  116ade:	e8 dd 4a ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  116ae3:	4c 8b 5b 18          	mov    0x18(%rbx),%r11
  116ae7:	4d 89 fa             	mov    %r15,%r10
  116aea:	4c 8b 4b 38          	mov    0x38(%rbx),%r9
  116aee:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  116af2:	4c 8b 43 40          	mov    0x40(%rbx),%r8
  116af6:	4c 89 e6             	mov    %r12,%rsi
  116af9:	48 8b 43 28          	mov    0x28(%rbx),%rax
  116afd:	e9 ce fb ff ff       	jmp    1166d0 <pqcrystals_kyber768_ref_poly_compress+0x428>
  116b02:	41 c6 81 04 80 ff 7f 	movb   $0xf8,0x7fff8004(%r9)
  116b09:	f8 
  116b0a:	48 c7 07 0e 36 e0 45 	movq   $0x45e0360e,(%rdi)
  116b11:	48 85 c0             	test   %rax,%rax
  116b14:	74 1a                	je     116b30 <pqcrystals_kyber768_ref_poly_compress+0x888>
  116b16:	48 b9 f5 f5 f5 f5 f5 	movabs $0xf5f5f5f5f5f5f5f5,%rcx
  116b1d:	f5 f5 f5 
  116b20:	49 89 89 00 80 ff 7f 	mov    %rcx,0x7fff8000(%r9)
  116b27:	48 8b 40 38          	mov    0x38(%rax),%rax
  116b2b:	c6 00 00             	movb   $0x0,(%rax)
  116b2e:	eb 0b                	jmp    116b3b <pqcrystals_kyber768_ref_poly_compress+0x893>
  116b30:	49 c7 81 00 80 ff 7f 	movq   $0x0,0x7fff8000(%r9)
  116b37:	00 00 00 00 
  116b3b:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  116b3f:	5b                   	pop    %rbx
  116b40:	41 5c                	pop    %r12
  116b42:	41 5d                	pop    %r13
  116b44:	41 5e                	pop    %r14
  116b46:	41 5f                	pop    %r15
  116b48:	5d                   	pop    %rbp
  116b49:	c3                   	ret
  116b4a:	4c 89 ef             	mov    %r13,%rdi
  116b4d:	e8 4e 01 fc ff       	call   d6ca0 <__asan_report_load2>
  116b52:	48 89 f7             	mov    %rsi,%rdi
  116b55:	e8 46 04 fc ff       	call   d6fa0 <__asan_report_store1>
  116b5a:	4c 89 ef             	mov    %r13,%rdi
  116b5d:	e8 3e 04 fc ff       	call   d6fa0 <__asan_report_store1>
  116b62:	4c 89 ef             	mov    %r13,%rdi
  116b65:	e8 36 04 fc ff       	call   d6fa0 <__asan_report_store1>
  116b6a:	4c 89 ef             	mov    %r13,%rdi
  116b6d:	e8 2e 04 fc ff       	call   d6fa0 <__asan_report_store1>

Disassembly of section .fini:
