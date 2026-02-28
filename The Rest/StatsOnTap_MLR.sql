--2024
--Position based on starting number (1-15)
Drop table if exists #improved
Select ma.Rnd
    , ma.Match_ID
    , ma.Team
    , ma.Player
    , ma.Points
    , ma.Number
    , Case when ma.Number in (1,2,3) then 'FR'
        when ma.Number in (4,5) then 'SR'
        when ma.Number in (6,7,8) then 'BR'
        when ma.Number in (9) then 'SH'
        when ma.Number in (10) then 'FH'
        when ma.Number in (12,13) then 'C'
        when ma.Number in (11,14,15) then 'B3'
        when ma.Number in (24) then 'DSP'
        when ma.Number between 16 and 23 then 'Bench'
        end as Pos
    , Case when ma.Number in (1,2,3) then 1
        when ma.Number in (4,5) then 2
        when ma.Number in (6,7,8) then 3
        when ma.Number in (9) then 4
        when ma.Number in (10) then 5
        when ma.Number in (12,13) then 6
        when ma.Number in (11,14,15) then 7
        when ma.Number in (24) then 8
        when ma.Number between 16 and 23 then 9
        end as Pos_Ordering
Into #improved
From Scratchdb_Research.[NM\NM287071].MLR2024API ma


--Matchups schedule
Drop table if exists #matchups
Select *
Into #matchups
From Scratchdb_Research.[NM\NM287071].MLR2024matchups





--Main table
Drop table if exists #main

Select distinct *
Into #main
From(
    Select i.Match_ID
        , i.Rnd
        , i.Number
        , i.Pos_Ordering
        , i.Pos
        , i.Team
        , Case when player like '%alikhan%' then 'Makeen Alikham' 
                when player like '%Juan Dee%' then 'Juan Dee Olivier' 
                else i.Player end as Player
        , i.Points
        , Case when i.Team = m.VisitorTeam then 'Away'
            when i.team = m.HomeTeam then 'Home'
            end as home_away
        , Case when i.Team = m.VisitorTeam then m.HomeTeam
            when i.Team = m.HomeTeam then m.VisitorTeam
            end as Opp
        , Case when i.Number between 1 and 8 then 'Forward'
            when i.Number between 9 and 15 then 'Back'
            when i.Number between 6 and 23 then 'Bench'
            when i.Number = 24 then 'aDSP'
            end as flex_pos
        , Case when i.Team = m.VisitorTeam and m.VisitorScore > m.HomeScore then 'W'
            when  i.Team = m.VisitorTeam and m.VisitorScore < m.HomeScore then 'L'
            when  i.Team = m.HomeTeam and m.HomeScore > m.VisitorScore then 'W'
            when  i.Team = m.HomeTeam and m.HomeScore < m.VisitorScore then 'L'
            when m.HomeScore = m.VisitorScore then 'T'
            end as Result
    From #improved i
        join #matchups m
            on i.Rnd = m.Rnd
) x
Where x.Opp is not null
Order by 1, Points desc, Player desc

--Avg for position against Opp
--Drop table if exists #avg_points
Select *
--Into #avg_points
From(
    Select x.Pos_Ordering
        , x.Pos
        , x.Opp
        , cast(avg(Points) as decimal(5,3)) as avg_points
    From(
        Select i.Pos
            , Case when i.Team = m.VisitorTeam then m.HomeTeam
                when i.Team = m.HomeTeam then m.VisitorTeam
                end as Opp
            , i.Points
            , i.Pos_Ordering
        From #main i
            join #matchups m
                on m.Rnd = i.Rnd
        --Where Pos != 'Bench'
    ) x
    Where Opp is not null
    Group by Pos_ordering, Pos, Opp
) y

Pivot(max(avg_points) for Opp in(
        [ARC]
        , [CHI]
        , [DAL]
        , [HOU]
        , [LA]
        , [MIA]
        , [NEFJ]
        , [NOLA]
        , [OGDC]
        , [SDL]
        , [SEA]
        , [UTAH]
    --[FR]
    --, [SR]
    --, [BR]
    --, [SH]
    --, [FH]
    --, [C]
    --, [B3]
    --, [DSP]
    --, [Bench]
)) p
Order by 1




