/* update mtr_cnt_month in the table parking_zone_occupancy
*/

DECLARE @yearidx as int
DECLARE @monthidx as int
DECLARE @maxmonth as int
DECLARE @maxyear as int

set @maxmonth = 12
set @monthidx = 1
set @maxyear = 2020
set @yearidx = 2018

while (@yearidx <= @maxyear)
begin
    while (@monthidx <= @maxmonth)
    begin
        UPDATE o
        set o.mtr_cnt_month = cnt.mtr_cnt
        FROM dbo.parking_zone_occupancy o
        INNER JOIN
            (SELECT z.zone_name, count (DISTINCT trans.[meter]) as mtr_cnt
            FROM 
                [dbo].[transf_parking_time] trans 
                    -- [dbo].[transf1819_parking_time] is the table of processed transactions in 2018-2019, 
                    -- change this to the equivalent in your case
            INNER JOIN  [dbo].[ref_meter] m 
            ON trans.meter = m.meter
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

    UPDATE o
    set o.mtr_cnt_month = 0
    FROM dbo.parking_zone_occupancy o
    WHERE datepart(year, o.semihour) = @yearidx
    AND o.mtr_cnt_month is NULL

    set @yearidx = @yearidx + 1
    set @monthidx = 1
end