SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO





CREATE VIEW [dbo].[imglhdr_vw] AS SELECT * from [CVO_Control]..imglhdr 


                                             
GO
GRANT REFERENCES ON  [dbo].[imglhdr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imglhdr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imglhdr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imglhdr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imglhdr_vw] TO [public]
GO