--Avg for position on a Team
--Drop table if exists #avg_points
Select *
--Into #avg_points
From(
    Select x.Pos_Ordering
        , x.Pos
        , x.Team
        , cast(avg(Points) as decimal(5,3)) as avg_points
    From(
        Select distinct i.Rnd
            , i.Team
            , i.Pos
            , i.Points
            , i.Pos_Ordering
        From #main i
            join #matchups m
                on m.Rnd = i.Rnd
        --Where Pos != 'Bench'
    ) x
    Group by Pos_ordering, Team, Pos
) y

Pivot(max(avg_points) for Team in(
        [ARC]
        , [CHI]
        --, [DAL]
        , [HOU]
        , [LA]
        , [MIA]
        , [NEFJ]
        , [NOLA]
        , [OGDC]
        , [SDL]
        , [SEA]
        , [UTAH]
    --[FR]
    --, [SR]
    --, [BR]
    --, [SH]
    --, [FH]
    --, [C]
    --, [B3]
    --, [DSP]
    --, [Bench]
)) p
Order by 1



Select Team
    , avg(Points) points_avg
From(
    Select Rnd
        , Pos
        , Team
        , Points
    From #main
    Where pos = 'DSP'
    and Team = 'CHI'
) x
Group by Team
Order by points_avg desc


--Excel printout
Declare @finished_round as int = 17
--Player score printout for Excel --DUPLICATES?
Select distinct Rnd
    , Team
    , Player
    , Points
    , home_away
    , Opp
From(
    Select distinct Rnd
            , Pos
            , Team
            , Player
            , Case when Points is not null then Points
                else null end as Points
            , home_away
            , Opp
    From #main i
    Where Rnd = @finished_round

    
    UNION

    --Futures printout
    Select distinct ma.Rnd
        , m.Pos
        , m.Team
        , m.Player
        , null as points_empty
        , case when m.Team = ma.HomeTeam then 'Home'
            else 'Away' end as proj_homeaway
        , case when m.Team = ma.HomeTeam then VisitorTeam 
            else HomeTeam end as Proj_Opp
    From #matchups ma
        left join #main m
            on (ma.HomeTeam = m.Team
            or ma.VisitorTeam = m.Team)
    and ma.Rnd > @finished_round
) x
--Where Pos in ('FR','SR','BR') --Forwards --not working
--Where Pos in ('SH','FH','C','B3') --Backs
Where x.pos = 'FR' --Position
Order by 1, Points desc, 2



--Rankings printout
Select Rnd
    , Pos
    , Player
    , Points
    , home_away
    , Team
    , Opp
    --, Result
From #main
--Where Pos in ('FR','SR','BR')
--Where Pos in ('SH','FH','C','B3')
--Where Pos != 'Bench'
--Where pos = 'SR'
Order by 1, 2, 3, 4

--Player Finder
Select Player, avg(Points)
From(
    Select distinct Rnd
                , Player
                , Pos
                , TEAM
                , Opp
                , cast(Points as decimal(5,1)) as Points
    From #main 
    Where player like '%thiebes%'
    --Where Pos like 'SH'
    --and Rnd = 6
    --and Opp = 'ARC'
    --Order by rnd
) x
Group by Player
--Order by Rnd, Player

Select *
From(
    Select player, Rnd, Points --could add pos to this
    From #main m
    Where (m.player like '%sitgh%'
    or m.player like '%manson%'
    or m.player like '%Fidow%'
    or m.player like '%windsor%'
    or m.player like '%danyon%')
    and Rnd >=6
) x
pivot(max(points) for rnd in (
    --[1]
    --,[2]
    --,[3]
    --,[4]
    --,[5]
    [6]
    ,[7]
    ,[8]
    ,[9]
    , [10]
    , [11]
)) p

--TEMP
Select *
From #main
Where player like '%tusit%'
order by Rnd

--FR compared to DSP

Select *
From(
    Select distinct Match_ID 
        , Pos
        , avg(Points) as avg_points
    From #main i
    Where Pos in ('DSP', 'FR')
    Group by Match_ID
        , Pos
) x
Pivot(max(avg_Points) for Pos in(
    [DSP]
    , [FR]
))p
Order by Match_ID



Select Pos, avg(Points) as avg_points
From #main
Group by Pos
Order by avg_points Desc

--Sanity check
Select *--avg(Points)
From #main m
Where Pos = 'SH'
and Opp = 'ARC'


--Printout for ML KNIME workflow
Select *
From #main


--TEST
Select *
From #main
Where player like '%mattina%'


--------------
---REQUESTS---
--------------

------------------------------------------------
--Number related to Scoring
------------------------------------------------
Select Number, avg(points)
From #main
Group by Number
Order by Number

Select Number, Player, avg(Points) as avg_points, count(player) as games_played
From #main where Number in (4,5)
Group by Number, Player
Order by avg_points desc


------------------------------------------------
--"Consistency Rating", what % of time they start position are they above average at that position
--work on Top 50%, 25%, 10%, Leader?
--Skipping Bench, it's a Wild West out there: Select count distinct player per round for pos bench
------------------------------------------------

--Finished version here:
Drop table if exists #consistency
Select *
Into #Consistency
From Scratchdb_Research.[NM\NM287071].MLR2024Consistency


--% of matches played <0, 0-5, 5.1-10, 10.1-15, 15.1-20, 20.1+
--Overall, by position


Drop table if exists #count_players_per_Rnd

--Select *
--From(
Select Rnd
    , Pos
    , Count(distinct player) as count_players_that_Rnd
Into #count_players_per_Rnd
From #main
Group by Rnd
    , Pos
--) x
--Pivot(max(count_players_that_Rnd) for Pos in (
--    [B3]
--    --, [Bench]
--    , [BR]
--    , [C]
--    , [DSP]
--    , [FH]
--    , [FR]
--    , [SH]
--    , [SR]
--))p

--each missing 1 person, work on that later
--DSP week 2/3
--SR week 9
--FR Rnd 14
--BR Rnk 13

--Average position ranking
Drop table if exists #average_Pos_Ranking
Declare @Finished_rnd as int = 15
Select *
Into #average_Pos_Ranking
From(
    Select Player
        , round(avg(cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float)), 3) as average_Pos_Ranking
        , count(Rnd) as games_played
    From(
        Select m.Player
            , m.Rnd
            , m.Pos
            , m.Points
            , row_number() over(Partition by m.Rnd, m.Pos Order by Points desc) as pos_points_rnk
            , cppr.count_players_that_Rnd
        From #main m
            join #count_players_per_Rnd cppr
                on m.Rnd = cppr.Rnd
                and m.Pos = cppr.Pos
        Where m.Pos != 'Bench'
        --Order by 1,2 --find specific guys
    ) x
    Group by Player
) y
Where cast(games_played as float) / @Finished_rnd > 0.5
Order by 2

--# of times in Top X, buckets overlap each other, Overall by round
Select Player
    , sum(leader_flag) as leader_flag
    , sum(top10_flag) as top10_flag
    , sum(top25_flag) as top25_flag
    , sum(top50_flag) as top50_flag
    , sum(bottom50_flag) as bottom50_flag
From (
    Select Player --not distinct!
            , leader_flag
            , top10_flag
            , top25_flag
            , top50_flag
            , bottom50_flag
    From(
        Select x.Player
            , Rnd
            , case when pos_points_rnk = 1 then 1 else 0 end as leader_flag
            , case when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) <= 0.1 then 1 else 0 end as top10_flag
            , case when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) <=  0.25 then 1 else 0 end as top25_flag
            , case when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) <=  0.50 then 1 else 0 end as top50_flag
            , case when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) > 0.5 then 1 else 0 end as bottom50_flag
        From(
            Select m.Player
                , m.Rnd
                , m.Pos
                , m.Points
                , row_number() over(Partition by m.Rnd Order by Points desc) as pos_points_rnk
                , cppr.count_players_that_Rnd
            From #main m
                join #count_players_per_Rnd cppr
                    on m.Rnd = cppr.Rnd
                    and m.Pos = cppr.Pos
            Where m.Pos != 'Bench'
            --Order by 1,2 --find specific guys
        ) x
        --        join #average_Pos_Ranking apr -- players with over half games played
        --            on apr.Player = x.Player
    ) y
) z
Group by Player
Order by 2 desc, 3 desc, 4 desc, 5 desc, 6 desc


