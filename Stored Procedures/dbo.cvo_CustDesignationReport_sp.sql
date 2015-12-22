SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		elabarbera
-- Create date: 6/13/2013
-- Description:	CustomerDesignationreport
-- EXEC cvo_CustDesignationReport_sp
-- =============================================
CREATE PROCEDURE [dbo].[cvo_CustDesignationReport_sp] 

AS
BEGIN
	SET NOCOUNT ON;

IF(OBJECT_ID('tempdb.dbo.#Desigs') is not null)
drop table dbo.#Desigs
      ;WITH C AS 
            ( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
            select Distinct customer_code,
                              STUFF ( ( SELECT '; ' + code
                              FROM cvo_cust_designation_codes (nolock)
                              WHERE customer_code = C.customer_code
                              AND (END_DATE IS NULL or END_DATE >=getdate())
                              FOR XML PATH ('') ), 1, 1, ''  ) AS NEW
      INTO #Desigs
      FROM C  -- select * from #Desigs
      
      
SELECT     TOP (100) PERCENT T2.territory_code, t1.customer_code, t2.address_name, t2.addr2, CASE WHEN t2.addr3 LIKE '%, __ %' THEN '' ELSE T2.ADDR3 END AS	addr3, City, State, Postal_Code as Zip, country_code as CC, t2.price_code as DisCode, t1.code, t3.description, t3.rebate, case when primary_flag = 1 THEN 'Y' ELSE '' END AS Pri, t1.start_date, t1.end_date, t4.new as OtherActive
FROM         dbo.cvo_cust_designation_codes AS t1 INNER JOIN
                      dbo.armaster AS t2 ON t1.customer_code = t2.customer_code INNER JOIN
                      dbo.cvo_designation_codes AS t3 ON t1.code = t3.code
                      join #desigs as t4 on t1.customer_code=t4.customer_code
WHERE     (t2.address_type = '0')
--and t3.rebate='y'
ORDER BY t1.code, t1.customer_code

END




GO
