SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

 


CREATE VIEW [dbo].[glcon_vw]
AS SELECT * FROM glcon
WHERE status_type != 2



 
GO
GRANT REFERENCES ON  [dbo].[glcon_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[glcon_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[glcon_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[glcon_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[glcon_vw] TO [public]
GO
