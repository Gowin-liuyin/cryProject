
/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2/unfixed/measure：     文件格式 elf64-x86-64


Disassembly of section .init:

0000000000001000 <_init>:
    1000:	f3 0f 1e fa          	endbr64
    1004:	48 83 ec 08          	sub    $0x8,%rsp
    1008:	48 8b 05 b9 df 00 00 	mov    0xdfb9(%rip),%rax        # efc8 <__gmon_start__@Base>
    100f:	48 85 c0             	test   %rax,%rax
    1012:	74 02                	je     1016 <_init+0x16>
    1014:	ff d0                	call   *%rax
    1016:	48 83 c4 08          	add    $0x8,%rsp
    101a:	c3                   	ret

Disassembly of section .plt:

0000000000001020 <free@plt-0x10>:
    1020:	ff 35 ca df 00 00    	push   0xdfca(%rip)        # eff0 <_GLOBAL_OFFSET_TABLE_+0x8>
    1026:	ff 25 cc df 00 00    	jmp    *0xdfcc(%rip)        # eff8 <_GLOBAL_OFFSET_TABLE_+0x10>
    102c:	0f 1f 40 00          	nopl   0x0(%rax)

0000000000001030 <free@plt>:
    1030:	ff 25 ca df 00 00    	jmp    *0xdfca(%rip)        # f000 <free@GLIBC_2.2.5>
    1036:	68 00 00 00 00       	push   $0x0
    103b:	e9 e0 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001040 <__errno_location@plt>:
    1040:	ff 25 c2 df 00 00    	jmp    *0xdfc2(%rip)        # f008 <__errno_location@GLIBC_2.2.5>
    1046:	68 01 00 00 00       	push   $0x1
    104b:	e9 d0 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001050 <remove@plt>:
    1050:	ff 25 ba df 00 00    	jmp    *0xdfba(%rip)        # f010 <remove@GLIBC_2.2.5>
    1056:	68 02 00 00 00       	push   $0x2
    105b:	e9 c0 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001060 <ferror@plt>:
    1060:	ff 25 b2 df 00 00    	jmp    *0xdfb2(%rip)        # f018 <ferror@GLIBC_2.2.5>
    1066:	68 03 00 00 00       	push   $0x3
    106b:	e9 b0 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001070 <fread@plt>:
    1070:	ff 25 aa df 00 00    	jmp    *0xdfaa(%rip)        # f020 <fread@GLIBC_2.2.5>
    1076:	68 04 00 00 00       	push   $0x4
    107b:	e9 a0 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001080 <readlink@plt>:
    1080:	ff 25 a2 df 00 00    	jmp    *0xdfa2(%rip)        # f028 <readlink@GLIBC_2.2.5>
    1086:	68 05 00 00 00       	push   $0x5
    108b:	e9 90 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001090 <clock_gettime@plt>:
    1090:	ff 25 9a df 00 00    	jmp    *0xdf9a(%rip)        # f030 <clock_gettime@GLIBC_2.17>
    1096:	68 06 00 00 00       	push   $0x6
    109b:	e9 80 ff ff ff       	jmp    1020 <_init+0x20>

00000000000010a0 <fclose@plt>:
    10a0:	ff 25 92 df 00 00    	jmp    *0xdf92(%rip)        # f038 <fclose@GLIBC_2.2.5>
    10a6:	68 07 00 00 00       	push   $0x7
    10ab:	e9 70 ff ff ff       	jmp    1020 <_init+0x20>

00000000000010b0 <strlen@plt>:
    10b0:	ff 25 8a df 00 00    	jmp    *0xdf8a(%rip)        # f040 <strlen@GLIBC_2.2.5>
    10b6:	68 08 00 00 00       	push   $0x8
    10bb:	e9 60 ff ff ff       	jmp    1020 <_init+0x20>

00000000000010c0 <strchr@plt>:
    10c0:	ff 25 82 df 00 00    	jmp    *0xdf82(%rip)        # f048 <strchr@GLIBC_2.2.5>
    10c6:	68 09 00 00 00       	push   $0x9
    10cb:	e9 50 ff ff ff       	jmp    1020 <_init+0x20>

00000000000010d0 <printf@plt>:
    10d0:	ff 25 7a df 00 00    	jmp    *0xdf7a(%rip)        # f050 <printf@GLIBC_2.2.5>
    10d6:	68 0a 00 00 00       	push   $0xa
    10db:	e9 40 ff ff ff       	jmp    1020 <_init+0x20>

00000000000010e0 <snprintf@plt>:
    10e0:	ff 25 72 df 00 00    	jmp    *0xdf72(%rip)        # f058 <snprintf@GLIBC_2.2.5>
    10e6:	68 0b 00 00 00       	push   $0xb
    10eb:	e9 30 ff ff ff       	jmp    1020 <_init+0x20>

00000000000010f0 <uname@plt>:
    10f0:	ff 25 6a df 00 00    	jmp    *0xdf6a(%rip)        # f060 <uname@GLIBC_2.2.5>
    10f6:	68 0c 00 00 00       	push   $0xc
    10fb:	e9 20 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001100 <fputs@plt>:
    1100:	ff 25 62 df 00 00    	jmp    *0xdf62(%rip)        # f068 <fputs@GLIBC_2.2.5>
    1106:	68 0d 00 00 00       	push   $0xd
    110b:	e9 10 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001110 <memset@plt>:
    1110:	ff 25 5a df 00 00    	jmp    *0xdf5a(%rip)        # f070 <memset@GLIBC_2.2.5>
    1116:	68 0e 00 00 00       	push   $0xe
    111b:	e9 00 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001120 <fgetc@plt>:
    1120:	ff 25 52 df 00 00    	jmp    *0xdf52(%rip)        # f078 <fgetc@GLIBC_2.2.5>
    1126:	68 0f 00 00 00       	push   $0xf
    112b:	e9 f0 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001130 <close@plt>:
    1130:	ff 25 4a df 00 00    	jmp    *0xdf4a(%rip)        # f080 <close@GLIBC_2.2.5>
    1136:	68 10 00 00 00       	push   $0x10
    113b:	e9 e0 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001140 <fputc@plt>:
    1140:	ff 25 42 df 00 00    	jmp    *0xdf42(%rip)        # f088 <fputc@GLIBC_2.2.5>
    1146:	68 11 00 00 00       	push   $0x11
    114b:	e9 d0 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001150 <strcspn@plt>:
    1150:	ff 25 3a df 00 00    	jmp    *0xdf3a(%rip)        # f090 <strcspn@GLIBC_2.2.5>
    1156:	68 12 00 00 00       	push   $0x12
    115b:	e9 c0 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001160 <read@plt>:
    1160:	ff 25 32 df 00 00    	jmp    *0xdf32(%rip)        # f098 <read@GLIBC_2.2.5>
    1166:	68 13 00 00 00       	push   $0x13
    116b:	e9 b0 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001170 <fgets@plt>:
    1170:	ff 25 2a df 00 00    	jmp    *0xdf2a(%rip)        # f0a0 <fgets@GLIBC_2.2.5>
    1176:	68 14 00 00 00       	push   $0x14
    117b:	e9 a0 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001180 <strtoull@plt>:
    1180:	ff 25 22 df 00 00    	jmp    *0xdf22(%rip)        # f0a8 <strtoull@GLIBC_2.2.5>
    1186:	68 15 00 00 00       	push   $0x15
    118b:	e9 90 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001190 <calloc@plt>:
    1190:	ff 25 1a df 00 00    	jmp    *0xdf1a(%rip)        # f0b0 <calloc@GLIBC_2.2.5>
    1196:	68 16 00 00 00       	push   $0x16
    119b:	e9 80 fe ff ff       	jmp    1020 <_init+0x20>

00000000000011a0 <strcmp@plt>:
    11a0:	ff 25 12 df 00 00    	jmp    *0xdf12(%rip)        # f0b8 <strcmp@GLIBC_2.2.5>
    11a6:	68 17 00 00 00       	push   $0x17
    11ab:	e9 70 fe ff ff       	jmp    1020 <_init+0x20>

00000000000011b0 <fprintf@plt>:
    11b0:	ff 25 0a df 00 00    	jmp    *0xdf0a(%rip)        # f0c0 <fprintf@GLIBC_2.2.5>
    11b6:	68 18 00 00 00       	push   $0x18
    11bb:	e9 60 fe ff ff       	jmp    1020 <_init+0x20>

00000000000011c0 <memcpy@plt>:
    11c0:	ff 25 02 df 00 00    	jmp    *0xdf02(%rip)        # f0c8 <memcpy@GLIBC_2.14>
    11c6:	68 19 00 00 00       	push   $0x19
    11cb:	e9 50 fe ff ff       	jmp    1020 <_init+0x20>

00000000000011d0 <time@plt>:
    11d0:	ff 25 fa de 00 00    	jmp    *0xdefa(%rip)        # f0d0 <time@GLIBC_2.2.5>
    11d6:	68 1a 00 00 00       	push   $0x1a
    11db:	e9 40 fe ff ff       	jmp    1020 <_init+0x20>

00000000000011e0 <fileno@plt>:
    11e0:	ff 25 f2 de 00 00    	jmp    *0xdef2(%rip)        # f0d8 <fileno@GLIBC_2.2.5>
    11e6:	68 1b 00 00 00       	push   $0x1b
    11eb:	e9 30 fe ff ff       	jmp    1020 <_init+0x20>

00000000000011f0 <malloc@plt>:
    11f0:	ff 25 ea de 00 00    	jmp    *0xdeea(%rip)        # f0e0 <malloc@GLIBC_2.2.5>
    11f6:	68 1c 00 00 00       	push   $0x1c
    11fb:	e9 20 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001200 <clock_getres@plt>:
    1200:	ff 25 e2 de 00 00    	jmp    *0xdee2(%rip)        # f0e8 <clock_getres@GLIBC_2.17>
    1206:	68 1d 00 00 00       	push   $0x1d
    120b:	e9 10 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001210 <open@plt>:
    1210:	ff 25 da de 00 00    	jmp    *0xdeda(%rip)        # f0f0 <open@GLIBC_2.2.5>
    1216:	68 1e 00 00 00       	push   $0x1e
    121b:	e9 00 fe ff ff       	jmp    1020 <_init+0x20>

0000000000001220 <fopen@plt>:
    1220:	ff 25 d2 de 00 00    	jmp    *0xded2(%rip)        # f0f8 <fopen@GLIBC_2.2.5>
    1226:	68 1f 00 00 00       	push   $0x1f
    122b:	e9 f0 fd ff ff       	jmp    1020 <_init+0x20>

0000000000001230 <fwrite@plt>:
    1230:	ff 25 ca de 00 00    	jmp    *0xdeca(%rip)        # f100 <fwrite@GLIBC_2.2.5>
    1236:	68 20 00 00 00       	push   $0x20
    123b:	e9 e0 fd ff ff       	jmp    1020 <_init+0x20>

0000000000001240 <fstat@plt>:
    1240:	ff 25 c2 de 00 00    	jmp    *0xdec2(%rip)        # f108 <fstat@GLIBC_2.33>
    1246:	68 21 00 00 00       	push   $0x21
    124b:	e9 d0 fd ff ff       	jmp    1020 <_init+0x20>

Disassembly of section .plt.got:

0000000000001250 <__cxa_finalize@plt>:
    1250:	ff 25 82 dd 00 00    	jmp    *0xdd82(%rip)        # efd8 <__cxa_finalize@GLIBC_2.2.5>
    1256:	66 90                	xchg   %ax,%ax

Disassembly of section .text:

0000000000001260 <_start>:
    1260:	f3 0f 1e fa          	endbr64
    1264:	31 ed                	xor    %ebp,%ebp
    1266:	49 89 d1             	mov    %rdx,%r9
    1269:	5e                   	pop    %rsi
    126a:	48 89 e2             	mov    %rsp,%rdx
    126d:	48 83 e4 f0          	and    $0xfffffffffffffff0,%rsp
    1271:	50                   	push   %rax
    1272:	54                   	push   %rsp
    1273:	45 31 c0             	xor    %r8d,%r8d
    1276:	31 c9                	xor    %ecx,%ecx
    1278:	48 8d 3d d1 00 00 00 	lea    0xd1(%rip),%rdi        # 1350 <main>
    127f:	ff 15 33 dd 00 00    	call   *0xdd33(%rip)        # efb8 <__libc_start_main@GLIBC_2.34>
    1285:	f4                   	hlt
    1286:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    128d:	00 00 00 

0000000000001290 <deregister_tm_clones>:
    1290:	48 8d 3d 89 de 00 00 	lea    0xde89(%rip),%rdi        # f120 <__TMC_END__>
    1297:	48 8d 05 82 de 00 00 	lea    0xde82(%rip),%rax        # f120 <__TMC_END__>
    129e:	48 39 f8             	cmp    %rdi,%rax
    12a1:	74 15                	je     12b8 <deregister_tm_clones+0x28>
    12a3:	48 8b 05 16 dd 00 00 	mov    0xdd16(%rip),%rax        # efc0 <_ITM_deregisterTMCloneTable@Base>
    12aa:	48 85 c0             	test   %rax,%rax
    12ad:	74 09                	je     12b8 <deregister_tm_clones+0x28>
    12af:	ff e0                	jmp    *%rax
    12b1:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    12b8:	c3                   	ret
    12b9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

00000000000012c0 <register_tm_clones>:
    12c0:	48 8d 3d 59 de 00 00 	lea    0xde59(%rip),%rdi        # f120 <__TMC_END__>
    12c7:	48 8d 35 52 de 00 00 	lea    0xde52(%rip),%rsi        # f120 <__TMC_END__>
    12ce:	48 29 fe             	sub    %rdi,%rsi
    12d1:	48 89 f0             	mov    %rsi,%rax
    12d4:	48 c1 ee 3f          	shr    $0x3f,%rsi
    12d8:	48 c1 f8 03          	sar    $0x3,%rax
    12dc:	48 01 c6             	add    %rax,%rsi
    12df:	48 d1 fe             	sar    $1,%rsi
    12e2:	74 14                	je     12f8 <register_tm_clones+0x38>
    12e4:	48 8b 05 e5 dc 00 00 	mov    0xdce5(%rip),%rax        # efd0 <_ITM_registerTMCloneTable@Base>
    12eb:	48 85 c0             	test   %rax,%rax
    12ee:	74 08                	je     12f8 <register_tm_clones+0x38>
    12f0:	ff e0                	jmp    *%rax
    12f2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    12f8:	c3                   	ret
    12f9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000001300 <__do_global_dtors_aux>:
    1300:	f3 0f 1e fa          	endbr64
    1304:	80 3d 15 de 00 00 00 	cmpb   $0x0,0xde15(%rip)        # f120 <__TMC_END__>
    130b:	75 2b                	jne    1338 <__do_global_dtors_aux+0x38>
    130d:	55                   	push   %rbp
    130e:	48 83 3d c2 dc 00 00 	cmpq   $0x0,0xdcc2(%rip)        # efd8 <__cxa_finalize@GLIBC_2.2.5>
    1315:	00 
    1316:	48 89 e5             	mov    %rsp,%rbp
    1319:	74 0c                	je     1327 <__do_global_dtors_aux+0x27>
    131b:	48 8b 3d f6 dd 00 00 	mov    0xddf6(%rip),%rdi        # f118 <__dso_handle>
    1322:	e8 29 ff ff ff       	call   1250 <__cxa_finalize@plt>
    1327:	e8 64 ff ff ff       	call   1290 <deregister_tm_clones>
    132c:	c6 05 ed dd 00 00 01 	movb   $0x1,0xdded(%rip)        # f120 <__TMC_END__>
    1333:	5d                   	pop    %rbp
    1334:	c3                   	ret
    1335:	0f 1f 00             	nopl   (%rax)
    1338:	c3                   	ret
    1339:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000001340 <frame_dummy>:
    1340:	f3 0f 1e fa          	endbr64
    1344:	e9 77 ff ff ff       	jmp    12c0 <register_tm_clones>
    1349:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)

0000000000001350 <main>:
    1350:	55                   	push   %rbp
    1351:	41 57                	push   %r15
    1353:	41 56                	push   %r14
    1355:	41 55                	push   %r13
    1357:	41 54                	push   %r12
    1359:	53                   	push   %rbx
    135a:	48 81 ec 58 19 00 00 	sub    $0x1958,%rsp
    1361:	83 ff 06             	cmp    $0x6,%edi
    1364:	0f 85 5c 07 00 00    	jne    1ac6 <main+0x776>
    136a:	49 89 f5             	mov    %rsi,%r13
    136d:	48 8b 7e 10          	mov    0x10(%rsi),%rdi
    1371:	48 8d 74 24 10       	lea    0x10(%rsp),%rsi
    1376:	e8 25 13 00 00       	call   26a0 <parse_unsigned_integer>
    137b:	85 c0                	test   %eax,%eax
    137d:	0f 85 43 07 00 00    	jne    1ac6 <main+0x776>
    1383:	49 8b 7d 18          	mov    0x18(%r13),%rdi
    1387:	48 8d 74 24 18       	lea    0x18(%rsp),%rsi
    138c:	e8 0f 13 00 00       	call   26a0 <parse_unsigned_integer>
    1391:	85 c0                	test   %eax,%eax
    1393:	0f 85 2d 07 00 00    	jne    1ac6 <main+0x776>
    1399:	48 8b 44 24 18       	mov    0x18(%rsp),%rax
    139e:	48 85 c0             	test   %rax,%rax
    13a1:	0f 84 1f 07 00 00    	je     1ac6 <main+0x776>
    13a7:	48 3d 21 4e 00 00    	cmp    $0x4e21,%rax
    13ad:	0f 83 13 07 00 00    	jae    1ac6 <main+0x776>
    13b3:	49 8b 5d 08          	mov    0x8(%r13),%rbx
    13b7:	48 89 df             	mov    %rbx,%rdi
    13ba:	e8 f1 fc ff ff       	call   10b0 <strlen@plt>
    13bf:	48 83 c0 bf          	add    $0xffffffffffffffbf,%rax
    13c3:	48 83 f8 c0          	cmp    $0xffffffffffffffc0,%rax
    13c7:	0f 82 65 07 00 00    	jb     1b32 <main+0x7e2>
    13cd:	0f b6 03             	movzbl (%rbx),%eax
    13d0:	84 c0                	test   %al,%al
    13d2:	74 52                	je     1426 <main+0xd6>
    13d4:	48 ff c3             	inc    %rbx
    13d7:	eb 11                	jmp    13ea <main+0x9a>
    13d9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    13e0:	0f b6 03             	movzbl (%rbx),%eax
    13e3:	48 ff c3             	inc    %rbx
    13e6:	84 c0                	test   %al,%al
    13e8:	74 3c                	je     1426 <main+0xd6>
    13ea:	8d 48 d0             	lea    -0x30(%rax),%ecx
    13ed:	80 f9 0a             	cmp    $0xa,%cl
    13f0:	72 ee                	jb     13e0 <main+0x90>
    13f2:	89 c1                	mov    %eax,%ecx
    13f4:	80 e1 df             	and    $0xdf,%cl
    13f7:	80 c1 bf             	add    $0xbf,%cl
    13fa:	80 f9 1a             	cmp    $0x1a,%cl
    13fd:	72 e1                	jb     13e0 <main+0x90>
    13ff:	3c 5f                	cmp    $0x5f,%al
    1401:	74 dd                	je     13e0 <main+0x90>
    1403:	0f b6 c0             	movzbl %al,%eax
    1406:	83 f8 2d             	cmp    $0x2d,%eax
    1409:	74 d5                	je     13e0 <main+0x90>
    140b:	48 8b 05 ce db 00 00 	mov    0xdbce(%rip),%rax        # efe0 <stderr@GLIBC_2.2.5>
    1412:	48 8b 08             	mov    (%rax),%rcx
    1415:	48 8d 3d 6e 3c 00 00 	lea    0x3c6e(%rip),%rdi        # 508a <_IO_stdin_used+0x8a>
    141c:	be 45 00 00 00       	mov    $0x45,%esi
    1421:	e9 22 07 00 00       	jmp    1b48 <main+0x7f8>
    1426:	48 8d b4 24 b0 04 00 	lea    0x4b0(%rsp),%rsi
    142d:	00 
    142e:	bf 01 00 00 00       	mov    $0x1,%edi
    1433:	e8 c8 fd ff ff       	call   1200 <clock_getres@plt>
    1438:	85 c0                	test   %eax,%eax
    143a:	0f 85 21 07 00 00    	jne    1b61 <main+0x811>
    1440:	48 8b 84 24 b0 04 00 	mov    0x4b0(%rsp),%rax
    1447:	00 
    1448:	48 85 c0             	test   %rax,%rax
    144b:	0f 88 10 07 00 00    	js     1b61 <main+0x811>
    1451:	48 8b 8c 24 b8 04 00 	mov    0x4b8(%rsp),%rcx
    1458:	00 
    1459:	48 85 c9             	test   %rcx,%rcx
    145c:	0f 88 ff 06 00 00    	js     1b61 <main+0x811>
    1462:	48 69 c0 00 ca 9a 3b 	imul   $0x3b9aca00,%rax,%rax
    1469:	48 01 c8             	add    %rcx,%rax
    146c:	48 89 44 24 38       	mov    %rax,0x38(%rsp)
    1471:	0f 84 ea 06 00 00    	je     1b61 <main+0x811>
    1477:	48 8d b4 24 50 09 00 	lea    0x950(%rsp),%rsi
    147e:	00 
    147f:	bf 01 00 00 00       	mov    $0x1,%edi
    1484:	e8 07 fc ff ff       	call   1090 <clock_gettime@plt>
    1489:	85 c0                	test   %eax,%eax
    148b:	0f 85 d0 06 00 00    	jne    1b61 <main+0x811>
    1491:	48 8b 8c 24 50 09 00 	mov    0x950(%rsp),%rcx
    1498:	00 
    1499:	48 85 c9             	test   %rcx,%rcx
    149c:	0f 88 bf 06 00 00    	js     1b61 <main+0x811>
    14a2:	48 8b b4 24 58 09 00 	mov    0x958(%rsp),%rsi
    14a9:	00 
    14aa:	48 85 f6             	test   %rsi,%rsi
    14ad:	0f 88 ae 06 00 00    	js     1b61 <main+0x811>
    14b3:	48 81 fe ff c9 9a 3b 	cmp    $0x3b9ac9ff,%rsi
    14ba:	0f 8f a1 06 00 00    	jg     1b61 <main+0x811>
    14c0:	48 89 f0             	mov    %rsi,%rax
    14c3:	48 f7 d0             	not    %rax
    14c6:	48 c1 e8 09          	shr    $0x9,%rax
    14ca:	48 ba 53 5a 9b a0 2f 	movabs $0x44b82fa09b5a53,%rdx
    14d1:	b8 44 00 
    14d4:	48 f7 e2             	mul    %rdx
    14d7:	48 c1 ea 0b          	shr    $0xb,%rdx
    14db:	48 39 d1             	cmp    %rdx,%rcx
    14de:	0f 87 7d 06 00 00    	ja     1b61 <main+0x811>
    14e4:	4c 69 e1 00 ca 9a 3b 	imul   $0x3b9aca00,%rcx,%r12
    14eb:	49 01 f4             	add    %rsi,%r12
    14ee:	31 ed                	xor    %ebp,%ebp
    14f0:	41 be 10 27 00 00    	mov    $0x2710,%r14d
    14f6:	41 bf 01 00 00 00    	mov    $0x1,%r15d
    14fc:	48 8d 9c 24 50 09 00 	lea    0x950(%rsp),%rbx
    1503:	00 
    1504:	66 66 66 2e 0f 1f 84 	data16 data16 cs nopw 0x0(%rax,%rax,1)
    150b:	00 00 00 00 00 
    1510:	bf 01 00 00 00       	mov    $0x1,%edi
    1515:	48 89 de             	mov    %rbx,%rsi
    1518:	e8 73 fb ff ff       	call   1090 <clock_gettime@plt>
    151d:	85 c0                	test   %eax,%eax
    151f:	0f 85 3c 06 00 00    	jne    1b61 <main+0x811>
    1525:	48 8b 8c 24 50 09 00 	mov    0x950(%rsp),%rcx
    152c:	00 
    152d:	48 85 c9             	test   %rcx,%rcx
    1530:	0f 88 2b 06 00 00    	js     1b61 <main+0x811>
    1536:	48 8b b4 24 58 09 00 	mov    0x958(%rsp),%rsi
    153d:	00 
    153e:	48 85 f6             	test   %rsi,%rsi
    1541:	0f 88 1a 06 00 00    	js     1b61 <main+0x811>
    1547:	48 81 fe ff c9 9a 3b 	cmp    $0x3b9ac9ff,%rsi
    154e:	0f 8f 0d 06 00 00    	jg     1b61 <main+0x811>
    1554:	48 89 f0             	mov    %rsi,%rax
    1557:	48 f7 d0             	not    %rax
    155a:	48 c1 e8 09          	shr    $0x9,%rax
    155e:	48 ba 53 5a 9b a0 2f 	movabs $0x44b82fa09b5a53,%rdx
    1565:	b8 44 00 
    1568:	48 f7 e2             	mul    %rdx
    156b:	48 c1 ea 0b          	shr    $0xb,%rdx
    156f:	48 39 d1             	cmp    %rdx,%rcx
    1572:	0f 87 e9 05 00 00    	ja     1b61 <main+0x811>
    1578:	48 69 c1 00 ca 9a 3b 	imul   $0x3b9aca00,%rcx,%rax
    157f:	48 01 f0             	add    %rsi,%rax
    1582:	4c 39 e0             	cmp    %r12,%rax
    1585:	0f 82 d6 05 00 00    	jb     1b61 <main+0x811>
    158b:	41 0f 47 ef          	cmova  %r15d,%ebp
    158f:	49 89 c4             	mov    %rax,%r12
    1592:	41 ff ce             	dec    %r14d
    1595:	0f 85 75 ff ff ff    	jne    1510 <main+0x1c0>
    159b:	85 ed                	test   %ebp,%ebp
    159d:	0f 84 be 05 00 00    	je     1b61 <main+0x811>
    15a3:	48 8d 3d d4 3b 00 00 	lea    0x3bd4(%rip),%rdi        # 517e <_IO_stdin_used+0x17e>
    15aa:	48 8d b4 24 50 09 00 	lea    0x950(%rsp),%rsi
    15b1:	00 
    15b2:	ba ff 0f 00 00       	mov    $0xfff,%edx
    15b7:	e8 c4 fa ff ff       	call   1080 <readlink@plt>
    15bc:	48 3d fe 0f 00 00    	cmp    $0xffe,%rax
    15c2:	0f 87 99 05 00 00    	ja     1b61 <main+0x811>
    15c8:	c6 84 04 50 09 00 00 	movb   $0x0,0x950(%rsp,%rax,1)
    15cf:	00 
    15d0:	48 8d 35 b6 3b 00 00 	lea    0x3bb6(%rip),%rsi        # 518d <_IO_stdin_used+0x18d>
    15d7:	48 8d bc 24 50 09 00 	lea    0x950(%rsp),%rdi
    15de:	00 
    15df:	e8 3c fc ff ff       	call   1220 <fopen@plt>
    15e4:	48 85 c0             	test   %rax,%rax
    15e7:	0f 84 74 05 00 00    	je     1b61 <main+0x811>
    15ed:	48 89 c3             	mov    %rax,%rbx
    15f0:	48 89 c7             	mov    %rax,%rdi
    15f3:	e8 e8 fb ff ff       	call   11e0 <fileno@plt>
    15f8:	48 8d b4 24 b0 04 00 	lea    0x4b0(%rsp),%rsi
    15ff:	00 
    1600:	89 c7                	mov    %eax,%edi
    1602:	e8 39 fc ff ff       	call   1240 <fstat@plt>
    1607:	85 c0                	test   %eax,%eax
    1609:	0f 85 4a 05 00 00    	jne    1b59 <main+0x809>
    160f:	4c 8b b4 24 e0 04 00 	mov    0x4e0(%rsp),%r14
    1616:	00 
    1617:	4d 85 f6             	test   %r14,%r14
    161a:	0f 8e 39 05 00 00    	jle    1b59 <main+0x809>
    1620:	49 81 fe 00 00 00 04 	cmp    $0x4000000,%r14
    1627:	0f 8f 2c 05 00 00    	jg     1b59 <main+0x809>
    162d:	4c 89 f7             	mov    %r14,%rdi
    1630:	e8 bb fb ff ff       	call   11f0 <malloc@plt>
    1635:	48 85 c0             	test   %rax,%rax
    1638:	0f 84 1b 05 00 00    	je     1b59 <main+0x809>
    163e:	49 89 c7             	mov    %rax,%r15
    1641:	be 01 00 00 00       	mov    $0x1,%esi
    1646:	48 89 c7             	mov    %rax,%rdi
    1649:	4c 89 f2             	mov    %r14,%rdx
    164c:	48 89 d9             	mov    %rbx,%rcx
    164f:	e8 1c fa ff ff       	call   1070 <fread@plt>
    1654:	4c 39 f0             	cmp    %r14,%rax
    1657:	0f 85 c3 04 00 00    	jne    1b20 <main+0x7d0>
    165d:	48 89 df             	mov    %rbx,%rdi
    1660:	e8 bb fa ff ff       	call   1120 <fgetc@plt>
    1665:	83 f8 ff             	cmp    $0xffffffff,%eax
    1668:	0f 85 b2 04 00 00    	jne    1b20 <main+0x7d0>
    166e:	48 89 df             	mov    %rbx,%rdi
    1671:	e8 ea f9 ff ff       	call   1060 <ferror@plt>
    1676:	85 c0                	test   %eax,%eax
    1678:	0f 85 a2 04 00 00    	jne    1b20 <main+0x7d0>
    167e:	48 89 df             	mov    %rbx,%rdi
    1681:	e8 1a fa ff ff       	call   10a0 <fclose@plt>
    1686:	85 c0                	test   %eax,%eax
    1688:	0f 85 9a 04 00 00    	jne    1b28 <main+0x7d8>
    168e:	4c 89 6c 24 30       	mov    %r13,0x30(%rsp)
    1693:	48 8d 7c 24 40       	lea    0x40(%rsp),%rdi
    1698:	4c 89 fe             	mov    %r15,%rsi
    169b:	4c 89 f2             	mov    %r14,%rdx
    169e:	e8 8d 0d 00 00       	call   2430 <platform_m2_sha3_256>
    16a3:	4c 89 ff             	mov    %r15,%rdi
    16a6:	e8 85 f9 ff ff       	call   1030 <free@plt>
    16ab:	48 8b 5c 24 18       	mov    0x18(%rsp),%rbx
    16b0:	48 8d 3c 9b          	lea    (%rbx,%rbx,4),%rdi
    16b4:	be 50 04 00 00       	mov    $0x450,%esi
    16b9:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
    16be:	e8 cd fa ff ff       	call   1190 <calloc@plt>
    16c3:	48 89 04 24          	mov    %rax,(%rsp)
    16c7:	48 85 c0             	test   %rax,%rax
    16ca:	0f 84 0e 04 00 00    	je     1ade <main+0x78e>
    16d0:	48 8b 7c 24 10       	mov    0x10(%rsp),%rdi
    16d5:	48 8d b4 24 b0 04 00 	lea    0x4b0(%rsp),%rsi
    16dc:	00 
    16dd:	48 8d 94 24 50 09 00 	lea    0x950(%rsp),%rdx
    16e4:	00 
    16e5:	e8 f6 10 00 00       	call   27e0 <generate_test_key_pair>
    16ea:	85 c0                	test   %eax,%eax
    16ec:	0f 85 ec 03 00 00    	jne    1ade <main+0x78e>
    16f2:	48 85 db             	test   %rbx,%rbx
    16f5:	0f 84 74 01 00 00    	je     186f <main+0x51f>
    16fb:	48 8b 5c 24 08       	mov    0x8(%rsp),%rbx
    1700:	48 83 fb 01          	cmp    $0x1,%rbx
    1704:	48 83 d3 00          	adc    $0x0,%rbx
    1708:	45 31 ff             	xor    %r15d,%r15d
    170b:	49 be cd cc cc cc cc 	movabs $0xcccccccccccccccd,%r14
    1712:	cc cc cc 
    1715:	4c 8d a4 24 b0 04 00 	lea    0x4b0(%rsp),%r12
    171c:	00 
    171d:	4c 8b 2c 24          	mov    (%rsp),%r13
    1721:	66 66 66 66 66 66 2e 	data16 data16 data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
    1728:	0f 1f 84 00 00 00 00 
    172f:	00 
    1730:	4c 89 f8             	mov    %r15,%rax
    1733:	49 f7 e6             	mul    %r14
    1736:	48 c1 ea 02          	shr    $0x2,%rdx
    173a:	8d 04 92             	lea    (%rdx,%rdx,4),%eax
    173d:	44 89 ff             	mov    %r15d,%edi
    1740:	29 c7                	sub    %eax,%edi
    1742:	41 89 bd 40 04 00 00 	mov    %edi,0x440(%r13)
    1749:	48 8b 74 24 10       	mov    0x10(%rsp),%rsi
    174e:	4c 89 e1             	mov    %r12,%rcx
    1751:	4d 89 e8             	mov    %r13,%r8
    1754:	e8 37 11 00 00       	call   2890 <generate_test_ciphertext>
    1759:	85 c0                	test   %eax,%eax
    175b:	0f 85 7d 03 00 00    	jne    1ade <main+0x78e>
    1761:	49 ff c7             	inc    %r15
    1764:	49 81 c5 50 04 00 00 	add    $0x450,%r13
    176b:	4c 39 fb             	cmp    %r15,%rbx
    176e:	75 c0                	jne    1730 <main+0x3e0>
    1770:	48 83 7c 24 08 01    	cmpq   $0x1,0x8(%rsp)
    1776:	0f 86 f3 00 00 00    	jbe    186f <main+0x51f>
    177c:	48 8b 04 24          	mov    (%rsp),%rax
    1780:	4c 8d b0 b0 fb ff ff 	lea    -0x450(%rax),%r14
    1787:	31 ed                	xor    %ebp,%ebp
    1789:	4c 8d 7c 24 60       	lea    0x60(%rsp),%r15
    178e:	48 8b 5c 24 08       	mov    0x8(%rsp),%rbx
    1793:	eb 5e                	jmp    17f3 <main+0x4a3>
    1795:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    179c:	00 00 00 00 
    17a0:	31 d2                	xor    %edx,%edx
    17a2:	48 f7 f3             	div    %rbx
    17a5:	4c 69 e2 50 04 00 00 	imul   $0x450,%rdx,%r12
    17ac:	4c 03 24 24          	add    (%rsp),%r12
    17b0:	ba 50 04 00 00       	mov    $0x450,%edx
    17b5:	4c 89 ff             	mov    %r15,%rdi
    17b8:	4c 89 e6             	mov    %r12,%rsi
    17bb:	e8 00 fa ff ff       	call   11c0 <memcpy@plt>
    17c0:	4c 69 eb 50 04 00 00 	imul   $0x450,%rbx,%r13
    17c7:	4d 01 f5             	add    %r14,%r13
    17ca:	ba 50 04 00 00       	mov    $0x450,%edx
    17cf:	4c 89 e7             	mov    %r12,%rdi
    17d2:	4c 89 ee             	mov    %r13,%rsi
    17d5:	e8 e6 f9 ff ff       	call   11c0 <memcpy@plt>
    17da:	ba 50 04 00 00       	mov    $0x450,%edx
    17df:	4c 89 ef             	mov    %r13,%rdi
    17e2:	4c 89 fe             	mov    %r15,%rsi
    17e5:	e8 d6 f9 ff ff       	call   11c0 <memcpy@plt>
    17ea:	48 ff cb             	dec    %rbx
    17ed:	48 83 fb 01          	cmp    $0x1,%rbx
    17f1:	76 7c                	jbe    186f <main+0x51f>
    17f3:	4c 8b 64 24 10       	mov    0x10(%rsp),%r12
    17f8:	48 89 d8             	mov    %rbx,%rax
    17fb:	48 f7 d8             	neg    %rax
    17fe:	48 89 c1             	mov    %rax,%rcx
    1801:	48 09 d9             	or     %rbx,%rcx
    1804:	48 c1 e9 20          	shr    $0x20,%rcx
    1808:	74 16                	je     1820 <main+0x4d0>
    180a:	31 d2                	xor    %edx,%edx
    180c:	48 f7 f3             	div    %rbx
    180f:	49 89 d5             	mov    %rdx,%r13
    1812:	eb 1c                	jmp    1830 <main+0x4e0>
    1814:	66 66 66 2e 0f 1f 84 	data16 data16 cs nopw 0x0(%rax,%rax,1)
    181b:	00 00 00 00 00 
    1820:	31 d2                	xor    %edx,%edx
    1822:	f7 f3                	div    %ebx
    1824:	41 89 d5             	mov    %edx,%r13d
    1827:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    182e:	00 00 
    1830:	48 89 e9             	mov    %rbp,%rcx
    1833:	48 ff c5             	inc    %rbp
    1836:	be 08 00 00 00       	mov    $0x8,%esi
    183b:	4c 89 ff             	mov    %r15,%rdi
    183e:	4c 89 e2             	mov    %r12,%rdx
    1841:	41 b8 04 00 00 00    	mov    $0x4,%r8d
    1847:	e8 f4 0e 00 00       	call   2740 <expand_test_seed>
    184c:	48 8b 44 24 60       	mov    0x60(%rsp),%rax
    1851:	4c 39 e8             	cmp    %r13,%rax
    1854:	72 da                	jb     1830 <main+0x4e0>
    1856:	48 89 c1             	mov    %rax,%rcx
    1859:	48 09 d9             	or     %rbx,%rcx
    185c:	48 c1 e9 20          	shr    $0x20,%rcx
    1860:	0f 85 3a ff ff ff    	jne    17a0 <main+0x450>
    1866:	31 d2                	xor    %edx,%edx
    1868:	f7 f3                	div    %ebx
    186a:	e9 36 ff ff ff       	jmp    17a5 <main+0x455>
    186f:	45 31 ff             	xor    %r15d,%r15d
    1872:	4c 8d 64 24 60       	lea    0x60(%rsp),%r12
    1877:	4c 8d ac 24 50 09 00 	lea    0x950(%rsp),%r13
    187e:	00 
    187f:	90                   	nop
    1880:	4c 89 f8             	mov    %r15,%rax
    1883:	48 8b 4c 24 08       	mov    0x8(%rsp),%rcx
    1888:	48 09 c8             	or     %rcx,%rax
    188b:	48 c1 e8 20          	shr    $0x20,%rax
    188f:	74 0f                	je     18a0 <main+0x550>
    1891:	4c 89 f8             	mov    %r15,%rax
    1894:	31 d2                	xor    %edx,%edx
    1896:	48 f7 f1             	div    %rcx
    1899:	eb 0c                	jmp    18a7 <main+0x557>
    189b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    18a0:	44 89 f8             	mov    %r15d,%eax
    18a3:	31 d2                	xor    %edx,%edx
    18a5:	f7 f1                	div    %ecx
    18a7:	48 69 d2 50 04 00 00 	imul   $0x450,%rdx,%rdx
    18ae:	48 03 14 24          	add    (%rsp),%rdx
    18b2:	be 20 00 00 00       	mov    $0x20,%esi
    18b7:	b9 40 04 00 00       	mov    $0x440,%ecx
    18bc:	41 b9 60 09 00 00    	mov    $0x960,%r9d
    18c2:	4c 89 e7             	mov    %r12,%rdi
    18c5:	4d 89 e8             	mov    %r13,%r8
    18c8:	e8 13 0a 00 00       	call   22e0 <mlkem_decapsulate>
    18cd:	85 c0                	test   %eax,%eax
    18cf:	0f 85 09 02 00 00    	jne    1ade <main+0x78e>
    18d5:	0f b6 44 24 60       	movzbl 0x60(%rsp),%eax
    18da:	30 05 41 d8 00 00    	xor    %al,0xd841(%rip)        # f121 <result_sink>
    18e0:	49 ff c7             	inc    %r15
    18e3:	49 83 ff 64          	cmp    $0x64,%r15
    18e7:	75 97                	jne    1880 <main+0x530>
    18e9:	4c 8b 74 24 08       	mov    0x8(%rsp),%r14
    18ee:	49 83 fe 01          	cmp    $0x1,%r14
    18f2:	49 83 d6 00          	adc    $0x0,%r14
    18f6:	45 31 e4             	xor    %r12d,%r12d
    18f9:	4c 8b 3c 24          	mov    (%rsp),%r15
    18fd:	0f 1f 00             	nopl   (%rax)
    1900:	bf 01 00 00 00       	mov    $0x1,%edi
    1905:	48 8d 74 24 20       	lea    0x20(%rsp),%rsi
    190a:	e8 81 f7 ff ff       	call   1090 <clock_gettime@plt>
    190f:	85 c0                	test   %eax,%eax
    1911:	0f 85 c7 01 00 00    	jne    1ade <main+0x78e>
    1917:	48 8b 5c 24 20       	mov    0x20(%rsp),%rbx
    191c:	48 85 db             	test   %rbx,%rbx
    191f:	0f 88 b9 01 00 00    	js     1ade <main+0x78e>
    1925:	4c 8b 6c 24 28       	mov    0x28(%rsp),%r13
    192a:	4d 85 ed             	test   %r13,%r13
    192d:	0f 88 ab 01 00 00    	js     1ade <main+0x78e>
    1933:	49 81 fd ff c9 9a 3b 	cmp    $0x3b9ac9ff,%r13
    193a:	0f 8f 9e 01 00 00    	jg     1ade <main+0x78e>
    1940:	4c 89 e8             	mov    %r13,%rax
    1943:	48 f7 d0             	not    %rax
    1946:	48 c1 e8 09          	shr    $0x9,%rax
    194a:	48 b9 53 5a 9b a0 2f 	movabs $0x44b82fa09b5a53,%rcx
    1951:	b8 44 00 
    1954:	48 f7 e1             	mul    %rcx
    1957:	48 c1 ea 0b          	shr    $0xb,%rdx
    195b:	48 39 d3             	cmp    %rdx,%rbx
    195e:	0f 87 7a 01 00 00    	ja     1ade <main+0x78e>
    1964:	be 20 00 00 00       	mov    $0x20,%esi
    1969:	b9 40 04 00 00       	mov    $0x440,%ecx
    196e:	41 b9 60 09 00 00    	mov    $0x960,%r9d
    1974:	48 8d 7c 24 60       	lea    0x60(%rsp),%rdi
    1979:	4c 89 fa             	mov    %r15,%rdx
    197c:	4c 8d 84 24 50 09 00 	lea    0x950(%rsp),%r8
    1983:	00 
    1984:	e8 57 09 00 00       	call   22e0 <mlkem_decapsulate>
    1989:	89 c5                	mov    %eax,%ebp
    198b:	bf 01 00 00 00       	mov    $0x1,%edi
    1990:	48 8d 74 24 20       	lea    0x20(%rsp),%rsi
    1995:	e8 f6 f6 ff ff       	call   1090 <clock_gettime@plt>
    199a:	85 c0                	test   %eax,%eax
    199c:	0f 85 3c 01 00 00    	jne    1ade <main+0x78e>
    19a2:	48 8b 4c 24 20       	mov    0x20(%rsp),%rcx
    19a7:	48 85 c9             	test   %rcx,%rcx
    19aa:	0f 88 2e 01 00 00    	js     1ade <main+0x78e>
    19b0:	48 8b 74 24 28       	mov    0x28(%rsp),%rsi
    19b5:	48 85 f6             	test   %rsi,%rsi
    19b8:	0f 88 20 01 00 00    	js     1ade <main+0x78e>
    19be:	48 81 fe ff c9 9a 3b 	cmp    $0x3b9ac9ff,%rsi
    19c5:	0f 8f 13 01 00 00    	jg     1ade <main+0x78e>
    19cb:	48 89 f0             	mov    %rsi,%rax
    19ce:	48 f7 d0             	not    %rax
    19d1:	48 c1 e8 09          	shr    $0x9,%rax
    19d5:	48 ba 53 5a 9b a0 2f 	movabs $0x44b82fa09b5a53,%rdx
    19dc:	b8 44 00 
    19df:	48 f7 e2             	mul    %rdx
    19e2:	48 c1 ea 0b          	shr    $0xb,%rdx
    19e6:	48 39 d1             	cmp    %rdx,%rcx
    19e9:	0f 87 ef 00 00 00    	ja     1ade <main+0x78e>
    19ef:	48 69 d3 00 ca 9a 3b 	imul   $0x3b9aca00,%rbx,%rdx
    19f6:	4c 01 ea             	add    %r13,%rdx
    19f9:	48 69 c1 00 ca 9a 3b 	imul   $0x3b9aca00,%rcx,%rax
    1a00:	48 01 f0             	add    %rsi,%rax
    1a03:	48 29 d0             	sub    %rdx,%rax
    1a06:	0f 82 d2 00 00 00    	jb     1ade <main+0x78e>
    1a0c:	85 ed                	test   %ebp,%ebp
    1a0e:	0f 85 ca 00 00 00    	jne    1ade <main+0x78e>
    1a14:	49 89 87 48 04 00 00 	mov    %rax,0x448(%r15)
    1a1b:	44 89 e0             	mov    %r12d,%eax
    1a1e:	83 e0 1f             	and    $0x1f,%eax
    1a21:	0f b6 44 04 60       	movzbl 0x60(%rsp,%rax,1),%eax
    1a26:	30 05 f5 d6 00 00    	xor    %al,0xd6f5(%rip)        # f121 <result_sink>
    1a2c:	49 ff c4             	inc    %r12
    1a2f:	49 81 c7 50 04 00 00 	add    $0x450,%r15
    1a36:	4d 39 e6             	cmp    %r12,%r14
    1a39:	0f 85 c1 fe ff ff    	jne    1900 <main+0x5b0>
    1a3f:	48 8b 44 24 30       	mov    0x30(%rsp),%rax
    1a44:	48 8b 50 08          	mov    0x8(%rax),%rdx
    1a48:	48 8b 78 20          	mov    0x20(%rax),%rdi
    1a4c:	48 8b 70 28          	mov    0x28(%rax),%rsi
    1a50:	48 8b 4c 24 10       	mov    0x10(%rsp),%rcx
    1a55:	4c 8b 34 24          	mov    (%rsp),%r14
    1a59:	4d 89 f0             	mov    %r14,%r8
    1a5c:	48 8b 5c 24 08       	mov    0x8(%rsp),%rbx
    1a61:	49 89 d9             	mov    %rbx,%r9
    1a64:	48 8d 44 24 40       	lea    0x40(%rsp),%rax
    1a69:	50                   	push   %rax
    1a6a:	ff 74 24 40          	push   0x40(%rsp)
    1a6e:	e8 2d 01 00 00       	call   1ba0 <save_measurements>
    1a73:	48 83 c4 10          	add    $0x10,%rsp
    1a77:	89 c5                	mov    %eax,%ebp
    1a79:	48 8d bc 24 50 09 00 	lea    0x950(%rsp),%rdi
    1a80:	00 
    1a81:	be 60 09 00 00       	mov    $0x960,%esi
    1a86:	e8 75 10 00 00       	call   2b00 <erase_secret_bytes>
    1a8b:	48 8d 7c 24 60       	lea    0x60(%rsp),%rdi
    1a90:	be 20 00 00 00       	mov    $0x20,%esi
    1a95:	e8 66 10 00 00       	call   2b00 <erase_secret_bytes>
    1a9a:	4c 89 f7             	mov    %r14,%rdi
    1a9d:	e8 8e f5 ff ff       	call   1030 <free@plt>
    1aa2:	85 ed                	test   %ebp,%ebp
    1aa4:	75 62                	jne    1b08 <main+0x7b8>
    1aa6:	e8 95 09 00 00       	call   2440 <mlkem_implementation_name>
    1aab:	48 8d 3d 84 36 00 00 	lea    0x3684(%rip),%rdi        # 5136 <_IO_stdin_used+0x136>
    1ab2:	48 89 c6             	mov    %rax,%rsi
    1ab5:	48 89 da             	mov    %rbx,%rdx
    1ab8:	31 c0                	xor    %eax,%eax
    1aba:	e8 11 f6 ff ff       	call   10d0 <printf@plt>
    1abf:	31 c0                	xor    %eax,%eax
    1ac1:	e9 c0 00 00 00       	jmp    1b86 <main+0x836>
    1ac6:	48 8b 05 13 d5 00 00 	mov    0xd513(%rip),%rax        # efe0 <stderr@GLIBC_2.2.5>
    1acd:	48 8b 08             	mov    (%rax),%rcx
    1ad0:	48 8d 3d 2d 35 00 00 	lea    0x352d(%rip),%rdi        # 5004 <_IO_stdin_used+0x4>
    1ad7:	be 54 00 00 00       	mov    $0x54,%esi
    1adc:	eb 6a                	jmp    1b48 <main+0x7f8>
    1ade:	48 8d bc 24 50 09 00 	lea    0x950(%rsp),%rdi
    1ae5:	00 
    1ae6:	be 60 09 00 00       	mov    $0x960,%esi
    1aeb:	e8 10 10 00 00       	call   2b00 <erase_secret_bytes>
    1af0:	48 8d 7c 24 60       	lea    0x60(%rsp),%rdi
    1af5:	be 20 00 00 00       	mov    $0x20,%esi
    1afa:	e8 01 10 00 00       	call   2b00 <erase_secret_bytes>
    1aff:	48 8b 3c 24          	mov    (%rsp),%rdi
    1b03:	e8 28 f5 ff ff       	call   1030 <free@plt>
    1b08:	48 8b 05 d1 d4 00 00 	mov    0xd4d1(%rip),%rax        # efe0 <stderr@GLIBC_2.2.5>
    1b0f:	48 8b 08             	mov    (%rax),%rcx
    1b12:	48 8d 3d df 35 00 00 	lea    0x35df(%rip),%rdi        # 50f8 <_IO_stdin_used+0xf8>
    1b19:	be 3d 00 00 00       	mov    $0x3d,%esi
    1b1e:	eb 57                	jmp    1b77 <main+0x827>
    1b20:	48 89 df             	mov    %rbx,%rdi
    1b23:	e8 78 f5 ff ff       	call   10a0 <fclose@plt>
    1b28:	4c 89 ff             	mov    %r15,%rdi
    1b2b:	e8 00 f5 ff ff       	call   1030 <free@plt>
    1b30:	eb 2f                	jmp    1b61 <main+0x811>
    1b32:	48 8b 05 a7 d4 00 00 	mov    0xd4a7(%rip),%rax        # efe0 <stderr@GLIBC_2.2.5>
    1b39:	48 8b 08             	mov    (%rax),%rcx
    1b3c:	48 8d 3d 16 35 00 00 	lea    0x3516(%rip),%rdi        # 5059 <_IO_stdin_used+0x59>
    1b43:	be 30 00 00 00       	mov    $0x30,%esi
    1b48:	ba 01 00 00 00       	mov    $0x1,%edx
    1b4d:	e8 de f6 ff ff       	call   1230 <fwrite@plt>
    1b52:	b8 02 00 00 00       	mov    $0x2,%eax
    1b57:	eb 2d                	jmp    1b86 <main+0x836>
    1b59:	48 89 df             	mov    %rbx,%rdi
    1b5c:	e8 3f f5 ff ff       	call   10a0 <fclose@plt>
    1b61:	48 8b 05 78 d4 00 00 	mov    0xd478(%rip),%rax        # efe0 <stderr@GLIBC_2.2.5>
    1b68:	48 8b 08             	mov    (%rax),%rcx
    1b6b:	48 8d 3d 5e 35 00 00 	lea    0x355e(%rip),%rdi        # 50d0 <_IO_stdin_used+0xd0>
    1b72:	be 27 00 00 00       	mov    $0x27,%esi
    1b77:	ba 01 00 00 00       	mov    $0x1,%edx
    1b7c:	e8 af f6 ff ff       	call   1230 <fwrite@plt>
    1b81:	b8 01 00 00 00       	mov    $0x1,%eax
    1b86:	48 81 c4 58 19 00 00 	add    $0x1958,%rsp
    1b8d:	5b                   	pop    %rbx
    1b8e:	41 5c                	pop    %r12
    1b90:	41 5d                	pop    %r13
    1b92:	41 5e                	pop    %r14
    1b94:	41 5f                	pop    %r15
    1b96:	5d                   	pop    %rbp
    1b97:	c3                   	ret
    1b98:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    1b9f:	00 

