SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_emp] @sort char(1), @search varchar(40), 
                           @empkey varchar(10), @void char(1)  AS

set rowcount 100

if @sort='D'
begin
  select kys, name, department
  from employee 
  where department >= @search and kys >= @empkey and
        (void is NULL OR void like @void)
  order by name
end
if @sort='K'
begin
  select kys, name, department
    from employee 
    where kys >= @search and 
          (void is NULL OR void like @void) 
    order by kys
end
if @sort='N'
begin
  select kys, name, department
  from employee 
  where name >= @search and 
        (void is NULL OR void like @void)
  order by name
end
  select kys, name, department
  from employee 
  where department >= @search and kys >= @empkey and
        (void is NULL OR void like @void)
  order by name
GO
GRANT EXECUTE ON  [dbo].[get_q_emp] TO [public]
GO
