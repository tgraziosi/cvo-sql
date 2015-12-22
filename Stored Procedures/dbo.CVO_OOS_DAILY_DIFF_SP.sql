SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		ELIZABETH LABARBERA
-- Create date: 8/28/2013
-- Description:	CREATE OUT OF STOCK (OOS) REPORT FULL DETAIL AND DAY TO DAY DIFFERENCES
-- EXEC CVO_OOS_DAILY_DIFF_SP 
-- =============================================
CREATE PROCEDURE [dbo].[CVO_OOS_DAILY_DIFF_SP] 

AS
BEGIN
	SET NOCOUNT ON;

-- -- IDENTIFY DIFFERENCES BETWEEN TWO DIFFERENT DAYS REPORTS
IF(OBJECT_ID('CVO_OutOfStock_DailyReportDIFFS') is not null)  
drop table CVO_OutOfStock_DailyReportDIFFS
SELECT * INTO CVO_OutOfStock_DailyReportDIFFS FROM (
select 'Add' as Movement, t2.* from CVO_OutOfStock_DailyReport_OLD t1 full outer join CVO_OutOfStock_DailyReport t2 on t1.part_no = t2.part_no where t1.part_no is null  -- ADDS
UNION ALL
select 'Off' as Movement, t1.* from CVO_OutOfStock_DailyReport_OLD t1 full outer join CVO_OutOfStock_DailyReport t2 on t1.part_no = t2.part_no where t2.part_no is null -- DELETES 
) as TMP
-- select * from  CVO_OutOfStock_DailyReport_OLD 
-- select * from  CVO_OutOfStock_DailyReport
 select * from CVO_OutOfStock_DailyReportDIFFS  Order by type, movement, Category, Model, Color, Size
 
END



GO
