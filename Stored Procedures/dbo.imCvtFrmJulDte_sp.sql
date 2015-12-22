SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create procedure [dbo].[imCvtFrmJulDte_sp] (
	@w_julian_date	int )
as

declare @w_calcd_date datetime

select @w_julian_date = @w_julian_date - 693596
select @w_calcd_date = '1/1/1900'
select dateadd(dd,@w_julian_date,@w_calcd_date) JulToSQLDate



GO
GRANT EXECUTE ON  [dbo].[imCvtFrmJulDte_sp] TO [public]
GO
