0000000000002048 <baseline_native_poly_frommsg>:
    2048:	xor    %eax,%eax
    204a:	xor    %ecx,%ecx
    204c:	mov    $0x1,%edx
    2051:	shl    %cl,%edx
    2053:	and    (%rsi,%rax,1),%dl
    2056:	movzbl %dl,%edx
    2059:	neg    %edx
    205b:	shr    $0x10,%edx
    205e:	and    $0x681,%edx
    2064:	mov    %dx,(%rdi,%rcx,2)
    2068:	inc    %rcx
    206b:	cmp    $0x8,%rcx
    206f:	jne    204c <baseline_native_poly_frommsg+0x4>
    2071:	inc    %rax
    2074:	add    $0x10,%rdi
    2078:	cmp    $0x20,%rax
    207c:	jne    204a <baseline_native_poly_frommsg+0x2>
    207e:	ret
