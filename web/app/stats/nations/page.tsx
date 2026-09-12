import { TeamStatsPage } from "@/components/team-stats-page";
import { isNationalTeamEdition } from "@/lib/scope";

export const dynamic = "force-dynamic";

/**
 * National teams, ranked apart from clubs.
 *
 * Publishing AFCON put 43 countries into a table headed "Club stats" next to
 * Yanga and Simba. They are separate pages now because the two are not
 * comparable — a nation plays three group matches every other year.
 */
export default async function NationsPage(props: PageProps<"/stats/nations">) {
  return (
    <TeamStatsPage
      searchParams={props.searchParams}
      teamType="NATIONAL"
      basePath="/stats/nations"
      noun="Nation"
      nounPlural="Nations"
      only={isNationalTeamEdition}
    />
  );
}
