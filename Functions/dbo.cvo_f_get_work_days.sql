SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [dbo].[cvo_f_get_work_days] (@fromdate datetime, @todate datetime)
returns smallint
as
begin
declare @days smallint
/* N=non-working day (planned), H=Holiday, P=non-productive day (unplanned), W=working weekend day, C=Closing (for reporting only), R = Release Date - added 101513 */

/*

select dbo.cvo_f_get_work_days ('08/01/2014','08/31/2014')

-- insert cvo_work_day_cal values('08/30/2014','C')

select * from cvo_work_day_cal where date_type = 'C'

-- INSERT ENTRIES FOR CLOSING DAYS - this is already done for January
insert cvo_work_day_cal values('1/1/2014','C')


-- WHEN NUMBERS ARE VALIDATED , REMOVE THE CLOSING DAYS FROM THE CALENDAR
delete from cvo_work_day_cal where date_type = 'c'

EXECUTE THE JOB, CVO - UPDATES FOR SALES ANALYSIS/REPORTING
    IMPORTANT :  START AT STEP 2!  IF STEP 1 RUNS DURING THE DAY, IT WILL LOCK PEEPS UP
   
Once complete, advise accounting, and
    Bulk re-run these subscriptions:
        Open Order Accounting Holds
        Sales Person Invoice
        Territory Sales
*/

SELECT @days = 
   (DATEDIFF(dd, @fromdate, @todate) + 1)
  -(DATEDIFF(wk, @fromdate, @todate) * 2)
  -(CASE WHEN DATENAME(dw, @fromdate) = 'Sunday' THEN 1 ELSE 0 END)
  -(CASE WHEN DATENAME(dw, @todate) = 'Saturday' THEN 1 ELSE 0 END)
  - (select count(*) from cvo_work_day_cal where workday between @fromdate and @todate and date_type in ('N','H','P') )
  + (select count(*) from cvo_work_day_cal where workday between @fromdate and @todate and date_type in ('W'/*,'C'*/) )  -- 040214 - count closing day as a work day

return @days
end

GO
