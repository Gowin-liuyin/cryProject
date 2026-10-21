0000000000004eec <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg>:
    4eec:	6dbb3bef 	stp	d15, d14, [sp, #-80]!
    4ef0:	6d0133ed 	stp	d13, d12, [sp, #16]
    4ef4:	6d022beb 	stp	d11, d10, [sp, #32]
    4ef8:	6d0323e9 	stp	d9, d8, [sp, #48]
    4efc:	f90023fd 	str	x29, [sp, #64]
    4f00:	d10b43ff 	sub	sp, sp, #0x2d0
    4f04:	91008028 	add	x8, x1, #0x20
    4f08:	eb00011f 	cmp	x8, x0
    4f0c:	54000589 	b.ls	4fbc <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xd0>  // b.plast
    4f10:	91080008 	add	x8, x0, #0x200
    4f14:	eb01011f 	cmp	x8, x1
    4f18:	54000529 	b.ls	4fbc <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0xd0>  // b.plast
    4f1c:	aa1f03e8 	mov	x8, xzr
    4f20:	91002009 	add	x9, x0, #0x8
    4f24:	5280d02a 	mov	w10, #0x681                 	// #1665
    4f28:	3868682b 	ldrb	w11, [x1, x8]
    4f2c:	1300016b 	sbfx	w11, w11, #0, #1
    4f30:	0a0a016b 	and	w11, w11, w10
    4f34:	781f812b 	sturh	w11, [x9, #-8]
    4f38:	3868682b 	ldrb	w11, [x1, x8]
    4f3c:	5302056b 	lsl	w11, w11, #30
    4f40:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4f44:	781fa12b 	sturh	w11, [x9, #-6]
    4f48:	3868682b 	ldrb	w11, [x1, x8]
    4f4c:	5303096b 	lsl	w11, w11, #29
    4f50:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4f54:	781fc12b 	sturh	w11, [x9, #-4]
    4f58:	3868682b 	ldrb	w11, [x1, x8]
    4f5c:	53040d6b 	lsl	w11, w11, #28
    4f60:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4f64:	781fe12b 	sturh	w11, [x9, #-2]
    4f68:	3868682b 	ldrb	w11, [x1, x8]
    4f6c:	5305116b 	lsl	w11, w11, #27
    4f70:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4f74:	7900012b 	strh	w11, [x9]
    4f78:	3868682b 	ldrb	w11, [x1, x8]
    4f7c:	5306156b 	lsl	w11, w11, #26
    4f80:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4f84:	7900052b 	strh	w11, [x9, #2]
    4f88:	3868682b 	ldrb	w11, [x1, x8]
    4f8c:	5307196b 	lsl	w11, w11, #25
    4f90:	0a8b7d4b 	and	w11, w10, w11, asr #31
    4f94:	7900092b 	strh	w11, [x9, #4]
    4f98:	38e8682b 	ldrsb	w11, [x1, x8]
    4f9c:	91000508 	add	x8, x8, #0x1
    4fa0:	7100017f 	cmp	w11, #0x0
    4fa4:	1a8aa3eb 	csel	w11, wzr, w10, ge	// ge = tcont
    4fa8:	f100811f 	cmp	x8, #0x20
    4fac:	79000d2b 	strh	w11, [x9, #6]
    4fb0:	91004129 	add	x9, x9, #0x10
    4fb4:	54fffba1 	b.ne	4f28 <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x3c>  // b.any
    4fb8:	14000219 	b	581c <pqcrystals_ml_kem_768_ipd_ref_poly_frommsg+0x930>
    4fbc:	4f00e420 	movi	v0.16b, #0x1
    4fc0:	4f00e441 	movi	v1.16b, #0x2
    4fc4:	3dc00022 	ldr	q2, [x1]
    4fc8:	4f02e404 	movi	v4.16b, #0x40
    4fcc:	4f00e487 	movi	v7.16b, #0x4
    4fd0:	5280d028 	mov	w8, #0x681                 	// #1665
    4fd4:	4f00e611 	movi	v17.16b, #0x10
    4fd8:	4f00e506 	movi	v6.16b, #0x8
    4fdc:	900000ab 	adrp	x11, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    4fe0:	4f01e414 	movi	v20.16b, #0x20
    4fe4:	4e020d1a 	dup	v26.8h, w8
    4fe8:	900000a8 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    4fec:	4e201c40 	and	v0.16b, v2.16b, v0.16b
    4ff0:	4e211c41 	and	v1.16b, v2.16b, v1.16b
    4ff4:	900000a9 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    4ff8:	4e241c44 	and	v4.16b, v2.16b, v4.16b
    4ffc:	4e271c47 	and	v7.16b, v2.16b, v7.16b
    5000:	f000008a 	adrp	x10, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5004:	4e311c51 	and	v17.16b, v2.16b, v17.16b
    5008:	4e261c50 	and	v16.16b, v2.16b, v6.16b
    500c:	f000008c 	adrp	x12, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5010:	4e209803 	cmeq	v3.16b, v0.16b, #0
    5014:	4e209825 	cmeq	v5.16b, v1.16b, #0
    5018:	6e208840 	cmge	v0.16b, v2.16b, #0
    501c:	4e209881 	cmeq	v1.16b, v4.16b, #0
    5020:	3dc1fd24 	ldr	q4, [x9, #2032]
    5024:	f0000089 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5028:	4e341c42 	and	v2.16b, v2.16b, v20.16b
    502c:	4e2098f4 	cmeq	v20.16b, v7.16b, #0
    5030:	4e209a27 	cmeq	v7.16b, v17.16b, #0
    5034:	4f08a472 	sxtl2	v18.8h, v3.16b
    5038:	3d809be4 	str	q4, [sp, #608]
    503c:	0f08a463 	sxtl	v3.8h, v3.8b
    5040:	0f08a431 	sxtl	v17.8h, v1.8b
    5044:	4f08a4b3 	sxtl2	v19.8h, v5.16b
    5048:	0f08a4b5 	sxtl	v21.8h, v5.8b
    504c:	3dc1f545 	ldr	q5, [x10, #2000]
    5050:	f000008a 	adrp	x10, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5054:	4e209a10 	cmeq	v16.16b, v16.16b, #0
    5058:	4e631f5c 	bic	v28.16b, v26.16b, v3.16b
    505c:	0f08a403 	sxtl	v3.8h, v0.8b
    5060:	4e721f4d 	bic	v13.16b, v26.16b, v18.16b
    5064:	3d8087e5 	str	q5, [sp, #528]
    5068:	4e711f56 	bic	v22.16b, v26.16b, v17.16b
    506c:	4e209842 	cmeq	v2.16b, v2.16b, #0
    5070:	4e731f4e 	bic	v14.16b, v26.16b, v19.16b
    5074:	0f08a692 	sxtl	v18.8h, v20.8b
    5078:	4f08a693 	sxtl2	v19.8h, v20.16b
    507c:	4e631f57 	bic	v23.16b, v26.16b, v3.16b
    5080:	3dc1d903 	ldr	q3, [x8, #1888]
    5084:	f0000088 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5088:	4e751f5d 	bic	v29.16b, v26.16b, v21.16b
    508c:	0f08a614 	sxtl	v20.8h, v16.8b
    5090:	4f08a615 	sxtl2	v21.8h, v16.16b
    5094:	3d80abe3 	str	q3, [sp, #672]
    5098:	0f08a4f8 	sxtl	v24.8h, v7.8b
    509c:	0f08a459 	sxtl	v25.8h, v2.8b
    50a0:	4e0322c3 	tbl	v3.16b, {v22.16b-v23.16b}, v3.16b
    50a4:	4e731f48 	bic	v8.16b, v26.16b, v19.16b
    50a8:	4e721f4a 	bic	v10.16b, v26.16b, v18.16b
    50ac:	4e751f49 	bic	v9.16b, v26.16b, v21.16b
    50b0:	4e741f4b 	bic	v11.16b, v26.16b, v20.16b
    50b4:	4eb61ed3 	mov	v19.16b, v22.16b
    50b8:	4e781f54 	bic	v20.16b, v26.16b, v24.16b
    50bc:	4f08a406 	sxtl2	v6.8h, v0.16b
    50c0:	3dc20160 	ldr	q0, [x11, #2048]
    50c4:	f000008b 	adrp	x11, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    50c8:	4e791f55 	bic	v21.16b, v26.16b, v25.16b
    50cc:	4f08a4f2 	sxtl2	v18.8h, v7.16b
    50d0:	3d80b3e3 	str	q3, [sp, #704]
    50d4:	3dc1e503 	ldr	q3, [x8, #1936]
    50d8:	f0000088 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    50dc:	3dc1f11b 	ldr	q27, [x8, #1984]
    50e0:	f0000088 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    50e4:	3d807fe0 	str	q0, [sp, #496]
    50e8:	3dc20911 	ldr	q17, [x8, #2080]
    50ec:	f0000088 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    50f0:	3d809fe3 	str	q3, [sp, #624]
    50f4:	4e0322de 	tbl	v30.16b, {v22.16b-v23.16b}, v3.16b
    50f8:	3dc20d03 	ldr	q3, [x8, #2096]
    50fc:	f0000088 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5100:	3d80a3f1 	str	q17, [sp, #640]
    5104:	4e1122d8 	tbl	v24.16b, {v22.16b-v23.16b}, v17.16b
    5108:	4f08a431 	sxtl2	v17.8h, v1.16b
    510c:	3dc1dd01 	ldr	q1, [x8, #1904]
    5110:	6e1e66f3 	mov	v19.h[7], v23.h[6]
    5114:	3d8097e3 	str	q3, [sp, #592]
    5118:	4e0322cc 	tbl	v12.16b, {v22.16b-v23.16b}, v3.16b
    511c:	4e002283 	tbl	v3.16b, {v20.16b-v21.16b}, v0.16b
    5120:	4e556a80 	trn2	v0.8h, v20.8h, v21.8h
    5124:	3d807be1 	str	q1, [sp, #480]
    5128:	4e01229f 	tbl	v31.16b, {v20.16b-v21.16b}, v1.16b
    512c:	4e557a81 	zip2	v1.8h, v20.8h, v21.8h
    5130:	f0000088 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5134:	4f08a447 	sxtl2	v7.8h, v2.16b
    5138:	4e577acf 	zip2	v15.8h, v22.8h, v23.8h
    513c:	3dc21102 	ldr	q2, [x8, #2112]
    5140:	4e1b22d9 	tbl	v25.16b, {v22.16b-v23.16b}, v27.16b
    5144:	4e0422d0 	tbl	v16.16b, {v22.16b-v23.16b}, v4.16b
    5148:	6e1c6580 	mov	v0.s[3], v12.s[3]
    514c:	3dc1e937 	ldr	q23, [x9, #1952]
    5150:	f0000088 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5154:	6e1c6661 	mov	v1.s[3], v19.s[3]
    5158:	3d8083e2 	str	q2, [sp, #512]
    515c:	4e022282 	tbl	v2.16b, {v20.16b-v21.16b}, v2.16b
    5160:	4e172284 	tbl	v4.16b, {v20.16b-v21.16b}, v23.16b
    5164:	4e052285 	tbl	v5.16b, {v20.16b-v21.16b}, v5.16b
    5168:	f0000089 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    516c:	4eb41e96 	mov	v22.16b, v20.16b
    5170:	6e1c6603 	mov	v3.s[3], v16.s[3]
    5174:	3d8057f7 	str	q23, [sp, #336]
    5178:	3d8077fb 	str	q27, [sp, #464]
    517c:	4e4e39b0 	zip1	v16.8h, v13.8h, v14.8h
    5180:	ad0883e1 	stp	q1, q0, [sp, #272]
    5184:	4eaa1d40 	mov	v0.16b, v10.16b
    5188:	6e1c65e2 	mov	v2.s[3], v15.s[3]
    518c:	6e1c67c4 	mov	v4.s[3], v30.s[3]
    5190:	6e1c6725 	mov	v5.s[3], v25.s[3]
    5194:	6e1646b6 	mov	v22.h[5], v21.h[4]
    5198:	4e4b6941 	trn2	v1.8h, v10.8h, v11.8h
    519c:	4e721f54 	bic	v20.16b, v26.16b, v18.16b
    51a0:	4e711f51 	bic	v17.16b, v26.16b, v17.16b
    51a4:	6e0e2560 	mov	v0.h[3], v11.h[2]
    51a8:	4e661f52 	bic	v18.16b, v26.16b, v6.16b
    51ac:	3dc0b3e6 	ldr	q6, [sp, #704]
    51b0:	3d8043e2 	str	q2, [sp, #256]
    51b4:	3dc1ed22 	ldr	q2, [x9, #1968]
    51b8:	f0000089 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    51bc:	ad0b13e5 	stp	q5, q4, [sp, #352]
    51c0:	6e1c6716 	mov	v22.s[3], v24.s[3]
    51c4:	6e1c64df 	mov	v31.s[3], v6.s[3]
    51c8:	3d8093e2 	str	q2, [sp, #576]
    51cc:	4e671f55 	bic	v21.16b, v26.16b, v7.16b
    51d0:	3dc1cd67 	ldr	q7, [x11, #1840]
    51d4:	3d803be0 	str	q0, [sp, #224]
    51d8:	3dc1e100 	ldr	q0, [x8, #1920]
    51dc:	f0000088 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    51e0:	3dc1c105 	ldr	q5, [x8, #1792]
    51e4:	f0000088 	adrp	x8, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    51e8:	4e07239e 	tbl	v30.16b, {v28.16b-v29.16b}, v7.16b
    51ec:	3d8017e0 	str	q0, [sp, #80]
    51f0:	4e002140 	tbl	v0.16b, {v10.16b-v11.16b}, v0.16b
    51f4:	4e172298 	tbl	v24.16b, {v20.16b-v21.16b}, v23.16b
    51f8:	ad098ff6 	stp	q22, q3, [sp, #304]
    51fc:	3dc1c943 	ldr	q3, [x10, #1824]
    5200:	f000008a 	adrp	x10, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5204:	3d808be5 	str	q5, [sp, #544]
    5208:	4e497916 	zip2	v22.8h, v8.8h, v9.8h
    520c:	3d8067ff 	str	q31, [sp, #400]
    5210:	3d803fe0 	str	q0, [sp, #240]
    5214:	4e022140 	tbl	v0.16b, {v10.16b-v11.16b}, v2.16b
    5218:	3dc1d122 	ldr	q2, [x9, #1856]
    521c:	f0000089 	adrp	x9, 18000 <pqcrystals_ml_kem_768_ipd_ref_invntt+0x560>
    5220:	3d808fe3 	str	q3, [sp, #560]
    5224:	3d8063e2 	str	q2, [sp, #384]
    5228:	3dc20526 	ldr	q6, [x9, #2064]
    522c:	3d80b3e7 	str	q7, [sp, #704]
    5230:	3d8037e0 	str	q0, [sp, #208]
    5234:	4e052140 	tbl	v0.16b, {v10.16b-v11.16b}, v5.16b
    5238:	4ea21c45 	mov	v5.16b, v2.16b
    523c:	3d80a7e6 	str	q6, [sp, #656]
    5240:	4e06238c 	tbl	v12.16b, {v28.16b-v29.16b}, v6.16b
    5244:	ad0587e0 	stp	q0, q1, [sp, #176]
    5248:	4e4b7940 	zip2	v0.8h, v10.8h, v11.8h
    524c:	4e032141 	tbl	v1.16b, {v10.16b-v11.16b}, v3.16b
    5250:	3dc1f903 	ldr	q3, [x8, #2016]
    5254:	910643e8 	add	x8, sp, #0x190
    5258:	4e03238f 	tbl	v15.16b, {v28.16b-v29.16b}, v3.16b
    525c:	3d8073e3 	str	q3, [sp, #448]
    5260:	3d8027e0 	str	q0, [sp, #144]
    5264:	4e022140 	tbl	v0.16b, {v10.16b-v11.16b}, v2.16b
    5268:	3dc1c542 	ldr	q2, [x10, #1808]
    526c:	4e5d7b8b 	zip2	v11.8h, v28.8h, v29.8h
    5270:	3d80afe2 	str	q2, [sp, #688]
    5274:	4e02239f 	tbl	v31.16b, {v28.16b-v29.16b}, v2.16b
    5278:	3dc0abe2 	ldr	q2, [sp, #672]
    527c:	ad0307e0 	stp	q0, q1, [sp, #96]
    5280:	4e5d3b80 	zip1	v0.8h, v28.8h, v29.8h
    5284:	4e022224 	tbl	v4.16b, {v17.16b-v18.16b}, v2.16b
    5288:	ad531be2 	ldp	q2, q6, [sp, #608]
    528c:	4ea31c61 	mov	v1.16b, v3.16b
    5290:	3dc1d583 	ldr	q3, [x12, #1872]
    5294:	3d802be0 	str	q0, [sp, #160]
    5298:	4e5d6b80 	trn2	v0.8h, v28.8h, v29.8h
    529c:	4e03239d 	tbl	v29.16b, {v28.16b-v29.16b}, v3.16b
    52a0:	4eb11e3c 	mov	v28.16b, v17.16b
    52a4:	3d806fe3 	str	q3, [sp, #432]
    52a8:	3d8023e0 	str	q0, [sp, #128]
    52ac:	4e062220 	tbl	v0.16b, {v17.16b-v18.16b}, v6.16b
    52b0:	6e1e665c 	mov	v28.h[7], v18.h[6]
    52b4:	4e4e69a6 	trn2	v6.8h, v13.8h, v14.8h
    52b8:	ad0193e0 	stp	q0, q4, [sp, #48]
    52bc:	4e1b2224 	tbl	v4.16b, {v17.16b-v18.16b}, v27.16b
    52c0:	4e022220 	tbl	v0.16b, {v17.16b-v18.16b}, v2.16b
    52c4:	4e527a3b 	zip2	v27.8h, v17.8h, v18.8h
    52c8:	ad0093e0 	stp	q0, q4, [sp, #16]
    52cc:	3dc0a3e0 	ldr	q0, [sp, #640]
    52d0:	4eb41e84 	mov	v4.16b, v20.16b
    52d4:	4e002220 	tbl	v0.16b, {v17.16b-v18.16b}, v0.16b
    52d8:	6e1646a4 	mov	v4.h[5], v21.h[4]
    52dc:	3d8003e0 	str	q0, [sp]
    52e0:	3dc097e0 	ldr	q0, [sp, #592]
    52e4:	4e00222a 	tbl	v10.16b, {v17.16b-v18.16b}, v0.16b
    52e8:	3dc07be0 	ldr	q0, [sp, #480]
    52ec:	4e556a92 	trn2	v18.8h, v20.8h, v21.8h
    52f0:	4e557a91 	zip2	v17.8h, v20.8h, v21.8h
    52f4:	4e002299 	tbl	v25.16b, {v20.16b-v21.16b}, v0.16b
    52f8:	3dc087e0 	ldr	q0, [sp, #528]
    52fc:	4e002297 	tbl	v23.16b, {v20.16b-v21.16b}, v0.16b
    5300:	ad4f83e2 	ldp	q2, q0, [sp, #496]
    5304:	6e1c6791 	mov	v17.s[3], v28.s[3]
    5308:	3dc017fc 	ldr	q28, [sp, #80]
    530c:	6e1c6552 	mov	v18.s[3], v10.s[3]
    5310:	4e022293 	tbl	v19.16b, {v20.16b-v21.16b}, v2.16b
    5314:	4e002287 	tbl	v7.16b, {v20.16b-v21.16b}, v0.16b
    5318:	4e052114 	tbl	v20.16b, {v8.16b-v9.16b}, v5.16b
    531c:	4e0121a5 	tbl	v5.16b, {v13.16b-v14.16b}, v1.16b
    5320:	3dc08fe1 	ldr	q1, [sp, #560]
    5324:	4e0321a0 	tbl	v0.16b, {v13.16b-v14.16b}, v3.16b
    5328:	3dc0a7e2 	ldr	q2, [sp, #656]
    532c:	4e012115 	tbl	v21.16b, {v8.16b-v9.16b}, v1.16b
    5330:	4e0221a3 	tbl	v3.16b, {v13.16b-v14.16b}, v2.16b
    5334:	ad5587e2 	ldp	q2, q1, [sp, #688]
    5338:	6e1c6767 	mov	v7.s[3], v27.s[3]
    533c:	4e0121a1 	tbl	v1.16b, {v13.16b-v14.16b}, v1.16b
    5340:	6e0c2680 	mov	v0.s[1], v20.s[1]
    5344:	3dc08bfb 	ldr	q27, [sp, #544]
    5348:	4e0221a2 	tbl	v2.16b, {v13.16b-v14.16b}, v2.16b
    534c:	4e4e79ad 	zip2	v13.8h, v13.8h, v14.8h
    5350:	4ea81d14 	mov	v20.16b, v8.16b
    5354:	4e1b211b 	tbl	v27.16b, {v8.16b-v9.16b}, v27.16b
    5358:	4e49690e 	trn2	v14.8h, v8.8h, v9.8h
    535c:	6e0c26a1 	mov	v1.s[1], v21.s[1]
    5360:	3dc093f5 	ldr	q21, [sp, #576]
    5364:	6e1844e0 	mov	v0.d[1], v7.d[1]
    5368:	6e0c26c2 	mov	v2.s[1], v22.s[1]
    536c:	4e1c2116 	tbl	v22.16b, {v8.16b-v9.16b}, v28.16b
    5370:	6e0e2534 	mov	v20.h[3], v9.h[2]
    5374:	4e152115 	tbl	v21.16b, {v8.16b-v9.16b}, v21.16b
    5378:	6e0c276d 	mov	v13.s[1], v27.s[1]
    537c:	ad406fe8 	ldp	q8, q27, [sp]
    5380:	3dc00be7 	ldr	q7, [sp, #32]
    5384:	6e0c25c3 	mov	v3.s[1], v14.s[1]
    5388:	6e184621 	mov	v1.d[1], v17.d[1]
    538c:	6e1c6504 	mov	v4.s[3], v8.s[3]
    5390:	4f02e411 	movi	v17.16b, #0x40
    5394:	6e184642 	mov	v2.d[1], v18.d[1]
    5398:	6e1c6773 	mov	v19.s[3], v27.s[3]
    539c:	6e1c64f7 	mov	v23.s[3], v7.s[3]
    53a0:	6e0c2685 	mov	v5.s[1], v20.s[1]
    53a4:	3dc00fe7 	ldr	q7, [sp, #48]
    53a8:	6e0c26a6 	mov	v6.s[1], v21.s[1]
    53ac:	6e0c26d0 	mov	v16.s[1], v22.s[1]
    53b0:	ad070001 	stp	q1, q0, [x0, #224]
    53b4:	6e18448d 	mov	v13.d[1], v4.d[1]
    53b8:	ad4303e4 	ldp	q4, q0, [sp, #96]
    53bc:	6e184663 	mov	v3.d[1], v19.d[1]
    53c0:	6e1c64f8 	mov	v24.s[3], v7.s[3]
    53c4:	6e0c241e 	mov	v30.s[1], v0.s[1]
    53c8:	3dc027e0 	ldr	q0, [sp, #144]
    53cc:	6e1846e5 	mov	v5.d[1], v23.d[1]
    53d0:	6e0c249d 	mov	v29.s[1], v4.s[1]
    53d4:	3dc013e7 	ldr	q7, [sp, #64]
    53d8:	4f01e404 	movi	v4.16b, #0x20
    53dc:	6e0c241f 	mov	v31.s[1], v0.s[1]
    53e0:	ad4583e1 	ldp	q1, q0, [sp, #176]
    53e4:	ad06080d 	stp	q13, q2, [x0, #192]
    53e8:	3dc023e2 	ldr	q2, [sp, #128]
    53ec:	6e1c64f9 	mov	v25.s[3], v7.s[3]
    53f0:	ad050c05 	stp	q5, q3, [x0, #160]
    53f4:	6e184706 	mov	v6.d[1], v24.d[1]
    53f8:	6e0c240c 	mov	v12.s[1], v0.s[1]
    53fc:	3dc043e0 	ldr	q0, [sp, #256]
    5400:	6e0c242b 	mov	v11.s[1], v1.s[1]
    5404:	3dc02be1 	ldr	q1, [sp, #160]
    5408:	6e18441d 	mov	v29.d[1], v0.d[1]
    540c:	3dc03be0 	ldr	q0, [sp, #224]
    5410:	6e184730 	mov	v16.d[1], v25.d[1]
    5414:	6e0c240f 	mov	v15.s[1], v0.s[1]
    5418:	3dc047e0 	ldr	q0, [sp, #272]
    541c:	6e18441e 	mov	v30.d[1], v0.d[1]
    5420:	3dc037e0 	ldr	q0, [sp, #208]
    5424:	ad041810 	stp	q16, q6, [x0, #128]
    5428:	4f00e486 	movi	v6.16b, #0x4
    542c:	4f00e510 	movi	v16.16b, #0x8
    5430:	6e0c2402 	mov	v2.s[1], v0.s[1]
    5434:	3dc04be0 	ldr	q0, [sp, #288]
    5438:	6e18441f 	mov	v31.d[1], v0.d[1]
    543c:	3dc03fe0 	ldr	q0, [sp, #240]
    5440:	ad03741e 	stp	q30, q29, [x0, #96]
    5444:	6e0c2401 	mov	v1.s[1], v0.s[1]
    5448:	ad4983e3 	ldp	q3, q0, [sp, #304]
    544c:	6e18446b 	mov	v11.d[1], v3.d[1]
    5450:	6e18440c 	mov	v12.d[1], v0.d[1]
    5454:	ad4b03e3 	ldp	q3, q0, [sp, #352]
    5458:	6e184402 	mov	v2.d[1], v0.d[1]
    545c:	3dc067e0 	ldr	q0, [sp, #400]
    5460:	6e18446f 	mov	v15.d[1], v3.d[1]
    5464:	ad027c0b 	stp	q11, q31, [x0, #64]
    5468:	4f00e603 	movi	v3.16b, #0x10
    546c:	3dc06feb 	ldr	q11, [sp, #432]
    5470:	6e184401 	mov	v1.d[1], v0.d[1]
    5474:	ad01300f 	stp	q15, q12, [x0, #32]
    5478:	3dc097ec 	ldr	q12, [sp, #592]
    547c:	ad000801 	stp	q1, q2, [x0]
    5480:	4f00e421 	movi	v1.16b, #0x1
    5484:	4f00e442 	movi	v2.16b, #0x2
    5488:	3dc00420 	ldr	q0, [x1, #16]
    548c:	4e231c03 	and	v3.16b, v0.16b, v3.16b
    5490:	4e241c04 	and	v4.16b, v0.16b, v4.16b
    5494:	4e311c11 	and	v17.16b, v0.16b, v17.16b
    5498:	4e211c01 	and	v1.16b, v0.16b, v1.16b
    549c:	4e221c02 	and	v2.16b, v0.16b, v2.16b
    54a0:	4e261c06 	and	v6.16b, v0.16b, v6.16b
    54a4:	4e301c10 	and	v16.16b, v0.16b, v16.16b
    54a8:	6e208800 	cmge	v0.16b, v0.16b, #0
    54ac:	4e209863 	cmeq	v3.16b, v3.16b, #0
    54b0:	4e209884 	cmeq	v4.16b, v4.16b, #0
    54b4:	4e209821 	cmeq	v1.16b, v1.16b, #0
    54b8:	4e209842 	cmeq	v2.16b, v2.16b, #0
    54bc:	4e2098c6 	cmeq	v6.16b, v6.16b, #0
    54c0:	0f08a472 	sxtl	v18.8h, v3.8b
    54c4:	4f08a496 	sxtl2	v22.8h, v4.16b
    54c8:	4f08a463 	sxtl2	v3.8h, v3.16b
    54cc:	4f08a425 	sxtl2	v5.8h, v1.16b
    54d0:	0f08a421 	sxtl	v1.8h, v1.8b
    54d4:	4f08a447 	sxtl2	v7.8h, v2.16b
    54d8:	0f08a442 	sxtl	v2.8h, v2.8b
    54dc:	4e611f53 	bic	v19.16b, v26.16b, v1.16b
    54e0:	4e209a21 	cmeq	v1.16b, v17.16b, #0
    54e4:	4e651f5d 	bic	v29.16b, v26.16b, v5.16b
    54e8:	4e621f54 	bic	v20.16b, v26.16b, v2.16b
    54ec:	0f08a485 	sxtl	v5.8h, v4.8b
    54f0:	0f08a404 	sxtl	v4.8h, v0.8b
    54f4:	4f08a400 	sxtl2	v0.8h, v0.16b
    54f8:	0f08a4c2 	sxtl	v2.8h, v6.8b
    54fc:	4e671f5e 	bic	v30.16b, v26.16b, v7.16b
    5500:	0f08a437 	sxtl	v23.8h, v1.8b
    5504:	4f08a421 	sxtl2	v1.8h, v1.16b
    5508:	4e209a07 	cmeq	v7.16b, v16.16b, #0
    550c:	4c00ad13 	st1	{v19.2d-v20.2d}, [x8]
    5510:	4e721f52 	bic	v18.16b, v26.16b, v18.16b
    5514:	4e631f54 	bic	v20.16b, v26.16b, v3.16b
    5518:	4e651f53 	bic	v19.16b, v26.16b, v5.16b
    551c:	4e621f58 	bic	v24.16b, v26.16b, v2.16b
    5520:	4f08a4c5 	sxtl2	v5.8h, v6.16b
    5524:	4e611f49 	bic	v9.16b, v26.16b, v1.16b
    5528:	4eb21e41 	mov	v1.16b, v18.16b
    552c:	0f08a4e6 	sxtl	v6.8h, v7.8b
    5530:	4e601f4a 	bic	v10.16b, v26.16b, v0.16b
    5534:	3dc07be0 	ldr	q0, [sp, #480]
    5538:	4e771f4d 	bic	v13.16b, v26.16b, v23.16b
    553c:	4e641f4e 	bic	v14.16b, v26.16b, v4.16b
    5540:	4e536a44 	trn2	v4.8h, v18.8h, v19.8h
    5544:	4f08a4e7 	sxtl2	v7.8h, v7.16b
    5548:	6e164661 	mov	v1.h[5], v19.h[4]
    554c:	4e002243 	tbl	v3.16b, {v18.16b-v19.16b}, v0.16b
    5550:	4e661f59 	bic	v25.16b, v26.16b, v6.16b
    5554:	4e651f50 	bic	v16.16b, v26.16b, v5.16b
    5558:	4eb81f05 	mov	v5.16b, v24.16b
    555c:	4e761f55 	bic	v21.16b, v26.16b, v22.16b
    5560:	4e671f51 	bic	v17.16b, v26.16b, v7.16b
    5564:	4e537a47 	zip2	v7.8h, v18.8h, v19.8h
    5568:	ad4e5fff 	ldp	q31, q23, [sp, #448]
    556c:	3d804fe1 	str	q1, [sp, #304]
    5570:	3dc057e1 	ldr	q1, [sp, #336]
    5574:	6e0e2725 	mov	v5.h[3], v25.h[2]
    5578:	4e002280 	tbl	v0.16b, {v20.16b-v21.16b}, v0.16b
    557c:	4e012242 	tbl	v2.16b, {v18.16b-v19.16b}, v1.16b
    5580:	4e01229a 	tbl	v26.16b, {v20.16b-v21.16b}, v1.16b
    5584:	ad0697e7 	stp	q7, q5, [sp, #208]
    5588:	4e1c2307 	tbl	v7.16b, {v24.16b-v25.16b}, v28.16b
    558c:	ad0b0fe2 	stp	q2, q3, [sp, #352]
    5590:	3dc087e2 	ldr	q2, [sp, #528]
    5594:	4e022243 	tbl	v3.16b, {v18.16b-v19.16b}, v2.16b
    5598:	4e02229b 	tbl	v27.16b, {v20.16b-v21.16b}, v2.16b
    559c:	4ea91d22 	mov	v2.16b, v9.16b
    55a0:	6e1e6542 	mov	v2.h[7], v10.h[6]
    55a4:	3d8053e3 	str	q3, [sp, #320]
    55a8:	3dc07fe3 	ldr	q3, [sp, #496]
    55ac:	4e032246 	tbl	v6.16b, {v18.16b-v19.16b}, v3.16b
    55b0:	ad089be4 	stp	q4, q6, [sp, #272]
    55b4:	3dc083e4 	ldr	q4, [sp, #512]
    55b8:	4e042246 	tbl	v6.16b, {v18.16b-v19.16b}, v4.16b
    55bc:	3dc093f2 	ldr	q18, [sp, #576]
    55c0:	4ebc1f93 	mov	v19.16b, v28.16b
    55c4:	4e1c2213 	tbl	v19.16b, {v16.16b-v17.16b}, v28.16b
    55c8:	4e03229c 	tbl	v28.16b, {v20.16b-v21.16b}, v3.16b
    55cc:	4e122305 	tbl	v5.16b, {v24.16b-v25.16b}, v18.16b
    55d0:	4e122212 	tbl	v18.16b, {v16.16b-v17.16b}, v18.16b
    55d4:	ad079fe5 	stp	q5, q7, [sp, #240]
    55d8:	4e596b01 	trn2	v1.8h, v24.8h, v25.8h
    55dc:	3dc08be7 	ldr	q7, [sp, #544]
    55e0:	4e072305 	tbl	v5.16b, {v24.16b-v25.16b}, v7.16b
    55e4:	4e072207 	tbl	v7.16b, {v16.16b-v17.16b}, v7.16b
    55e8:	ad0587e5 	stp	q5, q1, [sp, #176]
    55ec:	4e597b05 	zip2	v5.8h, v24.8h, v25.8h
    55f0:	3d808be7 	str	q7, [sp, #544]
    55f4:	4e5e6ba7 	trn2	v7.8h, v29.8h, v30.8h
    55f8:	ad0497e6 	stp	q6, q5, [sp, #144]
    55fc:	3dc08fe6 	ldr	q6, [sp, #560]
    5600:	4e062305 	tbl	v5.16b, {v24.16b-v25.16b}, v6.16b
    5604:	4e062206 	tbl	v6.16b, {v16.16b-v17.16b}, v6.16b
    5608:	3d8023e5 	str	q5, [sp, #128]
    560c:	3dc063e5 	ldr	q5, [sp, #384]
    5610:	ad024be6 	stp	q6, q18, [sp, #64]
    5614:	4e042292 	tbl	v18.16b, {v20.16b-v21.16b}, v4.16b
    5618:	4e052316 	tbl	v22.16b, {v24.16b-v25.16b}, v5.16b
    561c:	3dc0abf9 	ldr	q25, [sp, #672]
    5620:	4e052206 	tbl	v6.16b, {v16.16b-v17.16b}, v5.16b
    5624:	4e516a05 	trn2	v5.8h, v16.8h, v17.8h
    5628:	4e192121 	tbl	v1.16b, {v9.16b-v10.16b}, v25.16b
    562c:	ad035bf3 	stp	q19, q22, [sp, #96]
    5630:	4eb01e13 	mov	v19.16b, v16.16b
    5634:	ad535bf8 	ldp	q24, q22, [sp, #608]
    5638:	3d8063e5 	str	q5, [sp, #384]
    563c:	4e517a05 	zip2	v5.8h, v16.8h, v17.8h
    5640:	4e557a90 	zip2	v16.8h, v20.8h, v21.8h
    5644:	6e0e2633 	mov	v19.h[3], v17.h[2]
    5648:	4e556a91 	trn2	v17.8h, v20.8h, v21.8h
    564c:	4e16212f 	tbl	v15.16b, {v9.16b-v10.16b}, v22.16b
    5650:	6e1c6450 	mov	v16.s[3], v2.s[3]
    5654:	3dc013e2 	ldr	q2, [sp, #64]
    5658:	ad011be5 	stp	q5, q6, [sp, #32]
    565c:	ad11cfe0 	stp	q0, q19, [sp, #560]
    5660:	4e172120 	tbl	v0.16b, {v9.16b-v10.16b}, v23.16b
    5664:	4e1f23a5 	tbl	v5.16b, {v29.16b-v30.16b}, v31.16b
    5668:	ad5423f3 	ldp	q19, q8, [sp, #640]
    566c:	4eb41e86 	mov	v6.16b, v20.16b
    5670:	4e4a7934 	zip2	v20.8h, v9.8h, v10.8h
    5674:	6e1c65fa 	mov	v26.s[3], v15.s[3]
    5678:	3d807fe0 	str	q0, [sp, #496]
    567c:	4e182120 	tbl	v0.16b, {v9.16b-v10.16b}, v24.16b
    5680:	4e0823a4 	tbl	v4.16b, {v29.16b-v30.16b}, v8.16b
    5684:	6e1646a6 	mov	v6.h[5], v21.h[4]
    5688:	4e0c2135 	tbl	v21.16b, {v9.16b-v10.16b}, v12.16b
    568c:	4e132129 	tbl	v9.16b, {v9.16b-v10.16b}, v19.16b
    5690:	4e5e3baa 	zip1	v10.8h, v29.8h, v30.8h
    5694:	6e1c6692 	mov	v18.s[3], v20.s[3]
    5698:	4e0c21b4 	tbl	v20.16b, {v13.16b-v14.16b}, v12.16b
    569c:	4e1321b3 	tbl	v19.16b, {v13.16b-v14.16b}, v19.16b
    56a0:	ad1007e0 	stp	q0, q1, [sp, #512]
    56a4:	ad5583e1 	ldp	q1, q0, [sp, #688]
    56a8:	6e1c66b1 	mov	v17.s[3], v21.s[3]
    56ac:	6e1c6526 	mov	v6.s[3], v9.s[3]
    56b0:	4e0123a3 	tbl	v3.16b, {v29.16b-v30.16b}, v1.16b
    56b4:	4e0023a1 	tbl	v1.16b, {v29.16b-v30.16b}, v0.16b
    56b8:	4e0b23a0 	tbl	v0.16b, {v29.16b-v30.16b}, v11.16b
    56bc:	4e5e7bbe 	zip2	v30.8h, v29.8h, v30.8h
    56c0:	6e0c2441 	mov	v1.s[1], v2.s[1]
    56c4:	ad410bf5 	ldp	q21, q2, [sp, #32]
    56c8:	6e0c26a3 	mov	v3.s[1], v21.s[1]
    56cc:	4ead1db5 	mov	v21.16b, v13.16b
    56d0:	6e0c2440 	mov	v0.s[1], v2.s[1]
    56d4:	3dc017e2 	ldr	q2, [sp, #80]
    56d8:	6e0c2447 	mov	v7.s[1], v2.s[1]
    56dc:	3dc07fe2 	ldr	q2, [sp, #496]
    56e0:	6e184601 	mov	v1.d[1], v16.d[1]
    56e4:	4e1621b0 	tbl	v16.16b, {v13.16b-v14.16b}, v22.16b
    56e8:	6e184623 	mov	v3.d[1], v17.d[1]
    56ec:	6e1c645b 	mov	v27.s[3], v2.s[3]
    56f0:	3dc093e2 	ldr	q2, [sp, #576]
    56f4:	6e184640 	mov	v0.d[1], v18.d[1]
    56f8:	4e1721b1 	tbl	v17.16b, {v13.16b-v14.16b}, v23.16b
    56fc:	4e1821b2 	tbl	v18.16b, {v13.16b-v14.16b}, v24.16b
    5700:	6e1e65d5 	mov	v21.h[7], v14.h[6]
    5704:	6e0c2445 	mov	v5.s[1], v2.s[1]
    5708:	ad505be2 	ldp	q2, q22, [sp, #512]
    570c:	6e184747 	mov	v7.d[1], v26.d[1]
    5710:	6e1c645c 	mov	v28.s[3], v2.s[3]
    5714:	3dc063e2 	ldr	q2, [sp, #384]
    5718:	ad0f0001 	stp	q1, q0, [x0, #480]
    571c:	6e0c2444 	mov	v4.s[1], v2.s[1]
    5720:	ad5177e2 	ldp	q2, q29, [sp, #544]
    5724:	6e184765 	mov	v5.d[1], v27.d[1]
    5728:	4c40ad1a 	ld1	{v26.2d-v27.2d}, [x8]
    572c:	6e0c245e 	mov	v30.s[1], v2.s[1]
    5730:	6e1c66dd 	mov	v29.s[3], v22.s[3]
    5734:	3dc01bf6 	ldr	q22, [sp, #96]
    5738:	6e184784 	mov	v4.d[1], v28.d[1]
    573c:	4e0b2340 	tbl	v0.16b, {v26.16b-v27.16b}, v11.16b
    5740:	4e1f2341 	tbl	v1.16b, {v26.16b-v27.16b}, v31.16b
    5744:	6e0c26ca 	mov	v10.s[1], v22.s[1]
    5748:	4e5b3b57 	zip1	v23.8h, v26.8h, v27.8h
    574c:	4e5b6b58 	trn2	v24.8h, v26.8h, v27.8h
    5750:	4e1921a2 	tbl	v2.16b, {v13.16b-v14.16b}, v25.16b
    5754:	4e4e79b9 	zip2	v25.8h, v13.8h, v14.8h
    5758:	6e1844de 	mov	v30.d[1], v6.d[1]
    575c:	ad559bf6 	ldp	q22, q6, [sp, #688]
    5760:	ad0d1005 	stp	q5, q4, [x0, #416]
    5764:	3dc02be5 	ldr	q5, [sp, #160]
    5768:	6e1847aa 	mov	v10.d[1], v29.d[1]
    576c:	4e062346 	tbl	v6.16b, {v26.16b-v27.16b}, v6.16b
    5770:	4e162356 	tbl	v22.16b, {v26.16b-v27.16b}, v22.16b
    5774:	ad0e0c1e 	stp	q30, q3, [x0, #448]
    5778:	4e082343 	tbl	v3.16b, {v26.16b-v27.16b}, v8.16b
    577c:	4e5b7b5a 	zip2	v26.8h, v26.8h, v27.8h
    5780:	ad446fe4 	ldp	q4, q27, [sp, #128]
    5784:	ad0c1c0a 	stp	q10, q7, [x0, #384]
    5788:	6e0c2486 	mov	v6.s[1], v4.s[1]
    578c:	3dc047e4 	ldr	q4, [sp, #272]
    5790:	6e0c24b6 	mov	v22.s[1], v5.s[1]
    5794:	3dc02fe5 	ldr	q5, [sp, #176]
    5798:	6e1c673b 	mov	v27.s[3], v25.s[3]
    579c:	3dc01ff9 	ldr	q25, [sp, #112]
    57a0:	6e1c6684 	mov	v4.s[3], v20.s[3]
    57a4:	ad499ff4 	ldp	q20, q7, [sp, #304]
    57a8:	6e0c24ba 	mov	v26.s[1], v5.s[1]
    57ac:	6e0c2720 	mov	v0.s[1], v25.s[1]
    57b0:	ad4667e5 	ldp	q5, q25, [sp, #192]
    57b4:	6e0c24a3 	mov	v3.s[1], v5.s[1]
    57b8:	3dc03be5 	ldr	q5, [sp, #224]
    57bc:	6e1c6674 	mov	v20.s[3], v19.s[3]
    57c0:	6e184496 	mov	v22.d[1], v4.d[1]
    57c4:	3dc04bf3 	ldr	q19, [sp, #288]
    57c8:	6e0c24a1 	mov	v1.s[1], v5.s[1]
    57cc:	ad4b13e5 	ldp	q5, q4, [sp, #352]
    57d0:	6e1c66b9 	mov	v25.s[3], v21.s[3]
    57d4:	6e1c6444 	mov	v4.s[3], v2.s[3]
    57d8:	6e1c6653 	mov	v19.s[3], v18.s[3]
    57dc:	6e1c6605 	mov	v5.s[3], v16.s[3]
    57e0:	ad478bf0 	ldp	q16, q2, [sp, #240]
    57e4:	6e1c6627 	mov	v7.s[3], v17.s[3]
    57e8:	6e0c2457 	mov	v23.s[1], v2.s[1]
    57ec:	6e184760 	mov	v0.d[1], v27.d[1]
    57f0:	6e18469a 	mov	v26.d[1], v20.d[1]
    57f4:	6e0c2618 	mov	v24.s[1], v16.s[1]
    57f8:	6e184726 	mov	v6.d[1], v25.d[1]
    57fc:	6e184663 	mov	v3.d[1], v19.d[1]
    5800:	6e1844e1 	mov	v1.d[1], v7.d[1]
    5804:	6e184497 	mov	v23.d[1], v4.d[1]
    5808:	ad0a581a 	stp	q26, q22, [x0, #320]
    580c:	6e1844b8 	mov	v24.d[1], v5.d[1]
    5810:	ad0b0006 	stp	q6, q0, [x0, #352]
    5814:	ad090c01 	stp	q1, q3, [x0, #288]
    5818:	ad086017 	stp	q23, q24, [x0, #256]
    581c:	910b43ff 	add	sp, sp, #0x2d0
    5820:	6d4323e9 	ldp	d9, d8, [sp, #48]
    5824:	f94023fd 	ldr	x29, [sp, #64]
    5828:	6d422beb 	ldp	d11, d10, [sp, #32]
    582c:	6d4133ed 	ldp	d13, d12, [sp, #16]
    5830:	6cc53bef 	ldp	d15, d14, [sp], #80
    5834:	d65f03c0 	ret

