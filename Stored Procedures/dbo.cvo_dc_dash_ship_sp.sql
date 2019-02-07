SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_ship_sp] @sdate DATETIME = NULL, @edate DATETIME = null
AS 
BEGIN

-- cvo_dc_dash_ship_sp '1/18/2019', '1/22/2019'

    -- DECLARE @asofdate DATETIME
    IF @sdate IS null
    SELECT @sdate = DATEADD(dd, DATEDIFF(dd,0,GETDATE()),0)
    
    IF @edate IS NULL 
    SELECT @edate = DATEADD(dd, 1, @sdate)
    ELSE
    SELECT @edate = DATEADD(ms, -3, DATEADD(dd,1, @edate))

SELECT REPLACE(wms.UserID, 'cvoptical\', '') who_processed,
    
     wms.module,
     wms.trans,
    ISNULL(cu.fname + ' ' + cu.lname, REPLACE(wms.UserID, 'cvoptical\', '')) Username,
     COUNT(tran_date) num_trans,
     DATEADD(dd, DATEDIFF(dd, 0, wms.tran_date), 0) tran_date

FROM tdc_log (NOLOCK) wms
LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
            ON cu.user_login = REPLACE(wms.UserID, 'cvoptical\', '')
WHERE tran_date BETWEEN @sdate AND @edate
AND trans IN ('Close Carton','DataArrival')
GROUP BY REPLACE(wms.UserID, 'cvoptical\', ''),
         ISNULL(cu.fname + ' ' + cu.lname, REPLACE(wms.UserID, 'cvoptical\', '')),
         DATEADD(dd, DATEDIFF(dd, 0, wms.tran_date), 0),
         wms.module,
         wms.trans         

END



GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_ship_sp] TO [public]
GO
