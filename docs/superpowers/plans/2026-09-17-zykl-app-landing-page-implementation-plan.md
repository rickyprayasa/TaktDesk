# ZYKL Landing Page (`zykl.app`) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the official product landing website for ZYKL (`zykl.app`) adhering to Dieter Rams / Braun industrial modernism, featuring interactive 3D WebGL chronometer and vinyl turntable, static site export (SSG), Google Play Store CTA with QR code, and a serverless Google Sheets feedback terminal.

**Architecture:** Next.js 15 (App Router) with Static Site Generation (`output: 'export'`), React Three Fiber (`@react-three/fiber`, `@react-three/drei`, Three.js) for 3D hardware instruments, Framer Motion for tactile micro-interactions, and Tailwind CSS with Braun industrial color tokens (`Obsidian` dark & `Warm Bone` light). Client-side direct webhook to Google Sheets via Google Apps Script.

**Tech Stack:** Next.js 15 (App Router), React 19, TypeScript, Three.js, `@react-three/fiber`, `@react-three/drei`, Framer Motion, Tailwind CSS, Lucide React.

## Global Constraints

- Target directory: `/home/tuneeca/RSQUARE/Android/zykl.app/`.
- Strict Dieter Rams / Braun modernist industrial aesthetics: matte chassis, tactile Allen screws, monospace telemetry labels (`MOD. 01`, `REV. 104`), honest materials (Obsidian `#121316`, Basalt `#24272C`, Warm Bone `#F4F2EC`, Filament Amber `#FF9E00`, Raw Brass `#C89B3C`).
- Zero AI Slop: No purple gradients, no hollow corporate buzzwords, no generic cartoon illustrations.
- Zero GitHub links in user-facing navigation or copy.
- Zero direct APK download links (all CTAs route strictly to Google Play Store and display the desktop QR scanner plate).
- Zero namespace contamination: 0 occurrences of `tuneeca` across all code and assets.
- Production build: `npm run build` must cleanly generate static HTML in `out/` with 0 TypeScript/ESLint diagnostics.

---

### Task 1: Next.js 15 Project Scaffolding & Dieter Rams Industrial Design Tokens

**Files:**
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/package.json`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/tsconfig.json`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/next.config.ts`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/tailwind.config.ts`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/app/globals.css`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/app/layout.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/app/page.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/lib/utils.ts`
- Asset copy: `/home/tuneeca/RSQUARE/Android/zykl.app/public/audio/` (from Takt Desk `assets/audio/`)
- Asset copy: `/home/tuneeca/RSQUARE/Android/zykl.app/public/images/zykl_icon.png` (from Takt Desk `ic_launcher.png`)

**Interfaces:**
- Consumes: Audio WAV files and app launcher icons from `/home/tuneeca/RSQUARE/Android/Takt Desk/`.
- Produces: Base Next.js 15 SSG project, CSS variable theme engine (`dark` and `light`), industrial fonts, and asset pipeline.

- [ ] **Step 1: Initialize Git and package.json with dependencies**

In `/home/tuneeca/RSQUARE/Android/zykl.app/`:
Initialize git and create `package.json` with Next.js 15, React 19, Three.js, React Three Fiber, Framer Motion, Lucide React, and Tailwind CSS.

```json
{
  "name": "zykl-app",
  "version": "1.0.4",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "@react-three/drei": "^9.121.5",
    "@react-three/fiber": "^8.18.0",
    "clsx": "^2.1.1",
    "framer-motion": "^12.4.7",
    "lucide-react": "^1.16.0",
    "next": "15.2.1",
    "react": "19.0.0",
    "react-dom": "19.0.0",
    "tailwind-merge": "^3.0.2",
    "three": "^0.174.0"
  },
  "devDependencies": {
    "@types/node": "^22.13.9",
    "@types/react": "19.0.10",
    "@types/react-dom": "19.0.4",
    "@types/three": "^0.174.0",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.5.3",
    "tailwindcss": "^3.4.17",
    "typescript": "^5.8.2"
  }
}
```

- [ ] **Step 2: Run npm install**

Run: `cd /home/tuneeca/RSQUARE/Android/zykl.app && npm install`
Expected: `added ... packages in ...s`

- [ ] **Step 3: Configure next.config.ts, tsconfig.json, and tailwind.config.ts**

