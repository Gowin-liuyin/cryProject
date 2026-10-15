
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/qualification/unfixed/m2_hotspot_qualification：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000049a4 <pqcrystals_kyber768_ref_polyvec_compress>:
    49a4:	31 c9                	xor    %ecx,%ecx
    49a6:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    49ac:	48 83 f9 03          	cmp    $0x3,%rcx
    49b0:	0f 84 ae 00 00 00    	je     4a64 <pqcrystals_kyber768_ref_polyvec_compress+0xc0>
    49b6:	49 89 f1             	mov    %rsi,%r9
    49b9:	45 31 d2             	xor    %r10d,%r10d
    49bc:	49 83 fa 40          	cmp    $0x40,%r10
    49c0:	0f 84 8f 00 00 00    	je     4a55 <pqcrystals_kyber768_ref_polyvec_compress+0xb1>
    49c6:	45 31 db             	xor    %r11d,%r11d
    49c9:	49 83 fb 04          	cmp    $0x4,%r11
    49cd:	74 2f                	je     49fe <pqcrystals_kyber768_ref_polyvec_compress+0x5a>
    49cf:	43 0f bf 04 59       	movswl (%r9,%r11,2),%eax
    49d4:	89 c2                	mov    %eax,%edx
    49d6:	c1 ea 0f             	shr    $0xf,%edx
    49d9:	44 21 c2             	and    %r8d,%edx
    49dc:	01 c2                	add    %eax,%edx
    49de:	0f b7 c2             	movzwl %dx,%eax
    49e1:	c1 e0 0a             	shl    $0xa,%eax
    49e4:	05 80 06 00 00       	add    $0x680,%eax
    49e9:	31 d2                	xor    %edx,%edx
    49eb:	41 f7 f0             	div    %r8d
    49ee:	25 ff 03 00 00       	and    $0x3ff,%eax
    49f3:	66 42 89 44 5c f8    	mov    %ax,-0x8(%rsp,%r11,2)
    49f9:	49 ff c3             	inc    %r11
    49fc:	eb cb                	jmp    49c9 <pqcrystals_kyber768_ref_polyvec_compress+0x25>
    49fe:	8a 44 24 f8          	mov    -0x8(%rsp),%al
    4a02:	88 07                	mov    %al,(%rdi)
    4a04:	8a 44 24 fa          	mov    -0x6(%rsp),%al
    4a08:	c0 e0 02             	shl    $0x2,%al
    4a0b:	0a 44 24 f9          	or     -0x7(%rsp),%al
    4a0f:	88 47 01             	mov    %al,0x1(%rdi)
    4a12:	0f b7 44 24 fa       	movzwl -0x6(%rsp),%eax
    4a17:	c1 e8 06             	shr    $0x6,%eax
    4a1a:	8a 54 24 fc          	mov    -0x4(%rsp),%dl
    4a1e:	c0 e2 04             	shl    $0x4,%dl
    4a21:	08 c2                	or     %al,%dl
    4a23:	88 57 02             	mov    %dl,0x2(%rdi)
    4a26:	0f b7 44 24 fc       	movzwl -0x4(%rsp),%eax
    4a2b:	c1 e8 04             	shr    $0x4,%eax
    4a2e:	8a 54 24 fe          	mov    -0x2(%rsp),%dl
    4a32:	c0 e2 06             	shl    $0x6,%dl
    4a35:	08 c2                	or     %al,%dl
    4a37:	88 57 03             	mov    %dl,0x3(%rdi)
    4a3a:	0f b7 44 24 fe       	movzwl -0x2(%rsp),%eax
    4a3f:	c1 e8 02             	shr    $0x2,%eax
    4a42:	88 47 04             	mov    %al,0x4(%rdi)
    4a45:	48 83 c7 05          	add    $0x5,%rdi
    4a49:	49 ff c2             	inc    %r10
    4a4c:	49 83 c1 08          	add    $0x8,%r9
    4a50:	e9 67 ff ff ff       	jmp    49bc <pqcrystals_kyber768_ref_polyvec_compress+0x18>
    4a55:	48 ff c1             	inc    %rcx
    4a58:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    4a5f:	e9 48 ff ff ff       	jmp    49ac <pqcrystals_kyber768_ref_polyvec_compress+0x8>
    4a64:	c3                   	ret

Disassembly of section .fini:
