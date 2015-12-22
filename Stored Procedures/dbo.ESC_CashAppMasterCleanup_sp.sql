SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create procedure [dbo].[ESC_CashAppMasterCleanup_sp] @ParentRecID varchar(40)
as

delete ESC_CashAppInvDet where ParentRecID = @ParentRecID 
delete ESC_CashAppDet where ParentRecID = @ParentRecID 
delete ESC_CashAppHdr where ParentRecID = @ParentRecID 


GO
GRANT EXECUTE ON  [dbo].[ESC_CashAppMasterCleanup_sp] TO [public]
GO
