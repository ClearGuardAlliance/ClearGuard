<!-- Languages: [English](README.md) | [Português](README.pt.md) | [עברית](README.he.md) | [Русский](README.ru.md) | 中文 | [日本語](README.ja.md) | [العربية](README.ar.md) -->

# ClearGuard

ClearGuard 是一款安卓应用,通过本地 DNS 过滤来阻止色情内容,并以屏幕文字读取作为补充手段。核心区别在于关闭防护绝不会立即生效,任何削弱防护的请求都要经过等待时间,并在生效前通知一位可信的伙伴。

## 工作原理

主要拦截通过本地 VPN 运行,按照被拦截域名列表过滤 DNS 查询。无障碍服务读取屏幕上可见的文字作为额外一层防护,用来捕获绕过 DNS 过滤的内容。任何削弱防护的操作,例如关闭拦截或移除某个域名,都会创建一个待处理请求,包含 PIN 码、等待时间和对伙伴的通知。加强防护则始终是立即生效的。

## 架构

Flutter 代码位于 `lib` 目录,分为 `data`(服务与仓库)、`domain`(模型与业务规则)和 `ui`(界面与视图模型)。安卓原生代码位于 `native_android`,包含 VPN 服务、屏幕监控服务,以及集成到生成的 Flutter 项目中的说明。

## 局限性

DNS 拦截无法阻止通过 IP 地址的直接访问。设备所有者可以在系统设置中撤销 VPN 权限和无障碍服务,任何非 MDM 应用都无法阻止这一点。

## 运行

```bash
flutter pub get
flutter test
```

安卓部分请参考 `native_android/README.md`。如果不想在本地配置环境,可以在 Actions 标签页运行 `Build Android app` workflow 来生成 APK。
