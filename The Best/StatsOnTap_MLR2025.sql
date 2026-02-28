--Dataload check
Select Rnd, Team, Count(*) as count_performances
From(
Select distinct Rnd, Team, Number
From MLR2025API
) x
group by Rnd, Team
having count(*) != 24
order by rnd

--Noted missing players
--HOU week 2	#17
--ARC week 2	#21
--MIA week 2	#18

Select max(rnd)
From MLR2025API



--2025
Select *
From MLR2025API
Order by Fantasy_Points
--2024
Select *
From MLR2024API
Order by Fantasy_Points
--2023
Select *
From MLR2023
Order by Points


--Alltime
Drop table if exists #alltime
Select 2025 as year
    , *
    , Case when Number in (1,2,3) then 'FR'
        when Number in (4,5) then 'SR'
        when Number in (6,7,8) then 'BR'
        when Number in (9) then 'SH'
        when Number in (10) then 'FH'
        when Number in (12,13) then 'C'
        when Number in (11,14,15) then 'B3'
        when Number in (24) then 'DSP'
        when Number between 16 and 23 then 'Bench'
        end as Pos
Into #alltime
From MLR2025API m25
    
Union 

Select 2024 as year
    , *
    , Case when Number in (1,2,3) then 'FR'
        when Number in (4,5) then 'SR'
        when Number in (6,7,8) then 'BR'
        when Number in (9) then 'SH'
        when Number in (10) then 'FH'
        when Number in (12,13) then 'C'
        when Number in (11,14,15) then 'B3'
        when Number in (24) then 'DSP'
        when Number between 16 and 23 then 'Bench'
        end as Pos
From MLR2024API m24

Union 

Select 2023 as year
    , *
    , Case when Number in (1,2,3) then 'FR'
        when Number in (4,5) then 'SR'
        when Number in (6,7,8) then 'BR'
        when Number in (9) then 'SH'
        when Number in (10) then 'FH'
        when Number in (12,13) then 'C'
        when Number in (11,14,15) then 'B3'
        when Number in (24) then 'DSP'
        when Number between 16 and 23 then 'Bench'
        end as Pos
From MLR2023API m23


Select *
From #alltime
Order by Rnd, Year



--Position based on starting number (1-15)
Drop table if exists #improved
Select ma.*
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
From MLR2025API ma


--Matchups schedule
Drop table if exists #matchups
Select *
Into #matchups
From MLR2025_schedule

--Base sanity
Select *
From #improved
Select *
From #matchups


--Main table
Drop table if exists #main

Select distinct *
Into #main
From(
    Select i.*
        , Case when i.Team = m.AwayTeam then m.HomeTeam
            when i.Team = m.HomeTeam then m.AwayTeam
            end as Opp
        , Case when i.Number between 1 and 8 then 'Forward'
            when i.Number between 9 and 15 then 'Back'
            when i.Number between 6 and 23 then 'Bench'
            when i.Number = 24 then 'aDSP'
            end as flex_pos
        , Case when i.Team = m.AwayTeam and m.AwayScore > m.HomeScore then 'W'
            when  i.Team = m.AwayTeam and m.AwayScore < m.HomeScore then 'L'
            when  i.Team = m.HomeTeam and m.HomeScore > m.AwayScore then 'W'
            when  i.Team = m.HomeTeam and m.HomeScore < m.AwayScore then 'L'
            when m.HomeScore = m.AwayScore then 'T'
            end as Result
    From #improved i
        join #matchups m
            on i.Rnd = m.Rnd
) x
Where x.Opp is not null
Order by 1, Fantasy_Points desc, Player desc



