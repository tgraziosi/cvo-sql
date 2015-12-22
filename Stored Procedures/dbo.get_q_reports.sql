SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_reports] @user varchar(20), @start int, @stop int, @prod_id int  AS

declare @sec_all int

select @sec_all = access 
from sec_access 
where user_key=@user and module_key='SEC_ALL'

  SELECT dbo.sec_module.kys 'module_key',   
         dbo.sec_module.name 'module_name', rpt_type 'rpt_type', rpt_path  
    FROM dbo.sec_module  
   WHERE dbo.sec_module.ilevel >= @start AND  
	dbo.sec_module.ilevel <= @stop  AND
	dbo.sec_module.prod_id <= @prod_id AND
	dbo.sec_module.rpt_flag > 0
   ORDER BY dbo.sec_module.name

if @sec_all > 0 begin
  SELECT dbo.sec_module.kys 'module_key',   
         dbo.sec_module.name 'module_name', rpt_type 'rpt_type', rpt_path  
    FROM dbo.sec_module  
   WHERE dbo.sec_module.ilevel >= @start AND  
	dbo.sec_module.ilevel <= @stop  AND
	dbo.sec_module.prod_id <= @prod_id AND
	dbo.sec_module.rpt_flag > 0
   ORDER BY dbo.sec_module.name
end
else begin
  SELECT dbo.sec_module.kys 'module_key',   
         dbo.sec_module.name 'module_name', rpt_type 'rpt_type', rpt_path  
    FROM dbo.sec_access,   
         dbo.sec_module  
   WHERE ( dbo.sec_access.module_key = dbo.sec_module.kys ) and  
 	dbo.sec_access.user_key = @user AND  
	dbo.sec_access.access > 0 AND
	dbo.sec_module.ilevel >= @start AND  
	dbo.sec_module.ilevel <= @stop  AND
	dbo.sec_module.prod_id <= @prod_id AND
	dbo.sec_module.rpt_flag > 0
   ORDER BY dbo.sec_module.name
end



GO
GRANT EXECUTE ON  [dbo].[get_q_reports] TO [public]
GO
