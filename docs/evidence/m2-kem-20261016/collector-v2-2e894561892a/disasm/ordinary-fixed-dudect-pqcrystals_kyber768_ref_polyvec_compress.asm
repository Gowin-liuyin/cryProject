
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_dudect：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003f5c <pqcrystals_kyber768_ref_polyvec_compress>:
    3f5c:	31 c0                	xor    %eax,%eax
    3f5e:	b9 37 d5 09 80       	mov    $0x8009d537,%ecx
    3f63:	48 83 f8 03          	cmp    $0x3,%rax
    3f67:	0f 84 ce 00 00 00    	je     403b <pqcrystals_kyber768_ref_polyvec_compress+0xdf>
    3f6d:	48 89 f2             	mov    %rsi,%rdx
    3f70:	45 31 c0             	xor    %r8d,%r8d
    3f73:	49 83 f8 40          	cmp    $0x40,%r8
    3f77:	0f 84 af 00 00 00    	je     402c <pqcrystals_kyber768_ref_polyvec_compress+0xd0>
    3f7d:	45 31 c9             	xor    %r9d,%r9d
    3f80:	49 83 f9 04          	cmp    $0x4,%r9
    3f84:	74 3a                	je     3fc0 <pqcrystals_kyber768_ref_polyvec_compress+0x64>
    3f86:	46 0f bf 14 4a       	movswl (%rdx,%r9,2),%r10d
    3f8b:	45 89 d3             	mov    %r10d,%r11d
    3f8e:	41 c1 eb 0f          	shr    $0xf,%r11d
    3f92:	41 81 e3 01 0d 00 00 	and    $0xd01,%r11d
    3f99:	45 01 d3             	add    %r10d,%r11d
    3f9c:	45 0f b7 d3          	movzwl %r11w,%r10d
    3fa0:	4d 69 d2 00 dc be 4e 	imul   $0x4ebedc00,%r10,%r10
    3fa7:	49 01 ca             	add    %rcx,%r10
    3faa:	49 c1 ea 20          	shr    $0x20,%r10
    3fae:	41 81 e2 ff 03 00 00 	and    $0x3ff,%r10d
    3fb5:	66 46 89 54 4c f8    	mov    %r10w,-0x8(%rsp,%r9,2)
    3fbb:	49 ff c1             	inc    %r9
    3fbe:	eb c0                	jmp    3f80 <pqcrystals_kyber768_ref_polyvec_compress+0x24>
    3fc0:	44 8a 4c 24 f8       	mov    -0x8(%rsp),%r9b
    3fc5:	44 88 0f             	mov    %r9b,(%rdi)
    3fc8:	44 8a 4c 24 fa       	mov    -0x6(%rsp),%r9b
    3fcd:	41 c0 e1 02          	shl    $0x2,%r9b
    3fd1:	44 0a 4c 24 f9       	or     -0x7(%rsp),%r9b
    3fd6:	44 88 4f 01          	mov    %r9b,0x1(%rdi)
    3fda:	44 0f b7 4c 24 fa    	movzwl -0x6(%rsp),%r9d
    3fe0:	41 c1 e9 06          	shr    $0x6,%r9d
    3fe4:	44 8a 54 24 fc       	mov    -0x4(%rsp),%r10b
    3fe9:	41 c0 e2 04          	shl    $0x4,%r10b
    3fed:	45 08 ca             	or     %r9b,%r10b
    3ff0:	44 88 57 02          	mov    %r10b,0x2(%rdi)
    3ff4:	44 0f b7 4c 24 fc    	movzwl -0x4(%rsp),%r9d
    3ffa:	41 c1 e9 04          	shr    $0x4,%r9d
    3ffe:	44 8a 54 24 fe       	mov    -0x2(%rsp),%r10b
    4003:	41 c0 e2 06          	shl    $0x6,%r10b
    4007:	45 08 ca             	or     %r9b,%r10b
    400a:	44 88 57 03          	mov    %r10b,0x3(%rdi)
    400e:	44 0f b7 4c 24 fe    	movzwl -0x2(%rsp),%r9d
    4014:	41 c1 e9 02          	shr    $0x2,%r9d
    4018:	44 88 4f 04          	mov    %r9b,0x4(%rdi)
    401c:	48 83 c7 05          	add    $0x5,%rdi
    4020:	49 ff c0             	inc    %r8
    4023:	48 83 c2 08          	add    $0x8,%rdx
    4027:	e9 47 ff ff ff       	jmp    3f73 <pqcrystals_kyber768_ref_polyvec_compress+0x17>
    402c:	48 ff c0             	inc    %rax
    402f:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    4036:	e9 28 ff ff ff       	jmp    3f63 <pqcrystals_kyber768_ref_polyvec_compress+0x7>
    403b:	c3                   	ret

Disassembly of section .fini:
