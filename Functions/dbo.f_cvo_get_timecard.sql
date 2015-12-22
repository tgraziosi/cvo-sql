SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Tine Graziosi
-- Create date: 11/19/2012
-- Description:	Get a list of users and daily timecard for a given date
-- =============================================
-- select * from f_cvo_get_timecard ('11/19/2012','11/20/2012')

CREATE FUNCTION [dbo].[f_cvo_get_timecard] 
(	@tcard_sdate datetime, @tcard_edate datetime 	 )
RETURNS 
@Tbl_timecard TABLE 
(	userid varchar(50), 
	timecard varchar(5) )
AS
BEGIN

declare @last_user varchar(50)

declare user01 cursor for 
select distinct userid 
from tdc_log where tran_date between @tcard_sdate and @tcard_edate
order by userid

open user01
fetch next from user01 into @last_user

while (@@fetch_status = 0)
begin
	insert into @tbl_timecard select @last_user,'07:30' 
	insert into @tbl_timecard select @last_user,'08:00' 
	insert into @tbl_timecard Select @last_user,'08:30'
	insert into @tbl_timecard Select @last_user,'09:00'
	insert into @tbl_timecard Select @last_user,'09:30'
	insert into @tbl_timecard Select @last_user,'10:00'
	insert into @tbl_timecard Select @last_user,'10:30'
	insert into @tbl_timecard Select @last_user,'11:00'
	insert into @tbl_timecard Select @last_user,'11:30'
	insert into @tbl_timecard Select @last_user,'12:00'
	insert into @tbl_timecard Select @last_user,'12:30'
	insert into @tbl_timecard Select @last_user,'13:00'
	insert into @tbl_timecard Select @last_user,'13:30'
	insert into @tbl_timecard Select @last_user,'14:00'
	insert into @tbl_timecard Select @last_user,'14:30'
	insert into @tbl_timecard Select @last_user,'15:00'
	insert into @tbl_timecard Select @last_user,'15:30'
	insert into @tbl_timecard Select @last_user,'16:00'
	insert into @tbl_timecard Select @last_user,'16:30'
	insert into @tbl_timecard Select @last_user,'17:00'
	insert into @tbl_timecard Select @last_user,'17:30'
	insert into @tbl_timecard Select @last_user,'18:00'
	insert into @tbl_timecard Select @last_user,'18:30'
	insert into @tbl_timecard Select @last_user,'19:00'
	insert into @tbl_timecard Select @last_user,'19:30'
	insert into @tbl_timecard Select @last_user,'20:00'
	insert into @tbl_timecard Select @last_user,'20:30'

	fetch next from user01 into @last_user
end
	close user01
	deallocate user01

	RETURN 
END
GO
