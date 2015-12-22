SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_custact] @customer varchar(8)  AS

declare @dbname varchar(100), @cmd varchar(255)
begin



select @dbname = isnull( (select value_str from config where flag='PSQL_DBNAME'), 'plt41dist.' )
select @cmd = 'select customer_code,amt_age_bracket1,amt_age_bracket2,
       amt_age_bracket3,amt_age_bracket4,amt_age_bracket5,amt_age_bracket6,
       (amt_balance_oper)  total_age_amt FROM  '
select @cmd = @cmd + @dbname + '.aractcus'
select @cmd = @cmd + ' ( NOLOCK ) WHERE customer_code = '' + @customer + '''
exec( @cmd )
end

GO
GRANT EXECUTE ON  [dbo].[get_q_custact] TO [public]
GO
