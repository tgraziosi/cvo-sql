SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE VIEW [dbo].[impymerr_vw] AS SELECT * from [CVO_Control]..impymerr



                                             
GO
GRANT REFERENCES ON  [dbo].[impymerr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[impymerr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[impymerr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[impymerr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[impymerr_vw] TO [public]
GO
