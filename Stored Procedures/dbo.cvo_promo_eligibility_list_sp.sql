SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_promo_eligibility_list_sp] @terr VARCHAR(12) , @customer VARCHAR(12) , @promolist VARCHAR(1024) output
AS
BEGIN

-- get a list of all promos that a cust is OK to get

-- execute cvo_promo_eligibility_list_sp 20201

-- all current, seasonal promos

SET NOCOUNT ON;

IF ( OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL )
    DROP TABLE #territory;
CREATE TABLE #territory
    (
        territory VARCHAR(10) ,
        region VARCHAR(3) ,
        r_id INT ,
        t_id INT
    );

IF @terr IS NULL
        INSERT  #territory
                SELECT DISTINCT
                        territory_code ,
                        dbo.calculate_region_fn(territory_code) region ,
                        0 ,
                        0
                FROM    armaster
                WHERE   territory_code IS NOT NULL
                ORDER BY territory_code;
ELSE
        INSERT  INTO #territory
                ( territory ,
                    region ,
                    r_id ,
                    t_id
                )
                SELECT DISTINCT
                        ListItem ,
                        dbo.calculate_region_fn(ListItem) region ,
                        0 ,
                        0
                FROM    dbo.f_comma_list_to_table(@terr)
                ORDER BY ListItem;


IF ( OBJECT_ID('tempdb.dbo.#r') IS NOT NULL )
    DROP TABLE #r;
CREATE TABLE #r
    (
      cust_code VARCHAR(8) NULL ,
      ship_to VARCHAR(8) NULL ,
      promo_id VARCHAR(20) NULL ,
      promo_level VARCHAR(30) NULL ,
      code INT NULL ,
      reason VARCHAR(200) NULL ,
      review INT NULL
    );


IF ( OBJECT_ID('tempdb.dbo.#f') IS NOT NULL )
    DROP TABLE #f;
CREATE TABLE #f
    (
      code INT NULL ,
      reason VARCHAR(200) NULL
    );

IF ( OBJECT_ID('tempdb.dbo.#p') IS NOT NULL )
    DROP TABLE #p;

SELECT  promo_id ,
        promo_level ,
        promo_name ,
        promo_start_date ,
        promo_end_date ,
        review_ship_to ,
        frequency ,
        frequency_type,
		season_program
INTO    #p
FROM    CVO_promotions
WHERE   promo_end_date > GETDATE()
        AND promo_start_date <= GETDATE()
        AND 'N' = ISNULL(void, 'N')
		-- AND promo_id IN ('6+2','9+3')
		-- AND season_program = 1
		-- AND review_ship_to = 1
		;

--SELECT  *
--FROM    #p AS p;

DECLARE @cust VARCHAR(10) ,
    @ship_To VARCHAR(10) ,
    @row_id VARCHAR(50) ,
	@c_row_id VARCHAR(50),
    @promo VARCHAR(20) ,
    @level VARCHAR(30) ,
    @review INT ,
    @ret_code INT;

-- run thru all active customers/ship-to's

SELECT DISTINCT customer_code, ship_to_code
INTO #c
FROM #territory AS t
JOIN armaster ar ON t.territory = ar.territory_code
WHERE   1 = 1
        AND status_type = 1 -- active only
        AND address_type IN ( 0, 1 ) -- bill-to and ship-to
        AND valid_shipto_flag = 1
		AND ar.customer_code = ISNULL(@customer,ar.customer_code)

SELECT  @c_row_id = MIN(customer_code+ship_to_code) FROM #c AS c;

SELECT  @cust = customer_code, @ship_To = ship_to_code FROM #c WHERE @c_row_id = customer_code+ship_to_code;

