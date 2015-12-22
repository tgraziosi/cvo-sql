SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imcsherr_vw] AS SELECT * from [CVO_Control]..imcsherr


                                             
GO
GRANT REFERENCES ON  [dbo].[imcsherr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imcsherr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imcsherr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imcsherr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imcsherr_vw] TO [public]
GO
