SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[smusers_1rec_vw] 
AS
	select top 1 user_id , user_name from smusers_vw
GO
GRANT SELECT ON  [dbo].[smusers_1rec_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[smusers_1rec_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[smusers_1rec_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[smusers_1rec_vw] TO [public]
GO
