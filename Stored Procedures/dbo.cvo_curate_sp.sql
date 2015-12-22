SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 CT 18/07/2012 - Copy of fs_curate_sp, with output parameters added
 
CREATE PROCEDURE [dbo].[cvo_curate_sp]  
 @apply_date   int,  
 @from_currency  varchar(8),  
 @home_type  varchar(8),  
 @oper_type  varchar(8),
 @error INT OUTPUT, 
 @home_rate FLOAT OUTPUT, 
 @oper_rate FLOAT OUTPUT  
   
AS  
BEGIN  
  
DECLARE   
 @cnt  int,  
 @home_curr  varchar(8),  
 @oper_curr varchar(8),  
 @chrdate varchar(20)  
  
  
SELECT @home_curr=dbo.glco.home_currency, @oper_curr=dbo.glco.oper_currency  
FROM   dbo.glco   
  
select @home_rate = 0, @oper_rate = 0  
  
SELECT @chrdate=convert(varchar(20),@apply_date)  
  
Create Table #rate ( error int, rate float, divide_flag int )  
  
INSERT #rate   
exec CVO_Control.dbo.mccurate_sp @apply_date, @from_currency,   
      @home_curr, @home_type, 0, 1, 0  
  
SELECT @error = 0  
select @cnt = count(*) from #rate  
if @cnt > 0 begin  
 select @error = error, @home_rate = rate  
  from #rate  
end  
else begin  
 select @error = 110  
end  
  
delete #rate  
IF @error = 0 begin  
 SELECT @error = 0  
  
 INSERT #rate exec CVO_Control.dbo.mccurate_sp  @apply_date, @from_currency,   
        @oper_curr, @oper_type, 0, 1, 0  
  
 select @cnt = count(*) from #rate  
 if @cnt > 0 begin  
  select @error = error, @oper_rate = rate  
   from #rate  
 end  
 else begin  
  select @error = 120  
 end  
  
end  
  
drop table #rate  
  
END   
GO
GRANT EXECUTE ON  [dbo].[cvo_curate_sp] TO [public]
GO
