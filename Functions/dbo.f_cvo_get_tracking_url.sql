SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Tine Graziosi>
-- Create date: <8/25/2016>
-- Description:	To set the tracking url for shipments
-- =============================================

-- select dbo.f_cvo_get_tracking_url('1Z1458610209498224','UPS2D')
-- select dbo.f_cvo_get_tracking_url('8818847332','DHLI_ZH2')

CREATE FUNCTION [dbo].[f_cvo_get_tracking_url] (@tracking_no VARCHAR(255), @carrier_code VARCHAR(10))
RETURNS varchar(255)
AS
BEGIN
	
DECLARE @tracking_url VARCHAR(255), @config_url VARCHAR(255)


	SELECT	@config_url = value_str
	FROM	dbo.config (NOLOCK) 
	WHERE	flag = 'OE_TRACKING_NO_URL'
	
SELECT @tracking_url = 
CASE WHEN @carrier_code LIKE '%ups%' OR @carrier_code LIKE '%usps%' 
		THEN 'http://wwwapps.ups.com/etracking/tracking.cgi?tracknum=<t>' -- Mail Innovations and UPS
	 WHEN @carrier_code LIKE '%FE%' 
		THEN 'http://www.fedex.com/Tracking?action=track&language=english&cntry_code=us&initial=x&tracknumbers=<t>' -- Fedex
	 WHEN @carrier_code LIKE '%DHL%'
		THEN 'http://www.dhl.com/content/en/express/tracking.html?brand=DHL&AWB=<t>'
	 WHEN @carrier_code LIKE 'zzz' 
		THEN 'http://tools.usps.com/go/TrackConfirmAction_input?qtc_tLabels1=<t>' -- usps regular
	 ELSE @config_url+'<t>' END 


RETURN REPLACE(@tracking_url,'<t>',@tracking_no)

END

GO
