SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Tine Graziosi
-- Create date: 10/1/2012
-- Description:	return the date a part first went in to a TL status
-- select dbo.f_cvo_get_part_first_tl_status('bcgcolink5316','r')
-- =============================================
create FUNCTION [dbo].[f_cvo_get_part_first_tl_status] 
(
	-- Add the parameters for the function here
/*	@coll varchar(10),
	@style varchar(40),
	@color_desc varchar(40),
*/  @part_no varchar(30),
    @status varchar(1)
)
RETURNS datetime
AS
BEGIN
	-- Declare the return variable here
	declare @asofdate datetime
	DECLARE @tl varchar
	
	declare @coll varchar(10), @style varchar(40), @color_desc varchar(40)
	
	select @coll = i.category, @style = ia.field_2, @color_desc = ia.field_3
	from inv_master i (nolock) inner join inv_master_add ia (nolock) on i.part_no = ia.part_no
	where i.part_no = @part_no

	-- Add the T-SQL statements to compute the return value here
	
	-- check if the entire style is POM, or if it's partial
	
	select @tl = @status -- look for the first occurrence of this status

	if not exists (select 1 from cvo_pom_tl_status 
		where [COLLECTION] = @coll and STYLE = @style and color_desc = @color_desc
			and tl = @tl) 
		begin 
			return null
		end
	if exists (select 1 from cvo_pom_tl_status 
		where collection =@coll and STYLE = @style and color_desc = @color_desc 
		and Style_pom_status = 'all'
		and tl = @tl) 
		begin	
			set @asofdate = (select min(eff_date) from cvo_pom_tl_status 
			where [collection] = @COLL and  style = @STYLE and color_desc = @color_desc
			 and tl = @tl)
			RETURN @asofdate
	    end
	if exists (select 1 from cvo_pom_tl_status 
		where collection =@coll and STYLE = @style and Style_pom_status = 'all'
		and tl = @tl) 
		begin	
			set @asofdate = (select min(eff_date) from cvo_pom_tl_status 
			where [collection] = @COLL and  style = @STYLE 
			 and tl = @tl)
			RETURN @asofdate
	    end
	 if exists (select 1 from cvo_pom_tl_status 
		where [collection] = @COLL and  style = @STYLE and Style_pom_status = 'partial'
		and tl = @tl)
		begin
			set @asofdate = (select min(eff_date) from cvo_pom_tl_status 
			where [collection] = @COLL and  style = @STYLE and color_desc = @color_desc 
				and tl = @tl)
				return @asofdate
		end

	-- Return the result of the function
	RETURN ISNULL(@asofdate,'')

END
GO
GRANT EXECUTE ON  [dbo].[f_cvo_get_part_first_tl_status] TO [public]
GO
