SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Elizabeth LaBarbera
-- Create date: 11/20/2013
-- Description:	Updates Table for Handshake Qty's
-- EXEC HS_Inventory_QtyUpd_SP
-- EXEC HS_Inventory_QtyUpd_v8_SP
--  select * FROM cvo_hs_inventory_qtyupd_v8 where diff = 'y' or issynced = 0
-- UPDATE cvo_hs_inventory_qtyupd_v8 SET issynced = 1 WHERE issynced = 0
--select * FROM cvo_hs_inventory_qtyupd_v8 where sku = 'asmusitor5316'
-- UPDATE: 11/13/14 - USE NEW INVENTORY TABLE V8
-- update: 3/1/2017 - tag - rewrite
-- =============================================
create PROCEDURE [dbo].[HS_Inventory_QtyUpd_v8_SP]
AS
    BEGIN
        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;

-- Update Handshake Inventory Qty's

        IF ( OBJECT_ID('dbo.cvo_hs_inventory_qtyupd_v8') IS NULL )
            BEGIN
                SET ANSI_NULLS ON;
                SET QUOTED_IDENTIFIER ON;
                SET ANSI_PADDING ON;

                CREATE TABLE dbo.cvo_hs_inventory_qtyupd_v8
                    (
                      SKU VARCHAR(30) NOT NULL ,
                      ItemType VARCHAR(7) NOT NULL ,
                      ShelfQty DECIMAL(38, 8) NULL ,
                      WarningLevel INT NOT NULL ,
                      IsAvailable INT NOT NULL ,
                      RestockDate DATETIME NULL ,
                      isSynced INT NOT NULL ,
                      Diff VARCHAR(1) NOT NULL ,
                      OldShelfQty DECIMAL(38, 8) NULL ,
                      date_added DATETIME NULL ,
                      date_modified DATETIME NULL
                    )
                ON  [PRIMARY];
                CREATE CLUSTERED INDEX idx_hs_inv_upd_prtno ON dbo.cvo_hs_inventory_qtyupd_v8
                (
                SKU ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];
                SET ANSI_PADDING OFF;
            END;

		-- reset data
        UPDATE  dbo.cvo_hs_inventory_qtyupd_v8
        SET     isSynced = 0 ,
                Diff = 'N' ,
                OldShelfQty = ShelfQty
        WHERE   isSynced = 1
                AND Diff = 'Y';

		
        IF ( OBJECT_ID('tempdb.dbo.#Data') IS NOT NULL )
            DROP TABLE #Data;
        SELECT DISTINCT
                i.sku ,
                'variant' AS ItemType ,
                CASE WHEN i.COLL = 'SM'
                          AND '1/23/2017' > GETDATE() ---- 1/4/2017 - fudge SM inventory levels until released
                          THEN 2000
                     WHEN qty_avl < 0
                          OR i.COLL = 'ch' THEN 0
                     ELSE cia.qty_avl
                END AS ShelfQty ,
                CASE WHEN i.[category:1] IN ( 'EOS', 'EOR', 'QOP', 'RED',
                                              'ME SELL-DOWN' ) -- 2/10/2017
                          THEN 0
                     ELSE 5
                END AS WarningLevel ,
                CASE WHEN i.[category:1] IN ( 'EOR', 'EOS', 'SUN SPECIALS' ) /* remove 01/07/15 ,'RED') */
                          AND qty_avl <= 0 THEN 0    -- added RED 4/22
                     ELSE 1
                END AS IsAvailable ,
                CASE WHEN cia.qty_avl > 50 AND cia.NextPODueDate IS NOT NULL THEN NULL ELSE cia.nextpoduedate end AS RestockDate
        INTO    #Data
        FROM    cvo_hs_inventory_8 i ( NOLOCK )
                LEFT OUTER JOIN cvo_item_avail_vw cia (NOLOCK) ON i.sku = cia.part_no
                                                         AND cia.location = '001';

		CREATE CLUSTERED INDEX idx_data_prtno ON #data
                (
                SKU ASC
                )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY];
                SET ANSI_PADDING OFF;

        UPDATE  #Data
        SET     ShelfQty = 2000 ,
                IsAvailable = 1
        WHERE   sku IN (
                SELECT  t1.sku
                FROM    cvo_hs_inventory_8 t1 ( NOLOCK )
                        JOIN #Data t2 ON t1.sku = t2.sku
                        JOIN inv_master_add ia ( NOLOCK ) ON t1.sku = ia.part_no
                WHERE   ( APR IN ( 'Y', 'yy' ) -- removed 031315 -- or t1.sku like 'AS%' -- fudge aspire inventory 2/16/2015
                          OR t1.sku = 'ETREADER'
                          AND t1.ShelfQty <> 2000
                        )
                        OR ISNULL(ia.field_30, '') = 'Y' -- kits 061016
						); 

        UPDATE  #Data
        SET     ShelfQty = ( SELECT CASE WHEN qty_avl < 0 THEN 0
                                         ELSE qty_avl
                                    END
                             FROM   cvo_item_avail_vw
                             WHERE  part_no = 'IZZCLDISPLAY'
                                    AND location = '001'
                           )
        WHERE   sku = 'IZCLDISKITA';

        UPDATE  #Data
        SET     ShelfQty = ( SELECT CASE WHEN qty_avl < 0 THEN 0
                                         ELSE qty_avl
                                    END
                             FROM   cvo_item_avail_vw
                             WHERE  part_no = 'IZZDISCB8'
                                    AND location = '001'
                           )
        WHERE   sku = 'IZZTR90KIT';

		-- end gathering

		-- SELECT * FROM #Data AS d
		-- SELECT * FROM dbo.CVO_HS_INVENTORY_QTYUPD AS hiq

		-- delete sku's no longer in HS

        DELETE  FROM dbo.cvo_hs_inventory_qtyupd_v8
        WHERE   NOT EXISTS ( SELECT 1
                             FROM   #Data
                             WHERE  #Data.sku = cvo_hs_inventory_qtyupd_v8.SKU );

		-- update existing entries

        UPDATE  hiq
        SET     hiq.ShelfQty = d.ShelfQty ,
                hiq.OldShelfQty = hiq.ShelfQty ,
                hiq.WarningLevel = d.WarningLevel ,
                hiq.IsAvailable = d.IsAvailable ,
                hiq.RestockDate = d.RestockDate ,
                hiq.isSynced = 0 ,
                hiq.Diff = 'Y' ,
                hiq.date_modified = GETDATE()
		-- SELECT * 
        FROM    #Data d
                JOIN dbo.cvo_hs_inventory_qtyupd_v8 AS hiq ON hiq.SKU = d.sku
        WHERE   hiq.ShelfQty <> d.ShelfQty
                OR hiq.WarningLevel <> d.WarningLevel
                OR hiq.IsAvailable <> d.IsAvailable
                OR hiq.RestockDate <> d.RestockDate;

		-- add new ones
        INSERT  dbo.cvo_hs_inventory_qtyupd_v8
                ( SKU ,
                  ItemType ,
                  ShelfQty ,
                  WarningLevel ,
                  IsAvailable ,
                  RestockDate ,
                  isSynced ,
                  Diff ,
                  OldShelfQty ,
                  date_added
		        )
                SELECT  d.sku ,
                        d.ItemType ,
                        d.ShelfQty ,
                        d.WarningLevel ,
                        d.IsAvailable ,
                        d.RestockDate ,
                        0 AS isSynced ,
                        'Y' AS diff ,
                        0 AS OldShelfQty ,
                        GETDATE()
                FROM    #Data AS d
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   dbo.cvo_hs_inventory_qtyupd_v8 AS hiq
                                     WHERE  hiq.SKU = d.sku );

    END;


	

GO
GRANT EXECUTE ON  [dbo].[HS_Inventory_QtyUpd_v8_SP] TO [public]
GO
