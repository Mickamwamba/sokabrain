import { prisma } from '../db.js';

interface SeedThread {
  title: string;
  content: string;
  author_name: string;
  author_team_name: string;
  tag: string;
  likes_count: number;
  comments: {
    author_name: string;
    author_team_name: string;
    content: string;
    likes_count: number;
  }[];
}

interface SeedSpace {
  slug: string;
  name_sw: string;
  name_en: string;
  description_sw: string;
  description_en: string;
  icon: string;
  badge_color: string;
  display_order: number;
  threads: SeedThread[];
}

const SEED_SPACES: SeedSpace[] = [
  {
    slug: 'kariakoo-derby',
    name_sw: 'Kijiwe cha Kariakoo',
    name_en: 'Kariakoo Derby Corner',
    description_sw:
      'Makao makuu ya utani wa jadi. Simba na Yanga, ubishi wa vikombe, takwimu na tambo za watani wa jadi.',
    description_en:
      'The traditional rivalry hub. Simba vs Yanga debates, historical head-to-head stats, and bragging rights.',
    icon: '🔥',
    badge_color: 'from-amber-500 to-rose-600',
    display_order: 1,
    threads: [
      {
        title: 'Hivi Yanga ya sasa inaweza kufikia rekodi ya unbeaten ya Simba au ni nguvu ya soda?',
        content:
          'Kila mtu anasifia ubora wa kikosi cha Yanga cha misimu mitatu hii. Lakini tukumbuke Simba waliwahi kuweka rekodi ya kutofungwa msimu mzima bila kupoteza mchezo hata mmoja. Je, Yanga wana nidhamu ya mbinu kufikia kiwango kile, au mechi za ugenini zitawavunja?',
        author_name: 'Mnyama_Original',
        author_team_name: 'Simba SC',
        tag: 'UBISHI',
        likes_count: 24,
        comments: [
          {
            author_name: 'Utopolo_Pro_Max',
            author_team_name: 'Young Africans',
            content:
              'Nyie endeleeni kuishi kwa kumbukumbu za zamani, sisi tunajenga kabati jipya la mataji! Takwimu za sasa ziko wazi nani anatawala soka la Bongo.',
            likes_count: 18,
          },
          {
            author_name: 'Mchambuzi_Kijiweni',
            author_team_name: 'Azam FC',
            content:
              'Ukweli ni kwamba mechi za mikoani (Kagera, Mbeya, Singida) ndizo zitaamua. Hakuna timu inayoweza kutamba kirahisi ugenini msimu huu.',
            likes_count: 9,
          },
          {
            author_name: 'Fundi_Wa_Msimbazi',
            author_team_name: 'Simba SC',
            content: 'Ngoja tuone dabi ya mzunguko wa pili ndo jibu litapatikana uwanjani!',
            likes_count: 7,
          },
        ],
      },
      {
        title: 'Bora kati ya Fiston Mayele na Meddie Kagere: Nani straika hatari zaidi aliyewahi kutua VPL?',
        content:
          'Kagere alifunga mabao muhimu sana kwa misimu miwili mfululizo na kubeba viatu vya ufungaji bora. Mayele akaja na style yake ya kutetema na kufunga mabao ya maamuzi. Nani alikuwa tishio zaidi kwa mabeki wa ligi?',
        author_name: 'Kariakoo_Tactics',
        author_team_name: 'Young Africans',
        tag: 'MBINU',
        likes_count: 31,
        comments: [
          {
            author_name: 'Bocco_Fan',
            author_team_name: 'Simba SC',
            content:
              'Kagere alikuwa mnyama ndani ya 18! Hata akipata nusu nafasi ilikuwa goli. Mayele alikuwa mzuri pia lakini Kagere alikuwa mtulivu zaidi kwenye mechi kubwa.',
            likes_count: 14,
          },
          {
            author_name: 'Tetema_Nation',
            author_team_name: 'Young Africans',
            content:
              'Mayele hakuwa anafunga tu, alikuwa anatesa safu nzima ya ulinzi na kutoa pasi za mwisho. Yule jamaa alikuwa complete striker.',
            likes_count: 22,
          },
        ],
      },
    ],
  },
  {
    slug: 'ligi-kuu',
    name_sw: 'Kijiwe cha Ligi Kuu',
    name_en: 'Premier League Hub',
    description_sw:
      'Mbio za ubingwa, matokeo ya kushtukiza, ufundi wa makocha na msimamo wa NBC Premier League na ligi za ukanda mzima.',
    description_en:
      'Title race analysis, surprise upsets, coach tactics, and regional East African standings.',
    icon: '🏆',
    badge_color: 'from-emerald-500 to-teal-600',
    display_order: 2,
    threads: [
      {
        title: 'Singida Black Stars wanatishia Top 3 msimu huu au ni nguvu ya soda ya mwanzoni?',
        content:
          'Uwekezaji uliofanyika Singida Black Stars siyo wa kitoto. Usajili wao na namna wanavyocheza soka la kasi ugenini na nyumbani inatia hofu kwa Azam na Simba. Je, wana uwezo wa kudumu kwenye mbio hizi hadi raundi ya 30?',
        author_name: 'Mkulima_Wa_Singida',
        author_team_name: 'Singida Black Stars',
        tag: 'UBISHI',
        likes_count: 19,
        comments: [
          {
            author_name: 'Azam_Complex_Loyal',
            author_team_name: 'Azam FC',
            content:
              'Ligi ni marathon siyo mbio za mita 100. Kikosi chetu kina depth ya kutosha. Singida wataanza kuchoka mechi zikibana mwezi Novemba.',
            likes_count: 11,
          },
          {
            author_name: 'Soka_Data_Guru',
            author_team_name: 'Coastal Union',
            content:
              'Takwimu zinaonyesha timu inayotoka nje ya Dar ikikusanya alama 25 katika mechi 10 za kwanza huingia Top 4 kwa uhakika wa 85%. Singida wana mwendo mzuri sana.',
            likes_count: 15,
          },
        ],
      },
      {
        title: 'Utabiri: Nani atashuka daraja msimu huu kati ya timu zilizo chini?',
        content:
          'Tofauti ya alama kati ya nafasi ya 12 na 16 ni ndogo sana. Kagera Sugar, Pamba Jiji na Dodoma Jiji wote wanapambana. Weka utabiri wako hapa bila upendeleo.',
        author_name: 'Mchambuzi_Hururu',
        author_team_name: 'Kagera Sugar',
        tag: 'UTABIRI',
        likes_count: 12,
        comments: [
          {
            author_name: 'Pamba_Nguvu_Moja',
            author_team_name: 'Pamba Jiji',
            content: 'Nyamagana hatoki mtu! Pamba tutabaki Ligi Kuu, uwanja wa nyumbani ndio ngome yetu.',
            likes_count: 8,
          },
        ],
      },
    ],
  },
  {
    slug: 'kahawa-joint',
    name_sw: 'Kahawa Joint & Chombeza',
    name_en: 'Kahawa Joint & Banter',
    description_sw:
      'Vicheko, utani wa mashabiki, meme za soka, na ubishi mwepesi usio na hasira. Kaa chini unywe kahawa.',
    description_en:
      'Fan banter, hilarious memes, lighthearted banter, and weekend predictions over local coffee.',
    icon: '☕',
    badge_color: 'from-amber-600 to-orange-700',
    display_order: 3,
    threads: [
      {
        title: 'Utabiri wa wikendi hii: Nani atalala na viatu kati ya Simba na Azam?',
        content:
          'Kahawa imeshachemka hapa kijiweni. Kila mtu anatamba na kikosi chake. Mashabiki wa Azam wanadai chamazi hakuna njia, lakini Mnyama anasema hajawahi kufeli mechi za ufunguzi wa mwezi. Tupia tabiri yako ya magoli!',
        author_name: 'Kaka_Kahawa',
        author_team_name: 'Simba SC',
        tag: 'CHOMBEZA',
        likes_count: 42,
        comments: [
          {
            author_name: 'Drip_Ya_Chamazi',
            author_team_name: 'Azam FC',
            content: 'Azam 2 - 1 Simba. Feisal Salum anapiga bao la kideoni dakika ya 75. Weka hii akilini.',
            likes_count: 20,
          },
          {
            author_name: 'Mzee_Wa_Kona',
            author_team_name: 'Young Africans',
            content: 'Sisi tunatamani watoke sare ya 0-0 wote wagawane pointi moja moja ili kileleni kubaki kuko safi!',
            likes_count: 35,
          },
        ],
      },
      {
        title: 'Jezi kali zaidi ya msimu huu: Ni jezi gani imefunika viwanjani?',
        content:
          'Kuanzia uzi wa kijani na njano wa Wananchi, uzi mwekundu wa Msimbazi, hadi uzi mpya wa Singida na Namungo. Ni jezi gani ukiona mtaani inavutia zaidi?',
        author_name: 'Mtindo_Wa_Soka',
        author_team_name: 'Young Africans',
        tag: 'CHOMBEZA',
        likes_count: 17,
        comments: [
          {
            author_name: 'Kibandani_FC',
            author_team_name: 'Coastal Union',
            content: 'Uzi wa Coastal Union wa nyumbani (Wagosi wa Kaya) una ubunifu mkubwa sana msimu huu!',
            likes_count: 13,
          },
        ],
      },
    ],
  },
  {
    slug: 'taifa-kimataifa',
    name_sw: 'Kijiwe cha Taifa & CAF',
    name_en: 'National Stars & CAF Corner',
    description_sw:
      'Umoja wa Taifa Stars, Harambee Stars, na michuano mikubwa ya CAF Champions League na Kombe la Shirikisho.',
    description_en:
      'Support for Taifa Stars, Harambee Stars, and regional clubs conquering the CAF continental stage.',
    icon: '🌍',
    badge_color: 'from-blue-600 to-indigo-700',
    display_order: 4,
    threads: [
      {
        title: 'Je, vilabu vyetu vina uwezo wa kucheza Fainali ya CAF Champions League msimu huu?',
        content:
          'Kila mwaka tunafika robo fainali na kuishia hapo kwa tofauti ndogo za uzoefu dhidi ya Waarabu (Al Ahly, Mamelodi Sundowns, ES Tunis). Ni kipi kinachokosekana sasa hivi ili kuingia hatua ya fainali na kubeba taji?',
        author_name: 'Balozi_Wa_Soka',
        author_team_name: 'Tanzania',
        tag: 'MBINU',
        likes_count: 29,
        comments: [
          {
            author_name: 'Afcon_Veteran',
            author_team_name: 'Tanzania',
            content:
              'Kinachokosekana ni uimara wa safu ya ulinzi mechi za ugenini. Nyumbani tunacheza vizuri sana mbele ya mashabiki 60,000, lakini ugenini tunarudi nyuma sana.',
            likes_count: 16,
          },
          {
            author_name: 'Harambee_Brother',
            author_team_name: 'Kenya',
            content:
              'Kama mshabiki wa Kenya, lazima niseme soka la Tanzania linazidi kupaa. Ushindani wa Simba na Yanga kimataifa unaleta heshima kubwa kwa ukanda wetu wa CECAFA.',
            likes_count: 27,
          },
        ],
      },
    ],
  },
];

