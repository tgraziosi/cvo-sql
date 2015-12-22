SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[aptax]
AS
SELECT	*
FROM artax
GO
GRANT REFERENCES ON  [dbo].[aptax] TO [public]
GO
GRANT SELECT ON  [dbo].[aptax] TO [public]
GO
GRANT INSERT ON  [dbo].[aptax] TO [public]
GO
GRANT DELETE ON  [dbo].[aptax] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptax] TO [public]
GO
