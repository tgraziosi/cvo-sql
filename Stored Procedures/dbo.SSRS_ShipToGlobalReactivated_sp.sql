SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		elabarbera
-- Create date: 1/24/2013
-- Description:	Find Global/Ship_to's that were disabled that have been made Active again
-- =============================================
CREATE PROCEDURE [dbo].[SSRS_ShipToGlobalReactivated_sp] 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
-- FIND SHIP TOS THAT MATCH GLOBAL LABS
IF(OBJECT_ID('tempdb.dbo.#GlobalList') is not null)  
drop table #GlobalList
SELECT Customer_code, addr1, addr2, addr3, addr4, city, state, postal_code, status_type into #GlobalList from armaster where address_type=9 AND status_type =1

select T1.ADDRESS_NAME, T1.customer_code, T1.ship_to_code, T1.addr1, T1.addr2, T1.addr3, T1.addr4, T1.city, T1.state, T1.postal_code, T1.ADDR_SORT1,
(select top 1 order_no from orders_all t2 (nolock) where t1.customer_code=t2.cust_code and t1.ship_to_code=t2.ship_to and status not in ('v') order by date_entered desc) LastOrdNo
FROM ARMASTER T1 (nolock) 
where ADDR2 LIKE 'USE GLOBAL CODE%' AND STATUS_TYPE =1

END

GO
