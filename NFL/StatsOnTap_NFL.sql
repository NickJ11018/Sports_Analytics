-------------------------------------------------------------
--Stats On Tap SQL code
--Ensure data loaded from DataLoad
-------------------------------------------------------------



--First analysis: Fantasy Friendly Offense
/*
--Wrap to pull up to Team level
Select Team, Week, round(sum(cast(PPR as float)),2) as team_PPR
From(

    Select *
    FROM(
        SELECT Team
            , Week
            , case when pos = 'FB' then 'RB' else Pos end as Pos
            , Player
            , PPR
            , (Select count(*) 
                From [NM\NM287071].nfl_2023 t2 
                Where t2.Team = t1.Team
                and t2.Pos = t1.Pos
                and cast(t2.PPR as float) >= cast(t1.PPR as float)
                ) as rnk 
        , case when pos = 'QB' then 1
                when pos = 'RB' then 2
                when pos = 'WR' then 3
                when pos = 'TE' then 4
                when pos = 'K' then 5
                end as posrnk
        From [NM\NM287071].nfl_2023 t1
    ) x 
    Where 1=1
    --and Pos in ('QB', 'RB', 'WR', 'TE', 'K')
    and (rnk = 1
    or (rnk = 2 and Pos in('RB', 'WR')))
--order by Team, posrnk, rnk

) y
Group by team, week
Order by team_PPR desc
*/


--Realistically these Poss will not affect anything, only a handful positive PPR at 1.1
--Select * 
--From [NM\NM287071].nfl_2023 t1
--Where pos in ('G', 'LB', 'OL', 'DT', 'C', 'DB', 'P', 'S', 'CB')



--individual performances
Drop table if exists #individuals
Select Team
    , Week
    , case when pos = 'FB' then 'RB' else Pos end as Pos
    , Player
    , PPR
    , (Select count(*) 
        From [NM\NM287071].nfl_2023 t2 
        Where t2.Team = t1.Team
        and t2.Pos = t1.Pos
        and t2.Week = t1.Week
        and cast(t2.PPR as float) >= cast(t1.PPR as float)
        ) as rnk
Into #individuals
From [NM\NM287071].nfl_2023 t1
Where pos not in ('G', 'LB', 'OL', 'DT', 'C', 'DB', 'P', 'S', 'CB') --53 entries


Select distinct Pos
From #individuals
Order by 1


--Count per team in top X fantasy showings this year
--(as of week 14, 8 teams in top 10, 24 teams in top 50, 30 teams in top 100
--  , 2 teams without a top 100 performance: CLE, NWE)
Select Team
    , count(*) count_top10
    --, min(all_rnk) as highest_performer
From(
    Select Top 10 *
        --, team_rnk = dense_rank() over(partition by Team order by PPR desc)
        --, all_rnk = dense_rank() over(order by PPR desc)
    From #individuals
    --Where week between 11 and 14
) x
Group by Team
Order by 2 desc



--Player averages
Select player, count(Week) as games_played, avg(PPR) as PPR_average
From #individuals
--Where Player like '%D/ST%'
Group by Player
Order by 3 desc

--Weekly highs, and player
Select x.Week, max_PPR = PPR, Player
From #individuals i
    join (Select Week, max(PPR) as weekly_maxPPR
            From #individuals
            Group by Week) x
        on x.[Week] = i.[Week]
        and x.weekly_maxPPR = i.PPR
order by 1



--Count per player in top X fantasy showings this year
--(as of week 14, Tyreek leads with 4 top-100, 5 tied with 3, 18 tied with 2)
Select Player
    , count(*) as count
    --, min(all_rnk) as highest_performer
From(
    Select Top 100 *
        --, team_rnk = dense_rank() over(partition by Team order by PPR desc)
        --, all_rnk = dense_rank() over(order by PPR desc)
    From #individuals
) x
Group by Player
Order by 2 desc


--Team's best performance in the year
Select *
    , team_rnk = dense_rank() over(partition by Team order by PPR desc)
    , all_rnk = dense_rank() over(order by PPR desc)
From #individuals
order by team_rnk, PPR desc


--Player's highest performance this year
Select Player
    , min(all_rnk) as best_rnk
From(
    Select *
        , team_rnk = dense_rank() over(partition by Team order by PPR desc)
        , all_rnk = dense_rank() over(order by PPR desc)
    From #individuals
) x
Group by Player
order by 2





