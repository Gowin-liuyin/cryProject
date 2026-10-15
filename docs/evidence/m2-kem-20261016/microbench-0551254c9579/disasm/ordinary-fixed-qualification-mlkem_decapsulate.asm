
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/qualification/fixed/m2_hotspot_qualification：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003080 <mlkem_decapsulate>:
    3080:	49 81 f9 60 09 00 00 	cmp    $0x960,%r9
    3087:	75 29                	jne    30b2 <mlkem_decapsulate+0x32>
    3089:	48 81 f9 40 04 00 00 	cmp    $0x440,%rcx
    3090:	75 20                	jne    30b2 <mlkem_decapsulate+0x32>
    3092:	48 83 fe 20          	cmp    $0x20,%rsi
    3096:	75 1a                	jne    30b2 <mlkem_decapsulate+0x32>
    3098:	48 85 ff             	test   %rdi,%rdi
    309b:	74 15                	je     30b2 <mlkem_decapsulate+0x32>
    309d:	48 85 d2             	test   %rdx,%rdx
    30a0:	74 10                	je     30b2 <mlkem_decapsulate+0x32>
    30a2:	4d 85 c0             	test   %r8,%r8
    30a5:	74 0b                	je     30b2 <mlkem_decapsulate+0x32>
    30a7:	48 89 d6             	mov    %rdx,%rsi
    30aa:	4c 89 c2             	mov    %r8,%rdx
    30ad:	e9 d9 0e 00 00       	jmp    3f8b <pqcrystals_kyber768_ref_dec>
    30b2:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    30b7:	c3                   	ret

Disassembly of section .fini:
