--First off pull the whole table
Use Scratchdb_Research


Select *
From Scratchdb_Research.[NM\NM287071].nfl_2025
Where Week = 1 and Team = 'ARI'

-------------------------------------------------
--First analysis: Fantasy Friendly Offense
-------------------------------------------------
--Players with non-standard positions to be fixed, basically a bunch of FB
Select *
From Scratchdb_Research.[NM\NM287071].nfl_2025 n25
Where n25.Pos not in ('QB', 'RB', 'WR', 'TE', 'K', 'DST')

--Quick FB -> RB
Drop table if exists #players

Select Team
    , Week
    , case when pos = 'FB' then 'RB' else Pos end as Pos
    , Player
    , PPR
Into #players
From [NM\NM287071].nfl_2025


--Assign rankings per team per weeek per position
Drop table if exists #individuals

SELECT Team
    , Week
    , Pos
    , Player
    , PPR
    , DENSE_RANK() over(Partition by Week, Team, Pos Order by PPR desc, Player) as rnk
    --OG version
    --, (Select count(*) 
    --    From #players t2 
    --    --match to the same team, week, and position for who gets the Lineup start
    --    Where t2.Week = t1.Week
    --    and t2.Team = t1.Team
    --    and t2.Pos = t1.Pos
    --    and cast(t2.PPR as float) >= cast(t1.PPR as float)
    --    ) as rnk 
, case when pos = 'QB' then 1
        when pos = 'RB' then 2
        when pos = 'WR' then 3
        when pos = 'TE' then 4
        when pos = 'K' then 5
        when pos = 'DST' then 6
        end as posrnk
Into #individuals
From #players t1


Select *
From #individuals
Where Week = 1 and Team = 'NYG'--testing
Order by Week, Team, posrnk, PPR desc



--FFF non-flex Starters
Drop table if exists #fff_starters

Select *
Into #fff_starters
FROM #individuals i
Where 1=1
--and Pos in ('QB', 'RB', 'WR', 'TE', 'K', 'DST')
and (rnk = 1
or (rnk = 2 and Pos in('RB', 'WR')))


--FFF Flex per team/week
Drop table if exists #fff_flex

Select *
Into #fff_flex
From (
    Select *
        , row_number() over(Partition by Week, Team Order by PPR desc) as flex_rnk --alright with ties here, just need one player per Week/Team and the score is what counts
    From #individuals i
    --Find players not already selected as starters
    Where not exists (Select 'x'
                    From #fff_starters fs
                    Where fs.week = i.WEEK
                    and fs.Player = i.Player) --shouldn't need Team
    and Pos in ('RB', 'WR', 'TE') --possible flex positions, in case of doubling QB, DST, K
) x
Where flex_rnk = 1




---FFF Lineup to use later on
Drop table if exists #fff_lineups

Select *
    , null as flex_rnk
Into #fff_lineups
From #fff_starters

UNION

Select *
From #fff_flex



--FFF scores
Drop table if exists #fff_scores

Select Team
    , Week
    , round(sum(cast(PPR as float)),2) as team_PPR
Into #fff_scores
From #fff_lineups y
Group by Team, Week





--Check to see if any teams don't have the expected 9 players for a FFF lineup
--Only the Jets in Week 18 who didn't have a Kicker?
Drop table if exists #wrong_player_counts

Select Team
    , Week
    , count(*) as player_count --count of players
Into #wrong_player_counts
From #fff_lineups
Group by Team, Week
Having count(*) != 9

--printout of the wrong_player FFF teams
Select i.*, wpc.player_count
From #fff_lineups i
    join #wrong_player_counts wpc
        on i.Week = wpc.Week
        and i.Team = wpc.Team
Order by Week, Team, posrnk, PPR desc







--Quick looks
--top 10
Select top 10 *
From #fff_scores
Order by Team_PPR desc 
--DET top marks in Week 2 at 139.16
--bottom 10 
Select top 10 *
From #fff_scores
Order by Team_PPR asc
--LVR week 7 scored <10 points AS A TEAM in FFF format!! also LVR has 2 worst, CIN 2 in bottom 10


--Total for the year
--Relatively in line with final rankings, going with reverse of https://operations.nfl.com/journey-to-the-nfl/the-nfl-draft/2026-nfl-draft/
Drop table if exists #team_sum_ranks

