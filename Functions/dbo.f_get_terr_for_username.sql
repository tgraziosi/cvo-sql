SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- select * from f_get_terr_for_username('cvoptical\leeb')
-- tg - 2/4/2013 - added new security type for SalesSupport

CREATE FUNCTION [dbo].[f_get_terr_for_username] (@username varchar(30))
RETURNS @rettab table (territory_code varchar(10))
AS
begin
	if (select distinct s.salesperson_type from cvo_territoryxref x (nolock), arsalesp s (nolock)
		where x.salesperson_code = s.salesperson_code
		and x.user_name = @username) = 1 -- manager
	BEGIN
		INSERT INTO @rettab 
			select t.territory_code 
			from cvo_territoryxref x (nolock) 
			left join arterr t (nolock)
			on left(convert(varchar,x.territory_code),3) = left(t.territory_code,3)
			where x.user_name = @username
	return
	END

	if (select distinct s.salesperson_type from cvo_territoryxref x (nolock), arsalesp s (nolock)
		where x.salesperson_code = s.salesperson_code
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
	where x.user_name = @username) = 'SS' -- gets all territories except corp and internal
	BEGIN
		INSERT INTO @rettab 
			select  distinct t.territory_code 
			from arterr t (nolock) where t.territory_code between '20000' and '79999'
	return	
	END

	if (select distinct x.Salesperson_code from cvo_territoryxref x (nolock) 
		where x.user_name = @username) = 'Internal' -- gets all territories
	BEGIN
		INSERT INTO @rettab 
			select  distinct t.territory_code 
			from arterr t (nolock)
	return	
	END
	


RETURN
END



GO
