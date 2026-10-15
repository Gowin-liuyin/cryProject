
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-ordinary/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000001340 <main>:
    1340:	55                   	push   %rbp
    1341:	41 57                	push   %r15
    1343:	41 56                	push   %r14
    1345:	41 55                	push   %r13
    1347:	41 54                	push   %r12
    1349:	53                   	push   %rbx
    134a:	48 81 ec 18 2a 00 00 	sub    $0x2a18,%rsp
    1351:	48 89 f3             	mov    %rsi,%rbx
    1354:	89 fd                	mov    %edi,%ebp
    1356:	83 ff 02             	cmp    $0x2,%edi
    1359:	74 10                	je     136b <main+0x2b>
    135b:	83 fd 01             	cmp    $0x1,%ebp
    135e:	0f 84 c0 0c 00 00    	je     2024 <main+0xce4>
    1364:	7f 37                	jg     139d <main+0x5d>
    1366:	e9 41 0c 00 00       	jmp    1fac <main+0xc6c>
    136b:	4c 8b 73 08          	mov    0x8(%rbx),%r14
    136f:	48 8d 35 aa 5c 00 00 	lea    0x5caa(%rip),%rsi        # 7020 <_IO_stdin_used+0x20>
    1376:	4c 89 f7             	mov    %r14,%rdi
    1379:	e8 f2 fd ff ff       	call   1170 <strcmp@plt>
    137e:	85 c0                	test   %eax,%eax
    1380:	0f 84 1d 04 00 00    	je     17a3 <main+0x463>
    1386:	48 8d 35 9a 5c 00 00 	lea    0x5c9a(%rip),%rsi        # 7027 <_IO_stdin_used+0x27>
    138d:	4c 89 f7             	mov    %r14,%rdi
    1390:	e8 db fd ff ff       	call   1170 <strcmp@plt>
    1395:	85 c0                	test   %eax,%eax
    1397:	0f 84 06 04 00 00    	je     17a3 <main+0x463>
    139d:	48 8d bc 24 38 01 00 	lea    0x138(%rsp),%rdi
    13a4:	00 
    13a5:	c7 44 24 20 00 00 00 	movl   $0x0,0x20(%rsp)
    13ac:	00 
    13ad:	ba d8 10 00 00       	mov    $0x10d8,%edx
    13b2:	31 f6                	xor    %esi,%esi
    13b4:	e8 57 fd ff ff       	call   1110 <memset@plt>
    13b9:	48 c7 84 24 60 01 00 	movq   $0x64,0x160(%rsp)
    13c0:	00 64 00 00 00 
    13c5:	41 89 ed             	mov    %ebp,%r13d
    13c8:	bd 01 00 00 00       	mov    $0x1,%ebp
    13cd:	4c 8d b4 24 10 14 00 	lea    0x1410(%rsp),%r14
    13d4:	00 
    13d5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%rsp)
    13dc:	00 
    13dd:	48 89 5c 24 28       	mov    %rbx,0x28(%rsp)
    13e2:	eb 1f                	jmp    1403 <main+0xc3>
    13e4:	b9 01 00 00 00       	mov    $0x1,%ecx
    13e9:	48 89 8c 24 48 01 00 	mov    %rcx,0x148(%rsp)
    13f0:	00 
    13f1:	48 8b 5c 24 28       	mov    0x28(%rsp),%rbx
    13f6:	48 83 c5 02          	add    $0x2,%rbp
    13fa:	4c 39 ed             	cmp    %r13,%rbp
    13fd:	0f 83 c7 03 00 00    	jae    17ca <main+0x48a>
    1403:	48 8d 45 01          	lea    0x1(%rbp),%rax
    1407:	4c 39 e8             	cmp    %r13,%rax
    140a:	0f 83 9c 0b 00 00    	jae    1fac <main+0xc6c>
    1410:	4c 8b 64 eb 08       	mov    0x8(%rbx,%rbp,8),%r12
    1415:	4d 85 e4             	test   %r12,%r12
    1418:	0f 84 8e 0b 00 00    	je     1fac <main+0xc6c>
    141e:	4c 8b 3c eb          	mov    (%rbx,%rbp,8),%r15
    1422:	4c 89 ff             	mov    %r15,%rdi
    1425:	48 8d 35 7b 60 00 00 	lea    0x607b(%rip),%rsi        # 74a7 <_IO_stdin_used+0x4a7>
    142c:	e8 3f fd ff ff       	call   1170 <strcmp@plt>
    1431:	85 c0                	test   %eax,%eax
    1433:	0f 84 f7 00 00 00    	je     1530 <main+0x1f0>
    1439:	4c 89 ff             	mov    %r15,%rdi
    143c:	48 8d 35 6c 60 00 00 	lea    0x606c(%rip),%rsi        # 74af <_IO_stdin_used+0x4af>
    1443:	e8 28 fd ff ff       	call   1170 <strcmp@plt>
    1448:	85 c0                	test   %eax,%eax
    144a:	0f 84 a0 02 00 00    	je     16f0 <main+0x3b0>
    1450:	4c 89 ff             	mov    %r15,%rdi
    1453:	48 8d 35 5f 60 00 00 	lea    0x605f(%rip),%rsi        # 74b9 <_IO_stdin_used+0x4b9>
    145a:	e8 11 fd ff ff       	call   1170 <strcmp@plt>
    145f:	85 c0                	test   %eax,%eax
    1461:	0f 84 cc 02 00 00    	je     1733 <main+0x3f3>
    1467:	4c 89 ff             	mov    %r15,%rdi
    146a:	48 8d 35 4f 60 00 00 	lea    0x604f(%rip),%rsi        # 74c0 <_IO_stdin_used+0x4c0>
    1471:	e8 fa fc ff ff       	call   1170 <strcmp@plt>
    1476:	85 c0                	test   %eax,%eax
    1478:	0f 84 da 02 00 00    	je     1758 <main+0x418>
    147e:	4c 89 ff             	mov    %r15,%rdi
    1481:	48 8d 35 3e 60 00 00 	lea    0x603e(%rip),%rsi        # 74c6 <_IO_stdin_used+0x4c6>
    1488:	e8 e3 fc ff ff       	call   1170 <strcmp@plt>
    148d:	85 c0                	test   %eax,%eax
    148f:	0f 84 da 02 00 00    	je     176f <main+0x42f>
    1495:	4c 89 ff             	mov    %r15,%rdi
    1498:	48 8d 35 2e 60 00 00 	lea    0x602e(%rip),%rsi        # 74cd <_IO_stdin_used+0x4cd>
    149f:	e8 cc fc ff ff       	call   1170 <strcmp@plt>
    14a4:	85 c0                	test   %eax,%eax
    14a6:	0f 84 d0 02 00 00    	je     177c <main+0x43c>
    14ac:	4c 89 ff             	mov    %r15,%rdi
    14af:	48 8d 35 24 60 00 00 	lea    0x6024(%rip),%rsi        # 74da <_IO_stdin_used+0x4da>
    14b6:	e8 b5 fc ff ff       	call   1170 <strcmp@plt>
    14bb:	85 c0                	test   %eax,%eax
    14bd:	0f 84 c6 02 00 00    	je     1789 <main+0x449>
    14c3:	4c 89 ff             	mov    %r15,%rdi
    14c6:	48 8d 35 1a 60 00 00 	lea    0x601a(%rip),%rsi        # 74e7 <_IO_stdin_used+0x4e7>
    14cd:	e8 9e fc ff ff       	call   1170 <strcmp@plt>
    14d2:	85 c0                	test   %eax,%eax
    14d4:	0f 84 bc 02 00 00    	je     1796 <main+0x456>
    14da:	4c 89 ff             	mov    %r15,%rdi
    14dd:	48 8d 35 0c 60 00 00 	lea    0x600c(%rip),%rsi        # 74f0 <_IO_stdin_used+0x4f0>
    14e4:	e8 87 fc ff ff       	call   1170 <strcmp@plt>
    14e9:	85 c0                	test   %eax,%eax
    14eb:	0f 85 bb 0a 00 00    	jne    1fac <main+0xc6c>
    14f1:	4c 89 e7             	mov    %r12,%rdi
    14f4:	48 8d b4 24 60 01 00 	lea    0x160(%rsp),%rsi
    14fb:	00 
    14fc:	e8 6f 29 00 00       	call   3e70 <parse_unsigned_integer>
    1501:	85 c0                	test   %eax,%eax
    1503:	0f 85 a3 0a 00 00    	jne    1fac <main+0xc6c>
    1509:	48 8b 84 24 60 01 00 	mov    0x160(%rsp),%rax
    1510:	00 
    1511:	48 c7 c1 ef d8 ff ff 	mov    $0xffffffffffffd8ef,%rcx
    1518:	48 01 c8             	add    %rcx,%rax
    151b:	48 3d f0 d8 ff ff    	cmp    $0xffffffffffffd8f0,%rax
    1521:	0f 83 cf fe ff ff    	jae    13f6 <main+0xb6>
    1527:	e9 80 0a 00 00       	jmp    1fac <main+0xc6c>
    152c:	0f 1f 40 00          	nopl   0x0(%rax)
    1530:	4c 89 e7             	mov    %r12,%rdi
    1533:	e8 78 fb ff ff       	call   10b0 <strlen@plt>
    1538:	48 3d a0 00 00 00    	cmp    $0xa0,%rax
    153e:	0f 83 68 0a 00 00    	jae    1fac <main+0xc6c>
    1544:	48 ff c0             	inc    %rax
    1547:	48 8d 9c 24 10 1a 00 	lea    0x1a10(%rsp),%rbx
    154e:	00 
    154f:	48 89 df             	mov    %rbx,%rdi
    1552:	4c 89 e6             	mov    %r12,%rsi
    1555:	48 89 c2             	mov    %rax,%rdx
    1558:	e8 43 fc ff ff       	call   11a0 <memcpy@plt>
    155d:	48 89 df             	mov    %rbx,%rdi
    1560:	be 2c 00 00 00       	mov    $0x2c,%esi
    1565:	e8 56 fb ff ff       	call   10c0 <strchr@plt>
    156a:	49 89 c7             	mov    %rax,%r15
    156d:	48 85 c0             	test   %rax,%rax
    1570:	74 04                	je     1576 <main+0x236>
    1572:	41 c6 07 00          	movb   $0x0,(%r15)
    1576:	80 bc 24 10 1a 00 00 	cmpb   $0x0,0x1a10(%rsp)
    157d:	00 
    157e:	0f 84 28 0a 00 00    	je     1fac <main+0xc6c>
    1584:	48 8d bc 24 10 1a 00 	lea    0x1a10(%rsp),%rdi
    158b:	00 
    158c:	4c 89 f6             	mov    %r14,%rsi
    158f:	e8 bc 2f 00 00       	call   4550 <m2_collector_parse_class>
    1594:	85 c0                	test   %eax,%eax
    1596:	0f 85 10 0a 00 00    	jne    1fac <main+0xc6c>
    159c:	8b 84 24 10 14 00 00 	mov    0x1410(%rsp),%eax
    15a3:	83 f8 01             	cmp    $0x1,%eax
    15a6:	0f 87 00 0a 00 00    	ja     1fac <main+0xc6c>
    15ac:	89 84 24 38 01 00 00 	mov    %eax,0x138(%rsp)
    15b3:	4d 85 ff             	test   %r15,%r15
    15b6:	0f 84 28 fe ff ff    	je     13e4 <main+0xa4>
    15bc:	49 ff c7             	inc    %r15
    15bf:	4c 89 ff             	mov    %r15,%rdi
    15c2:	be 2c 00 00 00       	mov    $0x2c,%esi
    15c7:	e8 f4 fa ff ff       	call   10c0 <strchr@plt>
    15cc:	49 89 c4             	mov    %rax,%r12
    15cf:	48 85 c0             	test   %rax,%rax
    15d2:	74 05                	je     15d9 <main+0x299>
    15d4:	41 c6 04 24 00       	movb   $0x0,(%r12)
    15d9:	41 80 3f 00          	cmpb   $0x0,(%r15)
    15dd:	0f 84 c9 09 00 00    	je     1fac <main+0xc6c>
    15e3:	4c 89 ff             	mov    %r15,%rdi
    15e6:	4c 89 f6             	mov    %r14,%rsi
    15e9:	e8 62 2f 00 00       	call   4550 <m2_collector_parse_class>
    15ee:	85 c0                	test   %eax,%eax
    15f0:	0f 85 b6 09 00 00    	jne    1fac <main+0xc6c>
    15f6:	8b 84 24 10 14 00 00 	mov    0x1410(%rsp),%eax
    15fd:	83 f8 01             	cmp    $0x1,%eax
    1600:	0f 87 a6 09 00 00    	ja     1fac <main+0xc6c>
    1606:	39 84 24 38 01 00 00 	cmp    %eax,0x138(%rsp)
    160d:	0f 84 99 09 00 00    	je     1fac <main+0xc6c>
    1613:	89 84 24 3c 01 00 00 	mov    %eax,0x13c(%rsp)
    161a:	4d 85 e4             	test   %r12,%r12
    161d:	0f 84 42 01 00 00    	je     1765 <main+0x425>
    1623:	bb 02 00 00 00       	mov    $0x2,%ebx
    1628:	eb 1d                	jmp    1647 <main+0x307>
    162a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    1630:	48 8d 4b 01          	lea    0x1(%rbx),%rcx
    1634:	89 84 9c 38 01 00 00 	mov    %eax,0x138(%rsp,%rbx,4)
    163b:	48 89 cb             	mov    %rcx,%rbx
    163e:	4d 85 e4             	test   %r12,%r12
    1641:	0f 84 a2 fd ff ff    	je     13e9 <main+0xa9>
    1647:	4d 89 e7             	mov    %r12,%r15
    164a:	49 ff c7             	inc    %r15
    164d:	4c 89 ff             	mov    %r15,%rdi
    1650:	be 2c 00 00 00       	mov    $0x2c,%esi
    1655:	e8 66 fa ff ff       	call   10c0 <strchr@plt>
    165a:	49 89 c4             	mov    %rax,%r12
    165d:	48 85 c0             	test   %rax,%rax
    1660:	74 05                	je     1667 <main+0x327>
    1662:	41 c6 04 24 00       	movb   $0x0,(%r12)
    1667:	41 80 3f 00          	cmpb   $0x0,(%r15)
    166b:	0f 84 3b 09 00 00    	je     1fac <main+0xc6c>
    1671:	48 83 fb 03          	cmp    $0x3,%rbx
    1675:	0f 87 31 09 00 00    	ja     1fac <main+0xc6c>
    167b:	4c 89 ff             	mov    %r15,%rdi
    167e:	4c 89 f6             	mov    %r14,%rsi
    1681:	e8 ca 2e 00 00       	call   4550 <m2_collector_parse_class>
    1686:	85 c0                	test   %eax,%eax
    1688:	0f 85 1e 09 00 00    	jne    1fac <main+0xc6c>
    168e:	8b 84 24 10 14 00 00 	mov    0x1410(%rsp),%eax
    1695:	83 f8 01             	cmp    $0x1,%eax
    1698:	0f 87 0e 09 00 00    	ja     1fac <main+0xc6c>
    169e:	39 84 24 38 01 00 00 	cmp    %eax,0x138(%rsp)
    16a5:	0f 84 01 09 00 00    	je     1fac <main+0xc6c>
    16ab:	39 84 24 3c 01 00 00 	cmp    %eax,0x13c(%rsp)
    16b2:	0f 84 f4 08 00 00    	je     1fac <main+0xc6c>
    16b8:	48 83 fb 02          	cmp    $0x2,%rbx
    16bc:	0f 84 6e ff ff ff    	je     1630 <main+0x2f0>
    16c2:	39 84 24 40 01 00 00 	cmp    %eax,0x140(%rsp)
    16c9:	0f 84 dd 08 00 00    	je     1fac <main+0xc6c>
    16cf:	48 83 fb 03          	cmp    $0x3,%rbx
    16d3:	0f 84 57 ff ff ff    	je     1630 <main+0x2f0>
    16d9:	39 84 24 44 01 00 00 	cmp    %eax,0x144(%rsp)
    16e0:	0f 85 4a ff ff ff    	jne    1630 <main+0x2f0>
    16e6:	e9 c1 08 00 00       	jmp    1fac <main+0xc6c>
    16eb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
    16f0:	4c 89 e7             	mov    %r12,%rdi
    16f3:	48 8d b4 24 50 01 00 	lea    0x150(%rsp),%rsi
    16fa:	00 
    16fb:	e8 70 27 00 00       	call   3e70 <parse_unsigned_integer>
    1700:	85 c0                	test   %eax,%eax
    1702:	0f 85 a4 08 00 00    	jne    1fac <main+0xc6c>
    1708:	48 8b 84 24 50 01 00 	mov    0x150(%rsp),%rax
    170f:	00 
    1710:	48 c7 c1 df b1 ff ff 	mov    $0xffffffffffffb1df,%rcx
    1717:	48 01 c8             	add    %rcx,%rax
    171a:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%rsp)
    1721:	00 
    1722:	48 3d e0 b1 ff ff    	cmp    $0xffffffffffffb1e0,%rax
    1728:	0f 83 c8 fc ff ff    	jae    13f6 <main+0xb6>
    172e:	e9 79 08 00 00       	jmp    1fac <main+0xc6c>
    1733:	4c 89 e7             	mov    %r12,%rdi
    1736:	48 8d b4 24 58 01 00 	lea    0x158(%rsp),%rsi
    173d:	00 
    173e:	e8 2d 27 00 00       	call   3e70 <parse_unsigned_integer>
    1743:	c7 44 24 20 01 00 00 	movl   $0x1,0x20(%rsp)
    174a:	00 
    174b:	85 c0                	test   %eax,%eax
    174d:	0f 84 a3 fc ff ff    	je     13f6 <main+0xb6>
    1753:	e9 54 08 00 00       	jmp    1fac <main+0xc6c>
    1758:	4c 89 a4 24 68 01 00 	mov    %r12,0x168(%rsp)
    175f:	00 
    1760:	e9 91 fc ff ff       	jmp    13f6 <main+0xb6>
    1765:	b9 02 00 00 00       	mov    $0x2,%ecx
    176a:	e9 7a fc ff ff       	jmp    13e9 <main+0xa9>
    176f:	4c 89 a4 24 70 01 00 	mov    %r12,0x170(%rsp)
    1776:	00 
    1777:	e9 7a fc ff ff       	jmp    13f6 <main+0xb6>
    177c:	4c 89 a4 24 78 01 00 	mov    %r12,0x178(%rsp)
    1783:	00 
    1784:	e9 6d fc ff ff       	jmp    13f6 <main+0xb6>
    1789:	4c 89 a4 24 80 01 00 	mov    %r12,0x180(%rsp)
    1790:	00 
    1791:	e9 60 fc ff ff       	jmp    13f6 <main+0xb6>
    1796:	4c 89 a4 24 88 01 00 	mov    %r12,0x188(%rsp)
    179d:	00 
    179e:	e9 53 fc ff ff       	jmp    13f6 <main+0xb6>
    17a3:	48 8b 05 16 98 00 00 	mov    0x9816(%rip),%rax        # afc0 <stdout@GLIBC_2.2.5>
    17aa:	48 8b 08             	mov    (%rax),%rcx
    17ad:	48 8d 3d d7 5a 00 00 	lea    0x5ad7(%rip),%rdi        # 728b <_IO_stdin_used+0x28b>
    17b4:	be 1b 02 00 00       	mov    $0x21b,%esi
    17b9:	ba 01 00 00 00       	mov    $0x1,%edx
    17be:	e8 6d fa ff ff       	call   1230 <fwrite@plt>
    17c3:	31 c0                	xor    %eax,%eax
    17c5:	e9 d0 13 00 00       	jmp    2b9a <main+0x185a>
    17ca:	83 7c 24 20 00       	cmpl   $0x0,0x20(%rsp)
    17cf:	0f 84 d7 07 00 00    	je     1fac <main+0xc6c>
    17d5:	83 7c 24 08 00       	cmpl   $0x0,0x8(%rsp)
    17da:	0f 84 cc 07 00 00    	je     1fac <main+0xc6c>
    17e0:	48 83 bc 24 48 01 00 	cmpq   $0x0,0x148(%rsp)
    17e7:	00 00 
    17e9:	0f 84 bd 07 00 00    	je     1fac <main+0xc6c>
    17ef:	48 83 bc 24 68 01 00 	cmpq   $0x0,0x168(%rsp)
    17f6:	00 00 
    17f8:	0f 84 ae 07 00 00    	je     1fac <main+0xc6c>
    17fe:	48 83 bc 24 78 01 00 	cmpq   $0x0,0x178(%rsp)
    1805:	00 00 
    1807:	0f 84 9f 07 00 00    	je     1fac <main+0xc6c>
    180d:	48 83 bc 24 80 01 00 	cmpq   $0x0,0x180(%rsp)
    1814:	00 00 
    1816:	0f 84 90 07 00 00    	je     1fac <main+0xc6c>
    181c:	48 8b 9c 24 88 01 00 	mov    0x188(%rsp),%rbx
    1823:	00 
    1824:	48 85 db             	test   %rbx,%rbx
    1827:	75 37                	jne    1860 <main+0x520>
    1829:	48 8d 9c 24 90 11 00 	lea    0x1190(%rsp),%rbx
    1830:	00 
    1831:	48 8b 8c 24 58 01 00 	mov    0x158(%rsp),%rcx
    1838:	00 
    1839:	48 8d 15 b9 5c 00 00 	lea    0x5cb9(%rip),%rdx        # 74f9 <_IO_stdin_used+0x4f9>
    1840:	be 80 00 00 00       	mov    $0x80,%esi
    1845:	48 89 df             	mov    %rbx,%rdi
    1848:	31 c0                	xor    %eax,%eax
    184a:	e8 91 f8 ff ff       	call   10e0 <snprintf@plt>
    184f:	83 f8 7f             	cmp    $0x7f,%eax
    1852:	0f 87 54 07 00 00    	ja     1fac <main+0xc6c>
    1858:	48 89 9c 24 88 01 00 	mov    %rbx,0x188(%rsp)
    185f:	00 
    1860:	48 89 df             	mov    %rbx,%rdi
    1863:	e8 48 f8 ff ff       	call   10b0 <strlen@plt>
    1868:	48 83 f8 7f          	cmp    $0x7f,%rax
    186c:	0f 87 3a 07 00 00    	ja     1fac <main+0xc6c>
    1872:	48 89 df             	mov    %rbx,%rdi
    1875:	e8 36 1d 00 00       	call   35b0 <is_valid_run_id>
    187a:	85 c0                	test   %eax,%eax
    187c:	0f 84 2a 07 00 00    	je     1fac <main+0xc6c>
    1882:	48 83 bc 24 70 01 00 	cmpq   $0x0,0x170(%rsp)
    1889:	00 00 
    188b:	75 39                	jne    18c6 <main+0x586>
    188d:	48 8d 9c 24 90 01 00 	lea    0x190(%rsp),%rbx
    1894:	00 
    1895:	48 8b 8c 24 68 01 00 	mov    0x168(%rsp),%rcx
    189c:	00 
    189d:	48 8d 15 68 5c 00 00 	lea    0x5c68(%rip),%rdx        # 750c <_IO_stdin_used+0x50c>
    18a4:	be 00 10 00 00       	mov    $0x1000,%esi
    18a9:	48 89 df             	mov    %rbx,%rdi
    18ac:	31 c0                	xor    %eax,%eax
    18ae:	e8 2d f8 ff ff       	call   10e0 <snprintf@plt>
    18b3:	3d ff 0f 00 00       	cmp    $0xfff,%eax
    18b8:	0f 87 ee 06 00 00    	ja     1fac <main+0xc6c>
    18be:	48 89 9c 24 70 01 00 	mov    %rbx,0x170(%rsp)
    18c5:	00 
    18c6:	48 8d b4 24 10 1a 00 	lea    0x1a10(%rsp),%rsi
    18cd:	00 
    18ce:	bf 01 00 00 00       	mov    $0x1,%edi
    18d3:	e8 08 f9 ff ff       	call   11e0 <clock_getres@plt>
    18d8:	85 c0                	test   %eax,%eax
    18da:	0f 85 47 0b 00 00    	jne    2427 <main+0x10e7>
    18e0:	48 8b 84 24 10 1a 00 	mov    0x1a10(%rsp),%rax
    18e7:	00 
    18e8:	48 85 c0             	test   %rax,%rax
    18eb:	0f 88 36 0b 00 00    	js     2427 <main+0x10e7>
    18f1:	48 8b 8c 24 18 1a 00 	mov    0x1a18(%rsp),%rcx
    18f8:	00 
    18f9:	48 85 c9             	test   %rcx,%rcx
    18fc:	0f 88 25 0b 00 00    	js     2427 <main+0x10e7>
    1902:	48 69 c0 00 ca 9a 3b 	imul   $0x3b9aca00,%rax,%rax
    1909:	48 01 c8             	add    %rcx,%rax
    190c:	0f 84 2d 0b 00 00    	je     243f <main+0x10ff>
    1912:	48 89 84 24 90 00 00 	mov    %rax,0x90(%rsp)
    1919:	00 
    191a:	4c 8b ac 24 50 01 00 	mov    0x150(%rsp),%r13
    1921:	00 
    1922:	4c 0f af ac 24 48 01 	imul   0x148(%rsp),%r13
    1929:	00 00 
    192b:	bf a0 04 00 00       	mov    $0x4a0,%edi
    1930:	e8 8b f8 ff ff       	call   11c0 <malloc@plt>
    1935:	48 89 44 24 20       	mov    %rax,0x20(%rsp)
    193a:	bf 60 09 00 00       	mov    $0x960,%edi
    193f:	e8 7c f8 ff ff       	call   11c0 <malloc@plt>
    1944:	49 89 c6             	mov    %rax,%r14
    1947:	bf 00 11 00 00       	mov    $0x1100,%edi
    194c:	e8 6f f8 ff ff       	call   11c0 <malloc@plt>
    1951:	48 89 44 24 08       	mov    %rax,0x8(%rsp)
    1956:	49 69 fd 40 04 00 00 	imul   $0x440,%r13,%rdi
    195d:	e8 5e f8 ff ff       	call   11c0 <malloc@plt>
    1962:	48 89 44 24 10       	mov    %rax,0x10(%rsp)
    1967:	bf 00 08 00 00       	mov    $0x800,%edi
    196c:	e8 4f f8 ff ff       	call   11c0 <malloc@plt>
    1971:	49 89 c4             	mov    %rax,%r12
    1974:	4c 89 ef             	mov    %r13,%rdi
    1977:	48 c1 e7 09          	shl    $0x9,%rdi
    197b:	48 89 bc 24 98 00 00 	mov    %rdi,0x98(%rsp)
    1982:	00 
    1983:	e8 38 f8 ff ff       	call   11c0 <malloc@plt>
    1988:	48 89 c3             	mov    %rax,%rbx
    198b:	4a 8d 3c ad 00 00 00 	lea    0x0(,%r13,4),%rdi
    1992:	00 
    1993:	e8 28 f8 ff ff       	call   11c0 <malloc@plt>
    1998:	48 89 c5             	mov    %rax,%rbp
    199b:	4c 89 ef             	mov    %r13,%rdi
    199e:	48 c1 e7 05          	shl    $0x5,%rdi
    19a2:	e8 19 f8 ff ff       	call   11c0 <malloc@plt>
    19a7:	49 89 c7             	mov    %rax,%r15
    19aa:	4c 89 6c 24 40       	mov    %r13,0x40(%rsp)
    19af:	4a 8d 3c ed 00 00 00 	lea    0x0(,%r13,8),%rdi
    19b6:	00 
    19b7:	49 89 dd             	mov    %rbx,%r13
    19ba:	e8 01 f8 ff ff       	call   11c0 <malloc@plt>
    19bf:	4c 89 7c 24 78       	mov    %r15,0x78(%rsp)
    19c4:	66 49 0f 6e c7       	movq   %r15,%xmm0
    19c9:	49 89 c7             	mov    %rax,%r15
    19cc:	66 48 0f 6e c8       	movq   %rax,%xmm1
    19d1:	66 0f 6c c1          	punpcklqdq %xmm1,%xmm0
    19d5:	4c 89 74 24 48       	mov    %r14,0x48(%rsp)
    19da:	66 49 0f 6e ee       	movq   %r14,%xmm5
    19df:	4c 89 64 24 28       	mov    %r12,0x28(%rsp)
    19e4:	66 49 0f 6e cc       	movq   %r12,%xmm1
    19e9:	4c 8b 64 24 10       	mov    0x10(%rsp),%r12
    19ee:	66 0f 6c e9          	punpcklqdq %xmm1,%xmm5
    19f2:	66 49 0f 6e cc       	movq   %r12,%xmm1
    19f7:	48 89 6c 24 38       	mov    %rbp,0x38(%rsp)
    19fc:	66 48 0f 6e d5       	movq   %rbp,%xmm2
    1a01:	48 8b 6c 24 08       	mov    0x8(%rsp),%rbp
    1a06:	66 0f 6c ca          	punpcklqdq %xmm2,%xmm1
    1a0a:	f3 0f 7e 54 24 20    	movq   0x20(%rsp),%xmm2
    1a10:	66 48 0f 6e dd       	movq   %rbp,%xmm3
    1a15:	66 0f 6c da          	punpcklqdq %xmm2,%xmm3
    1a19:	66 0f ef d2          	pxor   %xmm2,%xmm2
    1a1d:	66 0f 76 da          	pcmpeqd %xmm2,%xmm3
    1a21:	66 0f 70 e3 b1       	pshufd $0xb1,%xmm3,%xmm4
    1a26:	66 0f db e3          	pand   %xmm3,%xmm4
    1a2a:	66 0f 76 ca          	pcmpeqd %xmm2,%xmm1
    1a2e:	66 0f 70 d9 b1       	pshufd $0xb1,%xmm1,%xmm3
    1a33:	66 0f db d9          	pand   %xmm1,%xmm3
    1a37:	66 0f 6b e3          	packssdw %xmm3,%xmm4
    1a3b:	66 0f 7f ac 24 a0 00 	movdqa %xmm5,0xa0(%rsp)
    1a42:	00 00 
    1a44:	66 0f 6f cd          	movdqa %xmm5,%xmm1
    1a48:	66 0f 76 ca          	pcmpeqd %xmm2,%xmm1
    1a4c:	66 0f 70 d9 b1       	pshufd $0xb1,%xmm1,%xmm3
    1a51:	66 0f db d9          	pand   %xmm1,%xmm3
    1a55:	66 0f 76 c2          	pcmpeqd %xmm2,%xmm0
    1a59:	66 0f 70 c8 b1       	pshufd $0xb1,%xmm0,%xmm1
    1a5e:	66 0f db c8          	pand   %xmm0,%xmm1
    1a62:	66 0f 6b cb          	packssdw %xmm3,%xmm1
    1a66:	66 0f 6b e1          	packssdw %xmm1,%xmm4
    1a6a:	66 0f d7 c4          	pmovmskb %xmm4,%eax
    1a6e:	a9 aa aa 00 00       	test   $0xaaaa,%eax
    1a73:	0f 85 f0 09 00 00    	jne    2469 <main+0x1129>
    1a79:	4d 85 ed             	test   %r13,%r13
    1a7c:	0f 84 e7 09 00 00    	je     2469 <main+0x1129>
    1a82:	48 8b bc 24 78 01 00 	mov    0x178(%rsp),%rdi
    1a89:	00 
    1a8a:	48 8d 1d f8 55 00 00 	lea    0x55f8(%rip),%rbx        # 7089 <_IO_stdin_used+0x89>
    1a91:	48 85 ff             	test   %rdi,%rdi
    1a94:	0f 84 5d 05 00 00    	je     1ff7 <main+0xcb7>
    1a9a:	48 8d 35 73 5a 00 00 	lea    0x5a73(%rip),%rsi        # 7514 <_IO_stdin_used+0x514>
    1aa1:	e8 6a f7 ff ff       	call   1210 <fopen@plt>
    1aa6:	48 85 c0             	test   %rax,%rax
    1aa9:	0f 84 48 05 00 00    	je     1ff7 <main+0xcb7>
    1aaf:	49 89 c6             	mov    %rax,%r14
    1ab2:	be 01 00 00 00       	mov    $0x1,%esi
    1ab7:	ba a0 04 00 00       	mov    $0x4a0,%edx
    1abc:	48 8b 7c 24 20       	mov    0x20(%rsp),%rdi
    1ac1:	48 89 c1             	mov    %rax,%rcx
    1ac4:	e8 a7 f5 ff ff       	call   1070 <fread@plt>
    1ac9:	48 8d 1d b9 55 00 00 	lea    0x55b9(%rip),%rbx        # 7089 <_IO_stdin_used+0x89>
    1ad0:	48 3d a0 04 00 00    	cmp    $0x4a0,%rax
    1ad6:	0f 85 13 05 00 00    	jne    1fef <main+0xcaf>
    1adc:	4c 89 f7             	mov    %r14,%rdi
    1adf:	e8 3c f6 ff ff       	call   1120 <fgetc@plt>
    1ae4:	83 f8 ff             	cmp    $0xffffffff,%eax
    1ae7:	0f 85 02 05 00 00    	jne    1fef <main+0xcaf>
    1aed:	4c 89 f7             	mov    %r14,%rdi
    1af0:	e8 6b f5 ff ff       	call   1060 <ferror@plt>
    1af5:	85 c0                	test   %eax,%eax
    1af7:	0f 85 f2 04 00 00    	jne    1fef <main+0xcaf>
    1afd:	4c 89 f7             	mov    %r14,%rdi
    1b00:	e8 9b f5 ff ff       	call   10a0 <fclose@plt>
    1b05:	85 c0                	test   %eax,%eax
    1b07:	0f 85 9f 10 00 00    	jne    2bac <main+0x186c>
    1b0d:	48 8b bc 24 80 01 00 	mov    0x180(%rsp),%rdi
    1b14:	00 
    1b15:	48 8d 1d b4 55 00 00 	lea    0x55b4(%rip),%rbx        # 70d0 <_IO_stdin_used+0xd0>
    1b1c:	48 85 ff             	test   %rdi,%rdi
    1b1f:	0f 84 d2 04 00 00    	je     1ff7 <main+0xcb7>
    1b25:	48 8d 35 e8 59 00 00 	lea    0x59e8(%rip),%rsi        # 7514 <_IO_stdin_used+0x514>
    1b2c:	e8 df f6 ff ff       	call   1210 <fopen@plt>
    1b31:	48 85 c0             	test   %rax,%rax
    1b34:	0f 84 bd 04 00 00    	je     1ff7 <main+0xcb7>
    1b3a:	49 89 c6             	mov    %rax,%r14
    1b3d:	be 01 00 00 00       	mov    $0x1,%esi
    1b42:	ba 60 09 00 00       	mov    $0x960,%edx
    1b47:	48 8b 7c 24 48       	mov    0x48(%rsp),%rdi
    1b4c:	48 89 c1             	mov    %rax,%rcx
    1b4f:	e8 1c f5 ff ff       	call   1070 <fread@plt>
    1b54:	48 8d 1d 75 55 00 00 	lea    0x5575(%rip),%rbx        # 70d0 <_IO_stdin_used+0xd0>
    1b5b:	48 3d 60 09 00 00    	cmp    $0x960,%rax
    1b61:	0f 85 88 04 00 00    	jne    1fef <main+0xcaf>
    1b67:	4c 89 f7             	mov    %r14,%rdi
    1b6a:	e8 b1 f5 ff ff       	call   1120 <fgetc@plt>
    1b6f:	83 f8 ff             	cmp    $0xffffffff,%eax
    1b72:	0f 85 77 04 00 00    	jne    1fef <main+0xcaf>
    1b78:	4c 89 f7             	mov    %r14,%rdi
    1b7b:	e8 e0 f4 ff ff       	call   1060 <ferror@plt>
    1b80:	85 c0                	test   %eax,%eax
    1b82:	0f 85 67 04 00 00    	jne    1fef <main+0xcaf>
    1b88:	4c 89 f7             	mov    %r14,%rdi
    1b8b:	e8 10 f5 ff ff       	call   10a0 <fclose@plt>
    1b90:	85 c0                	test   %eax,%eax
    1b92:	0f 85 20 10 00 00    	jne    2bb8 <main+0x1878>
    1b98:	4c 89 7c 24 30       	mov    %r15,0x30(%rsp)
    1b9d:	4c 89 6c 24 18       	mov    %r13,0x18(%rsp)
    1ba2:	48 8d bc 24 10 01 00 	lea    0x110(%rsp),%rdi
    1ba9:	00 
    1baa:	ba a0 04 00 00       	mov    $0x4a0,%edx
    1baf:	48 8b 74 24 20       	mov    0x20(%rsp),%rsi
    1bb4:	e8 47 20 00 00       	call   3c00 <platform_m2_sha3_256>
    1bb9:	48 8d bc 24 f0 00 00 	lea    0xf0(%rsp),%rdi
    1bc0:	00 
    1bc1:	ba 60 09 00 00       	mov    $0x960,%edx
    1bc6:	48 8b 74 24 48       	mov    0x48(%rsp),%rsi
    1bcb:	e8 30 20 00 00       	call   3c00 <platform_m2_sha3_256>
    1bd0:	48 83 bc 24 48 01 00 	cmpq   $0x0,0x148(%rsp)
    1bd7:	00 00 
    1bd9:	0f 84 3e 04 00 00    	je     201d <main+0xcdd>
    1bdf:	31 db                	xor    %ebx,%ebx
    1be1:	4c 8d b4 24 10 1a 00 	lea    0x1a10(%rsp),%r14
    1be8:	00 
    1be9:	4c 8d a4 24 10 12 00 	lea    0x1210(%rsp),%r12
    1bf0:	00 
    1bf1:	4c 8d bc 24 10 14 00 	lea    0x1410(%rsp),%r15
    1bf8:	00 
    1bf9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    1c00:	44 8b ac 9c 38 01 00 	mov    0x138(%rsp,%rbx,4),%r13d
    1c07:	00 
    1c08:	49 69 ed 40 04 00 00 	imul   $0x440,%r13,%rbp
    1c0f:	48 03 6c 24 08       	add    0x8(%rsp),%rbp
    1c14:	44 89 ef             	mov    %r13d,%edi
    1c17:	48 8b 74 24 20       	mov    0x20(%rsp),%rsi
    1c1c:	48 89 ea             	mov    %rbp,%rdx
    1c1f:	48 8d 8c 24 b0 00 00 	lea    0xb0(%rsp),%rcx
    1c26:	00 
    1c27:	e8 c4 29 00 00       	call   45f0 <m2_collector_build_ciphertext>
    1c2c:	85 c0                	test   %eax,%eax
    1c2e:	0f 85 d5 0f 00 00    	jne    2c09 <main+0x18c9>
    1c34:	be 20 00 00 00       	mov    $0x20,%esi
    1c39:	48 8d bc 24 b0 00 00 	lea    0xb0(%rsp),%rdi
    1c40:	00 
    1c41:	e8 8a 26 00 00       	call   42d0 <erase_secret_bytes>
    1c46:	49 c1 e5 09          	shl    $0x9,%r13
    1c4a:	4c 03 6c 24 28       	add    0x28(%rsp),%r13
    1c4f:	4c 89 f7             	mov    %r14,%rdi
    1c52:	48 89 ee             	mov    %rbp,%rsi
    1c55:	e8 3b 38 00 00       	call   5495 <pqcrystals_kyber768_ref_polyvec_decompress>
    1c5a:	48 81 c5 c0 03 00 00 	add    $0x3c0,%rbp
    1c61:	4c 89 e7             	mov    %r12,%rdi
    1c64:	48 89 ee             	mov    %rbp,%rsi
    1c67:	e8 5f 34 00 00       	call   50cb <pqcrystals_kyber768_ref_poly_decompress>
    1c6c:	4c 89 ff             	mov    %r15,%rdi
    1c6f:	48 8b 74 24 48       	mov    0x48(%rsp),%rsi
    1c74:	e8 1a 39 00 00       	call   5593 <pqcrystals_kyber768_ref_polyvec_frombytes>
    1c79:	4c 89 f7             	mov    %r14,%rdi
    1c7c:	e8 4b 39 00 00       	call   55cc <pqcrystals_kyber768_ref_polyvec_ntt>
    1c81:	4c 89 ef             	mov    %r13,%rdi
    1c84:	4c 89 fe             	mov    %r15,%rsi
    1c87:	4c 89 f2             	mov    %r14,%rdx
    1c8a:	e8 97 39 00 00       	call   5626 <pqcrystals_kyber768_ref_polyvec_basemul_acc_montgomery>
    1c8f:	4c 89 ef             	mov    %r13,%rdi
    1c92:	e8 4b 36 00 00       	call   52e2 <pqcrystals_kyber768_ref_poly_invntt_tomont>
    1c97:	4c 89 ef             	mov    %r13,%rdi
    1c9a:	4c 89 e6             	mov    %r12,%rsi
    1c9d:	4c 89 ea             	mov    %r13,%rdx
    1ca0:	e8 11 37 00 00       	call   53b6 <pqcrystals_kyber768_ref_poly_sub>
    1ca5:	4c 89 ef             	mov    %r13,%rdi
    1ca8:	e8 06 36 00 00       	call   52b3 <pqcrystals_kyber768_ref_poly_reduce>
    1cad:	be 00 06 00 00       	mov    $0x600,%esi
    1cb2:	4c 89 ff             	mov    %r15,%rdi
    1cb5:	e8 16 26 00 00       	call   42d0 <erase_secret_bytes>
    1cba:	48 ff c3             	inc    %rbx
    1cbd:	48 8b 84 24 48 01 00 	mov    0x148(%rsp),%rax
    1cc4:	00 
    1cc5:	48 39 c3             	cmp    %rax,%rbx
    1cc8:	0f 82 32 ff ff ff    	jb     1c00 <main+0x8c0>
    1cce:	45 31 ed             	xor    %r13d,%r13d
    1cd1:	48 85 c0             	test   %rax,%rax
    1cd4:	0f 84 56 03 00 00    	je     2030 <main+0xcf0>
    1cda:	4c 8d 74 24 50       	lea    0x50(%rsp),%r14
    1cdf:	45 31 ff             	xor    %r15d,%r15d
    1ce2:	48 8b 6c 24 08       	mov    0x8(%rsp),%rbp
    1ce7:	4c 8b 64 24 28       	mov    0x28(%rsp),%r12
    1cec:	0f 1f 40 00          	nopl   0x0(%rax)
    1cf0:	42 8b 9c bc 38 01 00 	mov    0x138(%rsp,%r15,4),%ebx
    1cf7:	00 
    1cf8:	48 89 de             	mov    %rbx,%rsi
    1cfb:	48 c1 e6 09          	shl    $0x9,%rsi
    1cff:	4c 01 e6             	add    %r12,%rsi
    1d02:	4c 89 f7             	mov    %r14,%rdi
    1d05:	e8 d0 34 00 00       	call   51da <pqcrystals_kyber768_ref_poly_tomsg>
    1d0a:	48 f7 db             	neg    %rbx
    1d0d:	b8 00 00 00 00       	mov    $0x0,%eax
    1d12:	19 c0                	sbb    %eax,%eax
    1d14:	66 0f 6e c0          	movd   %eax,%xmm0
    1d18:	66 0f 60 c0          	punpcklbw %xmm0,%xmm0
    1d1c:	66 49 0f 6e d5       	movq   %r13,%xmm2
    1d21:	66 0f 6f 4c 24 50    	movdqa 0x50(%rsp),%xmm1
    1d27:	66 0f 74 c8          	pcmpeqb %xmm0,%xmm1
    1d2b:	66 0f 76 ed          	pcmpeqd %xmm5,%xmm5
    1d2f:	66 0f ef cd          	pxor   %xmm5,%xmm1
    1d33:	66 0f 60 c9          	punpcklbw %xmm1,%xmm1
    1d37:	f2 0f 70 c9 d4       	pshuflw $0xd4,%xmm1,%xmm1
    1d3c:	66 0f 70 c9 d4       	pshufd $0xd4,%xmm1,%xmm1
    1d41:	66 0f 6f 35 c7 52 00 	movdqa 0x52c7(%rip),%xmm6        # 7010 <_IO_stdin_used+0x10>
    1d48:	00 
    1d49:	66 0f db ce          	pand   %xmm6,%xmm1
    1d4d:	0f b7 44 24 52       	movzwl 0x52(%rsp),%eax
    1d52:	66 0f 6e d8          	movd   %eax,%xmm3
    1d56:	66 0f 74 d8          	pcmpeqb %xmm0,%xmm3
    1d5a:	66 0f ef dd          	pxor   %xmm5,%xmm3
    1d5e:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    1d62:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    1d67:	66 0f 70 db d4       	pshufd $0xd4,%xmm3,%xmm3
    1d6c:	66 0f db de          	pand   %xmm6,%xmm3
    1d70:	66 0f d4 da          	paddq  %xmm2,%xmm3
    1d74:	66 0f 6e 54 24 54    	movd   0x54(%rsp),%xmm2
    1d7a:	66 0f 74 d0          	pcmpeqb %xmm0,%xmm2
    1d7e:	66 0f ef d5          	pxor   %xmm5,%xmm2
    1d82:	66 0f 60 d2          	punpcklbw %xmm2,%xmm2
    1d86:	f2 0f 70 d2 d4       	pshuflw $0xd4,%xmm2,%xmm2
    1d8b:	66 0f 70 d2 d4       	pshufd $0xd4,%xmm2,%xmm2
    1d90:	66 0f db d6          	pand   %xmm6,%xmm2
    1d94:	66 0f d4 d3          	paddq  %xmm3,%xmm2
    1d98:	0f b7 44 24 56       	movzwl 0x56(%rsp),%eax
    1d9d:	66 0f 6e d8          	movd   %eax,%xmm3
    1da1:	66 0f 74 d8          	pcmpeqb %xmm0,%xmm3
    1da5:	66 0f ef dd          	pxor   %xmm5,%xmm3
    1da9:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    1dad:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    1db2:	66 0f 70 db d4       	pshufd $0xd4,%xmm3,%xmm3
    1db7:	66 0f db de          	pand   %xmm6,%xmm3
    1dbb:	66 0f d4 da          	paddq  %xmm2,%xmm3
    1dbf:	f3 0f 7e 54 24 58    	movq   0x58(%rsp),%xmm2
    1dc5:	66 0f 74 d0          	pcmpeqb %xmm0,%xmm2
    1dc9:	66 0f ef d5          	pxor   %xmm5,%xmm2
    1dcd:	66 0f 60 d2          	punpcklbw %xmm2,%xmm2
    1dd1:	f2 0f 70 d2 d4       	pshuflw $0xd4,%xmm2,%xmm2
    1dd6:	66 0f 70 e2 d4       	pshufd $0xd4,%xmm2,%xmm4
    1ddb:	66 0f db e6          	pand   %xmm6,%xmm4
    1ddf:	66 0f d4 e3          	paddq  %xmm3,%xmm4
    1de3:	0f b7 44 24 5a       	movzwl 0x5a(%rsp),%eax
    1de8:	66 0f 6e d0          	movd   %eax,%xmm2
    1dec:	66 0f 74 d0          	pcmpeqb %xmm0,%xmm2
    1df0:	66 0f ef d5          	pxor   %xmm5,%xmm2
    1df4:	66 0f 60 d2          	punpcklbw %xmm2,%xmm2
    1df8:	f2 0f 70 d2 d4       	pshuflw $0xd4,%xmm2,%xmm2
    1dfd:	66 0f 70 d2 d4       	pshufd $0xd4,%xmm2,%xmm2
    1e02:	66 0f db d6          	pand   %xmm6,%xmm2
    1e06:	66 0f d4 d4          	paddq  %xmm4,%xmm2
    1e0a:	66 0f d4 d1          	paddq  %xmm1,%xmm2
    1e0e:	66 0f 6e 4c 24 5c    	movd   0x5c(%rsp),%xmm1
    1e14:	66 0f 74 c8          	pcmpeqb %xmm0,%xmm1
    1e18:	66 0f ef cd          	pxor   %xmm5,%xmm1
    1e1c:	66 0f 60 c9          	punpcklbw %xmm1,%xmm1
    1e20:	f2 0f 70 c9 d4       	pshuflw $0xd4,%xmm1,%xmm1
    1e25:	66 0f 70 c9 d4       	pshufd $0xd4,%xmm1,%xmm1
    1e2a:	66 0f db ce          	pand   %xmm6,%xmm1
    1e2e:	0f b7 44 24 5e       	movzwl 0x5e(%rsp),%eax
    1e33:	66 0f 6e d8          	movd   %eax,%xmm3
    1e37:	66 0f 74 d8          	pcmpeqb %xmm0,%xmm3
    1e3b:	66 0f ef dd          	pxor   %xmm5,%xmm3
    1e3f:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    1e43:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    1e48:	66 0f 70 db d4       	pshufd $0xd4,%xmm3,%xmm3
    1e4d:	66 0f db de          	pand   %xmm6,%xmm3
    1e51:	66 0f d4 d9          	paddq  %xmm1,%xmm3
    1e55:	66 0f 6f 4c 24 60    	movdqa 0x60(%rsp),%xmm1
    1e5b:	66 0f 74 c8          	pcmpeqb %xmm0,%xmm1
    1e5f:	66 0f ef cd          	pxor   %xmm5,%xmm1
    1e63:	66 0f 60 c9          	punpcklbw %xmm1,%xmm1
    1e67:	f2 0f 70 c9 d4       	pshuflw $0xd4,%xmm1,%xmm1
    1e6c:	66 0f 70 c9 d4       	pshufd $0xd4,%xmm1,%xmm1
    1e71:	66 0f db ce          	pand   %xmm6,%xmm1
    1e75:	66 0f d4 cb          	paddq  %xmm3,%xmm1
    1e79:	66 0f d4 ca          	paddq  %xmm2,%xmm1
    1e7d:	0f b7 44 24 62       	movzwl 0x62(%rsp),%eax
    1e82:	66 0f 6e d0          	movd   %eax,%xmm2
    1e86:	66 0f 74 d0          	pcmpeqb %xmm0,%xmm2
    1e8a:	66 0f ef d5          	pxor   %xmm5,%xmm2
    1e8e:	66 0f 60 d2          	punpcklbw %xmm2,%xmm2
    1e92:	f2 0f 70 d2 d4       	pshuflw $0xd4,%xmm2,%xmm2
    1e97:	66 0f 70 d2 d4       	pshufd $0xd4,%xmm2,%xmm2
    1e9c:	66 0f db d6          	pand   %xmm6,%xmm2
    1ea0:	66 0f 6e 5c 24 64    	movd   0x64(%rsp),%xmm3
    1ea6:	66 0f 74 d8          	pcmpeqb %xmm0,%xmm3
    1eaa:	66 0f ef dd          	pxor   %xmm5,%xmm3
    1eae:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    1eb2:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    1eb7:	66 0f 70 db d4       	pshufd $0xd4,%xmm3,%xmm3
    1ebc:	66 0f db de          	pand   %xmm6,%xmm3
    1ec0:	66 0f d4 da          	paddq  %xmm2,%xmm3
    1ec4:	0f b7 44 24 66       	movzwl 0x66(%rsp),%eax
    1ec9:	66 0f 6e d0          	movd   %eax,%xmm2
    1ecd:	66 0f 74 d0          	pcmpeqb %xmm0,%xmm2
    1ed1:	66 0f ef d5          	pxor   %xmm5,%xmm2
    1ed5:	66 0f 60 d2          	punpcklbw %xmm2,%xmm2
    1ed9:	f2 0f 70 d2 d4       	pshuflw $0xd4,%xmm2,%xmm2
    1ede:	66 0f 70 d2 d4       	pshufd $0xd4,%xmm2,%xmm2
    1ee3:	66 0f db d6          	pand   %xmm6,%xmm2
    1ee7:	66 0f d4 d3          	paddq  %xmm3,%xmm2
    1eeb:	f3 0f 7e 5c 24 68    	movq   0x68(%rsp),%xmm3
    1ef1:	66 0f 74 d8          	pcmpeqb %xmm0,%xmm3
    1ef5:	66 0f ef dd          	pxor   %xmm5,%xmm3
    1ef9:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    1efd:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    1f02:	66 0f 70 db d4       	pshufd $0xd4,%xmm3,%xmm3
    1f07:	66 0f db de          	pand   %xmm6,%xmm3
    1f0b:	66 0f d4 da          	paddq  %xmm2,%xmm3
    1f0f:	0f b7 44 24 6a       	movzwl 0x6a(%rsp),%eax
    1f14:	66 0f 6e d0          	movd   %eax,%xmm2
    1f18:	66 0f 74 d0          	pcmpeqb %xmm0,%xmm2
    1f1c:	66 0f ef d5          	pxor   %xmm5,%xmm2
    1f20:	66 0f 60 d2          	punpcklbw %xmm2,%xmm2
    1f24:	f2 0f 70 d2 d4       	pshuflw $0xd4,%xmm2,%xmm2
    1f29:	66 0f 70 d2 d4       	pshufd $0xd4,%xmm2,%xmm2
    1f2e:	66 0f db d6          	pand   %xmm6,%xmm2
    1f32:	66 0f d4 d3          	paddq  %xmm3,%xmm2
    1f36:	66 0f 6e 5c 24 6c    	movd   0x6c(%rsp),%xmm3
    1f3c:	66 0f 74 d8          	pcmpeqb %xmm0,%xmm3
    1f40:	66 0f ef dd          	pxor   %xmm5,%xmm3
    1f44:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    1f48:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    1f4d:	66 0f 70 db d4       	pshufd $0xd4,%xmm3,%xmm3
    1f52:	66 0f db de          	pand   %xmm6,%xmm3
    1f56:	66 0f d4 da          	paddq  %xmm2,%xmm3
    1f5a:	0f b7 44 24 6e       	movzwl 0x6e(%rsp),%eax
    1f5f:	66 0f 6e d0          	movd   %eax,%xmm2
    1f63:	66 0f 74 d0          	pcmpeqb %xmm0,%xmm2
    1f67:	66 0f ef d5          	pxor   %xmm5,%xmm2
    1f6b:	66 0f 60 d2          	punpcklbw %xmm2,%xmm2
    1f6f:	f2 0f 70 c2 d4       	pshuflw $0xd4,%xmm2,%xmm0
    1f74:	66 0f 70 c0 d4       	pshufd $0xd4,%xmm0,%xmm0
    1f79:	66 0f db c6          	pand   %xmm6,%xmm0
    1f7d:	66 0f d4 c3          	paddq  %xmm3,%xmm0
    1f81:	66 0f d4 c1          	paddq  %xmm1,%xmm0
    1f85:	66 0f 70 c8 ee       	pshufd $0xee,%xmm0,%xmm1
    1f8a:	66 0f d4 c8          	paddq  %xmm0,%xmm1
    1f8e:	66 49 0f 7e cd       	movq   %xmm1,%r13
    1f93:	49 ff c7             	inc    %r15
    1f96:	48 8b b4 24 48 01 00 	mov    0x148(%rsp),%rsi
    1f9d:	00 
    1f9e:	49 39 f7             	cmp    %rsi,%r15
    1fa1:	0f 82 49 fd ff ff    	jb     1cf0 <main+0x9b0>
    1fa7:	e9 8b 00 00 00       	jmp    2037 <main+0xcf7>
    1fac:	48 8b 1d 2d 90 00 00 	mov    0x902d(%rip),%rbx        # afe0 <stderr@GLIBC_2.2.5>
    1fb3:	48 8b 0b             	mov    (%rbx),%rcx
    1fb6:	48 8d 3d 6d 50 00 00 	lea    0x506d(%rip),%rdi        # 702a <_IO_stdin_used+0x2a>
    1fbd:	be 12 00 00 00       	mov    $0x12,%esi
    1fc2:	ba 01 00 00 00       	mov    $0x1,%edx
    1fc7:	e8 64 f2 ff ff       	call   1230 <fwrite@plt>
    1fcc:	48 8b 0b             	mov    (%rbx),%rcx
    1fcf:	48 8d 3d b5 52 00 00 	lea    0x52b5(%rip),%rdi        # 728b <_IO_stdin_used+0x28b>
    1fd6:	be 1b 02 00 00       	mov    $0x21b,%esi
    1fdb:	ba 01 00 00 00       	mov    $0x1,%edx
    1fe0:	e8 4b f2 ff ff       	call   1230 <fwrite@plt>
    1fe5:	b8 02 00 00 00       	mov    $0x2,%eax
    1fea:	e9 ab 0b 00 00       	jmp    2b9a <main+0x185a>
    1fef:	4c 89 f7             	mov    %r14,%rdi
    1ff2:	e8 a9 f0 ff ff       	call   10a0 <fclose@plt>
    1ff7:	48 8b 05 e2 8f 00 00 	mov    0x8fe2(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    1ffe:	48 8b 08             	mov    (%rax),%rcx
    2001:	be 46 00 00 00       	mov    $0x46,%esi
    2006:	ba 01 00 00 00       	mov    $0x1,%edx
    200b:	48 89 df             	mov    %rbx,%rdi
    200e:	e8 1d f2 ff ff       	call   1230 <fwrite@plt>
    2013:	bb 01 00 00 00       	mov    $0x1,%ebx
    2018:	e9 b6 0a 00 00       	jmp    2ad3 <main+0x1793>
    201d:	45 31 ed             	xor    %r13d,%r13d
    2020:	31 f6                	xor    %esi,%esi
    2022:	eb 13                	jmp    2037 <main+0xcf7>
    2024:	48 8b 05 b5 8f 00 00 	mov    0x8fb5(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    202b:	48 8b 08             	mov    (%rax),%rcx
    202e:	eb 9f                	jmp    1fcf <main+0xc8f>
    2030:	31 f6                	xor    %esi,%esi
    2032:	48 8b 6c 24 08       	mov    0x8(%rsp),%rbp
    2037:	48 8b 94 24 50 01 00 	mov    0x150(%rsp),%rdx
    203e:	00 
    203f:	48 8b 8c 24 58 01 00 	mov    0x158(%rsp),%rcx
    2046:	00 
    2047:	48 8d bc 24 38 01 00 	lea    0x138(%rsp),%rdi
    204e:	00 
    204f:	4c 8b 44 24 38       	mov    0x38(%rsp),%r8
    2054:	e8 b7 26 00 00       	call   4710 <m2_collector_build_schedule>
    2059:	85 c0                	test   %eax,%eax
    205b:	0f 85 63 0b 00 00    	jne    2bc4 <main+0x1884>
    2061:	4c 89 ac 24 80 00 00 	mov    %r13,0x80(%rsp)
    2068:	00 
    2069:	48 8b 74 24 40       	mov    0x40(%rsp),%rsi
    206e:	48 85 f6             	test   %rsi,%rsi
    2071:	48 8b 5c 24 38       	mov    0x38(%rsp),%rbx
    2076:	74 6a                	je     20e2 <main+0xda2>
    2078:	45 31 ed             	xor    %r13d,%r13d
    207b:	4c 8b 74 24 10       	mov    0x10(%rsp),%r14
    2080:	4c 8b 7c 24 18       	mov    0x18(%rsp),%r15
    2085:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    208c:	00 00 00 00 
    2090:	46 8b 24 ab          	mov    (%rbx,%r13,4),%r12d
    2094:	48 89 f5             	mov    %rsi,%rbp
    2097:	49 69 f4 40 04 00 00 	imul   $0x440,%r12,%rsi
    209e:	48 03 74 24 08       	add    0x8(%rsp),%rsi
    20a3:	ba 40 04 00 00       	mov    $0x440,%edx
    20a8:	4c 89 f7             	mov    %r14,%rdi
    20ab:	e8 f0 f0 ff ff       	call   11a0 <memcpy@plt>
    20b0:	49 c1 e4 09          	shl    $0x9,%r12
    20b4:	4c 03 64 24 28       	add    0x28(%rsp),%r12
    20b9:	ba 00 02 00 00       	mov    $0x200,%edx
    20be:	4c 89 ff             	mov    %r15,%rdi
    20c1:	4c 89 e6             	mov    %r12,%rsi
    20c4:	e8 d7 f0 ff ff       	call   11a0 <memcpy@plt>
    20c9:	48 89 ee             	mov    %rbp,%rsi
    20cc:	49 ff c5             	inc    %r13
    20cf:	49 81 c7 00 02 00 00 	add    $0x200,%r15
    20d6:	49 81 c6 40 04 00 00 	add    $0x440,%r14
    20dd:	4c 39 ed             	cmp    %r13,%rbp
    20e0:	75 ae                	jne    2090 <main+0xd50>
    20e2:	48 8b 6c 24 28       	mov    0x28(%rsp),%rbp
    20e7:	48 8d 94 24 10 14 00 	lea    0x1410(%rsp),%rdx
    20ee:	00 
    20ef:	48 8b 7c 24 10       	mov    0x10(%rsp),%rdi
    20f4:	e8 77 27 00 00       	call   4870 <m2_collector_digest_ciphertexts>
    20f9:	85 c0                	test   %eax,%eax
    20fb:	4c 8b 6c 24 18       	mov    0x18(%rsp),%r13
    2100:	0f 85 72 09 00 00    	jne    2a78 <main+0x1738>
    2106:	4c 8b a4 24 48 01 00 	mov    0x148(%rsp),%r12
    210d:	00 
    210e:	4d 89 e6             	mov    %r12,%r14
    2111:	49 c1 e6 09          	shl    $0x9,%r14
    2115:	4d 01 e6             	add    %r12,%r14
    2118:	4c 89 f7             	mov    %r14,%rdi
    211b:	e8 a0 f0 ff ff       	call   11c0 <malloc@plt>
    2120:	48 85 c0             	test   %rax,%rax
    2123:	0f 84 4f 09 00 00    	je     2a78 <main+0x1738>
    2129:	49 89 c7             	mov    %rax,%r15
    212c:	4d 85 e4             	test   %r12,%r12
    212f:	0f 84 c0 00 00 00    	je     21f5 <main+0xeb5>
    2135:	48 89 eb             	mov    %rbp,%rbx
    2138:	49 83 fc 01          	cmp    $0x1,%r12
    213c:	4c 89 bc 24 88 00 00 	mov    %r15,0x88(%rsp)
    2143:	00 
    2144:	75 04                	jne    214a <main+0xe0a>
    2146:	31 ed                	xor    %ebp,%ebp
    2148:	eb 6b                	jmp    21b5 <main+0xe75>
    214a:	4d 89 e5             	mov    %r12,%r13
    214d:	49 83 e5 fe          	and    $0xfffffffffffffffe,%r13
    2151:	49 81 c7 02 02 00 00 	add    $0x202,%r15
    2158:	31 ed                	xor    %ebp,%ebp
    215a:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    2160:	8b b4 ac 38 01 00 00 	mov    0x138(%rsp,%rbp,4),%esi
    2167:	41 88 b7 fe fd ff ff 	mov    %sil,-0x202(%r15)
    216e:	49 8d bf ff fd ff ff 	lea    -0x201(%r15),%rdi
    2175:	48 c1 e6 09          	shl    $0x9,%rsi
    2179:	48 01 de             	add    %rbx,%rsi
    217c:	ba 00 02 00 00       	mov    $0x200,%edx
    2181:	e8 1a f0 ff ff       	call   11a0 <memcpy@plt>
    2186:	8b b4 ac 3c 01 00 00 	mov    0x13c(%rsp,%rbp,4),%esi
    218d:	41 88 77 ff          	mov    %sil,-0x1(%r15)
    2191:	48 c1 e6 09          	shl    $0x9,%rsi
    2195:	48 01 de             	add    %rbx,%rsi
    2198:	ba 00 02 00 00       	mov    $0x200,%edx
    219d:	4c 89 ff             	mov    %r15,%rdi
    21a0:	e8 fb ef ff ff       	call   11a0 <memcpy@plt>
    21a5:	48 83 c5 02          	add    $0x2,%rbp
    21a9:	49 81 c7 02 04 00 00 	add    $0x402,%r15
    21b0:	49 39 ed             	cmp    %rbp,%r13
    21b3:	75 ab                	jne    2160 <main+0xe20>
    21b5:	41 f6 c4 01          	test   $0x1,%r12b
    21b9:	4c 8b 6c 24 18       	mov    0x18(%rsp),%r13
    21be:	4c 8b bc 24 88 00 00 	mov    0x88(%rsp),%r15
    21c5:	00 
    21c6:	74 2d                	je     21f5 <main+0xeb5>
    21c8:	8b b4 ac 38 01 00 00 	mov    0x138(%rsp,%rbp,4),%esi
    21cf:	48 89 e8             	mov    %rbp,%rax
    21d2:	48 c1 e0 09          	shl    $0x9,%rax
    21d6:	48 01 e8             	add    %rbp,%rax
    21d9:	41 88 34 07          	mov    %sil,(%r15,%rax,1)
    21dd:	49 8d 3c 07          	lea    (%r15,%rax,1),%rdi
    21e1:	48 ff c7             	inc    %rdi
    21e4:	48 c1 e6 09          	shl    $0x9,%rsi
    21e8:	48 01 de             	add    %rbx,%rsi
    21eb:	ba 00 02 00 00       	mov    $0x200,%edx
    21f0:	e8 ab ef ff ff       	call   11a0 <memcpy@plt>
    21f5:	48 8d bc 24 10 12 00 	lea    0x1210(%rsp),%rdi
    21fc:	00 
    21fd:	4c 89 fe             	mov    %r15,%rsi
    2200:	4c 89 f2             	mov    %r14,%rdx
    2203:	e8 f8 19 00 00       	call   3c00 <platform_m2_sha3_256>
    2208:	4c 89 ff             	mov    %r15,%rdi
    220b:	e8 20 ee ff ff       	call   1030 <free@plt>
    2210:	4c 8b bc 24 48 01 00 	mov    0x148(%rsp),%r15
    2217:	00 
    2218:	4d 89 fe             	mov    %r15,%r14
    221b:	49 c1 e6 05          	shl    $0x5,%r14
    221f:	4c 89 f7             	mov    %r14,%rdi
    2222:	e8 99 ef ff ff       	call   11c0 <malloc@plt>
    2227:	48 85 c0             	test   %rax,%rax
    222a:	0f 84 48 08 00 00    	je     2a78 <main+0x1738>
    2230:	49 89 c4             	mov    %rax,%r12
    2233:	4d 85 ff             	test   %r15,%r15
    2236:	0f 84 37 01 00 00    	je     2373 <main+0x1033>
    223c:	44 89 f8             	mov    %r15d,%eax
    223f:	83 e0 03             	and    $0x3,%eax
    2242:	31 d2                	xor    %edx,%edx
    2244:	49 83 ff 04          	cmp    $0x4,%r15
    2248:	73 07                	jae    2251 <main+0xf11>
    224a:	31 c9                	xor    %ecx,%ecx
    224c:	e9 c7 00 00 00       	jmp    2318 <main+0xfd8>
    2251:	49 83 e7 fc          	and    $0xfffffffffffffffc,%r15
    2255:	49 8d 74 24 60       	lea    0x60(%r12),%rsi
    225a:	31 c9                	xor    %ecx,%ecx
    225c:	0f 1f 40 00          	nopl   0x0(%rax)
    2260:	3b 94 8c 38 01 00 00 	cmp    0x138(%rsp,%rcx,4),%edx
    2267:	bf 00 00 00 00       	mov    $0x0,%edi
    226c:	19 ff                	sbb    %edi,%edi
    226e:	66 0f 6e c7          	movd   %edi,%xmm0
    2272:	66 0f 60 c0          	punpcklbw %xmm0,%xmm0
    2276:	f2 0f 70 c0 00       	pshuflw $0x0,%xmm0,%xmm0
    227b:	66 0f 70 c0 00       	pshufd $0x0,%xmm0,%xmm0
    2280:	3b 94 8c 3c 01 00 00 	cmp    0x13c(%rsp,%rcx,4),%edx
    2287:	f3 0f 7f 46 b0       	movdqu %xmm0,-0x50(%rsi)
    228c:	bf 00 00 00 00       	mov    $0x0,%edi
    2291:	19 ff                	sbb    %edi,%edi
    2293:	f3 0f 7f 46 a0       	movdqu %xmm0,-0x60(%rsi)
    2298:	66 0f 6e c7          	movd   %edi,%xmm0
    229c:	66 0f 60 c0          	punpcklbw %xmm0,%xmm0
    22a0:	f2 0f 70 c0 00       	pshuflw $0x0,%xmm0,%xmm0
    22a5:	66 0f 70 c0 00       	pshufd $0x0,%xmm0,%xmm0
    22aa:	f3 0f 7f 46 d0       	movdqu %xmm0,-0x30(%rsi)
    22af:	3b 94 8c 40 01 00 00 	cmp    0x140(%rsp,%rcx,4),%edx
    22b6:	f3 0f 7f 46 c0       	movdqu %xmm0,-0x40(%rsi)
    22bb:	bf 00 00 00 00       	mov    $0x0,%edi
    22c0:	19 ff                	sbb    %edi,%edi
    22c2:	66 0f 6e c7          	movd   %edi,%xmm0
    22c6:	66 0f 60 c0          	punpcklbw %xmm0,%xmm0
    22ca:	f2 0f 70 c0 00       	pshuflw $0x0,%xmm0,%xmm0
    22cf:	66 0f 70 c0 00       	pshufd $0x0,%xmm0,%xmm0
    22d4:	f3 0f 7f 46 f0       	movdqu %xmm0,-0x10(%rsi)
    22d9:	f3 0f 7f 46 e0       	movdqu %xmm0,-0x20(%rsi)
    22de:	3b 94 8c 44 01 00 00 	cmp    0x144(%rsp,%rcx,4),%edx
    22e5:	bf 00 00 00 00       	mov    $0x0,%edi
    22ea:	19 ff                	sbb    %edi,%edi
    22ec:	66 0f 6e c7          	movd   %edi,%xmm0
    22f0:	66 0f 60 c0          	punpcklbw %xmm0,%xmm0
    22f4:	f2 0f 70 c0 00       	pshuflw $0x0,%xmm0,%xmm0
    22f9:	66 0f 70 c0 00       	pshufd $0x0,%xmm0,%xmm0
    22fe:	f3 0f 7f 46 10       	movdqu %xmm0,0x10(%rsi)
    2303:	f3 0f 7f 06          	movdqu %xmm0,(%rsi)
    2307:	48 83 c1 04          	add    $0x4,%rcx
    230b:	48 83 ee 80          	sub    $0xffffffffffffff80,%rsi
    230f:	49 39 cf             	cmp    %rcx,%r15
    2312:	0f 85 48 ff ff ff    	jne    2260 <main+0xf20>
    2318:	48 85 c0             	test   %rax,%rax
    231b:	74 56                	je     2373 <main+0x1033>
    231d:	48 8d 14 8c          	lea    (%rsp,%rcx,4),%rdx
    2321:	48 81 c2 38 01 00 00 	add    $0x138,%rdx
    2328:	48 c1 e1 05          	shl    $0x5,%rcx
    232c:	4c 89 e6             	mov    %r12,%rsi
    232f:	48 01 ce             	add    %rcx,%rsi
    2332:	c1 e0 02             	shl    $0x2,%eax
    2335:	31 c9                	xor    %ecx,%ecx
    2337:	31 ff                	xor    %edi,%edi
    2339:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
    2340:	3b 0c 3a             	cmp    (%rdx,%rdi,1),%ecx
    2343:	41 b8 00 00 00 00    	mov    $0x0,%r8d
    2349:	45 19 c0             	sbb    %r8d,%r8d
    234c:	66 41 0f 6e c0       	movd   %r8d,%xmm0
    2351:	66 0f 60 c0          	punpcklbw %xmm0,%xmm0
    2355:	f2 0f 70 c0 00       	pshuflw $0x0,%xmm0,%xmm0
    235a:	66 0f 70 c0 00       	pshufd $0x0,%xmm0,%xmm0
    235f:	f3 0f 7f 44 fe 10    	movdqu %xmm0,0x10(%rsi,%rdi,8)
    2365:	f3 0f 7f 04 fe       	movdqu %xmm0,(%rsi,%rdi,8)
    236a:	48 83 c7 04          	add    $0x4,%rdi
    236e:	48 39 f8             	cmp    %rdi,%rax
    2371:	75 cd                	jne    2340 <main+0x1000>
    2373:	48 8d bc 24 b0 00 00 	lea    0xb0(%rsp),%rdi
    237a:	00 
    237b:	4c 89 e6             	mov    %r12,%rsi
    237e:	4c 89 f2             	mov    %r14,%rdx
    2381:	e8 7a 18 00 00       	call   3c00 <platform_m2_sha3_256>
    2386:	4c 89 e7             	mov    %r12,%rdi
    2389:	e8 a2 ec ff ff       	call   1030 <free@plt>
    238e:	48 8d 3d 82 51 00 00 	lea    0x5182(%rip),%rdi        # 7517 <_IO_stdin_used+0x517>
    2395:	48 8d b4 24 10 1a 00 	lea    0x1a10(%rsp),%rsi
    239c:	00 
    239d:	ba ff 0f 00 00       	mov    $0xfff,%edx
    23a2:	e8 d9 ec ff ff       	call   1080 <readlink@plt>
    23a7:	48 8d 88 01 f0 ff ff 	lea    -0xfff(%rax),%rcx
    23ae:	48 81 f9 02 f0 ff ff 	cmp    $0xfffffffffffff002,%rcx
    23b5:	0f 82 b8 06 00 00    	jb     2a73 <main+0x1733>
    23bb:	c6 84 04 10 1a 00 00 	movb   $0x0,0x1a10(%rsp,%rax,1)
    23c2:	00 
    23c3:	48 8d 35 4a 51 00 00 	lea    0x514a(%rip),%rsi        # 7514 <_IO_stdin_used+0x514>
    23ca:	48 8d bc 24 10 1a 00 	lea    0x1a10(%rsp),%rdi
    23d1:	00 
    23d2:	e8 39 ee ff ff       	call   1210 <fopen@plt>
    23d7:	48 85 c0             	test   %rax,%rax
    23da:	0f 84 93 06 00 00    	je     2a73 <main+0x1733>
    23e0:	49 89 c6             	mov    %rax,%r14
    23e3:	45 31 e4             	xor    %r12d,%r12d
    23e6:	48 89 c7             	mov    %rax,%rdi
    23e9:	31 f6                	xor    %esi,%esi
    23eb:	ba 02 00 00 00       	mov    $0x2,%edx
    23f0:	e8 fb ed ff ff       	call   11f0 <fseek@plt>
    23f5:	41 bd 00 00 00 00    	mov    $0x0,%r13d
    23fb:	85 c0                	test   %eax,%eax
    23fd:	0f 85 f5 00 00 00    	jne    24f8 <main+0x11b8>
    2403:	4c 89 f7             	mov    %r14,%rdi
    2406:	e8 85 ed ff ff       	call   1190 <ftell@plt>
    240b:	49 89 c7             	mov    %rax,%r15
    240e:	48 05 ff ff ff fb    	add    $0xfffffffffbffffff,%rax
    2414:	48 3d 00 00 00 fc    	cmp    $0xfffffffffc000000,%rax
    241a:	73 77                	jae    2493 <main+0x1153>
    241c:	45 31 e4             	xor    %r12d,%r12d
    241f:	45 31 ed             	xor    %r13d,%r13d
    2422:	e9 d1 00 00 00       	jmp    24f8 <main+0x11b8>
    2427:	48 8b 05 b2 8b 00 00 	mov    0x8bb2(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    242e:	48 8b 08             	mov    (%rax),%rcx
    2431:	48 8d 3d 05 4c 00 00 	lea    0x4c05(%rip),%rdi        # 703d <_IO_stdin_used+0x3d>
    2438:	be 1e 00 00 00       	mov    $0x1e,%esi
    243d:	eb 16                	jmp    2455 <main+0x1115>
    243f:	48 8b 05 9a 8b 00 00 	mov    0x8b9a(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2446:	48 8b 08             	mov    (%rax),%rcx
    2449:	48 8d 3d 0c 4c 00 00 	lea    0x4c0c(%rip),%rdi        # 705c <_IO_stdin_used+0x5c>
    2450:	be 19 00 00 00       	mov    $0x19,%esi
    2455:	ba 01 00 00 00       	mov    $0x1,%edx
    245a:	e8 d1 ed ff ff       	call   1230 <fwrite@plt>
    245f:	b8 01 00 00 00       	mov    $0x1,%eax
    2464:	e9 31 07 00 00       	jmp    2b9a <main+0x185a>
    2469:	48 8b 05 70 8b 00 00 	mov    0x8b70(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2470:	48 8b 08             	mov    (%rax),%rcx
    2473:	48 8d 3d fc 4b 00 00 	lea    0x4bfc(%rip),%rdi        # 7076 <_IO_stdin_used+0x76>
    247a:	be 12 00 00 00       	mov    $0x12,%esi
    247f:	ba 01 00 00 00       	mov    $0x1,%edx
    2484:	e8 a7 ed ff ff       	call   1230 <fwrite@plt>
    2489:	bb 01 00 00 00       	mov    $0x1,%ebx
    248e:	e9 19 06 00 00       	jmp    2aac <main+0x176c>
    2493:	45 31 e4             	xor    %r12d,%r12d
    2496:	4c 89 f7             	mov    %r14,%rdi
    2499:	31 f6                	xor    %esi,%esi
    249b:	31 d2                	xor    %edx,%edx
    249d:	e8 4e ed ff ff       	call   11f0 <fseek@plt>
    24a2:	41 bd 00 00 00 00    	mov    $0x0,%r13d
    24a8:	85 c0                	test   %eax,%eax
    24aa:	75 4c                	jne    24f8 <main+0x11b8>
    24ac:	4c 89 ff             	mov    %r15,%rdi
    24af:	e8 0c ed ff ff       	call   11c0 <malloc@plt>
    24b4:	48 85 c0             	test   %rax,%rax
    24b7:	0f 84 5f ff ff ff    	je     241c <main+0x10dc>
    24bd:	49 89 c4             	mov    %rax,%r12
    24c0:	be 01 00 00 00       	mov    $0x1,%esi
    24c5:	48 89 c7             	mov    %rax,%rdi
    24c8:	4c 89 fa             	mov    %r15,%rdx
    24cb:	4c 89 f1             	mov    %r14,%rcx
    24ce:	e8 9d eb ff ff       	call   1070 <fread@plt>
    24d3:	4c 39 f8             	cmp    %r15,%rax
    24d6:	75 1d                	jne    24f5 <main+0x11b5>
    24d8:	4c 89 f7             	mov    %r14,%rdi
    24db:	e8 40 ec ff ff       	call   1120 <fgetc@plt>
    24e0:	83 f8 ff             	cmp    $0xffffffff,%eax
    24e3:	75 10                	jne    24f5 <main+0x11b5>
    24e5:	4c 89 f7             	mov    %r14,%rdi
    24e8:	e8 73 eb ff ff       	call   1060 <ferror@plt>
    24ed:	85 c0                	test   %eax,%eax
    24ef:	0f 84 dc 07 00 00    	je     2cd1 <main+0x1991>
    24f5:	45 31 ed             	xor    %r13d,%r13d
    24f8:	4c 89 e7             	mov    %r12,%rdi
    24fb:	e8 30 eb ff ff       	call   1030 <free@plt>
    2500:	4c 89 f7             	mov    %r14,%rdi
    2503:	e8 98 eb ff ff       	call   10a0 <fclose@plt>
    2508:	85 c0                	test   %eax,%eax
    250a:	0f 85 63 05 00 00    	jne    2a73 <main+0x1733>
    2510:	45 84 ed             	test   %r13b,%r13b
    2513:	4c 8b 6c 24 18       	mov    0x18(%rsp),%r13
    2518:	0f 84 5a 05 00 00    	je     2a78 <main+0x1738>
    251e:	45 31 f6             	xor    %r14d,%r14d
    2521:	48 83 bc 24 60 01 00 	cmpq   $0x0,0x160(%rsp)
    2528:	00 00 
    252a:	74 5b                	je     2587 <main+0x1247>
    252c:	4c 8d 7c 24 50       	lea    0x50(%rsp),%r15
    2531:	48 8b 5c 24 40       	mov    0x40(%rsp),%rbx
    2536:	eb 3a                	jmp    2572 <main+0x1232>
    2538:	0f 1f 84 00 00 00 00 	nopl   0x0(%rax,%rax,1)
    253f:	00 
    2540:	4c 89 f0             	mov    %r14,%rax
    2543:	31 d2                	xor    %edx,%edx
    2545:	48 f7 f3             	div    %rbx
    2548:	49 ff c6             	inc    %r14
    254b:	48 c1 e2 09          	shl    $0x9,%rdx
    254f:	4c 01 ea             	add    %r13,%rdx
    2552:	4c 89 ff             	mov    %r15,%rdi
    2555:	48 89 d6             	mov    %rdx,%rsi
    2558:	e8 7d 2c 00 00       	call   51da <pqcrystals_kyber768_ref_poly_tomsg>
    255d:	0f b6 44 24 50       	movzbl 0x50(%rsp),%eax
    2562:	30 05 b1 8b 00 00    	xor    %al,0x8bb1(%rip)        # b119 <result_sink>
    2568:	4c 3b b4 24 60 01 00 	cmp    0x160(%rsp),%r14
    256f:	00 
    2570:	73 1a                	jae    258c <main+0x124c>
    2572:	4c 89 f0             	mov    %r14,%rax
    2575:	48 09 d8             	or     %rbx,%rax
    2578:	48 c1 e8 20          	shr    $0x20,%rax
    257c:	75 c2                	jne    2540 <main+0x1200>
    257e:	44 89 f0             	mov    %r14d,%eax
    2581:	31 d2                	xor    %edx,%edx
    2583:	f7 f3                	div    %ebx
    2585:	eb c1                	jmp    2548 <main+0x1208>
    2587:	48 8b 5c 24 40       	mov    0x40(%rsp),%rbx
    258c:	48 85 db             	test   %rbx,%rbx
    258f:	0f 84 10 04 00 00    	je     29a5 <main+0x1665>
    2595:	31 ed                	xor    %ebp,%ebp
    2597:	4c 8b 64 24 78       	mov    0x78(%rsp),%r12
    259c:	0f 1f 40 00          	nopl   0x0(%rax)
    25a0:	bf 01 00 00 00       	mov    $0x1,%edi
    25a5:	48 8d b4 24 10 1a 00 	lea    0x1a10(%rsp),%rsi
    25ac:	00 
    25ad:	e8 de ea ff ff       	call   1090 <clock_gettime@plt>
    25b2:	85 c0                	test   %eax,%eax
    25b4:	0f 85 d9 06 00 00    	jne    2c93 <main+0x1953>
    25ba:	4c 8b bc 24 10 1a 00 	mov    0x1a10(%rsp),%r15
    25c1:	00 
    25c2:	4d 85 ff             	test   %r15,%r15
    25c5:	0f 88 c8 06 00 00    	js     2c93 <main+0x1953>
    25cb:	48 8b 9c 24 18 1a 00 	mov    0x1a18(%rsp),%rbx
    25d2:	00 
    25d3:	48 85 db             	test   %rbx,%rbx
    25d6:	0f 88 b7 06 00 00    	js     2c93 <main+0x1953>
    25dc:	48 8d 7c 24 50       	lea    0x50(%rsp),%rdi
    25e1:	4c 89 ee             	mov    %r13,%rsi
    25e4:	e8 f1 2b 00 00       	call   51da <pqcrystals_kyber768_ref_poly_tomsg>
    25e9:	bf 01 00 00 00       	mov    $0x1,%edi
    25ee:	48 8d b4 24 10 1a 00 	lea    0x1a10(%rsp),%rsi
    25f5:	00 
    25f6:	e8 95 ea ff ff       	call   1090 <clock_gettime@plt>
    25fb:	85 c0                	test   %eax,%eax
    25fd:	0f 85 eb 05 00 00    	jne    2bee <main+0x18ae>
    2603:	48 8b 84 24 10 1a 00 	mov    0x1a10(%rsp),%rax
    260a:	00 
    260b:	48 85 c0             	test   %rax,%rax
    260e:	0f 88 da 05 00 00    	js     2bee <main+0x18ae>
    2614:	48 8b 8c 24 18 1a 00 	mov    0x1a18(%rsp),%rcx
    261b:	00 
    261c:	48 85 c9             	test   %rcx,%rcx
    261f:	0f 88 c9 05 00 00    	js     2bee <main+0x18ae>
    2625:	49 69 d7 00 ca 9a 3b 	imul   $0x3b9aca00,%r15,%rdx
    262c:	48 01 da             	add    %rbx,%rdx
    262f:	48 69 c0 00 ca 9a 3b 	imul   $0x3b9aca00,%rax,%rax
    2636:	48 01 c8             	add    %rcx,%rax
    2639:	48 29 d0             	sub    %rdx,%rax
    263c:	0f 82 ac 05 00 00    	jb     2bee <main+0x18ae>
    2642:	66 0f 6f 44 24 50    	movdqa 0x50(%rsp),%xmm0
    2648:	66 0f 6f 4c 24 60    	movdqa 0x60(%rsp),%xmm1
    264e:	f3 41 0f 7f 4c 24 10 	movdqu %xmm1,0x10(%r12)
    2655:	f3 41 0f 7f 04 24    	movdqu %xmm0,(%r12)
    265b:	4c 8b 7c 24 30       	mov    0x30(%rsp),%r15
    2660:	49 89 04 ef          	mov    %rax,(%r15,%rbp,8)
    2664:	48 ff c5             	inc    %rbp
    2667:	49 81 c5 00 02 00 00 	add    $0x200,%r13
    266e:	49 83 c4 20          	add    $0x20,%r12
    2672:	48 8b 5c 24 40       	mov    0x40(%rsp),%rbx
    2677:	48 39 eb             	cmp    %rbp,%rbx
    267a:	0f 85 20 ff ff ff    	jne    25a0 <main+0x1260>
    2680:	48 c7 c0 ff ff ff ff 	mov    $0xffffffffffffffff,%rax
    2687:	31 c9                	xor    %ecx,%ecx
    2689:	66 0f 76 c0          	pcmpeqd %xmm0,%xmm0
    268d:	66 0f 6f 0d 7b 49 00 	movdqa 0x497b(%rip),%xmm1        # 7010 <_IO_stdin_used+0x10>
    2694:	00 
    2695:	48 8b 54 24 78       	mov    0x78(%rsp),%rdx
    269a:	45 31 c9             	xor    %r9d,%r9d
    269d:	45 31 d2             	xor    %r10d,%r10d
    26a0:	45 31 e4             	xor    %r12d,%r12d
    26a3:	4c 8b 6c 24 18       	mov    0x18(%rsp),%r13
    26a8:	48 8b 74 24 38       	mov    0x38(%rsp),%rsi
    26ad:	48 8b ac 24 80 00 00 	mov    0x80(%rsp),%rbp
    26b4:	00 
    26b5:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    26bc:	00 00 00 00 
    26c0:	44 89 cf             	mov    %r9d,%edi
    26c3:	83 e7 1f             	and    $0x1f,%edi
    26c6:	42 3b 0c 8e          	cmp    (%rsi,%r9,4),%ecx
    26ca:	41 b8 00 00 00 00    	mov    $0x0,%r8d
    26d0:	45 19 c0             	sbb    %r8d,%r8d
    26d3:	0f b6 3c 3a          	movzbl (%rdx,%rdi,1),%edi
    26d7:	40 30 3d 3b 8a 00 00 	xor    %dil,0x8a3b(%rip)        # b119 <result_sink>
    26de:	66 41 0f 6e d0       	movd   %r8d,%xmm2
    26e3:	66 0f 60 d2          	punpcklbw %xmm2,%xmm2
    26e7:	66 48 0f 6e dd       	movq   %rbp,%xmm3
    26ec:	4b 8b 3c cf          	mov    (%r15,%r9,8),%rdi
    26f0:	48 39 c7             	cmp    %rax,%rdi
    26f3:	48 0f 42 c7          	cmovb  %rdi,%rax
    26f7:	44 0f b7 02          	movzwl (%rdx),%r8d
    26fb:	66 41 0f 6e e0       	movd   %r8d,%xmm4
    2700:	66 0f 74 e2          	pcmpeqb %xmm2,%xmm4
    2704:	66 0f ef e0          	pxor   %xmm0,%xmm4
    2708:	66 0f 60 e4          	punpcklbw %xmm4,%xmm4
    270c:	f2 0f 70 e4 d4       	pshuflw $0xd4,%xmm4,%xmm4
    2711:	66 0f 70 e4 d4       	pshufd $0xd4,%xmm4,%xmm4
    2716:	66 0f db e1          	pand   %xmm1,%xmm4
    271a:	66 0f d4 e3          	paddq  %xmm3,%xmm4
    271e:	44 0f b7 42 02       	movzwl 0x2(%rdx),%r8d
    2723:	66 41 0f 6e d8       	movd   %r8d,%xmm3
    2728:	66 0f 74 da          	pcmpeqb %xmm2,%xmm3
    272c:	66 0f ef d8          	pxor   %xmm0,%xmm3
    2730:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    2734:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    2739:	66 0f 70 eb d4       	pshufd $0xd4,%xmm3,%xmm5
    273e:	66 0f db e9          	pand   %xmm1,%xmm5
    2742:	44 0f b7 42 04       	movzwl 0x4(%rdx),%r8d
    2747:	66 41 0f 6e d8       	movd   %r8d,%xmm3
    274c:	66 0f 74 da          	pcmpeqb %xmm2,%xmm3
    2750:	66 0f ef d8          	pxor   %xmm0,%xmm3
    2754:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    2758:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    275d:	66 0f 70 db d4       	pshufd $0xd4,%xmm3,%xmm3
    2762:	66 0f db d9          	pand   %xmm1,%xmm3
    2766:	66 0f d4 dd          	paddq  %xmm5,%xmm3
    276a:	66 0f d4 dc          	paddq  %xmm4,%xmm3
    276e:	44 0f b7 42 06       	movzwl 0x6(%rdx),%r8d
    2773:	66 41 0f 6e e0       	movd   %r8d,%xmm4
    2778:	66 0f 74 e2          	pcmpeqb %xmm2,%xmm4
    277c:	66 0f ef e0          	pxor   %xmm0,%xmm4
    2780:	66 0f 60 e4          	punpcklbw %xmm4,%xmm4
    2784:	f2 0f 70 e4 d4       	pshuflw $0xd4,%xmm4,%xmm4
    2789:	66 0f 70 e4 d4       	pshufd $0xd4,%xmm4,%xmm4
    278e:	66 0f db e1          	pand   %xmm1,%xmm4
    2792:	44 0f b7 42 08       	movzwl 0x8(%rdx),%r8d
    2797:	66 41 0f 6e e8       	movd   %r8d,%xmm5
    279c:	66 0f 74 ea          	pcmpeqb %xmm2,%xmm5
    27a0:	66 0f ef e8          	pxor   %xmm0,%xmm5
    27a4:	66 0f 60 ed          	punpcklbw %xmm5,%xmm5
    27a8:	f2 0f 70 ed d4       	pshuflw $0xd4,%xmm5,%xmm5
    27ad:	66 0f 70 ed d4       	pshufd $0xd4,%xmm5,%xmm5
    27b2:	66 0f db e9          	pand   %xmm1,%xmm5
    27b6:	66 0f d4 ec          	paddq  %xmm4,%xmm5
    27ba:	44 0f b7 42 0a       	movzwl 0xa(%rdx),%r8d
    27bf:	66 41 0f 6e e0       	movd   %r8d,%xmm4
    27c4:	66 0f 74 e2          	pcmpeqb %xmm2,%xmm4
    27c8:	66 0f ef e0          	pxor   %xmm0,%xmm4
    27cc:	66 0f 60 e4          	punpcklbw %xmm4,%xmm4
    27d0:	f2 0f 70 e4 d4       	pshuflw $0xd4,%xmm4,%xmm4
    27d5:	66 0f 70 e4 d4       	pshufd $0xd4,%xmm4,%xmm4
    27da:	66 0f db e1          	pand   %xmm1,%xmm4
    27de:	66 0f d4 e5          	paddq  %xmm5,%xmm4
    27e2:	66 0f d4 e3          	paddq  %xmm3,%xmm4
    27e6:	44 0f b7 42 0c       	movzwl 0xc(%rdx),%r8d
    27eb:	66 41 0f 6e d8       	movd   %r8d,%xmm3
    27f0:	66 0f 74 da          	pcmpeqb %xmm2,%xmm3
    27f4:	66 0f ef d8          	pxor   %xmm0,%xmm3
    27f8:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    27fc:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    2801:	66 0f 70 db d4       	pshufd $0xd4,%xmm3,%xmm3
    2806:	66 0f db d9          	pand   %xmm1,%xmm3
    280a:	44 0f b7 42 0e       	movzwl 0xe(%rdx),%r8d
    280f:	66 41 0f 6e e8       	movd   %r8d,%xmm5
    2814:	66 0f 74 ea          	pcmpeqb %xmm2,%xmm5
    2818:	66 0f ef e8          	pxor   %xmm0,%xmm5
    281c:	66 0f 60 ed          	punpcklbw %xmm5,%xmm5
    2820:	f2 0f 70 ed d4       	pshuflw $0xd4,%xmm5,%xmm5
    2825:	66 0f 70 ed d4       	pshufd $0xd4,%xmm5,%xmm5
    282a:	66 0f db e9          	pand   %xmm1,%xmm5
    282e:	66 0f d4 eb          	paddq  %xmm3,%xmm5
    2832:	44 0f b7 42 10       	movzwl 0x10(%rdx),%r8d
    2837:	66 41 0f 6e d8       	movd   %r8d,%xmm3
    283c:	66 0f 74 da          	pcmpeqb %xmm2,%xmm3
    2840:	66 0f ef d8          	pxor   %xmm0,%xmm3
    2844:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    2848:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    284d:	66 0f 70 f3 d4       	pshufd $0xd4,%xmm3,%xmm6
    2852:	66 0f db f1          	pand   %xmm1,%xmm6
    2856:	66 0f d4 f5          	paddq  %xmm5,%xmm6
    285a:	44 0f b7 42 12       	movzwl 0x12(%rdx),%r8d
    285f:	66 41 0f 6e d8       	movd   %r8d,%xmm3
    2864:	66 0f 74 da          	pcmpeqb %xmm2,%xmm3
    2868:	66 0f ef d8          	pxor   %xmm0,%xmm3
    286c:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    2870:	f2 0f 70 db d4       	pshuflw $0xd4,%xmm3,%xmm3
    2875:	66 0f 70 db d4       	pshufd $0xd4,%xmm3,%xmm3
    287a:	66 0f db d9          	pand   %xmm1,%xmm3
    287e:	66 0f d4 de          	paddq  %xmm6,%xmm3
    2882:	66 0f d4 dc          	paddq  %xmm4,%xmm3
    2886:	44 0f b7 42 14       	movzwl 0x14(%rdx),%r8d
    288b:	66 41 0f 6e e0       	movd   %r8d,%xmm4
    2890:	66 0f 74 e2          	pcmpeqb %xmm2,%xmm4
    2894:	66 0f ef e0          	pxor   %xmm0,%xmm4
    2898:	66 0f 60 e4          	punpcklbw %xmm4,%xmm4
    289c:	f2 0f 70 e4 d4       	pshuflw $0xd4,%xmm4,%xmm4
    28a1:	66 0f 70 e4 d4       	pshufd $0xd4,%xmm4,%xmm4
    28a6:	66 0f db e1          	pand   %xmm1,%xmm4
    28aa:	44 0f b7 42 16       	movzwl 0x16(%rdx),%r8d
    28af:	66 41 0f 6e e8       	movd   %r8d,%xmm5
    28b4:	66 0f 74 ea          	pcmpeqb %xmm2,%xmm5
    28b8:	66 0f ef e8          	pxor   %xmm0,%xmm5
    28bc:	66 0f 60 ed          	punpcklbw %xmm5,%xmm5
    28c0:	f2 0f 70 ed d4       	pshuflw $0xd4,%xmm5,%xmm5
    28c5:	66 0f 70 ed d4       	pshufd $0xd4,%xmm5,%xmm5
    28ca:	66 0f db e9          	pand   %xmm1,%xmm5
    28ce:	66 0f d4 ec          	paddq  %xmm4,%xmm5
    28d2:	44 0f b7 42 18       	movzwl 0x18(%rdx),%r8d
    28d7:	66 41 0f 6e e0       	movd   %r8d,%xmm4
    28dc:	66 0f 74 e2          	pcmpeqb %xmm2,%xmm4
    28e0:	66 0f ef e0          	pxor   %xmm0,%xmm4
    28e4:	66 0f 60 e4          	punpcklbw %xmm4,%xmm4
    28e8:	f2 0f 70 e4 d4       	pshuflw $0xd4,%xmm4,%xmm4
    28ed:	66 0f 70 e4 d4       	pshufd $0xd4,%xmm4,%xmm4
    28f2:	66 0f db e1          	pand   %xmm1,%xmm4
    28f6:	66 0f d4 e5          	paddq  %xmm5,%xmm4
    28fa:	44 0f b7 42 1a       	movzwl 0x1a(%rdx),%r8d
    28ff:	66 41 0f 6e e8       	movd   %r8d,%xmm5
    2904:	66 0f 74 ea          	pcmpeqb %xmm2,%xmm5
    2908:	66 0f ef e8          	pxor   %xmm0,%xmm5
    290c:	66 0f 60 ed          	punpcklbw %xmm5,%xmm5
    2910:	f2 0f 70 ed d4       	pshuflw $0xd4,%xmm5,%xmm5
    2915:	66 0f 70 ed d4       	pshufd $0xd4,%xmm5,%xmm5
    291a:	66 0f db e9          	pand   %xmm1,%xmm5
    291e:	66 0f d4 ec          	paddq  %xmm4,%xmm5
    2922:	44 0f b7 42 1c       	movzwl 0x1c(%rdx),%r8d
    2927:	66 41 0f 6e e0       	movd   %r8d,%xmm4
    292c:	66 0f 74 e2          	pcmpeqb %xmm2,%xmm4
    2930:	66 0f ef e0          	pxor   %xmm0,%xmm4
    2934:	66 0f 60 e4          	punpcklbw %xmm4,%xmm4
    2938:	f2 0f 70 e4 d4       	pshuflw $0xd4,%xmm4,%xmm4
    293d:	66 0f 70 e4 d4       	pshufd $0xd4,%xmm4,%xmm4
    2942:	66 0f db e1          	pand   %xmm1,%xmm4
    2946:	66 0f d4 e5          	paddq  %xmm5,%xmm4
    294a:	66 0f d4 e3          	paddq  %xmm3,%xmm4
    294e:	44 0f b7 42 1e       	movzwl 0x1e(%rdx),%r8d
    2953:	66 41 0f 6e d8       	movd   %r8d,%xmm3
    2958:	66 0f 74 da          	pcmpeqb %xmm2,%xmm3
    295c:	66 0f ef d8          	pxor   %xmm0,%xmm3
    2960:	66 0f 60 db          	punpcklbw %xmm3,%xmm3
    2964:	f2 0f 70 d3 d4       	pshuflw $0xd4,%xmm3,%xmm2
    2969:	66 0f 70 d2 d4       	pshufd $0xd4,%xmm2,%xmm2
    296e:	66 0f db d1          	pand   %xmm1,%xmm2
    2972:	66 0f d4 d4          	paddq  %xmm4,%xmm2
    2976:	66 0f 70 da ee       	pshufd $0xee,%xmm2,%xmm3
    297b:	66 0f d4 da          	paddq  %xmm2,%xmm3
    297f:	48 83 ff 01          	cmp    $0x1,%rdi
    2983:	49 83 d4 00          	adc    $0x0,%r12
    2987:	4c 39 d7             	cmp    %r10,%rdi
    298a:	4c 0f 47 d7          	cmova  %rdi,%r10
    298e:	66 48 0f 7e dd       	movq   %xmm3,%rbp
    2993:	49 ff c1             	inc    %r9
    2996:	48 83 c2 20          	add    $0x20,%rdx
    299a:	4c 39 cb             	cmp    %r9,%rbx
    299d:	0f 85 1d fd ff ff    	jne    26c0 <main+0x1380>
    29a3:	eb 1f                	jmp    29c4 <main+0x1684>
    29a5:	48 c7 c0 ff ff ff ff 	mov    $0xffffffffffffffff,%rax
    29ac:	45 31 e4             	xor    %r12d,%r12d
    29af:	45 31 d2             	xor    %r10d,%r10d
    29b2:	48 8b 74 24 38       	mov    0x38(%rsp),%rsi
    29b7:	4c 8b 7c 24 30       	mov    0x30(%rsp),%r15
    29bc:	48 8b ac 24 80 00 00 	mov    0x80(%rsp),%rbp
    29c3:	00 
    29c4:	48 83 ec 08          	sub    $0x8,%rsp
    29c8:	4c 8d 9c 24 d8 00 00 	lea    0xd8(%rsp),%r11
    29cf:	00 
    29d0:	48 8d bc 24 40 01 00 	lea    0x140(%rsp),%rdi
    29d7:	00 
    29d8:	4c 89 fa             	mov    %r15,%rdx
    29db:	48 89 d9             	mov    %rbx,%rcx
    29de:	4c 8b 84 24 98 00 00 	mov    0x98(%rsp),%r8
    29e5:	00 
    29e6:	4d 89 e1             	mov    %r12,%r9
    29e9:	41 53                	push   %r11
    29eb:	4c 8d 9c 24 c0 00 00 	lea    0xc0(%rsp),%r11
    29f2:	00 
    29f3:	41 53                	push   %r11
    29f5:	4c 8d 9c 24 28 12 00 	lea    0x1228(%rsp),%r11
    29fc:	00 
    29fd:	41 53                	push   %r11
    29ff:	4c 8d 9c 24 30 14 00 	lea    0x1430(%rsp),%r11
    2a06:	00 
    2a07:	41 53                	push   %r11
    2a09:	4c 8d 9c 24 18 01 00 	lea    0x118(%rsp),%r11
    2a10:	00 
    2a11:	41 53                	push   %r11
    2a13:	4c 8d 9c 24 40 01 00 	lea    0x140(%rsp),%r11
    2a1a:	00 
    2a1b:	41 53                	push   %r11
    2a1d:	41 56                	push   %r14
    2a1f:	41 56                	push   %r14
    2a21:	55                   	push   %rbp
    2a22:	41 52                	push   %r10
    2a24:	50                   	push   %rax
    2a25:	e8 c6 02 00 00       	call   2cf0 <save_results>
    2a2a:	48 83 c4 60          	add    $0x60,%rsp
    2a2e:	85 c0                	test   %eax,%eax
    2a30:	0f 85 ee 01 00 00    	jne    2c24 <main+0x18e4>
    2a36:	48 85 ed             	test   %rbp,%rbp
    2a39:	0f 85 0f 02 00 00    	jne    2c4e <main+0x190e>
    2a3f:	4d 85 e4             	test   %r12,%r12
    2a42:	0f 85 2b 02 00 00    	jne    2c73 <main+0x1933>
    2a48:	e8 c3 11 00 00       	call   3c10 <mlkem_implementation_name>
    2a4d:	48 8d 3d fa 47 00 00 	lea    0x47fa(%rip),%rdi        # 724e <_IO_stdin_used+0x24e>
    2a54:	48 8d 0d 99 4e 00 00 	lea    0x4e99(%rip),%rcx        # 78f4 <_IO_stdin_used+0x8f4>
    2a5b:	31 db                	xor    %ebx,%ebx
    2a5d:	48 89 c6             	mov    %rax,%rsi
    2a60:	48 8b 54 24 40       	mov    0x40(%rsp),%rdx
    2a65:	31 c0                	xor    %eax,%eax
    2a67:	e8 64 e6 ff ff       	call   10d0 <printf@plt>
    2a6c:	4c 8b 64 24 10       	mov    0x10(%rsp),%r12
    2a71:	eb 34                	jmp    2aa7 <main+0x1767>
    2a73:	4c 8b 6c 24 18       	mov    0x18(%rsp),%r13
    2a78:	48 8b 05 61 85 00 00 	mov    0x8561(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2a7f:	48 8b 08             	mov    (%rax),%rcx
    2a82:	48 8d 3d cc 46 00 00 	lea    0x46cc(%rip),%rdi        # 7155 <_IO_stdin_used+0x155>
    2a89:	be 1f 00 00 00       	mov    $0x1f,%esi
    2a8e:	ba 01 00 00 00       	mov    $0x1,%edx
    2a93:	e8 98 e7 ff ff       	call   1230 <fwrite@plt>
    2a98:	bb 01 00 00 00       	mov    $0x1,%ebx
    2a9d:	4c 8b 64 24 10       	mov    0x10(%rsp),%r12
    2aa2:	4c 8b 7c 24 30       	mov    0x30(%rsp),%r15
    2aa7:	48 8b 6c 24 08       	mov    0x8(%rsp),%rbp
    2aac:	66 0f ef c0          	pxor   %xmm0,%xmm0
    2ab0:	66 0f 76 84 24 a0 00 	pcmpeqd 0xa0(%rsp),%xmm0
    2ab7:	00 00 
    2ab9:	66 0f 70 c8 b1       	pshufd $0xb1,%xmm0,%xmm1
    2abe:	66 0f db c8          	pand   %xmm0,%xmm1
    2ac2:	66 0f 6b c1          	packssdw %xmm1,%xmm0
    2ac6:	66 0f 6b c0          	packssdw %xmm0,%xmm0
    2aca:	66 0f c5 c0 06       	pextrw $0x6,%xmm0,%eax
    2acf:	a8 01                	test   $0x1,%al
    2ad1:	75 0f                	jne    2ae2 <main+0x17a2>
    2ad3:	be 60 09 00 00       	mov    $0x960,%esi
    2ad8:	48 8b 7c 24 48       	mov    0x48(%rsp),%rdi
    2add:	e8 ee 17 00 00       	call   42d0 <erase_secret_bytes>
    2ae2:	66 0f ef c0          	pxor   %xmm0,%xmm0
    2ae6:	66 0f 6f 8c 24 a0 00 	movdqa 0xa0(%rsp),%xmm1
    2aed:	00 00 
    2aef:	66 0f 76 c8          	pcmpeqd %xmm0,%xmm1
    2af3:	f3 0f 70 c1 84       	pshufhw $0x84,%xmm1,%xmm0
    2af8:	66 0f 70 c9 b1       	pshufd $0xb1,%xmm1,%xmm1
    2afd:	f3 0f 70 c9 84       	pshufhw $0x84,%xmm1,%xmm1
    2b02:	66 0f db c8          	pand   %xmm0,%xmm1
    2b06:	66 0f 6b c1          	packssdw %xmm1,%xmm0
    2b0a:	66 0f c5 c0 07       	pextrw $0x7,%xmm0,%eax
    2b0f:	a8 01                	test   $0x1,%al
    2b11:	75 0f                	jne    2b22 <main+0x17e2>
    2b13:	be 00 08 00 00       	mov    $0x800,%esi
    2b18:	48 8b 7c 24 28       	mov    0x28(%rsp),%rdi
    2b1d:	e8 ae 17 00 00       	call   42d0 <erase_secret_bytes>
    2b22:	4d 85 ed             	test   %r13,%r13
    2b25:	74 10                	je     2b37 <main+0x17f7>
    2b27:	4c 89 ef             	mov    %r13,%rdi
    2b2a:	48 8b b4 24 98 00 00 	mov    0x98(%rsp),%rsi
    2b31:	00 
    2b32:	e8 99 17 00 00       	call   42d0 <erase_secret_bytes>
    2b37:	48 8d 7c 24 50       	lea    0x50(%rsp),%rdi
    2b3c:	be 20 00 00 00       	mov    $0x20,%esi
    2b41:	e8 8a 17 00 00       	call   42d0 <erase_secret_bytes>
    2b46:	48 8b 7c 24 20       	mov    0x20(%rsp),%rdi
    2b4b:	e8 e0 e4 ff ff       	call   1030 <free@plt>
    2b50:	48 8b 7c 24 48       	mov    0x48(%rsp),%rdi
    2b55:	e8 d6 e4 ff ff       	call   1030 <free@plt>
    2b5a:	48 89 ef             	mov    %rbp,%rdi
    2b5d:	e8 ce e4 ff ff       	call   1030 <free@plt>
    2b62:	4c 89 e7             	mov    %r12,%rdi
    2b65:	e8 c6 e4 ff ff       	call   1030 <free@plt>
    2b6a:	48 8b 7c 24 28       	mov    0x28(%rsp),%rdi
    2b6f:	e8 bc e4 ff ff       	call   1030 <free@plt>
    2b74:	4c 89 ef             	mov    %r13,%rdi
    2b77:	e8 b4 e4 ff ff       	call   1030 <free@plt>
    2b7c:	48 8b 7c 24 38       	mov    0x38(%rsp),%rdi
    2b81:	e8 aa e4 ff ff       	call   1030 <free@plt>
    2b86:	48 8b 7c 24 78       	mov    0x78(%rsp),%rdi
    2b8b:	e8 a0 e4 ff ff       	call   1030 <free@plt>
    2b90:	4c 89 ff             	mov    %r15,%rdi
    2b93:	e8 98 e4 ff ff       	call   1030 <free@plt>
    2b98:	89 d8                	mov    %ebx,%eax
    2b9a:	48 81 c4 18 2a 00 00 	add    $0x2a18,%rsp
    2ba1:	5b                   	pop    %rbx
    2ba2:	41 5c                	pop    %r12
    2ba4:	41 5d                	pop    %r13
    2ba6:	41 5e                	pop    %r14
    2ba8:	41 5f                	pop    %r15
    2baa:	5d                   	pop    %rbp
    2bab:	c3                   	ret
    2bac:	48 8d 1d d6 44 00 00 	lea    0x44d6(%rip),%rbx        # 7089 <_IO_stdin_used+0x89>
    2bb3:	e9 3f f4 ff ff       	jmp    1ff7 <main+0xcb7>
    2bb8:	48 8d 1d 11 45 00 00 	lea    0x4511(%rip),%rbx        # 70d0 <_IO_stdin_used+0xd0>
    2bbf:	e9 33 f4 ff ff       	jmp    1ff7 <main+0xcb7>
    2bc4:	48 8b 05 15 84 00 00 	mov    0x8415(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2bcb:	48 8b 08             	mov    (%rax),%rcx
    2bce:	48 8d 3d 62 45 00 00 	lea    0x4562(%rip),%rdi        # 7137 <_IO_stdin_used+0x137>
    2bd5:	be 1d 00 00 00       	mov    $0x1d,%esi
    2bda:	ba 01 00 00 00       	mov    $0x1,%edx
    2bdf:	e8 4c e6 ff ff       	call   1230 <fwrite@plt>
    2be4:	bb 01 00 00 00       	mov    $0x1,%ebx
    2be9:	e9 cf 00 00 00       	jmp    2cbd <main+0x197d>
    2bee:	48 8b 05 eb 83 00 00 	mov    0x83eb(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2bf5:	48 8b 08             	mov    (%rax),%rcx
    2bf8:	48 8d 3d 89 45 00 00 	lea    0x4589(%rip),%rdi        # 7188 <_IO_stdin_used+0x188>
    2bff:	be 25 00 00 00       	mov    $0x25,%esi
    2c04:	e9 a0 00 00 00       	jmp    2ca9 <main+0x1969>
    2c09:	48 8b 05 d0 83 00 00 	mov    0x83d0(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2c10:	48 8b 08             	mov    (%rax),%rcx
    2c13:	48 8d 3d fd 44 00 00 	lea    0x44fd(%rip),%rdi        # 7117 <_IO_stdin_used+0x117>
    2c1a:	be 1f 00 00 00       	mov    $0x1f,%esi
    2c1f:	e9 85 00 00 00       	jmp    2ca9 <main+0x1969>
    2c24:	48 8b 05 b5 83 00 00 	mov    0x83b5(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2c2b:	48 8b 08             	mov    (%rax),%rcx
    2c2e:	48 8d 3d 79 45 00 00 	lea    0x4579(%rip),%rdi        # 71ae <_IO_stdin_used+0x1ae>
    2c35:	be 2a 00 00 00       	mov    $0x2a,%esi
    2c3a:	ba 01 00 00 00       	mov    $0x1,%edx
    2c3f:	e8 ec e5 ff ff       	call   1230 <fwrite@plt>
    2c44:	bb 01 00 00 00       	mov    $0x1,%ebx
    2c49:	e9 1e fe ff ff       	jmp    2a6c <main+0x172c>
    2c4e:	48 8b 05 8b 83 00 00 	mov    0x838b(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2c55:	48 8b 38             	mov    (%rax),%rdi
    2c58:	48 8d 35 7a 45 00 00 	lea    0x457a(%rip),%rsi        # 71d9 <_IO_stdin_used+0x1d9>
    2c5f:	48 89 ea             	mov    %rbp,%rdx
    2c62:	31 c0                	xor    %eax,%eax
    2c64:	e8 17 e5 ff ff       	call   1180 <fprintf@plt>
    2c69:	bb 01 00 00 00       	mov    $0x1,%ebx
    2c6e:	e9 f9 fd ff ff       	jmp    2a6c <main+0x172c>
    2c73:	48 8b 05 66 83 00 00 	mov    0x8366(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2c7a:	48 8b 38             	mov    (%rax),%rdi
    2c7d:	48 8d 35 94 45 00 00 	lea    0x4594(%rip),%rsi        # 7218 <_IO_stdin_used+0x218>
    2c84:	4c 89 e2             	mov    %r12,%rdx
    2c87:	31 c0                	xor    %eax,%eax
    2c89:	e8 f2 e4 ff ff       	call   1180 <fprintf@plt>
    2c8e:	e9 b5 fd ff ff       	jmp    2a48 <main+0x1708>
    2c93:	48 8b 05 46 83 00 00 	mov    0x8346(%rip),%rax        # afe0 <stderr@GLIBC_2.2.5>
    2c9a:	48 8b 08             	mov    (%rax),%rcx
    2c9d:	48 8d 3d d1 44 00 00 	lea    0x44d1(%rip),%rdi        # 7175 <_IO_stdin_used+0x175>
    2ca4:	be 12 00 00 00       	mov    $0x12,%esi
    2ca9:	ba 01 00 00 00       	mov    $0x1,%edx
    2cae:	e8 7d e5 ff ff       	call   1230 <fwrite@plt>
    2cb3:	bb 01 00 00 00       	mov    $0x1,%ebx
    2cb8:	48 8b 6c 24 08       	mov    0x8(%rsp),%rbp
    2cbd:	4c 8b 64 24 10       	mov    0x10(%rsp),%r12
    2cc2:	4c 8b 6c 24 18       	mov    0x18(%rsp),%r13
    2cc7:	4c 8b 7c 24 30       	mov    0x30(%rsp),%r15
    2ccc:	e9 db fd ff ff       	jmp    2aac <main+0x176c>
    2cd1:	48 8d bc 24 d0 00 00 	lea    0xd0(%rsp),%rdi
    2cd8:	00 
    2cd9:	4c 89 e6             	mov    %r12,%rsi
    2cdc:	4c 89 fa             	mov    %r15,%rdx
    2cdf:	e8 1c 0f 00 00       	call   3c00 <platform_m2_sha3_256>
    2ce4:	41 b5 01             	mov    $0x1,%r13b
    2ce7:	e9 0c f8 ff ff       	jmp    24f8 <main+0x11b8>

Disassembly of section .fini:
