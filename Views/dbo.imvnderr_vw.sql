SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imvnderr_vw] AS SELECT * from [CVO_Control]..imvnderr


                                             
GO
GRANT REFERENCES ON  [dbo].[imvnderr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imvnderr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imvnderr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imvnderr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imvnderr_vw] TO [public]
GO
