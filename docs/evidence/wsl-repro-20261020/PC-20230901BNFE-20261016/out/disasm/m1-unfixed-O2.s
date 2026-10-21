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
    467e:	je     4729 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xc9>
    4684:	testb  $0x1,(%rsi,%rax,1)
    4688:	mov    $0x0,%ecx
    468d:	je     4694 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x34>
    468f:	mov    $0x681,%ecx
    4694:	mov    %cx,-0xe(%rdi)
    4698:	testb  $0x2,(%rsi,%rax,1)
    469c:	mov    $0x0,%ecx
    46a1:	je     46a8 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x48>
    46a3:	mov    $0x681,%ecx
    46a8:	mov    %cx,-0xc(%rdi)
    46ac:	testb  $0x4,(%rsi,%rax,1)
    46b0:	mov    $0x0,%ecx
    46b5:	je     46bc <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x5c>
    46b7:	mov    $0x681,%ecx
    46bc:	mov    %cx,-0xa(%rdi)
    46c0:	testb  $0x8,(%rsi,%rax,1)
    46c4:	mov    $0x0,%ecx
    46c9:	je     46d0 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x70>
    46cb:	mov    $0x681,%ecx
    46d0:	mov    %cx,-0x8(%rdi)
    46d4:	testb  $0x10,(%rsi,%rax,1)
    46d8:	mov    $0x0,%ecx
    46dd:	je     46e4 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x84>
    46df:	mov    $0x681,%ecx
    46e4:	mov    %cx,-0x6(%rdi)
    46e8:	testb  $0x20,(%rsi,%rax,1)
    46ec:	mov    $0x0,%ecx
    46f1:	je     46f8 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x98>
    46f3:	mov    $0x681,%ecx
    46f8:	mov    %cx,-0x4(%rdi)
    46fc:	testb  $0x40,(%rsi,%rax,1)
    4700:	mov    $0x0,%ecx
    4705:	je     470c <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xac>
    4707:	mov    $0x681,%ecx
    470c:	mov    %cx,-0x2(%rdi)
    4710:	cmpb   $0x0,(%rsi,%rax,1)
    4714:	mov    $0x0,%ecx
    4719:	jns    4670 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x10>
    471f:	mov    $0x681,%ecx
    4724:	jmpq   4670 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x10>
    4729:	pop    %rbp
    472a:	retq   
    472b:	nopl   0x0(%rax,%rax,1)
