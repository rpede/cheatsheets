# React

## Project setup

**Create vite project**

Replace `<NAME>` with the name your want for SPA.

```sh
npm create vite@latest <NAME> -- --template react-ts
```

Accept the defaults.
When you see `Starting dev server...` press <kbd>CTRL</kbd>+<kbd>c</kbd> to exit.

**Initialize local git repository**

```sh
# Navigate to project folder
cd <NAME>
# Initialize local git repository
git init
```

**Setup routing**

```sh
npm install react-router
```

Replace `src/main.tsx` with:

```ts
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
```

## Tailwind + daisyUI

```sh
npm install tailwindcss@latest @tailwindcss/vite@latest daisyui@latest
```

Replace `vite.config.ts` with the following:

```ts
import { defineConfig } from "vite";
import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [tailwindcss(), react()],
});
```

Prepend to `src/App.css`:

```css
@import "tailwindcss";
@plugin "daisyui";
```

## Proxy

Replace `vite.config.ts` with the following, replacing target port with the
actual port of your backend.

```ts
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
```

Replace `5000` with the actual port of your backend.

## Dockerize

Create a template configuration for nginx in `nginx.conf.template` with:

```nginx
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
```

Create `Dockerfile` with:

```sh
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
```

## Scaffold client

```sh
npx swagger-typescript-api generate -p http://localhost:5000/swagger/v1/swagger.json -o ./ -n generated-client.ts
```

Replace `5000` with the actual port of your backend.
