SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE VIEW [dbo].[imarhdr_vw] AS SELECT * from [CVO_Control]..imarhdr


                                             
GO
GRANT REFERENCES ON  [dbo].[imarhdr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imarhdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imarhdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imarhdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imarhdr_vw] TO [public]
GO
