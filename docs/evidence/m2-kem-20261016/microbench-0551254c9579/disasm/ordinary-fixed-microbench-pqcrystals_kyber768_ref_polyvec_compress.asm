
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/fixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000053cc <pqcrystals_kyber768_ref_polyvec_compress>:
    53cc:	31 c0                	xor    %eax,%eax
    53ce:	b9 37 d5 09 80       	mov    $0x8009d537,%ecx
    53d3:	48 83 f8 03          	cmp    $0x3,%rax
    53d7:	0f 84 ce 00 00 00    	je     54ab <pqcrystals_kyber768_ref_polyvec_compress+0xdf>
    53dd:	48 89 f2             	mov    %rsi,%rdx
    53e0:	45 31 c0             	xor    %r8d,%r8d
    53e3:	49 83 f8 40          	cmp    $0x40,%r8
    53e7:	0f 84 af 00 00 00    	je     549c <pqcrystals_kyber768_ref_polyvec_compress+0xd0>
    53ed:	45 31 c9             	xor    %r9d,%r9d
    53f0:	49 83 f9 04          	cmp    $0x4,%r9
    53f4:	74 3a                	je     5430 <pqcrystals_kyber768_ref_polyvec_compress+0x64>
    53f6:	46 0f bf 14 4a       	movswl (%rdx,%r9,2),%r10d
    53fb:	45 89 d3             	mov    %r10d,%r11d
    53fe:	41 c1 eb 0f          	shr    $0xf,%r11d
    5402:	41 81 e3 01 0d 00 00 	and    $0xd01,%r11d
    5409:	45 01 d3             	add    %r10d,%r11d
    540c:	45 0f b7 d3          	movzwl %r11w,%r10d
    5410:	4d 69 d2 00 dc be 4e 	imul   $0x4ebedc00,%r10,%r10
    5417:	49 01 ca             	add    %rcx,%r10
    541a:	49 c1 ea 20          	shr    $0x20,%r10
    541e:	41 81 e2 ff 03 00 00 	and    $0x3ff,%r10d
    5425:	66 46 89 54 4c f8    	mov    %r10w,-0x8(%rsp,%r9,2)
    542b:	49 ff c1             	inc    %r9
    542e:	eb c0                	jmp    53f0 <pqcrystals_kyber768_ref_polyvec_compress+0x24>
    5430:	44 8a 4c 24 f8       	mov    -0x8(%rsp),%r9b
    5435:	44 88 0f             	mov    %r9b,(%rdi)
    5438:	44 8a 4c 24 fa       	mov    -0x6(%rsp),%r9b
    543d:	41 c0 e1 02          	shl    $0x2,%r9b
    5441:	44 0a 4c 24 f9       	or     -0x7(%rsp),%r9b
    5446:	44 88 4f 01          	mov    %r9b,0x1(%rdi)
    544a:	44 0f b7 4c 24 fa    	movzwl -0x6(%rsp),%r9d
    5450:	41 c1 e9 06          	shr    $0x6,%r9d
    5454:	44 8a 54 24 fc       	mov    -0x4(%rsp),%r10b
    5459:	41 c0 e2 04          	shl    $0x4,%r10b
    545d:	45 08 ca             	or     %r9b,%r10b
    5460:	44 88 57 02          	mov    %r10b,0x2(%rdi)
    5464:	44 0f b7 4c 24 fc    	movzwl -0x4(%rsp),%r9d
    546a:	41 c1 e9 04          	shr    $0x4,%r9d
    546e:	44 8a 54 24 fe       	mov    -0x2(%rsp),%r10b
    5473:	41 c0 e2 06          	shl    $0x6,%r10b
    5477:	45 08 ca             	or     %r9b,%r10b
    547a:	44 88 57 03          	mov    %r10b,0x3(%rdi)
    547e:	44 0f b7 4c 24 fe    	movzwl -0x2(%rsp),%r9d
    5484:	41 c1 e9 02          	shr    $0x2,%r9d
    5488:	44 88 4f 04          	mov    %r9b,0x4(%rdi)
    548c:	48 83 c7 05          	add    $0x5,%rdi
    5490:	49 ff c0             	inc    %r8
    5493:	48 83 c2 08          	add    $0x8,%rdx
    5497:	e9 47 ff ff ff       	jmp    53e3 <pqcrystals_kyber768_ref_polyvec_compress+0x17>
    549c:	48 ff c0             	inc    %rax
    549f:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    54a6:	e9 28 ff ff ff       	jmp    53d3 <pqcrystals_kyber768_ref_polyvec_compress+0x7>
    54ab:	c3                   	ret

Disassembly of section .fini:
