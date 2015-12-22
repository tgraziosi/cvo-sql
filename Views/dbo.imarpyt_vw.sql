SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imarpyt_vw] AS SELECT * from [CVO_Control]..imarpyt



                                             
GO
GRANT REFERENCES ON  [dbo].[imarpyt_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imarpyt_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imarpyt_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imarpyt_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imarpyt_vw] TO [public]
GO
