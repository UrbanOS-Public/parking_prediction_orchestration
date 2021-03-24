/* update total_cnt in the table parkmobile_zone_occupancy (equivalent to mtr_cnt_month in [parking_zone_occupancy])
*/

/* step 1: update total_cnt for the zones included in IPS data */
BEGIN
DECLARE @yearidx as int
DECLARE @maxyear as int
DECLARE @monthidx as int
DECLARE @maxmonth as int

set @maxmonth = 12
set @monthidx = 1
set @maxyear = 2020
set @yearidx = 2015   -- change this to the year you are updating

while (@yearidx <= @maxyear)
begin
    while (@monthidx <= @maxmonth)
    begin
        UPDATE o
        set o.total_cnt = cnt.mtr_cnt
        --select *
        FROM dbo.parkmobile_zone_occupancy o
        INNER JOIN
            (SELECT z.zone_name, count (DISTINCT trans.[meter]) as mtr_cnt
            FROM 
                [dbo].[transf_parking_time] trans
                    -- [dbo].[transf1819_parking_time] is the table of processed transactions in 2018-2019, 
                    -- change this to the equivalent in your case
            INNER JOIN  [dbo].[ref_meter] m 
            ON trans.meter = m.meter
            AND datepart(year, startdate) = @yearidx
            AND datepart(month, startdate) = @monthidx
            AND m.zone_name is not null
            INNER JOIN [dbo].[ref_zone] z
            ON m.zone_name = z.zone_name AND z.zone_eff_flg = 1
            GROUP BY z.zone_name)  cnt
        ON o.zone_name = cnt.zone_name
        AND datepart(year, o.semihour) = @yearidx
        AND datepart(month, o.semihour) = @monthidx

        set @monthidx = @monthidx + 1

    end

    /* step 2: update total_cnt for the zones in parkmobile only */
    update o	--974784 rows
    set [total_cnt] = ref.[total_cnt]
    from [dbo].[parkmobile_zone_occupancy] o
    inner join 
            (
            SELECT DISTINCT [zone_name], [total_cnt] 
            FROM  [dbo].[ref_zone]
            WHERE [zone_eff_flg] = 1
            ) ref
    ON o.[zone_name] = ref.[zone_name]
    where datepart(year, o.[semihour]) = @yearidx
    and o.total_cnt is NULL

    set @yearidx = @yearidx + 1
    set @monthidx = 1
end
END;