WHILE @c_row_id IS NOT NULL
    
	BEGIN

        SELECT  @row_id = MIN(promo_id + promo_level)
        FROM    #p;

        WHILE @row_id IS NOT NULL
            BEGIN
                SELECT  @promo = promo_id ,
                        @level = promo_level ,
                        @review = #p.review_ship_to
                FROM    #p
                WHERE   @row_id = promo_id + promo_level;

			-- just get the pass fail status.  we'll get the fail reasons later (due to variable sp output).
                IF @review = 1
                    EXECUTE @ret_code = CVO_verify_customer_shipto_quali_sp @promo,
                        @level, @cust, @ship_To, 0, 0, 1;
                ELSE
                    EXECUTE @ret_code = CVO_verify_customer_quali_sp @promo,
                        @level, @cust, @ship_To, 0, 0, 1;
        
                INSERT  #r
                        ( cust_code ,
                          ship_to ,
                          promo_id ,
                          promo_level ,
                          code ,
                          reason ,
                          review
					    )
                VALUES  ( @cust ,
                          @ship_To ,
                          @promo ,
                          @level ,
                          @ret_code ,
                          CASE WHEN @ret_code = 0 THEN 'Failed'
                               ELSE 'OK'
                          END ,
                          @review
                        );

                SELECT  @row_id = MIN(promo_id + promo_level)
                FROM    #p
                WHERE   promo_id + promo_level > @row_id;
            END; -- promo+level

			SELECT  @c_row_id = MIN(customer_code+ship_to_code) FROM #c AS c
					WHERE c.customer_code+c.ship_to_code > @c_row_id;

			SELECT @cust = customer_code, @ship_To = ship_to_code FROM #c WHERE @c_row_id = customer_code+ship_to_code;


            END;

    END;
 -- CUSTOMER LOOP



/*
-- now go back and get the failure reasons
	
SELECT  @row_id = MIN(cust_code + ship_to + promo_id + promo_level)
FROM    #r
WHERE   reason = 'Failed';

WHILE @row_id IS NOT NULL
    BEGIN
        SELECT  @cust = cust_code ,
                @ship_To = ship_to ,
                @promo = promo_id ,
                @level = promo_level ,
                @review = review
        FROM    #r
        WHERE   @row_id = cust_code + ship_to + promo_id + promo_level;

		-- SELECT @cust, @ship_To, @promo, @level;

        IF @review = 1
            INSERT  #f
                    ( code ,
                      reason
                    )
                    EXECUTE @ret_code = CVO_verify_customer_shipto_quali_sp @promo,
                        @level, @cust, @ship_To, 0, 0, 0;
        ELSE
            INSERT  #f
                    ( code ,
                      reason
                    )
                    EXECUTE @ret_code = CVO_verify_customer_quali_sp @promo,
                        @level, @cust, @ship_To, 0, 0, 0;
		
		-- SELECT * FROM #f;

        UPDATE  #r
        SET     #r.reason = ( SELECT TOP 1
                                        reason
                              FROM      #f
                            )
        WHERE   @row_id = cust_code + ship_to + promo_id + promo_level;

        TRUNCATE TABLE #f;

        SELECT  @row_id = MIN(cust_code + ship_to + promo_id + promo_level)
        FROM    #r
        WHERE   reason = 'Failed'
                AND ( cust_code + ship_to + promo_id + promo_level ) > @row_id;

    END;
*/

--IF ( OBJECT_ID('dbo.cvo_promo_eligibility_list_tbl') IS NULL ) 
--begin
--	CREATE TABLE dbo.cvo_promo_eligibility_list_tbl
--		( cust_code VARCHAR(10),
--			num_promos INT,
--			promo_list VARCHAR(1024)
--		);
--	CREATE INDEX idx_promo_elig_cust ON dbo.cvo_promo_eligibility_list_tbl (cust_code);
--END

--TRUNCATE TABLE dbo.cvo_promo_eligibility_list_tbl;

--INSERT INTO dbo.cvo_promo_eligibility_list_tbl
--(
--    cust_code,
--    num_promos,
--    promo_list
--)

SELECT  @promolist = 
        --r.cust_code ,
        --COUNT(DISTINCT r.promo_id+r.promo_level) num_promos ,
        ISNULL(REPLACE(STUFF(( SELECT DISTINCT
                        ':' + rr.promo_id + ',' + rr.promo_level
                FROM    #r rr
                WHERE   rr.cust_code = r.cust_code
                        AND reason = 'OK'
              FOR
                XML PATH('')
              ), 1, 1, ''),'&amp;','&'),'') 
FROM    #r AS r
WHERE   reason = 'OK'
GROUP BY r.cust_code;

-- SELECT @promolist



GO
GRANT EXECUTE ON  [dbo].[cvo_promo_eligibility_list_sp] TO [public]
GO