Create `next.config.ts`:
```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "export",
  images: {
    unoptimized: true,
  },
  reactStrictMode: true,
};

export default nextConfig;
```

Create `tailwind.config.ts`:
```typescript
import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: ["class", '[data-theme="dark"]'],
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        chassis: {
          bg: "var(--chassis-bg)",
          surface: "var(--chassis-surface)",
          plate: "var(--chassis-plate)",
          border: "var(--chassis-border)",
          rivet: "var(--chassis-rivet)",
        },
        monastic: {
          text: "var(--monastic-text)",
          muted: "var(--monastic-muted)",
          amber: "#FF9E00",
          brass: "#C89B3C",
          steel: "#8B929A",
          aluminum: "#D1D5DB",
          ink: "#121316",
        },
      },
      fontFamily: {
        mono: ["var(--font-mono)", "ui-monospace", "SFMono-Regular", "Menlo", "Monaco", "Consolas", "monospace"],
        sans: ["var(--font-sans)", "ui-sans-serif", "system-ui", "sans-serif"],
      },
    },
  },
  plugins: [],
};

export default config;
```

Create `tsconfig.json`:
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

Create `postcss.config.mjs`:
```javascript
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

- [ ] **Step 4: Create globals.css with Dieter Rams Industrial Color Variables & layout.tsx**

Create `src/app/globals.css`:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  /* Warm Bone (Light Theme) */
  --chassis-bg: #EAE6DF;
  --chassis-surface: #F4F2EC;
  --chassis-plate: #E2DDD5;
  --chassis-border: #CFC9BF;
  --chassis-rivet: #8D877C;
  --monastic-text: #191B1F;
  --monastic-muted: #626770;
}

[data-theme="dark"] {
  /* Obsidian Basalt (Dark Theme - Default) */
  --chassis-bg: #0F1012;
  --chassis-surface: #17181C;
  --chassis-plate: #22242A;
  --chassis-border: #32363E;
  --chassis-rivet: #525866;
  --monastic-text: #E6E8EB;
  --monastic-muted: #8F96A3;
}

body {
  background-color: var(--chassis-bg);
  color: var(--monastic-text);
  font-family: var(--font-mono), monospace;
  overflow-x: hidden;
  -webkit-font-smoothing: antialiased;
}

/* Subtle industrial micro-grid texture */
.chassis-grid-texture {
  background-image: radial-gradient(var(--chassis-border) 1px, transparent 1px);
  background-size: 24px 24px;
}

/* Brushed metal look */
.brushed-metal {
  background: linear-gradient(135deg, rgba(255,255,255,0.03) 0%, rgba(0,0,0,0.08) 100%);
}
```

Create `src/lib/utils.ts`:
```typescript
import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

Create `src/app/layout.tsx`:
```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ZYKL // Monastic Focus Hardware Instrument",
  description: "A monastic pomodoro instrument inspired by 20th-century German industrial modernism. Offline SQLite, analog chronometer, Braun TP-1 soundscapes.",
  keywords: ["Pomodoro", "Analog Chronometer", "Braun TP-1", "Focus Timer", "Dieter Rams", "Android App"],
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" data-theme="dark" className="dark">
      <head>
        <link rel="icon" href="/images/zykl_icon.png" />
      </head>
      <body className="min-h-screen bg-chassis-bg text-monastic-text selection:bg-monastic-amber selection:text-black">
        {children}
      </body>
    </html>
  );
}
```

- [ ] **Step 5: Copy audio assets and icons into public/**

Commands:
```bash
mkdir -p /home/tuneeca/RSQUARE/Android/zykl.app/public/audio
mkdir -p /home/tuneeca/RSQUARE/Android/zykl.app/public/images
cp "/home/tuneeca/RSQUARE/Android/Takt Desk/assets/audio/vinyl_lofi_rain.wav" /home/tuneeca/RSQUARE/Android/zykl.app/public/audio/
cp "/home/tuneeca/RSQUARE/Android/Takt Desk/assets/audio/vinyl_kyoto_bamboo.wav" /home/tuneeca/RSQUARE/Android/zykl.app/public/audio/
cp "/home/tuneeca/RSQUARE/Android/Takt Desk/assets/audio/vinyl_warm_tape.wav" /home/tuneeca/RSQUARE/Android/zykl.app/public/audio/
cp "/home/tuneeca/RSQUARE/Android/Takt Desk/assets/audio/foley_dial_click.wav" /home/tuneeca/RSQUARE/Android/zykl.app/public/audio/
cp "/home/tuneeca/RSQUARE/Android/Takt Desk/assets/audio/foley_switch_click.wav" /home/tuneeca/RSQUARE/Android/zykl.app/public/audio/
cp "/home/tuneeca/RSQUARE/Android/Takt Desk/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" /home/tuneeca/RSQUARE/Android/zykl.app/public/images/zykl_icon.png
```

- [ ] **Step 6: Build smoke test and commit**

Run: `npm run build`
Expected: Static HTML export generated into `out/` with exit code 0.
Commit:
```bash
git add .
git commit -m "chore: initialize Next.js 15 SSG project with Dieter Rams industrial tokens"
```

---

### Task 2: Data Models & Hardware UI Foundation Components

**Files:**
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/data/changelog.ts`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/data/soundscapes.ts`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/ui/TactileButton.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/ui/RivetPlaque.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/ui/StatusPip.tsx`

