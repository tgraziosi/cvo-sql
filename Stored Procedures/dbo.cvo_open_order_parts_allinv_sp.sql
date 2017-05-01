SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_open_order_parts_allinv_sp]
AS
    BEGIN

	-- exec cvo_open_order_parts_allinv_sp

        SET NOCOUNT ON
        ;

        IF
        (
            SELECT OBJECT_ID('tempdb..#main')
        ) IS NOT NULL
        BEGIN
            DROP TABLE #main
            ;
        END
        ;

        CREATE TABLE #main
        (
            brand VARCHAR(10),
            style VARCHAR(40),
            restype VARCHAR(10),
            gender VARCHAR(15),
            part_no VARCHAR(30),
            pom_date DATETIME,
            qty_avl DECIMAL(38, 8),
            location VARCHAR(10),
            nextpo VARCHAR(16),
            nextpoduedate DATETIME,
            nextpoonorder DECIMAL(21, 8),
            shipvia VARCHAR(4),
            plrecd VARCHAR(5),
            vendor VARCHAR(12),
            report_option VARCHAR(20),
            open_ord_qty DECIMAL(38, 8),
            daysoverdue VARCHAR(7)
        )
        ;

        DECLARE @location VARCHAR(12)
        ;
        SELECT @location = '001'
        ;

        INSERT #main
        EXEC cvo_open_order_backorder_sp @location, 4
        ;

        SELECT 
            #main.brand ,
            #main.style ,
            #main.restype ,
            #main.gender ,
            #main.part_no ,
            #main.pom_date ,
            #main.qty_avl ,
            #main.location ,
            #main.nextpo ,
            #main.nextpoduedate ,
            #main.nextpoonorder ,
            #main.shipvia ,
            #main.plrecd ,
            #main.vendor ,
            #main.report_option ,
            #main.open_ord_qty ,
            #main.daysoverdue, 
			ISNULL(inv.location,'') alt_loc ,
            ISNULL(inv.qty_avl,0) alt_qty_avl
        FROM
            #main
            LEFT OUTER JOIN
            (
                SELECT DISTINCT
                    iav.part_no, iav.location, iav.qty_avl
                FROM cvo_item_avail_vw AS iav
                WHERE
                    iav.location IN
                    (
                        SELECT la.location
                        FROM dbo.locations_all AS la
                        WHERE
                            1 = 1
                            AND la.location <> @location
                            AND
                            (
                                la.location < '200'
                                OR location >= '999'
                            )
                            AND location NOT IN ( '003', '004', '005', '006', '007', 
												  '008', '009', '014', '100 - JASZ',
                                                    '1011-TRUNK'
                                                )
                            AND void = 'n'
                    )
                    AND iav.qty_avl > 0
                    AND EXISTS
                (
                    SELECT 1 FROM #main WHERE #main.part_no = iav.part_no
                )
            ) inv
                ON inv.part_no = #main.part_no
        ;

    END
    ;

    GRANT EXECUTE
    ON dbo.cvo_open_order_parts_allinv_sp
    TO  PUBLIC
    ;
GO
GRANT EXECUTE ON  [dbo].[cvo_open_order_parts_allinv_sp] TO [public]
GO
