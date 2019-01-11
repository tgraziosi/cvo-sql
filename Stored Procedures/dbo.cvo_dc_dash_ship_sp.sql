SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_ship_sp]
AS 
BEGIN

    DECLARE @asofdate DATETIME
    SELECT @asofdate = DATEADD(dd, DATEDIFF(dd,0,GETDATE()),0)

SELECT REPLACE(wms.UserID, 'cvoptical\', '') who_processed,
    
     wms.module,
     wms.trans,
    ISNULL(cu.fname + ' ' + cu.lname, REPLACE(wms.UserID, 'cvoptical\', '')) Username,
     COUNT(tran_date) num_trans,
     DATEADD(dd, DATEDIFF(dd, 0, wms.tran_date), 0) tran_date

FROM tdc_log (NOLOCK) wms
LEFT OUTER JOIN dbo.cvo_cmi_users AS cu
            ON cu.user_login = REPLACE(wms.UserID, 'cvoptical\', '')
WHERE tran_date > @asofdate
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
