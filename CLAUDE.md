# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Application Overview

This is a minimal Rails 8.0.2 application called "Assignman" using PostgreSQL as the database. The application was generated with `rails new . --minimal --database=postgresql` and follows standard Rails conventions.

## Development Commands

### Setup and Installation
- `bin/setup` - Complete setup script that installs dependencies, prepares database, and starts the server
- `bin/setup --skip-server` - Setup without starting the server
- `bundle install` - Install Ruby gems

### Database Operations
- `bin/rails db:prepare` - Prepare database (create, migrate, seed as needed)
- `bin/rails db:create` - Create databases
- `bin/rails db:migrate` - Run migrations
- `bin/rails db:seed` - Load seed data
- `bin/rails db:reset` - Drop, create, migrate, and seed database

### Server and Development
- `bin/dev` - Start development server (executes `bin/rails server`)
- `bin/rails server` - Start Rails server directly
- `bin/rails console` - Start Rails console

### Testing
- `bundle exec rspec` - Run all RSpec tests
- `bundle exec rspec spec/models/` - Run model specs
- `bundle exec rspec spec/controllers/` - Run controller specs
- `bundle exec rspec spec/requests/` - Run request specs
- `bin/rails test` - Run Rails default tests (if any exist)

### Code Quality
- `bundle exec rubocop` - Run RuboCop static analysis
- `bundle exec rubocop --autocorrect` - Auto-fix RuboCop violations
- `bundle exec rubocop --autocorrect-all` - Auto-fix all RuboCop violations (including unsafe)

### Use Cases
- `bundle exec rspec spec/usecases/` - Run all use case tests
- Use cases are located in `app/usecases/` with corresponding specs in `spec/usecases/`

### Maintenance
- `bin/rails log:clear` - Clear log files
- `bin/rails tmp:clear` - Clear temporary files

## Architecture

### Database Configuration
- **Development & Test**: SQLite3 databases stored in `storage/` directory
  - `storage/development.sqlite3` (development)
  - `storage/test.sqlite3` (test)
- **Production**: PostgreSQL database
  - `assignman_production` (production)

### Rails Components
- **Minimal Rails setup** with only essential components enabled:
  - Active Model, Active Record, Action Controller, Action View
  - Test framework (Rails Test Unit)
  - Disabled: Active Job, Active Storage, Action Mailer, Action Mailbox, Action Text, Action Cable
- **Modern browser support** enforced via `allow_browser versions: :modern`
- **Propshaft** for asset pipeline instead of Sprockets
- **Puma** web server

### File Structure
- Standard Rails MVC structure in `app/` directory
- Test files organized in `test/` with parallel structure to `app/`
- Database configuration supports environment variables for production deployment
- PWA files available but commented out in routes

### Testing Configuration
- **RSpec** as primary testing framework with:
  - FactoryBot for test data generation
  - **Explicit expect statements preferred over DSL matchers** (no shoulda-matchers)
  - Automatic spec type inference based on file location
  - Support files auto-loaded from `spec/support/`
- **Rails Test::Unit framework disabled**: Generator configured to use RSpec only
- **No fixtures or test directory**: Only spec/ directory for all tests
- Database: Uses SQLite3 for fast test execution

### Testing Philosophy
- **Explicit over implicit**: Use clear `expect(user.errors[:email]).to include("can't be blank")` instead of `should validate_presence_of(:email)`
- **Readable test intentions**: Each test should clearly show what is being tested and what the expected outcome is
- **No magic DSL**: Avoid test DSLs that obscure the actual behavior being tested

### Code Quality Standards
- **RuboCop** for static code analysis with Rails and RSpec extensions
- **Configuration**: `.rubocop.yml` with Rails-specific rules and relaxed RSpec constraints
- **Key Settings**:
  - Line length: 120 characters
  - Method length: 15 lines max
  - Disabled rules: Documentation, FrozenStringLiteral, RSpec/LetSetup, RSpec/ContextWording
  - RSpec MultipleExpectations: 10 max (for comprehensive API tests)

### Generator Configuration
Rails generators are configured to:
- Use RSpec instead of Test::Unit
- Generate FactoryBot factories in `spec/factories/`
- Skip view specs, helper specs, stylesheets, and javascripts
- Not generate test/ directory files

## Development Preferences & Philosophy

### Code Quality & Testing Preferences
- **Explicit over implicit testing**: Prefer `expect(user.errors[:email]).to include("can't be blank")` over DSL matchers like `should validate_presence_of(:email)`
- **RSpec-only environment**: Never use Test::Unit, fixtures, or test/ directory
- **Clean generators**: Rails generators should only create RSpec specs and FactoryBot factories
- **Manual test verification**: Always run tests after major changes to ensure nothing breaks

### Data Model Design Preferences  
- **Separation of concerns**: Split models by responsibility (User/UserCredential/UserProfile pattern)
- **Authentication vs Authorization separation**: Keep auth data separate from permission data
- **Explicit relationships**: Use clear `has_one`/`belongs_to` relationships with proper validations

### API Design Preferences
- **API-first architecture**: All functionality exposed through well-designed REST endpoints
- **Consistent response format**: Use structured JSON with `total`, `offset`, `data` for collections
- **Proper HTTP status codes**: 200 for success, 404 for not found, 422 for validation errors
- **Request specs over controller specs**: Test the full HTTP request/response cycle

### Infrastructure Preferences
- **Docker for production**: Always provide Docker setup for consistent deployments
- **Multi-environment database**: SQLite for dev/test, PostgreSQL for production
- **Latest Ruby**: Use newest stable Ruby version (currently 3.4)
- **Minimal Rails**: Only include necessary Rails components, disable unused features

### Documentation Preferences
- **Comprehensive CLAUDE.md**: Document all setup, commands, and architectural decisions
- **Explicit data structure docs**: Maintain DATA_STRUCTURE.md with clear entity relationships
- **No redundant docs**: Don't create README or other docs unless explicitly requested

### Git Preferences
- **Descriptive commit messages**: Clear summary with detailed bullet points of changes
- **Include generation signature**: Always add "🤖 Generated with [Claude Code]" footer
- **Logical grouping**: Commit related changes together, not piecemeal

## Product Specification: Assignman

### Vision and Problem Statement
Assignman is a modern, visual SaaS platform designed to solve resource allocation challenges in project-based work environments. It replaces inefficient Excel-based assignment management with an intuitive, interactive visual canvas that provides real-time visibility into "who is working on what project, when, and at what capacity."

**Key Problems Solved:**
- Lack of real-time resource visibility
- Difficulty identifying available resources  
- Risk of member over-allocation
- Manual, error-prone assignment processes
- Dependency on specific individuals (避免属人化)

### Core Data Model

**Critical Design Decision: User vs Member Separation**
- **User**: System login credentials (limited by licensing costs)
- **Member**: Assignable human resources (unlimited, includes external contractors)
- This separation enables cost-effective management of external partners and contractors without requiring system licenses for each person

**Core Entities:**
- **Organization**: Multi-tenant root entity
- **User**: System access with roles (Admin/Manager/Viewer)  
- **Member**: Assignable resources with skills and capacity
- **Project**: Time-bounded work with start/end dates and status
- **Assignment**: Core relationship linking Member to Project with date range and allocation percentage
- **Role**: Job functions (Engineer, Designer, Director) - organization customizable
- **Skill**: Technical capabilities for advanced resource matching

### Key Features (MVP Scope)

#### 1. Assignment Canvas - Core Visual Interface
- **Dual View Toggle**: Project-centric vs Member-centric views
- **Project View**: Expandable project rows showing role requirements and current assignments
- **Member View**: Member rows with capacity utilization bars (green→yellow→red based on allocation)
- **Interactive Timeline**: Horizontal scrolling with sticky headers, zoom levels (week/month/quarter)
- **Drag & Drop**: Direct timeline manipulation for assignment creation/editing

#### 2. Smart Filtering & Search
- Standard filters: status, client, member, role, skill
- **Strategic Meta-filters**: 
  - "Unassigned projects" (0 assignments)
  - "Available members" (capacity < X% in specified period)
