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


CREATE PROCEDURE [dbo].[sm_get_grp_usr](@where nvarchar(1024))
AS
BEGIN

create table #tmp 
(
user_id smallint,
user_name varchar(40) null,
group_id smallint,
group_name varchar(40) null
)
		insert into #tmp
					select sm.user_id,sm.user_name,sm.group_id,smgp.group_name 
					from smgrpdet_vw sm inner join CVO_Control..smusers smu on smu.user_id = sm.user_id 
					left join CVO_Control..smgrphdr smgp on (smgp.group_id = sm.group_id)
		
		exec ('select user_id,user_name,group_id,group_name
			   from #tmp '+@where)
drop table #tmp
END



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[sm_get_grp_usr] TO [public]
GO