--# of times in Top X, buckets overlap each other, Position-specific
Select Player
    , sum(leader_flag) as leader_flag
    , sum(top10_flag) as top10_flag
    , sum(top25_flag) as top25_flag
    , sum(top50_flag) as top50_flag
    , sum(bottom50_flag) as bottom50_flag
From (
    Select Player --not distinct!
            , leader_flag
            , top10_flag
            , top25_flag
            , top50_flag
            , bottom50_flag
    From(
        Select x.Player
            , Rnd
            , case when pos_points_rnk = 1 then 1 else 0 end as leader_flag
            , case when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) <= 0.1 then 1 else 0 end as top10_flag
            , case when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) <=  0.25 then 1 else 0 end as top25_flag
            , case when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) <=  0.50 then 1 else 0 end as top50_flag
            , case when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) > 0.5 then 1 else 0 end as bottom50_flag
        From(
            Select m.Player
                , m.Rnd
                , m.Pos
                , m.Points
                , row_number() over(Partition by m.Rnd, m.Pos Order by Points desc) as pos_points_rnk
                , cppr.count_players_that_Rnd
            From #main m
                join #count_players_per_Rnd cppr
                    on m.Rnd = cppr.Rnd
                    and m.Pos = cppr.Pos
            Where m.Pos != 'Bench'
            --Order by 1,2 --find specific guys
        ) x
        --        join #average_Pos_Ranking apr -- players with over half games played
        --            on apr.Player = x.Player
    ) y
) z
Group by Player
Order by 2 desc, 3 desc, 4 desc, 5 desc, 6 desc

--# of times in Top X, buckets exclusive each other, position-specific
Select Player
    , coalesce([Leader],0) as [Leader]
    , coalesce([Top 10%],0) as [Top 10%]
    , coalesce([Top 25%],0) as [Top 25%]
    , coalesce([Top 50%],0) as [Top 50%]
    , coalesce([Bottom 50%],0) as [Bottom 50%]
From (
    Select Player
        , placement_flag
        , max(rnk) as number_of_flag
    From (
        Select Player --not distinct!
                , placement_flag
                , row_number() over(Partition by Player, placement_flag order by placement_flag) as rnk
        From(
            Select x.Player
                , Rnd
                , case when pos_points_rnk = 1 then 'Leader' 
                        when pos_points_rnk != 1
                            and cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) <= 0.1 then 'Top 10%'
                        when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) > 0.1
                            and cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) <=  0.25  then 'Top 25%'
                        when cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) > 0.25 
                            and cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float) <=  0.50 then 'Top 50%'
                    else 'Bottom 50%'
                    end as placement_flag
                --, round(avg(cast(pos_points_rnk as float) / cast(count_players_that_Rnd as float)), 3) as average_Pos_Ranking
            From(
                Select distinct m.Player
                    , m.Rnd
                    , m.Pos
                    , m.Points
                    , row_number() over(Partition by m.Rnd, m.Pos Order by Points desc) as pos_points_rnk
                    , cppr.count_players_that_Rnd
                    , c.ADP_league4
                From #main m
                    join #count_players_per_Rnd cppr
                        on m.Rnd = cppr.Rnd
                        and m.Pos = cppr.Pos
                    join #Consistency c
                        on c.player = m.player
                Where m.Pos != 'Bench'
                --Order by 1,2 --find specific guys
            ) x
            --        join #average_Pos_Ranking apr -- players with over half games played
            --            on apr.Player = x.Player
        ) y
    ) z
    Group by Player
        , placement_flag
) a
Pivot(max(number_of_flag) for placement_flag in (
    [Leader]
    , [Top 10%]
    , [Top 25%]
    , [Top 50%]
    , [Bottom 50%]
)) p
Order by 2 desc, 3 desc, 4 desc, 5 desc, 6 desc



---------------------------------------------------------------------
--How many wins/losses for Fantasy performances based on point thresholds
---------------------------------------------------------------------

