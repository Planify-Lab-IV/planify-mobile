# Engineering Guidelines

## General Philosophy

Write code that is:

* Simple
* Modular
* Maintainable
* Testable
* Easy to understand
* Easy to extend

Prefer clear and explicit solutions over clever or unnecessarily complex ones.

The goal is not to minimize the number of lines of code. The goal is to minimize complexity and coupling.

---

# 1. SOLID Principles

Follow SOLID principles whenever they improve the design.

### Single Responsibility Principle

Each class, module, and function should have one clear responsibility.

Avoid classes that:

* Handle business logic
* Perform I/O
* Format output
* Validate input
* Persist data

all at the same time.

If a class starts accumulating unrelated responsibilities, consider extracting them into separate components.

### Open/Closed Principle

Prefer designs that allow behavior to be extended without repeatedly modifying existing code.

Use interfaces, abstractions, composition, and polymorphism when they provide a real benefit.

Do not introduce abstractions just for the sake of following SOLID.

### Liskov Substitution Principle

Subclasses must behave consistently with the contracts defined by their parent types.

Do not use inheritance when composition is a better fit.

### Interface Segregation Principle

Prefer small, focused interfaces over large interfaces containing unrelated operations.

### Dependency Inversion Principle

High-level business logic should not depend directly on low-level implementation details.

Prefer depending on abstractions when this reduces coupling.

---

# 2. Modularity

Keep modules small and focused.

Avoid putting unrelated functionality in the same file.

A file should generally represent one meaningful concept.

Prefer:

```text
UserService
UserRepository
UserValidator
UserMapper
```

over a single large:

```text
UserManager
```

containing everything.

When a file becomes difficult to navigate or contains multiple unrelated responsibilities, consider splitting it.

However, do not create tiny classes or files without a meaningful responsibility just to reduce file size.

---

# 3. Functional / Reactive Programming

When the language and architecture support it, prefer functional and reactive approaches when they make the code clearer.

Prefer:

* Immutability
* Pure functions
* Higher-order functions
* `map`
* `filter`
* `reduce`
* Streams
* Declarative transformations
* Composition
* Reactive streams / asynchronous pipelines when appropriate

over unnecessary mutable state and imperative loops.

For example, prefer a declarative transformation such as:

```java
users.stream()
    .filter(User::isActive)
    .map(User::getName)
    .toList();
```

when it is clearer than manually creating and mutating a collection.

Do NOT force functional or reactive programming when it makes the code harder to understand.

Readability takes priority over stylistic purity.

---

# 4. Immutability

Prefer immutable data whenever practical.

Avoid unnecessary mutation of:

* Collections
* Objects
* Method parameters
* Shared state

Prefer creating transformed values over modifying existing values in place when doing so keeps the design simpler.

---

# 5. Composition Over Inheritance

Prefer composition over inheritance unless there is a genuine "is-a" relationship.

Do not create inheritance hierarchies merely to reuse code.

Prefer:

```text
Class A
    -> uses Class B
```

over:

```text
Class A extends B
```

when composition provides lower coupling and clearer responsibilities.

---

# 6. Functions and Methods

Methods should do one meaningful thing.

Prefer:

```java
validateUser();
saveUser();
sendNotification();
```

over a single method that performs all three responsibilities.

Keep methods reasonably small.

Avoid deeply nested conditionals.

Prefer guard clauses and early returns when they improve readability.

---

# 7. Dependencies and Coupling

Minimize coupling between components.

A component should know as little as possible about the internal implementation of another component.

Avoid:

* Global state
* Static mutable state
* Unnecessary singletons
* Direct dependencies on infrastructure
* Passing large objects when only a small piece of information is required

Prefer dependency injection and abstractions when appropriate.

---

# 8. Separation of Concerns

Keep different concerns separated.

For example:

```text
Presentation
    ↓
Application / Services
    ↓
Domain
    ↓
Infrastructure
```

Do not mix:

* UI logic with business logic
* Database queries with domain logic
* HTTP handling with business rules
* Serialization with domain models

unless the project architecture explicitly requires it.

---

# 9. Error Handling

Handle errors explicitly.

Do not silently ignore exceptions.

Avoid:

```java
catch (Exception e) {}
```

unless there is a very specific and documented reason.

Use meaningful exception types.

Do not use exceptions as normal control flow when a simpler mechanism exists.

---

# 10. Testing

Code should be designed to be testable.

When adding meaningful business logic:

* Consider whether it needs tests.
* Prefer unit-testable components.
* Avoid unnecessary dependencies on external systems.
* Keep business logic independent from I/O when possible.

When modifying existing behavior, inspect the existing tests before changing the implementation.

Do not modify tests merely to make them pass unless the expected behavior has intentionally changed.

---

# 11. Avoid Overengineering

Do not introduce:

* Unnecessary design patterns
* Abstractions with only one trivial implementation
* Excessive interfaces
* Deep inheritance hierarchies
* Unnecessary layers
* Complex frameworks for simple problems

Use the simplest architecture that satisfies the requirements.

SOLID and Clean Code are guidelines, not excuses for unnecessary complexity.

---

# 12. Before Writing Code

Before implementing a non-trivial change:

1. Understand the existing architecture.
2. Identify the responsibilities involved.
3. Check whether existing abstractions can be reused.
4. Check existing tests.
5. Consider whether the change introduces unnecessary coupling.
6. Decide whether the functionality belongs in a new component or an existing one.

Do not immediately start modifying files without understanding how the relevant parts of the project currently work.

---

# 13. When Refactoring

When you encounter code that violates these principles, consider whether it should be refactored.

Prioritize refactoring when it:

* Reduces significant complexity
* Removes duplicated logic
* Reduces coupling
* Improves testability
* Clarifies responsibilities
* Makes future changes easier

Do not perform large unrelated refactors while implementing a small feature.

Keep changes focused.

---

# 14. Decision Priority

When principles conflict, use this priority:

1. Correctness
2. Simplicity
3. Readability
4. Maintainability
5. Testability
6. Modularity
7. Performance
8. Architectural elegance

Do not sacrifice correctness or readability merely to satisfy a design principle.

---

# 15. Coding Style

Prefer code that a developer unfamiliar with the project can understand quickly.

Avoid clever tricks.

Use descriptive names.

Prefer explicit code when implicit behavior would be difficult to understand.

Comments should explain **why**, not simply repeat **what** the code does.

Bad:

```java
// Increment i
i++;
```

Good:

```java
// Retry because the external service occasionally returns a transient failure.
retryCount++;
```

---

# 16. Final Review

Before considering a task complete, check:

* Does each component have a clear responsibility?
* Is there unnecessary coupling?
* Is functionality unnecessarily concentrated in one file?
* Could composition be better than inheritance?
* Could immutable or functional approaches simplify the implementation?
* Is the code testable?
* Are there duplicated responsibilities?
* Is there unnecessary abstraction?
* Are existing project conventions being followed?
* Did the change introduce unnecessary complexity?

If the answer to any of these raises a significant concern, improve the implementation before finishing.
