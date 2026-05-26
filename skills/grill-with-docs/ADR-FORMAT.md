# ADR Format

ADRs live in `docs/adr/` and use sequential numbering: `0001-slug.md`, `0002-slug.md`, etc.

Create the `docs/adr/` directory lazily — only when the first ADR is needed.

## Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph.

## Optional sections

Only include these when they add genuine value:

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`)
- **Considered Options** — only when the rejected alternatives are worth remembering
- **Consequences** — only when non-obvious downstream effects need to be called out

## Numbering

Scan `docs/adr/` for the highest existing number and increment by one.

## When to offer an ADR

All three must be true:

1. **Hard to reverse**
2. **Surprising without context**
3. **Result of a real trade-off**

### What qualifies

- **Architectural shape.** "We're using a monorepo."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events."
- **Technology choices that carry lock-in.** Database, message bus, auth provider.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context."
- **Deliberate deviations from the obvious path.** "Manual SQL instead of ORM because X."
- **Constraints not visible in the code.** "Can't use AWS due to compliance."
- **Rejected alternatives when the rejection is non-obvious.**
