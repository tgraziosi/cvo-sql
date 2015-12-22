SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[cvo_tdcdet_vw]
AS

SELECT * FROM (
select ISNULL(tran_date,' ')tran_date, 
ISNULL(case when left(userid,10)='CVOPTICAL\' THEN substring(userid,11,15) ELSE USERID END,' ') userid,
'' module,
ISNULL(trans,' ')trans,
'' InvAdjCode,
 ISNULL(part_no,' ')part_no,
  ISNULL(qty,0)qty,
   ISNULL(location,' ')location,
    ISNULL(bin_group,' ')bin_group,
     ISNULL(bin_no,' ')bin_no,
      ISNULL(to_location,' ')to_location,
       ISNULL(to_bin_group,' ')to_bin_group,
        ISNULL(to_bin_no ,' ')to_bin_no
from tdc_3pl_bin_activity_log (nolock) where trans in ('quaran', 'bn2bn', 'wh2wh', 'putaway', 'Qbn2bn') 
--and tran_date between '4/17/2013' and '4/17/2013 23:59:59'
	UNION ALL
select ISNULL(tran_date,' ')tran_date,
ISNULL(case when left(userid,10)='CVOPTICAL\' THEN substring(userid,11,15) ELSE USERID END,' ') userid, 
Module,
Trans,
CASE WHEN module='adh' and trans='adhoc' and ((charindex('LP_BASE_UOM:', data))-(charindex('LP_REASON_CODE:', data)+16)-2)<>0 
	THEN CONVERT(VARCHAR,SUBSTRING(data, charindex('LP_REASON_CODE:',data)+16,((charindex('LP_BASE_UOM:',data))-(charindex('LP_REASON_CODE:',data)+16)-2)) )
	ELSE TRANS  END as InvAdjCode,

 ISNULL(part_no,' ')part_no,
  ISNULL(quantity,0)quantity,
  ' ' location,
   ' ' bin_group,
    ' ' bin_no,
     ISNULL(location,' ')location,
      ' ' to_bin_group,
        ISNULL(bin_no,' ')bin_no
from tdc_log t1 (nolock) 
where trans not in ('quaran', 'bn2bn', 'wh2wh', 'putaway', 'Qbn2bn') 
--and tran_date between '4/17/2013' and '4/17/2013 23:59:59'
) TMP --ORDER BY TRANS, PART_NO		




GO
GRANT REFERENCES ON  [dbo].[cvo_tdcdet_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_tdcdet_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_tdcdet_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_tdcdet_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_tdcdet_vw] TO [public]
GO
