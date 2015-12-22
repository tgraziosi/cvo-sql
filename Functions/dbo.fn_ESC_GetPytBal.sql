SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [dbo].[fn_ESC_GetPytBal]( @ParRec varchar(40), @Inv varchar(16), @Pyt varchar(16), @ApplyType smallint )

RETURNS float AS  
BEGIN 

declare @PytBal float, @PytAmt float, @AppBal float

if @ApplyType = 1
begin
	select @PytAmt = isnull(DocBal,0) from ESC_CashAppDet (NOLOCK)
	where	DocNum = @Pyt
	and		ParentRecID = @ParRec
	and		DocType = 'PYT'
end
else
begin
	select @PytAmt = isnull(CheckAmt,0) from ESC_CashAppHdr (NOLOCK)
	where	CheckNum = @Pyt
	and		ParentRecID = @ParRec
end

if isnull(@PytAmt,0) = 0 
begin
	select @PytBal = 0
	return @PytBal
end


select	@AppBal = sum(PytApp) from ESC_CashAppInvDet (NOLOCK)
where	PytDoc = @Pyt
and		InvDoc != @Inv
and		ParentRecID = @ParRec

select @PytBal = convert(dec(20,2),@PytAmt + isnull(@AppBal,0) )
return @PytBal

end
GO
