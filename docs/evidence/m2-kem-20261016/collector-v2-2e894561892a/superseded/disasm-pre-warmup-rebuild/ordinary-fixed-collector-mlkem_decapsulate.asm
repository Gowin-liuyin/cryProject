
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/fixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

00000000000031d0 <mlkem_decapsulate>:
    31d0:	49 81 f9 60 09 00 00 	cmp    $0x960,%r9
    31d7:	75 29                	jne    3202 <mlkem_decapsulate+0x32>
    31d9:	48 81 f9 40 04 00 00 	cmp    $0x440,%rcx
    31e0:	75 20                	jne    3202 <mlkem_decapsulate+0x32>
    31e2:	48 83 fe 20          	cmp    $0x20,%rsi
    31e6:	75 1a                	jne    3202 <mlkem_decapsulate+0x32>
    31e8:	48 85 ff             	test   %rdi,%rdi
    31eb:	74 15                	je     3202 <mlkem_decapsulate+0x32>
    31ed:	48 85 d2             	test   %rdx,%rdx
    31f0:	74 10                	je     3202 <mlkem_decapsulate+0x32>
    31f2:	4d 85 c0             	test   %r8,%r8
    31f5:	74 0b                	je     3202 <mlkem_decapsulate+0x32>
    31f7:	48 89 d6             	mov    %rdx,%rsi
    31fa:	4c 89 c2             	mov    %r8,%rdx
    31fd:	e9 d9 0e 00 00       	jmp    40db <pqcrystals_kyber768_ref_dec>
    3202:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    3207:	c3                   	ret

Disassembly of section .fini:
