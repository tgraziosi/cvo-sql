SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[EAI_ord_xref_change]
	@process_id		varchar(10),
	@action_id		varchar(10) AS
RETURN 0


/**/
GO
GRANT EXECUTE ON  [dbo].[EAI_ord_xref_change] TO [public]
GO
