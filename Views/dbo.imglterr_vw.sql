SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imglterr_vw] AS SELECT * from [CVO_Control]..imglterr 


                                             
GO
GRANT REFERENCES ON  [dbo].[imglterr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imglterr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imglterr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imglterr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imglterr_vw] TO [public]
GO