--How to select FLEX player?
--highest score for a player (W/R/T) who isn't WR12, RB12, or TE1)

--need to fix this
/*
Select *
From #FFF_lineup
Where week = 8
and Team = 'ATL'
*/

Drop table if exists #week_rnks

Select *
Into #week_rnks
From(
    Select i.*
        , week_rnk = dense_rank() over(Partition by Week, Team, Pos order by PPR desc, player desc) --arbitrarily chosen name tiebreak
    From #individuals i
) x
Where (pos in ('QB', 'RB', 'WR', 'TE', 'K', 'DST') and week_rnk = 1)
    or (pos in ('WR', 'RB') and week_rnk = 2)
Order by Week, week_rnk


--+ flex for anyone not in this list
Drop table if exists #FFF_lineup

Select *
Into #FFF_lineup
From(
    Select i.*
        , 99 as week_rnk --just to tag them
        , flex_rnk = dense_rank() over(Partition by i.Team, i.Week Order by i.PPR desc, i.player desc)
    From #individuals i
        left join #week_rnks wr
            on wr.[Week] = i.[Week]
            and i.Team = wr.Team
            and i.Player = wr.Player
    Where wr.Player is null
    and i.Pos in ('TE', 'RB', 'WR')

    Union

    Select *
        , 1 as flex_rnk --all these stay in
    From #week_rnks wr
) x
Where x.flex_rnk = 1
Order by Week, Team, Pos, week_rnk


Select *
From #individuals
Where week = 3
and Team = 'MIA'
Order by PPR desc

Select *
From(
Select Week, Team, count(*) as counters
From #FFF_lineup
Group by Week, Team
) x
Where counters > 9

/*
Select *
From #FFF
Where week = 3
and Team = 'MIA'
Order by team_sum desc
*/

--Season total
Select Team
        , sum(team_sum) as season_sum
From(

    --Per-week totals
    Select Week
            , Team
            , sum(PPR) as team_sum
    From(
    --P-wt
        Select *
        From #FFF_lineup
    ) x
    Group by Team, Week
    --Order by team_sum desc
    --Order by Week desc, team_sum desc
--------------------------------------Just realized this isn't pulling a FLEX spot yet
--St
) y
Group by Team
Order by season_sum desc



------------
--FFF
------------
Drop table if exists #FFF

Select Week
    , Team
    , sum(PPR) as team_sum
Into #FFF
From #FFF_lineup
Group by Week
    , Team


--opponents
Drop table if exists #opponents

Select distinct f.[Week]
    , f.Team
    , t1.Opp
Into #opponents
From #FFF_lineup f
    join [NM\NM287071].nfl_2023 t1
        on f.Team = t1.Team
        and f.[Week] = t1.[Week]

Select *
From #opponents


-------------
--Matchups
-------------

Drop table if exists #matchups
Select distinct x.Week
        , x.Team
        , x.Opp
        , x.FFF_win
        , x.Result
        , Case when FFF_win = Result then 1 else 0 end as real_correct
Into #matchups
From(
    Select f.[Week]
        , f.Team
        , Case when f.team_sum > fo.team_sum then 'W' 
                when f.team_sum < fo.team_sum then 'L'
                when f.team_sum = fo.team_sum then 'T'
                end as FFF_win
        , left(t1.Result, 1) as Result
        , f.team_sum
        , o.Opp
        , fo.team_sum as opp_sum
    From #FFF f
        join #opponents o
            on f.Team = o.Team
            and f.[Week] = o.[Week]
        join #FFF fo --opponent score
            on fo.Team = o.opp
            and fo.[Week] = o.[Week]
        join [NM\NM287071].nfl_2023 t1
            on t1.Team = f.team
            and t1.[Week] = f.[Week]
) x
--Where x.week = 1
Order by 1, 2

Select *
From #matchups
ORder by 1, 2

--Alphabetical team assignment
Drop table if exists #team_nums
Select Team
        , Row_number () over(Order by Team) as team_num
Into #team_nums
From (Select distinct Team 
        From [NM\NM287071].nfl_2023) x


/*
;
--For loop to remove matchups?
Declare @count as Int = 1;

While @count <= 5
Begin
    Select * 
    From #matchups m
        join #team_nums tn
            on m.Team = tn.Team
    Where Week = 1
    and team_num = @count;
    SET @count = @count + 1;
End;
*/


--Just looking for percentages basically? This is for Team
Select *
    --, cast(100*x.count_correct as float) as testing
    --, cast(x.possible_correct as float) as testing2
    , cast(100*x.count_correct as float)/cast(x.possible_correct as float)-- as decimal(3,2))
    --, cast((cast(100*x.count_correct as float)/cast(x.possible_correct as float)) as decimal (5,3)) as percent_correct
From (
    Select-- m.Week
        m.Team
        , sum(m.real_correct) as count_correct
        , count(m.real_correct) as possible_correct
    From #matchups m
    --Group by m.WEEK
    Group by m.Team
) x
Order by 1


--and this is for Weekly
Select *
    --, cast(100*x.count_correct as float) as testing
    --, cast(x.possible_correct as float) as testing2
    , cast(100*x.count_correct as float)/cast(x.possible_correct as float)-- as decimal(3,2))
    --, cast((cast(100*x.count_correct as float)/cast(x.possible_correct as float)) as decimal (5,3)) as percent_correct
From (
    Select m.Week
        , sum(m.real_correct)/2 as count_correct --doublecounting I think?
        , count(m.real_correct)/2 as possible_correct --doublecounting I think?
    From #matchups m
    Group by m.WEEK
) x
Order by 1



-------------------------------
--Can this be predictive?
-------------------------------
--running avg
Drop table if exists #running_avg
Select f.Week
    , f.Team
    , avg(fl.team_sum) as running_avg --?
Into #running_avg
From #FFF f
    left join #FFF fl
        on fl.Team = f.Team
Where fl.[Week] <= f.[Week]
Group by f.Week, f.Team


--Prediction time
Drop table if exists #FFF_predict

Select *
    , Case when x.lag_team_ra > x.lag_opp_ra then 'W' 
                when x.lag_team_ra < x.lag_opp_ra then 'L'
                --when x.lag_team_ra = x.lag_opp_ra then 'T'
                end as FFF_predict
Into #FFF_predict
From(
    Select ra.Week
            , ra.Team
            , lag(ra.running_avg, 1) over(partition by ra.team order by ra.Week) as lag_team_ra
            , m.Opp
            , lag(rao.running_avg, 1) over(partition by rao.team order by rao.Week) as lag_opp_ra
            --, lag(f.team_sum, 1) over(partition by f.team order by f.Week) as last_team_sum
            --, lag(fo.team_sum, 1) over(partition by fo.team order by f.Week) as last_opp_sum
            , m.Result
    From #running_avg ra
        join #matchups m
            on ra.Team = m.Team
            and ra.[Week] = m.[Week]
        join #running_avg rao
            on rao.Team = m.Opp
            and rao.[Week] = m.[Week]
) x
Order by 2,1


--SNF matchup
Select *
From #FFF_predict fp
Where fp.Team in ('BAL', 'JAX')
Order by 1,2

Select *
From #running_avg
Where week >= 12
and Team in ('BAL', 'JAX')
Order by 1,2


-------------------------------------------
--Prediction Percentages, Team/Weekly
-------------------------------------------
Select distinct Week
From #individuals
order by 1

--Team
Select *
    , cast(cast(predict_correct as float)/cast(predict_possible as float) as decimal(4,3)) as percent_predict
From(
    Select Team
        , sum(x.predict_correct) as predict_correct
        , count(x.predict_correct) as predict_possible --doublecounted matchups
    From(
        Select *
            , case when fp.Result = fp.FFF_predict then 1 
             else 0 end as predict_correct
        From #FFF_predict fp
        Where week != 1 --No prediction set for week 1
    ) x
    Group by Team
) y
Order by 4 desc



--Weekly
Drop table if exists #tempy
Select *
    , cast(cast(predict_correct as float)/cast(predict_possible as float) as decimal(4,3)) as percent_predict
Into #tempy
From(
    Select Week
        , sum(x.predict_correct)/2 as predict_correct
        , count(x.predict_correct)/2 as predict_possible --doublecounted matchups
    From(
        Select *
            , case when fp.Result = fp.FFF_predict then 1 
                else 0 end as predict_correct
        From #FFF_predict fp
        Where Week != 1 --No prediction set for week 1
    ) x
    Group by Week
) y
Order by 1


--Averages 54.4117% correct with running avg of fantasy teams
Select avg(case when fp.Result = fp.FFF_predict then 1.0 
    else 0.0 end) as predict_correct
--avg(fp.FFF_predict)
From #FFF_predict fp