Select x.Player
    , sum(more_than_20) as more_than_20
    , sum(between_15_20) as between_15_20
    , sum(between_10_15) as between_10_15
    , sum(between_5_10) as between_5_10
    , sum(between_0_5) as between_0_5
    , sum(less_or_equal_0) as less_or_equal_0
From(
    Select distinct m.rnd --should be distinct
        , m.Team
        , m.Player
        , m.Points
        , case when Points > 20 then 1 else 0 end as more_than_20
        , case when Points > 15 and Points <= 20 then 1 else 0 end as between_15_20
        , case when Points > 10 and Points <= 15 then 1 else 0 end as between_10_15
        , case when Points > 5 and Points <= 10 then 1 else 0 end as between_5_10
        , case when Points > 0 and Points <= 5 then 1 else 0 end as between_0_5
        , case when Points <= 0 then 1 else 0 end as less_or_equal_0
    From #main m
) x
Group by x.Player
Order by 2 desc, 3 desc, 4 desc, 5 desc




--------------------------------------
--Max score each week (max_Diff)
--------------------------------------

--Team
Select *
From(
    Select *
        , row_number() over(Partition by x.Rnd Order by x.highscore desc) as rnk
    From(
        Select Rnd
            , case when HomeScore > VisitorScore then HomeScore
                else VisitorScore
                end as highscore
            , case when HomeScore > VisitorScore then HomeTeam
                else VisitorTeam    
                end as highscore_team
            , case when HomeScore > VisitorScore then VisitorTeam
                else HomeTeam
                end as highscore_opp
        From #matchups
    ) x
) y
Where rnk = 1


--What about players?

Select *
From(
    Select Rnd
        , Pos
        , Player
        , Points
        , Opp
        , row_number() over(Partition by Rnd, Pos Order by Points desc) as rnk
    From #main m
) x
Where rnk = 1
Order by Rnd, Pos, rnk asc


-------------------------------------------------
--FFR (Fantasy Friendly Rugby)
--Putting teams into Best ball, by team
----Front row
----Second row
----Back row
----Flex forward
----Scrumhalf
----Flyhalf
----Center
----Back three
----Flex back
----Bonus point team
-------------------------------------------------
--FFR
Drop table if exists #FFR_starter

Select *
Into #FFR_starter
From(
    Select Rnd
        , Team
        , Number
        , Pos
        , Player
        , Points
        , flex_pos
        , (Select count(*) 
            From #main t2
            Where t2.Team = t1.Team
            and t2.Pos = t1.Pos
            and t2.Rnd = t1.Rnd
            and cast(t2.Points as float) >= cast(t1.Points as float)
            ) as lineup_rnk
    From #main t1
    Where Pos != 'Bench'
) x
Where lineup_rnk = 1
Order by Rnd, Team, Pos, Points desc



Drop table if exists #FFR_lineup

Select *
Into #FFR_lineup
From(
    Select Rnd
        , Team
        , Number
        , Pos
        , Player
        , Points
        , flex_pos
        , 0 as flex_rnk
    From #FFR_starter fs

    Union

    Select m.Rnd
        , m.Team
        , m.Number
        , m.Pos
        , m.Player
        , m.Points
        , m.flex_pos
        , row_number() over(Partition by m.Rnd, m.Team, m.flex_pos order by m.Points desc, m.Player) as flex_rnk --tie decided by name
    From #main m
        left join #FFR_starter fs
            on fs.Rnd = m.Rnd
            and fs.Player = m.Player
    Where m.Pos != 'Bench'
    and fs.lineup_rnk is null
) x
Where x.flex_rnk <= 1



--Seems to work
Select *
From #FFR_lineup

--Select distinct rnk
--From (
--    Select *
--        , row_number() over(Partition by fl.Rnd, fl.Team order by fl.number) as rnk
--    From #FFR_lineup fl
--) x
--Order by Rnd, Team, flex_pos desc, Number


----------------------------------------------------------------
--% of lineup points per Rnd/season, compare to bench?
----------------------------------------------------------------

Drop table if exists #team_sums

Select m.Rnd
    , m.Team
    , sum(m.Points) as team_sum
Into #team_sums
From #main m
Group by Player


