
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-sanitize/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000001145d8 <pqcrystals_kyber768_ref_dec>:
  1145d8:	55                   	push   %rbp
  1145d9:	48 89 e5             	mov    %rsp,%rbp
  1145dc:	41 57                	push   %r15
  1145de:	41 56                	push   %r14
  1145e0:	41 55                	push   %r13
  1145e2:	41 54                	push   %r12
  1145e4:	53                   	push   %rbx
  1145e5:	48 83 e4 e0          	and    $0xffffffffffffffe0,%rsp
  1145e9:	48 81 ec 80 00 00 00 	sub    $0x80,%rsp
  1145f0:	48 89 e3             	mov    %rsp,%rbx
  1145f3:	49 89 d4             	mov    %rdx,%r12
  1145f6:	48 89 7b 48          	mov    %rdi,0x48(%rbx)
  1145fa:	48 8d 05 2f 3e 06 00 	lea    0x63e2f(%rip),%rax        # 178430 <__asan_option_detect_stack_use_after_return>
  114601:	83 38 00             	cmpl   $0x0,(%rax)
  114604:	48 89 73 28          	mov    %rsi,0x28(%rbx)
  114608:	74 0c                	je     114616 <pqcrystals_kyber768_ref_dec+0x3e>
  11460a:	bf a0 05 00 00       	mov    $0x5a0,%edi
  11460f:	e8 2c f7 f2 ff       	call   43d40 <__asan_stack_malloc_5>
  114614:	eb 02                	jmp    114618 <pqcrystals_kyber768_ref_dec+0x40>
  114616:	31 c0                	xor    %eax,%eax
  114618:	49 89 c6             	mov    %rax,%r14
  11461b:	48 89 43 50          	mov    %rax,0x50(%rbx)
  11461f:	48 85 c0             	test   %rax,%rax
  114622:	75 11                	jne    114635 <pqcrystals_kyber768_ref_dec+0x5d>
  114624:	49 89 e6             	mov    %rsp,%r14
  114627:	49 81 c6 60 fa ff ff 	add    $0xfffffffffffffa60,%r14
  11462e:	49 83 e6 e0          	and    $0xffffffffffffffe0,%r14
  114632:	4c 89 f4             	mov    %r14,%rsp
  114635:	48 b9 f8 f8 f8 f8 f8 	movabs $0xf8f8f8f8f8f8f8f8,%rcx
  11463c:	f8 f8 f8 
  11463f:	4c 89 73 58          	mov    %r14,0x58(%rbx)
  114643:	4d 8d 7e 20          	lea    0x20(%r14),%r15
  114647:	49 c7 06 b3 8a b5 41 	movq   $0x41b58ab3,(%r14)
  11464e:	48 8d 05 52 15 02 00 	lea    0x21552(%rip),%rax        # 135ba7 <_ZN11__sanitizerL10kExtraRegsE+0x129f7>
  114655:	49 89 46 08          	mov    %rax,0x8(%r14)
  114659:	48 8d 05 78 ff ff ff 	lea    -0x88(%rip),%rax        # 1145d8 <pqcrystals_kyber768_ref_dec>
  114660:	49 89 46 10          	mov    %rax,0x10(%r14)
  114664:	4d 89 f5             	mov    %r14,%r13
  114667:	49 c1 ed 03          	shr    $0x3,%r13
  11466b:	48 8d 81 f9 f8 f8 f8 	lea    -0x7070707(%rcx),%rax
  114672:	49 89 85 00 80 ff 7f 	mov    %rax,0x7fff8000(%r13)
  114679:	48 b8 f8 f8 f8 f8 f2 	movabs $0xf2f2f2f2f8f8f8f8,%rax
  114680:	f2 f2 f2 
  114683:	49 89 85 08 80 ff 7f 	mov    %rax,0x7fff8008(%r13)
  11468a:	49 89 8d 10 80 ff 7f 	mov    %rcx,0x7fff8010(%r13)
  114691:	41 c7 85 18 80 ff 7f 	movl   $0xf2f2f2f2,0x7fff8018(%r13)
  114698:	f2 f2 f2 f2 
  11469c:	49 8d bd 1c 80 ff 7f 	lea    0x7fff801c(%r13),%rdi
  1146a3:	48 89 7b 10          	mov    %rdi,0x10(%rbx)
  1146a7:	be 88 00 00 00       	mov    $0x88,%esi
  1146ac:	e8 ef cb fb ff       	call   d12a0 <__asan_set_shadow_f8>
  1146b1:	48 b8 f3 f3 f3 f3 f3 	movabs $0xf3f3f3f3f3f3f3f3,%rax
  1146b8:	f3 f3 f3 
  1146bb:	49 89 85 a4 80 ff 7f 	mov    %rax,0x7fff80a4(%r13)
  1146c2:	49 89 85 ac 80 ff 7f 	mov    %rax,0x7fff80ac(%r13)
  1146c9:	49 c7 85 04 80 ff 7f 	movq   $0x0,0x7fff8004(%r13)
  1146d0:	00 00 00 00 
  1146d4:	4c 89 6b 30          	mov    %r13,0x30(%rbx)
  1146d8:	49 c7 85 10 80 ff 7f 	movq   $0x0,0x7fff8010(%r13)
  1146df:	00 00 00 00 
  1146e3:	be 88 00 00 00       	mov    $0x88,%esi
  1146e8:	48 8b 7b 10          	mov    0x10(%rbx),%rdi
  1146ec:	e8 2f ca fb ff       	call   d1120 <__asan_set_shadow_00>
  1146f1:	4d 8d ac 24 80 04 00 	lea    0x480(%r12),%r13
  1146f8:	00 
  1146f9:	4d 85 e4             	test   %r12,%r12
  1146fc:	0f 84 4c 02 00 00    	je     11494e <pqcrystals_kyber768_ref_dec+0x376>
  114702:	49 81 fc 7f fb ff ff 	cmp    $0xfffffffffffffb7f,%r12
  114709:	0f 87 3f 02 00 00    	ja     11494e <pqcrystals_kyber768_ref_dec+0x376>
  11470f:	4d 85 ed             	test   %r13,%r13
  114712:	0f 84 36 02 00 00    	je     11494e <pqcrystals_kyber768_ref_dec+0x376>
  114718:	4c 89 6b 18          	mov    %r13,0x18(%rbx)
  11471c:	49 8d 86 80 00 00 00 	lea    0x80(%r14),%rax
  114723:	48 89 43 10          	mov    %rax,0x10(%rbx)
  114727:	4c 89 73 40          	mov    %r14,0x40(%rbx)
  11472b:	49 8d 86 e0 00 00 00 	lea    0xe0(%r14),%rax
  114732:	48 89 43 38          	mov    %rax,0x38(%rbx)
  114736:	48 81 43 30 00 80 ff 	addq   $0x7fff8000,0x30(%rbx)
  11473d:	7f 
  11473e:	4c 89 ff             	mov    %r15,%rdi
  114741:	48 8b 73 28          	mov    0x28(%rbx),%rsi
  114745:	4c 89 e2             	mov    %r12,%rdx
  114748:	e8 8b 18 00 00       	call   115fd8 <pqcrystals_kyber768_ref_indcpa_dec>
  11474d:	41 bd 20 09 00 00    	mov    $0x920,%r13d
  114753:	66 66 66 66 2e 0f 1f 	data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
  11475a:	84 00 00 00 00 00 
  114760:	4f 8d 34 2c          	lea    (%r12,%r13,1),%r14
  114764:	4d 85 e4             	test   %r12,%r12
  114767:	74 46                	je     1147af <pqcrystals_kyber768_ref_dec+0x1d7>
  114769:	4d 85 f6             	test   %r14,%r14
  11476c:	74 41                	je     1147af <pqcrystals_kyber768_ref_dec+0x1d7>
  11476e:	4d 39 e6             	cmp    %r12,%r14
  114771:	72 3c                	jb     1147af <pqcrystals_kyber768_ref_dec+0x1d7>
  114773:	4c 89 f0             	mov    %r14,%rax
  114776:	48 c1 e8 03          	shr    $0x3,%rax
  11477a:	0f b6 80 00 80 ff 7f 	movzbl 0x7fff8000(%rax),%eax
  114781:	84 c0                	test   %al,%al
  114783:	75 1b                	jne    1147a0 <pqcrystals_kyber768_ref_dec+0x1c8>
  114785:	43 0f b6 04 2c       	movzbl (%r12,%r13,1),%eax
  11478a:	43 88 84 2f 00 f7 ff 	mov    %al,-0x900(%r15,%r13,1)
  114791:	ff 
  114792:	49 ff c5             	inc    %r13
  114795:	49 81 fd 40 09 00 00 	cmp    $0x940,%r13
  11479c:	75 c2                	jne    114760 <pqcrystals_kyber768_ref_dec+0x188>
  11479e:	eb 23                	jmp    1147c3 <pqcrystals_kyber768_ref_dec+0x1eb>
  1147a0:	44 89 f1             	mov    %r14d,%ecx
  1147a3:	80 e1 07             	and    $0x7,%cl
  1147a6:	38 c1                	cmp    %al,%cl
  1147a8:	7c db                	jl     114785 <pqcrystals_kyber768_ref_dec+0x1ad>
  1147aa:	e9 cd 01 00 00       	jmp    11497c <pqcrystals_kyber768_ref_dec+0x3a4>
  1147af:	48 8d 3d 5a e6 04 00 	lea    0x4e65a(%rip),%rdi        # 162e10 <_ZL17kSuppressionTypes+0x13c0>
  1147b6:	4c 89 e6             	mov    %r12,%rsi
  1147b9:	4c 89 f2             	mov    %r14,%rdx
  1147bc:	e8 ff 6d ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1147c1:	eb b0                	jmp    114773 <pqcrystals_kyber768_ref_dec+0x19b>
  1147c3:	ba 40 00 00 00       	mov    $0x40,%edx
  1147c8:	4c 8b 73 10          	mov    0x10(%rbx),%r14
  1147cc:	4c 89 f7             	mov    %r14,%rdi
  1147cf:	4c 89 fe             	mov    %r15,%rsi
  1147d2:	e8 a1 d8 00 00       	call   122078 <pqcrystals_kyber_fips202_ref_sha3_512>
  1147d7:	49 8d 46 20          	lea    0x20(%r14),%rax
  1147db:	49 83 fe e0          	cmp    $0xffffffffffffffe0,%r14
  1147df:	48 89 43 20          	mov    %rax,0x20(%rbx)
  1147e3:	0f 83 1d 01 00 00    	jae    114906 <pqcrystals_kyber768_ref_dec+0x32e>
  1147e9:	4c 8b 6b 38          	mov    0x38(%rbx),%r13
  1147ed:	4c 89 ef             	mov    %r13,%rdi
  1147f0:	4c 89 fe             	mov    %r15,%rsi
  1147f3:	48 8b 53 18          	mov    0x18(%rbx),%rdx
  1147f7:	48 89 c1             	mov    %rax,%rcx
  1147fa:	e8 d9 11 00 00       	call   1159d8 <pqcrystals_kyber768_ref_indcpa_enc>
  1147ff:	ba 40 04 00 00       	mov    $0x440,%edx
  114804:	4c 8b 7b 28          	mov    0x28(%rbx),%r15
  114808:	4c 89 ff             	mov    %r15,%rdi
  11480b:	4c 89 ee             	mov    %r13,%rsi
  11480e:	e8 75 83 00 00       	call   11cb88 <pqcrystals_kyber768_ref_verify>
  114813:	89 43 18             	mov    %eax,0x18(%rbx)
  114816:	49 83 fe e0          	cmp    $0xffffffffffffffe0,%r14
  11481a:	0f 83 01 01 00 00    	jae    114921 <pqcrystals_kyber768_ref_dec+0x349>
  114820:	ba 40 04 00 00       	mov    $0x440,%edx
  114825:	48 8b 7b 20          	mov    0x20(%rbx),%rdi
  114829:	4c 89 fe             	mov    %r15,%rsi
  11482c:	e8 17 ac 00 00       	call   11f448 <pqcrystals_kyber_fips202_ref_sha3_256>
  114831:	4d 8d b4 24 60 09 00 	lea    0x960(%r12),%r14
  114838:	00 
  114839:	4d 85 e4             	test   %r12,%r12
  11483c:	0f 84 23 01 00 00    	je     114965 <pqcrystals_kyber768_ref_dec+0x38d>
  114842:	49 81 fc 9f f6 ff ff 	cmp    $0xfffffffffffff69f,%r12
  114849:	0f 87 16 01 00 00    	ja     114965 <pqcrystals_kyber768_ref_dec+0x38d>
  11484f:	4d 85 f6             	test   %r14,%r14
  114852:	0f 84 0d 01 00 00    	je     114965 <pqcrystals_kyber768_ref_dec+0x38d>
  114858:	49 8d 56 e0          	lea    -0x20(%r14),%rdx
  11485c:	49 83 fe 20          	cmp    $0x20,%r14
  114860:	4c 8b 6b 10          	mov    0x10(%rbx),%r13
  114864:	0f 82 d0 00 00 00    	jb     11493a <pqcrystals_kyber768_ref_dec+0x362>
  11486a:	48 85 d2             	test   %rdx,%rdx
  11486d:	0f 84 c7 00 00 00    	je     11493a <pqcrystals_kyber768_ref_dec+0x362>
  114873:	49 81 c4 40 09 00 00 	add    $0x940,%r12
  11487a:	0f b6 4b 18          	movzbl 0x18(%rbx),%ecx
  11487e:	ba 20 00 00 00       	mov    $0x20,%edx
  114883:	4c 89 ef             	mov    %r13,%rdi
  114886:	4c 89 e6             	mov    %r12,%rsi
  114889:	e8 2a 85 00 00       	call   11cdb8 <pqcrystals_kyber768_ref_cmov>
  11488e:	be 20 00 00 00       	mov    $0x20,%esi
  114893:	b9 40 00 00 00       	mov    $0x40,%ecx
  114898:	48 8b 7b 48          	mov    0x48(%rbx),%rdi
  11489c:	4c 89 ea             	mov    %r13,%rdx
  11489f:	e8 84 a9 00 00       	call   11f228 <pqcrystals_kyber_fips202_ref_shake256>
  1148a4:	4c 8b 73 30          	mov    0x30(%rbx),%r14
  1148a8:	49 8d 7e 1c          	lea    0x1c(%r14),%rdi
  1148ac:	be 88 00 00 00       	mov    $0x88,%esi
  1148b1:	e8 ea c9 fb ff       	call   d12a0 <__asan_set_shadow_f8>
  1148b6:	48 b8 f8 f8 f8 f8 f8 	movabs $0xf8f8f8f8f8f8f8f8,%rax
  1148bd:	f8 f8 f8 
  1148c0:	49 89 46 10          	mov    %rax,0x10(%r14)
  1148c4:	49 89 46 04          	mov    %rax,0x4(%r14)
  1148c8:	48 8b 43 40          	mov    0x40(%rbx),%rax
  1148cc:	48 c7 00 0e 36 e0 45 	movq   $0x45e0360e,(%rax)
  1148d3:	48 8b 7b 50          	mov    0x50(%rbx),%rdi
  1148d7:	48 85 ff             	test   %rdi,%rdi
  1148da:	74 0c                	je     1148e8 <pqcrystals_kyber768_ref_dec+0x310>
  1148dc:	be a0 05 00 00       	mov    $0x5a0,%esi
  1148e1:	e8 7a fb f2 ff       	call   44460 <__asan_stack_free_5>
  1148e6:	eb 0d                	jmp    1148f5 <pqcrystals_kyber768_ref_dec+0x31d>
  1148e8:	be b4 00 00 00       	mov    $0xb4,%esi
  1148ed:	4c 89 f7             	mov    %r14,%rdi
  1148f0:	e8 2b c8 fb ff       	call   d1120 <__asan_set_shadow_00>
  1148f5:	31 c0                	xor    %eax,%eax
  1148f7:	48 8d 65 d8          	lea    -0x28(%rbp),%rsp
  1148fb:	5b                   	pop    %rbx
  1148fc:	41 5c                	pop    %r12
  1148fe:	41 5d                	pop    %r13
  114900:	41 5e                	pop    %r14
  114902:	41 5f                	pop    %r15
  114904:	5d                   	pop    %rbp
  114905:	c3                   	ret
  114906:	48 8d 3d 13 e5 04 00 	lea    0x4e513(%rip),%rdi        # 162e20 <_ZL17kSuppressionTypes+0x13d0>
  11490d:	4c 89 f6             	mov    %r14,%rsi
  114910:	48 89 c2             	mov    %rax,%rdx
  114913:	e8 a8 6c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  114918:	48 8b 43 20          	mov    0x20(%rbx),%rax
  11491c:	e9 c8 fe ff ff       	jmp    1147e9 <pqcrystals_kyber768_ref_dec+0x211>
  114921:	48 8d 3d 08 e5 04 00 	lea    0x4e508(%rip),%rdi        # 162e30 <_ZL17kSuppressionTypes+0x13e0>
  114928:	48 8b 73 10          	mov    0x10(%rbx),%rsi
  11492c:	48 8b 53 20          	mov    0x20(%rbx),%rdx
  114930:	e8 8b 6c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  114935:	e9 e6 fe ff ff       	jmp    114820 <pqcrystals_kyber768_ref_dec+0x248>
  11493a:	48 8d 3d 0f e5 04 00 	lea    0x4e50f(%rip),%rdi        # 162e50 <_ZL17kSuppressionTypes+0x1400>
  114941:	4c 89 f6             	mov    %r14,%rsi
  114944:	e8 77 6c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  114949:	e9 25 ff ff ff       	jmp    114873 <pqcrystals_kyber768_ref_dec+0x29b>
  11494e:	48 8d 3d ab e4 04 00 	lea    0x4e4ab(%rip),%rdi        # 162e00 <_ZL17kSuppressionTypes+0x13b0>
  114955:	4c 89 e6             	mov    %r12,%rsi
  114958:	4c 89 ea             	mov    %r13,%rdx
  11495b:	e8 60 6c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  114960:	e9 b3 fd ff ff       	jmp    114718 <pqcrystals_kyber768_ref_dec+0x140>
  114965:	48 8d 3d d4 e4 04 00 	lea    0x4e4d4(%rip),%rdi        # 162e40 <_ZL17kSuppressionTypes+0x13f0>
  11496c:	4c 89 e6             	mov    %r12,%rsi
  11496f:	4c 89 f2             	mov    %r14,%rdx
  114972:	e8 49 6c ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  114977:	e9 dc fe ff ff       	jmp    114858 <pqcrystals_kyber768_ref_dec+0x280>
  11497c:	4c 89 f7             	mov    %r14,%rdi
  11497f:	e8 5c 22 fc ff       	call   d6be0 <__asan_report_load1>

Disassembly of section .fini:
