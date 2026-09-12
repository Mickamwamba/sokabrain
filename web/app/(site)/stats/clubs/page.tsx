import { TeamStatsPage } from "@/components/team-stats-page";
import { isClubEdition } from "@/lib/scope";

export const dynamic = "force-dynamic";

export default async function ClubsPage(props: PageProps<"/stats/clubs">) {
  return (
    <TeamStatsPage
      searchParams={props.searchParams}
      teamType="CLUB"
      basePath="/stats/clubs"
      noun="Club"
      nounPlural="Clubs"
      only={isClubEdition}
    />
  );
}
