SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[amclsFetch_sp]
(
	@rowsrequested smallint = 1,
	@company_id 	smCompanyID,
	@classification_id 	smSurrogateKey,
	@classification_code 	smClassificationCode
) as


create table #temp (
	timestamp varbinary(8) null,
	company_id smallint null,
	classification_id int null,
	classification_code char(8) null,
	classification_description varchar(40) null,
	gl_override varchar(32) null,
	last_modified_date datetime null,
	modified_by int null
)
declare @rowsfound 				smallint
declare @MSKclassification_code smClassificationCode
declare @MSKclassification_id 	smSurrogateKey
declare @MSKcompany_id 			smCompanyID

select @rowsfound = 0
select @MSKclassification_code = @classification_code
select @MSKclassification_id = @classification_id
select @MSKcompany_id = @company_id

if exists (select * from amcls where
	company_id = @MSKcompany_id and
	classification_id = @MSKclassification_id and
	classification_code = @MSKclassification_code)
begin
	while @MSKclassification_code is not null and @rowsfound < @rowsrequested
	begin

		insert into #temp select 
				timestamp,
				company_id,
				classification_id,
				classification_code,
				classification_description,
				gl_override,
				last_modified_date,
				modified_by
		 from amcls where
			company_id = @MSKcompany_id and
			classification_id = @MSKclassification_id and
			classification_code = @MSKclassification_code

			select @rowsfound = @rowsfound + @@rowcount
		
		select @MSKclassification_code = min(classification_code) from amcls where
		company_id = @MSKcompany_id and
		classification_id = @MSKclassification_id and
		classification_code > @MSKclassification_code
	end
end
select
	timestamp,
	company_id,
	classification_id,
	classification_code,
	classification_description,
	gl_override,
	last_modified_date = convert(char(8),last_modified_date,112),
	modified_by
from #temp order by company_id, classification_id, classification_code
drop table #temp

return @@error
GO
GRANT EXECUTE ON  [dbo].[amclsFetch_sp] TO [public]
GO
