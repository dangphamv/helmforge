---
name: ai-engineering
description: How to build AI features INSIDE the product — chatbots, in-app assistants, multi-agent workflows, RAG, structured extraction. Covers the 2026 runtime stack (Vercel AI SDK 6, Mastra, Supabase pgvector), streaming UX, tool calling, agent loops, evals, guardrails, and cost control. Use whenever a feature calls an LLM at runtime for end-users. NOTE: this is about the SHIPPED app's AI, not the SDLC build-time agents.
---

# AI Engineering — building AI features users actually use

**Critical framing:** the SDLC agents in this kit (product-owner, frontend-engineer, …) are *build-time* tools that write your code. This skill is about the **runtime** AI features in the shipped product — the chatbot your users talk to, the multi-agent workflow that processes their tasks. Different layer entirely.

## Choose the runtime framework (2026)

| Need | Use | Why |
|---|---|---|
| In-app chatbot, streaming assistant, single agent loop, generative UI | **Vercel AI SDK 6** (`ai`, `@ai-sdk/react`) | Default for the user-facing layer; ~25KB client, `useChat` message-parts, `streamText`, tool calling, `Agent`/`ToolLoopAgent`, MCP support, provider-agnostic |
| Multi-agent workflows, persistent memory, RAG pipeline, built-in evals — all in TypeScript | **Mastra** (built on AI SDK) | Six primitives: agents, workflows, tools, memory, RAG, evals; pgvector support; `.suspend()/.resume()` for human-in-the-loop; Next.js-native; same Zod types end-to-end |
| Complex stateful agent graphs (conditional routing, cycles, subgraphs) | **LangGraph** | Most flexible graph orchestration (Python primary; TS client) — reach for it only when AI SDK/Mastra loops aren't enough |
| Multi-platform bots (Slack/Teams/Discord) | **Vercel Chat SDK** + AI SDK | `createChatTools`, webhook routing, approval-gated write tools |

**Default recommendation for this kit's stack (Next.js + Supabase):**
- Simple chatbot / in-app AI → **AI SDK 6** in a route handler + `useChat` on the client.
- Multi-agent / RAG / memory / evals → **Mastra** (it delegates LLM calls to AI SDK, stores vectors in Supabase pgvector, keeps everything TypeScript + Zod).
- Don't add LangGraph/Python unless a graph genuinely can't be expressed as an AI SDK agent loop or a Mastra workflow.

## The provider layer

- Use the **Vercel AI Gateway** (or provider SDKs directly) for model access; the Gateway gives one key + dynamic model switching + spend caps.
- Provider-agnostic via AI SDK: `anthropic('claude-...')`, `openai('gpt-...')`, `google('gemini-...')`. Pick per-task (cheap model for routing/classification, strong model for final answer).
- API keys are human-action — emit `docs/human-actions/<id>-llm-provider.md` (Anthropic/OpenAI/Gateway key, where to store, spend limit). NEVER ship a provider key to the client; all LLM calls go through a server route.

## Chatbot — the canonical shape (AI SDK 6)

**Server (route handler):**
```ts
// app/api/chat/route.ts
import { streamText, convertToModelMessages } from 'ai';
import { anthropic } from '@ai-sdk/anthropic';

export const maxDuration = 30; // Fluid Compute; raise for agent loops

export async function POST(req: Request) {
  const { messages } = await req.json();
  const result = streamText({
    model: anthropic('claude-sonnet-4-6'),
    system: 'You are a support assistant for <product>. Be concise. Cite sources.',
    messages: convertToModelMessages(messages),
    tools: { /* see tool calling below */ },
    stopWhen: stepCountIs(8),            // agent loop bound (cost guardrail)
    onFinish({ usage }) { /* log tokens for cost tracking */ },
  });
  return result.toUIMessageStreamResponse();
}
```

**Client:**
```tsx
'use client';
import { useChat } from '@ai-sdk/react';
export function Chat() {
  const { messages, sendMessage, status } = useChat();
  // messages use the v6 message-parts model: render parts (text, tool calls, files)
  // disable input while status==='streaming'; show stop button
}
```

## Tool calling (let the model act)

```ts
import { tool } from 'ai';
import { z } from 'zod';

const tools = {
  searchOrders: tool({
    description: 'Find a user\'s orders by status',
    inputSchema: z.object({ status: z.enum(['open','shipped','cancelled']) }),
    execute: async ({ status }, { abortSignal }) => {
      // SERVER-side: query Supabase WITH the user's session (RLS enforces scope)
      return await getOrdersForCurrentUser(status);
    },
  }),
};
```
- Tools run server-side; respect auth (RLS). Gate write tools behind explicit approval (`requireApproval`) so the model can't mutate without a human/UX confirm.
- Tool inputs validated by Zod — reuse schemas from `@<project>/contracts`.