0000000000001ba0 <save_measurements>:
    1ba0:	55                   	push   %rbp
    1ba1:	41 57                	push   %r15
    1ba3:	41 56                	push   %r14
    1ba5:	41 55                	push   %r13
    1ba7:	41 54                	push   %r12
    1ba9:	53                   	push   %rbx
    1baa:	48 81 ec b8 03 00 00 	sub    $0x3b8,%rsp
    1bb1:	4c 89 cb             	mov    %r9,%rbx
    1bb4:	4c 89 c5             	mov    %r8,%rbp
    1bb7:	49 89 cd             	mov    %rcx,%r13
    1bba:	48 89 54 24 18       	mov    %rdx,0x18(%rsp)
    1bbf:	49 89 f7             	mov    %rsi,%r15
    1bc2:	49 89 fe             	mov    %rdi,%r14
    1bc5:	31 ff                	xor    %edi,%edi
    1bc7:	e8 04 f6 ff ff       	call   11d0 <time@plt>
    1bcc:	49 89 c4             	mov    %rax,%r12
    1bcf:	48 8d bc 24 32 02 00 	lea    0x232(%rsp),%rdi
    1bd6:	00 
    1bd7:	e8 14 f5 ff ff       	call   10f0 <uname@plt>
    1bdc:	b9 01 00 00 00       	mov    $0x1,%ecx
    1be1:	85 c0                	test   %eax,%eax
    1be3:	0f 85 e0 02 00 00    	jne    1ec9 <save_measurements+0x329>
    1be9:	49 83 fc ff          	cmp    $0xffffffffffffffff,%r12
    1bed:	0f 84 d6 02 00 00    	je     1ec9 <save_measurements+0x329>
    1bf3:	4c 89 6c 24 20       	mov    %r13,0x20(%rsp)
    1bf8:	4c 89 64 24 28       	mov    %r12,0x28(%rsp)
    1bfd:	48 89 5c 24 10       	mov    %rbx,0x10(%rsp)
    1c02:	48 b8 75 6e 61 76 61 	movabs $0x616c696176616e75,%rax
    1c09:	69 6c 61 
    1c0c:	48 89 44 24 30       	mov    %rax,0x30(%rsp)
    1c11:	c7 44 24 38 62 6c 65 	movl   $0x656c62,0x38(%rsp)
    1c18:	00 
    1c19:	48 8d 3d 57 37 00 00 	lea    0x3757(%rip),%rdi        # 5377 <_IO_stdin_used+0x377>
    1c20:	48 8d 35 5e 37 00 00 	lea    0x375e(%rip),%rsi        # 5385 <_IO_stdin_used+0x385>
    1c27:	e8 f4 f5 ff ff       	call   1220 <fopen@plt>
    1c2c:	48 85 c0             	test   %rax,%rax
    1c2f:	0f 84 a3 00 00 00    	je     1cd8 <save_measurements+0x138>
    1c35:	49 89 c5             	mov    %rax,%r13
    1c38:	48 8d 9c 24 30 01 00 	lea    0x130(%rsp),%rbx
    1c3f:	00 
    1c40:	49 bc 6d 6f 64 65 6c 	movabs $0x616e206c65646f6d,%r12
    1c47:	20 6e 61 
    1c4a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1c50:	48 89 df             	mov    %rbx,%rdi
    1c53:	be 00 01 00 00       	mov    $0x100,%esi
    1c58:	4c 89 ea             	mov    %r13,%rdx
    1c5b:	e8 10 f5 ff ff       	call   1170 <fgets@plt>
    1c60:	48 85 c0             	test   %rax,%rax
    1c63:	74 6b                	je     1cd0 <save_measurements+0x130>
    1c65:	48 8b 84 24 30 01 00 	mov    0x130(%rsp),%rax
    1c6c:	00 
    1c6d:	4c 31 e0             	xor    %r12,%rax
    1c70:	0f b7 8c 24 38 01 00 	movzwl 0x138(%rsp),%ecx
    1c77:	00 
    1c78:	48 81 f1 6d 65 00 00 	xor    $0x656d,%rcx
    1c7f:	48 09 c1             	or     %rax,%rcx
    1c82:	75 cc                	jne    1c50 <save_measurements+0xb0>
    1c84:	48 8d bc 24 30 01 00 	lea    0x130(%rsp),%rdi
    1c8b:	00 
    1c8c:	be 3a 00 00 00       	mov    $0x3a,%esi
    1c91:	e8 2a f4 ff ff       	call   10c0 <strchr@plt>
    1c96:	48 85 c0             	test   %rax,%rax
    1c99:	74 35                	je     1cd0 <save_measurements+0x130>
    1c9b:	48 ff c0             	inc    %rax
    1c9e:	48 8d 15 ed 36 00 00 	lea    0x36ed(%rip),%rdx        # 5392 <_IO_stdin_used+0x392>
    1ca5:	48 8d 5c 24 30       	lea    0x30(%rsp),%rbx
    1caa:	be 00 01 00 00       	mov    $0x100,%esi
    1caf:	48 89 df             	mov    %rbx,%rdi
    1cb2:	48 89 c1             	mov    %rax,%rcx
    1cb5:	31 c0                	xor    %eax,%eax
    1cb7:	e8 24 f4 ff ff       	call   10e0 <snprintf@plt>
    1cbc:	48 8d 35 d2 36 00 00 	lea    0x36d2(%rip),%rsi        # 5395 <_IO_stdin_used+0x395>
    1cc3:	48 89 df             	mov    %rbx,%rdi
    1cc6:	e8 85 f4 ff ff       	call   1150 <strcspn@plt>
    1ccb:	c6 44 04 30 00       	movb   $0x0,0x30(%rsp,%rax,1)
    1cd0:	4c 89 ef             	mov    %r13,%rdi
    1cd3:	e8 c8 f3 ff ff       	call   10a0 <fclose@plt>
    1cd8:	48 8d 35 b1 34 00 00 	lea    0x34b1(%rip),%rsi        # 5190 <_IO_stdin_used+0x190>
    1cdf:	4c 89 f7             	mov    %r14,%rdi
    1ce2:	e8 39 f5 ff ff       	call   1220 <fopen@plt>
    1ce7:	48 85 c0             	test   %rax,%rax
    1cea:	4c 8b 6c 24 10       	mov    0x10(%rsp),%r13
    1cef:	0f 84 cf 01 00 00    	je     1ec4 <save_measurements+0x324>
    1cf5:	48 89 c3             	mov    %rax,%rbx
    1cf8:	48 8d 35 91 34 00 00 	lea    0x3491(%rip),%rsi        # 5190 <_IO_stdin_used+0x190>
    1cff:	4c 89 ff             	mov    %r15,%rdi
    1d02:	e8 19 f5 ff ff       	call   1220 <fopen@plt>
    1d07:	48 85 c0             	test   %rax,%rax
    1d0a:	0f 84 a4 01 00 00    	je     1eb4 <save_measurements+0x314>
    1d10:	49 89 c7             	mov    %rax,%r15
    1d13:	48 8d 35 79 34 00 00 	lea    0x3479(%rip),%rsi        # 5193 <_IO_stdin_used+0x193>
    1d1a:	48 89 5c 24 08       	mov    %rbx,0x8(%rsp)
    1d1f:	48 89 df             	mov    %rbx,%rdi
    1d22:	31 c0                	xor    %eax,%eax
    1d24:	e8 87 f4 ff ff       	call   11b0 <fprintf@plt>
    1d29:	41 89 c6             	mov    %eax,%r14d
    1d2c:	41 c1 ee 1f          	shr    $0x1f,%r14d
    1d30:	4d 85 ed             	test   %r13,%r13
    1d33:	74 74                	je     1da9 <save_measurements+0x209>
    1d35:	48 81 c5 48 04 00 00 	add    $0x448,%rbp
    1d3c:	31 db                	xor    %ebx,%ebx
    1d3e:	4c 8b 64 24 08       	mov    0x8(%rsp),%r12
    1d43:	66 66 66 66 2e 0f 1f 	data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
    1d4a:	84 00 00 00 00 00 
    1d50:	e8 eb 06 00 00       	call   2440 <mlkem_implementation_name>
    1d55:	49 89 c5             	mov    %rax,%r13
    1d58:	8b 7d f8             	mov    -0x8(%rbp),%edi
    1d5b:	e8 70 08 00 00       	call   25d0 <input_category_name>
    1d60:	48 83 ec 08          	sub    $0x8,%rsp
    1d64:	4c 89 e7             	mov    %r12,%rdi
    1d67:	48 8d 35 76 34 00 00 	lea    0x3476(%rip),%rsi        # 51e4 <_IO_stdin_used+0x1e4>
    1d6e:	48 8b 54 24 20       	mov    0x20(%rsp),%rdx
    1d73:	4c 89 e9             	mov    %r13,%rcx
    1d76:	4c 8b 6c 24 18       	mov    0x18(%rsp),%r13
    1d7b:	49 89 c0             	mov    %rax,%r8
    1d7e:	49 89 d9             	mov    %rbx,%r9
    1d81:	31 c0                	xor    %eax,%eax
    1d83:	ff 75 00             	push   0x0(%rbp)
    1d86:	e8 25 f4 ff ff       	call   11b0 <fprintf@plt>
    1d8b:	48 83 c4 10          	add    $0x10,%rsp
    1d8f:	85 c0                	test   %eax,%eax
    1d91:	b8 01 00 00 00       	mov    $0x1,%eax
    1d96:	44 0f 48 f0          	cmovs  %eax,%r14d
    1d9a:	48 ff c3             	inc    %rbx
    1d9d:	48 81 c5 50 04 00 00 	add    $0x450,%rbp
    1da4:	49 39 dd             	cmp    %rbx,%r13
    1da7:	75 a7                	jne    1d50 <save_measurements+0x1b0>
    1da9:	4c 8b a4 24 f8 03 00 	mov    0x3f8(%rsp),%r12
    1db0:	00 
    1db1:	e8 8a 06 00 00       	call   2440 <mlkem_implementation_name>
    1db6:	4c 8d 94 24 b4 02 00 	lea    0x2b4(%rsp),%r10
    1dbd:	00 
    1dbe:	4c 8d 9c 24 36 03 00 	lea    0x336(%rsp),%r11
    1dc5:	00 
    1dc6:	48 8d 5c 24 30       	lea    0x30(%rsp),%rbx
    1dcb:	48 8d 35 27 34 00 00 	lea    0x3427(%rip),%rsi        # 51f9 <_IO_stdin_used+0x1f9>
    1dd2:	4c 89 ff             	mov    %r15,%rdi
    1dd5:	48 8b 54 24 18       	mov    0x18(%rsp),%rdx
    1dda:	48 89 c1             	mov    %rax,%rcx
    1ddd:	4c 8b 44 24 20       	mov    0x20(%rsp),%r8
    1de2:	4d 89 e9             	mov    %r13,%r9
    1de5:	31 c0                	xor    %eax,%eax
    1de7:	53                   	push   %rbx
    1de8:	41 53                	push   %r11
    1dea:	41 52                	push   %r10
    1dec:	4c 8d 94 24 4a 02 00 	lea    0x24a(%rsp),%r10
    1df3:	00 
    1df4:	41 52                	push   %r10
    1df6:	ff 74 24 48          	push   0x48(%rsp)
    1dfa:	ff b4 24 18 04 00 00 	push   0x418(%rsp)
    1e01:	e8 aa f3 ff ff       	call   11b0 <fprintf@plt>
    1e06:	48 83 c4 30          	add    $0x30,%rsp
    1e0a:	85 c0                	test   %eax,%eax
    1e0c:	bd 01 00 00 00       	mov    $0x1,%ebp
    1e11:	44 0f 48 f5          	cmovs  %ebp,%r14d
    1e15:	48 8d 1d 4a 35 00 00 	lea    0x354a(%rip),%rbx        # 5366 <_IO_stdin_used+0x366>
    1e1c:	45 31 ed             	xor    %r13d,%r13d
    1e1f:	90                   	nop
    1e20:	43 0f b6 14 2c       	movzbl (%r12,%r13,1),%edx
    1e25:	4c 89 ff             	mov    %r15,%rdi
    1e28:	48 89 de             	mov    %rbx,%rsi
    1e2b:	31 c0                	xor    %eax,%eax
    1e2d:	e8 7e f3 ff ff       	call   11b0 <fprintf@plt>
    1e32:	85 c0                	test   %eax,%eax
    1e34:	44 0f 48 f5          	cmovs  %ebp,%r14d
    1e38:	49 ff c5             	inc    %r13
    1e3b:	49 83 fd 20          	cmp    $0x20,%r13
    1e3f:	75 df                	jne    1e20 <save_measurements+0x280>
    1e41:	bf 0a 00 00 00       	mov    $0xa,%edi
    1e46:	4c 89 fe             	mov    %r15,%rsi
    1e49:	e8 f2 f2 ff ff       	call   1140 <fputc@plt>
    1e4e:	83 f8 ff             	cmp    $0xffffffff,%eax
    1e51:	bb 01 00 00 00       	mov    $0x1,%ebx
    1e56:	44 0f 44 f3          	cmove  %ebx,%r14d
    1e5a:	45 31 e4             	xor    %r12d,%r12d
    1e5d:	4c 8d 2d f4 a5 00 00 	lea    0xa5f4(%rip),%r13        # c458 <reltable.save_measurements>
    1e64:	66 66 66 2e 0f 1f 84 	data16 data16 cs nopw 0x0(%rax,%rax,1)
    1e6b:	00 00 00 00 00 
    1e70:	4b 63 3c 2c          	movslq (%r12,%r13,1),%rdi
    1e74:	4c 01 ef             	add    %r13,%rdi
    1e77:	4c 89 fe             	mov    %r15,%rsi
    1e7a:	e8 81 f2 ff ff       	call   1100 <fputs@plt>
    1e7f:	83 f8 ff             	cmp    $0xffffffff,%eax
    1e82:	44 0f 44 f3          	cmove  %ebx,%r14d
    1e86:	49 83 c4 04          	add    $0x4,%r12
    1e8a:	49 81 fc 24 04 00 00 	cmp    $0x424,%r12
    1e91:	75 dd                	jne    1e70 <save_measurements+0x2d0>
    1e93:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    1e98:	e8 03 f2 ff ff       	call   10a0 <fclose@plt>
    1e9d:	89 c3                	mov    %eax,%ebx
    1e9f:	4c 89 ff             	mov    %r15,%rdi
    1ea2:	e8 f9 f1 ff ff       	call   10a0 <fclose@plt>
    1ea7:	09 d8                	or     %ebx,%eax
    1ea9:	b9 01 00 00 00       	mov    $0x1,%ecx
    1eae:	41 0f 44 ce          	cmove  %r14d,%ecx
    1eb2:	eb 15                	jmp    1ec9 <save_measurements+0x329>
    1eb4:	48 89 df             	mov    %rbx,%rdi
    1eb7:	e8 e4 f1 ff ff       	call   10a0 <fclose@plt>
    1ebc:	4c 89 f7             	mov    %r14,%rdi
    1ebf:	e8 8c f1 ff ff       	call   1050 <remove@plt>
    1ec4:	b9 01 00 00 00       	mov    $0x1,%ecx
    1ec9:	89 c8                	mov    %ecx,%eax
    1ecb:	48 81 c4 b8 03 00 00 	add    $0x3b8,%rsp
    1ed2:	5b                   	pop    %rbx
    1ed3:	41 5c                	pop    %r12
    1ed5:	41 5d                	pop    %r13
    1ed7:	41 5e                	pop    %r14
    1ed9:	41 5f                	pop    %r15
    1edb:	5d                   	pop    %rbp
    1edc:	c3                   	ret
    1edd:	0f 1f 00             	nopl   (%rax)

0000000000001ee0 <platform_m2_randombytes>:
    1ee0:	41 56                	push   %r14
    1ee2:	53                   	push   %rbx
    1ee3:	50                   	push   %rax
    1ee4:	64 48 8b 04 25 00 00 	mov    %fs:0x0,%rax
    1eeb:	00 00 
    1eed:	4c 8d b0 a8 ff ff ff 	lea    -0x58(%rax),%r14
    1ef4:	48 85 ff             	test   %rdi,%rdi
    1ef7:	74 33                	je     1f2c <platform_m2_randombytes+0x4c>
    1ef9:	48 89 f3             	mov    %rsi,%rbx
    1efc:	41 83 7e 50 00       	cmpl   $0x0,0x50(%r14)
    1f01:	75 10                	jne    1f13 <platform_m2_randombytes+0x33>
    1f03:	49 8b 46 40          	mov    0x40(%r14),%rax
    1f07:	49 8b 76 48          	mov    0x48(%r14),%rsi
    1f0b:	48 29 f0             	sub    %rsi,%rax
    1f0e:	48 39 d8             	cmp    %rbx,%rax
    1f11:	73 23                	jae    1f36 <platform_m2_randombytes+0x56>
    1f13:	41 c7 46 50 01 00 00 	movl   $0x1,0x50(%r14)
    1f1a:	00 
    1f1b:	31 f6                	xor    %esi,%esi
    1f1d:	48 89 da             	mov    %rbx,%rdx
    1f20:	48 83 c4 08          	add    $0x8,%rsp
    1f24:	5b                   	pop    %rbx
    1f25:	41 5e                	pop    %r14
    1f27:	e9 e4 f1 ff ff       	jmp    1110 <memset@plt>
    1f2c:	41 c7 46 50 01 00 00 	movl   $0x1,0x50(%r14)
    1f33:	00 
    1f34:	eb 0f                	jmp    1f45 <platform_m2_randombytes+0x65>
    1f36:	4c 01 f6             	add    %r14,%rsi
    1f39:	48 89 da             	mov    %rbx,%rdx
    1f3c:	e8 7f f2 ff ff       	call   11c0 <memcpy@plt>
    1f41:	49 01 5e 48          	add    %rbx,0x48(%r14)
    1f45:	48 83 c4 08          	add    $0x8,%rsp
    1f49:	5b                   	pop    %rbx
    1f4a:	41 5e                	pop    %r14
    1f4c:	c3                   	ret
    1f4d:	0f 1f 00             	nopl   (%rax)

0000000000001f50 <platform_m2_test_keypair>:
    1f50:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    1f55:	48 85 ff             	test   %rdi,%rdi
    1f58:	0f 84 f0 00 00 00    	je     204e <platform_m2_test_keypair+0xfe>
    1f5e:	41 57                	push   %r15
    1f60:	41 56                	push   %r14
    1f62:	41 54                	push   %r12
    1f64:	53                   	push   %rbx
    1f65:	50                   	push   %rax
    1f66:	48 89 f3             	mov    %rsi,%rbx
    1f69:	48 85 f6             	test   %rsi,%rsi
    1f6c:	0f 84 d1 00 00 00    	je     2043 <platform_m2_test_keypair+0xf3>
    1f72:	49 89 d4             	mov    %rdx,%r12
    1f75:	48 85 d2             	test   %rdx,%rdx
    1f78:	0f 84 c5 00 00 00    	je     2043 <platform_m2_test_keypair+0xf3>
    1f7e:	49 89 fe             	mov    %rdi,%r14
    1f81:	64 48 8b 04 25 00 00 	mov    %fs:0x0,%rax
    1f88:	00 00 
    1f8a:	4c 8d b8 a8 ff ff ff 	lea    -0x58(%rax),%r15
    1f91:	be 58 00 00 00       	mov    $0x58,%esi
    1f96:	4c 89 ff             	mov    %r15,%rdi
    1f99:	e8 62 0b 00 00       	call   2b00 <erase_secret_bytes>
    1f9e:	41 0f 10 04 24       	movups (%r12),%xmm0
    1fa3:	41 0f 10 4c 24 10    	movups 0x10(%r12),%xmm1
    1fa9:	41 0f 10 54 24 20    	movups 0x20(%r12),%xmm2
    1faf:	41 0f 10 5c 24 30    	movups 0x30(%r12),%xmm3
    1fb5:	64 0f 11 1c 25 d8 ff 	movups %xmm3,%fs:0xffffffffffffffd8
    1fbc:	ff ff 
    1fbe:	64 0f 11 14 25 c8 ff 	movups %xmm2,%fs:0xffffffffffffffc8
    1fc5:	ff ff 
    1fc7:	64 0f 11 0c 25 b8 ff 	movups %xmm1,%fs:0xffffffffffffffb8
    1fce:	ff ff 
    1fd0:	64 0f 11 04 25 a8 ff 	movups %xmm0,%fs:0xffffffffffffffa8
    1fd7:	ff ff 
    1fd9:	64 48 c7 04 25 e8 ff 	movq   $0x40,%fs:0xffffffffffffffe8
    1fe0:	ff ff 40 00 00 00 
    1fe6:	4c 89 f7             	mov    %r14,%rdi
    1fe9:	48 89 de             	mov    %rbx,%rsi
    1fec:	e8 6b 0d 00 00       	call   2d5c <pqcrystals_kyber768_ref_keypair>
    1ff1:	64 83 3c 25 f8 ff ff 	cmpl   $0x0,%fs:0xfffffffffffffff8
    1ff8:	ff 00 
    1ffa:	75 1b                	jne    2017 <platform_m2_test_keypair+0xc7>
    1ffc:	49 8b 47 48          	mov    0x48(%r15),%rax
    2000:	49 3b 47 40          	cmp    0x40(%r15),%rax
    2004:	75 11                	jne    2017 <platform_m2_test_keypair+0xc7>
    2006:	be 58 00 00 00       	mov    $0x58,%esi
    200b:	4c 89 ff             	mov    %r15,%rdi
    200e:	e8 ed 0a 00 00       	call   2b00 <erase_secret_bytes>
    2013:	31 c0                	xor    %eax,%eax
    2015:	eb 2c                	jmp    2043 <platform_m2_test_keypair+0xf3>
    2017:	be 58 00 00 00       	mov    $0x58,%esi
    201c:	4c 89 ff             	mov    %r15,%rdi
    201f:	e8 dc 0a 00 00       	call   2b00 <erase_secret_bytes>
    2024:	be a0 04 00 00       	mov    $0x4a0,%esi
    2029:	4c 89 f7             	mov    %r14,%rdi
    202c:	e8 cf 0a 00 00       	call   2b00 <erase_secret_bytes>
    2031:	be 60 09 00 00       	mov    $0x960,%esi
    2036:	48 89 df             	mov    %rbx,%rdi
    2039:	e8 c2 0a 00 00       	call   2b00 <erase_secret_bytes>
    203e:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    2043:	48 83 c4 08          	add    $0x8,%rsp
    2047:	5b                   	pop    %rbx
    2048:	41 5c                	pop    %r12
    204a:	41 5e                	pop    %r14
    204c:	41 5f                	pop    %r15
    204e:	c3                   	ret
    204f:	90                   	nop

0000000000002050 <platform_m2_test_encapsulate>:
    2050:	41 57                	push   %r15
    2052:	41 56                	push   %r14
    2054:	41 55                	push   %r13
    2056:	41 54                	push   %r12
    2058:	53                   	push   %rbx
    2059:	49 89 cf             	mov    %rcx,%r15
    205c:	66 48 0f 6e c7       	movq   %rdi,%xmm0
    2061:	66 48 0f 6e ce       	movq   %rsi,%xmm1
    2066:	66 0f 6c c8          	punpcklqdq %xmm0,%xmm1
    206a:	66 48 0f 6e c1       	movq   %rcx,%xmm0
    206f:	66 48 0f 6e d2       	movq   %rdx,%xmm2
    2074:	66 0f 6c d0          	punpcklqdq %xmm0,%xmm2
    2078:	66 0f ef c0          	pxor   %xmm0,%xmm0
    207c:	66 0f 76 d0          	pcmpeqd %xmm0,%xmm2
    2080:	66 0f 76 c8          	pcmpeqd %xmm0,%xmm1
    2084:	66 0f 6f c1          	movdqa %xmm1,%xmm0
    2088:	0f c6 c2 dd          	shufps $0xdd,%xmm2,%xmm0
    208c:	0f c6 ca 88          	shufps $0x88,%xmm2,%xmm1
    2090:	0f 54 c8             	andps  %xmm0,%xmm1
    2093:	0f 50 c9             	movmskps %xmm1,%ecx
    2096:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    209b:	85 c9                	test   %ecx,%ecx
    209d:	0f 85 b0 00 00 00    	jne    2153 <platform_m2_test_encapsulate+0x103>
    20a3:	48 89 f3             	mov    %rsi,%rbx
    20a6:	49 89 fe             	mov    %rdi,%r14
    20a9:	64 48 8b 04 25 00 00 	mov    %fs:0x0,%rax
    20b0:	00 00 
    20b2:	4c 8d a0 a8 ff ff ff 	lea    -0x58(%rax),%r12
    20b9:	be 58 00 00 00       	mov    $0x58,%esi
    20be:	4c 89 e7             	mov    %r12,%rdi
    20c1:	49 89 d5             	mov    %rdx,%r13
    20c4:	e8 37 0a 00 00       	call   2b00 <erase_secret_bytes>
    20c9:	41 0f 10 07          	movups (%r15),%xmm0
    20cd:	41 0f 10 4f 10       	movups 0x10(%r15),%xmm1
    20d2:	64 0f 11 0c 25 b8 ff 	movups %xmm1,%fs:0xffffffffffffffb8
    20d9:	ff ff 
    20db:	64 0f 11 04 25 a8 ff 	movups %xmm0,%fs:0xffffffffffffffa8
    20e2:	ff ff 
    20e4:	64 48 c7 04 25 e8 ff 	movq   $0x20,%fs:0xffffffffffffffe8
    20eb:	ff ff 20 00 00 00 
    20f1:	4c 89 f7             	mov    %r14,%rdi
    20f4:	48 89 de             	mov    %rbx,%rsi
    20f7:	4c 89 ea             	mov    %r13,%rdx
    20fa:	e8 b6 0c 00 00       	call   2db5 <pqcrystals_kyber768_ref_enc>
    20ff:	64 83 3c 25 f8 ff ff 	cmpl   $0x0,%fs:0xfffffffffffffff8
    2106:	ff 00 
    2108:	75 1d                	jne    2127 <platform_m2_test_encapsulate+0xd7>
    210a:	49 8b 44 24 48       	mov    0x48(%r12),%rax
    210f:	49 3b 44 24 40       	cmp    0x40(%r12),%rax
    2114:	75 11                	jne    2127 <platform_m2_test_encapsulate+0xd7>
    2116:	be 58 00 00 00       	mov    $0x58,%esi
    211b:	4c 89 e7             	mov    %r12,%rdi
    211e:	e8 dd 09 00 00       	call   2b00 <erase_secret_bytes>
    2123:	31 c0                	xor    %eax,%eax
    2125:	eb 2c                	jmp    2153 <platform_m2_test_encapsulate+0x103>
    2127:	be 58 00 00 00       	mov    $0x58,%esi
    212c:	4c 89 e7             	mov    %r12,%rdi
    212f:	e8 cc 09 00 00       	call   2b00 <erase_secret_bytes>
    2134:	be 40 04 00 00       	mov    $0x440,%esi
    2139:	4c 89 f7             	mov    %r14,%rdi
    213c:	e8 bf 09 00 00       	call   2b00 <erase_secret_bytes>
    2141:	be 20 00 00 00       	mov    $0x20,%esi
    2146:	48 89 df             	mov    %rbx,%rdi
    2149:	e8 b2 09 00 00       	call   2b00 <erase_secret_bytes>
    214e:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    2153:	5b                   	pop    %rbx
    2154:	41 5c                	pop    %r12
    2156:	41 5d                	pop    %r13
    2158:	41 5e                	pop    %r14
    215a:	41 5f                	pop    %r15
    215c:	c3                   	ret
    215d:	0f 1f 00             	nopl   (%rax)

