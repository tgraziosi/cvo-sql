SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_est] @strsort varchar(30), @sort char(1), @stat char(1), @xno int,
  @secured_mode int = 0, @org_id varchar(30) = '' , @module varchar(10) = '', @sec_level int = 99 AS

set @secured_mode = isnull(@secured_mode,0)

declare @minstat char(1), @maxstat char(1)
declare @no int, @dt datetime
if @stat = 'A' begin
   select @minstat = 'A', @maxstat = 'T'
end
if @stat = 'O' begin
   select @minstat = 'A', @maxstat = 'Q'
end
if @stat = 'S' begin
   select @minstat = 'R', @maxstat = 'T'
end
set rowcount 100
if @secured_mode = 0
begin
       
if @sort='N' begin
select @no=convert(int,@strsort)
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  (e.est_no >= @no) and
       (e.status >= @minstat and e.status <= @maxstat )
order by e.est_no
end       
    
      
if @sort='C' begin
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ( (e.customer_name > @strsort) OR 
       (e.customer_name = @strsort and e.est_no >= @xno) ) and
       (e.status >= @minstat and e.status <= @maxstat ) 
order by e.customer_name, e.est_no
end     

      
if @sort='D' begin
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ( (e.description > @strsort) OR 
       (e.description = @strsort and e.est_no >= @xno) ) and
       (e.status >= @minstat and e.status <= @maxstat )
order by e.description, e.customer_name, e.est_no
end     


if @sort='D' begin
select @dt=convert(datetime,@strsort)
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  (e.date_entered >= @dt) and e.est_no >= @xno and
       (e.status >= @minstat and e.status <= @maxstat ) 
order by e.date_entered,customer_name,description
end     
end

if @secured_mode = 1
begin
       
if @sort='N' begin
select @no=convert(int,@strsort)
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ((isnull(e.customer_key,'') = '') or isnull(e.customer_key,'') in (select customer_code from adm_cust (nolock)))  and
       (e.est_no >= @no) and
       (e.status >= @minstat and e.status <= @maxstat )
order by e.est_no
end       
    
      
if @sort='C' begin
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ((isnull(e.customer_key,'') = '') or isnull(e.customer_key,'') in (select customer_code from adm_cust (nolock)))  and
       ( (e.customer_name > @strsort) OR 
       (e.customer_name = @strsort and e.est_no >= @xno) ) and
       (e.status >= @minstat and e.status <= @maxstat ) 
order by e.customer_name, e.est_no
end     

      
if @sort='D' begin
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ((isnull(e.customer_key,'') = '') or isnull(e.customer_key,'') in (select customer_code from adm_cust (nolock)))  and
       ( (e.description > @strsort) OR 
       (e.description = @strsort and e.est_no >= @xno) ) and
       (e.status >= @minstat and e.status <= @maxstat )
order by e.description, e.customer_name, e.est_no
end     


if @sort='D' begin
select @dt=convert(datetime,@strsort)
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ((isnull(e.customer_key,'') = '') or isnull(e.customer_key,'') in (select customer_code from adm_cust (nolock)))  and
       (e.date_entered >= @dt) and e.est_no >= @xno and
       (e.status >= @minstat and e.status <= @maxstat ) 
order by e.date_entered,e.customer_name,description
end     
end

if @secured_mode > 1
begin
       
if @sort='N' begin
select @no=convert(int,@strsort)
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ((isnull(e.customer_key,'') = '') or isnull(e.customer_key,'') in (select customer_code from adm_cust (nolock)))  and
       (e.est_no >= @no) and (e.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level))) and
       (e.status >= @minstat and e.status <= @maxstat )
order by e.est_no
end       
    
      
if @sort='C' begin
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ((isnull(e.customer_key,'') = '') or isnull(e.customer_key,'') in (select customer_code from adm_cust (nolock)))  and
       ( (e.customer_name > @strsort) OR 
       (e.customer_name = @strsort and e.est_no >= @xno) ) and
       (e.status >= @minstat and e.status <= @maxstat ) and (e.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level))) 
order by e.customer_name, e.est_no
end     

      
if @sort='D' begin
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ((isnull(e.customer_key,'') = '') or isnull(e.customer_key,'') in (select customer_code from adm_cust (nolock)))  and
       ( (e.description > @strsort) OR 
       (e.description = @strsort and e.est_no >= @xno) ) and  (e.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level))) and
       (e.status >= @minstat and e.status <= @maxstat )
order by e.description, e.customer_name, e.est_no
end     


if @sort='D' begin
select @dt=convert(datetime,@strsort)
select e.est_no, e.customer_key, e.customer_name, 
       e.description, e.date_entered, e.status, e.quoted_qty
from   estimates e ( NOLOCK )
where  ((isnull(e.customer_key,'') = '') or isnull(e.customer_key,'') in (select customer_code from adm_cust (nolock)))  and
       (e.date_entered >= @dt) and e.est_no >= @xno and  (e.location in (select location from dbo.adm_get_related_locs_fn(@module,@org_id,@sec_level))) and
       (e.status >= @minstat and e.status <= @maxstat ) 
order by e.date_entered,e.customer_name,description
end     
end
GO
GRANT EXECUTE ON  [dbo].[get_q_est] TO [public]
GO
