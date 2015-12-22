SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--EXEC dbo.cvo_f_cvo_get_pom_tl_status_wrap_sp 'CBBLA3500'

CREATE PROC [dbo].[cvo_f_cvo_get_pom_tl_status_wrap_sp] @part_no varchar(30)
AS
BEGIN

	SELECT	dbo.f_cvo_get_pom_tl_status(c.category,ia.field_2,ia.field_3, getdate()) POM_status
	FROM	inv_master c (NOLOCK) 
	JOIN	inv_master_add ia (NOLOCK) 
	ON		c.part_no = ia.part_no
	WHERE	c.part_no = @part_no

END
GO
GRANT EXECUTE ON  [dbo].[cvo_f_cvo_get_pom_tl_status_wrap_sp] TO [public]
GO