**Interfaces:**
- Consumes: Tailwind theme tokens and audio files in `public/audio/`.
- Produces: `changelogData`, `soundscapeTracks`, and reusable tactile hardware UI components for sections.

- [ ] **Step 1: Create changelog.ts & soundscapes.ts**

Create `src/data/changelog.ts`:
```typescript
export interface ChangelogRelease {
  version: string;
  date: string;
  buildNumber: number;
  badgeText: string;
  highlights: string[];
  firmwareDetails: string[];
}

export const changelogData: ChangelogRelease[] = [
  {
    version: "v1.0.4",
    date: "2026-09-17",
    buildNumber: 104,
    badgeText: "CURRENT RELEASE // FIRMWARE STABLE",
    highlights: [
      "Calibrated 3-stage Pomodoro Chronometer setup (Focus, Short Break, Long Break)",
      "Interactive cycle gauge with tactile capsule button and progress pips",
      "Fixed dark mode thermal receipt strikethrough color contrast",
      "Modular dual 6-disc record drawers for soundscapes",
      "Android MediaSessionCompat & persistent background media controller",
    ],
    firmwareDetails: [
      "MOD_CHRONO: Needle movement restricted to 3 active duration sectors; cycle count isolated to dedicated capsule button.",
      "MOD_THERMAL: Set strikethrough decoration to thermalCarbon #1A1A1A across all theme states.",
      "MOD_SECURITY: Strip developer PRO switches and apply R8 ProGuard obfuscation on production builds.",
    ],
  },
  {
    version: "v1.0.3",
    date: "2026-09-15",
    buildNumber: 103,
    badgeText: "PREVIOUS REVISION",
    highlights: [
      "Expanded monastic sound library to 12 procedural focus soundscapes",
      "Added haptic detent clicks for mechanical needle rotation",
      "Integrated SQLite Drift database migrations with zero network dependencies",
    ],
    firmwareDetails: [
      "MOD_AUDIO: 22.05 kHz 16-bit mono sinusoidal crossfade looping engine.",
      "MOD_DATA: Drift SQLite schema v3 with automatic task archival table.",
    ],
  },
  {
    version: "v1.0.2",
    date: "2026-09-13",
    buildNumber: 102,
    badgeText: "REVISION",
    highlights: [
      "Thermal task dispenser with serrated paper tear physics",
      "Physical completed ink stamp action with foley acoustics",
    ],
    firmwareDetails: [
      "MOD_TASK: Enforced 5-task hard cap for monastic mental bandwidth.",
    ],
  },
  {
    version: "v1.0.0",
    date: "2026-09-08",
    buildNumber: 100,
    badgeText: "INITIAL GENESIS",
    highlights: [
      "Initial industrial release inspired by Braun TP-1 and Dieter Rams design principles",
      "Pure analog dial face without distracting digital readouts",
    ],
    firmwareDetails: [
      "MOD_CORE: Kotlin ForegroundService timer engine with exact alarm precision.",
    ],
  },
];
```

