
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_dudect：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000002640 <mlkem_decapsulate>:
    2640:	49 81 f9 60 09 00 00 	cmp    $0x960,%r9
    2647:	75 29                	jne    2672 <mlkem_decapsulate+0x32>
    2649:	48 81 f9 40 04 00 00 	cmp    $0x440,%rcx
    2650:	75 20                	jne    2672 <mlkem_decapsulate+0x32>
    2652:	48 83 fe 20          	cmp    $0x20,%rsi
    2656:	75 1a                	jne    2672 <mlkem_decapsulate+0x32>
    2658:	48 85 ff             	test   %rdi,%rdi
    265b:	74 15                	je     2672 <mlkem_decapsulate+0x32>
    265d:	48 85 d2             	test   %rdx,%rdx
    2660:	74 10                	je     2672 <mlkem_decapsulate+0x32>
    2662:	4d 85 c0             	test   %r8,%r8
    2665:	74 0b                	je     2672 <mlkem_decapsulate+0x32>
    2667:	48 89 d6             	mov    %rdx,%rsi
    266a:	4c 89 c2             	mov    %r8,%rdx
    266d:	e9 d9 0e 00 00       	jmp    354b <pqcrystals_kyber768_ref_dec>
    2672:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    2677:	c3                   	ret

Disassembly of section .fini:
