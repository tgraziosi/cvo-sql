SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[pdgm_po_matching]

----------------INPUT PARAMETERS------------------------------------------------------
@po_ctrl_num  varchar(16),            --This is the Purchase Order Number(PO number)
                                      --MUST BE A PRIMARY KEY
@msg integer OUTPUT		      -- 0 = commit, 1 = rollback
--------------------------------------------------------------------------------------
AS
Return 0


/**/
GO
GRANT EXECUTE ON  [dbo].[pdgm_po_matching] TO [public]
GO
