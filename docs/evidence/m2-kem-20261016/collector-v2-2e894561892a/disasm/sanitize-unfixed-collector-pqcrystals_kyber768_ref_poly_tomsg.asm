
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-sanitize/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000001164e8 <pqcrystals_kyber768_ref_poly_tomsg>:
  1164e8:	55                   	push   %rbp
  1164e9:	48 89 e5             	mov    %rsp,%rbp
  1164ec:	41 57                	push   %r15
  1164ee:	41 56                	push   %r14
  1164f0:	41 55                	push   %r13
  1164f2:	41 54                	push   %r12
  1164f4:	53                   	push   %rbx
  1164f5:	48 83 ec 38          	sub    $0x38,%rsp
  1164f9:	48 85 f6             	test   %rsi,%rsi
  1164fc:	0f 95 c0             	setne  %al
  1164ff:	40 f6 c6 01          	test   $0x1,%sil
  116503:	41 0f 94 c5          	sete   %r13b
  116507:	41 20 c5             	and    %al,%r13b
  11650a:	45 31 c0             	xor    %r8d,%r8d
  11650d:	4c 8d 0d 5c af 04 00 	lea    0x4af5c(%rip),%r9        # 161470 <_ZL17kSuppressionTypes+0x1a20>
  116514:	4c 8d 15 45 af 04 00 	lea    0x4af45(%rip),%r10        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  11651b:	4c 8d 1d 1e af 04 00 	lea    0x4af1e(%rip),%r11        # 161440 <_ZL17kSuppressionTypes+0x19f0>
  116522:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  116526:	49 89 f7             	mov    %rsi,%r15
  116529:	eb 1f                	jmp    11654a <pqcrystals_kyber768_ref_poly_tomsg+0x62>
  11652b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
  116530:	49 ff c0             	inc    %r8
  116533:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  116537:	49 83 c7 10          	add    $0x10,%r15
  11653b:	48 83 45 a0 10       	addq   $0x10,-0x60(%rbp)
  116540:	49 83 f8 20          	cmp    $0x20,%r8
  116544:	0f 84 d3 02 00 00    	je     11681d <pqcrystals_kyber768_ref_poly_tomsg+0x335>
  11654a:	48 85 ff             	test   %rdi,%rdi
  11654d:	0f 95 c0             	setne  %al
  116550:	48 89 fa             	mov    %rdi,%rdx
  116553:	4c 01 c2             	add    %r8,%rdx
  116556:	0f 95 c3             	setne  %bl
  116559:	48 39 fa             	cmp    %rdi,%rdx
  11655c:	0f 93 c1             	setae  %cl
  11655f:	20 c3                	and    %al,%bl
  116561:	20 cb                	and    %cl,%bl
  116563:	88 5d d7             	mov    %bl,-0x29(%rbp)
  116566:	48 89 55 b0          	mov    %rdx,-0x50(%rbp)
  11656a:	4c 89 7d a8          	mov    %r15,-0x58(%rbp)
  11656e:	0f 84 1b 02 00 00    	je     11678f <pqcrystals_kyber768_ref_poly_tomsg+0x2a7>
  116574:	48 85 ff             	test   %rdi,%rdi
  116577:	0f 84 5b 02 00 00    	je     1167d8 <pqcrystals_kyber768_ref_poly_tomsg+0x2f0>
  11657d:	49 89 d6             	mov    %rdx,%r14
  116580:	49 c1 ee 03          	shr    $0x3,%r14
  116584:	41 0f b6 86 00 80 ff 	movzbl 0x7fff8000(%r14),%eax
  11658b:	7f 
  11658c:	84 c0                	test   %al,%al
  11658e:	0f 85 e9 01 00 00    	jne    11677d <pqcrystals_kyber768_ref_poly_tomsg+0x295>
  116594:	c6 02 00             	movb   $0x0,(%rdx)
  116597:	45 31 e4             	xor    %r12d,%r12d
  11659a:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  11659e:	66 90                	xchg   %ax,%ax
  1165a0:	45 84 ed             	test   %r13b,%r13b
  1165a3:	0f 84 ba 00 00 00    	je     116663 <pqcrystals_kyber768_ref_poly_tomsg+0x17b>
  1165a9:	48 85 f6             	test   %rsi,%rsi
  1165ac:	0f 84 f7 00 00 00    	je     1166a9 <pqcrystals_kyber768_ref_poly_tomsg+0x1c1>
  1165b2:	4d 85 ff             	test   %r15,%r15
  1165b5:	0f 84 ee 00 00 00    	je     1166a9 <pqcrystals_kyber768_ref_poly_tomsg+0x1c1>
  1165bb:	49 39 f7             	cmp    %rsi,%r15
  1165be:	0f 82 e5 00 00 00    	jb     1166a9 <pqcrystals_kyber768_ref_poly_tomsg+0x1c1>
  1165c4:	45 84 ed             	test   %r13b,%r13b
  1165c7:	0f 84 25 01 00 00    	je     1166f2 <pqcrystals_kyber768_ref_poly_tomsg+0x20a>
  1165cd:	4c 89 f8             	mov    %r15,%rax
  1165d0:	48 c1 e8 03          	shr    $0x3,%rax
  1165d4:	0f b6 80 00 80 ff 7f 	movzbl 0x7fff8000(%rax),%eax
  1165db:	84 c0                	test   %al,%al
  1165dd:	75 63                	jne    116642 <pqcrystals_kyber768_ref_poly_tomsg+0x15a>
  1165df:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  1165e3:	42 0f bf 04 60       	movswl (%rax,%r12,2),%eax
  1165e8:	89 c1                	mov    %eax,%ecx
  1165ea:	c1 e9 0f             	shr    $0xf,%ecx
  1165ed:	81 e1 01 0d 00 00    	and    $0xd01,%ecx
  1165f3:	01 c1                	add    %eax,%ecx
  1165f5:	0f b7 c1             	movzwl %cx,%eax
  1165f8:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
  1165ff:	48 69 d8 b8 af 13 00 	imul   $0x13afb8,%rax,%rbx
  116606:	48 c1 eb 20          	shr    $0x20,%rbx
  11660a:	83 e3 01             	and    $0x1,%ebx
  11660d:	44 89 e1             	mov    %r12d,%ecx
  116610:	d3 e3                	shl    %cl,%ebx
  116612:	84 d2                	test   %dl,%dl
  116614:	0f 84 19 01 00 00    	je     116733 <pqcrystals_kyber768_ref_poly_tomsg+0x24b>
  11661a:	41 0f b6 86 00 80 ff 	movzbl 0x7fff8000(%r14),%eax
  116621:	7f 
  116622:	84 c0                	test   %al,%al
  116624:	75 2d                	jne    116653 <pqcrystals_kyber768_ref_poly_tomsg+0x16b>
  116626:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  11662a:	08 18                	or     %bl,(%rax)
  11662c:	49 ff c4             	inc    %r12
  11662f:	49 83 c7 02          	add    $0x2,%r15
  116633:	49 83 fc 08          	cmp    $0x8,%r12
  116637:	0f 85 63 ff ff ff    	jne    1165a0 <pqcrystals_kyber768_ref_poly_tomsg+0xb8>
  11663d:	e9 ee fe ff ff       	jmp    116530 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
  116642:	44 89 f9             	mov    %r15d,%ecx
  116645:	80 e1 07             	and    $0x7,%cl
  116648:	fe c1                	inc    %cl
  11664a:	38 c1                	cmp    %al,%cl
  11664c:	7c 91                	jl     1165df <pqcrystals_kyber768_ref_poly_tomsg+0xf7>
  11664e:	e9 d9 01 00 00       	jmp    11682c <pqcrystals_kyber768_ref_poly_tomsg+0x344>
  116653:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  116657:	80 e1 07             	and    $0x7,%cl
  11665a:	38 c1                	cmp    %al,%cl
  11665c:	7c c8                	jl     116626 <pqcrystals_kyber768_ref_poly_tomsg+0x13e>
  11665e:	e9 d1 01 00 00       	jmp    116834 <pqcrystals_kyber768_ref_poly_tomsg+0x34c>
  116663:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  116667:	4c 89 df             	mov    %r11,%rdi
  11666a:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11666e:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  116672:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  116676:	e8 f5 08 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  11667b:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  11667f:	4c 8d 1d ba ad 04 00 	lea    0x4adba(%rip),%r11        # 161440 <_ZL17kSuppressionTypes+0x19f0>
  116686:	4c 8d 15 d3 ad 04 00 	lea    0x4add3(%rip),%r10        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  11668d:	4c 8d 0d dc ad 04 00 	lea    0x4addc(%rip),%r9        # 161470 <_ZL17kSuppressionTypes+0x1a20>
  116694:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  116698:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  11669c:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1166a0:	48 85 f6             	test   %rsi,%rsi
  1166a3:	0f 85 09 ff ff ff    	jne    1165b2 <pqcrystals_kyber768_ref_poly_tomsg+0xca>
  1166a9:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  1166ad:	4c 89 d7             	mov    %r10,%rdi
  1166b0:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  1166b4:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1166b8:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  1166bc:	4c 89 fa             	mov    %r15,%rdx
  1166bf:	e8 fc 3e ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1166c4:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  1166c8:	4c 8d 1d 71 ad 04 00 	lea    0x4ad71(%rip),%r11        # 161440 <_ZL17kSuppressionTypes+0x19f0>
  1166cf:	4c 8d 15 8a ad 04 00 	lea    0x4ad8a(%rip),%r10        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  1166d6:	4c 8d 0d 93 ad 04 00 	lea    0x4ad93(%rip),%r9        # 161470 <_ZL17kSuppressionTypes+0x1a20>
  1166dd:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  1166e1:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  1166e5:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1166e9:	45 84 ed             	test   %r13b,%r13b
  1166ec:	0f 85 db fe ff ff    	jne    1165cd <pqcrystals_kyber768_ref_poly_tomsg+0xe5>
  1166f2:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  1166f6:	4c 89 cf             	mov    %r9,%rdi
  1166f9:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  1166fd:	4c 89 fe             	mov    %r15,%rsi
  116700:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  116704:	e8 67 08 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  116709:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  11670d:	4c 8d 1d 2c ad 04 00 	lea    0x4ad2c(%rip),%r11        # 161440 <_ZL17kSuppressionTypes+0x19f0>
  116714:	4c 8d 15 45 ad 04 00 	lea    0x4ad45(%rip),%r10        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  11671b:	4c 8d 0d 4e ad 04 00 	lea    0x4ad4e(%rip),%r9        # 161470 <_ZL17kSuppressionTypes+0x1a20>
  116722:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  116726:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  11672a:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  11672e:	e9 9a fe ff ff       	jmp    1165cd <pqcrystals_kyber768_ref_poly_tomsg+0xe5>
  116733:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  116737:	48 8d 3d 52 ad 04 00 	lea    0x4ad52(%rip),%rdi        # 161490 <_ZL17kSuppressionTypes+0x1a40>
  11673e:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  116742:	48 8b 75 c0          	mov    -0x40(%rbp),%rsi
  116746:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  11674a:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  11674e:	e8 6d 3e ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  116753:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  116757:	4c 8d 1d e2 ac 04 00 	lea    0x4ace2(%rip),%r11        # 161440 <_ZL17kSuppressionTypes+0x19f0>
  11675e:	4c 8d 15 fb ac 04 00 	lea    0x4acfb(%rip),%r10        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  116765:	4c 8d 0d 04 ad 04 00 	lea    0x4ad04(%rip),%r9        # 161470 <_ZL17kSuppressionTypes+0x1a20>
  11676c:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  116770:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  116774:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  116778:	e9 9d fe ff ff       	jmp    11661a <pqcrystals_kyber768_ref_poly_tomsg+0x132>
  11677d:	89 d1                	mov    %edx,%ecx
  11677f:	80 e1 07             	and    $0x7,%cl
  116782:	38 c1                	cmp    %al,%cl
  116784:	0f 8c 0a fe ff ff    	jl     116594 <pqcrystals_kyber768_ref_poly_tomsg+0xac>
  11678a:	e9 ae 00 00 00       	jmp    11683d <pqcrystals_kyber768_ref_poly_tomsg+0x355>
  11678f:	49 89 ff             	mov    %rdi,%r15
  116792:	48 8d 3d 77 ac 04 00 	lea    0x4ac77(%rip),%rdi        # 161410 <_ZL17kSuppressionTypes+0x19c0>
  116799:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11679d:	4c 89 fe             	mov    %r15,%rsi
  1167a0:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  1167a4:	4c 89 cb             	mov    %r9,%rbx
  1167a7:	4d 89 de             	mov    %r11,%r14
  1167aa:	e8 11 3e ff ff       	call   10a5c0 <__ubsan_handle_pointer_overflow>
  1167af:	4d 89 f3             	mov    %r14,%r11
  1167b2:	4c 8d 15 a7 ac 04 00 	lea    0x4aca7(%rip),%r10        # 161460 <_ZL17kSuppressionTypes+0x1a10>
  1167b9:	49 89 d9             	mov    %rbx,%r9
  1167bc:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  1167c0:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  1167c4:	4c 89 ff             	mov    %r15,%rdi
  1167c7:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  1167cb:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1167cf:	48 85 ff             	test   %rdi,%rdi
  1167d2:	0f 85 a5 fd ff ff    	jne    11657d <pqcrystals_kyber768_ref_poly_tomsg+0x95>
  1167d8:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  1167dc:	48 8d 3d 3d ac 04 00 	lea    0x4ac3d(%rip),%rdi        # 161420 <_ZL17kSuppressionTypes+0x19d0>
  1167e3:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  1167e7:	48 89 d6             	mov    %rdx,%rsi
  1167ea:	4d 89 c7             	mov    %r8,%r15
  1167ed:	4c 89 cb             	mov    %r9,%rbx
  1167f0:	4d 89 d6             	mov    %r10,%r14
  1167f3:	e8 78 07 ff ff       	call   106f70 <__ubsan_handle_type_mismatch_v1>
  1167f8:	4c 8d 1d 41 ac 04 00 	lea    0x4ac41(%rip),%r11        # 161440 <_ZL17kSuppressionTypes+0x19f0>
  1167ff:	4d 89 f2             	mov    %r14,%r10
  116802:	49 89 d9             	mov    %rbx,%r9
  116805:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  116809:	4d 89 f8             	mov    %r15,%r8
  11680c:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  116810:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  116814:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  116818:	e9 60 fd ff ff       	jmp    11657d <pqcrystals_kyber768_ref_poly_tomsg+0x95>
  11681d:	48 83 c4 38          	add    $0x38,%rsp
  116821:	5b                   	pop    %rbx
  116822:	41 5c                	pop    %r12
  116824:	41 5d                	pop    %r13
  116826:	41 5e                	pop    %r14
  116828:	41 5f                	pop    %r15
  11682a:	5d                   	pop    %rbp
  11682b:	c3                   	ret
  11682c:	4c 89 ff             	mov    %r15,%rdi
  11682f:	e8 6c f4 fb ff       	call   d5ca0 <__asan_report_load2>
  116834:	48 8b 7d b0          	mov    -0x50(%rbp),%rdi
  116838:	e8 a3 f3 fb ff       	call   d5be0 <__asan_report_load1>
  11683d:	48 89 d7             	mov    %rdx,%rdi
  116840:	e8 5b f7 fb ff       	call   d5fa0 <__asan_report_store1>

Disassembly of section .fini:
