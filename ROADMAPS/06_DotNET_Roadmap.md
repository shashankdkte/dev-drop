# 🟦 .NET Roadmap (300 Topics)

## Progress Overview
- **Total Topics**: 300
- **Completed**: 0/300 (0%)
- **In Progress**: Master .NET from C# basics to enterprise architecture across 15 stages

---

## Stage 1: Foundations
**Progress: 0/20 (0%)**

- [ ] What is .NET Framework vs .NET Core vs .NET 5+
- [ ] CLR (Common Language Runtime)
- [ ] C# syntax basics
- [ ] Value types vs reference types
- [ ] Nullable types
- [ ] Boxing & unboxing
- [ ] Memory management in .NET
- [ ] Garbage collection basics
- [ ] Namespaces & assemblies
- [ ] .NET project structure
- [ ] Solution (.sln) vs project (.csproj)
- [ ] NuGet package manager
- [ ] Compilation: IL code
- [ ] JIT compiler
- [ ] Cross-platform with .NET Core
- [ ] MSBuild basics
- [ ] .NET CLI (dotnet new, dotnet build)
- [ ] Debugging with Visual Studio
- [ ] Debugging with Rider/VS Code
- [ ] Unit test intro with MSTest

---

## Stage 2: C# Language Deep Dive
**Progress: 0/20 (0%)**

- [ ] OOP in C#
- [ ] Abstract classes vs Interfaces
- [ ] Polymorphism
- [ ] Sealed classes
- [ ] Static classes
- [ ] Records vs classes
- [ ] Structs in C#
- [ ] Properties & auto-properties
- [ ] Indexers
- [ ] Delegates
- [ ] Events
- [ ] Lambdas
- [ ] Extension methods
- [ ] Generics
- [ ] Constraints in generics
- [ ] Tuples
- [ ] Pattern matching
- [ ] LINQ basics
- [ ] LINQ deferred execution
- [ ] Anonymous types

---

## Stage 3: Advanced C# Features
**Progress: 0/20 (0%)**

- [ ] async/await
- [ ] Tasks vs Threads
- [ ] Parallel LINQ (PLINQ)
- [ ] Cancellation tokens
- [ ] Reflection
- [ ] Attributes in C#
- [ ] Dynamic type
- [ ] ExpandoObject
- [ ] Expression trees
- [ ] Span<T> & Memory<T>
- [ ] Unsafe code
- [ ] P/Invoke (Platform Invoke)
- [ ] IDisposable & using pattern
- [ ] IDisposable async
- [ ] IDisposable with IAsyncDisposable
- [ ] Records equality vs class equality
- [ ] Operator overloading
- [ ] Immutable types
- [ ] ValueTask vs Task
- [ ] Benchmarking C# code

---

## Stage 4: Data & Collections
**Progress: 0/20 (0%)**

- [ ] Arrays
- [ ] List<T>
- [ ] Dictionary<TKey, TValue>
- [ ] HashSet<T>
- [ ] SortedDictionary
- [ ] ConcurrentDictionary
- [ ] Queue & Stack
- [ ] LinkedList
- [ ] ObservableCollection
- [ ] IEnumerable vs IQueryable
- [ ] Iterators with yield
- [ ] LINQ filtering
- [ ] LINQ projection
- [ ] LINQ joins
- [ ] LINQ grouping
- [ ] LINQ aggregation
- [ ] LINQ to XML
- [ ] LINQ performance
- [ ] Custom collection classes
- [ ] IEnumerable custom implementation

---

## Stage 5: Entity Framework Core
**Progress: 0/20 (0%)**

- [ ] ORM basics
- [ ] DbContext & DbSet
- [ ] EF Core migrations
- [ ] Database-first vs Code-first
- [ ] Fluent API
- [ ] Data annotations
- [ ] LINQ to Entities
- [ ] Change tracking
- [ ] Lazy vs eager loading
- [ ] Explicit loading
- [ ] Transactions in EF Core
- [ ] Concurrency tokens
- [ ] Value converters
- [ ] Owned entities
- [ ] Global query filters
- [ ] Compiled queries
- [ ] Shadow properties
- [ ] Raw SQL in EF Core
- [ ] Interceptors
- [ ] EF Core performance tuning

---

## Stage 6: ASP.NET Core Basics
**Progress: 0/20 (0%)**

