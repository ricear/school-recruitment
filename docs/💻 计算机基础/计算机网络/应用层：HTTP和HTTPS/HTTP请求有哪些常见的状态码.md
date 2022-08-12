---
sidebar_position: 5
---

1. **2xx：** 操作成功，200 OK。
2. **3xx：** 重定向，301 永久重定向，302 暂时重定向。
3. **4xx：** 客户端错误，400 Bad Request，401 Unauthorized，403 Forbidden；404 Not Found。

   > 401 Unauthorized：用来表示缺失或错误的认证，可以修改后重试。
   >
   > 403 Forbidden：用户认证后，权限不足，无法对该资源进行操作。
   >
4. **5xx：** 服务端错误，500 服务器内部错误，501 服务不可用。

## 参考资料

1. [HTTP请求有哪些常见状态码？](https://github.com/wolverinn/Waking-Up/blob/master/Computer%20Network.md#HTTP%E8%AF%B7%E6%B1%82%E6%9C%89%E5%93%AA%E4%BA%9B%E5%B8%B8%E8%A7%81%E7%8A%B6%E6%80%81%E7%A0%81)
2. [HTTP 状态码 401 和 403 的区别](https://blog.csdn.net/qwqasd123456/article/details/100528295)。
