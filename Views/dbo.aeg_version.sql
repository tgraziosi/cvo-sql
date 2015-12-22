SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[aeg_version] AS SELECT * from CVO_Control..aeg_version


                                             
GO
GRANT REFERENCES ON  [dbo].[aeg_version] TO [public]
GO
GRANT SELECT ON  [dbo].[aeg_version] TO [public]
GO
GRANT INSERT ON  [dbo].[aeg_version] TO [public]
GO
GRANT DELETE ON  [dbo].[aeg_version] TO [public]
GO
GRANT UPDATE ON  [dbo].[aeg_version] TO [public]
GO