- [ ] ASP.NET Core project templates
- [ ] Startup.cs configuration
- [ ] Middleware pipeline
- [ ] Dependency injection in ASP.NET
- [ ] Controllers vs Minimal APIs
- [ ] Routing basics
- [ ] Model binding
- [ ] Model validation
- [ ] Filters (action, result, exception)
- [ ] Tag helpers in Razor
- [ ] View components
- [ ] Layout pages
- [ ] Razor pages
- [ ] Static files middleware
- [ ] appsettings.json config
- [ ] Environment-based config
- [ ] Logging in ASP.NET Core
- [ ] Request pipeline order
- [ ] HTTP context
- [ ] Global error handling middleware

---

## Stage 7: Web APIs
**Progress: 0/20 (0%)**

- [ ] Creating REST API
- [ ] Attribute routing
- [ ] Versioning APIs
- [ ] ActionResult vs IActionResult
- [ ] Return types in APIs
- [ ] Content negotiation
- [ ] ProducesResponseType attribute
- [ ] FromBody, FromQuery, FromRoute
- [ ] File uploads in Web API
- [ ] File downloads
- [ ] API validation filters
- [ ] JWT authentication
- [ ] Refresh tokens
- [ ] Role-based authorization
- [ ] Policy-based authorization
- [ ] API documentation with Swagger
- [ ] Swagger UI customization
- [ ] API testing with Postman
- [ ] CORS in ASP.NET Core
- [ ] API best practices

---

## Stage 8: Authentication & Security
**Progress: 0/20 (0%)**

- [ ] ASP.NET Identity basics
- [ ] Register/Login flow
- [ ] Password hashing
- [ ] Account confirmation
- [ ] Lockout policies
- [ ] Two-factor authentication
- [ ] OAuth2 in ASP.NET
- [ ] OpenID Connect
- [ ] External logins (Google, Facebook)
- [ ] Token validation middleware
- [ ] Claims-based identity
- [ ] Roles in ASP.NET Core
- [ ] Policy-based authorization
- [ ] Cookie authentication
- [ ] Secure headers middleware
- [ ] CSRF prevention
- [ ] XSS prevention in Razor
- [ ] Data protection API
- [ ] Secret management
- [ ] GDPR compliance in .NET

---

## Stage 9: Advanced ASP.NET Core
**Progress: 0/20 (0%)**

- [ ] SignalR basics
- [ ] SignalR hubs
- [ ] Real-time chat with SignalR
- [ ] Group management in SignalR
- [ ] Scaling SignalR with Redis
- [ ] gRPC with ASP.NET Core
- [ ] Unary vs streaming gRPC
- [ ] gRPC load balancing
- [ ] Custom middleware
- [ ] Endpoint routing
- [ ] Health checks
- [ ] Background services (IHostedService)
- [ ] Queued background services
- [ ] Quartz.NET in ASP.NET
- [ ] Hangfire basics
- [ ] Caching responses
- [ ] Response compression
- [ ] Output caching
- [ ] API throttling
- [ ] WebSockets in ASP.NET Core

---

## Stage 10: Microservices in .NET
**Progress: 0/20 (0%)**

- [ ] Monolith vs Microservices in .NET
- [ ] DDD with .NET
- [ ] CQRS with .NET
- [ ] Event sourcing in .NET
- [ ] MediatR library
- [ ] API Gateway (Ocelot)
- [ ] Service-to-service authentication
- [ ] Dockerizing .NET apps
- [ ] Kubernetes with .NET
- [ ] Service discovery
- [ ] Resiliency with Polly
- [ ] Circuit breaker pattern
- [ ] Retry policies
- [ ] Bulkhead isolation
- [ ] Distributed caching
- [ ] CAP theorem in .NET context
- [ ] Outbox pattern
- [ ] Saga pattern
- [ ] Event-driven microservices
- [ ] Logging correlation IDs

---

## Stage 11: Testing
**Progress: 0/20 (0%)**

- [ ] Unit testing with xUnit
- [ ] Moq for mocking
- [ ] NUnit basics
- [ ] FluentAssertions
- [ ] Integration testing ASP.NET
- [ ] TestServer in ASP.NET Core
- [ ] In-memory DB for EF Core tests
- [ ] End-to-end tests with Playwright
- [ ] Selenium for .NET
- [ ] Load testing APIs
- [ ] BenchmarkDotNet
- [ ] Test data builders
- [ ] Golden master tests
- [ ] Snapshot testing
- [ ] Test-driven development (TDD)
- [ ] Behavior-driven development (SpecFlow)
- [ ] Contract testing with Pact
- [ ] CI/CD test automation
- [ ] Code coverage tools
- [ ] Mutation testing in .NET

---

## Stage 12: Performance & Optimization
**Progress: 0/20 (0%)**

