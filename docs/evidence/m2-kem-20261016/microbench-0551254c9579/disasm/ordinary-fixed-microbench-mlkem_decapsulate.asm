
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/fixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003ab0 <mlkem_decapsulate>:
    3ab0:	49 81 f9 60 09 00 00 	cmp    $0x960,%r9
    3ab7:	75 29                	jne    3ae2 <mlkem_decapsulate+0x32>
    3ab9:	48 81 f9 40 04 00 00 	cmp    $0x440,%rcx
    3ac0:	75 20                	jne    3ae2 <mlkem_decapsulate+0x32>
    3ac2:	48 83 fe 20          	cmp    $0x20,%rsi
    3ac6:	75 1a                	jne    3ae2 <mlkem_decapsulate+0x32>
    3ac8:	48 85 ff             	test   %rdi,%rdi
    3acb:	74 15                	je     3ae2 <mlkem_decapsulate+0x32>
    3acd:	48 85 d2             	test   %rdx,%rdx
    3ad0:	74 10                	je     3ae2 <mlkem_decapsulate+0x32>
    3ad2:	4d 85 c0             	test   %r8,%r8
    3ad5:	74 0b                	je     3ae2 <mlkem_decapsulate+0x32>
    3ad7:	48 89 d6             	mov    %rdx,%rsi
    3ada:	4c 89 c2             	mov    %r8,%rdx
    3add:	e9 d9 0e 00 00       	jmp    49bb <pqcrystals_kyber768_ref_dec>
    3ae2:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    3ae7:	c3                   	ret

Disassembly of section .fini:
