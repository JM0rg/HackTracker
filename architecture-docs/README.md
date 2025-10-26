# 📚 Architecture Documentation

This folder contains the complete architectural documentation for HackTracker.

---

## 📖 Documentation Structure

### 🏠 Start Here

**[ARCHITECTURE.md](./ARCHITECTURE.md)** - Main architecture guide
- System overview and design philosophy
- High-level architecture and tech stack
- Domain model and core entities
- Development phases and roadmap
- References to detailed sub-documents

---

## 📑 Detailed Guides

### Core Architecture

**[dynamodb-design.md](./dynamodb-design.md)** - Database Design
- Single-table design principles
- Primary keys and GSI strategies
- Query patterns and examples
- Entity schemas and relationships
- Performance considerations

**[authorization.md](./authorization.md)** - Authorization System
- v2 Policy Engine implementation
- Role-based access control (RBAC)
- Team-scoped permissions
- Usage examples and patterns
- Migration from v0 → v1 → v2

**[caching.md](./caching.md)** - Frontend Caching
- Persistent caching strategy
- Stale-while-revalidate (SWR) pattern
- Optimistic UI implementation
- Race-condition-safe rollback
- Cache versioning and invalidation

---

## 🔗 Related Documentation

**[../DATA_MODEL.md](../DATA_MODEL.md)** - Current Implementation
- Implemented entities and schemas
- Lambda functions and API routes
- Access patterns and examples
- Test commands and workflows

**[../TESTING.md](../TESTING.md)** - Testing Guide
- Local testing with DynamoDB Local
- Cloud testing with deployed API
- Test commands and workflows
- Debugging tips

**[../OPTIMISTIC_UI_GUIDE.md](../OPTIMISTIC_UI_GUIDE.md)** - Optimistic UI
- Detailed implementation patterns
- Race-condition prevention
- Error handling and rollback
- Best practices and examples

---

## 🎯 Quick Navigation

**Need to understand...**

- **How data is stored?** → [dynamodb-design.md](./dynamodb-design.md)
- **How permissions work?** → [authorization.md](./authorization.md)
- **How caching works?** → [caching.md](./caching.md)
- **What's implemented?** → [../DATA_MODEL.md](../DATA_MODEL.md)
- **How to test?** → [../TESTING.md](../TESTING.md)
- **System overview?** → [ARCHITECTURE.md](./ARCHITECTURE.md)

---

## 📝 Documentation Philosophy

### Why Split Documents?

**Before:** One massive ARCHITECTURE.md (1200+ lines)
- Hard to navigate
- Difficult to find specific information
- Overwhelming for new developers

**After:** Modular documentation
- ✅ Easy to navigate
- ✅ Focused, digestible content
- ✅ Clear separation of concerns
- ✅ Quick reference for specific topics

### Document Types

**ARCHITECTURE.md** - High-level overview
- System design philosophy
- Core concepts and principles
- Roadmap and phases
- Links to detailed guides

**Topic Guides** - Deep dives
- Detailed implementation
- Code examples
- Best practices
- Troubleshooting

**Implementation Docs** - Current state
- What exists right now
- API endpoints and schemas
- Test commands
- Quick reference

---

## 🔄 Keeping Docs Updated

### When to Update

**ARCHITECTURE.md:**
- Major system design changes
- New architectural patterns
- Phase completions
- Tech stack changes

**dynamodb-design.md:**
- New entities or GSIs
- Query pattern changes
- Schema updates

**authorization.md:**
- New roles or permissions
- Policy changes
- Authorization patterns

**caching.md:**
- Caching strategy changes
- New optimistic UI patterns
- Cache versioning updates

**DATA_MODEL.md:**
- New Lambda functions
- New API routes
- Entity schema changes
- Implementation status updates

### Update Checklist

When making architectural changes:

1. ✅ Update relevant topic guide (e.g., `dynamodb-design.md`)
2. ✅ Update `DATA_MODEL.md` if implementation changed
3. ✅ Update `ARCHITECTURE.md` if high-level design changed
4. ✅ Add code examples to topic guides
5. ✅ Update cross-references between docs

---

## 💡 Contributing

### Adding New Documentation

**New Topic Guide:**
1. Create `architecture-docs/topic-name.md`
2. Add link to `ARCHITECTURE.md` documentation index
3. Add link to this `README.md`
4. Cross-reference from related docs

**New Section in Existing Doc:**
1. Add section to appropriate topic guide
2. Update table of contents
3. Add cross-references if needed

### Documentation Standards

**Structure:**
- Clear headings (## for main sections)
- Code examples with syntax highlighting
- Tables for comparisons
- Benefits/drawbacks lists
- Cross-references to related docs

**Style:**
- Use emojis for visual navigation (🎯 🔧 ✅ ❌)
- Keep paragraphs short
- Use bullet points for lists
- Include "See Also" sections
- Add "Why" explanations, not just "What"

---

## 🎓 Learning Path

**New to HackTracker?**

1. Start with [ARCHITECTURE.md](./ARCHITECTURE.md) - Get the big picture
2. Read [DATA_MODEL.md](../DATA_MODEL.md) - See what's implemented
3. Explore topic guides based on your work:
   - Backend dev? → [dynamodb-design.md](./dynamodb-design.md), [authorization.md](./authorization.md)
   - Frontend dev? → [caching.md](./caching.md), [OPTIMISTIC_UI_GUIDE.md](../OPTIMISTIC_UI_GUIDE.md)
   - Testing? → [TESTING.md](../TESTING.md)

**Working on a specific feature?**

1. Check [DATA_MODEL.md](../DATA_MODEL.md) for current implementation
2. Read relevant topic guide for patterns
3. Follow development guidelines in [ARCHITECTURE.md](./ARCHITECTURE.md)
4. Update docs when done!

---

## 📞 Questions?

If documentation is unclear or missing:
1. Check cross-references in related docs
2. Search for keywords across all docs
3. Create an issue or ask the team
4. Update docs once you figure it out!

**Remember:** Good documentation helps everyone! 📚✨

