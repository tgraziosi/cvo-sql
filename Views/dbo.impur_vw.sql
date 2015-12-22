SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[impur_vw] as select * from [CVO_Control].dbo.impur


GO
GRANT REFERENCES ON  [dbo].[impur_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[impur_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[impur_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[impur_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[impur_vw] TO [public]
GO
