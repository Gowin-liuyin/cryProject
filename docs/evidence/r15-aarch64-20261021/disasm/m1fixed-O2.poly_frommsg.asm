0000000000004c00 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4c00:	f81d0ffe 	str	x30, [sp, #-48]!
    4c04:	a90157f6 	stp	x22, x21, [sp, #16]
    4c08:	a9024ff4 	stp	x20, x19, [sp, #32]
    4c0c:	aa0103f3 	mov	x19, x1
    4c10:	aa0003f4 	mov	x20, x0
    4c14:	aa1f03f6 	mov	x22, xzr
    4c18:	8b160295 	add	x21, x20, x22
    4c1c:	5280d021 	mov	w1, #0x681                 	// #1665
    4c20:	790002bf 	strh	wzr, [x21]
    4c24:	aa1503e0 	mov	x0, x21
    4c28:	39400268 	ldrb	w8, [x19]
    4c2c:	12000102 	and	w2, w8, #0x1
    4c30:	97fff40f 	bl	1c6c <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4c34:	aa1503e0 	mov	x0, x21
    4c38:	5280d021 	mov	w1, #0x681                 	// #1665
    4c3c:	78002c1f 	strh	wzr, [x0, #2]!
    4c40:	39400268 	ldrb	w8, [x19]
    4c44:	53010502 	ubfx	w2, w8, #1, #1
    4c48:	97fff409 	bl	1c6c <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4c4c:	aa1503e0 	mov	x0, x21
    4c50:	5280d021 	mov	w1, #0x681                 	// #1665
    4c54:	78004c1f 	strh	wzr, [x0, #4]!
    4c58:	39400268 	ldrb	w8, [x19]
    4c5c:	53020902 	ubfx	w2, w8, #2, #1
    4c60:	97fff403 	bl	1c6c <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4c64:	aa1503e0 	mov	x0, x21
    4c68:	5280d021 	mov	w1, #0x681                 	// #1665
    4c6c:	78006c1f 	strh	wzr, [x0, #6]!
    4c70:	39400268 	ldrb	w8, [x19]
    4c74:	53030d02 	ubfx	w2, w8, #3, #1
    4c78:	97fff3fd 	bl	1c6c <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4c7c:	aa1503e0 	mov	x0, x21
    4c80:	5280d021 	mov	w1, #0x681                 	// #1665
    4c84:	78008c1f 	strh	wzr, [x0, #8]!
    4c88:	39400268 	ldrb	w8, [x19]
    4c8c:	53041102 	ubfx	w2, w8, #4, #1
    4c90:	97fff3f7 	bl	1c6c <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4c94:	aa1503e0 	mov	x0, x21
    4c98:	5280d021 	mov	w1, #0x681                 	// #1665
    4c9c:	7800ac1f 	strh	wzr, [x0, #10]!
    4ca0:	39400268 	ldrb	w8, [x19]
    4ca4:	53051502 	ubfx	w2, w8, #5, #1
    4ca8:	97fff3f1 	bl	1c6c <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4cac:	aa1503e0 	mov	x0, x21
    4cb0:	5280d021 	mov	w1, #0x681                 	// #1665
    4cb4:	7800cc1f 	strh	wzr, [x0, #12]!
    4cb8:	39400268 	ldrb	w8, [x19]
    4cbc:	53061902 	ubfx	w2, w8, #6, #1
    4cc0:	97fff3eb 	bl	1c6c <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4cc4:	7800eebf 	strh	wzr, [x21, #14]!
    4cc8:	aa1503e0 	mov	x0, x21
    4ccc:	38401668 	ldrb	w8, [x19], #1
    4cd0:	5280d021 	mov	w1, #0x681                 	// #1665
    4cd4:	53077d02 	lsr	w2, w8, #7
    4cd8:	97fff3e5 	bl	1c6c <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4cdc:	910042d6 	add	x22, x22, #0x10
    4ce0:	f10802df 	cmp	x22, #0x200
    4ce4:	54fff9a1 	b.ne	4c18 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x18>  // b.any
    4ce8:	a9424ff4 	ldp	x20, x19, [sp, #32]
    4cec:	a94157f6 	ldp	x22, x21, [sp, #16]
    4cf0:	f84307fe 	ldr	x30, [sp], #48
    4cf4:	d65f03c0 	ret