Select Team
, Team_Sum_2025
, ROW_NUMBER() over(Order by Team_Sum_2025 desc) as team_sum_rnk
Into #team_sum_ranks
From (
    Select Team
        , round(sum(team_PPR),2) as Team_Sum_2025
    From #fff_scores
    Group by Team
) x
Order by team_sum_rnk 



--Draft order
Drop table if exists #draft_order_reversed

Select distinct tsr.* 
    , case 
    when Team = 'SEA' then 1
    when Team = 'NWE' then 2
    when Team = 'DEN' then 3
    when Team = 'LAR' then 4
    when Team = 'HOU' then 5
    when Team = 'SFO' then 6
    when Team = 'BUF' then 7
    when Team = 'CHI' then 8
    when Team = 'JAX' then 9
    when Team = 'PHI' then 10
    when Team = 'LAC' then 11
    when Team = 'PIT' then 12
    when Team = 'GNB' then 13
    when Team = 'CAR' then 14
    when Team = 'MIN' then 15
    when Team = 'DET' then 16
    when Team = 'IND' then 17
    when Team = 'TAM' then 18
    when Team = 'BAL' then 19
    when Team = 'ATL' then 20
    when Team = 'DAL' then 21
    when Team = 'MIA' then 22
    when Team = 'CIN' then 23
    when Team = 'KAN' then 24
    when Team = 'NOR' then 25
    when Team = 'WAS' then 26
    when Team = 'CLE' then 27
    when Team = 'NYG' then 28
    when Team = 'TEN' then 29
    when Team = 'ARI' then 30
    when Team = 'NYJ' then 31
    when Team = 'LVR' then 32
    end as draft_rank
Into #draft_order_reversed
From #team_sum_ranks tsr


