
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000005044 <pqcrystals_kyber768_ref_poly_compress>:
    5044:	31 c9                	xor    %ecx,%ecx
    5046:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    504c:	48 83 f9 20          	cmp    $0x20,%rcx
    5050:	74 78                	je     50ca <pqcrystals_kyber768_ref_poly_compress+0x86>
    5052:	45 31 c9             	xor    %r9d,%r9d
    5055:	49 83 f9 08          	cmp    $0x8,%r9
    5059:	74 2b                	je     5086 <pqcrystals_kyber768_ref_poly_compress+0x42>
    505b:	42 0f bf 04 4e       	movswl (%rsi,%r9,2),%eax
    5060:	89 c2                	mov    %eax,%edx
    5062:	c1 ea 0f             	shr    $0xf,%edx
    5065:	44 21 c2             	and    %r8d,%edx
    5068:	01 c2                	add    %eax,%edx
    506a:	0f b7 c2             	movzwl %dx,%eax
    506d:	c1 e0 04             	shl    $0x4,%eax
    5070:	05 80 06 00 00       	add    $0x680,%eax
    5075:	31 d2                	xor    %edx,%edx
    5077:	41 f7 f0             	div    %r8d
    507a:	24 0f                	and    $0xf,%al
    507c:	42 88 44 0c f8       	mov    %al,-0x8(%rsp,%r9,1)
    5081:	49 ff c1             	inc    %r9
    5084:	eb cf                	jmp    5055 <pqcrystals_kyber768_ref_poly_compress+0x11>
    5086:	8a 44 24 f9          	mov    -0x7(%rsp),%al
    508a:	c0 e0 04             	shl    $0x4,%al
    508d:	0a 44 24 f8          	or     -0x8(%rsp),%al
    5091:	88 07                	mov    %al,(%rdi)
    5093:	8a 44 24 fb          	mov    -0x5(%rsp),%al
    5097:	c0 e0 04             	shl    $0x4,%al
    509a:	0a 44 24 fa          	or     -0x6(%rsp),%al
    509e:	88 47 01             	mov    %al,0x1(%rdi)
    50a1:	8a 44 24 fd          	mov    -0x3(%rsp),%al
    50a5:	c0 e0 04             	shl    $0x4,%al
    50a8:	0a 44 24 fc          	or     -0x4(%rsp),%al
    50ac:	88 47 02             	mov    %al,0x2(%rdi)
    50af:	8a 44 24 ff          	mov    -0x1(%rsp),%al
    50b3:	c0 e0 04             	shl    $0x4,%al
    50b6:	0a 44 24 fe          	or     -0x2(%rsp),%al
    50ba:	88 47 03             	mov    %al,0x3(%rdi)
    50bd:	48 83 c7 04          	add    $0x4,%rdi
    50c1:	48 ff c1             	inc    %rcx
    50c4:	48 83 c6 10          	add    $0x10,%rsi
    50c8:	eb 82                	jmp    504c <pqcrystals_kyber768_ref_poly_compress+0x8>
    50ca:	c3                   	ret

Disassembly of section .fini:
