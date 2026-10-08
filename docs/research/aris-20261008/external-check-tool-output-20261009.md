# 本轮外部检查的实际工具输出

日期：2026-10-09。本文件逐字保留本回合工具返回，作为current-external-checks-20261009.json摘要的依据。没有重试、扩展账户权限、关闭认证校验或启动实验。不把本轮失败解释为未来或其他正常获取途径永远不可用。

## 已验证邮箱接口

调用为gh api user/emails的只读请求。工具chunk为0f677e，退出1。原输出：

```text
gh: Not Found (HTTP 404)
{"message":"Not Found","documentation_url":"https://docs.github.com/rest/users/emails#list-email-addresses-for-the-authenticated-user","status":"404"}gh: This API operation needs the "user" scope. To request it, run:  gh auth refresh -h github.com -s user
```

这里保留工具的提示，不将其当成扩权授权；本回合没有执行auth refresh。

## 既定KVM只读连接

调用为BatchMode、8秒连接超时下的既定cryproject-native-x86别名uname -m。初始session68424，最终chunk d2c195，退出255。原输出：

```text
Connection closed by 119.45.121.134 port 22
```

该句柄已终止，不计为仍在运行或待收集的实验。

## 既定裸金属只读连接

调用为BatchMode、8秒连接超时下的nss-marker@10.144.144.5 uname -m。工具chunk0511fa，退出255。原输出：

```text
nss-marker@10.144.144.5: Permission denied (publickey,password).
```

## 官方工作簿正常HTTPS请求

工具chunk91a72a。Python正常HTTPS请求返回以下实际摘要；没有取得工作簿内容：

```json
{"url": "https://csrc.nist.gov/files/pubs/fips/203/final/docs/fips-203-potential-updates.xlsx", "status": 403, "content_type": "text/plain; charset=UTF-8", "bytes": 17}
```

## 审查范围

上述输出只证明当前接口权限、连接和精确URL获取结果，不证明今后无法恢复，也不代替实际研究设计、人员签署或邮箱验证信息。原输入、原源码、已核验报告和两类补充件没有因检查而改写。