## Multi-agent orchestration

Two patterns, pick by complexity:

1. **AI SDK agent loop** (simple): one `Agent` with a toolset and `stopWhen`. A "router" tool can delegate to sub-functions. Good for "assistant that can do N things."
2. **Mastra workflow** (structured): named agents (`researcher`, `writer`, `reviewer`) chained in a workflow with conditional branching, parallel steps, retries, and human-in-the-loop `.suspend()/.resume()`. Each step logs input/output/duration/tokens. Good for "pipeline of specialists" — which is exactly multi-task processing.

```ts
// Mastra sketch — a 3-agent content pipeline
const research = new Agent({ name: 'research', model, tools: { webSearch } });
const write    = new Agent({ name: 'write', model });
const review   = new Agent({ name: 'review', model, instructions: 'grade against the brief' });
// workflow: research → write → review → (branch: revise | done)
```
- Keep agents **single-responsibility** with explicit instructions and a narrow toolset — same discipline as this kit's SDLC agents.
- Bound every loop (`stopWhen`/step limits) — runaway loops are the #1 cost incident.

## RAG with Supabase pgvector

```sql
-- migration: enable vector + a table
create extension if not exists vector;
create table documents (
  id uuid primary key default gen_random_uuid(),
  content text,
  embedding vector(1536),
  owner_id uuid references auth.users
);
create index on documents using hnsw (embedding vector_cosine_ops);
-- RLS: users only retrieve their own docs
```
```ts
// embed + retrieve
import { embed } from 'ai';
import { openai } from '@ai-sdk/openai';
const { embedding } = await embed({ model: openai.embedding('text-embedding-3-small'), value: query });
// match via Supabase rpc('match_documents', { query_embedding, match_count }) — RLS-scoped
```
- RLS still applies to retrieval — users must not retrieve each other's documents.
- Chunk sensibly (by heading/paragraph, ~500–1000 tokens, small overlap). Rerank if recall is noisy (AI SDK 6 has reranking).
- Mastra's `rag` module does chunking + embedding + pgvector + retrieval for you.

## Structured output (extraction, classification)

```ts
import { generateObject } from 'ai';
const { object } = await generateObject({
  model: anthropic('claude-sonnet-4-6'),
  schema: InvoiceSchema,          // Zod, from @<project>/contracts
  prompt: `Extract invoice fields from:\n${text}`,
});
```
Prefer `generateObject` + Zod over parsing free text. The schema IS the contract.

## Guardrails (non-negotiable for shipped AI)

- **Cost/token budget:** bound agent loops (`stopWhen`), cap `maxOutputTokens`, choose cheap models for routing; log `usage` on every call; alert on per-user/day token spend.
- **Prompt injection:** treat retrieved/user content as untrusted; never let it override system instructions; don't expose tools that can exfiltrate secrets; sanitize tool outputs.
- **PII / safety:** filter inputs/outputs (AI SDK Language Model Middleware); don't log raw prompts containing PII; honor data-retention.
- **Rate limit** the chat/agent endpoints per user (separate bucket from normal API).
- **Authz in tools:** every tool that touches data runs with the user's session + RLS — the model must never see another user's data.
- **Fallbacks:** model/provider down → graceful message, not a crash; stream timeouts handled.

## Evals (how you know it works)

- Treat prompts/agents like code: a versioned **eval set** of inputs → expected properties, run in CI.
- Mastra has built-in evals; otherwise promptfoo or a small harness asserting: correctness on a golden set, no banned outputs, tool-call accuracy, latency/cost ceilings.
- Add an eval before tuning a prompt; regression-test on every prompt change. "It looked good in the demo" is not a test.

## Observability

- Log per turn: model, tokens (in/out), tool calls, latency, cost. AI SDK `onFinish` + OpenTelemetry; or Langfuse/Helicone for traces + dashboards.
- You cannot debug or cost-control what you don't measure.

## Anti-patterns

- ❌ Calling the provider API from the browser (key leak) — always a server route
- ❌ Unbounded agent loops (no `stopWhen`) — runaway cost
- ❌ Parsing free-text instead of `generateObject` + Zod
- ❌ RAG retrieval without RLS — cross-user data leak
- ❌ Letting retrieved content override the system prompt (injection)
- ❌ Shipping without an eval set — every prompt tweak is a silent regression risk
- ❌ One giant 2,000-line system prompt doing everything — decompose into agents/tools
- ❌ No token/cost logging — you'll find out via the invoice
- ❌ Adding LangGraph/Python to a TS app when a Mastra workflow would do
