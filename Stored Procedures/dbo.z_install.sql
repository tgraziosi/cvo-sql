SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[z_install] AS

declare @cmd varchar(255)



EXEC z_install_permissions


GO
GRANT EXECUTE ON  [dbo].[z_install] TO [public]
GO
