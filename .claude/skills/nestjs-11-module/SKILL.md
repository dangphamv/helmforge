---
name: nestjs-11-module
description: How to create a NestJS 11 feature module with controller, service, DTOs, guards, and tests. Use whenever adding/extending an API endpoint in apps/api/.
---

# NestJS 11 Feature Module Pattern

## File layout

```
src/<feature>/
├── <feature>.module.ts
├── <feature>.controller.ts
├── <feature>.controller.spec.ts
├── <feature>.service.ts
├── <feature>.service.spec.ts
├── dto/
│   ├── create-<feature>.dto.ts
│   └── update-<feature>.dto.ts
└── entities/  # if TypeORM; skip for Prisma
```

## Implementation order

1. **Prisma schema** (additive only) → `pnpm prisma migrate dev --name add_<feature>`
2. **DTOs** with `class-validator`
3. **Service** with constructor-injected `PrismaService`
4. **Controller** — thin: validate → delegate → format response
5. **Module** — register, `imports`/`providers`/`exports`
6. **App module** — import the new module
7. **Swagger decorators** — `@ApiTags`, `@ApiOperation`, `@ApiResponse`

## DTO example

```ts
import { IsEmail, IsString, MinLength, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateUserDto {
  @ApiProperty({ example: 'alice@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ minLength: 8, maxLength: 100 })
  @IsString()
  @MinLength(8)
  @MaxLength(100)
  password!: string;
}
```

## Controller pattern

```ts
@Controller('users')
@ApiTags('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UserController {
  constructor(private readonly userService: UserService) {}

  @Post()
  @Roles('ADMIN')
  @ApiOperation({ summary: 'Create user' })
  @ApiResponse({ status: 201, type: UserResponseDto })
  async create(@Body() dto: CreateUserDto): Promise<{ ok: true; data: UserResponseDto }> {
    const data = await this.userService.create(dto);
    return { ok: true, data };
  }
}
```

## Service pattern

```ts
@Injectable()
export class UserService {
  constructor(private readonly prisma: PrismaService) {}

  async create(dto: CreateUserDto): Promise<UserResponseDto> {
    const passwordHash = await argon2.hash(dto.password);
    return this.prisma.user.create({
      data: { email: dto.email, passwordHash },
      select: { id: true, email: true, createdAt: true },
    });
  }
}
```

## Global config (main.ts)

```ts
app.useGlobalPipes(
  new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }),
);
app.useGlobalInterceptors(new ClassSerializerInterceptor(app.get(Reflector)));
app.useGlobalFilters(new HttpProblemFilter()); // RFC 7807
```

## Testing

**Unit** (service, mocked Prisma):
```ts
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
let prisma: DeepMockProxy<PrismaClient>;
// configure module to provide `prisma`
```

**Integration** (Supertest):
```ts
const moduleRef = await Test.createTestingModule({ imports: [AppModule] }).compile();
const app = moduleRef.createNestApplication();
await app.init();
await request(app.getHttpServer()).post('/users').send({...}).expect(201);
```

## Anti-patterns

- ❌ Skipping `ValidationPipe` for "test convenience"
- ❌ Returning raw Prisma objects (use response DTO + `ClassSerializerInterceptor`)
- ❌ `findMany` without a `take`
- ❌ `console.log` (use NestJS `Logger`)
- ❌ Catch-and-swallow exceptions in controllers
