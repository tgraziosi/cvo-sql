SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_NewReaEmailList_sp]
AS 

-- Author: Tine Graziosi
-- Created: 9/24/2015
-- usage: exec cvo_newreaemaillist_sp

SET NOCOUNT ON
SET ANSI_WARNINGS OFF

BEGIN

IF (OBJECT_ID('tempdb.dbo.#newrea') IS NOT NULL) DROP TABLE #newrea
CREATE TABLE #newrea
( region VARCHAR(3),
terr VARCHAR(5),
salesperson VARCHAR(50),
date_of_hire DATETIME,
classof VARCHAR(10),
status VARCHAR(20),
territory VARCHAR(8),
customer_code VARCHAR(8),
ship_to_code VARCHAR(8),
door CHAR(1),
added_by_date DATETIME,
firstst_new DATETIME NULL,
prevst_new DATETIME NULL,
statustype VARCHAR(10),
designations VARCHAR(50),
pridesig VARCHAR(10)
)
INSERT into #newrea
EXEC  CVO_NewReaIncentive3_SP -- default period is rolling 12 ending yesterday

SELECT ar.customer_code, ar.ship_to_code, ar.addr_sort1 cust_type, ar.address_name, ar.contact_name, ISNULL(ar.contact_email,'') contact_email, 
ar.territory_code, #newrea.door, #newrea.statustype
FROM #newrea
INNER JOIN armaster (NOLOCK) ar ON ar.customer_code = #newrea.customer_code AND ar.ship_to_code = #newrea.ship_to_code
WHERE ar.addr_sort1 <> 'Employee'

END

GO
GRANT EXECUTE ON  [dbo].[CVO_NewReaEmailList_sp] TO [public]
GO