--difference between fantasy prediction checks
Select avg(abs(lag_team_ra-lag_opp_ra))
From #FFF_predict


Select difference, avg(case when x.Result = x.FFF_predict then 1.0 
    else 0.0 end) as predict_correct
From(
    Select *
        , Case when abs(lag_team_ra-lag_opp_ra) > 15.1 then 'over 15.1'
            else 'under 15.1'
            end as difference
    From #FFF_predict fp
) x
Group by difference


-------------------------------------
--Overflow
--who doesn't show up in the FFF
-------------------------------------
Drop table if exists #missing

Select Team
, sum(PPR) as missing_PPR
Into #missing
From(
    Select i.*
    From #individuals i
        left join #FFF_lineup fl
            on i.[Week] = fl.week
            and i.Player = fl.Player
    Where fl.Player is null
) x
Group by Team
Order by Team

Select *
From #FFF_lineup
Where pos = 'QB'
and team = 'NOR'
Order by 2 desc




--What about total fantasy output?
Drop table if exists #season_rnk

Select *
    , row_number() over(order by season_sum desc) as season_rnk
Into #season_rnk
From(
    Select Team
        , sum(PPR) as season_sum
    From(
        Select *
        From #individuals
    ) x
    Group by Team
) y

Select *
From #season_rnk



--What about per position?
--Here's overall, all included

Select * 
From( --wrap to pivot
    Select season_rnk
        , Team
        , Pos
        , sum(PPR) as summed
    From(
        Select i.*, sr.season_rnk
        From #individuals i
            join #season_rnk sr
                on sr.Team = i.Team
    ) x
    Group by season_rnk
        , Team
        , Pos
) y
Pivot(Max(summed) for Pos in(
    [QB]
    , [RB]
    , [WR]
    , [TE]
    , [K]
    , [DST]
)) p



Order by season_rnk



















---------------------------------------------------------------------
--How many wins/losses for QB performances based on 16pt threshold
---------------------------------------------------------------------
Select x.test16
    , count(*) as count_test16
    , count(*)/6.58 as percent_test16
From(
    Select distinct i.Week --should be distinct
        , i.Team
        , i.Player
        , i.PPR
        , m.Result
        , case when PPR <= 16 and Result = 'L' then '<=16 Loss'
            when PPR <= 16 and Result = 'W' then '<=16 Win'
            when PPR > 16 and Result = 'L' then '>16 Loss'
            else '>16 Win' end as test16
    From #individuals i
        left join #matchups m
            on i.Team = m.Team
            and i.[Week] = m.[Week]
    Where i.Pos = 'QB'
) x
Group by x.test16
Order by 2 desc





------------------------------
--What about defensively?
------------------------------
--Essentially avg where Opp team is operative

--I have defense now


--Select def_team
--    , avg(scored_against) as def_avg
--From(
--    Select f.Week
--            , m.Opp as def_team
--            , f.team_sum as scored_against
--    From #FFF f
--        join #matchups m
--            on f.[Week] = m.[Week]
--            and f.team = m.Team
--) x
--Group by def_team
--Order by def_avg asc




