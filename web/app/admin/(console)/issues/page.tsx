import { redirect } from 'next/navigation';

/**
 * The Issues page became Data audit. Old links and bookmarks still land in the
 * right place, carrying the season they pointed at.
 */
export default async function IssuesMoved(props: PageProps<'/admin/issues'>) {
  const sp = await props.searchParams;
  const edition = Array.isArray(sp.editionId) ? sp.editionId[0] : sp.editionId;
  redirect(edition ? `/admin/audit?editionId=${encodeURIComponent(edition)}` : '/admin/audit');
}
