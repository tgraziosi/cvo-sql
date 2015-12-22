SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                

	
CREATE PROCEDURE [dbo].[sm_get_grp_perm] (@where nvarchar(1024))
AS
BEGIN
create table #tmp
(
	group_id	smallint,
	group_name varchar(32),
	group_desc varchar(62),
	form_id		int,
	form_desc varchar(52)
)
insert into #tmp
select  smg.group_id,smg.group_name,smg.group_desc,smgr.form_id,smm.form_desc
from CVO_Control..smgrphdr smg inner join CVO_Control..smgrpperm smgr on (smg.group_id = smgr.group_id) 
left join CVO_Control..smmenus smm on (smgr.form_id = smm.form_id)

exec ('select group_id,group_name,group_desc,form_id,form_desc from #tmp '+@where)		
drop table #tmp	
END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[sm_get_grp_perm] TO [public]
GO
