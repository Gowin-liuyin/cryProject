
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-sanitize/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000001106d8 <mlkem_decapsulate>:
  1106d8:	55                   	push   %rbp
  1106d9:	48 89 e5             	mov    %rsp,%rbp
  1106dc:	49 81 f9 60 09 00 00 	cmp    $0x960,%r9
  1106e3:	75 2a                	jne    11070f <mlkem_decapsulate+0x37>
  1106e5:	48 81 f9 40 04 00 00 	cmp    $0x440,%rcx
  1106ec:	75 21                	jne    11070f <mlkem_decapsulate+0x37>
  1106ee:	48 83 fe 20          	cmp    $0x20,%rsi
  1106f2:	75 1b                	jne    11070f <mlkem_decapsulate+0x37>
  1106f4:	48 85 ff             	test   %rdi,%rdi
  1106f7:	74 16                	je     11070f <mlkem_decapsulate+0x37>
  1106f9:	48 85 d2             	test   %rdx,%rdx
  1106fc:	74 11                	je     11070f <mlkem_decapsulate+0x37>
  1106fe:	4d 85 c0             	test   %r8,%r8
  110701:	74 0c                	je     11070f <mlkem_decapsulate+0x37>
  110703:	48 89 d6             	mov    %rdx,%rsi
  110706:	4c 89 c2             	mov    %r8,%rdx
  110709:	5d                   	pop    %rbp
  11070a:	e9 29 25 00 00       	jmp    112c38 <pqcrystals_kyber768_ref_dec>
  11070f:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
  110714:	5d                   	pop    %rbp
  110715:	c3                   	ret

Disassembly of section .fini:
