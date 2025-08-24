# ASP.NET - cheat sheet

<!--toc:start-->
- [ASP.NET - cheat sheet](#aspnet-cheat-sheet)
  - [Project setup](#project-setup)
    - [Server (backend)](#server-backend)
    - [Database setup](#database-setup)
    - [Useful commands](#useful-commands)
    - [Identity](#identity)
    - [Scalar](#scalar)
  - [Resources](#resources)
<!--toc:end-->

## Project setup

### Server (backend)

In .NET you create a solution (.sln file) which
references one o more projects (.csproj files).

```sh
# Create a folder for your work
mkdir <NAME>
# Navigate into the folder
cd <NAME>
# Turn the folder into a local GIT repository
git init
# Create a .gitignore file, telling git to ignore certain files
dotnet new gitignore

# Create a solution file
dotnet new sln

# Create a ASP.NET Web API project
dotnet new webapi -controllers -o server/Api
# Add it to solution
dotnet sln add server/Api

# Create DataAccess project
dotnet new classlib -o server/DataAccess
# Add it to solution
dotnet sln *.sln add server/DataAccess
# Make sure you have Entity Framework CLI
dotnet tool install --global dotnet-ef
# Entity Framework dependency
dotnet add server/DataAccess package Microsoft.EntityFrameworkCore.Design
# PostgreSQL support
dotnet add server/DataAccess package Npgsql.EntityFrameworkCore.PostgreSQL

# Make sure TUnit project template is installed
dotnet new install TUnit.Templates
# Create Tests project
dotnet new TUnit -o server/Tests
# Add it to solution
dotnet sln *.sln add server/Tests

# Wire the projects together
dotnet add server/Api reference server/DataAccess
dotnet add server/Tests reference server/Api
```

### Database setup

Create `server/DataAccess/AppDbContext.cs` with:

```cs
using Microsoft.EntityFrameworkCore;
namespace DataAccess;
public class AppDbContext : DbContext { }
```

Add the following to `server/Api/Program.cs` before `var app = builder.Build();`.

```cs
var connectionString = builder.Configuration.GetConnectionString("AppDb");
builder.Services.AddDbContext<AppDbContext>(options =>
    options
        .UseNpgsql(connectionString)
        .UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking)
);
```

And somewhere after `var app = builder.Build();`, add these lines:

```cs
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    context.Database.EnsureCreated();
}
```

Add this to `server/Api/appsettings.Development`

```json
  "ConnectionStrings": {
    "AppDb": "HOST=localhost;DB=postgres;UID=postgres;PWD=mysecret;PORT=5432;"
  }
```

Start a local database with docker.
Add this to `docker-compose.yml`:

```yml
services:
  db:
    image: postgres:17-alpine
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: mysecret
    ports:
      - "5432:5432"
```

Then run:

```sh
docker compose up -d
```

### Useful commands

```sh
# Run the project
dotnet run --project server/Api

# Run, but reload on code change
dotnet run --project server/Api --watch

# Build/compile
dotnet build

# Run tests
dotnet test
```

### Identity

ASP.NET Core Identity or just Identity for short, can be used to quickly add
user registration, authentication to a project.

First, add the packages.

```sh
dotnet add server/DataAccess package Microsoft.AspNetCore.Identity.EntityFrameworkCore
dotnet add server/Api package Microsoft.AspNetCore.Identity.EntityFrameworkCore
```

Identity uses a bunch of extra tables.
A DbContext that supports those is needed.
Therefore, change your `server/DataAccess/AppDbContext.cs` to:

```cs
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
namespace DataAccess;
public class AppDbContext : IdentityDbContext<IdentityUser>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
}
```

The Identity related services etc. needs to be registered on startup.
Open `server/Api/Program.cs` and add the following before `var app =
builder.Build();`:

```cs
builder.Services.AddAuthorization();

builder.Services.AddIdentityApiEndpoints<IdentityUser>()
    .AddEntityFrameworkStores<AppDbContext>();
```

Then after `var app = builder.Build();` add:

```cs
app.MapIdentityApi<IdentityUser>();
```

### Scalar

Scalar gives a nice UI for documentation and manual testing base on OpenAPI.

```sh
dotnet add server/Api package Scalar.AspNetCore
```

Open `Program.cs` and change the following lines:

```cs
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}
```

To this:

```cs
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}
```

## Resources

- [Installing TUnit](https://tunit.dev/docs/getting-started/installation)
- [Getting Started with EF Core](https://learn.microsoft.com/en-us/ef/core/get-started/overview/first-app?tabs=netcore-cli)
- [How to use Identity to secure a Web API backend for SPAs](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-api-authorization?view=aspnetcore-9.0)
- [Scalar - .NET ASP.NET Core](https://guides.scalar.com/scalar/scalar-api-references/integrations/net-aspnet-core)
