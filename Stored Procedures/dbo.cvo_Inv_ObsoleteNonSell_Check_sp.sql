SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE  [dbo].[cvo_Inv_ObsoleteNonSell_Check_sp]
AS
--
-- TMcGrady		CVO  OCT.2010	Nightly Process to check Discontinue and BackOrder Date
--
-- TAG - CVO - 1/24/12 - adjust logic to current use of backorder date and discontinue date
--
-- First Pass check Backorder Date.  If it has passed, set obsolete flag
UPDATE inv_master set obsolete = 1
-- select i.part_no, i.description, a.datetime_2
  FROM inv_master i, inv_master_add a
 WHERE i.part_no = a.part_no
--   AND a.datetime_1 <= getdate()
   and a.datetime_2 <= getdate()	-- datetime_2 = backorder_date
   AND i.obsolete = 0

-- Second Pass check Discontinue Date    -- EL comments out we are not using datetime_1 discontinue date
--UPDATE inv_master set non_sellable_flag = 'Y'
---- select *
--  FROM inv_master i, inv_master_add a
-- WHERE i.part_no = a.part_no
--   AND a.datetime_1 <= getdate()	-- datetime_1 = disco date - not currently in use by CVO (1/12)
--   AND i.non_sellable_flag = 'N'

--GO


GO
GRANT EXECUTE ON  [dbo].[cvo_Inv_ObsoleteNonSell_Check_sp] TO [public]
GO