Create `src/data/soundscapes.ts`:
```typescript
export interface SoundscapeTrack {
  id: string;
  catalogId: string;
  title: string;
  subtitle: string;
  audioUrl: string;
  bpmOrRpm: string;
  drawer: 1 | 2;
  previewAvailable: boolean;
}

export const soundscapeTracks: SoundscapeTrack[] = [
  {
    id: "lofi-rain",
    catalogId: "TK-01",
    title: "LO-FI RAIN",
    subtitle: "Hydro-acoustic resonance & analog vinyl dust",
    audioUrl: "/audio/vinyl_lofi_rain.wav",
    bpmOrRpm: "33⅓ RPM",
    drawer: 1,
    previewAvailable: true,
  },
  {
    id: "kyoto-bamboo",
    catalogId: "TK-04",
    title: "KYOTO BAMBOO",
    subtitle: "Shishi-odoshi water trickle & wet moss stone",
    audioUrl: "/audio/vinyl_kyoto_bamboo.wav",
    bpmOrRpm: "33⅓ RPM",
    drawer: 1,
    previewAvailable: true,
  },
  {
    id: "warm-tape",
    catalogId: "TK-08",
    title: "WARM TAPE & FELT",
    subtitle: "Muted felt upright piano & analog tape saturation",
    audioUrl: "/audio/vinyl_warm_tape.wav",
    bpmOrRpm: "33⅓ RPM",
    drawer: 2,
    previewAvailable: true,
  },
  {
    id: "brown-noise",
    catalogId: "TK-02",
    title: "DEEP BROWN NOISE",
    subtitle: "Filtered sub-acoustic waterfall roar",
    audioUrl: "",
    bpmOrRpm: "33⅓ RPM",
    drawer: 1,
    previewAvailable: false,
  },
  {
    id: "alpine-brook",
    catalogId: "TK-07",
    title: "ALPINE BROOK",
    subtitle: "Crystalline mountain spring flow",
    audioUrl: "",
    bpmOrRpm: "33⅓ RPM",
    drawer: 2,
    previewAvailable: false,
  },
  {
    id: "zen-bowl",
    catalogId: "TK-09",
    title: "ZEN BOWL",
    subtitle: "Tibetan bronze bowl sustained fundamental",
    audioUrl: "",
    bpmOrRpm: "33⅓ RPM",
    drawer: 2,
    previewAvailable: false,
  },
];
```

- [ ] **Step 2: Create TactileButton.tsx with mechanical click acoustics**

Create `src/components/ui/TactileButton.tsx`:
```tsx
"use client";

import React from "react";
import { motion } from "framer-motion";
import { cn } from "@/lib/utils";

interface TactileButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "danger" | "stealth";
  size?: "sm" | "md" | "lg";
  withAcoustics?: boolean;
  children: React.ReactNode;
}

export const TactileButton: React.FC<TactileButtonProps> = ({
  variant = "primary",
  size = "md",
  withAcoustics = true,
  className,
  children,
  onClick,
  ...props
}) => {
  const playClick = () => {
    if (withAcoustics && typeof window !== "undefined") {
      try {
        const audio = new Audio("/audio/foley_switch_click.wav");
        audio.volume = 0.35;
        audio.play().catch(() => {});
      } catch {}
    }
  };

  const variants = {
    primary:
      "bg-monastic-amber text-black border-monastic-amber hover:bg-[#ffaa22] shadow-[0_3px_0_#b26e00] active:shadow-[0_0_0_transparent] active:translate-y-[3px]",
    secondary:
      "bg-chassis-plate text-monastic-text border-chassis-border hover:border-monastic-amber/50 shadow-[0_3px_0_var(--chassis-border)] active:shadow-[0_0_0_transparent] active:translate-y-[3px]",
    danger:
      "bg-[#A32222] text-white border-[#851B1B] shadow-[0_3px_0_#5C1313] active:shadow-[0_0_0_transparent] active:translate-y-[3px]",
    stealth:
      "bg-transparent text-monastic-muted border-transparent hover:text-monastic-text hover:border-chassis-border",
  };

  const sizes = {
    sm: "px-2.5 py-1 text-xs tracking-wider",
    md: "px-4 py-2 text-sm tracking-wider font-mono font-medium",
    lg: "px-6 py-3.5 text-base tracking-widest font-mono font-semibold",
  };

  return (
    <motion.button
      whileTap={{ scale: 0.98 }}
      onClick={(e) => {
        playClick();
        onClick?.(e);
      }}
      className={cn(
        "relative inline-flex items-center justify-center border transition-all duration-75 uppercase select-none rounded-[2px]",
        variants[variant],
        sizes[size],
        className
      )}
      {...(props as any)}
    >
      {children}
    </motion.button>
  );
};
```

