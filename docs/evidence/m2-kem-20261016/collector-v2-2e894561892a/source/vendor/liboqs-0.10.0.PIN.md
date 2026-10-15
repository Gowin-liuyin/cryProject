# liboqs 0.10.0 pin

- Upstream: https://github.com/open-quantum-safe/liboqs
- Release tag: `0.10.0`
- Tag commit: `36be57445d8ca53f7095160fde548efe82ace09d`
- Release page: https://github.com/open-quantum-safe/liboqs/releases/tag/0.10.0
- Archive URL: https://github.com/open-quantum-safe/liboqs/archive/refs/tags/0.10.0.tar.gz
- Archive SHA-256: `2b7b4436be9825dd0adaf000ee4f322f06551e638a8a9c8d54eda48ed40e40a9`
- License file in tree: `LICENSE.txt` (MIT for liboqs in general; vendored algorithm subtrees keep their own licenses)
- Advisory: https://github.com/open-quantum-safe/liboqs/security/advisories/GHSA-f2v9-5498-2vpp (CVE-2024-36405); fixed in 0.10.1 via `982c762c242ef549c914891b47bf6e0ed6321f91`
- Algorithm used by this repo: `ML-KEM-768-ipd` portable C (`pqcrystals-kyber-standard_ml-kem-768-ipd_ref`), not the AVX2 backend
- Fetch: `tools/fetch_liboqs_0.10.0.sh`

The extracted tree lives at `vendor/liboqs-0.10.0/` and is gitignored. Do not edit files under that tree.