- [ ] BenchmarkDotNet deep dive
- [ ] Memory leaks in .NET
- [ ] Profiling with dotMemory
- [ ] Profiling with PerfView
- [ ] Async deadlocks in .NET
- [ ] ValueTask optimizations
- [ ] Struct vs class performance
- [ ] Span<T> performance
- [ ] StringBuilder vs string concatenation
- [ ] JSON serialization performance
- [ ] System.Text.Json vs Newtonsoft.Json
- [ ] Minification & compression in ASP.NET
- [ ] Object pooling
- [ ] Caching patterns
- [ ] Response buffering
- [ ] Async I/O performance
- [ ] Parallel.For vs Task.Run
- [ ] Thread pool tuning
- [ ] Connection pool tuning
- [ ] Minimizing GC pressure

---

## Stage 13: DevOps & Deployment
**Progress: 0/20 (0%)**

- [ ] Publishing .NET apps
- [ ] Self-contained vs framework-dependent
- [ ] .NET Docker images
- [ ] Multi-stage Docker builds
- [ ] Kubernetes deployment
- [ ] Helm charts for .NET
- [ ] Azure App Service
- [ ] AWS Elastic Beanstalk
- [ ] GCP Cloud Run with .NET
- [ ] CI/CD pipelines (GitHub Actions)
- [ ] CI/CD pipelines (Azure DevOps)
- [ ] Environment variables in .NET
- [ ] Key Vault integration
- [ ] Monitoring with Application Insights
- [ ] Logging with Serilog
- [ ] Logging with NLog
- [ ] Distributed tracing with OpenTelemetry
- [ ] Health probes in Kubernetes
- [ ] Blue/green deployments
- [ ] Canary deployments

---

## Stage 14: Enterprise & Architecture
**Progress: 0/20 (0%)**

- [ ] Clean architecture in .NET
- [ ] Onion architecture
- [ ] Hexagonal architecture
- [ ] Modular monolith in .NET
- [ ] Multi-tenant SaaS in .NET
- [ ] Multi-layer architecture
- [ ] SOLID in .NET
- [ ] Repository pattern
- [ ] Unit of Work pattern
- [ ] Factory pattern
- [ ] Mediator pattern
- [ ] Observer pattern
- [ ] Singleton pitfalls
- [ ] Facade pattern
- [ ] Adapter pattern
- [ ] Proxy pattern
- [ ] Dependency injection container design
- [ ] Cross-cutting concerns
- [ ] API gateways for enterprise
- [ ] Governance in .NET projects

---

## Stage 15: Principal-Level .NET Concerns
**Progress: 0/20 (0%)**

- [ ] .NET long-term support (LTS)
- [ ] Migrating from .NET Framework to .NET 6/7/8
- [ ] Designing planet-scale .NET apps
- [ ] Multi-region .NET deployment
- [ ] Data residency challenges in .NET
- [ ] GDPR/Compliance in .NET systems
- [ ] High availability with .NET
- [ ] Reliability patterns in .NET
- [ ] Observability in .NET at scale
- [ ] Incident response in .NET
- [ ] Security audits in .NET
- [ ] Supply chain risks (NuGet packages)
- [ ] Dependency management
- [ ] Technical debt management
- [ ] Cost efficiency in .NET systems
- [ ] API monetization with .NET
- [ ] .NET in hybrid cloud
- [ ] .NET in IoT/Edge computing
- [ ] .NET + AI integration
- [ ] Future of .NET ecosystem

---

## 📊 Learning Tips

### .NET Learning Path:
1. **Master C# fundamentals** - Strong typing, OOP concepts
2. **Understand .NET runtime** - CLR, garbage collection, JIT
3. **Learn ASP.NET Core** - Modern web development framework
4. **Practice with Entity Framework** - ORM for data access
5. **Build real projects** - Apply concepts in practical scenarios

### Essential Resources:
- **Microsoft Learn**: Free learning paths and modules
- **C# Documentation**: docs.microsoft.com/dotnet
- **ASP.NET Core Documentation**: Comprehensive guides
- **Entity Framework Documentation**: Data access patterns
- **Visual Studio**: Full-featured IDE for .NET development

### Practice Projects:
- Web API with authentication and authorization
- Blazor web application
- Console application with dependency injection
- Microservices with Docker and Kubernetes
- Real-time application with SignalR
- Desktop application with WPF or MAUI

### Performance Tips:
- Use async/await for I/O operations
- Implement proper disposal patterns
- Choose appropriate collection types
- Profile and benchmark critical code paths
- Minimize allocations in hot paths

---

**Last Updated**: [Add your date here]
**Next Review**: [Schedule your next review]