export async function seedKijiweni() {
  console.log('Seeding Kijiweni spaces, threads, and comments...');

  for (const space of SEED_SPACES) {
    const existing = await prisma.kijiwe_spaces.findUnique({
      where: { slug: space.slug },
    });

    const spaceRow = existing
      ? await prisma.kijiwe_spaces.update({
          where: { slug: space.slug },
          data: {
            name_sw: space.name_sw,
            name_en: space.name_en,
            description_sw: space.description_sw,
            description_en: space.description_en,
            icon: space.icon,
            badge_color: space.badge_color,
            display_order: space.display_order,
          },
        })
      : await prisma.kijiwe_spaces.create({
          data: {
            slug: space.slug,
            name_sw: space.name_sw,
            name_en: space.name_en,
            description_sw: space.description_sw,
            description_en: space.description_en,
            icon: space.icon,
            badge_color: space.badge_color,
            display_order: space.display_order,
          },
        });

    console.log(`✓ Space: ${spaceRow.name_sw} (${spaceRow.slug})`);

    for (const t of space.threads) {
      const existingThread = await prisma.kijiwe_threads.findFirst({
        where: { kijiwe_id: spaceRow.id, title: t.title },
      });

      if (!existingThread) {
        const thread = await prisma.kijiwe_threads.create({
          data: {
            kijiwe_id: spaceRow.id,
            title: t.title,
            content: t.content,
            author_name: t.author_name,
            author_team_name: t.author_team_name,
            tag: t.tag,
            likes_count: t.likes_count,
            comments_count: t.comments.length,
          },
        });

        for (const c of t.comments) {
          await prisma.kijiwe_comments.create({
            data: {
              thread_id: thread.id,
              author_name: c.author_name,
              author_team_name: c.author_team_name,
              content: c.content,
              likes_count: c.likes_count,
            },
          });
        }
        console.log(`  + Thread: "${thread.title.slice(0, 40)}..." (${t.comments.length} comments)`);
      }
    }
  }

  console.log('✓ Kijiweni seed complete!');
}

// Run standalone if invoked via CLI
if (import.meta.url === `file://${process.argv[1]}`) {
  seedKijiweni()
    .catch((err) => {
      console.error('Seed error:', err);
      process.exit(1);
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
