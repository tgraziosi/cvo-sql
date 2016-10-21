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
        DROP TABLE CVO_HS_INVENTORY_QTYUPD_OLD;
        SELECT  *
        INTO    CVO_HS_INVENTORY_QTYUPD_OLD
        FROM    CVO_HS_INVENTORY_QTYUPD;
-- select * from CVO_HS_INVENTORY_QTYUPD_OLD
-- Update Handshake Inventory Qty's

        IF ( OBJECT_ID('tempdb.dbo.#Data') IS NOT NULL )
            DROP TABLE #Data;
        SELECT DISTINCT
                sku ,
                'variant' AS ItemType , 
-- don't allow negative stock qty's - 030615
                CASE WHEN qty_avl < 0
                          OR t1.COLL = 'ch' THEN 0
                     ELSE qty_avl
                END AS ShelfQty ,
                CASE WHEN [category:1] IN ( 'EOS', 'EOR', 'QOP', 'RED' )
                     THEN 0 
-- 8/26/2015
	 -- 10/23/15 - remove per hk -- WHEN [CATEGORY:1] = 'CH SELL-DOWN' THEN 10
                     ELSE 5
                END AS WarningLevel ,
                CASE WHEN [category:1] IN ( 'EOR', 'EOS', 'SUN SPECIALS' ) /* remove 01/07/15 ,'RED') */
                          AND qty_avl <= 0 THEN 0    -- added RED 4/22
                     ELSE 1
                END AS IsAvailable ,
                t3.NextPODueDate AS RestockDate ,
                0 AS isSynced
        INTO    #Data
        FROM    cvo_hs_inventory_8 t1 (nolock)
                LEFT OUTER JOIN cvo_item_avail_vw t3 ON t1.sku = t3.part_no
                                                        AND t3.location = '001';

-- select * from #DATA where sku o
        UPDATE  #Data
        SET     RestockDate = NULL
        WHERE   RestockDate IS NOT NULL
                AND ShelfQty > 50;

        UPDATE  #Data
        SET     ShelfQty = 2000 ,
                IsAvailable = 1  
-- select * from #DATA
        WHERE   sku IN (
--select t1.SKU from cvo_hs_inventory_everything7 t1
                SELECT  t1.sku
                FROM    cvo_hs_inventory_8 t1 (nolock)
                        JOIN #Data t2 ON t1.sku = t2.sku
                        JOIN inv_master_add t3 (nolock) ON t1.sku = t3.part_no
                WHERE   ( APR IN ( 'Y', 'yy' ) -- removed 031315 -- or t1.sku like 'AS%' -- fudge aspire inventory 2/16/2015
                          OR t1.sku = 'ETREADER'
                          AND t1.ShelfQty <> 2000
                        )
-- OR t1.[category:2]='revo' -- 061016 - show real inventory
                        OR ISNULL(t3.field_30, '') = 'Y' ); -- kits 061016

        DROP TABLE CVO_HS_INVENTORY_QTYUPD;
        SELECT  T1.sku ,
                T1.ItemType ,
                T1.ShelfQty ,
                T1.WarningLevel ,
                T1.IsAvailable ,
                T1.RestockDate ,
                T1.isSynced ,
                CASE WHEN T1.IsAvailable <> T2.IsAvailable THEN 'Y'
                     ELSE 'N'
                END AS Diff ,
                T2.ShelfQty AS OldShelfQty
        INTO    CVO_HS_INVENTORY_QTYUPD
        FROM    #Data T1
                LEFT OUTER JOIN CVO_HS_INVENTORY_QTYUPD_OLD T2 (NOLOCK) ON T1.sku = T2.SKU
        ORDER BY SKU;

        UPDATE  CVO_HS_INVENTORY_QTYUPD
        SET     ShelfQty = ( SELECT CASE WHEN qty_avl < 0 THEN 0
                                         ELSE qty_avl
                                    END
                             FROM   cvo_item_avail_vw
                             WHERE  part_no = 'IZZCLDISPLAY'
                                    AND location = '001'
                           )
        WHERE   SKU = 'IZCLDISKITA';

--8/26/2015
        UPDATE  CVO_HS_INVENTORY_QTYUPD
        SET     ShelfQty = ( SELECT CASE WHEN qty_avl < 0 THEN 0
                                         ELSE qty_avl
                                    END
                             FROM   cvo_item_avail_vw
                             WHERE  part_no = 'IZZDISCB8'
                                    AND location = '001'
                           )
        WHERE   SKU = 'IZZTR90KIT';


-- 12/15/2014 -- delete entries more than a month old
        DELETE  FROM dbo.CVO_HS_INVENTORY_QTYUPD_AUDIT
        WHERE   TIMESTAMP < DATEADD(m, -1, GETDATE());

        INSERT  INTO CVO_HS_INVENTORY_QTYUPD_AUDIT
                SELECT  GETDATE() AS TIMESTAMP ,
                        SKU ,
                        ItemType ,
                        ShelfQty ,
                        WarningLevel ,
                        IsAvailable ,
                        RestockDate ,
                        isSynced ,
                        Diff ,
                        OldShelfQty
                FROM    CVO_HS_INVENTORY_QTYUPD;


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
    END;








GO
