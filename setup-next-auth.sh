#!/bin/bash

echo "Setting up authentication for your Next.js project..."

# Prompt user for Google Client ID
read -p "Enter your Google Client ID: " GOOGLE_CLIENT_ID
read -p "Enter your Google Client Secret: " GOOGLE_CLIENT_SECRET

# Set environment variables in .env
echo "Updating .env file..."
cat <<EOL > .env
GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
GOOGLE_CLIENT_SECRET=$GOOGLE_CLIENT_SECRET
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=$(openssl rand -base64 32)
EOL
echo ".env file updated."

# Ensure necessary directories exist
mkdir -p src/app/api/auth/[...nextauth] src/app src/components

# Modify app/layout.tsx
echo "Updating app/layout.tsx..."
LAYOUT_FILE="src/app/layout.tsx"
if ! grep -q 'import { Providers } from "./providers";' "$LAYOUT_FILE"; then
  sed -i '1s|^|import { Providers } from "./providers";\n|' "$LAYOUT_FILE"
fi

if ! grep -q '<Providers> {children} </Providers>' "$LAYOUT_FILE"; then
  sed -i 's|{children}|<Providers> {children} </Providers>|' "$LAYOUT_FILE"
fi
echo "Updated app/layout.tsx."

# Create providers.tsx
echo "Creating providers.tsx..."
cat <<EOL > src/app/providers.tsx
"use client";

import { SessionProvider } from "next-auth/react";

export function Providers({ children }: { children: React.ReactNode }) {
  return <SessionProvider>{children}</SessionProvider>;
}
EOL
echo "Created providers.tsx."

# Create NextAuth API route
echo "Creating NextAuth route..."
cat <<EOL > src/app/api/auth/[...nextauth]/route.ts
import NextAuth from "next-auth";
import GoogleProvider from "next-auth/providers/google";

const handler = NextAuth({
    providers: [
        GoogleProvider({
          clientId: process.env.GOOGLE_CLIENT_ID ?? "",
          clientSecret: process.env.GOOGLE_CLIENT_SECRET ?? ""
        })
    ]
});

export { handler as GET, handler as POST };
EOL
echo "Created NextAuth API route."

# Create AuthButtons component
echo "Creating AuthButtons component..."
cat <<EOL > src/components/AuthButtons.tsx
"use client";
import { signIn, signOut, useSession } from "next-auth/react";
import { useEffect, useState } from "react";

const AuthButtons = () => {
  const session = useSession();
  const [signedIn, setSignedIn] = useState(false);

  useEffect(() => {
    if (session.data?.user) {
      setSignedIn(true);
    }
  }, [session]);

  return (
    <>
      {!signedIn ? (
        <div className="w-max h-max px-3 py-1 rounded bg-blue-500 cursor-pointer" onClick={() => signIn()}>
          Sign in
        </div>
      ) : (
        <div className="w-max h-max px-3 py-1 rounded bg-yellow-500 cursor-pointer" onClick={() => signOut()}>
          Sign Out
        </div>
      )}
    </>
  );
};

export default AuthButtons;
EOL
echo "Created AuthButtons component."

# Install NextAuth
echo "Installing next-auth..."
npm install next-auth
echo "next-auth installed successfully."

echo "✅ Setup complete! You can now run 'npm run dev' to start your project."
