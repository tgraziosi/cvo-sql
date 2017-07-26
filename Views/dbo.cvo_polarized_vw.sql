SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_polarized_vw]
AS

--	SELECT	part_no,
--			description
--	FROM	dbo.f_get_polarized_list()

	SELECT	a.part_no,
			b.description
	FROM	dbo.cvo_lens_options a (NOLOCK)
	JOIN	dbo.inv_master b (NOLOCK)
	ON		a.part_no = b.part_no

GO
GRANT SELECT ON  [dbo].[cvo_polarized_vw] TO [public]
GO
