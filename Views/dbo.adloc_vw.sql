SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adloc_vw] as

select 
	location ,
	name, 
	addr1 , 
	addr2, 
	addr3, 
	addr4, 
	addr5,
	phone , 
	void ,
	void_desc=
			CASE void
			WHEN 'V' THEN 'Yes'
			WHEN 'N' THEN 'No'
			ELSE ''
		END 
from locations_all

 
GO
GRANT REFERENCES ON  [dbo].[adloc_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adloc_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adloc_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adloc_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adloc_vw] TO [public]
GO
