SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_today] as 
select getdate() now
GO
GRANT REFERENCES ON  [dbo].[adm_today] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_today] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_today] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_today] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_today] TO [public]
GO
