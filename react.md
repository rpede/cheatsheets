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
        target: "http://localhost:5153",
        changeOrigin: true,
      },
    },
  },
});
```

Replace `5153` with the actual port of your backend.

## Scaffold client

```sh
npx swagger-typescript-api generate -p https://localhost:5153/swagger/v1/swagger.json -o ./ -n generated-client.ts
```

Replace `5153` with the actual port of your backend.
