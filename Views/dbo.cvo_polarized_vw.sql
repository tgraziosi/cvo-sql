SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_polarized_vw]
AS

	SELECT	part_no,
			description
	FROM	dbo.f_get_polarized_list()

GO
GRANT SELECT ON  [dbo].[cvo_polarized_vw] TO [public]
GO
