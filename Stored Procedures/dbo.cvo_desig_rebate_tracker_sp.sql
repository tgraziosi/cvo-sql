SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_desig_rebate_tracker_sp]
    @sdate DATETIME ,
    @edate DATETIME ,
    @terr VARCHAR(1024) = NULL ,
    @single_email INT = 0
AS
    BEGIN

        SET NOCOUNT ON;
        SET ANSI_WARNINGS OFF;

        -- exec cvo_desig_rebate_tracker_sp '1/1/2018', '12/31/2018', null, 0


        -- DECLARE @sdate DATETIME, @edate DATETIME, @terr VARCHAR(1024), @single_email int

        DECLARE @progyear INT ,
                @today DATETIME ,
                @lastcust VARCHAR(12) ,
                @emails VARCHAR(1024) ,
                @debug INT;

				SELECT @debug = 0;
        -- SELECT @debug = 1, @single_email = 0;

        SELECT @today = GETDATE();
        IF @sdate IS NULL
           OR @edate IS NULL
            SELECT @sdate = BeginDate ,
                   @edate = EndDate
            FROM   dbo.cvo_date_range_vw AS cdrv
            WHERE  Period = 'year to date';

        SELECT @progyear = YEAR(@edate);

        DECLARE @territory VARCHAR(1024);
        SELECT @territory = @terr;

        IF ( OBJECT_ID('tempdb.dbo.#terr') IS NOT NULL )
            DROP TABLE #terr;

        CREATE TABLE #terr
            (
                terr VARCHAR(8) ,
                region VARCHAR(3)
            );

        IF ( @territory IS NULL )
            BEGIN
                INSERT INTO #terr ( terr ,
                                    region )
                            SELECT DISTINCT territory_code ,
                                   dbo.calculate_region_fn(territory_code)
                            FROM   dbo.armaster
                            WHERE  1 = 1;
            END;
        ELSE
            BEGIN 
                INSERT INTO #terr ( terr ,
                                    region )
                            SELECT ListItem ,
                                   dbo.calculate_region_fn(ListItem)
                            FROM   dbo.f_comma_list_to_table(@territory);
            END;

        -- merge cust list

        --SELECT merge_cust
        --FROM 
        --(SELECT DISTINCT ar.customer_code, RIGHT(ar.customer_code,5) merge_cust
        --FROM armaster ar 
        --) AS xx
        --GROUP BY xx.merge_cust
        --HAVING COUNT(xx.customer_code) > 1   

        IF ( OBJECT_ID('tempdb.dbo.#email') IS NOT NULL )
            DROP TABLE #email;
        IF ( OBJECT_ID('tempdb.dbo.#single_email') IS NOT NULL )
            DROP TABLE #single_email;


        SELECT DISTINCT email.mergecust ,
               CAST(email.contact_email AS VARCHAR(255)) contact_email ,
               0 email_id
        INTO   #email
        FROM   (   SELECT DISTINCT RIGHT(customer_code, 5) mergecust ,
                          contact_email
                   FROM   armaster
                   WHERE  contact_email IS NOT NULL
                          AND CHARINDEX('@', contact_email) > 0
                   UNION
                   SELECT DISTINCT RIGHT(customer_code, 5) mergecust ,
                          contact_email
                   FROM   adm_arcontacts
                   WHERE  contact_email IS NOT NULL
                          AND CHARINDEX('@', contact_email) > 0
                          AND contact_code = 'Dr.' ) email;

        -- parse out multiple emails
        SELECT DISTINCT mergecust ,
               REPLACE(contact_email, ';', ',') contact_email ,
               0 AS email_id
        INTO   #single_email
        FROM   #email
        WHERE  CHARINDEX(',', REPLACE(contact_email, ';', ','), 1) > 0;

        DELETE FROM #email
        WHERE CHARINDEX(',', REPLACE(contact_email, ';', ','), 1) > 0;

        SELECT @lastcust = MIN(mergecust)
        FROM   #single_email AS se;

        WHILE @lastcust IS NOT NULL
            BEGIN

                SELECT @emails = contact_email
                FROM   #single_email AS se
                WHERE  se.mergecust = @lastcust;

                INSERT #email ( mergecust ,
                                contact_email ,
                                email_id )
                       SELECT @lastcust ,
                              ListItem ,
                              0
                       FROM   dbo.f_comma_list_to_table(@emails);

                SELECT @lastcust = MIN(mergecust)
                FROM   #single_email AS se
                WHERE  mergecust > @lastcust;

            END;

        UPDATE ee
        SET    ee.email_id = e_id.email_id
        FROM   #email ee
               JOIN (   SELECT e.mergecust ,
                               e.contact_email ,
                               -- DENSE_RANK() OVER ( PARTITION BY e.contact_email
							   ROW_NUMBER() OVER ( PARTITION BY e.contact_email
                                                   ORDER BY contact_email ASC ) email_id
                        FROM   #email AS e ) e_id ON e_id.contact_email = ee.contact_email
                                                     AND e_id.mergecust = ee.mergecust;

        IF @debug = 1
            SELECT *
            FROM   #email AS e;

        -- end

        SELECT cdr.progyear ,
               cdr.interval ,
               cdr.code ,
               facts.description ,
               cdr.goal1 ,
               cdr.rebatepct1 ,
               cdr.goal2 ,
               cdr.rebatepct2 ,
               cdr.RRLess ,
               ISNULL(ar.past_due,0) past_due ,
               cust.mergecust ,
               t.region ,
               t.terr territory_code ,
               cust.address_name ,
               contact_email = cust.contact_email ,
               dr_email = emails.contact_emails ,
               email = emails.email_each ,
               email_id ,
               facts.grosssales ,
               facts.netsales ,
               facts.rareturns ,
               facts.start_date ,
               facts.desig_grosssales ,
               facts.desig_netsales ,
               facts.desig_rareturns ,
               desig_RAretpct = CASE WHEN facts.desig_grosssales = 0 THEN 0
                                     ELSE
                                         facts.desig_rareturns
                                         / facts.desig_grosssales
                                END ,
               RAretpct = CASE WHEN facts.grosssales = 0 THEN 0
                               ELSE facts.rareturns / facts.grosssales
                          END ,
               NeedForGoal1 = cdr.goal1 - facts.desig_netsales ,
               NeedForGoal1RA = ( CASE WHEN cdr.RRLess = 0 THEN 0
                                       ELSE
               ( facts.desig_rareturns / cdr.RRLess )
               - facts.desig_grosssales
                                  END ) ,
               NeedForGoal2 = CASE WHEN ISNULL(cdr.goal2, 0) = 0 THEN 0
                                   ELSE cdr.goal2 - facts.desig_netsales
                              END ,
               NeedForGoal2RA = CASE WHEN ISNULL(cdr.goal2, 0) = 0 THEN 0
                                     ELSE
               ( CASE WHEN cdr.RRLess = 0 THEN 0
                      ELSE
               ( facts.desig_rareturns / cdr.RRLess )
               - facts.desig_grosssales
                 END )
                                END ,
               RebatePotential = CASE WHEN facts.desig_netsales < cdr.goal1 THEN
                                          cdr.goal1
                                      ELSE facts.desig_netsales
                                 END * ISNULL(cdr.rebatepct1, 0)
                                 + CASE WHEN cdr.goal2 IS NULL THEN 0
                                        ELSE
                                            CASE WHEN facts.desig_netsales < cdr.goal2 THEN
                                                     cdr.goal2
                                                 ELSE facts.desig_netsales
                                            END * ISNULL(cdr.rebatepct2, 0)
                                   END

        FROM   dbo.cvo_designation_rebates AS cdr
               LEFT OUTER JOIN (   SELECT   RIGHT(ccdc.customer_code, 5) mergecust ,
                                            ccdc.code ,
                                            ccdc.description ,
                                            MIN(ccdc.start_date) start_date ,
                                            -- 11/21/2016 - exclude exc returns from gross sales
                                            SUM(ISNULL(sbm.asales, 0))
                                            - SUM(ISNULL(
                                                      ( CASE WHEN return_code = 'exc' THEN
                                                                 sbm.areturns
                                                             ELSE 0
                                                        END ) ,
                                                      0)) grosssales ,
                                            SUM(ISNULL(sbm.anet, 0)) netsales ,
                                            SUM(CASE WHEN ISNULL(
                                                              sbm.return_code, '') = '' THEN
                                                         ISNULL(sbm.areturns, 0)
                                                     ELSE 0
                                                END) rareturns ,
                                            SUM(CASE WHEN ISNULL(yyyymmdd, @edate) >= ISNULL(
                                                                                          ccdc.start_date ,
                                                                                          ISNULL(
                                                                                              yyyymmdd ,
                                                                                              @edate)) THEN
                                                         ISNULL(asales, 0)
                                                     ELSE 0
                                                END)
                                            -- 11/21/2016 - exclude exc returns from gross sales 
                                            - SUM(CASE WHEN ISNULL(
                                                                yyyymmdd ,@edate) >= ISNULL(
                                                                                         ccdc.start_date ,
                                                                                         ISNULL(
                                                                                             yyyymmdd ,
                                                                                             @edate))
                                                            AND sbm.return_code = 'exc' THEN
                                                           ISNULL(areturns, 0)
                                                       ELSE 0
                                                  END) desig_grosssales ,
                                            SUM(CASE WHEN ISNULL(yyyymmdd, @edate) >= ISNULL(
                                                                                          ccdc.start_date ,
                                                                                          ISNULL(
                                                                                              yyyymmdd ,
                                                                                              @edate)) THEN
                                                         ISNULL(anet, 0)
                                                     ELSE 0
                                                END) desig_netsales ,
                                            SUM(CASE WHEN ISNULL(yyyymmdd, @edate) >= ISNULL(
                                                                                          ccdc.start_date ,
                                                                                          ISNULL(
                                                                                              yyyymmdd ,
                                                                                              @edate))
                                                          AND ISNULL(
                                                                  sbm.return_code ,
                                                                  '') = '' THEN
                                                         ISNULL(sbm.areturns, 0)
                                                     ELSE 0
                                                END) desig_rareturns
                                   FROM     (   SELECT DISTINCT cdc.code desig_code ,
                                                       cdc.description
                                                FROM   dbo.cvo_designation_codes AS cdc
                                                WHERE  cdc.rebate = 'Y' ) dr
                                            JOIN dbo.cvo_cust_designation_codes AS ccdc ON ccdc.code = dr.desig_code
                                            LEFT OUTER JOIN cvo_sbm_details sbm ON sbm.customer = ccdc.customer_code
                                                                                   AND sbm.yyyymmdd
                                                                                   BETWEEN @sdate AND @edate

                                   WHERE    1 = 1
                                            AND ccdc.primary_flag = 1
                                            AND ISNULL(ccdc.end_date, @edate) >= @edate
                                   -- AND ISNULL(sbm.yyyymmdd,@edate) BETWEEN @sdate AND @edate

                                   GROUP BY RIGHT(ccdc.customer_code, 5) ,
                                            ccdc.code ,
                                            ccdc.description 
                                            -- ccdc.start_date 
											) AS facts ON cdr.code = ISNULL(
                                                                                         facts.code ,
                                                                                         cdr.code)
                                                                          AND cdr.progyear = @progyear

               JOIN (   SELECT   RIGHT(customer_code, 5) mergecust ,
                                 MIN(customer_name) address_name ,
                                 MAX(contact_email) contact_email ,
                                 territory_code
                        FROM     arcust
                        -- 10/16/2018 - active customers only
                        WHERE status_type = 1
                        --
                        GROUP BY RIGHT(customer_code, 5) ,
                                 territory_code ) AS cust ON cust.mergecust = facts.mergecust

               JOIN #terr t ON t.terr = cust.territory_code

               LEFT OUTER JOIN

               (   SELECT   RIGHT(CUST_CODE, 5) mergecust ,
                            past_due = SUM(AR30 + AR60 + AR90 + AR120 + AR150)
                   FROM     dbo.SSRS_ARAging_Temp
                   GROUP BY RIGHT(CUST_CODE, 5)) AS ar ON ar.mergecust = cust.mergecust

               LEFT OUTER JOIN

               (   SELECT DISTINCT e.mergecust ,
                          STUFF((   SELECT DISTINCT ';' + ee.contact_email
                                    FROM   #email AS ee
                                    WHERE  ee.mergecust = e.mergecust
                                    FOR XML PATH('')) ,
                                1 ,
                                1 ,
                                '') contact_emails ,
                          email_each = CASE WHEN @single_email = 1 THEN
                                                e.contact_email
                                            ELSE ''
                                       END ,
                          email_id = CASE WHEN @single_email = 1 THEN
                                              e.email_id
                                          ELSE 0
                                     END
                   FROM   #email e ) emails ON emails.mergecust = cust.mergecust

        WHERE  cdr.progyear = @progyear
               AND t.region IS NOT NULL;

    -- SELECT * FROM dbo.cvo_designation_codes AS ccdc

    END;
















GO
GRANT EXECUTE ON  [dbo].[cvo_desig_rebate_tracker_sp] TO [public]
GO
