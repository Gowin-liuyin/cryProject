# HANDOFF_DONE

- 证据目录：`docs/evidence/tooling-strengthen-20261015/`。规程提交 `877c5f4` 在 RTLF、dudect、Valgrind 之前。
- 未修/已修 measure 摘要与锁频证据一致；AVX2 分发两边都额外关闭。`vendor/liboqs-0.10.0/` 未改。
- RTLF `2497d660`，α=0.01：未修两次检出，已修两次不检出。
- dudect `dc269651`：未修 max t +26.41 并提前停止；已修跑满预算，max t 约 +1.15。锁频请求与上次相同，退出时已恢复。
- Valgrind 3.22 只标记 indcpa 私钥：未修的秘密条件跳转在 `poly_frommsg`，已修没有这一上下文。整段私钥标记会让两边都报 `rej_uniform`，那是公开种子被标脏。
- ctgrind 补丁对不上 Valgrind 3.22，没有当成阳性。Microwalk 因没有 Pin 跳过。
- 没有密钥恢复。R02 / R04 仍不关闭。未 push。
