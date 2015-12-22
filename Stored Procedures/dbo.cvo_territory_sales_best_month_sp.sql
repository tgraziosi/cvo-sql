SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tine Graziosi
-- Create date: 2/25/2015
-- Description:	Territory Sales, Best Month

-- exec cvo_territory_sales_best_month_sp '20200,20202', '02/28/2015'

-- =============================================
CREATE PROCEDURE [dbo].[cvo_territory_sales_best_month_sp]
	@Terr varchar(1024) = null, @asofdate datetime = null
as
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

		declare 
				-- @asofdate datetime, 
			    @asofdately datetime 
				, @asofmonth varchar(6), @asofmonthly varchar(6)
				, @monthname varchar(20)

		if @asofdate is null select @asofdate = getdate()

		select  @asofdately = dateadd(yy,-1, @asofdate)
			   , @monthname = datename(mm,@asofdate)
			   , @asofmonth = left(convert(varchar(8),@asofdate,112),6)
			   , @asofmonthly = left(convert(varchar(8),@asofdately,112),6)

		declare @territory varchar(1024)
		set @territory = @Terr

		create table #territory (territory varchar(10), region varchar(3), salesperson varchar(40) )
		if @territory is null
		begin
		 insert into #territory (territory, region, salesperson)
		 select distinct a.territory_code, dbo.calculate_region_fn(a.territory_code), s.salesperson_name
			 from armaster a (nolock)
			 inner join arsalesp s (nolock) on a.salesperson_code = s.salesperson_code
		 where a.status_type = 1 -- active accounts only
		end
		else
		begin
		 insert into #territory (territory, region, salesperson)
		 select listitem, dbo.calculate_region_fn(listitem)
			, (select top 1 salesperson_name from arsalesp 
				    where territory_code = listitem and salesperson_code <> 'smithma'
			  and status_type = 1) salesperson
		 from dbo.f_comma_list_to_table(@territory) t
		 where exists (select 1 from armaster ar where ar.territory_code = t.listitem and ar.status_type = 1)
		end


		select  t.region
			, t.territory
			, t.salesperson
			, NetSalesTY = sum(case when best.yyyymm = @asofmonth then best.netsales else 0 end)
			, NetsalesLY = sum(case when yyyymm = @asofmonthly then netsales else 0 end)
			, BestMonthNetSales = sum(case when x_month = datepart(mm,@asofdate) and bestmonthrank = 1 then netsales else 0 end)
			, BestMonth = cast(min(case when x_month = datepart(mm,@asofdate) and bestmonthrank = 1 
						then right('00'+cast(x_month as varchar(2)),2) + '/01/' + cast(left(yyyymm,4) as varchar(4)) end) as datetime)
			, BestMonthEverNetSales = sum(case when bestmontheverrank = 1 then netsales else 0 end)
			, BestMonthEver = cast(min(case when bestmontheverrank = 1 
						then right('00'+cast(x_month as varchar(2)),2) + '/01/' + cast(left(yyyymm,4) as varchar(4)) end) as datetime)
	
		from #territory t 
		left outer join 
		(select ar.territory_code, round(sum(anet),2) NetSales, sbm.[year], sbm.x_month
		, (cast(sbm.[year] as varchar(4)) + right('00' + cast(sbm.x_month as varchar(2)),2) ) yyyymm
		-- , left(convert(varchar(8),yyyymmdd,112),6) yyyymm
		,Row_Number() over(partition by ar.territory_code
			 order by ar.territory_code, sum(anet) desc ) AS BestMonthEverRank
		,Row_Number() over(partition by ar.territory_code, sbm.x_month
		/*, right(left(convert(varchar(8),yyyymmdd,112),6),2) */
			 order by ar.territory_code,  sum(anet) desc ) AS BestMonthRank
		from 
		#territory t 
		inner join armaster ar (nolock) on ar.territory_code = t.territory
		inner join cvo_sbm_details sbm (nolock) on ar.customer_code = sbm.customer and ar.ship_to_code = sbm.ship_to
		
		group by ar.territory_code, year, x_month, left(convert(varchar(8),yyyymmdd,112),6)
		) best on t.territory = best.territory_code
		group by t.region, t.territory, t.salesperson
END
GO
