SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_sch_demand_forecast] @batch_id	varchar(20),
					@buyer		varchar(10),
					@location	varchar(10),
					@vendor_no	varchar(12),
					@part_no	varchar(30),
					@category	varchar(10),
					@part_type	varchar(10),
					@end_date	datetime
  AS



declare @session_id		int,
	@start_month		int,
	@end_month		int
declare	@start_day		decimal(20,8),
	@end_day		decimal(20,8),
	@days_in_start		decimal(20,8),
	@days_in_end		decimal(20,8)
declare	@start_period		varchar(10),
	@end_period		varchar(10),
	@current_scenario	varchar(30)

declare @inv_unit_decimal	int, @temp varchar(10)	-- mls 1/9/02 SCR 28150

declare @start_factor		decimal(20,8),
	@end_factor		decimal(20,8),
	@first_timeid		int,
	@last_timeid		int

if @end_date <= getdate() return

SELECT @first_timeid = max(TIMEID) FROM EFORECAST_TIME WHERE FIRST_DAY <= GETDATE()
SELECT @start_factor = convert(decimal,DATEDIFF(dd, GETDATE(), (SELECT FIRST_DAY FROM EFORECAST_TIME WHERE TIMEID = @first_timeid + 1)))
			/ convert(decimal,DATEDIFF(dd, (SELECT FIRST_DAY FROM EFORECAST_TIME WHERE TIMEID = @first_timeid), (SELECT FIRST_DAY FROM EFORECAST_TIME WHERE TIMEID = @first_timeid + 1)))	-- mls 7/22/05

SELECT @last_timeid = max(TIMEID) FROM EFORECAST_TIME WHERE FIRST_DAY <= @end_date
SELECT @end_factor = convert(decimal,DATEDIFF(dd, (SELECT FIRST_DAY FROM EFORECAST_TIME WHERE TIMEID = @last_timeid), @end_date))
			/ convert(decimal,DATEDIFF(dd, (SELECT FIRST_DAY FROM EFORECAST_TIME WHERE TIMEID = @last_timeid), (SELECT FIRST_DAY FROM EFORECAST_TIME WHERE TIMEID = @last_timeid + 1))) 	-- mls 7/22/05


select @inv_unit_decimal = 8					-- mls 1/9/02 SCR 28150 start
select @temp = isnull((select value_str 
  from config (nolock)
  where flag = 'INV_UNIT_DECIMALS'),'8')

if isnumeric(@temp) = 1
  select @inv_unit_decimal = convert(int,@temp)			-- mls 1/9/02 SCR 28150 end

CREATE TABLE #temp_inv_forecast (
  inv_forecast_location        VARCHAR(10) NOT NULL,
  inv_forecast_part_no         VARCHAR(30) NOT NULL,
  inv_forecast_demand_date     DATETIME NOT NULL,
  inv_forecast_qty             FLOAT NOT NULL
)

  INSERT #temp_inv_forecast(inv_forecast_location,inv_forecast_part_no,inv_forecast_demand_date,inv_forecast_qty)
  SELECT efl.LOCATION,efp.PART_NO, eft.FIRST_DAY, 
(ROUND(eff.FORECAST , case when isnull(m.allow_fractions,1) = 0 then 0 else @inv_unit_decimal end ) +
	ISNULL(eff.ADJUSTMENT, 0) ) -
round(CASE when eft.TIMEID = @first_timeid then
  (ROUND(eff.FORECAST , case when isnull(m.allow_fractions,1) = 0 then 0 else @inv_unit_decimal end ) +  ISNULL(eff.ADJUSTMENT, 0) ) *
  (1-@start_factor) else 0 end -
CASE when eft.TIMEID = @last_timeid then
  (ROUND(eff.FORECAST , case when isnull(m.allow_fractions,1) = 0 then 0 else @inv_unit_decimal end ) +  ISNULL(eff.ADJUSTMENT, 0) ) *
  (1-@end_factor) else 0 end , case when isnull(m.allow_fractions,1) = 0 then 0 else @inv_unit_decimal end )
  FROM EFORECAST_FORECAST eff (nolock)
  JOIN EFORECAST_TIME eft (nolock) on eft.TIMEID = eff.TIMEID 
    and eft.TIMEID BETWEEN @first_timeid AND @last_timeid
  JOIN EFORECAST_PRODUCT efp (nolock) on efp.PRODUCTID = eff.PRODUCTID
  JOIN EFORECAST_LOCATION efl (nolock) on efl.LOCATIONID = eff.LOCATIONID and efl.SESSIONID = eff.SESSIONID  -- mls 1/23/02 SCR 28222 
  JOIN #resource_demand t (nolock) on t.part_no = efp.PART_NO and t.location = efl.LOCATION and t.source = 'T'
  JOIN inv_master m (nolock) on m.part_no = efp.PART_NO

  INSERT #temp_inv_forecast(inv_forecast_location,inv_forecast_part_no,inv_forecast_demand_date,inv_forecast_qty)
  SELECT efl.LOCATION,efp.PART_NO, eft.FIRST_DAY, round((eff.QTY) *
	CASE	when eft.TIMEID = @first_timeid 		
			then @start_factor					-- prorate the first bucket's forecast
		when eft.TIMEID = @last_timeid 
			then @end_factor					-- prorate the last bucket's forecast
		else 1 end	, case when isnull(m.allow_fractions,1) = 0 then 0 else @inv_unit_decimal end )				-- all other bucket, include total forecast (multiply by 1)
  FROM EFORECAST_CUSTOMER_FORECAST eff (nolock)
  JOIN EFORECAST_TIME eft (nolock) on eft.TIMEID = eff.TIMEID 
    and eft.TIMEID BETWEEN @first_timeid AND @last_timeid
  JOIN EFORECAST_PRODUCT efp (nolock) on efp.PRODUCTID = eff.PRODUCTID
  JOIN EFORECAST_LOCATION efl (nolock) on efl.LOCATIONID = eff.LOCATIONID 
  JOIN #resource_demand t (nolock) on t.part_no = efp.PART_NO and t.location = efl.LOCATION and t.source = 'T'
  JOIN inv_master m (nolock) on m.part_no = efp.PART_NO
  where eff.QTY != 0

  INSERT  #resource_demand(batch_id, ilevel, part_no, qty, demand_date,
    location, source, status, commit_ed, source_no, pqty, p_used, type,
    vendor, uom, parent, buyer, prod_no, location2)
  SELECT
    @batch_id, 0, tf.inv_forecast_part_no, sum(tf.inv_forecast_qty),tf.inv_forecast_demand_date,
	tf.inv_forecast_location,'F',								-- set source to 'F' for Forecast
    'N',
    0, CONVERT( VARCHAR(20),tf.inv_forecast_demand_date, 12),							-- skk 03/01/01 source_no is MONTHYEAR for forecast entries -- dunno what it should be now  cnash
    1, 0, t.type, t.vendor, t.uom, '', t.buyer, 0, tf.inv_forecast_demand_date
  FROM #temp_inv_forecast tf
  JOIN #resource_demand t (nolock) on t.part_no = tf.inv_forecast_part_no and t.location = tf.inv_forecast_location and t.source = 'T'
  group by tf.inv_forecast_part_no, tf.inv_forecast_location, tf.inv_forecast_demand_date,
    t.type, t.vendor, t.uom, t.buyer
  order by tf.inv_forecast_part_no, tf.inv_forecast_demand_date
GO
GRANT EXECUTE ON  [dbo].[fs_sch_demand_forecast] TO [public]
GO
