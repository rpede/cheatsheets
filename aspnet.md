# ASP.NET - cheat sheet

<!--toc:start-->
- [ASP.NET - cheat sheet](#aspnet-cheat-sheet)
  - [Project setup](#project-setup)
  - [Database setup](#database-setup)
  - [Useful commands](#useful-commands)
  - [Identity](#identity)
  - [Scalar](#scalar)
  - [Resources](#resources)
<!--toc:end-->

## Prerequisites

Assumes you got .NET SDK 9 and ASP.NET runtime 9 installed.

- [Windows](https://learn.microsoft.com/en-us/dotnet/core/install/windows)
- [macOS](https://learn.microsoft.com/en-us/dotnet/core/install/macos)
- [Ubuntu](https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu-install?tabs=dotnet9)
- [Fedora](https://learn.microsoft.com/en-us/dotnet/core/install/linux-fedora?tabs=dotnet9)
- [Arch Linux](https://wiki.archlinux.org/title/.NET)

## Project setup

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

# Make sure xUnit.net project template is installed
dotnet new install xunit.v3.templates
# Create Tests project
dotnet new xunit3 -f net9.0 -o server/Tests
# Add it to solution
dotnet sln *.sln add server/Tests

# Wire the projects together
dotnet add server/Api reference server/DataAccess
dotnet add server/Tests reference server/Api
```

The `dotnet new aebapi` commands sets random ports which can be annoying since
other parts of project setup depends on the port.
It can be fixed by changing `server/Api/Properties/launchSettings.json` to:

```json
{
  "$schema": "https://json.schemastore.org/launchsettings.json",
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "https://localhost:5001;http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

Note: port 5000 for HTTP and 5001 for HTTPS.

Remove `server/Api/WeatherForecast.cs` and
`server/Api/Controllers/WeatherForecastController.cs` files.

## Database setup

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

## Useful commands

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

## Identity

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

## Scalar

Scalar gives a nice UI for documentation and manual testing base on OpenAPI.
It is an alternative to Swagger UI.

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

## Dockerize

Add `server/Dockerfile` for easy deployment.

```Dockerfile
# 1. Create a stage for building the application.
FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS build
# 2. Copy everything in current directory (server/) into /source on build container
COPY . /source
# 3. Change container working directory to /source/api
WORKDIR /source/Api
# 4. Build the application with Release configuration and for linux-x64 since Fly
# runs.
RUN dotnet publish --configuration Release --no-self-contained -o /app

# 5. Create a new stage for running the application with minimal runtime
# dependencies.
FROM mcr.microsoft.com/dotnet/aspnet:9.0-alpine AS final
# 6. Change container working directory to /app
WORKDIR /app
# 7. Copy everything needed to run the app from the "build" stage.
COPY --from=build /app .
# 8. Switch to a non-privileged user (defined in the base image) that the app will run under.
USER $APP_UID
# 9. Describe what port the server will listen on.
EXPOSE 8080
# 10. Start Api
CMD ["dotnet", "Api.dll"]
```

## Resources

- [Getting Started with xUnit.net v3](https://xunit.net/docs/getting-started/v3/getting-started)
- [Getting Started with EF Core](https://learn.microsoft.com/en-us/ef/core/get-started/overview/first-app?tabs=netcore-cli)
- [How to use Identity to secure a Web API backend for SPAs](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-api-authorization?view=aspnetcore-9.0)
- [Scalar - .NET ASP.NET Core](https://guides.scalar.com/scalar/scalar-api-references/integrations/net-aspnet-core)
