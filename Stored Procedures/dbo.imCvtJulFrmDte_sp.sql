SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create procedure [dbo].[imCvtJulFrmDte_sp] (
	@p_mssql_dt		datetime,
	@p_julian		int OUTPUT
)
as

select @p_julian = datediff(dd,'1/1/1900',@p_mssql_dt)
select @p_julian = 693596 + @p_julian



GO
GRANT EXECUTE ON  [dbo].[imCvtJulFrmDte_sp] TO [public]
GO
