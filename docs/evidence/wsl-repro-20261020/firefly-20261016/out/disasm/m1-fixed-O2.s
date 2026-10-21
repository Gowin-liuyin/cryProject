0000000000004680 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4680:	push   %rbp
    4681:	mov    %rsp,%rbp
    4684:	push   %r15
    4686:	push   %r14
    4688:	push   %rbx
    4689:	push   %rax
    468a:	mov    %rsi,%rbx
    468d:	mov    %rdi,%r14
    4690:	xor    %r15d,%r15d
    4693:	data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
    46a0:	lea    (%r14,%r15,1),%rdi
    46a4:	movw   $0x0,(%r14,%r15,1)
    46ab:	movzbl (%rbx),%edx
    46ae:	and    $0x1,%edx
    46b1:	mov    $0x681,%esi
    46b6:	call   2de0 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    46bb:	lea    (%r14,%r15,1),%rdi
    46bf:	add    $0x2,%rdi
    46c3:	movw   $0x0,0x2(%r14,%r15,1)
    46cb:	movzbl (%rbx),%edx
    46ce:	shr    $1,%edx
    46d0:	and    $0x1,%edx
    46d3:	mov    $0x681,%esi
    46d8:	call   2de0 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    46dd:	lea    (%r14,%r15,1),%rdi
    46e1:	add    $0x4,%rdi
    46e5:	movw   $0x0,0x4(%r14,%r15,1)
    46ed:	movzbl (%rbx),%edx
    46f0:	shr    $0x2,%edx
    46f3:	and    $0x1,%edx
    46f6:	mov    $0x681,%esi
    46fb:	call   2de0 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4700:	lea    (%r14,%r15,1),%rdi
    4704:	add    $0x6,%rdi
    4708:	movw   $0x0,0x6(%r14,%r15,1)
    4710:	movzbl (%rbx),%edx
    4713:	shr    $0x3,%edx
    4716:	and    $0x1,%edx
    4719:	mov    $0x681,%esi
    471e:	call   2de0 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4723:	lea    (%r14,%r15,1),%rdi
    4727:	add    $0x8,%rdi
    472b:	movw   $0x0,0x8(%r14,%r15,1)
    4733:	movzbl (%rbx),%edx
    4736:	shr    $0x4,%edx
    4739:	and    $0x1,%edx
    473c:	mov    $0x681,%esi
    4741:	call   2de0 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4746:	lea    (%r14,%r15,1),%rdi
    474a:	add    $0xa,%rdi
    474e:	movw   $0x0,0xa(%r14,%r15,1)
    4756:	movzbl (%rbx),%edx
    4759:	shr    $0x5,%edx
    475c:	and    $0x1,%edx
    475f:	mov    $0x681,%esi
    4764:	call   2de0 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4769:	lea    (%r14,%r15,1),%rdi
    476d:	add    $0xc,%rdi
    4771:	movw   $0x0,0xc(%r14,%r15,1)
    4779:	movzbl (%rbx),%edx
    477c:	shr    $0x6,%edx
    477f:	and    $0x1,%edx
    4782:	mov    $0x681,%esi
    4787:	call   2de0 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    478c:	lea    (%r14,%r15,1),%rdi
    4790:	add    $0xe,%rdi
    4794:	movw   $0x0,0xe(%r14,%r15,1)
    479c:	movzbl (%rbx),%edx
    479f:	shr    $0x7,%edx
    47a2:	mov    $0x681,%esi
    47a7:	call   2de0 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    47ac:	inc    %rbx
    47af:	add    $0x10,%r15
    47b3:	cmp    $0x200,%r15
    47ba:	jne    46a0 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x20>
    47c0:	add    $0x8,%rsp
    47c4:	pop    %rbx
    47c5:	pop    %r14
    47c7:	pop    %r15
    47c9:	pop    %rbp
    47ca:	ret
    47cb:	nopl   0x0(%rax,%rax,1)
