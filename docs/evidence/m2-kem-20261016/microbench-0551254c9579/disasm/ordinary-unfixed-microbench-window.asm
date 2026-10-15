# unfixed 微基准计时窗口：从第 1106 行的起点读钟到第 1123 行的终点读钟
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
# window_instruction_lines=18
