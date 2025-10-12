#!/bin/bash
set -e
if [ $# -eq 0 ]; then
  echo "No arguments provided."
  echo "Usage: $1 <name>"
  echo "Please provide a value to use as project name."
  exit 1
fi

NAME=$1
B='\033[0:34m'
G='\033[0:32m'
N='\033[0m'

echo "Create project folder"
mkdir $NAME
# Navigate into the folder
cd $NAME

echo "Initialize git repository"
# Turn the folder into a local GIT repository
git init
# Create a .gitignore file, telling git to ignore certain files
dotnet new gitignore

echo "Creating server"
echo "Create .NET solution and projects"
# Create a solution file
dotnet new sln > /dev/null

echo "Creating Api project"
# Create a ASP.NET Web API project
dotnet new webapi -controllers -o server/Api > /dev/null
# Add it to solution
dotnet sln add server/Api > /dev/null
dotnet add server/Api package Scalar.AspNetCore > /dev/null

echo "Creating DataAccess project"
# Create DataAccess project
dotnet new classlib -o server/DataAccess > /dev/null
# Add it to solution
dotnet sln *.sln add server/DataAccess > /dev/null

echo "Configuring Entity Framework"
# Make sure you have Entity Framework CLI
dotnet tool install --global dotnet-ef > /dev/null
# Entity Framework dependency
dotnet add server/DataAccess package Microsoft.EntityFrameworkCore.Design > /dev/null
# PostgreSQL support
dotnet add server/DataAccess package Npgsql.EntityFrameworkCore.PostgreSQL > /dev/null
# Add identity
dotnet add server/DataAccess package Microsoft.AspNetCore.Identity.EntityFrameworkCore > /dev/null
dotnet add server/Api package Microsoft.AspNetCore.Identity.EntityFrameworkCore > /dev/null

echo "Create Tests project using xUnit"
# Make sure xUnit.net project template is installed
dotnet new install xunit.v3.templates > /dev/null
# Create Tests project
dotnet new xunit3 -f net9.0 -o server/Tests > /dev/null
# Add it to solution
dotnet sln *.sln add server/Tests > /dev/null

echo "Add project references"
# Wire the projects together
dotnet add server/Api reference server/DataAccess > /dev/null
dotnet add server/Tests reference server/Api > /dev/null

echo "Finalizing server setup"

cat >server/Api/Properties/launchSettings.json <<EOF
{
  "\$schema": "https://json.schemastore.org/launchsettings.json",
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
EOF

cat >server/Api/appsettings.Development.json <<EOF
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ConnectionStrings": {
    "AppDb": "HOST=localhost;DB=postgres;UID=postgres;PWD=mysecret;PORT=5432;"
  }
}
EOF

cat >server/DataAccess/AppDbContext.cs <<EOF
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
namespace DataAccess;
public class AppDbContext : IdentityDbContext<IdentityUser>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }
}
EOF

cat >server/Api/Program.cs <<EOF
using DataAccess;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Scalar.AspNetCore;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

var connectionString = builder.Configuration.GetConnectionString("AppDb");
builder.Services.AddDbContext<AppDbContext>(options =>
    options
        .UseNpgsql(connectionString)
        .UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking)
);

builder.Services.AddAuthorization();
builder.Services.AddIdentityApiEndpoints<IdentityUser>()
    .AddEntityFrameworkStores<AppDbContext>();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    context.Database.EnsureCreated();
}

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.MapScalarApiReference();
}

app.UseHttpsRedirection();

app.UseAuthorization();

app.MapIdentityApi<IdentityUser>();
app.MapControllers();

app.Run();
EOF

echo "Done with server"

echo "Creating client"
echo "Creating React+Vite app"
echo "Please choose \"no\" for the next couple of prompts"
npm create vite@latest client -- --template react-ts

echo "Configuring react-router"
npm install react-router --prefix client > /dev/null
cat >client/src/main.tsx <<EOF
import ReactDOM from "react-dom/client"; import App from "./App";
import {
  createBrowserRouter,
  RouterProvider,
} from "react-router";

let router = createBrowserRouter([
  {
    path: "/",
    Component: App,
  },
]);

ReactDOM.createRoot(document.getElementById("root")!).render(
  <RouterProvider router={router} />,
);
EOF

echo "Configuring Tailwind CSS & daisyUI"
npm install tailwindcss@latest @tailwindcss/vite@latest daisyui@latest --prefix client > /dev/null
cat >client/vite.config.ts <<EOF
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [tailwindcss(), react()],
});
EOF
cat >client/src/App.css <<EOF
@import "tailwindcss";
@plugin "daisyui";
EOF

echo "Configuring vite proxy"
cat >client/vite.config.ts <<EOF
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// https://vite.dev/config/
export default defineConfig({
  plugins: [tailwindcss(), react()],
  server: {
    proxy: {
      "/api": {
        target: "http://localhost:5000",
        changeOrigin: true,
      },
    },
  },
});
EOF

echo "Creating Docker files"

cat >docker-compose.yml <<EOF
services:
  db:
    image: postgres:17-alpine
    restart: always
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: mysecret
    ports:
      - "5432:5432"
EOF

cat >server/Dockerfile <<EOF
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
USER \$APP_UID
# 9. Describe what port the server will listen on.
EXPOSE 8080
# 10. Start Api
CMD ["dotnet", "Api.dll"]
EOF

cp client/.gitignore client/.dockerignore

cat >client/nginx.conf.template <<EOF
map $http_connection $connection_upgrade {
  "~*Upgrade" $http_connection;
  default keep-alive;
}

server {
  listen        80;

  root /usr/share/nginx/html;
  index index.html index.htm;

  location /api {
      proxy_pass         $BACKEND_URL;
      proxy_http_version 1.1;
      proxy_set_header   Upgrade $http_upgrade;
      proxy_set_header   Connection $connection_upgrade;
      proxy_set_header   Host $host;
      proxy_cache_bypass $http_upgrade;
      proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header   X-Forwarded-Proto $scheme;
      proxy_ssl_server_name on;
  }
  location / {
      try_files $uri $uri/ /index.html index.html;
  }
}
EOF

cat >client/Dockerfile <<EOF
# 1. Create a stage for building the application.
FROM node:22-alpine AS build
WORKDIR /app
# 2. Copy package.json and package-lock.json
COPY package*.json ./
# 3. Install dependencies
RUN npm clean-install
# Copy the rest of the application source code
COPY . .
# 4. Build the React application
RUN npm run build

# 5. Stage 2: Serve the React app using nginx
FROM nginx:alpine AS final
# 6. Custom nginx config
COPY nginx.conf.template /
# 7. Copy the build output from the first stage to nginx's html directory
COPY --from=build /app/dist /usr/share/nginx/html
# 8. Expose port 80
EXPOSE 80
# 9. Start nginx
CMD envsubst '$BACKEND_URL' < /nginx.conf.template > /etc/nginx/conf.d/default.conf \
  && nginx -g 'daemon off;'
EOF

exit 0

echo "Creating README.md"
cat >README.md <<EOF
# $NAME

## Quick start

**Start database**

```sh
docker compose up
```

**Start server**

```sh
dotnet run --project server/Api
```

**Start client**

```sh
npm run dev --prefix client
```

**Generate API client**

Make sure your backend is running.
Then do:

```sh
npx swagger-typescript-api generate -p http://localhost:5000/openapi/v1.json -o ./ -n generated-client.ts
```
EOF

echo "Success!"
