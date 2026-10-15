
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000004af4 <pqcrystals_kyber768_ref_polyvec_compress>:
    4af4:	31 c9                	xor    %ecx,%ecx
    4af6:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    4afc:	48 83 f9 03          	cmp    $0x3,%rcx
    4b00:	0f 84 ae 00 00 00    	je     4bb4 <pqcrystals_kyber768_ref_polyvec_compress+0xc0>
    4b06:	49 89 f1             	mov    %rsi,%r9
    4b09:	45 31 d2             	xor    %r10d,%r10d
    4b0c:	49 83 fa 40          	cmp    $0x40,%r10
    4b10:	0f 84 8f 00 00 00    	je     4ba5 <pqcrystals_kyber768_ref_polyvec_compress+0xb1>
    4b16:	45 31 db             	xor    %r11d,%r11d
    4b19:	49 83 fb 04          	cmp    $0x4,%r11
    4b1d:	74 2f                	je     4b4e <pqcrystals_kyber768_ref_polyvec_compress+0x5a>
    4b1f:	43 0f bf 04 59       	movswl (%r9,%r11,2),%eax
    4b24:	89 c2                	mov    %eax,%edx
    4b26:	c1 ea 0f             	shr    $0xf,%edx
    4b29:	44 21 c2             	and    %r8d,%edx
    4b2c:	01 c2                	add    %eax,%edx
    4b2e:	0f b7 c2             	movzwl %dx,%eax
    4b31:	c1 e0 0a             	shl    $0xa,%eax
    4b34:	05 80 06 00 00       	add    $0x680,%eax
    4b39:	31 d2                	xor    %edx,%edx
    4b3b:	41 f7 f0             	div    %r8d
    4b3e:	25 ff 03 00 00       	and    $0x3ff,%eax
    4b43:	66 42 89 44 5c f8    	mov    %ax,-0x8(%rsp,%r11,2)
    4b49:	49 ff c3             	inc    %r11
    4b4c:	eb cb                	jmp    4b19 <pqcrystals_kyber768_ref_polyvec_compress+0x25>
    4b4e:	8a 44 24 f8          	mov    -0x8(%rsp),%al
    4b52:	88 07                	mov    %al,(%rdi)
    4b54:	8a 44 24 fa          	mov    -0x6(%rsp),%al
    4b58:	c0 e0 02             	shl    $0x2,%al
    4b5b:	0a 44 24 f9          	or     -0x7(%rsp),%al
    4b5f:	88 47 01             	mov    %al,0x1(%rdi)
    4b62:	0f b7 44 24 fa       	movzwl -0x6(%rsp),%eax
    4b67:	c1 e8 06             	shr    $0x6,%eax
    4b6a:	8a 54 24 fc          	mov    -0x4(%rsp),%dl
    4b6e:	c0 e2 04             	shl    $0x4,%dl
    4b71:	08 c2                	or     %al,%dl
    4b73:	88 57 02             	mov    %dl,0x2(%rdi)
    4b76:	0f b7 44 24 fc       	movzwl -0x4(%rsp),%eax
    4b7b:	c1 e8 04             	shr    $0x4,%eax
    4b7e:	8a 54 24 fe          	mov    -0x2(%rsp),%dl
    4b82:	c0 e2 06             	shl    $0x6,%dl
    4b85:	08 c2                	or     %al,%dl
    4b87:	88 57 03             	mov    %dl,0x3(%rdi)
    4b8a:	0f b7 44 24 fe       	movzwl -0x2(%rsp),%eax
    4b8f:	c1 e8 02             	shr    $0x2,%eax
    4b92:	88 47 04             	mov    %al,0x4(%rdi)
    4b95:	48 83 c7 05          	add    $0x5,%rdi
    4b99:	49 ff c2             	inc    %r10
    4b9c:	49 83 c1 08          	add    $0x8,%r9
    4ba0:	e9 67 ff ff ff       	jmp    4b0c <pqcrystals_kyber768_ref_polyvec_compress+0x18>
    4ba5:	48 ff c1             	inc    %rcx
    4ba8:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    4baf:	e9 48 ff ff ff       	jmp    4afc <pqcrystals_kyber768_ref_polyvec_compress+0x8>
    4bb4:	c3                   	ret

Disassembly of section .fini:
