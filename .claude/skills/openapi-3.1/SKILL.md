---
name: openapi-3.1
description: Conventions for authoring OpenAPI 3.1 contracts that the BA emits and the FE/BE follow. Use when writing or modifying api/openapi.yaml.
---

# OpenAPI 3.1 Authoring Conventions

## File structure

```
api/
  openapi.yaml         # main spec
  schemas/             # reusable component schemas (one per domain)
    User.yaml
    Error.yaml
  paths/               # reusable path objects (optional, for very large APIs)
```

## Spec header

```yaml
openapi: 3.1.0
info:
  title: Acme API
  version: 1.0.0
  description: |
    Errors follow RFC 7807 Problem Details.
    Authentication: Bearer JWT.
servers:
  - url: https://api.acme.example/v1
    description: Production
  - url: http://localhost:4000/v1
    description: Local
security:
  - bearerAuth: []
```

## Error envelope (RFC 7807)

```yaml
components:
  schemas:
    Problem:
      type: object
      required: [type, title, status]
      properties:
        type:
          type: string
          format: uri
          example: "https://acme.example/probs/validation"
        title:
          type: string
          example: "Validation failed"
        status:
          type: integer
          example: 422
        detail:
          type: string
        instance:
          type: string
          format: uri
        errors:
          type: array
          items:
            type: object
            properties:
              field: { type: string }
              code:  { type: string }
              message: { type: string }
```

## Every endpoint must have

- `summary` (≤80 chars) + `description`
- `operationId` in `camelCase` (used for codegen)
- `tags` (one per feature module)
- Security (or explicit `security: []` for public endpoints)
- Request body schema with `example`
- All response codes: 200/201, 400, 401, 403, 404, 409, 422, 429, 500
- `examples:` for every response

## Path example

```yaml
paths:
  /users:
    post:
      summary: Create a user
      operationId: createUser
      tags: [users]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserRequest'
            example:
              email: alice@example.com
              password: hunter2-very-secure
      responses:
        '201':
          description: Created
          content:
            application/json:
              schema: { $ref: '#/components/schemas/UserResponse' }
        '400':
          $ref: '#/components/responses/BadRequest'
        '409':
          $ref: '#/components/responses/Conflict'
        '422':
          $ref: '#/components/responses/Unprocessable'
        '429':
          $ref: '#/components/responses/RateLimited'
```

## Security schemes

```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

## Discriminator pattern (polymorphic responses)

```yaml
PaymentMethod:
  oneOf:
    - $ref: '#/components/schemas/CardMethod'
    - $ref: '#/components/schemas/BankMethod'
  discriminator:
    propertyName: type
    mapping:
      card: '#/components/schemas/CardMethod'
      bank: '#/components/schemas/BankMethod'
```

## Linting

```bash
npx @redocly/cli lint api/openapi.yaml
# or
npx @stoplight/spectral-cli lint api/openapi.yaml
```

CI should reject any spec that fails lint OR drifts from runtime (`@nestjs/swagger` output).

## Anti-patterns

- ❌ `"type": "string"` without `maxLength` (DoS surface)
- ❌ Free-form enums via string — use `enum:` array or `oneOf` with discriminator
- ❌ Omitting `example:` — frontend agent cannot generate fixtures
- ❌ `TODO`/`TBD` in production paths
- ❌ Inconsistent response shape (`{data}` here, naked array there)