Drop table if exists #player_sums

Select m.Player
    , sum(m.Points) as player_sum
Into #player_sums
From #main m
Group by Player






--------------------------
--Analytics fun
--------------------------


--Ranking each round by position
Drop table if exists #Round_rankings

Select i.Pos_Ordering
    , i.Rnd
    , i.Pos
    , i.Player
    , i.Points
    , row_number() over(Partition by i.Rnd, i.Pos order by i.Points desc) as rnk
Into #Round_rankings
From #main i

Select *
From #Round_rankings
Where rnk = 1
and Rnd = 11
Order by Pos_Ordering


--Weeks lead league at position
Select i.Player
    , i.Pos
    , Coalesce(x.count_leader, 0) as count_leader
    , count(i.Rnd) as appearances
From #main i
    left join ( Select rr.Player
                    , rr.Pos
                    , count(rr.Rnd) as count_leader
                From #Round_rankings rr
                Where rnk = 1
                Group by rr.Player, rr.Pos
            ) x
        on i.Player = x.Player
        and i.Pos = x.Pos
Group by i.Player, i.Pos, x.count_leader
Order by i.Pos, count_leader desc, i.Player




--Weeks lead team at position
--Select i.Player
--    , i.Pos
--    , Coalesce(x.count_leader, 0) as count_leader
--    , count(i.Rnd) as appearances
--From #individuals i
--    left join ( Select i.Player
--                    , i.Pos
--                    , count(*) as count_leader
--                From #individuals i
--                Where lineup_rnk = 1
--                Group by i.Player, i.Pos
--            ) x
--        on i.Player = x.Player
--        and i.Pos = x.Pos
--Group by i.Player, i.Pos, x.count_leader
--Order by i.Player, i.Pos






Select Pos, avg(Points)
From #main
Group by Pos
Order by 2 desc



--Windsor effect
Drop table if exists #windsor
Select *
Into #windsor
From #main
Where player like '%Windsor%'


Select Pos, avg(points)
From #windsor
Group by Pos

Select *
From (
    Select w.Rnd
        , w.Pos as Sam_pos
        , w.Player as Sam_Player
        , w.Points as Sam_Points
        , m.Points
        , m.Player
        , m.Pos
        , row_number() over(Partition by m.Rnd order by m.Points desc) as rnk
    From #windsor w
        join #main m
            on w.Rnd = m.Rnd
            and w.Pos = m.Pos
) x
Where rnk = 1

-----------
--SANDBOX--
-----------

--Top player for each position in the week (top 3 back three, top 2 centers, etc.)


--Anomaly Detection?

--kicking % versus win rate (deciding games with missed kick(s)?)

--Develop WOPR for Rugby?
--WOPR, or weighted opportunity rating, is a metric used to capture a receiver’s true usage and help predict his future fantasy football performance by combining and properly weighting his target share (the percentage of all team passes directed at him) and air yard share (the percentage of all team air yards — the distance between the line of scrimmage and the catch point — directed at him).


--Pick up new houston SH or keep inciarte going
--keep inciarte
Select case_log, avg(Points), min(Points), max(Points)
From(
    Select distinct Rnd
                , Player
                , Pos
                , Team
                , Opp
                , cast(Points as decimal(5,1)) as Points
                , case when team = 'HOU' then 1
                    when Opp = 'ARC' then 2
                    when player like '%inciarte%' then 3
                    end as case_log
    From #main 
    Where Pos like 'SH'
    and (Team = 'HOU'
    or Opp = 'ARC'
    or player like '%inciart%')
    --Order by Team, rnd
) x
Group by case_log

Select *
From (
Select distinct Rnd
            , Player
            , Pos
            --, Opp
            , cast(Points as decimal(5,1)) as Points
From #main 
Where player like '%tidwell%'
or player like '%gafa%'
--Where Pos like 'SH'
--and Rnd = 6
--and Opp = 'ARC'
) x
pivot(max(Points) for Player in (
    [Junior Gafa]
    , [Jason Tidwell]
))p
Order by 1






------------------------------
--WAIVER ASSISTANT v1
------------------------------
Select *
From #improved
Order by Rnd, Team