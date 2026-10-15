
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/fixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000005044 <pqcrystals_kyber768_ref_poly_compress>:
    5044:	31 c0                	xor    %eax,%eax
    5046:	48 83 f8 20          	cmp    $0x20,%rax
    504a:	0f 84 80 00 00 00    	je     50d0 <pqcrystals_kyber768_ref_poly_compress+0x8c>
    5050:	31 c9                	xor    %ecx,%ecx
    5052:	48 83 f9 08          	cmp    $0x8,%rcx
    5056:	74 31                	je     5089 <pqcrystals_kyber768_ref_poly_compress+0x45>
    5058:	0f bf 14 4e          	movswl (%rsi,%rcx,2),%edx
    505c:	41 89 d0             	mov    %edx,%r8d
    505f:	41 c1 e8 0f          	shr    $0xf,%r8d
    5063:	41 81 e0 01 0d 00 00 	and    $0xd01,%r8d
    506a:	41 01 d0             	add    %edx,%r8d
    506d:	41 0f bf d0          	movswl %r8w,%edx
    5071:	69 d2 b0 af 13 00    	imul   $0x13afb0,%edx,%edx
    5077:	81 c2 7b 9a 00 08    	add    $0x8009a7b,%edx
    507d:	c1 ea 1c             	shr    $0x1c,%edx
    5080:	88 54 0c f8          	mov    %dl,-0x8(%rsp,%rcx,1)
    5084:	48 ff c1             	inc    %rcx
    5087:	eb c9                	jmp    5052 <pqcrystals_kyber768_ref_poly_compress+0xe>
    5089:	8a 4c 24 f9          	mov    -0x7(%rsp),%cl
    508d:	c0 e1 04             	shl    $0x4,%cl
    5090:	0a 4c 24 f8          	or     -0x8(%rsp),%cl
    5094:	88 0f                	mov    %cl,(%rdi)
    5096:	8a 4c 24 fb          	mov    -0x5(%rsp),%cl
    509a:	c0 e1 04             	shl    $0x4,%cl
    509d:	0a 4c 24 fa          	or     -0x6(%rsp),%cl
    50a1:	88 4f 01             	mov    %cl,0x1(%rdi)
    50a4:	8a 4c 24 fd          	mov    -0x3(%rsp),%cl
    50a8:	c0 e1 04             	shl    $0x4,%cl
    50ab:	0a 4c 24 fc          	or     -0x4(%rsp),%cl
    50af:	88 4f 02             	mov    %cl,0x2(%rdi)
    50b2:	8a 4c 24 ff          	mov    -0x1(%rsp),%cl
    50b6:	c0 e1 04             	shl    $0x4,%cl
    50b9:	0a 4c 24 fe          	or     -0x2(%rsp),%cl
    50bd:	88 4f 03             	mov    %cl,0x3(%rdi)
    50c0:	48 83 c7 04          	add    $0x4,%rdi
    50c4:	48 ff c0             	inc    %rax
    50c7:	48 83 c6 10          	add    $0x10,%rsi
    50cb:	e9 76 ff ff ff       	jmp    5046 <pqcrystals_kyber768_ref_poly_compress+0x2>
    50d0:	c3                   	ret

Disassembly of section .fini:
