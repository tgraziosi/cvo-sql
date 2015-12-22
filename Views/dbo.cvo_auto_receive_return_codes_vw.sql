SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Name:			cvo_auto_receive_return_codes_vw.sql
Type:			View
Called From:	Enterprise
Description:	Returns return codes which are valid for auto-receiving
Developer:		Chris Tyler
Date:			11th October 2012

Revision History
v1.1 CT 06/06/13 - Issue #1306 - Don't include non-inventory return codes
*/

CREATE VIEW [dbo].[cvo_auto_receive_return_codes_vw]
AS

SELECT 
	return_code,
	return_bin,
	saleable_condition
FROM 
	dbo.po_retcode (NOLOCK)
WHERE
	ISNULL(ret_inv_flag,0) = 1 -- v1.1
	AND (ISNULL(return_bin,'') <> '' OR ISNULL(saleable_condition,0) = 1)  
	
GO
GRANT SELECT ON  [dbo].[cvo_auto_receive_return_codes_vw] TO [public]
GO