--------------------
--Excel printout
--------------------
--Avg for position against Opp
--Drop table if exists #avg_points
Select Pos
    , [ARC]
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
--Into #avg_points
From(
    Select x.Pos_Ordering
        , x.Pos
        , x.Opp
        , cast(avg(stat) as decimal(5,3)) as avg
    From(
        Select i.Pos
            , Case when i.Team = m.AwayTeam then m.HomeTeam
                when i.Team = m.HomeTeam then m.AwayTeam
                end as Opp
            , cast(i.[Fantasy_Points] as float) as stat
            , i.Pos_Ordering
        From #main i
            join #matchups m
                on m.Rnd = i.Rnd
        --Where Pos != 'Bench'
    ) x
    Where Opp is not null
    Group by Pos_ordering, Pos, Opp
) y
Pivot(max(avg) for Opp in(
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
Order by Pos_Ordering


--Avg for position on a Team
--Drop table if exists #avg_points
Select Pos
    , [ARC]
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
--Into #avg_points
From(
    Select x.Pos_Ordering
        , x.Pos
        , x.Team
        , cast(avg(stat) as decimal(5,3)) as avg
    From(
        Select distinct i.Rnd
            , i.Team
            , i.Pos
            , cast(i.[Fantasy_Points] as float) as stat
            , i.Pos_Ordering
        From #main i
            join #matchups m
                on m.Rnd = i.Rnd
        --Where Pos != 'Bench'
    ) x
    Group by Pos_ordering, Team, Pos
) y
Pivot(max(avg) for Team in(
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
Order by Pos_Ordering


--Example
Select Team
    , avg(Fantasy_Points) points_avg
From(
    Select Rnd
        , Pos
        , Team
        , Fantasy_Points
    From #main
    Where pos = 'DSP'
    and Team = 'CHI'
) x
Group by Team
Order by points_avg desc


--Teams OffDef25
Select Rnd
    , HomeTeam
    , AwayTeam
    , HomeScore
    , AwayScore
From #matchups



--Player_id printout
Select distinct Player, Player_id
From #improved i
Order by Player, Player_ID


--Excel Printouts
--Team switches take place here
Declare @finished_round as int = 13
--Player score printout for Excel --DUPLICATES?
Select distinct Rnd
    , Team
    , Player
    , Fantasy_Points
    , home_away
    , Opp
From(
    Select distinct Rnd
            , Pos
            , Team
            , Player
            , Case when Fantasy_Points is not null then Fantasy_Points
                else null end as Fantasy_Points
            , home_away
            , Opp
    From #main i
    Where Rnd = @finished_round

    
    UNION

    --Futures printout
    Select 
        ma.Rnd
        , m.Pos
        , m.Team
        , m.Player
        , null
        , case when m.Team = ma.HomeTeam then 'Home'
            else 'Away' end as proj_homeaway
        , case when m.Team = ma.HomeTeam then AwayTeam 
            else HomeTeam end as Proj_Opp
    From(
        Select distinct  m.Pos
            , Case when m.player like '%Gerlach%' then 'ARC' --team switch
                   when m.player like '%Fricker%' then 'ARC' --team switch
                   when m.player like '%Cassh%' then 'SDL' --team switch
                else m.Team end as Team
            , m.Player
            , null as points_empty
        From #main m
    ) m
        left join #matchups ma
            on (ma.HomeTeam = m.Team
            or ma.AwayTeam = m.Team)
    and ma.Rnd > @finished_round
) x
--Where Pos in ('FR','SR','BR') --Forwards
--Where Pos in ('SH','FH','C','B3') --Backs
Where x.pos = 'FR' --Position
Order by 1, Fantasy_Points desc, 2




--Sheets Result Printouts
--Team switches take place here
Declare @finished_round as int = 14
--Player score printout for Excel --DUPLICATES?
Select distinct Rnd
    --, Team
    --, Opp
    --, home_away
    , Pos
    , Player_ID
    --, Player
    , Fantasy_Points
From(
    Select distinct Rnd
            , Pos
            , Team
            , Player
            , Player_ID
            , Case when Fantasy_Points is not null then Fantasy_Points
                else null end as Fantasy_Points
            , home_away
            , Opp
    From #main i
    Where Rnd = @finished_round
    --
    --    
    --    UNION
    --
    --    --Futures printout
    --    Select 
    --        ma.Rnd
    --        , m.Pos
    --        , m.Team
    --        , m.Player
    --        , Player_ID
    --        , -99
    --        , case when m.Team = ma.HomeTeam then 'Home'
    --            else 'Away' end as proj_homeaway
    --        , case when m.Team = ma.HomeTeam then AwayTeam 
    --            else HomeTeam end as Proj_Opp
    --    From(
    --        Select distinct  m.Pos
    --            , Case when m.player like '%Gerlach%' then 'ARC' --team switch
    --                   when m.player like '%Fricker%' then 'ARC' --team switch
    --                   when m.player like '%Cassh%' then 'SDL' --team switch
    --                else m.Team end as Team
    --            , m.Player
    --            , null as points_empty
    --            , Player_id
    --        From #main m
    --    ) m
    --        left join #matchups ma
    --            on (ma.HomeTeam = m.Team
    --            or ma.AwayTeam = m.Team)
    --    and ma.Rnd > @finished_round
) x
Where pos is not null
Order by 1, Fantasy_Points desc, 2



--KNIME printout
--Into H:\Personal\Stats Analysis\MLR2025_stats_download_knime.xlsx
Declare @finished_round as int = 16

Select distinct Rnd
    , pos as Position
    , Player_id
    , Player
    , Fantasy_Points
    , home_away
    , Team
    , Opp
From(
    Select distinct Rnd
            , Pos
            , Team
            , Player_id
            , Player
            , Case when Fantasy_Points is not null then Fantasy_Points
                else null end as Fantasy_Points
            , home_away
            , Opp
    From #main i
    Where Rnd <= @finished_round

    
    UNION

    --Futures printout
    Select 
        ma.Rnd
        , m.Pos
        , m.Team
        , Player_ID
        , m.Player
        , -99
        , case when m.Team = ma.HomeTeam then 'Home'
            else 'Away' end as proj_homeaway
        , case when m.Team = ma.HomeTeam then AwayTeam 
            else HomeTeam end as Proj_Opp
    From(
        Select distinct  m.Pos
            , Case when m.player like '%Gerlach%' then 'ARC' --team switch
                   when m.player like '%Fricker%' then 'ARC' --team switch
                   when m.player like '%Cassh%' then 'SDL' --team switch
                else m.Team end as Team
            , m.Player
            , null as points_empty
            , Player_id
        From #main m
    ) m
        left join #matchups ma
            on (ma.HomeTeam = m.Team
            or ma.AwayTeam = m.Team)
    and ma.Rnd > @finished_round
) x
--Where Pos in ('FR','SR','BR') --Forwards
--Where Pos in ('SH','FH','C','B3') --Backs
--Where x.pos = 'FR' --Position
Where pos is not null
and Rnd is not null --last bye week
Order by 1, Fantasy_Points desc, 2


---------
--Sandbox
---------
--Player search alltime
Select Year, Rnd, Player, Number, Fantasy_Points--, cast([Fantasy_Points] as float)/cast([Minutes] as float) as points_per_minute, Fantasy_Points, [Minutes]
From #alltime
Where player like '%Botha%'
Order by year, rnd


--Temporary backfill
--Declare @finished_round as int = 6
Select distinct Rnd
    , Team
    , Player
    , Fantasy_Points
    , home_away
    , Opp
From #main i
Where Rnd <= @finished_round
and pos = 'DSP'
Order by Rnd, Fantasy_Points desc



--Alltime points sum by this time
Select Year, sum(Fantasy_Points) as fantasy_points_sum
From(
    Select Year, Fantasy_Points
    From #alltime
    Where Rnd <= 7
) x
Group by year
Order by fantasy_points_sum

--Teams per round
Drop table if exists #teams_per_round

Select Year, Rnd, count(distinct Team) as count_teams
Into #teams_per_round
From #alltime
Group by Year, Rnd


--sum / team per round
--Basically points per team that round
Select Year, sum(points_per_team)
From(
    Select Year, Rnd, (sum_points/count_teams) as points_per_team
    From(
        Select a.Year, a.Rnd, tpr.count_teams, sum(Fantasy_Points) as sum_points
        From #alltime a
            join #teams_per_round tpr
                on a.[year] = tpr.[year]
                and a.rnd = tpr.Rnd
        Where a.Rnd <= 7
        Group by a.Year, a.Rnd, tpr.count_teams
    ) x
) y
Group by Year



--Count of X+ points per year
Select Year, count(Fantasy_Points) --not distinct, duplicates are alright
From #alltime
Where Fantasy_Points < -10
and Rnd <=7
Group by Year Order by Year


--List of those players
Select Rnd, Team, Fantasy_Points, Player, Number
From #alltime
Where Fantasy_Points >= 30
and Rnd <=7
Order by Year, Fantasy_Points desc




----------------------------------
-- Current Position Eligibility --
----------------------------------
/*
--My method
--Using Google Sheets so this isn't really needed
Select Team
    , Player
    , InitialPos
    , Case when [1] is null and team in ('Utah')
            then 'Bye'
        else Coalesce([1], 'Out')
        end as Rnd1 --Should check for IR guys
    , Case when [2] is null and team in ('OGDC', 'NEFJ', 'SEA')
            then 'Bye'
        else Coalesce([2], 'Out')
        end as Rnd2
    , Case when [3] is null and team in ('LA')
            then 'Bye'
        else Coalesce([3], 'Out')
        end as Rnd3
    , Case when [4] is null and team in ('NOLA')
            then 'Bye'
        else Coalesce([4], 'Out')
        end as Rnd4
    , Case when [5] is null and team in ('ARC', 'HOU', 'SDL')
            then 'Bye'
        else Coalesce([5], 'Out')
        end as Rnd4
From(
    Select distinct i.Rnd
        , i.Team
        , i.Player
        , InitialPos
        , Pos
    From #improved i
        left join MLR2025_InitialEligibility mie
            on i.Player = mie.Player
) x
Pivot(max(Pos) for Rnd in (
    [1]
    ,[2]
    ,[3]
    ,[4]
    ,[5]
)) p
Order by Player 


--Switcher check, UPDATE WEEKLY
DECLARE @finished_week as int = 4

Select *
From(
    Select *
            , Case when Pos = lag_1 and lag_1 = lag_2 and lag_2 = lag_3
                then Pos
                when Pos = lag_1 and lag_1 = lag_2 and lag_3 = ' '
                then Pos
                when Pos = lag_1 and lag_2 = ' ' and lag_3 = ' '
                then Pos
                when lag_1 = ' ' and lag_2 = ' ' and lag_3 = ' '
                then Pos
                else 'Switch Check'
            end as eligibility
    From( 
            --DECLARE @finished_week as int = 4
        Select Player
            , Rnd
            , InitialPos
            , Pos
            , Coalesce(lag_1, ' ') as lag_1
            , Coalesce(lag_2, ' ') as lag_2
            , Coalesce(lag_3, ' ') as lag_3
        From(
            --DECLARE @finished_week as int = 4
            Select Case 
                    when i.Player like '% Vuli' then 'Viliami (Puna) Vuli'
                    when i.Player like 'Paddy Ryan' and i.Team = 'SDL' then 'Paddy Ryan_SDL'
                    when i.Player like 'Paddy Ryan' and i.Team = 'CHI' then 'Paddy Ryan_CHI'
                    else i.Player end as Player
                , Case when i.Player = 'Cameron Gerlach' then 'B3' --IncomplETE!
                    when i.Player = 'Rufus McLean' then 'B3'
                    when i.Player = 'Cassh Maluia' then 'C'
                    when i.Player = 'Christopher Hilsenbeck' then 'FH'
                    else mie.InitialPos end as InitialPos
                , Rnd
                , Team
                , Pos
                , lag(Pos,1) over(Partition by i.Player order by Rnd) as lag_1
                , lag(Pos,2) over(Partition by i.Player order by Rnd) as lag_2
                , lag(Pos,3) over(Partition by i.Player order by Rnd) as lag_3
                , row_number() over(Partition by i.Player order by Rnd desc) as rnk
            From #improved i
                left join MLR2025_InitialEligibility mie
                    on i.Player = mie.Player
            Where Rnd <= @finished_week
            and Pos not in ('Bench', 'Out', 'Bye')
        ) x
        Where rnk = 1
    ) y
) z
Where eligibility = 'Switch Check'
or eligibility != InitialPos
*/