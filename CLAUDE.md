# CLAUDE.md — AI Assistant Guide for ai-wisdom-battle

This file provides context and conventions for AI assistants (Claude and others) working on this repository.

## Project Overview

**ai-wisdom-battle** is a Java-based project intended to facilitate AI wisdom competitions or battle scenarios. The project is in its earliest stage — no source code exists yet. This document establishes conventions to follow as the codebase grows.

## Current Repository State

```
ai-wisdom-battle/
├── .gitignore        # Java-standard ignore patterns
├── README.md         # Minimal project description
└── CLAUDE.md         # This file
```

No build files, source code, tests, or CI/CD configuration exist yet.

## Technology Stack

- **Language**: Java (inferred from `.gitignore` patterns)
- **Build Tool**: TBD — Maven (`pom.xml`) or Gradle (`build.gradle`) expected
- **Testing**: TBD — JUnit 5 recommended for new Java projects

### Expected Future Structure (Maven Standard Layout)

```
ai-wisdom-battle/
├── src/
│   ├── main/
│   │   └── java/          # Application source code
│   └── test/
│       └── java/          # Test source code
├── pom.xml                # Maven build descriptor (or build.gradle for Gradle)
├── .gitignore
├── README.md
└── CLAUDE.md
```

## Git Workflow

### Branching Strategy

- **`master`** — stable, production-ready code; never push directly
- **Feature branches** — all development happens on feature branches

### AI Assistant Branch Naming

AI-generated branches follow this convention:
```
claude/<description>-<sessionId>
```
Example: `claude/add-claude-documentation-OLqcO`

### Workflow for AI Assistants

1. Always develop on the designated feature branch (never `master`)
2. Commit changes with clear, descriptive messages
3. Push using: `git push -u origin <branch-name>`
4. If push fails due to network errors, retry up to 4 times with exponential backoff (2s, 4s, 8s, 16s)

### Commit Message Convention

Use imperative mood, present tense:
```
Add CLAUDE.md with project conventions
Fix null pointer in BattleEngine
Add unit tests for WisdomScorer
```

## Build & Run

> **Note**: No build system is configured yet. Add these instructions once `pom.xml` or `build.gradle` is created.

### Maven (expected)
```bash
# Build
mvn clean package

# Run tests
mvn test

# Run the application
mvn exec:java -Dexec.mainClass="com.aiwisdombattle.Main"
```

### Gradle (alternative)
```bash
# Build
./gradlew build

# Run tests
./gradlew test

# Run the application
./gradlew run
```

## Testing

> **Note**: No tests exist yet. Follow these conventions when adding tests.

- Use **JUnit 5** (`@Test`, `@BeforeEach`, etc.)
- Place tests under `src/test/java/` mirroring the main source package structure
- Name test classes with the suffix `Test` (e.g., `BattleEngineTest`)
- Aim for unit tests on all business logic; integration tests for external dependencies

## Code Conventions

- Follow standard **Java naming conventions**:
  - Classes: `PascalCase`
  - Methods and variables: `camelCase`
  - Constants: `UPPER_SNAKE_CASE`
  - Packages: `lowercase.dotted` (e.g., `com.aiwisdombattle`)
- Keep classes focused on a single responsibility
- Prefer immutability where practical
- Document public APIs with Javadoc

## Environment Variables

No environment variables are required at this time. Add a `.env.example` file when environment-specific configuration is introduced.

## Key Instructions for AI Assistants

1. **Always work on the designated branch** — never commit directly to `master`
2. **Read before editing** — understand existing code before proposing changes
3. **Minimal changes** — only change what is necessary; avoid refactoring unrelated code
4. **No security vulnerabilities** — avoid SQL injection, command injection, XSS, and other OWASP Top 10 issues
5. **Commit and push** — always commit your work and push to the remote branch when done
6. **Verify** — after making changes, confirm the build still passes (once a build system exists)
