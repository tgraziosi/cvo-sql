SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
exec cvo_cir
select distinct territory, cust_code from cvo_carbi 
--where cust_code = '023806'
--where ship_to <> ''
--where address_name like '%brilliant%'
-- where cust_code = '046759' and territory = '50506'
where address_name is null
custnetsales <> totacctnetsales

SELECT * FROM CVO_CARBI WHERE STYLE = 'sunshine'

select * From cvo_cir where cust_code = '044057'
select territory_code, * From armaster where customer_code = '044057'

*/

CREATE PROCEDURE [dbo].[CVO_CIR] @pom_asof DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @first DATETIME;
    DECLARE @last DATETIME;
    DECLARE @F12 DATETIME;
    DECLARE @L12 DATETIME;
    DECLARE @F36 DATETIME;
    DECLARE @f24 DATETIME; --v3.3
    DECLARE @LYstart DATETIME;
    DECLARE @TYstart DATETIME;
    -- DECLARE @pom_asof DATETIME;

    /**
3/12/2012 - TAG - Rewrite                    
v3.1 - 4/26/2012 - April Release
color description, show 36 month window of sales
fix join to artrx to use orders_invoice instead of order_ctrl_num
add last stock order date to table
v3.2 - 5/31/2012 - May Changes
POM indicator
Net Sales for the reporting period - 12 months
v3.3 - 6/21/2012 - June Changes
exclude rebills
add more sales figures - p12, ytd ty and ly
last stock order date and order number
v3.4 - updates for ssrs - add city and postal code - 072512
v4.0 - July release - collapse affiliated accounts to the active account
where the from account is not active
v4.1 - august - add POM status (RYG)
v4.2 - Sept - add short_name for sorting and updates for pom active flag
v4.3 - Nov 2012 - add unposted AR - arinpchg
v4.4 - Dec 2012 - for last st order, only consider orders, not credits
include Net sales for entire account too.
v5.0 - Jan 2013 - run at any date - rewrite - again
v5.1 - collapse inactive ship-tos to main account
v5.2 - correct summary sales figures on collapsed ship-tos, and # on partial pom styles
v5.3 - check for territory match when rolling up non-door accounts and change the way the address is 
maintained so that the correct address displays with non-door ship-to's
v5.4 - 12/7/2017 - add an indicator for Suns into part_no2
v5.5 - 12/28/2017 - remove CH and ME

**/

    /** Run Times: 10/4/2012 - 16:04 **/
    /** 2/20/2013 - 8 min - db-02 **/
    /** 2/25 4:44m - db03 */
    /** 11/19/13 4:24 */
    /** 01/23/14 05:05 */
    /** 08/21/14 04:03 */
    /** 9/25/2015 03:26 after index on carbi table */


    -- get the first and last day of this month                                 
    --SET @first=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(getdate())-1),getdate()),101))      
    SELECT @first = CONVERT(VARCHAR(25), GETDATE(), 101); -- today   

    IF @pom_asof IS NULL
        SET @pom_asof = @first;

    -- UNCOMMENT FOR THE PRINTED CIR RUN
    -- set @pom_asof = '07/25/2017'

    -- set @first = '08/28/2013'

    --set @first = '6/1/2012'
    --SET @first=dateadd(mm,-2,@first)    
    --set @first = dateadd(mm,-1,@first)  --First Day of previous month
    --set @last = dateadd(dd,-1,@first)   --Last Day of previous month        
    SELECT @last = CONVERT(VARCHAR(25), DATEADD(dd, -1, GETDATE()), 101) + ' 23:59'; -- yesterday
    -- SET @last=(SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,getdate()))),DATEADD(mm,1,getdate())),101)) -- last day of this month
    --set @last = '03/27/2013 23:59'


    --select @first, @last

    SET @F12 = DATEADD(m, -12, @first);
    SET @F36 = DATEADD(m, -36, @first);
    SET @f24 = DATEADD(m, -24, @first); -- v3.3                                                
    SET @L12 = DATEADD(d, -1, @first);

    SET @LYstart = '1/1/' + CAST(YEAR(@F12) AS VARCHAR(4));
    SET @TYstart = '1/1/' + CAST(YEAR(@last) AS VARCHAR(4));

    DECLARE @Jf12 INT,
            @jf36 INT,
            @jlast INT;

    SELECT @Jf12 = dbo.adm_get_pltdate_f(@F12);
    SELECT @jf36 = dbo.adm_get_pltdate_f(@F36);
    SELECT @jlast = dbo.adm_get_pltdate_f(@last);

    SELECT @last,
           @jlast;

    SELECT 'f36= ',
           @F36,
           ' f24= ',
           @f24;

    SELECT '12mty=',
           @F12,
           @last;
    SELECT '12mly=',
           @f24,
           DATEADD(yy, -1, @last);
    SELECT 'ytdty=',
           DATEPART(yy, @first),
           DATEPART(m, @last);
    SELECT 'ytdly=',
           DATEPART(yy, DATEADD(yy, -1, @first)),
           DATEPART(m, @last);

    -- get part info
    PRINT 'starting part_info';
    SELECT GETDATE();

    IF (OBJECT_ID('tempdb.dbo.#tgCategorystyleEyeSizes') IS NOT NULL)
        DROP TABLE #tgCategorystyleEyeSizes;
    IF (OBJECT_ID('tempdb.dbo.#tgSumEyeSizes') IS NOT NULL)
        DROP TABLE #tgSumEyeSizes;

    IF (OBJECT_ID('tempdb.dbo.#pp') IS NOT NULL)
        DROP TABLE #pp;


    SELECT DISTINCT
           b.category,
           a.field_2,
           (CONVERT(VARCHAR(5), (CONVERT(INT, ISNULL(a.field_17, 0))))) eye_size
    INTO #tgCategoryStyleEyeSizes
    FROM dbo.inv_master_add a
        JOIN dbo.inv_master b
            ON b.part_no = a.part_no
    WHERE a.field_17 <> 0
          AND b.type_code IN ( 'FRAME', 'SUN' );

    CREATE NONCLUSTERED INDEX idx_for_eyesizes
    ON #tgCategoryStyleEyeSizes (
                                category ASC,
                                field_2 ASC
                                )
    WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
    ON [PRIMARY];

    -- select * from #categoryStyleEyeSizes

    SELECT DISTINCT
           c.category,
           c.field_2,
           STUFF(
           (
           SELECT ' ' + eye_size
           FROM #tgCategoryStyleEyeSizes a
           WHERE a.category = c.category
                 AND a.field_2 = c.field_2
           FOR XML PATH('')
           ),
           1,
           1,
           ''
                ) AS EyeSizes
    INTO #tgSumEyeSizes
    FROM #tgCategoryStyleEyeSizes c;

    CREATE NONCLUSTERED INDEX idx_for_eyesizes
    ON #tgSumEyeSizes (
                      category ASC,
                      field_2 ASC
                      )
    WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
    ON [PRIMARY];



    IF (OBJECT_ID('tempdb.dbo.#part_info') IS NOT NULL)
        DROP TABLE #part_info;

    CREATE TABLE #part_info
    (
        part_no VARCHAR(30),
        style VARCHAR(40),
        category VARCHAR(10),
        part_no2 NVARCHAR(MAX),
        POM_date DATETIME,
        obsolete SMALLINT
    );
    INSERT INTO #part_info
    SELECT p.part_no,
           p.style,
           p.category,
           CASE
           -- v4.1	
           WHEN p.color_desc IS NULL THEN p.style + ' ' + p.part_no -- color description v3.1
           WHEN p.POM_date <= @pom_asof
                AND p.POM_date <> '1/1/1900'
                AND p.RYG <> 'x' -- @last 
           THEN '#' + p.RYG ELSE -- color/active
                                ''
           END + ' ' + p.style + ' ' + p.color_desc + ' ' + ISNULL(
                                                            (
                                                            SELECT EyeSizes
                                                            FROM #tgSumEyeSizes a
                                                            WHERE a.category = p.category
                                                                  AND a.field_2 = p.style
                                                            ),
                                                            ''
                                                                  ) + p.Sun AS part_no2, -- add suns indicator
           p.POM_date,
           p.obsolete
    FROM
    (
    SELECT b.part_no,
           c.category,
           b.field_2 style,
           b.field_3 color_desc,
           CASE WHEN b.field_28 > @pom_asof THEN '' ELSE ISNULL(b.field_28, '') END AS POM_date,
           c.obsolete,
           dbo.f_cvo_get_pom_tl_status(c.category, b.field_2, b.field_3, @pom_asof /*@first*/) RYG,
           CASE WHEN c.type_code = 'sun' THEN ' S' ELSE '' END AS Sun -- 12/7/2017 per AM request
    FROM dbo.inv_master c (NOLOCK)
        INNER JOIN dbo.inv_master_add b (NOLOCK)
            ON c.part_no = b.part_no
    WHERE c.type_code IN ( 'frame', 'sun' )
          AND c.category NOT IN ( 'ch', 'me' )
    ) p;

    CREATE CLUSTERED INDEX idx_part_no ON #part_info (part_no);

    -- Buying Group info
    -- 071712 - tag - fix buying group

    DECLARE @bg TABLE
    (
        customer_code VARCHAR(8),
        discount VARCHAR(8),
        buying VARCHAR(80)
    );

    INSERT INTO @bg
    (
        customer_code,
        discount,
        buying
    )
    SELECT ar.customer_code,
           ar.price_code discount,
           CASE WHEN B.parent IS NULL THEN 'Direct Billing'
           WHEN B.parent
                BETWEEN '000500' AND '000699' THEN 'Buying Group: ' +
                                                   (
                                                   SELECT TOP (1)
                                                          customer_name
                                                   FROM dbo.arcust
                                                   WHERE customer_code = B.parent
                                                   ORDER BY customer_code
                                                   ) ELSE 'Bill-To: ' + ar.customer_name
           END AS buying
    FROM dbo.arcust ar (NOLOCK)
        LEFT OUTER JOIN dbo.arnarel B (NOLOCK)
            ON ar.customer_code = B.child;

    --
    IF (OBJECT_ID('tempdb.dbo.#cust_info') IS NOT NULL)
        DROP TABLE #cust_info;

    CREATE TABLE #cust_info
    (
        cust_code VARCHAR(8),
        ship_to VARCHAR(8),
        address_name VARCHAR(40),
        addr2 VARCHAR(40),
        addr3 VARCHAR(40),
        addr4 VARCHAR(40),
        contact_phone VARCHAR(30),
        city VARCHAR(40),
        postal_code VARCHAR(15),
        customer_short_name VARCHAR(8000),
        date_opened VARCHAR(23),
        territory VARCHAR(8),
		status_type int
    );
    INSERT INTO #cust_info
    (
        cust_code,
        ship_to,
        address_name,
        addr2,
        addr3,
        addr4,
        contact_phone,
        city,
        postal_code,
        customer_short_name,
        date_opened,
        territory,
		status_type
    )
    SELECT DISTINCT
           b.customer_code cust_code,
           b.ship_to_code ship_to,
                                                                  ---- v5.3
                                                                  --case when b.status_type <> 1 and b.ship_to_code <> '' then ''
                                                                  --    else isnull(b.ship_to_code,'') end as ship_to, 
                                                                  ---- v5.3
           b.address_name,
           b.addr2,
           b.addr3,
           b.addr4,
           b.contact_phone,
           b.city,
           b.postal_code,
           REPLACE(b.short_name, 'D-', 'D ') customer_short_name, -- 10/3/12 - v4.2 - Dr name sort
           'Date Opened '
           + SUBSTRING(CAST((CAST(FLOOR(CAST(b.added_by_date AS FLOAT)) AS DATETIME)) AS VARCHAR(25)), 1, 11) date_opened,
           b.territory_code territory,                             -- v5.3 082813 - tag
		   b.status_type
    FROM dbo.armaster b (NOLOCK);

    CREATE NONCLUSTERED INDEX idx_cust_info_1
    ON #cust_info (
                  territory,
                  cust_code,
                  ship_to
                  );

    --select * From #cust_info where cust_code = '023806'

    IF (OBJECT_ID('tempdb.dbo.#vsordList') IS NOT NULL)
        DROP TABLE #vsordList;

    CREATE TABLE #vsordlist
    (
        Shipped DECIMAL(22, 8),
        TimeEntered DATETIME,
        type CHAR(1),
        user_category VARCHAR(10),
        cust_code VARCHAR(10),
        ship_to VARCHAR(8),
        territory VARCHAR(8),
        part_no VARCHAR(30),
        date_applied INT,
        ShipDate VARCHAR(25),
        order_no VARCHAR(10),
        ext INT
    );
    INSERT INTO #vsordlist
    (
        Shipped,
        TimeEntered,
        type,
        user_category,
        cust_code,
        ship_to,
        territory,
        part_no,
        date_applied,
        ShipDate,
        order_no,
        ext
    )
    SELECT
        -- v3.2, v3.3 - exclude rebills
        CASE WHEN t2.type = 'i'
                  AND t2.user_category NOT LIKE '%RB' -- right(t2.user_category,2) <> 'RB' 
        THEN     ISNULL(t1.shipped, 0)
        WHEN t2.type = 'c'
             AND t1.return_code NOT LIKE '05%' -- left(t1.return_code,2) <> '05' 
        THEN ISNULL(t1.cr_shipped, 0) * -1 ELSE 0
        END AS Shipped,
                                                       --v3.1
        CASE WHEN t2.type = 'I' THEN t1.time_entered ELSE NULL END AS TimeEntered,
        t2.type,
        t2.user_category,
        t2.cust_code,
                                                       -- tag 082913 v5.3
        CASE WHEN ar.status_type <> 1 AND ar.ship_to_code <> '' THEN '' ELSE ISNULL(ar.ship_to_code, '') END AS ship_to,
                                                       -- v5.3 
        ar.territory_code territory,
        t1.part_no,
        t5.date_applied,
        CONVERT(VARCHAR(25), DATEADD(d, t5.date_applied - 711858, '1/1/1950'), 101) AS ShipDate,
        CONVERT(VARCHAR(10), t2.order_no) AS order_no, --v3.3 -- make varchar to match with history 
        t2.ext
    FROM dbo.orders_all t2 (NOLOCK)
        INNER JOIN dbo.orders_invoice oi (NOLOCK)
            ON t2.order_no = oi.order_no
               AND t2.ext = oi.order_ext
        INNER JOIN dbo.artrx t5 (NOLOCK)
            ON oi.trx_ctrl_num = t5.trx_ctrl_num
               --v3.1
               AND t5.trx_type IN ( 2031, 2032 )
               AND t5.void_flag = 0
               AND t5.doc_desc NOT LIKE 'CONVERTED%'
               AND t5.doc_desc NOT LIKE '%NONSALES%'
               AND t5.doc_ctrl_num NOT LIKE 'CB%'
               AND t5.doc_ctrl_num NOT LIKE 'FIN%'
        INNER JOIN dbo.ord_list t1 (NOLOCK)
            ON t1.order_no = t2.order_no
               AND t1.order_ext = t2.ext
        INNER JOIN dbo.inv_master t4 (NOLOCK)
            ON t4.part_no = t1.part_no
        LEFT OUTER JOIN dbo.armaster ar (NOLOCK)
            ON t2.cust_code = ar.customer_code
               AND t2.ship_to = ar.ship_to_code

    --left outer join armaster b (nolock) on b.customer_code = t2.cust_code and b.ship_to_code = t2.ship_to
    WHERE t5.date_applied
          BETWEEN @jf36 AND @jlast
          AND t4.type_code IN ( 'FRAME', 'SUN' )
          AND t4.category NOT IN ( 'ch', 'me' )
          AND t2.status = 'T';


    PRINT 'Done with ord_list - posted invoices';
    SELECT GETDATE();

    

    /* dON'T NEED TO CHECK HISTORY ANY LONGER ...
INSERT  INTO #vsordList
SELECT 
-- v3.2, v3.3 - exclude rebills
CASE WHEN t2.type = 'i'
AND t2.user_category NOT LIKE '%RB' -- right(t2.user_category,2) <> 'RB' 
THEN ISNULL(t1.shipped, 0)
WHEN t2.type = 'c'
AND t1.return_code NOT LIKE '05%' -- left(t1.return_code,2) <> '05' 
THEN ISNULL(t1.cr_shipped, 0) * -1
ELSE 0
END AS Shipped,
--v3.1
CASE WHEN t2.type = 'I' THEN t1.time_entered ELSE NULL END TimeEntered,
--t1.time_entered,
--v3.1
t2.type ,
t2.user_category ,
t2.cust_code , 
-- tag 082913 v5.3
CASE WHEN ar.status_type <> 1
AND ar.ship_to_code <> '' THEN ''
ELSE ISNULL(ar.ship_to_code, '')
END AS ship_to , 
-- isnull(t2.ship_to,'') ship_to, 
ar.territory_code territory ,
t1.part_no ,
t5.date_applied ,
CONVERT(VARCHAR(10), DATEADD(d, t5.date_applied - 711858,
'1/1/1950'), 101) AS ShipDate ,
CONVERT(VARCHAR(10), t2.order_no) AS order_no ,  --v3.3 -- make varchar to match with history 
t2.ext
FROM    dbo.orders_all t2 ( NOLOCK )
INNER JOIN dbo.orders_invoice oi ( NOLOCK ) ON t2.order_no = oi.order_no
AND t2.ext = oi.order_ext
INNER JOIN dbo.arinpchg t5 ( NOLOCK ) ON oi.trx_ctrl_num = t5.trx_ctrl_num
INNER JOIN dbo.ord_list t1 ( NOLOCK ) ON t1.order_no = t2.order_no
AND t1.order_ext = t2.ext
INNER JOIN dbo.inv_master t4 ( NOLOCK ) ON t4.part_no = t1.part_no
LEFT OUTER JOIN dbo.armaster ar ( NOLOCK ) ON t2.cust_code = ar.customer_code
AND t2.ship_to = ar.ship_to_code
WHERE   t5.date_applied BETWEEN @jf36 AND @jlast 
--v3.1
AND t5.trx_type IN ( 2031, 2032 ) -- and t5.void_flag = 0  
AND t5.doc_desc NOT LIKE 'CONVERTED%'
AND t5.doc_desc NOT LIKE '%NONSALES%'
AND t5.doc_ctrl_num NOT LIKE 'CB%'
AND t5.doc_ctrl_num NOT LIKE 'FIN%'
AND t4.type_code IN ( 'FRAME', 'SUN' ) AND t4.category NOT IN ('ch','me')
AND t2.status = 'T'
AND ( t1.shipped > 0
OR t1.cr_shipped > 0
)
--and t4.obsolete = 0		-- active items only
UNION ALL
SELECT  ISNULL(t1.shipped, 0) - ISNULL(t1.cr_shipped, 0) shipped,
--v3.1
CASE WHEN t2.type = 'I' THEN t1.time_entered ELSE NULL END TimeEntered,
--t1.time_entered,
--v3.1
t2.type ,
t2.user_category ,
t2.cust_code , 
-- tag 082913 v5.3
CASE WHEN ar.status_type <> 1
AND ar.ship_to_code <> '' THEN ''
ELSE ISNULL(ar.ship_to_code, '')
END AS ship_to , 
-- v5.3
ar.territory_code territory ,
t1.part_no ,
( DATEDIFF(DAY, '1/1/1950',
CONVERT(DATETIME, CONVERT(VARCHAR(8), ( YEAR(t2.date_shipped)
* 10000 )
+ ( MONTH(t2.date_shipped) * 100 )
+ DAY(t2.date_shipped)))) + 711858 ) ,
t2.date_shipped ,
t2.user_def_fld4 AS order_no ,  -- v3.3
--t2.order_no,
t2.ext
FROM    dbo.CVO_orders_all_Hist t2 ( NOLOCK )
INNER JOIN dbo.cvo_ord_list_hist t1 ( NOLOCK ) ON t2.order_no = t1.order_no
AND t2.ext = t1.order_ext
INNER JOIN dbo.inv_master t4 ( NOLOCK ) ON t4.part_no = t1.part_no
LEFT OUTER JOIN dbo.armaster ar ( NOLOCK ) ON t2.cust_code = ar.customer_code
AND t2.ship_to = ar.ship_to_code
WHERE   t2.date_shipped BETWEEN @F36 AND @last
AND t4.type_code IN ( 'FRAME', 'SUN' ) AND t4.category NOT IN ('ch','me')
AND t2.status = 'T';
--and t4.obsolete = 0		-- active items only
PRINT 'Done with ord_list hist';
*/

    CREATE NONCLUSTERED INDEX idx_vsord_custno
    ON #vsordlist (
                  territory ASC,
                  cust_code ASC,
                  ship_to ASC
                  )
    WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
    ON [PRIMARY];

    -- fix global ship-to's and other oddities in history table

    DELETE FROM #vsordlist
    WHERE Shipped = 0;

    UPDATE a
    SET ship_to = ''
    --select * 
    FROM #vsordlist a
    WHERE NOT EXISTS
    (
    SELECT 1
    FROM dbo.armaster AR
    WHERE a.cust_code = AR.customer_code
          AND a.ship_to = AR.ship_to_code
    );


    -- v5.3 - don't need to do this here any longer

    -- Collapse ship-to's that are not active
    update a set ship_to = ''
    from cvo_armaster_all ca (nolock) inner join #vsordlist a
    on ca.customer_code = a.cust_code and ca.ship_to =a.ship_to
    where ca.ship_to <> '' and ca.door = 0


    --update a set ship_to = ''
    --from armaster ca (nolock) inner join #vsordlist a
    --on ca.customer_code = a.cust_code and ca.ship_to_code =a.ship_to
    --where ca.status_type <> 1 and ship_to <> ''

    -- get date and order number of most recent stock order
    IF (OBJECT_ID('tempdb.dbo.#last_st') IS NOT NULL)
        DROP TABLE #last_st;

    CREATE TABLE #last_st
    (
        cust_code VARCHAR(10),
        ship_to VARCHAR(8),
        last_st_ord_date DATETIME,
        last_st_order_no VARCHAR(10),
        territory VARCHAR(8)
    );

    CREATE NONCLUSTERED INDEX idx_ord
    ON #vsordlist (
                  territory,
                  cust_code,
                  ship_to,
                  user_category,
                  type,
                  TimeEntered,
                  order_no
                  );

    INSERT INTO #last_st
    SELECT cust_code,
           ship_to,
           MAX(TimeEntered) last_st_ord_date,
           '0000000000' AS last_st_order_no,
           territory -- 082813

    FROM #vsordlist (NOLOCK) v
    WHERE ext = 0
          AND LEFT(user_category, 2) = 'ST'
          AND type = 'i'
    GROUP BY territory,
             cust_code,
             ship_to;

    CREATE NONCLUSTERED INDEX idx_ls
    ON #last_st (
                territory,
                cust_code,
                ship_to,
                last_st_ord_date
                );

    --tempdb..sp_help #last_st
    --tempdb..sp_help #vsordlist

    UPDATE ls
    SET last_st_order_no = LEFT(v.order_no, 10)
    FROM #last_st ls
        INNER JOIN #vsordlist v
            ON ls.cust_code = v.cust_code
               AND ls.ship_to = ls.ship_to
               AND ls.territory = v.territory
    WHERE ls.last_st_ord_date = v.TimeEntered
          AND v.ext = 0
          AND v.user_category LIKE 'ST%'
          -- left(v.user_category,2) = 'ST' 
          AND v.type = 'i';

    -- select * from #last_st WHERE cust_code = '046022'

    -- v5.2 - Setup summary figures

    IF (OBJECT_ID('tempdb.dbo.#cs') IS NOT NULL)
        DROP TABLE #cs;
    CREATE TABLE #cs
    (
        territory_code VARCHAR(8) NOT NULL,
        customer VARCHAR(10) NOT NULL,
        ship_to VARCHAR(10) NOT NULL,
        Custnetsales FLOAT(8) NOT NULL,
        NetSalesLY FLOAT(8) NOT NULL,
        YTDTY FLOAT(8) NOT NULL,
        YTDLY FLOAT(8) NOT NULL
    );
    INSERT INTO #cs
    (
        territory_code,
        customer,
        ship_to,
        Custnetsales,
        NetSalesLY,
        YTDTY,
        YTDLY
    )
    SELECT ar.territory_code,
           cs.customer,
           CASE WHEN (ar.status_type <> 1 OR car.door = 0) AND cs.ship_to <> '' THEN '' ELSE cs.ship_to END AS ship_to,
           SUM(CASE WHEN cs.yyyymmdd BETWEEN @F12 AND @last THEN cs.anet ELSE 0 END) AS Custnetsales,
           SUM(CASE WHEN cs.yyyymmdd BETWEEN @f24 AND DATEADD(yy, -1, @last) THEN cs.anet ELSE 0 END) AS NetSalesLY,
           SUM(CASE WHEN cs.yyyymmdd BETWEEN @TYstart AND @last THEN cs.anet ELSE 0 END) AS YTDTY,
           SUM(CASE WHEN cs.yyyymmdd BETWEEN @LYstart AND DATEADD(yy, -1, @last) THEN cs.anet ELSE 0 END) AS YTDLY
    FROM dbo.cvo_sbm_details AS cs (NOLOCK)
        INNER JOIN dbo.armaster ar (NOLOCK)
            ON cs.customer = ar.customer_code
               AND cs.ship_to = ar.ship_to_code
        INNER JOIN cvo_armaster_all car (NOLOCK)
            ON car.customer_code = ar.customer_code AND car.ship_to = cs.ship_to
    WHERE cs.yyyymmdd
    BETWEEN @f24 AND @last
    GROUP BY ar.territory_code,
             cs.customer,
             CASE WHEN (ar.status_type <> 1 OR car.door = 0) AND cs.ship_to <> '' THEN '' ELSE cs.ship_to END;

    CREATE NONCLUSTERED INDEX idx_cs
    ON #cs (
           territory_code,
           customer,
           ship_to
           );

-- SELECT * FROM #cs WHERE customer = '046022'

    -- 
    PRINT 'Start cvo_CIR';
    SELECT GETDATE();

    DECLARE @MinNetSales DECIMAL(20, 8);
    SET @MinNetSales = 1;

    IF (OBJECT_ID('tempdb.dbo.#cvo_CIR_det') IS NOT NULL)
        DROP TABLE #cvo_CIR_det;

    CREATE TABLE #cvo_cir_det
    (
        territory VARCHAR(8),
        cust_code VARCHAR(10),
        ship_to VARCHAR(8),
        part_no VARCHAR(30),
        TimeEntered DATETIME,
        custnetsales REAL,
        netsalesly REAL,
        ytdty REAL,
        ytdly REAL,
        ST12 DECIMAL(22, 8),
        ST36 DECIMAL(22, 8),
        RX12 DECIMAL(22, 8),
        RX36 DECIMAL(22, 8),
        RET12 DECIMAL(22, 8),
        RET36 DECIMAL(22, 8),
        NET12 DECIMAL(22, 8),
        net36 DECIMAL(22, 8),
        OTH12 DECIMAL(22, 8),
        OTH36 DECIMAL(22, 8),
        TotAcctNetSales FLOAT(8)
    );

    INSERT INTO #cvo_cir_det
    (
        territory,
        cust_code,
        ship_to,
        part_no,
        TimeEntered,
        custnetsales,
        netsalesly,
        ytdty,
        ytdly,
        ST12,
        ST36,
        RX12,
        RX36,
        RET12,
        RET36,
        NET12,
        net36,
        OTH12,
        OTH36,
        TotAcctNetSales
    )
    SELECT a.territory,
           a.cust_code,
           a.ship_to,
           a.part_no,
           a.TimeEntered,
           -- v5.2
           ISNULL(#cs.Custnetsales, 0) custnetsales,
           ISNULL(#cs.NetSalesLY, 0) netsalesly,
           ISNULL(#cs.YTDTY, 0) ytdty,
           ISNULL(#cs.YTDLY, 0) ytdly,
           CASE WHEN
                (
                a.ShipDate >= @F12
                AND a.type = 'I'
                AND a.user_category LIKE 'ST%'
                ) --left(A.user_category,2) = 'ST') 
           THEN (a.Shipped) ELSE 0
           END AS ST12,
           CASE WHEN
                (
                a.type = 'I'
                AND a.user_category LIKE 'ST%'
                ) --left(A.user_category,2) = 'ST') 
           THEN (a.Shipped) ELSE 0
           END ST36,
           CASE WHEN
                (
                a.ShipDate >= @F12
                AND a.type = 'I'
                AND a.user_category LIKE 'RX%'
                ) --left(A.user_category,2) = 'RX') 
           THEN (a.Shipped) ELSE 0
           END RX12,
           CASE WHEN
                (
                a.type = 'I'
                AND a.user_category LIKE 'RX%'
                ) --left(A.user_category,2) = 'RX') 
           THEN (a.Shipped) ELSE 0
           END RX36,
           CASE WHEN (a.ShipDate >= @F12 AND a.type = 'C') THEN (a.Shipped) ELSE 0 END RET12,
           CASE WHEN a.type = 'C' THEN (a.Shipped) ELSE 0 END RET36,
           CASE WHEN (a.ShipDate >= @F12)
                     AND
                     (
                     LEFT(a.user_category, 2) IN ( 'RX', 'ST' )
                     OR a.type = 'c'
                     ) THEN (a.Shipped) ELSE 0
           END NET12,
           CASE WHEN (LEFT(a.user_category, 2) IN ( 'RX', 'ST' ) OR a.type = 'c') THEN a.Shipped ELSE 0 END net36,
           CASE WHEN
                (
                a.ShipDate >= @F12
                AND a.type = 'I'
                AND LEFT(a.user_category, 2) NOT IN ( 'RX', 'ST' )
                ) THEN (a.Shipped) ELSE 0
           END OTH12,
           CASE WHEN (a.type = 'I' AND LEFT(a.user_category, 2) NOT IN ( 'RX', 'ST' )) THEN (a.Shipped) ELSE 0 END OTH36,
           -- v4.4
           ISNULL(
           (
           SELECT SUM(cs.anet)
           FROM dbo.cvo_sbm_details AS cs (NOLOCK)
               JOIN dbo.armaster ar (NOLOCK)
                   ON ar.customer_code = cs.customer
                      AND ar.ship_to_code = cs.ship_to
           WHERE cs.customer = a.cust_code
                 AND ar.territory_code = a.territory
                 AND cs.yyyymmdd
                 BETWEEN @F12 AND @last
           ),
           0
                 ) AS TotAcctNetSales
    FROM #vsordlist a (NOLOCK)
        LEFT OUTER JOIN #cs (NOLOCK)
            ON a.territory = #cs.territory_code
               AND a.cust_code = #cs.customer
               AND a.ship_to = #cs.ship_to;

    -- end v5.2

    CREATE NONCLUSTERED INDEX idx_cvo_CIR
    ON #cvo_cir_det (
                    territory ASC,
                    cust_code ASC,
                    ship_to ASC
                    )
    WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF)
    ON [PRIMARY];

    /* 080112 - tag -  new code to combine affiliated accounts */
    --select * from #cvo_cir_det where cust_code in ('931867','031867')


    DECLARE @cust_swap TABLE
    (
        from_cust VARCHAR(8),
        shipto VARCHAR(8),
        to_cust VARCHAR(8),
        territory VARCHAR(8)
    );

    INSERT INTO @cust_swap
    (
        from_cust,
        shipto,
        to_cust,
        territory
    )
    SELECT a.customer_code AS from_cust,
           a.ship_to_code AS shipto,
           a.affiliated_cust_code AS to_cust,
           a.territory_code AS territory
    FROM dbo.armaster a (NOLOCK)
        INNER JOIN dbo.armaster b (NOLOCK)
            ON a.affiliated_cust_code = b.customer_code
               AND a.ship_to_code = b.ship_to_code
    WHERE a.status_type <> 1
          AND a.address_type <> 9
          AND a.affiliated_cust_code <> ''
          AND a.affiliated_cust_code IS NOT NULL
          AND b.status_type = 1
          AND b.address_type <> 9
          AND
          (
          a.customer_code LIKE '9%'
          OR b.customer_code LIKE '9%'
          );
    --(left(a.customer_code,1)= '9' or left(b.customer_code,1) = '9')

    SELECT @@rowcount;
    SELECT from_cust,
           shipto,
           to_cust,
           territory
    FROM @cust_swap;

    -- CREATE NONCLUSTERED INDEX idx_cs_1 ON @cust_swap (territory, from_cust, shipto, to_cust);

    IF (OBJECT_ID('tempdb.dbo.#new') IS NOT NULL)
        DROP TABLE #new;

    CREATE TABLE #new
    (
        territory VARCHAR(8),
        cust_code VARCHAR(10),
        ship_to VARCHAR(8),
        part_no VARCHAR(30),
        TimeEntered DATETIME,
        custnetsales REAL,
        netsalesly REAL,
        ytdty REAL,
        ytdly REAL,
        ST12 DECIMAL(22, 8),
        ST36 DECIMAL(22, 8),
        RX12 DECIMAL(22, 8),
        RX36 DECIMAL(22, 8),
        RET12 DECIMAL(22, 8),
        RET36 DECIMAL(22, 8),
        NET12 DECIMAL(22, 8),
        net36 DECIMAL(22, 8),
        OTH12 DECIMAL(22, 8),
        OTH36 DECIMAL(22, 8),
        TotAcctNetSales REAL
    );
    INSERT INTO #new
    SELECT xx.territory,
           xx.cust_code,
           xx.ship_to,
           xx.part_no,
           xx.TimeEntered,
           xx.custnetsales,
           xx.netsalesly,
           xx.ytdty,
           xx.ytdly,
           xx.ST12,
           xx.ST36,
           xx.RX12,
           xx.RX36,
           xx.RET12,
           xx.RET36,
           xx.NET12,
           xx.net36,
           xx.OTH12,
           xx.OTH36,
           xx.TotAcctNetSales
    FROM @cust_swap c
        INNER JOIN #cvo_cir_det xx (NOLOCK)
            ON c.to_cust = xx.cust_code
               AND c.shipto = xx.ship_to
               AND c.territory = xx.territory;

    UPDATE old
    SET old.territory = new.territory,
        old.cust_code = new.cust_code,
        old.ship_to = new.ship_to
    FROM @cust_swap c
        INNER JOIN #new new
            ON new.cust_code = c.to_cust
               AND c.shipto = new.ship_to
               AND new.territory = c.territory
        INNER JOIN #cvo_cir_det old (NOLOCK)
            ON old.cust_code = c.from_cust
               AND c.shipto = old.ship_to
               AND old.territory = c.territory;

    UPDATE new
    SET -- v3.2 - net sales
        new.custnetsales = ISNULL(
                           (
                           SELECT SUM(Custnetsales)
                           FROM #cs
                           WHERE #cs.territory_code = c.territory
                                 AND #cs.customer IN ( c.to_cust, c.from_cust )
                                 AND #cs.ship_to = c.shipto
                           ),
                           0
                                 ),
        --v3.3 
        new.netsalesly = ISNULL(
                         (
                         SELECT SUM(NetSalesLY)
                         FROM #cs
                         WHERE #cs.territory_code = c.territory
                               AND #cs.customer IN ( c.to_cust, c.from_cust )
                               AND #cs.ship_to = c.shipto
                         ),
                         0
                               ),
        new.ytdty = ISNULL(
                    (
                    SELECT SUM(YTDTY)
                    FROM #cs
                    WHERE #cs.territory_code = c.territory
                          AND
                          (
                          #cs.customer = c.to_cust
                          OR #cs.customer = c.from_cust
                          )
                          AND #cs.ship_to = c.shipto
                    ),
                    0
                          ),
        new.ytdly = ISNULL(
                    (
                    SELECT SUM(YTDLY)
                    FROM #cs
                    WHERE #cs.territory_code = c.territory
                          AND
                          (
                          #cs.customer = c.to_cust
                          OR #cs.customer = c.from_cust
                          )
                          AND #cs.ship_to = c.shipto
                    ),
                    0
                          ),
        new.TotAcctNetSales = ISNULL(
                              (
                              SELECT SUM(cs.anet)
                              FROM dbo.cvo_sbm_details cs,
                                   dbo.armaster ar (NOLOCK)
                              WHERE cs.customer = ar.customer_code
                                    AND cs.customer IN ( c.to_cust, c.from_cust )
                                    AND ar.territory_code = c.territory
                                    AND cs.yyyymmdd
                                    BETWEEN @F12 AND @last
                              ),
                              0
                                    )
    FROM @cust_swap c
        INNER JOIN #cvo_cir_det new (NOLOCK)
            ON new.cust_code = c.to_cust
               AND c.shipto = new.ship_to
               AND new.territory = c.territory;

    /* end affiliated update 080112 tag */

    IF (OBJECT_ID('dbo.cvo_CarBi') IS NOT NULL)
        DROP TABLE dbo.cvo_carbi;

    CREATE TABLE dbo.cvo_carbi
    (
        as_of_date DATETIME NULL,
        territory VARCHAR(8) NULL,
        slp VARCHAR(8) NULL,
        cust_code VARCHAR(10) NULL,
        ship_to VARCHAR(10) NULL,
        address_name VARCHAR(40) NULL,
        addr2 VARCHAR(40) NULL,
        addr3 VARCHAR(40) NULL,
        addr4 VARCHAR(40) NULL,
                                              --v3.4
        city VARCHAR(40) NULL,
        postal_code VARCHAR(15) NULL,
                                              --
        customer_short_name VARCHAR(10) NULL, -- v4.2
        contact_phone VARCHAR(30) NULL,
        date_opened VARCHAR(23) NULL,
        last_st_ord_date DATETIME NULL,       --v3.1
        last_st_order_no VARCHAR(30) NULL,
        discount VARCHAR(8) NULL,
        buying VARCHAR(54) NULL,
        cstatus VARCHAR(26) NULL,
        custnetsales FLOAT NULL,              -- v3.2
        NetSalesLY FLOAT NULL,                -- v3.3
        YTDTY FLOAT NULL,
        YTDLY FLOAT NULL,
        TotAcctNetSales FLOAT NULL,           -- v4.4
        category VARCHAR(10) NULL,
        style VARCHAR(40) NULL,
        part_no2 VARCHAR(100) NULL,
        pom_date DATETIME NULL,
        First_order_date DATETIME NULL,
        Last_order_date DATETIME NULL,
        mst12 FLOAT NULL,
        mst36 FLOAT NULL,
        mrx12 FLOAT NULL,
        mrx36 FLOAT NULL,
        mret12 FLOAT NULL,
        mret36 FLOAT NULL,
        mnet12 FLOAT NULL,
        mnet36 FLOAT NULL,
        moth12 FLOAT NULL,
        moth36 FLOAT NULL
    );

    CREATE CLUSTERED INDEX idx_cir_cust
    ON dbo.cvo_carbi (
                     cust_code,
                     ship_to
                     );

    INSERT INTO dbo.cvo_carbi
    (
        territory,
        cust_code,
        ship_to,
        custnetsales,    -- v3.2
        NetSalesLY,      -- v3.3
        YTDTY,
        YTDLY,
        TotAcctNetSales, -- v4.4
        category,
        style,
        part_no2,
        pom_date,
        First_order_date,
        Last_order_date,
        mst12,
        mst36,
        mrx12,
        mrx36,
        mret12,
        mret36,
        mnet12,
        mnet36,
        moth12,
        moth36
    )
    SELECT c.territory,
           c.cust_code,
           c.ship_to,
           c.custnetsales,    -- v3.2
           c.netsalesly,      -- v3.3
           c.ytdty,
           c.ytdly,
           c.TotAcctNetSales, -- v4.4
           p.category,
           p.style,
           p.part_no2,
           MIN(p.POM_date) pom_date,
           MIN(c.TimeEntered) First_order_date,
           MAX(c.TimeEntered) Last_order_date,
           SUM(ISNULL(c.ST12, 0)) mst12,
           SUM(ISNULL(c.ST36, 0)) mst36,
           SUM(ISNULL(c.RX12, 0)) mrx12,
           SUM(ISNULL(c.RX36, 0)) mrx36,
           SUM(ISNULL(c.RET12, 0)) mret12,
           SUM(ISNULL(c.RET36, 0)) mret36,
           SUM(ISNULL(c.NET12, 0)) mnet12,
           SUM(ISNULL(c.net36, 0)) mnet36,
           SUM(ISNULL(c.OTH12, 0)) moth12,
           SUM(ISNULL(c.OTH36, 0)) moth36
    FROM #cvo_cir_det c
        INNER JOIN #part_info p
            ON c.part_no = p.part_no
    GROUP BY c.territory,
             c.cust_code,
             c.ship_to,
             c.custnetsales,    -- v3.2
             c.netsalesly,      -- v3.3
             c.ytdty,
             c.ytdly,
             c.TotAcctNetSales, -- v4.4
             p.category,
             p.style,
             p.part_no2;

    -- new

    UPDATE cir
    SET cir.as_of_date = @last,
        cir.slp = '',
        cir.address_name = b.address_name,
        cir.addr2 = b.addr2,
        cir.addr3 = b.addr3,
        cir.addr4 = b.addr4,
        cir.city = b.city,
        cir.postal_code = b.postal_code,
        cir.customer_short_name = b.customer_short_name, -- v4.2 - 100312
        cir.contact_phone = b.contact_phone,
        cir.date_opened = b.date_opened,
        cir.discount = bg.discount,
        cir.buying = bg.buying,
        -- cir.cstatus = '',
		cir.cstatus = CASE WHEN b.status_type = 1 THEN 'A' ELSE 'I' end,
        cir.last_st_ord_date = st.last_st_ord_date,
        cir.last_st_order_no = st.last_st_order_no
    FROM dbo.cvo_carbi cir
        LEFT OUTER JOIN #cust_info b
            ON cir.cust_code = b.cust_code
               AND cir.ship_to = b.ship_to
               AND cir.territory = b.territory -- 082813
        LEFT OUTER JOIN @bg bg
            ON bg.customer_code = b.cust_code
        LEFT OUTER JOIN #last_st st
            ON cir.cust_code = st.cust_code
               AND cir.ship_to = st.ship_to
               AND cir.territory = st.territory -- 082813
    WHERE 1 = 1;
    -- new 

    -- get name and address info for stragglers

    UPDATE cir
    SET cir.as_of_date = @last,
        cir.slp = '',
        cir.address_name = b.address_name,
        cir.addr2 = b.addr2,
        cir.addr3 = b.addr3,
        cir.addr4 = b.addr4,
        cir.city = b.city,
        cir.postal_code = b.postal_code,
        cir.customer_short_name = b.customer_short_name, -- v4.2 - 100312
        cir.contact_phone = b.contact_phone,
        cir.date_opened = b.date_opened,
        cir.discount = bg.discount,
        cir.buying = bg.buying,
        -- cir.cstatus = '',
		cir.cstatus = CASE WHEN b.status_type = 1 THEN 'A' ELSE 'I' end,
        cir.last_st_ord_date = st.last_st_ord_date,
        cir.last_st_order_no = st.last_st_order_no
    FROM dbo.cvo_carbi cir
        INNER JOIN #cust_info b
            ON cir.cust_code = b.cust_code
               AND cir.ship_to = b.ship_to
        LEFT OUTER JOIN @bg bg
            ON bg.customer_code = b.cust_code
        LEFT OUTER JOIN #last_st st
            ON cir.cust_code = st.cust_code
               AND cir.ship_to = st.ship_to
    WHERE cir.address_name IS NULL;

    -- figure date opened on affiliated accounts
    UPDATE cir
    SET cir.date_opened =
        (
        SELECT MIN(date_opened)
        FROM #cust_info ci
        WHERE (
              cs.to_cust = cir.cust_code
              OR cs.from_cust = cir.cust_code
              )
              AND date_opened IS NOT NULL
        )
    FROM @cust_swap cs
        INNER JOIN dbo.cvo_carbi cir
            ON cs.to_cust = cir.cust_code;

    --select distinct cust_code, ship_to, custnetsales from cvo_carbi order by cust_code, ship_to

    SELECT COUNT(*)
    FROM dbo.cvo_carbi
    WHERE (
          mst12 = 0
          AND mrx12 = 0
          AND mret12 = 0
          );
    --DELETE FROM CVO_CarBi WHERE (mst12=0 AND mrx12=0 AND mret12=0) -- v3.1 4/26/2012

    SELECT COUNT(*)
    FROM #cvo_cir_det;
    SELECT COUNT(*)
    FROM dbo.cvo_carbi;

END;

-- 





GO
