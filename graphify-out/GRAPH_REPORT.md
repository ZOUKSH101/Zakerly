# Graph Report - zakerly  (2026-09-18)

## Corpus Check
- Corpus is ~7,104 words - fits in a single context window. You may not need a graph.

## Summary
- 427 nodes · 540 edges · 19 communities (18 shown, 1 thin omitted)
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS · INFERRED: 29 edges (avg confidence: 0.85)
- Token cost: 77,049 input · 0 output

## Community Hubs (Navigation)
- Generation Cache
- Request Scheduler
- Build Contract
- Domain Models
- Budget and Plans
- Service Wiring
- Course Sync and Mock Canvas
- Mock LLM and Retrieval
- Mock HTML Animations
- BYOK Provider Registry
- Animation Service
- Tutor Service
- Ingestion Pipeline
- Prompt Templates
- Text and Token Utils
- ChangeNotifier Services
- App Entry Stub
- Design System Guidelines
- Services InheritedWidget

## God Nodes (most connected - your core abstractions)
1. `AppServices (Services.of)` - 12 edges
2. `Zakerly (GenAI study workspace)` - 9 edges
3. `BudgetController` - 7 edges
4. `BudgetController` - 7 edges
5. `ProviderRegistry` - 6 edges
6. `RequestScheduler` - 6 edges
7. `AnimationService` - 6 edges
8. `RequestScheduler` - 6 edges
9. `GenerationCache` - 5 edges
10. `LmsProvider` - 5 edges

## Surprising Connections (you probably didn't know these)
- `zakerly package (pubspec)` --implements--> `Zakerly (GenAI study workspace)`  [INFERRED]
  pubspec.yaml → CONTRACT.md
- `Stack: Flutter 3.47 web, Material 3, no state-mgmt packages` --references--> `web ^1.1.0 dependency`  [INFERRED]
  CONTRACT.md → pubspec.yaml
- `showAnimationWindow (builder F)` --references--> `web ^1.1.0 dependency`  [INFERRED]
  CONTRACT.md → pubspec.yaml
- `Verification Gate (flutter analyze + build web)` --references--> `flutter_lints ^6.0.0`  [INFERRED]
  CONTRACT.md → pubspec.yaml
- `MockCanvas` --implements--> `LmsProvider`  [EXTRACTED]
  lib/core/mock/mock_canvas.dart → lib/core/services.dart

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Core ChangeNotifier services exposed via AppServices** — contract_courserepository, contract_studysession, contract_tutorservice, contract_budgetcontroller, contract_requestscheduler, contract_generationcache, contract_providerregistry [EXTRACTED 1.00]
- **Workspace three-panel layout** — contract_workspace_integrator, contract_courserail, contract_studypanel, contract_statuspanel, contract_responsive_breakpoints [EXTRACTED 1.00]
- **Token budget and cost-control flow** — contract_budgetcontroller, contract_requestscheduler, contract_generationcache, contract_freemium_plans, contract_byok [INFERRED 0.85]

## Communities (19 total, 1 thin omitted)

### Community 0 - "Generation Cache"
Cohesion: 0.05
Nodes (44): dart:convert, double get, int get, int inputTokens,, CacheHit, GenerationCache, hitRate, hits (+36 more)

### Community 1 - "Request Scheduler"
Cohesion: 0.04
Nodes (44): dart:async, Future, budget, _completer, createdAt, dispose, done, error (+36 more)

### Community 2 - "Build Contract"
Cohesion: 0.07
Nodes (42): AnimationResult model, AnimationService, AppServices (Services.of), AuthService, BudgetController, BYOK (Bring Your Own Key, Gemini first), Canvas LMS Integration, ChangeNotifier + ListenableBuilder State Pattern (+34 more)

### Community 3 - "Domain Models"
Cohesion: 0.05
Nodes (39): Iterable, AppUser, Author, ChatMessage, Chunk, chunks, Citation, citations (+31 more)

### Community 4 - "Budget and Plans"
Cohesion: 0.05
Nodes (36): bool get, int monthlyTokens, maxCourses,, animationsPerDay, animationsToday, at, canGenerateAnimation, canSpend, countAnimation (+28 more)

