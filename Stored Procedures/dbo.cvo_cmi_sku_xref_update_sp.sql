SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_cmi_sku_xref_update_sp]
AS
BEGIN

IF ( OBJECT_ID('tempdb.dbo.#cvo_cmi_sku_xref') IS NOT NULL )
    DROP TABLE #cvo_cmi_sku_xref;

CREATE TABLE #cvo_cmi_sku_xref
    (
        dim_id INT ,
        part_no VARCHAR(30) NULL ,
        upc_code VARCHAR(20) NULL ,
        collection VARCHAR(12) ,
        model VARCHAR(40) ,
        colorname VARCHAR(40) NULL ,
        eye_size DECIMAL(20, 8) NULL
    );


INSERT #cvo_cmi_sku_xref ( dim_id ,
                           collection ,
                           model ,
                           colorname ,
                           eye_size )
       SELECT DISTINCT dim_id ,
              Collection ,
              model ,
              ColorName ,
              eye_size
       FROM   cvo_cmi_catalog_view
       WHERE  1 = 1
              AND upc_code IS NULL;


-- SELECT * FROM #cvo_cmi_sku_xref AS ccsx

-- 
DECLARE @dim_id INT;
SELECT @dim_id = NULL;

SELECT @dim_id = MIN(dim_id)
FROM   #cvo_cmi_sku_xref;
WHILE @dim_id IS NOT NULL
    BEGIN
        UPDATE c
        SET    c.part_no = inv.part_no ,
               c.upc_code = inv.upc_code
        -- SELECT * 
        FROM   #cvo_cmi_sku_xref c
               INNER JOIN (   SELECT DISTINCT i.part_no ,
                                     i.upc_code ,
                                     ia.field_2 model ,
                                     ia.field_17 eye_size ,
                                     ia.field_3 colorname
                              FROM   inv_master_add ia
                                     INNER JOIN inv_master i ON i.part_no = ia.part_no
                              WHERE  i.type_code IN ( 'frame', 'sun' )
                                     AND i.void = 'n'
               -- and ia.field_2 = 'spirited'

               ) inv ON inv.model = c.model
                        AND inv.colorname = c.colorname
                        AND inv.eye_size = c.eye_size
        WHERE  c.dim_id = @dim_id;

        SELECT @dim_id = MIN(dim_id)
        FROM   #cvo_cmi_sku_xref
        WHERE  dim_id > @dim_id;
    END;


-- SELECT * FROM #cvo_cmi_sku_xref AS ccsx 

INSERT cvo_cmi_sku_xref ( dim_id ,
                          part_no ,
                          upc_code ,
                          date_added )
       SELECT DISTINCT dim_id ,
              part_no ,
              upc_code ,
              GETDATE()
       FROM   #cvo_cmi_sku_xref c
       WHERE  NOT EXISTS (   SELECT 1
                             FROM   cvo_cmi_sku_xref
                             WHERE  dim_id = c.dim_id )
              AND c.part_no IS NOT NULL;

--UPDATE i SET void = 'V', VOID_WHO = 'epicoradmin', void_date = getdate() 
--select * 
--from inv_master i 
--where part_no like 'opulua%' and void = 'N' and entered_who = 'cmi'

/*
SELECT * 
FROM dbo.cvo_cmi_sku_xref AS ccsx
LEFT OUTER JOIN dbo.cvo_cmi_dimensions AS d ON d.id = ccsx.dim_id
WHERE ccsx.part_no IN 
(SELECT part_no 
 FROM dbo.cvo_cmi_sku_xref
 GROUP BY part_no  
 HAVING COUNT(*) > 1)
 ORDER BY ccsx.part_no
*/

DELETE FROM dbo.cvo_cmi_sku_xref
WHERE NOT EXISTS (   SELECT 1
                     FROM   dbo.cvo_cmi_dimensions AS ccd
                     WHERE  ccd.id = dim_id );


-- SELECT * FROM dbo.cvo_cmi_catalog_view AS ccv WHERE ccv.model = 'leigh'
END

GO
GRANT EXECUTE ON  [dbo].[cvo_cmi_sku_xref_update_sp] TO [public]
GO
