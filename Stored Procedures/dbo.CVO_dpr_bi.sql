
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- exec cvo_dpr_bi

CREATE PROCEDURE [dbo].[CVO_dpr_bi]
AS
    SET NOCOUNT ON;
    SET ANSI_WARNINGS OFF;

    TRUNCATE TABLE 
-- select * From 
DPR_Report;
                              
                              
    DECLARE @TodayDayOfWeek INT;                                        
    DECLARE @EndOfPrevWeek DATETIME;                                        
    DECLARE @StartOfPrevWeek4 DATETIME;                                        
    DECLARE @StartOfPrevWeek12 DATETIME;                                        
    DECLARE @StartOfPrevWeek26 DATETIME;                                        
    DECLARE @StartOfPrevWeek52 DATETIME;                                         
    DECLARE @location TINYINT;                        
    DECLARE @ctrl INT;                              
    DECLARE @locationName VARCHAR(80);                        

-- REBUILT BY ELABARBERA
--get number of a current day (1-Monday, 2-Tuesday... 7-Sunday)                                        
    SET @TodayDayOfWeek = DATEPART(dw, GETDATE());                                        
--get the last day of the previous week (last Sunday)                                        
    SET @EndOfPrevWeek = DATEADD(ms, -3,
                                 DATEADD(dd, 0, DATEDIFF(dd, 0, GETDATE())));
--get the first day of the previous week (the Monday before last)                                        
    SET @StartOfPrevWeek4 = DATEADD(ms, +4,
                                    DATEADD(dd, -( 28 ), @EndOfPrevWeek));                                       
-- 12 weeks                                        
    SET @StartOfPrevWeek12 = DATEADD(ms, +4,
                                     DATEADD(dd, -( 84 ), @EndOfPrevWeek));                                    
-- 26                                        
    SET @StartOfPrevWeek26 = DATEADD(ms, +4,
                                     DATEADD(dd, -( 182 ), @EndOfPrevWeek));                                         
-- 52                                        
    SET @StartOfPrevWeek52 = DATEADD(ms, +4,
                                     DATEADD(dd, -( 364 ), @EndOfPrevWeek));                                         
          
    SET @ctrl = 1;    

    IF ( OBJECT_ID('tempdb.dbo.#weeks') IS NOT NULL )
        DROP TABLE #weeks; 
    CREATE TABLE #weeks
        (
          startDate SMALLDATETIME ,
          endDate SMALLDATETIME ,
          week TINYINT
        );

    INSERT  INTO #weeks
    VALUES  ( @StartOfPrevWeek4, @EndOfPrevWeek, 4 );
    INSERT  INTO #weeks
    VALUES  ( @StartOfPrevWeek12, @EndOfPrevWeek, 12 );
    INSERT  INTO #weeks
    VALUES  ( @StartOfPrevWeek26, @EndOfPrevWeek, 26 );
    INSERT  INTO #weeks
    VALUES  ( @StartOfPrevWeek52, @EndOfPrevWeek, 52 );
     
    IF ( OBJECT_ID('tempdb.dbo.#prelocations') IS NOT NULL )
        DROP TABLE #prelocations;                      
    SELECT  * ,
            IDENTITY( INT, 1, 1 ) ctrl
    INTO    #prelocations
    FROM    DPR_Locations;                        
  
    IF ( OBJECT_ID('tempdb.dbo.#locations') IS NOT NULL )
        DROP TABLE #locations;                        
    SELECT TOP 0
            *
    INTO    #locations
    FROM    DPR_Locations;                        
                        
    SELECT  @location = MAX(ctrl)
    FROM    #prelocations;         


-- Get Historical Sales Data
-- Live
    IF ( OBJECT_ID('tempdb.dbo.#vsDataTable') IS NOT NULL )
        DROP TABLE #vsDataTable;
    SELECT  t1.part_no ,
            t3.type ,
            CASE t3.type
              WHEN 'I' THEN t1.shipped
              ELSE ( t1.cr_shipped * -1 )
            END AS Shipped ,
            date_shipped ,
            CAST(t3.location AS VARCHAR(80)) location
    INTO    #vsDataTable
    FROM    orders_all t3 ( NOLOCK )
            INNER JOIN ord_list (NOLOCK) t1 ON t1.order_no = t3.order_no
                                               AND t1.order_ext = t3.ext
            LEFT OUTER JOIN inv_master (NOLOCK) t2 ON t1.part_no = t2.part_no
            JOIN inv_master_add (NOLOCK) t4 ON t4.part_no = t1.part_no
    WHERE   t3.date_shipped >= ( SELECT MIN(startDate)
                                 FROM   #weeks
                               )
            AND t1.shipped IS NOT NULL;
--group by t1.part_no, T3.TYPE, t1.shipped, t1.cr_shipped, date_shipped, t1.location

