SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[pdgm_purchasing]

----------------INPUT PARAMETERS------------------------------------------------------
@po_ctrl_num  varchar(16),     --This is the Purchase Order Number(PO number)
                              --MUST BE A PRIMARY KEY
@msg int OUTPUT		      -- 0 = commit, 1 = rollback
--------------------------------------------------------------------------------------
AS
Return 0


/**/
GO
GRANT EXECUTE ON  [dbo].[pdgm_purchasing] TO [public]
GO
