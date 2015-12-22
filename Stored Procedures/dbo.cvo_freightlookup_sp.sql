SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- FREIGHT LOOKUP TOOL
-- Author: E.L.
-- 071812 - tag - create view for EV
/*
exec cvo_freightlookup_sp 'where ship_via_code like
''%ups%'' 
and wgt = 1
and lower_zip like ''%11542%'''
*/

CREATE procedure [dbo].[cvo_freightlookup_sp] (@whereclause varchar(200))
as
begin 
--
declare @zip nvarchar(5)     

--declare @whereclause varchar(200)                            
--set @whereclause = 'where ship_via_code like
--''%ups%'' 
--and wgt between 1 and 2
--and lower_zip like ''%11542%'''

if (charindex('and lower',@whereclause) <> 0 )
	begin
		set @zip = substring(@whereclause,charindex('lower_zip like',@whereclause)+17,5)
		set @whereclause = left(@whereclause, charindex('and lower_zip',@whereclause)-1)
	end

create table #cvofrt
(ship_via_code varchar(8) null ,
ship_via_name varchar(40) null ,
weight_code varchar(12) null , 
lower_zip varchar(15) null ,
upper_zip varchar(15) null,
wgt decimal(20,8) null,
charge decimal(20,8) null
)

exec ( 'insert into #cvofrt
select S.ship_via_code, S.Ship_via_name, W.Weight_code, Lower_zip, Upper_zip, wgt, charge
from arshipv S (nolock)
join cvo_carriers C (nolock) ON S.ship_via_code=C.Carrier
join cvo_weights W (nolock) ON W.WEIGHT_CODE=C.WEIGHT_CODE '
+
@whereclause
--+
--' and lower_zip <= '+@zip
--+
--' and upper_zip >= '+@zip
)

select ship_via_code ,
       ship_via_name ,
       weight_code ,
       lower_zip ,
       upper_zip ,
       wgt ,
       charge from #cvofrt where lower_zip <= @zip and upper_zip >= @zip order by charge

end

GO
GRANT EXECUTE ON  [dbo].[cvo_freightlookup_sp] TO [public]
GO
