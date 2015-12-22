SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[ESC_CleanupPytData_sp] @ParentRecID varchar(40)
as



if not exists (select * from ESC_CashAppDet where ParentRecID = @ParentRecID)
begin
	delete ESC_CashAppInvDet where ParentRecID = @ParentRecID 
	-- delete ESC_CashAppHdr where ParentRecID = @ParentRecID 
end

GO
GRANT EXECUTE ON  [dbo].[ESC_CleanupPytData_sp] TO [public]
GO
