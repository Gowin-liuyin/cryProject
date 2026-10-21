0000000000004660 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4660:	push   %rbp
    4661:	mov    %rsp,%rbp
    4664:	add    $0xe,%rdi
    4668:	xor    %eax,%eax
    466a:	jmp    4684 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x24>
    466c:	nopl   0x0(%rax)
    4670:	mov    %cx,(%rdi)
    4673:	inc    %rax
    4676:	add    $0x10,%rdi
    467a:	cmp    $0x20,%rax
    467e:	je     47d2 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x172>
    4684:	testb  $0x1,(%rsi,%rax,1)
    4688:	mov    $0x0,%ecx
    468d:	jne    4720 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xc0>
    4693:	mov    %cx,-0xe(%rdi)
    4697:	testb  $0x2,(%rsi,%rax,1)
    469b:	mov    $0x0,%ecx
    46a0:	jne    4738 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xd8>
    46a6:	mov    %cx,-0xc(%rdi)
    46aa:	testb  $0x4,(%rsi,%rax,1)
    46ae:	mov    $0x0,%ecx
    46b3:	jne    4750 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xf0>
    46b9:	mov    %cx,-0xa(%rdi)
    46bd:	testb  $0x8,(%rsi,%rax,1)
    46c1:	mov    $0x0,%ecx
    46c6:	jne    4768 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x108>
    46cc:	mov    %cx,-0x8(%rdi)
    46d0:	testb  $0x10,(%rsi,%rax,1)
    46d4:	mov    $0x0,%ecx
    46d9:	jne    4780 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x120>
    46df:	mov    %cx,-0x6(%rdi)
    46e3:	testb  $0x20,(%rsi,%rax,1)
    46e7:	mov    $0x0,%ecx
    46ec:	jne    4798 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x138>
    46f2:	mov    %cx,-0x4(%rdi)
    46f6:	testb  $0x40,(%rsi,%rax,1)
    46fa:	mov    $0x0,%ecx
    46ff:	jne    47b0 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x150>
    4705:	mov    %cx,-0x2(%rdi)
    4709:	cmpb   $0x0,(%rsi,%rax,1)
    470d:	mov    $0x0,%ecx
    4712:	jns    4670 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x10>
    4718:	jmp    47c8 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x168>
    471d:	nopl   (%rax)
    4720:	mov    $0x681,%ecx
    4725:	mov    %cx,-0xe(%rdi)
    4729:	testb  $0x2,(%rsi,%rax,1)
    472d:	mov    $0x0,%ecx
    4732:	je     46a6 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x46>
    4738:	mov    $0x681,%ecx
    473d:	mov    %cx,-0xc(%rdi)
    4741:	testb  $0x4,(%rsi,%rax,1)
    4745:	mov    $0x0,%ecx
    474a:	je     46b9 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x59>
    4750:	mov    $0x681,%ecx
    4755:	mov    %cx,-0xa(%rdi)
    4759:	testb  $0x8,(%rsi,%rax,1)
    475d:	mov    $0x0,%ecx
    4762:	je     46cc <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x6c>
    4768:	mov    $0x681,%ecx
    476d:	mov    %cx,-0x8(%rdi)
    4771:	testb  $0x10,(%rsi,%rax,1)
    4775:	mov    $0x0,%ecx
    477a:	je     46df <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x7f>
    4780:	mov    $0x681,%ecx
    4785:	mov    %cx,-0x6(%rdi)
    4789:	testb  $0x20,(%rsi,%rax,1)
    478d:	mov    $0x0,%ecx
    4792:	je     46f2 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x92>
    4798:	mov    $0x681,%ecx
    479d:	mov    %cx,-0x4(%rdi)
    47a1:	testb  $0x40,(%rsi,%rax,1)
    47a5:	mov    $0x0,%ecx
    47aa:	je     4705 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xa5>
    47b0:	mov    $0x681,%ecx
    47b5:	mov    %cx,-0x2(%rdi)
    47b9:	cmpb   $0x0,(%rsi,%rax,1)
    47bd:	mov    $0x0,%ecx
    47c2:	jns    4670 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x10>
    47c8:	mov    $0x681,%ecx
    47cd:	jmp    4670 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x10>
    47d2:	pop    %rbp
    47d3:	ret
    47d4:	data16 data16 cs nopw 0x0(%rax,%rax,1)
