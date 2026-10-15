
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/collector-v2-2e894561892a/build-ordinary/collector/unfixed/m2_dudect：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000003d6a <pqcrystals_kyber768_ref_poly_tomsg>:
    3d6a:	45 31 c0             	xor    %r8d,%r8d
    3d6d:	41 b9 01 0d 00 00    	mov    $0xd01,%r9d
    3d73:	49 83 f8 20          	cmp    $0x20,%r8
    3d77:	74 47                	je     3dc0 <pqcrystals_kyber768_ref_poly_tomsg+0x56>
    3d79:	42 c6 04 07 00       	movb   $0x0,(%rdi,%r8,1)
    3d7e:	31 c9                	xor    %ecx,%ecx
    3d80:	45 31 d2             	xor    %r10d,%r10d
    3d83:	48 83 f9 08          	cmp    $0x8,%rcx
    3d87:	74 2e                	je     3db7 <pqcrystals_kyber768_ref_poly_tomsg+0x4d>
    3d89:	0f bf 04 4e          	movswl (%rsi,%rcx,2),%eax
    3d8d:	89 c2                	mov    %eax,%edx
    3d8f:	c1 ea 0f             	shr    $0xf,%edx
    3d92:	44 21 ca             	and    %r9d,%edx
    3d95:	01 c2                	add    %eax,%edx
    3d97:	0f b7 c2             	movzwl %dx,%eax
    3d9a:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
    3da1:	31 d2                	xor    %edx,%edx
    3da3:	41 f7 f1             	div    %r9d
    3da6:	83 e0 01             	and    $0x1,%eax
    3da9:	d3 e0                	shl    %cl,%eax
    3dab:	41 08 c2             	or     %al,%r10b
    3dae:	46 88 14 07          	mov    %r10b,(%rdi,%r8,1)
    3db2:	48 ff c1             	inc    %rcx
    3db5:	eb cc                	jmp    3d83 <pqcrystals_kyber768_ref_poly_tomsg+0x19>
    3db7:	49 ff c0             	inc    %r8
    3dba:	48 83 c6 10          	add    $0x10,%rsi
    3dbe:	eb b3                	jmp    3d73 <pqcrystals_kyber768_ref_poly_tomsg+0x9>
    3dc0:	c3                   	ret

Disassembly of section .fini:
