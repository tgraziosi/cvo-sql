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

CREATE PROCEDURE [dbo].[sm_security_user] @where varchar(255)=''

AS
BEGIN

	create Table #temp  
	(
		company_id				smallint NULL,
		company_name				varchar(34) null,
		user_name				varchar(32) NULL,
		user_id					smallint NULL,
		application_id				int NULL,
		application_name			varchar(42) NULL,
		form_id					int NULL,
		form_desc				varchar(52) NULL,
		user_grant				char(1),
		group_grant				char(1),
		group_id				smallint
	)
insert into #temp (company_id,company_name,user_name,user_id,application_id,application_name,form_id,form_desc)
select smp.company_id,smc.company_name, smu.user_name, smu.user_id,smp.app_id,aon.ApplicationName,smp.form_id,smm.form_desc
from CVO_Control..smperm smp inner join CVO_Control..smusers smu on (smp.user_id  = smu.user_id) 
	 left join CVO_Control..smcomp smc	 on (smp.company_id = smc.company_id)
	 left join CVO_Control..smmenus smm on (smm.form_id = smp.form_id)
	 left join CVO_Control..ApplicationObjectNames aon on (aon.ApplicationId = smm.app_id)

update #temp 
set group_id =  smg.group_id
from CVO_Control..smgrpdet_vw smg ,#temp tmp where smg.user_id = tmp.user_id

update #temp
set user_grant = 'X'
from CVO_Control..smuserperm smp right join #temp tmp on (smp.user_id = tmp.user_id )
where smp.company_id = tmp.company_id 
and tmp.application_id = smp.app_id
and tmp.form_id = smp.form_id 

update #temp
set group_grant = 'X'
from CVO_Control..smgrpperm smg right join #temp tmp on (smg.group_id = tmp.group_id )
where smg.company_id = tmp.company_id 
and tmp.application_id = smg.app_id
and tmp.form_id = smg.form_id 

exec (' select  company_id,
		company_name,
		user_id,
		user_name,
		application_id,
		application_name,
		form_id,
		form_desc,
		user_grant,
		group_grant,
		group_id
 	from #temp '+@where)
 
 drop table #temp
END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[sm_security_user] TO [public]
GO
