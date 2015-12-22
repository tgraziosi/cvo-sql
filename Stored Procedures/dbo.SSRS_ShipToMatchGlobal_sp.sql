SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		elabarbera
-- Create date: 1/24/2013
-- Description:	Find ShipTo's that match Global Lab Addresses
-- EXEC SSRS_ShipToMatchGlobal_sp
-- =============================================
CREATE PROCEDURE [dbo].[SSRS_ShipToMatchGlobal_sp]
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
-- FIND SHIP TOS THAT MATCH GLOBAL LABS
        IF ( OBJECT_ID('tempdb.dbo.#GlobalList') IS NOT NULL )
            DROP TABLE #GlobalList;
        SELECT  customer_code ,
                addr1 ,
                addr2 ,
                addr3 ,
                addr4 ,
                city ,
                state ,
                postal_code ,
                status_type
        INTO    #GlobalList
        FROM    armaster
        WHERE   address_type = 9
                AND status_type = 1;
-- select * from #GlobalList

        SELECT  T1.address_name ,
                T1.customer_code ,
                T1.ship_to_code ,
                T1.addr1 ,
                T1.addr2 ,
                T1.addr3 ,
                T1.addr4 ,
                T1.city ,
                T1.state ,
                T1.postal_code ,
                T1.added_by_date ,
                T3.user_name ,
                T1.addr_sort1 ,
                ( SELECT TOP 1
                            order_no
                  FROM      orders_all t12 ( NOLOCK )
                  WHERE     T1.customer_code = t12.cust_code
                            AND T1.ship_to_code = t12.ship_to
                            AND status NOT IN ( 'v' )
                  ORDER BY  date_entered DESC
                ) LastOrdNo ,
                T2.customer_code AS GlobalCode ,
                T2.addr1 AS GlobalAddr1 ,
                T2.status_type AS GlobalStatus ,
                T2.city AS GlobalCity
        FROM    armaster T1
                JOIN #GlobalList T2 ON T1.addr2 = T2.addr2
                LEFT OUTER JOIN dbo.smusers_vw T3 ON T1.modified_by_user_name = T3.user_name
        WHERE   T1.address_type = 1
                AND T1.status_type = 1
                AND T1.customer_code NOT IN ( '' );

    END;



GO
