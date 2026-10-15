
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000004aec <pqcrystals_kyber768_ref_polyvec_compress>:
    4aec:	31 c0                	xor    %eax,%eax
    4aee:	b9 37 d5 09 80       	mov    $0x8009d537,%ecx
    4af3:	48 83 f8 03          	cmp    $0x3,%rax
    4af7:	0f 84 ce 00 00 00    	je     4bcb <pqcrystals_kyber768_ref_polyvec_compress+0xdf>
    4afd:	48 89 f2             	mov    %rsi,%rdx
    4b00:	45 31 c0             	xor    %r8d,%r8d
    4b03:	49 83 f8 40          	cmp    $0x40,%r8
    4b07:	0f 84 af 00 00 00    	je     4bbc <pqcrystals_kyber768_ref_polyvec_compress+0xd0>
    4b0d:	45 31 c9             	xor    %r9d,%r9d
    4b10:	49 83 f9 04          	cmp    $0x4,%r9
    4b14:	74 3a                	je     4b50 <pqcrystals_kyber768_ref_polyvec_compress+0x64>
    4b16:	46 0f bf 14 4a       	movswl (%rdx,%r9,2),%r10d
    4b1b:	45 89 d3             	mov    %r10d,%r11d
    4b1e:	41 c1 eb 0f          	shr    $0xf,%r11d
    4b22:	41 81 e3 01 0d 00 00 	and    $0xd01,%r11d
    4b29:	45 01 d3             	add    %r10d,%r11d
    4b2c:	45 0f b7 d3          	movzwl %r11w,%r10d
    4b30:	4d 69 d2 00 dc be 4e 	imul   $0x4ebedc00,%r10,%r10
    4b37:	49 01 ca             	add    %rcx,%r10
    4b3a:	49 c1 ea 20          	shr    $0x20,%r10
    4b3e:	41 81 e2 ff 03 00 00 	and    $0x3ff,%r10d
    4b45:	66 46 89 54 4c f8    	mov    %r10w,-0x8(%rsp,%r9,2)
    4b4b:	49 ff c1             	inc    %r9
    4b4e:	eb c0                	jmp    4b10 <pqcrystals_kyber768_ref_polyvec_compress+0x24>
    4b50:	44 8a 4c 24 f8       	mov    -0x8(%rsp),%r9b
    4b55:	44 88 0f             	mov    %r9b,(%rdi)
    4b58:	44 8a 4c 24 fa       	mov    -0x6(%rsp),%r9b
    4b5d:	41 c0 e1 02          	shl    $0x2,%r9b
    4b61:	44 0a 4c 24 f9       	or     -0x7(%rsp),%r9b
    4b66:	44 88 4f 01          	mov    %r9b,0x1(%rdi)
    4b6a:	44 0f b7 4c 24 fa    	movzwl -0x6(%rsp),%r9d
    4b70:	41 c1 e9 06          	shr    $0x6,%r9d
    4b74:	44 8a 54 24 fc       	mov    -0x4(%rsp),%r10b
    4b79:	41 c0 e2 04          	shl    $0x4,%r10b
    4b7d:	45 08 ca             	or     %r9b,%r10b
    4b80:	44 88 57 02          	mov    %r10b,0x2(%rdi)
    4b84:	44 0f b7 4c 24 fc    	movzwl -0x4(%rsp),%r9d
    4b8a:	41 c1 e9 04          	shr    $0x4,%r9d
    4b8e:	44 8a 54 24 fe       	mov    -0x2(%rsp),%r10b
    4b93:	41 c0 e2 06          	shl    $0x6,%r10b
    4b97:	45 08 ca             	or     %r9b,%r10b
    4b9a:	44 88 57 03          	mov    %r10b,0x3(%rdi)
    4b9e:	44 0f b7 4c 24 fe    	movzwl -0x2(%rsp),%r9d
    4ba4:	41 c1 e9 02          	shr    $0x2,%r9d
    4ba8:	44 88 4f 04          	mov    %r9b,0x4(%rdi)
    4bac:	48 83 c7 05          	add    $0x5,%rdi
    4bb0:	49 ff c0             	inc    %r8
    4bb3:	48 83 c2 08          	add    $0x8,%rdx
    4bb7:	e9 47 ff ff ff       	jmp    4b03 <pqcrystals_kyber768_ref_polyvec_compress+0x17>
    4bbc:	48 ff c0             	inc    %rax
    4bbf:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    4bc6:	e9 28 ff ff ff       	jmp    4af3 <pqcrystals_kyber768_ref_polyvec_compress+0x7>
    4bcb:	c3                   	ret

Disassembly of section .fini:
