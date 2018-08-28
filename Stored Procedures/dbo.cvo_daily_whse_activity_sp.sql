SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_daily_whse_activity_sp]
    @sdate DATETIME, @edate DATETIME
AS

-- EXEC cvo_daily_whse_activity_sp '08/24/2018', '08/26/2018'

SET NOCOUNT ON
;
SET ANSI_WARNINGS OFF
;

SELECT @edate = DATEADD(ms,-1,DATEADD(DAY,1,@edate))


SELECT
    REPLACE(wms.UserID, 'cvoptical\', '') who_processed,
    trans,
    COUNT(wms.tran_no) num_activity,
    COUNT(DISTINCT wms.part_no) total_skus
FROM tdc_log wms (NOLOCK)
WHERE
    wms.tran_date
    BETWEEN @sdate AND @edate
    -- AND trans IN ( 'qcrelease', 'poptwy' )
GROUP BY
    REPLACE(wms.UserID, 'cvoptical\', ''), wms.trans




;






GO
GRANT EXECUTE ON  [dbo].[cvo_daily_whse_activity_sp] TO [public]
GO
