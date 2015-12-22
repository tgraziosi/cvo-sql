SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

                                         

create view [dbo].[set_org_vw]

as

select	Case (select ib_flag from glco)
	When 0
	Then  (select  organization_id  from Organization_all where outline_num= '1' ) 
	Else ''
	End as org_id

GO
GRANT REFERENCES ON  [dbo].[set_org_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[set_org_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[set_org_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[set_org_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[set_org_vw] TO [public]
GO
