SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create Function [dbo].[cvo_draw_weeks] (@dt1 datetime,@dt2 datetime) returns int
as
Begin
Declare @cnt int,@dt as datetime

set @cnt=0
if @dt1 < @dt2
Begin
 set @dt=@dt1
 while @dt <= @dt2
 Begin
  if Datepart(dw,@dt) = 6 -- a Friday when @@datefirst = 7
  Begin
   set @cnt=@cnt+1
   set @dt=dateadd(dd,6,@dt)
  End
  set @dt=dateadd(dd,1,@dt)
 End
End

if @cnt=0
Begin
  return 0
End
Return @cnt
End


GO
