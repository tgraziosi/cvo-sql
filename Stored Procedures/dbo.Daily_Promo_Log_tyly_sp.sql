SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[Daily_Promo_Log_tyly_sp]
    @DFrom DATETIME,
    @DTo DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- EXEC dbo.Daily_Promo_Log_tyly_sp @DFrom = '2019-02-05',  @DTo = '2019-02-07'    -- datetime
    

    DECLARE @dfromly DATETIME, @dtoly DATETIME, @dfromty DATETIME, @dtoty datetime;

    
    SELECT @dfromty = DATEADD(YEAR,0, @dfrom), @dtoty = CASE WHEN @dto > GETDATE() THEN DATEADD(dd, DATEDIFF(dd,0, GETDATE()), 0) ELSE @dto end;

    SELECT @dfromly = DATEADD(YEAR,-1, @dfromty), @dtoly = DATEADD(YEAR,-1,@dto);

    ; WITH T1 
    
     AS (SELECT o.order_no,
               o.cust_code,
               o.ext,
               DATEADD(dd, DATEDIFF(dd, 0, date_entered), 0) AS date_entered,
               ISNULL(cvo.promo_id, '') AS promo_id,
               ISNULL(cvo.promo_level, '') AS promo_level,
               o.user_category AS OrderType,
               o.type + '-' + LEFT(o.user_category, 2) AS Type,
               CASE WHEN o.date_entered < @dtoly THEN 'LY' ELSE 'TY' END AS TYLY
        FROM orders o (NOLOCK)
            INNER JOIN CVO_orders_all cvo (NOLOCK)
                ON o.order_no = cvo.order_no
                   AND o.ext = cvo.ext
        WHERE o.status <> 'V'
              AND o.void = 'N'
              AND o.type = 'I'
              -- and left(o.user_category,2) <> 'RX'		-- CVO excluded 2/27/13 EL (for RX-PC's
              AND o.user_category NOT IN ( 'RX-RE', 'RX-RB', 'RX-PL', 'RX-LP', 'RX' ) -- EL -- 061417 - ADD RX-RE
              AND RIGHT(o.user_category, 2) NOT IN ( 'PM' )
              AND o.who_entered <> 'BACKORDR'
              AND 
              (date_entered
              BETWEEN @DFrom AND @DTo
              OR date_entered between @dfromly AND @dtoly)
              )
    , T2
    AS (SELECT promo_id,
               promo_level,
               promo_name
        FROM CVO_promotions
        WHERE promo_start_date <= @DFrom
              -- AND promo_end_date >= @DTo
              AND promo_end_date >= GETDATE() -- 10/29/2013 - all current promos in period
              AND void <> 'V' -- tag 121913 - exclude voids
    )


    SELECT o.cust_code,
           CASE
               WHEN o.promo_id <> '' THEN
                   o.promo_id -- 10/29/2013
               WHEN p.promo_id = '' THEN
                   '-'
               WHEN p.promo_id IS NULL THEN
                   '-'
               ELSE
                   p.promo_id
           END AS promo_id,
           CASE
               WHEN o.promo_level <> '' THEN
                   o.promo_level -- 10/29/2013
               WHEN p.promo_level = '' THEN
                   '-'
               WHEN p.promo_level IS NULL THEN
                   '-'
               ELSE
                   p.promo_level
           END AS promo_level,
           ISNULL(p.promo_name,'') promo_name,
           order_no,
           ext,
           date_entered,
           --isnull(cvo.promo_id,'') AS promo_id,
           --isnull(cvo.promo_level,'') as promo_level,
           OrderType,
           TYPE,
           tyly
    FROM T1 o
        full OUTER JOIN T2 p
            ON o.promo_id = p.promo_id
               AND o.promo_level = p.promo_level
    WHERE (o.promo_level NOT IN ( 'rx', 'pc' )) -- 061417 - don't include revo-rx or pc's (SM)
    ORDER BY promo_id,
             promo_level;
--)

--Select * from c
--Where promo_id <> '-'
--order by promo_id,promo_level



END;








GO
GRANT EXECUTE ON  [dbo].[Daily_Promo_Log_tyly_sp] TO [public]
GO