- [ ] **Step 3: Create RivetPlaque.tsx & StatusPip.tsx**

Create `src/components/ui/RivetPlaque.tsx`:
```tsx
import React from "react";
import { cn } from "@/lib/utils";

interface RivetPlaqueProps {
  children: React.ReactNode;
  title?: string;
  telemetry?: string;
  className?: string;
}

export const RivetPlaque: React.FC<RivetPlaqueProps> = ({
  children,
  title,
  telemetry,
  className,
}) => {
  return (
    <div
      className={cn(
        "relative rounded-[3px] border border-chassis-border bg-chassis-surface p-6 brushed-metal shadow-xl",
        className
      )}
    >
      {/* 4 Hex Rivets on Corners */}
      <div className="absolute top-2.5 left-2.5 h-2 w-2 rounded-full border border-chassis-border bg-chassis-rivet/40 flex items-center justify-center">
        <div className="h-0.5 w-1 bg-black/40 rotate-45" />
      </div>
      <div className="absolute top-2.5 right-2.5 h-2 w-2 rounded-full border border-chassis-border bg-chassis-rivet/40 flex items-center justify-center">
        <div className="h-0.5 w-1 bg-black/40 -rotate-45" />
      </div>
      <div className="absolute bottom-2.5 left-2.5 h-2 w-2 rounded-full border border-chassis-border bg-chassis-rivet/40 flex items-center justify-center">
        <div className="h-0.5 w-1 bg-black/40 -rotate-45" />
      </div>
      <div className="absolute bottom-2.5 right-2.5 h-2 w-2 rounded-full border border-chassis-border bg-chassis-rivet/40 flex items-center justify-center">
        <div className="h-0.5 w-1 bg-black/40 rotate-45" />
      </div>

      {(title || telemetry) && (
        <div className="mb-4 flex items-center justify-between border-b border-chassis-border pb-2.5 px-1 text-xs font-mono text-monastic-muted">
          {title && <span className="font-bold tracking-widest text-monastic-text uppercase">{title}</span>}
          {telemetry && <span className="tracking-wider">{telemetry}</span>}
        </div>
      )}

      {children}
    </div>
  );
};
```

Create `src/components/ui/StatusPip.tsx`:
```tsx
import React from "react";
import { cn } from "@/lib/utils";

interface StatusPipProps {
  status?: "nominal" | "warning" | "alert";
  label?: string;
  className?: string;
}

export const StatusPip: React.FC<StatusPipProps> = ({
  status = "nominal",
  label = "NOMINAL",
  className,
}) => {
  const colors = {
    nominal: "bg-monastic-amber shadow-[0_0_8px_#FF9E00]",
    warning: "bg-yellow-400 shadow-[0_0_8px_#FACC15]",
    alert: "bg-red-500 shadow-[0_0_8px_#EF4444]",
  };

  return (
    <div className={cn("inline-flex items-center gap-2 font-mono text-xs text-monastic-muted tracking-widest", className)}>
      <span className={cn("h-2 w-2 rounded-full animate-pulse", colors[status])} />
      <span>{label}</span>
    </div>
  );
};
```

- [ ] **Step 4: Commit UI components**

Run: `npm run build`
Expected: Static build completes with 0 errors.
Commit:
```bash
git add src/data/ src/components/ui/
git commit -m "feat(ui): implement changelog, soundscapes data, and tactile hardware UI components"
```

---

### Task 3: Interactive 3D WebGL Chronometer Engine (`ChronometerCanvas.tsx`)

**Files:**
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/3d/ChronometerCanvas.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/3d/ChronometerMesh.tsx`

**Interfaces:**
- Consumes: Three.js, `@react-three/fiber`, `@react-three/drei`.
- Produces: WebGL 3D Chronometer with real-time ticking needle, tactile bezel, and parallax tilt.

- [ ] **Step 1: Implement ChronometerMesh with Three.js Procedural Geometry**

Create `src/components/3d/ChronometerMesh.tsx`:
- Heavy brushed dark aluminum cylinder bezel.
- Recessed matte dial plate.
- 60 radial tick marks using instanced or procedural meshes (major ticks every 5 units).
- Brass central pin cap.
- Tapered filament amber needle `#FF9E00` that ticks once per second with a mechanical quartic bounce.
- Knurled tactile crown on the top/right side.
- Mouse movement parallax via lerping the group rotation.