0000000000002160 <mlkem_generate_key_pair>:
    2160:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    2165:	48 81 f9 60 09 00 00 	cmp    $0x960,%rcx
    216c:	0f 85 98 00 00 00    	jne    220a <mlkem_generate_key_pair+0xaa>
    2172:	48 81 fe a0 04 00 00 	cmp    $0x4a0,%rsi
    2179:	0f 85 8b 00 00 00    	jne    220a <mlkem_generate_key_pair+0xaa>
    217f:	55                   	push   %rbp
    2180:	41 57                	push   %r15
    2182:	41 56                	push   %r14
    2184:	53                   	push   %rbx
    2185:	48 83 ec 48          	sub    $0x48,%rsp
    2189:	49 89 fe             	mov    %rdi,%r14
    218c:	48 85 ff             	test   %rdi,%rdi
    218f:	74 6f                	je     2200 <mlkem_generate_key_pair+0xa0>
    2191:	48 89 d3             	mov    %rdx,%rbx
    2194:	48 85 d2             	test   %rdx,%rdx
    2197:	74 67                	je     2200 <mlkem_generate_key_pair+0xa0>
    2199:	48 89 e7             	mov    %rsp,%rdi
    219c:	be 40 00 00 00       	mov    $0x40,%esi
    21a1:	e8 da 09 00 00       	call   2b80 <system_random_bytes>
    21a6:	85 c0                	test   %eax,%eax
    21a8:	74 12                	je     21bc <mlkem_generate_key_pair+0x5c>
    21aa:	41 89 c7             	mov    %eax,%r15d
    21ad:	48 89 e7             	mov    %rsp,%rdi
    21b0:	be 40 00 00 00       	mov    $0x40,%esi
    21b5:	e8 46 09 00 00       	call   2b00 <erase_secret_bytes>
    21ba:	eb 27                	jmp    21e3 <mlkem_generate_key_pair+0x83>
    21bc:	49 89 e7             	mov    %rsp,%r15
    21bf:	4c 89 f7             	mov    %r14,%rdi
    21c2:	48 89 de             	mov    %rbx,%rsi
    21c5:	4c 89 fa             	mov    %r15,%rdx
    21c8:	e8 83 fd ff ff       	call   1f50 <platform_m2_test_keypair>
    21cd:	89 c5                	mov    %eax,%ebp
    21cf:	be 40 00 00 00       	mov    $0x40,%esi
    21d4:	4c 89 ff             	mov    %r15,%rdi
    21d7:	e8 24 09 00 00       	call   2b00 <erase_secret_bytes>
    21dc:	41 89 ef             	mov    %ebp,%r15d
    21df:	85 ed                	test   %ebp,%ebp
    21e1:	74 28                	je     220b <mlkem_generate_key_pair+0xab>
    21e3:	be a0 04 00 00       	mov    $0x4a0,%esi
    21e8:	4c 89 f7             	mov    %r14,%rdi
    21eb:	e8 10 09 00 00       	call   2b00 <erase_secret_bytes>
    21f0:	be 60 09 00 00       	mov    $0x960,%esi
    21f5:	48 89 df             	mov    %rbx,%rdi
    21f8:	e8 03 09 00 00       	call   2b00 <erase_secret_bytes>
    21fd:	44 89 f8             	mov    %r15d,%eax
    2200:	48 83 c4 48          	add    $0x48,%rsp
    2204:	5b                   	pop    %rbx
    2205:	41 5e                	pop    %r14
    2207:	41 5f                	pop    %r15
    2209:	5d                   	pop    %rbp
    220a:	c3                   	ret
    220b:	31 c0                	xor    %eax,%eax
    220d:	eb f1                	jmp    2200 <mlkem_generate_key_pair+0xa0>
    220f:	90                   	nop

0000000000002210 <mlkem_encapsulate>:
    2210:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    2215:	49 81 f9 a0 04 00 00 	cmp    $0x4a0,%r9
    221c:	0f 85 b1 00 00 00    	jne    22d3 <mlkem_encapsulate+0xc3>
    2222:	48 83 f9 20          	cmp    $0x20,%rcx
    2226:	0f 85 a7 00 00 00    	jne    22d3 <mlkem_encapsulate+0xc3>
    222c:	48 81 fe 40 04 00 00 	cmp    $0x440,%rsi
    2233:	0f 85 9a 00 00 00    	jne    22d3 <mlkem_encapsulate+0xc3>
    2239:	55                   	push   %rbp
    223a:	41 57                	push   %r15
    223c:	41 56                	push   %r14
    223e:	41 54                	push   %r12
    2240:	53                   	push   %rbx
    2241:	48 83 ec 20          	sub    $0x20,%rsp
    2245:	49 89 fe             	mov    %rdi,%r14
    2248:	48 85 ff             	test   %rdi,%rdi
    224b:	74 7a                	je     22c7 <mlkem_encapsulate+0xb7>
    224d:	48 89 d3             	mov    %rdx,%rbx
    2250:	48 85 d2             	test   %rdx,%rdx
    2253:	74 72                	je     22c7 <mlkem_encapsulate+0xb7>
    2255:	4d 85 c0             	test   %r8,%r8
    2258:	74 6d                	je     22c7 <mlkem_encapsulate+0xb7>
    225a:	4d 89 c7             	mov    %r8,%r15
    225d:	48 89 e7             	mov    %rsp,%rdi
    2260:	be 20 00 00 00       	mov    $0x20,%esi
    2265:	e8 16 09 00 00       	call   2b80 <system_random_bytes>
    226a:	85 c0                	test   %eax,%eax
    226c:	74 12                	je     2280 <mlkem_encapsulate+0x70>
    226e:	41 89 c7             	mov    %eax,%r15d
    2271:	48 89 e7             	mov    %rsp,%rdi
    2274:	be 20 00 00 00       	mov    $0x20,%esi
    2279:	e8 82 08 00 00       	call   2b00 <erase_secret_bytes>
    227e:	eb 2a                	jmp    22aa <mlkem_encapsulate+0x9a>
    2280:	49 89 e4             	mov    %rsp,%r12
    2283:	4c 89 f7             	mov    %r14,%rdi
    2286:	48 89 de             	mov    %rbx,%rsi
    2289:	4c 89 fa             	mov    %r15,%rdx
    228c:	4c 89 e1             	mov    %r12,%rcx
    228f:	e8 bc fd ff ff       	call   2050 <platform_m2_test_encapsulate>
    2294:	89 c5                	mov    %eax,%ebp
    2296:	be 20 00 00 00       	mov    $0x20,%esi
    229b:	4c 89 e7             	mov    %r12,%rdi
    229e:	e8 5d 08 00 00       	call   2b00 <erase_secret_bytes>
    22a3:	41 89 ef             	mov    %ebp,%r15d
    22a6:	85 ed                	test   %ebp,%ebp
    22a8:	74 2a                	je     22d4 <mlkem_encapsulate+0xc4>
    22aa:	be 40 04 00 00       	mov    $0x440,%esi
    22af:	4c 89 f7             	mov    %r14,%rdi
    22b2:	e8 49 08 00 00       	call   2b00 <erase_secret_bytes>
    22b7:	be 20 00 00 00       	mov    $0x20,%esi
    22bc:	48 89 df             	mov    %rbx,%rdi
    22bf:	e8 3c 08 00 00       	call   2b00 <erase_secret_bytes>
    22c4:	44 89 f8             	mov    %r15d,%eax
    22c7:	48 83 c4 20          	add    $0x20,%rsp
    22cb:	5b                   	pop    %rbx
    22cc:	41 5c                	pop    %r12
    22ce:	41 5e                	pop    %r14
    22d0:	41 5f                	pop    %r15
    22d2:	5d                   	pop    %rbp
    22d3:	c3                   	ret
    22d4:	31 c0                	xor    %eax,%eax
    22d6:	eb ef                	jmp    22c7 <mlkem_encapsulate+0xb7>
    22d8:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    22df:	00 

00000000000022e0 <mlkem_decapsulate>:
    22e0:	49 81 f9 60 09 00 00 	cmp    $0x960,%r9
    22e7:	75 29                	jne    2312 <mlkem_decapsulate+0x32>
    22e9:	48 81 f9 40 04 00 00 	cmp    $0x440,%rcx
    22f0:	75 20                	jne    2312 <mlkem_decapsulate+0x32>
    22f2:	48 83 fe 20          	cmp    $0x20,%rsi
    22f6:	75 1a                	jne    2312 <mlkem_decapsulate+0x32>
    22f8:	48 85 ff             	test   %rdi,%rdi
    22fb:	74 15                	je     2312 <mlkem_decapsulate+0x32>
    22fd:	48 85 d2             	test   %rdx,%rdx
    2300:	74 10                	je     2312 <mlkem_decapsulate+0x32>
    2302:	4d 85 c0             	test   %r8,%r8
    2305:	74 0b                	je     2312 <mlkem_decapsulate+0x32>
    2307:	48 89 d6             	mov    %rdx,%rsi
    230a:	4c 89 c2             	mov    %r8,%rdx
    230d:	e9 55 0b 00 00       	jmp    2e67 <pqcrystals_kyber768_ref_dec>
    2312:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    2317:	c3                   	ret
    2318:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    231f:	00 

0000000000002320 <platform_m2_test_message>:
    2320:	55                   	push   %rbp
    2321:	41 57                	push   %r15
    2323:	41 56                	push   %r14
    2325:	41 55                	push   %r13
    2327:	41 54                	push   %r12
    2329:	53                   	push   %rbx
    232a:	48 81 ec 88 00 00 00 	sub    $0x88,%rsp
    2331:	48 89 f3             	mov    %rsi,%rbx
    2334:	66 48 0f 6e c7       	movq   %rdi,%xmm0
    2339:	66 48 0f 6e ce       	movq   %rsi,%xmm1
    233e:	66 0f 6c c8          	punpcklqdq %xmm0,%xmm1
    2342:	66 48 0f 6e c1       	movq   %rcx,%xmm0
    2347:	66 48 0f 6e d2       	movq   %rdx,%xmm2
    234c:	66 0f 6c d0          	punpcklqdq %xmm0,%xmm2
    2350:	66 0f ef c0          	pxor   %xmm0,%xmm0
    2354:	66 0f 76 d0          	pcmpeqd %xmm0,%xmm2
    2358:	66 0f 76 c8          	pcmpeqd %xmm0,%xmm1
    235c:	66 0f 6f c1          	movdqa %xmm1,%xmm0
    2360:	0f c6 c2 dd          	shufps $0xdd,%xmm2,%xmm0
    2364:	0f c6 ca 88          	shufps $0x88,%xmm2,%xmm1
    2368:	0f 54 c8             	andps  %xmm0,%xmm1
    236b:	0f 50 f1             	movmskps %xmm1,%esi
    236e:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    2373:	85 f6                	test   %esi,%esi
    2375:	0f 85 97 00 00 00    	jne    2412 <platform_m2_test_message+0xf2>
    237b:	49 89 fe             	mov    %rdi,%r14
    237e:	0f 10 01             	movups (%rcx),%xmm0
    2381:	0f 10 49 10          	movups 0x10(%rcx),%xmm1
    2385:	0f 29 4c 24 10       	movaps %xmm1,0x10(%rsp)
    238a:	0f 29 04 24          	movaps %xmm0,(%rsp)
    238e:	48 8d 7c 24 20       	lea    0x20(%rsp),%rdi
    2393:	49 89 d5             	mov    %rdx,%r13
    2396:	ba a0 04 00 00       	mov    $0x4a0,%edx
    239b:	4c 89 ee             	mov    %r13,%rsi
    239e:	48 89 cd             	mov    %rcx,%rbp
    23a1:	e8 70 1f 00 00       	call   4316 <pqcrystals_kyber_fips202_ref_sha3_256>
    23a6:	4c 8d 7c 24 40       	lea    0x40(%rsp),%r15
    23ab:	48 89 e6             	mov    %rsp,%rsi
    23ae:	ba 40 00 00 00       	mov    $0x40,%edx
    23b3:	4c 89 ff             	mov    %r15,%rdi
    23b6:	e8 84 28 00 00       	call   4c3f <pqcrystals_kyber_fips202_ref_sha3_512>
    23bb:	4c 8d 64 24 60       	lea    0x60(%rsp),%r12
    23c0:	4c 89 f7             	mov    %r14,%rdi
    23c3:	48 89 ee             	mov    %rbp,%rsi
    23c6:	4c 89 ea             	mov    %r13,%rdx
    23c9:	4c 89 e1             	mov    %r12,%rcx
    23cc:	e8 b2 0e 00 00       	call   3283 <pqcrystals_kyber768_ref_indcpa_enc>
    23d1:	ba 40 04 00 00       	mov    $0x440,%edx
    23d6:	4c 89 e7             	mov    %r12,%rdi
    23d9:	4c 89 f6             	mov    %r14,%rsi
    23dc:	e8 35 1f 00 00       	call   4316 <pqcrystals_kyber_fips202_ref_sha3_256>
    23e1:	be 20 00 00 00       	mov    $0x20,%esi
    23e6:	b9 40 00 00 00       	mov    $0x40,%ecx
    23eb:	48 89 df             	mov    %rbx,%rdi
    23ee:	4c 89 fa             	mov    %r15,%rdx
    23f1:	e8 b4 1e 00 00       	call   42aa <pqcrystals_kyber_fips202_ref_shake256>
    23f6:	be 40 00 00 00       	mov    $0x40,%esi
    23fb:	48 89 e7             	mov    %rsp,%rdi
    23fe:	e8 fd 06 00 00       	call   2b00 <erase_secret_bytes>
    2403:	be 40 00 00 00       	mov    $0x40,%esi
    2408:	4c 89 ff             	mov    %r15,%rdi
    240b:	e8 f0 06 00 00       	call   2b00 <erase_secret_bytes>
    2410:	31 c0                	xor    %eax,%eax
    2412:	48 81 c4 88 00 00 00 	add    $0x88,%rsp
    2419:	5b                   	pop    %rbx
    241a:	41 5c                	pop    %r12
    241c:	41 5d                	pop    %r13
    241e:	41 5e                	pop    %r14
    2420:	41 5f                	pop    %r15
    2422:	5d                   	pop    %rbp
    2423:	c3                   	ret
    2424:	66 66 66 2e 0f 1f 84 	data16 data16 cs nopw 0x0(%rax,%rax,1)
    242b:	00 00 00 00 00 

0000000000002430 <platform_m2_sha3_256>:
    2430:	e9 e1 1e 00 00       	jmp    4316 <pqcrystals_kyber_fips202_ref_sha3_256>
    2435:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    243c:	00 00 00 00 

0000000000002440 <mlkem_implementation_name>:
    2440:	48 8d 05 b3 9f 00 00 	lea    0x9fb3(%rip),%rax        # c3fa <_IO_stdin_used+0x73fa>
    2447:	c3                   	ret
    2448:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    244f:	00 

0000000000002450 <mlkem_self_test>:
    2450:	41 56                	push   %r14
    2452:	53                   	push   %rbx
    2453:	48 81 ec 88 12 00 00 	sub    $0x1288,%rsp
    245a:	48 8d 7c 24 40       	lea    0x40(%rsp),%rdi
    245f:	be 40 00 00 00       	mov    $0x40,%esi
    2464:	e8 17 07 00 00       	call   2b80 <system_random_bytes>
    2469:	85 c0                	test   %eax,%eax
    246b:	74 13                	je     2480 <mlkem_self_test+0x30>
    246d:	89 c3                	mov    %eax,%ebx
    246f:	48 8d 7c 24 40       	lea    0x40(%rsp),%rdi
    2474:	be 40 00 00 00       	mov    $0x40,%esi
    2479:	e8 82 06 00 00       	call   2b00 <erase_secret_bytes>
    247e:	eb 30                	jmp    24b0 <mlkem_self_test+0x60>
    2480:	48 8d bc 24 80 04 00 	lea    0x480(%rsp),%rdi
    2487:	00 
    2488:	48 8d b4 24 20 09 00 	lea    0x920(%rsp),%rsi
    248f:	00 
    2490:	4c 8d 74 24 40       	lea    0x40(%rsp),%r14
    2495:	4c 89 f2             	mov    %r14,%rdx
    2498:	e8 b3 fa ff ff       	call   1f50 <platform_m2_test_keypair>
    249d:	89 c3                	mov    %eax,%ebx
    249f:	be 40 00 00 00       	mov    $0x40,%esi
    24a4:	4c 89 f7             	mov    %r14,%rdi
    24a7:	e8 54 06 00 00       	call   2b00 <erase_secret_bytes>
    24ac:	85 db                	test   %ebx,%ebx
    24ae:	74 5f                	je     250f <mlkem_self_test+0xbf>
    24b0:	48 8d bc 24 80 04 00 	lea    0x480(%rsp),%rdi
    24b7:	00 
    24b8:	be a0 04 00 00       	mov    $0x4a0,%esi
    24bd:	e8 3e 06 00 00       	call   2b00 <erase_secret_bytes>
    24c2:	48 8d bc 24 20 09 00 	lea    0x920(%rsp),%rdi
    24c9:	00 
    24ca:	be 60 09 00 00       	mov    $0x960,%esi
    24cf:	e8 2c 06 00 00       	call   2b00 <erase_secret_bytes>
    24d4:	48 8d bc 24 20 09 00 	lea    0x920(%rsp),%rdi
    24db:	00 
    24dc:	be 60 09 00 00       	mov    $0x960,%esi
    24e1:	e8 1a 06 00 00       	call   2b00 <erase_secret_bytes>
    24e6:	48 8d 7c 24 20       	lea    0x20(%rsp),%rdi
    24eb:	be 20 00 00 00       	mov    $0x20,%esi
    24f0:	e8 0b 06 00 00       	call   2b00 <erase_secret_bytes>
    24f5:	48 89 e7             	mov    %rsp,%rdi
    24f8:	be 20 00 00 00       	mov    $0x20,%esi
    24fd:	e8 fe 05 00 00       	call   2b00 <erase_secret_bytes>
    2502:	89 d8                	mov    %ebx,%eax
    2504:	48 81 c4 88 12 00 00 	add    $0x1288,%rsp
    250b:	5b                   	pop    %rbx
    250c:	41 5e                	pop    %r14
    250e:	c3                   	ret
    250f:	48 89 e7             	mov    %rsp,%rdi
    2512:	be 20 00 00 00       	mov    $0x20,%esi
    2517:	e8 64 06 00 00       	call   2b80 <system_random_bytes>
    251c:	85 c0                	test   %eax,%eax
    251e:	74 11                	je     2531 <mlkem_self_test+0xe1>
    2520:	89 c3                	mov    %eax,%ebx
    2522:	48 89 e7             	mov    %rsp,%rdi
    2525:	be 20 00 00 00       	mov    $0x20,%esi
    252a:	e8 d1 05 00 00       	call   2b00 <erase_secret_bytes>
    252f:	eb 30                	jmp    2561 <mlkem_self_test+0x111>
    2531:	48 8d 7c 24 40       	lea    0x40(%rsp),%rdi
    2536:	48 8d 74 24 20       	lea    0x20(%rsp),%rsi
    253b:	48 8d 94 24 80 04 00 	lea    0x480(%rsp),%rdx
    2542:	00 
    2543:	49 89 e6             	mov    %rsp,%r14
    2546:	4c 89 f1             	mov    %r14,%rcx
    2549:	e8 02 fb ff ff       	call   2050 <platform_m2_test_encapsulate>
    254e:	89 c3                	mov    %eax,%ebx
    2550:	be 20 00 00 00       	mov    $0x20,%esi
    2555:	4c 89 f7             	mov    %r14,%rdi
    2558:	e8 a3 05 00 00       	call   2b00 <erase_secret_bytes>
    255d:	85 db                	test   %ebx,%ebx
    255f:	74 1e                	je     257f <mlkem_self_test+0x12f>
    2561:	48 8d 7c 24 40       	lea    0x40(%rsp),%rdi
    2566:	be 40 04 00 00       	mov    $0x440,%esi
    256b:	e8 90 05 00 00       	call   2b00 <erase_secret_bytes>
    2570:	48 8d 7c 24 20       	lea    0x20(%rsp),%rdi
    2575:	be 20 00 00 00       	mov    $0x20,%esi
    257a:	e9 50 ff ff ff       	jmp    24cf <mlkem_self_test+0x7f>
    257f:	48 89 e7             	mov    %rsp,%rdi
    2582:	48 8d 74 24 40       	lea    0x40(%rsp),%rsi
    2587:	48 8d 94 24 20 09 00 	lea    0x920(%rsp),%rdx
    258e:	00 
    258f:	e8 d3 08 00 00       	call   2e67 <pqcrystals_kyber768_ref_dec>
    2594:	89 c3                	mov    %eax,%ebx
    2596:	85 c0                	test   %eax,%eax
    2598:	0f 85 36 ff ff ff    	jne    24d4 <mlkem_self_test+0x84>
    259e:	66 0f 6f 44 24 30    	movdqa 0x30(%rsp),%xmm0
    25a4:	66 0f 74 44 24 10    	pcmpeqb 0x10(%rsp),%xmm0
    25aa:	66 0f 6f 4c 24 20    	movdqa 0x20(%rsp),%xmm1
    25b0:	66 0f 74 0c 24       	pcmpeqb (%rsp),%xmm1
    25b5:	66 0f db c8          	pand   %xmm0,%xmm1
    25b9:	66 0f d7 c1          	pmovmskb %xmm1,%eax
    25bd:	31 db                	xor    %ebx,%ebx
    25bf:	3d ff ff 00 00       	cmp    $0xffff,%eax
    25c4:	0f 95 c3             	setne  %bl
    25c7:	e9 08 ff ff ff       	jmp    24d4 <mlkem_self_test+0x84>
    25cc:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000025d0 <input_category_name>:
    25d0:	83 ff 04             	cmp    $0x4,%edi
    25d3:	77 11                	ja     25e6 <input_category_name+0x16>
    25d5:	89 f8                	mov    %edi,%eax
    25d7:	48 8d 0d 9e a2 00 00 	lea    0xa29e(%rip),%rcx        # c87c <reltable.input_category_name>
    25de:	48 63 04 81          	movslq (%rcx,%rax,4),%rax
    25e2:	48 01 c8             	add    %rcx,%rax
    25e5:	c3                   	ret
    25e6:	48 8d 05 54 9e 00 00 	lea    0x9e54(%rip),%rax        # c441 <_IO_stdin_used+0x7441>
    25ed:	c3                   	ret
    25ee:	66 90                	xchg   %ax,%ax

00000000000025f0 <parse_input_category>:
    25f0:	b8 01 00 00 00       	mov    $0x1,%eax
    25f5:	48 85 ff             	test   %rdi,%rdi
    25f8:	0f 84 9d 00 00 00    	je     269b <parse_input_category+0xab>
    25fe:	41 56                	push   %r14
    2600:	53                   	push   %rbx
    2601:	50                   	push   %rax
    2602:	48 89 f3             	mov    %rsi,%rbx
    2605:	48 85 f6             	test   %rsi,%rsi
    2608:	0f 84 86 00 00 00    	je     2694 <parse_input_category+0xa4>
    260e:	49 89 fe             	mov    %rdi,%r14
    2611:	48 8d 35 fd 9d 00 00 	lea    0x9dfd(%rip),%rsi        # c415 <_IO_stdin_used+0x7415>
    2618:	e8 83 eb ff ff       	call   11a0 <strcmp@plt>
    261d:	31 c9                	xor    %ecx,%ecx
    261f:	85 c0                	test   %eax,%eax
    2621:	74 6d                	je     2690 <parse_input_category+0xa0>
    2623:	48 8d 35 f1 9d 00 00 	lea    0x9df1(%rip),%rsi        # c41b <_IO_stdin_used+0x741b>
    262a:	4c 89 f7             	mov    %r14,%rdi
    262d:	e8 6e eb ff ff       	call   11a0 <strcmp@plt>
    2632:	85 c0                	test   %eax,%eax
    2634:	74 47                	je     267d <parse_input_category+0x8d>
    2636:	48 8d 35 12 9e 00 00 	lea    0x9e12(%rip),%rsi        # c44f <_IO_stdin_used+0x744f>
    263d:	4c 89 f7             	mov    %r14,%rdi
    2640:	e8 5b eb ff ff       	call   11a0 <strcmp@plt>
    2645:	85 c0                	test   %eax,%eax
    2647:	74 3b                	je     2684 <parse_input_category+0x94>
    2649:	48 8d 35 d7 9d 00 00 	lea    0x9dd7(%rip),%rsi        # c427 <_IO_stdin_used+0x7427>
    2650:	4c 89 f7             	mov    %r14,%rdi
    2653:	e8 48 eb ff ff       	call   11a0 <strcmp@plt>
    2658:	85 c0                	test   %eax,%eax
    265a:	74 2f                	je     268b <parse_input_category+0x9b>
    265c:	48 8d 35 d1 9d 00 00 	lea    0x9dd1(%rip),%rsi        # c434 <_IO_stdin_used+0x7434>
    2663:	4c 89 f7             	mov    %r14,%rdi
    2666:	e8 35 eb ff ff       	call   11a0 <strcmp@plt>
    266b:	89 c1                	mov    %eax,%ecx
    266d:	b8 01 00 00 00       	mov    $0x1,%eax
    2672:	85 c9                	test   %ecx,%ecx
    2674:	75 1e                	jne    2694 <parse_input_category+0xa4>
    2676:	b9 04 00 00 00       	mov    $0x4,%ecx
    267b:	eb 13                	jmp    2690 <parse_input_category+0xa0>
    267d:	b9 01 00 00 00       	mov    $0x1,%ecx
    2682:	eb 0c                	jmp    2690 <parse_input_category+0xa0>
    2684:	b9 02 00 00 00       	mov    $0x2,%ecx
    2689:	eb 05                	jmp    2690 <parse_input_category+0xa0>
    268b:	b9 03 00 00 00       	mov    $0x3,%ecx
    2690:	89 0b                	mov    %ecx,(%rbx)
    2692:	31 c0                	xor    %eax,%eax
    2694:	48 83 c4 08          	add    $0x8,%rsp
    2698:	5b                   	pop    %rbx
    2699:	41 5e                	pop    %r14
    269b:	c3                   	ret
    269c:	0f 1f 40 00          	nopl   0x0(%rax)

00000000000026a0 <parse_unsigned_integer>:
    26a0:	b8 01 00 00 00       	mov    $0x1,%eax
    26a5:	48 85 ff             	test   %rdi,%rdi
    26a8:	0f 84 87 00 00 00    	je     2735 <parse_unsigned_integer+0x95>
    26ae:	48 85 f6             	test   %rsi,%rsi
    26b1:	0f 84 7e 00 00 00    	je     2735 <parse_unsigned_integer+0x95>
    26b7:	0f b6 0f             	movzbl (%rdi),%ecx
    26ba:	84 c9                	test   %cl,%cl
    26bc:	74 77                	je     2735 <parse_unsigned_integer+0x95>
    26be:	41 57                	push   %r15
    26c0:	41 56                	push   %r14
    26c2:	53                   	push   %rbx
    26c3:	48 83 ec 10          	sub    $0x10,%rsp
    26c7:	48 8d 57 01          	lea    0x1(%rdi),%rdx
    26cb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    26d0:	80 c1 c6             	add    $0xc6,%cl
    26d3:	80 f9 f6             	cmp    $0xf6,%cl
    26d6:	72 54                	jb     272c <parse_unsigned_integer+0x8c>
    26d8:	0f b6 0a             	movzbl (%rdx),%ecx
    26db:	48 ff c2             	inc    %rdx
    26de:	84 c9                	test   %cl,%cl
    26e0:	75 ee                	jne    26d0 <parse_unsigned_integer+0x30>
    26e2:	49 89 f7             	mov    %rsi,%r15
    26e5:	48 89 fb             	mov    %rdi,%rbx
    26e8:	e8 53 e9 ff ff       	call   1040 <__errno_location@plt>
    26ed:	49 89 c6             	mov    %rax,%r14
    26f0:	c7 00 00 00 00 00    	movl   $0x0,(%rax)
    26f6:	48 8d 74 24 08       	lea    0x8(%rsp),%rsi
    26fb:	48 89 df             	mov    %rbx,%rdi
    26fe:	ba 0a 00 00 00       	mov    $0xa,%edx
    2703:	e8 78 ea ff ff       	call   1180 <strtoull@plt>
    2708:	41 83 3e 00          	cmpl   $0x0,(%r14)
    270c:	74 07                	je     2715 <parse_unsigned_integer+0x75>
    270e:	b8 01 00 00 00       	mov    $0x1,%eax
    2713:	eb 17                	jmp    272c <parse_unsigned_integer+0x8c>
    2715:	48 89 c1             	mov    %rax,%rcx
    2718:	48 8b 44 24 08       	mov    0x8(%rsp),%rax
    271d:	80 38 00             	cmpb   $0x0,(%rax)
    2720:	b8 01 00 00 00       	mov    $0x1,%eax
    2725:	75 05                	jne    272c <parse_unsigned_integer+0x8c>
    2727:	49 89 0f             	mov    %rcx,(%r15)
    272a:	31 c0                	xor    %eax,%eax
    272c:	48 83 c4 10          	add    $0x10,%rsp
    2730:	5b                   	pop    %rbx
    2731:	41 5e                	pop    %r14
    2733:	41 5f                	pop    %r15
    2735:	c3                   	ret
    2736:	66 2e 0f 1f 84 00 00 	cs nopw 0x0(%rax,%rax,1)
    273d:	00 00 00 

0000000000002740 <expand_test_seed>:
    2740:	48 83 ec 18          	sub    $0x18,%rsp
    2744:	44 88 04 24          	mov    %r8b,(%rsp)
    2748:	88 54 24 01          	mov    %dl,0x1(%rsp)
    274c:	88 4c 24 09          	mov    %cl,0x9(%rsp)
    2750:	88 74 24 02          	mov    %dh,0x2(%rsp)
    2754:	88 6c 24 0a          	mov    %ch,0xa(%rsp)
    2758:	89 d0                	mov    %edx,%eax
    275a:	c1 e8 10             	shr    $0x10,%eax
    275d:	88 44 24 03          	mov    %al,0x3(%rsp)
    2761:	89 c8                	mov    %ecx,%eax
    2763:	c1 e8 10             	shr    $0x10,%eax
    2766:	88 44 24 0b          	mov    %al,0xb(%rsp)
    276a:	89 d0                	mov    %edx,%eax
    276c:	c1 e8 18             	shr    $0x18,%eax
    276f:	88 44 24 04          	mov    %al,0x4(%rsp)
    2773:	89 c8                	mov    %ecx,%eax
    2775:	c1 e8 18             	shr    $0x18,%eax
    2778:	88 44 24 0c          	mov    %al,0xc(%rsp)
    277c:	48 89 d0             	mov    %rdx,%rax
    277f:	48 c1 e8 20          	shr    $0x20,%rax
    2783:	88 44 24 05          	mov    %al,0x5(%rsp)
    2787:	48 89 c8             	mov    %rcx,%rax
    278a:	48 c1 e8 20          	shr    $0x20,%rax
    278e:	88 44 24 0d          	mov    %al,0xd(%rsp)
    2792:	48 89 d0             	mov    %rdx,%rax
    2795:	48 c1 e8 28          	shr    $0x28,%rax
    2799:	88 44 24 06          	mov    %al,0x6(%rsp)
    279d:	48 89 c8             	mov    %rcx,%rax
    27a0:	48 c1 e8 28          	shr    $0x28,%rax
    27a4:	88 44 24 0e          	mov    %al,0xe(%rsp)
    27a8:	48 89 d0             	mov    %rdx,%rax
    27ab:	48 c1 e8 30          	shr    $0x30,%rax
    27af:	88 44 24 07          	mov    %al,0x7(%rsp)
    27b3:	48 89 c8             	mov    %rcx,%rax
    27b6:	48 c1 e8 30          	shr    $0x30,%rax
    27ba:	88 44 24 0f          	mov    %al,0xf(%rsp)
    27be:	48 c1 ea 38          	shr    $0x38,%rdx
    27c2:	88 54 24 08          	mov    %dl,0x8(%rsp)
    27c6:	48 c1 e9 38          	shr    $0x38,%rcx
    27ca:	88 4c 24 10          	mov    %cl,0x10(%rsp)
    27ce:	48 89 e2             	mov    %rsp,%rdx
    27d1:	b9 11 00 00 00       	mov    $0x11,%ecx
    27d6:	e8 cf 1a 00 00       	call   42aa <pqcrystals_kyber_fips202_ref_shake256>
    27db:	48 83 c4 18          	add    $0x18,%rsp
    27df:	c3                   	ret

00000000000027e0 <generate_test_key_pair>:
    27e0:	41 57                	push   %r15
    27e2:	41 56                	push   %r14
    27e4:	53                   	push   %rbx
    27e5:	48 83 ec 60          	sub    $0x60,%rsp
    27e9:	48 89 d3             	mov    %rdx,%rbx
    27ec:	49 89 f6             	mov    %rsi,%r14
    27ef:	48 89 f8             	mov    %rdi,%rax
    27f2:	c6 04 24 01          	movb   $0x1,(%rsp)
    27f6:	88 44 24 01          	mov    %al,0x1(%rsp)
    27fa:	88 64 24 02          	mov    %ah,0x2(%rsp)
    27fe:	89 c1                	mov    %eax,%ecx
    2800:	c1 e9 10             	shr    $0x10,%ecx
    2803:	88 4c 24 03          	mov    %cl,0x3(%rsp)
    2807:	89 c1                	mov    %eax,%ecx
    2809:	c1 e9 18             	shr    $0x18,%ecx
    280c:	88 4c 24 04          	mov    %cl,0x4(%rsp)
    2810:	48 89 f9             	mov    %rdi,%rcx
    2813:	48 c1 e9 20          	shr    $0x20,%rcx
    2817:	88 4c 24 05          	mov    %cl,0x5(%rsp)
    281b:	48 89 f9             	mov    %rdi,%rcx
    281e:	48 c1 e9 28          	shr    $0x28,%rcx
    2822:	88 4c 24 06          	mov    %cl,0x6(%rsp)
    2826:	48 89 f9             	mov    %rdi,%rcx
    2829:	48 c1 e9 30          	shr    $0x30,%rcx
    282d:	88 4c 24 07          	mov    %cl,0x7(%rsp)
    2831:	48 c1 e8 38          	shr    $0x38,%rax
    2835:	88 44 24 08          	mov    %al,0x8(%rsp)
    2839:	48 c7 44 24 09 00 00 	movq   $0x0,0x9(%rsp)
    2840:	00 00 
    2842:	4c 8d 7c 24 20       	lea    0x20(%rsp),%r15
    2847:	48 89 e2             	mov    %rsp,%rdx
    284a:	be 40 00 00 00       	mov    $0x40,%esi
    284f:	b9 11 00 00 00       	mov    $0x11,%ecx
    2854:	4c 89 ff             	mov    %r15,%rdi
    2857:	e8 4e 1a 00 00       	call   42aa <pqcrystals_kyber_fips202_ref_shake256>
    285c:	4c 89 f7             	mov    %r14,%rdi
    285f:	48 89 de             	mov    %rbx,%rsi
    2862:	4c 89 fa             	mov    %r15,%rdx
    2865:	e8 e6 f6 ff ff       	call   1f50 <platform_m2_test_keypair>
    286a:	89 c3                	mov    %eax,%ebx
    286c:	be 40 00 00 00       	mov    $0x40,%esi
    2871:	4c 89 ff             	mov    %r15,%rdi
    2874:	e8 87 02 00 00       	call   2b00 <erase_secret_bytes>
    2879:	89 d8                	mov    %ebx,%eax
    287b:	48 83 c4 60          	add    $0x60,%rsp
    287f:	5b                   	pop    %rbx
    2880:	41 5e                	pop    %r14
    2882:	41 5f                	pop    %r15
    2884:	c3                   	ret
    2885:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    288c:	00 00 00 00 

