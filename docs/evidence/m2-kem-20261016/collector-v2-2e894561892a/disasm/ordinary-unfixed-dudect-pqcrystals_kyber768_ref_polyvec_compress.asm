
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_dudect：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003f64 <pqcrystals_kyber768_ref_polyvec_compress>:
    3f64:	31 c9                	xor    %ecx,%ecx
    3f66:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    3f6c:	48 83 f9 03          	cmp    $0x3,%rcx
    3f70:	0f 84 ae 00 00 00    	je     4024 <pqcrystals_kyber768_ref_polyvec_compress+0xc0>
    3f76:	49 89 f1             	mov    %rsi,%r9
    3f79:	45 31 d2             	xor    %r10d,%r10d
    3f7c:	49 83 fa 40          	cmp    $0x40,%r10
    3f80:	0f 84 8f 00 00 00    	je     4015 <pqcrystals_kyber768_ref_polyvec_compress+0xb1>
    3f86:	45 31 db             	xor    %r11d,%r11d
    3f89:	49 83 fb 04          	cmp    $0x4,%r11
    3f8d:	74 2f                	je     3fbe <pqcrystals_kyber768_ref_polyvec_compress+0x5a>
    3f8f:	43 0f bf 04 59       	movswl (%r9,%r11,2),%eax
    3f94:	89 c2                	mov    %eax,%edx
    3f96:	c1 ea 0f             	shr    $0xf,%edx
    3f99:	44 21 c2             	and    %r8d,%edx
    3f9c:	01 c2                	add    %eax,%edx
    3f9e:	0f b7 c2             	movzwl %dx,%eax
    3fa1:	c1 e0 0a             	shl    $0xa,%eax
    3fa4:	05 80 06 00 00       	add    $0x680,%eax
    3fa9:	31 d2                	xor    %edx,%edx
    3fab:	41 f7 f0             	div    %r8d
    3fae:	25 ff 03 00 00       	and    $0x3ff,%eax
    3fb3:	66 42 89 44 5c f8    	mov    %ax,-0x8(%rsp,%r11,2)
    3fb9:	49 ff c3             	inc    %r11
    3fbc:	eb cb                	jmp    3f89 <pqcrystals_kyber768_ref_polyvec_compress+0x25>
    3fbe:	8a 44 24 f8          	mov    -0x8(%rsp),%al
    3fc2:	88 07                	mov    %al,(%rdi)
    3fc4:	8a 44 24 fa          	mov    -0x6(%rsp),%al
    3fc8:	c0 e0 02             	shl    $0x2,%al
    3fcb:	0a 44 24 f9          	or     -0x7(%rsp),%al
    3fcf:	88 47 01             	mov    %al,0x1(%rdi)
    3fd2:	0f b7 44 24 fa       	movzwl -0x6(%rsp),%eax
    3fd7:	c1 e8 06             	shr    $0x6,%eax
    3fda:	8a 54 24 fc          	mov    -0x4(%rsp),%dl
    3fde:	c0 e2 04             	shl    $0x4,%dl
    3fe1:	08 c2                	or     %al,%dl
    3fe3:	88 57 02             	mov    %dl,0x2(%rdi)
    3fe6:	0f b7 44 24 fc       	movzwl -0x4(%rsp),%eax
    3feb:	c1 e8 04             	shr    $0x4,%eax
    3fee:	8a 54 24 fe          	mov    -0x2(%rsp),%dl
    3ff2:	c0 e2 06             	shl    $0x6,%dl
    3ff5:	08 c2                	or     %al,%dl
    3ff7:	88 57 03             	mov    %dl,0x3(%rdi)
    3ffa:	0f b7 44 24 fe       	movzwl -0x2(%rsp),%eax
    3fff:	c1 e8 02             	shr    $0x2,%eax
    4002:	88 47 04             	mov    %al,0x4(%rdi)
    4005:	48 83 c7 05          	add    $0x5,%rdi
    4009:	49 ff c2             	inc    %r10
    400c:	49 83 c1 08          	add    $0x8,%r9
    4010:	e9 67 ff ff ff       	jmp    3f7c <pqcrystals_kyber768_ref_polyvec_compress+0x18>
    4015:	48 ff c1             	inc    %rcx
    4018:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    401f:	e9 48 ff ff ff       	jmp    3f6c <pqcrystals_kyber768_ref_polyvec_compress+0x8>
    4024:	c3                   	ret

Disassembly of section .fini:
