SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Tine Graziosi
-- Create date: 10/1/2012
-- Description:	return the TL status for a POM part
-- select dbo.f_cvo_get_part_tl_status('bcgcolink5316',getdate())
-- tag 090414 - check pom date too. don't set a status if the item has no pom date
--  takes care of oddball pom's on size and such
-- =============================================
CREATE FUNCTION [dbo].[f_cvo_get_part_tl_status] 
(
	-- Add the parameters for the function here
/*	@coll varchar(10),
	@style varchar(40),
	@color_desc varchar(40),
*/  @part_no varchar(30),
	@asofdate datetime
)
RETURNS varchar
AS
BEGIN
	-- Declare the return variable here
	DECLARE @tl varchar
	
	declare @coll varchar(10), @style varchar(40), @color_desc varchar(40)
	
	select @coll = i.category, @style = ia.field_2, @color_desc = ia.field_3
	from inv_master i (nolock) inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
	where i.part_no = @part_no 
	-- if the part is not pom then stop right away.... needed for size pom's (jm185, for example)
	and @asofdate > isnull(ia.field_28,@asofdate)

	-- Add the T-SQL statements to compute the return value here
	
	-- check if the entire style is POM, or if it's partial
	
	select @tl = ''	

	if not exists (select 1 from cvo_pom_tl_status 
		where [COLLECTION] = @coll and STYLE = @style and color_desc = @color_desc
			and @asofdate between eff_date and obs_date) 
		begin 
			set @tl = 'X'
			return @tl
		end
	if exists (select 1 from cvo_pom_tl_status 
		where collection =@coll and STYLE = @style and color_desc = @color_desc 
		and Style_pom_status = 'all'
		and @asofdate between eff_date and obs_date) 
		begin	
			set @tl = (select top 1 tl from cvo_pom_tl_status 
			where [collection] = @COLL and  style = @STYLE and color_desc = @color_desc
			 and @asofdate between eff_date and obs_date)
			RETURN @tl
	    end
	if exists (select 1 from cvo_pom_tl_status 
		where collection =@coll and STYLE = @style and Style_pom_status = 'all'
		and @asofdate between eff_date and obs_date) 
		begin	
			set @tl = (select top 1 tl from cvo_pom_tl_status 
			where [collection] = @COLL and  style = @STYLE 
			 and @asofdate between eff_date and obs_date)
			RETURN @tl
	    end
	 if exists (select 1 from cvo_pom_tl_status 
		where [collection] = @COLL and  style = @STYLE and Style_pom_status = 'partial'
		and @asofdate between eff_date and obs_date)
		begin
			set @tl = (select top 1 tl from cvo_pom_tl_status 
			where [collection] = @COLL and  style = @STYLE and color_desc = @color_desc 
				and @asofdate between eff_date and obs_date)
		end

	-- Return the result of the function
	RETURN ISNULL(@tl,'')

END


GO
GRANT EXECUTE ON  [dbo].[f_cvo_get_part_tl_status] TO [public]
GO
