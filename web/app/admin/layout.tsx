import type { Metadata } from 'next';
import { Toaster } from '@/components/admin/toaster';

export const metadata: Metadata = {
  title: 'Sokabrain Admin',
  robots: { index: false, follow: false },
};

/**
 * Wraps both the sign-in page and the console. The toaster lives here, above
 * both, so a notice raised just before a navigation is still on screen after.
 */
export default function AdminRootLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      {children}
      <Toaster />
    </>
  );
}
