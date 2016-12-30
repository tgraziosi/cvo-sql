SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_ME_SellDown_sp] (@startdate DATETIME = NULL , @enddate DATETIME = null, @Terr VARCHAR(1024) = null)
AS

-- exec cvo_me_selldown_sp '1/1/2016','11/30/2016','20201'

DECLARE @sdate DATETIME , @edate DATETIME;

SELECT @sdate = @startdate, @edate = @enddate


SELECT  @sdate = ISNULL(@sdate,BeginDate) ,
        @edate = ISNULL(@edate,EndDate)
FROM    dbo.cvo_date_range_vw AS drv
WHERE   Period = 'year to date'; -- default dating if none specified in parameters


DECLARE @territory VARCHAR(1024);
SELECT  @territory = @terr;

IF ( OBJECT_ID('tempdb.dbo.#terr') IS NOT NULL )
    DROP TABLE #terr; 

CREATE TABLE #terr
    (
      terr VARCHAR(8) ,
      region VARCHAR(3)
    );

IF ( @territory IS NULL )
    BEGIN
        INSERT  INTO #terr
                ( terr ,
                  region
                )
                SELECT DISTINCT
                        territory_code ,
                        dbo.calculate_region_fn(territory_code)
                FROM    dbo.armaster
                WHERE   1 = 1;
    END;
ELSE
    BEGIN
        INSERT  INTO #terr
                ( terr ,
                  region
                )
                SELECT  ListItem ,
                        dbo.calculate_region_fn(ListItem)
                FROM    dbo.f_comma_list_to_table(@territory);
    END;


SELECT  t.region ,
        t.terr ,
        ar.customer_code ,
        -- ar.ship_to_code ,
		ar.customer_name,
        me_sales.me_net_sales ,
        sv_sales.promo_id ,
        sv_sales.sv_net_sales
FROM    #terr AS t
        JOIN dbo.arcust AS ar ON ar.territory_code = t.terr
        LEFT OUTER JOIN ( SELECT   sd.customer ,
                        SUM(anet) me_net_sales
               FROM     dbo.cvo_sbm_details AS sd
                        JOIN inv_master i ON i.part_no = sd.part_no
               WHERE    yyyymmdd BETWEEN @sdate AND @edate
                        AND i.category = 'ME'
               GROUP BY sd.customer
             ) me_sales ON me_sales.customer = ar.customer_code
                           
        LEFT OUTER JOIN ( SELECT    sd2.customer ,
                                    sd2.promo_id ,
                                    SUM(anet) sv_net_sales
                          FROM      dbo.cvo_sbm_details AS sd2
                          WHERE     yyyymmdd BETWEEN @sdate AND @edate
                                    AND sd2.promo_id IN ( 'ch', 'cl', 'eor',
                                                          'eos', 'qop', 'sv',
                                                          'sw' )
                          GROUP BY  sd2.customer ,
                                    sd2.promo_id
                        ) sv_sales ON sv_sales.customer = ar.customer_code
WHERE ISNULL(me_sales.me_net_sales,0) <> 0 OR ISNULL(sv_sales.sv_net_sales,0) <> 0                                      
ORDER BY ar.customer_code
;

--SELECT sd2.customer, sd2.ship_to, CASE WHEN sd2.promo_id = '' THEN 'NONE' ELSE sd2.promo_id END promo_id, SUM(anet)
--FROM dbo.cvo_sbm_details AS sd2
--WHERE yyyymmdd BETWEEN @sdate AND @edate
---- AND sd2.promo_id IN ('ch','cl','eor','eos','qop','sv','sw')
--AND iscl = 1
--GROUP BY sd2.customer ,
--         sd2.ship_to ,
--         sd2.promo_id

GO
GRANT EXECUTE ON  [dbo].[cvo_ME_SellDown_sp] TO [public]
GO
