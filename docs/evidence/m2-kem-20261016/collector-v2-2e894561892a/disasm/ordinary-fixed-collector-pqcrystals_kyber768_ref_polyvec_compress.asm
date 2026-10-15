
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000004b7c <pqcrystals_kyber768_ref_polyvec_compress>:
    4b7c:	31 c0                	xor    %eax,%eax
    4b7e:	b9 37 d5 09 80       	mov    $0x8009d537,%ecx
    4b83:	48 83 f8 03          	cmp    $0x3,%rax
    4b87:	0f 84 ce 00 00 00    	je     4c5b <pqcrystals_kyber768_ref_polyvec_compress+0xdf>
    4b8d:	48 89 f2             	mov    %rsi,%rdx
    4b90:	45 31 c0             	xor    %r8d,%r8d
    4b93:	49 83 f8 40          	cmp    $0x40,%r8
    4b97:	0f 84 af 00 00 00    	je     4c4c <pqcrystals_kyber768_ref_polyvec_compress+0xd0>
    4b9d:	45 31 c9             	xor    %r9d,%r9d
    4ba0:	49 83 f9 04          	cmp    $0x4,%r9
    4ba4:	74 3a                	je     4be0 <pqcrystals_kyber768_ref_polyvec_compress+0x64>
    4ba6:	46 0f bf 14 4a       	movswl (%rdx,%r9,2),%r10d
    4bab:	45 89 d3             	mov    %r10d,%r11d
    4bae:	41 c1 eb 0f          	shr    $0xf,%r11d
    4bb2:	41 81 e3 01 0d 00 00 	and    $0xd01,%r11d
    4bb9:	45 01 d3             	add    %r10d,%r11d
    4bbc:	45 0f b7 d3          	movzwl %r11w,%r10d
    4bc0:	4d 69 d2 00 dc be 4e 	imul   $0x4ebedc00,%r10,%r10
    4bc7:	49 01 ca             	add    %rcx,%r10
    4bca:	49 c1 ea 20          	shr    $0x20,%r10
    4bce:	41 81 e2 ff 03 00 00 	and    $0x3ff,%r10d
    4bd5:	66 46 89 54 4c f8    	mov    %r10w,-0x8(%rsp,%r9,2)
    4bdb:	49 ff c1             	inc    %r9
    4bde:	eb c0                	jmp    4ba0 <pqcrystals_kyber768_ref_polyvec_compress+0x24>
    4be0:	44 8a 4c 24 f8       	mov    -0x8(%rsp),%r9b
    4be5:	44 88 0f             	mov    %r9b,(%rdi)
    4be8:	44 8a 4c 24 fa       	mov    -0x6(%rsp),%r9b
    4bed:	41 c0 e1 02          	shl    $0x2,%r9b
    4bf1:	44 0a 4c 24 f9       	or     -0x7(%rsp),%r9b
    4bf6:	44 88 4f 01          	mov    %r9b,0x1(%rdi)
    4bfa:	44 0f b7 4c 24 fa    	movzwl -0x6(%rsp),%r9d
    4c00:	41 c1 e9 06          	shr    $0x6,%r9d
    4c04:	44 8a 54 24 fc       	mov    -0x4(%rsp),%r10b
    4c09:	41 c0 e2 04          	shl    $0x4,%r10b
    4c0d:	45 08 ca             	or     %r9b,%r10b
    4c10:	44 88 57 02          	mov    %r10b,0x2(%rdi)
    4c14:	44 0f b7 4c 24 fc    	movzwl -0x4(%rsp),%r9d
    4c1a:	41 c1 e9 04          	shr    $0x4,%r9d
    4c1e:	44 8a 54 24 fe       	mov    -0x2(%rsp),%r10b
    4c23:	41 c0 e2 06          	shl    $0x6,%r10b
    4c27:	45 08 ca             	or     %r9b,%r10b
    4c2a:	44 88 57 03          	mov    %r10b,0x3(%rdi)
    4c2e:	44 0f b7 4c 24 fe    	movzwl -0x2(%rsp),%r9d
    4c34:	41 c1 e9 02          	shr    $0x2,%r9d
    4c38:	44 88 4f 04          	mov    %r9b,0x4(%rdi)
    4c3c:	48 83 c7 05          	add    $0x5,%rdi
    4c40:	49 ff c0             	inc    %r8
    4c43:	48 83 c2 08          	add    $0x8,%rdx
    4c47:	e9 47 ff ff ff       	jmp    4b93 <pqcrystals_kyber768_ref_polyvec_compress+0x17>
    4c4c:	48 ff c0             	inc    %rax
    4c4f:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    4c56:	e9 28 ff ff ff       	jmp    4b83 <pqcrystals_kyber768_ref_polyvec_compress+0x7>
    4c5b:	c3                   	ret

Disassembly of section .fini:
