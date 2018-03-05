SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dashboard_upd_sp]
AS
BEGIN

	SET NOCOUNT ON;

    -- EXEC dbo.cvo_dc_dashboard_upd_sp
    -- SELECT * FROM dbo.cvo_dc_dashboard_arch_tbl AS ddat
    -- SELECT * FROM dbo.cvo_dc_dashboard_news_tbl AS ddnt

    DECLARE @asofdate DATETIME;

    SET @asofdate = GETDATE();

    IF OBJECT_ID('dbo.cvo_dc_dashboard_news_tbl') IS NULL
    BEGIN
        CREATE TABLE cvo_dc_dashboard_news_tbl
        (
            Tag VARCHAR(255) NOT NULL,
            order_type VARCHAR(2) NULL,
            must_go_today INT NULL,
            num_orders INT NULL,
            asofdate DATETIME NOT NULL,
            id INT IDENTITY(1, 1) NOT NULL
        );

        GRANT SELECT ON dbo.cvo_dc_dashboard_news_tbl TO PUBLIC;
    END;

    IF OBJECT_ID('dbo.cvo_dc_dashboard_arch_tbl') IS NULL
    BEGIN
        CREATE TABLE cvo_dc_dashboard_arch_tbl
        (
            Tag VARCHAR(255) NOT NULL,
            order_type VARCHAR(2) NULL,
            must_go_today INT NULL,
            num_orders INT NULL,
            asofdate DATETIME NOT NULL,
            id INT IDENTITY(1, 1) NOT NULL
        );

        GRANT SELECT ON dbo.cvo_dc_dashboard_arch_tbl TO PUBLIC;
    END;

    INSERT INTO dbo.cvo_dc_dashboard_arch_tbl
    (
        Tag,
        order_type,
        must_go_today,
        num_orders,
        asofdate
    )
    SELECT ddnt.Tag,
           ddnt.order_type,
           ddnt.must_go_today,
           ddnt.num_orders,
           ddnt.asofdate
    FROM dbo.cvo_dc_dashboard_news_tbl AS ddnt;

    TRUNCATE TABLE dbo.cvo_dc_dashboard_news_tbl;

    INSERT INTO dbo.cvo_dc_dashboard_news_tbl
    (
        Tag,
        order_type,
        must_go_today,
        num_orders,
        asofdate
    )
    SELECT 'Orders Today' Tag,
           CASE WHEN o.user_category LIKE 'rx%' THEN 'RX' ELSE 'ST' END AS tag_type,
           SUM(ISNULL(co.must_go_today, 0)) must_go_today,
           COUNT(DISTINCT o.order_no) num_orders,
           @asofdate
    FROM dbo.orders o (NOLOCK)
        JOIN dbo.CVO_orders_all co (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
    WHERE o.date_entered > DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)
          AND o.type = 'i'
          AND o.who_entered <> 'backordr'
          -- AND o.ext >= 0
    GROUP BY CASE WHEN o.user_category LIKE 'rx%' THEN 'RX' ELSE 'ST' END

	UNION all

    SELECT t.trans + ' ' + CASE WHEN pc.tran_no IS NOT NULL THEN 'Cart' ELSE 'Manual' END Tag,
           CASE WHEN o.user_category LIKE 'rx%' THEN 'RX' ELSE 'ST' END AS order_type,
           SUM(ISNULL(co.must_go_today, 0)) must_go_today,
           COUNT(DISTINCT t.tran_no) num_orders,
           @asofdate
    FROM dbo.tdc_log t (NOLOCK)
        JOIN dbo.orders o (NOLOCK)
            ON o.order_no = t.tran_no
               AND o.ext = t.tran_ext
        JOIN dbo.CVO_orders_all co (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
        LEFT OUTER JOIN
        (
        SELECT DISTINCT
               tran_no,
               tran_ext
        FROM dbo.tdc_log
        WHERE trans IN ( 'check in', 'check out' )
              AND tran_date > DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)
        ) pc
            ON pc.tran_no = t.tran_no
               AND pc.tran_ext = t.tran_ext

    WHERE t.trans IN ( 'STDPICK', 'DataArrival', 'check in', 'check out' )
          AND t.tran_date > DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)
          AND t.UserID > ''
          AND o.type = 'i'
          -- AND o.ext >= 0
    GROUP BY t.trans + ' ' + CASE WHEN pc.tran_no IS NOT NULL THEN 'Cart' ELSE 'Manual' END,
             CASE WHEN pc.tran_no IS NOT NULL THEN 'Cart Pick' ELSE 'Manual Pick' END,
             CASE WHEN o.user_category LIKE 'rx%' THEN 'RX' ELSE 'ST' END

	UNION ALL
    
	SELECT CASE WHEN tct.status IN ( 'f', 's', 'x' ) THEN 'Staged'
               WHEN o.status = 'P' THEN 'Open/Pick'
               WHEN o.status = 'q' THEN 'Open/Print'
               WHEN o.status = 'r' THEN 'Staged' ELSE 'Unknown'
           END AS Tag,
           CASE WHEN o.user_category LIKE 'rx%' THEN 'RX' ELSE 'ST' END AS tag_type,
           SUM(ISNULL(co.must_go_today, 0)) must_go_today,
           COUNT(DISTINCT o.order_no) num_orders,
           @asofdate
    FROM dbo.orders o (NOLOCK)
        JOIN dbo.CVO_orders_all co (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
        LEFT OUTER JOIN dbo.tdc_carton_tx AS tct (NOLOCK)
            ON tct.order_no = o.order_no
               AND tct.order_ext = o.ext

    WHERE o.type = 'i'
          AND o.status IN ( 'p', 'q', 'r' )
    --AND tct.status IN ('x','f','s')

    GROUP BY CASE WHEN tct.status IN ( 'f', 's', 'x' ) THEN 'Staged'
                 WHEN o.status = 'P' THEN 'Open/Pick'
                 WHEN o.status = 'q' THEN 'Open/Print'
                 WHEN o.status = 'r' THEN 'Staged' ELSE 'Unknown'
             END,
             CASE WHEN o.user_category LIKE 'rx%' THEN 'RX' ELSE 'ST' END

	UNION all

    SELECT 'Orders to Ship' Tag,
           CASE WHEN o.user_category LIKE 'rx%' THEN 'RX' ELSE 'ST' END AS tag_type,
           SUM(ISNULL(co.must_go_today, 0)) must_go_today,
           COUNT(DISTINCT o.order_no) num_orders,
           @asofdate
    FROM dbo.orders o (NOLOCK)
        JOIN dbo.CVO_orders_all co (NOLOCK)
            ON co.order_no = o.order_no
               AND co.ext = o.ext
    WHERE o.sch_ship_date <= DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0)
          AND o.type = 'i'
          -- AND o.who_entered <> 'backordr'
		  AND o.status = 'N'
          -- AND o.ext >= 0
    GROUP BY CASE WHEN o.user_category LIKE 'rx%' THEN 'RX' ELSE 'ST' END;

END;



GRANT EXECUTE ON dbo.cvo_dc_dashboard_upd_sp TO PUBLIC;


GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dashboard_upd_sp] TO [public]
GO