- Real-time capacity calculations for optimal resource matching

#### 3. Over-allocation Prevention
- Real-time visual feedback when member capacity exceeds 100%
- Immediate warning indicators (red highlighting) 
- Non-blocking notifications to maintain workflow

#### 4. CRUD Operations
- Project lifecycle management with visual impact warnings for date changes
- Member profiles with skill/role management
- Assignment creation via drag-drop or modal forms
- Timeline manipulation (drag to move, resize to adjust duration)

### Business Model
- **Freemium**: Limited to 10 active members (following competitor "asamana" model)
- **Paid Plans**: Unlimited members, RBAC, SSO, advanced reporting, Excel export

### Technical Requirements
- API-first architecture (RESTful endpoints)
- Real-time collaboration (soft refresh within 10-15 seconds)
- Performance: Main canvas loads <3 seconds, interactions <500ms
- Responsive design (laptop to large monitors)
- Data portability: CSV export (free), Excel export (paid)

### Post-MVP Roadmap
- V1.1: Advanced reporting dashboard
- V1.2: Calendar integration (Google/Outlook) and Slack notifications  
- V1.3: Time tracking and project cost analysis
- V1.4: Talent management features (goals, evaluations, career paths)

## Implemented Use Cases

The application implements four core use cases following the domain model specified in DATA_STRUCTURE.md:

### 1. CreateRoughProjectAssignment
**Purpose**: プロジェクト全体計画の策定 (Project Overall Planning)
- **Actor**: Administrator (User)
- **Input**: project, member, start_date, end_date, allocation_percentage, administrator
- **Behavior**: Creates rough assignments for planning purposes (not visible to members)
- **Validations**: Organization consistency, no overlapping rough assignments
- **Note**: Skips capacity and project period validations for planning flexibility

### 2. ConfirmRoughProjectAssignment  
**Purpose**: メンバーへのアサインの確定と通知 (Confirm and Notify Member Assignments)
- **Actor**: Administrator (User)
- **Input**: rough_assignment, administrator
- **Behavior**: Converts rough assignment to confirmed status (visible to members)
- **Validations**: Capacity constraints, authorization checks
- **Note**: Enforces all business rules when confirming assignments

### 3. CreateOngoingAssignment
**Purpose**: 定常業務の割り当て (Ongoing Work Assignment)
- **Actor**: Administrator (User)  
- **Input**: project, member, start_date, end_date (optional), allocation_percentage, administrator
- **Behavior**: Creates ongoing assignments for continuous work (immediately confirmed)
- **Validations**: Capacity constraints, supports indefinite end dates
- **Note**: Bypasses planning phase - directly creates confirmed assignments

### 4. GetMemberSchedule
**Purpose**: 自身の確定スケジュールの確認 (View Confirmed Schedule)
- **Actor**: Member or Administrator
- **Input**: member, start_date, end_date, viewer
- **Behavior**: Returns confirmed and ongoing assignments (excludes rough assignments)
- **Authorization**: Members can view own schedule, Administrators can view any member in their organization
- **Output**: Daily schedule with assignments, allocation totals, and summary statistics

### Use Case Architecture
- **Base Class**: `BaseUseCase` with standardized error handling and result objects
- **Error Types**: ValidationError, AuthorizationError, NotFoundError, Error
- **Result Pattern**: Returns success/failure objects with data or error information
- **Testing**: Comprehensive unit tests with explicit expectations (no DSL matchers)

## Docker Configuration

### Production Environment Setup
- **Dockerfile**: Multi-stage build with Ruby 3.3-alpine base image
- **docker-compose.yml**: PostgreSQL 17-alpine + Rails app setup
- **Environment Variables**: 
  - `DATABASE_URL` for PostgreSQL connection
  - `SECRET_KEY_BASE` for Rails security
  - `ASSIGNMAN_DATABASE_PASSWORD` for database authentication

### Usage Commands
- `docker compose up --build` - Build and start all services
- `docker compose up -d db` - Start only PostgreSQL database
- `docker compose logs web` - View Rails application logs
- `docker compose exec web bundle exec rails console` - Access Rails console in container