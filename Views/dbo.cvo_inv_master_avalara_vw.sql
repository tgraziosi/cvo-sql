SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_inv_master_avalara_vw] as
select 
i.part_no, 
description, 
taxcode = isnull(
	(select TOP 1 type_code from inv_master ii 
		inner join inv_master_add iia on ii.part_no = iia.part_no
	 where ii.type_code in ('SUN','FRAME') AND IIA.FIELD_2 = IA.FIELD_2),'FRAME'),
entered_date, entered_who,
IA.field_2 as Style,
i.type_code as ResType
from inv_master i inner join inv_master_add ia on i.part_no = ia.part_no
where void <> 'V'
--where entered_date >= '09/11/2011' and void <> 'Y'
GO
GRANT REFERENCES ON  [dbo].[cvo_inv_master_avalara_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_inv_master_avalara_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_inv_master_avalara_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_inv_master_avalara_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_inv_master_avalara_vw] TO [public]
GO
