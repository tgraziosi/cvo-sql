SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tine Graziosi	
-- Create date: 06/28/2012
-- Description:	CVO CIR for SSRS
-- exec cvo_cir_ssrs_sp '40450'
-- =============================================
CREATE PROCEDURE [dbo].[CVO_CIR_SSRS_SP]
    @territory VARCHAR(1024) = NULL
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

        DECLARE @terr VARCHAR(1024);
        SELECT  @terr = @territory;

        IF ( OBJECT_ID('tempdb.dbo.#territory') IS NOT NULL )
            DROP TABLE #territory;
        CREATE TABLE #territory
            (
              territory VARCHAR(10)
            );

        IF @terr IS NULL
            BEGIN
                INSERT  #territory
                        SELECT DISTINCT
                                territory_code
                        FROM    armaster
                        WHERE   territory_code IS NOT NULL
                        ORDER BY territory_code;
            END;
        ELSE
            BEGIN
                INSERT  INTO #territory
                        ( territory
                        )
                        SELECT DISTINCT
                                ListItem
                        FROM    dbo.f_comma_list_to_table(@terr)
                        ORDER BY ListItem;
            END;


--	select @terr
        SELECT  as_of_date ,
                t.territory ,
                slp ,
                cust_code ,
                ship_to ,
                address_name ,
                addr2 ,
                addr3 ,
                addr4 ,
                city ,
                postal_code ,
                customer_short_name ,
                contact_phone ,
                date_opened ,
				convert(datetime, last_st_ord_date, 101) AS last_st_ord_date,
--              last_st_ord_date ,
                last_st_order_no ,
                discount ,
                buying ,
                cstatus ,
                custnetsales ,
                NetSalesLY ,
                YTDTY ,
                YTDLY ,
                TotAcctNetSales ,
                category ,
                style ,
                part_no2 ,
                pom_date ,
                First_order_date ,
                Last_order_date ,
                mst12 ,
                mst36 ,
                mrx12 ,
                mrx36 ,
                mret12 ,
                mret36 ,
                mnet12 ,
                mnet36 ,
                moth12 ,
                moth36
        FROM    #territory AS t
                JOIN cvo_carbi c ON c.territory = t.territory;
		   

    END;

GO