0000000000002890 <generate_test_ciphertext>:
    2890:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    2895:	83 ff 04             	cmp    $0x4,%edi
    2898:	0f 87 5b 02 00 00    	ja     2af9 <generate_test_ciphertext+0x269>
    289e:	48 85 c9             	test   %rcx,%rcx
    28a1:	0f 84 52 02 00 00    	je     2af9 <generate_test_ciphertext+0x269>
    28a7:	4d 85 c0             	test   %r8,%r8
    28aa:	0f 84 49 02 00 00    	je     2af9 <generate_test_ciphertext+0x269>
    28b0:	55                   	push   %rbp
    28b1:	41 57                	push   %r15
    28b3:	41 56                	push   %r14
    28b5:	41 55                	push   %r13
    28b7:	41 54                	push   %r12
    28b9:	53                   	push   %rbx
    28ba:	48 83 ec 48          	sub    $0x48,%rsp
    28be:	48 89 f3             	mov    %rsi,%rbx
    28c1:	41 89 fd             	mov    %edi,%r13d
    28c4:	83 ff 02             	cmp    $0x2,%edi
    28c7:	0f 85 a4 00 00 00    	jne    2971 <generate_test_ciphertext+0xe1>
    28cd:	c6 04 24 03          	movb   $0x3,(%rsp)
    28d1:	88 5c 24 01          	mov    %bl,0x1(%rsp)
    28d5:	88 54 24 09          	mov    %dl,0x9(%rsp)
    28d9:	88 7c 24 02          	mov    %bh,0x2(%rsp)
    28dd:	88 74 24 0a          	mov    %dh,0xa(%rsp)
    28e1:	89 d8                	mov    %ebx,%eax
    28e3:	c1 e8 10             	shr    $0x10,%eax
    28e6:	88 44 24 03          	mov    %al,0x3(%rsp)
    28ea:	89 d0                	mov    %edx,%eax
    28ec:	c1 e8 10             	shr    $0x10,%eax
    28ef:	88 44 24 0b          	mov    %al,0xb(%rsp)
    28f3:	89 d8                	mov    %ebx,%eax
    28f5:	c1 e8 18             	shr    $0x18,%eax
    28f8:	88 44 24 04          	mov    %al,0x4(%rsp)
    28fc:	89 d0                	mov    %edx,%eax
    28fe:	c1 e8 18             	shr    $0x18,%eax
    2901:	88 44 24 0c          	mov    %al,0xc(%rsp)
    2905:	48 89 d8             	mov    %rbx,%rax
    2908:	48 c1 e8 20          	shr    $0x20,%rax
    290c:	88 44 24 05          	mov    %al,0x5(%rsp)
    2910:	48 89 d0             	mov    %rdx,%rax
    2913:	48 c1 e8 20          	shr    $0x20,%rax
    2917:	88 44 24 0d          	mov    %al,0xd(%rsp)
    291b:	48 89 d8             	mov    %rbx,%rax
    291e:	48 c1 e8 28          	shr    $0x28,%rax
    2922:	88 44 24 06          	mov    %al,0x6(%rsp)
    2926:	48 89 d0             	mov    %rdx,%rax
    2929:	48 c1 e8 28          	shr    $0x28,%rax
    292d:	88 44 24 0e          	mov    %al,0xe(%rsp)
    2931:	48 89 d8             	mov    %rbx,%rax
    2934:	48 c1 e8 30          	shr    $0x30,%rax
    2938:	88 44 24 07          	mov    %al,0x7(%rsp)
    293c:	48 89 d0             	mov    %rdx,%rax
    293f:	48 c1 e8 30          	shr    $0x30,%rax
    2943:	88 44 24 0f          	mov    %al,0xf(%rsp)
    2947:	48 c1 eb 38          	shr    $0x38,%rbx
    294b:	88 5c 24 08          	mov    %bl,0x8(%rsp)
    294f:	48 c1 ea 38          	shr    $0x38,%rdx
    2953:	88 54 24 10          	mov    %dl,0x10(%rsp)
    2957:	48 89 e2             	mov    %rsp,%rdx
    295a:	be 40 04 00 00       	mov    $0x440,%esi
    295f:	b9 11 00 00 00       	mov    $0x11,%ecx
    2964:	4c 89 c7             	mov    %r8,%rdi
    2967:	e8 3e 19 00 00       	call   42aa <pqcrystals_kyber_fips202_ref_shake256>
    296c:	e9 78 01 00 00       	jmp    2ae9 <generate_test_ciphertext+0x259>
    2971:	41 8d 45 fd          	lea    -0x3(%r13),%eax
    2975:	83 f8 01             	cmp    $0x1,%eax
    2978:	48 89 54 24 40       	mov    %rdx,0x40(%rsp)
    297d:	77 47                	ja     29c6 <generate_test_ciphertext+0x136>
    297f:	41 83 fd 03          	cmp    $0x3,%r13d
    2983:	0f 95 c0             	setne  %al
    2986:	f6 d8                	neg    %al
    2988:	0f b6 c0             	movzbl %al,%eax
    298b:	66 0f 6e c0          	movd   %eax,%xmm0
    298f:	66 0f 60 c0          	punpcklbw %xmm0,%xmm0
    2993:	f2 0f 70 c0 00       	pshuflw $0x0,%xmm0,%xmm0
    2998:	66 0f 70 c0 00       	pshufd $0x0,%xmm0,%xmm0
    299d:	66 0f 7f 44 24 10    	movdqa %xmm0,0x10(%rsp)
    29a3:	66 0f 7f 04 24       	movdqa %xmm0,(%rsp)
    29a8:	48 8d 74 24 20       	lea    0x20(%rsp),%rsi
    29ad:	48 89 e0             	mov    %rsp,%rax
    29b0:	4c 89 c3             	mov    %r8,%rbx
    29b3:	4c 89 c7             	mov    %r8,%rdi
    29b6:	48 89 ca             	mov    %rcx,%rdx
    29b9:	48 89 c1             	mov    %rax,%rcx
    29bc:	e8 5f f9 ff ff       	call   2320 <platform_m2_test_message>
    29c1:	e9 c4 00 00 00       	jmp    2a8a <generate_test_ciphertext+0x1fa>
    29c6:	c6 44 24 20 02       	movb   $0x2,0x20(%rsp)
    29cb:	88 5c 24 21          	mov    %bl,0x21(%rsp)
    29cf:	88 54 24 29          	mov    %dl,0x29(%rsp)
    29d3:	88 7c 24 22          	mov    %bh,0x22(%rsp)
    29d7:	88 74 24 2a          	mov    %dh,0x2a(%rsp)
    29db:	89 d8                	mov    %ebx,%eax
    29dd:	c1 e8 10             	shr    $0x10,%eax
    29e0:	88 44 24 23          	mov    %al,0x23(%rsp)
    29e4:	89 d0                	mov    %edx,%eax
    29e6:	c1 e8 10             	shr    $0x10,%eax
    29e9:	88 44 24 2b          	mov    %al,0x2b(%rsp)
    29ed:	89 d8                	mov    %ebx,%eax
    29ef:	c1 e8 18             	shr    $0x18,%eax
    29f2:	88 44 24 24          	mov    %al,0x24(%rsp)
    29f6:	89 d0                	mov    %edx,%eax
    29f8:	c1 e8 18             	shr    $0x18,%eax
    29fb:	88 44 24 2c          	mov    %al,0x2c(%rsp)
    29ff:	48 89 d8             	mov    %rbx,%rax
    2a02:	48 c1 e8 20          	shr    $0x20,%rax
    2a06:	88 44 24 25          	mov    %al,0x25(%rsp)
    2a0a:	48 89 d0             	mov    %rdx,%rax
    2a0d:	48 c1 e8 20          	shr    $0x20,%rax
    2a11:	88 44 24 2d          	mov    %al,0x2d(%rsp)
    2a15:	48 89 d8             	mov    %rbx,%rax
    2a18:	48 c1 e8 28          	shr    $0x28,%rax
    2a1c:	88 44 24 26          	mov    %al,0x26(%rsp)
    2a20:	48 89 d0             	mov    %rdx,%rax
    2a23:	48 c1 e8 28          	shr    $0x28,%rax
    2a27:	88 44 24 2e          	mov    %al,0x2e(%rsp)
    2a2b:	48 89 d8             	mov    %rbx,%rax
    2a2e:	48 c1 e8 30          	shr    $0x30,%rax
    2a32:	88 44 24 27          	mov    %al,0x27(%rsp)
    2a36:	48 89 d0             	mov    %rdx,%rax
    2a39:	48 c1 e8 30          	shr    $0x30,%rax
    2a3d:	88 44 24 2f          	mov    %al,0x2f(%rsp)
    2a41:	48 c1 eb 38          	shr    $0x38,%rbx
    2a45:	88 5c 24 28          	mov    %bl,0x28(%rsp)
    2a49:	48 89 d0             	mov    %rdx,%rax
    2a4c:	48 c1 e8 38          	shr    $0x38,%rax
    2a50:	88 44 24 30          	mov    %al,0x30(%rsp)
    2a54:	49 89 e6             	mov    %rsp,%r14
    2a57:	48 8d 54 24 20       	lea    0x20(%rsp),%rdx
    2a5c:	be 20 00 00 00       	mov    $0x20,%esi
    2a61:	49 89 cf             	mov    %rcx,%r15
    2a64:	b9 11 00 00 00       	mov    $0x11,%ecx
    2a69:	4c 89 f7             	mov    %r14,%rdi
    2a6c:	4d 89 c4             	mov    %r8,%r12
    2a6f:	e8 36 18 00 00       	call   42aa <pqcrystals_kyber_fips202_ref_shake256>
    2a74:	48 8d 74 24 20       	lea    0x20(%rsp),%rsi
    2a79:	4c 89 e3             	mov    %r12,%rbx
    2a7c:	4c 89 e7             	mov    %r12,%rdi
    2a7f:	4c 89 fa             	mov    %r15,%rdx
    2a82:	4c 89 f1             	mov    %r14,%rcx
    2a85:	e8 c6 f5 ff ff       	call   2050 <platform_m2_test_encapsulate>
    2a8a:	89 c5                	mov    %eax,%ebp
    2a8c:	48 8d 7c 24 20       	lea    0x20(%rsp),%rdi
    2a91:	be 20 00 00 00       	mov    $0x20,%esi
    2a96:	e8 65 00 00 00       	call   2b00 <erase_secret_bytes>
    2a9b:	48 89 e7             	mov    %rsp,%rdi
    2a9e:	be 20 00 00 00       	mov    $0x20,%esi
    2aa3:	e8 58 00 00 00       	call   2b00 <erase_secret_bytes>
    2aa8:	41 83 fd 01          	cmp    $0x1,%r13d
    2aac:	75 4c                	jne    2afa <generate_test_ciphertext+0x26a>
    2aae:	89 e8                	mov    %ebp,%eax
    2ab0:	85 ed                	test   %ebp,%ebp
    2ab2:	48 8b 54 24 40       	mov    0x40(%rsp),%rdx
    2ab7:	75 32                	jne    2aeb <generate_test_ciphertext+0x25b>
    2ab9:	89 d1                	mov    %edx,%ecx
    2abb:	80 e1 07             	and    $0x7,%cl
    2abe:	40 b6 01             	mov    $0x1,%sil
    2ac1:	40 d2 e6             	shl    %cl,%sil
    2ac4:	48 b9 f1 f0 f0 f0 f0 	movabs $0xf0f0f0f0f0f0f0f1,%rcx
    2acb:	f0 f0 f0 
    2ace:	48 89 d0             	mov    %rdx,%rax
    2ad1:	48 89 d7             	mov    %rdx,%rdi
    2ad4:	48 f7 e1             	mul    %rcx
    2ad7:	48 c1 ea 0a          	shr    $0xa,%rdx
    2adb:	48 69 c2 40 04 00 00 	imul   $0x440,%rdx,%rax
    2ae2:	48 29 c7             	sub    %rax,%rdi
    2ae5:	40 30 34 3b          	xor    %sil,(%rbx,%rdi,1)
    2ae9:	31 c0                	xor    %eax,%eax
    2aeb:	48 83 c4 48          	add    $0x48,%rsp
    2aef:	5b                   	pop    %rbx
    2af0:	41 5c                	pop    %r12
    2af2:	41 5d                	pop    %r13
    2af4:	41 5e                	pop    %r14
    2af6:	41 5f                	pop    %r15
    2af8:	5d                   	pop    %rbp
    2af9:	c3                   	ret
    2afa:	89 e8                	mov    %ebp,%eax
    2afc:	eb ed                	jmp    2aeb <generate_test_ciphertext+0x25b>
    2afe:	66 90                	xchg   %ax,%ax

0000000000002b00 <erase_secret_bytes>:
    2b00:	48 85 f6             	test   %rsi,%rsi
    2b03:	74 6b                	je     2b70 <erase_secret_bytes+0x70>
    2b05:	48 89 f0             	mov    %rsi,%rax
    2b08:	48 83 e0 07          	and    $0x7,%rax
    2b0c:	74 1f                	je     2b2d <erase_secret_bytes+0x2d>
    2b0e:	31 c9                	xor    %ecx,%ecx
    2b10:	c6 04 0f 00          	movb   $0x0,(%rdi,%rcx,1)
    2b14:	48 ff c1             	inc    %rcx
    2b17:	48 39 c8             	cmp    %rcx,%rax
    2b1a:	75 f4                	jne    2b10 <erase_secret_bytes+0x10>
    2b1c:	48 01 cf             	add    %rcx,%rdi
    2b1f:	48 89 f0             	mov    %rsi,%rax
    2b22:	48 29 c8             	sub    %rcx,%rax
    2b25:	48 83 fe 08          	cmp    $0x8,%rsi
    2b29:	73 0b                	jae    2b36 <erase_secret_bytes+0x36>
    2b2b:	eb 43                	jmp    2b70 <erase_secret_bytes+0x70>
    2b2d:	48 89 f0             	mov    %rsi,%rax
    2b30:	48 83 fe 08          	cmp    $0x8,%rsi
    2b34:	72 3a                	jb     2b70 <erase_secret_bytes+0x70>
    2b36:	31 c9                	xor    %ecx,%ecx
    2b38:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    2b3f:	00 
    2b40:	c6 04 0f 00          	movb   $0x0,(%rdi,%rcx,1)
    2b44:	c6 44 0f 01 00       	movb   $0x0,0x1(%rdi,%rcx,1)
    2b49:	c6 44 0f 02 00       	movb   $0x0,0x2(%rdi,%rcx,1)
    2b4e:	c6 44 0f 03 00       	movb   $0x0,0x3(%rdi,%rcx,1)
    2b53:	c6 44 0f 04 00       	movb   $0x0,0x4(%rdi,%rcx,1)
    2b58:	c6 44 0f 05 00       	movb   $0x0,0x5(%rdi,%rcx,1)
    2b5d:	c6 44 0f 06 00       	movb   $0x0,0x6(%rdi,%rcx,1)
    2b62:	c6 44 0f 07 00       	movb   $0x0,0x7(%rdi,%rcx,1)
    2b67:	48 83 c1 08          	add    $0x8,%rcx
    2b6b:	48 39 c8             	cmp    %rcx,%rax
    2b6e:	75 d0                	jne    2b40 <erase_secret_bytes+0x40>
    2b70:	c3                   	ret
    2b71:	66 66 66 66 66 66 2e 	data16 data16 data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
    2b78:	0f 1f 84 00 00 00 00 
    2b7f:	00 

0000000000002b80 <system_random_bytes>:
    2b80:	48 85 ff             	test   %rdi,%rdi
    2b83:	0f 84 d1 00 00 00    	je     2c5a <system_random_bytes+0xda>
    2b89:	55                   	push   %rbp
    2b8a:	41 57                	push   %r15
    2b8c:	41 56                	push   %r14
    2b8e:	41 54                	push   %r12
    2b90:	53                   	push   %rbx
    2b91:	49 89 f6             	mov    %rsi,%r14
    2b94:	48 89 fb             	mov    %rdi,%rbx
    2b97:	48 8d 3d ab 98 00 00 	lea    0x98ab(%rip),%rdi        # c449 <_IO_stdin_used+0x7449>
    2b9e:	31 f6                	xor    %esi,%esi
    2ba0:	31 c0                	xor    %eax,%eax
    2ba2:	e8 69 e6 ff ff       	call   1210 <open@plt>
    2ba7:	89 c5                	mov    %eax,%ebp
    2ba9:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    2bae:	85 ed                	test   %ebp,%ebp
    2bb0:	0f 88 9a 01 00 00    	js     2d50 <system_random_bytes+0x1d0>
    2bb6:	4d 85 f6             	test   %r14,%r14
    2bb9:	0f 84 a1 00 00 00    	je     2c60 <system_random_bytes+0xe0>
    2bbf:	45 31 ff             	xor    %r15d,%r15d
    2bc2:	41 bc 00 01 00 00    	mov    $0x100,%r12d
    2bc8:	eb 19                	jmp    2be3 <system_random_bytes+0x63>
    2bca:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2bd0:	e8 6b e4 ff ff       	call   1040 <__errno_location@plt>
    2bd5:	83 38 04             	cmpl   $0x4,(%rax)
    2bd8:	0f 85 9a 00 00 00    	jne    2c78 <system_random_bytes+0xf8>
    2bde:	4d 39 f7             	cmp    %r14,%r15
    2be1:	73 2b                	jae    2c0e <system_random_bytes+0x8e>
    2be3:	4c 89 f2             	mov    %r14,%rdx
    2be6:	4c 29 fa             	sub    %r15,%rdx
    2be9:	4a 8d 34 3b          	lea    (%rbx,%r15,1),%rsi
    2bed:	48 81 fa 00 01 00 00 	cmp    $0x100,%rdx
    2bf4:	49 0f 43 d4          	cmovae %r12,%rdx
    2bf8:	89 ef                	mov    %ebp,%edi
    2bfa:	e8 61 e5 ff ff       	call   1160 <read@plt>
    2bff:	48 85 c0             	test   %rax,%rax
    2c02:	78 cc                	js     2bd0 <system_random_bytes+0x50>
    2c04:	74 72                	je     2c78 <system_random_bytes+0xf8>
    2c06:	49 01 c7             	add    %rax,%r15
    2c09:	4d 39 f7             	cmp    %r14,%r15
    2c0c:	72 d5                	jb     2be3 <system_random_bytes+0x63>
    2c0e:	89 ef                	mov    %ebp,%edi
    2c10:	e8 1b e5 ff ff       	call   1130 <close@plt>
    2c15:	89 c1                	mov    %eax,%ecx
    2c17:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    2c1c:	85 c9                	test   %ecx,%ecx
    2c1e:	0f 44 c1             	cmove  %ecx,%eax
    2c21:	0f 84 29 01 00 00    	je     2d50 <system_random_bytes+0x1d0>
    2c27:	4d 85 f6             	test   %r14,%r14
    2c2a:	0f 84 20 01 00 00    	je     2d50 <system_random_bytes+0x1d0>
    2c30:	4c 89 f1             	mov    %r14,%rcx
    2c33:	48 83 e1 07          	and    $0x7,%rcx
    2c37:	0f 84 c5 00 00 00    	je     2d02 <system_random_bytes+0x182>
    2c3d:	31 c0                	xor    %eax,%eax
    2c3f:	90                   	nop
    2c40:	c6 04 03 00          	movb   $0x0,(%rbx,%rax,1)
    2c44:	48 ff c0             	inc    %rax
    2c47:	48 39 c1             	cmp    %rax,%rcx
    2c4a:	75 f4                	jne    2c40 <system_random_bytes+0xc0>
    2c4c:	48 01 c3             	add    %rax,%rbx
    2c4f:	4c 89 f1             	mov    %r14,%rcx
    2c52:	48 29 c1             	sub    %rax,%rcx
    2c55:	e9 ab 00 00 00       	jmp    2d05 <system_random_bytes+0x185>
    2c5a:	b8 9c ff ff ff       	mov    $0xffffff9c,%eax
    2c5f:	c3                   	ret
    2c60:	89 ef                	mov    %ebp,%edi
    2c62:	e8 c9 e4 ff ff       	call   1130 <close@plt>
    2c67:	89 c1                	mov    %eax,%ecx
    2c69:	85 c0                	test   %eax,%eax
    2c6b:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    2c70:	0f 44 c1             	cmove  %ecx,%eax
    2c73:	e9 d8 00 00 00       	jmp    2d50 <system_random_bytes+0x1d0>
    2c78:	89 ef                	mov    %ebp,%edi
    2c7a:	e8 b1 e4 ff ff       	call   1130 <close@plt>
    2c7f:	4c 89 f1             	mov    %r14,%rcx
    2c82:	48 83 e1 07          	and    $0x7,%rcx
    2c86:	74 28                	je     2cb0 <system_random_bytes+0x130>
    2c88:	31 d2                	xor    %edx,%edx
    2c8a:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    2c8f:	90                   	nop
    2c90:	c6 04 13 00          	movb   $0x0,(%rbx,%rdx,1)
    2c94:	48 ff c2             	inc    %rdx
    2c97:	48 39 d1             	cmp    %rdx,%rcx
    2c9a:	75 f4                	jne    2c90 <system_random_bytes+0x110>
    2c9c:	48 01 d3             	add    %rdx,%rbx
    2c9f:	4c 89 f1             	mov    %r14,%rcx
    2ca2:	48 29 d1             	sub    %rdx,%rcx
    2ca5:	49 83 fe 08          	cmp    $0x8,%r14
    2ca9:	73 17                	jae    2cc2 <system_random_bytes+0x142>
    2cab:	e9 a0 00 00 00       	jmp    2d50 <system_random_bytes+0x1d0>
    2cb0:	4c 89 f1             	mov    %r14,%rcx
    2cb3:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    2cb8:	49 83 fe 08          	cmp    $0x8,%r14
    2cbc:	0f 82 8e 00 00 00    	jb     2d50 <system_random_bytes+0x1d0>
    2cc2:	31 d2                	xor    %edx,%edx
    2cc4:	66 66 66 2e 0f 1f 84 	data16 data16 cs nopw 0x0(%rax,%rax,1)
    2ccb:	00 00 00 00 00 
    2cd0:	c6 04 13 00          	movb   $0x0,(%rbx,%rdx,1)
    2cd4:	c6 44 13 01 00       	movb   $0x0,0x1(%rbx,%rdx,1)
    2cd9:	c6 44 13 02 00       	movb   $0x0,0x2(%rbx,%rdx,1)
    2cde:	c6 44 13 03 00       	movb   $0x0,0x3(%rbx,%rdx,1)
    2ce3:	c6 44 13 04 00       	movb   $0x0,0x4(%rbx,%rdx,1)
    2ce8:	c6 44 13 05 00       	movb   $0x0,0x5(%rbx,%rdx,1)
    2ced:	c6 44 13 06 00       	movb   $0x0,0x6(%rbx,%rdx,1)
    2cf2:	c6 44 13 07 00       	movb   $0x0,0x7(%rbx,%rdx,1)
    2cf7:	48 83 c2 08          	add    $0x8,%rdx
    2cfb:	48 39 d1             	cmp    %rdx,%rcx
    2cfe:	75 d0                	jne    2cd0 <system_random_bytes+0x150>
    2d00:	eb 4e                	jmp    2d50 <system_random_bytes+0x1d0>
    2d02:	4c 89 f1             	mov    %r14,%rcx
    2d05:	b8 9b ff ff ff       	mov    $0xffffff9b,%eax
    2d0a:	49 83 fe 08          	cmp    $0x8,%r14
    2d0e:	72 40                	jb     2d50 <system_random_bytes+0x1d0>
    2d10:	31 d2                	xor    %edx,%edx
    2d12:	66 66 66 66 66 2e 0f 	data16 data16 data16 data16 cs nopw 0x0(%rax,%rax,1)
    2d19:	1f 84 00 00 00 00 00 
    2d20:	c6 04 13 00          	movb   $0x0,(%rbx,%rdx,1)
    2d24:	c6 44 13 01 00       	movb   $0x0,0x1(%rbx,%rdx,1)
    2d29:	c6 44 13 02 00       	movb   $0x0,0x2(%rbx,%rdx,1)
    2d2e:	c6 44 13 03 00       	movb   $0x0,0x3(%rbx,%rdx,1)
    2d33:	c6 44 13 04 00       	movb   $0x0,0x4(%rbx,%rdx,1)
    2d38:	c6 44 13 05 00       	movb   $0x0,0x5(%rbx,%rdx,1)
    2d3d:	c6 44 13 06 00       	movb   $0x0,0x6(%rbx,%rdx,1)
    2d42:	c6 44 13 07 00       	movb   $0x0,0x7(%rbx,%rdx,1)
    2d47:	48 83 c2 08          	add    $0x8,%rdx
    2d4b:	48 39 d1             	cmp    %rdx,%rcx
    2d4e:	75 d0                	jne    2d20 <system_random_bytes+0x1a0>
    2d50:	5b                   	pop    %rbx
    2d51:	41 5c                	pop    %r12
    2d53:	41 5e                	pop    %r14
    2d55:	41 5f                	pop    %r15
    2d57:	5d                   	pop    %rbp
    2d58:	c3                   	ret
    2d59:	0f 1f 00             	nopl   (%rax)

0000000000002d5c <pqcrystals_kyber768_ref_keypair>:
    2d5c:	41 56                	push   %r14
    2d5e:	53                   	push   %rbx
    2d5f:	50                   	push   %rax
    2d60:	48 89 f3             	mov    %rsi,%rbx
    2d63:	49 89 fe             	mov    %rdi,%r14
    2d66:	e8 b7 03 00 00       	call   3122 <pqcrystals_kyber768_ref_indcpa_keypair>
    2d6b:	31 c0                	xor    %eax,%eax
    2d6d:	48 3d a0 04 00 00    	cmp    $0x4a0,%rax
    2d73:	74 10                	je     2d85 <pqcrystals_kyber768_ref_keypair+0x29>
    2d75:	41 8a 0c 06          	mov    (%r14,%rax,1),%cl
    2d79:	88 8c 03 80 04 00 00 	mov    %cl,0x480(%rbx,%rax,1)
    2d80:	48 ff c0             	inc    %rax
    2d83:	eb e8                	jmp    2d6d <pqcrystals_kyber768_ref_keypair+0x11>
    2d85:	48 8d bb 20 09 00 00 	lea    0x920(%rbx),%rdi
    2d8c:	ba a0 04 00 00       	mov    $0x4a0,%edx
    2d91:	4c 89 f6             	mov    %r14,%rsi
    2d94:	e8 7d 15 00 00       	call   4316 <pqcrystals_kyber_fips202_ref_sha3_256>
    2d99:	48 81 c3 40 09 00 00 	add    $0x940,%rbx
    2da0:	6a 20                	push   $0x20
    2da2:	5e                   	pop    %rsi
    2da3:	48 89 df             	mov    %rbx,%rdi
    2da6:	e8 35 f1 ff ff       	call   1ee0 <platform_m2_randombytes>
    2dab:	31 c0                	xor    %eax,%eax
    2dad:	48 83 c4 08          	add    $0x8,%rsp
    2db1:	5b                   	pop    %rbx
    2db2:	41 5e                	pop    %r14
    2db4:	c3                   	ret

0000000000002db5 <pqcrystals_kyber768_ref_enc>:
    2db5:	55                   	push   %rbp
    2db6:	41 57                	push   %r15
    2db8:	41 56                	push   %r14
    2dba:	41 55                	push   %r13
    2dbc:	41 54                	push   %r12
    2dbe:	53                   	push   %rbx
    2dbf:	48 81 ec 98 00 00 00 	sub    $0x98,%rsp
    2dc6:	49 89 d4             	mov    %rdx,%r12
    2dc9:	48 89 74 24 08       	mov    %rsi,0x8(%rsp)
    2dce:	49 89 ff             	mov    %rdi,%r15
    2dd1:	4c 8d 6c 24 50       	lea    0x50(%rsp),%r13
    2dd6:	6a 20                	push   $0x20
    2dd8:	5b                   	pop    %rbx
    2dd9:	4c 89 ef             	mov    %r13,%rdi
    2ddc:	48 89 de             	mov    %rbx,%rsi
    2ddf:	e8 fc f0 ff ff       	call   1ee0 <platform_m2_randombytes>
    2de4:	4c 89 ef             	mov    %r13,%rdi
    2de7:	4c 89 ee             	mov    %r13,%rsi
    2dea:	48 89 da             	mov    %rbx,%rdx
    2ded:	e8 24 15 00 00       	call   4316 <pqcrystals_kyber_fips202_ref_sha3_256>
    2df2:	48 8d 7c 24 70       	lea    0x70(%rsp),%rdi
    2df7:	ba a0 04 00 00       	mov    $0x4a0,%edx
    2dfc:	4c 89 e6             	mov    %r12,%rsi
    2dff:	e8 12 15 00 00       	call   4316 <pqcrystals_kyber_fips202_ref_sha3_256>
    2e04:	48 8d 6c 24 10       	lea    0x10(%rsp),%rbp
    2e09:	6a 40                	push   $0x40
    2e0b:	5b                   	pop    %rbx
    2e0c:	48 89 ef             	mov    %rbp,%rdi
    2e0f:	4c 89 ee             	mov    %r13,%rsi
    2e12:	48 89 da             	mov    %rbx,%rdx
    2e15:	e8 25 1e 00 00       	call   4c3f <pqcrystals_kyber_fips202_ref_sha3_512>
    2e1a:	4c 8d 74 24 30       	lea    0x30(%rsp),%r14
    2e1f:	4c 89 ff             	mov    %r15,%rdi
    2e22:	4c 89 ee             	mov    %r13,%rsi
    2e25:	4c 89 e2             	mov    %r12,%rdx
    2e28:	4c 89 f1             	mov    %r14,%rcx
    2e2b:	e8 53 04 00 00       	call   3283 <pqcrystals_kyber768_ref_indcpa_enc>
    2e30:	ba 40 04 00 00       	mov    $0x440,%edx
    2e35:	4c 89 f7             	mov    %r14,%rdi
    2e38:	4c 89 fe             	mov    %r15,%rsi
    2e3b:	e8 d6 14 00 00       	call   4316 <pqcrystals_kyber_fips202_ref_sha3_256>
    2e40:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    2e45:	6a 20                	push   $0x20
    2e47:	5e                   	pop    %rsi
    2e48:	48 89 ea             	mov    %rbp,%rdx
    2e4b:	48 89 d9             	mov    %rbx,%rcx
    2e4e:	e8 57 14 00 00       	call   42aa <pqcrystals_kyber_fips202_ref_shake256>
    2e53:	31 c0                	xor    %eax,%eax
    2e55:	48 81 c4 98 00 00 00 	add    $0x98,%rsp
    2e5c:	5b                   	pop    %rbx
    2e5d:	41 5c                	pop    %r12
    2e5f:	41 5d                	pop    %r13
    2e61:	41 5e                	pop    %r14
    2e63:	41 5f                	pop    %r15
    2e65:	5d                   	pop    %rbp
    2e66:	c3                   	ret

0000000000002e67 <pqcrystals_kyber768_ref_dec>:
    2e67:	55                   	push   %rbp
    2e68:	41 57                	push   %r15
    2e6a:	41 56                	push   %r14
    2e6c:	41 55                	push   %r13
    2e6e:	41 54                	push   %r12
    2e70:	53                   	push   %rbx
    2e71:	48 81 ec d8 04 00 00 	sub    $0x4d8,%rsp
    2e78:	49 89 d6             	mov    %rdx,%r14
    2e7b:	49 89 f7             	mov    %rsi,%r15
    2e7e:	48 89 7c 24 08       	mov    %rdi,0x8(%rsp)
    2e83:	48 8d 7c 24 50       	lea    0x50(%rsp),%rdi
    2e88:	e8 b9 05 00 00       	call   3446 <pqcrystals_kyber768_ref_indcpa_dec>
    2e8d:	31 c0                	xor    %eax,%eax
    2e8f:	48 83 f8 20          	cmp    $0x20,%rax
    2e93:	74 11                	je     2ea6 <pqcrystals_kyber768_ref_dec+0x3f>
    2e95:	41 8a 8c 06 20 09 00 	mov    0x920(%r14,%rax,1),%cl
    2e9c:	00 
    2e9d:	88 4c 04 70          	mov    %cl,0x70(%rsp,%rax,1)
    2ea1:	48 ff c0             	inc    %rax
    2ea4:	eb e9                	jmp    2e8f <pqcrystals_kyber768_ref_dec+0x28>
    2ea6:	49 8d ae 80 04 00 00 	lea    0x480(%r14),%rbp
    2ead:	48 8d 7c 24 10       	lea    0x10(%rsp),%rdi
    2eb2:	48 8d 5c 24 50       	lea    0x50(%rsp),%rbx
    2eb7:	6a 40                	push   $0x40
    2eb9:	5a                   	pop    %rdx
    2eba:	48 89 de             	mov    %rbx,%rsi
    2ebd:	e8 7d 1d 00 00       	call   4c3f <pqcrystals_kyber_fips202_ref_sha3_512>
    2ec2:	4c 8d 6c 24 30       	lea    0x30(%rsp),%r13
    2ec7:	4c 8d a4 24 90 00 00 	lea    0x90(%rsp),%r12
    2ece:	00 
    2ecf:	4c 89 e7             	mov    %r12,%rdi
    2ed2:	48 89 de             	mov    %rbx,%rsi
    2ed5:	48 89 ea             	mov    %rbp,%rdx
    2ed8:	4c 89 e9             	mov    %r13,%rcx
    2edb:	e8 a3 03 00 00       	call   3283 <pqcrystals_kyber768_ref_indcpa_enc>
    2ee0:	ba 40 04 00 00       	mov    $0x440,%edx
    2ee5:	4c 89 ff             	mov    %r15,%rdi
    2ee8:	4c 89 e6             	mov    %r12,%rsi
    2eeb:	e8 58 0f 00 00       	call   3e48 <pqcrystals_kyber768_ref_verify>
    2ef0:	89 c3                	mov    %eax,%ebx
    2ef2:	ba 40 04 00 00       	mov    $0x440,%edx
    2ef7:	4c 89 ef             	mov    %r13,%rdi
    2efa:	4c 89 fe             	mov    %r15,%rsi
    2efd:	e8 14 14 00 00       	call   4316 <pqcrystals_kyber_fips202_ref_sha3_256>
    2f02:	49 81 c6 40 09 00 00 	add    $0x940,%r14
    2f09:	0f b6 cb             	movzbl %bl,%ecx
    2f0c:	6a 20                	push   $0x20
    2f0e:	5b                   	pop    %rbx
    2f0f:	4c 8d 7c 24 10       	lea    0x10(%rsp),%r15
    2f14:	4c 89 ff             	mov    %r15,%rdi
    2f17:	4c 89 f6             	mov    %r14,%rsi
    2f1a:	48 89 da             	mov    %rbx,%rdx
    2f1d:	e8 47 0f 00 00       	call   3e69 <pqcrystals_kyber768_ref_cmov>
    2f22:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    2f27:	48 89 de             	mov    %rbx,%rsi
    2f2a:	4c 89 fa             	mov    %r15,%rdx
    2f2d:	6a 40                	push   $0x40
    2f2f:	59                   	pop    %rcx
    2f30:	e8 75 13 00 00       	call   42aa <pqcrystals_kyber_fips202_ref_shake256>
    2f35:	31 c0                	xor    %eax,%eax
    2f37:	48 81 c4 d8 04 00 00 	add    $0x4d8,%rsp
    2f3e:	5b                   	pop    %rbx
    2f3f:	41 5c                	pop    %r12
    2f41:	41 5d                	pop    %r13
    2f43:	41 5e                	pop    %r14
    2f45:	41 5f                	pop    %r15
    2f47:	5d                   	pop    %rbp
    2f48:	c3                   	ret
    2f49:	0f 1f 00             	nopl   (%rax)

0000000000002f4c <pqcrystals_kyber768_ref_gen_matrix>:
    2f4c:	55                   	push   %rbp
    2f4d:	41 57                	push   %r15
    2f4f:	41 56                	push   %r14
    2f51:	41 55                	push   %r13
    2f53:	41 54                	push   %r12
    2f55:	53                   	push   %rbx
    2f56:	48 81 ec 08 03 00 00 	sub    $0x308,%rsp
    2f5d:	89 54 24 04          	mov    %edx,0x4(%rsp)
    2f61:	48 89 74 24 08       	mov    %rsi,0x8(%rsp)
    2f66:	48 89 7c 24 10       	mov    %rdi,0x10(%rsp)
    2f6b:	31 c0                	xor    %eax,%eax
    2f6d:	4c 8d a4 24 38 02 00 	lea    0x238(%rsp),%r12
    2f74:	00 
    2f75:	4c 8d 6c 24 30       	lea    0x30(%rsp),%r13
    2f7a:	48 83 f8 03          	cmp    $0x3,%rax
    2f7e:	0f 84 14 01 00 00    	je     3098 <pqcrystals_kyber768_ref_gen_matrix+0x14c>
    2f84:	48 69 c8 00 06 00 00 	imul   $0x600,%rax,%rcx
    2f8b:	48 03 4c 24 10       	add    0x10(%rsp),%rcx
    2f90:	48 89 4c 24 18       	mov    %rcx,0x18(%rsp)
    2f95:	0f b6 c8             	movzbl %al,%ecx
    2f98:	89 0c 24             	mov    %ecx,(%rsp)
    2f9b:	31 db                	xor    %ebx,%ebx
    2f9d:	48 89 44 24 20       	mov    %rax,0x20(%rsp)
    2fa2:	48 83 fb 03          	cmp    $0x3,%rbx
    2fa6:	0f 84 e4 00 00 00    	je     3090 <pqcrystals_kyber768_ref_gen_matrix+0x144>
    2fac:	0f b6 cb             	movzbl %bl,%ecx
    2faf:	83 7c 24 04 00       	cmpl   $0x0,0x4(%rsp)
    2fb4:	74 0d                	je     2fc3 <pqcrystals_kyber768_ref_gen_matrix+0x77>
    2fb6:	4c 89 e7             	mov    %r12,%rdi
    2fb9:	48 8b 74 24 08       	mov    0x8(%rsp),%rsi
    2fbe:	8b 14 24             	mov    (%rsp),%edx
    2fc1:	eb 0d                	jmp    2fd0 <pqcrystals_kyber768_ref_gen_matrix+0x84>
    2fc3:	4c 89 e7             	mov    %r12,%rdi
    2fc6:	48 8b 74 24 08       	mov    0x8(%rsp),%rsi
    2fcb:	89 ca                	mov    %ecx,%edx
    2fcd:	8b 0c 24             	mov    (%rsp),%ecx
    2fd0:	e8 bf 1c 00 00       	call   4c94 <pqcrystals_kyber768_ref_kyber_shake128_absorb>
    2fd5:	4c 89 ef             	mov    %r13,%rdi
    2fd8:	6a 03                	push   $0x3
    2fda:	5e                   	pop    %rsi
    2fdb:	4c 89 e2             	mov    %r12,%rdx
    2fde:	e8 51 11 00 00       	call   4134 <pqcrystals_kyber_fips202_ref_shake128_squeezeblocks>
    2fe3:	48 89 5c 24 28       	mov    %rbx,0x28(%rsp)
    2fe8:	48 c1 e3 09          	shl    $0x9,%rbx
    2fec:	48 03 5c 24 18       	add    0x18(%rsp),%rbx
    2ff1:	41 bf f8 01 00 00    	mov    $0x1f8,%r15d
    2ff7:	48 89 df             	mov    %rbx,%rdi
    2ffa:	be 00 01 00 00       	mov    $0x100,%esi
    2fff:	4c 89 ea             	mov    %r13,%rdx
    3002:	b9 f8 01 00 00       	mov    $0x1f8,%ecx
    3007:	e8 9e 00 00 00       	call   30aa <rej_uniform>
    300c:	41 89 c6             	mov    %eax,%r14d
    300f:	41 81 fe ff 00 00 00 	cmp    $0xff,%r14d
    3016:	77 66                	ja     307e <pqcrystals_kyber768_ref_gen_matrix+0x132>
    3018:	44 89 f8             	mov    %r15d,%eax
    301b:	31 d2                	xor    %edx,%edx
    301d:	6a 03                	push   $0x3
    301f:	59                   	pop    %rcx
    3020:	f7 f1                	div    %ecx
    3022:	89 d5                	mov    %edx,%ebp
    3024:	44 89 f8             	mov    %r15d,%eax
    3027:	48 29 e8             	sub    %rbp,%rax
    302a:	48 01 e0             	add    %rsp,%rax
    302d:	48 83 c0 30          	add    $0x30,%rax
    3031:	31 c9                	xor    %ecx,%ecx
    3033:	48 39 cd             	cmp    %rcx,%rbp
    3036:	74 0c                	je     3044 <pqcrystals_kyber768_ref_gen_matrix+0xf8>
    3038:	8a 14 08             	mov    (%rax,%rcx,1),%dl
    303b:	88 54 0c 30          	mov    %dl,0x30(%rsp,%rcx,1)
    303f:	48 ff c1             	inc    %rcx
    3042:	eb ef                	jmp    3033 <pqcrystals_kyber768_ref_gen_matrix+0xe7>
    3044:	48 8d 3c 2c          	lea    (%rsp,%rbp,1),%rdi
    3048:	48 83 c7 30          	add    $0x30,%rdi
    304c:	6a 01                	push   $0x1
    304e:	5e                   	pop    %rsi
    304f:	4c 89 e2             	mov    %r12,%rdx
    3052:	e8 dd 10 00 00       	call   4134 <pqcrystals_kyber_fips202_ref_shake128_squeezeblocks>
    3057:	81 cd a8 00 00 00    	or     $0xa8,%ebp
    305d:	44 89 f0             	mov    %r14d,%eax
    3060:	48 8d 3c 43          	lea    (%rbx,%rax,2),%rdi
    3064:	be 00 01 00 00       	mov    $0x100,%esi
    3069:	44 29 f6             	sub    %r14d,%esi
    306c:	4c 89 ea             	mov    %r13,%rdx
    306f:	89 e9                	mov    %ebp,%ecx
    3071:	e8 34 00 00 00       	call   30aa <rej_uniform>
    3076:	41 01 c6             	add    %eax,%r14d
    3079:	41 89 ef             	mov    %ebp,%r15d
    307c:	eb 91                	jmp    300f <pqcrystals_kyber768_ref_gen_matrix+0xc3>
    307e:	48 8b 5c 24 28       	mov    0x28(%rsp),%rbx
    3083:	48 ff c3             	inc    %rbx
    3086:	48 8b 44 24 20       	mov    0x20(%rsp),%rax
    308b:	e9 12 ff ff ff       	jmp    2fa2 <pqcrystals_kyber768_ref_gen_matrix+0x56>
    3090:	48 ff c0             	inc    %rax
    3093:	e9 e2 fe ff ff       	jmp    2f7a <pqcrystals_kyber768_ref_gen_matrix+0x2e>
    3098:	48 81 c4 08 03 00 00 	add    $0x308,%rsp
    309f:	5b                   	pop    %rbx
    30a0:	41 5c                	pop    %r12
    30a2:	41 5d                	pop    %r13
    30a4:	41 5e                	pop    %r14
    30a6:	41 5f                	pop    %r15
    30a8:	5d                   	pop    %rbp
    30a9:	c3                   	ret

