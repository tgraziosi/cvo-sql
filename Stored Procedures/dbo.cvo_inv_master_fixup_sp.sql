SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 4/4/2013
-- Description:	inv_master nighly fixes & updates
-- EXEC cvo_inv_master_fixup_sp
-- =============================================
CREATE PROCEDURE [dbo].[cvo_inv_master_fixup_sp] 


AS
BEGIN

	SET NOCOUNT ON;

-- Update UPC codes into inv_master
update inv_master set upc_code = u.upc from inv_master i join uom_id_code u on i.part_no = u.part_no where I.upc_code <> U.UPC OR I.UPC_CODE IS NULL


-- Inv Nightly update for setting BO based on POM
update t1 set DATETIME_2= ((select field_28 from inv_master_add t2 where t1.part_no=t2.part_no)+90) from inv_master_add T1 where datetime_2 is null and field_28 is not null
update t1 set DATETIME_2= NULL from inv_master_add T1 where datetime_2 is not null and field_28 is null  --EL 7/15/2014


-- -- Nightly Process to check Discontinue and BackOrder Date
-- First Pass check Backorder Date.  If it has passed, set obsolete flag
UPDATE inv_master set obsolete = 1 FROM inv_master i, inv_master_add a WHERE i.part_no = a.part_no and (a.datetime_2 <= getdate()   AND i.obsolete = 0)
UPDATE inv_master set obsolete = 1 FROM inv_master i, inv_master_add a WHERE i.part_no = a.part_no and  VOID = 'V' and i.obsolete=0    --EL 7/15/2014
UPDATE inv_master set obsolete = 0 FROM inv_master i, inv_master_add a WHERE i.part_no = a.part_no and ((a.datetime_2 is NULL OR a.datetime_2 > getdate()) AND i.obsolete = 1 AND VOID <> 'v')     --EL 7/15/2014

-- Second Pass check Discontinue Date
UPDATE inv_master set non_sellable_flag = 'Y'  FROM inv_master i, inv_master_add a
 WHERE i.part_no = a.part_no   AND a.datetime_1 <= getdate() AND i.non_sellable_flag = 'N'

-- TAG - 022414

-- Remove unmatched part_no's from inv_master_add
DELETE FROM INV_MASTER_ADD WHERE PART_NO = (SELECT T1.PART_NO FROM INV_MASTER_ADD T1 FULL OUTER JOIN INV_MASTER T2 ON T1.PART_NO=T2.PART_NO WHERE T2.PART_NO IS NULL)

-- MAINTAIN CVO_INV_MASTER_ADD TABLE
INSERT CVO_INV_MASTER_ADD (PART_NO, PRIM_IMG)   
SELECT PART_NO, 0 AS PRIM_IMG FROM INV_MASTER I
WHERE NOT EXISTS (SELECT 1 FROM CVO_INV_MASTER_ADD WHERE PART_NO = I.PART_NO)
AND TYPE_CODE IN ('FRAME','SUN')

-- turn on web saleable for new items.

update i set i.web_saleable_flag = 'Y' 
-- select ia.field_26,  ia.field_28, i.web_saleable_flag, i.part_no , i.category, ia.field_2
from inv_master i
join inv_master_add ia (NOLOCK) ON ia.part_no = i.part_no
where 1=1
 and ISNULL(i.web_saleable_Flag,'N') = 'N' 
 and ia.field_26  <= GETDATE()
 AND ISNULL(ia.field_28,'1/1/1900') = '1/1/1900'
 and ISNULL(ia.field_32,'') not in ('retail','hvc','costco')
 AND i.category<>'bt'
 AND i.type_code IN ('frame','sun')
 AND i.void = 'N'


-- mark Red styles as not web saleable
;with c as 
(select part_no, [dbo].[f_cvo_get_part_tl_status](part_no, getdate()) ryg_stat from inv_master (nolock)
where type_code in ('frame','sun'))
update i set web_saleable_flag = 'N'
-- select i.category brand, ia.field_2 style, i.part_no, c.ryg_stat, i.web_saleable_flag
from c 
join inv_master i (rowlock) on c.part_no = i.part_no
join inv_master_add ia (nolock) on ia.part_no = i.part_no
and c.ryg_stat = 'R'
and ISNULL(web_saleable_flag,'N') = 'Y'

-- 1/29/2015 - tag turn off APR status if the release date has passed

update inv_master_add with (rowlock) set field_35 = null 
-- select part_no, field_26 from inv_master_add
where isnull(field_35,'') in ('yy','y') and isnull(field_26,getdate()) < getdate()

END
GO
GRANT EXECUTE ON  [dbo].[cvo_inv_master_fixup_sp] TO [public]
GO
