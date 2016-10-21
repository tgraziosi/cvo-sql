SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 2/20/2013
-- Description:	Handshake ShipTo Customer Data
-- 071213 - tag - create table instead of temp table
-- 10/18/2016 - don't rebuild.  use insert/update logic
-- EXEC HS_ShipTo_tbl_sp
-- select *  From hs_shipto_tbl where added_by_date > '10/18/2016'
-- =============================================
CREATE PROCEDURE [dbo].[HS_ShipTo_tbl_sp]
AS
    BEGIN

        SET NOCOUNT ON;

---- PULL LIST FOR SHIP_TO  (Ship_to's)
--        IF ( OBJECT_ID('dbo.HS_Shipto_tbl') IS NOT NULL )
---- drop table HS_Shipto_tbl
--            TRUNCATE TABLE HS_Shipto_tbl;

        IF ( OBJECT_ID('dbo.#hs') IS NOT NULL )
            DROP TABLE #hs;

	    
        SELECT  customer_code AS cust_id ,
                ( SELECT    addr1
                  FROM      armaster T2
                  WHERE     T1.customer_code = T2.customer_code
                            AND ship_to_code = ''
                ) AS cust_name ,
                ship_to_code AS ship_id ,
                addr2 AS ship_street ,
                CASE WHEN addr3 LIKE '%, __ %' THEN ''
                     ELSE addr3
                END AS ship_street2 ,
                city AS ship_city ,
                state AS ship_state ,
                postal_code AS ship_postcode ,
                country_code AS ship_country ,
                contact_phone AS ship_phone ,
                tlx_twx AS ship_fax ,
                addr1 AS ship_name ,
                '0' AS is_default 
        INTO    #hs
        FROM    armaster T1
        WHERE   territory_code NOT LIKE ( '908%' )
                AND territory_code NOT LIKE ( '909%' )
                AND territory_code NOT LIKE ( '8%' )
                AND status_type = 1
                AND address_type = 1
                AND addr1 NOT LIKE '%do not%';

-- PULL LIST FOR SHIP_TO  (Customer's)
        INSERT  INTO #hs
                SELECT  customer_code AS cust_id ,
                        addr1 AS cust_name ,
                        '' AS ship_id , 
--'D' as ship_id, 
                        addr2 AS ship_street ,
                        CASE WHEN addr3 LIKE '%, __ %' THEN ''
                             ELSE addr3
                        END AS ship_street2 ,
                        city AS ship_city ,
                        state AS ship_state ,
                        postal_code AS ship_postcode ,
                        country_code AS ship_country ,
                        contact_phone AS ship_phone ,
                        tlx_twx AS ship_fax ,
                        addr1 AS ship_name ,
                        '1' AS is_default 
                FROM    armaster T1
                WHERE   territory_code NOT LIKE ( '908%' )
                        AND territory_code NOT LIKE ( '909%' )
                        AND territory_code NOT LIKE ( '8%' )
                        AND status_type = 1
                        AND address_type = 0
                        AND addr1 NOT LIKE '%do not%'
                        AND ( ISNULL(valid_shipto_flag, 0) = 1 );


        UPDATE  hst
        SET     hst.cust_name = h.cust_name ,
                hst.ship_street = h.ship_street ,
                hst.ship_street2 = h.ship_street2 ,
                hst.ship_city = h.ship_city ,
                hst.ship_state = h.ship_state ,
                hst.ship_postcode = h.ship_postcode ,
                hst.ship_country = h.ship_country ,
                hst.ship_phone = h.ship_phone ,
                hst.ship_fax = h.ship_fax ,
                hst.ship_name = h.ship_name ,
                hst.is_default = h.is_default ,
                hst.modified_by_date = GETDATE()
        FROM    #hs AS h
                JOIN dbo.HS_Shipto_tbl AS hst ON hst.cust_id = h.cust_id
                                                 AND hst.ship_id = h.ship_id
        WHERE   hst.cust_name <> h.cust_name
                OR hst.ship_street <> h.ship_street
                OR hst.ship_street2 <> h.ship_street2
                OR hst.ship_city <> h.ship_city
                OR hst.ship_state <> h.ship_state
                OR hst.ship_postcode <> h.ship_postcode
                OR hst.ship_country <> h.ship_country
                OR hst.ship_phone <> h.ship_phone
                OR hst.ship_fax <> h.ship_fax
                OR hst.ship_name <> h.ship_name
                OR hst.is_default <> h.is_default;

        INSERT  INTO dbo.HS_Shipto_tbl
                ( cust_id ,
                  cust_name ,
                  ship_id ,
                  ship_street ,
                  ship_street2 ,
                  ship_city ,
                  ship_state ,
                  ship_postcode ,
                  ship_country ,
                  ship_phone ,
                  ship_fax ,
                  ship_name ,
                  is_default ,
                  added_by_date ,
                  modified_by_date
				 )
                SELECT  h.cust_id ,
                        h.cust_name ,
                        h.ship_id ,
                        h.ship_street ,
                        h.ship_street2 ,
                        h.ship_city ,
                        h.ship_state ,
                        h.ship_postcode ,
                        h.ship_country ,
                        h.ship_phone ,
                        h.ship_fax ,
                        h.ship_name ,
                        h.is_default ,
                        GETDATE() added_by_date ,
                        NULL modified_by_date
                FROM    #hs AS h
                WHERE   NOT EXISTS ( SELECT 1
                                     FROM   dbo.HS_Shipto_tbl AS hst
                                     WHERE  hst.cust_id = h.cust_id
                                            AND hst.ship_id = h.ship_id );
    END;


GO
GRANT EXECUTE ON  [dbo].[HS_ShipTo_tbl_sp] TO [public]
GO