00000000000030aa <rej_uniform>:
    30aa:	53                   	push   %rbx
    30ab:	45 31 c9             	xor    %r9d,%r9d
    30ae:	31 c0                	xor    %eax,%eax
    30b0:	39 f0                	cmp    %esi,%eax
    30b2:	73 6c                	jae    3120 <rej_uniform+0x76>
    30b4:	45 8d 41 03          	lea    0x3(%r9),%r8d
    30b8:	41 39 c8             	cmp    %ecx,%r8d
    30bb:	77 63                	ja     3120 <rej_uniform+0x76>
    30bd:	45 89 ca             	mov    %r9d,%r10d
    30c0:	46 0f b6 14 12       	movzbl (%rdx,%r10,1),%r10d
    30c5:	45 8d 59 01          	lea    0x1(%r9),%r11d
    30c9:	46 0f b6 1c 1a       	movzbl (%rdx,%r11,1),%r11d
    30ce:	44 89 db             	mov    %r11d,%ebx
    30d1:	83 e3 0f             	and    $0xf,%ebx
    30d4:	c1 e3 08             	shl    $0x8,%ebx
    30d7:	44 09 d3             	or     %r10d,%ebx
    30da:	41 83 c1 02          	add    $0x2,%r9d
    30de:	46 0f b6 14 0a       	movzbl (%rdx,%r9,1),%r10d
    30e3:	66 81 fb 00 0d       	cmp    $0xd00,%bx
    30e8:	77 0a                	ja     30f4 <rej_uniform+0x4a>
    30ea:	41 89 c1             	mov    %eax,%r9d
    30ed:	ff c0                	inc    %eax
    30ef:	66 42 89 1c 4f       	mov    %bx,(%rdi,%r9,2)
    30f4:	45 89 c1             	mov    %r8d,%r9d
    30f7:	39 f0                	cmp    %esi,%eax
    30f9:	73 b5                	jae    30b0 <rej_uniform+0x6>
    30fb:	41 c1 eb 04          	shr    $0x4,%r11d
    30ff:	41 c1 e2 04          	shl    $0x4,%r10d
    3103:	45 09 da             	or     %r11d,%r10d
    3106:	45 89 c1             	mov    %r8d,%r9d
    3109:	66 41 81 fa 00 0d    	cmp    $0xd00,%r10w
    310f:	77 9f                	ja     30b0 <rej_uniform+0x6>
    3111:	41 89 c1             	mov    %eax,%r9d
    3114:	ff c0                	inc    %eax
    3116:	66 46 89 14 4f       	mov    %r10w,(%rdi,%r9,2)
    311b:	45 89 c1             	mov    %r8d,%r9d
    311e:	eb 90                	jmp    30b0 <rej_uniform+0x6>
    3120:	5b                   	pop    %rbx
    3121:	c3                   	ret

0000000000003122 <pqcrystals_kyber768_ref_indcpa_keypair>:
    3122:	55                   	push   %rbp
    3123:	41 57                	push   %r15
    3125:	41 56                	push   %r14
    3127:	41 55                	push   %r13
    3129:	41 54                	push   %r12
    312b:	53                   	push   %rbx
    312c:	48 81 ec 48 24 00 00 	sub    $0x2448,%rsp
    3133:	49 89 f6             	mov    %rsi,%r14
    3136:	48 89 fb             	mov    %rdi,%rbx
    3139:	4c 8d 64 24 20       	lea    0x20(%rsp),%r12
    313e:	49 89 e5             	mov    %rsp,%r13
    3141:	6a 20                	push   $0x20
    3143:	41 5f                	pop    %r15
    3145:	4c 89 ef             	mov    %r13,%rdi
    3148:	4c 89 fe             	mov    %r15,%rsi
    314b:	e8 90 ed ff ff       	call   1ee0 <platform_m2_randombytes>
    3150:	4c 89 ef             	mov    %r13,%rdi
    3153:	4c 89 ee             	mov    %r13,%rsi
    3156:	4c 89 fa             	mov    %r15,%rdx
    3159:	e8 e1 1a 00 00       	call   4c3f <pqcrystals_kyber_fips202_ref_sha3_512>
    315e:	4c 8d bc 24 40 12 00 	lea    0x1240(%rsp),%r15
    3165:	00 
    3166:	31 ed                	xor    %ebp,%ebp
    3168:	4c 89 ff             	mov    %r15,%rdi
    316b:	4c 89 ee             	mov    %r13,%rsi
    316e:	31 d2                	xor    %edx,%edx
    3170:	e8 d7 fd ff ff       	call   2f4c <pqcrystals_kyber768_ref_gen_matrix>
    3175:	4c 8d 6c 24 40       	lea    0x40(%rsp),%r13
    317a:	48 83 fd 03          	cmp    $0x3,%rbp
    317e:	74 1b                	je     319b <pqcrystals_kyber768_ref_indcpa_keypair+0x79>
    3180:	40 0f b6 d5          	movzbl %bpl,%edx
    3184:	4c 89 ef             	mov    %r13,%rdi
    3187:	4c 89 e6             	mov    %r12,%rsi
    318a:	e8 4e 05 00 00       	call   36dd <pqcrystals_kyber768_ref_poly_getnoise_eta1>
    318f:	48 ff c5             	inc    %rbp
    3192:	49 81 c5 00 02 00 00 	add    $0x200,%r13
    3199:	eb df                	jmp    317a <pqcrystals_kyber768_ref_indcpa_keypair+0x58>
    319b:	6a fd                	push   $0xfffffffffffffffd
    319d:	5d                   	pop    %rbp
    319e:	4c 8d ac 24 40 06 00 	lea    0x640(%rsp),%r13
    31a5:	00 
    31a6:	48 85 ed             	test   %rbp,%rbp
    31a9:	74 1e                	je     31c9 <pqcrystals_kyber768_ref_indcpa_keypair+0xa7>
    31ab:	48 8d 45 06          	lea    0x6(%rbp),%rax
    31af:	0f b6 d0             	movzbl %al,%edx
    31b2:	4c 89 ef             	mov    %r13,%rdi
    31b5:	4c 89 e6             	mov    %r12,%rsi
    31b8:	e8 20 05 00 00       	call   36dd <pqcrystals_kyber768_ref_poly_getnoise_eta1>
    31bd:	48 ff c5             	inc    %rbp
    31c0:	49 81 c5 00 02 00 00 	add    $0x200,%r13
    31c7:	eb dd                	jmp    31a6 <pqcrystals_kyber768_ref_indcpa_keypair+0x84>
    31c9:	4c 8d 64 24 40       	lea    0x40(%rsp),%r12
    31ce:	4c 89 e7             	mov    %r12,%rdi
    31d1:	e8 a2 08 00 00       	call   3a78 <pqcrystals_kyber768_ref_polyvec_ntt>
    31d6:	48 8d bc 24 40 06 00 	lea    0x640(%rsp),%rdi
    31dd:	00 
    31de:	e8 95 08 00 00       	call   3a78 <pqcrystals_kyber768_ref_polyvec_ntt>
    31e3:	31 ed                	xor    %ebp,%ebp
    31e5:	48 81 fd 00 06 00 00 	cmp    $0x600,%rbp
    31ec:	74 31                	je     321f <pqcrystals_kyber768_ref_indcpa_keypair+0xfd>
    31ee:	4c 8d 2c 2c          	lea    (%rsp,%rbp,1),%r13
    31f2:	49 81 c5 40 0c 00 00 	add    $0xc40,%r13
    31f9:	4c 89 ef             	mov    %r13,%rdi
    31fc:	4c 89 fe             	mov    %r15,%rsi
    31ff:	4c 89 e2             	mov    %r12,%rdx
    3202:	e8 cb 08 00 00       	call   3ad2 <pqcrystals_kyber768_ref_polyvec_basemul_acc_montgomery>
    3207:	4c 89 ef             	mov    %r13,%rdi
    320a:	e8 02 06 00 00       	call   3811 <pqcrystals_kyber768_ref_poly_tomont>
    320f:	48 81 c5 00 02 00 00 	add    $0x200,%rbp
    3216:	49 81 c7 00 06 00 00 	add    $0x600,%r15
    321d:	eb c6                	jmp    31e5 <pqcrystals_kyber768_ref_indcpa_keypair+0xc3>
    321f:	4c 8d bc 24 40 0c 00 	lea    0xc40(%rsp),%r15
    3226:	00 
    3227:	48 8d 94 24 40 06 00 	lea    0x640(%rsp),%rdx
    322e:	00 
    322f:	4c 89 ff             	mov    %r15,%rdi
    3232:	4c 89 fe             	mov    %r15,%rsi
    3235:	e8 3d 09 00 00       	call   3b77 <pqcrystals_kyber768_ref_polyvec_add>
    323a:	4c 89 ff             	mov    %r15,%rdi
    323d:	e8 08 09 00 00       	call   3b4a <pqcrystals_kyber768_ref_polyvec_reduce>
    3242:	48 8d 74 24 40       	lea    0x40(%rsp),%rsi
    3247:	4c 89 f7             	mov    %r14,%rdi
    324a:	e8 b7 07 00 00       	call   3a06 <pqcrystals_kyber768_ref_polyvec_tobytes>
    324f:	48 89 df             	mov    %rbx,%rdi
    3252:	4c 89 fe             	mov    %r15,%rsi
    3255:	e8 ac 07 00 00       	call   3a06 <pqcrystals_kyber768_ref_polyvec_tobytes>
    325a:	31 c0                	xor    %eax,%eax
    325c:	48 83 f8 20          	cmp    $0x20,%rax
    3260:	74 0f                	je     3271 <pqcrystals_kyber768_ref_indcpa_keypair+0x14f>
    3262:	8a 0c 04             	mov    (%rsp,%rax,1),%cl
    3265:	88 8c 03 80 04 00 00 	mov    %cl,0x480(%rbx,%rax,1)
    326c:	48 ff c0             	inc    %rax
    326f:	eb eb                	jmp    325c <pqcrystals_kyber768_ref_indcpa_keypair+0x13a>
    3271:	48 81 c4 48 24 00 00 	add    $0x2448,%rsp
    3278:	5b                   	pop    %rbx
    3279:	41 5c                	pop    %r12
    327b:	41 5d                	pop    %r13
    327d:	41 5e                	pop    %r14
    327f:	41 5f                	pop    %r15
    3281:	5d                   	pop    %rbp
    3282:	c3                   	ret

0000000000003283 <pqcrystals_kyber768_ref_indcpa_enc>:
    3283:	41 57                	push   %r15
    3285:	41 56                	push   %r14
    3287:	41 55                	push   %r13
    3289:	41 54                	push   %r12
    328b:	53                   	push   %rbx
    328c:	48 81 ec 20 30 00 00 	sub    $0x3020,%rsp
    3293:	49 89 cf             	mov    %rcx,%r15
    3296:	49 89 d4             	mov    %rdx,%r12
    3299:	49 89 f6             	mov    %rsi,%r14
    329c:	48 89 fb             	mov    %rdi,%rbx
    329f:	48 8d bc 24 20 18 00 	lea    0x1820(%rsp),%rdi
    32a6:	00 
    32a7:	48 89 d6             	mov    %rdx,%rsi
    32aa:	e8 90 07 00 00       	call   3a3f <pqcrystals_kyber768_ref_polyvec_frombytes>
    32af:	31 c0                	xor    %eax,%eax
    32b1:	48 83 f8 20          	cmp    $0x20,%rax
    32b5:	74 10                	je     32c7 <pqcrystals_kyber768_ref_indcpa_enc+0x44>
    32b7:	41 8a 8c 04 80 04 00 	mov    0x480(%r12,%rax,1),%cl
    32be:	00 
    32bf:	88 0c 04             	mov    %cl,(%rsp,%rax,1)
    32c2:	48 ff c0             	inc    %rax
    32c5:	eb ea                	jmp    32b1 <pqcrystals_kyber768_ref_indcpa_enc+0x2e>
    32c7:	48 8d bc 24 20 02 00 	lea    0x220(%rsp),%rdi
    32ce:	00 
    32cf:	4c 89 f6             	mov    %r14,%rsi
    32d2:	e8 7a 03 00 00       	call   3651 <pqcrystals_kyber768_ref_poly_frommsg>
    32d7:	4c 8d b4 24 20 1e 00 	lea    0x1e20(%rsp),%r14
    32de:	00 
    32df:	48 89 e6             	mov    %rsp,%rsi
    32e2:	6a 01                	push   $0x1
    32e4:	5a                   	pop    %rdx
    32e5:	4c 89 f7             	mov    %r14,%rdi
    32e8:	e8 5f fc ff ff       	call   2f4c <pqcrystals_kyber768_ref_gen_matrix>
    32ed:	4c 8d a4 24 20 06 00 	lea    0x620(%rsp),%r12
    32f4:	00 
    32f5:	45 31 ed             	xor    %r13d,%r13d
    32f8:	49 83 fd 03          	cmp    $0x3,%r13
    32fc:	74 1b                	je     3319 <pqcrystals_kyber768_ref_indcpa_enc+0x96>
    32fe:	41 0f b6 d5          	movzbl %r13b,%edx
    3302:	4c 89 e7             	mov    %r12,%rdi
    3305:	4c 89 fe             	mov    %r15,%rsi
    3308:	e8 d0 03 00 00       	call   36dd <pqcrystals_kyber768_ref_poly_getnoise_eta1>
    330d:	49 ff c5             	inc    %r13
    3310:	49 81 c4 00 02 00 00 	add    $0x200,%r12
    3317:	eb df                	jmp    32f8 <pqcrystals_kyber768_ref_indcpa_enc+0x75>
    3319:	6a fd                	push   $0xfffffffffffffffd
    331b:	41 5d                	pop    %r13
    331d:	4c 8d a4 24 20 12 00 	lea    0x1220(%rsp),%r12
    3324:	00 
    3325:	4d 85 ed             	test   %r13,%r13
    3328:	74 1e                	je     3348 <pqcrystals_kyber768_ref_indcpa_enc+0xc5>
    332a:	49 8d 45 06          	lea    0x6(%r13),%rax
    332e:	0f b6 d0             	movzbl %al,%edx
    3331:	4c 89 e7             	mov    %r12,%rdi
    3334:	4c 89 fe             	mov    %r15,%rsi
    3337:	e8 d9 03 00 00       	call   3715 <pqcrystals_kyber768_ref_poly_getnoise_eta2>
    333c:	49 ff c5             	inc    %r13
    333f:	49 81 c4 00 02 00 00 	add    $0x200,%r12
    3346:	eb dd                	jmp    3325 <pqcrystals_kyber768_ref_indcpa_enc+0xa2>
    3348:	48 8d 7c 24 20       	lea    0x20(%rsp),%rdi
    334d:	6a 06                	push   $0x6
    334f:	5a                   	pop    %rdx
    3350:	4c 89 fe             	mov    %r15,%rsi
    3353:	e8 bd 03 00 00       	call   3715 <pqcrystals_kyber768_ref_poly_getnoise_eta2>
    3358:	4c 8d bc 24 20 06 00 	lea    0x620(%rsp),%r15
    335f:	00 
    3360:	4c 89 ff             	mov    %r15,%rdi
    3363:	e8 10 07 00 00       	call   3a78 <pqcrystals_kyber768_ref_polyvec_ntt>
    3368:	45 31 e4             	xor    %r12d,%r12d
    336b:	49 81 fc 00 06 00 00 	cmp    $0x600,%r12
    3372:	74 26                	je     339a <pqcrystals_kyber768_ref_indcpa_enc+0x117>
    3374:	4a 8d 3c 24          	lea    (%rsp,%r12,1),%rdi
    3378:	48 81 c7 20 0c 00 00 	add    $0xc20,%rdi
    337f:	4c 89 f6             	mov    %r14,%rsi
    3382:	4c 89 fa             	mov    %r15,%rdx
    3385:	e8 48 07 00 00       	call   3ad2 <pqcrystals_kyber768_ref_polyvec_basemul_acc_montgomery>
    338a:	49 81 c4 00 02 00 00 	add    $0x200,%r12
    3391:	49 81 c6 00 06 00 00 	add    $0x600,%r14
    3398:	eb d1                	jmp    336b <pqcrystals_kyber768_ref_indcpa_enc+0xe8>
    339a:	4c 8d b4 24 20 04 00 	lea    0x420(%rsp),%r14
    33a1:	00 
    33a2:	48 8d b4 24 20 18 00 	lea    0x1820(%rsp),%rsi
    33a9:	00 
    33aa:	48 8d 94 24 20 06 00 	lea    0x620(%rsp),%rdx
    33b1:	00 
    33b2:	4c 89 f7             	mov    %r14,%rdi
    33b5:	e8 18 07 00 00       	call   3ad2 <pqcrystals_kyber768_ref_polyvec_basemul_acc_montgomery>
    33ba:	4c 8d bc 24 20 0c 00 	lea    0xc20(%rsp),%r15
    33c1:	00 
    33c2:	4c 89 ff             	mov    %r15,%rdi
    33c5:	e8 db 06 00 00       	call   3aa5 <pqcrystals_kyber768_ref_polyvec_invntt_tomont>
    33ca:	4c 89 f7             	mov    %r14,%rdi
    33cd:	e8 bc 03 00 00       	call   378e <pqcrystals_kyber768_ref_poly_invntt_tomont>
    33d2:	48 8d 94 24 20 12 00 	lea    0x1220(%rsp),%rdx
    33d9:	00 
    33da:	4c 89 ff             	mov    %r15,%rdi
    33dd:	4c 89 fe             	mov    %r15,%rsi
    33e0:	e8 92 07 00 00       	call   3b77 <pqcrystals_kyber768_ref_polyvec_add>
    33e5:	48 8d 54 24 20       	lea    0x20(%rsp),%rdx
    33ea:	4c 89 f7             	mov    %r14,%rdi
    33ed:	4c 89 f6             	mov    %r14,%rsi
    33f0:	e8 51 04 00 00       	call   3846 <pqcrystals_kyber768_ref_poly_add>
    33f5:	48 8d 94 24 20 02 00 	lea    0x220(%rsp),%rdx
    33fc:	00 
    33fd:	4c 89 f7             	mov    %r14,%rdi
    3400:	4c 89 f6             	mov    %r14,%rsi
    3403:	e8 3e 04 00 00       	call   3846 <pqcrystals_kyber768_ref_poly_add>
    3408:	4c 89 ff             	mov    %r15,%rdi
    340b:	e8 3a 07 00 00       	call   3b4a <pqcrystals_kyber768_ref_polyvec_reduce>
    3410:	4c 89 f7             	mov    %r14,%rdi
    3413:	e8 47 03 00 00       	call   375f <pqcrystals_kyber768_ref_poly_reduce>
    3418:	48 89 df             	mov    %rbx,%rdi
    341b:	4c 89 fe             	mov    %r15,%rsi
    341e:	e8 5d 04 00 00       	call   3880 <pqcrystals_kyber768_ref_polyvec_compress>
    3423:	48 81 c3 c0 03 00 00 	add    $0x3c0,%rbx
    342a:	48 89 df             	mov    %rbx,%rdi
    342d:	4c 89 f6             	mov    %r14,%rsi
    3430:	e8 bb 00 00 00       	call   34f0 <pqcrystals_kyber768_ref_poly_compress>
    3435:	48 81 c4 20 30 00 00 	add    $0x3020,%rsp
    343c:	5b                   	pop    %rbx
    343d:	41 5c                	pop    %r12
    343f:	41 5d                	pop    %r13
    3441:	41 5e                	pop    %r14
    3443:	41 5f                	pop    %r15
    3445:	c3                   	ret

0000000000003446 <pqcrystals_kyber768_ref_indcpa_dec>:
    3446:	41 57                	push   %r15
    3448:	41 56                	push   %r14
    344a:	41 55                	push   %r13
    344c:	41 54                	push   %r12
    344e:	53                   	push   %rbx
    344f:	48 81 ec 00 10 00 00 	sub    $0x1000,%rsp
    3456:	49 89 d6             	mov    %rdx,%r14
    3459:	49 89 f7             	mov    %rsi,%r15
    345c:	48 89 fb             	mov    %rdi,%rbx
    345f:	4c 8d a4 24 00 0a 00 	lea    0xa00(%rsp),%r12
    3466:	00 
    3467:	4c 89 e7             	mov    %r12,%rdi
    346a:	e8 d2 04 00 00       	call   3941 <pqcrystals_kyber768_ref_polyvec_decompress>
    346f:	49 81 c7 c0 03 00 00 	add    $0x3c0,%r15
    3476:	4c 8d ac 24 00 02 00 	lea    0x200(%rsp),%r13
    347d:	00 
    347e:	4c 89 ef             	mov    %r13,%rdi
    3481:	4c 89 fe             	mov    %r15,%rsi
    3484:	e8 ee 00 00 00       	call   3577 <pqcrystals_kyber768_ref_poly_decompress>
    3489:	4c 8d bc 24 00 04 00 	lea    0x400(%rsp),%r15
    3490:	00 
    3491:	4c 89 ff             	mov    %r15,%rdi
    3494:	4c 89 f6             	mov    %r14,%rsi
    3497:	e8 a3 05 00 00       	call   3a3f <pqcrystals_kyber768_ref_polyvec_frombytes>
    349c:	4c 89 e7             	mov    %r12,%rdi
    349f:	e8 d4 05 00 00       	call   3a78 <pqcrystals_kyber768_ref_polyvec_ntt>
    34a4:	49 89 e6             	mov    %rsp,%r14
    34a7:	4c 89 f7             	mov    %r14,%rdi
    34aa:	4c 89 fe             	mov    %r15,%rsi
    34ad:	4c 89 e2             	mov    %r12,%rdx
    34b0:	e8 1d 06 00 00       	call   3ad2 <pqcrystals_kyber768_ref_polyvec_basemul_acc_montgomery>
    34b5:	4c 89 f7             	mov    %r14,%rdi
    34b8:	e8 d1 02 00 00       	call   378e <pqcrystals_kyber768_ref_poly_invntt_tomont>
    34bd:	4c 89 f7             	mov    %r14,%rdi
    34c0:	4c 89 ee             	mov    %r13,%rsi
    34c3:	4c 89 f2             	mov    %r14,%rdx
    34c6:	e8 97 03 00 00       	call   3862 <pqcrystals_kyber768_ref_poly_sub>
    34cb:	4c 89 f7             	mov    %r14,%rdi
    34ce:	e8 8c 02 00 00       	call   375f <pqcrystals_kyber768_ref_poly_reduce>
    34d3:	48 89 df             	mov    %rbx,%rdi
    34d6:	4c 89 f6             	mov    %r14,%rsi
    34d9:	e8 a8 01 00 00       	call   3686 <pqcrystals_kyber768_ref_poly_tomsg>
    34de:	48 81 c4 00 10 00 00 	add    $0x1000,%rsp
    34e5:	5b                   	pop    %rbx
    34e6:	41 5c                	pop    %r12
    34e8:	41 5d                	pop    %r13
    34ea:	41 5e                	pop    %r14
    34ec:	41 5f                	pop    %r15
    34ee:	c3                   	ret
    34ef:	90                   	nop

00000000000034f0 <pqcrystals_kyber768_ref_poly_compress>:
    34f0:	31 c9                	xor    %ecx,%ecx
    34f2:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    34f8:	48 83 f9 20          	cmp    $0x20,%rcx
    34fc:	74 78                	je     3576 <pqcrystals_kyber768_ref_poly_compress+0x86>
    34fe:	45 31 c9             	xor    %r9d,%r9d
    3501:	49 83 f9 08          	cmp    $0x8,%r9
    3505:	74 2b                	je     3532 <pqcrystals_kyber768_ref_poly_compress+0x42>
    3507:	42 0f bf 04 4e       	movswl (%rsi,%r9,2),%eax
    350c:	89 c2                	mov    %eax,%edx
    350e:	c1 ea 0f             	shr    $0xf,%edx
    3511:	44 21 c2             	and    %r8d,%edx
    3514:	01 c2                	add    %eax,%edx
    3516:	0f b7 c2             	movzwl %dx,%eax
    3519:	c1 e0 04             	shl    $0x4,%eax
    351c:	05 80 06 00 00       	add    $0x680,%eax
    3521:	31 d2                	xor    %edx,%edx
    3523:	41 f7 f0             	div    %r8d
    3526:	24 0f                	and    $0xf,%al
    3528:	42 88 44 0c f8       	mov    %al,-0x8(%rsp,%r9,1)
    352d:	49 ff c1             	inc    %r9
    3530:	eb cf                	jmp    3501 <pqcrystals_kyber768_ref_poly_compress+0x11>
    3532:	8a 44 24 f9          	mov    -0x7(%rsp),%al
    3536:	c0 e0 04             	shl    $0x4,%al
    3539:	0a 44 24 f8          	or     -0x8(%rsp),%al
    353d:	88 07                	mov    %al,(%rdi)
    353f:	8a 44 24 fb          	mov    -0x5(%rsp),%al
    3543:	c0 e0 04             	shl    $0x4,%al
    3546:	0a 44 24 fa          	or     -0x6(%rsp),%al
    354a:	88 47 01             	mov    %al,0x1(%rdi)
    354d:	8a 44 24 fd          	mov    -0x3(%rsp),%al
    3551:	c0 e0 04             	shl    $0x4,%al
    3554:	0a 44 24 fc          	or     -0x4(%rsp),%al
    3558:	88 47 02             	mov    %al,0x2(%rdi)
    355b:	8a 44 24 ff          	mov    -0x1(%rsp),%al
    355f:	c0 e0 04             	shl    $0x4,%al
    3562:	0a 44 24 fe          	or     -0x2(%rsp),%al
    3566:	88 47 03             	mov    %al,0x3(%rdi)
    3569:	48 83 c7 04          	add    $0x4,%rdi
    356d:	48 ff c1             	inc    %rcx
    3570:	48 83 c6 10          	add    $0x10,%rsi
    3574:	eb 82                	jmp    34f8 <pqcrystals_kyber768_ref_poly_compress+0x8>
    3576:	c3                   	ret

0000000000003577 <pqcrystals_kyber768_ref_poly_decompress>:
    3577:	31 c0                	xor    %eax,%eax
    3579:	48 3d 80 00 00 00    	cmp    $0x80,%rax
    357f:	74 34                	je     35b5 <pqcrystals_kyber768_ref_poly_decompress+0x3e>
    3581:	0f b6 0c 06          	movzbl (%rsi,%rax,1),%ecx
    3585:	83 e1 0f             	and    $0xf,%ecx
    3588:	69 c9 01 0d 00 00    	imul   $0xd01,%ecx,%ecx
    358e:	83 c1 08             	add    $0x8,%ecx
    3591:	c1 e9 04             	shr    $0x4,%ecx
    3594:	66 89 0c 87          	mov    %cx,(%rdi,%rax,4)
    3598:	0f b6 0c 06          	movzbl (%rsi,%rax,1),%ecx
    359c:	c1 e9 04             	shr    $0x4,%ecx
    359f:	69 c9 01 0d 00 00    	imul   $0xd01,%ecx,%ecx
    35a5:	83 c1 08             	add    $0x8,%ecx
    35a8:	c1 e9 04             	shr    $0x4,%ecx
    35ab:	66 89 4c 87 02       	mov    %cx,0x2(%rdi,%rax,4)
    35b0:	48 ff c0             	inc    %rax
    35b3:	eb c4                	jmp    3579 <pqcrystals_kyber768_ref_poly_decompress+0x2>
    35b5:	c3                   	ret

00000000000035b6 <pqcrystals_kyber768_ref_poly_tobytes>:
    35b6:	48 83 c7 02          	add    $0x2,%rdi
    35ba:	31 c0                	xor    %eax,%eax
    35bc:	b9 01 0d 00 00       	mov    $0xd01,%ecx
    35c1:	48 3d 80 00 00 00    	cmp    $0x80,%rax
    35c7:	74 47                	je     3610 <pqcrystals_kyber768_ref_poly_tobytes+0x5a>
    35c9:	44 0f bf 04 86       	movswl (%rsi,%rax,4),%r8d
    35ce:	44 89 c2             	mov    %r8d,%edx
    35d1:	c1 ea 0f             	shr    $0xf,%edx
    35d4:	21 ca                	and    %ecx,%edx
    35d6:	44 01 c2             	add    %r8d,%edx
    35d9:	44 0f bf 44 86 02    	movswl 0x2(%rsi,%rax,4),%r8d
    35df:	45 89 c1             	mov    %r8d,%r9d
    35e2:	41 c1 e9 0f          	shr    $0xf,%r9d
    35e6:	41 21 c9             	and    %ecx,%r9d
    35e9:	45 01 c1             	add    %r8d,%r9d
    35ec:	88 57 fe             	mov    %dl,-0x2(%rdi)
    35ef:	0f b6 d6             	movzbl %dh,%edx
    35f2:	45 89 c8             	mov    %r9d,%r8d
    35f5:	41 c1 e0 04          	shl    $0x4,%r8d
    35f9:	41 09 d0             	or     %edx,%r8d
    35fc:	44 88 47 ff          	mov    %r8b,-0x1(%rdi)
    3600:	41 c1 e9 04          	shr    $0x4,%r9d
    3604:	44 88 0f             	mov    %r9b,(%rdi)
    3607:	48 ff c0             	inc    %rax
    360a:	48 83 c7 03          	add    $0x3,%rdi
    360e:	eb b1                	jmp    35c1 <pqcrystals_kyber768_ref_poly_tobytes+0xb>
    3610:	c3                   	ret

0000000000003611 <pqcrystals_kyber768_ref_poly_frombytes>:
    3611:	48 83 c6 02          	add    $0x2,%rsi
    3615:	31 c0                	xor    %eax,%eax
    3617:	48 3d 80 00 00 00    	cmp    $0x80,%rax
    361d:	74 31                	je     3650 <pqcrystals_kyber768_ref_poly_frombytes+0x3f>
    361f:	0f b6 4e fe          	movzbl -0x2(%rsi),%ecx
    3623:	0f b6 56 ff          	movzbl -0x1(%rsi),%edx
    3627:	83 e2 0f             	and    $0xf,%edx
    362a:	c1 e2 08             	shl    $0x8,%edx
    362d:	09 ca                	or     %ecx,%edx
    362f:	66 89 14 87          	mov    %dx,(%rdi,%rax,4)
    3633:	0f b6 4e ff          	movzbl -0x1(%rsi),%ecx
    3637:	c1 e9 04             	shr    $0x4,%ecx
    363a:	0f b6 16             	movzbl (%rsi),%edx
    363d:	c1 e2 04             	shl    $0x4,%edx
    3640:	09 ca                	or     %ecx,%edx
    3642:	66 89 54 87 02       	mov    %dx,0x2(%rdi,%rax,4)
    3647:	48 ff c0             	inc    %rax
    364a:	48 83 c6 03          	add    $0x3,%rsi
    364e:	eb c7                	jmp    3617 <pqcrystals_kyber768_ref_poly_frombytes+0x6>
    3650:	c3                   	ret

0000000000003651 <pqcrystals_kyber768_ref_poly_frommsg>:
    3651:	31 c0                	xor    %eax,%eax
    3653:	48 83 f8 20          	cmp    $0x20,%rax
    3657:	74 2c                	je     3685 <pqcrystals_kyber768_ref_poly_frommsg+0x34>
    3659:	31 c9                	xor    %ecx,%ecx
    365b:	48 83 f9 08          	cmp    $0x8,%rcx
    365f:	74 1b                	je     367c <pqcrystals_kyber768_ref_poly_frommsg+0x2b>
    3661:	44 0f b6 04 06       	movzbl (%rsi,%rax,1),%r8d
    3666:	31 d2                	xor    %edx,%edx
    3668:	41 0f a3 c8          	bt     %ecx,%r8d
    366c:	73 05                	jae    3673 <pqcrystals_kyber768_ref_poly_frommsg+0x22>
    366e:	ba 81 06 00 00       	mov    $0x681,%edx
    3673:	66 89 14 4f          	mov    %dx,(%rdi,%rcx,2)
    3677:	48 ff c1             	inc    %rcx
    367a:	eb df                	jmp    365b <pqcrystals_kyber768_ref_poly_frommsg+0xa>
    367c:	48 ff c0             	inc    %rax
    367f:	48 83 c7 10          	add    $0x10,%rdi
    3683:	eb ce                	jmp    3653 <pqcrystals_kyber768_ref_poly_frommsg+0x2>
    3685:	c3                   	ret

0000000000003686 <pqcrystals_kyber768_ref_poly_tomsg>:
    3686:	45 31 c0             	xor    %r8d,%r8d
    3689:	41 b9 01 0d 00 00    	mov    $0xd01,%r9d
    368f:	49 83 f8 20          	cmp    $0x20,%r8
    3693:	74 47                	je     36dc <pqcrystals_kyber768_ref_poly_tomsg+0x56>
    3695:	42 c6 04 07 00       	movb   $0x0,(%rdi,%r8,1)
    369a:	31 c9                	xor    %ecx,%ecx
    369c:	45 31 d2             	xor    %r10d,%r10d
    369f:	48 83 f9 08          	cmp    $0x8,%rcx
    36a3:	74 2e                	je     36d3 <pqcrystals_kyber768_ref_poly_tomsg+0x4d>
    36a5:	0f bf 04 4e          	movswl (%rsi,%rcx,2),%eax
    36a9:	89 c2                	mov    %eax,%edx
    36ab:	c1 ea 0f             	shr    $0xf,%edx
    36ae:	44 21 ca             	and    %r9d,%edx
    36b1:	01 c2                	add    %eax,%edx
    36b3:	0f b7 c2             	movzwl %dx,%eax
    36b6:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
    36bd:	31 d2                	xor    %edx,%edx
    36bf:	41 f7 f1             	div    %r9d
    36c2:	83 e0 01             	and    $0x1,%eax
    36c5:	d3 e0                	shl    %cl,%eax
    36c7:	41 08 c2             	or     %al,%r10b
    36ca:	46 88 14 07          	mov    %r10b,(%rdi,%r8,1)
    36ce:	48 ff c1             	inc    %rcx
    36d1:	eb cc                	jmp    369f <pqcrystals_kyber768_ref_poly_tomsg+0x19>
    36d3:	49 ff c0             	inc    %r8
    36d6:	48 83 c6 10          	add    $0x10,%rsi
    36da:	eb b3                	jmp    368f <pqcrystals_kyber768_ref_poly_tomsg+0x9>
    36dc:	c3                   	ret

00000000000036dd <pqcrystals_kyber768_ref_poly_getnoise_eta1>:
    36dd:	41 56                	push   %r14
    36df:	53                   	push   %rbx
    36e0:	48 81 ec 88 00 00 00 	sub    $0x88,%rsp
    36e7:	89 d1                	mov    %edx,%ecx
    36e9:	48 89 f2             	mov    %rsi,%rdx
    36ec:	48 89 fb             	mov    %rdi,%rbx
    36ef:	49 89 e6             	mov    %rsp,%r14
    36f2:	be 80 00 00 00       	mov    $0x80,%esi
    36f7:	4c 89 f7             	mov    %r14,%rdi
    36fa:	e8 bd 15 00 00       	call   4cbc <pqcrystals_kyber768_ref_kyber_shake256_prf>
    36ff:	48 89 df             	mov    %rbx,%rdi
    3702:	4c 89 f6             	mov    %r14,%rsi
    3705:	e8 a6 06 00 00       	call   3db0 <pqcrystals_kyber768_ref_poly_cbd_eta1>
    370a:	48 81 c4 88 00 00 00 	add    $0x88,%rsp
    3711:	5b                   	pop    %rbx
    3712:	41 5e                	pop    %r14
    3714:	c3                   	ret

0000000000003715 <pqcrystals_kyber768_ref_poly_getnoise_eta2>:
    3715:	41 56                	push   %r14
    3717:	53                   	push   %rbx
    3718:	48 81 ec 88 00 00 00 	sub    $0x88,%rsp
    371f:	89 d1                	mov    %edx,%ecx
    3721:	48 89 f2             	mov    %rsi,%rdx
    3724:	48 89 fb             	mov    %rdi,%rbx
    3727:	49 89 e6             	mov    %rsp,%r14
    372a:	be 80 00 00 00       	mov    $0x80,%esi
    372f:	4c 89 f7             	mov    %r14,%rdi
    3732:	e8 85 15 00 00       	call   4cbc <pqcrystals_kyber768_ref_kyber_shake256_prf>
    3737:	48 89 df             	mov    %rbx,%rdi
    373a:	4c 89 f6             	mov    %r14,%rsi
    373d:	e8 d0 06 00 00       	call   3e12 <pqcrystals_kyber768_ref_poly_cbd_eta2>
    3742:	48 81 c4 88 00 00 00 	add    $0x88,%rsp
    3749:	5b                   	pop    %rbx
    374a:	41 5e                	pop    %r14
    374c:	c3                   	ret

000000000000374d <pqcrystals_kyber768_ref_poly_ntt>:
    374d:	53                   	push   %rbx
    374e:	48 89 fb             	mov    %rdi,%rbx
    3751:	e8 66 04 00 00       	call   3bbc <pqcrystals_kyber768_ref_ntt>
    3756:	48 89 df             	mov    %rbx,%rdi
    3759:	5b                   	pop    %rbx
    375a:	e9 00 00 00 00       	jmp    375f <pqcrystals_kyber768_ref_poly_reduce>

