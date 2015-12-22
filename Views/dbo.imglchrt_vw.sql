SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imglchrt_vw] AS SELECT * from [CVO_Control]..imglchrt


                                             
GO
GRANT REFERENCES ON  [dbo].[imglchrt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imglchrt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imglchrt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imglchrt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imglchrt_vw] TO [public]
GO
