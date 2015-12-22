SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE VIEW [dbo].[imaphdr_vw] AS SELECT * from [CVO_Control]..imaphdr


                                             
GO
GRANT REFERENCES ON  [dbo].[imaphdr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imaphdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imaphdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imaphdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imaphdr_vw] TO [public]
GO