------------------------------
--New Betting format, spitballing
------------------------------
--Make "perfect Lineup" (maybe imperfect too) similar to NFL Fantasy on Facebook
--Make tiers based on that, aka B-team, C-team, etc.
--Score based on min(sum(tier#)), kinda like stars (5* player)
--Make this a betting game like the lottery, who will end up A team that week.
--My guess on Friday, Tuesday load what actually happened.
--Use powerpoint to show in more artistic fashion?
-- -Line 1 at the top is The A-team, followed by B, C, etc., higlighted,
-- - along with second row of RB, WR, as well as a flex third spot RW/WR or TE somehow
-- Deliberate ties? Week 1 Kicker





--What would this look like
--Pivoting out to player-per-row-grain

---------------------------------
--
--New Fantasy Format, spitballing
--
---------------------------------
--League members draft teams to be on their roster, let's say start 2 offenses and bench 1,
--the rest of the offenses are on the waiver per normal. This way the level of difficulty is
--just what teams score points, not individual players. Same could go for rugby




--Assign leagues to running_avg to be used for team choice
--Each Direction given all 8 teams, will use top 4 running_avg for matchups
Drop table if exists #Leagues

Select *
    , Case when Team in ('BAL', 'CLE', 'PIT', 'CIN', 'DET', 'CHI', 'GNB', 'MIN')
            then 'North'
            when Team in ('HOU', 'JAX', 'IND', 'TEN', 'TAM', 'NOR', 'ATL', 'CAR')
            then 'South'
            when Team in ('BUF', 'MIA', 'NYJ', 'NWE', 'DAL', 'PHI', 'NYG', 'WAS')
            then 'East'
            when Team in ('KAN', 'LVR', 'DEN', 'LAC', 'SFO', 'LAR', 'SEA', 'ARI')
            then 'West'
            end as LeagueTeam
Into #Leagues
From #running_avg ra


--Which 4 teams used each week
Drop table if exists #played_teams

Select *
Into #played_teams
From(

    --Week 1, choosing alphabetical top 4
    Select *
        , played_rnk = row_number() over(Partition by Week, LeagueTeam order by Team)
    From #Leagues l
    Where l.[Week] = 1

    Union

    --Week 2+, use top 4 teams
    Select *
        , played_rnk = row_number() over(Partition by Week, LeagueTeam order by l.running_avg desc)
    From #Leagues l
    Where l.week != 1

) x
Where played_rnk <= 4

Select *
From #played_teams
Order by 1,4


--Weekly score for League
Drop table if exists #weekly_league

Select x.Week
    , x.LeagueTeam
    , sum(x.team_sum) as LeagueTeam_sum
Into #weekly_league
From(
    Select pt.Week
        , pt.LeagueTeam
        , pt.Team
        , scores.team_sum
    From #played_teams pt
        join (Select Week, Team, team_sum
              From #FFF) scores
            on scores.Week = pt.[Week]
            and scores.Team = pt.Team
) x
Group by x.Week
    , x.LeagueTeam


--League Scores
Drop table if exists #weekly_league_result

Select *
    , case when weekly_score_rnk = 1 then 3
        when weekly_score_rnk = 2 then 2
        when weekly_score_rnk = 3 then 1
        when weekly_score_rnk = 4 then 0
    end as wins
    , case when weekly_score_rnk = 1 then 0
        when weekly_score_rnk = 2 then 1
        when weekly_score_rnk = 3 then 2
        when weekly_score_rnk = 4 then 3
    end as losses
Into #weekly_league_result
From (
Select wl.[Week]
    , wl.LeagueTeam
    , weekly_score_rnk = row_number() over(partition by wl.Week order by LeagueTeam_sum desc) 
From #weekly_league wl
) x
Select *
From #weekly_league_result


--Count of weekly winners for each LeagueTeam
Select LeagueTeam
    , count(*) as winning_weeks
From(
    Select *
    From #weekly_league_result
    Where weekly_score_rnk = 1
) x
Group by LeagueTeam
Order by 2 desc

--Overall
Select LeagueTeam
    , sum(wins) as total_wins
    , sum(losses) as total_losses

From(
    Select *
    From #weekly_league_result
) x
Group by LeagueTeam
Order by total_wins desc



---------------
--::SANDBOX::--
---------------

--Per-week totals
Drop table if exists #temp
Select Week
        , Team
        , sum(PPR) as team_sum
into #temp
From(
--P-wt
    Select *
    From #FFF_lineup
) x
Where Team = 'CLE'
Group by Team, Week
--Order by team_sum desc
Order by Week --desc, team_sum desc

Select avg(team_sum) as [pre-Flacco]
From #temp
Where week between 1 and 12
or week = 18

Select avg(team_sum) as [Flacco]
From #temp
Where week between 13 and 17




--Per-week totals for selected QB
Drop table if exists #tempQB
Select Player
        , count(PPR) as games_count
        , avg(PPR) as avg_PPR
into #tempQB
From(
--P-wt
    Select *
    From #FFF_lineup
    Where Player like '%Cousin%'
    or Player like '%Tannehill%'
    or Player like '%Brissett%'
    or Player like '%Tyrod%'
    or Player like '%Mariota%'
    or Player like '%Darnold%'
    or Player like '%Winston%'
    or Player like '% Lock'
    or Player like '%Mayfield%'
    or Player like '%Minshew%'
    or Player like '%water%'
    or Player like '%Huntley%'
    or Player like '%Flacco%'
    or Player like '%Dobbs%'
    or Player like '%Stick%'
) x
Group by Player
--Order by team_sum desc


Select * From #tempQB
Order by avg_PPR desc--, team_sum desc




--Ideas
--"client" asked for Fantasy Football for beginners, here's
--"my team's" first attempt at it

