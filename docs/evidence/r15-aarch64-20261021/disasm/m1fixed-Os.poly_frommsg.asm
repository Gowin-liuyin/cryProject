0000000000004b4c <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4b4c:	f81d0ffe 	str	x30, [sp, #-48]!
    4b50:	a90157f6 	stp	x22, x21, [sp, #16]
    4b54:	a9024ff4 	stp	x20, x19, [sp, #32]
    4b58:	aa0103f3 	mov	x19, x1
    4b5c:	aa0003f4 	mov	x20, x0
    4b60:	aa1f03f6 	mov	x22, xzr
    4b64:	8b160295 	add	x21, x20, x22
    4b68:	5280d021 	mov	w1, #0x681                 	// #1665
    4b6c:	790002bf 	strh	wzr, [x21]
    4b70:	aa1503e0 	mov	x0, x21
    4b74:	39400268 	ldrb	w8, [x19]
    4b78:	12000102 	and	w2, w8, #0x1
    4b7c:	97fff40f 	bl	1bb8 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4b80:	aa1503e0 	mov	x0, x21
    4b84:	5280d021 	mov	w1, #0x681                 	// #1665
    4b88:	78002c1f 	strh	wzr, [x0, #2]!
    4b8c:	39400268 	ldrb	w8, [x19]
    4b90:	53010502 	ubfx	w2, w8, #1, #1
    4b94:	97fff409 	bl	1bb8 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4b98:	aa1503e0 	mov	x0, x21
    4b9c:	5280d021 	mov	w1, #0x681                 	// #1665
    4ba0:	78004c1f 	strh	wzr, [x0, #4]!
    4ba4:	39400268 	ldrb	w8, [x19]
    4ba8:	53020902 	ubfx	w2, w8, #2, #1
    4bac:	97fff403 	bl	1bb8 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4bb0:	aa1503e0 	mov	x0, x21
    4bb4:	5280d021 	mov	w1, #0x681                 	// #1665
    4bb8:	78006c1f 	strh	wzr, [x0, #6]!
    4bbc:	39400268 	ldrb	w8, [x19]
    4bc0:	53030d02 	ubfx	w2, w8, #3, #1
    4bc4:	97fff3fd 	bl	1bb8 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4bc8:	aa1503e0 	mov	x0, x21
    4bcc:	5280d021 	mov	w1, #0x681                 	// #1665
    4bd0:	78008c1f 	strh	wzr, [x0, #8]!
    4bd4:	39400268 	ldrb	w8, [x19]
    4bd8:	53041102 	ubfx	w2, w8, #4, #1
    4bdc:	97fff3f7 	bl	1bb8 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4be0:	aa1503e0 	mov	x0, x21
    4be4:	5280d021 	mov	w1, #0x681                 	// #1665
    4be8:	7800ac1f 	strh	wzr, [x0, #10]!
    4bec:	39400268 	ldrb	w8, [x19]
    4bf0:	53051502 	ubfx	w2, w8, #5, #1
    4bf4:	97fff3f1 	bl	1bb8 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4bf8:	aa1503e0 	mov	x0, x21
    4bfc:	5280d021 	mov	w1, #0x681                 	// #1665
    4c00:	7800cc1f 	strh	wzr, [x0, #12]!
    4c04:	39400268 	ldrb	w8, [x19]
    4c08:	53061902 	ubfx	w2, w8, #6, #1
    4c0c:	97fff3eb 	bl	1bb8 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4c10:	7800eebf 	strh	wzr, [x21, #14]!
    4c14:	aa1503e0 	mov	x0, x21
    4c18:	38401668 	ldrb	w8, [x19], #1
    4c1c:	5280d021 	mov	w1, #0x681                 	// #1665
    4c20:	53077d02 	lsr	w2, w8, #7
    4c24:	97fff3e5 	bl	1bb8 <pqcrystals_ml_kem_768_ipd_ref_cmov_int16>
    4c28:	910042d6 	add	x22, x22, #0x10
    4c2c:	f10802df 	cmp	x22, #0x200
    4c30:	54fff9a1 	b.ne	4b64 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x18>  // b.any
    4c34:	a9424ff4 	ldp	x20, x19, [sp, #32]
    4c38:	a94157f6 	ldp	x22, x21, [sp, #16]
    4c3c:	f84307fe 	ldr	x30, [sp], #48
    4c40:	d65f03c0 	ret

