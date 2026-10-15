
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-sanitize/microbench/unfixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000117e88 <pqcrystals_kyber768_ref_poly_tomsg>:
  117e88:	55                   	push   %rbp
  117e89:	48 89 e5             	mov    %rsp,%rbp
  117e8c:	41 57                	push   %r15
  117e8e:	41 56                	push   %r14
  117e90:	41 55                	push   %r13
  117e92:	41 54                	push   %r12
  117e94:	53                   	push   %rbx
  117e95:	48 83 ec 38          	sub    $0x38,%rsp
  117e99:	48 85 f6             	test   %rsi,%rsi
  117e9c:	0f 95 c0             	setne  %al
  117e9f:	40 f6 c6 01          	test   $0x1,%sil
  117ea3:	41 0f 94 c5          	sete   %r13b
  117ea7:	41 20 c5             	and    %al,%r13b
  117eaa:	45 31 c0             	xor    %r8d,%r8d
  117ead:	4c 8d 0d cc b6 04 00 	lea    0x4b6cc(%rip),%r9        # 163580 <_ZL17kSuppressionTypes+0x1b30>
  117eb4:	4c 8d 15 b5 b6 04 00 	lea    0x4b6b5(%rip),%r10        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  117ebb:	4c 8d 1d 8e b6 04 00 	lea    0x4b68e(%rip),%r11        # 163550 <_ZL17kSuppressionTypes+0x1b00>
  117ec2:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  117ec6:	49 89 f7             	mov    %rsi,%r15
  117ec9:	eb 1f                	jmp    117eea <pqcrystals_kyber768_ref_poly_tomsg+0x62>
  117ecb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
  117ed0:	49 ff c0             	inc    %r8
  117ed3:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  117ed7:	49 83 c7 10          	add    $0x10,%r15
  117edb:	48 83 45 a0 10       	addq   $0x10,-0x60(%rbp)
  117ee0:	49 83 f8 20          	cmp    $0x20,%r8
  117ee4:	0f 84 d3 02 00 00    	je     1181bd <pqcrystals_kyber768_ref_poly_tomsg+0x335>
  117eea:	48 85 ff             	test   %rdi,%rdi
  117eed:	0f 95 c0             	setne  %al
  117ef0:	48 89 fa             	mov    %rdi,%rdx
  117ef3:	4c 01 c2             	add    %r8,%rdx
  117ef6:	0f 95 c3             	setne  %bl
  117ef9:	48 39 fa             	cmp    %rdi,%rdx
  117efc:	0f 93 c1             	setae  %cl
  117eff:	20 c3                	and    %al,%bl
  117f01:	20 cb                	and    %cl,%bl
  117f03:	88 5d d7             	mov    %bl,-0x29(%rbp)
  117f06:	48 89 55 b0          	mov    %rdx,-0x50(%rbp)
  117f0a:	4c 89 7d a8          	mov    %r15,-0x58(%rbp)
  117f0e:	0f 84 1b 02 00 00    	je     11812f <pqcrystals_kyber768_ref_poly_tomsg+0x2a7>
  117f14:	48 85 ff             	test   %rdi,%rdi
  117f17:	0f 84 5b 02 00 00    	je     118178 <pqcrystals_kyber768_ref_poly_tomsg+0x2f0>
  117f1d:	49 89 d6             	mov    %rdx,%r14
  117f20:	49 c1 ee 03          	shr    $0x3,%r14
  117f24:	41 0f b6 86 00 80 ff 	movzbl 0x7fff8000(%r14),%eax
  117f2b:	7f 
  117f2c:	84 c0                	test   %al,%al
  117f2e:	0f 85 e9 01 00 00    	jne    11811d <pqcrystals_kyber768_ref_poly_tomsg+0x295>
  117f34:	c6 02 00             	movb   $0x0,(%rdx)
  117f37:	45 31 e4             	xor    %r12d,%r12d
  117f3a:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  117f3e:	66 90                	xchg   %ax,%ax
  117f40:	45 84 ed             	test   %r13b,%r13b
  117f43:	0f 84 ba 00 00 00    	je     118003 <pqcrystals_kyber768_ref_poly_tomsg+0x17b>
  117f49:	48 85 f6             	test   %rsi,%rsi
  117f4c:	0f 84 f7 00 00 00    	je     118049 <pqcrystals_kyber768_ref_poly_tomsg+0x1c1>
  117f52:	4d 85 ff             	test   %r15,%r15
  117f55:	0f 84 ee 00 00 00    	je     118049 <pqcrystals_kyber768_ref_poly_tomsg+0x1c1>
  117f5b:	49 39 f7             	cmp    %rsi,%r15
  117f5e:	0f 82 e5 00 00 00    	jb     118049 <pqcrystals_kyber768_ref_poly_tomsg+0x1c1>
  117f64:	45 84 ed             	test   %r13b,%r13b
  117f67:	0f 84 25 01 00 00    	je     118092 <pqcrystals_kyber768_ref_poly_tomsg+0x20a>
  117f6d:	4c 89 f8             	mov    %r15,%rax
  117f70:	48 c1 e8 03          	shr    $0x3,%rax
  117f74:	0f b6 80 00 80 ff 7f 	movzbl 0x7fff8000(%rax),%eax
  117f7b:	84 c0                	test   %al,%al
  117f7d:	75 63                	jne    117fe2 <pqcrystals_kyber768_ref_poly_tomsg+0x15a>
  117f7f:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  117f83:	42 0f bf 04 60       	movswl (%rax,%r12,2),%eax
  117f88:	89 c1                	mov    %eax,%ecx
  117f8a:	c1 e9 0f             	shr    $0xf,%ecx
  117f8d:	81 e1 01 0d 00 00    	and    $0xd01,%ecx
  117f93:	01 c1                	add    %eax,%ecx
  117f95:	0f b7 c1             	movzwl %cx,%eax
  117f98:	8d 04 45 80 06 00 00 	lea    0x680(,%rax,2),%eax
  117f9f:	48 69 d8 b8 af 13 00 	imul   $0x13afb8,%rax,%rbx
  117fa6:	48 c1 eb 20          	shr    $0x20,%rbx
  117faa:	83 e3 01             	and    $0x1,%ebx
  117fad:	44 89 e1             	mov    %r12d,%ecx
  117fb0:	d3 e3                	shl    %cl,%ebx
  117fb2:	84 d2                	test   %dl,%dl
  117fb4:	0f 84 19 01 00 00    	je     1180d3 <pqcrystals_kyber768_ref_poly_tomsg+0x24b>
  117fba:	41 0f b6 86 00 80 ff 	movzbl 0x7fff8000(%r14),%eax
  117fc1:	7f 
  117fc2:	84 c0                	test   %al,%al
  117fc4:	75 2d                	jne    117ff3 <pqcrystals_kyber768_ref_poly_tomsg+0x16b>
  117fc6:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  117fca:	08 18                	or     %bl,(%rax)
  117fcc:	49 ff c4             	inc    %r12
  117fcf:	49 83 c7 02          	add    $0x2,%r15
  117fd3:	49 83 fc 08          	cmp    $0x8,%r12
  117fd7:	0f 85 63 ff ff ff    	jne    117f40 <pqcrystals_kyber768_ref_poly_tomsg+0xb8>
  117fdd:	e9 ee fe ff ff       	jmp    117ed0 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
  117fe2:	44 89 f9             	mov    %r15d,%ecx
  117fe5:	80 e1 07             	and    $0x7,%cl
  117fe8:	fe c1                	inc    %cl
  117fea:	38 c1                	cmp    %al,%cl
  117fec:	7c 91                	jl     117f7f <pqcrystals_kyber768_ref_poly_tomsg+0xf7>
  117fee:	e9 d9 01 00 00       	jmp    1181cc <pqcrystals_kyber768_ref_poly_tomsg+0x344>
  117ff3:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  117ff7:	80 e1 07             	and    $0x7,%cl
  117ffa:	38 c1                	cmp    %al,%cl
  117ffc:	7c c8                	jl     117fc6 <pqcrystals_kyber768_ref_poly_tomsg+0x13e>
  117ffe:	e9 d1 01 00 00       	jmp    1181d4 <pqcrystals_kyber768_ref_poly_tomsg+0x34c>
  118003:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  118007:	4c 89 df             	mov    %r11,%rdi
  11800a:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11800e:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  118012:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  118016:	e8 55 ff fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  11801b:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  11801f:	4c 8d 1d 2a b5 04 00 	lea    0x4b52a(%rip),%r11        # 163550 <_ZL17kSuppressionTypes+0x1b00>
  118026:	4c 8d 15 43 b5 04 00 	lea    0x4b543(%rip),%r10        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  11802d:	4c 8d 0d 4c b5 04 00 	lea    0x4b54c(%rip),%r9        # 163580 <_ZL17kSuppressionTypes+0x1b30>
  118034:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  118038:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  11803c:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  118040:	48 85 f6             	test   %rsi,%rsi
  118043:	0f 85 09 ff ff ff    	jne    117f52 <pqcrystals_kyber768_ref_poly_tomsg+0xca>
  118049:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  11804d:	4c 89 d7             	mov    %r10,%rdi
  118050:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  118054:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  118058:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  11805c:	4c 89 fa             	mov    %r15,%rdx
  11805f:	e8 5c 35 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  118064:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  118068:	4c 8d 1d e1 b4 04 00 	lea    0x4b4e1(%rip),%r11        # 163550 <_ZL17kSuppressionTypes+0x1b00>
  11806f:	4c 8d 15 fa b4 04 00 	lea    0x4b4fa(%rip),%r10        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  118076:	4c 8d 0d 03 b5 04 00 	lea    0x4b503(%rip),%r9        # 163580 <_ZL17kSuppressionTypes+0x1b30>
  11807d:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  118081:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  118085:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  118089:	45 84 ed             	test   %r13b,%r13b
  11808c:	0f 85 db fe ff ff    	jne    117f6d <pqcrystals_kyber768_ref_poly_tomsg+0xe5>
  118092:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  118096:	4c 89 cf             	mov    %r9,%rdi
  118099:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11809d:	4c 89 fe             	mov    %r15,%rsi
  1180a0:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  1180a4:	e8 c7 fe fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  1180a9:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  1180ad:	4c 8d 1d 9c b4 04 00 	lea    0x4b49c(%rip),%r11        # 163550 <_ZL17kSuppressionTypes+0x1b00>
  1180b4:	4c 8d 15 b5 b4 04 00 	lea    0x4b4b5(%rip),%r10        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  1180bb:	4c 8d 0d be b4 04 00 	lea    0x4b4be(%rip),%r9        # 163580 <_ZL17kSuppressionTypes+0x1b30>
  1180c2:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  1180c6:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  1180ca:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1180ce:	e9 9a fe ff ff       	jmp    117f6d <pqcrystals_kyber768_ref_poly_tomsg+0xe5>
  1180d3:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  1180d7:	48 8d 3d c2 b4 04 00 	lea    0x4b4c2(%rip),%rdi        # 1635a0 <_ZL17kSuppressionTypes+0x1b50>
  1180de:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  1180e2:	48 8b 75 c0          	mov    -0x40(%rbp),%rsi
  1180e6:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  1180ea:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  1180ee:	e8 cd 34 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  1180f3:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  1180f7:	4c 8d 1d 52 b4 04 00 	lea    0x4b452(%rip),%r11        # 163550 <_ZL17kSuppressionTypes+0x1b00>
  1180fe:	4c 8d 15 6b b4 04 00 	lea    0x4b46b(%rip),%r10        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  118105:	4c 8d 0d 74 b4 04 00 	lea    0x4b474(%rip),%r9        # 163580 <_ZL17kSuppressionTypes+0x1b30>
  11810c:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  118110:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  118114:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  118118:	e9 9d fe ff ff       	jmp    117fba <pqcrystals_kyber768_ref_poly_tomsg+0x132>
  11811d:	89 d1                	mov    %edx,%ecx
  11811f:	80 e1 07             	and    $0x7,%cl
  118122:	38 c1                	cmp    %al,%cl
  118124:	0f 8c 0a fe ff ff    	jl     117f34 <pqcrystals_kyber768_ref_poly_tomsg+0xac>
  11812a:	e9 ae 00 00 00       	jmp    1181dd <pqcrystals_kyber768_ref_poly_tomsg+0x355>
  11812f:	49 89 ff             	mov    %rdi,%r15
  118132:	48 8d 3d e7 b3 04 00 	lea    0x4b3e7(%rip),%rdi        # 163520 <_ZL17kSuppressionTypes+0x1ad0>
  118139:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11813d:	4c 89 fe             	mov    %r15,%rsi
  118140:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  118144:	4c 89 cb             	mov    %r9,%rbx
  118147:	4d 89 de             	mov    %r11,%r14
  11814a:	e8 71 34 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  11814f:	4d 89 f3             	mov    %r14,%r11
  118152:	4c 8d 15 17 b4 04 00 	lea    0x4b417(%rip),%r10        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  118159:	49 89 d9             	mov    %rbx,%r9
  11815c:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  118160:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  118164:	4c 89 ff             	mov    %r15,%rdi
  118167:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  11816b:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  11816f:	48 85 ff             	test   %rdi,%rdi
  118172:	0f 85 a5 fd ff ff    	jne    117f1d <pqcrystals_kyber768_ref_poly_tomsg+0x95>
  118178:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  11817c:	48 8d 3d ad b3 04 00 	lea    0x4b3ad(%rip),%rdi        # 163530 <_ZL17kSuppressionTypes+0x1ae0>
  118183:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  118187:	48 89 d6             	mov    %rdx,%rsi
  11818a:	4d 89 c7             	mov    %r8,%r15
  11818d:	4c 89 cb             	mov    %r9,%rbx
  118190:	4d 89 d6             	mov    %r10,%r14
  118193:	e8 d8 fd fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  118198:	4c 8d 1d b1 b3 04 00 	lea    0x4b3b1(%rip),%r11        # 163550 <_ZL17kSuppressionTypes+0x1b00>
  11819f:	4d 89 f2             	mov    %r14,%r10
  1181a2:	49 89 d9             	mov    %rbx,%r9
  1181a5:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  1181a9:	4d 89 f8             	mov    %r15,%r8
  1181ac:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  1181b0:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  1181b4:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1181b8:	e9 60 fd ff ff       	jmp    117f1d <pqcrystals_kyber768_ref_poly_tomsg+0x95>
  1181bd:	48 83 c4 38          	add    $0x38,%rsp
  1181c1:	5b                   	pop    %rbx
  1181c2:	41 5c                	pop    %r12
  1181c4:	41 5d                	pop    %r13
  1181c6:	41 5e                	pop    %r14
  1181c8:	41 5f                	pop    %r15
  1181ca:	5d                   	pop    %rbp
  1181cb:	c3                   	ret
  1181cc:	4c 89 ff             	mov    %r15,%rdi
  1181cf:	e8 cc ea fb ff       	call   d6ca0 <__asan_report_load2>
  1181d4:	48 8b 7d b0          	mov    -0x50(%rbp),%rdi
  1181d8:	e8 03 ea fb ff       	call   d6be0 <__asan_report_load1>
  1181dd:	48 89 d7             	mov    %rdx,%rdi
  1181e0:	e8 bb ed fb ff       	call   d6fa0 <__asan_report_store1>

Disassembly of section .fini:
