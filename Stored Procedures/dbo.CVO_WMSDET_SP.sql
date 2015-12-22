SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		elabarbera
-- Create date: 4/22/2013
-- Description:	WMS Transaction Detail
-- EXEC CVO_WMSDET_SP '4/19/2013','4/19/2013'
-- =============================================
CREATE PROCEDURE [dbo].[CVO_WMSDET_SP]
	-- Add the parameters for the stored procedure here
@DateFrom datetime,@DateTo Datetime
AS
BEGIN
	SET NOCOUNT ON;
SET @DateTo=dateadd(second,-1,@dateTo)
SET @DateTo=dateadd(day,1,@dateTo)

SELECT * FROM (
select ISNULL(tran_date,'')tran_date, 
ISNULL(case when left(userid,10)='CVOPTICAL\' THEN substring(userid,11,15) ELSE USERID END,'') userid,
ISNULL(trans,'')trans,
 ISNULL(part_no,'')part_no,
  ISNULL(qty,'')qty,
   ISNULL(location,'')location,
    ISNULL(bin_group,'')bin_group,
     ISNULL(bin_no,'')bin_no,
      ISNULL(to_location,'')to_location,
       ISNULL(to_bin_group,'')to_bin_group,
        ISNULL(to_bin_no ,'')to_bin_no
from tdc_3pl_bin_activity_log where trans in ('quaran', 'bn2bn', 'wh2wh', 'putaway', 'Qbn2bn')  and tran_date between @DateFrom and @DateTo
	UNION ALL
select ISNULL(tran_date,'')tran_date,
ISNULL(case when left(userid,10)='CVOPTICAL\' THEN substring(userid,11,15) ELSE USERID END,'') userid, 
ISNULL(SUBSTRING(t1.data, charindex('LP_REASON_CODE:', t1.data)+16,((charindex('LP_BASE_UOM:', t1.data))-(charindex('LP_REASON_CODE:', t1.data)+16)-2)),'ADHOC')InvAdjCode,
 ISNULL(part_no,'')part_no,
  ISNULL(quantity,'')quantity,
  ' ' location,
   ' ' bin_group,
    ' ' bin_no,
     ISNULL(location,'')location,
      ' ' to_bin_group,
        ISNULL(bin_no,'')bin_no
from tdc_log t1
where module='adh' and trans='adhoc' and tran_date between @DateFrom and @DateTo
 ) TMP --ORDER BY TRANS, PART_NO		
END
GO
