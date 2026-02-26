-------------------------------------------------------------
--Stats On Tap SQL code
--Ensure data loaded from DataLoad
-------------------------------------------------------------



--First analysis: Fantasy Friendly Offense

--Wrap to pull up to Team level
Select Team, round(sum(cast(PPR as float)),2) as team_PPR
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
        FROM [NM\NM287071].nfl_2023 t1
    ) x 
    Where Pos in ('QB', 'RB', 'WR', 'TE', 'K')
    and (rnk = 1
    or (rnk = 2 and Pos in('RB', 'WR')))
--order by Team, posrnk, rnk

) y
Group by team
Order by team_PPR desc



Drop table Scratchdb_Research.[NM\NM287071].w923