### Community 5 - "Service Wiring"
Cohesion: 0.06
Nodes (30): animations.dart, ingestion.dart, animations, AppServices, auth, budget, cache, courseId (+22 more)

### Community 6 - "Course Sync and Mock Canvas"
Cohesion: 0.07
Nodes (29): DateTime, For, byId, courses, error, lastSynced, lms, sync (+21 more)

### Community 7 - "Mock LLM and Retrieval"
Cohesion: 0.09
Nodes (21): dart:math, _animation, generate, _rng, _sentences, _summarize, _tutor, all (+13 more)

### Community 8 - "Mock HTML Animations"
Cohesion: 0.09
Nodes (21): , _base, bstAnimation, c, class, concept, _doc, growthAnimation (+13 more)

### Community 9 - "BYOK Provider Registry"
Cohesion: 0.09
Nodes (21): budget.dart, MockLlm, active, _activeId, available, budget, current, hasKey (+13 more)

### Community 10 - "Animation Service"
Cohesion: 0.10
Nodes (20): Exception, AnimationLimitReached, AnimationResult, AnimationService, budget, cache, extractHtml, fromCache (+12 more)

### Community 11 - "Tutor Service"
Cohesion: 0.12
Nodes (15): ask, chunks, ContextPlan, _historyTail, naiveTokens, plan, promptTokens, providers (+7 more)

### Community 12 - "Ingestion Pipeline"
Cohesion: 0.14
Nodes (13): cache.dart, courses.dart, budget, cache, canIndex, _chunk, courses, indexCourse (+5 more)

### Community 13 - "Prompt Templates"
Cohesion: 0.20
Nodes (9): animation, animationSystem, Prompts, summarize, summarizeSystem, tutor, tutorSystem, models.dart (+1 more)

### Community 14 - "Text and Token Utils"
Cohesion: 0.20
Nodes (9): a, conceptKey, contentTerms, estimateTokens, formatTokens, htmlEscape, stableHash, _stopWords (+1 more)

### Community 15 - "ChangeNotifier Services"
Cohesion: 0.29
Nodes (7): ChangeNotifier, StudySession, BudgetController, CourseRepository, ProviderRegistry, RequestScheduler, TutorService

### Community 16 - "App Entry Stub"
Cohesion: 0.50
Nodes (3): core/app_services.dart, main, package:flutter/material.dart

### Community 17 - "Design System Guidelines"
Cohesion: 0.67
Nodes (3): Apple-teardown Motion Guidelines, notes/APPLE-TECHNIQUES.md, Design System (tokens + primitives)

## Knowledge Gaps
- **289 isolated node(s):** `AnimationResult`, `html`, `tokens`, `fromCache`, `message` (+284 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 331 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **1 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `BudgetController` connect `ChangeNotifier Services` to `Request Scheduler`, `Budget and Plans`, `Service Wiring`, `BYOK Provider Registry`, `Animation Service`, `Ingestion Pipeline`?**
  _High betweenness centrality (0.058) - this node is a cross-community bridge._
- **Why does `RequestScheduler` connect `ChangeNotifier Services` to `Request Scheduler`, `Service Wiring`, `Animation Service`, `Tutor Service`, `Ingestion Pipeline`?**
  _High betweenness centrality (0.024) - this node is a cross-community bridge._
- **Why does `ProviderRegistry` connect `ChangeNotifier Services` to `Service Wiring`, `BYOK Provider Registry`, `Animation Service`, `Tutor Service`, `Ingestion Pipeline`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **What connects `AnimationResult`, `html`, `tokens` to the rest of the system?**
  _289 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Generation Cache` be split into smaller, more focused modules?**
  _Cohesion score 0.04625346901017576 - nodes in this community are weakly interconnected._
- **Should `Request Scheduler` be split into smaller, more focused modules?**
  _Cohesion score 0.044444444444444446 - nodes in this community are weakly interconnected._
- **Should `Build Contract` be split into smaller, more focused modules?**
  _Cohesion score 0.0743321718931475 - nodes in this community are weakly interconnected._