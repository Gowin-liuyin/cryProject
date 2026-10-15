
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-sanitize/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000112078 <mlkem_decapsulate>:
  112078:	55                   	push   %rbp
  112079:	48 89 e5             	mov    %rsp,%rbp
  11207c:	49 81 f9 60 09 00 00 	cmp    $0x960,%r9
  112083:	75 2a                	jne    1120af <mlkem_decapsulate+0x37>
  112085:	48 81 f9 40 04 00 00 	cmp    $0x440,%rcx
  11208c:	75 21                	jne    1120af <mlkem_decapsulate+0x37>
  11208e:	48 83 fe 20          	cmp    $0x20,%rsi
  112092:	75 1b                	jne    1120af <mlkem_decapsulate+0x37>
  112094:	48 85 ff             	test   %rdi,%rdi
  112097:	74 16                	je     1120af <mlkem_decapsulate+0x37>
  112099:	48 85 d2             	test   %rdx,%rdx
  11209c:	74 11                	je     1120af <mlkem_decapsulate+0x37>
  11209e:	4d 85 c0             	test   %r8,%r8
  1120a1:	74 0c                	je     1120af <mlkem_decapsulate+0x37>
  1120a3:	48 89 d6             	mov    %rdx,%rsi
  1120a6:	4c 89 c2             	mov    %r8,%rdx
  1120a9:	5d                   	pop    %rbp
  1120aa:	e9 29 25 00 00       	jmp    1145d8 <pqcrystals_kyber768_ref_dec>
  1120af:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
  1120b4:	5d                   	pop    %rbp
  1120b5:	c3                   	ret

Disassembly of section .fini:
