SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select * from dbo.f_get_polarized_list()

CREATE FUNCTION [dbo].[f_get_polarized_list]()
RETURNS @rettab table (part_no varchar(30), description varchar(60))
AS
BEGIN
	-- DECLARATIONS
	DECLARE @strlist varchar(500)

	-- PROCESSING
	SELECT	@strlist = value_str 
	FROM	tdc_config (NOLOCK)
	WHERE	[function] = 'DEF_RES_TYPE_POLARIZED'
	
	INSERT INTO @rettab 	
	SELECT	a.listitem part_no, 
			b.description 
	FROM	f_comma_list_to_table(@strlist) a
	JOIN	inv_master b (NOLOCK) 
	ON		a.listitem = b.part_no

	RETURN
END
GO
GRANT REFERENCES ON  [dbo].[f_get_polarized_list] TO [public]
GO
GRANT SELECT ON  [dbo].[f_get_polarized_list] TO [public]
GO
