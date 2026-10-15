
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_decaps_collector：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003260 <mlkem_decapsulate>:
    3260:	49 81 f9 60 09 00 00 	cmp    $0x960,%r9
    3267:	75 29                	jne    3292 <mlkem_decapsulate+0x32>
    3269:	48 81 f9 40 04 00 00 	cmp    $0x440,%rcx
    3270:	75 20                	jne    3292 <mlkem_decapsulate+0x32>
    3272:	48 83 fe 20          	cmp    $0x20,%rsi
    3276:	75 1a                	jne    3292 <mlkem_decapsulate+0x32>
    3278:	48 85 ff             	test   %rdi,%rdi
    327b:	74 15                	je     3292 <mlkem_decapsulate+0x32>
    327d:	48 85 d2             	test   %rdx,%rdx
    3280:	74 10                	je     3292 <mlkem_decapsulate+0x32>
    3282:	4d 85 c0             	test   %r8,%r8
    3285:	74 0b                	je     3292 <mlkem_decapsulate+0x32>
    3287:	48 89 d6             	mov    %rdx,%rsi
    328a:	4c 89 c2             	mov    %r8,%rdx
    328d:	e9 d9 0e 00 00       	jmp    416b <pqcrystals_kyber768_ref_dec>
    3292:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    3297:	c3                   	ret

Disassembly of section .fini:
