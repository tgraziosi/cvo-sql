SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_shiptocode]

AS

set rowcount 100

select 		distinct (ship_to_code) 
from 		adm_shipto_all ( NOLOCK )
order by 	ship_to_code

GO
GRANT EXECUTE ON  [dbo].[get_q_shiptocode] TO [public]
GO
