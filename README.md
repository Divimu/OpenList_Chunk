<div align="center">
  <img src="https://raw.githubusercontent.com/OpenListTeam/Logo/main/logo.svg" width="128" height="128" alt="logo" />

  <h1>OpenList_Chunk</h1>

  <p><em>OpenList 的增强分支 — 绕过 CDN 上传大小限制，支持大文件分片上传</em></p>

  <a href="https://github.com/zmabin/OpenList_Chunk/actions?query=workflow%3ABuild"><img src="https://img.shields.io/github/actions/workflow/status/zmabin/OpenList_Chunk/build.yml?branch=main" alt="Build status" /></a>
  <a href="https://github.com/zmabin/OpenList_Chunk/releases"><img src="https://img.shields.io/github/v/release/zmabin/OpenList_Chunk" alt="latest version" /></a>
  <a href="https://github.com/zmabin/OpenList_Chunk/blob/main/LICENSE"><img src="https://img.shields.io/github/license/zmabin/OpenList_Chunk" alt="License" /></a>
</div>

---

[English](./README_en.md) | **中文** | [日本語](./README_ja.md) | [Nederlands](./README_nl.md)

---

## 概述

**OpenList_Chunk** 是 [OpenList](https://github.com/OpenListTeam/OpenList) 的增强分支，在不改动原版数据结构的前提下，重构了上传逻辑。

**核心目的：绕过 Cloudflare CDN 等反向代理服务的上传大小限制（如免费版 Cloudflare 单次请求限制 100MB）。**

**主打一个：替换即用，拒绝折腾。**

---

## 核心修改：绕过 CDN 限制原理

本项目针对 CDN 的上传体限制，实现了两种完全不同的"物理绕过"机制。

### 1. Form 分片模式 (Chunked Upload)

传统的高兼容性分片机制，核心是 **"会话管理 + 磁盘缓存 + 流式合并"**。

- **工作流程**：
  1. **初始化会话**：前端请求 `/api/fs/put/chunk/init`，后端生成唯一 `upload_id` 并创建会话文件。
  2. **分片上传**：每个分片作为 `multipart/form-data` 请求发送到 `/api/fs/put/chunk`，携带 `upload_id` 和 `index`。
  3. **CRC32 校验**：服务端对每个分片计算 CRC32 并与客户端的 `X-Chunk-CRC32` 请求头比对，确保传输完整。
  4. **虚拟合并**：所有分片上传完成后，前端发起合并请求 `/api/fs/put/chunk/merge`。后端使用 `io.MultiReader` 将所有临时文件按顺序**原地读取**，无需磁盘合并，直接流式上传到存储后端。
  5. **自动清理**：合并完成后自动删除临时分片目录。

- **优势**：兼容性强，CRC32 校验保障数据完整性。
- **会话安全**：每个会话绑定上传用户身份，防止未授权访问。

### 2. Stream 分片模式 (Stream Chunking)

专为极致性能和低资源占用设计，核心是 **"零拷贝管道"**。

- **工作流程**：
  1. **前端流式切分**：前端将大文件逻辑分块，使用 `PUT` 方法发送 `Raw Binary` 数据，携带 `Content-Range` 请求头。
  2. **io.Pipe 桥接**：第一个分片到达时，后端创建无缓冲管道 (`io.Pipe`)，立即启动存储驱动上传任务从管道读取数据。
  3. **零拷贝流转**：后续分片写入同一管道，数据直接从"前端请求"经由"服务器内存"流向"云端存储"。
  4. **自动完成**：最后一个分片完成后关闭管道，上传任务结束。

- **优势**：
  - **零磁盘占用**：不需要存储临时分片，无需磁盘合并。
  - **极低内存占用**：通过管道背压机制，内存仅维持 KB 级缓冲。
  - **高性能**：直接流式传输，无 I/O 瓶颈。
- **注意**：服务端作为同步管道，云端速度慢时会通过 TCP 窗口自动限速。

---

## 路由变更

| 路由 | 方法 | 功能 | 认证 |
|------|------|------|------|
| `/api/fs/put/chunk/init` | POST | 初始化分片会话 | `FsUp` 中间件 |
| `/api/fs/put/chunk` | PUT | 上传单个分片 | `FsUp` + 限流 |
| `/api/fs/put/chunk/merge` | POST | 合并分片并上传 | `FsUp` + 限流 |
| `/api/fs/put` | PUT | 流式上传（支持 Content-Range 分片） | `FsUp` + 限流 |

---

## 部署指南

### 直接替换（与 OpenList 数据完全兼容）

1. 停止原 OpenList 服务
2. 备份原 `openlist` 二进制
3. 将编译好的 `openlist` 替换进去
4. 启动服务

```bash
systemctl stop openlist
cp openlist /opt/openlist/openlist
chmod +x /opt/openlist/openlist
systemctl start openlist
```

### 从源码编译

```bash
git clone https://github.com/zmabin/OpenList_Chunk.git
cd OpenList_Chunk

# 下载前端资源
bash build.sh dev web

# 编译（Linux）
export CGO_ENABLED=0
go build -o openlist -tags=jsoniter -ldflags="-s -w" .

# 编译（Windows）
set CGO_ENABLED=0
go build -o openlist.exe -tags=jsoniter -ldflags="-s -w" .
```

### Docker 部署

```bash
docker run -d --name openlist \
  -p 5244:5244 \
  -v "/opt/openlist/data:/opt/openlist/data" \
  --restart always \
  zmabin/openlist-chunk:latest
```

### Nginx 代理配置

参考 `conf.d/openlist.conf`，关键配置：

```nginx
client_max_body_size 102400m;       # 100GB 最大上传
proxy_request_buffering off;         # 禁用请求缓冲（流式上传必需）
proxy_send_timeout 86400s;           # 24小时超时
```

---

## 配置项

| 配置键 | 类型 | 默认值 | 说明 |
|--------|------|--------|------|
| `chunked_upload_mode` | 选择 | `auto` | 分片上传模式：`auto`（自动）/ `disabled`（禁用） |
| `chunked_upload_chunk_size` | 数值 | `95` | 分片阈值（MB），超过此大小的文件自动分片 |

---

## 路线图

- [x] **Form 分片上传**：基于会话的 multipart 分片 + 流式合并
- [x] **Stream 分片上传**：基于 Content-Range 的零拷贝管道分片
- [ ] **多线程下载**：浏览器端多线程并发下载

---

## 致谢

本项目参考并继承了以下优秀项目的成果：

- 感谢 [LusiyAvA/openlist-chunk](https://github.com/LusiyAvA/openlist-chunk) 提供分片上传功能的核心思路与实现参考
- 感谢 [OpenListTeam/OpenList](https://github.com/OpenListTeam/OpenList) 提供稳定可靠的基础框架

---

## 支持

如果这个项目对你有帮助，请给个 ⭐ Star 支持一下！

遇到问题或有建议？欢迎提交 [Issue](https://github.com/zmabin/OpenList_Chunk/issues)。
