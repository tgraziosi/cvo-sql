SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


create view [dbo].[imdmapping_vw] as select * from CVO_Control.dbo.imdmapping

GO
GRANT REFERENCES ON  [dbo].[imdmapping_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[imdmapping_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[imdmapping_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[imdmapping_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[imdmapping_vw] TO [public]
GO
