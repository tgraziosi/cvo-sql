SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Tine Graziosi
-- Create date: 10/1/2012
-- Description:	return the TL status for a POM style
-- select dbo.f_cvo_get_pom_tl_status('bcbg','ambrosia','brown','2/1/2013')
-- =============================================
CREATE FUNCTION [dbo].[f_cvo_get_pom_tl_status] 
(
	-- Add the parameters for the function here
	@coll varchar(10),
	@style varchar(40),
	@color_desc varchar(40),
	@asofdate datetime
)
RETURNS varchar
AS
BEGIN
	-- Declare the return variable here
	DECLARE @tl varchar

	-- Add the T-SQL statements to compute the return value here
	
	-- check if the entire style is POM, or if it's partial
	
	select @tl = ''	

	if exists (select 1 from cvo_pom_tl_status 
		where collection =@coll and STYLE = @style and Style_pom_status = 'all'
		and @asofdate between eff_date and obs_date) 
		begin	
			set @tl = (select top 1 tl from cvo_pom_tl_status 
			where [collection] = @COLL and  style = @STYLE 
			 and @asofdate between eff_date and obs_date)
			RETURN isnull(@tl,'X')
	    end

	--if exists (select 1 from cvo_pom_tl_status 
	--	where collection =@coll and STYLE = @style and color_desc = @color_desc 
	--	and Style_pom_status = 'all'
	--	and @asofdate between eff_date and obs_date) 
	--	begin	
	--		set @tl = (select top 1 tl from cvo_pom_tl_status 
	--		where [collection] = @COLL and  style = @STYLE and color_desc = @color_desc
	--		 and @asofdate between eff_date and obs_date)
	--		RETURN @tl
	--    end

	 if exists (select 1 from cvo_pom_tl_status 
		where [collection] = @COLL and  style = @STYLE and Style_pom_status = 'partial'
		and @asofdate between eff_date and obs_date)
		begin
			set @tl = (select top 1 tl from cvo_pom_tl_status 
			where [collection] = @COLL and  style = @STYLE and color_desc = @color_desc 
				and @asofdate between eff_date and obs_date)
			return isnull(@tl,'X')
		end

	if not exists (select 1 from cvo_pom_tl_status 
		where [COLLECTION] = @coll and STYLE = @style and color_desc = @color_desc
			and @asofdate between eff_date and obs_date) 
		begin 
			set @tl = 'X'
			return @tl
		end
	
	-- Return the result of the function
	RETURN ISNULL(@tl,'')

END


GO
GRANT REFERENCES ON  [dbo].[f_cvo_get_pom_tl_status] TO [public]
GO
GRANT EXECUTE ON  [dbo].[f_cvo_get_pom_tl_status] TO [public]
GO
