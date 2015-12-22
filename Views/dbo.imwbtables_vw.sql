SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE view [dbo].[imwbtables_vw]
as
select * from [CVO_Control].dbo.imwbtables


GO
GRANT REFERENCES ON  [dbo].[imwbtables_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imwbtables_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imwbtables_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imwbtables_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imwbtables_vw] TO [public]
GO
