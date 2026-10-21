0000000000004f0c <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4f0c:	f81d0ffe 	str	x30, [sp, #-48]!
    4f10:	a90157f6 	stp	x22, x21, [sp, #16]
    4f14:	a9024ff4 	stp	x20, x19, [sp, #32]
    4f18:	aa0103f3 	mov	x19, x1
    4f1c:	aa0003f4 	mov	x20, x0
    4f20:	aa1f03f6 	mov	x22, xzr
    4f24:	8b160295 	add	x21, x20, x22
    4f28:	5280d021 	mov	w1, #0x681                 	// #1665
    4f2c:	790002bf 	strh	wzr, [x21]
    4f30:	aa1503e0 	mov	x0, x21
    4f34:	39400268 	ldrb	w8, [x19]
    4f38:	12000102 	and	w2, w8, #0x1
    4f3c:	97fff40f 	bl	1f78 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4f40:	aa1503e0 	mov	x0, x21
    4f44:	5280d021 	mov	w1, #0x681                 	// #1665
    4f48:	78002c1f 	strh	wzr, [x0, #2]!
    4f4c:	39400268 	ldrb	w8, [x19]
    4f50:	53010502 	ubfx	w2, w8, #1, #1
    4f54:	97fff409 	bl	1f78 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4f58:	aa1503e0 	mov	x0, x21
    4f5c:	5280d021 	mov	w1, #0x681                 	// #1665
    4f60:	78004c1f 	strh	wzr, [x0, #4]!
    4f64:	39400268 	ldrb	w8, [x19]
    4f68:	53020902 	ubfx	w2, w8, #2, #1
    4f6c:	97fff403 	bl	1f78 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4f70:	aa1503e0 	mov	x0, x21
    4f74:	5280d021 	mov	w1, #0x681                 	// #1665
    4f78:	78006c1f 	strh	wzr, [x0, #6]!
    4f7c:	39400268 	ldrb	w8, [x19]
    4f80:	53030d02 	ubfx	w2, w8, #3, #1
    4f84:	97fff3fd 	bl	1f78 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4f88:	aa1503e0 	mov	x0, x21
    4f8c:	5280d021 	mov	w1, #0x681                 	// #1665
    4f90:	78008c1f 	strh	wzr, [x0, #8]!
    4f94:	39400268 	ldrb	w8, [x19]
    4f98:	53041102 	ubfx	w2, w8, #4, #1
    4f9c:	97fff3f7 	bl	1f78 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4fa0:	aa1503e0 	mov	x0, x21
    4fa4:	5280d021 	mov	w1, #0x681                 	// #1665
    4fa8:	7800ac1f 	strh	wzr, [x0, #10]!
    4fac:	39400268 	ldrb	w8, [x19]
    4fb0:	53051502 	ubfx	w2, w8, #5, #1
    4fb4:	97fff3f1 	bl	1f78 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4fb8:	aa1503e0 	mov	x0, x21
    4fbc:	5280d021 	mov	w1, #0x681                 	// #1665
    4fc0:	7800cc1f 	strh	wzr, [x0, #12]!
    4fc4:	39400268 	ldrb	w8, [x19]
    4fc8:	53061902 	ubfx	w2, w8, #6, #1
    4fcc:	97fff3eb 	bl	1f78 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4fd0:	7800eebf 	strh	wzr, [x21, #14]!
    4fd4:	aa1503e0 	mov	x0, x21
    4fd8:	38401668 	ldrb	w8, [x19], #1
    4fdc:	5280d021 	mov	w1, #0x681                 	// #1665
    4fe0:	53077d02 	lsr	w2, w8, #7
    4fe4:	97fff3e5 	bl	1f78 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4fe8:	910042d6 	add	x22, x22, #0x10
    4fec:	f10802df 	cmp	x22, #0x200
    4ff0:	54fff9a1 	b.ne	4f24 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x18>  // b.any
    4ff4:	a9424ff4 	ldp	x20, x19, [sp, #32]
    4ff8:	a94157f6 	ldp	x22, x21, [sp, #16]
    4ffc:	f84307fe 	ldr	x30, [sp], #48
    5000:	d65f03c0 	ret