- [ ] **Step 2: Implement ChronometerCanvas wrapper with dynamic SSR bypass**

Create `src/components/3d/ChronometerCanvas.tsx`:
- Dynamically imported with `ssr: false` to avoid window/WebGL hydration mismatch.
- Ambient lighting + warm directional key light at `[5, 5, 5]` + rim light.
- Smooth loading fallback plate.

- [ ] **Step 3: Test WebGL canvas in browser / build**

Run: `npm run build`
Expected: Static HTML builds cleanly without any `document is not defined` or `window is not defined` errors.
Commit:
```bash
git add src/components/3d/
git commit -m "feat(3d): implement interactive 3D WebGL chronometer with mechanical ticking needle"
```

---

### Task 4: Interactive 3D WebGL Vinyl Turntable & Audio Preview Player (`VinylCanvas.tsx` & `VinylShowcase.tsx`)

**Files:**
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/3d/VinylCanvas.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/3d/VinylMesh.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/sections/VinylShowcase.tsx`

**Interfaces:**
- Consumes: `soundscapeTracks` from `src/data/soundscapes.ts`, audio files in `/audio/`.
- Produces: Interactive 3D Vinyl Turntable showcase with real-time rotation and browser audio audition player.

- [ ] **Step 1: Implement VinylMesh.tsx in Three.js**

Create `src/components/3d/VinylMesh.tsx`:
- 3D circular vinyl disc with dark grooved material and subtle specular sheen.
- Central circular label with track catalog information (TK-01, TK-04, TK-08).
- Minimalist tonearm with stylus resting on groove.
- Rotation at 33⅓ RPM when playing (`useFrame` increments rotation y).

- [ ] **Step 2: Implement VinylShowcase.tsx audio preview player**

Create `src/components/sections/VinylShowcase.tsx`:
- Header: `[ UNIT 03 // MONASTIC TURNTABLE ]` with `33⅓ RPM MONO DSP`.
- Left: Interactive 3D Vinyl Turntable canvas (`VinylCanvas`).
- Right: Discrete soundscape audition rack (`[ TK-01 LO-FI RAIN ]`, `[ TK-04 KYOTO BAMBOO ]`, `[ TK-08 WARM TAPE ]`).
- Mechanical play/pause toggle with volume slider and live animated frequency spectrum bars.
- Audio foley: plays needle drop sound when track changes.

- [ ] **Step 3: Test audio playback and build**

Run: `npm run build`
Expected: Static build completes with 0 errors.
Commit:
```bash
git add src/components/3d/Vinyl* src/components/sections/VinylShowcase.tsx
git commit -m "feat(vinyl): implement 3D turntable canvas and browser soundscape preview player"
```

---

### Task 5: Masthead, Hero Section & The Instrument Trinity Section

**Files:**
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/sections/Masthead.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/sections/HeroSection.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/sections/InstrumentTrinity.tsx`

**Interfaces:**
- Consumes: `ChronometerCanvas`, `TactileButton`, `StatusPip`, `RivetPlaque`.
- Produces: Complete upper-fold visual hierarchy.

- [ ] **Step 1: Implement Masthead.tsx**

Create `src/components/sections/Masthead.tsx`:
- ZYKL monogram / logotype with industrial knurled lettering.
- Live telemetry badge: `STATUS: NOMINAL // REV 104`.
- Navigation anchor links: `[ INSTRUMENTS ]`, `[ SOUNDSCAPES ]`, `[ SPECS ]`, `[ CHANGELOG ]`, `[ FEEDBACK ]`.
- Tactile rocker theme switch: `DARK (OBSIDIAN)` $\leftrightarrow$ `LIGHT (WARM BONE)` that sets `document.documentElement.setAttribute('data-theme', theme)`.

- [ ] **Step 2: Implement HeroSection.tsx**

Create `src/components/sections/HeroSection.tsx`:
- Micro-badge: `INSTRUMENT DISPATCH // ANDROID 14+`.
- Headline: "Quiet Time. Physical Intent."
- Subtext: "A monastic pomodoro instrument inspired by 20th-century German industrial modernism. No subscriptions, zero accounts, strictly local SQLite."
- Play Store Primary CTA button (`GET ON GOOGLE PLAY`) with brass rivets and tactile elevation.
- Micro telemetry strip: `OFFLINE SQLITE · 22.05kHz DSP · ZERO TRACKERS`.
- Embeds `ChronometerCanvas` with responsive sizing and parallax.

- [ ] **Step 3: Implement InstrumentTrinity.tsx**

Create `src/components/sections/InstrumentTrinity.tsx`:
- **Unit 01 // Analog Chronometer:** Pure dial face without distracting digital numbers; 3-stage calibration engine (Focus, Short Break, Long Break).
- **Unit 02 // Thermal Receipt Dispenser:** Max 5 task physical queue with serrated paper tear and wet ink stamp `[DONE]`.
- **Unit 03 // Monastic Vinyl Turntable:** Braun TP-1 minimalist record player running at 33⅓ RPM with 12 curated procedural soundscapes.

- [ ] **Step 4: Commit Task 5**

Run: `npm run build`
Expected: Static build completes with 0 errors.
Commit:
```bash
git add src/components/sections/Masthead.tsx src/components/sections/HeroSection.tsx src/components/sections/InstrumentTrinity.tsx
git commit -m "feat(hero): assemble Masthead, Hero section with 3D dial, and Instrument Trinity"
```

---

### Task 6: Specs Matrix, System Changelog & Google Play Store Dedicated Hub

**Files:**
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/sections/SpecsMatrix.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/sections/ChangelogSection.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/sections/PlayStoreCta.tsx`

**Interfaces:**
- Consumes: `changelogData` from `src/data/changelog.ts`, `TactileButton`, `RivetPlaque`.
- Produces: Hardware specifications table, revision history log, and dedicated Play Store installation hub with desktop-to-mobile QR scanner.

- [ ] **Step 1: Implement SpecsMatrix.tsx**

Create `src/components/sections/SpecsMatrix.tsx`:
- Clean monospace hardware telemetry table:
  - Architecture: Local Offline SQLite (Drift Engine)
  - Audio Engine: 22,050 Hz 16-Bit Mono PCM with Sinusoidal Crossfade
  - Energy Footprint: < 0.1% CPU wake overhead
  - Background Service: Android Native MediaSessionCompat + ForegroundService
  - Telemetry: Zero third-party trackers, zero advertising SDKs
  - Physical Aesthetic: Braun Atelier / Dieter Rams modernism

- [ ] **Step 2: Implement ChangelogSection.tsx**

Create `src/components/sections/ChangelogSection.tsx`:
- Header: `[ FIRMWARE DISPATCH // REVISION TELEMETRY ]`.
- Maps through `changelogData` (v1.0.4, v1.0.3, v1.0.2, v1.0.0).
- Monospace teletype cards showing release dates, highlights, and technical firmware modifications.
- Expandable details for older revisions.

- [ ] **Step 3: Implement PlayStoreCta.tsx with High-Contrast QR Plate**

Create `src/components/sections/PlayStoreCta.tsx`:
- Heavy anodized steel plate container with corner Allen screws.
- Official Google Play Store button linking to `https://play.google.com/store/apps/details?id=com.zykl.app`.
- Embedded high-contrast SVG QR Code pointing to the Play Store link for desktop users to scan with their Android phones.
- Clear assurance banner: "Play Store Exclusive. Direct APK links are restricted to guarantee cryptographic signature authenticity and prevent tampering."
- Live version indicator: `CURRENT FIRMWARE: v1.0.4 (BUILD 104)`.

- [ ] **Step 4: Commit Task 6**

Run: `npm run build`
Expected: Static build completes with 0 errors.
Commit:
```bash
git add src/components/sections/SpecsMatrix.tsx src/components/sections/ChangelogSection.tsx src/components/sections/PlayStoreCta.tsx
git commit -m "feat(specs): implement engineering matrix, changelog teletype, and Play Store QR hub"
```

---

### Task 7: Serverless Thermal Receipt Feedback Terminal & Colophon Footer

**Files:**
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/sections/FeedbackTerminal.tsx`
- Create: `/home/tuneeca/RSQUARE/Android/zykl.app/src/components/sections/ColophonFooter.tsx`

**Interfaces:**
- Consumes: Google Sheets Webhook endpoint configuration, `TactileButton`.
- Produces: Physical thermal receipt feedback form and Dieter Rams colophon footer.

- [ ] **Step 1: Implement FeedbackTerminal.tsx (Google Sheets Dispatch)**

Create `src/components/sections/FeedbackTerminal.tsx`:
- Container styled as a continuous roll of thermal receipt paper with serrated cut marks.
- Inputs:
  - Call-sign / Email (optional)
  - Category: `[ BUG REPORT ]`, `[ HARDWARE FEATURE ]`, `[ SOUNDSCAPE REQUEST ]`
  - Transmission / Feedback notes
- Submission handler:
  - Posts payload `{ timestamp, callSign, category, notes, userAgent }` directly to Google Apps Script Web App URL via `fetch(webhookUrl, { method: "POST", mode: "no-cors", ... })`.
  - Fallback: Gracefully handles unconfigured URL by storing locally or notifying the user with simulated print confirmation.
  - Tactile print animation with paper feed sound effect on dispatch.
- Includes Google Apps Script instructions in a foldout for quick deployment to user's Google Sheet.

- [ ] **Step 2: Implement ColophonFooter.tsx**

Create `src/components/sections/ColophonFooter.tsx`:
- Minimalist industrial colophon.
- Dieter Rams tenet quote: *"Weniger, aber besser"* (Less, but better).
- Attribution to 20th-century German industrial design.
- Zero GitHub links. Clean standalone copyright notice.

- [ ] **Step 3: Assemble all sections in page.tsx**

Edit `src/app/page.tsx`:
Assemble:
- `Masthead`
- `HeroSection`
- `InstrumentTrinity`
- `VinylShowcase`
- `SpecsMatrix`
- `ChangelogSection`
- `PlayStoreCta`
- `FeedbackTerminal`
- `ColophonFooter`

- [ ] **Step 4: Commit Task 7**

Run: `npm run build`
Expected: Static export builds cleanly.
Commit:
```bash
git add src/components/sections/FeedbackTerminal.tsx src/components/sections/ColophonFooter.tsx src/app/page.tsx
git commit -m "feat(feedback): implement thermal receipt feedback terminal and assemble page"
```

---

### Task 8: End-to-End Verification, Responsive Polish & Static Export Production Build

**Files:**
- Modify: `/home/tuneeca/RSQUARE/Android/zykl.app/src/app/globals.css` (if any styling refinements needed)
- Modify: `/home/tuneeca/RSQUARE/Android/zykl.app/README.md`

**Interfaces:**
- Consumes: Complete assembled site in `/home/tuneeca/RSQUARE/Android/zykl.app/`.
- Produces: Verified static build in `out/`, verified 0 occurrences of `tuneeca`, verified dark/light theme switching, and deployment guide.

- [ ] **Step 1: Test Theme Switching & Mobile Viewports**

Verify that:
- Dark theme (`Obsidian`) and Light theme (`Warm Bone`) render accurately.
- 3D canvases adapt on smaller screens without horizontal scrollbar overflow.
- Audio player functions smoothly.

- [ ] **Step 2: Verify zero occurrences of tuneeca**

Run:
```bash
grep -rn "tuneeca" /home/tuneeca/RSQUARE/Android/zykl.app/src/ || true
```
Expected: 0 matches found.

- [ ] **Step 3: Run production build and verify out/ directory**

Run:
```bash
cd /home/tuneeca/RSQUARE/Android/zykl.app && npm run build
ls -la out/
```
Expected: `index.html`, static assets, and `out/` created with exit code 0.

- [ ] **Step 4: Write README.md with Google Sheets Webhook setup instructions**

Create `/home/tuneeca/RSQUARE/Android/zykl.app/README.md` documenting:
- Architecture & tech stack.
- How to deploy static build to Cloudflare Pages / Vercel.
- 5-line Google Apps Script template for the Google Sheets feedback endpoint.

- [ ] **Step 5: Final commit**

Commit:
```bash
git add .
git commit -m "release: finalize zykl.app SSG landing page with 3D WebGL instruments and Google Sheets terminal"
```
