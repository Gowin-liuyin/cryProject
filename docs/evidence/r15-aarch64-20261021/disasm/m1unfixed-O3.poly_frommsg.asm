0000000000004c78 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4c78:	6dbb3bef 	stp	d15, d14, [sp, #-80]!
    4c7c:	6d0133ed 	stp	d13, d12, [sp, #16]
    4c80:	6d022beb 	stp	d11, d10, [sp, #32]
    4c84:	6d0323e9 	stp	d9, d8, [sp, #48]
    4c88:	f90023fd 	str	x29, [sp, #64]
    4c8c:	d10b43ff 	sub	sp, sp, #0x2d0
    4c90:	91008028 	add	x8, x1, #0x20
    4c94:	eb00011f 	cmp	x8, x0
    4c98:	54000589 	b.ls	4d48 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xd0>  // b.plast
    4c9c:	91080008 	add	x8, x0, #0x200
    4ca0:	eb01011f 	cmp	x8, x1
    4ca4:	54000529 	b.ls	4d48 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xd0>  // b.plast
    4ca8:	aa1f03e8 	mov	x8, xzr
    4cac:	91002009 	add	x9, x0, #0x8
    4cb0:	5280d02a 	mov	w10, #0x681                 	// #1665
    4cb4:	3868682b 	ldrb	w11, [x1, x8]
    4cb8:	1300016b 	sbfx	w11, w11, #0, #1
    4cbc:	0a0a016b 	and	w11, w11, w10
    4cc0:	781f812b 	sturh	w11, [x9, #-8]
    4cc4:	3868682b 	ldrb	w11, [x1, x8]
    4cc8:	5302056b 	lsl	w11, w11, #30
    4ccc:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4cd0:	781fa12b 	sturh	w11, [x9, #-6]
    4cd4:	3868682b 	ldrb	w11, [x1, x8]
    4cd8:	5303096b 	lsl	w11, w11, #29
    4cdc:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4ce0:	781fc12b 	sturh	w11, [x9, #-4]
    4ce4:	3868682b 	ldrb	w11, [x1, x8]
    4ce8:	53040d6b 	lsl	w11, w11, #28
    4cec:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4cf0:	781fe12b 	sturh	w11, [x9, #-2]
    4cf4:	3868682b 	ldrb	w11, [x1, x8]
    4cf8:	5305116b 	lsl	w11, w11, #27
    4cfc:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4d00:	7900012b 	strh	w11, [x9]
    4d04:	3868682b 	ldrb	w11, [x1, x8]
    4d08:	5306156b 	lsl	w11, w11, #26
    4d0c:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4d10:	7900052b 	strh	w11, [x9, #2]
    4d14:	3868682b 	ldrb	w11, [x1, x8]
    4d18:	5307196b 	lsl	w11, w11, #25
    4d1c:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4d20:	7900092b 	strh	w11, [x9, #4]
    4d24:	38e8682b 	ldrsb	w11, [x1, x8]
    4d28:	91000508 	add	x8, x8, #0x1
    4d2c:	7100017f 	cmp	w11, #0x0
    4d30:	1a8aa3eb 	csel	w11, wzr, w10, ge	// ge = tcont
    4d34:	f100811f 	cmp	x8, #0x20
    4d38:	79000d2b 	strh	w11, [x9, #6]
    4d3c:	91004129 	add	x9, x9, #0x10
    4d40:	54fffba1 	b.ne	4cb4 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x3c>  // b.any
    4d44:	14000219 	b	55a8 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x930>
    4d48:	4f00e420 	movi	v0.16b, #0x1
    4d4c:	4f00e441 	movi	v1.16b, #0x2
    4d50:	3dc00022 	ldr	q2, [x1]
    4d54:	4f02e404 	movi	v4.16b, #0x40
    4d58:	4f00e487 	movi	v7.16b, #0x4
    4d5c:	5280d028 	mov	w8, #0x681                 	// #1665
    4d60:	4f00e611 	movi	v17.16b, #0x10
    4d64:	4f00e506 	movi	v6.16b, #0x8
    4d68:	900000ab 	adrp	x11, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4d6c:	4f01e414 	movi	v20.16b, #0x20
    4d70:	4e020d1a 	dup	v26.8h, w8
    4d74:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4d78:	4e201c40 	and	v0.16b, v2.16b, v0.16b
    4d7c:	4e211c41 	and	v1.16b, v2.16b, v1.16b
    4d80:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4d84:	4e241c44 	and	v4.16b, v2.16b, v4.16b
    4d88:	4e271c47 	and	v7.16b, v2.16b, v7.16b
    4d8c:	900000aa 	adrp	x10, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4d90:	4e311c51 	and	v17.16b, v2.16b, v17.16b
    4d94:	4e261c50 	and	v16.16b, v2.16b, v6.16b
    4d98:	900000ac 	adrp	x12, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4d9c:	4e209803 	cmeq	v3.16b, v0.16b, #0
    4da0:	4e209825 	cmeq	v5.16b, v1.16b, #0
    4da4:	6e208840 	cmge	v0.16b, v2.16b, #0
    4da8:	4e209881 	cmeq	v1.16b, v4.16b, #0
    4dac:	3dc16524 	ldr	q4, [x9, #1424]
    4db0:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4db4:	4e341c42 	and	v2.16b, v2.16b, v20.16b
    4db8:	4e2098f4 	cmeq	v20.16b, v7.16b, #0
    4dbc:	4e209a27 	cmeq	v7.16b, v17.16b, #0
    4dc0:	4f08a472 	sxtl2	v18.8h, v3.16b
    4dc4:	3d809be4 	str	q4, [sp, #608]
    4dc8:	0f08a463 	sxtl	v3.8h, v3.8b
    4dcc:	0f08a431 	sxtl	v17.8h, v1.8b
    4dd0:	4f08a4b3 	sxtl2	v19.8h, v5.16b
    4dd4:	0f08a4b5 	sxtl	v21.8h, v5.8b
    4dd8:	3dc15d45 	ldr	q5, [x10, #1392]
    4ddc:	900000aa 	adrp	x10, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4de0:	4e209a10 	cmeq	v16.16b, v16.16b, #0
    4de4:	4e631f5c 	bic	v28.16b, v26.16b, v3.16b
    4de8:	0f08a403 	sxtl	v3.8h, v0.8b
    4dec:	4e721f4d 	bic	v13.16b, v26.16b, v18.16b
    4df0:	3d8087e5 	str	q5, [sp, #528]
    4df4:	4e711f56 	bic	v22.16b, v26.16b, v17.16b
    4df8:	4e209842 	cmeq	v2.16b, v2.16b, #0
    4dfc:	4e731f4e 	bic	v14.16b, v26.16b, v19.16b
    4e00:	0f08a692 	sxtl	v18.8h, v20.8b
    4e04:	4f08a693 	sxtl2	v19.8h, v20.16b
    4e08:	4e631f57 	bic	v23.16b, v26.16b, v3.16b
    4e0c:	3dc14103 	ldr	q3, [x8, #1280]
    4e10:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4e14:	4e751f5d 	bic	v29.16b, v26.16b, v21.16b
    4e18:	0f08a614 	sxtl	v20.8h, v16.8b
    4e1c:	4f08a615 	sxtl2	v21.8h, v16.16b
    4e20:	3d80abe3 	str	q3, [sp, #672]
    4e24:	0f08a4f8 	sxtl	v24.8h, v7.8b
    4e28:	0f08a459 	sxtl	v25.8h, v2.8b
    4e2c:	4e0322c3 	tbl	v3.16b, {v22.16b-v23.16b}, v3.16b
    4e30:	4e731f48 	bic	v8.16b, v26.16b, v19.16b
    4e34:	4e721f4a 	bic	v10.16b, v26.16b, v18.16b
    4e38:	4e751f49 	bic	v9.16b, v26.16b, v21.16b
    4e3c:	4e741f4b 	bic	v11.16b, v26.16b, v20.16b
    4e40:	4eb61ed3 	mov	v19.16b, v22.16b
    4e44:	4e781f54 	bic	v20.16b, v26.16b, v24.16b
    4e48:	4f08a406 	sxtl2	v6.8h, v0.16b
    4e4c:	3dc16960 	ldr	q0, [x11, #1440]
    4e50:	900000ab 	adrp	x11, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4e54:	4e791f55 	bic	v21.16b, v26.16b, v25.16b
    4e58:	4f08a4f2 	sxtl2	v18.8h, v7.16b
    4e5c:	3d80b3e3 	str	q3, [sp, #704]
    4e60:	3dc14d03 	ldr	q3, [x8, #1328]
    4e64:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4e68:	3dc1591b 	ldr	q27, [x8, #1376]
    4e6c:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4e70:	3d807fe0 	str	q0, [sp, #496]
    4e74:	3dc17111 	ldr	q17, [x8, #1472]
    4e78:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4e7c:	3d809fe3 	str	q3, [sp, #624]
    4e80:	4e0322de 	tbl	v30.16b, {v22.16b-v23.16b}, v3.16b
    4e84:	3dc17503 	ldr	q3, [x8, #1488]
    4e88:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4e8c:	3d80a3f1 	str	q17, [sp, #640]
    4e90:	4e1122d8 	tbl	v24.16b, {v22.16b-v23.16b}, v17.16b
    4e94:	4f08a431 	sxtl2	v17.8h, v1.16b
    4e98:	3dc14501 	ldr	q1, [x8, #1296]
    4e9c:	6e1e66f3 	mov	v19.h[7], v23.h[6]
    4ea0:	3d8097e3 	str	q3, [sp, #592]
    4ea4:	4e0322cc 	tbl	v12.16b, {v22.16b-v23.16b}, v3.16b
    4ea8:	4e002283 	tbl	v3.16b, {v20.16b-v21.16b}, v0.16b
    4eac:	4e556a80 	trn2	v0.8h, v20.8h, v21.8h
    4eb0:	3d807be1 	str	q1, [sp, #480]
    4eb4:	4e01229f 	tbl	v31.16b, {v20.16b-v21.16b}, v1.16b
    4eb8:	4e557a81 	zip2	v1.8h, v20.8h, v21.8h
    4ebc:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4ec0:	4f08a447 	sxtl2	v7.8h, v2.16b
    4ec4:	4e577acf 	zip2	v15.8h, v22.8h, v23.8h
    4ec8:	3dc17902 	ldr	q2, [x8, #1504]
    4ecc:	4e1b22d9 	tbl	v25.16b, {v22.16b-v23.16b}, v27.16b
    4ed0:	4e0422d0 	tbl	v16.16b, {v22.16b-v23.16b}, v4.16b
    4ed4:	6e1c6580 	mov	v0.s[3], v12.s[3]
    4ed8:	3dc15137 	ldr	q23, [x9, #1344]
    4edc:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4ee0:	6e1c6661 	mov	v1.s[3], v19.s[3]
    4ee4:	3d8083e2 	str	q2, [sp, #512]
    4ee8:	4e022282 	tbl	v2.16b, {v20.16b-v21.16b}, v2.16b
    4eec:	4e172284 	tbl	v4.16b, {v20.16b-v21.16b}, v23.16b
    4ef0:	4e052285 	tbl	v5.16b, {v20.16b-v21.16b}, v5.16b
    4ef4:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4ef8:	4eb41e96 	mov	v22.16b, v20.16b
    4efc:	6e1c6603 	mov	v3.s[3], v16.s[3]
    4f00:	3d8057f7 	str	q23, [sp, #336]
    4f04:	3d8077fb 	str	q27, [sp, #464]
    4f08:	4e4e39b0 	zip1	v16.8h, v13.8h, v14.8h
    4f0c:	ad0883e1 	stp	q1, q0, [sp, #272]
    4f10:	4eaa1d40 	mov	v0.16b, v10.16b
    4f14:	6e1c65e2 	mov	v2.s[3], v15.s[3]
    4f18:	6e1c67c4 	mov	v4.s[3], v30.s[3]
    4f1c:	6e1c6725 	mov	v5.s[3], v25.s[3]
    4f20:	6e1646b6 	mov	v22.h[5], v21.h[4]
    4f24:	4e4b6941 	trn2	v1.8h, v10.8h, v11.8h
    4f28:	4e721f54 	bic	v20.16b, v26.16b, v18.16b
    4f2c:	4e711f51 	bic	v17.16b, v26.16b, v17.16b
    4f30:	6e0e2560 	mov	v0.h[3], v11.h[2]
    4f34:	4e661f52 	bic	v18.16b, v26.16b, v6.16b
    4f38:	3dc0b3e6 	ldr	q6, [sp, #704]
    4f3c:	3d8043e2 	str	q2, [sp, #256]
    4f40:	3dc15522 	ldr	q2, [x9, #1360]
    4f44:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4f48:	ad0b13e5 	stp	q5, q4, [sp, #352]
    4f4c:	6e1c6716 	mov	v22.s[3], v24.s[3]
    4f50:	6e1c64df 	mov	v31.s[3], v6.s[3]
    4f54:	3d8093e2 	str	q2, [sp, #576]
    4f58:	4e671f55 	bic	v21.16b, v26.16b, v7.16b
    4f5c:	3dc13567 	ldr	q7, [x11, #1232]
    4f60:	3d803be0 	str	q0, [sp, #224]
    4f64:	3dc14900 	ldr	q0, [x8, #1312]
    4f68:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4f6c:	3dc12905 	ldr	q5, [x8, #1184]
    4f70:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4f74:	4e07239e 	tbl	v30.16b, {v28.16b-v29.16b}, v7.16b
    4f78:	3d8017e0 	str	q0, [sp, #80]
    4f7c:	4e002140 	tbl	v0.16b, {v10.16b-v11.16b}, v0.16b
    4f80:	4e172298 	tbl	v24.16b, {v20.16b-v21.16b}, v23.16b
    4f84:	ad098ff6 	stp	q22, q3, [sp, #304]
    4f88:	3dc13143 	ldr	q3, [x10, #1216]
    4f8c:	900000aa 	adrp	x10, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4f90:	3d808be5 	str	q5, [sp, #544]
    4f94:	4e497916 	zip2	v22.8h, v8.8h, v9.8h
    4f98:	3d8067ff 	str	q31, [sp, #400]
    4f9c:	3d803fe0 	str	q0, [sp, #240]
    4fa0:	4e022140 	tbl	v0.16b, {v10.16b-v11.16b}, v2.16b
    4fa4:	3dc13922 	ldr	q2, [x9, #1248]
    4fa8:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x7d4>
    4fac:	3d808fe3 	str	q3, [sp, #560]
    4fb0:	3d8063e2 	str	q2, [sp, #384]
    4fb4:	3dc16d26 	ldr	q6, [x9, #1456]
    4fb8:	3d80b3e7 	str	q7, [sp, #704]
    4fbc:	3d8037e0 	str	q0, [sp, #208]
    4fc0:	4e052140 	tbl	v0.16b, {v10.16b-v11.16b}, v5.16b
    4fc4:	4ea21c45 	mov	v5.16b, v2.16b
    4fc8:	3d80a7e6 	str	q6, [sp, #656]
    4fcc:	4e06238c 	tbl	v12.16b, {v28.16b-v29.16b}, v6.16b
    4fd0:	ad0587e0 	stp	q0, q1, [sp, #176]
    4fd4:	4e4b7940 	zip2	v0.8h, v10.8h, v11.8h
    4fd8:	4e032141 	tbl	v1.16b, {v10.16b-v11.16b}, v3.16b
    4fdc:	3dc16103 	ldr	q3, [x8, #1408]
    4fe0:	910643e8 	add	x8, sp, #0x190
    4fe4:	4e03238f 	tbl	v15.16b, {v28.16b-v29.16b}, v3.16b
    4fe8:	3d8073e3 	str	q3, [sp, #448]
    4fec:	3d8027e0 	str	q0, [sp, #144]
    4ff0:	4e022140 	tbl	v0.16b, {v10.16b-v11.16b}, v2.16b
    4ff4:	3dc12d42 	ldr	q2, [x10, #1200]
    4ff8:	4e5d7b8b 	zip2	v11.8h, v28.8h, v29.8h
    4ffc:	3d80afe2 	str	q2, [sp, #688]
    5000:	4e02239f 	tbl	v31.16b, {v28.16b-v29.16b}, v2.16b
    5004:	3dc0abe2 	ldr	q2, [sp, #672]
    5008:	ad0307e0 	stp	q0, q1, [sp, #96]
    500c:	4e5d3b80 	zip1	v0.8h, v28.8h, v29.8h
    5010:	4e022224 	tbl	v4.16b, {v17.16b-v18.16b}, v2.16b
    5014:	ad531be2 	ldp	q2, q6, [sp, #608]
    5018:	4ea31c61 	mov	v1.16b, v3.16b
    501c:	3dc13d83 	ldr	q3, [x12, #1264]
    5020:	3d802be0 	str	q0, [sp, #160]
    5024:	4e5d6b80 	trn2	v0.8h, v28.8h, v29.8h
    5028:	4e03239d 	tbl	v29.16b, {v28.16b-v29.16b}, v3.16b
    502c:	4eb11e3c 	mov	v28.16b, v17.16b
    5030:	3d806fe3 	str	q3, [sp, #432]
    5034:	3d8023e0 	str	q0, [sp, #128]
    5038:	4e062220 	tbl	v0.16b, {v17.16b-v18.16b}, v6.16b
    503c:	6e1e665c 	mov	v28.h[7], v18.h[6]
    5040:	4e4e69a6 	trn2	v6.8h, v13.8h, v14.8h
    5044:	ad0193e0 	stp	q0, q4, [sp, #48]
    5048:	4e1b2224 	tbl	v4.16b, {v17.16b-v18.16b}, v27.16b
    504c:	4e022220 	tbl	v0.16b, {v17.16b-v18.16b}, v2.16b
    5050:	4e527a3b 	zip2	v27.8h, v17.8h, v18.8h
    5054:	ad0093e0 	stp	q0, q4, [sp, #16]
    5058:	3dc0a3e0 	ldr	q0, [sp, #640]
    505c:	4eb41e84 	mov	v4.16b, v20.16b
    5060:	4e002220 	tbl	v0.16b, {v17.16b-v18.16b}, v0.16b
    5064:	6e1646a4 	mov	v4.h[5], v21.h[4]
    5068:	3d8003e0 	str	q0, [sp]
    506c:	3dc097e0 	ldr	q0, [sp, #592]
    5070:	4e00222a 	tbl	v10.16b, {v17.16b-v18.16b}, v0.16b
    5074:	3dc07be0 	ldr	q0, [sp, #480]
    5078:	4e556a92 	trn2	v18.8h, v20.8h, v21.8h
    507c:	4e557a91 	zip2	v17.8h, v20.8h, v21.8h
    5080:	4e002299 	tbl	v25.16b, {v20.16b-v21.16b}, v0.16b
    5084:	3dc087e0 	ldr	q0, [sp, #528]
    5088:	4e002297 	tbl	v23.16b, {v20.16b-v21.16b}, v0.16b
    508c:	ad4f83e2 	ldp	q2, q0, [sp, #496]
    5090:	6e1c6791 	mov	v17.s[3], v28.s[3]
    5094:	3dc017fc 	ldr	q28, [sp, #80]
    5098:	6e1c6552 	mov	v18.s[3], v10.s[3]
    509c:	4e022293 	tbl	v19.16b, {v20.16b-v21.16b}, v2.16b
    50a0:	4e002287 	tbl	v7.16b, {v20.16b-v21.16b}, v0.16b
    50a4:	4e052114 	tbl	v20.16b, {v8.16b-v9.16b}, v5.16b
    50a8:	4e0121a5 	tbl	v5.16b, {v13.16b-v14.16b}, v1.16b
    50ac:	3dc08fe1 	ldr	q1, [sp, #560]
    50b0:	4e0321a0 	tbl	v0.16b, {v13.16b-v14.16b}, v3.16b
    50b4:	3dc0a7e2 	ldr	q2, [sp, #656]
    50b8:	4e012115 	tbl	v21.16b, {v8.16b-v9.16b}, v1.16b
    50bc:	4e0221a3 	tbl	v3.16b, {v13.16b-v14.16b}, v2.16b
    50c0:	ad5587e2 	ldp	q2, q1, [sp, #688]
    50c4:	6e1c6767 	mov	v7.s[3], v27.s[3]
    50c8:	4e0121a1 	tbl	v1.16b, {v13.16b-v14.16b}, v1.16b
    50cc:	6e0c2680 	mov	v0.s[1], v20.s[1]
    50d0:	3dc08bfb 	ldr	q27, [sp, #544]
    50d4:	4e0221a2 	tbl	v2.16b, {v13.16b-v14.16b}, v2.16b
    50d8:	4e4e79ad 	zip2	v13.8h, v13.8h, v14.8h
    50dc:	4ea81d14 	mov	v20.16b, v8.16b
    50e0:	4e1b211b 	tbl	v27.16b, {v8.16b-v9.16b}, v27.16b
    50e4:	4e49690e 	trn2	v14.8h, v8.8h, v9.8h
    50e8:	6e0c26a1 	mov	v1.s[1], v21.s[1]
    50ec:	3dc093f5 	ldr	q21, [sp, #576]
    50f0:	6e1844e0 	mov	v0.d[1], v7.d[1]
    50f4:	6e0c26c2 	mov	v2.s[1], v22.s[1]
    50f8:	4e1c2116 	tbl	v22.16b, {v8.16b-v9.16b}, v28.16b
    50fc:	6e0e2534 	mov	v20.h[3], v9.h[2]
    5100:	4e152115 	tbl	v21.16b, {v8.16b-v9.16b}, v21.16b
    5104:	6e0c276d 	mov	v13.s[1], v27.s[1]
    5108:	ad406fe8 	ldp	q8, q27, [sp]
    510c:	3dc00be7 	ldr	q7, [sp, #32]
    5110:	6e0c25c3 	mov	v3.s[1], v14.s[1]
    5114:	6e184621 	mov	v1.d[1], v17.d[1]
    5118:	6e1c6504 	mov	v4.s[3], v8.s[3]
    511c:	4f02e411 	movi	v17.16b, #0x40
    5120:	6e184642 	mov	v2.d[1], v18.d[1]
    5124:	6e1c6773 	mov	v19.s[3], v27.s[3]
    5128:	6e1c64f7 	mov	v23.s[3], v7.s[3]
    512c:	6e0c2685 	mov	v5.s[1], v20.s[1]
    5130:	3dc00fe7 	ldr	q7, [sp, #48]
    5134:	6e0c26a6 	mov	v6.s[1], v21.s[1]
    5138:	6e0c26d0 	mov	v16.s[1], v22.s[1]
    513c:	ad070001 	stp	q1, q0, [x0, #224]
    5140:	6e18448d 	mov	v13.d[1], v4.d[1]
    5144:	ad4303e4 	ldp	q4, q0, [sp, #96]
    5148:	6e184663 	mov	v3.d[1], v19.d[1]
    514c:	6e1c64f8 	mov	v24.s[3], v7.s[3]
    5150:	6e0c241e 	mov	v30.s[1], v0.s[1]
    5154:	3dc027e0 	ldr	q0, [sp, #144]
    5158:	6e1846e5 	mov	v5.d[1], v23.d[1]
    515c:	6e0c249d 	mov	v29.s[1], v4.s[1]
    5160:	3dc013e7 	ldr	q7, [sp, #64]
    5164:	4f01e404 	movi	v4.16b, #0x20
    5168:	6e0c241f 	mov	v31.s[1], v0.s[1]
    516c:	ad4583e1 	ldp	q1, q0, [sp, #176]
    5170:	ad06080d 	stp	q13, q2, [x0, #192]
    5174:	3dc023e2 	ldr	q2, [sp, #128]
    5178:	6e1c64f9 	mov	v25.s[3], v7.s[3]
    517c:	ad050c05 	stp	q5, q3, [x0, #160]
    5180:	6e184706 	mov	v6.d[1], v24.d[1]
    5184:	6e0c240c 	mov	v12.s[1], v0.s[1]
    5188:	3dc043e0 	ldr	q0, [sp, #256]
    518c:	6e0c242b 	mov	v11.s[1], v1.s[1]
    5190:	3dc02be1 	ldr	q1, [sp, #160]
    5194:	6e18441d 	mov	v29.d[1], v0.d[1]
    5198:	3dc03be0 	ldr	q0, [sp, #224]
    519c:	6e184730 	mov	v16.d[1], v25.d[1]
    51a0:	6e0c240f 	mov	v15.s[1], v0.s[1]
    51a4:	3dc047e0 	ldr	q0, [sp, #272]
    51a8:	6e18441e 	mov	v30.d[1], v0.d[1]
    51ac:	3dc037e0 	ldr	q0, [sp, #208]
    51b0:	ad041810 	stp	q16, q6, [x0, #128]
    51b4:	4f00e486 	movi	v6.16b, #0x4
    51b8:	4f00e510 	movi	v16.16b, #0x8
    51bc:	6e0c2402 	mov	v2.s[1], v0.s[1]
    51c0:	3dc04be0 	ldr	q0, [sp, #288]
    51c4:	6e18441f 	mov	v31.d[1], v0.d[1]
    51c8:	3dc03fe0 	ldr	q0, [sp, #240]
    51cc:	ad03741e 	stp	q30, q29, [x0, #96]
    51d0:	6e0c2401 	mov	v1.s[1], v0.s[1]
    51d4:	ad4983e3 	ldp	q3, q0, [sp, #304]
    51d8:	6e18446b 	mov	v11.d[1], v3.d[1]
    51dc:	6e18440c 	mov	v12.d[1], v0.d[1]
    51e0:	ad4b03e3 	ldp	q3, q0, [sp, #352]
    51e4:	6e184402 	mov	v2.d[1], v0.d[1]
    51e8:	3dc067e0 	ldr	q0, [sp, #400]
    51ec:	6e18446f 	mov	v15.d[1], v3.d[1]
    51f0:	ad027c0b 	stp	q11, q31, [x0, #64]
    51f4:	4f00e603 	movi	v3.16b, #0x10
    51f8:	3dc06feb 	ldr	q11, [sp, #432]
    51fc:	6e184401 	mov	v1.d[1], v0.d[1]
    5200:	ad01300f 	stp	q15, q12, [x0, #32]
    5204:	3dc097ec 	ldr	q12, [sp, #592]
    5208:	ad000801 	stp	q1, q2, [x0]
    520c:	4f00e421 	movi	v1.16b, #0x1
    5210:	4f00e442 	movi	v2.16b, #0x2
    5214:	3dc00420 	ldr	q0, [x1, #16]
    5218:	4e231c03 	and	v3.16b, v0.16b, v3.16b
    521c:	4e241c04 	and	v4.16b, v0.16b, v4.16b
    5220:	4e311c11 	and	v17.16b, v0.16b, v17.16b
    5224:	4e211c01 	and	v1.16b, v0.16b, v1.16b
    5228:	4e221c02 	and	v2.16b, v0.16b, v2.16b
    522c:	4e261c06 	and	v6.16b, v0.16b, v6.16b
    5230:	4e301c10 	and	v16.16b, v0.16b, v16.16b
    5234:	6e208800 	cmge	v0.16b, v0.16b, #0
    5238:	4e209863 	cmeq	v3.16b, v3.16b, #0
    523c:	4e209884 	cmeq	v4.16b, v4.16b, #0
    5240:	4e209821 	cmeq	v1.16b, v1.16b, #0
    5244:	4e209842 	cmeq	v2.16b, v2.16b, #0
    5248:	4e2098c6 	cmeq	v6.16b, v6.16b, #0
    524c:	0f08a472 	sxtl	v18.8h, v3.8b
    5250:	4f08a496 	sxtl2	v22.8h, v4.16b
    5254:	4f08a463 	sxtl2	v3.8h, v3.16b
    5258:	4f08a425 	sxtl2	v5.8h, v1.16b
    525c:	0f08a421 	sxtl	v1.8h, v1.8b
    5260:	4f08a447 	sxtl2	v7.8h, v2.16b
    5264:	0f08a442 	sxtl	v2.8h, v2.8b
    5268:	4e611f53 	bic	v19.16b, v26.16b, v1.16b
    526c:	4e209a21 	cmeq	v1.16b, v17.16b, #0
    5270:	4e651f5d 	bic	v29.16b, v26.16b, v5.16b
    5274:	4e621f54 	bic	v20.16b, v26.16b, v2.16b
    5278:	0f08a485 	sxtl	v5.8h, v4.8b
    527c:	0f08a404 	sxtl	v4.8h, v0.8b
    5280:	4f08a400 	sxtl2	v0.8h, v0.16b
    5284:	0f08a4c2 	sxtl	v2.8h, v6.8b
    5288:	4e671f5e 	bic	v30.16b, v26.16b, v7.16b
    528c:	0f08a437 	sxtl	v23.8h, v1.8b
    5290:	4f08a421 	sxtl2	v1.8h, v1.16b
    5294:	4e209a07 	cmeq	v7.16b, v16.16b, #0
    5298:	4c00ad13 	st1	{v19.2d-v20.2d}, [x8]
    529c:	4e721f52 	bic	v18.16b, v26.16b, v18.16b
    52a0:	4e631f54 	bic	v20.16b, v26.16b, v3.16b
    52a4:	4e651f53 	bic	v19.16b, v26.16b, v5.16b
    52a8:	4e621f58 	bic	v24.16b, v26.16b, v2.16b
    52ac:	4f08a4c5 	sxtl2	v5.8h, v6.16b
    52b0:	4e611f49 	bic	v9.16b, v26.16b, v1.16b
    52b4:	4eb21e41 	mov	v1.16b, v18.16b
    52b8:	0f08a4e6 	sxtl	v6.8h, v7.8b
    52bc:	4e601f4a 	bic	v10.16b, v26.16b, v0.16b
    52c0:	3dc07be0 	ldr	q0, [sp, #480]
    52c4:	4e771f4d 	bic	v13.16b, v26.16b, v23.16b
    52c8:	4e641f4e 	bic	v14.16b, v26.16b, v4.16b
    52cc:	4e536a44 	trn2	v4.8h, v18.8h, v19.8h
    52d0:	4f08a4e7 	sxtl2	v7.8h, v7.16b
    52d4:	6e164661 	mov	v1.h[5], v19.h[4]
    52d8:	4e002243 	tbl	v3.16b, {v18.16b-v19.16b}, v0.16b
    52dc:	4e661f59 	bic	v25.16b, v26.16b, v6.16b
    52e0:	4e651f50 	bic	v16.16b, v26.16b, v5.16b
    52e4:	4eb81f05 	mov	v5.16b, v24.16b
    52e8:	4e761f55 	bic	v21.16b, v26.16b, v22.16b
    52ec:	4e671f51 	bic	v17.16b, v26.16b, v7.16b
    52f0:	4e537a47 	zip2	v7.8h, v18.8h, v19.8h
    52f4:	ad4e5fff 	ldp	q31, q23, [sp, #448]
    52f8:	3d804fe1 	str	q1, [sp, #304]
    52fc:	3dc057e1 	ldr	q1, [sp, #336]
    5300:	6e0e2725 	mov	v5.h[3], v25.h[2]
    5304:	4e002280 	tbl	v0.16b, {v20.16b-v21.16b}, v0.16b
    5308:	4e012242 	tbl	v2.16b, {v18.16b-v19.16b}, v1.16b
    530c:	4e01229a 	tbl	v26.16b, {v20.16b-v21.16b}, v1.16b
    5310:	ad0697e7 	stp	q7, q5, [sp, #208]
    5314:	4e1c2307 	tbl	v7.16b, {v24.16b-v25.16b}, v28.16b
    5318:	ad0b0fe2 	stp	q2, q3, [sp, #352]
    531c:	3dc087e2 	ldr	q2, [sp, #528]
    5320:	4e022243 	tbl	v3.16b, {v18.16b-v19.16b}, v2.16b
    5324:	4e02229b 	tbl	v27.16b, {v20.16b-v21.16b}, v2.16b
    5328:	4ea91d22 	mov	v2.16b, v9.16b
    532c:	6e1e6542 	mov	v2.h[7], v10.h[6]
    5330:	3d8053e3 	str	q3, [sp, #320]
    5334:	3dc07fe3 	ldr	q3, [sp, #496]
    5338:	4e032246 	tbl	v6.16b, {v18.16b-v19.16b}, v3.16b
    533c:	ad089be4 	stp	q4, q6, [sp, #272]
    5340:	3dc083e4 	ldr	q4, [sp, #512]
    5344:	4e042246 	tbl	v6.16b, {v18.16b-v19.16b}, v4.16b
    5348:	3dc093f2 	ldr	q18, [sp, #576]
    534c:	4ebc1f93 	mov	v19.16b, v28.16b
    5350:	4e1c2213 	tbl	v19.16b, {v16.16b-v17.16b}, v28.16b
    5354:	4e03229c 	tbl	v28.16b, {v20.16b-v21.16b}, v3.16b
    5358:	4e122305 	tbl	v5.16b, {v24.16b-v25.16b}, v18.16b
    535c:	4e122212 	tbl	v18.16b, {v16.16b-v17.16b}, v18.16b
    5360:	ad079fe5 	stp	q5, q7, [sp, #240]
    5364:	4e596b01 	trn2	v1.8h, v24.8h, v25.8h
    5368:	3dc08be7 	ldr	q7, [sp, #544]
    536c:	4e072305 	tbl	v5.16b, {v24.16b-v25.16b}, v7.16b
    5370:	4e072207 	tbl	v7.16b, {v16.16b-v17.16b}, v7.16b
    5374:	ad0587e5 	stp	q5, q1, [sp, #176]
    5378:	4e597b05 	zip2	v5.8h, v24.8h, v25.8h
    537c:	3d808be7 	str	q7, [sp, #544]
    5380:	4e5e6ba7 	trn2	v7.8h, v29.8h, v30.8h
    5384:	ad0497e6 	stp	q6, q5, [sp, #144]
    5388:	3dc08fe6 	ldr	q6, [sp, #560]
    538c:	4e062305 	tbl	v5.16b, {v24.16b-v25.16b}, v6.16b
    5390:	4e062206 	tbl	v6.16b, {v16.16b-v17.16b}, v6.16b
    5394:	3d8023e5 	str	q5, [sp, #128]
    5398:	3dc063e5 	ldr	q5, [sp, #384]
    539c:	ad024be6 	stp	q6, q18, [sp, #64]
    53a0:	4e042292 	tbl	v18.16b, {v20.16b-v21.16b}, v4.16b
    53a4:	4e052316 	tbl	v22.16b, {v24.16b-v25.16b}, v5.16b
    53a8:	3dc0abf9 	ldr	q25, [sp, #672]
    53ac:	4e052206 	tbl	v6.16b, {v16.16b-v17.16b}, v5.16b
    53b0:	4e516a05 	trn2	v5.8h, v16.8h, v17.8h
    53b4:	4e192121 	tbl	v1.16b, {v9.16b-v10.16b}, v25.16b
    53b8:	ad035bf3 	stp	q19, q22, [sp, #96]
    53bc:	4eb01e13 	mov	v19.16b, v16.16b
    53c0:	ad535bf8 	ldp	q24, q22, [sp, #608]
    53c4:	3d8063e5 	str	q5, [sp, #384]
    53c8:	4e517a05 	zip2	v5.8h, v16.8h, v17.8h
    53cc:	4e557a90 	zip2	v16.8h, v20.8h, v21.8h
    53d0:	6e0e2633 	mov	v19.h[3], v17.h[2]
    53d4:	4e556a91 	trn2	v17.8h, v20.8h, v21.8h
    53d8:	4e16212f 	tbl	v15.16b, {v9.16b-v10.16b}, v22.16b
    53dc:	6e1c6450 	mov	v16.s[3], v2.s[3]
    53e0:	3dc013e2 	ldr	q2, [sp, #64]
    53e4:	ad011be5 	stp	q5, q6, [sp, #32]
    53e8:	ad11cfe0 	stp	q0, q19, [sp, #560]
    53ec:	4e172120 	tbl	v0.16b, {v9.16b-v10.16b}, v23.16b
    53f0:	4e1f23a5 	tbl	v5.16b, {v29.16b-v30.16b}, v31.16b
    53f4:	ad5423f3 	ldp	q19, q8, [sp, #640]
    53f8:	4eb41e86 	mov	v6.16b, v20.16b
    53fc:	4e4a7934 	zip2	v20.8h, v9.8h, v10.8h
    5400:	6e1c65fa 	mov	v26.s[3], v15.s[3]
    5404:	3d807fe0 	str	q0, [sp, #496]
    5408:	4e182120 	tbl	v0.16b, {v9.16b-v10.16b}, v24.16b
    540c:	4e0823a4 	tbl	v4.16b, {v29.16b-v30.16b}, v8.16b
    5410:	6e1646a6 	mov	v6.h[5], v21.h[4]
    5414:	4e0c2135 	tbl	v21.16b, {v9.16b-v10.16b}, v12.16b
    5418:	4e132129 	tbl	v9.16b, {v9.16b-v10.16b}, v19.16b
    541c:	4e5e3baa 	zip1	v10.8h, v29.8h, v30.8h
    5420:	6e1c6692 	mov	v18.s[3], v20.s[3]
    5424:	4e0c21b4 	tbl	v20.16b, {v13.16b-v14.16b}, v12.16b
    5428:	4e1321b3 	tbl	v19.16b, {v13.16b-v14.16b}, v19.16b
    542c:	ad1007e0 	stp	q0, q1, [sp, #512]
    5430:	ad5583e1 	ldp	q1, q0, [sp, #688]
    5434:	6e1c66b1 	mov	v17.s[3], v21.s[3]
    5438:	6e1c6526 	mov	v6.s[3], v9.s[3]
    543c:	4e0123a3 	tbl	v3.16b, {v29.16b-v30.16b}, v1.16b
    5440:	4e0023a1 	tbl	v1.16b, {v29.16b-v30.16b}, v0.16b
    5444:	4e0b23a0 	tbl	v0.16b, {v29.16b-v30.16b}, v11.16b
    5448:	4e5e7bbe 	zip2	v30.8h, v29.8h, v30.8h
    544c:	6e0c2441 	mov	v1.s[1], v2.s[1]
    5450:	ad410bf5 	ldp	q21, q2, [sp, #32]
    5454:	6e0c26a3 	mov	v3.s[1], v21.s[1]
    5458:	4ead1db5 	mov	v21.16b, v13.16b
    545c:	6e0c2440 	mov	v0.s[1], v2.s[1]
    5460:	3dc017e2 	ldr	q2, [sp, #80]
    5464:	6e0c2447 	mov	v7.s[1], v2.s[1]
    5468:	3dc07fe2 	ldr	q2, [sp, #496]
    546c:	6e184601 	mov	v1.d[1], v16.d[1]
    5470:	4e1621b0 	tbl	v16.16b, {v13.16b-v14.16b}, v22.16b
    5474:	6e184623 	mov	v3.d[1], v17.d[1]
    5478:	6e1c645b 	mov	v27.s[3], v2.s[3]
    547c:	3dc093e2 	ldr	q2, [sp, #576]
    5480:	6e184640 	mov	v0.d[1], v18.d[1]
    5484:	4e1721b1 	tbl	v17.16b, {v13.16b-v14.16b}, v23.16b
    5488:	4e1821b2 	tbl	v18.16b, {v13.16b-v14.16b}, v24.16b
    548c:	6e1e65d5 	mov	v21.h[7], v14.h[6]
    5490:	6e0c2445 	mov	v5.s[1], v2.s[1]
    5494:	ad505be2 	ldp	q2, q22, [sp, #512]
    5498:	6e184747 	mov	v7.d[1], v26.d[1]
    549c:	6e1c645c 	mov	v28.s[3], v2.s[3]
    54a0:	3dc063e2 	ldr	q2, [sp, #384]
    54a4:	ad0f0001 	stp	q1, q0, [x0, #480]
    54a8:	6e0c2444 	mov	v4.s[1], v2.s[1]
    54ac:	ad5177e2 	ldp	q2, q29, [sp, #544]
    54b0:	6e184765 	mov	v5.d[1], v27.d[1]
    54b4:	4c40ad1a 	ld1	{v26.2d-v27.2d}, [x8]
    54b8:	6e0c245e 	mov	v30.s[1], v2.s[1]
    54bc:	6e1c66dd 	mov	v29.s[3], v22.s[3]
    54c0:	3dc01bf6 	ldr	q22, [sp, #96]
    54c4:	6e184784 	mov	v4.d[1], v28.d[1]
    54c8:	4e0b2340 	tbl	v0.16b, {v26.16b-v27.16b}, v11.16b
    54cc:	4e1f2341 	tbl	v1.16b, {v26.16b-v27.16b}, v31.16b
    54d0:	6e0c26ca 	mov	v10.s[1], v22.s[1]
    54d4:	4e5b3b57 	zip1	v23.8h, v26.8h, v27.8h
    54d8:	4e5b6b58 	trn2	v24.8h, v26.8h, v27.8h
    54dc:	4e1921a2 	tbl	v2.16b, {v13.16b-v14.16b}, v25.16b
    54e0:	4e4e79b9 	zip2	v25.8h, v13.8h, v14.8h
    54e4:	6e1844de 	mov	v30.d[1], v6.d[1]
    54e8:	ad559bf6 	ldp	q22, q6, [sp, #688]
    54ec:	ad0d1005 	stp	q5, q4, [x0, #416]
    54f0:	3dc02be5 	ldr	q5, [sp, #160]
    54f4:	6e1847aa 	mov	v10.d[1], v29.d[1]
    54f8:	4e062346 	tbl	v6.16b, {v26.16b-v27.16b}, v6.16b
    54fc:	4e162356 	tbl	v22.16b, {v26.16b-v27.16b}, v22.16b
    5500:	ad0e0c1e 	stp	q30, q3, [x0, #448]
    5504:	4e082343 	tbl	v3.16b, {v26.16b-v27.16b}, v8.16b
    5508:	4e5b7b5a 	zip2	v26.8h, v26.8h, v27.8h
    550c:	ad446fe4 	ldp	q4, q27, [sp, #128]
    5510:	ad0c1c0a 	stp	q10, q7, [x0, #384]
    5514:	6e0c2486 	mov	v6.s[1], v4.s[1]
    5518:	3dc047e4 	ldr	q4, [sp, #272]
    551c:	6e0c24b6 	mov	v22.s[1], v5.s[1]
    5520:	3dc02fe5 	ldr	q5, [sp, #176]
    5524:	6e1c673b 	mov	v27.s[3], v25.s[3]
    5528:	3dc01ff9 	ldr	q25, [sp, #112]
    552c:	6e1c6684 	mov	v4.s[3], v20.s[3]
    5530:	ad499ff4 	ldp	q20, q7, [sp, #304]
    5534:	6e0c24ba 	mov	v26.s[1], v5.s[1]
    5538:	6e0c2720 	mov	v0.s[1], v25.s[1]
    553c:	ad4667e5 	ldp	q5, q25, [sp, #192]
    5540:	6e0c24a3 	mov	v3.s[1], v5.s[1]
    5544:	3dc03be5 	ldr	q5, [sp, #224]
    5548:	6e1c6674 	mov	v20.s[3], v19.s[3]
    554c:	6e184496 	mov	v22.d[1], v4.d[1]
    5550:	3dc04bf3 	ldr	q19, [sp, #288]
    5554:	6e0c24a1 	mov	v1.s[1], v5.s[1]
    5558:	ad4b13e5 	ldp	q5, q4, [sp, #352]
    555c:	6e1c66b9 	mov	v25.s[3], v21.s[3]
    5560:	6e1c6444 	mov	v4.s[3], v2.s[3]
    5564:	6e1c6653 	mov	v19.s[3], v18.s[3]
    5568:	6e1c6605 	mov	v5.s[3], v16.s[3]
    556c:	ad478bf0 	ldp	q16, q2, [sp, #240]
    5570:	6e1c6627 	mov	v7.s[3], v17.s[3]
    5574:	6e0c2457 	mov	v23.s[1], v2.s[1]
    5578:	6e184760 	mov	v0.d[1], v27.d[1]
    557c:	6e18469a 	mov	v26.d[1], v20.d[1]
    5580:	6e0c2618 	mov	v24.s[1], v16.s[1]
    5584:	6e184726 	mov	v6.d[1], v25.d[1]
    5588:	6e184663 	mov	v3.d[1], v19.d[1]
    558c:	6e1844e1 	mov	v1.d[1], v7.d[1]
    5590:	6e184497 	mov	v23.d[1], v4.d[1]
    5594:	ad0a581a 	stp	q26, q22, [x0, #320]
    5598:	6e1844b8 	mov	v24.d[1], v5.d[1]
    559c:	ad0b0006 	stp	q6, q0, [x0, #352]
    55a0:	ad090c01 	stp	q1, q3, [x0, #288]
    55a4:	ad086017 	stp	q23, q24, [x0, #256]
    55a8:	910b43ff 	add	sp, sp, #0x2d0
    55ac:	6d4323e9 	ldp	d9, d8, [sp, #48]
    55b0:	f94023fd 	ldr	x29, [sp, #64]
    55b4:	6d422beb 	ldp	d11, d10, [sp, #32]
    55b8:	6d4133ed 	ldp	d13, d12, [sp, #16]
    55bc:	6cc53bef 	ldp	d15, d14, [sp], #80
    55c0:	d65f03c0 	ret

