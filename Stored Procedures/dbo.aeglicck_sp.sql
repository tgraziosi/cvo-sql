SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[aeglicck_sp]
AS
	SELECT passwd_str FROM master..s2passwd

GO
GRANT EXECUTE ON  [dbo].[aeglicck_sp] TO [public]
GO
