0000000000004c98 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4c98:	f81d0ffe 	str	x30, [sp, #-48]!
    4c9c:	a90157f6 	stp	x22, x21, [sp, #16]
    4ca0:	a9024ff4 	stp	x20, x19, [sp, #32]
    4ca4:	aa0103f3 	mov	x19, x1
    4ca8:	aa0003f4 	mov	x20, x0
    4cac:	aa1f03f6 	mov	x22, xzr
    4cb0:	8b160295 	add	x21, x20, x22
    4cb4:	5280d021 	mov	w1, #0x681                 	// #1665
    4cb8:	790002bf 	strh	wzr, [x21]
    4cbc:	aa1503e0 	mov	x0, x21
    4cc0:	39400268 	ldrb	w8, [x19]
    4cc4:	12000102 	and	w2, w8, #0x1
    4cc8:	97fff40f 	bl	1d04 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4ccc:	aa1503e0 	mov	x0, x21
    4cd0:	5280d021 	mov	w1, #0x681                 	// #1665
    4cd4:	78002c1f 	strh	wzr, [x0, #2]!
    4cd8:	39400268 	ldrb	w8, [x19]
    4cdc:	53010502 	ubfx	w2, w8, #1, #1
    4ce0:	97fff409 	bl	1d04 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4ce4:	aa1503e0 	mov	x0, x21
    4ce8:	5280d021 	mov	w1, #0x681                 	// #1665
    4cec:	78004c1f 	strh	wzr, [x0, #4]!
    4cf0:	39400268 	ldrb	w8, [x19]
    4cf4:	53020902 	ubfx	w2, w8, #2, #1
    4cf8:	97fff403 	bl	1d04 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4cfc:	aa1503e0 	mov	x0, x21
    4d00:	5280d021 	mov	w1, #0x681                 	// #1665
    4d04:	78006c1f 	strh	wzr, [x0, #6]!
    4d08:	39400268 	ldrb	w8, [x19]
    4d0c:	53030d02 	ubfx	w2, w8, #3, #1
    4d10:	97fff3fd 	bl	1d04 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4d14:	aa1503e0 	mov	x0, x21
    4d18:	5280d021 	mov	w1, #0x681                 	// #1665
    4d1c:	78008c1f 	strh	wzr, [x0, #8]!
    4d20:	39400268 	ldrb	w8, [x19]
    4d24:	53041102 	ubfx	w2, w8, #4, #1
    4d28:	97fff3f7 	bl	1d04 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4d2c:	aa1503e0 	mov	x0, x21
    4d30:	5280d021 	mov	w1, #0x681                 	// #1665
    4d34:	7800ac1f 	strh	wzr, [x0, #10]!
    4d38:	39400268 	ldrb	w8, [x19]
    4d3c:	53051502 	ubfx	w2, w8, #5, #1
    4d40:	97fff3f1 	bl	1d04 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4d44:	aa1503e0 	mov	x0, x21
    4d48:	5280d021 	mov	w1, #0x681                 	// #1665
    4d4c:	7800cc1f 	strh	wzr, [x0, #12]!
    4d50:	39400268 	ldrb	w8, [x19]
    4d54:	53061902 	ubfx	w2, w8, #6, #1
    4d58:	97fff3eb 	bl	1d04 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4d5c:	7800eebf 	strh	wzr, [x21, #14]!
    4d60:	aa1503e0 	mov	x0, x21
    4d64:	38401668 	ldrb	w8, [x19], #1
    4d68:	5280d021 	mov	w1, #0x681                 	// #1665
    4d6c:	53077d02 	lsr	w2, w8, #7
    4d70:	97fff3e5 	bl	1d04 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4d74:	910042d6 	add	x22, x22, #0x10
    4d78:	f10802df 	cmp	x22, #0x200
    4d7c:	54fff9a1 	b.ne	4cb0 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x18>  // b.any
    4d80:	a9424ff4 	ldp	x20, x19, [sp, #32]
    4d84:	a94157f6 	ldp	x22, x21, [sp, #16]
    4d88:	f84307fe 	ldr	x30, [sp], #48
    4d8c:	d65f03c0 	ret

