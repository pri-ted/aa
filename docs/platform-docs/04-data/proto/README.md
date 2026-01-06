# Protocol Buffer Definitions

> gRPC service contracts for inter-service communication.

---

## Overview

All platform services communicate internally via gRPC using Protocol Buffers. This directory contains the canonical `.proto` definitions that serve as the source of truth for service contracts.

---

## Directory Structure

```text
proto/
├── README.md                 # This file
├── buf.yaml                  # Buf configuration
├── buf.gen.yaml              # Code generation config
├── common/
│   ├── pagination.proto      # Shared pagination types
│   ├── errors.proto          # Standard error types
│   ├── health.proto          # Health check service
│   └── types.proto           # Common field types
├── auth/
│   └── v1/
│       └── auth.proto        # Auth service contract
├── config/
│   └── v1/
│       └── config.proto      # Config service contract
├── connector/
│   └── v1/
│       └── connector.proto   # Connector service contract
├── etl/
│   └── v1/
│       └── etl.proto         # ETL orchestrator contract
├── data/
│   └── v1/
│       ├── bronze.proto      # Bronze service contract
│       ├── silver.proto      # Silver service contract
│       └── gold.proto        # Gold service contract
├── intelligence/
│   └── v1/
│       ├── calculation.proto # Calculation engine contract
│       ├── rules.proto       # Rule engine contract
│       └── analytics.proto   # Analytics service contract
├── notification/
│   └── v1/
│       └── notification.proto # Notification service contract
└── query/
    └── v1/
        └── query.proto       # Query service contract
```

---

## Code Generation

### Prerequisites

```bash
# Install buf
brew install bufbuild/buf/buf

# Or via npm
npm install -g @bufbuild/buf
```

### Generate Code

```bash
# Generate for all languages
buf generate

# Generate for specific language
buf generate --template buf.gen.go.yaml
buf generate --template buf.gen.rust.yaml
buf generate --template buf.gen.ts.yaml
```

### Generated Output

| Language | Output Directory | Package |
| ---------- | ------------------ | --------- |
| Go | `gen/go/` | `github.com/org/platform/gen/go` |
| Rust | `gen/rust/` | `platform_proto` |
| TypeScript | `gen/ts/` | `@platform/proto` |

---

## Versioning

All services use URL-based versioning in the package path:

```protobuf
package platform.auth.v1;
```

### Version Policy

| Version | Status | Support |
| --------- | -------- | --------- |
| v1 | Current | Full support |
| v2 | Planning | Not started |

### Breaking Changes

Breaking changes require a new version. Non-breaking additions (new fields, new RPCs) can be added to existing versions.

---

## Common Patterns

### Request/Response Naming

```protobuf
// Pattern: {Action}{Resource}Request/Response
message GetUserRequest { ... }
message GetUserResponse { ... }

message ListPipelinesRequest { ... }
message ListPipelinesResponse { ... }

message CreateRuleRequest { ... }
message CreateRuleResponse { ... }
```

### Pagination

All list operations use standard pagination:

```protobuf
import "common/pagination.proto";

message ListCampaignsRequest {
  int64 org_id = 1;
  platform.common.PaginationRequest pagination = 2;
}

message ListCampaignsResponse {
  repeated Campaign campaigns = 1;
  platform.common.PaginationResponse pagination = 2;
}
```

### Error Handling

Errors use gRPC status codes with additional detail:

```protobuf
import "common/errors.proto";

message SomeResponse {
  oneof result {
    SuccessPayload success = 1;
    platform.common.Error error = 2;
  }
}
```

---

## Service Dependencies

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SERVICE gRPC DEPENDENCIES                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────┐                                                               │
│   │  Auth   │◄─────────────── All services call for token validation        │
│   └─────────┘                                                               │
│        │                                                                    │
│        ▼                                                                    │
│   ┌─────────┐      ┌─────────┐      ┌─────────┐                             │
│   │ Config   │◄─────│   ETL   │─────►│Connector│                             │
│   └─────────┘      └─────────┘      └─────────┘                             │
│        │                │                                                   │
│        ▼                ▼                                                   │
│   ┌─────────┐      ┌─────────┐      ┌─────────┐      ┌─────────┐            │
│   │  Rules  │◄─────│  Gold   │◄─────│ Silver  │◄─────│ Bronze  │            │
│   └─────────┘      └─────────┘      └─────────┘      └─────────┘            │
│        │                │                                                   │
│        ▼                ▼                                                   │
│   ┌─────────┐      ┌─────────┐                                              │
│   │  Notif  │      │  Calc   │                                              │
│   └─────────┘      └─────────┘                                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Development Workflow

### 1. Define Proto

```protobuf
// auth/v1/auth.proto
syntax = "proto3";
package platform.auth.v1;

service AuthService {
  rpc ValidateToken(ValidateTokenRequest) returns (ValidateTokenResponse);
}
```

### 2. Generate Code

```bash
buf generate
```

### 3. Implement Service

```go
// Go implementation
type authServer struct {
    pb.UnimplementedAuthServiceServer
}

func (s *authServer) ValidateToken(ctx context.Context, req *pb.ValidateTokenRequest) (*pb.ValidateTokenResponse, error) {
    // Implementation
}
```

### 4. Register with gRPC Server

```go
grpcServer := grpc.NewServer()
pb.RegisterAuthServiceServer(grpcServer, &authServer{})
```

---

## Linting & Validation

```bash
# Lint protos
buf lint

# Check for breaking changes
buf breaking --against '.git#branch=main'

# Format protos
buf format -w
```

---

## Navigation

- **Up:** [Data Architecture](../README.md)
- **Next:** [Common Types](common/types.proto)