000000000000375f <pqcrystals_kyber768_ref_poly_reduce>:
    375f:	41 56                	push   %r14
    3761:	53                   	push   %rbx
    3762:	50                   	push   %rax
    3763:	48 89 fb             	mov    %rdi,%rbx
    3766:	45 31 f6             	xor    %r14d,%r14d
    3769:	49 81 fe 00 01 00 00 	cmp    $0x100,%r14
    3770:	74 14                	je     3786 <pqcrystals_kyber768_ref_poly_reduce+0x27>
    3772:	42 0f bf 3c 73       	movswl (%rbx,%r14,2),%edi
    3777:	e8 ad 06 00 00       	call   3e29 <pqcrystals_kyber768_ref_barrett_reduce>
    377c:	66 42 89 04 73       	mov    %ax,(%rbx,%r14,2)
    3781:	49 ff c6             	inc    %r14
    3784:	eb e3                	jmp    3769 <pqcrystals_kyber768_ref_poly_reduce+0xa>
    3786:	48 83 c4 08          	add    $0x8,%rsp
    378a:	5b                   	pop    %rbx
    378b:	41 5e                	pop    %r14
    378d:	c3                   	ret

000000000000378e <pqcrystals_kyber768_ref_poly_invntt_tomont>:
    378e:	e9 c8 04 00 00       	jmp    3c5b <pqcrystals_kyber768_ref_invntt>

0000000000003793 <pqcrystals_kyber768_ref_poly_basemul_montgomery>:
    3793:	55                   	push   %rbp
    3794:	41 57                	push   %r15
    3796:	41 56                	push   %r14
    3798:	41 55                	push   %r13
    379a:	41 54                	push   %r12
    379c:	53                   	push   %rbx
    379d:	50                   	push   %rax
    379e:	48 89 d3             	mov    %rdx,%rbx
    37a1:	49 89 f6             	mov    %rsi,%r14
    37a4:	49 89 ff             	mov    %rdi,%r15
    37a7:	4c 8d 25 e2 90 00 00 	lea    0x90e2(%rip),%r12        # c890 <pqcrystals_kyber768_ref_zetas>
    37ae:	49 83 ec 80          	sub    $0xffffffffffffff80,%r12
    37b2:	45 31 ed             	xor    %r13d,%r13d
    37b5:	49 81 fd 00 02 00 00 	cmp    $0x200,%r13
    37bc:	74 44                	je     3802 <pqcrystals_kyber768_ref_poly_basemul_montgomery+0x6f>
    37be:	4b 8d 3c 2f          	lea    (%r15,%r13,1),%rdi
    37c2:	4b 8d 34 2e          	lea    (%r14,%r13,1),%rsi
    37c6:	4a 8d 14 2b          	lea    (%rbx,%r13,1),%rdx
    37ca:	41 0f bf 2c 24       	movswl (%r12),%ebp
    37cf:	89 e9                	mov    %ebp,%ecx
    37d1:	e8 6a 05 00 00       	call   3d40 <pqcrystals_kyber768_ref_basemul>
    37d6:	4b 8d 3c 2f          	lea    (%r15,%r13,1),%rdi
    37da:	48 83 c7 04          	add    $0x4,%rdi
    37de:	4b 8d 34 2e          	lea    (%r14,%r13,1),%rsi
    37e2:	48 83 c6 04          	add    $0x4,%rsi
    37e6:	4a 8d 14 2b          	lea    (%rbx,%r13,1),%rdx
    37ea:	48 83 c2 04          	add    $0x4,%rdx
    37ee:	f7 dd                	neg    %ebp
    37f0:	0f bf cd             	movswl %bp,%ecx
    37f3:	e8 48 05 00 00       	call   3d40 <pqcrystals_kyber768_ref_basemul>
    37f8:	49 83 c5 08          	add    $0x8,%r13
    37fc:	49 83 c4 02          	add    $0x2,%r12
    3800:	eb b3                	jmp    37b5 <pqcrystals_kyber768_ref_poly_basemul_montgomery+0x22>
    3802:	48 83 c4 08          	add    $0x8,%rsp
    3806:	5b                   	pop    %rbx
    3807:	41 5c                	pop    %r12
    3809:	41 5d                	pop    %r13
    380b:	41 5e                	pop    %r14
    380d:	41 5f                	pop    %r15
    380f:	5d                   	pop    %rbp
    3810:	c3                   	ret

0000000000003811 <pqcrystals_kyber768_ref_poly_tomont>:
    3811:	41 56                	push   %r14
    3813:	53                   	push   %rbx
    3814:	50                   	push   %rax
    3815:	48 89 fb             	mov    %rdi,%rbx
    3818:	45 31 f6             	xor    %r14d,%r14d
    381b:	49 81 fe 00 01 00 00 	cmp    $0x100,%r14
    3822:	74 1a                	je     383e <pqcrystals_kyber768_ref_poly_tomont+0x2d>
    3824:	42 0f bf 04 73       	movswl (%rbx,%r14,2),%eax
    3829:	69 f8 49 05 00 00    	imul   $0x549,%eax,%edi
    382f:	e8 e0 05 00 00       	call   3e14 <pqcrystals_kyber768_ref_montgomery_reduce>
    3834:	66 42 89 04 73       	mov    %ax,(%rbx,%r14,2)
    3839:	49 ff c6             	inc    %r14
    383c:	eb dd                	jmp    381b <pqcrystals_kyber768_ref_poly_tomont+0xa>
    383e:	48 83 c4 08          	add    $0x8,%rsp
    3842:	5b                   	pop    %rbx
    3843:	41 5e                	pop    %r14
    3845:	c3                   	ret

0000000000003846 <pqcrystals_kyber768_ref_poly_add>:
    3846:	31 c0                	xor    %eax,%eax
    3848:	48 3d 00 01 00 00    	cmp    $0x100,%rax
    384e:	74 11                	je     3861 <pqcrystals_kyber768_ref_poly_add+0x1b>
    3850:	0f b7 0c 42          	movzwl (%rdx,%rax,2),%ecx
    3854:	66 03 0c 46          	add    (%rsi,%rax,2),%cx
    3858:	66 89 0c 47          	mov    %cx,(%rdi,%rax,2)
    385c:	48 ff c0             	inc    %rax
    385f:	eb e7                	jmp    3848 <pqcrystals_kyber768_ref_poly_add+0x2>
    3861:	c3                   	ret

0000000000003862 <pqcrystals_kyber768_ref_poly_sub>:
    3862:	31 c0                	xor    %eax,%eax
    3864:	48 3d 00 01 00 00    	cmp    $0x100,%rax
    386a:	74 11                	je     387d <pqcrystals_kyber768_ref_poly_sub+0x1b>
    386c:	0f b7 0c 46          	movzwl (%rsi,%rax,2),%ecx
    3870:	66 2b 0c 42          	sub    (%rdx,%rax,2),%cx
    3874:	66 89 0c 47          	mov    %cx,(%rdi,%rax,2)
    3878:	48 ff c0             	inc    %rax
    387b:	eb e7                	jmp    3864 <pqcrystals_kyber768_ref_poly_sub+0x2>
    387d:	c3                   	ret
    387e:	66 90                	xchg   %ax,%ax

0000000000003880 <pqcrystals_kyber768_ref_polyvec_compress>:
    3880:	31 c9                	xor    %ecx,%ecx
    3882:	41 b8 01 0d 00 00    	mov    $0xd01,%r8d
    3888:	48 83 f9 03          	cmp    $0x3,%rcx
    388c:	0f 84 ae 00 00 00    	je     3940 <pqcrystals_kyber768_ref_polyvec_compress+0xc0>
    3892:	49 89 f1             	mov    %rsi,%r9
    3895:	45 31 d2             	xor    %r10d,%r10d
    3898:	49 83 fa 40          	cmp    $0x40,%r10
    389c:	0f 84 8f 00 00 00    	je     3931 <pqcrystals_kyber768_ref_polyvec_compress+0xb1>
    38a2:	45 31 db             	xor    %r11d,%r11d
    38a5:	49 83 fb 04          	cmp    $0x4,%r11
    38a9:	74 2f                	je     38da <pqcrystals_kyber768_ref_polyvec_compress+0x5a>
    38ab:	43 0f bf 04 59       	movswl (%r9,%r11,2),%eax
    38b0:	89 c2                	mov    %eax,%edx
    38b2:	c1 ea 0f             	shr    $0xf,%edx
    38b5:	44 21 c2             	and    %r8d,%edx
    38b8:	01 c2                	add    %eax,%edx
    38ba:	0f b7 c2             	movzwl %dx,%eax
    38bd:	c1 e0 0a             	shl    $0xa,%eax
    38c0:	05 80 06 00 00       	add    $0x680,%eax
    38c5:	31 d2                	xor    %edx,%edx
    38c7:	41 f7 f0             	div    %r8d
    38ca:	25 ff 03 00 00       	and    $0x3ff,%eax
    38cf:	66 42 89 44 5c f8    	mov    %ax,-0x8(%rsp,%r11,2)
    38d5:	49 ff c3             	inc    %r11
    38d8:	eb cb                	jmp    38a5 <pqcrystals_kyber768_ref_polyvec_compress+0x25>
    38da:	8a 44 24 f8          	mov    -0x8(%rsp),%al
    38de:	88 07                	mov    %al,(%rdi)
    38e0:	8a 44 24 fa          	mov    -0x6(%rsp),%al
    38e4:	c0 e0 02             	shl    $0x2,%al
    38e7:	0a 44 24 f9          	or     -0x7(%rsp),%al
    38eb:	88 47 01             	mov    %al,0x1(%rdi)
    38ee:	0f b7 44 24 fa       	movzwl -0x6(%rsp),%eax
    38f3:	c1 e8 06             	shr    $0x6,%eax
    38f6:	8a 54 24 fc          	mov    -0x4(%rsp),%dl
    38fa:	c0 e2 04             	shl    $0x4,%dl
    38fd:	08 c2                	or     %al,%dl
    38ff:	88 57 02             	mov    %dl,0x2(%rdi)
    3902:	0f b7 44 24 fc       	movzwl -0x4(%rsp),%eax
    3907:	c1 e8 04             	shr    $0x4,%eax
    390a:	8a 54 24 fe          	mov    -0x2(%rsp),%dl
    390e:	c0 e2 06             	shl    $0x6,%dl
    3911:	08 c2                	or     %al,%dl
    3913:	88 57 03             	mov    %dl,0x3(%rdi)
    3916:	0f b7 44 24 fe       	movzwl -0x2(%rsp),%eax
    391b:	c1 e8 02             	shr    $0x2,%eax
    391e:	88 47 04             	mov    %al,0x4(%rdi)
    3921:	48 83 c7 05          	add    $0x5,%rdi
    3925:	49 ff c2             	inc    %r10
    3928:	49 83 c1 08          	add    $0x8,%r9
    392c:	e9 67 ff ff ff       	jmp    3898 <pqcrystals_kyber768_ref_polyvec_compress+0x18>
    3931:	48 ff c1             	inc    %rcx
    3934:	48 81 c6 00 02 00 00 	add    $0x200,%rsi
    393b:	e9 48 ff ff ff       	jmp    3888 <pqcrystals_kyber768_ref_polyvec_compress+0x8>
    3940:	c3                   	ret

0000000000003941 <pqcrystals_kyber768_ref_polyvec_decompress>:
    3941:	31 c0                	xor    %eax,%eax
    3943:	48 83 f8 03          	cmp    $0x3,%rax
    3947:	0f 84 b8 00 00 00    	je     3a05 <pqcrystals_kyber768_ref_polyvec_decompress+0xc4>
    394d:	48 89 f9             	mov    %rdi,%rcx
    3950:	31 d2                	xor    %edx,%edx
    3952:	48 83 fa 40          	cmp    $0x40,%rdx
    3956:	0f 84 9a 00 00 00    	je     39f6 <pqcrystals_kyber768_ref_polyvec_decompress+0xb5>
    395c:	44 0f b7 06          	movzwl (%rsi),%r8d
    3960:	66 44 89 44 24 f8    	mov    %r8w,-0x8(%rsp)
    3966:	44 0f b6 46 01       	movzbl 0x1(%rsi),%r8d
    396b:	41 c1 e8 02          	shr    $0x2,%r8d
    396f:	44 0f b6 4e 02       	movzbl 0x2(%rsi),%r9d
    3974:	41 c1 e1 06          	shl    $0x6,%r9d
    3978:	45 09 c1             	or     %r8d,%r9d
    397b:	66 44 89 4c 24 fa    	mov    %r9w,-0x6(%rsp)
    3981:	44 0f b6 46 02       	movzbl 0x2(%rsi),%r8d
    3986:	41 c1 e8 04          	shr    $0x4,%r8d
    398a:	44 0f b6 4e 03       	movzbl 0x3(%rsi),%r9d
    398f:	41 c1 e1 04          	shl    $0x4,%r9d
    3993:	45 09 c1             	or     %r8d,%r9d
    3996:	66 44 89 4c 24 fc    	mov    %r9w,-0x4(%rsp)
    399c:	44 0f b6 46 03       	movzbl 0x3(%rsi),%r8d
    39a1:	41 c1 e8 06          	shr    $0x6,%r8d
    39a5:	44 0f b6 4e 04       	movzbl 0x4(%rsi),%r9d
    39aa:	47 8d 04 88          	lea    (%r8,%r9,4),%r8d
    39ae:	66 44 89 44 24 fe    	mov    %r8w,-0x2(%rsp)
    39b4:	45 31 c0             	xor    %r8d,%r8d
    39b7:	49 83 f8 04          	cmp    $0x4,%r8
    39bb:	74 29                	je     39e6 <pqcrystals_kyber768_ref_polyvec_decompress+0xa5>
    39bd:	46 0f b7 4c 44 f8    	movzwl -0x8(%rsp,%r8,2),%r9d
    39c3:	41 81 e1 ff 03 00 00 	and    $0x3ff,%r9d
    39ca:	45 69 c9 01 0d 00 00 	imul   $0xd01,%r9d,%r9d
    39d1:	41 81 c1 00 02 00 00 	add    $0x200,%r9d
    39d8:	41 c1 e9 0a          	shr    $0xa,%r9d
    39dc:	66 46 89 0c 41       	mov    %r9w,(%rcx,%r8,2)
    39e1:	49 ff c0             	inc    %r8
    39e4:	eb d1                	jmp    39b7 <pqcrystals_kyber768_ref_polyvec_decompress+0x76>
    39e6:	48 83 c6 05          	add    $0x5,%rsi
    39ea:	48 ff c2             	inc    %rdx
    39ed:	48 83 c1 08          	add    $0x8,%rcx
    39f1:	e9 5c ff ff ff       	jmp    3952 <pqcrystals_kyber768_ref_polyvec_decompress+0x11>
    39f6:	48 ff c0             	inc    %rax
    39f9:	48 81 c7 00 02 00 00 	add    $0x200,%rdi
    3a00:	e9 3e ff ff ff       	jmp    3943 <pqcrystals_kyber768_ref_polyvec_decompress+0x2>
    3a05:	c3                   	ret

0000000000003a06 <pqcrystals_kyber768_ref_polyvec_tobytes>:
    3a06:	41 57                	push   %r15
    3a08:	41 56                	push   %r14
    3a0a:	53                   	push   %rbx
    3a0b:	48 89 f3             	mov    %rsi,%rbx
    3a0e:	49 89 fe             	mov    %rdi,%r14
    3a11:	45 31 ff             	xor    %r15d,%r15d
    3a14:	49 81 ff 00 06 00 00 	cmp    $0x600,%r15
    3a1b:	74 1c                	je     3a39 <pqcrystals_kyber768_ref_polyvec_tobytes+0x33>
    3a1d:	4a 8d 34 3b          	lea    (%rbx,%r15,1),%rsi
    3a21:	4c 89 f7             	mov    %r14,%rdi
    3a24:	e8 8d fb ff ff       	call   35b6 <pqcrystals_kyber768_ref_poly_tobytes>
    3a29:	49 81 c7 00 02 00 00 	add    $0x200,%r15
    3a30:	49 81 c6 80 01 00 00 	add    $0x180,%r14
    3a37:	eb db                	jmp    3a14 <pqcrystals_kyber768_ref_polyvec_tobytes+0xe>
    3a39:	5b                   	pop    %rbx
    3a3a:	41 5e                	pop    %r14
    3a3c:	41 5f                	pop    %r15
    3a3e:	c3                   	ret

0000000000003a3f <pqcrystals_kyber768_ref_polyvec_frombytes>:
    3a3f:	41 57                	push   %r15
    3a41:	41 56                	push   %r14
    3a43:	53                   	push   %rbx
    3a44:	48 89 f3             	mov    %rsi,%rbx
    3a47:	49 89 fe             	mov    %rdi,%r14
    3a4a:	45 31 ff             	xor    %r15d,%r15d
    3a4d:	49 81 ff 80 04 00 00 	cmp    $0x480,%r15
    3a54:	74 1c                	je     3a72 <pqcrystals_kyber768_ref_polyvec_frombytes+0x33>
    3a56:	4a 8d 34 3b          	lea    (%rbx,%r15,1),%rsi
    3a5a:	4c 89 f7             	mov    %r14,%rdi
    3a5d:	e8 af fb ff ff       	call   3611 <pqcrystals_kyber768_ref_poly_frombytes>
    3a62:	49 81 c7 80 01 00 00 	add    $0x180,%r15
    3a69:	49 81 c6 00 02 00 00 	add    $0x200,%r14
    3a70:	eb db                	jmp    3a4d <pqcrystals_kyber768_ref_polyvec_frombytes+0xe>
    3a72:	5b                   	pop    %rbx
    3a73:	41 5e                	pop    %r14
    3a75:	41 5f                	pop    %r15
    3a77:	c3                   	ret

0000000000003a78 <pqcrystals_kyber768_ref_polyvec_ntt>:
    3a78:	41 56                	push   %r14
    3a7a:	53                   	push   %rbx
    3a7b:	50                   	push   %rax
    3a7c:	48 89 fb             	mov    %rdi,%rbx
    3a7f:	45 31 f6             	xor    %r14d,%r14d
    3a82:	49 81 fe 00 06 00 00 	cmp    $0x600,%r14
    3a89:	74 12                	je     3a9d <pqcrystals_kyber768_ref_polyvec_ntt+0x25>
    3a8b:	4a 8d 3c 33          	lea    (%rbx,%r14,1),%rdi
    3a8f:	e8 b9 fc ff ff       	call   374d <pqcrystals_kyber768_ref_poly_ntt>
    3a94:	49 81 c6 00 02 00 00 	add    $0x200,%r14
    3a9b:	eb e5                	jmp    3a82 <pqcrystals_kyber768_ref_polyvec_ntt+0xa>
    3a9d:	48 83 c4 08          	add    $0x8,%rsp
    3aa1:	5b                   	pop    %rbx
    3aa2:	41 5e                	pop    %r14
    3aa4:	c3                   	ret

0000000000003aa5 <pqcrystals_kyber768_ref_polyvec_invntt_tomont>:
    3aa5:	41 56                	push   %r14
    3aa7:	53                   	push   %rbx
    3aa8:	50                   	push   %rax
    3aa9:	48 89 fb             	mov    %rdi,%rbx
    3aac:	45 31 f6             	xor    %r14d,%r14d
    3aaf:	49 81 fe 00 06 00 00 	cmp    $0x600,%r14
    3ab6:	74 12                	je     3aca <pqcrystals_kyber768_ref_polyvec_invntt_tomont+0x25>
    3ab8:	4a 8d 3c 33          	lea    (%rbx,%r14,1),%rdi
    3abc:	e8 cd fc ff ff       	call   378e <pqcrystals_kyber768_ref_poly_invntt_tomont>
    3ac1:	49 81 c6 00 02 00 00 	add    $0x200,%r14
    3ac8:	eb e5                	jmp    3aaf <pqcrystals_kyber768_ref_polyvec_invntt_tomont+0xa>
    3aca:	48 83 c4 08          	add    $0x8,%rsp
    3ace:	5b                   	pop    %rbx
    3acf:	41 5e                	pop    %r14
    3ad1:	c3                   	ret

0000000000003ad2 <pqcrystals_kyber768_ref_polyvec_basemul_acc_montgomery>:
    3ad2:	41 57                	push   %r15
    3ad4:	41 56                	push   %r14
    3ad6:	41 55                	push   %r13
    3ad8:	41 54                	push   %r12
    3ada:	53                   	push   %rbx
    3adb:	48 81 ec 00 02 00 00 	sub    $0x200,%rsp
    3ae2:	49 89 d6             	mov    %rdx,%r14
    3ae5:	49 89 f7             	mov    %rsi,%r15
    3ae8:	48 89 fb             	mov    %rdi,%rbx
    3aeb:	e8 a3 fc ff ff       	call   3793 <pqcrystals_kyber768_ref_poly_basemul_montgomery>
    3af0:	b8 00 02 00 00       	mov    $0x200,%eax
    3af5:	49 01 c7             	add    %rax,%r15
    3af8:	49 01 c6             	add    %rax,%r14
    3afb:	45 31 ed             	xor    %r13d,%r13d
    3afe:	49 89 e4             	mov    %rsp,%r12
    3b01:	49 81 fd 00 04 00 00 	cmp    $0x400,%r13
    3b08:	74 27                	je     3b31 <pqcrystals_kyber768_ref_polyvec_basemul_acc_montgomery+0x5f>
    3b0a:	4b 8d 34 2f          	lea    (%r15,%r13,1),%rsi
    3b0e:	4b 8d 14 2e          	lea    (%r14,%r13,1),%rdx
    3b12:	4c 89 e7             	mov    %r12,%rdi
    3b15:	e8 79 fc ff ff       	call   3793 <pqcrystals_kyber768_ref_poly_basemul_montgomery>
    3b1a:	48 89 df             	mov    %rbx,%rdi
    3b1d:	48 89 de             	mov    %rbx,%rsi
    3b20:	4c 89 e2             	mov    %r12,%rdx
    3b23:	e8 1e fd ff ff       	call   3846 <pqcrystals_kyber768_ref_poly_add>
    3b28:	49 81 c5 00 02 00 00 	add    $0x200,%r13
    3b2f:	eb d0                	jmp    3b01 <pqcrystals_kyber768_ref_polyvec_basemul_acc_montgomery+0x2f>
    3b31:	48 89 df             	mov    %rbx,%rdi
    3b34:	e8 26 fc ff ff       	call   375f <pqcrystals_kyber768_ref_poly_reduce>
    3b39:	48 81 c4 00 02 00 00 	add    $0x200,%rsp
    3b40:	5b                   	pop    %rbx
    3b41:	41 5c                	pop    %r12
    3b43:	41 5d                	pop    %r13
    3b45:	41 5e                	pop    %r14
    3b47:	41 5f                	pop    %r15
    3b49:	c3                   	ret

0000000000003b4a <pqcrystals_kyber768_ref_polyvec_reduce>:
    3b4a:	41 56                	push   %r14
    3b4c:	53                   	push   %rbx
    3b4d:	50                   	push   %rax
    3b4e:	48 89 fb             	mov    %rdi,%rbx
    3b51:	45 31 f6             	xor    %r14d,%r14d
    3b54:	49 81 fe 00 06 00 00 	cmp    $0x600,%r14
    3b5b:	74 12                	je     3b6f <pqcrystals_kyber768_ref_polyvec_reduce+0x25>
    3b5d:	4a 8d 3c 33          	lea    (%rbx,%r14,1),%rdi
    3b61:	e8 f9 fb ff ff       	call   375f <pqcrystals_kyber768_ref_poly_reduce>
    3b66:	49 81 c6 00 02 00 00 	add    $0x200,%r14
    3b6d:	eb e5                	jmp    3b54 <pqcrystals_kyber768_ref_polyvec_reduce+0xa>
    3b6f:	48 83 c4 08          	add    $0x8,%rsp
    3b73:	5b                   	pop    %rbx
    3b74:	41 5e                	pop    %r14
    3b76:	c3                   	ret

0000000000003b77 <pqcrystals_kyber768_ref_polyvec_add>:
    3b77:	41 57                	push   %r15
    3b79:	41 56                	push   %r14
    3b7b:	41 54                	push   %r12
    3b7d:	53                   	push   %rbx
    3b7e:	50                   	push   %rax
    3b7f:	48 89 d3             	mov    %rdx,%rbx
    3b82:	49 89 f6             	mov    %rsi,%r14
    3b85:	49 89 ff             	mov    %rdi,%r15
    3b88:	45 31 e4             	xor    %r12d,%r12d
    3b8b:	49 81 fc 00 06 00 00 	cmp    $0x600,%r12
    3b92:	74 1a                	je     3bae <pqcrystals_kyber768_ref_polyvec_add+0x37>
    3b94:	4b 8d 3c 27          	lea    (%r15,%r12,1),%rdi
    3b98:	4b 8d 34 26          	lea    (%r14,%r12,1),%rsi
    3b9c:	4a 8d 14 23          	lea    (%rbx,%r12,1),%rdx
    3ba0:	e8 a1 fc ff ff       	call   3846 <pqcrystals_kyber768_ref_poly_add>
    3ba5:	49 81 c4 00 02 00 00 	add    $0x200,%r12
    3bac:	eb dd                	jmp    3b8b <pqcrystals_kyber768_ref_polyvec_add+0x14>
    3bae:	48 83 c4 08          	add    $0x8,%rsp
    3bb2:	5b                   	pop    %rbx
    3bb3:	41 5c                	pop    %r12
    3bb5:	41 5e                	pop    %r14
    3bb7:	41 5f                	pop    %r15
    3bb9:	c3                   	ret
    3bba:	66 90                	xchg   %ax,%ax

0000000000003bbc <pqcrystals_kyber768_ref_ntt>:
    3bbc:	55                   	push   %rbp
    3bbd:	41 57                	push   %r15
    3bbf:	41 56                	push   %r14
    3bc1:	41 55                	push   %r13
    3bc3:	41 54                	push   %r12
    3bc5:	53                   	push   %rbx
    3bc6:	50                   	push   %rax
    3bc7:	48 89 fb             	mov    %rdi,%rbx
    3bca:	b9 80 00 00 00       	mov    $0x80,%ecx
    3bcf:	6a 01                	push   $0x1
    3bd1:	58                   	pop    %rax
    3bd2:	83 f9 02             	cmp    $0x2,%ecx
    3bd5:	72 6d                	jb     3c44 <pqcrystals_kyber768_ref_ntt+0x88>
    3bd7:	41 89 cd             	mov    %ecx,%r13d
    3bda:	45 31 f6             	xor    %r14d,%r14d
    3bdd:	89 0c 24             	mov    %ecx,(%rsp)
    3be0:	41 81 fe ff 00 00 00 	cmp    $0xff,%r14d
    3be7:	77 57                	ja     3c40 <pqcrystals_kyber768_ref_ntt+0x84>
    3be9:	89 44 24 04          	mov    %eax,0x4(%rsp)
    3bed:	89 c0                	mov    %eax,%eax
    3bef:	45 89 f4             	mov    %r14d,%r12d
    3bf2:	41 01 ce             	add    %ecx,%r14d
    3bf5:	48 8d 0d 94 8c 00 00 	lea    0x8c94(%rip),%rcx        # c890 <pqcrystals_kyber768_ref_zetas>
    3bfc:	0f bf 2c 41          	movswl (%rcx,%rax,2),%ebp
    3c00:	4d 39 f4             	cmp    %r14,%r12
    3c03:	73 2a                	jae    3c2f <pqcrystals_kyber768_ref_ntt+0x73>
    3c05:	47 8d 3c 2c          	lea    (%r12,%r13,1),%r15d
    3c09:	42 0f bf 34 7b       	movswl (%rbx,%r15,2),%esi
    3c0e:	89 ef                	mov    %ebp,%edi
    3c10:	e8 3e 00 00 00       	call   3c53 <fqmul>
    3c15:	42 0f b7 0c 63       	movzwl (%rbx,%r12,2),%ecx
    3c1a:	89 ca                	mov    %ecx,%edx
    3c1c:	29 c2                	sub    %eax,%edx
    3c1e:	66 42 89 14 7b       	mov    %dx,(%rbx,%r15,2)
    3c23:	01 c1                	add    %eax,%ecx
    3c25:	66 42 89 0c 63       	mov    %cx,(%rbx,%r12,2)
    3c2a:	49 ff c4             	inc    %r12
    3c2d:	eb d1                	jmp    3c00 <pqcrystals_kyber768_ref_ntt+0x44>
    3c2f:	8b 44 24 04          	mov    0x4(%rsp),%eax
    3c33:	ff c0                	inc    %eax
    3c35:	45 01 ec             	add    %r13d,%r12d
    3c38:	45 89 e6             	mov    %r12d,%r14d
    3c3b:	8b 0c 24             	mov    (%rsp),%ecx
    3c3e:	eb a0                	jmp    3be0 <pqcrystals_kyber768_ref_ntt+0x24>
    3c40:	d1 e9                	shr    $1,%ecx
    3c42:	eb 8e                	jmp    3bd2 <pqcrystals_kyber768_ref_ntt+0x16>
    3c44:	48 83 c4 08          	add    $0x8,%rsp
    3c48:	5b                   	pop    %rbx
    3c49:	41 5c                	pop    %r12
    3c4b:	41 5d                	pop    %r13
    3c4d:	41 5e                	pop    %r14
    3c4f:	41 5f                	pop    %r15
    3c51:	5d                   	pop    %rbp
    3c52:	c3                   	ret

0000000000003c53 <fqmul>:
    3c53:	0f af fe             	imul   %esi,%edi
    3c56:	e9 b9 01 00 00       	jmp    3e14 <pqcrystals_kyber768_ref_montgomery_reduce>

0000000000003c5b <pqcrystals_kyber768_ref_invntt>:
    3c5b:	55                   	push   %rbp
    3c5c:	41 57                	push   %r15
    3c5e:	41 56                	push   %r14
    3c60:	41 55                	push   %r13
    3c62:	41 54                	push   %r12
    3c64:	53                   	push   %rbx
    3c65:	48 83 ec 18          	sub    $0x18,%rsp
    3c69:	48 89 fb             	mov    %rdi,%rbx
    3c6c:	6a 02                	push   $0x2
    3c6e:	59                   	pop    %rcx
    3c6f:	6a 7f                	push   $0x7f
    3c71:	58                   	pop    %rax
    3c72:	81 f9 81 00 00 00    	cmp    $0x81,%ecx
    3c78:	0f 83 8e 00 00 00    	jae    3d0c <pqcrystals_kyber768_ref_invntt+0xb1>
    3c7e:	89 ca                	mov    %ecx,%edx
    3c80:	48 89 54 24 10       	mov    %rdx,0x10(%rsp)
    3c85:	4c 8d 24 53          	lea    (%rbx,%rdx,2),%r12
    3c89:	45 31 ed             	xor    %r13d,%r13d
    3c8c:	89 4c 24 08          	mov    %ecx,0x8(%rsp)
    3c90:	41 81 fd ff 00 00 00 	cmp    $0xff,%r13d
    3c97:	77 6c                	ja     3d05 <pqcrystals_kyber768_ref_invntt+0xaa>
    3c99:	89 44 24 0c          	mov    %eax,0xc(%rsp)
    3c9d:	89 c0                	mov    %eax,%eax
    3c9f:	45 89 ee             	mov    %r13d,%r14d
    3ca2:	41 01 cd             	add    %ecx,%r13d
    3ca5:	48 8d 0d e4 8b 00 00 	lea    0x8be4(%rip),%rcx        # c890 <pqcrystals_kyber768_ref_zetas>
    3cac:	0f bf 2c 41          	movswl (%rcx,%rax,2),%ebp
    3cb0:	4d 39 ee             	cmp    %r13,%r14
    3cb3:	73 3c                	jae    3cf1 <pqcrystals_kyber768_ref_invntt+0x96>
    3cb5:	46 0f b7 3c 73       	movzwl (%rbx,%r14,2),%r15d
    3cba:	43 0f b7 04 74       	movzwl (%r12,%r14,2),%eax
    3cbf:	66 44 01 f8          	add    %r15w,%ax
    3cc3:	0f bf f8             	movswl %ax,%edi
    3cc6:	e8 5e 01 00 00       	call   3e29 <pqcrystals_kyber768_ref_barrett_reduce>
    3ccb:	66 42 89 04 73       	mov    %ax,(%rbx,%r14,2)
    3cd0:	43 0f b7 04 74       	movzwl (%r12,%r14,2),%eax
    3cd5:	44 29 f8             	sub    %r15d,%eax
    3cd8:	66 43 89 04 74       	mov    %ax,(%r12,%r14,2)
    3cdd:	0f bf f0             	movswl %ax,%esi
    3ce0:	89 ef                	mov    %ebp,%edi
    3ce2:	e8 6c ff ff ff       	call   3c53 <fqmul>
    3ce7:	66 43 89 04 74       	mov    %ax,(%r12,%r14,2)
    3cec:	49 ff c6             	inc    %r14
    3cef:	eb bf                	jmp    3cb0 <pqcrystals_kyber768_ref_invntt+0x55>
    3cf1:	8b 44 24 0c          	mov    0xc(%rsp),%eax
    3cf5:	ff c8                	dec    %eax
    3cf7:	44 03 74 24 10       	add    0x10(%rsp),%r14d
    3cfc:	45 89 f5             	mov    %r14d,%r13d
    3cff:	8b 4c 24 08          	mov    0x8(%rsp),%ecx
    3d03:	eb 8b                	jmp    3c90 <pqcrystals_kyber768_ref_invntt+0x35>
    3d05:	01 c9                	add    %ecx,%ecx
    3d07:	e9 66 ff ff ff       	jmp    3c72 <pqcrystals_kyber768_ref_invntt+0x17>
    3d0c:	45 31 f6             	xor    %r14d,%r14d
    3d0f:	49 81 fe 00 01 00 00 	cmp    $0x100,%r14
    3d16:	74 19                	je     3d31 <pqcrystals_kyber768_ref_invntt+0xd6>
    3d18:	42 0f bf 3c 73       	movswl (%rbx,%r14,2),%edi
    3d1d:	be a1 05 00 00       	mov    $0x5a1,%esi
    3d22:	e8 2c ff ff ff       	call   3c53 <fqmul>
    3d27:	66 42 89 04 73       	mov    %ax,(%rbx,%r14,2)
    3d2c:	49 ff c6             	inc    %r14
    3d2f:	eb de                	jmp    3d0f <pqcrystals_kyber768_ref_invntt+0xb4>
    3d31:	48 83 c4 18          	add    $0x18,%rsp
    3d35:	5b                   	pop    %rbx
    3d36:	41 5c                	pop    %r12
    3d38:	41 5d                	pop    %r13
    3d3a:	41 5e                	pop    %r14
    3d3c:	41 5f                	pop    %r15
    3d3e:	5d                   	pop    %rbp
    3d3f:	c3                   	ret

0000000000003d40 <pqcrystals_kyber768_ref_basemul>:
    3d40:	55                   	push   %rbp
    3d41:	41 57                	push   %r15
    3d43:	41 56                	push   %r14
    3d45:	53                   	push   %rbx
    3d46:	50                   	push   %rax
    3d47:	89 cd                	mov    %ecx,%ebp
    3d49:	49 89 d6             	mov    %rdx,%r14
    3d4c:	49 89 f7             	mov    %rsi,%r15
    3d4f:	48 89 fb             	mov    %rdi,%rbx
    3d52:	0f bf 7e 02          	movswl 0x2(%rsi),%edi
    3d56:	0f bf 72 02          	movswl 0x2(%rdx),%esi
    3d5a:	e8 f4 fe ff ff       	call   3c53 <fqmul>
    3d5f:	66 89 03             	mov    %ax,(%rbx)
    3d62:	0f bf f8             	movswl %ax,%edi
    3d65:	89 ee                	mov    %ebp,%esi
    3d67:	e8 e7 fe ff ff       	call   3c53 <fqmul>
    3d6c:	66 89 03             	mov    %ax,(%rbx)
    3d6f:	41 0f bf 3f          	movswl (%r15),%edi
    3d73:	41 0f bf 36          	movswl (%r14),%esi
    3d77:	e8 d7 fe ff ff       	call   3c53 <fqmul>
    3d7c:	66 01 03             	add    %ax,(%rbx)
    3d7f:	41 0f bf 3f          	movswl (%r15),%edi
    3d83:	41 0f bf 76 02       	movswl 0x2(%r14),%esi
    3d88:	e8 c6 fe ff ff       	call   3c53 <fqmul>
    3d8d:	66 89 43 02          	mov    %ax,0x2(%rbx)
    3d91:	41 0f bf 7f 02       	movswl 0x2(%r15),%edi
    3d96:	41 0f bf 36          	movswl (%r14),%esi
    3d9a:	e8 b4 fe ff ff       	call   3c53 <fqmul>
    3d9f:	66 01 43 02          	add    %ax,0x2(%rbx)
    3da3:	48 83 c4 08          	add    $0x8,%rsp
    3da7:	5b                   	pop    %rbx
    3da8:	41 5e                	pop    %r14
    3daa:	41 5f                	pop    %r15
    3dac:	5d                   	pop    %rbp
    3dad:	c3                   	ret
    3dae:	66 90                	xchg   %ax,%ax

0000000000003db0 <pqcrystals_kyber768_ref_poly_cbd_eta1>:
    3db0:	eb 00                	jmp    3db2 <cbd2>

0000000000003db2 <cbd2>:
    3db2:	53                   	push   %rbx
    3db3:	31 d2                	xor    %edx,%edx
    3db5:	41 b8 55 55 55 55    	mov    $0x55555555,%r8d
    3dbb:	48 83 fa 20          	cmp    $0x20,%rdx
    3dbf:	74 4f                	je     3e10 <cbd2+0x5e>
    3dc1:	44 8b 0c 96          	mov    (%rsi,%rdx,4),%r9d
    3dc5:	44 89 c8             	mov    %r9d,%eax
    3dc8:	44 21 c0             	and    %r8d,%eax
    3dcb:	41 d1 e9             	shr    $1,%r9d
    3dce:	45 21 c1             	and    %r8d,%r9d
    3dd1:	41 01 c1             	add    %eax,%r9d
    3dd4:	49 89 fa             	mov    %rdi,%r10
    3dd7:	31 c0                	xor    %eax,%eax
    3dd9:	48 83 f8 20          	cmp    $0x20,%rax
    3ddd:	74 28                	je     3e07 <cbd2+0x55>
    3ddf:	45 89 cb             	mov    %r9d,%r11d
    3de2:	89 c1                	mov    %eax,%ecx
    3de4:	41 d3 eb             	shr    %cl,%r11d
    3de7:	41 83 e3 03          	and    $0x3,%r11d
    3deb:	8d 48 02             	lea    0x2(%rax),%ecx
    3dee:	44 89 cb             	mov    %r9d,%ebx
    3df1:	d3 eb                	shr    %cl,%ebx
    3df3:	83 e3 03             	and    $0x3,%ebx
    3df6:	41 29 db             	sub    %ebx,%r11d
    3df9:	66 45 89 1a          	mov    %r11w,(%r10)
    3dfd:	48 83 c0 04          	add    $0x4,%rax
    3e01:	49 83 c2 02          	add    $0x2,%r10
    3e05:	eb d2                	jmp    3dd9 <cbd2+0x27>
    3e07:	48 ff c2             	inc    %rdx
    3e0a:	48 83 c7 10          	add    $0x10,%rdi
    3e0e:	eb ab                	jmp    3dbb <cbd2+0x9>
    3e10:	5b                   	pop    %rbx
    3e11:	c3                   	ret

