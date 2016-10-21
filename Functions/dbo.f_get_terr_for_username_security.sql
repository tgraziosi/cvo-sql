SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select top (1) * from dbo.f_get_terr_for_username_security('cvoptical\lgraham','9573')
-- insert into cvo_work_day_cal values ('09/26/2013','C') -- Closing Day
-- delete from cvo_work_day_cal where date_type = 'C'
-- 2/4/2013 - tag - added option for SAles Support users
-- 9/24/2013 - tag - add functionality for Closing Days to not run reports.


CREATE FUNCTION [dbo].[f_get_terr_for_username_security] (@username varchar(30),@security varchar(10))
RETURNS @rettab table (territory_code varchar(10))
AS
begin

if (exists (select * from cvo_work_day_cal
                where workday = dateadd(dd, datediff(dd,0,getdate()), 0)
                and date_type = 'C')
  
	and (select distinct x.Salesperson_code from cvo_territoryxref x (nolock) 
	where x.user_name = @username AND x.status = 1) not in ('Internal','SS','CS','KA','IS')
                
                 )
begin
        -- insert @rettab values('*Closing*')
		insert @rettab values('00000')
        return
end
   
IF(@security = (Select TOP(1) security_code From cvo_territoryxref
                Where user_name = @username)             
                )
Begin               

	if (select distinct s.salesperson_type from cvo_territoryxref x (nolock), arsalesp s (nolock)
		where x.salesperson_code = s.salesperson_code AND x.Status = 1
		and x.user_name = @username) = 1 -- manager
	BEGIN
		INSERT INTO @rettab 
			select DISTINCT t.territory_code 
			from cvo_territoryxref x (nolock) 
			left join arterr t (nolock)
			on left(convert(varchar,x.territory_code),3) = left(t.territory_code,3)
			where x.user_name = @username
	return
	END

	if (select distinct s.salesperson_type from cvo_territoryxref x (nolock), arsalesp s (nolock)
		where x.salesperson_code = s.salesperson_code AND x.status = 1
		and x.user_name = @username) = 0 -- rep
	BEGIN
		INSERT INTO @rettab 
			select t.territory_code
			from cvo_territoryxref x (nolock)
			left join arterr t (nolock)
			on convert(varchar,x.territory_code) = t.territory_code
			where x.user_name = @username
	return	
	END

	if (select distinct x.Salesperson_code from cvo_territoryxref x (nolock) 
	where x.user_name = @username AND x.status = 1) in ('SS') -- gets all territories except corp and internal
	BEGIN
		INSERT INTO @rettab 
			select  distinct t.territory_code 
			from arterr t (nolock) where t.territory_code between '20000' and '79999'
	return	
	END

	if (select distinct x.Salesperson_code from cvo_territoryxref x (nolock) 
		where x.user_name = @username AND x.status = 1) in ('Internal','CS','KA','IS') -- gets all territories
	BEGIN
		INSERT INTO @rettab 
			select  distinct t.territory_code 
			from arterr t (nolock)
	return	
	END

END
RETURN
END


GO
