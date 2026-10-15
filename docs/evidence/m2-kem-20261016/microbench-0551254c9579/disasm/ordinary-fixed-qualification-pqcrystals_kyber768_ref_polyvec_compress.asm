
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/qualification/fixed/m2_hotspot_qualification：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

000000000000499c <pqcrystals_kyber768_ref_polyvec_compress>:
    499c:	31 c0                	xor    %eax,%eax
    499e:	b9 37 d5 09 80       	mov    $0x8009d537,%ecx
    49a3:	48 83 f8 03          	cmp    $0x3,%rax
    49a7:	0f 84 ce 00 00 00    	je     4a7b <pqcrystals_kyber768_ref_polyvec_compress+0xdf>
    49ad:	48 89 f2             	mov    %rsi,%rdx
    49b0:	45 31 c0             	xor    %r8d,%r8d
    49b3:	49 83 f8 40          	cmp    $0x40,%r8
    49b7:	0f 84 af 00 00 00    	je     4a6c <pqcrystals_kyber768_ref_polyvec_compress+0xd0>
    49bd:	45 31 c9             	xor    %r9d,%r9d
    49c0:	49 83 f9 04          	cmp    $0x4,%r9
    49c4:	74 3a                	je     4a00 <pqcrystals_kyber768_ref_polyvec_compress+0x64>
    49c6:	46 0f bf 14 4a       	movswl (%rdx,%r9,2),%r10d
    49cb:	45 89 d3             	mov    %r10d,%r11d
    49ce:	41 c1 eb 0f          	shr    $0xf,%r11d
    49d2:	41 81 e3 01 0d 00 00 	and    $0xd01,%r11d
    49d9:	45 01 d3             	add    %r10d,%r11d
    49dc:	45 0f b7 d3          	movzwl %r11w,%r10d
    49e0:	4d 69 d2 00 dc be 4e 	imul   $0x4ebedc00,%r10,%r10
    49e7:	49 01 ca             	add    %rcx,%r10
    49ea:	49 c1 ea 20          	shr    $0x20,%r10
    49ee:	41 81 e2 ff 03 00 00 	and    $0x3ff,%r10d
    49f5:	66 46 89 54 4c f8    	mov    %r10w,-0x8(%rsp,%r9,2)
    49fb:	49 ff c1             	inc    %r9
    49fe:	eb c0                	jmp    49c0 <pqcrystals_kyber768_ref_polyvec_compress+0x24>
    4a00:	44 8a 4c 24 f8       	mov    -0x8(%rsp),%r9b
    4a05:	44 88 0f             	mov    %r9b,(%rdi)
    4a08:	44 8a 4c 24 fa       	mov    -0x6(%rsp),%r9b
    4a0d:	41 c0 e1 02          	shl    $0x2,%r9b
    4a11:	44 0a 4c 24 f9       	or     -0x7(%rsp),%r9b
    4a16:	44 88 4f 01          	mov    %r9b,0x1(%rdi)
    4a1a:	44 0f b7 4c 24 fa    	movzwl -0x6(%rsp),%r9d
    4a20:	41 c1 e9 06          	shr    $0x6,%r9d
    4a24:	44 8a 54 24 fc       	mov    -0x4(%rsp),%r10b
    4a29:	41 c0 e2 04          	shl    $0x4,%r10b
    4a2d:	45 08 ca             	or     %r9b,%r10b
    4a30:	44 88 57 02          	mov    %r10b,0x2(%rdi)
    4a34:	44 0f b7 4c 24 fc    	movzwl -0x4(%rsp),%r9d
    4a3a:	41 c1 e9 04          	shr    $0x4,%r9d
    4a3e:	44 8a 54 24 fe       	mov    -0x2(%rsp),%r10b
    4a43:	41 c0 e2 06          	shl    $0x6,%r10b
    4a47:	45 08 ca             	or     %r9b,%r10b
    4a4a:	44 88 57 03          	mov    %r10b,0x3(%rdi)
    4a4e:	44 0f b7 4c 24 fe    	movzwl -0x2(%rsp),%r9d
    4a54:	41 c1 e9 02          	shr    $0x2,%r9d
    4a58:	44 88 4f 04          	mov    %r9b,0x4(%rdi)
    4a5c:	48 83 c7 05          	add    $0x5,%rdi
    4a60:	49 ff c0             	inc    %r8
    4a63:	48 83 c2 08          	add    $0x8,%rdx
    4a67:	e9 47 ff ff ff       	jmp    49b3 <pqcrystals_kyber768_ref_polyvec_compress+0x17>
    4a6c:	48 ff c0             	inc    %rax
    4a6f:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    4a76:	e9 28 ff ff ff       	jmp    49a3 <pqcrystals_kyber768_ref_polyvec_compress+0x7>
    4a7b:	c3                   	ret

Disassembly of section .fini:
