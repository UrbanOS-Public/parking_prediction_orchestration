UPDATE o --10836288 rows
SET o.occu_cnt_rate = o.occu_mtr_cnt/(mtr_cnt_month*1.0)
	, o.occu_min_rate = o.occu_min/(mtr_cnt_month*30)
FROM dbo.parking_zone_occupancy o
WHERE o.mtr_cnt_month > 0


UPDATE o   --645600 rows
SET o.occu_cnt_rate = NULL
	, o.occu_min_rate = NULL
FROM dbo.parking_zone_occupancy o
WHERE o.mtr_cnt_month = 0


--- QA -----
select * from  dbo.parking_zone_occupancy -- should return o rows
where occu_cnt_rate > 1 or occu_min_rate > 1