SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_affiliated_vw]
as

select a.customer_code, 
ar.customer_name, 
a.affiliated_code, 
aa.customer_name affiliated_name
from cvo_affiliated_customers a 
inner join arcust ar on ar.customer_code = a.customer_code
inner join arcust aa on aa.customer_code = a.affiliated_code


GO
GRANT REFERENCES ON  [dbo].[cvo_affiliated_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_affiliated_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_affiliated_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_affiliated_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_affiliated_vw] TO [public]
GO