---- History    
--Insert Into #vsDataTable
--select t1.part_no, t3.type,
--CASE T3.TYPE WHEN 'I' THEN t1.shipped ELSE (t1.cr_shipped*-1) END AS Shipped,
-- date_shipped, t1.location 
--from cvo_ord_list_hist (nolock) t1
--left outer join inv_master (nolock) t2 on t1.part_no=t2.part_no
--join cvo_orders_all_hist (nolock) t3 on t1.order_no=t3.order_no and t1.order_ext=t3.ext
--join inv_master_add (nolock) t4 on t4.part_no=t1.part_no
--		Where t3.date_shipped >= (Select MIN(startdate) From #weeks) and t1.shipped is not null
----group by t1.part_no, T3.TYPE, t1.shipped, t1.cr_shipped, date_shipped, t1.location

-- Pull All Item Codes for all locations

    INSERT  INTO #vsDataTable
            SELECT  part_no ,
                    'I' AS type ,
                    0 AS shipped ,
                    ( DATEADD(DAY, 0, DATEDIFF(DAY, 0, GETDATE())) ) AS date_shipped ,
                    LEFT(l.location, 80) location
            FROM    inv_master i ( NOLOCK )
                    CROSS JOIN DPR_Locations l
            WHERE   i.void = 'n';

-- select * From #vsdatatable

/*
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, '001' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'costco' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'insight' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'centennial' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'kaiser' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'luxottica' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'Astucci' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'Liberty' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'ME Retail' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'U.S.Vision' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'Nordstrom' as location
from inv_master  where VOID ='N'
Insert Into #vsDataTable
select part_no, 'I' as type, 0 as shipped, (DATEADD(Day, 0, DATEDIFF(Day, 0, GetDate()))) as date_shipped, 'Visionwork' as location
from inv_master  where VOID ='N'
*/

--
    WHILE ( @ctrl <= @location )
        BEGIN                        
            TRUNCATE TABLE #locations;                        
                        
            SELECT  @locationName = location
            FROM    #prelocations
            WHERE   ctrl = @ctrl;                        
                        
            IF ( @locationName = 'ALL' )
                INSERT  INTO #locations
                        SELECT  *
                        FROM    DPR_Locations
                        WHERE   location NOT IN ( 'ALL', 'Key Accounts' );                        
            ELSE
                IF ( @locationName = 'Key Accounts' )
                    INSERT  INTO #locations
                            SELECT  *
                            FROM    DPR_Locations
                            WHERE   location NOT IN ( 'ALL', 'Key Accounts',
                                                      '001', 'Astucci',
                                                      'Liberty', 'ME Retail',
                                                      'U.S.Vision',
                                                      'Nordstrom' );                        
                ELSE
                    INSERT  INTO #locations
                    VALUES  ( @locationName );                        
                        
            PRINT CAST(@ctrl AS VARCHAR) + ': ' + @locationName;                         

--Sales Shipped Live & Hist
            IF ( OBJECT_ID('tempdb.dbo.#WeekShipped') IS NOT NULL )
                DROP TABLE #WeekShipped; 
            SELECT  part_no ,
                    ISNULL(Shipped, 0) AS shipped ,
                    CASE WHEN date_shipped BETWEEN ( SELECT startDate
                                                     FROM   #weeks
                                                     WHERE  week = 4
                                                   )
                                           AND     ( SELECT endDate
                                                     FROM   #weeks
                                                     WHERE  week = 4
                                                   ) THEN 4
                         WHEN date_shipped BETWEEN ( SELECT startDate
                                                     FROM   #weeks
                                                     WHERE  week = 12
                                                   )
                                           AND     ( SELECT endDate
                                                     FROM   #weeks
                                                     WHERE  week = 12
                                                   ) THEN 12
                         WHEN date_shipped BETWEEN ( SELECT startDate
                                                     FROM   #weeks
                                                     WHERE  week = 26
                                                   )
                                           AND     ( SELECT endDate
                                                     FROM   #weeks
                                                     WHERE  week = 26
                                                   ) THEN 26
                         WHEN date_shipped BETWEEN ( SELECT startDate
                                                     FROM   #weeks
                                                     WHERE  week = 52
                                                   )
                                           AND     ( SELECT endDate
                                                     FROM   #weeks
                                                     WHERE  week = 52
                                                   ) THEN 52
                         WHEN date_shipped IS NULL THEN 4
                    END Week
            INTO    #WeekShipped
            FROM    #vsDataTable
                    INNER JOIN #locations l ON l.location = #vsDataTable.location;
-- Where location in (Select * From #locations) 

-- Total shipped Live & Hist
            IF ( OBJECT_ID('tempdb.dbo.#ShippedTotal') IS NOT NULL )
                DROP TABLE #ShippedTotal; 
            SELECT  a.part_no ,
                    b.e4_wu ,
                    c.e12_wu ,
                    d.e26_wu ,
                    e.e52_wu
            INTO    #ShippedTotal
            FROM    ( SELECT DISTINCT
                                part_no
                      FROM      #WeekShipped
                    ) a
                    LEFT JOIN ( SELECT  part_no ,
                                        CAST(SUM(ISNULL(shipped, 0)) / 4 AS INT) e4_wu
                                FROM    #WeekShipped
                                WHERE   Week = 4
                                GROUP BY part_no
                              ) b ON a.part_no = b.part_no
                    LEFT JOIN ( SELECT  part_no ,
                                        CAST(SUM(ISNULL(shipped, 0)) / 12 AS INT) e12_wu
                                FROM    #WeekShipped
                                WHERE   Week IN ( 4, 12 )
                                GROUP BY part_no
                              ) c ON a.part_no = c.part_no
                    LEFT JOIN ( SELECT  part_no ,
                                        CAST(SUM(ISNULL(shipped, 0)) / 26 AS INT) e26_wu
                                FROM    #WeekShipped
                                WHERE   Week IN ( 4, 12, 26 )
                                GROUP BY part_no
                              ) d ON a.part_no = d.part_no
                    LEFT JOIN ( SELECT  part_no ,
                                        CAST(SUM(ISNULL(shipped, 0)) / 52 AS INT) e52_wu
                                FROM    #WeekShipped
                                WHERE   Week IN ( 4, 12, 26, 52 )
                                GROUP BY part_no
                              ) e ON a.part_no = e.part_no;
  
-- Forecast 
            IF ( OBJECT_ID('tempdb.dbo.#WeekForecast') IS NOT NULL )
                DROP TABLE #WeekForecast;
            SELECT  '' AS part_no ,
                    '0' AS forecast ,
                    '4' AS Week
            INTO    #WeekForecast;

-- Total forecast
            IF ( OBJECT_ID('tempdb.dbo.#ForescastTotal') IS NOT NULL )
                DROP TABLE #ForescastTotal; 
            SELECT  a.* ,
                    '0' AS s4_wu ,
                    '0' AS s12_wu ,
                    '0' AS s26_wu ,
                    '0' AS s52_wu
            INTO    #ForescastTotal
            FROM    #ShippedTotal a; 

-- BO
            IF ( OBJECT_ID('tempdb.dbo.#TBBo') IS NOT NULL )
                DROP TABLE #TBBo; 
            SELECT  t1.part_no ,
                    ( SUM(ISNULL(ordered, 0)) - SUM(ISNULL(qty, 0)) ) bo ,
                    SUM(ISNULL(ordered, 0)) bod ,
                    SUM(ISNULL(qty, 0)) AllBo
            INTO    #TBBo
            FROM    #locations l
                    INNER JOIN orders_all t2 ( NOLOCK ) ON t2.location = l.location
                    INNER JOIN ord_list t1 ( NOLOCK ) ON t1.order_no = t2.order_no
                                                         AND t1.order_ext = t2.ext
                    INNER JOIN CVO_orders_all t3 ( NOLOCK ) ON t2.order_no = t3.order_no
                                                              AND t2.ext = t3.ext
                    FULL OUTER JOIN tdc_soft_alloc_tbl t4 ( NOLOCK ) ON t4.order_no = t1.order_no
                                                              AND t4.order_ext = t1.order_ext
                                                              AND t4.line_no = t1.line_no
            WHERE   1 = 1
-- and t1.location in (Select * From #locations) 
                    AND t2.type = 'I'
                    AND t2.ext <> 0
                    AND t2.status NOT IN ( 'T', 'V' )
            GROUP BY t1.part_no;

-- Pull data for RR
            IF ( OBJECT_ID('tempdb.dbo.#TBRRI') IS NOT NULL )
                DROP TABLE #TBRRI;
            SELECT  t1.part_no ,
                    ordered ,
                    CASE WHEN t2.date_shipped BETWEEN DATEADD(m, -1, GETDATE())
                                              AND     GETDATE() THEN 1
                         ELSE 3
                    END Month
            INTO    #TBRRI
            FROM    ord_list t1 ( NOLOCK )
                    INNER JOIN orders_all t2 ( NOLOCK ) ON t1.order_no = t2.order_no
                                                           AND t1.order_ext = t2.ext
                    INNER JOIN CVO_orders_all t3 ( NOLOCK ) ON t2.order_no = t3.order_no
                                                              AND t2.ext = t3.ext
            WHERE   t2.type = 'I'
                    AND t2.date_shipped BETWEEN DATEADD(m, -3, GETDATE())
                                        AND     GETDATE()
                    AND t2.ext = 0
                    AND t2.status = 'T';

            IF ( OBJECT_ID('tempdb.dbo.#TBRRC') IS NOT NULL )
                DROP TABLE #TBRRC;
            SELECT  t1.part_no ,
                    cr_ordered AS ordered ,
                    CASE WHEN t2.date_shipped BETWEEN DATEADD(m, -1, GETDATE())
                                              AND     GETDATE() THEN 1
                         ELSE 3
                    END Month
            INTO    #TBRRC
            FROM    orders_all t2 ( NOLOCK )
                    INNER JOIN ord_list t1 ( NOLOCK ) ON t1.order_no = t2.order_no
                                                         AND t1.order_ext = t2.ext
                    INNER JOIN CVO_orders_all t3 ( NOLOCK ) ON t2.order_no = t3.order_no
                                                              AND t2.ext = t3.ext
            WHERE   t2.type = 'C'
                    AND t2.date_shipped BETWEEN DATEADD(m, -3, GETDATE())
                                        AND     GETDATE()
                    AND t2.ext = 0
                    AND t2.status = 'T'; 


-- RR1
            IF ( OBJECT_ID('tempdb.dbo.#TBRR1') IS NOT NULL )
                DROP TABLE #TBRR1;
            SELECT  ISNULL(a.part_no, b.part_no) part_no ,
                    ISNULL(( a.ordered / ( b.ordered + .0001 ) ), 0) RR1
            INTO    #TBRR1
            FROM    ( SELECT    part_no ,
                                SUM(ISNULL(CAST(ordered AS FLOAT), 0)) ordered
                      FROM      #TBRRC
                      WHERE     Month = 1
                      GROUP BY  part_no
                    ) a
                    FULL JOIN ( SELECT  part_no ,
                                        SUM(ISNULL(CAST(ordered AS FLOAT), 0)) ordered
                                FROM    #TBRRI
                                WHERE   Month = 1
                                GROUP BY part_no
                              ) b ON a.part_no = b.part_no; 

-- RR3
            IF ( OBJECT_ID('tempdb.dbo.#TBRR3') IS NOT NULL )
                DROP TABLE #TBRR3;
            SELECT  ISNULL(a.part_no, b.part_no) part_no ,
                    ISNULL(( a.ordered / ( b.ordered + .0001 ) ), 0) RR3
            INTO    #TBRR3
            FROM    ( SELECT    part_no ,
                                SUM(ISNULL(CAST(ordered AS FLOAT), 0)) ordered
                      FROM      #TBRRC
                      GROUP BY  part_no
                    ) a
                    FULL JOIN ( SELECT  part_no ,
                                        SUM(ISNULL(CAST(ordered AS FLOAT), 0)) ordered
                                FROM    #TBRRI
                                GROUP BY part_no
                              ) b ON a.part_no = b.part_no; 
                                     

-- Add BO, RR1 & RR3
            IF ( OBJECT_ID('tempdb.dbo.#TBA') IS NOT NULL )
                DROP TABLE #TBA;
            SELECT  a.* ,
                    c.bo ,
                    d.RR1 ,
                    e.RR3
            INTO    #TBA
            FROM    #ForescastTotal a
                    LEFT JOIN #TBBo c ON a.part_no = c.part_no
                    LEFT JOIN #TBRR1 d ON a.part_no = d.part_no
                    LEFT JOIN #TBRR3 e ON a.part_no = e.part_no;


-- Add addl collection, vendor, obsolete
            IF ( OBJECT_ID('tempdb.dbo.#TBB') IS NOT NULL )
                DROP TABLE #TBB;
            SELECT  a.* ,
                    category collection ,
                    vendor , --obsolete status_Old,
                    CASE WHEN type_code IN ( 'SUN', 'FRAME', 'BRUIT' )
                         THEN 'Frame/Sun'
                         ELSE type_code
                    END AS Type_code
            INTO    #TBB
            FROM    #TBA a
                    LEFT JOIN inv_master (NOLOCK) b ON a.part_no = b.part_no
            WHERE   obsolete IN ( 1, 0 );

-- Add addl POM, RD, Style             
            IF ( OBJECT_ID('tempdb.dbo.#DPR_InvMaster') IS NOT NULL )
                DROP TABLE #DPR_InvMaster;                          
            SELECT  a.* ,
                    DATEADD(dd, 0, DATEDIFF(dd, 0, field_28)) POM ,
                    DATEADD(dd, 0, DATEDIFF(dd, 0, field_26)) RD ,
                    CASE WHEN ( field_26 <= GETDATE()
                                AND field_28 IS NULL
                              )
                              OR ( field_26 <= GETDATE()
                                   AND field_28 > GETDATE()
                                 ) THEN 0
                         ELSE 1
                    END AS status ,
-- CASE WHEN FIELD_26 <=GETDATE() OR FIELD_28 >=GETDATE() THEN 1 ELSE 0 end as [status],
                    field_2 style
            INTO    #DPR_InvMaster
            FROM    #TBB a
                    LEFT JOIN inv_master_add (NOLOCK) b ON a.part_no = b.part_no;                          
             
-- Pull Reserve Level, In Stock
            IF ( OBJECT_ID('tempdb.dbo.#vs1DPRInventory') IS NOT NULL )
                DROP TABLE #vs1DPRInventory;
            SELECT  part_no ,
                    MAX(ISNULL(min_stock, 0)) RL ,
                    SUM(ISNULL(in_stock, 0)) on_hand
            INTO    #vs1DPRInventory
            FROM    #locations l
                    INNER JOIN cvo_item_avail_vw (NOLOCK) c ON c.location = l.location
-- Where location in (Select * From #locations)
GROUP BY            part_no;  

-- Pull QC ON HAND
            IF ( OBJECT_ID('tempdb.dbo.#vs2DPRInventory') IS NOT NULL )
                DROP TABLE #vs2DPRInventory;
            SELECT  part_no ,
                    SUM(ISNULL(qty, 0)) QCOH
            INTO    #vs2DPRInventory
            FROM    #locations l
                    INNER JOIN lot_bin_recv (NOLOCK) r ON r.location = l.location
            WHERE   qc_flag = 'y'
-- and location in (Select * From #locations)
GROUP BY            part_no;  

-- add soft allocation table
            IF ( OBJECT_ID('tempdb.dbo.#vs3DPRInventory') IS NOT NULL )
                DROP TABLE #vs3DPRInventory;
--SELECT part_no, sum(ISNULL( DBO.f_cvo_get_soft_alloc_stock('0', LOCATION, PART_NO),0) ) AS SA_Alloc  -- GET RID OF FUNCTION
            SELECT  part_no ,
                    ( SUM(ISNULL(Allocated, 0)) + SUM(ISNULL(SOF, 0)) ) SA_Alloc
            INTO    #vs3DPRInventory
            FROM    #locations l
                    INNER JOIN cvo_item_avail_vw t1 ( NOLOCK ) ON t1.location = l.location
-- Where location in (Select * From #locations)
GROUP BY            part_no;   

--IF(OBJECT_ID('tempdb.dbo.#ItemAvl') is not null)                          
--drop table #ItemAvl
--Select part_no, location, MAX(ISNULL(min_stock,0))RL, SUM(ISNULL(in_stock,0))on_hand, sum(ISNULL(QTY_AVL,0))AvlToProm, ( sum(ISNULL(Allocated,0))+sum(ISNULL(SOF,0)) )Alloc
--Into #ItemAvl
--From cvo_item_avail_vw (nolock)
--Where location in (select * from DPR_Locations)
--Group By part_no, location



-- add soft allocation table
            IF ( OBJECT_ID('tempdb.dbo.#vs4DPRInventory') IS NOT NULL )
                DROP TABLE #vs4DPRInventory;
            SELECT  part_no ,
                    SUM(ISNULL(qty_avl, 0)) AS SA_ALLOCATED    -- SA_Allocated is actually Available to Promise
            INTO    #vs4DPRInventory
            FROM    #locations l
                    INNER JOIN cvo_item_avail_vw (NOLOCK) c ON c.location = l.location
-- Where location in (Select * From #locations)
GROUP BY            part_no;

--     SELECT * FROM #vs1DPRInventory WHERE part_no='BC804HOR5818'
--     SELECT * FROM #DPR_ApMaster  WHERE part_no='BC804HOR5818'


--  Add INV Master data to RL & OH & QC
            IF ( OBJECT_ID('tempdb.dbo.#DPR_Inventory') IS NOT NULL )
                DROP TABLE #DPR_Inventory;                           
            SELECT  a.* ,
                    b.RL ,
                    SUM(ISNULL(b.on_hand, 0) + ISNULL(c.QCOH, 0)) on_hand ,
                    D.SA_Alloc ,
                    e.SA_ALLOCATED  -- SA_Allocated is actually Available to Promise
            INTO    #DPR_Inventory
            FROM    #DPR_InvMaster a
                    LEFT JOIN #vs1DPRInventory b ON a.part_no = b.part_no
                    LEFT JOIN #vs2DPRInventory c ON a.part_no = c.part_no
                    LEFT JOIN #vs3DPRInventory D ON a.part_no = D.part_no
                    LEFT JOIN #vs4DPRInventory e ON a.part_no = e.part_no
            GROUP BY a.part_no ,
                    a.e4_wu ,
                    a.e12_wu ,
                    a.e26_wu ,
                    a.e52_wu ,
                    a.s4_wu ,
                    a.s12_wu ,
                    a.s26_wu ,
                    a.s52_wu ,
                    a.bo ,
                    a.RR1 ,
                    a.RR3 ,
                    a.collection ,
                    a.vendor ,
                    a.status ,
                    a.Type_code ,
                    a.POM ,
                    a.RD ,
                    a.style ,
                    b.RL ,
                    D.SA_Alloc ,
                    e.SA_ALLOCATED;

-- Add Addl LT
            IF ( OBJECT_ID('tempdb.dbo.#DPR_ApMaster') IS NOT NULL )
                DROP TABLE #DPR_ApMaster;                          
            SELECT  a.* ,
                    b.lt
            INTO    #DPR_ApMaster
            FROM    #DPR_Inventory a
                    LEFT JOIN ( SELECT  vendor_code ,
                                        MAX(ISNULL(lead_time, 0)) lt
                                FROM    apmaster_all (NOLOCK)
                                GROUP BY vendor_code
                              ) b ON a.vendor = b.vendor_code;         



-- BUILD Alloc

            IF ( OBJECT_ID('tempdb.dbo.#tbAlloc') IS NOT NULL )
                DROP TABLE #tbAlloc;                           
            SELECT  a.* ,
                    (/*ISNULL(b.alloc,0)+*/ ISNULL(a.SA_Alloc, 0) ) alloc ,
                    ISNULL(c.alloc1, 0) alloc1 ,
                    ( ISNULL(d.nalloc1, 0) ) nalloc1 ,
                    ISNULL(e.FO1, 0) FO1 ,
                    ISNULL(f.alloc2, 0) alloc2 ,
                    ( ISNULL(g.nalloc2, 0) ) nalloc2 ,
                    ISNULL(h.FO2, 0) FO2 ,
                    ISNULL(i.alloc3, 0) alloc3 ,
                    ( ISNULL(j.nalloc3, 0) ) nalloc3 ,
                    ISNULL(k.FO3, 0) FO3 ,
                    ISNULL(l.alloc4, 0) alloc4 ,
                    ( ISNULL(m.nalloc4, 0) ) nalloc4 ,
                    ISNULL(n.FO4, 0) FO4 ,
                    ISNULL(o.alloc5, 0) alloc5 ,
                    ( ISNULL(p.nalloc5, 0) ) nalloc5 ,
                    ISNULL(q.FO5, 0) FO5 ,
                    ISNULL(r.alloc6, 0) alloc6 ,
                    ( ISNULL(s.nalloc6, 0) ) nalloc6 ,
                    ISNULL(t.FO6, 0) FO6
            INTO    #tbAlloc
            FROM    #DPR_ApMaster a
                    LEFT JOIN ( SELECT  t2.part_no ,
                                        SUM(t1.qty) alloc
                                FROM    #locations l
                                        INNER JOIN tdc_soft_alloc_tbl t1 ( NOLOCK ) ON t1.location = l.location
                                        INNER JOIN ord_list (NOLOCK) t2 ON t1.order_no = t2.order_no
                                                              AND t1.order_ext = t2.order_ext
                                                              AND t1.line_no = t2.line_no
                                        INNER JOIN orders_all t3 ( NOLOCK ) ON t2.order_no = t3.order_no
                                                              AND t2.order_ext = t3.ext
                                WHERE   t3.status NOT IN ( 'T', 'V' )
                                        AND t3.type = 'I'
                                        AND t1.alloc_type <> 'xf' 
-- and t3.location in (Select * From #locations) 
GROUP BY                                t2.part_no
                              ) b /*  */ ON a.part_no = b.part_no                          


-- BUILD Future
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) alloc1
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        INNER JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        INNER JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                         
--and t2.ship_to_no in (Select * From #locations)                       
-- and t1.location in (Select * From #locations)                       
                                        AND t3.inhouse_date BETWEEN DATEADD(yy,
                                                              -1, GETDATE())
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 28,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type = 'XX'
                                GROUP BY t1.part_no
                              ) c /*  */ ON a.part_no = c.part_no
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) nalloc1
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                        
--and t2.ship_to_no in (Select * From #locations)                       
-- and t1.location in (Select * From #locations)                       
                                        AND t2.inhouse_date BETWEEN GETDATE()
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 28,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type <> 'XX'
                                GROUP BY t1.part_no
                              ) d /*  */ ON a.part_no = d.part_no
                    LEFT JOIN ( SELECT  t2.part_no ,
                                        SUM(t2.ordered) - SUM(ISNULL(t3.qty, 0)) FO1
                                FROM    #locations l
                                        INNER JOIN orders_all (NOLOCK) t1 ON t1.location = l.location
                                        JOIN ord_list (NOLOCK) t2 ON t1.order_no = t2.order_no
                                                              AND t1.ext = t2.order_ext                     
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
                                        LEFT JOIN ( SELECT  order_no ,
                                                            location ,
                                                            line_no ,
                                                            SUM(qty) qty ,
                                                            part_no
                                                    FROM    tdc_soft_alloc_tbl (NOLOCK)
                                                    GROUP BY part_no ,
                                                            order_no ,
                                                            line_no ,
                                                            location
                                                  ) t3 ON t2.order_no = t3.order_no
                                                          AND t2.location = t3.location
                                                          AND t2.part_no = t3.part_no
                                                          AND t2.line_no = t3.line_no
                                        JOIN CVO_orders_all t4 ( NOLOCK ) ON t1.order_no = t4.order_no
                                                              AND t1.ext = t4.ext
                                WHERE   t1.req_ship_date BETWEEN '1/1/2012'
                                                         AND  DATEADD(S, -1,
                                                              DATEADD(dd, 28,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND t4.allocation_date > GETDATE() 
-- and t2.location in (Select * From #locations) 
                                        AND t1.ext = 0
                                        AND t1.status NOT IN ( 'T', 'V' )
                                GROUP BY t2.part_no
                              ) e /*  */ ON a.part_no = e.part_no 


--2                        
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) alloc2
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                        
--and t2.ship_to_no in (Select * From #locations) 
-- and t1.location in (Select * From #locations)                     
                                        AND t3.inhouse_date BETWEEN DATEADD(dd,
                                                              28,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 56,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type = 'XX'
                                GROUP BY t1.part_no
                              ) f /*  */ ON a.part_no = f.part_no
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) nalloc2
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                        
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)                       
                                        AND t3.inhouse_date BETWEEN DATEADD(dd,
                                                              28,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 56,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type <> 'XX'
                                GROUP BY t1.part_no
                              ) g /*  */ ON a.part_no = g.part_no
                    LEFT JOIN ( SELECT  t2.part_no ,
                                        SUM(t2.ordered) - SUM(ISNULL(t3.qty, 0)) FO2
                                FROM    #locations l
                                        INNER JOIN orders_all (NOLOCK) t1 ON t1.location = l.location
                                        JOIN ord_list (NOLOCK) t2 ON t1.order_no = t2.order_no
                                                              AND t1.ext = t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
                                        LEFT JOIN ( SELECT  order_no ,
                                                            location ,
                                                            line_no ,
                                                            SUM(qty) qty ,
                                                            part_no
                                                    FROM    tdc_soft_alloc_tbl (NOLOCK)
                                                    GROUP BY part_no ,
                                                            order_no ,
                                                            line_no ,
                                                            location
                                                  ) t3 ON t2.order_no = t3.order_no
                                                          AND t2.location = t3.location
                                                          AND t2.part_no = t3.part_no
                                                          AND t2.line_no = t3.line_no
                                        JOIN CVO_orders_all t4 ( NOLOCK ) ON t1.order_no = t4.order_no
                                                              AND t1.ext = t4.ext
                                WHERE   t1.req_ship_date BETWEEN DATEADD(dd,
                                                              28,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                         AND  DATEADD(S, -1,
                                                              DATEADD(dd, 56,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND t4.allocation_date > GETDATE() 
-- and t2.location in (Select * From #locations) 
                                        AND t1.ext = 0
                                        AND t1.status NOT IN ( 'T', 'V' )
                                GROUP BY t2.part_no
                              ) h /*  */ ON a.part_no = h.part_no                          
--3                        
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) alloc3
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                         
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)
                                        AND t3.inhouse_date BETWEEN DATEADD(dd,
                                                              56,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 84,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type = 'XX'
                                GROUP BY t1.part_no
                              ) i /*  */ ON a.part_no = i.part_no
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) nalloc3
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'
                                        AND t2.ship_to_no IN ( SELECT
                                                              *
                                                              FROM
                                                              #locations )                      
-- and t1.location in (Select * From #locations)                       
                                        AND t3.inhouse_date BETWEEN DATEADD(dd,
                                                              56,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 84,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type <> 'XX'
                                GROUP BY t1.part_no
                              ) j /*  */ ON a.part_no = j.part_no
                    LEFT JOIN ( SELECT  t2.part_no ,
                                        SUM(t2.ordered) - SUM(ISNULL(t3.qty, 0)) FO3
                                FROM    #locations l
                                        INNER JOIN orders_all (NOLOCK) t1 ON t1.location = l.location
                                        JOIN ord_list (NOLOCK) t2 ON t1.order_no = t2.order_no
                                                              AND t1.ext = t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
                                        LEFT JOIN ( SELECT  order_no ,
                                                            location ,
                                                            line_no ,
                                                            SUM(qty) qty ,
                                                            part_no
                                                    FROM    tdc_soft_alloc_tbl (NOLOCK)
                                                    GROUP BY part_no ,
                                                            order_no ,
                                                            line_no ,
                                                            location
                                                  ) t3 ON t2.order_no = t3.order_no
                                                          AND t2.location = t3.location
                                                          AND t2.part_no = t3.part_no
                                                          AND t2.line_no = t3.line_no
                                        JOIN CVO_orders_all t4 ( NOLOCK ) ON t1.order_no = t4.order_no
                                                              AND t1.ext = t4.ext
                                WHERE   t1.req_ship_date BETWEEN DATEADD(dd,
                                                              56,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                         AND  DATEADD(S, -1,
                                                              DATEADD(dd, 84,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND t4.allocation_date > GETDATE() 
-- and t2.location in (Select * From #locations)  
                                        AND t1.ext = 0
                                        AND t1.status NOT IN ( 'T', 'V' )
                                GROUP BY t2.part_no
                              ) k /*  */ ON a.part_no = k.part_no                          
--4                        
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) alloc4
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                           
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)
                                        AND t3.inhouse_date BETWEEN DATEADD(dd,
                                                              84,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 112,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type = 'XX'
                                GROUP BY t1.part_no
                              ) l /*  */ ON a.part_no = l.part_no
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) nalloc4
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                       
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)                       
                                        AND t3.inhouse_date BETWEEN DATEADD(dd,
                                                              84,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 112,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type <> 'XX'
                                GROUP BY t1.part_no
                              ) m /*  */ ON a.part_no = m.part_no
                    LEFT JOIN ( SELECT  t2.part_no ,
                                        SUM(t2.ordered) - SUM(ISNULL(t3.qty, 0)) FO4
                                FROM    #locations l
                                        INNER JOIN orders_all (NOLOCK) t1 ON t1.location = l.location
                                        JOIN ord_list (NOLOCK) t2 ON t1.order_no = t2.order_no
                                                              AND t1.ext = t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
                                        LEFT JOIN ( SELECT  order_no ,
                                                            location ,
                                                            line_no ,
                                                            SUM(qty) qty ,
                                                            part_no
                                                    FROM    tdc_soft_alloc_tbl (NOLOCK)
                                                    GROUP BY part_no ,
                                                            order_no ,
                                                            line_no ,
                                                            location
                                                  ) t3 ON t2.order_no = t3.order_no
                                                          AND t2.location = t3.location
                                                          AND t2.part_no = t3.part_no
                                                          AND t2.line_no = t3.line_no
                                        JOIN CVO_orders_all t4 ( NOLOCK ) ON t1.order_no = t4.order_no
                                                              AND t1.ext = t4.ext
                                WHERE   t1.req_ship_date BETWEEN DATEADD(dd,
                                                              84,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                         AND  DATEADD(S, -1,
                                                              DATEADD(dd, 112,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND t4.allocation_date > GETDATE() 
-- and t2.location in (Select * From #locations)  
                                        AND t1.ext = 0
                                        AND t1.status NOT IN ( 'T', 'V' )
                                GROUP BY t2.part_no
                              ) n /*  */ ON a.part_no = n.part_no                          
--5                        
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) alloc5
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                                             
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)
                                        AND t3.inhouse_date BETWEEN DATEADD(dd,
                                                              112,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 140,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type = 'XX'
                                GROUP BY t1.part_no
                              ) o /*  */ ON a.part_no = o.part_no
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) nalloc5
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                                              
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)                       
                                        AND t3.inhouse_date BETWEEN DATEADD(dd,
                                                              112,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                            AND
                                                              DATEADD(S, -1,
                                                              DATEADD(dd, 140,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND po_type <> 'XX'
                                GROUP BY t1.part_no
                              ) p /*  */ ON a.part_no = p.part_no
                    LEFT JOIN ( SELECT  t2.part_no ,
                                        SUM(t2.ordered) - SUM(ISNULL(t3.qty, 0)) FO5
                                FROM    #locations l
                                        INNER JOIN orders_all (NOLOCK) t1 ON t1.location = l.location
                                        JOIN ord_list (NOLOCK) t2 ON t1.order_no = t2.order_no
                                                              AND t1.ext = t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
                                        LEFT JOIN ( SELECT  order_no ,
                                                            location ,
                                                            line_no ,
                                                            SUM(qty) qty ,
                                                            part_no
                                                    FROM    tdc_soft_alloc_tbl (NOLOCK)
                                                    GROUP BY part_no ,
                                                            order_no ,
                                                            line_no ,
                                                            location
                                                  ) t3 ON t2.order_no = t3.order_no
                                                          AND t2.location = t3.location
                                                          AND t2.part_no = t3.part_no
                                                          AND t2.line_no = t3.line_no
                                        JOIN CVO_orders_all t4 ( NOLOCK ) ON t1.order_no = t4.order_no
                                                              AND t1.ext = t4.ext
                                WHERE   t1.req_ship_date BETWEEN DATEADD(dd,
                                                              112,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                                         AND  DATEADD(S, -1,
                                                              DATEADD(dd, 140,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE())))
                                        AND t4.allocation_date > GETDATE() 
-- and t2.location in (Select * From #locations)  
                                        AND t1.ext = 0
                                        AND t1.status NOT IN ( 'T', 'V' )
                                GROUP BY t2.part_no
                              ) q /*  */ ON a.part_no = q.part_no                          
--6                        
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) alloc6
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                                             
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)
                                        AND t3.inhouse_date >= DATEADD(dd, 140,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                        AND po_type = 'XX'
                                GROUP BY t1.part_no
                              ) r /*  */ ON a.part_no = r.part_no
                    LEFT JOIN ( SELECT  t1.part_no ,
                                        SUM(ISNULL(qty_ordered, 0)
                                            - ISNULL(qty_received, 0)) nalloc6
                                FROM    #locations l
                                        INNER JOIN pur_list (NOLOCK) t1 ON t1.location = l.location
                                        JOIN purchase (NOLOCK) t2 ON t1.po_no = t2.po_no
	-- EL added below to  change join from t2.date_order_due date to t3.inhouse_date
                                        JOIN releases (NOLOCK) t3 ON t3.po_line = t1.line
                                                              AND t3.po_no = t1.po_no
                                WHERE   t2.status IN ( 'H', 'O' )
                                        AND t1.status = 'O'                                            
--and t2.ship_to_no in (Select * From #locations)                      
-- and t1.location in (Select * From #locations)                       
                                        AND t3.inhouse_date >= DATEADD(dd, 140,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                        AND po_type <> 'XX'
                                GROUP BY t1.part_no
                              ) s ON a.part_no = s.part_no
                    LEFT JOIN ( SELECT  t2.part_no ,
                                        SUM(t2.ordered) - SUM(ISNULL(t3.qty, 0)) FO6
                                FROM    #locations l
                                        INNER JOIN orders_all (NOLOCK) t1 ON t1.location = l.location
                                        JOIN ord_list (NOLOCK) t2 ON t1.order_no = t2.order_no
                                                              AND t1.ext = t2.order_ext
--left join tdc_soft_alloc_tbl (nolock) T3 on t2.order_no = t3.order_no and t2.LINE_NO = t3.LINE_NO and t2.part_no = t3.part_no       
-- UPDATED 11/06/12 TO FIX PROBLEM WITH JOIN ON MULTI LINE
                                        LEFT JOIN ( SELECT  order_no ,
                                                            location ,
                                                            line_no ,
                                                            SUM(qty) qty ,
                                                            part_no
                                                    FROM    tdc_soft_alloc_tbl (NOLOCK)
                                                    GROUP BY part_no ,
                                                            order_no ,
                                                            line_no ,
                                                            location
                                                  ) t3 ON t2.order_no = t3.order_no
                                                          AND t2.location = t3.location
                                                          AND t2.part_no = t3.part_no
                                                          AND t2.line_no = t3.line_no
                                        JOIN CVO_orders_all t4 ( NOLOCK ) ON t1.order_no = t4.order_no
                                                              AND t1.ext = t4.ext
                                WHERE   t1.req_ship_date >= DATEADD(dd, 140,
                                                              DATEDIFF(dd, 0,
                                                              GETDATE()))
                                        AND t4.allocation_date > GETDATE() 
-- and t2.location in (Select * From #locations) 
                                        AND t1.ext = 0
                                        AND t1.status NOT IN ( 'T', 'V' )
                                GROUP BY t2.part_no
                              ) t /*  */ ON a.part_no = t.part_no;                            
                          
                             
            IF ( OBJECT_ID('tempdb.dbo.#tbAvend') IS NOT NULL )
                DROP TABLE #tbAvend;                        
            SELECT  a.* ,
                    ( ISNULL(on_hand, 0) - ISNULL(alloc, 0) ) avend
            INTO    #tbAvend
            FROM    #tbAlloc a;
           
                          
            IF ( OBJECT_ID('tempdb.dbo.#tbAv4end') IS NOT NULL )
                DROP TABLE #tbAv4end;                        
            SELECT  a.* ,
                    ( ISNULL(avend, 0) - ( 4 * ISNULL(e12_wu, 0) )
                      + ISNULL(nalloc1, 0) + ISNULL(alloc1, 0) - ISNULL(FO1, 0) ) av4end
            INTO    #tbAv4end
            FROM    #tbAvend a;  

                    
            IF ( OBJECT_ID('tempdb.dbo.#tbAv8end') IS NOT NULL )
                DROP TABLE #tbAv8end;
            SELECT  a.* ,
                    ( ISNULL(av4end, 0) - ( 4 * ISNULL(e12_wu, 0) )
                      + ISNULL(nalloc2, 0) + ISNULL(alloc2, 0) - ISNULL(FO2, 0) ) av8end
            INTO    #tbAv8end
            FROM    #tbAv4end a;                        
                        
                        
            IF ( OBJECT_ID('tempdb.dbo.#tbAv12end') IS NOT NULL )
                DROP TABLE #tbAv12end;                      
            SELECT  a.* ,
                    ( ISNULL(av8end, 0) - ( 4 * ISNULL(e12_wu, 0) )
                      + ISNULL(nalloc3, 0) + ISNULL(alloc3, 0) - ISNULL(FO3, 0) ) av12end
            INTO    #tbAv12end
            FROM    #tbAv8end a;                        
                        
                        
            IF ( OBJECT_ID('tempdb.dbo.#tbAv16end') IS NOT NULL )
                DROP TABLE #tbAv16end;                        
            SELECT  a.* ,
                    ( ISNULL(av12end, 0) - ( 4 * ISNULL(e12_wu, 0) )
                      + ISNULL(nalloc4, 0) + ISNULL(alloc4, 0) - ISNULL(FO4, 0) ) av16end
            INTO    #tbAv16end
            FROM    #tbAv12end a;                        
                        
                        
            IF ( OBJECT_ID('tempdb.dbo.#tbAv20end') IS NOT NULL )
                DROP TABLE #tbAv20end;                        
            SELECT  a.* ,
                    ( ISNULL(av16end, 0) - ( 4 * ISNULL(e12_wu, 0) )
                      + ISNULL(nalloc5, 0) + ISNULL(alloc5, 0) - ISNULL(FO5, 0) ) av20end
            INTO    #tbAv20end
            FROM    #tbAv16end a;                        
                        
                        
            IF ( OBJECT_ID('tempdb.dbo.#tbAv24end') IS NOT NULL )
                DROP TABLE #tbAv24end;                     
            SELECT  a.* ,
                    ( ISNULL(av20end, 0) - ( 4 * ISNULL(e12_wu, 0) )
                      + ISNULL(nalloc6, 0) + ISNULL(alloc6, 0) - ISNULL(FO6, 0) ) av24end ,
                    1 MOQ
            INTO    #tbAv24end
            FROM    #tbAv20end a;                        
                      
            
            INSERT  INTO DPR_Report
                    ( part_no ,
                      Reserver_Level ,
                      POM_Date ,
                      e4_WU ,
                      e12_WU ,
                      e26_WU ,
                      e52_WU ,
                      S4_WU ,
                      S12_WU ,
                      S26_WU ,
                      S52_WU ,
                      On_Hand ,
                      BackOrder ,
                      Allocated ,
                      SA_Allocated ,        -- SA_Allocated is actually Available to Promise                               
                      Non_Allocated_PO ,
                      Allocated_PO ,
                      Future_Orders ,
                      Non_Allocated_PO2 ,
                      Allocated_PO2 ,
                      Future_Orders2 ,
                      Non_Allocated_PO3 ,
                      Allocated_PO3 ,
                      Future_Orders3 ,
                      Non_Allocated_PO4 ,
                      Allocated_PO4 ,
                      Future_Orders4 ,
                      Non_Allocated_PO5 ,
                      Allocated_PO5 ,
                      Future_Orders5 ,
                      Non_Allocated_PO6 ,
                      Allocated_PO6 ,
                      Future_Orders6 ,
                      avend ,
                      av4end ,
                      av8end ,
                      av12end ,
                      av16end ,
                      av20end ,
                      av24end ,
                      style ,
                      collection ,
                      vendor ,
                      MOQ ,
                      RR1 ,
                      RR3 ,
                      status ,
                      status_description ,
                      release_date ,
                      lead_time ,
                      location ,
                      type_code                                  
                    )
                    SELECT  part_no ,
                            RL ,
                            POM ,
                            e4_wu ,
                            e12_wu ,
                            e26_wu ,
                            e52_wu ,
                            s4_wu ,
                            s12_wu ,
                            s26_wu ,
                            s52_wu ,
                            on_hand ,
                            bo ,
                            alloc ,
                            SA_ALLOCATED ,
                            ISNULL(alloc1, 0) ,
                            ISNULL(nalloc1, 0) ,
                            FO1 ,
                            ISNULL(alloc2, 0) ,
                            ISNULL(nalloc2, 0) ,
                            FO2 ,
                            ISNULL(alloc3, 0) ,
                            ISNULL(nalloc3, 0) ,
                            FO3 ,
                            ISNULL(alloc4, 0) ,
                            ISNULL(nalloc4, 0) ,
                            FO4 ,
                            ISNULL(alloc5, 0) ,
                            ISNULL(nalloc5, 0) ,
                            FO5 ,
                            ISNULL(alloc6, 0) ,
                            ISNULL(nalloc6, 0) ,
                            FO6 ,
                            avend ,
                            av4end ,
                            av8end ,
                            av12end ,
                            av16end ,
                            av20end ,
                            av24end ,
                            style ,
                            collection ,
                            vendor ,
                            MOQ ,
                            RR1 ,
                            RR3 ,
                            status ,
                            CASE WHEN status = 0 THEN 'Active'
                                 ELSE 'Inactive'
                            END AS status_description ,
                            RD ,
                            lt ,
                            @locationName ,
                            Type_code
                    FROM    #tbAv24end
                    ORDER BY collection ,
                            part_no;
                    

            SET @ctrl = @ctrl + 1;                        
        END;

    DELETE  FROM DPR_Report
    WHERE   location NOT IN ( 'ALL' )
            AND e4_WU = 0
            AND e12_WU = 0
            AND e26_WU = 0
            AND e52_WU = 0
            AND S4_WU = 0
            AND S12_WU = 0
            AND S26_WU = 0
            AND S52_WU = 0
            AND On_Hand = 0
            AND BackOrder IS NULL
            AND Allocated = 0
            AND Non_Allocated_PO = 0
            AND Allocated_PO = 0
            AND Future_Orders = 0
            AND Non_Allocated_PO2 = 0
            AND Allocated_PO2 = 0
            AND Future_Orders2 = 0
            AND Non_Allocated_PO3 = 0
            AND Allocated_PO3 = 0
            AND Future_Orders3 = 0
            AND Non_Allocated_PO4 = 0
            AND Allocated_PO4 = 0
            AND Future_Orders4 = 0
            AND Non_Allocated_PO5 = 0
            AND Allocated_PO5 = 0
            AND Future_Orders5 = 0
            AND Non_Allocated_PO6 = 0
            AND Allocated_PO6 = 0
            AND Future_Orders6 = 0
            AND avend = 0
            AND av4end = 0
            AND av8end = 0
            AND av12end = 0
            AND av16end = 0
            AND av20end = 0
            AND av24end = 0;

    DELETE  FROM DPR_Report
    WHERE   DPR_Report.location = '001'
            AND DPR_Report.part_no IN (
            SELECT  T1.part_no
            FROM    DPR_Report T1
                    JOIN inv_master_add t2 ON T1.part_no = t2.part_no
            WHERE   location IN ( '001' )
                    AND t2.field_32 = 'Retail'
                    AND T1.part_no LIKE 'ME%'
                    AND e4_WU = 0
                    AND e12_WU = 0
                    AND e26_WU = 0
                    AND e52_WU = 0
                    AND S4_WU = 0
                    AND S12_WU = 0
                    AND S26_WU = 0
                    AND S52_WU = 0
                    AND On_Hand = 0
                    AND BackOrder IS NULL
                    AND Allocated = 0
                    AND Non_Allocated_PO = 0
                    AND Allocated_PO = 0
                    AND Future_Orders = 0
                    AND Non_Allocated_PO2 = 0
                    AND Allocated_PO2 = 0
                    AND Future_Orders2 = 0
                    AND Non_Allocated_PO3 = 0
                    AND Allocated_PO3 = 0
                    AND Future_Orders3 = 0
                    AND Non_Allocated_PO4 = 0
                    AND Allocated_PO4 = 0
                    AND Future_Orders4 = 0
                    AND Non_Allocated_PO5 = 0
                    AND Allocated_PO5 = 0
                    AND Future_Orders5 = 0
                    AND Non_Allocated_PO6 = 0
                    AND Allocated_PO6 = 0
                    AND Future_Orders6 = 0
                    AND avend = 0
                    AND av4end = 0
                    AND av8end = 0
                    AND av12end = 0
                    AND av16end = 0
                    AND av20end = 0
                    AND av24end = 0 );

    DELETE  FROM DPR_Report
    WHERE   part_no IN ( SELECT part_no
                         FROM   inv_master (NOLOCK)
                         WHERE  void = 'v' );




GO

GRANT EXECUTE ON  [dbo].[CVO_dpr_bi] TO [public]
GO
