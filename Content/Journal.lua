local _, W = ...
local C, L = W.Content, W.L

C.journal = {
    ranks = 20,
    xpPerRank = 150,
    bonusEveryXP = 200,
    dailyXP = 40,
    weeklyXP = 150,
    bonusXP = 40,
    achievementXP = 50,
}
C.contracts = {
    { id = "quest", name = L.JOURNAL_QUESTS, daily = 5, weekly = 25, icon = "INV_Misc_Note_01" },
    {
        id = "kill",
        name = L.JOURNAL_KILLS,
        daily = 30,
        weekly = 150,
        icon = "Ability_Warrior_BattleShout",
    },
    { id = "explore", name = L.JOURNAL_EXPLORE, daily = 3, weekly = 8, icon = "INV_Misc_Map_01" },
    { id = "gather", name = L.JOURNAL_GATHER, daily = 10, weekly = 50, icon = "Trade_Mining" },
    {
        id = "boss",
        name = L.JOURNAL_BOSSES,
        daily = 1,
        weekly = 5,
        icon = "INV_Misc_Head_Dragon_01",
    },
    { id = "dungeon", name = L.JOURNAL_DUNGEONS, daily = 1, weekly = 3, icon = "INV_Misc_Key_14" },
}
C.contractByID = {}
for _, contract in ipairs(C.contracts) do
    C.contractByID[contract.id] = contract
end
C.journalTitles = {
    { rank = 5, name = L.JOURNAL_TITLE_5, icon = "INV_Misc_Map_01" },
    { rank = 10, name = L.JOURNAL_TITLE_10, icon = "INV_Misc_Book_09" },
    { rank = 15, name = L.JOURNAL_TITLE_15, icon = "INV_Misc_Head_Dragon_01" },
    { rank = 20, name = L.JOURNAL_TITLE_20, icon = "INV_BannerPVP_02" },
}
C.journalAchievements = {
    { id = "companions", name = L.JOURNAL_A_COMPANIONS, metric = "heroes", target = 2 },
    { id = "company", name = L.JOURNAL_A_COMPANY, metric = "heroes", target = 5 },
    { id = "frontier", name = L.JOURNAL_A_FRONTIER, metric = "best", target = 10 },
    { id = "summit", name = L.JOURNAL_A_SUMMIT, metric = "best", target = 60 },
    { id = "artisan", name = L.JOURNAL_A_ARTISAN, metric = "crafted", target = 1 },
    { id = "heirloom", name = L.JOURNAL_A_HEIRLOOM, metric = "heirloom", target = 1 },
    { id = "chapter", name = L.JOURNAL_A_CHAPTER, metric = "prestiges", target = 1 },
    { id = "service", name = L.JOURNAL_A_SERVICE, metric = "quest", target = 10 },
    { id = "veteran", name = L.JOURNAL_A_VETERAN, metric = "quest", target = 100 },
    { id = "traveler", name = L.JOURNAL_A_TRAVELER, metric = "explore", target = 5 },
    { id = "contracts", name = L.JOURNAL_A_CONTRACTS, metric = "contracts", target = 10 },
    { id = "journal", name = L.JOURNAL_A_JOURNAL, metric = "rank", target = 20 },
}
