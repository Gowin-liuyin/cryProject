
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000053d4 <pqcrystals_kyber768_ref_polyvec_compress>:
    53d4:	31 c9                	xor    %ecx,%ecx
    53d6:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    53dc:	48 83 f9 03          	cmp    $0x3,%rcx
    53e0:	0f 84 ae 00 00 00    	je     5494 <pqcrystals_kyber768_ref_polyvec_compress+0xc0>
    53e6:	49 89 f1             	mov    %rsi,%r9
    53e9:	45 31 d2             	xor    %r10d,%r10d
    53ec:	49 83 fa 40          	cmp    $0x40,%r10
    53f0:	0f 84 8f 00 00 00    	je     5485 <pqcrystals_kyber768_ref_polyvec_compress+0xb1>
    53f6:	45 31 db             	xor    %r11d,%r11d
    53f9:	49 83 fb 04          	cmp    $0x4,%r11
    53fd:	74 2f                	je     542e <pqcrystals_kyber768_ref_polyvec_compress+0x5a>
    53ff:	43 0f bf 04 59       	movswl (%r9,%r11,2),%eax
    5404:	89 c2                	mov    %eax,%edx
    5406:	c1 ea 0f             	shr    $0xf,%edx
    5409:	44 21 c2             	and    %r8d,%edx
    540c:	01 c2                	add    %eax,%edx
    540e:	0f b7 c2             	movzwl %dx,%eax
    5411:	c1 e0 0a             	shl    $0xa,%eax
    5414:	05 80 06 00 00       	add    $0x680,%eax
    5419:	31 d2                	xor    %edx,%edx
    541b:	41 f7 f0             	div    %r8d
    541e:	25 ff 03 00 00       	and    $0x3ff,%eax
    5423:	66 42 89 44 5c f8    	mov    %ax,-0x8(%rsp,%r11,2)
    5429:	49 ff c3             	inc    %r11
    542c:	eb cb                	jmp    53f9 <pqcrystals_kyber768_ref_polyvec_compress+0x25>
    542e:	8a 44 24 f8          	mov    -0x8(%rsp),%al
    5432:	88 07                	mov    %al,(%rdi)
    5434:	8a 44 24 fa          	mov    -0x6(%rsp),%al
    5438:	c0 e0 02             	shl    $0x2,%al
    543b:	0a 44 24 f9          	or     -0x7(%rsp),%al
    543f:	88 47 01             	mov    %al,0x1(%rdi)
    5442:	0f b7 44 24 fa       	movzwl -0x6(%rsp),%eax
    5447:	c1 e8 06             	shr    $0x6,%eax
    544a:	8a 54 24 fc          	mov    -0x4(%rsp),%dl
    544e:	c0 e2 04             	shl    $0x4,%dl
    5451:	08 c2                	or     %al,%dl
    5453:	88 57 02             	mov    %dl,0x2(%rdi)
    5456:	0f b7 44 24 fc       	movzwl -0x4(%rsp),%eax
    545b:	c1 e8 04             	shr    $0x4,%eax
    545e:	8a 54 24 fe          	mov    -0x2(%rsp),%dl
    5462:	c0 e2 06             	shl    $0x6,%dl
    5465:	08 c2                	or     %al,%dl
    5467:	88 57 03             	mov    %dl,0x3(%rdi)
    546a:	0f b7 44 24 fe       	movzwl -0x2(%rsp),%eax
    546f:	c1 e8 02             	shr    $0x2,%eax
    5472:	88 47 04             	mov    %al,0x4(%rdi)
    5475:	48 83 c7 05          	add    $0x5,%rdi
    5479:	49 ff c2             	inc    %r10
    547c:	49 83 c1 08          	add    $0x8,%r9
    5480:	e9 67 ff ff ff       	jmp    53ec <pqcrystals_kyber768_ref_polyvec_compress+0x18>
    5485:	48 ff c1             	inc    %rcx
    5488:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    548f:	e9 48 ff ff ff       	jmp    53dc <pqcrystals_kyber768_ref_polyvec_compress+0x8>
    5494:	c3                   	ret

Disassembly of section .fini:
