
/home/nss-marker/yhr/Cry/platform-m2micro-20261016-0551254c9579/build-sanitize/microbench/fixed/m2_hotspot_microbench：     文件格式 elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .text:

0000000000117ea8 <pqcrystals_kyber768_ref_poly_tomsg>:
  117ea8:	55                   	push   %rbp
  117ea9:	48 89 e5             	mov    %rsp,%rbp
  117eac:	41 57                	push   %r15
  117eae:	41 56                	push   %r14
  117eb0:	41 55                	push   %r13
  117eb2:	41 54                	push   %r12
  117eb4:	53                   	push   %rbx
  117eb5:	48 83 ec 38          	sub    $0x38,%rsp
  117eb9:	48 85 f6             	test   %rsi,%rsi
  117ebc:	0f 95 c0             	setne  %al
  117ebf:	40 f6 c6 01          	test   $0x1,%sil
  117ec3:	41 0f 94 c5          	sete   %r13b
  117ec7:	41 20 c5             	and    %al,%r13b
  117eca:	45 31 c0             	xor    %r8d,%r8d
  117ecd:	4c 8d 0d cc b6 04 00 	lea    0x4b6cc(%rip),%r9        # 1635a0 <_ZL17kSuppressionTypes+0x1b50>
  117ed4:	4c 8d 15 b5 b6 04 00 	lea    0x4b6b5(%rip),%r10        # 163590 <_ZL17kSuppressionTypes+0x1b40>
  117edb:	4c 8d 1d 8e b6 04 00 	lea    0x4b68e(%rip),%r11        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  117ee2:	48 89 75 a0          	mov    %rsi,-0x60(%rbp)
  117ee6:	49 89 f7             	mov    %rsi,%r15
  117ee9:	eb 1f                	jmp    117f0a <pqcrystals_kyber768_ref_poly_tomsg+0x62>
  117eeb:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)
  117ef0:	49 ff c0             	inc    %r8
  117ef3:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  117ef7:	49 83 c7 10          	add    $0x10,%r15
  117efb:	48 83 45 a0 10       	addq   $0x10,-0x60(%rbp)
  117f00:	49 83 f8 20          	cmp    $0x20,%r8
  117f04:	0f 84 c0 02 00 00    	je     1181ca <pqcrystals_kyber768_ref_poly_tomsg+0x322>
  117f0a:	48 85 ff             	test   %rdi,%rdi
  117f0d:	0f 95 c0             	setne  %al
  117f10:	48 89 fa             	mov    %rdi,%rdx
  117f13:	4c 01 c2             	add    %r8,%rdx
  117f16:	0f 95 c3             	setne  %bl
  117f19:	48 39 fa             	cmp    %rdi,%rdx
  117f1c:	0f 93 c1             	setae  %cl
  117f1f:	20 c3                	and    %al,%bl
  117f21:	20 cb                	and    %cl,%bl
  117f23:	88 5d d7             	mov    %bl,-0x29(%rbp)
  117f26:	48 89 55 b0          	mov    %rdx,-0x50(%rbp)
  117f2a:	4c 89 7d a8          	mov    %r15,-0x58(%rbp)
  117f2e:	0f 84 08 02 00 00    	je     11813c <pqcrystals_kyber768_ref_poly_tomsg+0x294>
  117f34:	48 85 ff             	test   %rdi,%rdi
  117f37:	0f 84 48 02 00 00    	je     118185 <pqcrystals_kyber768_ref_poly_tomsg+0x2dd>
  117f3d:	49 89 d6             	mov    %rdx,%r14
  117f40:	49 c1 ee 03          	shr    $0x3,%r14
  117f44:	41 0f b6 86 00 80 ff 	movzbl 0x7fff8000(%r14),%eax
  117f4b:	7f 
  117f4c:	84 c0                	test   %al,%al
  117f4e:	0f 85 d6 01 00 00    	jne    11812a <pqcrystals_kyber768_ref_poly_tomsg+0x282>
  117f54:	c6 02 00             	movb   $0x0,(%rdx)
  117f57:	45 31 e4             	xor    %r12d,%r12d
  117f5a:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  117f5e:	66 90                	xchg   %ax,%ax
  117f60:	45 84 ed             	test   %r13b,%r13b
  117f63:	0f 84 a7 00 00 00    	je     118010 <pqcrystals_kyber768_ref_poly_tomsg+0x168>
  117f69:	48 85 f6             	test   %rsi,%rsi
  117f6c:	0f 84 e4 00 00 00    	je     118056 <pqcrystals_kyber768_ref_poly_tomsg+0x1ae>
  117f72:	4d 85 ff             	test   %r15,%r15
  117f75:	0f 84 db 00 00 00    	je     118056 <pqcrystals_kyber768_ref_poly_tomsg+0x1ae>
  117f7b:	49 39 f7             	cmp    %rsi,%r15
  117f7e:	0f 82 d2 00 00 00    	jb     118056 <pqcrystals_kyber768_ref_poly_tomsg+0x1ae>
  117f84:	45 84 ed             	test   %r13b,%r13b
  117f87:	0f 84 12 01 00 00    	je     11809f <pqcrystals_kyber768_ref_poly_tomsg+0x1f7>
  117f8d:	4c 89 f8             	mov    %r15,%rax
  117f90:	48 c1 e8 03          	shr    $0x3,%rax
  117f94:	0f b6 80 00 80 ff 7f 	movzbl 0x7fff8000(%rax),%eax
  117f9b:	84 c0                	test   %al,%al
  117f9d:	75 50                	jne    117fef <pqcrystals_kyber768_ref_poly_tomsg+0x147>
  117f9f:	48 8b 45 a0          	mov    -0x60(%rbp),%rax
  117fa3:	42 0f bf 04 60       	movswl (%rax,%r12,2),%eax
  117fa8:	69 d8 f6 75 02 00    	imul   $0x275f6,%eax,%ebx
  117fae:	81 c3 7b 9a 00 08    	add    $0x8009a7b,%ebx
  117fb4:	c1 eb 1c             	shr    $0x1c,%ebx
  117fb7:	83 e3 01             	and    $0x1,%ebx
  117fba:	44 89 e1             	mov    %r12d,%ecx
  117fbd:	d3 e3                	shl    %cl,%ebx
  117fbf:	84 d2                	test   %dl,%dl
  117fc1:	0f 84 19 01 00 00    	je     1180e0 <pqcrystals_kyber768_ref_poly_tomsg+0x238>
  117fc7:	41 0f b6 86 00 80 ff 	movzbl 0x7fff8000(%r14),%eax
  117fce:	7f 
  117fcf:	84 c0                	test   %al,%al
  117fd1:	75 2d                	jne    118000 <pqcrystals_kyber768_ref_poly_tomsg+0x158>
  117fd3:	48 8b 45 b0          	mov    -0x50(%rbp),%rax
  117fd7:	08 18                	or     %bl,(%rax)
  117fd9:	49 ff c4             	inc    %r12
  117fdc:	49 83 c7 02          	add    $0x2,%r15
  117fe0:	49 83 fc 08          	cmp    $0x8,%r12
  117fe4:	0f 85 76 ff ff ff    	jne    117f60 <pqcrystals_kyber768_ref_poly_tomsg+0xb8>
  117fea:	e9 01 ff ff ff       	jmp    117ef0 <pqcrystals_kyber768_ref_poly_tomsg+0x48>
  117fef:	44 89 f9             	mov    %r15d,%ecx
  117ff2:	80 e1 07             	and    $0x7,%cl
  117ff5:	fe c1                	inc    %cl
  117ff7:	38 c1                	cmp    %al,%cl
  117ff9:	7c a4                	jl     117f9f <pqcrystals_kyber768_ref_poly_tomsg+0xf7>
  117ffb:	e9 d9 01 00 00       	jmp    1181d9 <pqcrystals_kyber768_ref_poly_tomsg+0x331>
  118000:	48 8b 4d b0          	mov    -0x50(%rbp),%rcx
  118004:	80 e1 07             	and    $0x7,%cl
  118007:	38 c1                	cmp    %al,%cl
  118009:	7c c8                	jl     117fd3 <pqcrystals_kyber768_ref_poly_tomsg+0x12b>
  11800b:	e9 d1 01 00 00       	jmp    1181e1 <pqcrystals_kyber768_ref_poly_tomsg+0x339>
  118010:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  118014:	4c 89 df             	mov    %r11,%rdi
  118017:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11801b:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  11801f:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  118023:	e8 48 ff fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  118028:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  11802c:	4c 8d 1d 3d b5 04 00 	lea    0x4b53d(%rip),%r11        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  118033:	4c 8d 15 56 b5 04 00 	lea    0x4b556(%rip),%r10        # 163590 <_ZL17kSuppressionTypes+0x1b40>
  11803a:	4c 8d 0d 5f b5 04 00 	lea    0x4b55f(%rip),%r9        # 1635a0 <_ZL17kSuppressionTypes+0x1b50>
  118041:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  118045:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  118049:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  11804d:	48 85 f6             	test   %rsi,%rsi
  118050:	0f 85 1c ff ff ff    	jne    117f72 <pqcrystals_kyber768_ref_poly_tomsg+0xca>
  118056:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  11805a:	4c 89 d7             	mov    %r10,%rdi
  11805d:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  118061:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  118065:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  118069:	4c 89 fa             	mov    %r15,%rdx
  11806c:	e8 4f 35 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  118071:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  118075:	4c 8d 1d f4 b4 04 00 	lea    0x4b4f4(%rip),%r11        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  11807c:	4c 8d 15 0d b5 04 00 	lea    0x4b50d(%rip),%r10        # 163590 <_ZL17kSuppressionTypes+0x1b40>
  118083:	4c 8d 0d 16 b5 04 00 	lea    0x4b516(%rip),%r9        # 1635a0 <_ZL17kSuppressionTypes+0x1b50>
  11808a:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  11808e:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  118092:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  118096:	45 84 ed             	test   %r13b,%r13b
  118099:	0f 85 ee fe ff ff    	jne    117f8d <pqcrystals_kyber768_ref_poly_tomsg+0xe5>
  11809f:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  1180a3:	4c 89 cf             	mov    %r9,%rdi
  1180a6:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  1180aa:	4c 89 fe             	mov    %r15,%rsi
  1180ad:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  1180b1:	e8 ba fe fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  1180b6:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  1180ba:	4c 8d 1d af b4 04 00 	lea    0x4b4af(%rip),%r11        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  1180c1:	4c 8d 15 c8 b4 04 00 	lea    0x4b4c8(%rip),%r10        # 163590 <_ZL17kSuppressionTypes+0x1b40>
  1180c8:	4c 8d 0d d1 b4 04 00 	lea    0x4b4d1(%rip),%r9        # 1635a0 <_ZL17kSuppressionTypes+0x1b50>
  1180cf:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  1180d3:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  1180d7:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1180db:	e9 ad fe ff ff       	jmp    117f8d <pqcrystals_kyber768_ref_poly_tomsg+0xe5>
  1180e0:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  1180e4:	48 8d 3d d5 b4 04 00 	lea    0x4b4d5(%rip),%rdi        # 1635c0 <_ZL17kSuppressionTypes+0x1b70>
  1180eb:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  1180ef:	48 8b 75 c0          	mov    -0x40(%rbp),%rsi
  1180f3:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  1180f7:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  1180fb:	e8 c0 34 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  118100:	0f b6 55 d7          	movzbl -0x29(%rbp),%edx
  118104:	4c 8d 1d 65 b4 04 00 	lea    0x4b465(%rip),%r11        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  11810b:	4c 8d 15 7e b4 04 00 	lea    0x4b47e(%rip),%r10        # 163590 <_ZL17kSuppressionTypes+0x1b40>
  118112:	4c 8d 0d 87 b4 04 00 	lea    0x4b487(%rip),%r9        # 1635a0 <_ZL17kSuppressionTypes+0x1b50>
  118119:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  11811d:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  118121:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  118125:	e9 9d fe ff ff       	jmp    117fc7 <pqcrystals_kyber768_ref_poly_tomsg+0x11f>
  11812a:	89 d1                	mov    %edx,%ecx
  11812c:	80 e1 07             	and    $0x7,%cl
  11812f:	38 c1                	cmp    %al,%cl
  118131:	0f 8c 1d fe ff ff    	jl     117f54 <pqcrystals_kyber768_ref_poly_tomsg+0xac>
  118137:	e9 ae 00 00 00       	jmp    1181ea <pqcrystals_kyber768_ref_poly_tomsg+0x342>
  11813c:	49 89 ff             	mov    %rdi,%r15
  11813f:	48 8d 3d fa b3 04 00 	lea    0x4b3fa(%rip),%rdi        # 163540 <_ZL17kSuppressionTypes+0x1af0>
  118146:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  11814a:	4c 89 fe             	mov    %r15,%rsi
  11814d:	4c 89 45 b8          	mov    %r8,-0x48(%rbp)
  118151:	4c 89 cb             	mov    %r9,%rbx
  118154:	4d 89 de             	mov    %r11,%r14
  118157:	e8 64 34 ff ff       	call   10b5c0 <__ubsan_handle_pointer_overflow>
  11815c:	4d 89 f3             	mov    %r14,%r11
  11815f:	4c 8d 15 2a b4 04 00 	lea    0x4b42a(%rip),%r10        # 163590 <_ZL17kSuppressionTypes+0x1b40>
  118166:	49 89 d9             	mov    %rbx,%r9
  118169:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  11816d:	4c 8b 45 b8          	mov    -0x48(%rbp),%r8
  118171:	4c 89 ff             	mov    %r15,%rdi
  118174:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  118178:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  11817c:	48 85 ff             	test   %rdi,%rdi
  11817f:	0f 85 b8 fd ff ff    	jne    117f3d <pqcrystals_kyber768_ref_poly_tomsg+0x95>
  118185:	48 89 7d c0          	mov    %rdi,-0x40(%rbp)
  118189:	48 8d 3d c0 b3 04 00 	lea    0x4b3c0(%rip),%rdi        # 163550 <_ZL17kSuppressionTypes+0x1b00>
  118190:	48 89 75 c8          	mov    %rsi,-0x38(%rbp)
  118194:	48 89 d6             	mov    %rdx,%rsi
  118197:	4d 89 c7             	mov    %r8,%r15
  11819a:	4c 89 cb             	mov    %r9,%rbx
  11819d:	4d 89 d6             	mov    %r10,%r14
  1181a0:	e8 cb fd fe ff       	call   107f70 <__ubsan_handle_type_mismatch_v1>
  1181a5:	4c 8d 1d c4 b3 04 00 	lea    0x4b3c4(%rip),%r11        # 163570 <_ZL17kSuppressionTypes+0x1b20>
  1181ac:	4d 89 f2             	mov    %r14,%r10
  1181af:	49 89 d9             	mov    %rbx,%r9
  1181b2:	48 8b 55 b0          	mov    -0x50(%rbp),%rdx
  1181b6:	4d 89 f8             	mov    %r15,%r8
  1181b9:	4c 8b 7d a8          	mov    -0x58(%rbp),%r15
  1181bd:	48 8b 7d c0          	mov    -0x40(%rbp),%rdi
  1181c1:	48 8b 75 c8          	mov    -0x38(%rbp),%rsi
  1181c5:	e9 73 fd ff ff       	jmp    117f3d <pqcrystals_kyber768_ref_poly_tomsg+0x95>
  1181ca:	48 83 c4 38          	add    $0x38,%rsp
  1181ce:	5b                   	pop    %rbx
  1181cf:	41 5c                	pop    %r12
  1181d1:	41 5d                	pop    %r13
  1181d3:	41 5e                	pop    %r14
  1181d5:	41 5f                	pop    %r15
  1181d7:	5d                   	pop    %rbp
  1181d8:	c3                   	ret
  1181d9:	4c 89 ff             	mov    %r15,%rdi
  1181dc:	e8 bf ea fb ff       	call   d6ca0 <__asan_report_load2>
  1181e1:	48 8b 7d b0          	mov    -0x50(%rbp),%rdi
  1181e5:	e8 f6 e9 fb ff       	call   d6be0 <__asan_report_load1>
  1181ea:	48 89 d7             	mov    %rdx,%rdi
  1181ed:	e8 ae ed fb ff       	call   d6fa0 <__asan_report_store1>

Disassembly of section .fini:
