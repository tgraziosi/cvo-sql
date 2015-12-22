SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- FREIGHT LOOKUP TOOL
-- Author: E.L.
-- 071812 - tag - create view for EV

--declare @carrier nvarchar (8)                                   
--declare @zip nvarchar(15)                                    
--declare @LowWgt nvarchar(15)                                    
--declare @UpWgt nvarchar(15)                                    
--
--SET @carrier = 'UPS%'
--SET @zip = '21224'
--SET @LowWgt ='2'                    
--SET @UpWgt = '2'

CREATE View [dbo].[cvo_freightlookup_vw] as
select S.ship_via_code, S.Ship_via_name, W.Weight_code, Lower_zip, Upper_zip, wgt, charge  
from arshipv S (nolock)
join cvo_carriers C (nolock)ON S.ship_via_code=C.Carrier
join cvo_weights W (nolock) ON W.WEIGHT_CODE=C.WEIGHT_CODE
--WHERE SHIP_VIA_CODE like @CARRIER
--AND lower_zip <= @zip
--and upper_zip >= @zip
--and wgt >= @LowWgt
--and wgt <= @UpWgt
--order by charge
GO
GRANT SELECT ON  [dbo].[cvo_freightlookup_vw] TO [public]
GO
