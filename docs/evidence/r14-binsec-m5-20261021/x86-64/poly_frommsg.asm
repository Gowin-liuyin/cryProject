0000000000005ec0 <baseline_native_poly_frommsg>:
    5ec0:	f3 0f 1e fa          	endbr64
    5ec4:	49 89 f8             	mov    %rdi,%r8
    5ec7:	41 b9 01 00 00 00    	mov    $0x1,%r9d
    5ecd:	31 ff                	xor    %edi,%edi
    5ecf:	90                   	nop
    5ed0:	31 c9                	xor    %ecx,%ecx
    5ed2:	66 0f 1f 44 00 00    	nopw   0x0(%rax,%rax,1)
    5ed8:	44 89 c8             	mov    %r9d,%eax
    5edb:	d3 e0                	shl    %cl,%eax
    5edd:	22 06                	and    (%rsi),%al
    5edf:	0f b6 c0             	movzbl %al,%eax
    5ee2:	f7 d8                	neg    %eax
    5ee4:	c1 f8 10             	sar    $0x10,%eax
    5ee7:	8d 14 39             	lea    (%rcx,%rdi,1),%edx
    5eea:	83 c1 01             	add    $0x1,%ecx
    5eed:	66 25 81 06          	and    $0x681,%ax
    5ef1:	66 41 89 04 50       	mov    %ax,(%r8,%rdx,2)
    5ef6:	83 f9 08             	cmp    $0x8,%ecx
    5ef9:	75 dd                	jne    5ed8 <baseline_native_poly_frommsg+0x18>
    5efb:	83 c7 08             	add    $0x8,%edi
    5efe:	48 83 c6 01          	add    $0x1,%rsi
    5f02:	81 ff 00 01 00 00    	cmp    $0x100,%edi
    5f08:	75 c6                	jne    5ed0 <baseline_native_poly_frommsg+0x10>
    5f0a:	c3                   	ret
    5f0b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