0000000000003e12 <pqcrystals_kyber768_ref_poly_cbd_eta2>:
    3e12:	eb 9e                	jmp    3db2 <cbd2>

0000000000003e14 <pqcrystals_kyber768_ref_montgomery_reduce>:
    3e14:	69 c7 00 00 01 f3    	imul   $0xf3010000,%edi,%eax
    3e1a:	c1 f8 10             	sar    $0x10,%eax
    3e1d:	69 c0 ff f2 ff ff    	imul   $0xfffff2ff,%eax,%eax
    3e23:	01 f8                	add    %edi,%eax
    3e25:	c1 e8 10             	shr    $0x10,%eax
    3e28:	c3                   	ret

0000000000003e29 <pqcrystals_kyber768_ref_barrett_reduce>:
    3e29:	89 f8                	mov    %edi,%eax
    3e2b:	69 cf bf 4e 00 00    	imul   $0x4ebf,%edi,%ecx
    3e31:	81 c1 00 00 00 02    	add    $0x2000000,%ecx
    3e37:	c1 f9 1a             	sar    $0x1a,%ecx
    3e3a:	69 c9 00 00 01 0d    	imul   $0xd010000,%ecx,%ecx
    3e40:	c1 e9 10             	shr    $0x10,%ecx
    3e43:	29 c8                	sub    %ecx,%eax
    3e45:	c3                   	ret
    3e46:	66 90                	xchg   %ax,%ax

0000000000003e48 <pqcrystals_kyber768_ref_verify>:
    3e48:	31 c0                	xor    %eax,%eax
    3e4a:	31 c9                	xor    %ecx,%ecx
    3e4c:	48 39 c2             	cmp    %rax,%rdx
    3e4f:	74 10                	je     3e61 <pqcrystals_kyber768_ref_verify+0x19>
    3e51:	44 8a 04 06          	mov    (%rsi,%rax,1),%r8b
    3e55:	44 32 04 07          	xor    (%rdi,%rax,1),%r8b
    3e59:	44 08 c1             	or     %r8b,%cl
    3e5c:	48 ff c0             	inc    %rax
    3e5f:	eb eb                	jmp    3e4c <pqcrystals_kyber768_ref_verify+0x4>
    3e61:	31 c0                	xor    %eax,%eax
    3e63:	84 c9                	test   %cl,%cl
    3e65:	0f 95 c0             	setne  %al
    3e68:	c3                   	ret

0000000000003e69 <pqcrystals_kyber768_ref_cmov>:
    3e69:	f6 d9                	neg    %cl
    3e6b:	31 c0                	xor    %eax,%eax
    3e6d:	48 39 c2             	cmp    %rax,%rdx
    3e70:	74 1a                	je     3e8c <pqcrystals_kyber768_ref_cmov+0x23>
    3e72:	44 8a 04 07          	mov    (%rdi,%rax,1),%r8b
    3e76:	44 8a 0c 06          	mov    (%rsi,%rax,1),%r9b
    3e7a:	45 30 c1             	xor    %r8b,%r9b
    3e7d:	41 20 c9             	and    %cl,%r9b
    3e80:	45 30 c1             	xor    %r8b,%r9b
    3e83:	44 88 0c 07          	mov    %r9b,(%rdi,%rax,1)
    3e87:	48 ff c0             	inc    %rax
    3e8a:	eb e1                	jmp    3e6d <pqcrystals_kyber768_ref_cmov+0x4>
    3e8c:	c3                   	ret
    3e8d:	0f 1f 00             	nopl   (%rax)

0000000000003e90 <pqcrystals_kyber_fips202_ref_shake128_init>:
    3e90:	53                   	push   %rbx
    3e91:	48 89 fb             	mov    %rdi,%rbx
    3e94:	e8 09 00 00 00       	call   3ea2 <keccak_init>
    3e99:	83 a3 c8 00 00 00 00 	andl   $0x0,0xc8(%rbx)
    3ea0:	5b                   	pop    %rbx
    3ea1:	c3                   	ret

0000000000003ea2 <keccak_init>:
    3ea2:	31 c0                	xor    %eax,%eax
    3ea4:	48 83 f8 19          	cmp    $0x19,%rax
    3ea8:	74 0a                	je     3eb4 <keccak_init+0x12>
    3eaa:	48 83 24 c7 00       	andq   $0x0,(%rdi,%rax,8)
    3eaf:	48 ff c0             	inc    %rax
    3eb2:	eb f0                	jmp    3ea4 <keccak_init+0x2>
    3eb4:	c3                   	ret

0000000000003eb5 <pqcrystals_kyber_fips202_ref_shake128_absorb>:
    3eb5:	53                   	push   %rbx
    3eb6:	49 89 d0             	mov    %rdx,%r8
    3eb9:	48 89 f1             	mov    %rsi,%rcx
    3ebc:	48 89 fb             	mov    %rdi,%rbx
    3ebf:	8b b7 c8 00 00 00    	mov    0xc8(%rdi),%esi
    3ec5:	ba a8 00 00 00       	mov    $0xa8,%edx
    3eca:	e8 08 00 00 00       	call   3ed7 <keccak_absorb>
    3ecf:	89 83 c8 00 00 00    	mov    %eax,0xc8(%rbx)
    3ed5:	5b                   	pop    %rbx
    3ed6:	c3                   	ret

0000000000003ed7 <keccak_absorb>:
    3ed7:	55                   	push   %rbp
    3ed8:	41 57                	push   %r15
    3eda:	41 56                	push   %r14
    3edc:	41 54                	push   %r12
    3ede:	53                   	push   %rbx
    3edf:	4d 89 c7             	mov    %r8,%r15
    3ee2:	48 89 cb             	mov    %rcx,%rbx
    3ee5:	89 d5                	mov    %edx,%ebp
    3ee7:	89 f0                	mov    %esi,%eax
    3ee9:	49 89 fe             	mov    %rdi,%r14
    3eec:	41 89 d4             	mov    %edx,%r12d
    3eef:	89 c2                	mov    %eax,%edx
    3ef1:	4c 01 fa             	add    %r15,%rdx
    3ef4:	4c 39 e2             	cmp    %r12,%rdx
    3ef7:	72 3e                	jb     3f37 <keccak_absorb+0x60>
    3ef9:	8d 14 c5 00 00 00 00 	lea    0x0(,%rax,8),%edx
    3f00:	89 c6                	mov    %eax,%esi
    3f02:	39 ee                	cmp    %ebp,%esi
    3f04:	73 1e                	jae    3f24 <keccak_absorb+0x4d>
    3f06:	0f b6 3b             	movzbl (%rbx),%edi
    3f09:	89 d1                	mov    %edx,%ecx
    3f0b:	80 e1 38             	and    $0x38,%cl
    3f0e:	48 d3 e7             	shl    %cl,%rdi
    3f11:	89 f1                	mov    %esi,%ecx
    3f13:	83 e1 f8             	and    $0xfffffff8,%ecx
    3f16:	49 31 3c 0e          	xor    %rdi,(%r14,%rcx,1)
    3f1a:	48 ff c3             	inc    %rbx
    3f1d:	ff c6                	inc    %esi
    3f1f:	83 c2 08             	add    $0x8,%edx
    3f22:	eb de                	jmp    3f02 <keccak_absorb+0x2b>
    3f24:	89 e9                	mov    %ebp,%ecx
    3f26:	29 c1                	sub    %eax,%ecx
    3f28:	49 29 cf             	sub    %rcx,%r15
    3f2b:	4c 89 f7             	mov    %r14,%rdi
    3f2e:	e8 39 04 00 00       	call   436c <KeccakF1600_StatePermute>
    3f33:	31 c0                	xor    %eax,%eax
    3f35:	eb b8                	jmp    3eef <keccak_absorb+0x18>
    3f37:	8d 34 c5 00 00 00 00 	lea    0x0(,%rax,8),%esi
    3f3e:	89 c1                	mov    %eax,%ecx
    3f40:	48 39 ca             	cmp    %rcx,%rdx
    3f43:	76 1e                	jbe    3f63 <keccak_absorb+0x8c>
    3f45:	0f b6 3b             	movzbl (%rbx),%edi
    3f48:	89 f1                	mov    %esi,%ecx
    3f4a:	80 e1 38             	and    $0x38,%cl
    3f4d:	48 d3 e7             	shl    %cl,%rdi
    3f50:	89 c1                	mov    %eax,%ecx
    3f52:	83 e1 f8             	and    $0xfffffff8,%ecx
    3f55:	49 31 3c 0e          	xor    %rdi,(%r14,%rcx,1)
    3f59:	48 ff c3             	inc    %rbx
    3f5c:	ff c0                	inc    %eax
    3f5e:	83 c6 08             	add    $0x8,%esi
    3f61:	eb db                	jmp    3f3e <keccak_absorb+0x67>
    3f63:	5b                   	pop    %rbx
    3f64:	41 5c                	pop    %r12
    3f66:	41 5e                	pop    %r14
    3f68:	41 5f                	pop    %r15
    3f6a:	5d                   	pop    %rbp
    3f6b:	c3                   	ret

0000000000003f6c <pqcrystals_kyber_fips202_ref_shake128_finalize>:
    3f6c:	8b 87 c8 00 00 00    	mov    0xc8(%rdi),%eax
    3f72:	8d 0c c5 00 00 00 00 	lea    0x0(,%rax,8),%ecx
    3f79:	6a 1f                	push   $0x1f
    3f7b:	5a                   	pop    %rdx
    3f7c:	48 d3 e2             	shl    %cl,%rdx
    3f7f:	83 e0 f8             	and    $0xfffffff8,%eax
    3f82:	48 31 14 07          	xor    %rdx,(%rdi,%rax,1)
    3f86:	80 b7 a7 00 00 00 80 	xorb   $0x80,0xa7(%rdi)
    3f8d:	c7 87 c8 00 00 00 a8 	movl   $0xa8,0xc8(%rdi)
    3f94:	00 00 00 
    3f97:	c3                   	ret

0000000000003f98 <pqcrystals_kyber_fips202_ref_shake128_squeeze>:
    3f98:	53                   	push   %rbx
    3f99:	48 89 d3             	mov    %rdx,%rbx
    3f9c:	8b 8a c8 00 00 00    	mov    0xc8(%rdx),%ecx
    3fa2:	41 b8 a8 00 00 00    	mov    $0xa8,%r8d
    3fa8:	e8 08 00 00 00       	call   3fb5 <keccak_squeeze>
    3fad:	89 83 c8 00 00 00    	mov    %eax,0xc8(%rbx)
    3fb3:	5b                   	pop    %rbx
    3fb4:	c3                   	ret

0000000000003fb5 <keccak_squeeze>:
    3fb5:	41 57                	push   %r15
    3fb7:	41 56                	push   %r14
    3fb9:	41 55                	push   %r13
    3fbb:	41 54                	push   %r12
    3fbd:	53                   	push   %rbx
    3fbe:	44 89 c3             	mov    %r8d,%ebx
    3fc1:	89 c8                	mov    %ecx,%eax
    3fc3:	49 89 d6             	mov    %rdx,%r14
    3fc6:	49 89 f7             	mov    %rsi,%r15
    3fc9:	49 89 fc             	mov    %rdi,%r12
    3fcc:	45 89 c5             	mov    %r8d,%r13d
    3fcf:	4d 85 ff             	test   %r15,%r15
    3fd2:	74 55                	je     4029 <keccak_squeeze+0x74>
    3fd4:	39 d8                	cmp    %ebx,%eax
    3fd6:	75 0a                	jne    3fe2 <keccak_squeeze+0x2d>
    3fd8:	4c 89 f7             	mov    %r14,%rdi
    3fdb:	e8 8c 03 00 00       	call   436c <KeccakF1600_StatePermute>
    3fe0:	31 c0                	xor    %eax,%eax
    3fe2:	89 c0                	mov    %eax,%eax
    3fe4:	49 8d 34 07          	lea    (%r15,%rax,1),%rsi
    3fe8:	49 39 f5             	cmp    %rsi,%r13
    3feb:	49 0f 42 f5          	cmovb  %r13,%rsi
    3fef:	48 8d 3c c5 00 00 00 	lea    0x0(,%rax,8),%rdi
    3ff6:	00 
    3ff7:	31 d2                	xor    %edx,%edx
    3ff9:	48 39 f0             	cmp    %rsi,%rax
    3ffc:	73 21                	jae    401f <keccak_squeeze+0x6a>
    3ffe:	89 c1                	mov    %eax,%ecx
    4000:	83 e1 f8             	and    $0xfffffff8,%ecx
    4003:	4d 8b 04 0e          	mov    (%r14,%rcx,1),%r8
    4007:	89 f9                	mov    %edi,%ecx
    4009:	80 e1 38             	and    $0x38,%cl
    400c:	49 d3 e8             	shr    %cl,%r8
    400f:	45 88 04 14          	mov    %r8b,(%r12,%rdx,1)
    4013:	48 ff c0             	inc    %rax
    4016:	48 ff c2             	inc    %rdx
    4019:	48 83 c7 08          	add    $0x8,%rdi
    401d:	eb da                	jmp    3ff9 <keccak_squeeze+0x44>
    401f:	89 d1                	mov    %edx,%ecx
    4021:	49 29 cf             	sub    %rcx,%r15
    4024:	49 01 d4             	add    %rdx,%r12
    4027:	eb a6                	jmp    3fcf <keccak_squeeze+0x1a>
    4029:	5b                   	pop    %rbx
    402a:	41 5c                	pop    %r12
    402c:	41 5d                	pop    %r13
    402e:	41 5e                	pop    %r14
    4030:	41 5f                	pop    %r15
    4032:	c3                   	ret

0000000000004033 <pqcrystals_kyber_fips202_ref_shake128_absorb_once>:
    4033:	53                   	push   %rbx
    4034:	48 89 d1             	mov    %rdx,%rcx
    4037:	48 89 f2             	mov    %rsi,%rdx
    403a:	48 89 fb             	mov    %rdi,%rbx
    403d:	6a 1f                	push   $0x1f
    403f:	41 58                	pop    %r8
    4041:	be a8 00 00 00       	mov    $0xa8,%esi
    4046:	e8 0c 00 00 00       	call   4057 <keccak_absorb_once>
    404b:	c7 83 c8 00 00 00 a8 	movl   $0xa8,0xc8(%rbx)
    4052:	00 00 00 
    4055:	5b                   	pop    %rbx
    4056:	c3                   	ret

0000000000004057 <keccak_absorb_once>:
    4057:	55                   	push   %rbp
    4058:	41 57                	push   %r15
    405a:	41 56                	push   %r14
    405c:	41 55                	push   %r13
    405e:	41 54                	push   %r12
    4060:	53                   	push   %rbx
    4061:	50                   	push   %rax
    4062:	44 89 44 24 04       	mov    %r8d,0x4(%rsp)
    4067:	48 89 c8             	mov    %rcx,%rax
    406a:	49 89 d7             	mov    %rdx,%r15
    406d:	89 f3                	mov    %esi,%ebx
    406f:	49 89 fe             	mov    %rdi,%r14
    4072:	31 c9                	xor    %ecx,%ecx
    4074:	48 83 f9 19          	cmp    $0x19,%rcx
    4078:	74 0a                	je     4084 <keccak_absorb_once+0x2d>
    407a:	49 83 24 ce 00       	andq   $0x0,(%r14,%rcx,8)
    407f:	48 ff c1             	inc    %rcx
    4082:	eb f0                	jmp    4074 <keccak_absorb_once+0x1d>
    4084:	41 89 dc             	mov    %ebx,%r12d
    4087:	41 89 dd             	mov    %ebx,%r13d
    408a:	41 c1 ed 03          	shr    $0x3,%r13d
    408e:	48 89 c5             	mov    %rax,%rbp
    4091:	4c 29 e5             	sub    %r12,%rbp
    4094:	72 47                	jb     40dd <keccak_absorb_once+0x86>
    4096:	4c 89 f8             	mov    %r15,%rax
    4099:	31 d2                	xor    %edx,%edx
    409b:	4c 39 ea             	cmp    %r13,%rdx
    409e:	74 2d                	je     40cd <keccak_absorb_once+0x76>
    40a0:	48 89 c6             	mov    %rax,%rsi
    40a3:	31 c9                	xor    %ecx,%ecx
    40a5:	31 ff                	xor    %edi,%edi
    40a7:	48 83 f9 40          	cmp    $0x40,%rcx
    40ab:	74 13                	je     40c0 <keccak_absorb_once+0x69>
    40ad:	44 0f b6 06          	movzbl (%rsi),%r8d
    40b1:	49 d3 e0             	shl    %cl,%r8
    40b4:	4c 09 c7             	or     %r8,%rdi
    40b7:	48 83 c1 08          	add    $0x8,%rcx
    40bb:	48 ff c6             	inc    %rsi
    40be:	eb e7                	jmp    40a7 <keccak_absorb_once+0x50>
    40c0:	49 31 3c d6          	xor    %rdi,(%r14,%rdx,8)
    40c4:	48 ff c2             	inc    %rdx
    40c7:	48 83 c0 08          	add    $0x8,%rax
    40cb:	eb ce                	jmp    409b <keccak_absorb_once+0x44>
    40cd:	4d 01 e7             	add    %r12,%r15
    40d0:	4c 89 f7             	mov    %r14,%rdi
    40d3:	e8 94 02 00 00       	call   436c <KeccakF1600_StatePermute>
    40d8:	48 89 e8             	mov    %rbp,%rax
    40db:	eb b4                	jmp    4091 <keccak_absorb_once+0x3a>
    40dd:	31 d2                	xor    %edx,%edx
    40df:	31 c9                	xor    %ecx,%ecx
    40e1:	89 ce                	mov    %ecx,%esi
    40e3:	48 39 f0             	cmp    %rsi,%rax
    40e6:	76 1e                	jbe    4106 <keccak_absorb_once+0xaf>
    40e8:	41 0f b6 3c 37       	movzbl (%r15,%rsi,1),%edi
    40ed:	89 d1                	mov    %edx,%ecx
    40ef:	80 e1 38             	and    $0x38,%cl
    40f2:	48 d3 e7             	shl    %cl,%rdi
    40f5:	89 f1                	mov    %esi,%ecx
    40f7:	83 e1 f8             	and    $0xfffffff8,%ecx
    40fa:	49 31 3c 0e          	xor    %rdi,(%r14,%rcx,1)
    40fe:	8d 4e 01             	lea    0x1(%rsi),%ecx
    4101:	83 c2 08             	add    $0x8,%edx
    4104:	eb db                	jmp    40e1 <keccak_absorb_once+0x8a>
    4106:	0f b6 44 24 04       	movzbl 0x4(%rsp),%eax
    410b:	80 e2 38             	and    $0x38,%dl
    410e:	89 d1                	mov    %edx,%ecx
    4110:	48 d3 e0             	shl    %cl,%rax
    4113:	83 e6 f8             	and    $0xfffffff8,%esi
    4116:	49 31 04 36          	xor    %rax,(%r14,%rsi,1)
    411a:	ff cb                	dec    %ebx
    411c:	83 e3 f8             	and    $0xfffffff8,%ebx
    411f:	41 80 74 1e 07 80    	xorb   $0x80,0x7(%r14,%rbx,1)
    4125:	48 83 c4 08          	add    $0x8,%rsp
    4129:	5b                   	pop    %rbx
    412a:	41 5c                	pop    %r12
    412c:	41 5d                	pop    %r13
    412e:	41 5e                	pop    %r14
    4130:	41 5f                	pop    %r15
    4132:	5d                   	pop    %rbp
    4133:	c3                   	ret

0000000000004134 <pqcrystals_kyber_fips202_ref_shake128_squeezeblocks>:
    4134:	b9 a8 00 00 00       	mov    $0xa8,%ecx
    4139:	eb 00                	jmp    413b <keccak_squeezeblocks>

000000000000413b <keccak_squeezeblocks>:
    413b:	55                   	push   %rbp
    413c:	41 57                	push   %r15
    413e:	41 56                	push   %r14
    4140:	41 55                	push   %r13
    4142:	41 54                	push   %r12
    4144:	53                   	push   %rbx
    4145:	50                   	push   %rax
    4146:	89 cb                	mov    %ecx,%ebx
    4148:	49 89 d6             	mov    %rdx,%r14
    414b:	49 89 f7             	mov    %rsi,%r15
    414e:	49 89 fc             	mov    %rdi,%r12
    4151:	41 89 cd             	mov    %ecx,%r13d
    4154:	83 e3 f8             	and    $0xfffffff8,%ebx
    4157:	49 83 ef 01          	sub    $0x1,%r15
    415b:	72 27                	jb     4184 <keccak_squeezeblocks+0x49>
    415d:	4c 89 f7             	mov    %r14,%rdi
    4160:	e8 07 02 00 00       	call   436c <KeccakF1600_StatePermute>
    4165:	31 ed                	xor    %ebp,%ebp
    4167:	48 39 eb             	cmp    %rbp,%rbx
    416a:	74 13                	je     417f <keccak_squeezeblocks+0x44>
    416c:	49 8d 3c 2c          	lea    (%r12,%rbp,1),%rdi
    4170:	49 8b 34 2e          	mov    (%r14,%rbp,1),%rsi
    4174:	e8 ac 0a 00 00       	call   4c25 <store64>
    4179:	48 83 c5 08          	add    $0x8,%rbp
    417d:	eb e8                	jmp    4167 <keccak_squeezeblocks+0x2c>
    417f:	4d 01 ec             	add    %r13,%r12
    4182:	eb d3                	jmp    4157 <keccak_squeezeblocks+0x1c>
    4184:	48 83 c4 08          	add    $0x8,%rsp
    4188:	5b                   	pop    %rbx
    4189:	41 5c                	pop    %r12
    418b:	41 5d                	pop    %r13
    418d:	41 5e                	pop    %r14
    418f:	41 5f                	pop    %r15
    4191:	5d                   	pop    %rbp
    4192:	c3                   	ret

0000000000004193 <pqcrystals_kyber_fips202_ref_shake256_init>:
    4193:	53                   	push   %rbx
    4194:	48 89 fb             	mov    %rdi,%rbx
    4197:	e8 06 fd ff ff       	call   3ea2 <keccak_init>
    419c:	83 a3 c8 00 00 00 00 	andl   $0x0,0xc8(%rbx)
    41a3:	5b                   	pop    %rbx
    41a4:	c3                   	ret

00000000000041a5 <pqcrystals_kyber_fips202_ref_shake256_absorb>:
    41a5:	53                   	push   %rbx
    41a6:	49 89 d0             	mov    %rdx,%r8
    41a9:	48 89 f1             	mov    %rsi,%rcx
    41ac:	48 89 fb             	mov    %rdi,%rbx
    41af:	8b b7 c8 00 00 00    	mov    0xc8(%rdi),%esi
    41b5:	ba 88 00 00 00       	mov    $0x88,%edx
    41ba:	e8 18 fd ff ff       	call   3ed7 <keccak_absorb>
    41bf:	89 83 c8 00 00 00    	mov    %eax,0xc8(%rbx)
    41c5:	5b                   	pop    %rbx
    41c6:	c3                   	ret

00000000000041c7 <pqcrystals_kyber_fips202_ref_shake256_finalize>:
    41c7:	8b 87 c8 00 00 00    	mov    0xc8(%rdi),%eax
    41cd:	8d 0c c5 00 00 00 00 	lea    0x0(,%rax,8),%ecx
    41d4:	6a 1f                	push   $0x1f
    41d6:	5a                   	pop    %rdx
    41d7:	48 d3 e2             	shl    %cl,%rdx
    41da:	83 e0 f8             	and    $0xfffffff8,%eax
    41dd:	48 31 14 07          	xor    %rdx,(%rdi,%rax,1)
    41e1:	80 b7 87 00 00 00 80 	xorb   $0x80,0x87(%rdi)
    41e8:	c7 87 c8 00 00 00 88 	movl   $0x88,0xc8(%rdi)
    41ef:	00 00 00 
    41f2:	c3                   	ret

00000000000041f3 <pqcrystals_kyber_fips202_ref_shake256_squeeze>:
    41f3:	53                   	push   %rbx
    41f4:	48 89 d3             	mov    %rdx,%rbx
    41f7:	8b 8a c8 00 00 00    	mov    0xc8(%rdx),%ecx
    41fd:	41 b8 88 00 00 00    	mov    $0x88,%r8d
    4203:	e8 ad fd ff ff       	call   3fb5 <keccak_squeeze>
    4208:	89 83 c8 00 00 00    	mov    %eax,0xc8(%rbx)
    420e:	5b                   	pop    %rbx
    420f:	c3                   	ret

0000000000004210 <pqcrystals_kyber_fips202_ref_shake256_absorb_once>:
    4210:	53                   	push   %rbx
    4211:	48 89 d1             	mov    %rdx,%rcx
    4214:	48 89 f2             	mov    %rsi,%rdx
    4217:	48 89 fb             	mov    %rdi,%rbx
    421a:	6a 1f                	push   $0x1f
    421c:	41 58                	pop    %r8
    421e:	be 88 00 00 00       	mov    $0x88,%esi
    4223:	e8 2f fe ff ff       	call   4057 <keccak_absorb_once>
    4228:	c7 83 c8 00 00 00 88 	movl   $0x88,0xc8(%rbx)
    422f:	00 00 00 
    4232:	5b                   	pop    %rbx
    4233:	c3                   	ret

0000000000004234 <pqcrystals_kyber_fips202_ref_shake256_squeezeblocks>:
    4234:	b9 88 00 00 00       	mov    $0x88,%ecx
    4239:	e9 fd fe ff ff       	jmp    413b <keccak_squeezeblocks>

000000000000423e <pqcrystals_kyber_fips202_ref_shake128>:
    423e:	41 57                	push   %r15
    4240:	41 56                	push   %r14
    4242:	41 54                	push   %r12
    4244:	53                   	push   %rbx
    4245:	48 81 ec d8 00 00 00 	sub    $0xd8,%rsp
    424c:	48 89 f3             	mov    %rsi,%rbx
    424f:	49 89 fe             	mov    %rdi,%r14
    4252:	4c 8d 7c 24 08       	lea    0x8(%rsp),%r15
    4257:	4c 89 ff             	mov    %r15,%rdi
    425a:	48 89 d6             	mov    %rdx,%rsi
    425d:	48 89 ca             	mov    %rcx,%rdx
    4260:	e8 ce fd ff ff       	call   4033 <pqcrystals_kyber_fips202_ref_shake128_absorb_once>
    4265:	b9 a8 00 00 00       	mov    $0xa8,%ecx
    426a:	48 89 d8             	mov    %rbx,%rax
    426d:	31 d2                	xor    %edx,%edx
    426f:	48 f7 f1             	div    %rcx
    4272:	48 89 d3             	mov    %rdx,%rbx
    4275:	49 89 c4             	mov    %rax,%r12
    4278:	4c 89 f7             	mov    %r14,%rdi
    427b:	48 89 c6             	mov    %rax,%rsi
    427e:	4c 89 fa             	mov    %r15,%rdx
    4281:	e8 ae fe ff ff       	call   4134 <pqcrystals_kyber_fips202_ref_shake128_squeezeblocks>
    4286:	49 69 fc a8 00 00 00 	imul   $0xa8,%r12,%rdi
    428d:	4c 01 f7             	add    %r14,%rdi
    4290:	48 89 de             	mov    %rbx,%rsi
    4293:	4c 89 fa             	mov    %r15,%rdx
    4296:	e8 fd fc ff ff       	call   3f98 <pqcrystals_kyber_fips202_ref_shake128_squeeze>
    429b:	48 81 c4 d8 00 00 00 	add    $0xd8,%rsp
    42a2:	5b                   	pop    %rbx
    42a3:	41 5c                	pop    %r12
    42a5:	41 5e                	pop    %r14
    42a7:	41 5f                	pop    %r15
    42a9:	c3                   	ret

00000000000042aa <pqcrystals_kyber_fips202_ref_shake256>:
    42aa:	41 57                	push   %r15
    42ac:	41 56                	push   %r14
    42ae:	41 54                	push   %r12
    42b0:	53                   	push   %rbx
    42b1:	48 81 ec d8 00 00 00 	sub    $0xd8,%rsp
    42b8:	48 89 f3             	mov    %rsi,%rbx
    42bb:	49 89 fe             	mov    %rdi,%r14
    42be:	4c 8d 7c 24 08       	lea    0x8(%rsp),%r15
    42c3:	4c 89 ff             	mov    %r15,%rdi
    42c6:	48 89 d6             	mov    %rdx,%rsi
    42c9:	48 89 ca             	mov    %rcx,%rdx
    42cc:	e8 3f ff ff ff       	call   4210 <pqcrystals_kyber_fips202_ref_shake256_absorb_once>
    42d1:	b9 88 00 00 00       	mov    $0x88,%ecx
    42d6:	48 89 d8             	mov    %rbx,%rax
    42d9:	31 d2                	xor    %edx,%edx
    42db:	48 f7 f1             	div    %rcx
    42de:	48 89 d3             	mov    %rdx,%rbx
    42e1:	49 89 c4             	mov    %rax,%r12
    42e4:	4c 89 f7             	mov    %r14,%rdi
    42e7:	48 89 c6             	mov    %rax,%rsi
    42ea:	4c 89 fa             	mov    %r15,%rdx
    42ed:	e8 42 ff ff ff       	call   4234 <pqcrystals_kyber_fips202_ref_shake256_squeezeblocks>
    42f2:	49 69 fc 88 00 00 00 	imul   $0x88,%r12,%rdi
    42f9:	4c 01 f7             	add    %r14,%rdi
    42fc:	48 89 de             	mov    %rbx,%rsi
    42ff:	4c 89 fa             	mov    %r15,%rdx
    4302:	e8 ec fe ff ff       	call   41f3 <pqcrystals_kyber_fips202_ref_shake256_squeeze>
    4307:	48 81 c4 d8 00 00 00 	add    $0xd8,%rsp
    430e:	5b                   	pop    %rbx
    430f:	41 5c                	pop    %r12
    4311:	41 5e                	pop    %r14
    4313:	41 5f                	pop    %r15
    4315:	c3                   	ret

0000000000004316 <pqcrystals_kyber_fips202_ref_sha3_256>:
    4316:	41 56                	push   %r14
    4318:	53                   	push   %rbx
    4319:	48 81 ec c8 00 00 00 	sub    $0xc8,%rsp
    4320:	48 89 d1             	mov    %rdx,%rcx
    4323:	48 89 f2             	mov    %rsi,%rdx
    4326:	48 89 fb             	mov    %rdi,%rbx
    4329:	49 89 e6             	mov    %rsp,%r14
    432c:	6a 06                	push   $0x6
    432e:	41 58                	pop    %r8
    4330:	4c 89 f7             	mov    %r14,%rdi
    4333:	be 88 00 00 00       	mov    $0x88,%esi
    4338:	e8 1a fd ff ff       	call   4057 <keccak_absorb_once>
    433d:	4c 89 f7             	mov    %r14,%rdi
    4340:	e8 27 00 00 00       	call   436c <KeccakF1600_StatePermute>
    4345:	45 31 f6             	xor    %r14d,%r14d
    4348:	49 83 fe 20          	cmp    $0x20,%r14
    434c:	74 13                	je     4361 <pqcrystals_kyber_fips202_ref_sha3_256+0x4b>
    434e:	4a 8d 3c 33          	lea    (%rbx,%r14,1),%rdi
    4352:	4a 8b 34 34          	mov    (%rsp,%r14,1),%rsi
    4356:	e8 ca 08 00 00       	call   4c25 <store64>
    435b:	49 83 c6 08          	add    $0x8,%r14
    435f:	eb e7                	jmp    4348 <pqcrystals_kyber_fips202_ref_sha3_256+0x32>
    4361:	48 81 c4 c8 00 00 00 	add    $0xc8,%rsp
    4368:	5b                   	pop    %rbx
    4369:	41 5e                	pop    %r14
    436b:	c3                   	ret

