SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imchterr_vw] AS SELECT * from [CVO_Control]..imchterr


                                             
GO
GRANT REFERENCES ON  [dbo].[imchterr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imchterr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imchterr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imchterr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imchterr_vw] TO [public]
GO
