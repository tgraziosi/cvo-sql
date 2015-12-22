SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_get_version_sp] @apptype varchar(10) OUTPUT
AS
	SELECT @apptype = CASE WHEN AppType IN ('MFS', 'WMS') THEN 'WMS'
			       WHEN AppType IS NULL THEN 'NON'
			       ELSE 'DCS' END
	  FROM tdc_contact_reg (nolock)
	 WHERE ServerName = @@SERVERNAME
	   AND DatabaseName = DB_NAME()
GO
GRANT EXECUTE ON  [dbo].[tdc_get_version_sp] TO [public]
GO
