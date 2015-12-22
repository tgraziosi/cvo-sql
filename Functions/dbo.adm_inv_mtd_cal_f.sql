SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 16/06/2014 - Add NOLOCK  
  
CREATE function [dbo].[adm_inv_mtd_cal_f]()   
  returns @table TABLE (period int, fiscal_start int) as  
begin  
	declare @mtd_ind int, @fiscal_start_mth int, @fiscal_year int,  
			@now int, @now_date datetime, @fy_date datetime, @beg_pltdate int, @fy_pltdate int,  
			@date_info varchar(14), @date datetime, @fy_int int  
  
	select	@mtd_ind = mtd_ind,  
			@fiscal_start_mth = fiscal_start_mth  
	from	adm_inv_mtd_calendar (NOLOCK)
	where	tran_type = 'H'  
  
	if @@rowcount = 0  
		select @mtd_ind = 1, @fiscal_start_mth = 1  
  
	select	@now_date = now,  
			@now = datediff(day,'1/1/1950',now) + 711858  
	from	adm_today  
  
	if @mtd_ind = 1  
	begin  
		select	@beg_pltdate = isnull((select max(beg_date)   
		from	dbo.adm_inv_mtd_calendar (NOLOCK) 
		where	reset_date <= @now_date and tran_type = '1'),-1)  
  
		if @beg_pltdate = -1  
		begin  
			select @beg_pltdate = isnull((select max(period) from dbo.adm_inv_mtd (nolock)),-1)  
			set @fy_pltdate = 0  
		end  
		else  
			select @fy_pltdate = isnull((select max(beg_date)   
			from dbo.adm_inv_mtd_calendar (NOLOCK) where reset_date <= @now_date and tran_type = '2'),0)  
  
		if @beg_pltdate = -1  
			set @beg_pltdate = 0  
	end  
  
	if @mtd_ind = 0  
	begin  
		set @now_date = dateadd(day,1-day(@now_date),@now_date)  
		set @fy_date = dateadd(month,@fiscal_start_mth - (case when month(@now_date) < @fiscal_start_mth then 12 else 0 end)  
				- month(@now_date),@now_date)  
  
		set @beg_pltdate =  dbo.adm_get_pltdate_f (@now_date)  
		set @fy_pltdate = dbo.adm_get_pltdate_f (@fy_date)  
	end  
  
	if @mtd_ind = 2  
	begin  
		select	@date_info = isnull((select max(convert(varchar(6),beg_date) + year_month + '01')  
		from	dbo.adm_inv_mtd_calendar (NOLOCK) where beg_date <= dbo.adm_get_pltdate_f (@now_date) and tran_type = 'C'),'')  
  
		if @date_info = ''  
			select @date_info = convert(varchar(6),dbo.adm_get_pltdate_f (dateadd(day,(1-day(@now_date)),@now_date))) +  
				convert(varchar(8),(year(@now_date) * 10000) + (month(@now_date) * 100) + '01')  
  
		set @beg_pltdate = convert(int,left(@date_info,6))  
		set @date = convert(datetime,right(@date_info,8))  
		set @date = dateadd(day,1-day(@date),@date)  
		set @date = dateadd(month,@fiscal_start_mth - (case when month(@date) < @fiscal_start_mth then 12 else 0 end) - month(@date),@date)  
  
		set @fy_int = (year(@date) * 100) + @fiscal_start_mth  
		select	@fy_pltdate = isnull((select max(beg_date)  
		from	dbo.adm_inv_mtd_calendar (NOLOCK) where year_month <= convert(varchar(6),@fy_int) and tran_type = 'C'),0)  
  
		if @fy_pltdate = 0  
			select @fy_pltdate = dbo.adm_get_pltdate_f (@date)  
	end  
  
	if @mtd_ind = 3  
	begin  
		select @beg_pltdate = isnull((select max(period_start_date) from glprd (NOLOCK) 
		where period_start_date <= dbo.adm_get_pltdate_f (@now_date)),NULL)  
		select @fy_pltdate = isnull((select max(period_start_date) from glystart_vw (NOLOCK)
		where period_start_date <= @beg_pltdate),@beg_pltdate)  
	end  
  
	if @mtd_ind = 4  
	begin  
		select @now = isnull((select convert(int,value_str) from config (nolock)   
		where flag = 'DIST_PLT_END_DATE'),-1)  
  
		if @now < 0  
			select @now = period_end_date from glco (NOLOCK) 
  
		select @beg_pltdate = isnull((select period_start_date from glprd (NOLOCK) 
		where period_end_date = @now),NULL)  
		select @fy_pltdate = isnull((select max(period_start_date) from glystart_vw  (NOLOCK)
		where period_start_date <= @beg_pltdate),@beg_pltdate)  
	end  
  
	insert @table  
	values( @beg_pltdate , @fy_pltdate)  
  
	return  
end  

GO
GRANT REFERENCES ON  [dbo].[adm_inv_mtd_cal_f] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_inv_mtd_cal_f] TO [public]
GO