--FFF vs Draft-based ranking printout
Select *
    --ranking underperformers (perhaps tougher competition) to overperformers (softer competition?)
    --e.g. Lions scored 2nd highest FFF yet missed playoffs and ended at 16th draft ranking
    , team_sum_rnk - draft_rank as fff_to_draft_difference
    --ranking combination from low (scored better and placed better) to high (scored worse and placed worse)
    --e.g. Raiders scored 32nd and draft ranking 32nd (get the first pick, they're the worst) so high number 1024
    , draft_rank * team_sum_rnk as draft_sum_mult
From #draft_order_reversed dor
Order by draft_sum_mult



-----------------------------------------------------------
--Is there a "Pythagorean formula" for NFL like Baseball?
-----------------------------------------------------------
/*
--(PF^x)/(PF^x+PA^x)
x:	2.98696335			One game would be 1/17 or 0.0588
Team	                Win_pct	    PointsFor	PointsAgainst	formula	        Winn_form_diff	games off
New York Jets	        0.176	    300	        503	            0.176000129	    1.29014E-07	    2.19324E-06							
Dallas Cowboys	        0.441	    471	        511	            0.439430946	    0.001569054	    0.026673924							
Tennessee Titans	    0.176	    284	        478	            0.174347705	    0.001652295	    0.028089021							
Green Bay Packers	    0.559	    391	        360	            0.561372394	    0.002372394	    0.040330691							
Minnesota Vikings	    0.529	    344	        333	            0.524249416	    0.004750584	    0.080759929							
Seattle Seahawks	    0.824	    483	        292	            0.818055382	    0.005944618	    0.101058511							
Cleveland Browns	    0.294	    279	        379	            0.285981893	    0.008018107	    0.136307823							
Buffalo Bills	        0.706	    481	        365	            0.695150896	    0.010849104	    0.184434764							
Houston Texans	        0.706	    404	        295	            0.718941938	    0.012941938	    0.220012948							
New Orleans Saints	    0.353	    306	        383	            0.338401999	    0.014598001	    0.248166016							
Cincinnati Bengals	    0.353	    414	        492	            0.373884499	    0.020884499	    0.355036487							
Las Vegas Raiders	    0.176	    241	        432	            0.148897122	    0.027102878	    0.460748928							
Jacksonville Jaguars	0.765	    474	        336	            0.736489667	    0.028510333	    0.484675662							
Tampa Bay Buccaneers	0.471	    380	        411	            0.441705427	    0.029294573	    0.498007737							
Philadelphia Eagles	    0.647	    379	        325	            0.612807576	    0.034192424	    0.581271211							
Washington Commanders	0.294	    356	        451	            0.330366881	    0.036366881	    0.618236978							
New England Patriots	0.824	    490	        320	            0.781204332	    0.042795668	    0.727526356							
Miami Dolphins	        0.412	    347	        424	            0.354660997	    0.057339003	    0.974763045							
Los Angeles Rams	    0.706	    518	        346	            0.76947491	    0.06347491	    1.079073463							
Atlanta Falcons	        0.471	    353	        401	            0.405929615	    0.065070385	    1.106196552							
Pittsburgh Steelers	    0.588	    397	        387	            0.519041331	    0.068958669	    1.17229737							
Baltimore Ravens	    0.471	    424	        398	            0.547114649	    0.076114649	    1.293949035							
Detroit Lions	        0.529	    481	        413	            0.611891963	    0.082891963	    1.409163372							
San Francisco 49ers	    0.706	    437	        371	            0.619884706	    0.086115294	    1.463959993							
Los Angeles Chargers	0.647	    368	        340	            0.558821433	    0.088178567	    1.499035633							
Chicago Bears	        0.647	    441	        415	            0.545252551	    0.101747449	    1.729706633							
Arizona Cardinals	    0.176	    355	        488	            0.278795414	    0.102795414	    1.747522046							
Carolina Panthers	    0.471	    311	        380	            0.354681736	    0.116318264	    1.977410491							
Indianapolis Colts	    0.471	    466	        412	            0.59094691	    0.11994691	    2.039097471							
Denver Broncos	        0.824	    401	        311	            0.681178291	    0.142821709	    2.427969052							
New York Giants	        0.235	    381	        439	            0.395738641	    0.160738641	    2.732556906							
Kansas City Chiefs	    0.353	    362	        328	            0.573123382	    0.220123382	    3.742097488							
				                                                        sum:	1.83447869								
*/







--Find cumulative leading into X week
Drop table if exists #cumulative_team_PPR

Select fs1.Week
    , fs1.Team
    , round(sum(fs2.team_PPR),2) as cumulative_team_PPR
Into #cumulative_team_PPR
From #fff_scores fs1
    left join #fff_scores fs2
        on fs1.Team = fs2.Team
        and fs1.Week > fs2.Week
Group by fs1.Week, fs1.Team 
Order by fs1.Team, fs1.Week

Select *
From #cumulative_team_PPR

-------------
--Matchups
-------------
Drop table if exists #opponents

Select distinct f.[Week]
    , f.Team
    , t1.Opp
Into #opponents
From #FFF_scores f
    join [NM\NM287071].nfl_2025 t1
        on f.Team = t1.Team
        and f.[Week] = t1.[Week]

Select *
From #opponents
Order by 1,2


--Comparison of FFF win vs real win, non-predictive but rather retrospective
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
        , Case when f.team_PPR > fo.team_PPR then 'W' 
                when f.team_PPR < fo.team_PPR then 'L'
                when f.team_PPR = fo.team_PPR then 'T'
                end as FFF_win
        , left(t1.Result, 1) as Result
        , f.team_PPR
        , o.Opp
        , fo.team_PPR as opp_sum
    From #FFF_scores f
        join #opponents o
            on f.Team = o.Team
            and f.[Week] = o.[Week]
        join #FFF_scores fo --opponent score
            on fo.Team = o.opp
            and fo.[Week] = o.[Week]
        join [NM\NM287071].nfl_2025 t1
            on t1.Team = f.team
            and t1.[Week] = f.[Week]
) x
--Where x.week = 1
Order by 1, 2

Select *
From #matchups
ORder by 1, 2





-------------------------------------------------------
--Predictive part
--Compare running avg of FFF to see "who will win"
-------------------------------------------------------
Drop table if exists #FFF_predict

Select *
    , Case when x.cumulative_team_PPR > x.cumulative_opp_PPR then 'W' 
                when x.cumulative_team_PPR < x.cumulative_opp_PPR then 'L'
                --when x.lag_team_ra = x.lag_opp_ra then 'T'
                end as FFF_predict
Into #FFF_predict
From(
    Select ctp.Week
            , ctp.Team
            , ctp.cumulative_team_PPR
            , m.Opp
            , ctpo.cumulative_team_PPR as cumulative_opp_PPR
            --, lag(f.team_sum, 1) over(partition by f.team order by f.Week) as last_team_sum
            --, lag(fo.team_sum, 1) over(partition by fo.team order by f.Week) as last_opp_sum
            , m.Result
    From #cumulative_team_PPR ctp
        join #matchups m
            on ctp.Team = m.Team
            and ctp.[Week] = m.[Week]
        left join #cumulative_team_PPR ctpo
            on ctpo.Team = m.Opp
            and ctpo.[Week] = m.[Week]
) x
Order by 2,1

--Currently two records for each game, doesn't matter for %
select *
From #FFF_predict
Order by Week, Team

--how many of them count? Week 2-18 where there is something to use
Select count(*)
From #FFF_predict
Where week != 1

--Check matches
--According to this, running average was 58.2% correct for weeks 2-18
Select round((sum(matching_result)/512.0)*100,2) as pct_correct
From (
    Select *
        , case when FFF_predict = Result then 1
            when FFF_predict != Result then 0
            else 0 end as matching_result
    From #FFF_predict
) x


--Per week?
--None correct in week 1, peak of 80% in week 7
Select Week
    , round((sum(matching_result)/cast(count(Team) as float))*100,2) as pct_correct
From (
    Select Week
    , Team
        , case when FFF_predict = Result then 1
            when FFF_predict != Result then 0
            else null end as matching_result
    From #FFF_predict fffp
) x
Group by Week
Order by 1


--count of correct out of games
Select sum(matching_result)/2 as correct
    , count(*)/2 as games
From (
    Select *
    , case when FFF_predict = Result then 1
            when FFF_predict != Result then 0
        else null end as matching_result
From #FFF_predict
Where week != 1 --these don't count
) x





------------------------------------------------
--Random Intrigue
------------------------------------------------

--Count per team in top X fantasy showings this year
Select Team
    , count(*) count_top10
    --, min(all_rnk) as highest_performer
From(
    Select *
        --, team_rnk = dense_rank() over(partition by Team order by PPR desc)
        , all_rnk = dense_rank() over(order by PPR desc) 
    From #individuals
    --Where week between 11 and 14
) x
Where all_rnk <= 10
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



--Count per player in top 100 fantasy showings this year
Select Player
    , count(*) as count
    --, min(all_rnk) as highest_performer
From(
    Select *
        --, team_rnk = dense_rank() over(partition by Team order by PPR desc)
        , all_rnk = dense_rank() over(order by PPR desc)
    From #individuals
) x
Where all_rnk <= 100
Group by Player
Order by 2 desc


--Team's best performance in the year
Select Team, Week, Player, PPR
From (
    Select *
        , team_rnk = dense_rank() over(partition by Team order by PPR desc)
        , all_rnk = dense_rank() over(order by PPR desc)
    From #individuals
) x
Where team_rnk = 1
order by PPR desc


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



--Percent of team's FFF points that came from individual player
Select tsr.Team
    , x.Player
    , x.Pos
    , round((player_fff_sum/Team_Sum_2025)*100,2) as player_contribution_pct
From #team_sum_ranks tsr
    join (Select Team
                , Player
                , Pos
                , sum(PPR) as player_fff_sum
            From #fff_lineups
            Group by Team, Player, Pos
        ) x
        on tsr.Team = x.Team
Order by player_contribution_pct desc

--Percent of team's FFF points that came from specific Position
Select tsr.Team
    , x.Pos
    , round((player_fff_sum/Team_Sum_2025)*100,2) as player_contribution_pct
From #team_sum_ranks tsr
    join (Select Team
                , Pos
                , sum(PPR) as player_fff_sum
            From #fff_lineups
            Group by Team, Pos
        ) x
        on tsr.Team = x.Team
Order by player_contribution_pct desc

--Average FFF points for a Team per week by position
Select Team
    , Week
    , Pos
    , round(avg(PPR)/count(*), 2) as avg_pos_team_week
From #fff_lineups fl
Group by Team
    , Week
    , Pos
Order by Team, Week, avg_pos_team_week desc






--What's useful for betting? ML is nice but what about Spread?
--Or do we go with applicability and creating a "League"




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
From #cumulative_team_PPR ra


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
        , played_rnk = row_number() over(Partition by Week, LeagueTeam order by l.cumulative_team_PPR desc)
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
    , round(sum(x.team_PPR), 2) as LeagueTeam_sum
Into #weekly_league
From(
    Select pt.Week
        , pt.LeagueTeam
        , pt.Team
        , scores.team_PPR
    From #played_teams pt
        join (Select Week, Team, team_PPR
              From #FFF_scores) scores
            on scores.Week = pt.[Week]
            and scores.Team = pt.Team
) x
Group by x.Week
    , x.LeagueTeam

Select *
From #weekly_league

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