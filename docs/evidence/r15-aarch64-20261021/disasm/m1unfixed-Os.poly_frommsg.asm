0000000000004b2c <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4b2c:	6dbb3bef 	stp	d15, d14, [sp, #-80]!
    4b30:	6d0133ed 	stp	d13, d12, [sp, #16]
    4b34:	6d022beb 	stp	d11, d10, [sp, #32]
    4b38:	6d0323e9 	stp	d9, d8, [sp, #48]
    4b3c:	f90023fd 	str	x29, [sp, #64]
    4b40:	d10b43ff 	sub	sp, sp, #0x2d0
    4b44:	91008028 	add	x8, x1, #0x20
    4b48:	eb00011f 	cmp	x8, x0
    4b4c:	54000589 	b.ls	4bfc <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xd0>  // b.plast
    4b50:	91080008 	add	x8, x0, #0x200
    4b54:	eb01011f 	cmp	x8, x1
    4b58:	54000529 	b.ls	4bfc <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xd0>  // b.plast
    4b5c:	aa1f03e8 	mov	x8, xzr
    4b60:	91002009 	add	x9, x0, #0x8
    4b64:	5280d02a 	mov	w10, #0x681                 	// #1665
    4b68:	3868682b 	ldrb	w11, [x1, x8]
    4b6c:	1300016b 	sbfx	w11, w11, #0, #1
    4b70:	0a0a016b 	and	w11, w11, w10
    4b74:	781f812b 	sturh	w11, [x9, #-8]
    4b78:	3868682b 	ldrb	w11, [x1, x8]
    4b7c:	5302056b 	lsl	w11, w11, #30
    4b80:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4b84:	781fa12b 	sturh	w11, [x9, #-6]
    4b88:	3868682b 	ldrb	w11, [x1, x8]
    4b8c:	5303096b 	lsl	w11, w11, #29
    4b90:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4b94:	781fc12b 	sturh	w11, [x9, #-4]
    4b98:	3868682b 	ldrb	w11, [x1, x8]
    4b9c:	53040d6b 	lsl	w11, w11, #28
    4ba0:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4ba4:	781fe12b 	sturh	w11, [x9, #-2]
    4ba8:	3868682b 	ldrb	w11, [x1, x8]
    4bac:	5305116b 	lsl	w11, w11, #27
    4bb0:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4bb4:	7900012b 	strh	w11, [x9]
    4bb8:	3868682b 	ldrb	w11, [x1, x8]
    4bbc:	5306156b 	lsl	w11, w11, #26
    4bc0:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4bc4:	7900052b 	strh	w11, [x9, #2]
    4bc8:	3868682b 	ldrb	w11, [x1, x8]
    4bcc:	5307196b 	lsl	w11, w11, #25
    4bd0:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4bd4:	7900092b 	strh	w11, [x9, #4]
    4bd8:	38e8682b 	ldrsb	w11, [x1, x8]
    4bdc:	91000508 	add	x8, x8, #0x1
    4be0:	7100017f 	cmp	w11, #0x0
    4be4:	1a8aa3eb 	csel	w11, wzr, w10, ge	// ge = tcont
    4be8:	f100811f 	cmp	x8, #0x20
    4bec:	79000d2b 	strh	w11, [x9, #6]
    4bf0:	91004129 	add	x9, x9, #0x10
    4bf4:	54fffba1 	b.ne	4b68 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x3c>  // b.any
    4bf8:	14000219 	b	545c <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x930>
    4bfc:	4f00e420 	movi	v0.16b, #0x1
    4c00:	4f00e441 	movi	v1.16b, #0x2
    4c04:	3dc00022 	ldr	q2, [x1]
    4c08:	4f02e404 	movi	v4.16b, #0x40
    4c0c:	4f00e487 	movi	v7.16b, #0x4
    4c10:	5280d028 	mov	w8, #0x681                 	// #1665
    4c14:	4f00e611 	movi	v17.16b, #0x10
    4c18:	4f00e506 	movi	v6.16b, #0x8
    4c1c:	900000ab 	adrp	x11, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4c20:	4f01e414 	movi	v20.16b, #0x20
    4c24:	4e020d1a 	dup	v26.8h, w8
    4c28:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4c2c:	4e201c40 	and	v0.16b, v2.16b, v0.16b
    4c30:	4e211c41 	and	v1.16b, v2.16b, v1.16b
    4c34:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4c38:	4e241c44 	and	v4.16b, v2.16b, v4.16b
    4c3c:	4e271c47 	and	v7.16b, v2.16b, v7.16b
    4c40:	900000aa 	adrp	x10, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4c44:	4e311c51 	and	v17.16b, v2.16b, v17.16b
    4c48:	4e261c50 	and	v16.16b, v2.16b, v6.16b
    4c4c:	900000ac 	adrp	x12, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4c50:	4e209803 	cmeq	v3.16b, v0.16b, #0
    4c54:	4e209825 	cmeq	v5.16b, v1.16b, #0
    4c58:	6e208840 	cmge	v0.16b, v2.16b, #0
    4c5c:	4e209881 	cmeq	v1.16b, v4.16b, #0
    4c60:	3dc11d24 	ldr	q4, [x9, #1136]
    4c64:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4c68:	4e341c42 	and	v2.16b, v2.16b, v20.16b
    4c6c:	4e2098f4 	cmeq	v20.16b, v7.16b, #0
    4c70:	4e209a27 	cmeq	v7.16b, v17.16b, #0
    4c74:	4f08a472 	sxtl2	v18.8h, v3.16b
    4c78:	3d809be4 	str	q4, [sp, #608]
    4c7c:	0f08a463 	sxtl	v3.8h, v3.8b
    4c80:	0f08a431 	sxtl	v17.8h, v1.8b
    4c84:	4f08a4b3 	sxtl2	v19.8h, v5.16b
    4c88:	0f08a4b5 	sxtl	v21.8h, v5.8b
    4c8c:	3dc11545 	ldr	q5, [x10, #1104]
    4c90:	900000aa 	adrp	x10, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4c94:	4e209a10 	cmeq	v16.16b, v16.16b, #0
    4c98:	4e631f5c 	bic	v28.16b, v26.16b, v3.16b
    4c9c:	0f08a403 	sxtl	v3.8h, v0.8b
    4ca0:	4e721f4d 	bic	v13.16b, v26.16b, v18.16b
    4ca4:	3d8087e5 	str	q5, [sp, #528]
    4ca8:	4e711f56 	bic	v22.16b, v26.16b, v17.16b
    4cac:	4e209842 	cmeq	v2.16b, v2.16b, #0
    4cb0:	4e731f4e 	bic	v14.16b, v26.16b, v19.16b
    4cb4:	0f08a692 	sxtl	v18.8h, v20.8b
    4cb8:	4f08a693 	sxtl2	v19.8h, v20.16b
    4cbc:	4e631f57 	bic	v23.16b, v26.16b, v3.16b
    4cc0:	3dc0f903 	ldr	q3, [x8, #992]
    4cc4:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4cc8:	4e751f5d 	bic	v29.16b, v26.16b, v21.16b
    4ccc:	0f08a614 	sxtl	v20.8h, v16.8b
    4cd0:	4f08a615 	sxtl2	v21.8h, v16.16b
    4cd4:	3d80abe3 	str	q3, [sp, #672]
    4cd8:	0f08a4f8 	sxtl	v24.8h, v7.8b
    4cdc:	0f08a459 	sxtl	v25.8h, v2.8b
    4ce0:	4e0322c3 	tbl	v3.16b, {v22.16b-v23.16b}, v3.16b
    4ce4:	4e731f48 	bic	v8.16b, v26.16b, v19.16b
    4ce8:	4e721f4a 	bic	v10.16b, v26.16b, v18.16b
    4cec:	4e751f49 	bic	v9.16b, v26.16b, v21.16b
    4cf0:	4e741f4b 	bic	v11.16b, v26.16b, v20.16b
    4cf4:	4eb61ed3 	mov	v19.16b, v22.16b
    4cf8:	4e781f54 	bic	v20.16b, v26.16b, v24.16b
    4cfc:	4f08a406 	sxtl2	v6.8h, v0.16b
    4d00:	3dc12160 	ldr	q0, [x11, #1152]
    4d04:	900000ab 	adrp	x11, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4d08:	4e791f55 	bic	v21.16b, v26.16b, v25.16b
    4d0c:	4f08a4f2 	sxtl2	v18.8h, v7.16b
    4d10:	3d80b3e3 	str	q3, [sp, #704]
    4d14:	3dc10503 	ldr	q3, [x8, #1040]
    4d18:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4d1c:	3dc1111b 	ldr	q27, [x8, #1088]
    4d20:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4d24:	3d807fe0 	str	q0, [sp, #496]
    4d28:	3dc12911 	ldr	q17, [x8, #1184]
    4d2c:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4d30:	3d809fe3 	str	q3, [sp, #624]
    4d34:	4e0322de 	tbl	v30.16b, {v22.16b-v23.16b}, v3.16b
    4d38:	3dc12d03 	ldr	q3, [x8, #1200]
    4d3c:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4d40:	3d80a3f1 	str	q17, [sp, #640]
    4d44:	4e1122d8 	tbl	v24.16b, {v22.16b-v23.16b}, v17.16b
    4d48:	4f08a431 	sxtl2	v17.8h, v1.16b
    4d4c:	3dc0fd01 	ldr	q1, [x8, #1008]
    4d50:	6e1e66f3 	mov	v19.h[7], v23.h[6]
    4d54:	3d8097e3 	str	q3, [sp, #592]
    4d58:	4e0322cc 	tbl	v12.16b, {v22.16b-v23.16b}, v3.16b
    4d5c:	4e002283 	tbl	v3.16b, {v20.16b-v21.16b}, v0.16b
    4d60:	4e556a80 	trn2	v0.8h, v20.8h, v21.8h
    4d64:	3d807be1 	str	q1, [sp, #480]
    4d68:	4e01229f 	tbl	v31.16b, {v20.16b-v21.16b}, v1.16b
    4d6c:	4e557a81 	zip2	v1.8h, v20.8h, v21.8h
    4d70:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4d74:	4f08a447 	sxtl2	v7.8h, v2.16b
    4d78:	4e577acf 	zip2	v15.8h, v22.8h, v23.8h
    4d7c:	3dc13102 	ldr	q2, [x8, #1216]
    4d80:	4e1b22d9 	tbl	v25.16b, {v22.16b-v23.16b}, v27.16b
    4d84:	4e0422d0 	tbl	v16.16b, {v22.16b-v23.16b}, v4.16b
    4d88:	6e1c6580 	mov	v0.s[3], v12.s[3]
    4d8c:	3dc10937 	ldr	q23, [x9, #1056]
    4d90:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4d94:	6e1c6661 	mov	v1.s[3], v19.s[3]
    4d98:	3d8083e2 	str	q2, [sp, #512]
    4d9c:	4e022282 	tbl	v2.16b, {v20.16b-v21.16b}, v2.16b
    4da0:	4e172284 	tbl	v4.16b, {v20.16b-v21.16b}, v23.16b
    4da4:	4e052285 	tbl	v5.16b, {v20.16b-v21.16b}, v5.16b
    4da8:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4dac:	4eb41e96 	mov	v22.16b, v20.16b
    4db0:	6e1c6603 	mov	v3.s[3], v16.s[3]
    4db4:	3d8057f7 	str	q23, [sp, #336]
    4db8:	3d8077fb 	str	q27, [sp, #464]
    4dbc:	4e4e39b0 	zip1	v16.8h, v13.8h, v14.8h
    4dc0:	ad0883e1 	stp	q1, q0, [sp, #272]
    4dc4:	4eaa1d40 	mov	v0.16b, v10.16b
    4dc8:	6e1c65e2 	mov	v2.s[3], v15.s[3]
    4dcc:	6e1c67c4 	mov	v4.s[3], v30.s[3]
    4dd0:	6e1c6725 	mov	v5.s[3], v25.s[3]
    4dd4:	6e1646b6 	mov	v22.h[5], v21.h[4]
    4dd8:	4e4b6941 	trn2	v1.8h, v10.8h, v11.8h
    4ddc:	4e721f54 	bic	v20.16b, v26.16b, v18.16b
    4de0:	4e711f51 	bic	v17.16b, v26.16b, v17.16b
    4de4:	6e0e2560 	mov	v0.h[3], v11.h[2]
    4de8:	4e661f52 	bic	v18.16b, v26.16b, v6.16b
    4dec:	3dc0b3e6 	ldr	q6, [sp, #704]
    4df0:	3d8043e2 	str	q2, [sp, #256]
    4df4:	3dc10d22 	ldr	q2, [x9, #1072]
    4df8:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4dfc:	ad0b13e5 	stp	q5, q4, [sp, #352]
    4e00:	6e1c6716 	mov	v22.s[3], v24.s[3]
    4e04:	6e1c64df 	mov	v31.s[3], v6.s[3]
    4e08:	3d8093e2 	str	q2, [sp, #576]
    4e0c:	4e671f55 	bic	v21.16b, v26.16b, v7.16b
    4e10:	3dc0ed67 	ldr	q7, [x11, #944]
    4e14:	3d803be0 	str	q0, [sp, #224]
    4e18:	3dc10100 	ldr	q0, [x8, #1024]
    4e1c:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4e20:	3dc0e105 	ldr	q5, [x8, #896]
    4e24:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4e28:	4e07239e 	tbl	v30.16b, {v28.16b-v29.16b}, v7.16b
    4e2c:	3d8017e0 	str	q0, [sp, #80]
    4e30:	4e002140 	tbl	v0.16b, {v10.16b-v11.16b}, v0.16b
    4e34:	4e172298 	tbl	v24.16b, {v20.16b-v21.16b}, v23.16b
    4e38:	ad098ff6 	stp	q22, q3, [sp, #304]
    4e3c:	3dc0e943 	ldr	q3, [x10, #928]
    4e40:	900000aa 	adrp	x10, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4e44:	3d808be5 	str	q5, [sp, #544]
    4e48:	4e497916 	zip2	v22.8h, v8.8h, v9.8h
    4e4c:	3d8067ff 	str	q31, [sp, #400]
    4e50:	3d803fe0 	str	q0, [sp, #240]
    4e54:	4e022140 	tbl	v0.16b, {v10.16b-v11.16b}, v2.16b
    4e58:	3dc0f122 	ldr	q2, [x9, #960]
    4e5c:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x920>
    4e60:	3d808fe3 	str	q3, [sp, #560]
    4e64:	3d8063e2 	str	q2, [sp, #384]
    4e68:	3dc12526 	ldr	q6, [x9, #1168]
    4e6c:	3d80b3e7 	str	q7, [sp, #704]
    4e70:	3d8037e0 	str	q0, [sp, #208]
    4e74:	4e052140 	tbl	v0.16b, {v10.16b-v11.16b}, v5.16b
    4e78:	4ea21c45 	mov	v5.16b, v2.16b
    4e7c:	3d80a7e6 	str	q6, [sp, #656]
    4e80:	4e06238c 	tbl	v12.16b, {v28.16b-v29.16b}, v6.16b
    4e84:	ad0587e0 	stp	q0, q1, [sp, #176]
    4e88:	4e4b7940 	zip2	v0.8h, v10.8h, v11.8h
    4e8c:	4e032141 	tbl	v1.16b, {v10.16b-v11.16b}, v3.16b
    4e90:	3dc11903 	ldr	q3, [x8, #1120]
    4e94:	910643e8 	add	x8, sp, #0x190
    4e98:	4e03238f 	tbl	v15.16b, {v28.16b-v29.16b}, v3.16b
    4e9c:	3d8073e3 	str	q3, [sp, #448]
    4ea0:	3d8027e0 	str	q0, [sp, #144]
    4ea4:	4e022140 	tbl	v0.16b, {v10.16b-v11.16b}, v2.16b
    4ea8:	3dc0e542 	ldr	q2, [x10, #912]
    4eac:	4e5d7b8b 	zip2	v11.8h, v28.8h, v29.8h
    4eb0:	3d80afe2 	str	q2, [sp, #688]
    4eb4:	4e02239f 	tbl	v31.16b, {v28.16b-v29.16b}, v2.16b
    4eb8:	3dc0abe2 	ldr	q2, [sp, #672]
    4ebc:	ad0307e0 	stp	q0, q1, [sp, #96]
    4ec0:	4e5d3b80 	zip1	v0.8h, v28.8h, v29.8h
    4ec4:	4e022224 	tbl	v4.16b, {v17.16b-v18.16b}, v2.16b
    4ec8:	ad531be2 	ldp	q2, q6, [sp, #608]
    4ecc:	4ea31c61 	mov	v1.16b, v3.16b
    4ed0:	3dc0f583 	ldr	q3, [x12, #976]
    4ed4:	3d802be0 	str	q0, [sp, #160]
    4ed8:	4e5d6b80 	trn2	v0.8h, v28.8h, v29.8h
    4edc:	4e03239d 	tbl	v29.16b, {v28.16b-v29.16b}, v3.16b
    4ee0:	4eb11e3c 	mov	v28.16b, v17.16b
    4ee4:	3d806fe3 	str	q3, [sp, #432]
    4ee8:	3d8023e0 	str	q0, [sp, #128]
    4eec:	4e062220 	tbl	v0.16b, {v17.16b-v18.16b}, v6.16b
    4ef0:	6e1e665c 	mov	v28.h[7], v18.h[6]
    4ef4:	4e4e69a6 	trn2	v6.8h, v13.8h, v14.8h
    4ef8:	ad0193e0 	stp	q0, q4, [sp, #48]
    4efc:	4e1b2224 	tbl	v4.16b, {v17.16b-v18.16b}, v27.16b
    4f00:	4e022220 	tbl	v0.16b, {v17.16b-v18.16b}, v2.16b
    4f04:	4e527a3b 	zip2	v27.8h, v17.8h, v18.8h
    4f08:	ad0093e0 	stp	q0, q4, [sp, #16]
    4f0c:	3dc0a3e0 	ldr	q0, [sp, #640]
    4f10:	4eb41e84 	mov	v4.16b, v20.16b
    4f14:	4e002220 	tbl	v0.16b, {v17.16b-v18.16b}, v0.16b
    4f18:	6e1646a4 	mov	v4.h[5], v21.h[4]
    4f1c:	3d8003e0 	str	q0, [sp]
    4f20:	3dc097e0 	ldr	q0, [sp, #592]
    4f24:	4e00222a 	tbl	v10.16b, {v17.16b-v18.16b}, v0.16b
    4f28:	3dc07be0 	ldr	q0, [sp, #480]
    4f2c:	4e556a92 	trn2	v18.8h, v20.8h, v21.8h
    4f30:	4e557a91 	zip2	v17.8h, v20.8h, v21.8h
    4f34:	4e002299 	tbl	v25.16b, {v20.16b-v21.16b}, v0.16b
    4f38:	3dc087e0 	ldr	q0, [sp, #528]
    4f3c:	4e002297 	tbl	v23.16b, {v20.16b-v21.16b}, v0.16b
    4f40:	ad4f83e2 	ldp	q2, q0, [sp, #496]
    4f44:	6e1c6791 	mov	v17.s[3], v28.s[3]
    4f48:	3dc017fc 	ldr	q28, [sp, #80]
    4f4c:	6e1c6552 	mov	v18.s[3], v10.s[3]
    4f50:	4e022293 	tbl	v19.16b, {v20.16b-v21.16b}, v2.16b
    4f54:	4e002287 	tbl	v7.16b, {v20.16b-v21.16b}, v0.16b
    4f58:	4e052114 	tbl	v20.16b, {v8.16b-v9.16b}, v5.16b
    4f5c:	4e0121a5 	tbl	v5.16b, {v13.16b-v14.16b}, v1.16b
    4f60:	3dc08fe1 	ldr	q1, [sp, #560]
    4f64:	4e0321a0 	tbl	v0.16b, {v13.16b-v14.16b}, v3.16b
    4f68:	3dc0a7e2 	ldr	q2, [sp, #656]
    4f6c:	4e012115 	tbl	v21.16b, {v8.16b-v9.16b}, v1.16b
    4f70:	4e0221a3 	tbl	v3.16b, {v13.16b-v14.16b}, v2.16b
    4f74:	ad5587e2 	ldp	q2, q1, [sp, #688]
    4f78:	6e1c6767 	mov	v7.s[3], v27.s[3]
    4f7c:	4e0121a1 	tbl	v1.16b, {v13.16b-v14.16b}, v1.16b
    4f80:	6e0c2680 	mov	v0.s[1], v20.s[1]
    4f84:	3dc08bfb 	ldr	q27, [sp, #544]
    4f88:	4e0221a2 	tbl	v2.16b, {v13.16b-v14.16b}, v2.16b
    4f8c:	4e4e79ad 	zip2	v13.8h, v13.8h, v14.8h
    4f90:	4ea81d14 	mov	v20.16b, v8.16b
    4f94:	4e1b211b 	tbl	v27.16b, {v8.16b-v9.16b}, v27.16b
    4f98:	4e49690e 	trn2	v14.8h, v8.8h, v9.8h
    4f9c:	6e0c26a1 	mov	v1.s[1], v21.s[1]
    4fa0:	3dc093f5 	ldr	q21, [sp, #576]
    4fa4:	6e1844e0 	mov	v0.d[1], v7.d[1]
    4fa8:	6e0c26c2 	mov	v2.s[1], v22.s[1]
    4fac:	4e1c2116 	tbl	v22.16b, {v8.16b-v9.16b}, v28.16b
    4fb0:	6e0e2534 	mov	v20.h[3], v9.h[2]
    4fb4:	4e152115 	tbl	v21.16b, {v8.16b-v9.16b}, v21.16b
    4fb8:	6e0c276d 	mov	v13.s[1], v27.s[1]
    4fbc:	ad406fe8 	ldp	q8, q27, [sp]
    4fc0:	3dc00be7 	ldr	q7, [sp, #32]
    4fc4:	6e0c25c3 	mov	v3.s[1], v14.s[1]
    4fc8:	6e184621 	mov	v1.d[1], v17.d[1]
    4fcc:	6e1c6504 	mov	v4.s[3], v8.s[3]
    4fd0:	4f02e411 	movi	v17.16b, #0x40
    4fd4:	6e184642 	mov	v2.d[1], v18.d[1]
    4fd8:	6e1c6773 	mov	v19.s[3], v27.s[3]
    4fdc:	6e1c64f7 	mov	v23.s[3], v7.s[3]
    4fe0:	6e0c2685 	mov	v5.s[1], v20.s[1]
    4fe4:	3dc00fe7 	ldr	q7, [sp, #48]
    4fe8:	6e0c26a6 	mov	v6.s[1], v21.s[1]
    4fec:	6e0c26d0 	mov	v16.s[1], v22.s[1]
    4ff0:	ad070001 	stp	q1, q0, [x0, #224]
    4ff4:	6e18448d 	mov	v13.d[1], v4.d[1]
    4ff8:	ad4303e4 	ldp	q4, q0, [sp, #96]
    4ffc:	6e184663 	mov	v3.d[1], v19.d[1]
    5000:	6e1c64f8 	mov	v24.s[3], v7.s[3]
    5004:	6e0c241e 	mov	v30.s[1], v0.s[1]
    5008:	3dc027e0 	ldr	q0, [sp, #144]
    500c:	6e1846e5 	mov	v5.d[1], v23.d[1]
    5010:	6e0c249d 	mov	v29.s[1], v4.s[1]
    5014:	3dc013e7 	ldr	q7, [sp, #64]
    5018:	4f01e404 	movi	v4.16b, #0x20
    501c:	6e0c241f 	mov	v31.s[1], v0.s[1]
    5020:	ad4583e1 	ldp	q1, q0, [sp, #176]
    5024:	ad06080d 	stp	q13, q2, [x0, #192]
    5028:	3dc023e2 	ldr	q2, [sp, #128]
    502c:	6e1c64f9 	mov	v25.s[3], v7.s[3]
    5030:	ad050c05 	stp	q5, q3, [x0, #160]
    5034:	6e184706 	mov	v6.d[1], v24.d[1]
    5038:	6e0c240c 	mov	v12.s[1], v0.s[1]
    503c:	3dc043e0 	ldr	q0, [sp, #256]
    5040:	6e0c242b 	mov	v11.s[1], v1.s[1]
    5044:	3dc02be1 	ldr	q1, [sp, #160]
    5048:	6e18441d 	mov	v29.d[1], v0.d[1]
    504c:	3dc03be0 	ldr	q0, [sp, #224]
    5050:	6e184730 	mov	v16.d[1], v25.d[1]
    5054:	6e0c240f 	mov	v15.s[1], v0.s[1]
    5058:	3dc047e0 	ldr	q0, [sp, #272]
    505c:	6e18441e 	mov	v30.d[1], v0.d[1]
    5060:	3dc037e0 	ldr	q0, [sp, #208]
    5064:	ad041810 	stp	q16, q6, [x0, #128]
    5068:	4f00e486 	movi	v6.16b, #0x4
    506c:	4f00e510 	movi	v16.16b, #0x8
    5070:	6e0c2402 	mov	v2.s[1], v0.s[1]
    5074:	3dc04be0 	ldr	q0, [sp, #288]
    5078:	6e18441f 	mov	v31.d[1], v0.d[1]
    507c:	3dc03fe0 	ldr	q0, [sp, #240]
    5080:	ad03741e 	stp	q30, q29, [x0, #96]
    5084:	6e0c2401 	mov	v1.s[1], v0.s[1]
    5088:	ad4983e3 	ldp	q3, q0, [sp, #304]
    508c:	6e18446b 	mov	v11.d[1], v3.d[1]
    5090:	6e18440c 	mov	v12.d[1], v0.d[1]
    5094:	ad4b03e3 	ldp	q3, q0, [sp, #352]
    5098:	6e184402 	mov	v2.d[1], v0.d[1]
    509c:	3dc067e0 	ldr	q0, [sp, #400]
    50a0:	6e18446f 	mov	v15.d[1], v3.d[1]
    50a4:	ad027c0b 	stp	q11, q31, [x0, #64]
    50a8:	4f00e603 	movi	v3.16b, #0x10
    50ac:	3dc06feb 	ldr	q11, [sp, #432]
    50b0:	6e184401 	mov	v1.d[1], v0.d[1]
    50b4:	ad01300f 	stp	q15, q12, [x0, #32]
    50b8:	3dc097ec 	ldr	q12, [sp, #592]
    50bc:	ad000801 	stp	q1, q2, [x0]
    50c0:	4f00e421 	movi	v1.16b, #0x1
    50c4:	4f00e442 	movi	v2.16b, #0x2
    50c8:	3dc00420 	ldr	q0, [x1, #16]
    50cc:	4e231c03 	and	v3.16b, v0.16b, v3.16b
    50d0:	4e241c04 	and	v4.16b, v0.16b, v4.16b
    50d4:	4e311c11 	and	v17.16b, v0.16b, v17.16b
    50d8:	4e211c01 	and	v1.16b, v0.16b, v1.16b
    50dc:	4e221c02 	and	v2.16b, v0.16b, v2.16b
    50e0:	4e261c06 	and	v6.16b, v0.16b, v6.16b
    50e4:	4e301c10 	and	v16.16b, v0.16b, v16.16b
    50e8:	6e208800 	cmge	v0.16b, v0.16b, #0
    50ec:	4e209863 	cmeq	v3.16b, v3.16b, #0
    50f0:	4e209884 	cmeq	v4.16b, v4.16b, #0
    50f4:	4e209821 	cmeq	v1.16b, v1.16b, #0
    50f8:	4e209842 	cmeq	v2.16b, v2.16b, #0
    50fc:	4e2098c6 	cmeq	v6.16b, v6.16b, #0
    5100:	0f08a472 	sxtl	v18.8h, v3.8b
    5104:	4f08a496 	sxtl2	v22.8h, v4.16b
    5108:	4f08a463 	sxtl2	v3.8h, v3.16b
    510c:	4f08a425 	sxtl2	v5.8h, v1.16b
    5110:	0f08a421 	sxtl	v1.8h, v1.8b
    5114:	4f08a447 	sxtl2	v7.8h, v2.16b
    5118:	0f08a442 	sxtl	v2.8h, v2.8b
    511c:	4e611f53 	bic	v19.16b, v26.16b, v1.16b
    5120:	4e209a21 	cmeq	v1.16b, v17.16b, #0
    5124:	4e651f5d 	bic	v29.16b, v26.16b, v5.16b
    5128:	4e621f54 	bic	v20.16b, v26.16b, v2.16b
    512c:	0f08a485 	sxtl	v5.8h, v4.8b
    5130:	0f08a404 	sxtl	v4.8h, v0.8b
    5134:	4f08a400 	sxtl2	v0.8h, v0.16b
    5138:	0f08a4c2 	sxtl	v2.8h, v6.8b
    513c:	4e671f5e 	bic	v30.16b, v26.16b, v7.16b
    5140:	0f08a437 	sxtl	v23.8h, v1.8b
    5144:	4f08a421 	sxtl2	v1.8h, v1.16b
    5148:	4e209a07 	cmeq	v7.16b, v16.16b, #0
    514c:	4c00ad13 	st1	{v19.2d-v20.2d}, [x8]
    5150:	4e721f52 	bic	v18.16b, v26.16b, v18.16b
    5154:	4e631f54 	bic	v20.16b, v26.16b, v3.16b
    5158:	4e651f53 	bic	v19.16b, v26.16b, v5.16b
    515c:	4e621f58 	bic	v24.16b, v26.16b, v2.16b
    5160:	4f08a4c5 	sxtl2	v5.8h, v6.16b
    5164:	4e611f49 	bic	v9.16b, v26.16b, v1.16b
    5168:	4eb21e41 	mov	v1.16b, v18.16b
    516c:	0f08a4e6 	sxtl	v6.8h, v7.8b
    5170:	4e601f4a 	bic	v10.16b, v26.16b, v0.16b
    5174:	3dc07be0 	ldr	q0, [sp, #480]
    5178:	4e771f4d 	bic	v13.16b, v26.16b, v23.16b
    517c:	4e641f4e 	bic	v14.16b, v26.16b, v4.16b
    5180:	4e536a44 	trn2	v4.8h, v18.8h, v19.8h
    5184:	4f08a4e7 	sxtl2	v7.8h, v7.16b
    5188:	6e164661 	mov	v1.h[5], v19.h[4]
    518c:	4e002243 	tbl	v3.16b, {v18.16b-v19.16b}, v0.16b
    5190:	4e661f59 	bic	v25.16b, v26.16b, v6.16b
    5194:	4e651f50 	bic	v16.16b, v26.16b, v5.16b
    5198:	4eb81f05 	mov	v5.16b, v24.16b
    519c:	4e761f55 	bic	v21.16b, v26.16b, v22.16b
    51a0:	4e671f51 	bic	v17.16b, v26.16b, v7.16b
    51a4:	4e537a47 	zip2	v7.8h, v18.8h, v19.8h
    51a8:	ad4e5fff 	ldp	q31, q23, [sp, #448]
    51ac:	3d804fe1 	str	q1, [sp, #304]
    51b0:	3dc057e1 	ldr	q1, [sp, #336]
    51b4:	6e0e2725 	mov	v5.h[3], v25.h[2]
    51b8:	4e002280 	tbl	v0.16b, {v20.16b-v21.16b}, v0.16b
    51bc:	4e012242 	tbl	v2.16b, {v18.16b-v19.16b}, v1.16b
    51c0:	4e01229a 	tbl	v26.16b, {v20.16b-v21.16b}, v1.16b
    51c4:	ad0697e7 	stp	q7, q5, [sp, #208]
    51c8:	4e1c2307 	tbl	v7.16b, {v24.16b-v25.16b}, v28.16b
    51cc:	ad0b0fe2 	stp	q2, q3, [sp, #352]
    51d0:	3dc087e2 	ldr	q2, [sp, #528]
    51d4:	4e022243 	tbl	v3.16b, {v18.16b-v19.16b}, v2.16b
    51d8:	4e02229b 	tbl	v27.16b, {v20.16b-v21.16b}, v2.16b
    51dc:	4ea91d22 	mov	v2.16b, v9.16b
    51e0:	6e1e6542 	mov	v2.h[7], v10.h[6]
    51e4:	3d8053e3 	str	q3, [sp, #320]
    51e8:	3dc07fe3 	ldr	q3, [sp, #496]
    51ec:	4e032246 	tbl	v6.16b, {v18.16b-v19.16b}, v3.16b
    51f0:	ad089be4 	stp	q4, q6, [sp, #272]
    51f4:	3dc083e4 	ldr	q4, [sp, #512]
    51f8:	4e042246 	tbl	v6.16b, {v18.16b-v19.16b}, v4.16b
    51fc:	3dc093f2 	ldr	q18, [sp, #576]
    5200:	4ebc1f93 	mov	v19.16b, v28.16b
    5204:	4e1c2213 	tbl	v19.16b, {v16.16b-v17.16b}, v28.16b
    5208:	4e03229c 	tbl	v28.16b, {v20.16b-v21.16b}, v3.16b
    520c:	4e122305 	tbl	v5.16b, {v24.16b-v25.16b}, v18.16b
    5210:	4e122212 	tbl	v18.16b, {v16.16b-v17.16b}, v18.16b
    5214:	ad079fe5 	stp	q5, q7, [sp, #240]
    5218:	4e596b01 	trn2	v1.8h, v24.8h, v25.8h
    521c:	3dc08be7 	ldr	q7, [sp, #544]
    5220:	4e072305 	tbl	v5.16b, {v24.16b-v25.16b}, v7.16b
    5224:	4e072207 	tbl	v7.16b, {v16.16b-v17.16b}, v7.16b
    5228:	ad0587e5 	stp	q5, q1, [sp, #176]
    522c:	4e597b05 	zip2	v5.8h, v24.8h, v25.8h
    5230:	3d808be7 	str	q7, [sp, #544]
    5234:	4e5e6ba7 	trn2	v7.8h, v29.8h, v30.8h
    5238:	ad0497e6 	stp	q6, q5, [sp, #144]
    523c:	3dc08fe6 	ldr	q6, [sp, #560]
    5240:	4e062305 	tbl	v5.16b, {v24.16b-v25.16b}, v6.16b
    5244:	4e062206 	tbl	v6.16b, {v16.16b-v17.16b}, v6.16b
    5248:	3d8023e5 	str	q5, [sp, #128]
    524c:	3dc063e5 	ldr	q5, [sp, #384]
    5250:	ad024be6 	stp	q6, q18, [sp, #64]
    5254:	4e042292 	tbl	v18.16b, {v20.16b-v21.16b}, v4.16b
    5258:	4e052316 	tbl	v22.16b, {v24.16b-v25.16b}, v5.16b
    525c:	3dc0abf9 	ldr	q25, [sp, #672]
    5260:	4e052206 	tbl	v6.16b, {v16.16b-v17.16b}, v5.16b
    5264:	4e516a05 	trn2	v5.8h, v16.8h, v17.8h
    5268:	4e192121 	tbl	v1.16b, {v9.16b-v10.16b}, v25.16b
    526c:	ad035bf3 	stp	q19, q22, [sp, #96]
    5270:	4eb01e13 	mov	v19.16b, v16.16b
    5274:	ad535bf8 	ldp	q24, q22, [sp, #608]
    5278:	3d8063e5 	str	q5, [sp, #384]
    527c:	4e517a05 	zip2	v5.8h, v16.8h, v17.8h
    5280:	4e557a90 	zip2	v16.8h, v20.8h, v21.8h
    5284:	6e0e2633 	mov	v19.h[3], v17.h[2]
    5288:	4e556a91 	trn2	v17.8h, v20.8h, v21.8h
    528c:	4e16212f 	tbl	v15.16b, {v9.16b-v10.16b}, v22.16b
    5290:	6e1c6450 	mov	v16.s[3], v2.s[3]
    5294:	3dc013e2 	ldr	q2, [sp, #64]
    5298:	ad011be5 	stp	q5, q6, [sp, #32]
    529c:	ad11cfe0 	stp	q0, q19, [sp, #560]
    52a0:	4e172120 	tbl	v0.16b, {v9.16b-v10.16b}, v23.16b
    52a4:	4e1f23a5 	tbl	v5.16b, {v29.16b-v30.16b}, v31.16b
    52a8:	ad5423f3 	ldp	q19, q8, [sp, #640]
    52ac:	4eb41e86 	mov	v6.16b, v20.16b
    52b0:	4e4a7934 	zip2	v20.8h, v9.8h, v10.8h
    52b4:	6e1c65fa 	mov	v26.s[3], v15.s[3]
    52b8:	3d807fe0 	str	q0, [sp, #496]
    52bc:	4e182120 	tbl	v0.16b, {v9.16b-v10.16b}, v24.16b
    52c0:	4e0823a4 	tbl	v4.16b, {v29.16b-v30.16b}, v8.16b
    52c4:	6e1646a6 	mov	v6.h[5], v21.h[4]
    52c8:	4e0c2135 	tbl	v21.16b, {v9.16b-v10.16b}, v12.16b
    52cc:	4e132129 	tbl	v9.16b, {v9.16b-v10.16b}, v19.16b
    52d0:	4e5e3baa 	zip1	v10.8h, v29.8h, v30.8h
    52d4:	6e1c6692 	mov	v18.s[3], v20.s[3]
    52d8:	4e0c21b4 	tbl	v20.16b, {v13.16b-v14.16b}, v12.16b
    52dc:	4e1321b3 	tbl	v19.16b, {v13.16b-v14.16b}, v19.16b
    52e0:	ad1007e0 	stp	q0, q1, [sp, #512]
    52e4:	ad5583e1 	ldp	q1, q0, [sp, #688]
    52e8:	6e1c66b1 	mov	v17.s[3], v21.s[3]
    52ec:	6e1c6526 	mov	v6.s[3], v9.s[3]
    52f0:	4e0123a3 	tbl	v3.16b, {v29.16b-v30.16b}, v1.16b
    52f4:	4e0023a1 	tbl	v1.16b, {v29.16b-v30.16b}, v0.16b
    52f8:	4e0b23a0 	tbl	v0.16b, {v29.16b-v30.16b}, v11.16b
    52fc:	4e5e7bbe 	zip2	v30.8h, v29.8h, v30.8h
    5300:	6e0c2441 	mov	v1.s[1], v2.s[1]
    5304:	ad410bf5 	ldp	q21, q2, [sp, #32]
    5308:	6e0c26a3 	mov	v3.s[1], v21.s[1]
    530c:	4ead1db5 	mov	v21.16b, v13.16b
    5310:	6e0c2440 	mov	v0.s[1], v2.s[1]
    5314:	3dc017e2 	ldr	q2, [sp, #80]
    5318:	6e0c2447 	mov	v7.s[1], v2.s[1]
    531c:	3dc07fe2 	ldr	q2, [sp, #496]
    5320:	6e184601 	mov	v1.d[1], v16.d[1]
    5324:	4e1621b0 	tbl	v16.16b, {v13.16b-v14.16b}, v22.16b
    5328:	6e184623 	mov	v3.d[1], v17.d[1]
    532c:	6e1c645b 	mov	v27.s[3], v2.s[3]
    5330:	3dc093e2 	ldr	q2, [sp, #576]
    5334:	6e184640 	mov	v0.d[1], v18.d[1]
    5338:	4e1721b1 	tbl	v17.16b, {v13.16b-v14.16b}, v23.16b
    533c:	4e1821b2 	tbl	v18.16b, {v13.16b-v14.16b}, v24.16b
    5340:	6e1e65d5 	mov	v21.h[7], v14.h[6]
    5344:	6e0c2445 	mov	v5.s[1], v2.s[1]
    5348:	ad505be2 	ldp	q2, q22, [sp, #512]
    534c:	6e184747 	mov	v7.d[1], v26.d[1]
    5350:	6e1c645c 	mov	v28.s[3], v2.s[3]
    5354:	3dc063e2 	ldr	q2, [sp, #384]
    5358:	ad0f0001 	stp	q1, q0, [x0, #480]
    535c:	6e0c2444 	mov	v4.s[1], v2.s[1]
    5360:	ad5177e2 	ldp	q2, q29, [sp, #544]
    5364:	6e184765 	mov	v5.d[1], v27.d[1]
    5368:	4c40ad1a 	ld1	{v26.2d-v27.2d}, [x8]
    536c:	6e0c245e 	mov	v30.s[1], v2.s[1]
    5370:	6e1c66dd 	mov	v29.s[3], v22.s[3]
    5374:	3dc01bf6 	ldr	q22, [sp, #96]
    5378:	6e184784 	mov	v4.d[1], v28.d[1]
    537c:	4e0b2340 	tbl	v0.16b, {v26.16b-v27.16b}, v11.16b
    5380:	4e1f2341 	tbl	v1.16b, {v26.16b-v27.16b}, v31.16b
    5384:	6e0c26ca 	mov	v10.s[1], v22.s[1]
    5388:	4e5b3b57 	zip1	v23.8h, v26.8h, v27.8h
    538c:	4e5b6b58 	trn2	v24.8h, v26.8h, v27.8h
    5390:	4e1921a2 	tbl	v2.16b, {v13.16b-v14.16b}, v25.16b
    5394:	4e4e79b9 	zip2	v25.8h, v13.8h, v14.8h
    5398:	6e1844de 	mov	v30.d[1], v6.d[1]
    539c:	ad559bf6 	ldp	q22, q6, [sp, #688]
    53a0:	ad0d1005 	stp	q5, q4, [x0, #416]
    53a4:	3dc02be5 	ldr	q5, [sp, #160]
    53a8:	6e1847aa 	mov	v10.d[1], v29.d[1]
    53ac:	4e062346 	tbl	v6.16b, {v26.16b-v27.16b}, v6.16b
    53b0:	4e162356 	tbl	v22.16b, {v26.16b-v27.16b}, v22.16b
    53b4:	ad0e0c1e 	stp	q30, q3, [x0, #448]
    53b8:	4e082343 	tbl	v3.16b, {v26.16b-v27.16b}, v8.16b
    53bc:	4e5b7b5a 	zip2	v26.8h, v26.8h, v27.8h
    53c0:	ad446fe4 	ldp	q4, q27, [sp, #128]
    53c4:	ad0c1c0a 	stp	q10, q7, [x0, #384]
    53c8:	6e0c2486 	mov	v6.s[1], v4.s[1]
    53cc:	3dc047e4 	ldr	q4, [sp, #272]
    53d0:	6e0c24b6 	mov	v22.s[1], v5.s[1]
    53d4:	3dc02fe5 	ldr	q5, [sp, #176]
    53d8:	6e1c673b 	mov	v27.s[3], v25.s[3]
    53dc:	3dc01ff9 	ldr	q25, [sp, #112]
    53e0:	6e1c6684 	mov	v4.s[3], v20.s[3]
    53e4:	ad499ff4 	ldp	q20, q7, [sp, #304]
    53e8:	6e0c24ba 	mov	v26.s[1], v5.s[1]
    53ec:	6e0c2720 	mov	v0.s[1], v25.s[1]
    53f0:	ad4667e5 	ldp	q5, q25, [sp, #192]
    53f4:	6e0c24a3 	mov	v3.s[1], v5.s[1]
    53f8:	3dc03be5 	ldr	q5, [sp, #224]
    53fc:	6e1c6674 	mov	v20.s[3], v19.s[3]
    5400:	6e184496 	mov	v22.d[1], v4.d[1]
    5404:	3dc04bf3 	ldr	q19, [sp, #288]
    5408:	6e0c24a1 	mov	v1.s[1], v5.s[1]
    540c:	ad4b13e5 	ldp	q5, q4, [sp, #352]
    5410:	6e1c66b9 	mov	v25.s[3], v21.s[3]
    5414:	6e1c6444 	mov	v4.s[3], v2.s[3]
    5418:	6e1c6653 	mov	v19.s[3], v18.s[3]
    541c:	6e1c6605 	mov	v5.s[3], v16.s[3]
    5420:	ad478bf0 	ldp	q16, q2, [sp, #240]
    5424:	6e1c6627 	mov	v7.s[3], v17.s[3]
    5428:	6e0c2457 	mov	v23.s[1], v2.s[1]
    542c:	6e184760 	mov	v0.d[1], v27.d[1]
    5430:	6e18469a 	mov	v26.d[1], v20.d[1]
    5434:	6e0c2618 	mov	v24.s[1], v16.s[1]
    5438:	6e184726 	mov	v6.d[1], v25.d[1]
    543c:	6e184663 	mov	v3.d[1], v19.d[1]
    5440:	6e1844e1 	mov	v1.d[1], v7.d[1]
    5444:	6e184497 	mov	v23.d[1], v4.d[1]
    5448:	ad0a581a 	stp	q26, q22, [x0, #320]
    544c:	6e1844b8 	mov	v24.d[1], v5.d[1]
    5450:	ad0b0006 	stp	q6, q0, [x0, #352]
    5454:	ad090c01 	stp	q1, q3, [x0, #288]
    5458:	ad086017 	stp	q23, q24, [x0, #256]
    545c:	910b43ff 	add	sp, sp, #0x2d0
    5460:	6d4323e9 	ldp	d9, d8, [sp, #48]
    5464:	f94023fd 	ldr	x29, [sp, #64]
    5468:	6d422beb 	ldp	d11, d10, [sp, #32]
    546c:	6d4133ed 	ldp	d13, d12, [sp, #16]
    5470:	6cc53bef 	ldp	d15, d14, [sp], #80
    5474:	d65f03c0 	ret

