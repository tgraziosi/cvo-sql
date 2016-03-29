
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Elizabeth LaBarbera
-- Create date: 11/20/2013
-- Description:	Updates Table for Handshake Qty's
-- EXEC HS_Inventory_QtyUpd_SP
-- UPDATE: 11/13/14 - USE NEW INVENTORY TABLE V8
-- =============================================
CREATE PROCEDURE [dbo].[HS_Inventory_QtyUpd_SP]

AS
BEGIN
	SET NOCOUNT ON;

--Backup Old File 
DROP TABLE CVO_HS_INVENTORY_QTYUPD_OLD
SELECT * INTO CVO_HS_INVENTORY_QTYUPD_OLD FROM CVO_HS_INVENTORY_QTYUPD
-- select * from CVO_HS_INVENTORY_QTYUPD_OLD
-- Update Handshake Inventory Qty's

IF(OBJECT_ID('tempdb.dbo.#Data') is not null)   drop table #Data
select DISTINCT SKU, 'variant' as ItemType, 
-- don't allow negative stock qty's - 030615
case when qty_Avl < 0 OR t1.coll = 'ch' THEN 0 ELSE qty_avl end as ShelfQty, 
case when [category:1] in ('EOS','EOR','QOP','RED') THEN 0 
-- 8/26/2015
	 -- 10/23/15 - remove per hk -- WHEN [CATEGORY:1] = 'CH SELL-DOWN' THEN 10
	 ELSE 5 END as WarningLevel, 
CASE WHEN [category:1] in ('EOR','EOS','SUN SPECIALS') /* remove 01/07/15 ,'RED') */
	 and qty_avl <=0  THEN 0    -- added RED 4/22
ELSE 1 END as IsAvailable, 
t3.NextPODueDate as RestockDate,
0 as isSynced
INTO #Data
from cvo_hs_inventory_8 t1
left outer join CVO_ITEM_AVAIL_VW t3 on t1.sku=t3.part_no and t3.location='001'

-- select * from #DATA where sku o
UPDATE #DATA SET RestockDate =  NULL where  restockdate is not null and ShelfQty > 50

UPDATE #DATA SET ShelfQty = 2000, IsAvailable = 1  
-- select * from #DATA
where  SKU in (
--select t1.SKU from cvo_hs_inventory_everything7 t1
select t1.SKU from cvo_hs_inventory_8 t1
join #Data t2 on t1.sku=t2.sku
join inv_master_add t3 on t1.sku=t3.part_no
where (APR in('Y','yy') -- removed 031315 -- or t1.sku like 'AS%' -- fudge aspire inventory 2/16/2015
OR T1.SKU = 'ETREADER'
and t1.shelfqty <> 2000)
OR t1.[category:2]='revo')

DROP TABLE cvo_hs_inventory_qtyupd
select t1.*, 
CASE WHEN T1.IsAvailable <> T2.IsAvailable then 'Y' else 'N' end as Diff,
T2.ShelfQty as OldShelfQty
INTO CVO_HS_INVENTORY_QTYUPD 
from #Data T1
left outer join CVO_HS_INVENTORY_QTYUPD_OLD T2 ON T1.SKU=T2.SKU
Order by SKU

update CVO_HS_INVENTORY_QTYUPD set 
ShelfQty=(select case when Qty_avl < 0 then 0 else qty_avl end 
from cvo_item_avail_vw where part_no ='IZZCLDISPLAY' and location='001') 
where sku = 'IZCLDISKITA'

--8/26/2015
update CVO_HS_INVENTORY_QTYUPD set 
ShelfQty=(select case when Qty_avl < 0 then 0 else qty_avl end 
from cvo_item_avail_vw where part_no ='IZZDISCB8' and location='001') 
where sku = 'IZZTR90KIT'


-- 12/15/2014 -- delete entries more than a month old
delete from [dbo].[CVO_HS_INVENTORY_QTYUPD_AUDIT] 
 where timestamp < dateadd(m,-1,getdate())

insert into  CVO_HS_INVENTORY_QTYUPD_AUDIT
 select getdate() AS TIMESTAMP,* FROM cvo_hs_inventory_qtyupd


/*
select * from #Data where sku = 'BCDATTOR5617'

SELECT * FROM CVO_HS_INVENTORY_QTYUPD 
SELECT * FROM CVO_HS_INVENTORY_QTYUPD_OLD 

SELECT * FROM CVO_HS_INVENTORY_QTYUPD WHERE Diff = 'Y'
SELECT * FROM CVO_HS_INVENTORY_QTYUPD_OLD  WHERE Diff = 'Y'

SELECT IsAvailable, field_26, field_28, type_code, SUNPS, APR, [category:1], t1.*,t2.* FROM CVO_HS_INVENTORY_QTYUPD T1 join cvo_hs_inventory_everything7 T2 on T1.SKU=T2.SKU join inv_master_add t3 on t1.sku=t3.part_no join inv_master t4 on t3.part_no=t4.part_no
WHERE IsAvailable=0 and [category:1] not in('eos','eor','red','qop')
 Order by t1.sku


SELECT * FROM CVO_HS_INVENTORY_QTYUPD where IsAvailable = 1 and shelfQty < 5 order by SKU

*/

-- EXEC HS_Inventory_QtyUpd_SP
END




GO
