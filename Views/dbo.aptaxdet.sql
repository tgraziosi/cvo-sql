SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[aptaxdet]
AS
SELECT	*
FROM artaxdet
GO
GRANT REFERENCES ON  [dbo].[aptaxdet] TO [public]
GO
GRANT SELECT ON  [dbo].[aptaxdet] TO [public]
GO
GRANT INSERT ON  [dbo].[aptaxdet] TO [public]
GO
GRANT DELETE ON  [dbo].[aptaxdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptaxdet] TO [public]
GO