000000000000436c <KeccakF1600_StatePermute>:
    436c:	55                   	push   %rbp
    436d:	41 57                	push   %r15
    436f:	41 56                	push   %r14
    4371:	41 55                	push   %r13
    4373:	41 54                	push   %r12
    4375:	53                   	push   %rbx
    4376:	48 83 ec 68          	sub    $0x68,%rsp
    437a:	48 8b 07             	mov    (%rdi),%rax
    437d:	48 89 44 24 80       	mov    %rax,-0x80(%rsp)
    4382:	48 8b 6f 08          	mov    0x8(%rdi),%rbp
    4386:	48 8b 47 10          	mov    0x10(%rdi),%rax
    438a:	48 89 44 24 08       	mov    %rax,0x8(%rsp)
    438f:	48 8b 47 18          	mov    0x18(%rdi),%rax
    4393:	48 89 44 24 b8       	mov    %rax,-0x48(%rsp)
    4398:	48 8b 57 20          	mov    0x20(%rdi),%rdx
    439c:	48 8b 47 28          	mov    0x28(%rdi),%rax
    43a0:	48 89 04 24          	mov    %rax,(%rsp)
    43a4:	48 8b 47 30          	mov    0x30(%rdi),%rax
    43a8:	48 89 44 24 98       	mov    %rax,-0x68(%rsp)
    43ad:	48 8b 47 38          	mov    0x38(%rdi),%rax
    43b1:	48 89 44 24 a8       	mov    %rax,-0x58(%rsp)
    43b6:	48 8b 47 40          	mov    0x40(%rdi),%rax
    43ba:	48 89 44 24 f8       	mov    %rax,-0x8(%rsp)
    43bf:	4c 8b 7f 48          	mov    0x48(%rdi),%r15
    43c3:	48 8b 47 50          	mov    0x50(%rdi),%rax
    43c7:	48 89 44 24 90       	mov    %rax,-0x70(%rsp)
    43cc:	48 8b 47 58          	mov    0x58(%rdi),%rax
    43d0:	48 89 44 24 f0       	mov    %rax,-0x10(%rsp)
    43d5:	48 8b 47 60          	mov    0x60(%rdi),%rax
    43d9:	48 89 44 24 40       	mov    %rax,0x40(%rsp)
    43de:	48 8b 47 68          	mov    0x68(%rdi),%rax
    43e2:	48 89 44 24 a0       	mov    %rax,-0x60(%rsp)
    43e7:	4c 8b 77 70          	mov    0x70(%rdi),%r14
    43eb:	48 8b 47 78          	mov    0x78(%rdi),%rax
    43ef:	48 89 44 24 d0       	mov    %rax,-0x30(%rsp)
    43f4:	48 8b 87 80 00 00 00 	mov    0x80(%rdi),%rax
    43fb:	48 89 44 24 88       	mov    %rax,-0x78(%rsp)
    4400:	48 8b 87 88 00 00 00 	mov    0x88(%rdi),%rax
    4407:	48 89 44 24 c8       	mov    %rax,-0x38(%rsp)
    440c:	4c 8b a7 90 00 00 00 	mov    0x90(%rdi),%r12
    4413:	4c 8b 87 98 00 00 00 	mov    0x98(%rdi),%r8
    441a:	4c 8b af a0 00 00 00 	mov    0xa0(%rdi),%r13
    4421:	4c 8b 97 a8 00 00 00 	mov    0xa8(%rdi),%r10
    4428:	48 8b 87 b0 00 00 00 	mov    0xb0(%rdi),%rax
    442f:	48 8b 8f b8 00 00 00 	mov    0xb8(%rdi),%rcx
    4436:	48 89 4c 24 c0       	mov    %rcx,-0x40(%rsp)
    443b:	48 89 7c 24 58       	mov    %rdi,0x58(%rsp)
    4440:	48 8b 8f c0 00 00 00 	mov    0xc0(%rdi),%rcx
    4447:	48 89 4c 24 b0       	mov    %rcx,-0x50(%rsp)
    444c:	31 c9                	xor    %ecx,%ecx
    444e:	48 89 4c 24 10       	mov    %rcx,0x10(%rsp)
    4453:	48 83 7c 24 10 17    	cmpq   $0x17,0x10(%rsp)
    4459:	0f 87 e5 06 00 00    	ja     4b44 <KeccakF1600_StatePermute+0x7d8>
    445f:	48 8b 4c 24 d0       	mov    -0x30(%rsp),%rcx
    4464:	4c 89 6c 24 30       	mov    %r13,0x30(%rsp)
    4469:	4c 31 e9             	xor    %r13,%rcx
    446c:	4c 89 d7             	mov    %r10,%rdi
    446f:	4c 89 54 24 38       	mov    %r10,0x38(%rsp)
    4474:	4c 8b 54 24 90       	mov    -0x70(%rsp),%r10
    4479:	4c 33 14 24          	xor    (%rsp),%r10
    447d:	49 31 ca             	xor    %rcx,%r10
    4480:	48 8b 4c 24 88       	mov    -0x78(%rsp),%rcx
    4485:	48 31 f9             	xor    %rdi,%rcx
    4488:	4c 89 fb             	mov    %r15,%rbx
    448b:	4d 89 f5             	mov    %r14,%r13
    448e:	4c 8b 74 24 f0       	mov    -0x10(%rsp),%r14
    4493:	4c 33 74 24 98       	xor    -0x68(%rsp),%r14
    4498:	49 31 ce             	xor    %rcx,%r14
    449b:	48 8b 4c 24 c8       	mov    -0x38(%rsp),%rcx
    44a0:	48 31 c1             	xor    %rax,%rcx
    44a3:	49 89 d7             	mov    %rdx,%r15
    44a6:	4d 89 c3             	mov    %r8,%r11
    44a9:	4c 89 44 24 e0       	mov    %r8,-0x20(%rsp)
    44ae:	4c 8b 44 24 40       	mov    0x40(%rsp),%r8
    44b3:	4c 89 c2             	mov    %r8,%rdx
    44b6:	48 33 54 24 a8       	xor    -0x58(%rsp),%rdx
    44bb:	48 31 ca             	xor    %rcx,%rdx
    44be:	48 89 6c 24 d8       	mov    %rbp,-0x28(%rsp)
    44c3:	4d 89 e1             	mov    %r12,%r9
    44c6:	4c 33 4c 24 c0       	xor    -0x40(%rsp),%r9
    44cb:	48 8b 4c 24 a0       	mov    -0x60(%rsp),%rcx
    44d0:	48 33 4c 24 f8       	xor    -0x8(%rsp),%rcx
    44d5:	4c 31 c9             	xor    %r9,%rcx
    44d8:	48 8b 7c 24 b0       	mov    -0x50(%rsp),%rdi
    44dd:	49 31 fb             	xor    %rdi,%r11
    44e0:	4d 89 e9             	mov    %r13,%r9
    44e3:	49 31 d9             	xor    %rbx,%r9
    44e6:	48 89 de             	mov    %rbx,%rsi
    44e9:	4d 31 d9             	xor    %r11,%r9
    44ec:	4c 33 54 24 80       	xor    -0x80(%rsp),%r10
    44f1:	49 31 ee             	xor    %rbp,%r14
    44f4:	48 33 54 24 08       	xor    0x8(%rsp),%rdx
    44f9:	4c 8b 5c 24 b8       	mov    -0x48(%rsp),%r11
    44fe:	4c 31 d9             	xor    %r11,%rcx
    4501:	48 89 cd             	mov    %rcx,%rbp
    4504:	48 d1 c5             	rol    $1,%rbp
    4507:	4c 31 f5             	xor    %r14,%rbp
    450a:	49 d1 c6             	rol    $1,%r14
    450d:	4d 31 f9             	xor    %r15,%r9
    4510:	4d 31 ce             	xor    %r9,%r14
    4513:	49 d1 c1             	rol    $1,%r9
    4516:	49 31 d1             	xor    %rdx,%r9
    4519:	48 89 d3             	mov    %rdx,%rbx
    451c:	48 d1 c3             	rol    $1,%rbx
    451f:	4c 31 d3             	xor    %r10,%rbx
    4522:	49 d1 c2             	rol    $1,%r10
    4525:	49 31 ca             	xor    %rcx,%r10
    4528:	4c 31 d7             	xor    %r10,%rdi
    452b:	4c 31 d6             	xor    %r10,%rsi
    452e:	48 89 74 24 b0       	mov    %rsi,-0x50(%rsp)
    4533:	4c 31 54 24 e0       	xor    %r10,-0x20(%rsp)
    4538:	4d 31 d7             	xor    %r10,%r15
    453b:	4c 89 7c 24 e8       	mov    %r15,-0x18(%rsp)
    4540:	4d 31 ea             	xor    %r13,%r10
    4543:	4c 89 54 24 60       	mov    %r10,0x60(%rsp)
    4548:	48 8b 54 24 98       	mov    -0x68(%rsp),%rdx
    454d:	48 31 da             	xor    %rbx,%rdx
    4550:	48 c1 c2 2c          	rol    $0x2c,%rdx
    4554:	49 31 e8             	xor    %rbp,%r8
    4557:	49 c1 c0 2b          	rol    $0x2b,%r8
    455b:	4d 31 cc             	xor    %r9,%r12
    455e:	49 c1 c4 15          	rol    $0x15,%r12
    4562:	48 c1 c7 0e          	rol    $0xe,%rdi
    4566:	4c 8b 7c 24 80       	mov    -0x80(%rsp),%r15
    456b:	4d 31 f7             	xor    %r14,%r15
    456e:	48 89 d6             	mov    %rdx,%rsi
    4571:	48 f7 d6             	not    %rsi
    4574:	4c 21 c6             	and    %r8,%rsi
    4577:	4c 8d 15 12 84 00 00 	lea    0x8412(%rip),%r10        # c990 <KeccakF_RoundConstants>
    457e:	4c 8b 6c 24 30       	mov    0x30(%rsp),%r13
    4583:	48 8b 4c 24 10       	mov    0x10(%rsp),%rcx
    4588:	49 33 34 ca          	xor    (%r10,%rcx,8),%rsi
    458c:	4c 89 e1             	mov    %r12,%rcx
    458f:	48 f7 d1             	not    %rcx
    4592:	48 21 f9             	and    %rdi,%rcx
    4595:	4c 31 c1             	xor    %r8,%rcx
    4598:	48 89 4c 24 50       	mov    %rcx,0x50(%rsp)
    459d:	49 f7 d0             	not    %r8
    45a0:	4d 21 e0             	and    %r12,%r8
    45a3:	48 89 f9             	mov    %rdi,%rcx
    45a6:	48 f7 d1             	not    %rcx
    45a9:	4c 21 f9             	and    %r15,%rcx
    45ac:	4c 31 e1             	xor    %r12,%rcx
    45af:	48 89 4c 24 20       	mov    %rcx,0x20(%rsp)
    45b4:	4c 31 fe             	xor    %r15,%rsi
    45b7:	48 89 74 24 18       	mov    %rsi,0x18(%rsp)
    45bc:	49 31 d0             	xor    %rdx,%r8
    45bf:	4c 89 44 24 28       	mov    %r8,0x28(%rsp)
    45c4:	4d 31 cb             	xor    %r9,%r11
    45c7:	49 c1 c3 1c          	rol    $0x1c,%r11
    45cb:	48 89 f9             	mov    %rdi,%rcx
    45ce:	48 8b 74 24 b0       	mov    -0x50(%rsp),%rsi
    45d3:	48 c1 c6 14          	rol    $0x14,%rsi
    45d7:	49 f7 d7             	not    %r15
    45da:	48 8b 7c 24 90       	mov    -0x70(%rsp),%rdi
    45df:	4c 31 f7             	xor    %r14,%rdi
    45e2:	48 c1 c7 03          	rol    $0x3,%rdi
    45e6:	49 21 d7             	and    %rdx,%r15
    45e9:	4c 8b 44 24 88       	mov    -0x78(%rsp),%r8
    45ee:	49 31 d8             	xor    %rbx,%r8
    45f1:	49 c1 c0 2d          	rol    $0x2d,%r8
    45f5:	49 31 cf             	xor    %rcx,%r15
    45f8:	4c 89 7c 24 80       	mov    %r15,-0x80(%rsp)
    45fd:	48 31 e8             	xor    %rbp,%rax
    4600:	48 c1 c0 3d          	rol    $0x3d,%rax
    4604:	48 89 f1             	mov    %rsi,%rcx
    4607:	49 89 f7             	mov    %rsi,%r15
    460a:	48 f7 d1             	not    %rcx
    460d:	48 21 f9             	and    %rdi,%rcx
    4610:	48 89 ce             	mov    %rcx,%rsi
    4613:	4c 89 c1             	mov    %r8,%rcx
    4616:	48 f7 d1             	not    %rcx
    4619:	48 21 c1             	and    %rax,%rcx
    461c:	48 31 f9             	xor    %rdi,%rcx
    461f:	48 89 4c 24 90       	mov    %rcx,-0x70(%rsp)
    4624:	48 89 fa             	mov    %rdi,%rdx
    4627:	48 f7 d2             	not    %rdx
    462a:	4c 21 c2             	and    %r8,%rdx
    462d:	48 89 c1             	mov    %rax,%rcx
    4630:	48 f7 d1             	not    %rcx
    4633:	4c 21 d9             	and    %r11,%rcx
    4636:	4c 31 c1             	xor    %r8,%rcx
    4639:	48 89 4c 24 48       	mov    %rcx,0x48(%rsp)
    463e:	4c 31 de             	xor    %r11,%rsi
    4641:	48 89 74 24 88       	mov    %rsi,-0x78(%rsp)
    4646:	4c 31 fa             	xor    %r15,%rdx
    4649:	48 89 54 24 98       	mov    %rdx,-0x68(%rsp)
    464e:	49 f7 d3             	not    %r11
    4651:	48 8b 74 24 d8       	mov    -0x28(%rsp),%rsi
    4656:	48 31 de             	xor    %rbx,%rsi
    4659:	48 d1 c6             	rol    $1,%rsi
    465c:	4c 8b 44 24 a8       	mov    -0x58(%rsp),%r8
    4661:	49 31 e8             	xor    %rbp,%r8
    4664:	49 c1 c0 06          	rol    $0x6,%r8
    4668:	4c 8b 64 24 a0       	mov    -0x60(%rsp),%r12
    466d:	4d 31 cc             	xor    %r9,%r12
    4670:	49 c1 c4 19          	rol    $0x19,%r12
    4674:	48 8b 7c 24 e0       	mov    -0x20(%rsp),%rdi
    4679:	48 c1 c7 08          	rol    $0x8,%rdi
    467d:	4d 21 fb             	and    %r15,%r11
    4680:	4d 31 f5             	xor    %r14,%r13
    4683:	49 c1 c5 12          	rol    $0x12,%r13
    4687:	49 31 c3             	xor    %rax,%r11
    468a:	4c 89 5c 24 b8       	mov    %r11,-0x48(%rsp)
    468f:	4c 89 c0             	mov    %r8,%rax
    4692:	48 f7 d0             	not    %rax
    4695:	4c 21 e0             	and    %r12,%rax
    4698:	48 89 c1             	mov    %rax,%rcx
    469b:	49 89 ff             	mov    %rdi,%r15
    469e:	49 f7 d7             	not    %r15
    46a1:	4d 21 ef             	and    %r13,%r15
    46a4:	4d 31 e7             	xor    %r12,%r15
    46a7:	4c 89 e0             	mov    %r12,%rax
    46aa:	48 f7 d0             	not    %rax
    46ad:	48 21 f8             	and    %rdi,%rax
    46b0:	49 89 fb             	mov    %rdi,%r11
    46b3:	4c 89 ef             	mov    %r13,%rdi
    46b6:	48 f7 d7             	not    %rdi
    46b9:	48 21 f7             	and    %rsi,%rdi
    46bc:	4c 31 df             	xor    %r11,%rdi
    46bf:	48 89 7c 24 a0       	mov    %rdi,-0x60(%rsp)
    46c4:	48 31 f1             	xor    %rsi,%rcx
    46c7:	48 89 4c 24 a8       	mov    %rcx,-0x58(%rsp)
    46cc:	4c 31 c0             	xor    %r8,%rax
    46cf:	48 89 44 24 e0       	mov    %rax,-0x20(%rsp)
    46d4:	48 f7 d6             	not    %rsi
    46d7:	48 8b 7c 24 e8       	mov    -0x18(%rsp),%rdi
    46dc:	48 c1 c7 1b          	rol    $0x1b,%rdi
    46e0:	4c 21 c6             	and    %r8,%rsi
    46e3:	48 8b 0c 24          	mov    (%rsp),%rcx
    46e7:	4c 31 f1             	xor    %r14,%rcx
    46ea:	48 c1 c1 24          	rol    $0x24,%rcx
    46ee:	4c 31 ee             	xor    %r13,%rsi
    46f1:	48 89 74 24 d8       	mov    %rsi,-0x28(%rsp)
    46f6:	4c 8b 6c 24 f0       	mov    -0x10(%rsp),%r13
    46fb:	49 31 dd             	xor    %rbx,%r13
    46fe:	49 c1 c5 0a          	rol    $0xa,%r13
    4702:	4c 8b 44 24 c8       	mov    -0x38(%rsp),%r8
    4707:	49 31 e8             	xor    %rbp,%r8
    470a:	49 c1 c0 0f          	rol    $0xf,%r8
    470e:	4c 8b 64 24 c0       	mov    -0x40(%rsp),%r12
    4713:	4d 31 cc             	xor    %r9,%r12
    4716:	4c 89 ca             	mov    %r9,%rdx
    4719:	49 c1 c4 38          	rol    $0x38,%r12
    471d:	49 89 c9             	mov    %rcx,%r9
    4720:	49 f7 d1             	not    %r9
    4723:	4d 21 e9             	and    %r13,%r9
    4726:	4d 89 c3             	mov    %r8,%r11
    4729:	49 f7 d3             	not    %r11
    472c:	4d 21 e3             	and    %r12,%r11
    472f:	4d 31 eb             	xor    %r13,%r11
    4732:	4c 89 5c 24 c8       	mov    %r11,-0x38(%rsp)
    4737:	49 f7 d5             	not    %r13
    473a:	4d 21 c5             	and    %r8,%r13
    473d:	4c 89 e6             	mov    %r12,%rsi
    4740:	48 f7 d6             	not    %rsi
    4743:	48 21 fe             	and    %rdi,%rsi
    4746:	4c 31 c6             	xor    %r8,%rsi
    4749:	49 31 f9             	xor    %rdi,%r9
    474c:	4c 89 4c 24 c0       	mov    %r9,-0x40(%rsp)
    4751:	49 31 cd             	xor    %rcx,%r13
    4754:	48 f7 d7             	not    %rdi
    4757:	48 21 cf             	and    %rcx,%rdi
    475a:	4c 31 e7             	xor    %r12,%rdi
    475d:	48 89 7c 24 e8       	mov    %rdi,-0x18(%rsp)
    4762:	48 33 6c 24 08       	xor    0x8(%rsp),%rbp
    4767:	48 89 d0             	mov    %rdx,%rax
    476a:	48 33 44 24 f8       	xor    -0x8(%rsp),%rax
    476f:	4c 33 74 24 d0       	xor    -0x30(%rsp),%r14
    4774:	48 c1 c5 3e          	rol    $0x3e,%rbp
    4778:	48 c1 c0 37          	rol    $0x37,%rax
    477c:	4c 8b 54 24 60       	mov    0x60(%rsp),%r10
    4781:	49 c1 c2 27          	rol    $0x27,%r10
    4785:	49 c1 c6 29          	rol    $0x29,%r14
    4789:	48 33 5c 24 38       	xor    0x38(%rsp),%rbx
    478e:	48 c1 c3 02          	rol    $0x2,%rbx
    4792:	48 89 c7             	mov    %rax,%rdi
    4795:	48 89 c2             	mov    %rax,%rdx
    4798:	48 f7 d7             	not    %rdi
    479b:	4c 21 d7             	and    %r10,%rdi
    479e:	4c 89 d0             	mov    %r10,%rax
    47a1:	4d 89 f4             	mov    %r14,%r12
    47a4:	49 f7 d4             	not    %r12
    47a7:	49 21 dc             	and    %rbx,%r12
    47aa:	4d 31 d4             	xor    %r10,%r12
    47ad:	48 f7 d0             	not    %rax
    47b0:	4c 21 f0             	and    %r14,%rax
    47b3:	49 89 da             	mov    %rbx,%r10
    47b6:	49 f7 d2             	not    %r10
    47b9:	49 21 ea             	and    %rbp,%r10
    47bc:	4d 31 f2             	xor    %r14,%r10
    47bf:	4d 89 d6             	mov    %r10,%r14
    47c2:	4c 89 54 24 d0       	mov    %r10,-0x30(%rsp)
    47c7:	48 31 ef             	xor    %rbp,%rdi
    47ca:	48 31 d0             	xor    %rdx,%rax
    47cd:	48 89 44 24 38       	mov    %rax,0x38(%rsp)
    47d2:	48 f7 d5             	not    %rbp
    47d5:	48 21 d5             	and    %rdx,%rbp
    47d8:	48 31 dd             	xor    %rbx,%rbp
    47db:	4c 33 4c 24 a8       	xor    -0x58(%rsp),%r9
    47e0:	4c 8b 54 24 88       	mov    -0x78(%rsp),%r10
    47e5:	49 31 fa             	xor    %rdi,%r10
    47e8:	4d 31 ca             	xor    %r9,%r10
    47eb:	4c 8b 4c 24 98       	mov    -0x68(%rsp),%r9
    47f0:	4c 33 4c 24 28       	xor    0x28(%rsp),%r9
    47f5:	4c 89 ea             	mov    %r13,%rdx
    47f8:	48 33 54 24 e0       	xor    -0x20(%rsp),%rdx
    47fd:	4c 31 ca             	xor    %r9,%rdx
    4800:	4c 8b 4c 24 90       	mov    -0x70(%rsp),%r9
    4805:	4d 31 d9             	xor    %r11,%r9
    4808:	4c 89 e3             	mov    %r12,%rbx
    480b:	48 33 5c 24 50       	xor    0x50(%rsp),%rbx
    4810:	4c 31 cb             	xor    %r9,%rbx
    4813:	4c 8b 4c 24 a0       	mov    -0x60(%rsp),%r9
    4818:	4c 33 4c 24 48       	xor    0x48(%rsp),%r9
    481d:	4d 89 f3             	mov    %r14,%r11
    4820:	4c 33 5c 24 20       	xor    0x20(%rsp),%r11
    4825:	4d 31 cb             	xor    %r9,%r11
    4828:	4c 8b 74 24 80       	mov    -0x80(%rsp),%r14
    482d:	49 31 ee             	xor    %rbp,%r14
    4830:	4c 8b 4c 24 d8       	mov    -0x28(%rsp),%r9
    4835:	48 8b 4c 24 b8       	mov    -0x48(%rsp),%rcx
    483a:	49 31 c9             	xor    %rcx,%r9
    483d:	4d 31 f1             	xor    %r14,%r9
    4840:	4c 33 54 24 18       	xor    0x18(%rsp),%r10
    4845:	48 31 c2             	xor    %rax,%rdx
    4848:	4c 31 fb             	xor    %r15,%rbx
    484b:	49 31 f3             	xor    %rsi,%r11
    484e:	4c 33 4c 24 e8       	xor    -0x18(%rsp),%r9
    4853:	4c 89 d8             	mov    %r11,%rax
    4856:	48 d1 c0             	rol    $1,%rax
    4859:	48 31 d0             	xor    %rdx,%rax
    485c:	48 89 44 24 b0       	mov    %rax,-0x50(%rsp)
    4861:	49 89 d6             	mov    %rdx,%r14
    4864:	49 d1 c6             	rol    $1,%r14
    4867:	4d 31 ce             	xor    %r9,%r14
    486a:	48 89 da             	mov    %rbx,%rdx
    486d:	48 d1 c2             	rol    $1,%rdx
    4870:	4c 31 d2             	xor    %r10,%rdx
    4873:	48 89 54 24 30       	mov    %rdx,0x30(%rsp)
    4878:	49 d1 c1             	rol    $1,%r9
    487b:	49 d1 c2             	rol    $1,%r10
    487e:	49 31 d9             	xor    %rbx,%r9
    4881:	4c 8b 44 24 98       	mov    -0x68(%rsp),%r8
    4886:	49 31 d0             	xor    %rdx,%r8
    4889:	49 c1 c0 2c          	rol    $0x2c,%r8
    488d:	4d 31 da             	xor    %r11,%r10
    4890:	49 31 c7             	xor    %rax,%r15
    4893:	49 c1 c7 2b          	rol    $0x2b,%r15
    4897:	4c 31 d5             	xor    %r10,%rbp
    489a:	4c 31 d1             	xor    %r10,%rcx
    489d:	48 89 4c 24 b8       	mov    %rcx,-0x48(%rsp)
    48a2:	4c 31 54 24 e8       	xor    %r10,-0x18(%rsp)
    48a7:	4c 31 54 24 80       	xor    %r10,-0x80(%rsp)
    48ac:	4c 33 54 24 d8       	xor    -0x28(%rsp),%r10
    48b1:	4c 31 ce             	xor    %r9,%rsi
    48b4:	48 c1 c6 15          	rol    $0x15,%rsi
    48b8:	48 8b 4c 24 18       	mov    0x18(%rsp),%rcx
    48bd:	4c 31 f1             	xor    %r14,%rcx
    48c0:	48 c1 c5 0e          	rol    $0xe,%rbp
    48c4:	4c 89 c3             	mov    %r8,%rbx
    48c7:	48 f7 d3             	not    %rbx
    48ca:	4c 21 fb             	and    %r15,%rbx
    48cd:	49 89 f3             	mov    %rsi,%r11
    48d0:	49 f7 d3             	not    %r11
    48d3:	49 21 eb             	and    %rbp,%r11
    48d6:	4d 31 fb             	xor    %r15,%r11
    48d9:	4c 89 5c 24 08       	mov    %r11,0x8(%rsp)
    48de:	49 f7 d7             	not    %r15
    48e1:	49 21 f7             	and    %rsi,%r15
    48e4:	49 89 eb             	mov    %rbp,%r11
    48e7:	49 f7 d3             	not    %r11
    48ea:	49 21 cb             	and    %rcx,%r11
    48ed:	49 31 f3             	xor    %rsi,%r11
    48f0:	48 8b 74 24 10       	mov    0x10(%rsp),%rsi
    48f5:	48 8d 05 94 80 00 00 	lea    0x8094(%rip),%rax        # c990 <KeccakF_RoundConstants>
    48fc:	48 33 5c f0 08       	xor    0x8(%rax,%rsi,8),%rbx
    4901:	48 89 ce             	mov    %rcx,%rsi
    4904:	48 31 cb             	xor    %rcx,%rbx
    4907:	4d 31 c7             	xor    %r8,%r15
    490a:	4c 89 7c 24 d8       	mov    %r15,-0x28(%rsp)
    490f:	48 f7 d6             	not    %rsi
    4912:	4c 21 c6             	and    %r8,%rsi
    4915:	48 8b 54 24 20       	mov    0x20(%rsp),%rdx
    491a:	4c 31 ca             	xor    %r9,%rdx
    491d:	48 c1 c2 1c          	rol    $0x1c,%rdx
    4921:	48 8b 4c 24 b8       	mov    -0x48(%rsp),%rcx
    4926:	48 c1 c1 14          	rol    $0x14,%rcx
    492a:	48 31 ee             	xor    %rbp,%rsi
    492d:	48 89 74 24 18       	mov    %rsi,0x18(%rsp)
    4932:	48 8b 74 24 a8       	mov    -0x58(%rsp),%rsi
    4937:	4c 31 f6             	xor    %r14,%rsi
    493a:	48 c1 c6 03          	rol    $0x3,%rsi
    493e:	48 8b 44 24 30       	mov    0x30(%rsp),%rax
    4943:	49 31 c5             	xor    %rax,%r13
    4946:	49 c1 c5 2d          	rol    $0x2d,%r13
    494a:	4c 8b 7c 24 b0       	mov    -0x50(%rsp),%r15
    494f:	4d 31 fc             	xor    %r15,%r12
    4952:	49 c1 c4 3d          	rol    $0x3d,%r12
    4956:	49 89 c8             	mov    %rcx,%r8
    4959:	49 f7 d0             	not    %r8
    495c:	49 21 f0             	and    %rsi,%r8
    495f:	4c 89 ed             	mov    %r13,%rbp
    4962:	48 f7 d5             	not    %rbp
    4965:	4c 21 e5             	and    %r12,%rbp
    4968:	48 31 f5             	xor    %rsi,%rbp
    496b:	48 89 6c 24 a8       	mov    %rbp,-0x58(%rsp)
    4970:	48 f7 d6             	not    %rsi
    4973:	4c 21 ee             	and    %r13,%rsi
    4976:	4c 89 e5             	mov    %r12,%rbp
    4979:	48 f7 d5             	not    %rbp
    497c:	48 21 d5             	and    %rdx,%rbp
    497f:	4c 31 ed             	xor    %r13,%rbp
    4982:	48 89 6c 24 f8       	mov    %rbp,-0x8(%rsp)
    4987:	49 31 d0             	xor    %rdx,%r8
    498a:	4c 89 04 24          	mov    %r8,(%rsp)
    498e:	48 31 ce             	xor    %rcx,%rsi
    4991:	48 89 74 24 98       	mov    %rsi,-0x68(%rsp)
    4996:	48 f7 d2             	not    %rdx
    4999:	48 21 ca             	and    %rcx,%rdx
    499c:	4c 31 e2             	xor    %r12,%rdx
    499f:	48 89 54 24 20       	mov    %rdx,0x20(%rsp)
    49a4:	48 8b 6c 24 28       	mov    0x28(%rsp),%rbp
    49a9:	48 31 c5             	xor    %rax,%rbp
    49ac:	48 89 c2             	mov    %rax,%rdx
    49af:	48 d1 c5             	rol    $1,%rbp
    49b2:	4c 8b 44 24 90       	mov    -0x70(%rsp),%r8
    49b7:	4d 31 f8             	xor    %r15,%r8
    49ba:	49 c1 c0 06          	rol    $0x6,%r8
    49be:	48 8b 44 24 a0       	mov    -0x60(%rsp),%rax
    49c3:	4c 31 c8             	xor    %r9,%rax
    49c6:	48 c1 c0 19          	rol    $0x19,%rax
    49ca:	48 8b 4c 24 e8       	mov    -0x18(%rsp),%rcx
    49cf:	48 c1 c1 08          	rol    $0x8,%rcx
    49d3:	4c 31 f7             	xor    %r14,%rdi
    49d6:	48 c1 c7 12          	rol    $0x12,%rdi
    49da:	4c 89 c6             	mov    %r8,%rsi
    49dd:	48 f7 d6             	not    %rsi
    49e0:	48 21 c6             	and    %rax,%rsi
    49e3:	49 89 cc             	mov    %rcx,%r12
    49e6:	49 f7 d4             	not    %r12
    49e9:	49 21 fc             	and    %rdi,%r12
    49ec:	49 31 c4             	xor    %rax,%r12
    49ef:	4c 89 64 24 40       	mov    %r12,0x40(%rsp)
    49f4:	49 89 c4             	mov    %rax,%r12
    49f7:	49 f7 d4             	not    %r12
    49fa:	49 21 cc             	and    %rcx,%r12
    49fd:	49 89 fd             	mov    %rdi,%r13
    4a00:	49 f7 d5             	not    %r13
    4a03:	49 21 ed             	and    %rbp,%r13
    4a06:	49 31 cd             	xor    %rcx,%r13
    4a09:	4c 89 6c 24 a0       	mov    %r13,-0x60(%rsp)
    4a0e:	48 31 ee             	xor    %rbp,%rsi
    4a11:	48 89 74 24 90       	mov    %rsi,-0x70(%rsp)
    4a16:	4d 31 c4             	xor    %r8,%r12
    4a19:	4c 89 64 24 f0       	mov    %r12,-0x10(%rsp)
    4a1e:	48 f7 d5             	not    %rbp
    4a21:	4c 21 c5             	and    %r8,%rbp
    4a24:	4c 8b 6c 24 88       	mov    -0x78(%rsp),%r13
    4a29:	4d 31 f5             	xor    %r14,%r13
    4a2c:	49 c1 c5 24          	rol    $0x24,%r13
    4a30:	48 31 fd             	xor    %rdi,%rbp
    4a33:	48 89 6c 24 28       	mov    %rbp,0x28(%rsp)
    4a38:	48 8b 74 24 e0       	mov    -0x20(%rsp),%rsi
    4a3d:	48 31 d6             	xor    %rdx,%rsi
    4a40:	48 89 d5             	mov    %rdx,%rbp
    4a43:	48 c1 c6 0a          	rol    $0xa,%rsi
    4a47:	48 8b 7c 24 c8       	mov    -0x38(%rsp),%rdi
    4a4c:	4c 31 ff             	xor    %r15,%rdi
    4a4f:	48 c1 c7 0f          	rol    $0xf,%rdi
    4a53:	48 8b 54 24 d0       	mov    -0x30(%rsp),%rdx
    4a58:	4c 31 ca             	xor    %r9,%rdx
    4a5b:	48 c1 c2 38          	rol    $0x38,%rdx
    4a5f:	4c 89 e8             	mov    %r13,%rax
    4a62:	48 f7 d0             	not    %rax
    4a65:	48 21 f0             	and    %rsi,%rax
    4a68:	49 89 fc             	mov    %rdi,%r12
    4a6b:	49 f7 d4             	not    %r12
    4a6e:	49 21 d4             	and    %rdx,%r12
    4a71:	49 31 f4             	xor    %rsi,%r12
    4a74:	4c 89 64 24 c8       	mov    %r12,-0x38(%rsp)
    4a79:	48 89 f1             	mov    %rsi,%rcx
    4a7c:	4c 8b 44 24 80       	mov    -0x80(%rsp),%r8
    4a81:	49 c1 c0 1b          	rol    $0x1b,%r8
    4a85:	48 f7 d1             	not    %rcx
    4a88:	48 21 f9             	and    %rdi,%rcx
    4a8b:	49 89 d4             	mov    %rdx,%r12
    4a8e:	49 f7 d4             	not    %r12
    4a91:	4d 21 c4             	and    %r8,%r12
    4a94:	49 31 fc             	xor    %rdi,%r12
    4a97:	4c 31 c0             	xor    %r8,%rax
    4a9a:	48 89 44 24 d0       	mov    %rax,-0x30(%rsp)
    4a9f:	4c 31 e9             	xor    %r13,%rcx
    4aa2:	48 89 4c 24 88       	mov    %rcx,-0x78(%rsp)
    4aa7:	49 f7 d0             	not    %r8
    4aaa:	4d 21 e8             	and    %r13,%r8
    4aad:	4c 33 7c 24 50       	xor    0x50(%rsp),%r15
    4ab2:	4c 33 4c 24 48       	xor    0x48(%rsp),%r9
    4ab7:	4c 33 74 24 c0       	xor    -0x40(%rsp),%r14
    4abc:	48 33 6c 24 38       	xor    0x38(%rsp),%rbp
    4ac1:	49 c1 c7 3e          	rol    $0x3e,%r15
    4ac5:	49 c1 c1 37          	rol    $0x37,%r9
    4ac9:	49 c1 c2 27          	rol    $0x27,%r10
    4acd:	49 c1 c6 29          	rol    $0x29,%r14
    4ad1:	48 c1 c5 02          	rol    $0x2,%rbp
    4ad5:	49 31 d0             	xor    %rdx,%r8
    4ad8:	4c 89 ca             	mov    %r9,%rdx
    4adb:	48 f7 d2             	not    %rdx
    4ade:	4c 21 d2             	and    %r10,%rdx
    4ae1:	4c 89 f0             	mov    %r14,%rax
    4ae4:	48 f7 d0             	not    %rax
    4ae7:	48 21 e8             	and    %rbp,%rax
    4aea:	4c 31 d0             	xor    %r10,%rax
    4aed:	49 f7 d2             	not    %r10
    4af0:	4d 21 f2             	and    %r14,%r10
    4af3:	48 89 ef             	mov    %rbp,%rdi
    4af6:	48 f7 d7             	not    %rdi
    4af9:	4c 21 ff             	and    %r15,%rdi
    4afc:	4c 31 f7             	xor    %r14,%rdi
    4aff:	48 89 7c 24 c0       	mov    %rdi,-0x40(%rsp)
    4b04:	4c 31 fa             	xor    %r15,%rdx
    4b07:	49 89 d5             	mov    %rdx,%r13
    4b0a:	4d 31 ca             	xor    %r9,%r10
    4b0d:	49 f7 d7             	not    %r15
    4b10:	4d 21 cf             	and    %r9,%r15
    4b13:	49 31 ef             	xor    %rbp,%r15
    4b16:	4c 89 7c 24 b0       	mov    %r15,-0x50(%rsp)
    4b1b:	4c 8b 74 24 28       	mov    0x28(%rsp),%r14
    4b20:	48 83 44 24 10 02    	addq   $0x2,0x10(%rsp)
    4b26:	4c 8b 7c 24 20       	mov    0x20(%rsp),%r15
    4b2b:	48 8b 54 24 18       	mov    0x18(%rsp),%rdx
    4b30:	4c 89 5c 24 b8       	mov    %r11,-0x48(%rsp)
    4b35:	48 8b 6c 24 d8       	mov    -0x28(%rsp),%rbp
    4b3a:	48 89 5c 24 80       	mov    %rbx,-0x80(%rsp)
    4b3f:	e9 0f f9 ff ff       	jmp    4453 <KeccakF1600_StatePermute+0xe7>
    4b44:	48 8b 4c 24 58       	mov    0x58(%rsp),%rcx
    4b49:	48 8b 7c 24 80       	mov    -0x80(%rsp),%rdi
    4b4e:	48 89 39             	mov    %rdi,(%rcx)
    4b51:	48 89 69 08          	mov    %rbp,0x8(%rcx)
    4b55:	48 8b 7c 24 08       	mov    0x8(%rsp),%rdi
    4b5a:	48 89 79 10          	mov    %rdi,0x10(%rcx)
    4b5e:	48 8b 74 24 b8       	mov    -0x48(%rsp),%rsi
    4b63:	48 89 71 18          	mov    %rsi,0x18(%rcx)
    4b67:	48 89 51 20          	mov    %rdx,0x20(%rcx)
    4b6b:	48 8b 14 24          	mov    (%rsp),%rdx
    4b6f:	48 89 51 28          	mov    %rdx,0x28(%rcx)
    4b73:	48 8b 54 24 98       	mov    -0x68(%rsp),%rdx
    4b78:	48 89 51 30          	mov    %rdx,0x30(%rcx)
    4b7c:	48 8b 54 24 a8       	mov    -0x58(%rsp),%rdx
    4b81:	48 89 51 38          	mov    %rdx,0x38(%rcx)
    4b85:	48 8b 54 24 f8       	mov    -0x8(%rsp),%rdx
    4b8a:	48 89 51 40          	mov    %rdx,0x40(%rcx)
    4b8e:	4c 89 79 48          	mov    %r15,0x48(%rcx)
    4b92:	48 8b 54 24 90       	mov    -0x70(%rsp),%rdx
    4b97:	48 89 51 50          	mov    %rdx,0x50(%rcx)
    4b9b:	48 8b 54 24 f0       	mov    -0x10(%rsp),%rdx
    4ba0:	48 89 51 58          	mov    %rdx,0x58(%rcx)
    4ba4:	48 8b 54 24 40       	mov    0x40(%rsp),%rdx
    4ba9:	48 89 51 60          	mov    %rdx,0x60(%rcx)
    4bad:	48 8b 54 24 a0       	mov    -0x60(%rsp),%rdx
    4bb2:	48 89 51 68          	mov    %rdx,0x68(%rcx)
    4bb6:	4c 89 71 70          	mov    %r14,0x70(%rcx)
    4bba:	48 8b 54 24 d0       	mov    -0x30(%rsp),%rdx
    4bbf:	48 89 51 78          	mov    %rdx,0x78(%rcx)
    4bc3:	48 8b 54 24 88       	mov    -0x78(%rsp),%rdx
    4bc8:	48 89 91 80 00 00 00 	mov    %rdx,0x80(%rcx)
    4bcf:	48 8b 54 24 c8       	mov    -0x38(%rsp),%rdx
    4bd4:	48 89 91 88 00 00 00 	mov    %rdx,0x88(%rcx)
    4bdb:	4c 89 a1 90 00 00 00 	mov    %r12,0x90(%rcx)
    4be2:	4c 89 81 98 00 00 00 	mov    %r8,0x98(%rcx)
    4be9:	4c 89 a9 a0 00 00 00 	mov    %r13,0xa0(%rcx)
    4bf0:	4c 89 91 a8 00 00 00 	mov    %r10,0xa8(%rcx)
    4bf7:	48 89 81 b0 00 00 00 	mov    %rax,0xb0(%rcx)
    4bfe:	48 8b 44 24 c0       	mov    -0x40(%rsp),%rax
    4c03:	48 89 81 b8 00 00 00 	mov    %rax,0xb8(%rcx)
    4c0a:	48 8b 44 24 b0       	mov    -0x50(%rsp),%rax
    4c0f:	48 89 81 c0 00 00 00 	mov    %rax,0xc0(%rcx)
    4c16:	48 83 c4 68          	add    $0x68,%rsp
    4c1a:	5b                   	pop    %rbx
    4c1b:	41 5c                	pop    %r12
    4c1d:	41 5d                	pop    %r13
    4c1f:	41 5e                	pop    %r14
    4c21:	41 5f                	pop    %r15
    4c23:	5d                   	pop    %rbp
    4c24:	c3                   	ret

0000000000004c25 <store64>:
    4c25:	31 c9                	xor    %ecx,%ecx
    4c27:	48 83 f9 40          	cmp    $0x40,%rcx
    4c2b:	74 11                	je     4c3e <store64+0x19>
    4c2d:	48 89 f0             	mov    %rsi,%rax
    4c30:	48 d3 e8             	shr    %cl,%rax
    4c33:	88 07                	mov    %al,(%rdi)
    4c35:	48 83 c1 08          	add    $0x8,%rcx
    4c39:	48 ff c7             	inc    %rdi
    4c3c:	eb e9                	jmp    4c27 <store64+0x2>
    4c3e:	c3                   	ret

0000000000004c3f <pqcrystals_kyber_fips202_ref_sha3_512>:
    4c3f:	41 56                	push   %r14
    4c41:	53                   	push   %rbx
    4c42:	48 81 ec c8 00 00 00 	sub    $0xc8,%rsp
    4c49:	48 89 d1             	mov    %rdx,%rcx
    4c4c:	48 89 f2             	mov    %rsi,%rdx
    4c4f:	48 89 fb             	mov    %rdi,%rbx
    4c52:	49 89 e6             	mov    %rsp,%r14
    4c55:	6a 48                	push   $0x48
    4c57:	5e                   	pop    %rsi
    4c58:	6a 06                	push   $0x6
    4c5a:	41 58                	pop    %r8
    4c5c:	4c 89 f7             	mov    %r14,%rdi
    4c5f:	e8 f3 f3 ff ff       	call   4057 <keccak_absorb_once>
    4c64:	4c 89 f7             	mov    %r14,%rdi
    4c67:	e8 00 f7 ff ff       	call   436c <KeccakF1600_StatePermute>
    4c6c:	45 31 f6             	xor    %r14d,%r14d
    4c6f:	49 83 fe 40          	cmp    $0x40,%r14
    4c73:	74 13                	je     4c88 <pqcrystals_kyber_fips202_ref_sha3_512+0x49>
    4c75:	4a 8d 3c 33          	lea    (%rbx,%r14,1),%rdi
    4c79:	4a 8b 34 34          	mov    (%rsp,%r14,1),%rsi
    4c7d:	e8 a3 ff ff ff       	call   4c25 <store64>
    4c82:	49 83 c6 08          	add    $0x8,%r14
    4c86:	eb e7                	jmp    4c6f <pqcrystals_kyber_fips202_ref_sha3_512+0x30>
    4c88:	48 81 c4 c8 00 00 00 	add    $0xc8,%rsp
    4c8f:	5b                   	pop    %rbx
    4c90:	41 5e                	pop    %r14
    4c92:	c3                   	ret
    4c93:	90                   	nop

0000000000004c94 <pqcrystals_kyber768_ref_kyber_shake128_absorb>:
    4c94:	48 83 ec 28          	sub    $0x28,%rsp
    4c98:	0f 10 06             	movups (%rsi),%xmm0
    4c9b:	0f 10 4e 10          	movups 0x10(%rsi),%xmm1
    4c9f:	48 89 e6             	mov    %rsp,%rsi
    4ca2:	0f 29 4e 10          	movaps %xmm1,0x10(%rsi)
    4ca6:	0f 29 06             	movaps %xmm0,(%rsi)
    4ca9:	88 56 20             	mov    %dl,0x20(%rsi)
    4cac:	88 4e 21             	mov    %cl,0x21(%rsi)
    4caf:	6a 22                	push   $0x22
    4cb1:	5a                   	pop    %rdx
    4cb2:	e8 7c f3 ff ff       	call   4033 <pqcrystals_kyber_fips202_ref_shake128_absorb_once>
    4cb7:	48 83 c4 28          	add    $0x28,%rsp
    4cbb:	c3                   	ret

0000000000004cbc <pqcrystals_kyber768_ref_kyber_shake256_prf>:
    4cbc:	48 83 ec 28          	sub    $0x28,%rsp
    4cc0:	0f 10 02             	movups (%rdx),%xmm0
    4cc3:	0f 10 4a 10          	movups 0x10(%rdx),%xmm1
    4cc7:	48 89 e2             	mov    %rsp,%rdx
    4cca:	0f 29 4a 10          	movaps %xmm1,0x10(%rdx)
    4cce:	0f 29 02             	movaps %xmm0,(%rdx)
    4cd1:	88 4a 20             	mov    %cl,0x20(%rdx)
    4cd4:	6a 21                	push   $0x21
    4cd6:	59                   	pop    %rcx
    4cd7:	e8 ce f5 ff ff       	call   42aa <pqcrystals_kyber_fips202_ref_shake256>
    4cdc:	48 83 c4 28          	add    $0x28,%rsp
    4ce0:	c3                   	ret

Disassembly of section .fini:

0000000000004ce4 <_fini>:
    4ce4:	f3 0f 1e fa          	endbr64
    4ce8:	48 83 ec 08          	sub    $0x8,%rsp
    4cec:	48 83 c4 08          	add    $0x8,%rsp
    4cf0:	c3                   	ret
