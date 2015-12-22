CREATE TABLE [dbo].[cc_cust_status_hist]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_code] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[clear_date] [int] NULL,
[cleared_by] [smallint] NULL,
[sequence_num] [smallint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*    
Object:      Trigger  [CVO_CC_cust_hold_tr]      
Source file: CVO_CC_cust_hold_tr.sql    
Author: Bruce Bishop     
Created:  09/22/2011    
Called by:  ,     
Copyright:   Epicor Software 2011.  All rights reserved.      
*/    
-- v1.1 CB 15/11/2011 - Should not update orders on credit hold and orders which are picked  
-- v1.2 CB 05/11/2012 - Issue #891 - WMS Transaction Log 
-- v1.3 CB 23/07/2013 - Issue #927 - Buying Group Switching
-- v1.4 CB 07/11/2013 - Issue #1359 - User and credit Holds do not soft allocate if the hold reason is not in cvo_alloc_hold_values_tbl 
    
CREATE TRIGGER [dbo].[CVO_CC_cust_hold_tr] ON [dbo].[cc_cust_status_hist]   FOR Insert, UPDATE  AS     
    
begin    
    
DECLARE     
@sequence_id  int,     
@max_sequence_id int,    
@customer_code  varchar (8),    
@status_code  varchar (5),    
@clear_date   int,     
@sequence_num  smallint,    
@fin_sequence_id int,     
@fin_max_sequence_id int,    
@customer_code_up varchar (8),    
@prior_hold   varchar (10)    
    
-- create table for status    
CREATE TABLE #hold    
(    
ID    int identity(1,1),    
customer_code varchar (8)null,    
status_code  varchar (5)null,    
date   int null,    
user_id   smallint null,    
clear_date  int null,    
cleared_by  smallint null,    
sequence_num smallint null    
)    
create index idx_customer_code on  #hold (customer_code) with fillfactor = 80    
create index idx_sequence_num on  #hold (sequence_num) with fillfactor = 80    
    
    
CREATE TABLE #cust    
(    
ID    int identity(1,1),    
customer_code varchar (8)null,    
sequence_num smallint null    
)    
create index idx_customer_code on  #cust (customer_code) with fillfactor = 80    
create index idx_sequence_num on  #cust (sequence_num) with fillfactor = 80    
    
    
insert #hold    
(    
customer_code,    
status_code,    
date,    
user_id,    
clear_date,    
cleared_by,    
sequence_num    
)    
select     
customer_code,    
status_code,    
date,    
user_id,    
clear_date,    
cleared_by,    
sequence_num    
from inserted (nolock)     
where status_code in (select hold_code from adm_oehold)    -- TM    
    
    
select @sequence_id = 0, @max_sequence_id = 0    
select @sequence_id = min(ID), @max_sequence_id = max(ID)     
from #hold (nolock)    
    
WHILE (@sequence_id <= @max_sequence_id )      
 begin    
    
 select     
 @customer_code = NULL,    
 @status_code = NULL,    
 @clear_date = NULL,    
 @sequence_num = NULL    
    
 select     
 @customer_code = customer_code,    
 @status_code = status_code,    
 @clear_date = clear_date,    
 @sequence_num = sequence_num    
 from #hold (nolock)    
 where ID = @sequence_id    
    
 -- put orders on hold    
 truncate table #cust    
    
 insert #cust    
 (    
 customer_code,    
 sequence_num    
 )    
 select     
 @customer_code,    
 @sequence_num    

-- v1.3 Start    
-- insert #cust    
-- (    
-- customer_code,    
-- sequence_num    
-- )    
-- select     
-- child,    
-- @sequence_num    
-- from arnarel (nolock)    
-- where parent = @customer_code    

insert #cust    
 (    
 customer_code,    
 sequence_num    
 )    
 SELECT child, @sequence_num
 FROM dbo.f_cvo_get_buying_group_child_list(@customer_code,CONVERT(varchar(10),GETDATE(),121))
 
-- v1.2    
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
  select     
  @fin_sequence_id = '',     
  @fin_max_sequence_id = '',     
  @customer_code_up = ''    
    
  select @fin_sequence_id = min(ID), @fin_max_sequence_id = max(ID)     
  from #cust (nolock)    
    
     
   WHILE (@fin_sequence_id <= @fin_max_sequence_id )      
   Begin    
       
   if @clear_date is null    
   begin    
    
   SELECT @customer_code_up = customer_code    
   from #cust (nolock)     
   where  ID = @fin_sequence_id    
    
   update CVO_orders_all    
   set prior_hold = isnull(hold_reason, '')     
   from orders_all     
   where CVO_orders_all.order_no = orders_all.order_no    
   and CVO_orders_all.ext = orders_all.ext    
   and orders_all.cust_code = @customer_code_up    
   and orders_all.status < 'P'  
   AND  orders_all.status <> 'C' -- v1.1  
      
   update orders_all     
   set     
   status = 'A' ,     
   hold_reason = @status_code     
   where status < 'P'    
   and cust_code = @customer_code_up    
   AND  orders_all.status <> 'C' -- v1.1  

	-- v1.2 Start
	INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
	SELECT	GETDATE() , suser_name() , 'BO' , 'C&C' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
			'STATUS:A/USER HOLD; HOLD REASON:' + LTRIM(RTRIM(@status_code))
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	WHERE	cust_code = @customer_code_up    
	AND		status = 'A'
	AND		hold_reason = @status_code
	-- v1.2 End

	EXEC dbo.cvo_release_to_soft_alloc_sp @customer_code_up, 1 -- v1.4

   end -- if @clear_date is null    
    
   if @clear_date is not null    
   begin    
    
   SELECT @customer_code_up = customer_code    
   from #cust (nolock)     
   where  ID = @fin_sequence_id    
    
   update orders_all    
   set status =   
   case     
    when (prior_hold is not null) and (prior_hold <> '') then 'A'    
    else 'N'    
   end,    
   hold_reason = isnull(prior_hold,'')    
   from CVO_orders_all     
   where CVO_orders_all.order_no = orders_all.order_no    
   and CVO_orders_all.ext = orders_all.ext    
   and orders_all.cust_code = @customer_code_up    
   and orders_all.status < 'P'    
   and orders_all.status not in  ('N','C') -- v1.1 Add credit hold    
   and orders_all.hold_reason in (select status_code from cc_status_codes)    -- TM    
    
	-- v1.2 Start
	INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
	SELECT	GETDATE() , suser_name() , 'BO' , 'C&C' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
			'STATUS:' + CASE WHEN (b.prior_hold is not null) and (b.prior_hold <> '') THEN 'A/USER HOLD; HOLD REASON:' + LTRIM(RTRIM(isnull(b.prior_hold,''))) ELSE 'N/RELEASE USER HOLD' END 
	FROM	orders_all a (NOLOCK)
	JOIN	cvo_orders_all b (NOLOCK)
	ON		a.order_no = b.order_no
	AND		a.ext = b.ext
	WHERE	a.cust_code = @customer_code_up    
	AND		a.status < 'P'    
	AND		a.status not in  ('C') -- v1.1 Add credit hold    
	AND		a.hold_reason in (select status_code from cc_status_codes) 
	-- v1.2 End

    
   update CVO_orders_all set prior_hold = NULL    
   from dbo.CVO_orders_all c join orders_all o    
   on o.order_no = c.order_no and o.ext = c.ext     
   where  o.cust_code = @customer_code_up    
   and status <'P'     
   AND  status <> 'C' -- v1.1  
       
	EXEC dbo.cvo_release_to_soft_alloc_sp @customer_code_up -- v1.4


   end -- if @clear_date is not null    
       
    
   Select @fin_sequence_id = @fin_sequence_id + 1    
   end     
    
    
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
    
 select @sequence_id = @sequence_id +1    
 end    
    
    
end    
    
    
drop table #cust    
drop table #hold    
GO
CREATE NONCLUSTERED INDEX [cc_cust_status_hist_idx2] ON [dbo].[cc_cust_status_hist] ([clear_date]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cc_cust_status_hist_idx] ON [dbo].[cc_cust_status_hist] ([customer_code], [status_code], [date], [sequence_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_cust_status_hist] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_cust_status_hist] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_cust_status_hist] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_cust_status_hist] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_cust_status_hist] TO [public]
GO
