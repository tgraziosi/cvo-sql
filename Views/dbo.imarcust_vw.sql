SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[imarcust_vw] AS SELECT * from [CVO_Control]..imarcust


                                             
GO
GRANT REFERENCES ON  [dbo].[imarcust_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imarcust_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imarcust_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imarcust_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imarcust_vw] TO [public]
GO
